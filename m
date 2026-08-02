From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:21 +0200
Subject: [PATCH v3 05/15] drivers: fan: add fan subsystem, core API and
 G76x fan controller driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-rn102-rn104-series-v3-5-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=48323;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=RmHioB2JheS7/iLreT4HE44PJF9jXhSc6UuEwLVSDMw=;
 b=gkL6AWKyeM/GGt0VIi3GNQh6sSskXgX8JJhzUUcWq5wKv9HKqISEaI0hCKQzhy5tnLwS1AvTm
 meQUUzd+lJ4CI8RGSWUR2NiaDrWiQ9kkW7d9t/OQ09XUkfoBzBbsP8N
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a new fan subsystem with a shared API for multiple fan controller backends.
The subsystem provides a common interface for configuring and reading common fan
parameters like speed, level percentage, tachometer values,
and exposing fan devices to upper layers.

Add the initial controller implementation for the G76x family,
including Kconfig/Makefile entries, register layout, and support for
basic PWM and tachometer functionality.
---
 drivers/Kconfig                            |    1 +
 drivers/Makefile                           |    1 +
 drivers/fan/Kconfig                        |   35 +
 drivers/fan/Makefile                       |    8 +
 drivers/fan/fan.c                          |  180 +++++
 drivers/fan/i2c_fan_controllers/Kconfig    |    6 +
 drivers/fan/i2c_fan_controllers/Makefile   |    5 +
 drivers/fan/i2c_fan_controllers/g76x.c     | 1185 ++++++++++++++++++++++++++++
 drivers/fan/other_fan_controllers/Kconfig  |    7 +
 drivers/fan/other_fan_controllers/Makefile |    3 +
 drivers/fan/spi_fan_controllers/Kconfig    |    1 +
 drivers/fan/spi_fan_controllers/Makefile   |    3 +
 include/fan/fan.h                          |   94 +++
 include/fan/i2c_fan_controllers/g76x.h     |   37 +
 14 files changed, 1566 insertions(+)

diff --git a/drivers/Kconfig b/drivers/Kconfig
index 32910addcd..b1ba73887a 100644
--- a/drivers/Kconfig
+++ b/drivers/Kconfig
@@ -50,5 +50,6 @@ source "drivers/power/Kconfig"
 source "drivers/virtio/Kconfig"
 source "drivers/mailbox/Kconfig"
 source "drivers/tee/Kconfig"
+source "drivers/fan/Kconfig"
 
 endmenu
diff --git a/drivers/Makefile b/drivers/Makefile
index db491dad83..4d6071fdc7 100644
--- a/drivers/Makefile
+++ b/drivers/Makefile
@@ -51,3 +51,4 @@ obj-$(CONFIG_SOUND) += sound/
 obj-y	+= virtio/
 obj-y	+= mailbox/
 obj-y	+= tee/
+obj-$(CONFIG_FAN) += fan/
diff --git a/drivers/fan/Kconfig b/drivers/fan/Kconfig
new file mode 100644
index 0000000000..0ff71d7e7d
--- /dev/null
+++ b/drivers/fan/Kconfig
@@ -0,0 +1,35 @@
+# SPDX-License-Identifier: GPL-2.0-only
+menuconfig FAN
+	bool "Fan controller drivers"
+	help
+		Add support for various fan controllers.
+
+if FAN
+
+menuconfig I2C_FAN
+	bool "i2c fan controllers support"
+	depends on I2C
+	help
+		add support for fan controllers based on i2c interface.
+	if I2C_FAN
+	source "drivers/fan/i2c_fan_controllers/Kconfig"
+	endif
+
+menuconfig SPI_FAN
+	bool "spi fan controllers support"
+	depends on SPI
+	help
+		add support fan controllers based on spi interface.
+	if SPI_FAN
+	source "drivers/fan/spi_fan_controllers/Kconfig"
+	endif
+
+menuconfig OTHER_FAN
+	bool "other fan controllers support"
+	help
+		support other fan control methods.
+	if OTHER_FAN
+	source "drivers/fan/other_fan_controllers/Kconfig"
+	endif
+
+endif
diff --git a/drivers/fan/Makefile b/drivers/fan/Makefile
new file mode 100644
index 0000000000..9ff140c0da
--- /dev/null
+++ b/drivers/fan/Makefile
@@ -0,0 +1,8 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+# fan controller interface types
+
+obj-y += fan.o
+obj-$(CONFIG_I2C_FAN) += i2c_fan_controllers/
+obj-$(CONFIG_SPI_FAN) += spi_fan_controllers/
+obj-$(CONFIG_OTHER_FAN) += other_fan_controllers/
diff --git a/drivers/fan/fan.c b/drivers/fan/fan.c
new file mode 100644
index 0000000000..4ec675d01a
--- /dev/null
+++ b/drivers/fan/fan.c
@@ -0,0 +1,180 @@
+#include <fan/fan.h>
+
+/* Generic fan driver fan device management */
+
+LIST_HEAD(fan_device_list);
+
+static void fan_set_dev(struct fan_device *fan, struct device *dev)
+{
+	fan->dev = dev;
+}
+/*
+static struct device *fan_get_dev(struct fan_device *fan)
+{
+	return fan->dev;
+}
+*/
+static void fan_set_ops(struct fan_device *fan, struct fan_ops *ops)
+{
+	fan->ops = ops;
+}
+/*
+static const struct fan_ops *fan_get_ops(struct fan_device *fan)
+{
+	return fan->ops;
+}
+*/
+
+/* Generic filesystem fan device management */
+
+static int fan_idx = 0;
+
+static void cdev_set_fan(struct fan_device *fan)
+{
+	struct cdev *cdev = fan->cdev;
+
+	cdev->priv = fan;
+	cdev->dev  = fan->dev;
+	cdev->ops  = NULL;
+	cdev->size = 0;
+	cdev->flags = 0;
+}
+/*
+static struct fan_device *cdev_get_fan(struct cdev *cdev)
+{
+	return cdev->priv;
+}
+*/
+static int cdev_set_name(struct cdev *cdev)
+{
+	char name[32];
+
+	if (snprintf(name, sizeof(name), "fan%d", fan_idx++) >= sizeof(name))
+		return -EINVAL;
+
+	cdev->name = xstrdup(name);
+	if (!cdev->name)
+		return -ENOMEM;
+
+	return 0;
+}
+/*
+static char *cdev_get_name(struct cdev *cdev)
+{
+	return cdev->name;
+}
+*/
+struct fan_device *fan_device_find(const char *devmatch)
+{
+	struct fan_device *fan = NULL;
+	char devpath[32];
+
+	if (!devmatch || strlen(devmatch) > sizeof(devpath) - sizeof("/dev/"))
+		return ERR_PTR(-EINVAL);
+
+	list_for_each_entry(fan, &fan_device_list, list) {
+		/* search by driver-specific fan controller device */
+		if (fan->dev && fan->dev->name) {
+			snprintf(devpath, sizeof(devpath),
+						"/dev/%s", fan->dev->name);
+
+			/* by path ("/dev/.../ctrlr name") */
+			if (!strcmp(devpath, devmatch))
+				return fan;
+
+			/* or by name ("ctrlr name") */
+			if (!strcmp(fan->dev->name, devmatch))
+				return fan;
+		}
+		/* search by filesystem generic fan device */
+		if (fan->cdev && fan->cdev->name) {
+			snprintf(devpath, sizeof(devpath),
+						"/dev/%s", fan->cdev->name);
+			/* by path ("/dev/fanX") or by name ("fanX") */
+			if (!strcmp(devpath, devmatch) ||
+				!strcmp(fan->cdev->name, devmatch))
+				return fan;
+		}
+	}
+
+	return ERR_PTR(-ENODEV);
+}
+
+
+/* specific fan controller driver device management */
+
+int fan_device_register(struct device *dev, struct fan_ops *ops)
+{
+	struct fan_device *fan;
+	int ret;
+
+	if (!dev || !ops)
+		return -EINVAL;
+
+	/* allocate and initialize generic fan device structure */
+	fan = xzalloc(sizeof(*fan));
+	if (!fan)
+		return -ENOMEM;
+
+	fan->cdev = xzalloc(sizeof(*fan->cdev));
+	if (!fan->cdev) {
+		free(fan);
+		return -ENOMEM;
+	}
+
+	fan_set_dev(fan, dev);
+	fan_set_ops(fan, ops);
+	dev->type_data = fan;
+
+	list_add(&fan->list, &fan_device_list);
+
+	cdev_set_fan(fan);
+
+	ret = cdev_set_name(fan->cdev);
+	if (ret)
+		goto err;
+
+	ret = devfs_create(fan->cdev);
+	if (ret)
+		goto err;
+
+	// expose fan parameters as global variables
+	// globalvar_add_simple_int(".clk_freq", (int *)fan->ops->get_clk_freq, "%u");
+	// globalvar_add_simple_bool(".fail_state", (int *)fan->ops->get_failure_state);
+	// globalvar_add_simple_bool(".ooc_state", (int *)fan->ops->get_failure_state);
+
+	return 0;
+
+err:
+	if (fan->cdev->name)
+		free(fan->cdev->name);
+	free(fan->cdev);
+	free(fan);
+	dev->type_data = NULL;
+	return ret;
+}
+
+void fan_device_unregister(struct device *dev)
+{
+	/* find the generic fan device associated to the driver-specific fan controller device */
+	struct fan_device *fan;
+
+	if (!dev)
+		return;
+
+	fan = dev->type_data;
+	if (!fan)
+		return;
+
+	list_del(&fan->list);
+
+	if (fan->cdev) {
+		devfs_remove(fan->cdev);
+		if (fan->cdev->name)
+			free(fan->cdev->name);
+		free(fan->cdev);
+	}
+
+	free(fan);
+	dev->type_data = NULL;
+}
diff --git a/drivers/fan/i2c_fan_controllers/Kconfig b/drivers/fan/i2c_fan_controllers/Kconfig
new file mode 100644
index 0000000000..e258783848
--- /dev/null
+++ b/drivers/fan/i2c_fan_controllers/Kconfig
@@ -0,0 +1,6 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+config G76x
+	bool "GMT G76x driver"
+	help
+	Support Global Mixed-mode Technology Inc. G762 and G763 fan speed PWM controller chips
diff --git a/drivers/fan/i2c_fan_controllers/Makefile b/drivers/fan/i2c_fan_controllers/Makefile
new file mode 100644
index 0000000000..ca3c49e8a2
--- /dev/null
+++ b/drivers/fan/i2c_fan_controllers/Makefile
@@ -0,0 +1,5 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+# fan controller interface types
+
+obj-$(CONFIG_G76x) += g76x.o
\ No newline at end of file
diff --git a/drivers/fan/i2c_fan_controllers/g76x.c b/drivers/fan/i2c_fan_controllers/g76x.c
new file mode 100644
index 0000000000..da34dcb9da
--- /dev/null
+++ b/drivers/fan/i2c_fan_controllers/g76x.c
@@ -0,0 +1,1185 @@
+/*
+ * g76x - Driver for the Global Mixed-mode Technology Inc. fan speed
+ *        PWM controller chips from G76x family, i.e. g76x and G763
+ *
+ * based on g760a code written by Herbert Valerio Riedel <hvr@gnu.org>
+ * Copyright (C) 2007  Herbert Valerio Riedel <hvr@gnu.org>
+ *
+ * Author: Olivier Mouchet <olivier.mouchet@gmail.com>
+ * Copyright (c) 2009 LaCie
+ *
+ * Copyright (C) 2013, Arnaud EBALARD <arno@natisbad.org>
+ *
+ * g76x: minimal datasheet available at:
+ *       http://www.gmt.com.tw/product/datasheet/EDS-762_3.pdf
+ *
+ * This program is free software; you can redistribute it and/or modify
+ * it under the terms of the GNU General Public License as published by
+ * the Free Software Foundation; either version 2 of the License, or
+ * (at your option) any later version.
+ *
+ * This program is distributed in the hope that it will be useful,
+ * but WITHOUT ANY WARRANTY; without even the implied warranty of
+ * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
+ * GNU General Public License for more details.
+ *
+ * You should have received a copy of the GNU General Public License
+ * along with this program; if not, write to the Free Software
+ * Foundation.
+ */
+
+#include <fan/fan.h>
+#include <stdbool.h>
+#include <i2c/i2c.h>
+#include <init.h>
+#include <of.h>
+#include <of_device.h>
+#include <linux/minmax.h>
+#include <linux/err.h>
+#include <linux/mutex.h>
+#include <linux/limits.h>
+
+/*
+ * driver-specific layer
+ */
+
+static const struct platform_device_id g76x_id[] = {
+	{ "g762", 0 },
+	{ "g763", 0 },
+	{ /* sentinel */ },
+};
+MODULE_DEVICE_TABLE(i2c, g76x_id);
+
+enum g76x_regs {
+	G76x_REG_SET_CNT  = 0x00,
+	G76x_REG_ACT_CNT  = 0x01,
+	G76x_REG_FAN_STA  = 0x02,
+	G76x_REG_SET_OUT  = 0x03,
+	G76x_REG_FAN_CMD1 = 0x04,
+	G76x_REG_FAN_CMD2 = 0x05,
+};
+
+/* Config register bits */
+#define G76x_REG_FAN_CMD1_DET_FAN_FAIL	0x80 /* enable fan_fail signal */
+#define G76x_REG_FAN_CMD1_DET_FAN_OOC	0x40 /* enable fan_out_of_control */
+#define G76x_REG_FAN_CMD1_OUT_MODE		0x20 /* out mode: PWM or DC */
+#define G76x_REG_FAN_CMD1_CTRL_MODE		0x10 /* fan mode: closed/open-loop */
+#define G76x_REG_FAN_CMD1_CLK_DIV_ID1	0x08 /* clock divisor value */
+#define G76x_REG_FAN_CMD1_CLK_DIV_ID0	0x04
+#define G76x_REG_FAN_CMD1_PWM_POLARITY	0x02 /* PWM polarity */
+#define G76x_REG_FAN_CMD1_PULSE_PER_REV	0x01 /* pulse per fan revolution */
+
+#define G76x_REG_FAN_CMD2_GEAR_MODE_1	0x08 /* fan gear mode */
+#define G76x_REG_FAN_CMD2_GEAR_MODE_0	0x04
+#define G76x_REG_FAN_CMD2_FAN_STARTV_1	0x02 /* fan startup voltage */
+#define G76x_REG_FAN_CMD2_FAN_STARTV_0	0x01
+
+#define G76x_REG_FAN_STA_FAIL			0x02 /* fan fail */
+#define G76x_REG_FAN_STA_OOC			0x01 /* fan out of control */
+
+/* Config register values */
+#define G76x_OUT_MODE_PWM			1
+#define G76x_OUT_MODE_ADC			0
+
+#define G76x_FAN_MODE_CLOSED_LOOP	1
+#define G76x_FAN_MODE_OPEN_LOOP		0
+
+#define G76x_PWM_POLARITY_NEGATIVE	1
+#define G76x_PWM_POLARITY_POSITIVE	0
+
+/* Register data is read (and cached) at most once per second. */
+#define G76x_UPDATE_INTERVAL_NS		1000000
+
+/*
+ * Extract fan startup voltage value (0, 1, 2 or 3) from given
+ * FAN_CMD2 register value.
+ */
+#define G76x_STARTV_FROM_REG(reg) \
+	((reg) & (G76x_REG_FAN_CMD2_FAN_STARTV_0 |	\
+			G76x_REG_FAN_CMD2_FAN_STARTV_1))
+
+/*
+ * Extract fan gear mode multiplier value (0, 2 or 4) from given
+ * FAN_CMD2 register value.
+ */
+#define G76x_GEARMULT_FROM_REG(reg) \
+	(1 << (((reg) & (G76x_REG_FAN_CMD2_GEAR_MODE_0 |	\
+			G76x_REG_FAN_CMD2_GEAR_MODE_1)) >> 2))
+
+/*
+ * Extract pulse count per fan revolution value (2 or 4) from given
+ * FAN_CMD1 register value.
+ */
+#define G76x_PULSE_FROM_REG(reg) \
+	((((reg) & G76x_REG_FAN_CMD1_PULSE_PER_REV) + 1) << 1)
+
+/*
+ * Extract fan clock divisor (1, 2, 4 or 8) from given FAN_CMD1
+ * register value.
+ */
+#define G76x_CLKDIV_FROM_REG(reg) \
+	(1 << (((reg) & (G76x_REG_FAN_CMD1_CLK_DIV_ID0 |	\
+			 G76x_REG_FAN_CMD1_CLK_DIV_ID1)) >> 2))
+
+struct g76x_data {
+	struct i2c_client *client;
+	struct clk *clk;
+
+	/* update mutex */
+	struct mutex update_lock;
+
+	/* board specific parameters. */
+	uint32_t clk_freq;
+
+	/* g76x register cache */
+	bool valid;
+	uint64_t last_updated; /* in nanoseconds */
+
+	uint8_t set_cnt;	/* controls fan rotation speed in closed-loop mode */
+	uint8_t act_cnt;	/* provides access to current fan RPM value */
+	uint8_t fan_sta;	/* bit 0: set when actual fan speed is more than
+						 * 		  25% outside requested fan speed
+						 * bit 1: set when no transition occurs on fan
+						 * 		  pin for 0.7s
+						 */
+	uint8_t set_out;	/* controls fan rotation speed in open-loop mode */
+	uint8_t fan_cmd1;	/* 0: FG_PLS_ID0 FG pulses count per revolution
+						 * 		0: 2 counts per revolution
+						 * 		1: 4 counts per revolution
+						 * 1: PWM_POLARITY
+						 * 		1: negative_duty
+						 * 		0: positive_duty
+						 * 2,3: [FG_CLOCK_ID0, FG_CLK_ID1]
+						 * 		00: Divide fan clock by 1
+						 * 		01: Divide fan clock by 2
+						 * 		10: Divide fan clock by 4
+						 * 		11: Divide fan clock by 8
+						 * 4: FAN_MODE 1:closed-loop, 0:open-loop
+						 * 5: OUT_MODE 1:PWM, 0:DC
+						 * 6: DET_FAN_OOC enable "fan ooc" status
+						 * 7: DET_FAN_FAIL enable "fan fail" status
+						 */
+	uint8_t fan_cmd2; 	/* 0,1: FAN_STARTV 0,1,2,3 -> 0,32,64,96 dac_code
+						 * 2,3: FG_GEAR_MODE
+						 * 		00: multiplier = 1
+						 * 		01: multiplier = 2
+						 * 		10: multiplier = 4
+						 * 4: Mask ALERT# (g763 only)
+						 */
+};
+
+/*
+ * Following structure can be used to set g762 driver-specific platform data
+ * during board init. Note that passing a sparse structure is possible but
+ * will result in non-specified attributes to be set to default value, hence
+ * overloading those installed during boot (e.g. by u-boot).
+ */
+struct g76x_platform_data {
+	unsigned int fan_startv;
+	unsigned int fan_gear_mode;
+	unsigned int pwm_polarity;
+	unsigned int clk_freq;
+};
+
+/* driver-specific helpers */
+
+/*
+ * Convert count value from fan controller register (FAN_SET_CNT) into fan
+ * speed RPM value. Note that the datasheet documents a basic formula;
+ * influence of additional parameters (fan clock divisor, fan gear mode)
+ * have been infered from examples in the datasheet and tests.
+ */
+static inline unsigned int g76x_rpm_from_cnt(uint8_t cnt, uint32_t clk_freq, uint16_t p,
+					uint8_t clk_div, uint8_t gear_mult)
+{
+	return (clk_freq * 30 * gear_mult) / ((cnt ? cnt : 1) * p * clk_div);
+}
+
+/*
+ * Convert fan RPM value into pulse count value for fan controller
+ * register (FAN_SET_CNT).
+ */
+static inline unsigned char g76x_cnt_from_rpm(unsigned long rpm, uint32_t clk_freq, uint16_t p,
+					 uint8_t clk_div, uint8_t gear_mult)
+{
+	unsigned long f1 = clk_freq * 30 * gear_mult;
+	unsigned long f2 = p * clk_div;
+
+	rpm = clamp_val(rpm, f1 / (255 * f2), ULONG_MAX / f2);
+	return DIV_ROUND_CLOSEST(f1, rpm * f2);
+}
+
+/*
+ * Convert count value for fan controller register (FAN_SET_CNT)
+ * into percentage of full speed (0 to 100).
+ */
+static inline unsigned int g76x_level_from_cnt(uint8_t cnt) {
+	uint8_t level = 0;
+	cnt = clamp_val(cnt, 0, 255);
+	level = (cnt * 100) / 255;
+	return level;
+}
+
+/*
+ * Convert percentage of full speed into count value for 
+ * fan controller register (FAN_SET_CNT).
+ */
+static inline unsigned int g76x_cnt_from_level(unsigned char level) {
+	unsigned char cnt = 0;
+	level = clamp_val(level, 0, 100);
+	cnt = (level * 255) / 100;
+	return cnt;
+}
+
+/* helper to manage g76x errors */
+static struct g76x_data *g76x_error_handle(struct g76x_data *data, int err_ret)
+{
+	if (data) {
+		mutex_unlock(&data->update_lock);
+		dev_err(&data->client->dev, "g76x error: %d\n", err_ret);
+	}
+
+	return ERR_PTR(err_ret);
+}
+
+/* helper to grab and cache data, at most one time per second */
+static struct g76x_data *g76x_update_client(struct device *dev)
+{
+	struct g76x_data *data = dev->priv;
+	if (!data) return ERR_PTR(-ENODEV);
+	struct i2c_client *client = data->client;
+	int ret = 0;
+
+	mutex_lock(&data->update_lock);
+
+	if (data->valid && !is_timeout(data->last_updated, G76x_UPDATE_INTERVAL_NS)) {
+		mutex_unlock(&data->update_lock);
+		return data;
+	}
+
+	ret = i2c_smbus_read_byte_data(client, G76x_REG_SET_CNT);
+	if (ret < 0) goto err_update;
+	data->set_cnt = ret;
+
+	ret = i2c_smbus_read_byte_data(client, G76x_REG_ACT_CNT);
+	if (ret < 0) goto err_update;
+	data->act_cnt = ret;
+
+	ret = i2c_smbus_read_byte_data(client, G76x_REG_FAN_STA);
+	if (ret < 0) goto err_update;
+	data->fan_sta = ret;
+
+	ret = i2c_smbus_read_byte_data(client, G76x_REG_SET_OUT);
+	if (ret < 0) goto err_update;
+	data->set_out = ret;
+
+	ret = i2c_smbus_read_byte_data(client, G76x_REG_FAN_CMD1);
+	if (ret < 0) goto err_update;
+	data->fan_cmd1 = ret;
+
+	ret = i2c_smbus_read_byte_data(client, G76x_REG_FAN_CMD2);
+	if (ret < 0) goto err_update;
+	data->fan_cmd2 = ret;
+
+	data->last_updated = get_time_ns();
+	data->valid = true;
+
+	mutex_unlock(&data->update_lock);
+	return data;
+
+err_update:
+	data->valid = false;
+	return g76x_error_handle(data, ret);
+}
+
+
+/* driver-specific configuration functions */
+
+/* Get and Set fan startup voltage. Accepted values are either 0, 1, 2 or 3. */
+static int g76x_get_fan_startv(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", G76x_STARTV_FROM_REG(data->fan_cmd2));
+}
+
+static int g76x_set_fan_startv(struct device *dev, unsigned long val)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	int ret;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	mutex_lock(&data->update_lock);
+	switch (val) {
+	case 0:
+		data->fan_cmd2 &= ~G76x_REG_FAN_CMD2_FAN_STARTV_0;
+		data->fan_cmd2 &= ~G76x_REG_FAN_CMD2_FAN_STARTV_1;
+		break;
+	case 1:
+		data->fan_cmd2 |=  G76x_REG_FAN_CMD2_FAN_STARTV_0;
+		data->fan_cmd2 &= ~G76x_REG_FAN_CMD2_FAN_STARTV_1;
+		break;
+	case 2:
+		data->fan_cmd2 &= ~G76x_REG_FAN_CMD2_FAN_STARTV_0;
+		data->fan_cmd2 |=  G76x_REG_FAN_CMD2_FAN_STARTV_1;
+		break;
+	case 3:
+		data->fan_cmd2 |=  G76x_REG_FAN_CMD2_FAN_STARTV_0;
+		data->fan_cmd2 |=  G76x_REG_FAN_CMD2_FAN_STARTV_1;
+		break;
+	default:
+		mutex_unlock(&data->update_lock);
+		return -EINVAL;
+	}
+	ret = i2c_smbus_write_byte_data(data->client, G76x_REG_FAN_CMD2,
+					data->fan_cmd2);
+	data->valid = false;
+	mutex_unlock(&data->update_lock);
+
+	return ret;
+}
+
+/* Get and Set fan gear multiplier. Accepts either 0, 1 or 2. */
+static int g76x_get_gear_multiplier(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", G76x_GEARMULT_FROM_REG(data->fan_cmd2));
+}
+
+static int g76x_set_gear_multiplier(struct device *dev, unsigned long val)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	int ret;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	mutex_lock(&data->update_lock);
+	switch (val) {
+	case 0:
+		data->fan_cmd2 &= ~G76x_REG_FAN_CMD2_GEAR_MODE_0;
+		data->fan_cmd2 &= ~G76x_REG_FAN_CMD2_GEAR_MODE_1;
+		break;
+	case 1:
+		data->fan_cmd2 |=  G76x_REG_FAN_CMD2_GEAR_MODE_0;
+		data->fan_cmd2 &= ~G76x_REG_FAN_CMD2_GEAR_MODE_1;
+		break;
+	case 2:
+		data->fan_cmd2 &= ~G76x_REG_FAN_CMD2_GEAR_MODE_0;
+		data->fan_cmd2 |=  G76x_REG_FAN_CMD2_GEAR_MODE_1;
+		break;
+	default:
+		mutex_unlock(&data->update_lock);
+		return -EINVAL;
+	}
+	ret = i2c_smbus_write_byte_data(data->client, G76x_REG_FAN_CMD2,
+					data->fan_cmd2);
+	data->valid = false;
+	mutex_unlock(&data->update_lock);
+
+	return ret;
+}
+
+/* Get and Set number of fan pulses per revolution. Accepts either 2 or 4. */
+static int g76x_get_fan_ppr(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", G76x_PULSE_FROM_REG(data->fan_cmd1));
+}
+
+static int g76x_set_fan_ppr(struct device *dev, unsigned long val)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	int ret;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	mutex_lock(&data->update_lock);
+	switch (val) {
+	case 2:
+		data->fan_cmd1 &= ~G76x_REG_FAN_CMD1_PULSE_PER_REV;
+		break;
+	case 4:
+		data->fan_cmd1 |=  G76x_REG_FAN_CMD1_PULSE_PER_REV;
+		break;
+	default:
+		mutex_unlock(&data->update_lock);
+		return -EINVAL;
+	}
+	ret = i2c_smbus_write_byte_data(data->client, G76x_REG_FAN_CMD1,
+					data->fan_cmd1);
+	data->valid = false;
+	mutex_unlock(&data->update_lock);
+
+	return ret;
+}
+
+/* Get and Set PWM polarity. Accepts either 0 (positive duty) or 1 (negative duty) */
+static int g76x_get_pwm_polarity(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", !!(data->fan_cmd1 & G76x_REG_FAN_CMD1_PWM_POLARITY));
+}
+
+static int g76x_set_pwm_polarity(struct device *dev, unsigned long val)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	int ret;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	mutex_lock(&data->update_lock);
+	switch (val) {
+	case G76x_PWM_POLARITY_POSITIVE:
+		data->fan_cmd1 &= ~G76x_REG_FAN_CMD1_PWM_POLARITY;
+		break;
+	case G76x_PWM_POLARITY_NEGATIVE:
+		data->fan_cmd1 |=  G76x_REG_FAN_CMD1_PWM_POLARITY;
+		break;
+	default:
+		mutex_unlock(&data->update_lock);
+		return -EINVAL;
+	}
+	ret = i2c_smbus_write_byte_data(data->client, G76x_REG_FAN_CMD1,
+					data->fan_cmd1);
+	data->valid = false;
+	mutex_unlock(&data->update_lock);
+
+	return ret;
+}
+
+/*
+ * Get and Set input clock frequency received on CLK pin of the chip. Accepted values
+ * are between 0 and 0xffffff. If zero is given, then default frequency
+ * (32768Hz) is used. Note that clock frequency is a characteristic of the
+ * system but an internal parameter, i.e. value is not passed to the device.
+ */
+static int g76x_get_clk_freq(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", !!(data->clk_freq));
+}
+
+static int g76x_set_clk_freq(struct device *dev, unsigned long val)
+{
+	struct i2c_client *client = to_i2c_client(dev);
+	struct g76x_data *data = i2c_get_clientdata(client);
+
+	if (!data)
+		return 0;
+
+	if (val == 0)
+		val = 32768;
+
+	else if (val > 100000000)
+		return -EINVAL;
+
+	data->clk_freq = val;
+
+	return 0;
+}
+
+/* Get and Set fan clock divisor. Accepts either 1, 2, 4 or 8. */
+static int g76x_get_clk_div(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", G76x_CLKDIV_FROM_REG(data->fan_cmd1));
+}
+
+static int g76x_set_clk_div(struct device *dev, unsigned long val)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	int ret;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	mutex_lock(&data->update_lock);
+	switch (val) {
+	case 1:
+		data->fan_cmd1 &= ~G76x_REG_FAN_CMD1_CLK_DIV_ID0;
+		data->fan_cmd1 &= ~G76x_REG_FAN_CMD1_CLK_DIV_ID1;
+		break;
+	case 2:
+		data->fan_cmd1 |=  G76x_REG_FAN_CMD1_CLK_DIV_ID0;
+		data->fan_cmd1 &= ~G76x_REG_FAN_CMD1_CLK_DIV_ID1;
+		break;
+	case 4:
+		data->fan_cmd1 &= ~G76x_REG_FAN_CMD1_CLK_DIV_ID0;
+		data->fan_cmd1 |=  G76x_REG_FAN_CMD1_CLK_DIV_ID1;
+		break;
+	case 8:
+		data->fan_cmd1 |=  G76x_REG_FAN_CMD1_CLK_DIV_ID0;
+		data->fan_cmd1 |=  G76x_REG_FAN_CMD1_CLK_DIV_ID1;
+		break;
+	default:
+		mutex_unlock(&data->update_lock);
+		return -EINVAL;
+	}
+	ret = i2c_smbus_write_byte_data(data->client, G76x_REG_FAN_CMD1,
+					data->fan_cmd1);
+	data->valid = false;
+	mutex_unlock(&data->update_lock);
+
+	return ret;
+}
+
+/* Get and Set fan control mode. Accepts either 0 (open-loop) or 1 (closed-loop). */
+static int g76x_get_control_mode(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", !!(data->fan_cmd1 & G76x_REG_FAN_CMD1_CTRL_MODE));
+}
+
+static int g76x_set_control_mode(struct device *dev, unsigned long val)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	int ret;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	mutex_lock(&data->update_lock);
+	switch (val) {
+	case G76x_FAN_MODE_CLOSED_LOOP:
+		data->fan_cmd1 |=  G76x_REG_FAN_CMD1_CTRL_MODE;
+		break;
+	case G76x_FAN_MODE_OPEN_LOOP:
+		data->fan_cmd1 &= ~G76x_REG_FAN_CMD1_CTRL_MODE;
+		/*
+		 * NOTE: if SET_CNT register value is 255, fan is disarmed,
+		 * no matter the value of SET_OUT (to be specific, this seems
+		 * to happen only in PWM mode). To workaround this case,
+		 * we give SET_CNT value of 0 if it is 255 when switching to open-loop.
+		 * This means that fan will be armed every time we switch to open-loop.
+		 */
+		if (data->set_cnt == 0xff)
+			i2c_smbus_write_byte_data(data->client, G76x_REG_SET_CNT, 0);
+		break;
+	default:
+		mutex_unlock(&data->update_lock);
+		return -EINVAL;
+	}
+
+	ret = i2c_smbus_write_byte_data(data->client, G76x_REG_FAN_CMD1,
+					data->fan_cmd1);
+	data->valid = false;
+	mutex_unlock(&data->update_lock);
+
+	return ret;
+}
+
+/* Get and Set output mode. Accepts either 0 (ADC) or 1 (PWM) */
+static int g76x_get_output_mode(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", !!(data->fan_cmd1 & G76x_REG_FAN_CMD1_OUT_MODE));
+}
+
+static int g76x_set_output_mode(struct device *dev, unsigned long val)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	int ret;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	mutex_lock(&data->update_lock);
+	switch (val) {
+	case G76x_OUT_MODE_PWM:
+		data->fan_cmd1 |=  G76x_REG_FAN_CMD1_OUT_MODE;
+		break;
+	case G76x_OUT_MODE_ADC:
+		data->fan_cmd1 &= ~G76x_REG_FAN_CMD1_OUT_MODE;
+		break;
+	default:
+		mutex_unlock(&data->update_lock);
+		return -EINVAL;
+	}
+	ret = i2c_smbus_write_byte_data(data->client, G76x_REG_FAN_CMD1,
+					data->fan_cmd1);
+	data->valid = false;
+	mutex_unlock(&data->update_lock);
+
+	return ret;
+}
+
+/* Get and Set fan out of control detection. Accepts either 0 (disabled) or 1 (enabled) */
+static int g76x_get_ooc_detection(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", !!(data->fan_cmd1 & G76x_REG_FAN_CMD1_DET_FAN_OOC));
+}
+
+static int g76x_set_ooc_detection(struct device *dev, unsigned long val)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	int ret;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	mutex_lock(&data->update_lock);
+	switch (val) {
+	case 0:
+		data->fan_cmd1 &= ~G76x_REG_FAN_CMD1_DET_FAN_OOC;
+		break;
+	case 1:
+		data->fan_cmd1 |= G76x_REG_FAN_CMD1_DET_FAN_OOC;
+		break;
+	default:
+		mutex_unlock(&data->update_lock);
+		return -EINVAL;
+	}
+	ret = i2c_smbus_write_byte_data(data->client, G76x_REG_FAN_CMD1,
+									data->fan_cmd1);
+	data->valid = false;
+	mutex_unlock(&data->update_lock);
+
+	return ret;
+}
+
+/* Get and Set fan failure detection. Accepts either 0 (disabled) or 1 (enabled) */
+static int g76x_get_failure_detection(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", !!(data->fan_cmd1 & G76x_REG_FAN_CMD1_DET_FAN_FAIL));
+}
+
+static int g76x_set_failure_detection(struct device *dev, unsigned long val)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	int ret;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	mutex_lock(&data->update_lock);
+	switch (val) {
+	case 0:
+		data->fan_cmd1 &= ~G76x_REG_FAN_CMD1_DET_FAN_FAIL;
+		break;
+	case 1:
+		data->fan_cmd1 |= G76x_REG_FAN_CMD1_DET_FAN_FAIL;
+		break;
+	default:
+		mutex_unlock(&data->update_lock);
+		return -EINVAL;
+	}
+	ret = i2c_smbus_write_byte_data(data->client, G76x_REG_FAN_CMD1,
+									data->fan_cmd1);
+	data->valid = false;
+	mutex_unlock(&data->update_lock);
+
+	return ret;
+}
+
+/*
+ * Import hardware characteristics from .dts file and push
+ * those to the chip.
+ */
+#ifdef CONFIG_OF
+static const struct of_device_id g76x_dt_match[] = {
+	{ .compatible = "gmt,g762" },
+	{ .compatible = "gmt,g763" },
+	{ /* sentinel */ },
+};
+MODULE_DEVICE_TABLE(of, g76x_dt_match);
+/*
+ * Grab clock (a required property), enable it, get (fixed) clock frequency
+ * and store it. Note: upon success, clock has been prepared and enabled; it
+ * must later be unprepared and disabled (e.g. during module unloading) by a
+ * call to g76x_of_clock_disable(). Note that a reference to clock is kept
+ * in our private data structure to be used in this function.
+ */
+static int g76x_of_clock_enable(struct i2c_client *client)
+{
+	struct g76x_data *data;
+	unsigned long clk_freq;
+	struct clk *clk;
+	int ret;
+
+	if (!client->dev.of_node)
+		return 0;
+
+	clk = of_clk_get(client->dev.of_node, 0);
+	if (IS_ERR(clk)) {
+		dev_err(&client->dev, "failed to get clock\n");
+		return PTR_ERR(clk);
+	}
+
+	ret = clk_prepare_enable(clk);
+	if (ret) {
+		dev_err(&client->dev, "failed to enable clock\n");
+		clk_put(clk);
+		return ret;
+	}
+
+	clk_freq = clk_get_rate(clk);
+	ret = g76x_set_clk_freq(&client->dev, clk_freq);
+	if (ret) {
+		dev_err(&client->dev, "invalid clock freq %lu\n", clk_freq);
+		clk_disable_unprepare(clk);
+		clk_put(clk);
+		return ret;
+	}
+
+	data = i2c_get_clientdata(client);
+	data->clk = clk;
+
+	return 0;
+}
+
+static void g76x_of_clock_disable(struct i2c_client *client)
+{
+	struct g76x_data *data = i2c_get_clientdata(client);
+
+	if (!data->clk)
+		return;
+
+	clk_disable_unprepare(data->clk);
+	clk_put(data->clk);
+}
+
+static int g76x_of_prop_import_one(struct i2c_client *client,
+				   const char *pname,
+				   int (*psetter)(struct device *dev,
+						  unsigned long val))
+{
+	int ret;
+	uint32_t pval;
+
+	if (of_property_read_u32(client->dev.of_node, pname, &pval))
+		return 0;
+
+	dev_dbg(&client->dev, "found %s (%d)\n", pname, pval);
+	ret = (*psetter)(&client->dev, pval);
+	if (ret)
+		dev_err(&client->dev, "unable to set %s (%d)\n", pname, pval);
+
+	return ret;
+}
+
+static int g76x_of_prop_import(struct i2c_client *client)
+{
+	int ret;
+
+	if (!client->dev.of_node)
+		return 0;
+
+	ret = g76x_of_prop_import_one(client, "fan_gear_mode",
+					  g76x_set_gear_multiplier);
+	if (ret)
+		return ret;
+
+	ret = g76x_of_prop_import_one(client, "pwm_polarity",
+					  g76x_set_pwm_polarity);
+	if (ret)
+		return ret;
+
+	return g76x_of_prop_import_one(client, "fan_startv",
+					   g76x_set_fan_startv);
+}
+
+#else
+static int g76x_of_prop_import(struct i2c_client *client)
+{
+	return 0;
+}
+
+static int g76x_of_clock_enable(struct i2c_client *client)
+{
+	return 0;
+}
+
+static void g76x_of_clock_disable(struct i2c_client *client) { }
+#endif
+
+/*
+ * Import platform data from chip
+ */
+static int g76x_pdata_prop_import(struct i2c_client *client)
+{
+	struct g76x_platform_data *pdata = client->dev.platform_data;
+	int ret;
+
+	if (!pdata)
+		return 0;
+
+	ret = g76x_set_gear_multiplier(&client->dev, pdata->fan_gear_mode);
+	if (ret)
+		return ret;
+
+	ret = g76x_set_pwm_polarity(&client->dev, pdata->pwm_polarity);
+	if (ret)
+		return ret;
+
+	ret = g76x_set_fan_startv(&client->dev, pdata->fan_startv);
+	if (ret)
+		return ret;
+
+	return g76x_set_clk_freq(&client->dev, pdata->clk_freq);
+}
+
+
+/* driver-specific control functions */
+
+/* Get fan failure flag state. 0 (no fault) or 1 (fan failure) */
+static int g76x_get_failure_state(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", !!(data->fan_sta & G76x_REG_FAN_STA_FAIL));
+}
+
+/* Get fan out of control flag state. 0 (fan ooc) or 1 (fan under control) */
+static int g76x_get_ooc_state(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	return sprintf(buf, "%d\n", !!(data->fan_sta & G76x_REG_FAN_STA_OOC));
+}
+
+/*
+ * Get and Set fan speed value. Can be called both in closed and open-loop mode
+ * but effect will only be seen after closed-loop mode is configured.
+ * 
+ * Accepts values between
+ * 0 (stops the fan) and 255 (full speed) for open-loop
+ * 0 (stops the fan) and 254 (full speed) for closed-loop
+ * 255 in closed-loop mode will disarm the fan
+ */
+static int g76x_get_fan_speed(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	int ret;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	switch (data->fan_cmd1 & G76x_REG_FAN_CMD1_CTRL_MODE) {
+	case G76x_FAN_MODE_CLOSED_LOOP:
+		ret = sprintf(buf, "%d\n", data->act_cnt);
+		break;
+	default:
+		ret = sprintf(buf, "%d\n", data->set_out);
+		break;
+	}
+
+	return ret;
+}
+
+static int g76x_set_fan_speed(struct device *dev, unsigned long val)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	int ret;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	val = clamp_val(val, 0, 255);
+
+	mutex_lock(&data->update_lock);
+	switch (data->fan_cmd1 & G76x_REG_FAN_CMD1_CTRL_MODE) {
+	case G76x_FAN_MODE_CLOSED_LOOP:
+		data->set_cnt = val;
+		ret = i2c_smbus_write_byte_data(data->client, G76x_REG_SET_CNT, val);
+		break;
+	default:
+		data->set_out = val;
+		ret = i2c_smbus_write_byte_data(data->client, G76x_REG_SET_OUT, val);
+		break;
+	}
+	data->valid = false;
+	mutex_unlock(&data->update_lock);
+
+	return ret;
+}
+
+/*
+ * Get/set the fan speed as a RPM value;
+ * in closed-loop mode the chip will regulate the fan speed using
+ * pulses from fan tachometer.
+ *
+ * in open-loop mode fan speed feedback is not available so it will
+ * estimate rpm from open-loop input speed.
+ * 
+ * Also note that due to rounding errors it is possible that you don't read
+ * back exactly the value you have set.
+ */
+ static int g76x_get_fan_rpm(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	unsigned int rpm;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	mutex_lock(&data->update_lock);
+	switch (data->fan_cmd1 & G76x_REG_FAN_CMD1_CTRL_MODE) {
+	case G76x_FAN_MODE_CLOSED_LOOP:
+		if (data->set_cnt == 0xff) /* fan disarmed */
+			rpm = 0;
+		else
+			rpm = g76x_rpm_from_cnt(data->act_cnt, data->clk_freq,
+									G76x_PULSE_FROM_REG(data->fan_cmd1),
+									G76x_CLKDIV_FROM_REG(data->fan_cmd1),
+									G76x_GEARMULT_FROM_REG(data->fan_cmd2));
+		break;
+	default:
+		/* estimate rpm from input speed value as a percentage of common max RPM */
+		rpm = (data->set_out * 3000) / 255;
+		break;
+	}
+	mutex_unlock(&data->update_lock);
+
+	return sprintf(buf, "%u\n", rpm);
+}
+
+static int g76x_set_fan_rpm(struct device *dev, unsigned long rpm)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	unsigned int speed;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	speed = g76x_cnt_from_rpm(rpm, data->clk_freq,
+							G76x_PULSE_FROM_REG(data->fan_cmd1),
+							G76x_CLKDIV_FROM_REG(data->fan_cmd1),
+							G76x_GEARMULT_FROM_REG(data->fan_cmd2));
+
+	return g76x_set_fan_speed(dev, speed);
+}
+
+/* Get/set the fan speed as a percentage of max speed */
+static int g76x_get_fan_level(struct device *dev, char *buf)
+{
+	struct g76x_data *data = g76x_update_client(dev);
+	unsigned int level;
+
+	if (IS_ERR(data))
+		return PTR_ERR(data);
+
+	mutex_lock(&data->update_lock);
+
+	switch (data->fan_cmd1 & G76x_REG_FAN_CMD1_CTRL_MODE) {
+	case G76x_FAN_MODE_CLOSED_LOOP:
+		if (data->set_cnt == 0xff) /* fan disarmed */
+			level = 0;
+		else
+			level = g76x_level_from_cnt(data->act_cnt);
+		break;
+	default:
+		/* estimate level from input speed value */
+		level = g76x_level_from_cnt(data->set_out);
+		break;
+	}
+	mutex_unlock(&data->update_lock);
+
+	return sprintf(buf, "%d\n", level);
+}
+
+static int g76x_set_fan_level(struct device *dev, unsigned long level)
+{
+	level = clamp_val(level, 0, 100);
+
+	return g76x_set_fan_speed(dev, g76x_cnt_from_level(level));
+}
+
+/* Setup parameters to a default (and safe) known state and arm the fan */
+static int g76x_fan_init(struct device *dev)
+{
+	/*
+	 * g76x PowerOn/Reset state:
+	 * set_cnt  = 0xff	(fan disarmed)
+	 * act_cnt  = 0xff
+	 * fan_sta  = 0x01	(no fault, no ooc)
+	 * set_out  = 0x0	(open-loop speed set to 0)
+	 * fan_cmd1 = 0x10	(2 ppr, positive duty, clk div 1,
+	 *				  closed-loop, ADC mode, ooc detection disabled,
+	 * 					failure detection disabled)
+	 * fan_cmd2 = 0x01	(fan startv 1, gear mode x1, alert# unmasked)
+	 */
+	int ret;
+	/* default clock frequency */
+	ret = g76x_set_clk_freq(dev, 32768);
+	if (ret < 0) goto err_init;
+
+	/* enable ooc detection */
+	ret = g76x_set_ooc_detection(dev, 1);
+	if (ret < 0) goto err_init;
+
+	/* enable failure detection */
+	ret = g76x_set_failure_detection(dev, 1);
+	if (ret < 0) goto err_init;
+
+	/* set speed to 0 and arm the fan */
+	ret = g76x_set_fan_speed(dev, 0);
+	if (ret < 0) goto err_init;
+
+	return 0;
+
+err_init:
+	return -EIO;
+}
+
+
+/*
+ * Generic fan driver layer
+ */
+
+static struct fan_ops g76x_fan_ops = {
+	.get_fan_startv			=	g76x_get_fan_startv,
+	.set_fan_startv			=	g76x_set_fan_startv,
+	.get_gear_multiplier	=	g76x_get_gear_multiplier,
+	.set_gear_multiplier	=	g76x_set_gear_multiplier,
+	.get_fan_ppr			=	g76x_get_fan_ppr,
+	.set_fan_ppr			=	g76x_set_fan_ppr,
+	.get_pwm_polarity		=	g76x_get_pwm_polarity,
+	.set_pwm_polarity		=	g76x_set_pwm_polarity,
+	.get_clk_freq			=	g76x_get_clk_freq,
+	.set_clk_freq			=	g76x_set_clk_freq,
+	.get_clk_div			=	g76x_get_clk_div,
+	.set_clk_div			=	g76x_set_clk_div,
+	.get_control_mode		=	g76x_get_control_mode,
+	.set_control_mode		=	g76x_set_control_mode,
+	.get_output_mode		=	g76x_get_output_mode,
+	.set_output_mode		=	g76x_set_output_mode,
+	.get_ooc_detection		=	g76x_get_ooc_detection,
+	.set_ooc_detection		=	g76x_set_ooc_detection,
+	.get_failure_detection	=	g76x_get_failure_detection,
+	.set_failure_detection	=	g76x_set_failure_detection,
+	.get_failure_state		=	g76x_get_failure_state,
+	.get_ooc_state			=	g76x_get_ooc_state,
+	.get_fan_speed			=	g76x_get_fan_speed,
+	.set_fan_speed			=	g76x_set_fan_speed,
+	.get_fan_rpm			=	g76x_get_fan_rpm,
+	.set_fan_rpm			=	g76x_set_fan_rpm,
+	.get_fan_level			=	g76x_get_fan_level,
+	.set_fan_level			=	g76x_set_fan_level,
+	.fan_init				=	g76x_fan_init,
+};
+
+static int g76x_fan_probe(struct device *dev)
+{
+	struct i2c_client *client = to_i2c_client(dev);
+	struct g76x_data *data;
+	int ret;
+
+	/* make sure that chip is present by reading a register */
+	ret = i2c_smbus_read_byte_data(client, G76x_REG_FAN_CMD1);
+	if (ret < 0) {
+		ret = -ENODEV;
+		goto err_ret;
+	}
+
+	/* allocate and initialize driver data structure */
+	data = xzalloc(sizeof(*data));
+	if (!data) {
+		ret = -ENOMEM;
+		goto err_ret;
+	}
+
+	/* pass specific driver data to i2c device */
+	dev->priv = data;
+	i2c_set_clientdata(client, data);
+	data->client = client;
+	mutex_init(&data->update_lock);
+
+	/* Get configuration via DT ... */
+	ret = g76x_of_clock_enable(client);
+	if (ret)
+		goto err_alloc;
+
+	ret = g76x_of_prop_import(client);
+	if (ret)
+		goto err_clk;
+
+	/* ... or platform_data */
+	ret = g76x_pdata_prop_import(client);
+	if (ret)
+		goto err_clk;
+
+	ret = fan_device_register(&client->dev, &g76x_fan_ops);
+	if (ret)
+		goto err_clk;
+
+	return 0;
+
+err_clk:
+	g76x_of_clock_disable(client);
+err_alloc:
+	free(data);
+err_ret:
+	return ret;
+}
+
+static void g76x_fan_remove(struct device *dev)
+{
+	struct i2c_client *client = to_i2c_client(dev);
+	struct g76x_data *data = i2c_get_clientdata(client);
+
+	fan_device_unregister(&client->dev);
+	g76x_of_clock_disable(client);
+	free(data);
+}
+
+static struct driver g76x_driver = {
+	.name = "g76x",
+	.probe	  = g76x_fan_probe,
+	.remove	  = g76x_fan_remove,
+	.id_table = g76x_id,
+	.of_match_table = of_match_ptr(g76x_dt_match),
+};
+
+device_i2c_driver(g76x_driver);
diff --git a/drivers/fan/other_fan_controllers/Kconfig b/drivers/fan/other_fan_controllers/Kconfig
new file mode 100644
index 0000000000..44836c38ac
--- /dev/null
+++ b/drivers/fan/other_fan_controllers/Kconfig
@@ -0,0 +1,7 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+config GPIO_PWM_FAN
+	bool "Generic GPIO PWM controlled fan driver"
+	depends on PWM
+	help
+	(placeholder, not impemented) Support fan speed control trough GPIO PWM signal
diff --git a/drivers/fan/other_fan_controllers/Makefile b/drivers/fan/other_fan_controllers/Makefile
new file mode 100644
index 0000000000..43ea3ab5b3
--- /dev/null
+++ b/drivers/fan/other_fan_controllers/Makefile
@@ -0,0 +1,3 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+# fan controller interface types
diff --git a/drivers/fan/spi_fan_controllers/Kconfig b/drivers/fan/spi_fan_controllers/Kconfig
new file mode 100644
index 0000000000..a4e40e534e
--- /dev/null
+++ b/drivers/fan/spi_fan_controllers/Kconfig
@@ -0,0 +1 @@
+# SPDX-License-Identifier: GPL-2.0-only
diff --git a/drivers/fan/spi_fan_controllers/Makefile b/drivers/fan/spi_fan_controllers/Makefile
new file mode 100644
index 0000000000..43ea3ab5b3
--- /dev/null
+++ b/drivers/fan/spi_fan_controllers/Makefile
@@ -0,0 +1,3 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+# fan controller interface types
diff --git a/include/fan/fan.h b/include/fan/fan.h
new file mode 100644
index 0000000000..ae5c23b71d
--- /dev/null
+++ b/include/fan/fan.h
@@ -0,0 +1,94 @@
+#ifndef __FAN_H__
+#define __FAN_H__
+
+#include <common.h>
+#include <device.h>
+#include <driver.h>
+#include <linux/list.h>
+#include <linux/types.h>
+#include <fs.h>
+#include <malloc.h>
+#include <xfuncs.h>
+#include <globalvar.h>
+#include <errno.h>
+
+
+/* Generic fan driver fan device management */
+
+struct fan_device {			 	/*!< generic fan driver device */
+	struct list_head list;	  	/*!< link in generic fan driver devices list */
+	struct device *dev;		 	/*!< specific fan controller driver device */
+	const struct fan_ops *ops;	/*!< specific fan controller driver operations */
+	struct cdev *cdev;		  	/*!< generic filesystem fan device */
+};
+
+struct fan_ops {
+	int (*get_fan_startv)(struct device *dev, char *buf);
+	int (*set_fan_startv)(struct device *dev, unsigned long val);
+
+	int (*get_gear_multiplier)(struct device *dev, char *buf);
+	int (*set_gear_multiplier)(struct device *dev, unsigned long val);
+
+	int (*get_fan_ppr)(struct device *dev, char *buf);
+	int (*set_fan_ppr)(struct device *dev, unsigned long val);
+
+	int (*get_pwm_polarity)(struct device *dev, char *buf);
+	int (*set_pwm_polarity)(struct device *dev, unsigned long val);
+
+	int (*get_clk_freq)(struct device *dev, char *buf);
+	int (*set_clk_freq)(struct device *dev, unsigned long val);
+
+	int (*get_clk_div)(struct device *dev, char *buf);
+	int (*set_clk_div)(struct device *dev, unsigned long val);
+
+	int (*get_control_mode)(struct device *dev, char *buf);
+	int (*set_control_mode)(struct device *dev, unsigned long val);
+
+	int (*get_output_mode)(struct device *dev, char *buf);
+	int (*set_output_mode)(struct device *dev, unsigned long val);
+
+	int (*get_ooc_detection)(struct device *dev, char *buf);
+	int (*set_ooc_detection)(struct device *dev, unsigned long val);
+
+	int (*get_failure_detection)(struct device *dev, char *buf);
+	int (*set_failure_detection)(struct device *dev, unsigned long val);
+
+	int (*get_failure_state)(struct device *dev, char *buf);
+	int (*get_ooc_state)(struct device *dev, char *buf);
+
+	int (*get_fan_speed)(struct device *dev, char *buf);
+	int (*set_fan_speed)(struct device *dev, unsigned long val);
+
+	int (*get_fan_rpm)(struct device *dev, char *buf);
+	int (*set_fan_rpm)(struct device *dev, unsigned long val);
+
+	int (*get_fan_level)(struct device *dev, char *buf);
+	int (*set_fan_level)(struct device *dev, unsigned long val);
+
+	int (*fan_init)(struct device *dev);
+};
+/*
+static void fan_set_dev(struct fan_device *fan, struct device *dev);
+static struct device *fan_get_dev(struct fan_device *fan);
+
+static void fan_set_ops(struct fan_device *fan, struct fan_ops *ops);
+static const struct fan_ops *fan_get_ops(struct fan_device *fan);
+*/
+
+/* Generic filesystem fan device management */
+/*
+static void cdev_set_fan(struct fan_device *fan);
+static struct fan_device *cdev_get_fan(struct cdev *cdev);
+
+static void cdev_set_name(struct cdev *cdev);
+static char *cdev_get_name(struct cdev *cdev);
+*/
+struct fan_device *fan_device_find(const char *devmatch);
+
+
+/* specific fan controller driver device management */
+
+int fan_device_register(struct device *dev, struct fan_ops *ops);
+void fan_device_unregister(struct device *dev);
+
+#endif /* __FAN_H__ */
\ No newline at end of file
diff --git a/include/fan/i2c_fan_controllers/g76x.h b/include/fan/i2c_fan_controllers/g76x.h
new file mode 100644
index 0000000000..e9075a1b5c
--- /dev/null
+++ b/include/fan/i2c_fan_controllers/g76x.h
@@ -0,0 +1,37 @@
+/*
+ * Platform data structure for g762 fan controller driver
+ *
+ * Copyright (C) 2013, Arnaud EBALARD <arno@natisbad.org>
+ *
+ * This program is free software; you can redistribute it and/or modify
+ * it under the terms of the GNU General Public License as published by
+ * the Free Software Foundation; either version 2 of the License, or
+ * (at your option) any later version.
+ *
+ * This program is distributed in the hope that it will be useful,
+ * but WITHOUT ANY WARRANTY; without even the implied warranty of
+ * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
+ * GNU General Public License for more details.
+ *
+ * You should have received a copy of the GNU General Public License
+ * along with this program; if not, write to the Free Software
+ * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
+ */
+#ifndef __LINUX_PLATFORM_DATA_G762_H__
+#define __LINUX_PLATFORM_DATA_G762_H__
+
+/*
+ * Following structure can be used to set g762 driver platform specific data
+ * during board init. Note that passing a sparse structure is possible but
+ * will result in non-specified attributes to be set to default value, hence
+ * overloading those installed during boot (e.g. by u-boot).
+ */
+
+struct g76x_platform_data {
+	unsigned int fan_startv;
+	unsigned int fan_gear_mode;
+	unsigned int pwm_polarity;
+	unsigned int clk_freq;
+};
+
+#endif /* __LINUX_PLATFORM_DATA_G762_H__ */

-- 
2.47.3

