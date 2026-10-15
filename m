From: Remy Demangeot <remy@demangeot.net>
Date: Thu, 15 Oct 2026 18:09:31 +0200
Subject: [PATCH] hwmon: (asus-ec-sensors) add MAXIMUS IX EXTREME
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-b4-m9e-extreme-v1-1-621da921e320@demangeot.net>
X-B4-Tracking: v=1; b=H4sIALr60GoC/x3MOwqAMBBF0a3I1A4kosG4FbGI8alT+CEREYJ7N
 1ie4t5EEUEQqSsSBdwS5dgzdFmQX92+gGXKpkpVRivd8FjzZsF4roAN7J1x1livMLeUozNgluc
 f9sP7fiWlCJRgAAAA
X-Change-ID: 20261015-b4-m9e-extreme-ca6a969c0ef8
To: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Eugene Shalygin <eugene.shalygin@gmail.com>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Remy Demangeot <remy@demangeot.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792080575; l=3658;
 i=remy@demangeot.net; s=20261015; h=from:subject:message-id;
 bh=s3RVR8WZtpDUVgsbn6tZJmB7/61SZqwM9dWjrNL/sE8=;
 b=rGwERFoK5sFkNhsxqY7emnSMCBzhsr0L6ItSBTwV90Dhc8YICxW+OQZv1Y524JOzlNTUgdRT+
 gDnKpI49Nx2CUKVfZCvwZQHtj4vVjJvoVV6BWRrnox9vbIJyLBpiFDd
X-Developer-Key: i=remy@demangeot.net; a=ed25519;
 pk=h/s5N2ZlgZ0m+8FpMhSaCNJt0jvb9whRBAdJwpC+VAo=
X-Endpoint-Received: by B4 Relay for remy@demangeot.net/20261015 with auth_id=1194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the ROG MAXIMUS IX EXTREME (Intel Z270). The board
uses the same EC layout as the PRIME Z270-A for the chipset and
T_Sensor temperatures, and additionally exposes the VRM temperature
at the same register as the 300-series boards (bank 0, 0x3e), so add
that sensor to the Intel 200-series family.

The hardware access mutex is \_SB_.PCI0.LPCB.SIO1.MUT0, as on the
PRIME Z270-A (verified in the board's DSDT).

Readings were checked against HWiNFO 8.54 on the same machine
(Chipset 47 C, T_Sensor 25 C, VRM 32 C).

Signed-off-by: Remy Demangeot <remy@demangeot.net>
---
The board's EC also exposes more sensors that HWiNFO reads, but they
need access patterns the driver does not have yet:
 - three extension card fans (EXT_FAN1-3): write 0x0a/0x0b/0x0c to
   bank 0 register 0x43 (selector), then read 0x57:0x58 (BE RPM);
 - EXT_Sensor1-3 temperatures at bank 0, 0x60-0x62;
 - Water_In/Out and Water_In2/Out2 on a second EC (firmware ID
   "RGE2-Z270-0109") at I/O ports 0x68/0x6c, bank 1, registers
   0x0d/0x0b/0x13/0x11 (same offsets as Water_In/Out on AMD boards).

I have a working out-of-tree driver for these and can prepare follow-up
patches if this approach would be acceptable.
---
 Documentation/hwmon/asus_ec_sensors.rst |  1 +
 drivers/hwmon/asus-ec-sensors.c         | 10 ++++++++++
 2 files changed, 11 insertions(+)

diff --git a/Documentation/hwmon/asus_ec_sensors.rst b/Documentation/hwmon/asus_ec_sensors.rst
index 7032c40731d900f6b345c3f52512eab4866cbe93..6d1fa99acefc94bf018b70715ae2f057d1d58fa6 100644
--- a/Documentation/hwmon/asus_ec_sensors.rst
+++ b/Documentation/hwmon/asus_ec_sensors.rst
@@ -5,6 +5,7 @@ Kernel driver asus_ec_sensors
 
 Supported boards:
  * MAXIMUS VI HERO
+ * MAXIMUS IX EXTREME
  * PRIME X470-PRO
  * PRIME X570-PRO
  * PRIME X670E-PRO WIFI
diff --git a/drivers/hwmon/asus-ec-sensors.c b/drivers/hwmon/asus-ec-sensors.c
index 19f423e45ce5e4b2cfdd5befea2450318ac626ba..3c97ae09cc19acad54696bff9e65d6bc4f3ce835 100644
--- a/drivers/hwmon/asus-ec-sensors.c
+++ b/drivers/hwmon/asus-ec-sensors.c
@@ -358,6 +358,7 @@ static const struct ec_sensor_info sensors_family_intel_200[] = {
 		EC_SENSOR("Motherboard", hwmon_temp, 1, 0x00, 0x3c),
 	[ec_sensor_temp_t_sensor] =
 		EC_SENSOR("T_Sensor", hwmon_temp, 1, 0x00, 0x3d),
+	[ec_sensor_temp_vrm] = EC_SENSOR("VRM", hwmon_temp, 1, 0x00, 0x3e),
 	[ec_sensor_fan_cpu_opt] =
 		EC_SENSOR("CPU_Opt", hwmon_fan, 2, 0x00, 0xbc),
 };
@@ -520,6 +521,13 @@ static const struct ec_board_info board_info_maximus_vi_hero = {
 	.family = family_intel_300_series,
 };
 
+static const struct ec_board_info board_info_maximus_ix_extreme = {
+	.sensors = SENSOR_TEMP_CHIPSET | SENSOR_TEMP_T_SENSOR |
+		SENSOR_TEMP_VRM,
+	.mutex_path = ASUS_HW_ACCESS_MUTEX_SB_PCI0_LPCB_SIO1_MUT0,
+	.family = family_intel_200_series,
+};
+
 static const struct ec_board_info board_info_maximus_x_hero = {
 	.sensors = SENSOR_SET_TEMP_CHIPSET_CPU_MB |
 		SENSOR_TEMP_T_SENSOR |
@@ -882,6 +890,8 @@ static const struct ec_board_info board_info_zenith_ii_extreme = {
 static const struct dmi_system_id dmi_table[] = {
 	DMI_EXACT_MATCH_ASUS_BOARD_NAME("MAXIMUS VI HERO",
 					&board_info_maximus_vi_hero),
+	DMI_EXACT_MATCH_ASUS_BOARD_NAME("MAXIMUS IX EXTREME",
+					&board_info_maximus_ix_extreme),
 	DMI_EXACT_MATCH_ASUS_BOARD_NAME("PRIME X470-PRO",
 					&board_info_prime_x470_pro),
 	DMI_EXACT_MATCH_ASUS_BOARD_NAME("PRIME X570-PRO",

---
base-commit: 4781ca52761e666cf18b591e6bb0478396c90320
change-id: 20261015-b4-m9e-extreme-ca6a969c0ef8

Best regards,
-- 
Remy Demangeot <remy@demangeot.net>

