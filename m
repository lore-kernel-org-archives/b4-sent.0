From: Nikolai Burov <nikolai.burov@jolla.com>
Date: Sat, 11 Jul 2026 13:34:46 +0300
Subject: [PATCH] phy: mediatek: xsphy: clear U2 DTM0 force bits during init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260711-mt6858-xsphy-poweron-v1-1-dee2fb71c7d5@jolla.com>
X-B4-Tracking: v=1; b=H4sIAEYcUmoC/yXMQQ6CMBBA0auQWTtJaRTRqxgX7TjIkNA2HVQM4
 e5WWL7F/wsoZ2GFa7VA5reoxFBQHyqg3oUnozyKwRrbmHNtcJya9tTirKn/YoofzjEgkeu8Mxd
 /JAslTZk7mbft7b5bX35gmv4vWNcfgYXly3gAAAA=
X-Change-ID: 20260710-mt6858-xsphy-poweron-ccafba09b4c2
To: Chunfeng Yun <chunfeng.yun@mediatek.com>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-phy@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Nikolai Burov <nikolai.burov+review@abscue.de>, 
 Nikolai Burov <nikolai.burov@jolla.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783766141; l=1733;
 i=nikolai.burov@jolla.com; s=20260707; h=from:subject:message-id;
 bh=JAVmiLYc4qL5R032CUvK9+ze4/IqmRRFbWXmWnyY5tU=;
 b=T0DPUN3D5Y3CUdetCWkVyJ8WU48VXB/UEznv/4kjGDWgJZk/mqULDgRof1/ZH+idGNPgKT1a6
 pFaBDtZ/Hb3D6lHiIqqboDwvOCv8CCaBmwx/OkrHgkfRfuPuhtGdoaN
X-Developer-Key: i=nikolai.burov@jolla.com; a=ed25519;
 pk=yzpa+PD+ovHUFMIOBA9o2QqGwI110jM6hdGHLc7jtoQ=
X-Endpoint-Received: by B4 Relay for nikolai.burov@jolla.com/20260707 with auth_id=859
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On mobile SoCs, the USB PHY is completely powered off during bootup.
As a result, various bits in the DTM0 register are set that prevent
the USB 2.0 PHY from functioning. Clear them as part of the
initialization sequence.

Signed-off-by: Nikolai Burov <nikolai.burov@jolla.com>
---
 drivers/phy/mediatek/phy-mtk-xsphy.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/phy/mediatek/phy-mtk-xsphy.c b/drivers/phy/mediatek/phy-mtk-xsphy.c
index cc1d66954212..b29220bc5592 100644
--- a/drivers/phy/mediatek/phy-mtk-xsphy.c
+++ b/drivers/phy/mediatek/phy-mtk-xsphy.c
@@ -62,6 +62,14 @@
 #define P2A6_RG_BC11_SW_EN	BIT(23)
 #define P2A6_RG_OTG_VBUSCMP_EN	BIT(20)
 
+#define XSP_U2PHYDTM0		((SSUSB_SIFSLV_U2PHY_COM) + 0x068)
+#define P2D_FORCE_DATAIN	BIT(23)
+#define P2D_FORCE_DM_PULLDOWN	BIT(21)
+#define P2D_FORCE_DP_PULLDOWN	BIT(20)
+#define P2D_FORCE_XCVRSEL	BIT(19)
+#define P2D_FORCE_SUSPENDM	BIT(18)
+#define P2D_FORCE_TERMSEL	BIT(17)
+
 #define XSP_U2PHYDTM1		((SSUSB_SIFSLV_U2PHY_COM) + 0x06C)
 #define P2D_FORCE_IDDIG		BIT(9)
 #define P2D_RG_VBUSVALID	BIT(5)
@@ -181,6 +189,11 @@ static void u2_phy_instance_init(struct mtk_xsphy *xsphy,
 {
 	void __iomem *pbase = inst->port_base;
 
+	mtk_phy_clear_bits(pbase + XSP_U2PHYDTM0,
+			   P2D_FORCE_DATAIN | P2D_FORCE_DM_PULLDOWN |
+			   P2D_FORCE_DP_PULLDOWN | P2D_FORCE_XCVRSEL |
+			   P2D_FORCE_SUSPENDM | P2D_FORCE_TERMSEL);
+
 	/* DP/DM BC1.1 path Disable */
 	mtk_phy_clear_bits(pbase + XSP_USBPHYACR6, P2A6_RG_BC11_SW_EN);
 

---
base-commit: bee763d5f341b99cf472afeb508d4988f62a6ca1
change-id: 20260710-mt6858-xsphy-poweron-ccafba09b4c2

Best regards,
--  
Nikolai Burov <nikolai.burov@jolla.com>

