From: Luna Hart <lhart.opensource@witekio.com>
Date: Tue, 29 Sep 2026 16:04:05 -0700
Subject: [PATCH 2/2] hwmon: (tps38900x) Add driver for TI
 TPS389004/TPS389006/TPS389008
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260929-lhart-dev-tps38900x-v1-2-7045c5894152@witekio.com>
References: <20260929-lhart-dev-tps38900x-v1-0-7045c5894152@witekio.com>
In-Reply-To: <20260929-lhart-dev-tps38900x-v1-0-7045c5894152@witekio.com>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Flaviu Nistor <flaviu.nistor@gmail.com>, 
 Luna Hart <lhart.opensource@witekio.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790723106; l=13637;
 i=lhart.opensource@witekio.com; s=20260928; h=from:subject:message-id;
 bh=+qVGxX3yOTF+sfxmr3ve2C9TjPC9RNjo5GB4+MdBUTQ=;
 b=iroosU7heBWTpKFxJFdCpchE0EuQNRr+QYnG+wrmTc/dzvKdgqj7tJ8VanMRpq3jBj9ynadbG
 ZhqE5XbLO1MDtU1r1z+gFQ5akD6n66WgzD/0uw/auHoqviZUkIomZwd
X-Developer-Key: i=lhart.opensource@witekio.com; a=ed25519;
 pk=Dm1WPzsg+HuKn11WChbCWrNOk7GD980BnpCdnUwyDuU=
X-Endpoint-Received: by B4 Relay for lhart.opensource@witekio.com/20260928 with auth_id=1079
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the TI TPS389004/TPS389006/TPS389008 I2C voltage
supervisors and monitors. This initial implementation supports enabling
ADC monitoring from the chip and reading back the measured voltage in
millivolts. All functionality is provided over sysfs. Device tree
configurations may be used to further configure each voltage channel.

This work is based on an initial implementation by Flaviu Nistor.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Luna Hart <lhart.opensource@witekio.com>
---
 Documentation/hwmon/index.rst     |   1 +
 Documentation/hwmon/tps38900x.rst |  55 ++++++++
 MAINTAINERS                       |   8 ++
 drivers/hwmon/Kconfig             |  11 ++
 drivers/hwmon/Makefile            |   1 +
 drivers/hwmon/tps38900x.c         | 281 ++++++++++++++++++++++++++++++++++++++
 6 files changed, 357 insertions(+)

diff --git a/Documentation/hwmon/index.rst b/Documentation/hwmon/index.rst
index 199ca79621e94a3f2e1aed3e2a49a1b43c9f41d6..f7c5747a813efab4d7bc55745eb595140362648d 100644
--- a/Documentation/hwmon/index.rst
+++ b/Documentation/hwmon/index.rst
@@ -279,6 +279,7 @@ Hardware Monitoring Kernel Drivers
    tmp513
    tps23861
    tps25990
+   tps38900x
    tps40422
    tps53679
    tps546d24
diff --git a/Documentation/hwmon/tps38900x.rst b/Documentation/hwmon/tps38900x.rst
new file mode 100644
index 0000000000000000000000000000000000000000..e232a179e0062b49dd2a78cd38790a6b5dae0774
--- /dev/null
+++ b/Documentation/hwmon/tps38900x.rst
@@ -0,0 +1,55 @@
+.. SPDX-License-Identifier: GPL-2.0-or-later
+
+Kernel Driver tps38900x
+=======================
+
+Supported chips:
+
+  * Texas Instruments TPS389008, TPS389006, TPS389004
+
+    Prefix: 'tps38900x'
+
+    Addresses scanned: -
+
+    Datasheet: https://www.ti.com/lit/ds/symlink/tps389006.pdf
+
+Author:
+
+  - Luna Hart <lhart.opensource@witekio.com>
+
+Description
+-----------
+
+This driver implements support for the TI TPS38900x family of voltage monitor.
+Supported chips include the TPS389004, TPS389006, and TPS389008.
+
+The driver currently supports reading out current voltage levels from the ADCs.
+Features like interrupts and sequencing readings are not currently supported.
+
+All ADC measurements are 8 bit, and there are 2 supported measurement scales.
+
+  - 1x scaling: 200 to 1475 mV (5mV steps) (default)
+  - 4x scaling: 800 to 5900 mV (20mV steps)
+
+Voltage values are read from sysfs. By default, all ADCs are exposed. However,
+when channels are defined via child nodes in the device tree: only the channels
+that explicitly have a device tree node will be available.
+
+Known Issues
+------------
+
+Interrupts and sequenced readings functions of the tps38900x family are not
+implemented.
+
+sysfs-Interface
+---------------
+
+The complete list of sysfs attributes provided for each channel:
+
+=============================== ======= ========================================
+Name                            Perm    Description
+=============================== ======= ========================================
+in[01234567]_input              RO      Voltage channel input
+in[01234567]_label              RO      Voltage channel label
+in[01234567]_enable             RW      Voltage channel enable controls
+=============================== ======= ========================================
diff --git a/MAINTAINERS b/MAINTAINERS
index 5ad12c57ca5f546079f1dd5d139f27daa11e99c7..b08c52e929e5d15e182f83f2f7bdfef70002f7a3 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -27082,6 +27082,14 @@ F:	Documentation/devicetree/bindings/hwmon/ti,tps23861.yaml
 F:	Documentation/hwmon/tps23861.rst
 F:	drivers/hwmon/tps23861.c
 
+TEXAS INSTRUMENTS TPS38900X VOLTAGE MONITOR DRIVER
+M:	Luna Hart <lhart.opensource@witekio.com>
+L:	linux-hwmon@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/hwmon/ti,tps38900x.yaml
+F:	Documentation/hwmon/tps38900x.rst
+F:	drivers/hwmon/tps38900x.c
+
 TEXAS INSTRUMENTS TPS6131X FLASH LED DRIVER
 M:	Matthias Fend <matthias.fend@emfend.at>
 L:	linux-leds@vger.kernel.org
diff --git a/drivers/hwmon/Kconfig b/drivers/hwmon/Kconfig
index 18c682e1a4756a35e1433493271ba65b65f7fbe8..91f0c9fa7f436c73bfbe9a07a154cceb8f4af50f 100644
--- a/drivers/hwmon/Kconfig
+++ b/drivers/hwmon/Kconfig
@@ -1503,6 +1503,17 @@ config SENSORS_TPS23861
 	  This driver can also be built as a module. If so, the module
 	  will be called tps23861.
 
+config SENSORS_TPS38900X
+	tristate "TI TPS38900x VMON Driver"
+	depends on I2C
+	select REGMAP_I2C
+	help
+	  If you say yes here you get support for Texas Instruments
+	  TPS389004/TPS389006/TPS389008 voltage monitors.
+
+	  This driver can also be built as a module. If so, the module
+	  will be called tps38900x.
+
 config SENSORS_MENF21BMC_HWMON
 	tristate "MEN 14F021P00 BMC Hardware Monitoring"
 	depends on MFD_MENF21BMC
diff --git a/drivers/hwmon/Makefile b/drivers/hwmon/Makefile
index d4c345ed7261f9fc459c170af899ef40197839e3..e43804a53415111f15dba875c909dd9ac849aa33 100644
--- a/drivers/hwmon/Makefile
+++ b/drivers/hwmon/Makefile
@@ -181,6 +181,7 @@ obj-$(CONFIG_SENSORS_MCP3021)	+= mcp3021.o
 obj-$(CONFIG_SENSORS_MCP9982)	+= mcp9982.o
 obj-$(CONFIG_SENSORS_TC654)	+= tc654.o
 obj-$(CONFIG_SENSORS_TPS23861)	+= tps23861.o
+obj-$(CONFIG_SENSORS_TPS38900X)	+= tps38900x.o
 obj-$(CONFIG_SENSORS_MLXREG_FAN) += mlxreg-fan.o
 obj-$(CONFIG_SENSORS_MENF21BMC_HWMON) += menf21bmc_hwmon.o
 obj-$(CONFIG_SENSORS_MINISFORUM_UM780XTX) += minisforum-um780xtx.o
diff --git a/drivers/hwmon/tps38900x.c b/drivers/hwmon/tps38900x.c
new file mode 100644
index 0000000000000000000000000000000000000000..659d61b1cb55c79d42d4ba6dc69d19334f3292ca
--- /dev/null
+++ b/drivers/hwmon/tps38900x.c
@@ -0,0 +1,281 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Driver for Texas Instruments TPS389004/TPS389006/TPS389008 i2c voltage
+ * supervisor and monitor.
+ *
+ * Author: Luna Hart <lhart.opensource@witekio.com>
+ *
+ * Datasheet: https://www.ti.com/lit/ds/symlink/tps389006.pdf
+ * Datasheet: https://www.ti.com/lit/ds/symlink/tps389006-q1.pdf
+ */
+
+#include <linux/bits.h>
+#include <linux/hwmon.h>
+#include <linux/i2c.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/property.h>
+#include <linux/regmap.h>
+
+#define TPS38900X_MAX_CHANNELS 8
+#define TPS38900X_BANK_LEN 0x100
+
+// Registers, stored over 2 banks of 256 bytes.
+#define TPS38900X_VRANGE_MULT 0x1f
+#define TPS38900X_MON_LVL(ch) (0x40 + (ch))
+#define TPS38900X_BANK_SEL 0xf0
+#define TPS38900X_MON_CH_EN 0x11e
+
+#define TPS38900X_LSB_MV 5
+#define TPS38900X_OFFSET_MV 200
+
+struct tps38900x_data {
+	struct regmap *regmap;
+	const char *label[TPS38900X_MAX_CHANNELS];
+	unsigned int num_channels;
+	// bitmasks of channel states
+	u8 channel_present;
+	u8 channel_scale_4x;
+};
+
+static umode_t tps38900x_is_visible(const void *data,
+				    enum hwmon_sensor_types type, u32 attr,
+				    int channel)
+{
+	const struct tps38900x_data *priv = data;
+
+	if (!(priv->channel_present & BIT(channel)))
+		return 0;
+
+	switch (attr) {
+	case hwmon_in_input:
+		return 0444;
+	case hwmon_in_enable:
+		return 0644;
+	case hwmon_in_label:
+		return priv->label[channel] ? 0444 : 0;
+	}
+
+	return 0;
+}
+
+static int tps38900x_read(struct device *dev, enum hwmon_sensor_types type,
+			  u32 attr, int channel, long *val)
+{
+	struct tps38900x_data *priv = dev_get_drvdata(dev);
+	unsigned int regval;
+	int ret;
+	int val_scale;
+
+	switch (attr) {
+	case hwmon_in_input:
+		ret = regmap_read(priv->regmap, TPS38900X_MON_CH_EN, &regval);
+		if (ret)
+			return ret;
+
+		if (!(regval & BIT(channel)))
+			return -ENODATA;
+
+		ret = regmap_read(priv->regmap, TPS38900X_MON_LVL(channel),
+				  &regval);
+		if (ret)
+			return ret;
+
+		val_scale = priv->channel_scale_4x & BIT(channel) ? 4 : 1;
+		*val = (regval * TPS38900X_LSB_MV + TPS38900X_OFFSET_MV) *
+		       val_scale;
+		return 0;
+	case hwmon_in_enable:
+		ret = regmap_read(priv->regmap, TPS38900X_MON_CH_EN, &regval);
+		if (ret)
+			return ret;
+
+		*val = !!(regval & BIT(channel));
+		return 0;
+	}
+
+	return -EOPNOTSUPP;
+}
+
+static int tps38900x_write(struct device *dev, enum hwmon_sensor_types type,
+			   u32 attr, int channel, long enable)
+{
+	struct tps38900x_data *priv = dev_get_drvdata(dev);
+
+	switch (attr) {
+	case hwmon_in_enable:
+		if (enable != 0 && enable != 1)
+			return -EINVAL;
+
+		return regmap_update_bits(priv->regmap, TPS38900X_MON_CH_EN,
+					  BIT(channel),
+					  enable ? BIT(channel) : 0);
+	}
+
+	return -EOPNOTSUPP;
+}
+
+static int tps38900x_read_string(struct device *dev,
+				 enum hwmon_sensor_types type, u32 attr,
+				 int channel, const char **str)
+{
+	struct tps38900x_data *priv = dev_get_drvdata(dev);
+
+	switch (attr) {
+	case hwmon_in_label:
+		*str = priv->label[channel];
+		return 0;
+	}
+
+	return -EOPNOTSUPP;
+}
+
+static const struct hwmon_ops tps38900x_hwmon_ops = {
+	.is_visible = tps38900x_is_visible,
+	.read = tps38900x_read,
+	.write = tps38900x_write,
+	.read_string = tps38900x_read_string,
+};
+
+#define TPS38900X_IN_CONFIG (HWMON_I_INPUT | HWMON_I_ENABLE | HWMON_I_LABEL)
+
+static const struct hwmon_channel_info *const tps38900x_info[] = {
+	HWMON_CHANNEL_INFO(in, TPS38900X_IN_CONFIG, TPS38900X_IN_CONFIG,
+			   TPS38900X_IN_CONFIG, TPS38900X_IN_CONFIG,
+			   TPS38900X_IN_CONFIG, TPS38900X_IN_CONFIG,
+			   TPS38900X_IN_CONFIG, TPS38900X_IN_CONFIG),
+	NULL
+};
+
+static const struct hwmon_chip_info tps38900x_chip_info = {
+	.ops = &tps38900x_hwmon_ops,
+	.info = tps38900x_info,
+};
+
+static const struct regmap_range_cfg tps38900x_bank_range = {
+	.name = "tps38900x-mem-bank",
+	.range_min = 0x00,
+	.range_max = (2 * TPS38900X_BANK_LEN) - 1,
+	.selector_reg = TPS38900X_BANK_SEL,
+	.selector_mask = BIT(0),
+	.window_start = 0,
+	.window_len = TPS38900X_BANK_LEN,
+};
+
+static bool tps38900x_volatile_reg(struct device *dev, unsigned int reg)
+{
+	// ADC results region is volatile
+	if (reg >= TPS38900X_MON_LVL(0) &&
+	    reg < TPS38900X_MON_LVL(TPS38900X_MAX_CHANNELS))
+		return true;
+
+	return false;
+}
+
+static const struct regmap_config tps38900x_regmap_config = {
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = 2 * TPS38900X_BANK_LEN - 1,
+	.ranges = &tps38900x_bank_range,
+	.num_ranges = 1,
+	.volatile_reg = tps38900x_volatile_reg,
+	.cache_type = REGCACHE_MAPLE,
+};
+
+static int tps38900x_parse_dt_channels(struct device *dev,
+				       struct tps38900x_data *priv)
+{
+	u32 reg;
+	int ret;
+
+	device_for_each_child_node_scoped(dev, child) {
+		ret = fwnode_property_read_u32(child, "reg", &reg);
+		if (ret)
+			return dev_err_probe(dev, ret,
+					     "missing reg property\n");
+
+		if (reg >= priv->num_channels)
+			return dev_err_probe(dev, -EINVAL,
+					     "reg out of range: %u (max %u)\n",
+					     reg, priv->num_channels);
+
+		priv->channel_present |= BIT(reg);
+		if (fwnode_property_read_bool(child, "ti,4x-scaling"))
+			priv->channel_scale_4x |= BIT(reg);
+
+		fwnode_property_read_string(child, "label", &priv->label[reg]);
+	}
+
+	// When no channels are explicitly described in the DT, expose all of them.
+	if (!priv->channel_present)
+		priv->channel_present = GENMASK(priv->num_channels - 1, 0);
+
+	return 0;
+}
+
+static int tps38900x_probe(struct i2c_client *client)
+{
+	struct device *dev = &client->dev;
+	struct tps38900x_data *priv;
+	struct device *hwmon_dev;
+	int ret;
+
+	if (!i2c_check_functionality(client->adapter, I2C_FUNC_SMBUS_BYTE_DATA))
+		return -ENODEV;
+
+	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv)
+		return -ENOMEM;
+
+	priv->num_channels = (uintptr_t)i2c_get_match_data(client);
+
+	priv->regmap = devm_regmap_init_i2c(client, &tps38900x_regmap_config);
+	if (IS_ERR(priv->regmap))
+		return dev_err_probe(dev, PTR_ERR(priv->regmap),
+				     "failed to allocate register map\n");
+
+	ret = tps38900x_parse_dt_channels(dev, priv);
+	if (ret)
+		return ret;
+
+	ret = regmap_write(priv->regmap, TPS38900X_VRANGE_MULT,
+			   priv->channel_scale_4x);
+	if (ret)
+		return dev_err_probe(dev, ret,
+				     "failed to write voltage range\n");
+
+	hwmon_dev = devm_hwmon_device_register_with_info(dev, client->name, priv,
+							 &tps38900x_chip_info, NULL);
+
+	return PTR_ERR_OR_ZERO(hwmon_dev);
+}
+
+static const struct i2c_device_id tps38900x_id[] = {
+	{ .name = "tps389004", .driver_data = 4 },
+	{ .name = "tps389006", .driver_data = 6 },
+	{ .name = "tps389008", .driver_data = 8 },
+	{}
+};
+MODULE_DEVICE_TABLE(i2c, tps38900x_id);
+
+static const struct of_device_id tps38900x_of_match[] = {
+	{ .compatible = "ti,tps389004", .data = (void *)4 },
+	{ .compatible = "ti,tps389006", .data = (void *)6 },
+	{ .compatible = "ti,tps389008", .data = (void *)8 },
+	{}
+};
+MODULE_DEVICE_TABLE(of, tps38900x_of_match);
+
+static struct i2c_driver tps38900x_driver = {
+	.driver = {
+		.name = "tps38900x",
+		.of_match_table = tps38900x_of_match,
+	},
+	.probe = tps38900x_probe,
+	.id_table = tps38900x_id,
+};
+module_i2c_driver(tps38900x_driver);
+
+MODULE_AUTHOR("Luna Hart <lhart.opensource@witekio.com>");
+MODULE_DESCRIPTION("TI TPS389004/TPS389006/TPS389008 voltage monitor driver");
+MODULE_LICENSE("GPL");

-- 
2.47.3

