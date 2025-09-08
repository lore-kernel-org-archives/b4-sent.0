From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Mon, 08 Sep 2025 10:25:45 +0800
Subject: [PATCH v9 2/2] hwmon: document: add gpd-fan
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250908-gpd_fan-v9-2-7b4506c03953@uniontech.com>
References: <20250908-gpd_fan-v9-0-7b4506c03953@uniontech.com>
In-Reply-To: <20250908-gpd_fan-v9-0-7b4506c03953@uniontech.com>
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Jonathan Corbet <corbet@lwn.net>, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-doc@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>, 
 Yao Zi <ziyao@disroot.org>, Derek John Clark <derekjohn.clark@gmail.com>, 
 Jun Zhan <zhanjun@uniontech.com>, Cheng Nie <niecheng1@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757298351; l=3651;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=XJBaOZygIlHycO8BeXsmyRPcKndp0Zqqqn5Kg3pQ5T0=;
 b=qBznmcyRfPSdCHkxXtonLTap0YL4ULYMFkQDkYxMLZhjamDoZ9QXBldXz6xHA3arpPvGK1xSX
 Gbsr08fBfS2BszBtqwTCWyNyKAx73VpRpBLWVnACwP8/9RbKK4qHYFs
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add GPD fan driver document

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 Documentation/hwmon/gpd-fan.rst | 78 +++++++++++++++++++++++++++++++++++++++++
 Documentation/hwmon/index.rst   |  1 +
 MAINTAINERS                     |  1 +
 3 files changed, 80 insertions(+)

diff --git a/Documentation/hwmon/gpd-fan.rst b/Documentation/hwmon/gpd-fan.rst
new file mode 100644
index 0000000000000000000000000000000000000000..0b56b70e6264ddccaa4d84b326841c8f63b43a39
--- /dev/null
+++ b/Documentation/hwmon/gpd-fan.rst
@@ -0,0 +1,78 @@
+.. SPDX-License-Identifier: GPL-2.0-or-later
+
+Kernel driver gpd-fan
+=========================
+
+Author:
+    - Cryolitia PukNgae <cryolitia@uniontech.com>
+
+Description
+------------
+
+Handheld devices from Shenzhen GPD Technology Co., Ltd. provide fan readings
+and fan control through their embedded controllers.
+
+Supported devices
+-----------------
+
+Currently the driver supports the following handhelds:
+
+ - GPD Win Mini (7840U)
+ - GPD Win Mini (8840U)
+ - GPD Win Mini (HX370)
+ - GPD Pocket 4
+ - GPD Duo
+ - GPD Win Max 2 (6800U)
+ - GPD Win Max 2 2023 (7840U)
+ - GPD Win Max 2 2024 (8840U)
+ - GPD Win Max 2 2025 (HX370)
+ - GPD Win 4 (6800U)
+ - GPD Win 4 (7840U)
+
+Module parameters
+-----------------
+
+gpd_fan_board
+  Force specific which module quirk should be used.
+  Use it like "gpd_fan_board=wm2".
+
+   - wm2
+       - GPD Win 4 (7840U)
+       - GPD Win Max 2 (6800U)
+       - GPD Win Max 2 2023 (7840U)
+       - GPD Win Max 2 2024 (8840U)
+       - GPD Win Max 2 2025 (HX370)
+   - win4
+       - GPD Win 4 (6800U)
+   - win_mini
+       - GPD Win Mini (7840U)
+       - GPD Win Mini (8840U)
+       - GPD Win Mini (HX370)
+       - GPD Pocket 4
+       - GPD Duo
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
+  at full speed. Write "1" to set to manual, write "2" to let the EC control
+  decide fan speed. Read this attribute to see current status.
+
+  NB：In consideration of the safety of the device, when setting to manual mode,
+  the pwm speed will be set to the maximum value (255) by default. You can set
+  a different value by writing pwm1 later.
+
+pwm1
+  Read/Write. Read this attribute to see current duty cycle in the range
+  [0-255]. When pwm1_enable is set to "1" (manual) write any value in the
+  range [0-255] to set fan speed.
+
+  NB: Many boards (except listed under wm2 above) don't support reading the
+  current pwm value in auto mode. That will just return EOPNOTSUPP. In manual
+  mode it will always return the real value.
diff --git a/Documentation/hwmon/index.rst b/Documentation/hwmon/index.rst
index d292a86ac5da902cad02c1965c90f5de530489df..ce4419f064e1368740387af70af38a85cadd952d 100644
--- a/Documentation/hwmon/index.rst
+++ b/Documentation/hwmon/index.rst
@@ -82,6 +82,7 @@ Hardware Monitoring Kernel Drivers
    gigabyte_waterforce
    gsc-hwmon
    gl518sm
+   gpd-fan
    gxp-fan-ctrl
    hih6130
    hp-wmi-sensors
diff --git a/MAINTAINERS b/MAINTAINERS
index 14a616be5ff08aaeee52436dff54a86c4a81e5fb..0b6ae95c2007f0737bc4a4e1f2bac52f71628f78 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -10425,6 +10425,7 @@ GPD FAN DRIVER
 M:	Cryolitia PukNgae <cryolitia@uniontech.com>
 L:	linux-hwmon@vger.kernel.org
 S:	Maintained
+F:	Documentation/hwmon/gpd-fan.rst
 F:	drivers/hwmon/gpd-fan.c
 
 GPD POCKET FAN DRIVER

-- 
2.51.0

