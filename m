From: Willie Wiholm <willie.wiholm@tritechsolutions.se>
Date: Fri, 27 Nov 2026 19:44:57 +0100
Subject: [PATCH RFC net 2/2] net: phy: dp83867: clear latched WoL interrupt
 before suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-wol-net-v1-2-769a2aff91df@tritechsolutions.se>
References: <20261127-wol-net-v1-0-769a2aff91df@tritechsolutions.se>
In-Reply-To: <20261127-wol-net-v1-0-769a2aff91df@tritechsolutions.se>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Thomas Haemmerle <thomas.haemmerle@wolfvision.net>
Cc: netdev@vger.kernel.org, 
 Willie Wiholm <willie.wiholm@tritechsolutions.se>, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795805097; l=2183;
 i=willie.wiholm@tritechsolutions.se; s=20261127; h=from:subject:message-id;
 bh=OTu68TuDMbFEnIoadSFdiWgIpDYzTT9DBuTGVclx374=;
 b=K+6XR3DKmSbFx+H6GWP5nkkaPMLUcI58nSHrZYYxzLt9Y3KYkoqND/LRot5U4Zpc9a7/6tuXN
 gpnhZ5bODA+DDVYfEypo7h9VKIt0pahoY4PeJWGQw31j27vazdOMw/8
X-Developer-Key: i=willie.wiholm@tritechsolutions.se; a=ed25519;
 pk=+cNLoL8211zFctWUX7P+l/TZm0pSVfYhLugt3NOecW8=
X-Endpoint-Received: by B4 Relay for willie.wiholm@tritechsolutions.se/20261127 with auth_id=1669
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

WOL_INT in ISR is latched until ISR is read. When the PHY has no IRQ,
nothing reads ISR, so a magic packet received while the system is
running leaves the WoL interrupt pending and INT/PWDN_N asserted. The
next suspend then does not wake up on a magic packet, as the pin is
already active.

With WoL enabled, phy_suspend() does not call the driver's suspend
callback, so the driver has no chance to clear the interrupt. Set
PHY_ALWAYS_CALL_SUSPEND and, when WoL is enabled, only read ISR in
dp83867_suspend(). ISR is only read when the PHY has no IRQ, so that
pending interrupts are not lost when it has one. Without WoL the
behaviour is unchanged.

bcm54xx_suspend() acknowledges the WoL interrupt before suspend in the
same way.

Fixes: caabee5b53f5 ("net: phy: dp83867: support Wake on LAN")
Cc: stable@vger.kernel.org
Signed-off-by: Willie Wiholm <willie.wiholm@tritechsolutions.se>
---
 drivers/net/phy/dp83867.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/drivers/net/phy/dp83867.c b/drivers/net/phy/dp83867.c
index e3617f01b5d9..d997e10cd5ef 100644
--- a/drivers/net/phy/dp83867.c
+++ b/drivers/net/phy/dp83867.c
@@ -712,6 +712,22 @@ static int dp83867_of_init(struct phy_device *phydev)
 
 static int dp83867_suspend(struct phy_device *phydev)
 {
+	int ret;
+
+	/* The PHY must stay powered up for WoL. Without a PHY IRQ nothing
+	 * reads ISR, so a WoL event latched while the system was running
+	 * keeps INT/PWDN_N asserted and the next magic packet does not
+	 * wake the system. Clear it before suspend.
+	 */
+	if (phydev->wol_enabled) {
+		if (!phy_interrupt_is_valid(phydev)) {
+			ret = phy_read(phydev, MII_DP83867_ISR);
+			if (ret < 0)
+				return ret;
+		}
+		return 0;
+	}
+
 	/* Disable PHY Interrupts */
 	if (phy_interrupt_is_valid(phydev)) {
 		phydev->interrupts = PHY_INTERRUPT_DISABLED;
@@ -1274,6 +1290,7 @@ static struct phy_driver dp83867_driver[] = {
 		.phy_id_mask	= 0xfffffff0,
 		.name		= "TI DP83867",
 		/* PHY_GBIT_FEATURES */
+		.flags		= PHY_ALWAYS_CALL_SUSPEND,
 
 		.probe          = dp83867_probe,
 		.config_init	= dp83867_config_init,

-- 
2.43.0

