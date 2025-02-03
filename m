From: Tobias Sperling <tobias.sperling@softing.com>
Date: Mon, 03 Feb 2025 17:27:34 +0100
Subject: [PATCH v2 1/2] dt-bindings: iio: adc: Introduce ADS7138
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250203-adc_ml-v2-1-8a597660c395@softing.com>
References: <20250203-adc_ml-v2-0-8a597660c395@softing.com>
In-Reply-To: <20250203-adc_ml-v2-0-8a597660c395@softing.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Tobias Sperling <tobias.sperling@softing.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.15-dev-355e8
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738600069; l=2570;
 i=tobias.sperling@softing.com; s=20241122; h=from:subject:message-id;
 bh=OmyOmU49Tz1XrsAj9x+7MhVBICvzllgrTbFg4A067Vw=;
 b=MDHxEkxPXoj9vT/XalU8a15PJKhH0+FjFtE6rkAtkTEV7IDoTBPKqLPSG4fUq/MlhTHRTiGVc
 0/YafsLXPxhCWmXMmLMU+Z31nOPnScK5EAA9qoOXoaB4Jer0gJEQ1qg
X-Developer-Key: i=tobias.sperling@softing.com; a=ed25519;
 pk=v7hgaMHsrA9ul4UXkBVUuwusS9PF3uHW/CC+gABI65E=
X-Endpoint-Received: by B4 Relay for tobias.sperling@softing.com/20241122 with auth_id=281
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for the driver of ADS7128 and ADS7138 12-bit, 8-channel
analog-to-digital converters. These ADCs have a wide operating range and
a wide feature set. Communication is based on the I2C interface.
ADS7128 differs in the addition of further hardware features, like a
root-mean-square (RMS) and a zero-crossing-detect (ZCD) module.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Tobias Sperling <tobias.sperling@softing.com>
---
 .../devicetree/bindings/iio/adc/ti,ads7138.yaml    | 62 ++++++++++++++++++++++
 1 file changed, 62 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/ti,ads7138.yaml b/Documentation/devicetree/bindings/iio/adc/ti,ads7138.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..c73057df6d8a56230a69978a7f673045f17a276b
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/adc/ti,ads7138.yaml
@@ -0,0 +1,62 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/adc/ti,ads7138.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Texas Instruments ADS7128/ADS7138 analog-to-digital converter (ADC)
+
+maintainers:
+  - Tobias Sperling <tobias.sperling@softing.com>
+
+description: |
+  The ADS7128 and ADS7138 chips are 12-bit, 8 channel analog-to-digital
+  converters (ADC) with build-in digital window comparator (DWC), using the
+  I2C interface.
+  ADS7128 differs in the addition of further hardware features, like a
+  root-mean-square (RMS) and a zero-crossing-detect (ZCD) module.
+
+  Datasheets:
+    https://www.ti.com/product/ADS7128
+    https://www.ti.com/product/ADS7138
+
+properties:
+  compatible:
+    enum:
+      - ti,ads7128
+      - ti,ads7138
+
+  reg:
+    maxItems: 1
+
+  avdd-supply:
+    description:
+      The regulator used as analog supply voltage as well as reference voltage.
+
+  interrupts:
+    description:
+      Interrupt on ALERT pin, triggers on low level.
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
+    #include <dt-bindings/interrupt-controller/irq.h>
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        adc@10 {
+            compatible = "ti,ads7138";
+            reg = <0x10>;
+            avdd-supply = <&reg_stb_3v3>;
+            interrupt-parent = <&gpio2>;
+            interrupts = <12 IRQ_TYPE_LEVEL_LOW>;
+        };
+    };
+...

-- 
2.34.1

