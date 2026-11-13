From: Igor Velkov <iav@iav.lv>
Date: Fri, 13 Nov 2026 21:06:37 +0000
Subject: [PATCH net v6 3/4] net: phy: stop postponing PHY interrupts when
 phy_suspend() fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-b4-phylib-mac-pm-irq-v3-v6-3-05af2503cb23@iav.lv>
References: <20261113-b4-phylib-mac-pm-irq-v3-v6-0-05af2503cb23@iav.lv>
In-Reply-To: <20261113-b4-phylib-mac-pm-irq-v3-v6-0-05af2503cb23@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2032; i=iav@iav.lv;
 h=from:subject:message-id; bh=5VvbAr93FGmELOk5YU+LU+0e2l85PgvFDy/Bv6Z+ybI=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnfq+8preMt/Pyy4Hnk/fmsp+vKI1cYBFXbZ3H2qtufe
 Tzh/MbgjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCRr6sYGe43mfCkVc57W2F/
 480FoZ8FUS9d1Fs2JF/583/ZhASeuNUM/6v3vHeJu/84e5W6eChDle+s7b7s7A/nSORdCJH56/h
 zMRcA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When phy_suspend() fails in mdio_bus_phy_suspend(), irq_suspended
stays set and the state machine stays stopped: the PM core does not
resume a device whose suspend callback failed, and the next PHY
interrupt disables the line until the next resume.

Undo the postponing and restart the state machine when phy_suspend()
fails. Set suspended_by_mdio_bus only after phy_suspend() succeeds.
Set before it, the flag outlived a failed suspend, and in a later cycle
where mdio_bus_phy_may_suspend() returns false, mdio_bus_phy_resume()
ran phy_init_hw() and phy_resume() on a PHY that the MDIO bus had not
suspended.

Fixes: 1758bde2e4aa ("net: phy: Don't trigger state machine while in suspend")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Haoning Cheng's Tested-by on v5 is not carried: this patch no longer
changes the resume error path.
---
 drivers/net/phy/phy_device.c | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 573eb234dc79..39e232a3144a 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
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

-- 
2.43.0

