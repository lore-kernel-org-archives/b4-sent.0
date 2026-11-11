From: Asdlerto Korry <korryasdlerto@gmail.com>
Date: Wed, 11 Nov 2026 17:35:00 +0200
Subject: [PATCH 2/2] power: supply: Add Silicon Mitus SM5714 fuel gauge
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-sm5714-fuel-gauge-v1-2-b9d163fff6ff@gmail.com>
References: <20261111-sm5714-fuel-gauge-v1-0-b9d163fff6ff@gmail.com>
In-Reply-To: <20261111-sm5714-fuel-gauge-v1-0-b9d163fff6ff@gmail.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Asdlerto Korry <korryasdlerto@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794411298; l=12513;
 i=korryasdlerto@gmail.com; s=20261104; h=from:subject:message-id;
 bh=Lekw6INBVEp1iVKbC0YMJC/5A9IPhd7ZRU9tU/Z8NkQ=;
 b=b/n9TcF/G8t/DDbVp5imIHjQYzoUdaoRcktvrc/3c6xhnW7rPp6+nIAI7fUFmn3dbxUZqdebe
 Jzm0zwapcwJA8/0VqjaLCar1e6NPpZ5UOZzYB+E5AVVGUxTa1PEccwQ
X-Developer-Key: i=korryasdlerto@gmail.com; a=ed25519;
 pk=RqttIGkm2XZ8NhLQBzPgpXXawOdVa1uODGsk+sagbxs=
X-Endpoint-Received: by B4 Relay for korryasdlerto@gmail.com/20261104 with auth_id=1411
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver for the fuel gauge of the Silicon Mitus SM5714. The gauge
keeps its results in an internal SRAM that is read through an address
and a data register. The driver only reads: it reports the state of
charge, the battery voltage (now, average and open-circuit), the current
(now and average) and the temperature. The conversions follow the vendor
driver.

The temperature reported by the gauge rises with the charge current, so
the battery temperature is read from the thermistor ADC channel when the
devicetree provides one.

The gauge interrupt is not used, power_supply_changed() is reported once
a minute.

Signed-off-by: Asdlerto Korry <korryasdlerto@gmail.com>
---
 MAINTAINERS                              |   7 +
 drivers/power/supply/Kconfig             |  13 ++
 drivers/power/supply/Makefile            |   1 +
 drivers/power/supply/sm5714_fuel_gauge.c | 315 +++++++++++++++++++++++++++++++
 4 files changed, 336 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index aaf2825ac945..9d08b04c1537 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25750,6 +25750,13 @@ S:	Supported
 F:	Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml
 F:	drivers/net/wireless/silabs/
 
+SILICON MITUS SM5714 FUEL GAUGE DRIVER
+M:	Asdlerto Korry <korryasdlerto@gmail.com>
+L:	linux-pm@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/power/supply/siliconmitus,sm5714-fuelgauge.yaml
+F:	drivers/power/supply/sm5714_fuel_gauge.c
+
 SILICON MOTION SM712 FRAME BUFFER DRIVER
 M:	Sudip Mukherjee <sudipm.mukherjee@gmail.com>
 M:	Teddy Wang <teddy.wang@siliconmotion.com>
diff --git a/drivers/power/supply/Kconfig b/drivers/power/supply/Kconfig
index ee7dc5f2617a..a84de54229cd 100644
--- a/drivers/power/supply/Kconfig
+++ b/drivers/power/supply/Kconfig
@@ -1192,6 +1192,19 @@ config FUEL_GAUGE_MM8013
 	  the state of charge, temperature, cycle count, actual and design
 	  capacity, etc.
 
+config BATTERY_SM5714
+	tristate "Silicon Mitus SM5714 fuel gauge driver"
+	depends on I2C
+	depends on IIO
+	select REGMAP_I2C
+	help
+	  Say Y here to enable the driver for the fuel gauge of the Silicon
+	  Mitus SM5714 power management chip. It reports the battery state of
+	  charge, voltage, current and temperature.
+
+	  This driver can also be built as a module. If so, the module will be
+	  called sm5714_fuel_gauge.
+
 config MACSMC_POWER
 	tristate "Apple SMC Battery and Power Driver"
 	depends on MFD_MACSMC
diff --git a/drivers/power/supply/Makefile b/drivers/power/supply/Makefile
index f3c0d1006c1a..00d0f975f5ec 100644
--- a/drivers/power/supply/Makefile
+++ b/drivers/power/supply/Makefile
@@ -133,5 +133,6 @@ obj-$(CONFIG_BATTERY_CHARGER_SURFACE_RT) += surface-rt-ec.o
 obj-$(CONFIG_BATTERY_UG3105)	+= ug3105_battery.o
 obj-$(CONFIG_CHARGER_QCOM_SMB2)	+= qcom_smbx.o
 obj-$(CONFIG_FUEL_GAUGE_MM8013)	+= mm8013.o
+obj-$(CONFIG_BATTERY_SM5714)	+= sm5714_fuel_gauge.o
 obj-$(CONFIG_MACSMC_POWER)	+= macsmc-power.o
 obj-$(CONFIG_CHARGER_MAX77759)	+= max77759_charger.o
diff --git a/drivers/power/supply/sm5714_fuel_gauge.c b/drivers/power/supply/sm5714_fuel_gauge.c
new file mode 100644
index 000000000000..531583fb211b
--- /dev/null
+++ b/drivers/power/supply/sm5714_fuel_gauge.c
@@ -0,0 +1,315 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Silicon Mitus SM5714 fuel gauge driver
+ *
+ * The gauge keeps its results in an internal SRAM: the SRAM address is
+ * written to RADDR, then the 16-bit word is read from RDATA. The driver only
+ * reads; the gauge algorithm and charging stay under hardware control. The
+ * conversions follow the vendor driver.
+ *
+ * The temperature measured by the gauge itself rises with the charge current,
+ * so the battery temperature is read from the battery thermistor ADC channel
+ * when the devicetree provides one.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+#include <linux/devm-helpers.h>
+#include <linux/i2c.h>
+#include <linux/iio/consumer.h>
+#include <linux/minmax.h>
+#include <linux/module.h>
+#include <linux/mod_devicetable.h>
+#include <linux/mutex.h>
+#include <linux/power_supply.h>
+#include <linux/regmap.h>
+#include <linux/workqueue.h>
+
+#define SM5714_FG_REG_DEVICE_ID		0x00
+#define SM5714_FG_REG_AUX_STAT		0x22
+#define SM5714_FG_REG_SRAM_RADDR	0x8c
+#define SM5714_FG_REG_SRAM_RDATA	0x8d
+
+#define SM5714_FG_SRAM_SOC		0x00
+#define SM5714_FG_SRAM_OCV		0x01
+#define SM5714_FG_SRAM_VBAT		0x03
+#define SM5714_FG_SRAM_CURRENT		0x05
+#define SM5714_FG_SRAM_TEMPERATURE	0x07
+#define SM5714_FG_SRAM_VBAT_AVG		0x08
+#define SM5714_FG_SRAM_CURRENT_AVG	0x09
+
+#define SM5714_FG_AUX_STAT_CHG_ON	BIT(5)
+#define SM5714_FG_AUX_STAT_CURR_X2_5	BIT(10)
+
+#define SM5714_FG_SIGN			BIT(15)
+#define SM5714_FG_MAGNITUDE		GENMASK(14, 0)
+
+/* the gauge interrupt is not used: report changes periodically */
+#define SM5714_FG_POLL_INTERVAL		(60 * HZ)
+
+struct sm5714_fg {
+	struct regmap *regmap;
+	struct power_supply *psy;
+	struct iio_channel *ntc;	/* NULL: use the gauge temperature */
+	struct mutex lock;		/* RADDR/RDATA pair */
+	struct delayed_work work;
+};
+
+static const struct regmap_config sm5714_fg_regmap_config = {
+	.reg_bits = 8,
+	.val_bits = 16,
+	.val_format_endian = REGMAP_ENDIAN_LITTLE,
+	.max_register = SM5714_FG_REG_SRAM_RDATA,
+};
+
+static int sm5714_fg_read_sram(struct sm5714_fg *fg, u8 addr, unsigned int *val)
+{
+	int ret;
+
+	mutex_lock(&fg->lock);
+	ret = regmap_write(fg->regmap, SM5714_FG_REG_SRAM_RADDR, addr);
+	if (!ret)
+		ret = regmap_read(fg->regmap, SM5714_FG_REG_SRAM_RDATA, val);
+	mutex_unlock(&fg->lock);
+
+	return ret;
+}
+
+/* 0.1 % */
+static int sm5714_fg_soc_permille(unsigned int raw)
+{
+	return (raw * 10) >> 8;
+}
+
+/* mV */
+static int sm5714_fg_raw_to_mv(unsigned int raw)
+{
+	int mv = (FIELD_GET(SM5714_FG_MAGNITUDE, raw) * 10) / 109;
+
+	return raw & SM5714_FG_SIGN ? 2700 - mv : 2700 + mv;
+}
+
+/* mA, positive while charging */
+static int sm5714_fg_get_current_ma(struct sm5714_fg *fg, u8 sram, int *ma)
+{
+	unsigned int raw, aux;
+	int ret;
+
+	ret = sm5714_fg_read_sram(fg, sram, &raw);
+	if (ret)
+		return ret;
+	ret = regmap_read(fg->regmap, SM5714_FG_REG_AUX_STAT, &aux);
+	if (ret)
+		return ret;
+
+	*ma = (FIELD_GET(SM5714_FG_MAGNITUDE, raw) * 1000) / 2044;
+	if (raw & SM5714_FG_SIGN)
+		*ma = -*ma;
+	if (aux & SM5714_FG_AUX_STAT_CURR_X2_5)
+		*ma = *ma * 25 / 10;
+
+	return 0;
+}
+
+/* 0.1 degC */
+static int sm5714_fg_get_temp(struct sm5714_fg *fg, int *temp)
+{
+	unsigned int raw;
+	int ret, mdegc;
+
+	if (fg->ntc) {
+		ret = iio_read_channel_processed(fg->ntc, &mdegc);
+		if (ret < 0)
+			return ret;
+		*temp = mdegc / 100;
+		return 0;
+	}
+
+	ret = sm5714_fg_read_sram(fg, SM5714_FG_SRAM_TEMPERATURE, &raw);
+	if (ret)
+		return ret;
+
+	*temp = ((FIELD_GET(SM5714_FG_MAGNITUDE, raw) * 10) * 2989) >> 19;
+	if (raw & SM5714_FG_SIGN)
+		*temp = -*temp;
+
+	return 0;
+}
+
+static int sm5714_fg_get_status(struct sm5714_fg *fg, int *status)
+{
+	unsigned int aux, soc;
+	int ma, ret;
+
+	ret = regmap_read(fg->regmap, SM5714_FG_REG_AUX_STAT, &aux);
+	if (ret)
+		return ret;
+	ret = sm5714_fg_read_sram(fg, SM5714_FG_SRAM_SOC, &soc);
+	if (ret)
+		return ret;
+	ret = sm5714_fg_get_current_ma(fg, SM5714_FG_SRAM_CURRENT_AVG, &ma);
+	if (ret)
+		return ret;
+
+	/* the charger stops after top-off while the adapter stays connected */
+	if (!(aux & SM5714_FG_AUX_STAT_CHG_ON) && power_supply_am_i_supplied(fg->psy) <= 0)
+		*status = POWER_SUPPLY_STATUS_DISCHARGING;
+	else if (sm5714_fg_soc_permille(soc) >= 990)
+		*status = POWER_SUPPLY_STATUS_FULL;
+	else if (ma > 0)
+		*status = POWER_SUPPLY_STATUS_CHARGING;
+	else
+		*status = POWER_SUPPLY_STATUS_NOT_CHARGING;
+
+	return 0;
+}
+
+static int sm5714_fg_get_property(struct power_supply *psy,
+				  enum power_supply_property psp,
+				  union power_supply_propval *val)
+{
+	struct sm5714_fg *fg = power_supply_get_drvdata(psy);
+	unsigned int raw;
+	int ret;
+
+	switch (psp) {
+	case POWER_SUPPLY_PROP_STATUS:
+		return sm5714_fg_get_status(fg, &val->intval);
+	case POWER_SUPPLY_PROP_PRESENT:
+		val->intval = 1;
+		return 0;
+	case POWER_SUPPLY_PROP_TECHNOLOGY:
+		val->intval = POWER_SUPPLY_TECHNOLOGY_LION;
+		return 0;
+	case POWER_SUPPLY_PROP_CAPACITY:
+		ret = sm5714_fg_read_sram(fg, SM5714_FG_SRAM_SOC, &raw);
+		if (ret)
+			return ret;
+		val->intval = clamp((sm5714_fg_soc_permille(raw) + 5) / 10, 0, 100);
+		return 0;
+	case POWER_SUPPLY_PROP_VOLTAGE_NOW:
+	case POWER_SUPPLY_PROP_VOLTAGE_AVG:
+		ret = sm5714_fg_read_sram(fg, psp == POWER_SUPPLY_PROP_VOLTAGE_NOW ?
+					  SM5714_FG_SRAM_VBAT : SM5714_FG_SRAM_VBAT_AVG, &raw);
+		if (ret)
+			return ret;
+		val->intval = sm5714_fg_raw_to_mv(raw) * 1000;
+		return 0;
+	case POWER_SUPPLY_PROP_VOLTAGE_OCV:
+		ret = sm5714_fg_read_sram(fg, SM5714_FG_SRAM_OCV, &raw);
+		if (ret)
+			return ret;
+		val->intval = ((raw * 1000) >> 11) * 1000;
+		return 0;
+	case POWER_SUPPLY_PROP_CURRENT_NOW:
+	case POWER_SUPPLY_PROP_CURRENT_AVG:
+		ret = sm5714_fg_get_current_ma(fg, psp == POWER_SUPPLY_PROP_CURRENT_NOW ?
+					       SM5714_FG_SRAM_CURRENT :
+					       SM5714_FG_SRAM_CURRENT_AVG, &val->intval);
+		if (ret)
+			return ret;
+		val->intval *= 1000;
+		return 0;
+	case POWER_SUPPLY_PROP_TEMP:
+		return sm5714_fg_get_temp(fg, &val->intval);
+	default:
+		return -EINVAL;
+	}
+}
+
+static const enum power_supply_property sm5714_fg_props[] = {
+	POWER_SUPPLY_PROP_STATUS,
+	POWER_SUPPLY_PROP_PRESENT,
+	POWER_SUPPLY_PROP_TECHNOLOGY,
+	POWER_SUPPLY_PROP_CAPACITY,
+	POWER_SUPPLY_PROP_VOLTAGE_NOW,
+	POWER_SUPPLY_PROP_VOLTAGE_AVG,
+	POWER_SUPPLY_PROP_VOLTAGE_OCV,
+	POWER_SUPPLY_PROP_CURRENT_NOW,
+	POWER_SUPPLY_PROP_CURRENT_AVG,
+	POWER_SUPPLY_PROP_TEMP,
+};
+
+static const struct power_supply_desc sm5714_fg_desc = {
+	.name		= "battery",
+	.type		= POWER_SUPPLY_TYPE_BATTERY,
+	.properties	= sm5714_fg_props,
+	.num_properties	= ARRAY_SIZE(sm5714_fg_props),
+	.get_property	= sm5714_fg_get_property,
+};
+
+static void sm5714_fg_work(struct work_struct *work)
+{
+	struct sm5714_fg *fg = container_of(work, struct sm5714_fg, work.work);
+
+	power_supply_changed(fg->psy);
+	schedule_delayed_work(&fg->work, SM5714_FG_POLL_INTERVAL);
+}
+
+static int sm5714_fg_probe(struct i2c_client *client)
+{
+	struct device *dev = &client->dev;
+	struct power_supply_config cfg = {};
+	struct sm5714_fg *fg;
+	unsigned int id;
+	int ret;
+
+	fg = devm_kzalloc(dev, sizeof(*fg), GFP_KERNEL);
+	if (!fg)
+		return -ENOMEM;
+
+	ret = devm_mutex_init(dev, &fg->lock);
+	if (ret)
+		return ret;
+
+	fg->regmap = devm_regmap_init_i2c(client, &sm5714_fg_regmap_config);
+	if (IS_ERR(fg->regmap))
+		return dev_err_probe(dev, PTR_ERR(fg->regmap), "failed to init regmap\n");
+
+	ret = regmap_read(fg->regmap, SM5714_FG_REG_DEVICE_ID, &id);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to read device id\n");
+
+	fg->ntc = devm_iio_channel_get(dev, NULL);
+	if (IS_ERR(fg->ntc)) {
+		ret = PTR_ERR(fg->ntc);
+		if (ret != -ENODEV)
+			return dev_err_probe(dev, ret, "failed to get thermistor channel\n");
+		fg->ntc = NULL;
+	}
+
+	cfg.drv_data = fg;
+	cfg.fwnode = dev_fwnode(dev);
+	fg->psy = devm_power_supply_register(dev, &sm5714_fg_desc, &cfg);
+	if (IS_ERR(fg->psy))
+		return dev_err_probe(dev, PTR_ERR(fg->psy), "failed to register power supply\n");
+
+	ret = devm_delayed_work_autocancel(dev, &fg->work, sm5714_fg_work);
+	if (ret)
+		return ret;
+	schedule_delayed_work(&fg->work, SM5714_FG_POLL_INTERVAL);
+
+	dev_dbg(dev, "device id 0x%04x, temperature from %s\n", id,
+		fg->ntc ? "battery thermistor" : "fuel gauge");
+
+	return 0;
+}
+
+static const struct of_device_id sm5714_fg_of_match[] = {
+	{ .compatible = "siliconmitus,sm5714-fuelgauge" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, sm5714_fg_of_match);
+
+static struct i2c_driver sm5714_fg_driver = {
+	.driver = {
+		.name = "sm5714-fuelgauge",
+		.of_match_table = sm5714_fg_of_match,
+	},
+	.probe = sm5714_fg_probe,
+};
+module_i2c_driver(sm5714_fg_driver);
+
+MODULE_AUTHOR("Asdlerto Korry <korryasdlerto@gmail.com>");
+MODULE_DESCRIPTION("Silicon Mitus SM5714 fuel gauge driver");
+MODULE_LICENSE("GPL");

-- 
2.25.1

