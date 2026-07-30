From: Andy Chung <Andy.Chung@amd.com>
Date: Thu, 30 Jul 2026 17:07:59 +0800
Subject: [PATCH linux dev-6.18 4/4] hwmon: (kb9002) Add documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-kb9002-backport-v1-4-41f472e52215@amd.com>
References: <20260730-kb9002-backport-v1-0-41f472e52215@amd.com>
In-Reply-To: <20260730-kb9002-backport-v1-0-41f472e52215@amd.com>
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Andy Chung <Andy.Chung@amd.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785402478; l=3238;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=Cs3I2lHt4yFot07JU10N1d1mkW1cQdIYWwy95kNiqTw=;
 b=+ZFFSx80+aocXw/dg2GHNRt+kCfz5VI2cMVgIFf1wIxUBUA55MzCUUKPGQf6sqU4QLyUfUUcn
 2m+Qd7ie9Z9AoqWoND47sMPx//RlZ0Q3R96c0LhdDAbBfTfphbk+x+y
X-Developer-Key: i=Andy.Chung@amd.com; a=ed25519;
 pk=X2gaHRnhU2q5hvMjkC6xmIcC03vKNvHY9CQRdsj9ecM=
X-Endpoint-Received: by B4 Relay for Andy.Chung@amd.com/20260327 with auth_id=696
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the sysfs and debugfs interfaces of the Kandou KB9002 hwmon
driver.

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
Link: https://lore.kernel.org/r/20260724-kb9002-upstream-v5-4-9523c3ffe83a@amd.com
Signed-off-by: Guenter Roeck <linux@roeck-us.net>
---
 Documentation/hwmon/index.rst  |  1 +
 Documentation/hwmon/kb9002.rst | 64 ++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 65 insertions(+)

diff --git a/Documentation/hwmon/index.rst b/Documentation/hwmon/index.rst
index c5ab1aa5d416..f115f9f4c181 100644
--- a/Documentation/hwmon/index.rst
+++ b/Documentation/hwmon/index.rst
@@ -108,6 +108,7 @@ Hardware Monitoring Kernel Drivers
    jc42
    k10temp
    k8temp
+   kb9002
    kbatt
    kfan
    lan966x
diff --git a/Documentation/hwmon/kb9002.rst b/Documentation/hwmon/kb9002.rst
new file mode 100644
index 000000000000..6f8116dde918
--- /dev/null
+++ b/Documentation/hwmon/kb9002.rst
@@ -0,0 +1,64 @@
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

