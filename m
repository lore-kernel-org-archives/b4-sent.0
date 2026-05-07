From: Colin Huang <u8813345@gmail.com>
Date: Thu, 07 May 2026 13:12:26 +0800
Subject: [PATCH v4 1/3] dt-bindings: hwmon: pmbus: add Delta E50SN12051
 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260507-add-e50sn12051-v4-1-ff2b3768ac7e@gmail.com>
References: <20260507-add-e50sn12051-v4-0-ff2b3768ac7e@gmail.com>
In-Reply-To: <20260507-add-e50sn12051-v4-0-ff2b3768ac7e@gmail.com>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kevin Chang <kevin.chang2@amd.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778130752; l=1608;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=LsFD1WB8cxVjFqAQavi/vJOUq3ztpTJc2Fdx31QeHU8=;
 b=4NS/ybOabUG3+V2P0oSOL1ps+nIvcGkTNqJgHgyue+rBFC199HBt1GzcJdm2eDOqYInD8wgtm
 n+Ir/xejrHWASDuy9Q3aUwt42DWGOI9pkJJZnSBPXeBKQ+FgIfVHbtT
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding documentation for the Delta E50SN12051
PMBus-compliant device.

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
 .../bindings/hwmon/pmbus/delta,e50sn12051.yaml     | 42 ++++++++++++++++++++++
 1 file changed, 42 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/pmbus/delta,e50sn12051.yaml b/Documentation/devicetree/bindings/hwmon/pmbus/delta,e50sn12051.yaml
new file mode 100644
index 000000000000..72aefe212d17
--- /dev/null
+++ b/Documentation/devicetree/bindings/hwmon/pmbus/delta,e50sn12051.yaml
@@ -0,0 +1,42 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/hwmon/pmbus/delta,e50sn12051.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Delta E50SN12051 PMBus Sensor
+
+maintainers:
+  - Kevin Chang <kevin.chang2@amd.com>
+
+description: |
+  Delta E50SN12051 is a non-isolated 1/8th brick DC-DC power module.
+  It is a PMBus-compliant device accessible via an I2C/SMBus interface
+  and provides standard telemetry such as voltage, current, and
+  temperature measurements.
+
+properties:
+  compatible:
+    const: delta,e50sn12051
+
+  reg:
+    maxItems: 1
+    description: I2C bus address of the PMBus device
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        power-module@40 {
+            compatible = "delta,e50sn12051";
+            reg = <0x40>;
+        };
+    };

-- 
2.34.1

