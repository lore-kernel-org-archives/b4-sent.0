From: Peter LaDow <pladow@gmail.com>
Date: Fri, 20 Nov 2026 09:40:24 -0800
Subject: [PATCH v2] leds: lp5860: Add I2C interface support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-add-i2c-support-for-lp5860-v2-1-bcb2ce00a7f5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAeGAGsC/42NSw6DIBQAr2JY9zWAqZ+ueo/GhcBDX6NCQE0b4
 92L9gJdTjKZ2VjEQBjZPdtYwJUiuSmBvGRM9+3UIZBJzCSXhRCSQ2sMkNQQF+9dmMG6AIO/VQW
 HurR5pSQqFJqlgA9o6X3Gn82P46JeqOejeBg9xdmFz3lfxeH9NVoFCMi50nVptLJl9ejGloard
 iNr9n3/AiLc5xHWAAAA
X-Change-ID: 20261120-add-i2c-support-for-lp5860-97f38b2ebe1c
To: Nam Tran <trannamatk@gmail.com>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Griffin Kroah-Hartman <griffin@kroah.com>
Cc: linux-kernel@vger.kernel.org, linux-leds@vger.kernel.org, 
 Peter LaDow <pladow@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795196424; l=6956;
 i=pladow@gmail.com; s=20261120; h=from:subject:message-id;
 bh=xozLBt9WPkM9Emoa1I+i7XryYHRlBk5nwDYxPBgOQgQ=;
 b=hqGuZsh7VMIKGghMl40sxHPRIaId38O0BHU/NtkL9cl2D69REyWsEI6FAJ3T7ACHdayM4IKET
 h3tWXYExQ31DtpCKR/u/b6xK6ZJowXERKIVATe35gatE4me22AUTelM
X-Developer-Key: i=pladow@gmail.com; a=ed25519;
 pk=GEdL9uXOAV0PnykeFpXX87oqKs0/Ac0qAUc4Oow7WN4=
X-Endpoint-Received: by B4 Relay for pladow@gmail.com/20261120 with auth_id=1585
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds I2C bus support to the Texas Instruments LP5860 RGB LED
matrix driver.

The LP5860 supports both SPI and I2C interfaces depending on the hardware
IFS pin configuration, but the existing driver only implements the SPI
bus interface (leds-lp5860-spi).

Changes include:
- Adding the leds-lp5860-i2c bus driver module to handle the LP5860's
  10-bit register addressing scheme over I2C.
- Updating Kconfig and Makefile so I2C and SPI bus support can be built
  independently or together.

Tested on ZymqMP (ZU3) with an LP5860 connected over an AXI IIC at
base address 0x40 (A1=0, A0=0) at 400kHz.

Signed-off-by: Peter LaDow <pladow@gmail.com>
---
Changes in v2:
- Use designated initializer (.name = "lp5860") in i2c_device_id table
- Link to v1: https://patch.msgid.link/20261120-add-i2c-support-for-lp5860-v1-1-30bc97dcbf78@gmail.com

To: Nam Tran <trannamatk@gmail.com>
To: Lee Jones <lee@kernel.org>
To: Pavel Machek <pavel@kernel.org>
To: Griffin Kroah-Hartman <griffin@kroah.com>
Cc: linux-kernel@vger.kernel.org
Cc: linux-leds@vger.kernel.org
---
 drivers/leds/rgb/Kconfig           |  12 ++++
 drivers/leds/rgb/Makefile          |   1 +
 drivers/leds/rgb/leds-lp5860-i2c.c | 139 +++++++++++++++++++++++++++++++++++++
 3 files changed, 152 insertions(+)

diff --git a/drivers/leds/rgb/Kconfig b/drivers/leds/rgb/Kconfig
index 3f6786616a7d..5dfca8949464 100644
--- a/drivers/leds/rgb/Kconfig
+++ b/drivers/leds/rgb/Kconfig
@@ -78,6 +78,18 @@ config LEDS_LP5860_SPI
 	  To compile this driver as a module, choose M here: the
 	  module will be called leds-lp5860-spi.
 
+config LEDS_LP5860_I2C
+	tristate "LED Support for TI LP5860 I2C LED driver chip"
+	depends on I2C
+	depends on OF
+	select LEDS_LP5860_CORE
+	help
+	  If you say yes here you get support for the Texas Instruments
+	  LP5860 LED driver for I2C bus connections.
+
+	  To compile this driver as a module, choose M here: the
+	  module will be called leds-lp5860-i2c.
+
 config LEDS_NCP5623
 	tristate "LED support for NCP5623"
 	depends on I2C
diff --git a/drivers/leds/rgb/Makefile b/drivers/leds/rgb/Makefile
index a59c13396a22..0e35bf16d615 100644
--- a/drivers/leds/rgb/Makefile
+++ b/drivers/leds/rgb/Makefile
@@ -6,6 +6,7 @@ obj-$(CONFIG_LEDS_KTD202X)		+= leds-ktd202x.o
 obj-$(CONFIG_LEDS_LP5812)		+= leds-lp5812.o
 obj-$(CONFIG_LEDS_LP5860_CORE)		+= leds-lp5860-core.o
 obj-$(CONFIG_LEDS_LP5860_SPI)		+= leds-lp5860-spi.o
+obj-$(CONFIG_LEDS_LP5860_I2C)		+= leds-lp5860-i2c.o
 obj-$(CONFIG_LEDS_NCP5623)		+= leds-ncp5623.o
 obj-$(CONFIG_LEDS_PWM_MULTICOLOR)	+= leds-pwm-multicolor.o
 obj-$(CONFIG_LEDS_QCOM_LPG)		+= leds-qcom-lpg.o
diff --git a/drivers/leds/rgb/leds-lp5860-i2c.c b/drivers/leds/rgb/leds-lp5860-i2c.c
new file mode 100644
index 000000000000..97948cde54a9
--- /dev/null
+++ b/drivers/leds/rgb/leds-lp5860-i2c.c
@@ -0,0 +1,139 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <linux/i2c.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/of.h>
+#include <linux/property.h>
+#include <linux/regmap.h>
+#include <linux/slab.h>
+
+#include "leds-lp5860.h"
+
+#define LP5860_I2C_NUM_PAGES	4
+
+struct lp5860_i2c {
+	struct i2c_client *clients[LP5860_I2C_NUM_PAGES];
+};
+
+static int lp5860_i2c_reg_read(void *context, unsigned int reg, unsigned int *val)
+{
+	struct lp5860_i2c *i2c = context;
+	int ret;
+
+	ret = i2c_smbus_read_byte_data(i2c->clients[reg >> 8], reg & 0xff);
+	if (ret < 0)
+		return ret;
+
+	*val = ret;
+	return 0;
+}
+
+static int lp5860_i2c_reg_write(void *context, unsigned int reg, unsigned int val)
+{
+	struct lp5860_i2c *i2c = context;
+
+	return i2c_smbus_write_byte_data(i2c->clients[reg >> 8], reg & 0xff, val);
+}
+
+static const struct regmap_bus lp5860_i2c_regmap_bus = {
+	.reg_read = lp5860_i2c_reg_read,
+	.reg_write = lp5860_i2c_reg_write,
+};
+
+static const struct regmap_config lp5860_i2c_regmap_config = {
+	.name = "lp5860",
+	.reg_bits = 16,
+	.val_bits = 8,
+	.max_register = LP5860_MAX_REG,
+};
+
+static int lp5860_i2c_probe(struct i2c_client *client)
+{
+	struct device *dev = &client->dev;
+	struct lp5860_i2c *i2c;
+	struct lp5860 *lp5860;
+	unsigned int multi_leds;
+	unsigned int page;
+	int ret;
+
+	if ((client->flags & I2C_CLIENT_TEN) ||
+	    client->addr < 0x40 || client->addr > 0x4c || (client->addr & 0x03))
+		return dev_err_probe(dev, -EINVAL,
+				     "Use the page-zero I2C address (0x40, 0x44, 0x48 or 0x4c).\n");
+
+	if (!i2c_check_functionality(client->adapter, I2C_FUNC_SMBUS_BYTE_DATA))
+		return dev_err_probe(dev, -EOPNOTSUPP,
+				     "SMBus byte-data transactions are not supported.\n");
+
+	multi_leds = device_get_child_node_count(dev);
+	if (!multi_leds)
+		return dev_err_probe(dev, -ENODEV, "LEDs are not defined in Device Tree!\n");
+
+	if (multi_leds > LP5860_MAX_LED)
+		return dev_err_probe(dev, -EINVAL, "Too many LEDs specified.\n");
+
+	lp5860 = devm_kzalloc(dev, struct_size(lp5860, leds, multi_leds), GFP_KERNEL);
+	if (!lp5860)
+		return -ENOMEM;
+
+	i2c = devm_kzalloc(dev, sizeof(*i2c), GFP_KERNEL);
+	if (!i2c)
+		return -ENOMEM;
+
+	i2c->clients[0] = client;
+	for (page = 1; page < LP5860_I2C_NUM_PAGES; page++) {
+		i2c->clients[page] = devm_i2c_new_dummy_device(dev, client->adapter,
+							       client->addr | page);
+		if (IS_ERR(i2c->clients[page]))
+			return dev_err_probe(dev, PTR_ERR(i2c->clients[page]),
+					     "Failed to reserve I2C register page %u.\n", page);
+	}
+
+	lp5860->regmap = devm_regmap_init(dev, &lp5860_i2c_regmap_bus, i2c,
+					  &lp5860_i2c_regmap_config);
+	if (IS_ERR(lp5860->regmap))
+		return dev_err_probe(dev, PTR_ERR(lp5860->regmap),
+				     "Failed to initialise Regmap.\n");
+
+	lp5860->dev = dev;
+
+	ret = devm_mutex_init(dev, &lp5860->lock);
+	if (ret)
+		return ret;
+
+	i2c_set_clientdata(client, lp5860);
+
+	return lp5860_device_init(dev);
+}
+
+static void lp5860_i2c_remove(struct i2c_client *client)
+{
+	lp5860_device_remove(&client->dev);
+}
+
+static const struct of_device_id lp5860_i2c_of_match[] = {
+	{ .compatible = "ti,lp5860" },
+	{}
+};
+MODULE_DEVICE_TABLE(of, lp5860_i2c_of_match);
+
+static const struct i2c_device_id lp5860_i2c_ids[] = {
+	{ .name = "lp5860" },
+	{}
+};
+MODULE_DEVICE_TABLE(i2c, lp5860_i2c_ids);
+
+static struct i2c_driver lp5860_i2c_driver = {
+	.driver = {
+		.name = "lp5860-i2c",
+		.of_match_table = lp5860_i2c_of_match,
+	},
+	.probe = lp5860_i2c_probe,
+	.remove = lp5860_i2c_remove,
+	.id_table = lp5860_i2c_ids,
+};
+module_i2c_driver(lp5860_i2c_driver);
+
+MODULE_DESCRIPTION("TI LP5860 RGB LED I2C driver");
+MODULE_LICENSE("GPL");

---
base-commit: c016466c8c8b01af27ac66d97b64fa9c9e431a3d
change-id: 20261120-add-i2c-support-for-lp5860-97f38b2ebe1c

Best regards,
--  
Peter LaDow <pladow@gmail.com>

