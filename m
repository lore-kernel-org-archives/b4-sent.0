From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Mon, 29 Jun 2026 10:23:40 -0700
Subject: [PATCH net-next v6 10/15] net: phy: ncn26000: Enable enhanced
 noise immunity
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-s2500-mac-phy-support-v6-10-18ce79500371@onsemi.com>
References: <20260629-s2500-mac-phy-support-v6-0-18ce79500371@onsemi.com>
In-Reply-To: <20260629-s2500-mac-phy-support-v6-0-18ce79500371@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782753817; l=2584;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=5Na9s+cgIKrW+MuMHZXvz2w+TLk9Kzp/wuujDQ4F5mo=;
 b=tHDOWlX0pR4+1kGSK9PL3rYopWgvnclQIQBYTmaoUubEXimLKemCDkx5yFYl/wnMKl9juhlaS
 Qh4YO79rLj1D2YjTIatMYB92udcEImN+xVQLIG9exzia5xsrUVSgUd/
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

By setting ENI bit, noise immunity is improved and it is
specifically meant for PLCA enabled nodes.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v6
  - No change
changes in v5
  - No changes
changes in v4
  - No changes
changes in v3
  - Moved as a separate patch
---
 drivers/net/phy/ncn26000.c | 26 ++++++++++++++++++++++++--
 1 file changed, 24 insertions(+), 2 deletions(-)

diff --git a/drivers/net/phy/ncn26000.c b/drivers/net/phy/ncn26000.c
index 2c8601c3f94a..c3a34b2c524d 100644
--- a/drivers/net/phy/ncn26000.c
+++ b/drivers/net/phy/ncn26000.c
@@ -36,6 +36,10 @@
 
 #define TO_TMR_DEFAULT			32
 
+#define NCN26000_REG_PHYCFG1		0x8001
+#define NCN26000_PHYCFG1_ENI		BIT(7)
+#define NCN26000_PHYCFG1_ENI_MASK	BIT(7)
+
 static int ncn26000_config_init(struct phy_device *phydev)
 {
 	int ret = 0;
@@ -106,6 +110,24 @@ static int ncn26000_read_status(struct phy_device *phydev)
 	return 0;
 }
 
+/* Intercept PLCA enable/disable request to
+ * set the proprietary, ENI mode accordingly
+ */
+static int ncn26000_c45_plca_set_cfg(struct phy_device *phydev,
+				     const struct phy_plca_cfg *plca_cfg)
+{
+	int ret = genphy_c45_plca_set_cfg(phydev, plca_cfg);
+	u16 eni_cfg = 0;
+
+	if (ret || plca_cfg->enabled < 0)
+		return ret;
+
+	eni_cfg = (plca_cfg->enabled) ? NCN26000_PHYCFG1_ENI : 0;
+	return phy_modify_mmd(phydev, MDIO_MMD_VEND2,
+			      NCN26000_REG_PHYCFG1,
+			      NCN26000_PHYCFG1_ENI_MASK, eni_cfg);
+}
+
 static irqreturn_t ncn26000_handle_interrupt(struct phy_device *phydev)
 {
 	int ret;
@@ -156,7 +178,7 @@ static struct phy_driver ncn26000_driver[] = {
 		.config_aneg           = ncn26000_config_aneg,
 		.read_status           = ncn26000_read_status,
 		.handle_interrupt      = ncn26000_handle_interrupt,
-		.set_plca_cfg          = genphy_c45_plca_set_cfg,
+		.set_plca_cfg          = ncn26000_c45_plca_set_cfg,
 		.get_plca_cfg          = genphy_c45_plca_get_cfg,
 		.get_plca_status       = genphy_c45_plca_get_status,
 		.soft_reset            = genphy_soft_reset,
@@ -177,7 +199,7 @@ static struct phy_driver ncn26000_driver[] = {
 		.read_status		= ncn26000_read_status,
 		.handle_interrupt       = ncn26000_handle_interrupt,
 		.get_plca_cfg		= genphy_c45_plca_get_cfg,
-		.set_plca_cfg		= genphy_c45_plca_set_cfg,
+		.set_plca_cfg		= ncn26000_c45_plca_set_cfg,
 		.get_plca_status	= genphy_c45_plca_get_status,
 		.soft_reset             = genphy_soft_reset,
 	},

-- 
2.43.0

