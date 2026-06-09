From: Ferdinand Schwenk <ferdinand.schwenk@advastore.com>
Date: Tue, 09 Jun 2026 21:43:10 +0200
Subject: [PATCH v3 1/3] hwmon: ina238: add support for samples and
 update_interval
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260609-hwmon-ina238-update-interval-us-v2-v3-1-016b55567950@advastore.com>
References: <20260609-hwmon-ina238-update-interval-us-v2-v3-0-016b55567950@advastore.com>
In-Reply-To: <20260609-hwmon-ina238-update-interval-us-v2-v3-0-016b55567950@advastore.com>
To: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, richard.leitner@linux.dev, 
 Ferdinand Schwenk <ferdinand.schwenk@advastore.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781034237; l=10107;
 i=ferdinand.schwenk@advastore.com; h=from:subject:message-id;
 bh=dQHDtHhV2jsrDYAQ4/1ii6QcUe4fOkIwkUXgWO76amw=;
 b=9R7tda8swC237Nwnvh0aQzEwvFvd5G3NuFs3tE/CiaG2yYn2xCkxVSCAt8gYjgxRnRyr0wEBW
 hN9ndkFjGQvAfmS1HXMeU2wipLgdtWLDBu+GRk+eQJewGq23ttS4hhX
X-Developer-Key: i=ferdinand.schwenk@advastore.com; a=ed25519;
 pk=HyA9NdHJ7NystP+1SyuWJeyXNH2EO4A09FXli9mfs9Q=
X-Endpoint-Received: by B4 Relay for ferdinand.schwenk@advastore.com/default with auth_id=788
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Expose INA238 ADC averaging count (AVG) and conversion timing
(VBUSCT/VSHCT/VTCT) through chip-level hwmon attributes:

  chip/samples
  chip/update_interval

Use per-chip conversion-time lookup tables so the same helpers work
for INA228/INA237/INA238/INA700/INA780 and SQ52206. Cache ADC_CONFIG
in driver data and update it on writes to avoid extra register reads
during read-modify-write updates.

Report update_interval in milliseconds as required by the hwmon ABI.
Compute it from raw ADC cycle time multiplied by the active averaging
count, and apply the inverse mapping on writes so programmed conversion
time tracks the selected sample count.

Clamp user-provided update_interval before unit scaling to prevent
overflow in arithmetic conversions.

Also combine chip attributes in HWMON_CHANNEL_INFO using a bitwise OR
for a single logical chip channel.

Signed-off-by: Ferdinand Schwenk <ferdinand.schwenk@advastore.com>
---
 drivers/hwmon/ina238.c | 144 ++++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 142 insertions(+), 2 deletions(-)

diff --git a/drivers/hwmon/ina238.c b/drivers/hwmon/ina238.c
index ff67b03189f7..dc5dd3ad2557 100644
--- a/drivers/hwmon/ina238.c
+++ b/drivers/hwmon/ina238.c
@@ -15,6 +15,7 @@
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/regmap.h>
+#include <linux/util_macros.h>
 
 /* INA238 register definitions */
 #define INA238_CONFIG			0x0
@@ -49,6 +50,17 @@
 #define INA238_DIAG_ALERT_BUSUL		BIT(3)
 #define INA238_DIAG_ALERT_POL		BIT(2)
 
+/* INA238_ADC_CONFIG register field masks and shifts */
+#define INA238_ADC_CONFIG_MODE_MASK	GENMASK(15, 12)
+#define INA238_ADC_CONFIG_VBUSCT_SHIFT	9
+#define INA238_ADC_CONFIG_VBUSCT_MASK	GENMASK(11, 9)
+#define INA238_ADC_CONFIG_VSHCT_SHIFT	6
+#define INA238_ADC_CONFIG_VSHCT_MASK	GENMASK(8, 6)
+#define INA238_ADC_CONFIG_VTCT_SHIFT	3
+#define INA238_ADC_CONFIG_VTCT_MASK	GENMASK(5, 3)
+#define INA238_ADC_CONFIG_AVG_SHIFT	0
+#define INA238_ADC_CONFIG_AVG_MASK	GENMASK(2, 0)
+
 #define INA238_REGISTERS		0x20
 
 #define INA238_RSHUNT_DEFAULT		2500	/* uOhm */
@@ -101,6 +113,21 @@ static const struct regmap_config ina238_regmap_config = {
 	.val_bits = 16,
 };
 
+/* Lookup table for conversion times in usec for INA238 family */
+static const u16 ina238_conv_time[] = {
+	50, 84, 150, 280, 540, 1052, 2074, 4120,
+};
+
+/* Lookup table for conversion times in usec for SQ52206 */
+static const u16 sq52206_conv_time[] = {
+	66, 118, 310, 566, 1070, 2090, 4140, 8230,
+};
+
+/* Lookup table for number of samples used in averaging mode */
+static const int ina238_avg_samples[] = {
+	1, 4, 16, 64, 128, 256, 512, 1024,
+};
+
 enum ina238_ids { ina228, ina237, ina238, ina700, ina780, sq52206 };
 
 struct ina238_config {
@@ -112,6 +139,7 @@ struct ina238_config {
 	u32 power_calculate_factor;	/* fixed parameter for power calculation, from datasheet */
 	u32 bus_voltage_lsb;		/* bus voltage LSB, in nV */
 	int current_lsb;		/* current LSB, in uA */
+	const u16 *conv_time;		/* conversion time lookup table */
 };
 
 struct ina238_data {
@@ -124,6 +152,7 @@ struct ina238_data {
 	int current_lsb;		/* current LSB, in uA */
 	int power_lsb;			/* power LSB, in uW */
 	int energy_lsb;			/* energy LSB, in uJ */
+	u16 adc_config;			/* cached ADC_CONFIG register value */
 };
 
 static const struct ina238_config ina238_config[] = {
@@ -135,6 +164,7 @@ static const struct ina238_config ina238_config[] = {
 		.config_default = INA238_CONFIG_DEFAULT,
 		.bus_voltage_lsb = INA238_BUS_VOLTAGE_LSB,
 		.temp_resolution = 16,
+		.conv_time = ina238_conv_time,
 	},
 	[ina237] = {
 		.has_20bit_voltage_current = false,
@@ -144,6 +174,7 @@ static const struct ina238_config ina238_config[] = {
 		.config_default = INA238_CONFIG_DEFAULT,
 		.bus_voltage_lsb = INA238_BUS_VOLTAGE_LSB,
 		.temp_resolution = 12,
+		.conv_time = ina238_conv_time,
 	},
 	[ina238] = {
 		.has_20bit_voltage_current = false,
@@ -153,6 +184,7 @@ static const struct ina238_config ina238_config[] = {
 		.config_default = INA238_CONFIG_DEFAULT,
 		.bus_voltage_lsb = INA238_BUS_VOLTAGE_LSB,
 		.temp_resolution = 12,
+		.conv_time = ina238_conv_time,
 	},
 	[ina700] = {
 		.has_20bit_voltage_current = false,
@@ -163,6 +195,7 @@ static const struct ina238_config ina238_config[] = {
 		.bus_voltage_lsb = INA238_BUS_VOLTAGE_LSB,
 		.temp_resolution = 12,
 		.current_lsb = 480,
+		.conv_time = ina238_conv_time,
 	},
 	[ina780] = {
 		.has_20bit_voltage_current = false,
@@ -173,6 +206,7 @@ static const struct ina238_config ina238_config[] = {
 		.bus_voltage_lsb = INA238_BUS_VOLTAGE_LSB,
 		.temp_resolution = 12,
 		.current_lsb = 2400,
+		.conv_time = ina238_conv_time,
 	},
 	[sq52206] = {
 		.has_20bit_voltage_current = false,
@@ -182,6 +216,7 @@ static const struct ina238_config ina238_config[] = {
 		.config_default = SQ52206_CONFIG_DEFAULT,
 		.bus_voltage_lsb = SQ52206_BUS_VOLTAGE_LSB,
 		.temp_resolution = 16,
+		.conv_time = sq52206_conv_time,
 	},
 };
 
@@ -261,6 +296,97 @@ static int ina228_read_voltage(struct ina238_data *data, int channel, long *val)
 	return 0;
 }
 
+/* Converting ADC_CONFIG register value to update_interval in usec */
+static inline u32 ina238_reg_to_interval_us(struct ina238_data *data)
+{
+	const u16 *ct = data->config->conv_time;
+	u32 vbusct = ct[(data->adc_config & INA238_ADC_CONFIG_VBUSCT_MASK) >>
+			INA238_ADC_CONFIG_VBUSCT_SHIFT];
+	u32 vshct  = ct[(data->adc_config & INA238_ADC_CONFIG_VSHCT_MASK) >>
+			INA238_ADC_CONFIG_VSHCT_SHIFT];
+	u32 vtct   = ct[(data->adc_config & INA238_ADC_CONFIG_VTCT_MASK) >>
+			INA238_ADC_CONFIG_VTCT_SHIFT];
+
+	return vbusct + vshct + vtct;
+}
+
+static inline u32 ina238_samples(struct ina238_data *data)
+{
+	return ina238_avg_samples[(data->adc_config & INA238_ADC_CONFIG_AVG_MASK) >>
+				  INA238_ADC_CONFIG_AVG_SHIFT];
+}
+
+/* Converting update_interval in msec to a single conversion time in usec */
+static inline u32 ina238_interval_ms_to_conv_time(long interval, u32 samples)
+{
+	u64 interval_us;
+
+	interval = clamp_val(interval, 0, INT_MAX / 1000);
+	interval_us = (u64)interval * 1000;
+
+	/*
+	 * update_interval reports the ADC cycle time including averaging.
+	 * The target per-field conversion time is interval_us / (samples * 3).
+	 */
+	return DIV_ROUND_CLOSEST_ULL(interval_us, samples * 3);
+}
+
+static int ina238_read_chip(struct device *dev, u32 attr, long *val)
+{
+	struct ina238_data *data = dev_get_drvdata(dev);
+
+	switch (attr) {
+	case hwmon_chip_samples:
+		*val = ina238_samples(data);
+		return 0;
+	case hwmon_chip_update_interval:
+		/* Return in msec */
+		*val = DIV_ROUND_CLOSEST(ina238_reg_to_interval_us(data) *
+					ina238_samples(data), 1000);
+		return 0;
+	default:
+		return -EOPNOTSUPP;
+	}
+}
+
+static int ina238_write_chip(struct device *dev, u32 attr, long val)
+{
+	struct ina238_data *data = dev_get_drvdata(dev);
+	u16 adc_config;
+	int idx, ret;
+
+	switch (attr) {
+	case hwmon_chip_samples:
+		idx = find_closest(val, ina238_avg_samples,
+				   ARRAY_SIZE(ina238_avg_samples));
+		adc_config = (data->adc_config & ~INA238_ADC_CONFIG_AVG_MASK) |
+			     (idx << INA238_ADC_CONFIG_AVG_SHIFT);
+		ret = regmap_write(data->regmap, INA238_ADC_CONFIG, adc_config);
+		if (ret)
+			return ret;
+		data->adc_config = adc_config;
+		return 0;
+	case hwmon_chip_update_interval:
+		val = ina238_interval_ms_to_conv_time(val, ina238_samples(data));
+		idx = find_closest(val, data->config->conv_time,
+				   ARRAY_SIZE(ina238_conv_time));
+		adc_config = (data->adc_config &
+			      ~(INA238_ADC_CONFIG_VBUSCT_MASK |
+				INA238_ADC_CONFIG_VSHCT_MASK |
+				INA238_ADC_CONFIG_VTCT_MASK)) |
+			     ((u16)idx << INA238_ADC_CONFIG_VBUSCT_SHIFT) |
+			     ((u16)idx << INA238_ADC_CONFIG_VSHCT_SHIFT) |
+			     ((u16)idx << INA238_ADC_CONFIG_VTCT_SHIFT);
+		ret = regmap_write(data->regmap, INA238_ADC_CONFIG, adc_config);
+		if (ret)
+			return ret;
+		data->adc_config = adc_config;
+		return 0;
+	default:
+		return -EOPNOTSUPP;
+	}
+}
+
 static int ina238_read_in(struct device *dev, u32 attr, int channel,
 			  long *val)
 {
@@ -587,6 +713,8 @@ static int ina238_read(struct device *dev, enum hwmon_sensor_types type,
 		       u32 attr, int channel, long *val)
 {
 	switch (type) {
+	case hwmon_chip:
+		return ina238_read_chip(dev, attr, val);
 	case hwmon_in:
 		return ina238_read_in(dev, attr, channel, val);
 	case hwmon_curr:
@@ -607,6 +735,8 @@ static int ina238_write(struct device *dev, enum hwmon_sensor_types type,
 			u32 attr, int channel, long val)
 {
 	switch (type) {
+	case hwmon_chip:
+		return ina238_write_chip(dev, attr, val);
 	case hwmon_in:
 		return ina238_write_in(dev, attr, channel, val);
 	case hwmon_curr:
@@ -629,6 +759,14 @@ static umode_t ina238_is_visible(const void *drvdata,
 	bool has_energy = data->config->has_energy;
 
 	switch (type) {
+	case hwmon_chip:
+		switch (attr) {
+		case hwmon_chip_samples:
+		case hwmon_chip_update_interval:
+			return 0644;
+		default:
+			return 0;
+		}
 	case hwmon_in:
 		switch (attr) {
 		case hwmon_in_input:
@@ -692,6 +830,8 @@ static umode_t ina238_is_visible(const void *drvdata,
 				HWMON_I_MIN | HWMON_I_MIN_ALARM)
 
 static const struct hwmon_channel_info * const ina238_info[] = {
+	HWMON_CHANNEL_INFO(chip,
+			   HWMON_C_SAMPLES | HWMON_C_UPDATE_INTERVAL),
 	HWMON_CHANNEL_INFO(in,
 			   /* 0: shunt voltage */
 			   INA238_HWMON_IN_CONFIG,
@@ -798,8 +938,8 @@ static int ina238_probe(struct i2c_client *client)
 	}
 
 	/* Setup ADC_CONFIG register */
-	ret = regmap_write(data->regmap, INA238_ADC_CONFIG,
-			   INA238_ADC_CONFIG_DEFAULT);
+	data->adc_config = INA238_ADC_CONFIG_DEFAULT;
+	ret = regmap_write(data->regmap, INA238_ADC_CONFIG, data->adc_config);
 	if (ret < 0) {
 		dev_err(dev, "error configuring the device: %d\n", ret);
 		return -ENODEV;

-- 
2.54.0

