From: Igor Velkov <iav@iav.lv>
Date: Sat, 31 Oct 2026 08:01:14 +0000
Subject: [PATCH net v4 3/5] net: phy: balance a postponed PHY interrupt
 when the interrupt is freed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-b4-phylib-mac-pm-irq-v3-v4-3-5ba23b3ff9a4@iav.lv>
References: <20261031-b4-phylib-mac-pm-irq-v3-v4-0-5ba23b3ff9a4@iav.lv>
In-Reply-To: <20261031-b4-phylib-mac-pm-irq-v3-v4-0-5ba23b3ff9a4@iav.lv>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Lukas Wunner <lukas@wunner.de>, 
 "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>, 
 Wei Fang <wei.fang@nxp.com>, 
 =?utf-8?q?Niklas_S=C3=B6derlund?= <niklas.soderlund@ragnatech.se>, 
 Paul Barker <paul@pbarker.dev>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Doug Berger <opendmb@gmail.com>, 
 Thangaraj Samynathan <Thangaraj.S@microchip.com>, 
 Shenwei Wang <shenwei.wang@nxp.com>, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=7932; i=iav@iav.lv;
 h=from:subject:message-id; bh=x72AMhw5nghAvnc4EZ6e9kKurw3YNmp6489QcqrP4Ls=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlPF3jHKly3mxuyNVWQ/c1+9pWzlD/zW8/ff8A1ZuJSG
 Y+m1J27O0pZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBEpO0Z/rtNk7grU7IwIiY4
 TctI7WnrqhUOJX/jdFlS1+rk1EpyHmP4K3pXWjvWievtR53qpmoWQXs+nvgd5Ye/L9a5l5Gr4xj
 OBQA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

phy_interrupt() postpones interrupts during a system sleep transition:
it sets irq_rerun and disables the line, and mdio_bus_phy_resume()
re-enables the line and reruns the handler. phy_free_interrupt() can
run in between and leaves irq_rerun set:

- Other users of a shared line stay without interrupts until
  mdio_bus_phy_resume().
- Without other users, a new request starts the line at depth 0, and
  the enable_irq() in mdio_bus_phy_resume() is unbalanced.

MAC drivers that close the interface in their suspend callback, such
as ravb and cpsw, reach it through phy_disconnect(), and so does
dev_close() in a kernel-internal reset of the MAC such as
stmmac_reset_subtask(), whose workqueue does not freeze. These drivers
set mac_managed_pm, which a later patch brings under postponing.

Let phy_free_interrupt() set irq_rerun too, so that a postponed
interrupt that follows leaves the line enabled. If a handler set it
first, phy_free_interrupt() waits for that handler and re-enables the
line before free_irq(), while the line is still its own, whether or
not other users remain. On a level-triggered line whose source
phy_disable_interrupts() did not clear, the interrupt then fires until
free_irq(), in the same call, removes the handler. Add irq_pm_lock, so
that phy_free_interrupt() and the rerun after resume do not both
re-enable the line, and move the postponing and the rerun into helpers
that take it. phy_interrupt() never takes the lock, so synchronize_irq()
and free_irq() can wait for the handler under it.

This does not keep close and open off the MDIO bus: on close,
phy_disconnect() calls phy_stop(), phy_disable_interrupts() and, in
phy_detach(), phy_suspend(); on open, phy_attach_direct() calls
phy_init_hw() and phy_request_interrupt() calls
phy_enable_interrupts(). A MAC driver that powers its MDIO bus down
during sleep must not close or open the interface until the bus is
back.

Fixes: 1758bde2e4aa ("net: phy: Don't trigger state machine while in suspend")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/net/phy/phy.c        | 16 ++++++++++++-
 drivers/net/phy/phy_device.c | 54 ++++++++++++++++++++++++++++----------------
 include/linux/phy.h          |  8 ++++++-
 3 files changed, 56 insertions(+), 22 deletions(-)

diff --git a/drivers/net/phy/phy.c b/drivers/net/phy/phy.c
index b47f0d3d99e5..49098b481388 100644
--- a/drivers/net/phy/phy.c
+++ b/drivers/net/phy/phy.c
@@ -1430,7 +1430,9 @@ static irqreturn_t phy_interrupt(int irq, void *phy_dat)
 				pm_wakeup_dev_event(parent, 0, true);
 		}
 
-		/* Disable the line only once: an edge can rerun the thread. */
+		/* Disable the line only once: an edge can rerun the thread, and
+		 * phy_free_interrupt() presets irq_rerun to keep it enabled.
+		 */
 		if (!atomic_xchg(&phydev->irq_rerun, 1))
 			disable_irq_nosync(irq);
 		return IRQ_HANDLED;
@@ -1508,7 +1510,19 @@ EXPORT_SYMBOL(phy_request_interrupt);
 void phy_free_interrupt(struct phy_device *phydev)
 {
 	phy_disable_interrupts(phydev);
+
+	/* Re-enable a line left disabled by a postponed interrupt while it
+	 * is still ours, and keep later postponed interrupts from disabling it.
+	 */
+	mutex_lock(&phydev->irq_pm_lock);
+	if (atomic_xchg(&phydev->irq_rerun, 1)) {
+		/* Wait for the handler that set irq_rerun to disable the line */
+		synchronize_irq(phydev->irq);
+		enable_irq(phydev->irq);
+	}
 	free_irq(phydev->irq, phydev);
+	atomic_set(&phydev->irq_rerun, 0);
+	mutex_unlock(&phydev->irq_pm_lock);
 }
 EXPORT_SYMBOL(phy_free_interrupt);
 
diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index d5d0efc10418..ef5e1cd3a831 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -332,6 +332,37 @@ static bool mdio_bus_phy_may_suspend(struct phy_device *phydev)
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
+	if (!phy_interrupt_is_valid(phydev))
+		return;
+
+	mutex_lock(&phydev->irq_pm_lock);
+	synchronize_irq(phydev->irq);
+	if (atomic_xchg(&phydev->irq_rerun, 0)) {
+		enable_irq(phydev->irq);
+		irq_wake_thread(phydev->irq, phydev);
+	}
+	mutex_unlock(&phydev->irq_pm_lock);
+}
+
 static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 {
 	struct phy_device *phydev = to_phy_device(dev);
@@ -339,14 +370,7 @@ static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 	if (phydev->mac_managed_pm)
 		return 0;
 
-	/* Wakeup interrupts may occur during the system sleep transition when
-	 * the PHY is inaccessible. Set flag to postpone handling until the PHY
-	 * has resumed. Wait for concurrent interrupt handler to complete.
-	 */
-	if (phy_interrupt_is_valid(phydev)) {
-		WRITE_ONCE(phydev->irq_suspended, true);
-		synchronize_irq(phydev->irq);
-	}
+	mdio_bus_phy_suspend_irq(phydev);
 
 	/* We must stop the state machine manually, otherwise it stops out of
 	 * control, possibly with the phydev->lock held. Upon resume, netdev
@@ -393,18 +417,7 @@ static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
 	if (ret < 0)
 		return ret;
 no_resume:
-	if (phy_interrupt_is_valid(phydev)) {
-		WRITE_ONCE(phydev->irq_suspended, false);
-		synchronize_irq(phydev->irq);
-
-		/* Rerun interrupts which were postponed by phy_interrupt()
-		 * because they occurred during the system sleep transition.
-		 */
-		if (atomic_xchg(&phydev->irq_rerun, 0)) {
-			enable_irq(phydev->irq);
-			irq_wake_thread(phydev->irq, phydev);
-		}
-	}
+	mdio_bus_phy_resume_irq(phydev);
 
 	if (phy_uses_state_machine(phydev))
 		phy_start_machine(phydev);
@@ -710,6 +723,7 @@ struct phy_device *phy_device_create(struct mii_bus *bus, int addr, u32 phy_id,
 	dev->max_n_ports = 1;
 
 	mutex_init(&dev->lock);
+	mutex_init(&dev->irq_pm_lock);
 	INIT_DELAYED_WORK(&dev->state_queue, phy_state_machine);
 
 	/* Request the appropriate module unconditionally; don't
diff --git a/include/linux/phy.h b/include/linux/phy.h
index 48b4e852f230..04916fc29ed7 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -651,7 +651,11 @@ struct phy_oatc14_sqi_capability {
  * @interrupts: Flag interrupts have been enabled
  * @irq_suspended: Flag indicating PHY is suspended and therefore interrupt
  *                 handling shall be postponed until PHY has resumed
- * @irq_rerun: Set by the postponed interrupt that disabled the line
+ * @irq_rerun: Set by the postponed interrupt that disabled the line, and
+ *             by phy_free_interrupt() to keep the line enabled
+ * @irq_pm_lock: Serializes phy_free_interrupt() against the rerun of a
+ *               postponed interrupt, so that only one of them re-enables
+ *               the line; never taken by phy_interrupt()
  * @default_timestamp: Flag indicating whether we are using the phy
  *		       timestamp as the default one
  * @interface: enum phy_interface_t value
@@ -728,6 +732,8 @@ struct phy_device {
 	/* Written without phydev->lock, so not bitfields */
 	bool irq_suspended;
 	atomic_t irq_rerun;
+	/* Serializes phy_free_interrupt() against mdio_bus_phy_resume_irq() */
+	struct mutex irq_pm_lock;
 
 	unsigned default_timestamp:1;
 

-- 
2.43.0

