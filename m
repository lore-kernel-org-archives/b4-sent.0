From: Roman Vivchar <rva333@protonmail.com>
Date: Thu, 26 Nov 2026 14:39:59 +0200
Subject: [PATCH 6/8] watchdog: mediatek: add mt6768
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-6768-init-v1-6-abc364a2447e@protonmail.com>
References: <20261126-6768-init-v1-0-abc364a2447e@protonmail.com>
In-Reply-To: <20261126-6768-init-v1-0-abc364a2447e@protonmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795696875; l=2135;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=jAPSajMnZh+hMZ6iDj37c2MT6NvYmDln5J/TW+J+zRs=;
 b=Yz4XRtVNQJXynvl4XLUm7InE7Brv5zcZOoVcd5MwlGAP/i81oe4cNulQo34Tz0uSKj0mqBVUi
 dT3sHhHT4SGAOYwJErNTU9b0mT7LifQfzM4ClSSGCe/AyruV2MQkL+E
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for mt6768 watchdog, which provides 12 software resets.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/watchdog/mtk_wdt.c | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/drivers/watchdog/mtk_wdt.c b/drivers/watchdog/mtk_wdt.c
index d180727986f2..45d56e8b5ef0 100644
--- a/drivers/watchdog/mtk_wdt.c
+++ b/drivers/watchdog/mtk_wdt.c
@@ -11,6 +11,7 @@
 
 #include <dt-bindings/reset/mt2712-resets.h>
 #include <dt-bindings/reset/mediatek,mt6735-wdt.h>
+#include <dt-bindings/reset/mediatek,mt6768-wdt.h>
 #include <dt-bindings/reset/mediatek,mt6795-resets.h>
 #include <dt-bindings/reset/mediatek,mt6797-wdt.h>
 #include <dt-bindings/reset/mediatek,mt8167-wdt.h>
@@ -107,6 +108,26 @@ static const struct mtk_wdt_data mt6735_data = {
 	.toprgu_sw_rst_num = MT6735_TOPRGU_RST_NUM,
 };
 
+static const u8 mt6768_toprgu_sw_rst_tb[] = {
+	[MT6768_TOPRGU_MM_RST]		= 1,
+	[MT6768_TOPRGU_MFG_RST]		= 2,
+	[MT6768_TOPRGU_VENC_RST]	= 3,
+	[MT6768_TOPRGU_VDEC_RST]	= 4,
+	[MT6768_TOPRGU_IMG_RST]		= 5,
+	[MT6768_TOPRGU_MD_RST]		= 7,
+	[MT6768_TOPRGU_CONN_RST]	= 9,
+	[MT6768_TOPRGU_APMIXED_RST]	= 10,
+	[MT6768_TOPRGU_CONN_MCU_RST]	= 12,
+	[MT6768_TOPRGU_C2K_RST]		= 15,
+	[MT6768_TOPRGU_AUDIO_RST]	= 17,
+	[MT6768_TOPRGU_CAMSYS_RST]	= 18,
+};
+
+static const struct mtk_wdt_data mt6768_data = {
+	.toprgu_sw_rst_tb = mt6768_toprgu_sw_rst_tb,
+	.toprgu_sw_rst_num = ARRAY_SIZE(mt6768_toprgu_sw_rst_tb),
+};
+
 static const struct mtk_wdt_data mt6795_data = {
 	.toprgu_sw_rst_num = MT6795_TOPRGU_SW_RST_NUM,
 };
@@ -632,6 +653,7 @@ static const struct of_device_id mtk_wdt_dt_ids[] = {
 	{ .compatible = "mediatek,mt2712-wdt", .data = &mt2712_data },
 	{ .compatible = "mediatek,mt6589-wdt", .data = &mt6589_data },
 	{ .compatible = "mediatek,mt6735-wdt", .data = &mt6735_data },
+	{ .compatible = "mediatek,mt6768-wdt", .data = &mt6768_data },
 	{ .compatible = "mediatek,mt6795-wdt", .data = &mt6795_data },
 	{ .compatible = "mediatek,mt6797-wdt", .data = &mt6797_data },
 	{ .compatible = "mediatek,mt6833-wdt" },

-- 
2.56.1

