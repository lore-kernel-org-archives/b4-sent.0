From: Maud Spierings <maudspierings@gocontroll.com>
Date: Tue, 04 Mar 2025 09:24:43 +0100
Subject: [PATCH] hwmon: (ntc_thermistor) Add min and max temperature
 attributes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250304-ntc_min_max-v1-1-b08e70e56459@gocontroll.com>
X-B4-Tracking: v=1; b=H4sIAMq4xmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDYwMT3byS5PjczLz43MQK3URLI9NUC/MUg5REcyWgjoKi1LTMCrBp0bG
 1tQB0iY2eXQAAAA==
X-Change-ID: 20250304-ntc_min_max-a925e87d0da7
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741076683; l=2025;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=CtUQPwJHavioCaVE/ITL8uSD7Pf7f336ipLgnIe6DqQ=;
 b=VFtcbljprV8WoPiWguyklrq7/qaLVB3HmKS463g82n6G8aqwOurAdFbPbzZhWxI6zEoLahSgm
 h8SEs5l/xFuBQ2FXtWz2q45eksoMtFL2AGfke/QRtIW/sQrO+8omJyx
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the min and max temperature attributes as it is trivial for this
driver.

This can help with detecting implausible readings and indicates to users
which range they can actually measure, so they will not set a trip point
at a temperature higher than max or lower than min.

This implementation only works for ntcs, if a ptc gets added this will
have to be changed, but I'm not sure if that is ever the intention.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 drivers/hwmon/ntc_thermistor.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/hwmon/ntc_thermistor.c b/drivers/hwmon/ntc_thermistor.c
index 0d29c8f97ba7c2f264588b6309b91ca494012ad6..fecee177be5daf304c0521a74f2733f6e42567e0 100644
--- a/drivers/hwmon/ntc_thermistor.c
+++ b/drivers/hwmon/ntc_thermistor.c
@@ -522,6 +522,12 @@ static int ntc_read(struct device *dev, enum hwmon_sensor_types type,
 		case hwmon_temp_type:
 			*val = 4;
 			return 0;
+		case hwmon_temp_min:
+			*val = data->comp[0].temp_c*1000;
+			return 0;
+		case hwmon_temp_max:
+			*val = data->comp[data->n_comp-1].temp_c*1000;
+			return 0;
 		default:
 			break;
 		}
@@ -539,6 +545,8 @@ static umode_t ntc_is_visible(const void *data, enum hwmon_sensor_types type,
 		switch (attr) {
 		case hwmon_temp_input:
 		case hwmon_temp_type:
+		case hwmon_temp_min:
+		case hwmon_temp_max:
 			return 0444;
 		default:
 			break;
@@ -549,7 +557,8 @@ static umode_t ntc_is_visible(const void *data, enum hwmon_sensor_types type,
 
 static const struct hwmon_channel_info * const ntc_info[] = {
 	HWMON_CHANNEL_INFO(chip, HWMON_C_REGISTER_TZ),
-	HWMON_CHANNEL_INFO(temp, HWMON_T_INPUT | HWMON_T_TYPE),
+	HWMON_CHANNEL_INFO(temp, HWMON_T_INPUT | HWMON_T_TYPE | HWMON_T_MIN |
+					 HWMON_T_MAX),
 	NULL
 };
 

---
base-commit: cd3215bbcb9d4321def93fea6cfad4d5b42b9d1d
change-id: 20250304-ntc_min_max-a925e87d0da7

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

