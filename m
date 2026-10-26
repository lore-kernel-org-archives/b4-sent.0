From: Remy Demangeot <remy@demangeot.net>
Date: Mon, 26 Oct 2026 09:57:35 +0100
Subject: [PATCH 1/3] hwmon: (asus-ec-sensors) add EXT_Sensor temperatures
 for MAXIMUS IX EXTREME
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-b4-m9e-ext-sensors-v1-1-644d389b2de1@demangeot.net>
References: <20261026-b4-m9e-ext-sensors-v1-0-644d389b2de1@demangeot.net>
In-Reply-To: <20261026-b4-m9e-ext-sensors-v1-0-644d389b2de1@demangeot.net>
To: Eugene Shalygin <eugene.shalygin@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Remy Demangeot <remy@demangeot.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793005066; l=1995;
 i=remy@demangeot.net; s=20261015; h=from:subject:message-id;
 bh=WyQhdqkdM10QFFAO+QYVgb4wy5e8BEIj6Hxrc9XW7Nw=;
 b=IsS3JVtgVcHZt6LMRA58mLfSaGRk0OeMoYSUZ4jIBAxWs3CD3Qx7RVDcXd+TBTvWwhC+Zwoew
 F4byR4xKpaLDkoMthVlHNQ6XFLuQE2rXN7h4hHcdCuHwAMOcVJI4ZLa
X-Developer-Key: i=remy@demangeot.net; a=ed25519;
 pk=h/s5N2ZlgZ0m+8FpMhSaCNJt0jvb9whRBAdJwpC+VAo=
X-Endpoint-Received: by B4 Relay for remy@demangeot.net/20261015 with auth_id=1194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MAXIMUS IX EXTREME supports three additional thermistor inputs,
EXT_Sensor1-3, located on the optional ASUS fan extension card. The
EC reports them at bank 0, registers 0x60-0x62, as signed degrees
Celsius, with -60 when no probe is connected (already handled as a
blank value).

Add them to the Intel 200-series family as Extra_1-Extra_3 and enable
them for the board.

Readings match HWiNFO 8.54 on the same machine, and moving a probe
from one header to another moves the reading accordingly.

Signed-off-by: Remy Demangeot <remy@demangeot.net>
---
 drivers/hwmon/asus-ec-sensors.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/hwmon/asus-ec-sensors.c b/drivers/hwmon/asus-ec-sensors.c
index 3c97ae09cc19acad54696bff9e65d6bc4f3ce835..8966053b58173592a19afbab42ccbe8e6e6d7042 100644
--- a/drivers/hwmon/asus-ec-sensors.c
+++ b/drivers/hwmon/asus-ec-sensors.c
@@ -359,6 +359,12 @@ static const struct ec_sensor_info sensors_family_intel_200[] = {
 	[ec_sensor_temp_t_sensor] =
 		EC_SENSOR("T_Sensor", hwmon_temp, 1, 0x00, 0x3d),
 	[ec_sensor_temp_vrm] = EC_SENSOR("VRM", hwmon_temp, 1, 0x00, 0x3e),
+	[ec_sensor_temp_sensor_extra_1] =
+		EC_SENSOR("Extra_1", hwmon_temp, 1, 0x00, 0x60),
+	[ec_sensor_temp_sensor_extra_2] =
+		EC_SENSOR("Extra_2", hwmon_temp, 1, 0x00, 0x61),
+	[ec_sensor_temp_sensor_extra_3] =
+		EC_SENSOR("Extra_3", hwmon_temp, 1, 0x00, 0x62),
 	[ec_sensor_fan_cpu_opt] =
 		EC_SENSOR("CPU_Opt", hwmon_fan, 2, 0x00, 0xbc),
 };
@@ -523,7 +529,8 @@ static const struct ec_board_info board_info_maximus_vi_hero = {
 
 static const struct ec_board_info board_info_maximus_ix_extreme = {
 	.sensors = SENSOR_TEMP_CHIPSET | SENSOR_TEMP_T_SENSOR |
-		SENSOR_TEMP_VRM,
+		SENSOR_TEMP_VRM | SENSOR_TEMP_SENSOR_EXTRA_1 |
+		SENSOR_TEMP_SENSOR_EXTRA_2 | SENSOR_TEMP_SENSOR_EXTRA_3,
 	.mutex_path = ASUS_HW_ACCESS_MUTEX_SB_PCI0_LPCB_SIO1_MUT0,
 	.family = family_intel_200_series,
 };

-- 
2.47.3

