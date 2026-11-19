From: Igor Velkov <iav@iav.lv>
Date: Thu, 19 Nov 2026 07:24:01 +0000
Subject: [PATCH net v7 5/5] net: phy: postpone PHY interrupts during sleep
 with MAC-managed PM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-b4-phylib-mac-pm-irq-v3-v7-5-d8b8f43b5a62@iav.lv>
References: <20261119-b4-phylib-mac-pm-irq-v3-v7-0-d8b8f43b5a62@iav.lv>
In-Reply-To: <20261119-b4-phylib-mac-pm-irq-v3-v7-0-d8b8f43b5a62@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=10701; i=iav@iav.lv;
 h=from:subject:message-id; bh=BYqkLelIj0GKD5GRd5jre2P8EBEqvvGdLu7U85SLWvg=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFn/lghV/LV4FyTz+6XEfK3FyoJLj+aklLy8fc7S8+KRy
 udaK7ptOkpZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBEYqYw/GK6c67m016xH1vO
 /jfZFfpzWtK6B702l84teGzV5GXG62vE8N/jivxDPuEUNufQuNx9sx/smTnX1KVUrmr+n5XBHBX
 xcdwA
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
bus up, the replay still reaches the bus. When the PHY sits on an MDIO
bus the MAC does not own, phy_attach_direct() links the MAC as a
consumer of the PHY, so the MAC suspends before and resumes after the
PHY; there the replay still runs before the MAC resumes, as the handler did
from resume_device_irqs() before this change, and until the PHY
suspends, an interrupt still runs the handler after the MAC has
suspended. ODROID-HC4 (stmmac, RTL8211F behind mdio-mux-meson-g12a)
takes this path. phy_suspend(), phy_resume() and the state machine stay
with the MAC driver, and no MAC driver needs a change. Doing this in
phylink_suspend() instead would miss macb, which sets mac_managed_pm but
suspends with phylink_stop().

A postponed interrupt cannot read the PHY, so it cannot tell Wake-on-LAN
from a link change. A PHY without MAC-managed PM reports what
phy_interrupt() reports today. A PHY with MAC-managed PM reports no
wakeup from the postponed interrupt: the MAC can change the link in its
suspend callback, as stmmac lowers the link speed through
phylink_suspend() when the PHY may wake the system.

A postponed interrupt leaves its line disabled. suspend_device_irqs()
runs before the noirq callbacks: it arms a wakeup line and leaves a
disabled one masked unless the irqchip has
IRQCHIP_ENABLE_WAKEUP_ON_SUSPEND, so a PHY whose interrupt line is also
its wake IRQ would sleep through a wakeup. Enable the line a postponed
interrupt disabled in the noirq suspend callback while it is still
disabled and armed for wakeup, and disable it again in the noirq resume
callback, before resume_device_irqs(). The irq core turns an interrupt
on an armed line into a wakeup without running the handler, and clears
the armed state before it disables the line, so a line that already
woke the system is left alone, and so is a line that is no longer
disabled. An edge the postponed interrupt consumed does not repeat, so
on an edge-triggered line a magic packet that arrives during the
transition does not abort it; the next one wakes the system. On a
level-triggered line, a PHY that keeps a link interrupt asserted, such
as the one from the speed change above, aborts every suspend with
Wake-on-LAN enabled: its driver has to restrict the interrupt to
Wake-on-LAN in its suspend callback, as rtl8211f_suspend() does.

Tested on Helios64 with 7.3.5 and this series, s2idle with the link up:
- no Wake-on-LAN, GMAC clocks off in suspend: 10 of 10 cycles suspended
  and resumed; on 7.3 without this series the same test hung or reset
  the board after the link went down 10 of 10 times;
- MAC power/wakeup enabled, no Wake-on-LAN: 3 of 3 slept;
- Wake-on-LAN in the PHY, so phylink_suspend() also drops the link
  speed: a magic packet woke the board 7 of 8 times, no suspend
  aborted; in the eighth the PHY raised no interrupt, cause not found;
- the same under a flood of magic packets: a packet after
  rtl8211f_suspend() was postponed and disabled the line, the noirq
  callback enabled it, and the wakeup aborted the suspend 5 of 5 times
  (traced); a single magic packet then woke the board.

Fixes: 1758bde2e4aa ("net: phy: Don't trigger state machine while in suspend")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Haoning Cheng's Tested-by on v5 is not carried: MAC-managed PHYs no
longer report a wakeup.
---
 drivers/net/phy/phy.c        | 13 ++++++++---
 drivers/net/phy/phy_device.c | 54 ++++++++++++++++++++++++++++++++++++++++----
 include/linux/phy.h          |  7 ++++--
 3 files changed, 64 insertions(+), 10 deletions(-)

diff --git a/drivers/net/phy/phy.c b/drivers/net/phy/phy.c
index 6cc94b525e09..45891570a56e 100644
--- a/drivers/net/phy/phy.c
+++ b/drivers/net/phy/phy.c
@@ -1419,7 +1419,10 @@ static irqreturn_t phy_interrupt(int irq, void *phy_dat)
 	if (IS_ENABLED(CONFIG_PM_SLEEP) && READ_ONCE(phydev->irq_suspended)) {
 		struct net_device *netdev = phydev->attached_dev;
 
-		if (netdev) {
+		/* With MAC-managed PM, a postponed interrupt cannot tell
+		 * Wake-on-LAN from a link change the MAC causes.
+		 */
+		if (netdev && !phydev->mac_managed_pm) {
 			struct device *parent = netdev->dev.parent;
 
 			if (netdev->ethtool->wol_enabled)
@@ -1486,8 +1489,10 @@ void phy_request_interrupt(struct phy_device *phydev)
 
 	/* A line without users restarts at depth 0, so our disable is gone */
 	mutex_lock(&phydev->irq_pm_lock);
-	if (phydev->irq_rerun && !irq_has_action(phydev->irq_rerun_line))
+	if (phydev->irq_rerun && !irq_has_action(phydev->irq_rerun_line)) {
 		phydev->irq_rerun = false;
+		phydev->irq_wake_enabled = false;
+	}
 	mutex_unlock(&phydev->irq_pm_lock);
 
 	err = request_threaded_irq(phydev->irq, NULL, phy_interrupt,
@@ -1522,8 +1527,10 @@ void phy_free_interrupt(struct phy_device *phydev)
 	/* free_irq() shuts down a line left without users and the next request
 	 * resets its depth; mdio_bus_phy_resume_irq() enables a shared line.
 	 */
-	if (!irq_has_action(phydev->irq))
+	if (!irq_has_action(phydev->irq)) {
 		phydev->irq_rerun = false;
+		phydev->irq_wake_enabled = false;
+	}
 	mutex_unlock(&phydev->irq_pm_lock);
 }
 EXPORT_SYMBOL(phy_free_interrupt);
diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 8bc394ff7d2d..c700b34e40a2 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -18,6 +18,7 @@
 #include <linux/init.h>
 #include <linux/interrupt.h>
 #include <linux/io.h>
+#include <linux/irq.h>
 #include <linux/kernel.h>
 #include <linux/list.h>
 #include <linux/mdio.h>
@@ -377,11 +378,14 @@ static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
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
@@ -414,8 +418,10 @@ static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
 	struct phy_device *phydev = to_phy_device(dev);
 	int ret;
 
-	if (phydev->mac_managed_pm)
+	if (phydev->mac_managed_pm) {
+		mdio_bus_phy_resume_irq(phydev);
 		return 0;
+	}
 
 	if (!phydev->suspended_by_mdio_bus)
 		goto no_resume;
@@ -446,8 +452,46 @@ static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
 	return 0;
 }
 
-static SIMPLE_DEV_PM_OPS(mdio_bus_phy_pm_ops, mdio_bus_phy_suspend,
-			 mdio_bus_phy_resume);
+static __maybe_unused int mdio_bus_phy_suspend_noirq(struct device *dev)
+{
+	struct phy_device *phydev = to_phy_device(dev);
+	struct irq_data *d;
+
+	mutex_lock(&phydev->irq_pm_lock);
+	/* We enable the line a postponed interrupt disabled if the irq core
+	 * armed it for wakeup, so that it wakes the system.
+	 */
+	if (phydev->irq_rerun) {
+		d = irq_get_irq_data(phydev->irq_rerun_line);
+		if (d && irqd_irq_disabled(d) && irqd_is_wakeup_armed(d)) {
+			enable_irq(phydev->irq_rerun_line);
+			phydev->irq_wake_enabled = true;
+		}
+	}
+	mutex_unlock(&phydev->irq_pm_lock);
+
+	return 0;
+}
+
+static __maybe_unused int mdio_bus_phy_resume_noirq(struct device *dev)
+{
+	struct phy_device *phydev = to_phy_device(dev);
+
+	mutex_lock(&phydev->irq_pm_lock);
+	if (phydev->irq_wake_enabled) {
+		phydev->irq_wake_enabled = false;
+		disable_irq_nosync(phydev->irq_rerun_line);
+	}
+	mutex_unlock(&phydev->irq_pm_lock);
+
+	return 0;
+}
+
+static const struct dev_pm_ops mdio_bus_phy_pm_ops = {
+	SET_SYSTEM_SLEEP_PM_OPS(mdio_bus_phy_suspend, mdio_bus_phy_resume)
+	SET_NOIRQ_SYSTEM_SLEEP_PM_OPS(mdio_bus_phy_suspend_noirq,
+				      mdio_bus_phy_resume_noirq)
+};
 
 /**
  * genphy_match_phy_device - match a PHY device with a PHY driver
diff --git a/include/linux/phy.h b/include/linux/phy.h
index f370690d62a7..74acbb15ef7b 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -649,10 +649,12 @@ struct phy_oatc14_sqi_capability {
  * @mdix_ctrl: User setting of crossover
  * @pma_extable: Cached value of PMA/PMD Extended Abilities Register
  * @interrupts: Flag interrupts have been enabled
- * @irq_suspended: Flag indicating PHY is suspended and therefore interrupt
- *                 handling shall be postponed until PHY has resumed
+ * @irq_suspended: Flag indicating a system sleep transition, so interrupt
+ *                 handling shall be postponed until the PHY has resumed
  * @irq_rerun: Set by the postponed interrupt that disabled the line
  * @irq_rerun_line: The line the postponed interrupt disabled
+ * @irq_wake_enabled: Set while @irq_rerun_line is enabled for the noirq
+ *                    phase, as it wakes the system
  * @default_timestamp: Flag indicating whether we are using the phy
  *		       timestamp as the default one
  * @interface: enum phy_interface_t value
@@ -734,6 +736,7 @@ struct phy_device {
 	bool irq_suspended;
 	bool irq_rerun;
 	int irq_rerun_line;
+	bool irq_wake_enabled;
 
 	unsigned default_timestamp:1;
 

-- 
2.43.0

