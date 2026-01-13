From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 13 Jan 2026 23:16:16 +0800
Subject: [PATCH RFC 2/2] net: dwmac_meson8b: Fix incorrect clock divider
 setting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260113-aml_eth-v1-2-3dd74db37c4f@outlook.com>
References: <20260113-aml_eth-v1-0-3dd74db37c4f@outlook.com>
In-Reply-To: <20260113-aml_eth-v1-0-3dd74db37c4f@outlook.com>
To: u-boot-amlogic@groups.io, u-boot@lists.denx.de
Cc: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>, Jerome Forissier <jerome@forissier.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768317381; l=4015;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=N54o61iT+QMkRPDSfAfYCMn3c7ohOQtF54kAkKdLB7A=;
 b=533nhsA9QPpoM1+GR3lsAA5fVXmcxKJUrgqQVQKDj8cBEj82qL2QXcyn6jUK7H3Y0lrO6Fov5
 0KX9ppxGjw7CmS24E8WBt//kVEycjWlk38Wg8Vmgu3AHpqjthD+VD+Y
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The original code sets divisor to 4, which seems incorrect as per the
datasheet[1] and Linux driver code[2]. See explanation below:

                                                   crystal (24MHz)
                                                           |
                                                 Fixed DPLL (2550MHz)
                                                           |
                                            -----------------------------
                                            |                           |
                                   FCLK_DIV2 (1275MHz)            MPLL2 (500MHz)
                                            |---------------------------|
                                                           |
                                                        M250_MUX (Usually MPLL2)
                                                           |
                                                        M250_DIV  (500 / 2 = 250MHz)
                                                           |
                                                       FIXED_DIV2 (250 / 2 = 125MHz)
                                                           |
                                                       RGMII_TX_EN (Gate)
                                                           |
                                                       RGMII_TX_CLK (125MHz)

Note:
1. It doesn't work to switch M250_MUX to FCLK_DIV2 because it's unable
   to generate 125MHz rgmii clock (1275/125=10.2);
2. There is a fixed 2x divider before rgmii tx clock;
3. MPLL2 is configurable, theoretically. In practice it's always 500MHz.

Because of all these reasons, M250_DIV should be set to 0b010, which
divides input 500MHz clock to 250MHz output, to generate the 125MHz
rgmii clock.

In vendor U-Boot, the value read out from 0xc1108140 is 0x7531 (bit7-9
is 0b010), which also verify this.

This patch is tested on a board with S805.

[1]: https://dn.odroid.com/S905/DataSheet/S905_Public_Datasheet_V1.1.4.pdf P304
[2]: https://elixir.bootlin.com/linux/v6.18.4/source/drivers/net/ethernet/stmicro/stmmac/dwmac-meson8b.c#L143

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>

------------
---
 drivers/net/dwmac_meson8b.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/net/dwmac_meson8b.c b/drivers/net/dwmac_meson8b.c
index b1a3946ce684..34f55a4d42ea 100644
--- a/drivers/net/dwmac_meson8b.c
+++ b/drivers/net/dwmac_meson8b.c
@@ -67,7 +67,7 @@ static int dwmac_setup_axg(struct udevice *dev, struct eth_pdata *edata)
 				AXG_ETH_REG_0_TX_PHASE_MASK | AXG_ETH_REG_0_TX_RATIO_MASK,
 				AXG_ETH_REG_0_PHY_INTF_RGMII |
 				AXG_ETH_REG_0_TX_PHASE(1) |
-				AXG_ETH_REG_0_TX_RATIO(4) |
+				AXG_ETH_REG_0_TX_RATIO(2) |
 				AXG_ETH_REG_0_PHY_CLK_EN |
 				AXG_ETH_REG_0_CLK_EN);
 		break;
@@ -78,7 +78,7 @@ static int dwmac_setup_axg(struct udevice *dev, struct eth_pdata *edata)
 		clrsetbits_le32(plat->regs + ETH_REG_0,
 				AXG_ETH_REG_0_TX_PHASE_MASK | AXG_ETH_REG_0_TX_RATIO_MASK,
 				AXG_ETH_REG_0_PHY_INTF_RGMII |
-				AXG_ETH_REG_0_TX_RATIO(4) |
+				AXG_ETH_REG_0_TX_RATIO(2) |
 				AXG_ETH_REG_0_PHY_CLK_EN |
 				AXG_ETH_REG_0_CLK_EN);
 		break;
@@ -109,7 +109,7 @@ static int dwmac_setup_gx(struct udevice *dev, struct eth_pdata *edata)
 				GX_ETH_REG_0_TX_PHASE_MASK | GX_ETH_REG_0_TX_RATIO_MASK,
 				GX_ETH_REG_0_PHY_INTF |
 				GX_ETH_REG_0_TX_PHASE(1) |
-				GX_ETH_REG_0_TX_RATIO(4) |
+				GX_ETH_REG_0_TX_RATIO(2) |
 				GX_ETH_REG_0_PHY_CLK_EN |
 				GX_ETH_REG_0_CLK_EN);
 
@@ -121,7 +121,7 @@ static int dwmac_setup_gx(struct udevice *dev, struct eth_pdata *edata)
 		clrsetbits_le32(plat->regs + ETH_REG_0,
 				GX_ETH_REG_0_TX_PHASE_MASK | GX_ETH_REG_0_TX_RATIO_MASK,
 				GX_ETH_REG_0_PHY_INTF |
-				GX_ETH_REG_0_TX_RATIO(4) |
+				GX_ETH_REG_0_TX_RATIO(2) |
 				GX_ETH_REG_0_PHY_CLK_EN |
 				GX_ETH_REG_0_CLK_EN);
 

-- 
2.43.0

