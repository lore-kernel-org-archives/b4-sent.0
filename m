From: Sung-Chi Li <lschyi@chromium.org>
Date: Tue, 29 Apr 2025 16:14:22 +0800
Subject: [PATCH 2/3] hwmon: (cros_ec) add PWM control over fans
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250429-cros_ec_fan-v1-2-a8d9e3efbb1a@chromium.org>
References: <20250429-cros_ec_fan-v1-0-a8d9e3efbb1a@chromium.org>
In-Reply-To: <20250429-cros_ec_fan-v1-0-a8d9e3efbb1a@chromium.org>
To: Benson Leung <bleung@chromium.org>, Guenter Roeck <groeck@chromium.org>, 
 =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>, 
 Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: chrome-platform@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 Sung-Chi Li <lschyi@google.com>, Sung-Chi Li <lschyi@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745914465; l=12358;
 i=lschyi@chromium.org; s=20250429; h=from:subject:message-id;
 bh=4PCkSeWQAdaLAbrCAAHRvD/qTzf/L9llle707SU1Nak=;
 b=bNvY13jjmgoYCBdpc4WQB/RpDf5YARzOG6jGvjexTcqH0YrJyn6XNXC0tjFd3HkgiVCaGIJt4
 5CZ0D370iqyBGHQkCqYWm3Lqln56+zfoBS+kTUVrWGJvWX3Kbxap6Vs
X-Developer-Key: i=lschyi@chromium.org; a=ed25519;
 pk=9gCZPRJmYyHDt6VN9FV2UreFcUr73JFrwYvmsltW9Y8=
X-Endpoint-Received: by B4 Relay for lschyi@chromium.org/20250429 with auth_id=392
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Newer EC firmware supports controlling fans through host commands, so
adding corresponding implementations for controlling these fans in the
driver for other kernel services and userspace to control them.

The driver will first probe the supported host command versions (get and
set of fan PWM values, get and set of fan control mode) to see if the
connected EC fulfills the requirements of controlling the fan, then
exposes corresponding sysfs nodes for userspace to control the fan with
corresponding read and write implementations.
As EC will automatically change the fan mode to auto when the device is
suspended, the power management hooks are added as well to keep the fan
control mode and fan PWM value consistent during suspend and resume. As
we need to access the hwmon device in the power management hook, update
the driver by storing the hwmon device in the driver data as well.

Signed-off-by: Sung-Chi Li <lschyi@chromium.org>
---
 Documentation/hwmon/cros_ec_hwmon.rst |   5 +-
 drivers/hwmon/cros_ec_hwmon.c         | 237 +++++++++++++++++++++++++++++++++-
 2 files changed, 237 insertions(+), 5 deletions(-)

diff --git a/Documentation/hwmon/cros_ec_hwmon.rst b/Documentation/hwmon/cros_ec_hwmon.rst
index 47ecae983bdbef4bfcafc5dd2fff3de039f77f8e..5b802be120438732529c3d25b1afa8b4ee353305 100644
--- a/Documentation/hwmon/cros_ec_hwmon.rst
+++ b/Documentation/hwmon/cros_ec_hwmon.rst
@@ -23,4 +23,7 @@ ChromeOS embedded controller used in Chromebooks and other devices.
 
 The channel labels exposed via hwmon are retrieved from the EC itself.
 
-Fan and temperature readings are supported.
+Fan and temperature readings are supported. PWM fan control is also supported if
+the EC also supports setting fan PWM values and fan mode. Note that EC will
+switch fan control mode back to auto when suspended. This driver will restore
+the fan state before suspended.
diff --git a/drivers/hwmon/cros_ec_hwmon.c b/drivers/hwmon/cros_ec_hwmon.c
index 9991c3fa020ac859cbbff29dfb669e53248df885..1139074d3eb003ee72bbe54a954647ced40f6d21 100644
--- a/drivers/hwmon/cros_ec_hwmon.c
+++ b/drivers/hwmon/cros_ec_hwmon.c
@@ -17,10 +17,17 @@
 
 #define DRV_NAME	"cros-ec-hwmon"
 
+struct cros_ec_hwmon_platform_priv {
+	struct device *hwmon_dev;
+};
+
 struct cros_ec_hwmon_priv {
 	struct cros_ec_device *cros_ec;
 	const char *temp_sensor_names[EC_TEMP_SENSOR_ENTRIES + EC_TEMP_SENSOR_B_ENTRIES];
 	u8 usable_fans;
+	bool fan_control_supported;
+	u8 manual_fans; /* bits to indicate whether the fan is set to manual */
+	u8 manual_fan_pwm_values[EC_FAN_SPEED_ENTRIES];
 };
 
 static int cros_ec_hwmon_read_fan_speed(struct cros_ec_device *cros_ec, u8 index, u16 *speed)
@@ -36,6 +43,51 @@ static int cros_ec_hwmon_read_fan_speed(struct cros_ec_device *cros_ec, u8 index
 	return 0;
 }
 
+static int cros_ec_hwmon_read_pwm_raw_value(struct cros_ec_device *cros_ec,
+					    u8 index, u8 *pwm_value)
+{
+	struct ec_params_pwm_get_fan_duty req = {
+		.fan_idx = index,
+	};
+	struct ec_response_pwm_get_fan_duty resp;
+	int ret = cros_ec_cmd(cros_ec, 0, EC_CMD_PWM_GET_FAN_DUTY, &req,
+			      sizeof(req), &resp, sizeof(resp));
+
+	if (ret < 0)
+		return ret;
+
+	*pwm_value = (u8)(le32_to_cpu(resp.percent));
+	return 0;
+}
+
+static int cros_ec_hwmon_read_pwm_value(struct cros_ec_device *cros_ec,
+					u8 index, u8 *pwm_value)
+{
+	int ret = cros_ec_hwmon_read_pwm_raw_value(cros_ec, index, pwm_value);
+
+	if (ret == 0)
+		*pwm_value = *pwm_value * 255 / 100;
+	return ret;
+}
+
+static int cros_ec_hwmon_read_pwm_enable(struct cros_ec_device *cros_ec,
+					 u8 index, u8 *control_method)
+{
+	struct ec_params_auto_fan_ctrl_v2 req = {
+		.fan_idx = index,
+		.cmd = EC_AUTO_FAN_CONTROL_CMD_GET,
+	};
+	struct ec_response_auto_fan_control resp;
+	int ret = cros_ec_cmd(cros_ec, 2, EC_CMD_THERMAL_AUTO_FAN_CTRL, &req,
+			      sizeof(req), &resp, sizeof(resp));
+
+	if (ret < 0)
+		return ret;
+
+	*control_method = (resp.is_auto) ? 2 : 1;
+	return 0;
+}
+
 static int cros_ec_hwmon_read_temp(struct cros_ec_device *cros_ec, u8 index, u8 *temp)
 {
 	unsigned int offset;
@@ -76,6 +128,8 @@ static int cros_ec_hwmon_read(struct device *dev, enum hwmon_sensor_types type,
 	struct cros_ec_hwmon_priv *priv = dev_get_drvdata(dev);
 	int ret = -EOPNOTSUPP;
 	u16 speed;
+	u8 pwm_value;
+	u8 control_method;
 	u8 temp;
 
 	if (type == hwmon_fan) {
@@ -92,6 +146,18 @@ static int cros_ec_hwmon_read(struct device *dev, enum hwmon_sensor_types type,
 			if (ret == 0)
 				*val = cros_ec_hwmon_is_error_fan(speed);
 		}
+	} else if (type == hwmon_pwm) {
+		if (attr == hwmon_pwm_enable) {
+			ret = cros_ec_hwmon_read_pwm_enable(
+				priv->cros_ec, channel, &control_method);
+			if (ret == 0)
+				*val = control_method;
+		} else if (attr == hwmon_pwm_input) {
+			ret = cros_ec_hwmon_read_pwm_value(priv->cros_ec,
+							   channel, &pwm_value);
+			if (ret == 0)
+				*val = pwm_value;
+		}
 	} else if (type == hwmon_temp) {
 		if (attr == hwmon_temp_input) {
 			ret = cros_ec_hwmon_read_temp(priv->cros_ec, channel, &temp);
@@ -124,6 +190,97 @@ static int cros_ec_hwmon_read_string(struct device *dev, enum hwmon_sensor_types
 	return -EOPNOTSUPP;
 }
 
+static int cros_ec_hwmon_write_pwm_value(struct cros_ec_device *cros_ec,
+					     u8 index, u8 val)
+{
+	struct ec_params_pwm_set_fan_duty_v1 req = {
+		.percent = val,
+		.fan_idx = index,
+	};
+	int ret = cros_ec_cmd(cros_ec, 1, EC_CMD_PWM_SET_FAN_DUTY, &req,
+			      sizeof(req), NULL, 0);
+
+	if (ret < 0)
+		return ret;
+	return 0;
+}
+
+static int cros_ec_hwmon_set_pwm_raw_value(struct cros_ec_hwmon_priv *priv,
+					   u8 index, u8 val)
+{
+	int ret;
+
+	if (!(priv->manual_fans & BIT(index)))
+		return -ECANCELED;
+
+	ret = cros_ec_hwmon_write_pwm_value(priv->cros_ec, index, val);
+	if (ret == 0)
+		priv->manual_fan_pwm_values[index] = val;
+	return ret;
+}
+
+static int cros_ec_hwmon_set_pwm_value(struct cros_ec_hwmon_priv *priv,
+				       u8 index, u8 val)
+{
+	return cros_ec_hwmon_set_pwm_raw_value(priv, index,
+					       (((uint32_t)val) * 100 / 255));
+}
+
+static int cros_ec_hwmon_write_pwm_enable(struct cros_ec_device *cros_ec,
+					  u8 index, u8 val)
+{
+	struct ec_params_auto_fan_ctrl_v2 req = {
+		.fan_idx = index,
+		.cmd = EC_AUTO_FAN_CONTROL_CMD_SET,
+	};
+	int ret;
+
+	/* No CROS EC supports no fan speed control */
+	if (val == 0)
+		return -EOPNOTSUPP;
+
+	req.set_auto = (val != 1) ? true : false;
+	ret = cros_ec_cmd(cros_ec, 2, EC_CMD_THERMAL_AUTO_FAN_CTRL, &req,
+			  sizeof(req), NULL, 0);
+	if (ret < 0)
+		return ret;
+	return 0;
+}
+
+static int cros_ec_hwmon_set_pwm_control_method(struct cros_ec_hwmon_priv *priv,
+						u8 index, u8 val)
+{
+	int ret = cros_ec_hwmon_write_pwm_enable(priv->cros_ec, index, val);
+
+	if (ret == 0) {
+		if (val == 1)
+			priv->manual_fans |= BIT(index);
+		else
+			priv->manual_fans &= ~BIT(index);
+	}
+	return ret;
+}
+
+static int cros_ec_hwmon_write(struct device *dev, enum hwmon_sensor_types type,
+			       u32 attr, int channel, long val)
+{
+	struct cros_ec_hwmon_priv *priv = dev_get_drvdata(dev);
+
+	if (type == hwmon_pwm) {
+		switch (attr) {
+		case hwmon_pwm_input:
+			return cros_ec_hwmon_set_pwm_value(priv, channel, val);
+		case hwmon_pwm_enable:
+			return cros_ec_hwmon_set_pwm_control_method(
+				priv, channel, val);
+		default:
+			return -EOPNOTSUPP;
+		}
+	}
+
+	return -EOPNOTSUPP;
+}
+
 static umode_t cros_ec_hwmon_is_visible(const void *data, enum hwmon_sensor_types type,
 					u32 attr, int channel)
 {
@@ -132,6 +289,9 @@ static umode_t cros_ec_hwmon_is_visible(const void *data, enum hwmon_sensor_type
 	if (type == hwmon_fan) {
 		if (priv->usable_fans & BIT(channel))
 			return 0444;
+	} else if (type == hwmon_pwm && priv->fan_control_supported) {
+		if (priv->usable_fans & BIT(channel))
+			return 0644;
 	} else if (type == hwmon_temp) {
 		if (priv->temp_sensor_names[channel])
 			return 0444;
@@ -147,6 +307,11 @@ static const struct hwmon_channel_info * const cros_ec_hwmon_info[] = {
 			   HWMON_F_INPUT | HWMON_F_FAULT,
 			   HWMON_F_INPUT | HWMON_F_FAULT,
 			   HWMON_F_INPUT | HWMON_F_FAULT),
+	HWMON_CHANNEL_INFO(pwm,
+			   HWMON_PWM_INPUT | HWMON_PWM_ENABLE,
+			   HWMON_PWM_INPUT | HWMON_PWM_ENABLE,
+			   HWMON_PWM_INPUT | HWMON_PWM_ENABLE,
+			   HWMON_PWM_INPUT | HWMON_PWM_ENABLE),
 	HWMON_CHANNEL_INFO(temp,
 			   HWMON_T_INPUT | HWMON_T_FAULT | HWMON_T_LABEL,
 			   HWMON_T_INPUT | HWMON_T_FAULT | HWMON_T_LABEL,
@@ -178,6 +343,7 @@ static const struct hwmon_channel_info * const cros_ec_hwmon_info[] = {
 static const struct hwmon_ops cros_ec_hwmon_ops = {
 	.read = cros_ec_hwmon_read,
 	.read_string = cros_ec_hwmon_read_string,
+	.write = cros_ec_hwmon_write,
 	.is_visible = cros_ec_hwmon_is_visible,
 };
 
@@ -233,13 +399,35 @@ static void cros_ec_hwmon_probe_fans(struct cros_ec_hwmon_priv *priv)
 	}
 }
 
+static void
+cros_ec_hwmon_probe_fan_control_supported(struct cros_ec_hwmon_priv *priv)
+{
+	int ret;
+
+	priv->fan_control_supported = false;
+
+	ret = cros_ec_get_cmd_versions(priv->cros_ec, EC_CMD_PWM_GET_FAN_DUTY);
+	if (ret < 0 || !(ret & EC_VER_MASK(0)))
+		return;
+
+	ret = cros_ec_get_cmd_versions(priv->cros_ec, EC_CMD_PWM_SET_FAN_DUTY);
+	if (ret < 0 || !(ret & EC_VER_MASK(1)))
+		return;
+
+	ret = cros_ec_get_cmd_versions(priv->cros_ec, EC_CMD_THERMAL_AUTO_FAN_CTRL);
+	if (ret < 0 || !(ret & EC_VER_MASK(2)))
+		return;
+
+	priv->fan_control_supported = true;
+}
+
 static int cros_ec_hwmon_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
 	struct cros_ec_dev *ec_dev = dev_get_drvdata(dev->parent);
 	struct cros_ec_device *cros_ec = ec_dev->ec_dev;
+	struct cros_ec_hwmon_platform_priv *platform_priv;
 	struct cros_ec_hwmon_priv *priv;
-	struct device *hwmon_dev;
 	u8 thermal_version;
 	int ret;
 
@@ -251,6 +439,10 @@ static int cros_ec_hwmon_probe(struct platform_device *pdev)
 	if (thermal_version == 0)
 		return -ENODEV;
 
+	platform_priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
+	if (!platform_priv)
+		return -ENOMEM;
+
 	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
 	if (!priv)
 		return -ENOMEM;
@@ -259,11 +451,47 @@ static int cros_ec_hwmon_probe(struct platform_device *pdev)
 
 	cros_ec_hwmon_probe_temp_sensors(dev, priv, thermal_version);
 	cros_ec_hwmon_probe_fans(priv);
+	cros_ec_hwmon_probe_fan_control_supported(priv);
 
-	hwmon_dev = devm_hwmon_device_register_with_info(dev, "cros_ec", priv,
-							 &cros_ec_hwmon_chip_info, NULL);
+	platform_priv->hwmon_dev = devm_hwmon_device_register_with_info(
+		dev, "cros_ec", priv, &cros_ec_hwmon_chip_info, NULL);
+	dev_set_drvdata(dev, platform_priv);
 
-	return PTR_ERR_OR_ZERO(hwmon_dev);
+	return PTR_ERR_OR_ZERO(platform_priv->hwmon_dev);
+}
+
+static int cros_ec_hwmon_resume(struct platform_device *pdev)
+{
+	const struct cros_ec_hwmon_platform_priv *platform_priv =
+		dev_get_drvdata(&pdev->dev);
+	const struct cros_ec_hwmon_priv *priv =
+		dev_get_drvdata(platform_priv->hwmon_dev);
+	size_t i;
+	int ret;
+
+	if (!priv->fan_control_supported)
+		return 0;
+
+	/*
+	 * EC sets fan control to auto after suspended, restore settings to
+	 * before suspended.
+	 */
+	for (i = 0; i < EC_FAN_SPEED_ENTRIES; i++) {
+		if (!(priv->manual_fans & BIT(i)))
+			continue;
+
+		/*
+		 * Setting fan PWM value to EC will change the mode to manual
+		 * for that fan in EC as well, so we do not need to issue a
+		 * separate fan mode to manual call.
+		 */
+		ret = cros_ec_hwmon_write_pwm_value(
+			priv->cros_ec, i, priv->manual_fan_pwm_values[i]);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
 }
 
 static const struct platform_device_id cros_ec_hwmon_id[] = {
@@ -274,6 +502,7 @@ static const struct platform_device_id cros_ec_hwmon_id[] = {
 static struct platform_driver cros_ec_hwmon_driver = {
 	.driver.name	= DRV_NAME,
 	.probe		= cros_ec_hwmon_probe,
+	.resume		= cros_ec_hwmon_resume,
 	.id_table	= cros_ec_hwmon_id,
 };
 module_platform_driver(cros_ec_hwmon_driver);

-- 
2.49.0.901.g37484f566f-goog

