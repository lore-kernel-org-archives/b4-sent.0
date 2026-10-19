From: Ben Grisdale <bengris32@protonmail.ch>
Date: Mon, 19 Oct 2026 01:40:02 +0100
Subject: [PATCH 6/8] watchdog: mediatek: Add support for MT8163 TOPRGU/WDT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-6-f2462b2d2437@protonmail.ch>
References: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-0-f2462b2d2437@protonmail.ch>
In-Reply-To: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-0-f2462b2d2437@protonmail.ch>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792370441; l=1544;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=/XTNZ0sJc5waPCmXjLC0TBnLTxhdHSp17UVgQTVrcOk=;
 b=9D6DQ5YEYoCFOvrvWp1BbWcmknxj8b+1B1kqQkshIu/XlI0b7gwW+LxkowQ591ZAtqpzpaqJl
 4sxYm6Pi5RSBHAy8FNOmRMon9XRZGxzEgy00AXgppSlSwETOELBdjXj
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the Top Reset Generation Unit (TOPRGU) and watchdog
timer on the MediaTek MT8163 SoC, which provides 15 software resets.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 drivers/watchdog/mtk_wdt.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/watchdog/mtk_wdt.c b/drivers/watchdog/mtk_wdt.c
index 1630ab65d593..0c6efa2e851d 100644
--- a/drivers/watchdog/mtk_wdt.c
+++ b/drivers/watchdog/mtk_wdt.c
@@ -70,6 +70,7 @@
 
 #define MT6589_TOPRGU_SW_RST_NUM	12
 #define MT7988_TOPRGU_SW_RST_NUM	24
+#define MT8163_TOPRGU_SW_RST_NUM	15
 
 static bool nowayout = WATCHDOG_NOWAYOUT;
 static unsigned int timeout;
@@ -117,6 +118,10 @@ static const struct mtk_wdt_data mt7988_data = {
 	.has_swsysrst_en = true,
 };
 
+static const struct mtk_wdt_data mt8163_data = {
+	.toprgu_sw_rst_num = MT8163_TOPRGU_SW_RST_NUM,
+};
+
 static const struct mtk_wdt_data mt8183_data = {
 	.toprgu_sw_rst_num = MT8183_TOPRGU_SW_RST_NUM,
 };
@@ -597,6 +602,7 @@ static const struct of_device_id mtk_wdt_dt_ids[] = {
 	{ .compatible = "mediatek,mt6795-wdt", .data = &mt6795_data },
 	{ .compatible = "mediatek,mt7986-wdt", .data = &mt7986_data },
 	{ .compatible = "mediatek,mt7988-wdt", .data = &mt7988_data },
+	{ .compatible = "mediatek,mt8163-wdt", .data = &mt8163_data },
 	{ .compatible = "mediatek,mt8167-wdt", .data = &mt8167_data },
 	{ .compatible = "mediatek,mt8183-wdt", .data = &mt8183_data },
 	{ .compatible = "mediatek,mt8186-wdt", .data = &mt8186_data },

-- 
2.56.0

