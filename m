From: Sung-Chi Li <lschyi@google.com>
Date: Thu, 11 Sep 2025 06:56:34 +0000
Subject: [PATCH v6 1/3] platform/chrome: update pwm fan control host
 commands
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250911-cros_ec_fan-v6-1-a1446cc098af@google.com>
References: <20250911-cros_ec_fan-v6-0-a1446cc098af@google.com>
In-Reply-To: <20250911-cros_ec_fan-v6-0-a1446cc098af@google.com>
To: Benson Leung <bleung@chromium.org>, Guenter Roeck <groeck@chromium.org>, 
 =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>
Cc: chrome-platform@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 Sung-Chi Li <lschyi@google.com>, Sung-Chi Li <lschyi@chromium.org>, 
 Tzung-Bi Shih <tzungbi@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757573797; l=2291;
 i=lschyi@google.com; s=20250911; h=from:subject:message-id;
 bh=XKg9pL8fIe9un0KsLGA/Xf6YwtKbC9ILlKEDmhqAsDU=;
 b=FvHu5OpVFEL0f244w4/fsq2OrKNUPTtwqaJQemt9+rCvk0KUy8TERMzTpaDrq3YVMtgCMH4u/
 4w7AAZyyKaPB1vKic0iSO2MgIfgyTPja9mAcahOuZXUVfRsg0zDmtsR
X-Developer-Key: i=lschyi@google.com; a=ed25519;
 pk=fBhhFxZrEyInLLODzeoq06UxQhKVqNjmZ2680pwMBCM=
X-Endpoint-Received: by B4 Relay for lschyi@google.com/20250911 with auth_id=518
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sung-Chi Li <lschyi@chromium.org>

Update cros_ec_commands.h to include definitions for getting PWM fan
duty, getting and setting the fan control mode.

Signed-off-by: Sung-Chi Li <lschyi@chromium.org>
Acked-by: Tzung-Bi Shih <tzungbi@kernel.org>
Reviewed-by: Thomas Weißschuh <linux@weissschuh.net>
---
 include/linux/platform_data/cros_ec_commands.h | 29 +++++++++++++++++++++++++-
 1 file changed, 28 insertions(+), 1 deletion(-)

diff --git a/include/linux/platform_data/cros_ec_commands.h b/include/linux/platform_data/cros_ec_commands.h
index c19b404e3d8d9ec895a17838aa6e271e235f0823..69294f79cc88aaa6289af3f104743ff0d93ab753 100644
--- a/include/linux/platform_data/cros_ec_commands.h
+++ b/include/linux/platform_data/cros_ec_commands.h
@@ -1825,6 +1825,16 @@ struct ec_response_pwm_get_duty {
 	uint16_t duty;     /* Duty cycle, EC_PWM_MAX_DUTY = 100% */
 } __ec_align2;
 
+#define EC_CMD_PWM_GET_FAN_DUTY 0x0027
+
+struct ec_params_pwm_get_fan_duty {
+	uint8_t fan_idx;
+} __ec_align1;
+
+struct ec_response_pwm_get_fan_duty {
+	uint32_t percent; /* Percentage of duty cycle, ranging from 0 ~ 100 */
+} __ec_align4;
+
 /*****************************************************************************/
 /*
  * Lightbar commands. This looks worse than it is. Since we only use one HOST
@@ -3127,14 +3137,31 @@ struct ec_params_thermal_set_threshold_v1 {
 
 /****************************************************************************/
 
-/* Toggle automatic fan control */
+/* Set or get fan control mode */
 #define EC_CMD_THERMAL_AUTO_FAN_CTRL 0x0052
 
+enum ec_auto_fan_ctrl_cmd {
+	EC_AUTO_FAN_CONTROL_CMD_SET = 0,
+	EC_AUTO_FAN_CONTROL_CMD_GET,
+};
+
 /* Version 1 of input params */
 struct ec_params_auto_fan_ctrl_v1 {
 	uint8_t fan_idx;
 } __ec_align1;
 
+/* Version 2 of input params */
+struct ec_params_auto_fan_ctrl_v2 {
+	uint8_t fan_idx;
+	uint8_t cmd; /* enum ec_auto_fan_ctrl_cmd */
+	uint8_t set_auto; /* only used with EC_AUTO_FAN_CONTROL_CMD_SET - bool
+			   */
+} __ec_align4;
+
+struct ec_response_auto_fan_control {
+	uint8_t is_auto; /* bool */
+} __ec_align1;
+
 /* Get/Set TMP006 calibration data */
 #define EC_CMD_TMP006_GET_CALIBRATION 0x0053
 #define EC_CMD_TMP006_SET_CALIBRATION 0x0054

-- 
2.51.0.384.g4c02a37b29-goog

