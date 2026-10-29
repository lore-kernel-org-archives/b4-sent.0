From: Igor Velkov <iav@iav.lv>
Date: Thu, 29 Oct 2026 04:58:22 +0000
Subject: [PATCH net v3 2/2] net: phy: postpone PHY interrupts during sleep
 with MAC-managed PM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-b4-phylib-mac-pm-irq-v3-v3-2-5907045f3210@iav.lv>
References: <20261029-b4-phylib-mac-pm-irq-v3-v3-0-5907045f3210@iav.lv>
In-Reply-To: <20261029-b4-phylib-mac-pm-irq-v3-v3-0-5907045f3210@iav.lv>
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
 Thangaraj Samynathan <Thangaraj.S@microchip.com>, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=7353; i=iav@iav.lv;
 h=from:subject:message-id; bh=0jzCIm6lJ2Yfq40Vke+VWeHqxr3HXaFj0zXIYFJcMKg=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmPLuW7t64JS/wouEtVRsxlgreRyNKEN4Ephcl5wn4+i
 1mqRV06SlkYxLgYZMUUWSYc0riVseTqX38P8wcwc1iZQIYwcHEKwETaehgZ9jknf1te5tCpZLJ6
 6/6eV8o8fuazu6Zn+n/QesbXLbZ8MsN//y9/tsetfy2x5ts25waGq0nFbwt0+mLy0x5x6R6+WFr
 DCAA=
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

On Helios64 (dwmac-rk, RTL8211F with its interrupt line described in
DT) both hang the board: the handler reads INSR while the GMAC clocks
are off, after rk_gmac_suspend() or before rk_gmac_resume().

Set irq_suspended for these PHYs too. The PHY device is a child of its
MDIO bus, so mdio_bus_phy_resume() runs after the bus is back (with
stmmac, after the MAC) and replays the postponed interrupt then.
phy_suspend(), phy_resume() and the state machine stay with the MAC
driver. An interrupt in that window signals a wakeup event only if
Wake-on-LAN is enabled: the MAC powers the PHY down itself, and the
link interrupt that follows must not abort suspend just because the MAC
device may wake the system.

MAC drivers that close the interface in suspend free the interrupt
before the PHY resumes. The PHY is still reachable there, so
phy_free_interrupt() stops postponing and re-enables a line left
disabled by a postponed interrupt before it frees its handler.

Tested on Helios64 with 7.3, s2idle with the link up:
- no Wake-on-LAN, GMAC clocks off in suspend: 10 of 10 cycles suspended
  and resumed; without this series the same test hung or reset the
  board after the link went down 10 of 10 times;
- MAC power/wakeup enabled, no Wake-on-LAN: 3 of 3 slept;
- Wake-on-LAN in the PHY: a magic packet woke the board 3 of 3 times.

Fixes: 1758bde2e4aa ("net: phy: Don't trigger state machine while in suspend")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/net/phy/phy.c        | 19 +++++++++++++++++--
 drivers/net/phy/phy_device.c | 44 +++++++++++++++++++++++++++-----------------
 include/linux/phy.h          |  5 +++--
 3 files changed, 47 insertions(+), 21 deletions(-)

diff --git a/drivers/net/phy/phy.c b/drivers/net/phy/phy.c
index 9af303d60bd6..c3863a72a5da 100644
--- a/drivers/net/phy/phy.c
+++ b/drivers/net/phy/phy.c
@@ -1421,12 +1421,16 @@ static irqreturn_t phy_interrupt(int irq, void *phy_dat)
 
 		if (netdev) {
 			struct device *parent = netdev->dev.parent;
+			/* Without WoL, a MAC that manages PHY PM takes the
+			 * link down itself: that interrupt is not a wakeup.
+			 */
+			bool may_wake = !phydev->mac_managed_pm;
 
 			if (netdev->ethtool->wol_enabled)
 				pm_system_wakeup();
-			else if (device_may_wakeup(&netdev->dev))
+			else if (may_wake && device_may_wakeup(&netdev->dev))
 				pm_wakeup_dev_event(&netdev->dev, 0, true);
-			else if (parent && device_may_wakeup(parent))
+			else if (may_wake && parent && device_may_wakeup(parent))
 				pm_wakeup_dev_event(parent, 0, true);
 		}
 
@@ -1507,6 +1511,17 @@ EXPORT_SYMBOL(phy_request_interrupt);
 void phy_free_interrupt(struct phy_device *phydev)
 {
 	phy_disable_interrupts(phydev);
+
+	/* The PHY is reachable: stop postponing, and while our handler is still
+	 * registered re-enable a line that a postponed interrupt left disabled.
+	 */
+	phydev->irq_suspended = false;
+	synchronize_irq(phydev->irq);
+	if (phydev->irq_rerun) {
+		phydev->irq_rerun = false;
+		enable_irq(phydev->irq);
+	}
+
 	free_irq(phydev->irq, phydev);
 }
 EXPORT_SYMBOL(phy_free_interrupt);
diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 79dba43d703a..7d1486185070 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -336,18 +336,20 @@ static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 {
 	struct phy_device *phydev = to_phy_device(dev);
 
-	if (phydev->mac_managed_pm)
-		return 0;
-
 	/* Wakeup interrupts may occur during the system sleep transition when
 	 * the PHY is inaccessible. Set flag to postpone handling until the PHY
 	 * has resumed. Wait for concurrent interrupt handler to complete.
+	 * This holds when the MAC manages PHY PM too: an interrupt can still
+	 * fire while the MAC has the MDIO bus powered down.
 	 */
 	if (phy_interrupt_is_valid(phydev)) {
 		phydev->irq_suspended = true;
 		synchronize_irq(phydev->irq);
 	}
 
+	if (phydev->mac_managed_pm)
+		return 0;
+
 	/* We must stop the state machine manually, otherwise it stops out of
 	 * control, possibly with the phydev->lock held. Upon resume, netdev
 	 * may call phy routines that try to grab the same lock, and that may
@@ -364,13 +366,33 @@ static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 	return phy_suspend(phydev);
 }
 
+static __maybe_unused void mdio_bus_phy_resume_irq(struct phy_device *phydev)
+{
+	if (!phy_interrupt_is_valid(phydev))
+		return;
+
+	phydev->irq_suspended = false;
+	synchronize_irq(phydev->irq);
+
+	/* Rerun interrupts which were postponed by phy_interrupt()
+	 * because they occurred during the system sleep transition.
+	 */
+	if (phydev->irq_rerun) {
+		phydev->irq_rerun = false;
+		enable_irq(phydev->irq);
+		irq_wake_thread(phydev->irq, phydev);
+	}
+}
+
 static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
 {
 	struct phy_device *phydev = to_phy_device(dev);
 	int ret;
 
-	if (phydev->mac_managed_pm)
+	if (phydev->mac_managed_pm) {
+		mdio_bus_phy_resume_irq(phydev);
 		return 0;
+	}
 
 	if (!phydev->suspended_by_mdio_bus)
 		goto no_resume;
@@ -393,19 +415,7 @@ static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
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
diff --git a/include/linux/phy.h b/include/linux/phy.h
index 0e0066186ba2..bb62a80d6a30 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -649,8 +649,9 @@ struct phy_oatc14_sqi_capability {
  * @mdix_ctrl: User setting of crossover
  * @pma_extable: Cached value of PMA/PMD Extended Abilities Register
  * @interrupts: Flag interrupts have been enabled
- * @irq_suspended: Flag indicating PHY is suspended and therefore interrupt
- *                 handling shall be postponed until PHY has resumed
+ * @irq_suspended: Flag indicating a system sleep transition in progress, so
+ *                 interrupt handling shall be postponed until
+ *                 mdio_bus_phy_resume()
  * @irq_rerun: Flag indicating interrupts occurred while PHY was suspended,
  *             requiring a rerun of the interrupt handler after resume
  * @default_timestamp: Flag indicating whether we are using the phy

-- 
2.43.0

