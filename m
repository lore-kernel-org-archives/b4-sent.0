From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Sun, 08 Nov 2026 12:22:26 +0100
Subject: [PATCH 2/2] power: supply: Add Silicon Mitus SM5714 fuel gauge
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-sm5714-fuel-gauge-v1-2-c659b6c0884a@dxdmail.cc>
References: <20261108-b4-sm5714-fuel-gauge-v1-0-c659b6c0884a@dxdmail.cc>
In-Reply-To: <20261108-b4-sm5714-fuel-gauge-v1-0-c659b6c0884a@dxdmail.cc>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794136945; l=8857;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=0xZbLK5B8C7WzRBXVs40P3RdNG+1xfko7pbUx/2GRKE=;
 b=czDEglVhaTbT3dT6wmTTHnq1gpm/CZ8WZr/a3swN6UJy77X6ik5nE2/kZ3ikG/r8WYBbkNw2J
 tHQpJuxstbnDYjUy5Xcylj7hqqakoWrPUh5FD/ziie+luG1TGWsF+oc
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver for the fuel gauge of the Silicon Mitus SM5714. The state
of charge, voltage and current are read through an SRAM window, and the
SRAM read address is the only register the driver writes. The status
is derived from the battery current, as in s2mu005-battery. The driver
does not load a battery model, so capacity is only reported once
Samsung's software has initialized the gauge. The register layout and
scaling come from Samsung's GPL driver for the Galaxy Tab S9.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 MAINTAINERS                           |   1 +
 drivers/power/supply/Kconfig          |  10 ++
 drivers/power/supply/Makefile         |   1 +
 drivers/power/supply/sm5714-battery.c | 221 ++++++++++++++++++++++++++++++++++
 4 files changed, 233 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 2875017d21c2..d9f37c040453 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25718,6 +25718,7 @@ M:	Nizat Mikayilli <nacht@dxdmail.cc>
 L:	linux-pm@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/power/supply/siliconmitus,sm5714-fuel-gauge.yaml
+F:	drivers/power/supply/sm5714-battery.c
 
 SILICON MOTION SM712 FRAME BUFFER DRIVER
 M:	Sudip Mukherjee <sudipm.mukherjee@gmail.com>
diff --git a/drivers/power/supply/Kconfig b/drivers/power/supply/Kconfig
index ee7dc5f2617a..c92d09a4f1c9 100644
--- a/drivers/power/supply/Kconfig
+++ b/drivers/power/supply/Kconfig
@@ -240,6 +240,16 @@ config BATTERY_S2MU005
 
 	  This driver, if built as a module, will be called s2mu005-fuel-gauge.
 
+config BATTERY_SM5714
+	tristate "Silicon Mitus SM5714 fuel gauge driver"
+	depends on I2C
+	help
+	  Say Y to enable support for the fuel gauge of the Silicon Mitus
+	  SM5714, which reports the battery state of charge, voltage and
+	  current.
+
+	  This driver, if built as a module, will be called sm5714-battery.
+
 config BATTERY_COLLIE
 	tristate "Sharp SL-5500 (collie) battery"
 	depends on SA1100_COLLIE && MCP_UCB1200
diff --git a/drivers/power/supply/Makefile b/drivers/power/supply/Makefile
index f3c0d1006c1a..459f9cbe5f30 100644
--- a/drivers/power/supply/Makefile
+++ b/drivers/power/supply/Makefile
@@ -41,6 +41,7 @@ obj-$(CONFIG_BATTERY_QCOM_BATTMGR)	+= qcom_battmgr.o
 obj-$(CONFIG_BATTERY_OLPC)	+= olpc_battery.o
 obj-$(CONFIG_BATTERY_SAMSUNG_SDI)	+= samsung-sdi-battery.o
 obj-$(CONFIG_BATTERY_S2MU005)	+= s2mu005-battery.o
+obj-$(CONFIG_BATTERY_SM5714)	+= sm5714-battery.o
 obj-$(CONFIG_BATTERY_COLLIE)	+= collie_battery.o
 obj-$(CONFIG_BATTERY_INGENIC)	+= ingenic-battery.o
 obj-$(CONFIG_BATTERY_INTEL_DC_TI) += intel_dc_ti_battery.o
diff --git a/drivers/power/supply/sm5714-battery.c b/drivers/power/supply/sm5714-battery.c
new file mode 100644
index 000000000000..bd8cb97d81df
--- /dev/null
+++ b/drivers/power/supply/sm5714-battery.c
@@ -0,0 +1,221 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <linux/bits.h>
+#include <linux/err.h>
+#include <linux/i2c.h>
+#include <linux/math.h>
+#include <linux/minmax.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/power_supply.h>
+#include <linux/property.h>
+#include <linux/units.h>
+
+#define SM5714_FG_REG_DEVICE_ID		0x00
+#define SM5714_FG_REG_SYSTEM_STATUS	0x10
+#define SM5714_FG_REG_AUX_STAT		0x22
+#define SM5714_FG_REG_SRAM_RADDR	0x8c
+#define SM5714_FG_REG_SRAM_RDATA	0x8d
+
+#define SM5714_FG_SYSTEM_STATUS_INIT	BIT(12)
+#define SM5714_FG_AUX_STAT_CURRENT_X2_5	BIT(10)
+
+#define SM5714_FG_SRAM_SOC		0x00
+#define SM5714_FG_SRAM_VBAT		0x03
+#define SM5714_FG_SRAM_CURRENT		0x05
+#define SM5714_FG_SRAM_VBAT_AVG		0x08
+#define SM5714_FG_SRAM_CURRENT_AVG	0x09
+
+struct sm5714_fg {
+	struct i2c_client *client;
+	struct mutex lock; /* SRAM read address and data */
+};
+
+static int sm5714_fg_read_sram(struct sm5714_fg *fg, u8 addr)
+{
+	int ret;
+
+	guard(mutex)(&fg->lock);
+
+	ret = i2c_smbus_write_word_data(fg->client, SM5714_FG_REG_SRAM_RADDR, addr);
+	if (ret)
+		return ret;
+
+	return i2c_smbus_read_word_data(fg->client, SM5714_FG_REG_SRAM_RDATA);
+}
+
+static int sm5714_fg_sign_mag(int raw, int mul, int div)
+{
+	int val = mult_frac(raw & 0x7fff, mul, div);
+
+	return raw & BIT(15) ? -val : val;
+}
+
+static int sm5714_fg_get_voltage(struct sm5714_fg *fg, u8 addr, int *val)
+{
+	int ret;
+
+	ret = sm5714_fg_read_sram(fg, addr);
+	if (ret < 0)
+		return ret;
+
+	*val = 2700000 + sm5714_fg_sign_mag(ret, 10000, 109);
+
+	return 0;
+}
+
+static int sm5714_fg_get_current(struct sm5714_fg *fg, u8 addr, int *val)
+{
+	int aux, ret;
+
+	ret = sm5714_fg_read_sram(fg, addr);
+	if (ret < 0)
+		return ret;
+
+	aux = i2c_smbus_read_word_data(fg->client, SM5714_FG_REG_AUX_STAT);
+	if (aux < 0)
+		return aux;
+
+	*val = sm5714_fg_sign_mag(ret, MICRO, 2044);
+	if (aux & SM5714_FG_AUX_STAT_CURRENT_X2_5)
+		*val = *val * 5 / 2;
+
+	return 0;
+}
+
+static int sm5714_fg_get_capacity(struct sm5714_fg *fg, int *val)
+{
+	int ret;
+
+	ret = i2c_smbus_read_word_data(fg->client, SM5714_FG_REG_SYSTEM_STATUS);
+	if (ret < 0)
+		return ret;
+
+	if (!(ret & SM5714_FG_SYSTEM_STATUS_INIT))
+		return -ENODATA;
+
+	ret = sm5714_fg_read_sram(fg, SM5714_FG_SRAM_SOC);
+	if (ret < 0)
+		return ret;
+
+	*val = min(ret >> 8, 100);
+
+	return 0;
+}
+
+static int sm5714_fg_get_status(struct sm5714_fg *fg, int *val)
+{
+	int now, avg, capacity, ret;
+
+	ret = sm5714_fg_get_current(fg, SM5714_FG_SRAM_CURRENT, &now);
+	if (ret)
+		return ret;
+
+	ret = sm5714_fg_get_current(fg, SM5714_FG_SRAM_CURRENT_AVG, &avg);
+	if (ret)
+		return ret;
+
+	/* Use the average as well, to ride out noise around 0 A */
+	if (now < 0 && avg < 0)
+		*val = POWER_SUPPLY_STATUS_DISCHARGING;
+	else if (!now)
+		*val = POWER_SUPPLY_STATUS_NOT_CHARGING;
+	else if (!sm5714_fg_get_capacity(fg, &capacity) && capacity > 98)
+		*val = POWER_SUPPLY_STATUS_FULL;
+	else
+		*val = POWER_SUPPLY_STATUS_CHARGING;
+
+	return 0;
+}
+
+static const enum power_supply_property sm5714_fg_props[] = {
+	POWER_SUPPLY_PROP_STATUS,
+	POWER_SUPPLY_PROP_CAPACITY,
+	POWER_SUPPLY_PROP_VOLTAGE_NOW,
+	POWER_SUPPLY_PROP_VOLTAGE_AVG,
+	POWER_SUPPLY_PROP_CURRENT_NOW,
+	POWER_SUPPLY_PROP_CURRENT_AVG,
+};
+
+static int sm5714_fg_get_property(struct power_supply *psy,
+				  enum power_supply_property psp,
+				  union power_supply_propval *val)
+{
+	struct sm5714_fg *fg = power_supply_get_drvdata(psy);
+
+	switch (psp) {
+	case POWER_SUPPLY_PROP_STATUS:
+		return sm5714_fg_get_status(fg, &val->intval);
+	case POWER_SUPPLY_PROP_CAPACITY:
+		return sm5714_fg_get_capacity(fg, &val->intval);
+	case POWER_SUPPLY_PROP_VOLTAGE_NOW:
+		return sm5714_fg_get_voltage(fg, SM5714_FG_SRAM_VBAT, &val->intval);
+	case POWER_SUPPLY_PROP_VOLTAGE_AVG:
+		return sm5714_fg_get_voltage(fg, SM5714_FG_SRAM_VBAT_AVG, &val->intval);
+	case POWER_SUPPLY_PROP_CURRENT_NOW:
+		return sm5714_fg_get_current(fg, SM5714_FG_SRAM_CURRENT, &val->intval);
+	case POWER_SUPPLY_PROP_CURRENT_AVG:
+		return sm5714_fg_get_current(fg, SM5714_FG_SRAM_CURRENT_AVG, &val->intval);
+	default:
+		return -EINVAL;
+	}
+}
+
+static const struct power_supply_desc sm5714_fg_desc = {
+	.name = "sm5714-fuel-gauge",
+	.type = POWER_SUPPLY_TYPE_BATTERY,
+	.properties = sm5714_fg_props,
+	.num_properties = ARRAY_SIZE(sm5714_fg_props),
+	.get_property = sm5714_fg_get_property,
+};
+
+static int sm5714_fg_probe(struct i2c_client *client)
+{
+	struct power_supply_config psy_cfg = {};
+	struct device *dev = &client->dev;
+	struct power_supply *psy;
+	struct sm5714_fg *fg;
+	int ret;
+
+	fg = devm_kzalloc(dev, sizeof(*fg), GFP_KERNEL);
+	if (!fg)
+		return -ENOMEM;
+
+	fg->client = client;
+
+	ret = i2c_smbus_read_word_data(client, SM5714_FG_REG_DEVICE_ID);
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "failed to read device ID\n");
+
+	ret = devm_mutex_init(dev, &fg->lock);
+	if (ret)
+		return ret;
+
+	psy_cfg.drv_data = fg;
+	psy_cfg.fwnode = dev_fwnode(dev);
+
+	psy = devm_power_supply_register(dev, &sm5714_fg_desc, &psy_cfg);
+	if (IS_ERR(psy))
+		return dev_err_probe(dev, PTR_ERR(psy), "failed to register power supply\n");
+
+	return 0;
+}
+
+static const struct of_device_id sm5714_fg_of_match[] = {
+	{ .compatible = "siliconmitus,sm5714-fuel-gauge" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, sm5714_fg_of_match);
+
+static struct i2c_driver sm5714_fg_driver = {
+	.driver = {
+		.name = "sm5714-fuel-gauge",
+		.of_match_table = sm5714_fg_of_match,
+	},
+	.probe = sm5714_fg_probe,
+};
+module_i2c_driver(sm5714_fg_driver);
+
+MODULE_AUTHOR("Nizat Mikayilli <nacht@dxdmail.cc>");
+MODULE_DESCRIPTION("Silicon Mitus SM5714 fuel gauge driver");
+MODULE_LICENSE("GPL");

-- 
2.56.0

