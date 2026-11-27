From: Willie Wiholm <willie.wiholm@tritechsolutions.se>
Date: Fri, 27 Nov 2026 19:44:56 +0100
Subject: [PATCH RFC net 1/2] net: phy: dp83867: set INT_OE when enabling
 Wake-on-LAN
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-wol-net-v1-1-769a2aff91df@tritechsolutions.se>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795805097; l=2238;
 i=willie.wiholm@tritechsolutions.se; s=20261127; h=from:subject:message-id;
 bh=B87NcVtP8Gbvppa+UGSk6FssaUMl/qL287zqyqf5hJM=;
 b=897rzI3isKP0tS/ULgHWxEmbuqqUDUWhC52++aHyXiF+YZ8xEcDarLvBHO4C+CaV/Fw73uSCr
 KtGYGDnv8JMAV30Rr+Sqo11LEuY51msyXjLgkL4zdBSs5uLw/laNHai
X-Developer-Key: i=willie.wiholm@tritechsolutions.se; a=ed25519;
 pk=+cNLoL8211zFctWUX7P+l/TZm0pSVfYhLugt3NOecW8=
X-Endpoint-Received: by B4 Relay for willie.wiholm@tritechsolutions.se/20261127 with auth_id=1669
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dp83867_set_wol() enables the WoL interrupt in MICR, so a detected
magic packet is signalled on the INT/PWDN_N pin. That pin is only an
interrupt output when CFG3.INT_OE is set, and dp83867_config_init()
sets INT_OE only when the PHY has a valid IRQ. Otherwise the pin stays
a power-down input and the WoL event never leaves the PHY.

This happens on Intel Elkhart Lake boards with dwmac-intel, where the
PHY is polled (no PHY IRQ in Linux) and INT/PWDN_N is wired to the MAC,
which raises PME to wake the system.

The firmware on such a board (congatec conga-SA7) sets INT_OE, but the
global soft reset in dp83867_phy_reset() clears it on every attach. As
a result the first suspend after boot or after a link down/up never
wakes up. Later suspends do wake, because the firmware sets INT_OE
again on S3 resume, which makes the bug look intermittent.

Set INT_OE when WoL is enabled. When WoL is disabled, clear it again
if the PHY has no IRQ, restoring the reset default. PHYs with a valid
IRQ already have INT_OE set, so nothing changes for them.

Fixes: caabee5b53f5 ("net: phy: dp83867: support Wake on LAN")
Cc: stable@vger.kernel.org
Signed-off-by: Willie Wiholm <willie.wiholm@tritechsolutions.se>
---
 drivers/net/phy/dp83867.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/net/phy/dp83867.c b/drivers/net/phy/dp83867.c
index b4b4931c6f8c..e3617f01b5d9 100644
--- a/drivers/net/phy/dp83867.c
+++ b/drivers/net/phy/dp83867.c
@@ -233,6 +233,8 @@ static int dp83867_set_wol(struct phy_device *phydev,
 			    WAKE_BCAST)) {
 		val_rxcfg |= DP83867_WOL_ENH_MAC;
 		val_micr |= MII_DP83867_MICR_WOL_INT_EN;
+		/* WoL is signalled on INT/PWDN_N which must be an output */
+		phy_set_bits(phydev, DP83867_CFG3, DP83867_CFG3_INT_OE);
 
 		if (wol->wolopts & WAKE_MAGIC) {
 			mac = (const u8 *)ndev->dev_addr;
@@ -277,6 +279,8 @@ static int dp83867_set_wol(struct phy_device *phydev,
 	} else {
 		val_rxcfg &= ~DP83867_WOL_ENH_MAC;
 		val_micr &= ~MII_DP83867_MICR_WOL_INT_EN;
+		if (!phy_interrupt_is_valid(phydev))
+			phy_clear_bits(phydev, DP83867_CFG3, DP83867_CFG3_INT_OE);
 	}
 
 	phy_write_mmd(phydev, DP83867_DEVADDR, DP83867_RXFCFG, val_rxcfg);

-- 
2.43.0

