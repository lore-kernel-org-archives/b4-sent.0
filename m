From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 13 Jul 2026 23:07:54 +0200
Subject: [PATCH] hwmon: (tmp401) register with thermal subsystem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260713-for-upstream-hwmon-tmp401-register-tz-v1-1-47315d8617bc@free.fr>
X-B4-Tracking: v=1; b=H4sIAKlTVWoC/x2NywqDQAwAf0VybiCrpWJ/pfSgNWoO+yBZtVT89
 257HBhmDjBWYYN7dYDyJiYxFHCXCl5LH2ZGGQtDTfWNWtfgFBXXZFm597jsPgbMPl3JofIsllk
 xf3D8uTR0AzcEpZWUJ3n/P4/neX4BN85exXcAAAA=
To: Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783976874; l=1435;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=KjziWIi0OltnNwCWGxqiR9hdiO69mfw90Ja+vvlTw18=;
 b=PDafruWlxKd+Zk51eUp/TVu8YihLTuQ1OXVy5lEYlD4EGX56l8xI9Rc7l+XmakcCc4uzGaSOD
 6QfYJZ+60K1BsFQzdVXe3DW1b6luC+aK8F+ix0TKYXJNGLduKOoiTnI
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tmp401 is missing HWMON_C_REGISTER_TZ. So a devicetree thermal
zone referencing a such sensor ('thermal-sensors = <&tmp411 N>')
fails to register it. Then its cooling-maps is not set, which means
that the fans are not managed.

Same as lm90 or jc42, set HWMON_C_REGISTER_TZ.
Boards without the property into the DT keep the same behavior.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
It was checked on a LX2160A board that uses a TMP411 for the chassis ambient
input of a fan thermal zone.
Without this patch the zone silently never registers.
With this patch, the zone registers and the cooling-map drives the EMC2305
fans.
---
 drivers/hwmon/tmp401.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/hwmon/tmp401.c b/drivers/hwmon/tmp401.c
index ca0ff525ea29..83aafe4bd3e7 100644
--- a/drivers/hwmon/tmp401.c
+++ b/drivers/hwmon/tmp401.c
@@ -695,7 +695,7 @@ static int tmp401_probe(struct i2c_client *client)
 	info->type = hwmon_chip;
 	info->config = data->chip_channel_config;
 
-	data->chip_channel_config[0] = HWMON_C_UPDATE_INTERVAL;
+	data->chip_channel_config[0] = HWMON_C_REGISTER_TZ | HWMON_C_UPDATE_INTERVAL;
 
 	info = &data->temp_info;
 	info->type = hwmon_temp;

---
base-commit: ca078d004cf58137bcf8cb24a8b271397431ba58
change-id: 20260713-for-upstream-hwmon-tmp401-register-tz-d07130b9be30

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

