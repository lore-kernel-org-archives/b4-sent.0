From: Cryolitia PukNgae <Cryolitia@gmail.com>
Date: Tue, 11 Feb 2025 15:01:17 +0800
Subject: [PATCH v5 1/2] hwmon: add GPD devices sensor driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250211-gpd_fan-v5-1-608f4255f0e1@gmail.com>
References: <20250211-gpd_fan-v5-0-608f4255f0e1@gmail.com>
In-Reply-To: <20250211-gpd_fan-v5-0-608f4255f0e1@gmail.com>
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Cryolitia PukNgae <Cryolitia@gmail.com>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-doc@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>, 
 Yao Zi <ziyao@disroot.org>, Derek John Clark <derekjohn.clark@gmail.com>, 
 =?utf-8?q?Marcin_Str=C4=85gowski?= <marcin@stragowski.com>, 
 someone5678 <someone5678.dev@gmail.com>, 
 Justin Weiss <justin@justinweiss.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=17483; i=Cryolitia@gmail.com;
 h=from:subject:message-id; bh=b09RN5Rg24dna4uGOlfBMSYyKNJCSe6BskOoggNvJ7Y=;
 b=LS0tLS1CRUdJTiBQR1AgTUVTU0FHRS0tLS0tCgpvd0did012TXdDV1dQRU9OYzFGS3JRM2phY
 lVraHZSVlg4OWVtYmEwdFA1WGdRNExRM1pJeVllbGh0UDlab253CjhUUmxIbzM5Zml4RTUwSkxS
 eWtMZ3hnWGc2eVlJc3NLR2V1SmRTVmQyVmZrVy9iQXpHRmxBaG5Dd01VcEFCTloKMHNud2gzTkg
 3L3NYSDRPa3RuUk5VTHA1WWM0V0MrR0d2YjVweHlmbVN6bysycGVpRU1ESTBMTko4dTVlaFdmMg
 pOOFROdEZrZTk3dW1mZURsWDdKYjg5ajNFL3hDN3g3R2NRSUEKPXNMQisKLS0tLS1FTkQgUEdQI
 E1FU1NBR0UtLS0tLQo=
X-Developer-Key: i=Cryolitia@gmail.com; a=openpgp;
 fpr=1C3C6547538D7152310C0EEA84DD0C0130A54DF7
X-Endpoint-Received: by B4 Relay for Cryolitia@gmail.com/default with auth_id=186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sensors driver for GPD Handhelds that expose fan reading and control via
hwmon sysfs.

Shenzhen GPD Technology Co., Ltd. manufactures a series of handheld
devices. This driver implements these functions through x86 port-mapped IO.

Signed-off-by: Cryolitia PukNgae <Cryolitia@gmail.com>
---
 MAINTAINERS             |   6 +
 drivers/hwmon/Kconfig   |  10 +
 drivers/hwmon/Makefile  |   1 +
 drivers/hwmon/gpd-fan.c | 611 ++++++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 628 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 0fa7c5728f1e64d031f4a47b6fce1db484ce0fc2..777ba74ccb07ccc0840c3cd34e7b4d98d726f964 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -9762,6 +9762,12 @@ F:	drivers/phy/samsung/phy-gs101-ufs.c
 F:	include/dt-bindings/clock/google,gs101.h
 K:	[gG]oogle.?[tT]ensor
 
+GPD FAN DRIVER
+M:	Cryolitia PukNgae <Cryolitia@gmail.com>
+L:	linux-hwmon@vger.kernel.org
+S:	Maintained
+F:	drivers/hwmon/gpd-fan.c
+
 GPD POCKET FAN DRIVER
 M:	Hans de Goede <hdegoede@redhat.com>
 L:	platform-driver-x86@vger.kernel.org
diff --git a/drivers/hwmon/Kconfig b/drivers/hwmon/Kconfig
index dd376602f3f19c6f258651afeffbe1bb5d9b6b72..974b341c0bdaba147370de59f510140c0c937913 100644
--- a/drivers/hwmon/Kconfig
+++ b/drivers/hwmon/Kconfig
@@ -729,6 +729,16 @@ config SENSORS_GL520SM
 	  This driver can also be built as a module. If so, the module
 	  will be called gl520sm.
 
+config SENSORS_GPD
+	tristate "GPD handhelds"
+	depends on X86
+	help
+	  If you say yes here you get support for fan readings and
+	  control over GPD handheld devices.
+
+	  Can also be built as a module. In that case it will be
+	  called gpd-fan.
+
 config SENSORS_G760A
 	tristate "GMT G760A"
 	depends on I2C
diff --git a/drivers/hwmon/Makefile b/drivers/hwmon/Makefile
index b827b92f2a7844418f3f3b6434a63b744b52c33d..cd512c19caa9737a2926a3d4860f65b65cd013c3 100644
--- a/drivers/hwmon/Makefile
+++ b/drivers/hwmon/Makefile
@@ -87,6 +87,7 @@ obj-$(CONFIG_SENSORS_GIGABYTE_WATERFORCE) += gigabyte_waterforce.o
 obj-$(CONFIG_SENSORS_GL518SM)	+= gl518sm.o
 obj-$(CONFIG_SENSORS_GL520SM)	+= gl520sm.o
 obj-$(CONFIG_SENSORS_GSC)	+= gsc-hwmon.o
+obj-$(CONFIG_SENSORS_GPD)	+= gpd-fan.o
 obj-$(CONFIG_SENSORS_GPIO_FAN)	+= gpio-fan.o
 obj-$(CONFIG_SENSORS_GXP_FAN_CTRL) += gxp-fan-ctrl.o
 obj-$(CONFIG_SENSORS_HIH6130)	+= hih6130.o
diff --git a/drivers/hwmon/gpd-fan.c b/drivers/hwmon/gpd-fan.c
new file mode 100644
index 0000000000000000000000000000000000000000..8d54ebf5defa45f4d01c0dd7786b1908bca55ec0
--- /dev/null
+++ b/drivers/hwmon/gpd-fan.c
@@ -0,0 +1,611 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+/* Platform driver for GPD devices that expose fan control via hwmon sysfs.
+ *
+ * Fan control is provided via pwm interface in the range [0-255].
+ * Each model has a different range in the EC, the written value is scaled to accommodate for that.
+ *
+ * Based on this repo:
+ * https://github.com/Cryolitia/gpd-fan-driver
+ *
+ * Copyright (c) 2024 Cryolitia PukNgae
+ */
+
+#include <linux/acpi.h>
+#include <linux/dmi.h>
+#include <linux/hwmon.h>
+#include <linux/ioport.h>
+#include <linux/kernel.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+
+#define DRIVER_NAME "gpdfan"
+
+#define GPD_PWM_CTR_OFFSET 0x1841
+
+// model param, see document
+static char *gpd_fan_board = "";
+module_param(gpd_fan_board, charp, 0444);
+
+// EC read/write locker
+// Should never access EC at the same time, otherwise system down.
+static DEFINE_MUTEX(gpd_fan_lock);
+
+enum gpd_board {
+	win_mini,
+	win4_6800u,
+	win_max_2,
+};
+
+enum FAN_PWM_ENABLE {
+	DISABLE = 0,
+	MANUAL = 1,
+	AUTOMATIC = 2,
+};
+
+static struct {
+	enum FAN_PWM_ENABLE pwm_enable;
+	u8 pwm_value;
+
+	const struct gpd_board_drvdata *drvdata;
+} gpd_driver_priv;
+
+struct gpd_board_drvdata {
+	const char *board_name; /* Board name for module param comparison */
+	const enum gpd_board board;
+
+	const u8 addr_port;
+	const u8 data_port;
+	const u16 manual_control_enable;
+	const u16 rpm_read;
+	const u16 pwm_write;
+	const u16 pwm_max;
+};
+
+static struct gpd_board_drvdata gpd_win_mini_drvdata = {
+	.board_name = "win_mini",
+	.board = win_mini,
+
+	.addr_port = 0x4E,
+	.data_port = 0x4F,
+	.manual_control_enable = 0x047A,
+	.rpm_read = 0x0478,
+	.pwm_write = 0x047A,
+	.pwm_max = 244,
+};
+
+static struct gpd_board_drvdata gpd_win4_drvdata = {
+	.board_name = "win4",
+	.board = win4_6800u,
+
+	.addr_port = 0x2E,
+	.data_port = 0x2F,
+	.manual_control_enable = 0xC311,
+	.rpm_read = 0xC880,
+	.pwm_write = 0xC311,
+	.pwm_max = 127,
+};
+
+static struct gpd_board_drvdata gpd_wm2_drvdata = {
+	.board_name = "wm2",
+	.board = win_max_2,
+
+	.addr_port = 0x4E,
+	.data_port = 0x4F,
+	.manual_control_enable = 0x0275,
+	.rpm_read = 0x0218,
+	.pwm_write = 0x1809,
+	.pwm_max = 184,
+};
+
+static const struct dmi_system_id dmi_table[] = {
+	{
+		// GPD Win Mini
+		// GPD Win Mini with AMD Ryzen 8840U
+		.matches	= {
+					DMI_MATCH(DMI_SYS_VENDOR, "GPD"),
+					DMI_MATCH(DMI_PRODUCT_NAME, "G1617-01")
+				},
+		.driver_data	= &gpd_win_mini_drvdata,
+	},
+	{
+		// GPD Win 4 with AMD Ryzen 6800U
+		.matches	= {
+					DMI_MATCH(DMI_SYS_VENDOR, "GPD"),
+					DMI_MATCH(DMI_PRODUCT_NAME, "G1618-04"),
+					DMI_MATCH(DMI_BOARD_VERSION, "Default string"),
+				},
+		.driver_data	= &gpd_win4_drvdata,
+	},
+	{
+		// GPD Win 4 with Ryzen 7840U
+		.matches	= {
+					DMI_MATCH(DMI_SYS_VENDOR, "GPD"),
+					DMI_MATCH(DMI_PRODUCT_NAME, "G1618-04"),
+					DMI_MATCH(DMI_BOARD_VERSION, "Ver. 1.0"),
+				},
+		// Since 7840U, win4 uses the same drvdata as wm2
+		.driver_data	= &gpd_wm2_drvdata,
+	},
+	{
+		// GPD Win Max 2 with Ryzen 6800U
+		// GPD Win Max 2 2023 with Ryzen 7840U
+		// GPD Win Max 2 2024 with Ryzen 8840U
+		.matches	= {
+					DMI_MATCH(DMI_SYS_VENDOR, "GPD"),
+					DMI_MATCH(DMI_PRODUCT_NAME, "G1619-04"),
+				},
+		.driver_data	= &gpd_wm2_drvdata,
+	},
+	{}
+};
+
+static const struct gpd_board_drvdata *gpd_module_drvdata[] = {
+	&gpd_win_mini_drvdata, &gpd_win4_drvdata, &gpd_wm2_drvdata, NULL
+};
+
+/* Helper functions to handle EC read/write */
+static int gpd_ecram_read(const struct gpd_board_drvdata *drvdata, u16 offset,
+			  u8 *val)
+{
+	int ret;
+	u16 addr_port = drvdata->addr_port;
+	u16 data_port = drvdata->data_port;
+
+	ret = mutex_lock_interruptible(&gpd_fan_lock);
+
+	if (ret)
+		return ret;
+
+	outb(0x2E, addr_port);
+	outb(0x11, data_port);
+	outb(0x2F, addr_port);
+	outb((u8)((offset >> 8) & 0xFF), data_port);
+
+	outb(0x2E, addr_port);
+	outb(0x10, data_port);
+	outb(0x2F, addr_port);
+	outb((u8)(offset & 0xFF), data_port);
+
+	outb(0x2E, addr_port);
+	outb(0x12, data_port);
+	outb(0x2F, addr_port);
+	*val = inb(data_port);
+
+	mutex_unlock(&gpd_fan_lock);
+	return 0;
+}
+
+static int gpd_ecram_write(const struct gpd_board_drvdata *drvdata, u16 offset,
+			   u8 value)
+{
+	int ret;
+	u16 addr_port = drvdata->addr_port;
+	u16 data_port = drvdata->data_port;
+
+	ret = mutex_lock_interruptible(&gpd_fan_lock);
+
+	if (ret)
+		return ret;
+
+	outb(0x2E, addr_port);
+	outb(0x11, data_port);
+	outb(0x2F, addr_port);
+	outb((u8)((offset >> 8) & 0xFF), data_port);
+
+	outb(0x2E, addr_port);
+	outb(0x10, data_port);
+	outb(0x2F, addr_port);
+	outb((u8)(offset & 0xFF), data_port);
+
+	outb(0x2E, addr_port);
+	outb(0x12, data_port);
+	outb(0x2F, addr_port);
+	outb(value, data_port);
+
+	mutex_unlock(&gpd_fan_lock);
+	return 0;
+}
+
+static int gpd_generic_read_rpm_uncached(void)
+{
+	u8 high, low;
+	int ret;
+	const struct gpd_board_drvdata *const drvdata = gpd_driver_priv.drvdata;
+
+	ret = gpd_ecram_read(drvdata, drvdata->rpm_read, &high);
+	if (ret)
+		return ret;
+	ret = gpd_ecram_read(drvdata, drvdata->rpm_read + 1, &low);
+	if (ret)
+		return ret;
+
+	return (u16)high << 8 | low;
+}
+
+static int gpd_win4_read_rpm_uncached(void)
+{
+	const struct gpd_board_drvdata *const drvdata = gpd_driver_priv.drvdata;
+	u8 PWMCTR;
+	int ret;
+
+	gpd_ecram_read(drvdata, GPD_PWM_CTR_OFFSET, &PWMCTR);
+	if (PWMCTR != 0x7F)
+		gpd_ecram_write(drvdata, GPD_PWM_CTR_OFFSET, 0x7F);
+
+	ret = gpd_generic_read_rpm_uncached();
+
+	if (ret < 0)
+		return ret;
+
+	if (ret == 0) {
+		//re-init EC
+		u8 chip_id;
+
+		gpd_ecram_read(drvdata, 0x2000, &chip_id);
+		if (chip_id == 0x55) {
+			u8 chip_ver;
+
+			if (gpd_ecram_read(drvdata, 0x1060, &chip_ver))
+				gpd_ecram_write(drvdata, 0x1060, chip_ver | 0x80);
+		}
+	}
+	return ret;
+}
+
+static int gpd_wm2_read_rpm_uncached(void)
+{
+	const struct gpd_board_drvdata *const drvdata = gpd_driver_priv.drvdata;
+
+	for (u16 pwm_ctr_offset = GPD_PWM_CTR_OFFSET; pwm_ctr_offset <= GPD_PWM_CTR_OFFSET + 2;
+	     pwm_ctr_offset++) {
+		u8 PWMCTR;
+
+		gpd_ecram_read(drvdata, pwm_ctr_offset, &PWMCTR);
+		if (PWMCTR != 0xB8)
+			gpd_ecram_write(drvdata, pwm_ctr_offset, 0xB8);
+	}
+	return gpd_generic_read_rpm_uncached();
+}
+
+// Read value for fan1_input
+static int gpd_read_rpm(void)
+{
+	switch (gpd_driver_priv.drvdata->board) {
+	case win_mini: {
+		return gpd_generic_read_rpm_uncached();
+	}
+	case win4_6800u: {
+		return gpd_win4_read_rpm_uncached();
+	}
+	case win_max_2: {
+		return gpd_wm2_read_rpm_uncached();
+	}
+	}
+	return 0;
+}
+
+static int gpd_wm2_read_pwm_uncached(void)
+{
+	const struct gpd_board_drvdata *const drvdata = gpd_driver_priv.drvdata;
+	u8 var;
+	int ret = gpd_ecram_read(drvdata, drvdata->pwm_write, &var);
+
+	if (ret < 0)
+		return ret;
+
+	return var * 255 / drvdata->pwm_max;
+}
+
+// Read value for pwm1
+static int gpd_read_pwm(void)
+{
+	switch (gpd_driver_priv.drvdata->board) {
+	case win_mini:
+	case win4_6800u:
+		return gpd_driver_priv.pwm_value;
+	case win_max_2:
+		return gpd_wm2_read_pwm_uncached();
+	}
+	return 0;
+}
+
+static int gpd_generic_write_pwm(u8 val)
+{
+	const struct gpd_board_drvdata *const drvdata = gpd_driver_priv.drvdata;
+	u8 actual;
+
+	// PWM value's range in EC is 1 - pwm_max, cast 0 - 255 to it.
+	actual = val * (drvdata->pwm_max - 1) / 255 + 1;
+	return gpd_ecram_write(drvdata, drvdata->pwm_write, actual);
+}
+
+static int gpd_win_mini_write_pwm(u8 val)
+{
+	if (gpd_driver_priv.pwm_enable == MANUAL)
+		return gpd_generic_write_pwm(val);
+	else
+		return -EPERM;
+}
+
+static int gpd_wm2_write_pwm(u8 val)
+{
+	if (gpd_driver_priv.pwm_enable != DISABLE)
+		return gpd_generic_write_pwm(val);
+	else
+		return -EPERM;
+}
+
+// Write value for pwm1
+static int gpd_write_pwm(u8 val)
+{
+	switch (gpd_driver_priv.drvdata->board) {
+	case win_mini:
+		return gpd_win_mini_write_pwm(val);
+	case win4_6800u:
+		return gpd_generic_write_pwm(val);
+	case win_max_2:
+		return gpd_wm2_write_pwm(val);
+	}
+	return 0;
+}
+
+static int gpd_win_mini_set_pwm_enable(enum FAN_PWM_ENABLE pwm_enable)
+{
+	switch (pwm_enable) {
+	case DISABLE:
+		return gpd_generic_write_pwm(255);
+	case MANUAL:
+		return gpd_generic_write_pwm(gpd_driver_priv.pwm_value);
+	case AUTOMATIC:
+		const struct gpd_board_drvdata *drvdata = gpd_driver_priv.drvdata;
+
+		return gpd_ecram_write(drvdata, drvdata->pwm_write, 0);
+	}
+	return 0;
+}
+
+static int gpd_wm2_set_pwm_enable(enum FAN_PWM_ENABLE enable)
+{
+	const struct gpd_board_drvdata *const drvdata = gpd_driver_priv.drvdata;
+	int ret;
+
+	switch (enable) {
+	case DISABLE: {
+		ret = gpd_generic_write_pwm(255);
+
+		if (ret)
+			return ret;
+
+		return gpd_ecram_write(drvdata, drvdata->manual_control_enable, 1);
+	}
+	case MANUAL: {
+		ret = gpd_generic_write_pwm(gpd_driver_priv.pwm_value);
+
+		if (ret)
+			return ret;
+
+		return gpd_ecram_write(drvdata, drvdata->manual_control_enable, 1);
+	}
+	case AUTOMATIC: {
+		ret = gpd_ecram_write(drvdata, drvdata->manual_control_enable, 0);
+
+		return ret;
+	}
+	}
+	return 0;
+}
+
+// Write value for pwm1_enable
+static int gpd_set_pwm_enable(enum FAN_PWM_ENABLE enable)
+{
+	switch (gpd_driver_priv.drvdata->board) {
+	case win_mini:
+	case win4_6800u:
+		return gpd_win_mini_set_pwm_enable(enable);
+	case win_max_2:
+		return gpd_wm2_set_pwm_enable(enable);
+	}
+	return 0;
+}
+
+static umode_t gpd_fan_hwmon_is_visible(__always_unused const void *drvdata,
+					enum hwmon_sensor_types type, u32 attr,
+					__always_unused int channel)
+{
+	if (type == hwmon_fan && attr == hwmon_fan_input) {
+		return 0444;
+	} else if (type == hwmon_pwm) {
+		switch (attr) {
+		case hwmon_pwm_enable:
+		case hwmon_pwm_input:
+			return 0644;
+		default:
+			return 0;
+		}
+	}
+	return 0;
+}
+
+static int gpd_fan_hwmon_read(__always_unused struct device *dev,
+			      enum hwmon_sensor_types type, u32 attr,
+			      __always_unused int channel, long *val)
+{
+	if (type == hwmon_fan) {
+		if (attr == hwmon_fan_input) {
+			int ret = gpd_read_rpm();
+
+			if (ret < 0)
+				return ret;
+
+			*val = ret;
+			return 0;
+		}
+		return -EOPNOTSUPP;
+	}
+	if (type == hwmon_pwm) {
+		switch (attr) {
+		case hwmon_pwm_enable:
+			*val = gpd_driver_priv.pwm_enable;
+			return 0;
+		case hwmon_pwm_input:
+			int ret = gpd_read_pwm();
+
+			if (ret < 0)
+				return ret;
+
+			*val = ret;
+			return 0;
+		default:
+			return -EOPNOTSUPP;
+		}
+	}
+	return -EOPNOTSUPP;
+}
+
+static int gpd_fan_hwmon_write(__always_unused struct device *dev,
+			       enum hwmon_sensor_types type, u32 attr,
+			       __always_unused int channel, long val)
+{
+	if (type == hwmon_pwm) {
+		switch (attr) {
+		case hwmon_pwm_enable:
+			if (!in_range(val, 0, 3))
+				return -EINVAL;
+			gpd_driver_priv.pwm_enable = val;
+			return gpd_set_pwm_enable(gpd_driver_priv.pwm_enable);
+		case hwmon_pwm_input:
+			u8 var = clamp_val(val, 0, 255);
+
+			gpd_driver_priv.pwm_value = var;
+			return gpd_write_pwm(var);
+		default:
+			return -EOPNOTSUPP;
+		}
+	}
+	return -EOPNOTSUPP;
+}
+
+static const struct hwmon_ops gpd_fan_ops = {
+	.is_visible = gpd_fan_hwmon_is_visible,
+	.read = gpd_fan_hwmon_read,
+	.write = gpd_fan_hwmon_write,
+};
+
+static const struct hwmon_channel_info *gpd_fan_hwmon_channel_info[] = {
+	HWMON_CHANNEL_INFO(fan, HWMON_F_INPUT),
+	HWMON_CHANNEL_INFO(pwm, HWMON_PWM_INPUT | HWMON_PWM_ENABLE), NULL
+};
+
+static struct hwmon_chip_info gpd_fan_chip_info = {
+	.ops = &gpd_fan_ops,
+	.info = gpd_fan_hwmon_channel_info
+};
+
+static int gpd_fan_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct gpd_driver_priv *data;
+	const struct resource *plat_res;
+	const struct device *dev_reg;
+	const struct resource *region_res;
+
+	data = dev_get_platdata(&pdev->dev);
+	if (IS_ERR(data))
+		return -ENODEV;
+
+	plat_res = platform_get_resource(pdev, IORESOURCE_IO, 0);
+	if (IS_ERR(plat_res))
+		return dev_err_probe(dev, PTR_ERR(plat_res),
+				     "Failed to get platform resource\n");
+
+	region_res = devm_request_region(dev, plat_res->start,
+					 resource_size(plat_res), DRIVER_NAME);
+	if (IS_ERR(region_res))
+		return dev_err_probe(dev, PTR_ERR(region_res),
+				     "Failed to request region\n");
+
+	dev_reg = devm_hwmon_device_register_with_info(dev,
+						       DRIVER_NAME,
+						       data,
+						       &gpd_fan_chip_info,
+						       NULL);
+	if (IS_ERR(dev_reg))
+		return dev_err_probe(dev, PTR_ERR(region_res),
+				     "Failed to register hwmon device\n");
+
+	return 0;
+}
+
+static void gpd_fan_remove(__always_unused struct platform_device *pdev)
+{
+	gpd_driver_priv.pwm_enable = AUTOMATIC;
+	gpd_set_pwm_enable(AUTOMATIC);
+}
+
+static struct platform_driver gpd_fan_driver = {
+	.probe	= gpd_fan_probe,
+	.remove	= gpd_fan_remove,
+	.driver	= {
+		.name	= KBUILD_MODNAME,
+	},
+};
+
+static struct platform_device *gpd_fan_platform_device;
+
+static int __init gpd_fan_init(void)
+{
+	const struct gpd_board_drvdata *match = NULL;
+
+	for (const struct gpd_board_drvdata **p = gpd_module_drvdata; *p; p++) {
+		if (strcmp(gpd_fan_board, (*p)->board_name) == 0) {
+			match = *p;
+			break;
+		}
+	}
+
+	if (!match)
+		match = dmi_first_match(dmi_table)->driver_data;
+
+	if (!match)
+		return -ENODEV;
+
+	gpd_driver_priv.pwm_enable = AUTOMATIC;
+	gpd_driver_priv.pwm_value = 255;
+	gpd_driver_priv.drvdata = match;
+
+	struct resource gpd_fan_resources[] = {
+		{
+			.start = match->addr_port,
+			.end = match->data_port,
+			.flags = IORESOURCE_IO,
+		},
+	};
+
+	gpd_fan_platform_device = platform_create_bundle(&gpd_fan_driver,
+							 gpd_fan_probe,
+							 gpd_fan_resources,
+							 1, NULL, 0);
+
+	if (IS_ERR(gpd_fan_platform_device)) {
+		pr_warn("Failed to create platform device\n");
+		return PTR_ERR(gpd_fan_platform_device);
+	}
+
+	return 0;
+}
+
+static void __exit gpd_fan_exit(void)
+{
+	platform_device_unregister(gpd_fan_platform_device);
+	platform_driver_unregister(&gpd_fan_driver);
+}
+
+MODULE_DEVICE_TABLE(dmi, dmi_table);
+
+module_init(gpd_fan_init)
+module_exit(gpd_fan_exit)
+
+MODULE_LICENSE("GPL");
+MODULE_AUTHOR("Cryolitia <Cryolitia@gmail.com>");
+MODULE_DESCRIPTION("GPD Devices fan control driver");

-- 
2.47.1

