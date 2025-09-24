From: Remi Buisson <remi.buisson@tdk.com>
Date: Wed, 24 Sep 2025 09:24:01 +0000
Subject: [PATCH v6 8/9] iio: imu: inv_icm45600: add I3C driver for
 inv_icm45600 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250924-add_newport_driver-v6-8-76687b9d8a6e@tdk.com>
References: <20250924-add_newport_driver-v6-0-76687b9d8a6e@tdk.com>
In-Reply-To: <20250924-add_newport_driver-v6-0-76687b9d8a6e@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, Remi Buisson <remi.buisson@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758705845; l=4443;
 i=remi.buisson@tdk.com; s=20250411; h=from:subject:message-id;
 bh=ulJC5cZrbmgNFuVSQTVMJUGFEnE5if7UXY07LEl0pkE=;
 b=6CfAxC21JIFqppXR/tAk0L/v/dkHQJG86loV4qbLrOVbpUYrgwJOz/9vZswyMYbp9PE08tBM3
 8yNAW2TCWV5CvTXtIKeZnvZsJ67PskenO4vcVvAHIB2Zw6uRjRIzjZ/
X-Developer-Key: i=remi.buisson@tdk.com; a=ed25519;
 pk=yDVMi4C7RpXN4dififo42A7fDDt3THYzoZoNq9lUZuo=
X-Endpoint-Received: by B4 Relay for remi.buisson@tdk.com/20250411 with auth_id=372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add I3C driver for InvenSense ICM-45600 devices.

Signed-off-by: Remi Buisson <remi.buisson@tdk.com>
---
 drivers/iio/imu/inv_icm45600/Kconfig            | 21 +++++++
 drivers/iio/imu/inv_icm45600/Makefile           |  3 +
 drivers/iio/imu/inv_icm45600/inv_icm45600_i3c.c | 78 +++++++++++++++++++++++++
 3 files changed, 102 insertions(+)

diff --git a/drivers/iio/imu/inv_icm45600/Kconfig b/drivers/iio/imu/inv_icm45600/Kconfig
index 01399d136a7ea3aa92a3a18ea455c95c0a6578b3..dc133402f6d75f8c050100e8475404e00993818b 100644
--- a/drivers/iio/imu/inv_icm45600/Kconfig
+++ b/drivers/iio/imu/inv_icm45600/Kconfig
@@ -47,3 +47,24 @@ config INV_ICM45600_SPI
 
 	  This driver can be built as a module. The module will be called
 	  inv-icm45600-spi.
+
+config INV_ICM45600_I3C
+	tristate "InvenSense ICM-456xx I3C driver"
+	depends on I3C
+	select INV_ICM45600
+	select REGMAP_I3C
+	help
+	  This driver supports the InvenSense ICM-456xx motion tracking
+	  devices over I3C.
+	  Supported devices:
+	  - ICM-45605
+	  - ICM-45606
+	  - ICM-45608
+	  - ICM-45634
+	  - ICM-45686
+	  - ICM-45687
+	  - ICM-45688-P
+	  - ICM-45689
+
+	  This driver can be built as a module. The module will be called
+	  inv-icm45600-i3c.
diff --git a/drivers/iio/imu/inv_icm45600/Makefile b/drivers/iio/imu/inv_icm45600/Makefile
index 3692636d393a109a0ad68e955e1cad59005e9128..c98b8365b467de6abe9873e7ba3c0aca77f464e3 100644
--- a/drivers/iio/imu/inv_icm45600/Makefile
+++ b/drivers/iio/imu/inv_icm45600/Makefile
@@ -11,3 +11,6 @@ inv-icm45600-i2c-y += inv_icm45600_i2c.o
 
 obj-$(CONFIG_INV_ICM45600_SPI) += inv-icm45600-spi.o
 inv-icm45600-spi-y += inv_icm45600_spi.o
+
+obj-$(CONFIG_INV_ICM45600_I3C) += inv-icm45600-i3c.o
+inv-icm45600-i3c-y += inv_icm45600_i3c.o
diff --git a/drivers/iio/imu/inv_icm45600/inv_icm45600_i3c.c b/drivers/iio/imu/inv_icm45600/inv_icm45600_i3c.c
new file mode 100644
index 0000000000000000000000000000000000000000..b5df06b97d44e0e769a082751fdecd95cc10c5d8
--- /dev/null
+++ b/drivers/iio/imu/inv_icm45600/inv_icm45600_i3c.c
@@ -0,0 +1,78 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/* Copyright (C) 2025 InvenSense, Inc. */
+
+#include <linux/err.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/regmap.h>
+
+#include <linux/i3c/device.h>
+#include <linux/i3c/master.h>
+
+#include "inv_icm45600.h"
+
+static const struct regmap_config inv_icm45600_regmap_config = {
+	.reg_bits = 8,
+	.val_bits = 8,
+};
+
+static const struct i3c_device_id inv_icm45600_i3c_ids[] = {
+	I3C_DEVICE_EXTRA_INFO(0x0235, 0x0000, 0x0011, (void *)NULL),
+	I3C_DEVICE_EXTRA_INFO(0x0235, 0x0000, 0x0084, (void *)NULL),
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(i3c, inv_icm45600_i3c_ids);
+
+static const struct inv_icm45600_chip_info *i3c_chip_info[] = {
+	&inv_icm45605_chip_info,
+	&inv_icm45606_chip_info,
+	&inv_icm45608_chip_info,
+	&inv_icm45634_chip_info,
+	&inv_icm45686_chip_info,
+	&inv_icm45687_chip_info,
+	&inv_icm45688p_chip_info,
+	&inv_icm45689_chip_info,
+};
+
+static int inv_icm45600_i3c_probe(struct i3c_device *i3cdev)
+{
+	int ret;
+	unsigned int whoami;
+	struct regmap *regmap;
+	const int nb_chip = ARRAY_SIZE(i3c_chip_info);
+	int chip;
+
+	regmap = devm_regmap_init_i3c(i3cdev, &inv_icm45600_regmap_config);
+	if (IS_ERR(regmap))
+		return dev_err_probe(&i3cdev->dev, PTR_ERR(regmap),
+					"Failed to register i3c regmap %ld\n", PTR_ERR(regmap));
+
+	ret = regmap_read(regmap, INV_ICM45600_REG_WHOAMI, &whoami);
+	if (ret)
+		return dev_err_probe(&i3cdev->dev, ret, "Failed to read part id %d\n", whoami);
+
+	for (chip = 0; chip < nb_chip; chip++) {
+		if (whoami == i3c_chip_info[chip]->whoami)
+			break;
+	}
+
+	if (chip == nb_chip)
+		dev_err_probe(&i3cdev->dev, -ENODEV, "Failed to match part id %d\n", whoami);
+
+	return inv_icm45600_core_probe(regmap, i3c_chip_info[chip], false, NULL);
+}
+
+static struct i3c_driver inv_icm45600_driver = {
+	.driver = {
+		.name = "inv_icm45600_i3c",
+		.pm = pm_sleep_ptr(&inv_icm45600_pm_ops),
+	},
+	.probe = inv_icm45600_i3c_probe,
+	.id_table = inv_icm45600_i3c_ids,
+};
+module_i3c_driver(inv_icm45600_driver);
+
+MODULE_AUTHOR("Remi Buisson <remi.buisson@tdk.com>");
+MODULE_DESCRIPTION("InvenSense ICM-456xx i3c driver");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("IIO_ICM45600");

-- 
2.34.1

