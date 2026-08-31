From: Asai Neko <sugar@sne.moe>
Date: Tue, 01 Sep 2026 00:18:24 +0800
Subject: [PATCH v2] hwmon: (asus-ec-sensors) add ROG STRIX X670E-A GAMING
 WIFI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260901-asus-x670e-a-hwmon-fix-v2-1-759406c2a61a@sne.moe>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0K6dsy0YiGuvIdhUeogNaE1HUAM6
 d0teACX7+f//1bBFB2xuBSriDQ7dsFnUIdC2N74B4G7ZxYKlcb6hGB4Ylh0hQQG+vcQPHRuAaP
 PpSYkWVZK5PErUo7341vzY57aJ9lxe9saveMxxM9unuXW+yuZJUiwHRpdo7UtqSt7Og6BRJNS+
 gIMX/2AzAAAAA==
X-Change-ID: 20260830-asus-x670e-a-hwmon-fix-a6546e0e1472
To: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Eugene Shalygin <eugene.shalygin@gmail.com>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Asai Neko <sugar@sne.moe>, 
 Randy Dunlap <rdunlap@infradead.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3278; i=sugar@sne.moe;
 h=from:subject:message-id; bh=+gs3hJ6ieL/dIW+XjKLDc1RXibqydIaNrIgceHoduwg=;
 b=owJ4nJvAy8zAJfZHZ3FlRAEbJ+NptSSGrKkrg/MOiC161rJeecbTxQVGArm3Wz+yrK55lLNCg
 fHJLVujS2s7SlkYxLgYZMUUWTqPdBU+eT3vwwEXXT6YOaxMIEMYuDgFYCKXFzMy7CjpT7N48S2a
 yfCxu3BHpZNg+7rvNhuunSyQiksT+6j7hOF/nH361uzXIbLfnXalXHj/v7Fp6ZsUv69NGW/zJ6k
 W7CxnBwBC70vg
X-Developer-Key: i=sugar@sne.moe; a=openpgp;
 fpr=89C48A71E4EB9EF0C0442D0EFC2CA37958700609
X-Endpoint-Received: by B4 Relay for sugar@sne.moe/default with auth_id=990
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ROG STRIX X670E-A GAMING WIFI is missing from the driver's DMI
table. Consequently, the board lookup fails with -ENODEV,
asus_ec_sensors does not load, and no asusec hwmon device or EC
temperature readings are available.

The board uses the same EC sensors, access mutex, and AMD 600-series
register layout as the ROG STRIX X670E-E GAMING WIFI. Add its DMI entry
using the existing X670E-E board information and document the board as
supported.

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
Changes in v2:
- Reuse the existing X670E-E board information instead of duplicating it.
- Link to v1: https://patch.msgid.link/20260830-asus-x670e-a-hwmon-fix-v1-1-cf0a680ccbe2@sne.moe

To: Guenter Roeck <linux@roeck-us.net>
To: Jonathan Corbet <corbet@lwn.net>
To: Shuah Khan <skhan@linuxfoundation.org>
To: Randy Dunlap <rdunlap@infradead.org>
To: Eugene Shalygin <eugene.shalygin@gmail.com>
Cc: linux-hwmon@vger.kernel.org
Cc: linux-doc@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 Documentation/hwmon/asus_ec_sensors.rst | 1 +
 drivers/hwmon/asus-ec-sensors.c         | 2 ++
 2 files changed, 3 insertions(+)

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
index e43645e884fd..7293c48c72b1 100644
--- a/drivers/hwmon/asus-ec-sensors.c
+++ b/drivers/hwmon/asus-ec-sensors.c
@@ -962,6 +962,8 @@ static const struct dmi_system_id dmi_table[] = {
 					&board_info_strix_x570_f_gaming),
 	DMI_EXACT_MATCH_ASUS_BOARD_NAME("ROG STRIX X570-I GAMING",
 					&board_info_strix_x570_i_gaming),
+	DMI_EXACT_MATCH_ASUS_BOARD_NAME("ROG STRIX X670E-A GAMING WIFI",
+					&board_info_strix_x670e_e_gaming_wifi),
 	DMI_EXACT_MATCH_ASUS_BOARD_NAME("ROG STRIX X670E-E GAMING WIFI",
 					&board_info_strix_x670e_e_gaming_wifi),
 	DMI_EXACT_MATCH_ASUS_BOARD_NAME("ROG STRIX X670E-I GAMING WIFI",

---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260830-asus-x670e-a-hwmon-fix-a6546e0e1472

Best regards,
--  
Asai Neko <sugar@sne.moe>

