From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 10 Nov 2026 21:22:22 +0200
Subject: [PATCH 2/3] watchdog: mediatek: add mt6797 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-6797-wdt-v1-2-7f07755b6074@protonmail.com>
References: <20261110-6797-wdt-v1-0-7f07755b6074@protonmail.com>
In-Reply-To: <20261110-6797-wdt-v1-0-7f07755b6074@protonmail.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Ben Grisdale <bengris32@protonmail.ch>, linux-watchdog@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794338551; l=2582;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=XN0xD57bgx+IYBVgDg/di/5aMiE8ZsNZz0yTSSqhsM4=;
 b=lBURJBTCWv0BYmj39ZK6Y8b99JQuvBYmQK4wEfwEzme9aU/iWZ7+9/rFbvi86AsP6wINMqFu4
 kT1uTnxRQThAtGvmR+UpUWM0QtrJWgzP+8kSVRueHoojO2XjbcJiIFB
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for mt6797 SoC watchdog, which provides 17 software resets.
The mapping table uses bits from the datasheet [1].

Link: https://www.96boards.org/documentation/consumer/mediatekx20/additional-docs/docs/MT6797_Register_Table_Part_1.pdf [1]
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/watchdog/mtk_wdt.c | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/drivers/watchdog/mtk_wdt.c b/drivers/watchdog/mtk_wdt.c
index a210fe1569e4..56341f746704 100644
--- a/drivers/watchdog/mtk_wdt.c
+++ b/drivers/watchdog/mtk_wdt.c
@@ -12,6 +12,7 @@
 #include <dt-bindings/reset/mt2712-resets.h>
 #include <dt-bindings/reset/mediatek,mt6735-wdt.h>
 #include <dt-bindings/reset/mediatek,mt6795-resets.h>
+#include <dt-bindings/reset/mediatek,mt6797-wdt.h>
 #include <dt-bindings/reset/mediatek,mt8167-wdt.h>
 #include <dt-bindings/reset/mt7986-resets.h>
 #include <dt-bindings/reset/mt8183-resets.h>
@@ -110,6 +111,31 @@ static const struct mtk_wdt_data mt6795_data = {
 	.toprgu_sw_rst_num = MT6795_TOPRGU_SW_RST_NUM,
 };
 
+static const u8 mt6797_toprgu_sw_rst_tb[] = {
+	[MT6797_TOPRGU_INFRA_RST] =		0,
+	[MT6797_TOPRGU_MM_RST] =		1,
+	[MT6797_TOPRGU_MFG_RST] =		2,
+	[MT6797_TOPRGU_VENC_RST] =		3,
+	[MT6797_TOPRGU_VDEC_RST] =		4,
+	[MT6797_TOPRGU_IMG_RST] =		5,
+	[MT6797_TOPRGU_DDRPHY_RST] =		6,
+	[MT6797_TOPRGU_MD_RST] =		7,
+	[MT6797_TOPRGU_INFRA_AO_RST] =		8,
+	[MT6797_TOPRGU_CONN_RST] =		9,
+	[MT6797_TOPRGU_APMIXED_RST] =		10,
+	[MT6797_TOPRGU_PWRAP_SPICTL_RST] =	11,
+	[MT6797_TOPRGU_CONN_MCU_RST] =		12,
+	[MT6797_TOPRGU_MJC_RST] =		13,
+	[MT6797_TOPRGU_AUDIO_RST] =		15,
+	[MT6797_TOPRGU_C2K_SYS_RST] =		16,
+	[MT6797_TOPRGU_C2K_WDT_RST] =		17,
+};
+
+static const struct mtk_wdt_data mt6797_data = {
+	.toprgu_sw_rst_tb = mt6797_toprgu_sw_rst_tb,
+	.toprgu_sw_rst_num = ARRAY_SIZE(mt6797_toprgu_sw_rst_tb),
+};
+
 static const struct mtk_wdt_data mt7629_data = {
 	.toprgu_sw_rst_num = MT7629_TOPRGU_SW_RST_NUM,
 };
@@ -607,6 +633,7 @@ static const struct of_device_id mtk_wdt_dt_ids[] = {
 	{ .compatible = "mediatek,mt6589-wdt", .data = &mt6589_data },
 	{ .compatible = "mediatek,mt6735-wdt", .data = &mt6735_data },
 	{ .compatible = "mediatek,mt6795-wdt", .data = &mt6795_data },
+	{ .compatible = "mediatek,mt6797-wdt", .data = &mt6797_data },
 	{ .compatible = "mediatek,mt7629-wdt", .data = &mt7629_data },
 	{ .compatible = "mediatek,mt7986-wdt", .data = &mt7986_data },
 	{ .compatible = "mediatek,mt7988-wdt", .data = &mt7988_data },

-- 
2.56.0

