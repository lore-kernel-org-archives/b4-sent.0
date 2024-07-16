From: Cryolitia PukNgae <Cryolitia@gmail.com>
Date: Wed, 17 Jul 2024 00:58:08 +0800
Subject: [PATCH v2 2/2] hwmon: document: add gpd-fan
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240717-gpd_fan-v2-2-f7b7e6b9f21b@gmail.com>
References: <20240717-gpd_fan-v2-0-f7b7e6b9f21b@gmail.com>
In-Reply-To: <20240717-gpd_fan-v2-0-f7b7e6b9f21b@gmail.com>
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Cryolitia PukNgae <Cryolitia@gmail.com>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-doc@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>, 
 =?utf-8?q?Marcin_Str=C4=85gowski?= <marcin@stragowski.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3034; i=Cryolitia@gmail.com;
 h=from:subject:message-id; bh=Nw5WNnztmQvB/uQybSpOS79cJ2EsL9qlteCrPY1B3To=;
 b=LS0tLS1CRUdJTiBQR1AgTUVTU0FHRS0tLS0tCgpvd0VCYlFHUy9wQU5Bd0FJQVQ1ZEYzTDhpb
 zdkQWNzbVlnQm1scWF0Qll4ZlNlMW1iQ0xYbTgrU1hicGNxb2ROCnpRZmgva2pNUWdlRDcrRWRG
 cXlKQVRNRUFBRUlBQjBXSVFSME5XMHB5dmR3U0JGOENDWStYUmR5L0lxTzNRVUMKWnBhbXJRQUt
 DUkErWFJkeS9JcU8zZWo1Qi85b201SDV2Ry9UNWZnRzVzYWs1dzBLV2hZL0pOSG1kR1h2TW9kWQ
 oyZEk3bUFWWnE4UjQxcU0wMXNWeThBSHk2Y0VEOWtkV0poVDhrYUhvMWdnQmFiaUtkNFBFcWVoS
 Gp5QkRQMkJ2CmhxS1ltOU4wTnFDd3Jac0xNUWhac0Rrd0t0dTVSWmlPaUViTk41THFrdEFLZEJK
 WEIrckZiVHNQd3dwQmVVZWUKb2Vxb3lOaVZ2WmdpRjFJYm9kbTVybFdTcUcyei9HRndLT0xlZ3d
 EaG1uZkJhM2g1Q3NNZjN3MTg2azFhT1FtcQprcHZRT2ZoR3FLK25uQXpXQld4V0d2NFAwUnVKSj
 l3RzhueWFSY1h3b21IaTJaQ2JPdGUzcFk1N3Y0Sitpb0VPCkJpV3dTWldyQ1JKdlArQmEvYTZBZ
 G1wMGo3VXJxclIyN1p6Ylc0djVzQ3hmTVpicwo9T2h5SAotLS0tLUVORCBQR1AgTUVTU0FHRS0t
 LS0tCg==
X-Developer-Key: i=Cryolitia@gmail.com; a=openpgp;
 fpr=1C3C6547538D7152310C0EEA84DD0C0130A54DF7
X-Endpoint-Received: by B4 Relay for Cryolitia@gmail.com/default with auth_id=186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add GPD fan driver document

Signed-off-by: Cryolitia PukNgae <Cryolitia@gmail.com>
---
 Documentation/hwmon/gpd-fan.rst | 69 +++++++++++++++++++++++++++++++++++++++++
 Documentation/hwmon/index.rst   |  1 +
 MAINTAINERS                     |  1 +
 3 files changed, 71 insertions(+)

diff --git a/Documentation/hwmon/gpd-fan.rst b/Documentation/hwmon/gpd-fan.rst
new file mode 100644
index 000000000000..01812386cad8
--- /dev/null
+++ b/Documentation/hwmon/gpd-fan.rst
@@ -0,0 +1,69 @@
+.. SPDX-License-Identifier: GPL-2.0-or-later
+
+Kernel driver gpd-fan
+=========================
+
+Author:
+    - Cryolitia PukNgae <Cryolitia@gmail.com>
+
+Description
+------------
+
+Handheld devices from GPD provide fan readings and fan control through
+their embedded controllers.
+
+Supported devices
+-----------------
+
+Currently the driver supports the following handhelds:
+
+ - GPD Win Mini (7840U)
+ - GPD Win Mini (8840U)
+ - GPD Win Max 2
+ - GPD Win Max 2 2023 (7840U)
+ - GPD Win Max 2 2024 (8840U)
+ - GPD Win 4 (6800U)
+ - GPD Win 4 (7840U)
+
+Module parameters
+-----------------
+
+gpd_fan_model
+  Force specific which module quirk should be used.
+  Use it like "gpd_fan_model=wm2".
+
+   - wm2
+       - GPD Win 4 (7840U)
+       - GPD Win Max 2 (6800U)
+       - GPD Win Max 2 2023 (7840U)
+       - GPD Win Max 2 2024 (8840U)
+   - win4
+       - GPD Win 4 (6800U)
+   - win_mini
+       - GPD Win Mini (7840U)
+       - GPD Win Mini (8840U)
+
+Sysfs entries
+-------------
+
+The following attributes are supported:
+
+fan1_input
+  Read Only. Reads current fan RPM.
+
+pwm1_enable
+  Read/Write. Enable manual fan control. Write "0" to disable control and run
+  full speed. Write "1" to set to manual, write "2" to let the EC control decide
+  fan speed. Read this attribute to see current status.
+
+pwm1
+  Read/Write. Read this attribute to see current duty cycle in the range [0-255].
+  When pwm1_enable is set to "1" (manual) write any value in the range [0-255]
+  to set fan speed.
+
+pwm1_mode
+  Read Only. Should always be "1" to indicate the fan being under PWM mode.
+
+update_interval
+  Read/Write. Set the interval in milliseconds to update fan speed. The default
+  and minimum time is 1 second
diff --git a/Documentation/hwmon/index.rst b/Documentation/hwmon/index.rst
index 913c11390a45..97add26f53b7 100644
--- a/Documentation/hwmon/index.rst
+++ b/Documentation/hwmon/index.rst
@@ -80,6 +80,7 @@ Hardware Monitoring Kernel Drivers
    gigabyte_waterforce
    gsc-hwmon
    gl518sm
+   gpd-fan
    gxp-fan-ctrl
    hih6130
    hp-wmi-sensors
diff --git a/MAINTAINERS b/MAINTAINERS
index 9ced72cec42b..5079b5bfe4b1 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -9376,6 +9376,7 @@ GPD FAN DRIVER
 M:	Cryolitia PukNgae <Cryolitia@gmail.com>
 L:	linux-hwmon@vger.kernel.org
 S:	Maintained
+F:	Documentation/hwmon/gpd-fan.rst
 F:	drivers/hwmon/gpd-fan.c
 
 GPD POCKET FAN DRIVER

-- 
2.45.2

