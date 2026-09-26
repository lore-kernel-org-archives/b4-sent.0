From: Alexei Solcanu <alexei.solcanu@pm.me>
Date: Sat, 26 Sep 2026 16:11:21 -0400
Subject: [PATCH v2 2/2] hwmon: (gpd-fan) Register both fans on the GPD Win
 5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-gpd-fan-duo-auto-v2-2-0a2ea41ee3b5@pm.me>
References: <20260926-gpd-fan-duo-auto-v2-0-0a2ea41ee3b5@pm.me>
In-Reply-To: <20260926-gpd-fan-duo-auto-v2-0-0a2ea41ee3b5@pm.me>
To: Guenter Roeck <linux@roeck-us.net>, 
 Cryolitia PukNgae <cryolitia@uniontech.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, Antheas Kapenekakis <lkml@antheas.dev>, 
 Alexei Solcanu <alexei.solcanu@pm.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790453516; l=14211;
 i=alexei.solcanu@pm.me; s=20260925; h=from:subject:message-id;
 bh=MrFpUbF13O41mLbsfNDEJnDo2n8txXqAySWA4z3dd98=;
 b=pTkexDRnGwFsCZWHoRkKq+t1VK3C/Jli6ZXqNz6iuGBl/DuZykPgN+gnvT3A5fVEX6Innial1
 KDzXoMVjVnABNKMcACaGytsTQh2iAAdnkRkygeCmwZ+ix9QIINAD334
X-Developer-Key: i=alexei.solcanu@pm.me; a=ed25519;
 pk=iK6ervbccknflfirBb6E4x7TaOyCpnoGd33gzfiNEeo=
X-Endpoint-Received: by B4 Relay for alexei.solcanu@pm.me/20260925 with auth_id=1064
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GPD Win 5 uses gpd_duo_drvdata, which exposes a single fan and pwm
channel: pwm1 writes the same duty cycle to both fans, and fan1_input
only reads the first fan's RPM.

The two fans have independent registers. Fan 1 uses duty cycle 0x047A
and RPM 0x0478/0x0479, fan 2 uses duty cycle 0x047B and RPM
0x0476/0x0477. A duty cycle of 0 returns that fan to EC control.

Add separate board data for the Win 5 and register fan1/pwm1 and
fan2/pwm2, one channel per fan. Boards with a single fan are unchanged.

This changes behaviour on the Win 5: pwm1 and pwm1_enable now control
only the first fan. The second fan stays under EC control unless pwm2
and pwm2_enable are used.

The GPD Duo keeps a single channel, since it is untested and its
second fan's RPM register is unknown.

Tested on a GPD Win 5 (G1618-05).

Suggested-by: Guenter Roeck <linux@roeck-us.net>
Assisted-by: LLM
Signed-off-by: Alexei Solcanu <alexei.solcanu@pm.me>
---
 Documentation/hwmon/gpd-fan.rst |  14 ++--
 drivers/hwmon/gpd-fan.c         | 146 +++++++++++++++++++++++++++-------------
 2 files changed, 107 insertions(+), 53 deletions(-)

diff --git a/Documentation/hwmon/gpd-fan.rst b/Documentation/hwmon/gpd-fan.rst
index b27657d3305..6c8569c5f64 100644
--- a/Documentation/hwmon/gpd-fan.rst
+++ b/Documentation/hwmon/gpd-fan.rst
@@ -28,6 +28,7 @@ Currently the driver supports the following handhelds:
  - GPD Win Max 2 2025 (HX370)
  - GPD Win 4 (6800U)
  - GPD Win 4 (7840U)
+ - GPD Win 5
  - GPD Micro PC 2
 
 Module parameters
@@ -59,23 +60,26 @@ Sysfs entries
 
 The following attributes are supported:
 
-fan1_input
+fan[1-2]_input
   Read Only. Reads current fan RPM.
 
-pwm1_enable
+pwm[1-2]_enable
   Read/Write. Enable manual fan control. Write "0" to disable control and run
   at full speed. Write "1" to set to manual, write "2" to let the EC control
   decide fan speed. Read this attribute to see current status.
 
   NB: In consideration of the safety of the device, when setting to manual mode,
   the pwm speed will be set to the maximum value (255) by default. You can set
-  a different value by writing pwm1 later.
+  a different value by writing pwm[1-2] later.
 
-pwm1
+pwm[1-2]
   Read/Write. Read this attribute to see current duty cycle in the range
-  [0-255]. When pwm1_enable is set to "1" (manual) write any value in the
+  [0-255]. When pwm[1-2]_enable is set to "1" (manual) write any value in the
   range [0-255] to set fan speed.
 
   NB: Many boards (except listed under wm2 above) don't support reading the
   current pwm value in auto mode. That will just return EOPNOTSUPP. In manual
   mode it will always return the real value.
+
+fan2_input, pwm2_enable and pwm2 only exist on devices with two fans
+(GPD Win 5).
diff --git a/drivers/hwmon/gpd-fan.c b/drivers/hwmon/gpd-fan.c
index b3b75f99f58..e03b0dde66f 100644
--- a/drivers/hwmon/gpd-fan.c
+++ b/drivers/hwmon/gpd-fan.c
@@ -31,6 +31,7 @@ enum gpd_board {
 	win4_6800u,
 	win_max_2,
 	duo,
+	win5,
 	mpc2,
 };
 
@@ -40,9 +41,11 @@ enum FAN_PWM_ENABLE {
 	AUTOMATIC	= 2,
 };
 
+#define GPD_MAX_FANS	2
+
 struct gpd_fan_data {
-	enum FAN_PWM_ENABLE pwm_enable;
-	u8 pwm_value;
+	enum FAN_PWM_ENABLE pwm_enable[GPD_MAX_FANS];
+	u8 pwm_value[GPD_MAX_FANS];
 	const struct gpd_fan_drvdata *drvdata;
 };
 
@@ -55,6 +58,8 @@ struct gpd_fan_drvdata {
 	const u16 manual_control_enable;
 	const u16 rpm_read;
 	const u16 pwm_write;
+	const u16 rpm2_read; // Second fan, 0 if there is none
+	const u16 pwm2_write;
 	const u16 pwm_max;
 };
 
@@ -82,6 +87,20 @@ static struct gpd_fan_drvdata gpd_duo_drvdata = {
 	.pwm_max		= 244,
 };
 
+static struct gpd_fan_drvdata gpd_win5_drvdata = {
+	.board_name		= "win5",
+	.board			= win5,
+
+	.addr_port		= 0x4E,
+	.data_port		= 0x4F,
+	.manual_control_enable	= 0x047A,
+	.rpm_read		= 0x0478,
+	.pwm_write		= 0x047A,
+	.rpm2_read		= 0x0476,
+	.pwm2_write		= 0x047B,
+	.pwm_max		= 244,
+};
+
 static struct gpd_fan_drvdata gpd_win4_drvdata = {
 	.board_name		= "win4",
 	.board			= win4_6800u,
@@ -214,7 +233,7 @@ static const struct dmi_system_id dmi_table[] = {
 			DMI_MATCH(DMI_SYS_VENDOR, "GPD"),
 			DMI_MATCH(DMI_PRODUCT_NAME, "G1618-05"),
 		},
-		.driver_data = &gpd_duo_drvdata,
+		.driver_data = &gpd_win5_drvdata,
 	},
 	{
 		// GPD Pocket 4
@@ -290,13 +309,29 @@ static void gpd_ecram_write(const struct gpd_fan_drvdata *drvdata, u16 offset, u
 	outb(value, data_port);
 }
 
-static int gpd_generic_read_rpm(struct gpd_fan_data *data)
+static int gpd_num_fans(const struct gpd_fan_drvdata *drvdata)
+{
+	return drvdata->pwm2_write ? 2 : 1;
+}
+
+static u16 gpd_rpm_reg(const struct gpd_fan_drvdata *drvdata, int channel)
+{
+	return channel ? drvdata->rpm2_read : drvdata->rpm_read;
+}
+
+static u16 gpd_pwm_reg(const struct gpd_fan_drvdata *drvdata, int channel)
+{
+	return channel ? drvdata->pwm2_write : drvdata->pwm_write;
+}
+
+static int gpd_generic_read_rpm(struct gpd_fan_data *data, int channel)
 {
 	const struct gpd_fan_drvdata *drvdata = data->drvdata;
+	u16 reg = gpd_rpm_reg(drvdata, channel);
 	u8 high, low;
 
-	gpd_ecram_read(drvdata, drvdata->rpm_read, &high);
-	gpd_ecram_read(drvdata, drvdata->rpm_read + 1, &low);
+	gpd_ecram_read(drvdata, reg, &high);
+	gpd_ecram_read(drvdata, reg + 1, &low);
 
 	return (u16)high << 8 | low;
 }
@@ -315,18 +350,19 @@ static int gpd_wm2_read_rpm(struct gpd_fan_data *data)
 			gpd_ecram_write(drvdata, pwm_ctr_offset, 0xB8);
 	}
 
-	return gpd_generic_read_rpm(data);
+	return gpd_generic_read_rpm(data, 0);
 }
 
-// Read value for fan1_input
-static int gpd_read_rpm(struct gpd_fan_data *data)
+// Read value for fanN_input
+static int gpd_read_rpm(struct gpd_fan_data *data, int channel)
 {
 	switch (data->drvdata->board) {
 	case win4_6800u:
 	case win_mini:
 	case duo:
+	case win5:
 	case mpc2:
-		return gpd_generic_read_rpm(data);
+		return gpd_generic_read_rpm(data, channel);
 	case win_max_2:
 		return gpd_wm2_read_rpm(data);
 	}
@@ -349,19 +385,20 @@ static int gpd_wm2_read_pwm(struct gpd_fan_data *data)
 	return DIV_ROUND_CLOSEST((var - 1) * 255, (drvdata->pwm_max - 1));
 }
 
-// Read value for pwm1
-static int gpd_read_pwm(struct gpd_fan_data *data)
+// Read value for pwmN
+static int gpd_read_pwm(struct gpd_fan_data *data, int channel)
 {
 	switch (data->drvdata->board) {
 	case win_mini:
 	case duo:
+	case win5:
 	case win4_6800u:
 	case mpc2:
-		switch (data->pwm_enable) {
+		switch (data->pwm_enable[channel]) {
 		case DISABLE:
 			return 255;
 		case MANUAL:
-			return data->pwm_value;
+			return data->pwm_value[channel];
 		case AUTOMATIC:
 			return -EOPNOTSUPP;
 		}
@@ -378,13 +415,13 @@ static inline u8 gpd_cast_pwm_range(const struct gpd_fan_drvdata *drvdata, u8 va
 	return DIV_ROUND_CLOSEST(val * (drvdata->pwm_max - 1), 255) + 1;
 }
 
-static void gpd_generic_write_pwm(struct gpd_fan_data *data, u8 val)
+static void gpd_generic_write_pwm(struct gpd_fan_data *data, int channel, u8 val)
 {
 	const struct gpd_fan_drvdata *drvdata = data->drvdata;
 	u8 pwm_reg;
 
 	pwm_reg = gpd_cast_pwm_range(drvdata, val);
-	gpd_ecram_write(drvdata, drvdata->pwm_write, pwm_reg);
+	gpd_ecram_write(drvdata, gpd_pwm_reg(drvdata, channel), pwm_reg);
 }
 
 static void gpd_duo_write_pwm(struct gpd_fan_data *data, u8 val)
@@ -397,10 +434,10 @@ static void gpd_duo_write_pwm(struct gpd_fan_data *data, u8 val)
 	gpd_ecram_write(drvdata, drvdata->pwm_write + 1, pwm_reg);
 }
 
-// Write value for pwm1
-static int gpd_write_pwm(struct gpd_fan_data *data, u8 val)
+// Write value for pwmN
+static int gpd_write_pwm(struct gpd_fan_data *data, int channel, u8 val)
 {
-	if (data->pwm_enable != MANUAL)
+	if (data->pwm_enable[channel] != MANUAL)
 		return -EPERM;
 
 	switch (data->drvdata->board) {
@@ -410,25 +447,27 @@ static int gpd_write_pwm(struct gpd_fan_data *data, u8 val)
 	case win_mini:
 	case win4_6800u:
 	case win_max_2:
+	case win5:
 	case mpc2:
-		gpd_generic_write_pwm(data, val);
+		gpd_generic_write_pwm(data, channel, val);
 		break;
 	}
 
 	return 0;
 }
 
-static void gpd_win_mini_set_pwm_enable(struct gpd_fan_data *data, enum FAN_PWM_ENABLE pwm_enable)
+static void gpd_win_mini_set_pwm_enable(struct gpd_fan_data *data, int channel,
+					enum FAN_PWM_ENABLE pwm_enable)
 {
 	switch (pwm_enable) {
 	case DISABLE:
-		gpd_generic_write_pwm(data, 255);
+		gpd_generic_write_pwm(data, channel, 255);
 		break;
 	case MANUAL:
-		gpd_generic_write_pwm(data, data->pwm_value);
+		gpd_generic_write_pwm(data, channel, data->pwm_value[channel]);
 		break;
 	case AUTOMATIC:
-		gpd_ecram_write(data->drvdata, data->drvdata->pwm_write, 0);
+		gpd_ecram_write(data->drvdata, gpd_pwm_reg(data->drvdata, channel), 0);
 		break;
 	}
 }
@@ -440,7 +479,7 @@ static void gpd_duo_set_pwm_enable(struct gpd_fan_data *data, enum FAN_PWM_ENABL
 		gpd_duo_write_pwm(data, 255);
 		break;
 	case MANUAL:
-		gpd_duo_write_pwm(data, data->pwm_value);
+		gpd_duo_write_pwm(data, data->pwm_value[0]);
 		break;
 	case AUTOMATIC:
 		gpd_ecram_write(data->drvdata, data->drvdata->pwm_write, 0);
@@ -455,11 +494,11 @@ static void gpd_wm2_set_pwm_enable(struct gpd_fan_data *data, enum FAN_PWM_ENABL
 
 	switch (enable) {
 	case DISABLE:
-		gpd_generic_write_pwm(data, 255);
+		gpd_generic_write_pwm(data, 0, 255);
 		gpd_ecram_write(drvdata, drvdata->manual_control_enable, 1);
 		break;
 	case MANUAL:
-		gpd_generic_write_pwm(data, data->pwm_value);
+		gpd_generic_write_pwm(data, 0, data->pwm_value[0]);
 		gpd_ecram_write(drvdata, drvdata->manual_control_enable, 1);
 		break;
 	case AUTOMATIC:
@@ -468,19 +507,20 @@ static void gpd_wm2_set_pwm_enable(struct gpd_fan_data *data, enum FAN_PWM_ENABL
 	}
 }
 
-// Write value for pwm1_enable
-static void gpd_set_pwm_enable(struct gpd_fan_data *data, enum FAN_PWM_ENABLE enable)
+// Write value for pwmN_enable
+static void gpd_set_pwm_enable(struct gpd_fan_data *data, int channel, enum FAN_PWM_ENABLE enable)
 {
 	if (enable == MANUAL)
 		// Set pwm_value to max firstly when switching to manual mode, in
 		// consideration of device safety.
-		data->pwm_value = 255;
+		data->pwm_value[channel] = 255;
 
 	switch (data->drvdata->board) {
 	case win_mini:
 	case win4_6800u:
+	case win5:
 	case mpc2:
-		gpd_win_mini_set_pwm_enable(data, enable);
+		gpd_win_mini_set_pwm_enable(data, channel, enable);
 		break;
 	case duo:
 		gpd_duo_set_pwm_enable(data, enable);
@@ -491,10 +531,15 @@ static void gpd_set_pwm_enable(struct gpd_fan_data *data, enum FAN_PWM_ENABLE en
 	}
 }
 
-static umode_t gpd_fan_hwmon_is_visible(__always_unused const void *drvdata,
+static umode_t gpd_fan_hwmon_is_visible(const void *hwmon_data,
 					enum hwmon_sensor_types type, u32 attr,
-					__always_unused int channel)
+					int channel)
 {
+	const struct gpd_fan_data *data = hwmon_data;
+
+	if (channel >= gpd_num_fans(data->drvdata))
+		return 0;
+
 	if (type == hwmon_fan && attr == hwmon_fan_input) {
 		return 0444;
 	} else if (type == hwmon_pwm) {
@@ -511,14 +556,14 @@ static umode_t gpd_fan_hwmon_is_visible(__always_unused const void *drvdata,
 
 static int gpd_fan_hwmon_read(struct device *dev,
 			      enum hwmon_sensor_types type, u32 attr,
-			      __always_unused int channel, long *val)
+			      int channel, long *val)
 {
 	struct gpd_fan_data *data = dev_get_drvdata(dev);
 	int ret;
 
 	if (type == hwmon_fan) {
 		if (attr == hwmon_fan_input) {
-			ret = gpd_read_rpm(data);
+			ret = gpd_read_rpm(data, channel);
 
 			if (ret < 0)
 				return ret;
@@ -529,10 +574,10 @@ static int gpd_fan_hwmon_read(struct device *dev,
 	} else if (type == hwmon_pwm) {
 		switch (attr) {
 		case hwmon_pwm_enable:
-			*val = data->pwm_enable;
+			*val = data->pwm_enable[channel];
 			return 0;
 		case hwmon_pwm_input:
-			ret = gpd_read_pwm(data);
+			ret = gpd_read_pwm(data, channel);
 
 			if (ret < 0)
 				return ret;
@@ -547,7 +592,7 @@ static int gpd_fan_hwmon_read(struct device *dev,
 
 static int gpd_fan_hwmon_write(struct device *dev,
 			       enum hwmon_sensor_types type, u32 attr,
-			       __always_unused int channel, long val)
+			       int channel, long val)
 {
 	struct gpd_fan_data *data = dev_get_drvdata(dev);
 
@@ -557,17 +602,17 @@ static int gpd_fan_hwmon_write(struct device *dev,
 			if (!in_range(val, 0, 3))
 				return -EINVAL;
 
-			data->pwm_enable = val;
+			data->pwm_enable[channel] = val;
 
-			gpd_set_pwm_enable(data, data->pwm_enable);
+			gpd_set_pwm_enable(data, channel, data->pwm_enable[channel]);
 			return 0;
 		case hwmon_pwm_input:
 			if (!in_range(val, 0, 256))
 				return -EINVAL;
 
-			data->pwm_value = val;
+			data->pwm_value[channel] = val;
 
-			return gpd_write_pwm(data, val);
+			return gpd_write_pwm(data, channel, val);
 		}
 	}
 
@@ -581,8 +626,9 @@ static const struct hwmon_ops gpd_fan_ops = {
 };
 
 static const struct hwmon_channel_info *gpd_fan_hwmon_channel_info[] = {
-	HWMON_CHANNEL_INFO(fan, HWMON_F_INPUT),
-	HWMON_CHANNEL_INFO(pwm, HWMON_PWM_INPUT | HWMON_PWM_ENABLE),
+	HWMON_CHANNEL_INFO(fan, HWMON_F_INPUT, HWMON_F_INPUT),
+	HWMON_CHANNEL_INFO(pwm, HWMON_PWM_INPUT | HWMON_PWM_ENABLE,
+			   HWMON_PWM_INPUT | HWMON_PWM_ENABLE),
 	NULL
 };
 
@@ -619,8 +665,10 @@ static void gpd_fan_reset_hardware(void *pdata)
 	struct gpd_fan_data *data = pdata;
 
 	if (data) {
-		data->pwm_enable = AUTOMATIC;
-		gpd_set_pwm_enable(data, AUTOMATIC);
+		for (int i = 0; i < gpd_num_fans(data->drvdata); i++) {
+			data->pwm_enable[i] = AUTOMATIC;
+			gpd_set_pwm_enable(data, i, AUTOMATIC);
+		}
 	}
 }
 
@@ -654,8 +702,10 @@ static int gpd_fan_probe(struct platform_device *pdev)
 		return -EINVAL;
 
 	data->drvdata = match;
-	data->pwm_enable = AUTOMATIC;
-	data->pwm_value = 255;
+	for (int i = 0; i < gpd_num_fans(match); i++) {
+		data->pwm_enable[i] = AUTOMATIC;
+		data->pwm_value[i] = 255;
+	}
 
 	dev_set_drvdata(dev, data);
 

-- 
2.55.0

