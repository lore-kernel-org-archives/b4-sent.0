From: Igor Velkov <iav@iav.lv>
Date: Mon, 23 Nov 2026 00:46:15 +0000
Subject: [PATCH net v8 3/5] net: phy: stop postponing PHY interrupts when
 phy_suspend() fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-phylib-mac-pm-irq-v3-v8-3-e9f706e79614@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2342; i=iav@iav.lv;
 h=from:subject:message-id; bh=uRMMA0Q2puJNX3mPj5NSRgKeAYrUSBenrydqXPVYlvM=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNnMPTcunbzVGP1OpeTbgvawfYxi57IlgpU/MQg4/Two6
 XRPVXB7RykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZiI5GyG/8Er+nccNVhetqpN
 yupD+yHR8gMWbvE3ApMnTtGfw/rywU6G3yweXLbbD9j+VhK/FrBpk49ugWSyqsuTJkGlO3ru06x
 iuAA=
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

The error returns of mdio_bus_phy_resume(), after phy_init_hw() or
phy_resume() failed, stay as they are: the postponing goes on, and a
line that a postponed interrupt disabled stays disabled. Undoing the
postponing there would run the handler, from the next interrupt on, on
a PHY that did not resume.

Fixes: 1758bde2e4aa ("net: phy: Don't trigger state machine while in suspend")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Haoning Cheng's Tested-by on v5 is not carried: this patch no longer
changes the resume error path.
---
 drivers/net/phy/phy_device.c | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index f2e2370b4be7..2d2058c29f30 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -368,6 +368,7 @@ static __maybe_unused void mdio_bus_phy_resume_irq(struct phy_device *phydev)
 static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 {
 	struct phy_device *phydev = to_phy_device(dev);
+	int ret;
 
 	if (phydev->mac_managed_pm)
 		return 0;
@@ -385,9 +386,20 @@ static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
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

