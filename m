From: Igor Velkov <iav@iav.lv>
Date: Sat, 31 Oct 2026 08:01:15 +0000
Subject: [PATCH net v4 4/5] net: phy: stop postponing PHY interrupts when a
 PHY PM callback fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-b4-phylib-mac-pm-irq-v3-v4-4-5ba23b3ff9a4@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2660; i=iav@iav.lv;
 h=from:subject:message-id; bh=AMBusW+D9sd+roS3h8dA/iGRRagd/TAxSjS7ZWRcGGw=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlPF3irMb5Zbvn0dEa+JufUGSYN4e9/vE1/Kbyjonnyy
 rRMh81vOkpZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBE1kxk+KdTfeHms7wHzzve
 nNXjFgqJuPnYU363yKwDB5PvhAtE9tgwMryc4fMlQq/LfOtNw5/V33aeuK7+wS1tP3PkBvaqmWc
 XX+YFAA==
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
fails, and rerun the postponed interrupt when phy_init_hw() or
phy_resume() fail, which gives the line back to the other users of a
shared line. A handler that then cannot read the PHY reports it through
phy_error(), as most PHY drivers do on any MDIO error.

Fixes: 1758bde2e4aa ("net: phy: Don't trigger state machine while in suspend")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/net/phy/phy_device.c | 22 +++++++++++++++++++---
 1 file changed, 19 insertions(+), 3 deletions(-)

diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index ef5e1cd3a831..390069ec13ca 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -366,6 +366,7 @@ static __maybe_unused void mdio_bus_phy_resume_irq(struct phy_device *phydev)
 static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 {
 	struct phy_device *phydev = to_phy_device(dev);
+	int ret;
 
 	if (phydev->mac_managed_pm)
 		return 0;
@@ -383,9 +384,20 @@ static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
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
@@ -411,11 +423,11 @@ static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
 
 	ret = phy_init_hw(phydev);
 	if (ret < 0)
-		return ret;
+		goto err_resume_irq;
 
 	ret = phy_resume(phydev);
 	if (ret < 0)
-		return ret;
+		goto err_resume_irq;
 no_resume:
 	mdio_bus_phy_resume_irq(phydev);
 
@@ -423,6 +435,10 @@ static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
 		phy_start_machine(phydev);
 
 	return 0;
+
+err_resume_irq:
+	mdio_bus_phy_resume_irq(phydev);
+	return ret;
 }
 
 static SIMPLE_DEV_PM_OPS(mdio_bus_phy_pm_ops, mdio_bus_phy_suspend,

-- 
2.43.0

