From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Date: Sat, 29 Aug 2026 16:06:34 +0300
Subject: [PATCH v2 2/2] media: i2c: imx258: Add reset-gpio support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-imx258-add-reset-gpio-patch-v2-2-bfd27891e225@mainlining.org>
References: <20260829-imx258-add-reset-gpio-patch-v2-0-bfd27891e225@mainlining.org>
In-Reply-To: <20260829-imx258-add-reset-gpio-patch-v2-0-bfd27891e225@mainlining.org>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: git@luigi311.com, pavel@ucw.cz, tomm.merciai@gmail.com, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Muzaffer Kadir <muzafferkadir@mainlining.org>, 
 =?utf-8?q?Ond=C5=99ej_Jirman?= <megi@xff.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788008809; l=2313;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=AbYnmMAAO6Q9SZ+P54cCQpoqnvvpRe+zS71V1ysAPrU=;
 b=q9yuk/z81n9lwAaG9CVZRENF6xYpN494oOHBNgm4PDrgsUWBU/jpJuYhF2X2VZb7LQnaLhOW7
 rxMdLz8rY0pCjBy0VOet2rdRknrGvoZ+AXn1bbyN275zh+Yxf7l5+df
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

reset-gpio is already documented in dt-bindings but never implemented
in the driver.

Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
 drivers/media/i2c/imx258.c | 24 +++++++++++++++++++++++-
 1 file changed, 23 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/imx258.c b/drivers/media/i2c/imx258.c
index 9c3a6579df0d..4a0663e816b5 100644
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
@@ -1127,10 +1129,23 @@ static int imx258_power_on(struct device *dev)
 	ret = clk_prepare_enable(imx258->clk);
 	if (ret) {
 		dev_err(dev, "failed to enable clock\n");
-		regulator_bulk_disable(IMX258_NUM_SUPPLIES, imx258->supplies);
+		goto err_disable_regulators;
+	}
+
+	ret = gpiod_set_value_cansleep(imx258->reset_gpio, 0);
+	if (ret) {
+		dev_err(dev, "failed to deassert reset\n");
+		goto err_disable_clk;
 	}
 	fsleep(400);
 
+	return ret;
+
+err_disable_clk:
+	clk_disable_unprepare(imx258->clk);
+err_disable_regulators:
+	regulator_bulk_disable(IMX258_NUM_SUPPLIES, imx258->supplies);
+
 	return ret;
 }
 
@@ -1139,6 +1154,7 @@ static int imx258_power_off(struct device *dev)
 	struct v4l2_subdev *sd = dev_get_drvdata(dev);
 	struct imx258 *imx258 = to_imx258(sd);
 
+	gpiod_set_value_cansleep(imx258->reset_gpio, 1);
 	clk_disable_unprepare(imx258->clk);
 	regulator_bulk_disable(IMX258_NUM_SUPPLIES, imx258->supplies);
 
@@ -1383,6 +1399,12 @@ static int imx258_probe(struct i2c_client *client)
 		return ret;
 	}
 
+	imx258->reset_gpio = devm_gpiod_get_optional(imx258->dev, "reset",
+		GPIOD_OUT_HIGH);
+	if (IS_ERR(imx258->reset_gpio))
+		return dev_err_probe(imx258->dev, PTR_ERR(imx258->reset_gpio),
+				     "Failed to get reset-gpios\n");
+
 	ret = imx258_get_regulators(imx258);
 	if (ret)
 		return dev_err_probe(imx258->dev, ret,

-- 
2.54.0

