From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Tue, 04 Mar 2025 19:37:26 +0100
Subject: [PATCH net-next v2 1/2] net: phy: tja11xx: add support for
 TJA1102S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250304-tja1102s-support-v2-1-cd3e61ab920f@liebherr.com>
References: <20250304-tja1102s-support-v2-0-cd3e61ab920f@liebherr.com>
In-Reply-To: <20250304-tja1102s-support-v2-0-cd3e61ab920f@liebherr.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, Marek Vasut <marex@denx.de>, 
 Oleksij Rempel <o.rempel@pengutronix.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741113448; l=2412;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=y/3Zxepwsaqd2jpN3C4CZmIRRD7IQrec5wOpGQfwzi4=;
 b=iBq4ApaWGp44G40Pkl0W63THM7SFgzJd445ADM/7ANAcu+tvf5p0l3MJHEwnEdTx5JQw9XVZ1
 f1kfZnDIcsYCRzUBs/eNkGtHpt+bMrGVcXh24reYd2aCvrhj9U0rFS0
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

NXPs TJA1102S is a single PHY version of the TJA1102 in which one of the
PHYs is disabled.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/nxp-tja11xx.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/drivers/net/phy/nxp-tja11xx.c b/drivers/net/phy/nxp-tja11xx.c
index ed7fa26bac8e83f43d6d656e2e2812e501111eb0..9cf5e6d32fab88cae5cd556623a9ffa285227ab6 100644
--- a/drivers/net/phy/nxp-tja11xx.c
+++ b/drivers/net/phy/nxp-tja11xx.c
@@ -21,6 +21,7 @@
 #define PHY_ID_TJA1100			0x0180dc40
 #define PHY_ID_TJA1101			0x0180dd00
 #define PHY_ID_TJA1102			0x0180dc80
+#define PHY_ID_TJA1102S			0x0180dc90
 
 #define MII_ECTRL			17
 #define MII_ECTRL_LINK_CONTROL		BIT(15)
@@ -316,6 +317,7 @@ static int tja11xx_config_init(struct phy_device *phydev)
 		if (ret)
 			return ret;
 		break;
+	case PHY_ID_TJA1102S:
 	case PHY_ID_TJA1101:
 		reg_mask = MII_CFG1_INTERFACE_MODE_MASK;
 		ret = tja11xx_get_interface_mode(phydev);
@@ -883,6 +885,29 @@ static struct phy_driver tja11xx_driver[] = {
 		.handle_interrupt = tja11xx_handle_interrupt,
 		.cable_test_start = tja11xx_cable_test_start,
 		.cable_test_get_status = tja11xx_cable_test_get_status,
+	}, {
+		PHY_ID_MATCH_MODEL(PHY_ID_TJA1102S),
+		.name		= "NXP TJA1102S",
+		.features       = PHY_BASIC_T1_FEATURES,
+		.flags          = PHY_POLL_CABLE_TEST,
+		.probe		= tja11xx_probe,
+		.soft_reset	= tja11xx_soft_reset,
+		.config_aneg	= tja11xx_config_aneg,
+		.config_init	= tja11xx_config_init,
+		.read_status	= tja11xx_read_status,
+		.get_sqi	= tja11xx_get_sqi,
+		.get_sqi_max	= tja11xx_get_sqi_max,
+		.suspend	= genphy_suspend,
+		.resume		= genphy_resume,
+		.set_loopback   = genphy_loopback,
+		/* Statistics */
+		.get_sset_count = tja11xx_get_sset_count,
+		.get_strings	= tja11xx_get_strings,
+		.get_stats	= tja11xx_get_stats,
+		.config_intr	= tja11xx_config_intr,
+		.handle_interrupt = tja11xx_handle_interrupt,
+		.cable_test_start = tja11xx_cable_test_start,
+		.cable_test_get_status = tja11xx_cable_test_get_status,
 	}
 };
 
@@ -892,6 +917,7 @@ static const struct mdio_device_id __maybe_unused tja11xx_tbl[] = {
 	{ PHY_ID_MATCH_MODEL(PHY_ID_TJA1100) },
 	{ PHY_ID_MATCH_MODEL(PHY_ID_TJA1101) },
 	{ PHY_ID_MATCH_MODEL(PHY_ID_TJA1102) },
+	{ PHY_ID_MATCH_MODEL(PHY_ID_TJA1102S) },
 	{ }
 };
 

-- 
2.39.5

