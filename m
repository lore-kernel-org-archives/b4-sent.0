From: Remi Buisson <remi.buisson@tdk.com>
Date: Fri, 11 Apr 2025 13:28:38 +0000
Subject: [PATCH 6/8] iio: imu: add Kconfig and Makefile for inv_icm45600
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250411-add_newport_driver-v1-6-15082160b019@tdk.com>
References: <20250411-add_newport_driver-v1-0-15082160b019@tdk.com>
In-Reply-To: <20250411-add_newport_driver-v1-0-15082160b019@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, Remi Buisson <remi.buisson@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744378119; l=4140;
 i=remi.buisson@tdk.com; s=20250411; h=from:subject:message-id;
 bh=JKi2GN1rX4ptrduYYDNWdyAYIQv9H73qs4FmqmLloQw=;
 b=/TXZTOwq25RwAGuqKUwN+ZtntsPPAgi8phGEgNImREFZdnkwGsxs6M44j1HgXhFIVxc41u4Hc
 K+VDRjApQERBtMJkC2O9bT+vgPICtUnF+dcq5R1ht8xr2zyoB9jD58+
X-Developer-Key: i=remi.buisson@tdk.com; a=ed25519;
 pk=yDVMi4C7RpXN4dififo42A7fDDt3THYzoZoNq9lUZuo=
X-Endpoint-Received: by B4 Relay for remi.buisson@tdk.com/20250411 with auth_id=372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add 4 modules:
- inv-icm45600
- inv-icm45600-i2c
- inv-icm45600-spi
- inv-icm45600-i3c.

Signed-off-by: Remi Buisson <remi.buisson@tdk.com>
---
 drivers/iio/imu/Kconfig               |  1 +
 drivers/iio/imu/Makefile              |  1 +
 drivers/iio/imu/inv_icm45600/Kconfig  | 70 +++++++++++++++++++++++++++++++++++
 drivers/iio/imu/inv_icm45600/Makefile | 17 +++++++++
 4 files changed, 89 insertions(+)

diff --git a/drivers/iio/imu/Kconfig b/drivers/iio/imu/Kconfig
index 15612f0f189b5114deb414ef840339678abdc562..9d732bed9fcdac12a13713dba3455c1fdf9f4a53 100644
--- a/drivers/iio/imu/Kconfig
+++ b/drivers/iio/imu/Kconfig
@@ -109,6 +109,7 @@ config KMX61
 	  be called kmx61.
 
 source "drivers/iio/imu/inv_icm42600/Kconfig"
+source "drivers/iio/imu/inv_icm45600/Kconfig"
 source "drivers/iio/imu/inv_mpu6050/Kconfig"
 
 config SMI240
diff --git a/drivers/iio/imu/Makefile b/drivers/iio/imu/Makefile
index e901aea498d37e5897e8b71268356a19eac2cb59..2ae6344f84699b2f85fff1c8077cb412f6ae2658 100644
--- a/drivers/iio/imu/Makefile
+++ b/drivers/iio/imu/Makefile
@@ -25,6 +25,7 @@ obj-$(CONFIG_FXOS8700_I2C) += fxos8700_i2c.o
 obj-$(CONFIG_FXOS8700_SPI) += fxos8700_spi.o
 
 obj-y += inv_icm42600/
+obj-y += inv_icm45600/
 obj-y += inv_mpu6050/
 
 obj-$(CONFIG_KMX61) += kmx61.o
diff --git a/drivers/iio/imu/inv_icm45600/Kconfig b/drivers/iio/imu/inv_icm45600/Kconfig
new file mode 100644
index 0000000000000000000000000000000000000000..4fade8852a0dcf54df2bbd67b9269ed2c59f8699
--- /dev/null
+++ b/drivers/iio/imu/inv_icm45600/Kconfig
@@ -0,0 +1,70 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+
+config INV_ICM45600
+	tristate
+	select IIO_BUFFER
+	select IIO_KFIFO_BUF
+	select IIO_INV_SENSORS_TIMESTAMP
+
+config INV_ICM45600_I2C
+	tristate "InvenSense ICM-456xx I2C driver"
+	depends on I2C
+	select INV_ICM45600
+	select REGMAP_I2C
+	help
+	  This driver supports the InvenSense ICM-456xx motion tracking
+	  devices over I2C.
+	  Supported devices:
+	  - ICM-45605
+	  - ICM-45686
+	  - ICM-45688-P
+	  - ICM-45608
+	  - ICM-45634
+	  - ICM-45689
+	  - ICM-45606
+	  - ICM-45687
+
+	  This driver can be built as a module. The module will be called
+	  inv-icm45600-i2c.
+
+config INV_ICM45600_SPI
+	tristate "InvenSense ICM-456xx SPI driver"
+	depends on SPI_MASTER
+	select INV_ICM45600
+	select REGMAP_SPI
+	help
+	  This driver supports the InvenSense ICM-456xx motion tracking
+	  devices over SPI.
+	  Supported devices:
+	  - ICM-45605
+	  - ICM-45686
+	  - ICM-45688-P
+	  - ICM-45608
+	  - ICM-45634
+	  - ICM-45689
+	  - ICM-45606
+	  - ICM-45687
+
+	  This driver can be built as a module. The module will be called
+	  inv-icm45600-spi.
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
+	  - ICM-45686
+	  - ICM-45688-P
+	  - ICM-45608
+	  - ICM-45634
+	  - ICM-45689
+	  - ICM-45606
+	  - ICM-45687
+
+	  This driver can be built as a module. The module will be called
+	  inv-icm45600-i3c.
diff --git a/drivers/iio/imu/inv_icm45600/Makefile b/drivers/iio/imu/inv_icm45600/Makefile
new file mode 100644
index 0000000000000000000000000000000000000000..0fd6fbce0286f24504dbfe71925f9c35e717c446
--- /dev/null
+++ b/drivers/iio/imu/inv_icm45600/Makefile
@@ -0,0 +1,17 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+
+obj-$(CONFIG_INV_ICM45600) += inv-icm45600.o
+inv-icm45600-y += inv_icm45600_core.o
+inv-icm45600-y += inv_icm45600_gyro.o
+inv-icm45600-y += inv_icm45600_accel.o
+inv-icm45600-y += inv_icm45600_temp.o
+inv-icm45600-y += inv_icm45600_buffer.o
+
+obj-$(CONFIG_INV_ICM45600_I2C) += inv-icm45600-i2c.o
+inv-icm45600-i2c-y += inv_icm45600_i2c.o
+
+obj-$(CONFIG_INV_ICM45600_SPI) += inv-icm45600-spi.o
+inv-icm45600-spi-y += inv_icm45600_spi.o
+
+obj-$(CONFIG_INV_ICM45600_I3C) += inv-icm45600-i3c.o
+inv-icm45600-i3c-y += inv_icm45600_i3c.o

-- 
2.34.1

