From: Andy Chung <Andy.Chung@amd.com>
Date: Tue, 14 Jul 2026 16:19:35 +0800
Subject: [PATCH 4/4] hwmon: (kb9002) Add documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-kb9002-upstream-v1-4-8fd2f0b135d8@amd.com>
References: <20260714-kb9002-upstream-v1-0-8fd2f0b135d8@amd.com>
In-Reply-To: <20260714-kb9002-upstream-v1-0-8fd2f0b135d8@amd.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Chung <andy.chung@amd.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 Andy Chung <Andy.Chung@amd.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784017234; l=3142;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=N49+QrvixV76oNVim+qejmy5UhGOUcqywymzDOcJACo=;
 b=J8pTjlGcewVJ2uWOgm1rGzZ5vNCgSsjQ4/Zo3/xaIYmypB6O33r4rcw7m3RnPnkQxhSeAR1go
 T1Ciw6+GTJHDZJ0v4rR4st3Bk0UgxZLHrW2ei9UCy1sXs3OSbBbiOzD
X-Developer-Key: i=Andy.Chung@amd.com; a=ed25519;
 pk=X2gaHRnhU2q5hvMjkC6xmIcC03vKNvHY9CQRdsj9ecM=
X-Endpoint-Received: by B4 Relay for Andy.Chung@amd.com/20260327 with auth_id=696
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the sysfs and debugfs interfaces of the Kandou KB9002 hwmon
driver.

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
---
 Documentation/hwmon/index.rst  |  1 +
 Documentation/hwmon/kb9002.rst | 65 ++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 66 insertions(+)

diff --git a/Documentation/hwmon/index.rst b/Documentation/hwmon/index.rst
index 226789376217..9dc796d087dc 100644
--- a/Documentation/hwmon/index.rst
+++ b/Documentation/hwmon/index.rst
@@ -112,6 +112,7 @@ Hardware Monitoring Kernel Drivers
    jc42
    k10temp
    k8temp
+   kb9002
    kbatt
    kfan
    lan966x
diff --git a/Documentation/hwmon/kb9002.rst b/Documentation/hwmon/kb9002.rst
new file mode 100644
index 000000000000..e6d8d9c78923
--- /dev/null
+++ b/Documentation/hwmon/kb9002.rst
@@ -0,0 +1,65 @@
+.. SPDX-License-Identifier: GPL-2.0-or-later
+
+Kernel driver kb9002
+====================
+
+Supported chips:
+
+  * Kandou KB9002
+
+    Prefix: 'kb9002'
+
+    Addresses scanned: -
+
+    Datasheet: KA-015171-PD (available from Kandou under NDA)
+
+Author: Andy Chung <andy.chung@amd.com>
+
+Description
+-----------
+
+The Kandou KB9002 is an 8-lane PCIe 5.0 retimer with an integrated
+microcontroller. It exposes an SMBus 3.0 target (with mandatory PEC)
+on its sideband interface. The internal firmware aggregates per-lane
+die temperatures and publishes the maximum value through a 16-bit
+addressed register window.
+
+This driver reports that aggregated maximum as the only hwmon
+temperature channel. The running firmware version and the firmware
+boot status are exposed under debugfs.
+
+sysfs interface
+---------------
+
+==================  ===============================================
+temp1_input         Aggregated maximum die temperature across all
+                    active lanes (millidegrees Celsius).
+temp1_label         Always "kb9002".
+==================  ===============================================
+
+debugfs interface
+-----------------
+
+Files live in the per-client debugfs directory created by the I2C
+core: ``/sys/kernel/debug/i2c/i2c-<bus>/<bus>-<addr>/``.
+
+==================  ===============================================
+fw_ver              Running firmware version in
+                    "major.minor.patch.suffix" format. Read-only.
+fw_load_status      Firmware boot status: "normal" once firmware has
+                    finished initialising, "abnormal" otherwise.
+                    Read-only.
+==================  ===============================================
+
+Notes
+-----
+
+The driver requires ``I2C_FUNC_SMBUS_BLOCK_DATA``,
+``I2C_FUNC_SMBUS_PEC`` and ``I2C_FUNC_I2C`` from the host adapter. The
+last is needed only during probe for the host-interface mode switch;
+runtime accesses use SMBus block transactions exclusively.
+
+The retimer's SMBus address is configurable on three strap pins and
+ranges from 0x20 to 0x27. The address is selected through device tree
+(or i2c board info) the same way as any other I2C device; the driver
+does not auto-detect.

-- 
2.34.1

