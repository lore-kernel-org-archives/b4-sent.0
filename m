From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Wed, 02 Sep 2026 14:51:08 +0200
Subject: [PATCH v11 4/6] thermal: khadas-mcu-fan: Add fan config from
 platform data Add regulator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-add-mcu-fan-khadas-vim4-v11-4-5f1610d83bf0@aliel.fr>
References: <20260902-add-mcu-fan-khadas-vim4-v11-0-5f1610d83bf0@aliel.fr>
In-Reply-To: <20260902-add-mcu-fan-khadas-vim4-v11-0-5f1610d83bf0@aliel.fr>
To: Neil Armstrong <neil.armstrong@linaro.org>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Beniamino Galvani <b.galvani@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>
Cc: linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-pm@vger.kernel.org, 
 mfd@lists.linux.dev, Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5696;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=zXGNIJ6KCWP9FF8FljP2h9aLndxz2U6+8oWPcyZ4qNY=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9YM6c9/lAQnGdfs3vnxtdpH7p0Pb6ydzMtbf4Tn7z3Jw
 Mnef7J+dJSyMIhxMciKKbL0z7U88e7y0TNf96inwMxhZQIZwsDFKQATCXFn+B+YtsC+eodxzpmV
 9RLP9qf9UP3iPbkyOeLs2ZWxS9NERfQZ/pfciNmX9e/ckTL2XXtuCCoLpRhYbPs3LT38r6vZleB
 lf7gB
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Read the fan register and level table from platform_data (fan_reg,
levels[] and nlevels) instead of hardcoding a single register and
level count, as new MCUs need different values. MAX_LEVEL is kept
and bumped from 3 to 5 to make the speed change more gradual with
the newer MCUs.

The cooling device's state is stored as an index into levels[],
and khadas_mcu_fan_set_level() writes levels[state] to fan_reg,
rather than writing the raw state value as before.

Optionally acquire and enable a "fan" regulator supply
at probe time and on resume,
so boards that gate fan power through a regulator are handled.
The regulator is released via a devm_add_action_or_reset()
callback.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/thermal/khadas_mcu_fan.c | 90 ++++++++++++++++++++++++++++++----------
 1 file changed, 69 insertions(+), 21 deletions(-)

diff --git a/drivers/thermal/khadas_mcu_fan.c b/drivers/thermal/khadas_mcu_fan.c
index 21b3d0a71bd0d..62d4736985b2d 100644
--- a/drivers/thermal/khadas_mcu_fan.c
+++ b/drivers/thermal/khadas_mcu_fan.c
@@ -13,34 +13,33 @@
 #include <linux/regmap.h>
 #include <linux/sysfs.h>
 #include <linux/thermal.h>
+#include <linux/regulator/consumer.h>
+#include <linux/minmax.h>
 
-#define MAX_LEVEL 3
+#define MAX_LEVEL 5
 
 struct khadas_mcu_fan_ctx {
 	struct khadas_mcu *mcu;
+	unsigned int fan_reg;
 	unsigned int level;
+	const unsigned int *levels;
+	unsigned int nlevels;
 	struct thermal_cooling_device *cdev;
+	struct regulator *power;
 };
 
 static int khadas_mcu_fan_set_level(struct khadas_mcu_fan_ctx *ctx,
 				    unsigned int level)
 {
-	int ret;
-
-	ret = regmap_write(ctx->mcu->regmap, KHADAS_MCU_CMD_FAN_STATUS_CTRL_REG,
-			   level);
-	if (ret)
-		return ret;
-
-	ctx->level = level;
-
-	return 0;
+	return regmap_write(ctx->mcu->regmap, ctx->fan_reg, level);
 }
 
 static int khadas_mcu_fan_get_max_state(struct thermal_cooling_device *cdev,
 					unsigned long *state)
 {
-	*state = MAX_LEVEL;
+	struct khadas_mcu_fan_ctx *ctx = cdev->devdata;
+
+	*state = min_t(unsigned int, MAX_LEVEL, ctx->nlevels - 1);
 
 	return 0;
 }
@@ -60,14 +59,21 @@ khadas_mcu_fan_set_cur_state(struct thermal_cooling_device *cdev,
 			     unsigned long state)
 {
 	struct khadas_mcu_fan_ctx *ctx = cdev->devdata;
+	int ret;
 
-	if (state > MAX_LEVEL)
+	if (state > MAX_LEVEL || state >= ctx->nlevels)
 		return -EINVAL;
 
 	if (state == ctx->level)
 		return 0;
 
-	return khadas_mcu_fan_set_level(ctx, state);
+	ret = khadas_mcu_fan_set_level(ctx, ctx->levels[state]);
+	if (ret)
+		return ret;
+
+	ctx->level = state;
+
+	return 0;
 }
 
 static const struct thermal_cooling_device_ops khadas_mcu_fan_cooling_ops = {
@@ -76,22 +82,56 @@ static const struct thermal_cooling_device_ops khadas_mcu_fan_cooling_ops = {
 	.set_cur_state = khadas_mcu_fan_set_cur_state,
 };
 
+static void khadas_mcu_fan_regulator_disable(void *data)
+{
+	struct regulator *power = data;
+
+	regulator_disable(power);
+}
+
 static int khadas_mcu_fan_probe(struct platform_device *pdev)
 {
+	const struct khadas_mcu_fan_pdata *pdata = dev_get_platdata(&pdev->dev);
 	struct khadas_mcu *mcu = dev_get_drvdata(pdev->dev.parent);
 	struct thermal_cooling_device *cdev;
 	struct device *dev = &pdev->dev;
 	struct khadas_mcu_fan_ctx *ctx;
 	int ret;
 
+
+	if (!dev->of_node)
+		dev->of_node = of_node_get(dev->parent->of_node);
+
+	if (!pdata)
+		return -EINVAL;
+
 	ctx = devm_kzalloc(dev, sizeof(*ctx), GFP_KERNEL);
 	if (!ctx)
 		return -ENOMEM;
+
 	ctx->mcu = mcu;
+	ctx->fan_reg = pdata->fan_reg;
+	ctx->levels = pdata->levels;
+	ctx->nlevels = pdata->nlevels;
+
+	ctx->power = devm_regulator_get(dev, "fan");
+	if (IS_ERR(ctx->power))
+		return PTR_ERR(ctx->power);
+
+	ret = regulator_enable(ctx->power);
+	if (ret) {
+		dev_err(dev, "Failed to enable fan power supply: %d\n", ret);
+		return ret;
+	}
+
+	ret = devm_add_action_or_reset(dev, khadas_mcu_fan_regulator_disable, ctx->power);
+	if (ret)
+		return ret;
+
 	platform_set_drvdata(pdev, ctx);
 
-	cdev = devm_thermal_of_child_cooling_device_register(dev->parent,
-							     dev->parent->of_node,
+	cdev = devm_thermal_of_child_cooling_device_register(dev,
+							     dev->of_node,
 							     "khadas-mcu-fan", ctx,
 							     &khadas_mcu_fan_cooling_ops);
 	if (IS_ERR(cdev)) {
@@ -109,21 +149,24 @@ static void khadas_mcu_fan_shutdown(struct platform_device *pdev)
 {
 	struct khadas_mcu_fan_ctx *ctx = platform_get_drvdata(pdev);
 
-	khadas_mcu_fan_set_level(ctx, 0);
+	khadas_mcu_fan_set_level(ctx, ctx->levels[0]);
 }
 
 #ifdef CONFIG_PM_SLEEP
 static int khadas_mcu_fan_suspend(struct device *dev)
 {
 	struct khadas_mcu_fan_ctx *ctx = dev_get_drvdata(dev);
-	unsigned int level_save = ctx->level;
 	int ret;
 
-	ret = khadas_mcu_fan_set_level(ctx, 0);
+	ret = khadas_mcu_fan_set_level(ctx, ctx->levels[0]);
 	if (ret)
 		return ret;
 
-	ctx->level = level_save;
+	ret = regulator_disable(ctx->power);
+	if (ret) {
+		khadas_mcu_fan_set_level(ctx, ctx->levels[ctx->level]);
+		return ret;
+	}
 
 	return 0;
 }
@@ -131,8 +174,13 @@ static int khadas_mcu_fan_suspend(struct device *dev)
 static int khadas_mcu_fan_resume(struct device *dev)
 {
 	struct khadas_mcu_fan_ctx *ctx = dev_get_drvdata(dev);
+	int ret;
+
+	ret = regulator_enable(ctx->power);
+	if (ret)
+		return ret;
 
-	return khadas_mcu_fan_set_level(ctx, ctx->level);
+	return khadas_mcu_fan_set_level(ctx, ctx->levels[ctx->level]);
 }
 #endif
 

-- 
2.49.0

