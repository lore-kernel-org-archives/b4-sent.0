From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Thu, 02 Jan 2025 12:15:03 +0100
Subject: [PATCH v2 1/4] power: supply: add support for max77759 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-b4-gs101_max77759_fg-v2-1-87959abeb7ff@uclouvain.be>
References: <20250102-b4-gs101_max77759_fg-v2-0-87959abeb7ff@uclouvain.be>
In-Reply-To: <20250102-b4-gs101_max77759_fg-v2-0-87959abeb7ff@uclouvain.be>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735816515; l=11285;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=4IBL246Fhqd8ttrmprrDpul0IZFfaEgZlroRGDMXvR0=;
 b=G/RKsQ1nU4D1xA5pEpCVOpAbdQXgpvT7DmVsoImMwv94qnAd5VaLPNVuvpEnWA/eEmjkj4W76
 Kolf6kKjJSCCoxnV63/r7ILZI1eAXDXclQCTpA/ALDbKj0Og/mYGpK/
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The interface of the Maxim max77759 fuel gauge has a lot of common with the
Maxim max1720x. The major difference is the lack of non-volatile memory
slave address. No slave is available at address 0xb of the i2c bus, which
is coherent with the following driver from google: line 5836 disables
non-volatile memory for m5 gauge.

Link: https://android.googlesource.com/kernel/google-modules/bms/+/1a68c36bef474573cc8629cc1d121eb6a81ab68c/max1720x_battery.c

Other differences include the lack of V_BATT register to read the battery
level and a difference in the way to identify the chip (the same register
is used but not the same mask).

Add support for the max77759 by allowing to use the non-volatile
memory or not based on the chip. Also add the V_CELL regsister as a
fallback to read voltage value in the case where read of V_BATT fails.

The cast is necessary to avoid an overflow when the value of the register
is above 54975 (equivalent to a voltage around 4.29 V).

The regmap of the max77759 will lead the read to fail for V_BATT and to
correctly use V_CELL instead. This regmap was proposed by André Draszik in

Link: https://lore.kernel.org/all/d1bade77b5281c1de6b2ddcb4dbbd033e455a116.camel@linaro.org/

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 drivers/power/supply/max1720x_battery.c | 189 +++++++++++++++++++++++++++-----
 1 file changed, 164 insertions(+), 25 deletions(-)

diff --git a/drivers/power/supply/max1720x_battery.c b/drivers/power/supply/max1720x_battery.c
index 33105419e2427bb37963bda9948b647c239f8faa..a41976679eded44fbd13120ad756a626d2867919 100644
--- a/drivers/power/supply/max1720x_battery.c
+++ b/drivers/power/supply/max1720x_battery.c
@@ -27,6 +27,7 @@
 #define MAX172XX_REPCAP			0x05	/* Average capacity */
 #define MAX172XX_REPSOC			0x06	/* Percentage of charge */
 #define MAX172XX_TEMP			0x08	/* Temperature */
+#define MAX172XX_VCELL			0x09	/* Lowest cell voltage */
 #define MAX172XX_CURRENT		0x0A	/* Actual current */
 #define MAX172XX_AVG_CURRENT		0x0B	/* Average current */
 #define MAX172XX_TTE			0x11	/* Time to empty */
@@ -39,6 +40,8 @@
 #define MAX172XX_DEV_NAME_TYPE_MASK	GENMASK(3, 0)
 #define MAX172XX_DEV_NAME_TYPE_MAX17201	BIT(0)
 #define MAX172XX_DEV_NAME_TYPE_MAX17205	(BIT(0) | BIT(2))
+#define MAX77759_DEV_NAME_TYPE_MASK	GENMASK(15, 9)
+#define MAX77759_DEV_NAME_TYPE_MAX77759	0x31
 #define MAX172XX_QR_TABLE10		0x22
 #define MAX172XX_BATT			0xDA	/* Battery voltage */
 #define MAX172XX_ATAVCAP		0xDF
@@ -46,12 +49,20 @@
 static const char *const max1720x_manufacturer = "Maxim Integrated";
 static const char *const max17201_model = "MAX17201";
 static const char *const max17205_model = "MAX17205";
+static const char *const max77759_model = "MAX77759";
+
+enum chip_id {
+	MAX1720X_ID,
+	MAX77759_ID,
+};
 
 struct max1720x_device_info {
 	struct regmap *regmap;
 	struct regmap *regmap_nv;
 	struct i2c_client *ancillary;
 	int rsense;
+	int has_nvmem;
+	enum chip_id id;
 };
 
 /*
@@ -254,6 +265,67 @@ static const enum power_supply_property max1720x_battery_props[] = {
 	POWER_SUPPLY_PROP_MANUFACTURER,
 };
 
+/*
+ * Registers 0x80 up to 0xaf which contain the model for the fuel gauge
+ * algorithm (stored in nvmem for the max1720x) are locked. They can
+ * be unlocked by writing 0x59 to 0x62 and 0xc4 to 0x63. They should be
+ * enabled in the regmap if the driver is extended to manage the model.
+ */
+static const struct regmap_range max77759_registers[] = {
+	regmap_reg_range(0x00, 0x4f),
+	regmap_reg_range(0xb0, 0xbf),
+	regmap_reg_range(0xd0, 0xd0),
+	regmap_reg_range(0xdc, 0xdf),
+	regmap_reg_range(0xfb, 0xfb),
+	regmap_reg_range(0xff, 0xff),
+};
+
+static const struct regmap_range max77759_ro_registers[] = {
+	regmap_reg_range(0x3d, 0x3d),
+	regmap_reg_range(0xfb, 0xfb),
+	regmap_reg_range(0xff, 0xff),
+};
+
+static const struct regmap_access_table max77759_write_table = {
+	.yes_ranges = max77759_registers,
+	.n_yes_ranges = ARRAY_SIZE(max77759_registers),
+	.no_ranges = max77759_ro_registers,
+	.n_no_ranges = ARRAY_SIZE(max77759_ro_registers),
+};
+
+static const struct regmap_access_table max77759_rd_table = {
+	.yes_ranges = max77759_registers,
+	.n_yes_ranges = ARRAY_SIZE(max77759_registers),
+};
+
+static const struct regmap_config max77759_regmap_cfg = {
+	.reg_bits = 8,
+	.val_bits = 16,
+	.max_register = 0xff,
+	.wr_table = &max77759_write_table,
+	.rd_table = &max77759_rd_table,
+	.val_format_endian = REGMAP_ENDIAN_LITTLE,
+	.cache_type = REGCACHE_NONE,
+};
+
+struct chip_data {
+	u8 has_nvmem;
+	const struct regmap_config *regmap_cfg;
+	enum chip_id id;
+};
+
+static const struct chip_data max1720x_data  = {
+	.has_nvmem = 1,
+	.regmap_cfg = &max1720x_regmap_cfg,
+	.id = MAX1720X_ID,
+};
+
+static const struct chip_data max77759_data = {
+	.has_nvmem = 0,
+	.regmap_cfg = &max77759_regmap_cfg,
+	.id = MAX77759_ID,
+};
+
 /* Convert regs value to power_supply units */
 
 static int max172xx_time_to_ps(unsigned int reg)
@@ -271,6 +343,14 @@ static int max172xx_voltage_to_ps(unsigned int reg)
 	return reg * 1250;	/* in uV */
 }
 
+// Use 64 bits because computation on 32 bits leads to an overflow
+static int max172xx_cell_voltage_to_ps(unsigned int reg)
+{
+	u64 val = reg;
+
+	return val * 78125 / 1000;	/* in uV */
+}
+
 static int max172xx_capacity_to_ps(unsigned int reg)
 {
 	return reg * 500;	/* in uAh */
@@ -303,6 +383,33 @@ static int max172xx_current_to_voltage(unsigned int reg)
 	return val * 156252;
 }
 
+static int max1720x_devname_to_model(unsigned int reg_val,
+					union power_supply_propval *val,
+					struct max1720x_device_info *info)
+{
+	switch (info->id) {
+	case MAX1720X_ID:
+		reg_val = FIELD_GET(MAX172XX_DEV_NAME_TYPE_MASK, reg_val);
+		if (reg_val == MAX172XX_DEV_NAME_TYPE_MAX17201)
+			val->strval = max17201_model;
+		else if (reg_val == MAX172XX_DEV_NAME_TYPE_MAX17205)
+			val->strval = max17205_model;
+		else
+			return -ENODEV;
+		break;
+	case MAX77759_ID:
+		reg_val = FIELD_GET(MAX77759_DEV_NAME_TYPE_MASK, reg_val);
+		if (reg_val == MAX77759_DEV_NAME_TYPE_MAX77759)
+			val->strval = max77759_model;
+		else
+			return -ENODEV;
+		break;
+	default:
+		return -ENODEV;
+	}
+	return 0;
+}
+
 static int max1720x_battery_get_property(struct power_supply *psy,
 					 enum power_supply_property psp,
 					 union power_supply_propval *val)
@@ -332,7 +439,12 @@ static int max1720x_battery_get_property(struct power_supply *psy,
 		break;
 	case POWER_SUPPLY_PROP_VOLTAGE_NOW:
 		ret = regmap_read(info->regmap, MAX172XX_BATT, &reg_val);
-		val->intval = max172xx_voltage_to_ps(reg_val);
+		if (!ret)
+			val->intval = max172xx_voltage_to_ps(reg_val);
+		else {
+			ret = regmap_read(info->regmap, MAX172XX_VCELL, &reg_val);
+			val->intval = max172xx_cell_voltage_to_ps(reg_val);
+		}
 		break;
 	case POWER_SUPPLY_PROP_CHARGE_FULL_DESIGN:
 		ret = regmap_read(info->regmap, MAX172XX_DESIGN_CAP, &reg_val);
@@ -364,13 +476,8 @@ static int max1720x_battery_get_property(struct power_supply *psy,
 		break;
 	case POWER_SUPPLY_PROP_MODEL_NAME:
 		ret = regmap_read(info->regmap, MAX172XX_DEV_NAME, &reg_val);
-		reg_val = FIELD_GET(MAX172XX_DEV_NAME_TYPE_MASK, reg_val);
-		if (reg_val == MAX172XX_DEV_NAME_TYPE_MAX17201)
-			val->strval = max17201_model;
-		else if (reg_val == MAX172XX_DEV_NAME_TYPE_MAX17205)
-			val->strval = max17205_model;
-		else
-			return -ENODEV;
+		if (!ret)
+			ret = max1720x_devname_to_model(reg_val, val, info);
 		break;
 	case POWER_SUPPLY_PROP_MANUFACTURER:
 		val->strval = max1720x_manufacturer;
@@ -416,7 +523,6 @@ static int max1720x_probe_nvmem(struct i2c_client *client,
 		.priv = info,
 	};
 	struct nvmem_device *nvmem;
-	unsigned int val;
 	int ret;
 
 	info->ancillary = i2c_new_ancillary_device(client, "nvmem", 0xb);
@@ -438,18 +544,6 @@ static int max1720x_probe_nvmem(struct i2c_client *client,
 		return PTR_ERR(info->regmap_nv);
 	}
 
-	ret = regmap_read(info->regmap_nv, MAX1720X_NRSENSE, &val);
-	if (ret < 0) {
-		dev_err(dev, "Failed to read sense resistor value\n");
-		return ret;
-	}
-
-	info->rsense = val;
-	if (!info->rsense) {
-		dev_warn(dev, "RSense not calibrated, set 10 mOhms!\n");
-		info->rsense = 1000; /* in regs in 10^-5 */
-	}
-
 	nvmem = devm_nvmem_register(dev, &nvmem_config);
 	if (IS_ERR(nvmem)) {
 		dev_err(dev, "Could not register nvmem!");
@@ -459,6 +553,36 @@ static int max1720x_probe_nvmem(struct i2c_client *client,
 	return 0;
 }
 
+static int max1720x_get_rsense(struct device *dev,
+					 struct max1720x_device_info *info)
+{
+	unsigned int val;
+	int ret;
+
+	if (info->has_nvmem) {
+		ret = regmap_read(info->regmap_nv, MAX1720X_NRSENSE, &val);
+		if (ret < 0) {
+			dev_err(dev, "Failed to read RSense from nvmem\n");
+			return ret;
+		}
+
+		info->rsense = val;
+		if (!info->rsense) {
+			dev_warn(dev, "RSense not calibrated, set 10 mOhms!\n");
+			info->rsense = 1000; /* in regs in 10^-5 */
+		}
+	} else {
+		ret = of_property_read_u32(dev->of_node,
+					"shunt-resistor-micro-ohms", &val);
+		if (ret) {
+			dev_err(dev, "Failed to read RSense from devicetree\n");
+			return ret;
+		}
+		info->rsense = val/10;
+	}
+	return 0;
+}
+
 static const struct power_supply_desc max1720x_bat_desc = {
 	.name = "max1720x",
 	.no_thermal = true,
@@ -474,6 +598,7 @@ static int max1720x_probe(struct i2c_client *client)
 	struct device *dev = &client->dev;
 	struct max1720x_device_info *info;
 	struct power_supply *bat;
+	const struct chip_data *data;
 	int ret;
 
 	info = devm_kzalloc(dev, sizeof(*info), GFP_KERNEL);
@@ -483,14 +608,27 @@ static int max1720x_probe(struct i2c_client *client)
 	psy_cfg.drv_data = info;
 	psy_cfg.fwnode = dev_fwnode(dev);
 	i2c_set_clientdata(client, info);
-	info->regmap = devm_regmap_init_i2c(client, &max1720x_regmap_cfg);
+
+	data = device_get_match_data(dev);
+	if (!data)
+		return dev_err_probe(dev, ret, "Failed to get chip data\n");
+
+	info->has_nvmem = data->has_nvmem;
+	info->id = data->id;
+	info->regmap = devm_regmap_init_i2c(client, data->regmap_cfg);
 	if (IS_ERR(info->regmap))
 		return dev_err_probe(dev, PTR_ERR(info->regmap),
 				     "regmap initialization failed\n");
 
-	ret = max1720x_probe_nvmem(client, info);
+	if (data->has_nvmem) {
+		ret = max1720x_probe_nvmem(client, info);
+		if (ret)
+			return dev_err_probe(dev, ret, "Failed to probe nvmem\n");
+	}
+
+	ret = max1720x_get_rsense(dev, info);
 	if (ret)
-		return dev_err_probe(dev, ret, "Failed to probe nvmem\n");
+		return dev_err_probe(dev, ret, "Failed to get RSense");
 
 	bat = devm_power_supply_register(dev, &max1720x_bat_desc, &psy_cfg);
 	if (IS_ERR(bat))
@@ -501,7 +639,8 @@ static int max1720x_probe(struct i2c_client *client)
 }
 
 static const struct of_device_id max1720x_of_match[] = {
-	{ .compatible = "maxim,max17201" },
+	{ .compatible = "maxim,max17201", .data = (void *) &max1720x_data },
+	{ .compatible = "maxim,max77759-fg", .data = (void *) &max77759_data },
 	{}
 };
 MODULE_DEVICE_TABLE(of, max1720x_of_match);

-- 
2.47.1

