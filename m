From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Date: Mon, 28 Apr 2025 12:50:13 +0200
Subject: [PATCH 1/2] dt-bindings: iio: chemical: Document SEN0322
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250428-iio-chemical-sen0322-v1-1-9b18363ffe42@gmail.com>
References: <20250428-iio-chemical-sen0322-v1-0-9b18363ffe42@gmail.com>
In-Reply-To: <20250428-iio-chemical-sen0322-v1-0-9b18363ffe42@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745837432; l=1418;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=0xoZK3utDzrQmadpl8iAFzEdDReFTnsvqPVnBKUfQhE=;
 b=gcjxH5FV6xoBddG8KX8yGpC+BYXKxA+r2MBnFPA0kEZ0bO/lhMjI2cyKcg286Is61lO2TMqLN
 yFi3gDFnqn3CG0ZtmO2pXR7YJqgdXtJL4qMWZEIj6POgdLliYXegYRd
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for the DFRobot SEN0322 oxygen sensor.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
 .../bindings/iio/chemical/dfrobot,sen0322.yaml     | 41 ++++++++++++++++++++++
 1 file changed, 41 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/chemical/dfrobot,sen0322.yaml b/Documentation/devicetree/bindings/iio/chemical/dfrobot,sen0322.yaml
new file mode 100644
index 000000000000..9410d04fb91d
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/chemical/dfrobot,sen0322.yaml
@@ -0,0 +1,41 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/chemical/dfrobot,sen0322.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: DFRobot SEN0322 oxygen sensor
+
+maintainers:
+  - Tóth János <gomba007@gmail.com>
+
+description: >
+  DFRobot SEN0322 is an oxygen sensor. It supports I2C for communication.
+
+  Datasheet:
+    https://wiki.dfrobot.com/Gravity_I2C_Oxygen_Sensor_SKU_SEN0322
+
+properties:
+  compatible:
+    const: dfrobot,sen0322
+
+  reg:
+    maxItems: 1
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
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      sen0322@73 {
+        compatible = "dfrobot,sen0322";
+        reg = <0x73>;
+      };
+    };

-- 
2.34.1

