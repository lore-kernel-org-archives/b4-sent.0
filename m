From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:13:55 +0000
Subject: [PATCH net-next] net: stmmac: dwmac-rk: only read the delays the
 MAC applies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-stmmac-dwmac-rk-delays-v1-1-87abb6592921@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMSw7CMAwFr1J5jaU4VOVzFcQiJC4YaEBxoK2q3
 r0pbJ40epqZQDkJKxyrCRJ/ReUVC9CmAn9z8coooTBYYxsiMqi565zH0K+bHhj46UbFmpzZ7ne
 Nrf0BivxO3MrwC58gcsbIQ4bz/9HP5c4+r12Y5wWXMDVLhAAAAA==
X-Change-ID: 20261110-stmmac-dwmac-rk-delays-41a0387624c9
To: Heiko Stuebner <heiko@sntech.de>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>
Cc: linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, netdev@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294835; l=4046;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=QQNrpXBNV3rRDNQu9MSMqZkKJ0F2a8WJAor/zaH4Dzs=;
 b=/C7vRZ019UGX9xEoKZox6IV8k6tffQB9VzApV8qqosMVT1iLXR/1PDjegWS5Hdu7X7RjjaWaU
 YUuaeZtNgpXD+xcNDzz7bUfPLAHBcBOQ1lGwJhWyMw7CR3dHdeNQqcn
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The tx_delay and rx_delay properties are only used for the directions in
which the MAC inserts the RGMII clock delay itself: both for "rgmii",
TX for "rgmii-rxid" and RX for "rgmii-txid". For "rgmii-id" (the PHY
adds both delays, the recommended setup) and for RMII they are ignored
by rk_gmac_powerup().

The driver nevertheless parses both properties unconditionally and logs
an error, plus the default it picks, for each one that is missing. A
correct device tree using "rgmii-rxid" therefore gets

  Can not read property: rx_delay.
  set rx_delay to 0x10

and one using "rgmii-id" gets the same pair for tx_delay as well, for a
value that is never programmed.

Only parse the delay values that will actually be used, so the error is
reserved for device trees that really lack a required delay. Behaviour
for "rgmii", "rgmii-rxid" and "rgmii-txid" is unchanged.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi 5 (RK3588S, Motorcomm YT8531C on gmac1) with its
device tree using "rgmii-id": the probe log has "init for RGMII_ID" and
no "Can not read property" lines any more, the link comes up at
1000/Full and transfers run at line rate (940 Mbit/s receive, 0 errors).
The "rgmii", "rgmii-rxid" and "rgmii-txid" paths are unchanged and were
not re-tested.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed and tested it
as described above.
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c | 47 ++++++++++++++++----------
 1 file changed, 29 insertions(+), 18 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
index c4db919ec164..f06428ce3cfc 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
@@ -1331,26 +1331,37 @@ static struct rk_priv_data *rk_gmac_setup(struct platform_device *pdev,
 			bsp_priv->clock_input = false;
 	}
 
-	ret = of_property_read_u32(dev->of_node, "tx_delay", &value);
-	if (ret) {
-		bsp_priv->tx_delay = 0x30;
-		dev_err(dev, "Can not read property: tx_delay.");
-		dev_err(dev, "set tx_delay to 0x%x\n",
-			bsp_priv->tx_delay);
-	} else {
-		dev_info(dev, "TX delay(0x%x).\n", value);
-		bsp_priv->tx_delay = value;
+	/*
+	 * The MAC only inserts the delays which neither the PCB nor the PHY
+	 * provide (see rk_gmac_powerup()), so only the delay values for
+	 * those directions are needed.
+	 */
+	if (bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII ||
+	    bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII_RXID) {
+		ret = of_property_read_u32(dev->of_node, "tx_delay", &value);
+		if (ret) {
+			bsp_priv->tx_delay = 0x30;
+			dev_err(dev, "Can not read property: tx_delay.");
+			dev_err(dev, "set tx_delay to 0x%x\n",
+				bsp_priv->tx_delay);
+		} else {
+			dev_info(dev, "TX delay(0x%x).\n", value);
+			bsp_priv->tx_delay = value;
+		}
 	}
 
-	ret = of_property_read_u32(dev->of_node, "rx_delay", &value);
-	if (ret) {
-		bsp_priv->rx_delay = 0x10;
-		dev_err(dev, "Can not read property: rx_delay.");
-		dev_err(dev, "set rx_delay to 0x%x\n",
-			bsp_priv->rx_delay);
-	} else {
-		dev_info(dev, "RX delay(0x%x).\n", value);
-		bsp_priv->rx_delay = value;
+	if (bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII ||
+	    bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII_TXID) {
+		ret = of_property_read_u32(dev->of_node, "rx_delay", &value);
+		if (ret) {
+			bsp_priv->rx_delay = 0x10;
+			dev_err(dev, "Can not read property: rx_delay.");
+			dev_err(dev, "set rx_delay to 0x%x\n",
+				bsp_priv->rx_delay);
+		} else {
+			dev_info(dev, "RX delay(0x%x).\n", value);
+			bsp_priv->rx_delay = value;
+		}
 	}
 
 	bsp_priv->grf = syscon_regmap_lookup_by_phandle(dev->of_node,

---
base-commit: d26955e57475434b59d43ba372b2a50d33d5e0ed
change-id: 20261110-stmmac-dwmac-rk-delays-41a0387624c9

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

