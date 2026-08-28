From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Date: Fri, 28 Aug 2026 13:51:47 +0300
Subject: [PATCH] media: i2c: imx258: Add reset-gpio support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260828-imx258-add-reset-gpio-patch-v1-1-633972d2a700@mainlining.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MwQ5AMAwA0F+RnjVhTMaviMPSFj1g2UQk4t8tj
 u/yHkgSVRIMxQNRLk167Bl1WQCtfl8ElbPBVKarnLGo222sQ8+MUZKcuAQ9MPiTVqS2ccyNnXs
 iyEOIMuv97+P0vh/hRW3qbQAAAA==
X-Change-ID: 20260825-imx258-add-reset-gpio-patch-c438dd35f9cc
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: git@luigi311.com, pavel@ucw.cz, tomm.merciai@gmail.com, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, =?utf-8?q?Ond=C5=99ej_Jirman?= <megi@xff.cz>, 
 Muzaffer Kadir <muzafferkadir@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787914322; l=3095;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=K0S+hjXRamfbzSLaocvKAIe3EyDCb1YJZikydR5BEuc=;
 b=mjwp5RpdIhMaH1pNMCJ5xaW0CERNyBgRwYlJG2z3+TccO462CU5jd3zCCEWTr3EzakaORCNEx
 6IBnSq136srDLxgZiUy0s/fEBaI2XemBZih+Mkgl2SXHumI/QKC0ORB
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

reset-gpio is already documented in dt-bindings but never implemented
in the driver.
Reset deassert delay comes from Luis Garcia's and Ondrej Jirman's patch.

Link: https://lore.kernel.org/all/20240602201345.328737-22-git@luigi311.com
Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
I have a device that is not upstreamed yet (General Mobile Shamrock)
whose camera needs reset gpio to probe, it is documented for
dts check but not implemented for some reason.
With adding it rear camera on the device probes correctly.

I created this patch without knowing the older one that submitted
before: https://lore.kernel.org/all/20240602201345.328737-22-git@luigi311.com/

I don't fully know the correct reset timing so I was using a random wait before,
after I discovered existing patch I reused previous work for delay time after reset.
---
 drivers/media/i2c/imx258.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/drivers/media/i2c/imx258.c b/drivers/media/i2c/imx258.c
index bc9ee449a87c..af3f12c7452a 100644
--- a/drivers/media/i2c/imx258.c
+++ b/drivers/media/i2c/imx258.c
@@ -9,6 +9,7 @@
 #include <linux/pm_runtime.h>
 #include <linux/regulator/consumer.h>
 #include <linux/unaligned.h>
+#include <linux/gpio/consumer.h>
 
 #include <media/v4l2-cci.h>
 #include <media/v4l2-ctrls.h>
@@ -681,6 +682,7 @@ struct imx258 {
 
 	struct clk *clk;
 	struct regulator_bulk_data supplies[IMX258_NUM_SUPPLIES];
+	struct gpio_desc *reset_gpio;
 };
 
 static inline struct imx258 *to_imx258(struct v4l2_subdev *_sd)
@@ -1128,6 +1130,18 @@ static int imx258_power_on(struct device *dev)
 	if (ret) {
 		dev_err(dev, "failed to enable clock\n");
 		regulator_bulk_disable(IMX258_NUM_SUPPLIES, imx258->supplies);
+		return ret;
+	}
+
+	if (imx258->reset_gpio) {
+		ret = gpiod_set_value_cansleep(imx258->reset_gpio, 0);
+		if (ret) {
+			dev_err(dev, "failed to deassert reset\n");
+			clk_disable_unprepare(imx258->clk);
+			regulator_bulk_disable(IMX258_NUM_SUPPLIES, imx258->supplies);
+			return ret;
+		}
+		usleep_range(400, 500);
 	}
 
 	return ret;
@@ -1138,6 +1152,7 @@ static int imx258_power_off(struct device *dev)
 	struct v4l2_subdev *sd = dev_get_drvdata(dev);
 	struct imx258 *imx258 = to_imx258(sd);
 
+	gpiod_set_value_cansleep(imx258->reset_gpio, 1);
 	clk_disable_unprepare(imx258->clk);
 	regulator_bulk_disable(IMX258_NUM_SUPPLIES, imx258->supplies);
 
@@ -1382,6 +1397,11 @@ static int imx258_probe(struct i2c_client *client)
 		return ret;
 	}
 
+	imx258->reset_gpio = devm_gpiod_get_optional(imx258->dev, "reset", GPIOD_OUT_HIGH);
+	if (IS_ERR(imx258->reset_gpio))
+		return dev_err_probe(imx258->dev, PTR_ERR(imx258->reset_gpio),
+				     "Failed to get reset-gpios\n");
+
 	ret = imx258_get_regulators(imx258);
 	if (ret)
 		return dev_err_probe(imx258->dev, ret,

---
base-commit: db2ddb87143519e20a95aa36c60b36107b736a58
change-id: 20260825-imx258-add-reset-gpio-patch-c438dd35f9cc

Best regards,
-- 
Muzaffer Kadir <muzafferkadir@mainlining.org>

