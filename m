From: Colin Huang <u8813345@gmail.com>
Date: Wed, 29 Apr 2026 17:41:58 +0800
Subject: [PATCH 1/3] dt-bindings: hwmon: pmbus: add Delta E50SN12051
 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-add-e50sn12051-v1-1-c101e6c80bbb@gmail.com>
References: <20260429-add-e50sn12051-v1-0-c101e6c80bbb@gmail.com>
In-Reply-To: <20260429-add-e50sn12051-v1-0-c101e6c80bbb@gmail.com>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kevin Chang <kevin.chang2@amd.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777455724; l=1513;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=4ai3gQorriR95uJn5LyCKNAUfjhgHd9lSkC+s7TUrI8=;
 b=a221JMOGHN2o9wbB6pOEIlq4J//kGnqL99ROnMmLVkYapRPebeu8B5/gLt0jB3dJyj2OVUXZJ
 7QYkvSSrVMVA4OlYnv8JNf/p0vdGTO3wzfFuzrW6NUHSYia97vwZeyf
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding documentation for the Delta E50SN12051
PMBus-compliant device.

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
 .../bindings/hwmon/pmbus/delta,e50sn12051.yaml     | 40 ++++++++++++++++++++++
 1 file changed, 40 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/pmbus/delta,e50sn12051.yaml b/Documentation/devicetree/bindings/hwmon/pmbus/delta,e50sn12051.yaml
new file mode 100644
index 000000000000..362cbbf10bfe
--- /dev/null
+++ b/Documentation/devicetree/bindings/hwmon/pmbus/delta,e50sn12051.yaml
@@ -0,0 +1,40 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
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
+  This binding describes the Delta E50SN12051 PMBus sensor.
+  The driver supports reading voltage, current, and temperature
+  using the PMBus interface.
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
+        e50sn12051@40 {
+            compatible = "delta,e50sn12051";
+            reg = <0x40>;
+        };
+    };

-- 
2.34.1

