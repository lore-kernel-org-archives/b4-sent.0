From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 15 Aug 2025 16:37:32 +0800
Subject: [PATCH 06/13] soc: amlogic: clk-measure: Unify the compatible
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250815-add-more-socs-to-support-clk_measure-v1-6-59f04ba67457@amlogic.com>
References: <20250815-add-more-socs-to-support-clk_measure-v1-0-59f04ba67457@amlogic.com>
In-Reply-To: <20250815-add-more-socs-to-support-clk_measure-v1-0-59f04ba67457@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755247057; l=1243;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=0eEPVOYjuBKHP/v29Jhs15ySgwAKkYRM0UAoAkVVptI=;
 b=w5p2xKfbh6z56WSYU5ZafMzFPC+EGumxKh+Ixvc4DqIg3NuGpxaEkMcSlMCGGj8XeqMlAmup6
 tvRqqTQbYEjD0o6iaUTAx+p1HW8LJoy1QBm9o9TPulukjmKQ89dnunU
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clk-measure IPs across Amlogic SoCs have minimal differences, so
they can be managed with a unified compatible property.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/soc/amlogic/meson-clk-measure.c | 23 +----------------------
 1 file changed, 1 insertion(+), 22 deletions(-)

diff --git a/drivers/soc/amlogic/meson-clk-measure.c b/drivers/soc/amlogic/meson-clk-measure.c
index 4d91d463d2a5..6927f87b99cc 100644
--- a/drivers/soc/amlogic/meson-clk-measure.c
+++ b/drivers/soc/amlogic/meson-clk-measure.c
@@ -292,28 +292,7 @@ static int meson_msr_probe(struct platform_device *pdev)
 
 static const struct of_device_id meson_msr_match_table[] = {
 	{
-		.compatible = "amlogic,meson-gx-clk-measure",
-	},
-	{
-		.compatible = "amlogic,meson8-clk-measure",
-	},
-	{
-		.compatible = "amlogic,meson8b-clk-measure",
-	},
-	{
-		.compatible = "amlogic,meson-axg-clk-measure",
-	},
-	{
-		.compatible = "amlogic,meson-g12a-clk-measure",
-	},
-	{
-		.compatible = "amlogic,meson-sm1-clk-measure",
-	},
-	{
-		.compatible = "amlogic,c3-clk-measure",
-	},
-	{
-		.compatible = "amlogic,s4-clk-measure",
+		.compatible = "amlogic,clk-measure",
 	},
 	{ /* sentinel */ }
 };

-- 
2.42.0

