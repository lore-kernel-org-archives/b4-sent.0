From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Thu, 15 May 2025 14:40:54 +0200
Subject: [PATCH v2] pwm: mc33xs2410: add support for temperature sensors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250515-mc33xs2410-hwmon-v2-1-8d2e78f7e30d@liebherr.com>
X-B4-Tracking: v=1; b=H4sIANXgJWgC/2WNwQ7CIBAFf6XZsxigEqwn/8P0QGGRTaQ0YGpN0
 38XG28eZ5I3b4WCmbDApVkh40yF0lhBHhqwwYx3ZOQqg+RSccU1i7ZtlyJPgrPwimlkRnnfoUf
 LuYI6mzJ6Wvbkra8cqDxTfu8Ps/jaX0zI/9gsmGDGucFobfXZd9cH4RAw56NNEfpt2z52aYhYs
 wAAAA==
X-Change-ID: 20250507-mc33xs2410-hwmon-a5ff9efec005
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747312859; l=7130;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=gA7zDwXiWTd8xg0+Xj9LCJz286VbanRc/qAT/ceC6j8=;
 b=jpXZejTJ7h9giZQBIT2GK8g/rUbED3gfWmU7XG48Ly0erh7RzibKfhlbRLKw1csn1ye4BSLC9
 5kMAxJ1Y/wKCgULVNY/Ym/7uwgbNEqd2nXpCzFXWiqcuhwrVeEJPh17
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MC33XS2410 provides temperature sensors for the central die temperature
and the four outputs. Additionally a common temperature warning threshold
can be configured for the outputs. Add hwmon support for the sensors.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v2:
- Remove helper mc33xs2410_hwmon_read_out_status and report the last
  latched status.
- Link to v1: https://lore.kernel.org/r/20250512-mc33xs2410-hwmon-v1-1-addba77c78f9@liebherr.com
---
 drivers/pwm/Kconfig          |   1 +
 drivers/pwm/pwm-mc33xs2410.c | 164 ++++++++++++++++++++++++++++++++++++++++++-
 2 files changed, 164 insertions(+), 1 deletion(-)

diff --git a/drivers/pwm/Kconfig b/drivers/pwm/Kconfig
index 6faa8b2ec0a4844f667a84335f30bde44d52378e..0deaf8447f4302e7cfd3b4cb35c7d46ef19e006c 100644
--- a/drivers/pwm/Kconfig
+++ b/drivers/pwm/Kconfig
@@ -425,6 +425,7 @@ config PWM_LPSS_PLATFORM
 
 config PWM_MC33XS2410
 	tristate "MC33XS2410 PWM support"
+	depends on HWMON || HWMON=n
 	depends on OF
 	depends on SPI
 	help
diff --git a/drivers/pwm/pwm-mc33xs2410.c b/drivers/pwm/pwm-mc33xs2410.c
index a1ac3445ccdb4709d92e0075d424a8abc1416eee..c1b99b1143141242ce99782162ae05536dd88163 100644
--- a/drivers/pwm/pwm-mc33xs2410.c
+++ b/drivers/pwm/pwm-mc33xs2410.c
@@ -21,6 +21,7 @@
 #include <linux/bitfield.h>
 #include <linux/delay.h>
 #include <linux/err.h>
+#include <linux/hwmon.h>
 #include <linux/math64.h>
 #include <linux/minmax.h>
 #include <linux/module.h>
@@ -29,6 +30,8 @@
 
 #include <linux/spi/spi.h>
 
+/* ctrl registers */
+
 #define MC33XS2410_GLB_CTRL			0x00
 #define MC33XS2410_GLB_CTRL_MODE		GENMASK(7, 6)
 #define MC33XS2410_GLB_CTRL_MODE_NORMAL		FIELD_PREP(MC33XS2410_GLB_CTRL_MODE, 1)
@@ -51,6 +54,21 @@
 
 #define MC33XS2410_WDT				0x14
 
+#define MC33XS2410_TEMP_WT			0x29
+#define MC33XS2410_TEMP_WT_MASK			GENMASK(7, 0)
+
+/* diag registers */
+
+/* chan in { 1 ... 4 } */
+#define MC33XS2410_OUT_STA(chan)		(0x02 + (chan) - 1)
+#define MC33XS2410_OUT_STA_OTW			BIT(8)
+
+#define MC33XS2410_TS_TEMP_DIE			0x26
+#define MC33XS2410_TS_TEMP_MASK			GENMASK(9, 0)
+
+/* chan in { 1 ... 4 } */
+#define MC33XS2410_TS_TEMP(chan)		(0x2f + (chan) - 1)
+
 #define MC33XS2410_PWM_MIN_PERIOD		488282
 /* step in { 0 ... 3 } */
 #define MC33XS2410_PWM_MAX_PERIOD(step)		(2000000000 >> (2 * (step)))
@@ -125,6 +143,11 @@ static int mc33xs2410_read_reg_ctrl(struct spi_device *spi, u8 reg, u16 *val)
 	return mc33xs2410_read_reg(spi, reg, val, MC33XS2410_FRAME_IN_DATA_RD);
 }
 
+static int mc33xs2410_read_reg_diag(struct spi_device *spi, u8 reg, u16 *val)
+{
+	return mc33xs2410_read_reg(spi, reg, val, 0);
+}
+
 static int mc33xs2410_modify_reg(struct spi_device *spi, u8 reg, u8 mask, u8 val)
 {
 	u16 tmp;
@@ -140,6 +163,145 @@ static int mc33xs2410_modify_reg(struct spi_device *spi, u8 reg, u8 mask, u8 val
 	return mc33xs2410_write_reg(spi, reg, tmp);
 }
 
+#if IS_ENABLED(CONFIG_HWMON)
+static const struct hwmon_channel_info * const mc33xs2410_hwmon_info[] = {
+	HWMON_CHANNEL_INFO(temp,
+			   HWMON_T_LABEL | HWMON_T_INPUT,
+			   HWMON_T_LABEL | HWMON_T_INPUT | HWMON_T_MAX |
+			   HWMON_T_ALARM,
+			   HWMON_T_LABEL | HWMON_T_INPUT | HWMON_T_MAX |
+			   HWMON_T_ALARM,
+			   HWMON_T_LABEL | HWMON_T_INPUT | HWMON_T_MAX |
+			   HWMON_T_ALARM,
+			   HWMON_T_LABEL | HWMON_T_INPUT | HWMON_T_MAX |
+			   HWMON_T_ALARM),
+	NULL,
+};
+
+static umode_t mc33xs2410_hwmon_is_visible(const void *data,
+					   enum hwmon_sensor_types type,
+					   u32 attr, int channel)
+{
+	switch (attr) {
+	case hwmon_temp_input:
+	case hwmon_temp_alarm:
+	case hwmon_temp_label:
+		return 0444;
+	case hwmon_temp_max:
+		return 0644;
+	default:
+		return 0;
+	}
+}
+
+static int mc33xs2410_hwmon_read(struct device *dev,
+				 enum hwmon_sensor_types type,
+				 u32 attr, int channel, long *val)
+{
+	struct spi_device *spi = dev_get_drvdata(dev);
+	u16 reg_val;
+	int ret;
+	u8 reg;
+
+	switch (attr) {
+	case hwmon_temp_input:
+		reg = (channel == 0) ? MC33XS2410_TS_TEMP_DIE :
+				       MC33XS2410_TS_TEMP(channel);
+		ret = mc33xs2410_read_reg_diag(spi, reg, &reg_val);
+		if (ret < 0)
+			return ret;
+
+		/* LSB is 0.25 degree celsius */
+		*val = FIELD_GET(MC33XS2410_TS_TEMP_MASK, reg_val) * 250 - 40000;
+		return 0;
+	case hwmon_temp_alarm:
+		ret = mc33xs2410_read_reg_diag(spi, MC33XS2410_OUT_STA(channel),
+					       &reg_val);
+		if (ret < 0)
+			return ret;
+
+		*val = FIELD_GET(MC33XS2410_OUT_STA_OTW, reg_val);
+		return 0;
+	case hwmon_temp_max:
+		ret = mc33xs2410_read_reg_ctrl(spi, MC33XS2410_TEMP_WT, &reg_val);
+		if (ret < 0)
+			return ret;
+
+		/* LSB is 1 degree celsius */
+		*val = FIELD_GET(MC33XS2410_TEMP_WT_MASK, reg_val) * 1000 - 40000;
+		return 0;
+	default:
+		return -EOPNOTSUPP;
+	}
+}
+
+static int mc33xs2410_hwmon_write(struct device *dev,
+				  enum hwmon_sensor_types type, u32 attr,
+				  int channel, long val)
+{
+	struct spi_device *spi = dev_get_drvdata(dev);
+
+	switch (attr) {
+	case hwmon_temp_max:
+		val = clamp_val(val, -40000, 215000);
+
+		/* LSB is 1 degree celsius */
+		val = (val / 1000) + 40;
+		return mc33xs2410_modify_reg(spi, MC33XS2410_TEMP_WT,
+					     MC33XS2410_TEMP_WT_MASK, val);
+	default:
+		return -EOPNOTSUPP;
+	}
+}
+
+static const char *const mc33xs2410_temp_label[] = {
+	"Central die temperature",
+	"Channel 1 temperature",
+	"Channel 2 temperature",
+	"Channel 3 temperature",
+	"Channel 4 temperature",
+};
+
+static int mc33xs2410_read_string(struct device *dev,
+				  enum hwmon_sensor_types type,
+				  u32 attr, int channel, const char **str)
+{
+	*str = mc33xs2410_temp_label[channel];
+
+	return 0;
+}
+
+static const struct hwmon_ops mc33xs2410_hwmon_hwmon_ops = {
+	.is_visible = mc33xs2410_hwmon_is_visible,
+	.read = mc33xs2410_hwmon_read,
+	.read_string = mc33xs2410_read_string,
+	.write = mc33xs2410_hwmon_write,
+};
+
+static const struct hwmon_chip_info mc33xs2410_hwmon_chip_info = {
+	.ops = &mc33xs2410_hwmon_hwmon_ops,
+	.info = mc33xs2410_hwmon_info,
+};
+
+static int mc33xs2410_hwmon_probe(struct spi_device *spi)
+{
+	struct device *dev = &spi->dev;
+	struct device *hwmon;
+
+	hwmon = devm_hwmon_device_register_with_info(dev, NULL, spi,
+						     &mc33xs2410_hwmon_chip_info,
+						     NULL);
+
+	return PTR_ERR_OR_ZERO(hwmon);
+}
+
+#else
+static int mc33xs2410_hwmon_probe(struct spi_device *spi)
+{
+	return 0;
+}
+#endif
+
 static u8 mc33xs2410_pwm_get_freq(u64 period)
 {
 	u8 step, count;
@@ -361,7 +523,7 @@ static int mc33xs2410_probe(struct spi_device *spi)
 	if (ret < 0)
 		return dev_err_probe(dev, ret, "Failed to add pwm chip\n");
 
-	return 0;
+	return mc33xs2410_hwmon_probe(spi);
 }
 
 static const struct spi_device_id mc33xs2410_spi_id[] = {

---
base-commit: 7395eb13e3a85067de3e083d3781630ea303c0c4
change-id: 20250507-mc33xs2410-hwmon-a5ff9efec005

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

