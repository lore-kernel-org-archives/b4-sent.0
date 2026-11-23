From: Igor Velkov <iav@iav.lv>
Date: Mon, 23 Nov 2026 00:46:14 +0000
Subject: [PATCH net v8 2/5] net: phy: fix three paths that unbalance a
 postponed PHY interrupt line
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-phylib-mac-pm-irq-v3-v8-2-e9f706e79614@iav.lv>
References: <20261123-b4-phylib-mac-pm-irq-v3-v8-0-e9f706e79614@iav.lv>
In-Reply-To: <20261123-b4-phylib-mac-pm-irq-v3-v8-0-e9f706e79614@iav.lv>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Thomas Gleixner <tglx@kernel.org>, linux-pm@vger.kernel.org, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Lukas Wunner <lukas@wunner.de>, 
 "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>, 
 Wei Fang <wei.fang@nxp.com>, 
 =?utf-8?q?Niklas_S=C3=B6derlund?= <niklas.soderlund@ragnatech.se>, 
 Paul Barker <paul@pbarker.dev>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Doug Berger <opendmb@gmail.com>, 
 Thangaraj Samynathan <Thangaraj.S@microchip.com>, 
 Shenwei Wang <shenwei.wang@nxp.com>, 
 Haoning Cheng <Haoning.CHENG@cn.bosch.com>, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=11424; i=iav@iav.lv;
 h=from:subject:message-id; bh=w00LTI1p+eM+1x7ZRAmQjTjEZhBtoli35Tub5EEx2ho=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNnMPTe2C7lsy/ZrW5y0or9+fmbl6zdCVUbap849XXSCx
 eP7Ve/WjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCRV9yMDCeEFxvMa9/d7z/b
 o+7d9/cHgrUiW2fONXZy+LuJocRn7RSGvwLzV14U9dqx6eG/p1u9OoPUmbxWftkyT1JrS1Toq9C
 rt7kA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

phy_interrupt() postpones interrupts during a system sleep transition:
it sets irq_rerun and disables the line, and mdio_bus_phy_resume()
re-enables the line once and reruns the handler. Three paths leave the
line unbalanced:

- On an edge-triggered line the IRQ core does not mask a ONESHOT
  interrupt, so an edge that arrives before disable_irq_nosync() runs
  the thread again. That second run disables the line again, and the
  line stays disabled after resume.
- phy_free_interrupt() can run between the postponed interrupt and
  mdio_bus_phy_resume() and leaves irq_rerun set. Once the line has no
  users, free_irq() shuts it down and a new request starts it at depth
  0, so the enable_irq() in mdio_bus_phy_resume() is unbalanced. On a
  shared line this can happen once the other users free it too, as with
  the two PHYs of dra72-evm-revc behind cpsw.
- If phy_request_interrupt() then leaves the PHY polling,
  mdio_bus_phy_resume() returns before enable_irq(), and the other
  users of a shared line stay disabled.

MAC drivers that close the interface in their suspend callback, such as
cpsw, and ravb with Wake-on-LAN off, reach phy_free_interrupt() through
phy_disconnect(), and so does dev_close() in a kernel-internal reset of
the MAC such as stmmac_reset_subtask(), whose workqueue does not freeze.
These drivers set mac_managed_pm, which a later patch brings under
postponing.

Let only the run that sets irq_rerun disable the line, and record the
line it disabled. Clear irq_rerun where the line starts again at depth
0: in phy_free_interrupt() when free_irq() leaves the line without
users, and in phy_request_interrupt() when the line has no users. Otherwise
mdio_bus_phy_resume() enables the recorded line, also for a PHY that
fell back to polling, and reruns the handler only if the PHY still uses
that line. Enabling the line in phy_free_interrupt() instead would
unmask a source that phy_disable_interrupts() failed to clear, and
inside the noirq phase it would unbalance a wakeup line that
suspend_device_irqs() enabled (IRQCHIP_ENABLE_WAKEUP_ON_SUSPEND).

Add irq_pm_lock, so that requesting and freeing the interrupt do not
change irq_rerun between the check and the enable_irq() of the rerun
after resume, and move the postponing and the rerun into helpers.
phy_interrupt() never takes the lock, so synchronize_irq() and
free_irq() can wait for the handler under it. irq_rerun and
irq_rerun_line are plain fields: one thread runs the handler, and the
other paths access them only under the lock, after free_irq() or
synchronize_irq(), or before this PHY has requested the line. Mark the
irq_suspended accesses with READ_ONCE() and WRITE_ONCE(): the handler
reads it while the PM callbacks write it.

Three cases on a shared line stay unbalanced: after all users have freed
the line, another user requests it first, so it has users when this PHY
requests it; another user requests it between free_irq() and the
irq_has_action() check in phy_free_interrupt(); or the last other user
frees it between the irq_has_action() check and request_threaded_irq()
in phy_request_interrupt(). irq_rerun then stays, and the enable after
resume is unbalanced or reaches a line without users; until then a
postponed interrupt does not disable the line again, so a
level-triggered one keeps firing.

This does not keep close and open off the MDIO bus: on close,
phy_disconnect() calls phy_stop(), phy_free_interrupt() with its
phy_disable_interrupts() and, in phy_detach(), phy_suspend(); on open,
phy_attach_direct() calls phy_init_hw() and phy_request_interrupt()
calls phy_enable_interrupts(). A MAC driver that powers its MDIO bus
down during sleep must not close or open the interface until the bus is
back.

Fixes: 1758bde2e4aa ("net: phy: Don't trigger state machine while in suspend")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Haoning Cheng's Tested-by on v5 is not carried: phy_free_interrupt()
no longer enables a shared line.
---
 drivers/net/phy/phy.c        | 24 ++++++++++++++++---
 drivers/net/phy/phy_device.c | 57 ++++++++++++++++++++++++++++----------------
 include/linux/phy.h          | 12 ++++++++--
 3 files changed, 67 insertions(+), 26 deletions(-)

diff --git a/drivers/net/phy/phy.c b/drivers/net/phy/phy.c
index 9af303d60bd6..92ee4651bdbc 100644
--- a/drivers/net/phy/phy.c
+++ b/drivers/net/phy/phy.c
@@ -1416,7 +1416,7 @@ static irqreturn_t phy_interrupt(int irq, void *phy_dat)
 	/* Wakeup interrupts may occur during a system sleep transition.
 	 * Postpone handling until the PHY has resumed.
 	 */
-	if (IS_ENABLED(CONFIG_PM_SLEEP) && phydev->irq_suspended) {
+	if (IS_ENABLED(CONFIG_PM_SLEEP) && READ_ONCE(phydev->irq_suspended)) {
 		struct net_device *netdev = phydev->attached_dev;
 
 		if (netdev) {
@@ -1430,8 +1430,12 @@ static irqreturn_t phy_interrupt(int irq, void *phy_dat)
 				pm_wakeup_dev_event(parent, 0, true);
 		}
 
-		phydev->irq_rerun = true;
-		disable_irq_nosync(irq);
+		/* Disable the line only once: an edge can rerun the thread. */
+		if (!phydev->irq_rerun) {
+			phydev->irq_rerun_line = irq;
+			phydev->irq_rerun = true;
+			disable_irq_nosync(irq);
+		}
 		return IRQ_HANDLED;
 	}
 
@@ -1480,6 +1484,12 @@ void phy_request_interrupt(struct phy_device *phydev)
 {
 	int err;
 
+	/* A line without users restarts at depth 0, so our disable is gone */
+	mutex_lock(&phydev->irq_pm_lock);
+	if (phydev->irq_rerun && !irq_has_action(phydev->irq_rerun_line))
+		phydev->irq_rerun = false;
+	mutex_unlock(&phydev->irq_pm_lock);
+
 	err = request_threaded_irq(phydev->irq, NULL, phy_interrupt,
 				   IRQF_ONESHOT | IRQF_SHARED,
 				   phydev_name(phydev), phydev);
@@ -1507,7 +1517,15 @@ EXPORT_SYMBOL(phy_request_interrupt);
 void phy_free_interrupt(struct phy_device *phydev)
 {
 	phy_disable_interrupts(phydev);
+
+	mutex_lock(&phydev->irq_pm_lock);
 	free_irq(phydev->irq, phydev);
+	/* free_irq() shuts down a line left without users and the next request
+	 * resets its depth; mdio_bus_phy_resume_irq() enables a shared line.
+	 */
+	if (!irq_has_action(phydev->irq))
+		phydev->irq_rerun = false;
+	mutex_unlock(&phydev->irq_pm_lock);
 }
 EXPORT_SYMBOL(phy_free_interrupt);
 
diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 1791d578f4dd..f2e2370b4be7 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -332,6 +332,39 @@ static bool mdio_bus_phy_may_suspend(struct phy_device *phydev)
 	return !phydev->suspended;
 }
 
+/* Wakeup interrupts may occur during the system sleep transition when
+ * the PHY is inaccessible. Set flag to postpone handling until the PHY
+ * has resumed. Wait for concurrent interrupt handler to complete.
+ */
+static __maybe_unused void mdio_bus_phy_suspend_irq(struct phy_device *phydev)
+{
+	if (!phy_interrupt_is_valid(phydev))
+		return;
+
+	WRITE_ONCE(phydev->irq_suspended, true);
+	synchronize_irq(phydev->irq);
+}
+
+/* Rerun interrupts which were postponed by phy_interrupt()
+ * because they occurred during the system sleep transition.
+ */
+static __maybe_unused void mdio_bus_phy_resume_irq(struct phy_device *phydev)
+{
+	WRITE_ONCE(phydev->irq_suspended, false);
+
+	mutex_lock(&phydev->irq_pm_lock);
+	if (phy_interrupt_is_valid(phydev))
+		synchronize_irq(phydev->irq);
+	/* The PHY may have fallen back to polling since it disabled the line */
+	if (phydev->irq_rerun) {
+		phydev->irq_rerun = false;
+		enable_irq(phydev->irq_rerun_line);
+		if (phydev->irq == phydev->irq_rerun_line)
+			irq_wake_thread(phydev->irq, phydev);
+	}
+	mutex_unlock(&phydev->irq_pm_lock);
+}
+
 static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 {
 	struct phy_device *phydev = to_phy_device(dev);
@@ -339,14 +372,7 @@ static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 	if (phydev->mac_managed_pm)
 		return 0;
 
-	/* Wakeup interrupts may occur during the system sleep transition when
-	 * the PHY is inaccessible. Set flag to postpone handling until the PHY
-	 * has resumed. Wait for concurrent interrupt handler to complete.
-	 */
-	if (phy_interrupt_is_valid(phydev)) {
-		phydev->irq_suspended = true;
-		synchronize_irq(phydev->irq);
-	}
+	mdio_bus_phy_suspend_irq(phydev);
 
 	/* We must stop the state machine manually, otherwise it stops out of
 	 * control, possibly with the phydev->lock held. Upon resume, netdev
@@ -393,19 +419,7 @@ static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
 	if (ret < 0)
 		return ret;
 no_resume:
-	if (phy_interrupt_is_valid(phydev)) {
-		phydev->irq_suspended = false;
-		synchronize_irq(phydev->irq);
-
-		/* Rerun interrupts which were postponed by phy_interrupt()
-		 * because they occurred during the system sleep transition.
-		 */
-		if (phydev->irq_rerun) {
-			phydev->irq_rerun = false;
-			enable_irq(phydev->irq);
-			irq_wake_thread(phydev->irq, phydev);
-		}
-	}
+	mdio_bus_phy_resume_irq(phydev);
 
 	if (phy_uses_state_machine(phydev))
 		phy_start_machine(phydev);
@@ -711,6 +725,7 @@ struct phy_device *phy_device_create(struct mii_bus *bus, int addr, u32 phy_id,
 	dev->max_n_ports = 1;
 
 	mutex_init(&dev->lock);
+	mutex_init(&dev->irq_pm_lock);
 	INIT_DELAYED_WORK(&dev->state_queue, phy_state_machine);
 
 	/* Request the appropriate module unconditionally; don't
diff --git a/include/linux/phy.h b/include/linux/phy.h
index 59c75296d535..d84f7d8bc9df 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -651,8 +651,8 @@ struct phy_oatc14_sqi_capability {
  * @interrupts: Flag interrupts have been enabled
  * @irq_suspended: Flag indicating PHY is suspended and therefore interrupt
  *                 handling shall be postponed until PHY has resumed
- * @irq_rerun: Flag indicating interrupts occurred while PHY was suspended,
- *             requiring a rerun of the interrupt handler after resume
+ * @irq_rerun: Set by the postponed interrupt that disabled the line
+ * @irq_rerun_line: The line the postponed interrupt disabled
  * @default_timestamp: Flag indicating whether we are using the phy
  *		       timestamp as the default one
  * @interface: enum phy_interface_t value
@@ -675,6 +675,9 @@ struct phy_oatc14_sqi_capability {
  * @n_ports: Number of ports currently attached to the PHY
  * @max_n_ports: Max number of ports this PHY can expose
  * @lock:  Mutex for serialization access to PHY
+ * @irq_pm_lock: Held by the PM callbacks, and by the requesting and freeing
+ *               of the interrupt where they test and clear @irq_rerun;
+ *               phy_interrupt() never takes it
  * @state_queue: Work queue for state machine
  * @link_down_events: Number of times link was lost
  * @shared: Pointer to private data shared by phys in one package
@@ -731,6 +734,7 @@ struct phy_device {
 	 */
 	bool irq_suspended;
 	bool irq_rerun;
+	int irq_rerun_line;
 
 	unsigned default_timestamp:1;
 
@@ -808,6 +812,10 @@ struct phy_device {
 	struct delayed_work state_queue;
 
 	struct mutex lock;
+	/* Held where the PM callbacks and the requesting and freeing of the
+	 * interrupt test and clear irq_rerun
+	 */
+	struct mutex irq_pm_lock;
 
 	/* This may be modified under the rtnl lock */
 	bool sfp_bus_attached;

-- 
2.43.0

