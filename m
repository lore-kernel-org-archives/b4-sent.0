From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Mon, 02 Dec 2024 23:03:51 +0100
Subject: [PATCH net-next v7 12/15] net: dwmac-sti: Use helper rgmii_clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241202-upstream_s32cc_gmac-v7-12-bc3e1f9f656e@oss.nxp.com>
References: <20241202-upstream_s32cc_gmac-v7-0-bc3e1f9f656e@oss.nxp.com>
In-Reply-To: <20241202-upstream_s32cc_gmac-v7-0-bc3e1f9f656e@oss.nxp.com>
To: Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <joabreu@synopsys.com>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Vinod Koul <vkoul@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Emil Renner Berthing <kernel@esmil.dk>, 
 Minda Chen <minda.chen@starfivetech.com>, 
 Nicolas Ferre <nicolas.ferre@microchip.com>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>, 
 Iyappan Subramanian <iyappan@os.amperecomputing.com>, 
 Keyur Chudgar <keyur@os.amperecomputing.com>, 
 Quan Nguyen <quan@os.amperecomputing.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>
Cc: linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, linux-arm-msm@vger.kernel.org, imx@lists.linux.dev, 
 devicetree@vger.kernel.org, NXP S32 Linux Team <s32@nxp.com>, 
 0x1207@gmail.com, fancer.lancer@gmail.com, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733177022; l=2017;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=E3dKlyRUyP013sEwa3YoW1YOIguttVezMK0ReGNP/J8=;
 b=5EU9Td/kVd7f4K9kEjDJi+349oi1iNwhZveDd+NbdQO1HK6hNFZF1sN6KFKDbDtGKZoUd0cQE
 bWHECNs0viOC6v11NRJYA4/ZXYvX9/tmNblOkNBiTsbNjmEjreDosHe
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Utilize a new helper function rgmii_clock().

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Reviewed-by: Russell King (Oracle) <rmk+kernel@armlinux.org.uk>
Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sti.c | 18 +++++-------------
 1 file changed, 5 insertions(+), 13 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sti.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sti.c
index a6ff02d905a9..eabc4da9e1a9 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sti.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sti.c
@@ -21,10 +21,7 @@
 
 #include "stmmac_platform.h"
 
-#define DWMAC_125MHZ	125000000
 #define DWMAC_50MHZ	50000000
-#define DWMAC_25MHZ	25000000
-#define DWMAC_2_5MHZ	2500000
 
 #define IS_PHY_IF_MODE_RGMII(iface)	(iface == PHY_INTERFACE_MODE_RGMII || \
 			iface == PHY_INTERFACE_MODE_RGMII_ID || \
@@ -140,7 +137,7 @@ static void stih4xx_fix_retime_src(void *priv, u32 spd, unsigned int mode)
 	struct sti_dwmac *dwmac = priv;
 	u32 src = dwmac->tx_retime_src;
 	u32 reg = dwmac->ctrl_reg;
-	u32 freq = 0;
+	long freq = 0;
 
 	if (dwmac->interface == PHY_INTERFACE_MODE_MII) {
 		src = TX_RETIME_SRC_TXCLK;
@@ -153,19 +150,14 @@ static void stih4xx_fix_retime_src(void *priv, u32 spd, unsigned int mode)
 		}
 	} else if (IS_PHY_IF_MODE_RGMII(dwmac->interface)) {
 		/* On GiGa clk source can be either ext or from clkgen */
-		if (spd == SPEED_1000) {
-			freq = DWMAC_125MHZ;
-		} else {
+		freq = rgmii_clock(spd);
+
+		if (spd != SPEED_1000 && freq > 0)
 			/* Switch to clkgen for these speeds */
 			src = TX_RETIME_SRC_CLKGEN;
-			if (spd == SPEED_100)
-				freq = DWMAC_25MHZ;
-			else if (spd == SPEED_10)
-				freq = DWMAC_2_5MHZ;
-		}
 	}
 
-	if (src == TX_RETIME_SRC_CLKGEN && freq)
+	if (src == TX_RETIME_SRC_CLKGEN && freq > 0)
 		clk_set_rate(dwmac->clk, freq);
 
 	regmap_update_bits(dwmac->regmap, reg, STIH4XX_RETIME_SRC_MASK,

-- 
2.47.0

