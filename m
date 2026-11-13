From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 13 Nov 2026 08:59:28 -0800
Subject: [PATCH net-next v11 09/14] net: phy: ncn26000: Enable enhanced
 noise immunity
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-s2500-mac-phy-support-v11-9-7a186141952c@onsemi.com>
References: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
In-Reply-To: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794589162; l=2405;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=iAG7lV9gijg3z6XNjiMZoINHKklWCTR9M+HVJm+0cQY=;
 b=zflYKp3NW29ITGTeZqKbIdOuwjnCjgA7yNjVcQAf8y41uSt1lI61G/69krDWbv5pcYIsa5sl1
 fAvRKJIGBj6Di/HQLTnqOpemvxaNwWts24JW1kL9UZFM+r4ZizuH2yZ
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Intercept PLCA enable/disable requests in set_plca_cfg() and set or
clear the proprietary ENI bit accordingly. By setting the ENI bit,
noise immunity is improved and it is specifically meant for PLCA
enabled nodes.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v11
  - Updated commit message to be more accurate
changes in v10
  - No change
changes in v9
  - Added Reviewed tag
changes in v8
  - No change
changes in v7
  - No change
changes in v6
  - No change
changes in v5
  - No changes
changes in v4
  - No changes
changes in v3
  - Moved as a separate patch
---
 drivers/net/phy/ncn26000.c | 23 ++++++++++++++++++++++-
 1 file changed, 22 insertions(+), 1 deletion(-)

diff --git a/drivers/net/phy/ncn26000.c b/drivers/net/phy/ncn26000.c
index cabdd83c614f..888d74b83125 100644
--- a/drivers/net/phy/ncn26000.c
+++ b/drivers/net/phy/ncn26000.c
@@ -35,6 +35,9 @@
 
 #define TO_TMR_DEFAULT			32
 
+#define NCN26000_REG_PHYCFG1		0x8001
+#define NCN26000_PHYCFG1_ENI		BIT(7)
+
 static int ncn26000_config_init(struct phy_device *phydev)
 {
 	/* HW bug workaround: the default value of the PLCA TO_TIMER should be
@@ -100,6 +103,24 @@ static int ncn26000_read_status(struct phy_device *phydev)
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
+			      NCN26000_PHYCFG1_ENI, eni_cfg);
+}
+
 static irqreturn_t ncn26000_handle_interrupt(struct phy_device *phydev)
 {
 	int ret;
@@ -151,7 +172,7 @@ static struct phy_driver ncn26000_driver[] = {
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

