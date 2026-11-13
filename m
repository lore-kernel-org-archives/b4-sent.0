From: Paul Sajna <sajattack@postmarketos.org>
Date: Thu, 12 Nov 2026 17:01:41 -0700
Subject: [PATCH v6 2/3] leds: aw2013: Add AW2027 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-aw2013-aw20xx-rename-v6-2-251eca340abc@postmarketos.org>
References: <20261112-aw2013-aw20xx-rename-v6-0-251eca340abc@postmarketos.org>
In-Reply-To: <20261112-aw2013-aw20xx-rename-v6-0-251eca340abc@postmarketos.org>
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Nikita Travkin <nikitos.tr@gmail.com>, 
 Alexey Min <alexeymin@minlexx.ru>, David Heidelberg <david@ixit.cz>, 
 Griffin Kroah-Hartman <griffin@kroah.com>
Cc: Nikita Travkin <nikita@trvn.ru>, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Paul Sajna <sajattack@postmarketos.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794528107; l=10491;
 i=sajattack@postmarketos.org; s=20250413; h=from:subject:message-id;
 bh=RvDElYn0Gil8KldZ2kYITA2GI/sk43fagtC7hicXPnE=;
 b=mQeRo72KQeRxRDcB4pKdiYunQzawKOn5dLSNtjcsi+PVCfhVMadJ56r+bSM3a3U15mUtKOjM9
 EGQ4rYcK6efDhaiTz8LOMtUnjRA0TeMGvZtPLLdxClef2Bw/5OxcESU
X-Developer-Key: i=sajattack@postmarketos.org; a=ed25519;
 pk=ZFE/UBqiz9Wr8b+zBL27opOjw5x5ket5JFqks/VQGeM=
X-Endpoint-Received: by B4 Relay for sajattack@postmarketos.org/20250413 with auth_id=1505
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AW2027 is basically the same as the AW2013.

It differs in:
- the max current (30mA rather than 15)
- the number of current levels for colour-mixing (16 rather than 4)
- the supply voltage max
- the charge indicator (unsupported by our driver at this time)

The max current register (imax) also moves from LCFG to GCR2, and the
selectable current levels for colour-mixing (LCFG_CUR) take their place.

The current driver implementation provided here sets the global imax to
it's maximum, and scales each led to the closest value using the local
imax. It's the best result achievable short of adding custom sysfs
entries and mucking up the linux interfaces.

Comparison of all AW20XX chips https://www.awinic.com/en/productCompareList?id=47&ids=1022,74,96,75,72,71,928,927,73,76,578
AW2027 datasheet: https://doc.awinic.com/doc/202507/77b87097-27bf-48cd-af9b-9b615064c1e1.pdf
Vendor driver: https://www.awinic.com/en/driver/AW2027DNR/454

Signed-off-by: Paul Sajna <sajattack@postmarketos.org>
---
 drivers/leds/leds-aw2013.c | 190 ++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 163 insertions(+), 27 deletions(-)

diff --git a/drivers/leds/leds-aw2013.c b/drivers/leds/leds-aw2013.c
index cf20e94920fd..5ff9887086a6 100644
--- a/drivers/leds/leds-aw2013.c
+++ b/drivers/leds/leds-aw2013.c
@@ -1,5 +1,5 @@
 // SPDX-License-Identifier: GPL-2.0+
-// Driver for Awinic AW2013 3-channel LED driver
+// Driver for Awinic AW2013/AW2027 3-channel LED drivers
 
 #include <linux/i2c.h>
 #include <linux/leds.h>
@@ -20,13 +20,15 @@
 #define AW2013_GCR 0x01
 #define AW2013_GCR_ENABLE BIT(0)
 
+#define AW20XX_GCR2 0x04
+
 /* LED channel enable register */
 #define AW2013_LCTR 0x30
 #define AW2013_LCTR_LE(x) BIT((x))
 
 /* LED channel control registers */
 #define AW2013_LCFG(x) (0x31 + (x))
-#define AW2013_LCFG_IMAX_MASK (BIT(0) | BIT(1)) // Should be 0-3
+#define AW2013_IMAX_MASK (BIT(0) | BIT(1)) // Should be 0-3
 #define AW2013_LCFG_MD BIT(4)
 #define AW2013_LCFG_FI BIT(5)
 #define AW2013_LCFG_FO BIT(6)
@@ -51,6 +53,16 @@
 
 #define AW2013_TIME_STEP 130 /* ms */
 
+/* AW2027-specific defines */
+#define AW2016_23_27_33_CHIPID 0x09 /* vendor shared same chipid between several chips */
+#define AW2027_REG_MAX 0x7F /* copied from vendor driver, but only up to 0x3F is documented */
+#define AW2027_LOCAL_IMAX_MASK GENMASK(3, 0)
+
+#define AW2027_GLOBAL_IMAX_15MA 0
+#define AW2027_GLOBAL_IMAX_30MA 1
+#define AW2027_GLOBAL_IMAX_5MA  2
+#define AW2027_GLOBAL_IMAX_10MA 3
+
 struct aw2013;
 
 struct aw2013_led {
@@ -60,19 +72,99 @@ struct aw2013_led {
 	unsigned int imax;
 };
 
+struct aw2013_chipdef {
+	u8 chip_id;
+	const struct regmap_config *regmap_cfg;
+	u32 default_imax;
+	bool gcr2_imax;
+	unsigned int current_levels;
+	unsigned int current_max_ua;
+};
+
 struct aw2013 {
 	struct mutex mutex; /* held when writing to registers */
 	struct regulator_bulk_data regulators[2];
 	struct i2c_client *client;
 	struct aw2013_led leds[AW2013_MAX_LEDS];
 	struct regmap *regmap;
+	const struct aw2013_chipdef *cdef;
 	int num_leds;
 	bool enabled;
 };
 
+static const struct regmap_config aw2013_regmap_config = {
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = AW2013_REG_MAX,
+};
+
+static const struct regmap_config aw2027_regmap_config = {
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = AW2027_REG_MAX,
+};
+
+static const struct aw2013_chipdef aw2013_chipdef = {
+	.chip_id = AW2013_RSTR_CHIP_ID,
+	.regmap_cfg = &aw2013_regmap_config,
+	.default_imax = 1, /* 5mA */
+	.gcr2_imax = false,
+	.current_levels = 4,
+	.current_max_ua = 15000,
+};
+
+static const struct aw2013_chipdef aw2027_chipdef = {
+	.chip_id = AW2016_23_27_33_CHIPID,
+	.regmap_cfg = &aw2027_regmap_config,
+	.default_imax = 3, /* 6mA */
+	.gcr2_imax = true,
+	.current_levels = 16,
+	.current_max_ua = 30000,
+};
+
+/**
+ * aw2013_microamp_to_imax() - Finds the closest current step to the given microamp
+ * @microamp: Desired current in microamps
+ * @cdef: Chip definition
+ *
+ * Return: The closest current-step to the given microamp, rounded down
+ * and limited by the max current step possible for the chip.
+ */
+static inline u32 aw2013_microamp_to_imax(u32 microamp, const struct aw2013_chipdef *cdef)
+{
+	u32 max_current_step = cdef->current_levels - 1;
+	u32 closest_current_step_floor = (microamp * max_current_step) / cdef->current_max_ua;
+
+	return min_t(u32, closest_current_step_floor, max_current_step);
+}
+
+static int aw2027_set_global_imax(struct aw2013 *chip)
+{
+	int ret;
+
+	ret = regmap_update_bits(chip->regmap,
+				 AW20XX_GCR2,
+				 AW2013_IMAX_MASK,
+				 AW2027_GLOBAL_IMAX_30MA);
+
+	return ret;
+}
+
+static int aw2027_set_local_imax(struct aw2013 *chip, struct aw2013_led led, u32 imax)
+{
+	int ret;
+
+	ret = regmap_update_bits(chip->regmap,
+				 AW2013_LCFG(led.num),
+				 AW2027_LOCAL_IMAX_MASK,
+				 imax);
+
+	return ret;
+}
+
 static int aw2013_chip_init(struct aw2013 *chip)
 {
-	int i, ret;
+	int ret;
 
 	ret = regmap_write(chip->regmap, AW2013_GCR, AW2013_GCR_ENABLE);
 	if (ret) {
@@ -81,10 +173,37 @@ static int aw2013_chip_init(struct aw2013 *chip)
 		return ret;
 	}
 
-	for (i = 0; i < chip->num_leds; i++) {
+	if (chip->cdef->gcr2_imax) {
+		/*
+		 * AW2027 supports 4-step global imax, and also a 16-step control for limiting
+		 * individual current per LED. This doesn't map to the single value the
+		 * devicetree provides super well, so set global imax to maximum, and
+		 * local imax to whatever gets us closest to the value in the devicetree.
+		 */
+		ret = aw2027_set_global_imax(chip);
+		if (ret) {
+			dev_err(&chip->client->dev,
+				"Failed to set maximum global current: %d\n",
+				ret);
+			return ret;
+		}
+		for (int i = 0; i < chip->num_leds; i++) {
+			ret = aw2027_set_local_imax(chip, chip->leds[i], chip->leds[i].imax);
+			if (ret) {
+				dev_err(&chip->client->dev,
+					"Failed to set maximum current for led %d: %d\n",
+					chip->leds[i].num, ret);
+				return ret;
+			}
+		}
+		return ret;
+	}
+
+	/* AW2013 only supports 4-step individual current per LED */
+	for (int i = 0; i < chip->num_leds; i++) {
 		ret = regmap_update_bits(chip->regmap,
 					 AW2013_LCFG(chip->leds[i].num),
-					 AW2013_LCFG_IMAX_MASK,
+					 AW2013_IMAX_MASK,
 					 chip->leds[i].imax);
 		if (ret) {
 			dev_err(&chip->client->dev,
@@ -142,9 +261,7 @@ static int aw2013_chip_enable(struct aw2013 *chip)
 
 static bool aw2013_chip_in_use(struct aw2013 *chip)
 {
-	int i;
-
-	for (i = 0; i < chip->num_leds; i++)
+	for (int i = 0; i < chip->num_leds; i++)
 		if (chip->leds[i].cdev.brightness)
 			return true;
 
@@ -271,6 +388,16 @@ static int aw2013_probe_dt(struct aw2013 *chip)
 	if (!count || count > AW2013_MAX_LEDS)
 		return -EINVAL;
 
+	if (chip->cdef->gcr2_imax) {
+		mutex_lock(&chip->mutex);
+		ret = aw2027_set_global_imax(chip);
+		if (ret) {
+			mutex_unlock(&chip->mutex);
+			return ret;
+		}
+		mutex_unlock(&chip->mutex);
+	}
+
 	for_each_available_child_of_node_scoped(np, child) {
 		struct led_init_data init_data = {};
 		u32 source;
@@ -293,9 +420,9 @@ static int aw2013_probe_dt(struct aw2013 *chip)
 		init_data.fwnode = of_fwnode_handle(child);
 
 		if (!of_property_read_u32(child, "led-max-microamp", &imax)) {
-			led->imax = min_t(u32, imax / 5000, 3);
+			led->imax = aw2013_microamp_to_imax(imax, chip->cdef);
 		} else {
-			led->imax = 1; // 5mA
+			led->imax = chip->cdef->default_imax;
 			dev_info(&chip->client->dev,
 				 "DT property led-max-microamp is missing\n");
 		}
@@ -306,13 +433,21 @@ static int aw2013_probe_dt(struct aw2013 *chip)
 		mutex_lock(&chip->mutex);
 		chip->num_leds = ++i;
 		if (chip->enabled) {
-			ret = regmap_update_bits(chip->regmap,
-						 AW2013_LCFG(led->num),
-						 AW2013_LCFG_IMAX_MASK,
-						 led->imax);
-			if (ret) {
-				mutex_unlock(&chip->mutex);
-				return ret;
+			if (chip->cdef->gcr2_imax) {
+				ret = aw2027_set_local_imax(chip, *led, led->imax);
+				if (ret) {
+					mutex_unlock(&chip->mutex);
+					return ret;
+				}
+			} else {
+				ret = regmap_update_bits(chip->regmap,
+							 AW2013_LCFG(led->num),
+							 AW2013_IMAX_MASK,
+							 led->imax);
+				if (ret) {
+					mutex_unlock(&chip->mutex);
+					return ret;
+				}
 			}
 		}
 		mutex_unlock(&chip->mutex);
@@ -334,18 +469,18 @@ static void aw2013_chip_disable_action(void *data)
 	aw2013_chip_disable(data);
 }
 
-static const struct regmap_config aw2013_regmap_config = {
-	.reg_bits = 8,
-	.val_bits = 8,
-	.max_register = AW2013_REG_MAX,
-};
 
 static int aw2013_probe(struct i2c_client *client)
 {
 	struct aw2013 *chip;
+	const struct aw2013_chipdef *cdef;
 	int ret;
 	unsigned int chipid;
 
+	cdef = device_get_match_data(&client->dev);
+	if (!cdef)
+		return -ENODEV;
+
 	chip = devm_kzalloc_obj(&client->dev, *chip);
 	if (!chip)
 		return -ENOMEM;
@@ -357,9 +492,10 @@ static int aw2013_probe(struct i2c_client *client)
 	mutex_lock(&chip->mutex);
 
 	chip->client = client;
+	chip->cdef = cdef;
 	i2c_set_clientdata(client, chip);
 
-	chip->regmap = devm_regmap_init_i2c(client, &aw2013_regmap_config);
+	chip->regmap = devm_regmap_init_i2c(client, chip->cdef->regmap_cfg);
 	if (IS_ERR(chip->regmap)) {
 		ret = PTR_ERR(chip->regmap);
 		dev_err(&client->dev, "Failed to allocate register map: %d\n",
@@ -393,8 +529,7 @@ static int aw2013_probe(struct i2c_client *client)
 			ret);
 		goto error_reg;
 	}
-
-	if (chipid != AW2013_RSTR_CHIP_ID) {
+	if (chipid != chip->cdef->chip_id) {
 		dev_err(&client->dev, "Chip reported wrong ID: %x\n",
 			chipid);
 		ret = -ENODEV;
@@ -433,7 +568,8 @@ static int aw2013_probe(struct i2c_client *client)
 }
 
 static const struct of_device_id aw2013_match_table[] = {
-	{ .compatible = "awinic,aw2013", },
+	{ .compatible = "awinic,aw2013", .data = &aw2013_chipdef },
+	{ .compatible = "awinic,aw2027", .data = &aw2027_chipdef },
 	{ /* sentinel */ },
 };
 
@@ -450,5 +586,5 @@ static struct i2c_driver aw2013_driver = {
 module_i2c_driver(aw2013_driver);
 
 MODULE_AUTHOR("Nikita Travkin <nikitos.tr@gmail.com>");
-MODULE_DESCRIPTION("AW2013 LED driver");
+MODULE_DESCRIPTION("AW2013/AW2027 LED driver");
 MODULE_LICENSE("GPL v2");

-- 
2.56.0

