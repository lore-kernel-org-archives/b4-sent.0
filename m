From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Sat, 28 Nov 2026 00:38:56 +0100
Subject: [PATCH v4 1/2] dt-bindings: iio: light: Add Capella CM3217
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-upstream-iio-cm3217-v4-1-fdab04f40bbc@tsv-stahl-riesa.de>
References: <20261128-upstream-iio-cm3217-v4-0-fdab04f40bbc@tsv-stahl-riesa.de>
In-Reply-To: <20261128-upstream-iio-cm3217-v4-0-fdab04f40bbc@tsv-stahl-riesa.de>
To: Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Kevin Tsai <ktsai@capellamicro.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795822755; l=2057;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=Qf+hCvwfO7ANZ6gJHm3yJLRxcLVAWMuBfi8uqq1FrSU=;
 b=ET6cguaw50TINTCrvqJ0WxCmlUlUfzsa+/FSgLA7x/WEklrg3cjdLmQYKTx+d0ZCvAbWRRD5t
 tcr9HXGiQYnB5UEK39yNy55SiiwTn75RwHKXxQWRNL9vdEQMCq8CkTR
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Capella CM3217 is an ambient light sensor with an I2C interface but
without registers and without an interrupt line. It always answers on
the two fixed addresses 0x10 and 0x11, which are both listed in reg.

The sensor is used in the NVIDIA Tegra Note 7 and the NVIDIA Shield
Tablet.

Tool use: Claude Code wrote this binding.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 .../bindings/iio/light/capella,cm3217.yaml         | 49 ++++++++++++++++++++++
 1 file changed, 49 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/capella,cm3217.yaml b/Documentation/devicetree/bindings/iio/light/capella,cm3217.yaml
new file mode 100644
index 000000000000..a03cdf2bd375
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/light/capella,cm3217.yaml
@@ -0,0 +1,49 @@
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
+  The CM3217 is an I2C ambient light sensor.
+
+properties:
+  compatible:
+    const: capella,cm3217
+
+  reg:
+    items:
+      - description:
+          Command byte 1 (shutdown and IT_T) on write, high byte of the light
+          count on read. Fixed at 0x10.
+      - description:
+          Command byte 2 (FD_IT) on write, low byte of the light count on
+          read. Fixed at 0x11.
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
+            reg = <0x10>, <0x11>;
+            vdd-supply = <&vdd_2v85_sen>;
+        };
+    };
+...

-- 
2.56.1

