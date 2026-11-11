From: Igor Velkov <iav@iav.lv>
Date: Wed, 11 Nov 2026 23:48:22 +0000
Subject: [PATCH net v5 4/4] net: phy: postpone PHY interrupts during sleep
 with MAC-managed PM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-b4-phylib-mac-pm-irq-v3-v5-4-bbfdb5afb7d3@iav.lv>
References: <20261111-b4-phylib-mac-pm-irq-v3-v5-0-bbfdb5afb7d3@iav.lv>
In-Reply-To: <20261111-b4-phylib-mac-pm-irq-v3-v5-0-bbfdb5afb7d3@iav.lv>
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
 Shenwei Wang <shenwei.wang@nxp.com>, 
 Haoning Cheng <Haoning.CHENG@cn.bosch.com>, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=11568; i=iav@iav.lv;
 h=from:subject:message-id; bh=jbHx8Bz2Y7ohAkUwihZv3T7ClFglixonpV5yKyVxm6I=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlf/h0Ly0k9ej/2czFf6fy69QoT2Q+pFX9SXTXV7rpt3
 lWrxuS7HaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiXPsZ/od1Pjh+YF3d5Dmt
 FXuMbzgv/Gz7VGDZWateD51jyo+fqO5nZPj7aIXAhOybP11OZ/7YN+9jynnTd5Y3YhS8uF55uPR
 y3ecEAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mdio_bus_phy_suspend() and mdio_bus_phy_resume() return early when the
MAC driver manages PHY PM, so the PHY never gets irq_suspended and
phy_interrupt() runs the PHY driver's handler at any point of the sleep
transition. If the MAC driver powers the MDIO bus down, the MDIO access
in that handler can stall the CPU. This happens on both sides:

- suspend: the MAC's suspend callback stops the PHY, the link goes
  down, and the handler runs while the MAC powers down;
- resume: resume_device_irqs() re-enables a pending interrupt before
  the MAC resumes.

On Helios64 (dwmac-rk, RTL8211F with its interrupt line described in DT)
both hang the board: the handler reads INSR while the GMAC clocks are
off, after rk_gmac_suspend() or before rk_gmac_resume(). The commit in
the Fixes tag added the postponing after the early return for
MAC-managed PHY PM, and stmmac has set mac_managed_pm since commit
f151c147b3af ("net: stmmac: Enable mac_managed_pm phylink config").

Set irq_suspended for these PHYs too. The PHY device is a child of its
MDIO bus, so mdio_bus_phy_resume() runs after the resume callbacks of
the bus and its parents (with stmmac, the MAC) and replays the postponed
interrupt then. The PM core resumes children of a device whose resume
callback failed, and phylib cannot tell: if the MAC fails to power the
bus up, the replay still reaches the bus. phy_suspend(), phy_resume()
and the state machine stay with the MAC driver, and no MAC driver needs
a change. Doing this in phylink_suspend() instead would miss macb, which
sets mac_managed_pm but suspends with phylink_stop().

A postponed interrupt cannot ask the PHY whether Wake-on-LAN is enabled:
phy_may_wakeup() may read the PHY over MDIO. Decide that in
mdio_bus_phy_suspend() instead, which runs before the suspend callback
of the device that owns the MDIO bus, and store the wakeup event to
report. For a PHY whose MAC manages PHY PM, this MDIO access in the
suspend path is new; phy_suspend() makes the same one for other PHYs. A
PHY on the MDIO bus of another MAC can already be suspended there:
phy_attach_direct() links its MAC to it, so the MAC suspends first. For
a suspended PHY without driver-model wakeup, do not read the PHY: use
wol_phy, where phy_suspend() now keeps the answer of phy_may_wakeup().
wol_enabled also counts Wake-on-LAN in the MAC.
mdio_bus_phy_suspend_irq() sets irq_suspended with a store-release after
writing irq_wake, and phy_interrupt() reads it with a load-acquire, so a
postponed interrupt sees the event decided for it.

A PHY reports a system wakeup when phy_may_wakeup() says Wake-on-LAN is
enabled in it, as phy_suspend() already counts it; this is new for PHYs
without MAC-managed PM too. Otherwise a PHY without MAC-managed PM
reports what phy_interrupt() reports today: Wake-on-LAN set through
ethtool, then the netdev and its parent. A PHY with MAC-managed PM
reports nothing: the MAC stops the PHY itself, its ethtool flag may
describe Wake-on-LAN in the MAC, as with fec, and the MAC device may
wake the system on its own, so a link interrupt the MAC causes must not
abort suspend.

Tested on Helios64 with 7.3.4, s2idle with the link up:
- no Wake-on-LAN, GMAC clocks off in suspend: 10 of 10 cycles suspended
  and resumed; on 7.3 without this series the same test hung or reset
  the board after the link went down 10 of 10 times;
- MAC power/wakeup enabled, no Wake-on-LAN: 3 of 3 slept;
- Wake-on-LAN in the PHY, so phylink_suspend() also drops the link
  speed: a magic packet woke the board 4 of 4 times, no suspend
  aborted.

Fixes: 1758bde2e4aa ("net: phy: Don't trigger state machine while in suspend")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Haoning Cheng's Tested-by on v4 is not carried: the wakeup policy for
MAC-managed PHYs changed.
---
 drivers/net/phy/phy.c        | 25 ++++++++++++-------
 drivers/net/phy/phy_device.c | 57 ++++++++++++++++++++++++++++++++++++++++----
 include/linux/phy.h          | 23 ++++++++++++++++--
 3 files changed, 89 insertions(+), 16 deletions(-)

diff --git a/drivers/net/phy/phy.c b/drivers/net/phy/phy.c
index 62b7f428f9da..1a7648c381f7 100644
--- a/drivers/net/phy/phy.c
+++ b/drivers/net/phy/phy.c
@@ -1416,18 +1416,25 @@ static irqreturn_t phy_interrupt(int irq, void *phy_dat)
 	/* Wakeup interrupts may occur during a system sleep transition.
 	 * Postpone handling until the transition ends.
 	 */
-	if (IS_ENABLED(CONFIG_PM_SLEEP) && READ_ONCE(phydev->irq_suspended)) {
+	if (IS_ENABLED(CONFIG_PM_SLEEP) &&
+	    /* Pairs with smp_store_release() in mdio_bus_phy_suspend_irq() */
+	    smp_load_acquire(&phydev->irq_suspended)) {
 		struct net_device *netdev = phydev->attached_dev;
 
-		if (netdev) {
-			struct device *parent = netdev->dev.parent;
-
-			if (netdev->ethtool->wol_enabled)
-				pm_system_wakeup();
-			else if (device_may_wakeup(&netdev->dev))
+		switch (phydev->irq_wake) {
+		case PHY_IRQ_WAKE_SYSTEM:
+			pm_system_wakeup();
+			break;
+		case PHY_IRQ_WAKE_NETDEV:
+			if (netdev)
 				pm_wakeup_dev_event(&netdev->dev, 0, true);
-			else if (parent && device_may_wakeup(parent))
-				pm_wakeup_dev_event(parent, 0, true);
+			break;
+		case PHY_IRQ_WAKE_PARENT:
+			if (netdev && netdev->dev.parent)
+				pm_wakeup_dev_event(netdev->dev.parent, 0, true);
+			break;
+		case PHY_IRQ_WAKE_NONE:
+			break;
 		}
 
 		/* Disable the line only once: an edge can rerun the thread. */
diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 110c9dfcbd91..2dc13dd1afb6 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -332,6 +332,44 @@ static bool mdio_bus_phy_may_suspend(struct phy_device *phydev)
 	return !phydev->suspended;
 }
 
+static __maybe_unused enum phy_irq_wake
+phy_irq_wake_source(struct phy_device *phydev)
+{
+	struct net_device *netdev = phydev->attached_dev;
+	bool phy_wol;
+
+	if (!netdev)
+		return PHY_IRQ_WAKE_NONE;
+
+	/* phy_suspend() cached the answer of a suspended PHY, which may
+	 * not be reachable over MDIO.
+	 */
+	if (phydev->suspended && !phy_can_wakeup(phydev))
+		phy_wol = phydev->wol_phy;
+	else
+		phy_wol = phy_may_wakeup(phydev);
+
+	if (phy_wol)
+		return PHY_IRQ_WAKE_SYSTEM;
+
+	/* With MAC-managed PM, only Wake-on-LAN in the PHY makes its
+	 * interrupt a wakeup: the MAC stops the PHY itself.
+	 */
+	if (phydev->mac_managed_pm)
+		return PHY_IRQ_WAKE_NONE;
+
+	if (netdev->ethtool->wol_enabled)
+		return PHY_IRQ_WAKE_SYSTEM;
+
+	if (device_may_wakeup(&netdev->dev))
+		return PHY_IRQ_WAKE_NETDEV;
+
+	if (netdev->dev.parent && device_may_wakeup(netdev->dev.parent))
+		return PHY_IRQ_WAKE_PARENT;
+
+	return PHY_IRQ_WAKE_NONE;
+}
+
 /* Wakeup interrupts may occur during the system sleep transition when
  * the PHY is inaccessible. Set flag to postpone handling until the
  * transition ends. Wait for concurrent interrupt handler to complete.
@@ -341,7 +379,10 @@ static __maybe_unused void mdio_bus_phy_suspend_irq(struct phy_device *phydev)
 	if (!phy_interrupt_is_valid(phydev))
 		return;
 
-	WRITE_ONCE(phydev->irq_suspended, true);
+	/* A postponed handler cannot read the PHY: decide the event now */
+	phydev->irq_wake = phy_irq_wake_source(phydev);
+	/* Pairs with smp_load_acquire() in phy_interrupt() */
+	smp_store_release(&phydev->irq_suspended, true);
 	synchronize_irq(phydev->irq);
 }
 
@@ -369,11 +410,14 @@ static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 	struct phy_device *phydev = to_phy_device(dev);
 	int ret;
 
+	/* An interrupt can fire while the MAC has the MDIO bus powered
+	 * down, whether or not the MAC manages PHY PM.
+	 */
+	mdio_bus_phy_suspend_irq(phydev);
+
 	if (phydev->mac_managed_pm)
 		return 0;
 
-	mdio_bus_phy_suspend_irq(phydev);
-
 	/* We must stop the state machine manually, otherwise it stops out of
 	 * control, possibly with the phydev->lock held. Upon resume, netdev
 	 * may call phy routines that try to grab the same lock, and that may
@@ -406,8 +450,10 @@ static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
 	struct phy_device *phydev = to_phy_device(dev);
 	int ret;
 
-	if (phydev->mac_managed_pm)
+	if (phydev->mac_managed_pm) {
+		mdio_bus_phy_resume_irq(phydev);
 		return 0;
+	}
 
 	if (!phydev->suspended_by_mdio_bus)
 		goto no_resume;
@@ -2127,7 +2173,8 @@ int phy_suspend(struct phy_device *phydev)
 	if (phydev->suspended || !phydrv)
 		return 0;
 
-	phydev->wol_enabled = phy_may_wakeup(phydev) ||
+	phydev->wol_phy = phy_may_wakeup(phydev);
+	phydev->wol_enabled = phydev->wol_phy ||
 			      (netdev && netdev->ethtool->wol_enabled);
 	/* If the device has WOL enabled, we cannot suspend the PHY */
 	if (phydev->wol_enabled && !(phydrv->flags & PHY_ALWAYS_CALL_SUSPEND))
diff --git a/include/linux/phy.h b/include/linux/phy.h
index a2a4d318e334..b1fdc4504b68 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -573,6 +573,20 @@ struct phy_oatc14_sqi_capability {
 	u8 sqiplus_bits;
 };
 
+/**
+ * enum phy_irq_wake - wakeup event a postponed PHY interrupt reports
+ * @PHY_IRQ_WAKE_NONE: none
+ * @PHY_IRQ_WAKE_SYSTEM: pm_system_wakeup(), Wake-on-LAN is enabled
+ * @PHY_IRQ_WAKE_NETDEV: pm_wakeup_dev_event() for the attached netdev
+ * @PHY_IRQ_WAKE_PARENT: pm_wakeup_dev_event() for the netdev's parent
+ */
+enum phy_irq_wake {
+	PHY_IRQ_WAKE_NONE,
+	PHY_IRQ_WAKE_SYSTEM,
+	PHY_IRQ_WAKE_NETDEV,
+	PHY_IRQ_WAKE_PARENT,
+};
+
 /**
  * struct phy_device - An instance of a PHY
  *
@@ -600,6 +614,7 @@ struct phy_oatc14_sqi_capability {
  * @mac_managed_pm: Set true if MAC driver takes of suspending/resuming PHY
  * @wol_enabled: Set to true if the PHY or the attached MAC have Wake-on-LAN
  * 		 enabled.
+ * @wol_phy: Set to true if phy_suspend() found that the PHY may wake the system
  * @is_genphy_driven: PHY is driven by one of the generic PHY drivers
  * @state: State of the PHY for management purposes
  * @dev_flags: Device-specific flags used by the PHY driver.
@@ -649,9 +664,11 @@ struct phy_oatc14_sqi_capability {
  * @mdix_ctrl: User setting of crossover
  * @pma_extable: Cached value of PMA/PMD Extended Abilities Register
  * @interrupts: Flag interrupts have been enabled
- * @irq_suspended: Flag indicating PHY is suspended and therefore interrupt
- *                 handling shall be postponed until PHY has resumed
+ * @irq_suspended: Flag indicating a system sleep transition in progress, so
+ *                 interrupt handling shall be postponed until it ends
  * @irq_rerun: Set by the postponed interrupt that disabled the line
+ * @irq_wake: Wakeup event a postponed interrupt reports, decided by
+ *            mdio_bus_phy_suspend()
  * @irq_pm_lock: Serializes phy_free_interrupt() against the rerun of a
  *               postponed interrupt; never taken by phy_interrupt()
  * @default_timestamp: Flag indicating whether we are using the phy
@@ -716,6 +733,7 @@ struct phy_device {
 	unsigned is_on_sfp_module:1;
 	unsigned mac_managed_pm:1;
 	unsigned wol_enabled:1;
+	unsigned wol_phy:1;
 	unsigned is_genphy_driven:1;
 
 	unsigned autoneg:1;
@@ -730,6 +748,7 @@ struct phy_device {
 	/* Written without phydev->lock, so not bitfields */
 	bool irq_suspended;
 	bool irq_rerun;
+	enum phy_irq_wake irq_wake;
 	/* Serializes phy_free_interrupt() against mdio_bus_phy_resume_irq() */
 	struct mutex irq_pm_lock;
 

-- 
2.43.0

