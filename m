From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Sun, 01 Nov 2026 15:46:06 +0100
Subject: [PATCH 1/2] dt-bindings: iio: light: Add Capella CM3217
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-upstream-iio-cm3217-v1-1-5e1724cae7b7@tsv-stahl-riesa.de>
References: <20261101-upstream-iio-cm3217-v1-0-5e1724cae7b7@tsv-stahl-riesa.de>
In-Reply-To: <20261101-upstream-iio-cm3217-v1-0-5e1724cae7b7@tsv-stahl-riesa.de>
To: Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Kevin Tsai <ktsai@capellamicro.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793544375; l=1847;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=DRsA8LrGGGchvF8FpCFYONWWJwxVpYsv7ZwhqvhN1Oo=;
 b=VSrV1z5oB0nvlFENH52PtDcThkAqDcLjbK2YH3sepafcsh2zRwhs1q2ZZcZYxzX+AM8r7nQ+g
 QgZpwmO/UvFCQOD7VnXySogZXTIkgvABxGZQc25PzAxqpwKu79DWqI4
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Capella CM3217 is an ambient light sensor with an I2C interface but
without registers and without an interrupt line. It always answers on
the two addresses 0x10 and 0x11. The node describes the first address;
the second one is fixed and claimed by the driver.

The sensor is used in the NVIDIA Tegra Note 7 and the NVIDIA Shield
Tablet.

Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 .../bindings/iio/light/capella,cm3217.yaml         | 45 ++++++++++++++++++++++
 1 file changed, 45 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/capella,cm3217.yaml b/Documentation/devicetree/bindings/iio/light/capella,cm3217.yaml
new file mode 100644
index 000000000000..b2ddb14d657b
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/light/capella,cm3217.yaml
@@ -0,0 +1,45 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/light/capella,cm3217.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Capella CM3217 ambient light sensor
+
+maintainers:
+  - Patrick Fischer <admin@tsv-stahl-riesa.de>
+
+description:
+  The CM3217 is an I2C ambient light sensor without registers or interrupt
+  line. It always occupies the two I2C addresses 0x10 and 0x11; the node
+  describes the first one.
+
+properties:
+  compatible:
+    const: capella,cm3217
+
+  reg:
+    const: 0x10
+
+  vdd-supply: true
+
+required:
+  - compatible
+  - reg
+  - vdd-supply
+
+additionalProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        light-sensor@10 {
+            compatible = "capella,cm3217";
+            reg = <0x10>;
+            vdd-supply = <&vdd_2v85_sen>;
+        };
+    };
+...

-- 
2.56.0

