From: Igor Velkov <iav@iav.lv>
Date: Wed, 11 Nov 2026 23:48:21 +0000
Subject: [PATCH net v5 3/4] net: phy: stop postponing PHY interrupts when a
 PHY PM callback fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-b4-phylib-mac-pm-irq-v3-v5-3-bbfdb5afb7d3@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4173; i=iav@iav.lv;
 h=from:subject:message-id; bh=ufSlJR1JUWh6LMI/LBIHvZWnCZGjjT9SaXzc2rd3OA0=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlf/h2b/CJEz0j6Q4P2rmuzmK46PuP0Lr745mKsyDfut
 L1u9WxxHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiz6cx/K/Tb02WEuhxvTVj
 zQ+mM+XxVTJCS9nNupRV+7gTBSIa8hgZnn0S5JT5NeeXn+i2bSY/rHKDAxw/S0j9LIrYwB5byHq
 NEwA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When phy_suspend() fails in mdio_bus_phy_suspend(), irq_suspended
stays set and the state machine stays stopped: the PM core does not
resume a device whose suspend callback failed, and the next PHY
interrupt disables the line until the next resume. When phy_init_hw()
or phy_resume() fail, mdio_bus_phy_resume() returns before the rerun,
with irq_suspended set and a postponed interrupt left disabled.

Undo the postponing and restart the state machine when phy_suspend()
fails. When phy_init_hw() or phy_resume() fail, stop postponing too, but
leave a line that a postponed interrupt disabled off, as before this
patch: the PHY may be out of reach, and its handler could not quiet a
level-triggered source. The line comes back on the next successful
resume; phy_free_interrupt() gives it back to the other users of a
shared line, and a new request restarts it.

Fixes: 1758bde2e4aa ("net: phy: Don't trigger state machine while in suspend")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Haoning Cheng's Tested-by on v4 is not carried: a failed resume now
leaves the line disabled.
---
 drivers/net/phy/phy.c        |  2 +-
 drivers/net/phy/phy_device.c | 29 ++++++++++++++++++++++++-----
 2 files changed, 25 insertions(+), 6 deletions(-)

diff --git a/drivers/net/phy/phy.c b/drivers/net/phy/phy.c
index ea22ebb14a83..62b7f428f9da 100644
--- a/drivers/net/phy/phy.c
+++ b/drivers/net/phy/phy.c
@@ -1414,7 +1414,7 @@ static irqreturn_t phy_interrupt(int irq, void *phy_dat)
 	irqreturn_t ret;
 
 	/* Wakeup interrupts may occur during a system sleep transition.
-	 * Postpone handling until the PHY has resumed.
+	 * Postpone handling until the transition ends.
 	 */
 	if (IS_ENABLED(CONFIG_PM_SLEEP) && READ_ONCE(phydev->irq_suspended)) {
 		struct net_device *netdev = phydev->attached_dev;
diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index d3815ee21541..110c9dfcbd91 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -333,8 +333,8 @@ static bool mdio_bus_phy_may_suspend(struct phy_device *phydev)
 }
 
 /* Wakeup interrupts may occur during the system sleep transition when
- * the PHY is inaccessible. Set flag to postpone handling until the PHY
- * has resumed. Wait for concurrent interrupt handler to complete.
+ * the PHY is inaccessible. Set flag to postpone handling until the
+ * transition ends. Wait for concurrent interrupt handler to complete.
  */
 static __maybe_unused void mdio_bus_phy_suspend_irq(struct phy_device *phydev)
 {
@@ -367,6 +367,7 @@ static __maybe_unused void mdio_bus_phy_resume_irq(struct phy_device *phydev)
 static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 {
 	struct phy_device *phydev = to_phy_device(dev);
+	int ret;
 
 	if (phydev->mac_managed_pm)
 		return 0;
@@ -384,9 +385,20 @@ static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 	if (!mdio_bus_phy_may_suspend(phydev))
 		return 0;
 
+	ret = phy_suspend(phydev);
+	if (ret) {
+		/* The PM core skips the resume callback of a device whose
+		 * suspend callback failed.
+		 */
+		mdio_bus_phy_resume_irq(phydev);
+		if (phy_uses_state_machine(phydev))
+			phy_start_machine(phydev);
+		return ret;
+	}
+
 	phydev->suspended_by_mdio_bus = 1;
 
-	return phy_suspend(phydev);
+	return 0;
 }
 
 static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
@@ -412,11 +424,11 @@ static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
 
 	ret = phy_init_hw(phydev);
 	if (ret < 0)
-		return ret;
+		goto err;
 
 	ret = phy_resume(phydev);
 	if (ret < 0)
-		return ret;
+		goto err;
 no_resume:
 	mdio_bus_phy_resume_irq(phydev);
 
@@ -424,6 +436,13 @@ static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
 		phy_start_machine(phydev);
 
 	return 0;
+
+err:
+	/* Stop postponing, but leave a line that a postponed interrupt
+	 * disabled off: its handler may not reach a PHY that did not resume.
+	 */
+	WRITE_ONCE(phydev->irq_suspended, false);
+	return ret;
 }
 
 static SIMPLE_DEV_PM_OPS(mdio_bus_phy_pm_ops, mdio_bus_phy_suspend,

-- 
2.43.0

