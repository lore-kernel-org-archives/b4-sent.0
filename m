From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Date: Tue, 24 Nov 2026 18:43:21 +0100
Subject: [PATCH 2/2] power: supply: Add Maxim DS28E16 battery cycle counter
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-ds28e16-v1-2-bed431df0578@proton.me>
References: <20261124-ds28e16-v1-0-bed431df0578@proton.me>
In-Reply-To: <20261124-ds28e16-v1-0-bed431df0578@proton.me>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795542200; l=10933;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=NTeRpXwxd+MTZshtvrtuUvlpAKRdjB/h0L830UKmkiM=;
 b=lSupGZxuordbwtAAg3s7kJJczpI0IE9O5wziJwQLNP4bU60pWhNfVCAvr7Rk0OTzhrb+sWFI0
 XS8TdGXeS+lB41XanMrgt1U1b+PkYwDRVITUZT7iju/qkxlOPQcXLQM
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Read the cycle count from the DS28E16 decrement counter and report it
as a power supply property. Writing cycle_count steps the counter by
one.

The w1 core has no overdrive support, so the GPIO is driven directly.

Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
 MAINTAINERS                            |   7 +
 drivers/power/supply/Kconfig           |  11 ++
 drivers/power/supply/Makefile          |   1 +
 drivers/power/supply/ds28e16_battery.c | 335 +++++++++++++++++++++++++++++++++
 4 files changed, 354 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index d9e325244ac2..32cb7bd25395 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -16439,6 +16439,13 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/iio/proximity/maxbotix,mb1232.yaml
 F:	drivers/iio/proximity/mb1232.c
 
+MAXIM DS28E16 BATTERY AUTHENTICATOR DRIVER
+M:	Armandas Kvietkus <armandas.kvietkus@proton.me>
+L:	linux-pm@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/power/supply/maxim,ds28e16.yaml
+F:	drivers/power/supply/ds28e16_battery.c
+
 MAXIM GMSL2/3 SERIALIZERS AND DESERIALIZERS
 M:	Cosmin Tanislav <cosmin.tanislav@analog.com>
 L:	linux-media@vger.kernel.org
diff --git a/drivers/power/supply/Kconfig b/drivers/power/supply/Kconfig
index 2d69f1adb951..5f787eaf8382 100644
--- a/drivers/power/supply/Kconfig
+++ b/drivers/power/supply/Kconfig
@@ -1183,6 +1183,17 @@ config BATTERY_CHARGER_SURFACE_RT
 	  This driver can also be built as a module. If so, the module
 	  will be called surface-rt-ec.
 
+config BATTERY_DS28E16
+	tristate "Maxim DS28E16 battery cycle counter"
+	depends on GPIOLIB && OF
+	help
+	  Say Y here to enable the Maxim DS28E16 battery authenticator
+	  driver. It reads the battery cycle count from the decrement
+	  counter of the chip over a GPIO driven 1-Wire line.
+
+	  This driver can also be built as a module. If so, the module
+	  will be called ds28e16_battery.
+
 config CHARGER_QCOM_SMB2
 	tristate "Qualcomm PMI8998 PMIC charger driver"
 	depends on MFD_SPMI_PMIC
diff --git a/drivers/power/supply/Makefile b/drivers/power/supply/Makefile
index 459f9cbe5f30..c51eea9e82a6 100644
--- a/drivers/power/supply/Makefile
+++ b/drivers/power/supply/Makefile
@@ -136,3 +136,4 @@ obj-$(CONFIG_CHARGER_QCOM_SMB2)	+= qcom_smbx.o
 obj-$(CONFIG_FUEL_GAUGE_MM8013)	+= mm8013.o
 obj-$(CONFIG_MACSMC_POWER)	+= macsmc-power.o
 obj-$(CONFIG_CHARGER_MAX77759)	+= max77759_charger.o
+obj-$(CONFIG_BATTERY_DS28E16)	+= ds28e16_battery.o
diff --git a/drivers/power/supply/ds28e16_battery.c b/drivers/power/supply/ds28e16_battery.c
new file mode 100644
index 000000000000..f23201eb6369
--- /dev/null
+++ b/drivers/power/supply/ds28e16_battery.c
@@ -0,0 +1,335 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <linux/delay.h>
+#include <linux/gpio/consumer.h>
+#include <linux/irqflags.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/mod_devicetable.h>
+#include <linux/platform_device.h>
+#include <linux/power_supply.h>
+#include <linux/property.h>
+#include <linux/string.h>
+
+#define DS28E16_CMD_READ_ROM	0x33
+#define DS28E16_CMD_SKIP_ROM	0xcc
+#define DS28E16_CMD_START	0x66
+#define DS28E16_CMD_READ_MEM	0x44
+#define DS28E16_CMD_RELEASE	0xaa
+#define DS28E16_CMD_DECREMENT	0xc9
+#define DS28E16_RESULT_OK	0xaa
+#define DS28E16_DC_PAGE		2
+#define DS28E16_DC_INIT		0x1ffff
+#define DS28E16_PAGE_LEN	32
+#define DS28E16_READ_DELAY_MS	50
+#define DS28E16_DEC_DELAY_MS	50
+#define DS28E16_TRIES		10
+
+struct ds28e16 {
+	struct device *dev;
+	struct gpio_desc *gpio;
+	struct power_supply *psy;
+	struct mutex lock;
+	int cycle_count;
+	bool valid;
+};
+
+static int ds28e16_reset(struct ds28e16 *ds)
+{
+	unsigned long flags;
+	int presence;
+
+	local_irq_save(flags);
+	gpiod_direction_output_raw(ds->gpio, 0);
+	udelay(50);
+	gpiod_direction_input(ds->gpio);
+	udelay(7);
+	presence = gpiod_get_raw_value(ds->gpio);
+	udelay(50);
+	local_irq_restore(flags);
+
+	return presence ? -ENODEV : 0;
+}
+
+static int ds28e16_read_bit(struct ds28e16 *ds)
+{
+	int v;
+
+	gpiod_direction_output_raw(ds->gpio, 0);
+	udelay(1);
+	gpiod_direction_input(ds->gpio);
+	v = gpiod_get_raw_value(ds->gpio);
+	udelay(5);
+	gpiod_direction_output_raw(ds->gpio, 1);
+	udelay(6);
+
+	return v;
+}
+
+static void ds28e16_write_bit(struct ds28e16 *ds, int bit)
+{
+	gpiod_set_raw_value(ds->gpio, 0);
+	udelay(1);
+	if (bit)
+		gpiod_set_raw_value(ds->gpio, 1);
+	udelay(10);
+	gpiod_set_raw_value(ds->gpio, 1);
+	udelay(6);
+}
+
+static u8 ds28e16_read_byte(struct ds28e16 *ds)
+{
+	unsigned long flags;
+	u8 v = 0;
+	int i;
+
+	local_irq_save(flags);
+	for (i = 0; i < 8; i++)
+		if (ds28e16_read_bit(ds))
+			v |= BIT(i);
+	local_irq_restore(flags);
+
+	return v;
+}
+
+static void ds28e16_write_byte(struct ds28e16 *ds, u8 v)
+{
+	unsigned long flags;
+	int i;
+
+	local_irq_save(flags);
+	gpiod_direction_output_raw(ds->gpio, 1);
+	for (i = 0; i < 8; i++)
+		ds28e16_write_bit(ds, (v >> i) & 1);
+	local_irq_restore(flags);
+}
+
+static u16 ds28e16_crc16(u16 crc, u8 data)
+{
+	static const u8 oddparity[16] = {
+		0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0
+	};
+	u16 d = (data ^ (crc & 0xff)) & 0xff;
+
+	crc >>= 8;
+	if (oddparity[d & 0xf] ^ oddparity[d >> 4])
+		crc ^= 0xc001;
+	d <<= 6;
+	crc ^= d;
+	d <<= 1;
+	crc ^= d;
+
+	return crc;
+}
+
+static int ds28e16_cmd(struct ds28e16 *ds, const u8 *cmd, int n,
+		       unsigned int delay_ms, u8 *rsp, int rsp_len)
+{
+	u8 buf[DS28E16_PAGE_LEN + 4];
+	u16 crc = 0;
+	int i, len, ret;
+
+	ret = ds28e16_reset(ds);
+	if (ret)
+		return ret;
+
+	ds28e16_write_byte(ds, DS28E16_CMD_SKIP_ROM);
+	ds28e16_write_byte(ds, DS28E16_CMD_START);
+	crc = ds28e16_crc16(crc, DS28E16_CMD_START);
+	for (i = 0; i < n; i++) {
+		ds28e16_write_byte(ds, cmd[i]);
+		crc = ds28e16_crc16(crc, cmd[i]);
+	}
+	crc = ds28e16_crc16(crc, ds28e16_read_byte(ds));
+	crc = ds28e16_crc16(crc, ds28e16_read_byte(ds));
+	if (crc != 0xb001)
+		return -EIO;
+
+	ds28e16_write_byte(ds, DS28E16_CMD_RELEASE);
+	msleep(delay_ms);
+
+	ds28e16_read_byte(ds);
+	len = ds28e16_read_byte(ds);
+	if (len != rsp_len + 1)
+		return -EIO;
+
+	for (i = 0; i < len + 2; i++)
+		buf[i] = ds28e16_read_byte(ds);
+
+	crc = ds28e16_crc16(0, len);
+	for (i = 0; i < len + 2; i++)
+		crc = ds28e16_crc16(crc, buf[i]);
+	if (crc != 0xb001)
+		return -EIO;
+
+	if (buf[0] != DS28E16_RESULT_OK)
+		return -EIO;
+
+	if (rsp_len)
+		memcpy(rsp, buf + 1, rsp_len);
+
+	return 0;
+}
+
+static int ds28e16_read_page(struct ds28e16 *ds, u8 page, u8 *out)
+{
+	u8 cmd[3] = { 2, DS28E16_CMD_READ_MEM, page & 3 };
+
+	return ds28e16_cmd(ds, cmd, sizeof(cmd), DS28E16_READ_DELAY_MS, out,
+			   DS28E16_PAGE_LEN);
+}
+
+static int ds28e16_decrement(struct ds28e16 *ds)
+{
+	u8 cmd[2] = { 1, DS28E16_CMD_DECREMENT };
+
+	return ds28e16_cmd(ds, cmd, sizeof(cmd), DS28E16_DEC_DELAY_MS, NULL, 0);
+}
+
+static int ds28e16_read_cycle_count(struct ds28e16 *ds)
+{
+	u8 page[DS28E16_PAGE_LEN];
+	int i, ret = -EIO;
+
+	for (i = 0; i < DS28E16_TRIES; i++) {
+		ret = ds28e16_read_page(ds, DS28E16_DC_PAGE, page);
+		if (!ret)
+			return DS28E16_DC_INIT -
+			       (page[0] | page[1] << 8 | page[2] << 16);
+	}
+
+	return ret;
+}
+
+static int ds28e16_get_property(struct power_supply *psy,
+				enum power_supply_property psp,
+				union power_supply_propval *val)
+{
+	struct ds28e16 *ds = power_supply_get_drvdata(psy);
+	int ret;
+
+	switch (psp) {
+	case POWER_SUPPLY_PROP_CYCLE_COUNT: {
+		guard(mutex)(&ds->lock);
+		if (!ds->valid) {
+			ret = ds28e16_read_cycle_count(ds);
+			gpiod_direction_input(ds->gpio);
+			if (ret < 0)
+				return -ENODATA;
+			ds->cycle_count = ret;
+			ds->valid = true;
+		}
+		val->intval = ds->cycle_count;
+		return 0;
+	}
+	case POWER_SUPPLY_PROP_PRESENT:
+		val->intval = 1;
+		return 0;
+	default:
+		return -EINVAL;
+	}
+}
+
+static int ds28e16_set_property(struct power_supply *psy,
+				enum power_supply_property psp,
+				const union power_supply_propval *val)
+{
+	struct ds28e16 *ds = power_supply_get_drvdata(psy);
+	int cur, now, ret;
+
+	if (psp != POWER_SUPPLY_PROP_CYCLE_COUNT)
+		return -EINVAL;
+
+	guard(mutex)(&ds->lock);
+	cur = ds28e16_read_cycle_count(ds);
+	if (cur < 0) {
+		gpiod_direction_input(ds->gpio);
+		return cur;
+	}
+	if (val->intval != cur + 1) {
+		gpiod_direction_input(ds->gpio);
+		return -EINVAL;
+	}
+
+	ret = ds28e16_decrement(ds);
+	now = ds28e16_read_cycle_count(ds);
+	gpiod_direction_input(ds->gpio);
+	ds->valid = now >= 0;
+	if (ds->valid)
+		ds->cycle_count = now;
+	dev_info(ds->dev, "cycle count %d -> %d, decrement %d\n", cur, now, ret);
+	if (now < 0)
+		return now;
+
+	return now == cur + 1 ? 0 : -EIO;
+}
+
+static int ds28e16_property_is_writeable(struct power_supply *psy,
+					 enum power_supply_property psp)
+{
+	return psp == POWER_SUPPLY_PROP_CYCLE_COUNT;
+}
+
+static const enum power_supply_property ds28e16_props[] = {
+	POWER_SUPPLY_PROP_CYCLE_COUNT,
+	POWER_SUPPLY_PROP_PRESENT,
+};
+
+static const struct power_supply_desc ds28e16_psy_desc = {
+	.name = "battery-id",
+	.type = POWER_SUPPLY_TYPE_UNKNOWN,
+	.properties = ds28e16_props,
+	.num_properties = ARRAY_SIZE(ds28e16_props),
+	.get_property = ds28e16_get_property,
+	.set_property = ds28e16_set_property,
+	.property_is_writeable = ds28e16_property_is_writeable,
+};
+
+static int ds28e16_probe(struct platform_device *pdev)
+{
+	struct power_supply_config cfg = {};
+	struct ds28e16 *ds;
+	int ret;
+
+	ds = devm_kzalloc(&pdev->dev, sizeof(*ds), GFP_KERNEL);
+	if (!ds)
+		return -ENOMEM;
+
+	ds->dev = &pdev->dev;
+	ds->gpio = devm_gpiod_get(&pdev->dev, "onewire", GPIOD_IN);
+	if (IS_ERR(ds->gpio))
+		return dev_err_probe(&pdev->dev, PTR_ERR(ds->gpio),
+				     "no onewire gpio\n");
+
+	ret = devm_mutex_init(&pdev->dev, &ds->lock);
+	if (ret)
+		return ret;
+
+	cfg.drv_data = ds;
+	cfg.fwnode = dev_fwnode(&pdev->dev);
+	ds->psy = devm_power_supply_register(&pdev->dev, &ds28e16_psy_desc,
+					     &cfg);
+	if (IS_ERR(ds->psy))
+		return PTR_ERR(ds->psy);
+
+	return 0;
+}
+
+static const struct of_device_id ds28e16_of_match[] = {
+	{ .compatible = "maxim,ds28e16" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, ds28e16_of_match);
+
+static struct platform_driver ds28e16_driver = {
+	.probe = ds28e16_probe,
+	.driver = {
+		.name = "ds28e16-battery",
+		.of_match_table = ds28e16_of_match,
+	},
+};
+module_platform_driver(ds28e16_driver);
+
+MODULE_AUTHOR("Armandas Kvietkus <armandas.kvietkus@proton.me>");
+MODULE_DESCRIPTION("Maxim DS28E16 battery cycle counter");
+MODULE_LICENSE("GPL");

-- 
2.56.0

