From: Asai Neko <sugar@sne.moe>
Date: Sun, 30 Aug 2026 21:03:51 +0800
Subject: [PATCH] hwmon: (asus-ec-sensors) add ROG STRIX X670E-A GAMING WIFI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-asus-x670e-a-hwmon-fix-v1-1-cf0a680ccbe2@sne.moe>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QqCQBCF4VeRuW5g3GyNXiW62OyoE7TGjpYgv
 rtbXn4Hzr+QISmMLsVCCR81HWJGeSio6UPswPrIJifOy/koHGwynn0t4MD99zVEbnXm4E+Vh6C
 sakf5/E7I8z98ve226f5EM/5qtK4byROxT3oAAAA=
X-Change-ID: 20260830-asus-x670e-a-hwmon-fix-a6546e0e1472
To: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Eugene Shalygin <eugene.shalygin@gmail.com>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Asai Neko <sugar@sne.moe>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3374; i=sugar@sne.moe;
 h=from:subject:message-id; bh=woM7oFfMNv790yC/zom6LKZaK43bcPQBp2AM1p8C9nY=;
 b=owJ4nJvAy8zAJfZHZ3FlRAEbJ+NptSSGrCla1i3/ds3PuJk0ubRE9G2FqN6lI5aM6jk8KSq+Q
 YuP1LcHenSUsjCIcTHIiimydB7pKnzyet6HAy66fDBzWJlAhjBwcQrARBy3MzI0hB26us5ViW0S
 U+OUn0Gfm94+eKzl8bDhnOjhvXOrJ6RdY2Rompn3MDCV72dUDdPOf6suLC+UUfjCc25Sl4XsrZD
 jb36zAgClsEhf
X-Developer-Key: i=sugar@sne.moe; a=openpgp;
 fpr=89C48A71E4EB9EF0C0442D0EFC2CA37958700609
X-Endpoint-Received: by B4 Relay for sugar@sne.moe/default with auth_id=990
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ROG STRIX X670E-A GAMING WIFI is missing from the driver's DMI
table. Consequently, the board lookup fails with -ENODEV,
asus_ec_sensors does not load, and no asusec hwmon device or EC
temperature readings are available.

Add a board definition using the AMD 600-series register layout and the
ACPI mutex used by the board firmware. Expose CPU, CPU package,
motherboard, and VRM temperatures, and add the board to the supported
hardware documentation.

Before the change, there was no asusec device under /sys/class/hwmon and
there were no EC readings. After the change, the driver registered four
sensors with representative readings of 57-61 C for CPU, 68-71 C for
CPU package, 43-44 C for motherboard, and 49-52 C for VRM.

The readings correlated with nct6775 and k10temp. Repeated polling with
both hwmon drivers loaded produced no EC access, bank-switch, concurrent
access, or locking errors.

Tested on an ASUS ROG STRIX X670E-A GAMING WIFI with BIOS 2704.

Signed-off-by: Asai Neko <sugar@sne.moe>
---
Add asus-ec-sensors support for the ASUS ROG STRIX X670E-A GAMING WIFI.
Testing details and the rationale are included in the patch commit
message.

Background:
https://github.com/lm-sensors/lm-sensors/issues/474
---
 Documentation/hwmon/asus_ec_sensors.rst | 1 +
 drivers/hwmon/asus-ec-sensors.c         | 9 +++++++++
 2 files changed, 10 insertions(+)

diff --git a/Documentation/hwmon/asus_ec_sensors.rst b/Documentation/hwmon/asus_ec_sensors.rst
index 2c68a343a2ed..ebed9f8d2adb 100644
--- a/Documentation/hwmon/asus_ec_sensors.rst
+++ b/Documentation/hwmon/asus_ec_sensors.rst
@@ -45,6 +45,7 @@ Supported boards:
  * ROG STRIX X570-E GAMING WIFI II
  * ROG STRIX X570-F GAMING
  * ROG STRIX X570-I GAMING
+ * ROG STRIX X670E-A GAMING WIFI
  * ROG STRIX X670E-E GAMING WIFI
  * ROG STRIX X670E-I GAMING WIFI
  * ROG STRIX X870-F GAMING WIFI
diff --git a/drivers/hwmon/asus-ec-sensors.c b/drivers/hwmon/asus-ec-sensors.c
index e43645e884fd..850c8e297397 100644
--- a/drivers/hwmon/asus-ec-sensors.c
+++ b/drivers/hwmon/asus-ec-sensors.c
@@ -752,6 +752,13 @@ static const struct ec_board_info board_info_strix_x570_i_gaming = {
 	.family = family_amd_500_series,
 };
 
+static const struct ec_board_info board_info_strix_x670e_a_gaming_wifi = {
+	.sensors = SENSOR_TEMP_CPU | SENSOR_TEMP_CPU_PACKAGE |
+		SENSOR_TEMP_MB | SENSOR_TEMP_VRM,
+	.mutex_path = ASUS_HW_ACCESS_MUTEX_SB_PCI0_SBRG_SIO1_MUT0,
+	.family = family_amd_600_series,
+};
+
 static const struct ec_board_info board_info_strix_x670e_e_gaming_wifi = {
 	.sensors = SENSOR_TEMP_CPU | SENSOR_TEMP_CPU_PACKAGE |
 		SENSOR_TEMP_MB  | SENSOR_TEMP_VRM,
@@ -962,6 +969,8 @@ static const struct dmi_system_id dmi_table[] = {
 					&board_info_strix_x570_f_gaming),
 	DMI_EXACT_MATCH_ASUS_BOARD_NAME("ROG STRIX X570-I GAMING",
 					&board_info_strix_x570_i_gaming),
+	DMI_EXACT_MATCH_ASUS_BOARD_NAME("ROG STRIX X670E-A GAMING WIFI",
+					&board_info_strix_x670e_a_gaming_wifi),
 	DMI_EXACT_MATCH_ASUS_BOARD_NAME("ROG STRIX X670E-E GAMING WIFI",
 					&board_info_strix_x670e_e_gaming_wifi),
 	DMI_EXACT_MATCH_ASUS_BOARD_NAME("ROG STRIX X670E-I GAMING WIFI",

---
base-commit: 75f2c0b3690702c90863c2e138cb5520670845ea
change-id: 20260830-asus-x670e-a-hwmon-fix-a6546e0e1472

Best regards,
--  
Asai Neko <sugar@sne.moe>

