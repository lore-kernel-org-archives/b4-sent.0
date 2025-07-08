From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Tue, 08 Jul 2025 18:13:03 +0200
Subject: [PATCH v4 1/2] pwm: mc33xs2410: add hwmon support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250708-mc33xs2410-hwmon-v4-1-95b9e3ea5f5c@liebherr.com>
References: <20250708-mc33xs2410-hwmon-v4-0-95b9e3ea5f5c@liebherr.com>
In-Reply-To: <20250708-mc33xs2410-hwmon-v4-0-95b9e3ea5f5c@liebherr.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751991187; l=4821;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=qUeIPQxAnEuF2jKIbHlawUN2Esf14Kuip2Av+HM28AE=;
 b=MAE1xJLv80KoXUG0E3hmAt8xy2tNB7u4QUT1fh5ElufY3ZbJ0ksAiVxSxMnxNeiaTKkYgKODy
 6GgbmAJynfyBH86NEJWcYU+lsv2tsDsytyjasY6LoUh1xXuC9H3GX3q
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support for hwmon is provided by a separate driver residing in hwmon
subsystem which is implemented as auxiliary device. Add handling of this
device.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/pwm/Kconfig          |  1 +
 drivers/pwm/pwm-mc33xs2410.c | 64 ++++++++++++++++++++++++++++++++++++++++++--
 include/linux/mc33xs2410.h   | 14 ++++++++++
 3 files changed, 77 insertions(+), 2 deletions(-)

diff --git a/drivers/pwm/Kconfig b/drivers/pwm/Kconfig
index 6e113f8b4baf293284f017bc22fbc162633bb2fc..5b20230c5ccd99137efcd968efe603b8c8e2253f 100644
--- a/drivers/pwm/Kconfig
+++ b/drivers/pwm/Kconfig
@@ -427,6 +427,7 @@ config PWM_MC33XS2410
 	tristate "MC33XS2410 PWM support"
 	depends on OF
 	depends on SPI
+	select AUXILIARY_BUS
 	help
 	  NXP MC33XS2410 high-side switch driver. The MC33XS2410 is a four
 	  channel high-side switch. The device is operational from 3.0 V
diff --git a/drivers/pwm/pwm-mc33xs2410.c b/drivers/pwm/pwm-mc33xs2410.c
index a1ac3445ccdb4709d92e0075d424a8abc1416eee..e70ed90bfdac77f5c777f0ba66d670331a515d12 100644
--- a/drivers/pwm/pwm-mc33xs2410.c
+++ b/drivers/pwm/pwm-mc33xs2410.c
@@ -18,10 +18,12 @@
  *   rather something in between.
  */
 
+#include <linux/auxiliary_bus.h>
 #include <linux/bitfield.h>
 #include <linux/delay.h>
 #include <linux/err.h>
 #include <linux/math64.h>
+#include <linux/mc33xs2410.h>
 #include <linux/minmax.h>
 #include <linux/module.h>
 #include <linux/of.h>
@@ -120,12 +122,19 @@ static int mc33xs2410_read_reg(struct spi_device *spi, u8 reg, u16 *val, u8 flag
 	return mc33xs2410_read_regs(spi, &reg, flag, val, 1);
 }
 
-static int mc33xs2410_read_reg_ctrl(struct spi_device *spi, u8 reg, u16 *val)
+int mc33xs2410_read_reg_ctrl(struct spi_device *spi, u8 reg, u16 *val)
 {
 	return mc33xs2410_read_reg(spi, reg, val, MC33XS2410_FRAME_IN_DATA_RD);
 }
+EXPORT_SYMBOL_NS_GPL(mc33xs2410_read_reg_ctrl, "PWM_MC33XS2410");
 
-static int mc33xs2410_modify_reg(struct spi_device *spi, u8 reg, u8 mask, u8 val)
+int mc33xs2410_read_reg_diag(struct spi_device *spi, u8 reg, u16 *val)
+{
+	return mc33xs2410_read_reg(spi, reg, val, 0);
+}
+EXPORT_SYMBOL_NS_GPL(mc33xs2410_read_reg_diag, "PWM_MC33XS2410");
+
+int mc33xs2410_modify_reg(struct spi_device *spi, u8 reg, u8 mask, u8 val)
 {
 	u16 tmp;
 	int ret;
@@ -139,6 +148,7 @@ static int mc33xs2410_modify_reg(struct spi_device *spi, u8 reg, u8 mask, u8 val
 
 	return mc33xs2410_write_reg(spi, reg, tmp);
 }
+EXPORT_SYMBOL_NS_GPL(mc33xs2410_modify_reg, "PWM_MC33XS2410");
 
 static u8 mc33xs2410_pwm_get_freq(u64 period)
 {
@@ -297,6 +307,52 @@ static const struct pwm_ops mc33xs2410_pwm_ops = {
 	.get_state = mc33xs2410_pwm_get_state,
 };
 
+static void mc33xs2410_adev_release(struct device *dev)
+{
+	struct auxiliary_device *adev = to_auxiliary_dev(dev);
+
+	kfree(adev);
+}
+
+static void mc33xs2410_unregister_adev(void *_adev)
+{
+	struct auxiliary_device *adev = _adev;
+
+	auxiliary_device_delete(adev);
+	auxiliary_device_uninit(adev);
+}
+
+static int mc33xs2410_hwmon_register(struct device *dev)
+{
+	struct auxiliary_device *adev;
+	int ret;
+
+	adev = kzalloc(sizeof(*adev), GFP_KERNEL);
+	if (!adev)
+		return -ENOMEM;
+
+	adev->name = "hwmon";
+	adev->dev.parent = dev;
+	adev->dev.release = mc33xs2410_adev_release;
+	adev->id = 0;
+
+	ret = auxiliary_device_init(adev);
+	if (ret)
+		return ret;
+
+	ret = auxiliary_device_add(adev);
+	if (ret) {
+		auxiliary_device_uninit(adev);
+		return ret;
+	}
+
+	ret = devm_add_action_or_reset(dev, mc33xs2410_unregister_adev, adev);
+	if (ret)
+		return ret;
+
+	return 0;
+}
+
 static int mc33xs2410_reset(struct device *dev)
 {
 	struct gpio_desc *reset_gpio;
@@ -361,6 +417,10 @@ static int mc33xs2410_probe(struct spi_device *spi)
 	if (ret < 0)
 		return dev_err_probe(dev, ret, "Failed to add pwm chip\n");
 
+	ret = mc33xs2410_hwmon_register(dev);
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "Failed to register hwmon device\n");
+
 	return 0;
 }
 
diff --git a/include/linux/mc33xs2410.h b/include/linux/mc33xs2410.h
new file mode 100644
index 0000000000000000000000000000000000000000..15a0b0b595fe00a369cee45f2d30b2d912b612bb
--- /dev/null
+++ b/include/linux/mc33xs2410.h
@@ -0,0 +1,14 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (C) 2024 Liebherr-Electronics and Drives GmbH
+ */
+#ifndef _MC33XS2410_H
+#define _MC33XS2410_H
+
+#include <linux/spi/spi.h>
+
+int mc33xs2410_read_reg_ctrl(struct spi_device *spi, u8 reg, u16 *val);
+int mc33xs2410_read_reg_diag(struct spi_device *spi, u8 reg, u16 *val);
+int mc33xs2410_modify_reg(struct spi_device *spi, u8 reg, u8 mask, u8 val);
+
+#endif /* _MC33XS2410_H */

-- 
2.39.5

