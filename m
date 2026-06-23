From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 23 Jun 2026 11:55:43 +0100
Subject: [PATCH v4 03/12] dt-bindings: iio: dac: ad5686: add
 reset/ldac/gain support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260623-ad5686-new-features-v4-3-28962a57db0f@analog.com>
References: <20260623-ad5686-new-features-v4-0-28962a57db0f@analog.com>
In-Reply-To: <20260623-ad5686-new-features-v4-0-28962a57db0f@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782212158; l=2649;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=tqSguVcv0F+ri4HoEKx7VIIb7gTICL++YlTges0Sc4s=;
 b=OBYuG73TFLFunnmvJqy7wCJHlF3zHlxn+91h7/5P4xBJJWim9yT7FpoMgGXyZD9Hl4Y5WwHXg
 u2oMG8X12PrDJbFkm1T5icju3b+nzXgC9tI8iYolcP4cwqDI1HqRAbq
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add GPIO property for RESET, LDAC and GAIN pin. RESET is active-low, LDAC
is used to load DAC channels with values from input registers and GAIN
can double the voltage in output channels. The gain-gpios property is
not available to all supported parts. The adi,range-double property
indicates that GAIN pin is hardwired to high in case gain-gpios is not
set, otherwise it sets the initial value for the gain setting.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../devicetree/bindings/iio/dac/adi,ad5686.yaml    | 38 ++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml
index 713f535bb33a..d781baca6a6c 100644
--- a/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml
@@ -35,17 +35,53 @@ properties:
   vcc-supply:
     description: If not supplied the internal reference is used.
 
+  reset-gpios:
+    description: Active-low RESET pin to reset the device.
+    maxItems: 1
+
+  ldac-gpios:
+    description:
+      Active-low LDAC pin used to asynchronously update the DAC channels.
+    maxItems: 1
+
+  gain-gpios:
+    description:
+      GAIN pin that sets a multiplier for the DAC output voltage. When high,
+      the DAC output voltage is multiplied by 2, otherwise it is unchanged.
+    maxItems: 1
+
+  adi,range-double:
+    description:
+      Sets the initial voltage output range from 0 to 2xVREF. On devices that
+      have a GAIN pin and no gain-gpios property is set, this indicates the pin
+      is hardwired high.
+    type: boolean
+
 required:
   - compatible
   - reg
 
 allOf:
   - $ref: /schemas/spi/spi-peripheral-props.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - adi,ad5310r
+              - adi,ad5681r
+              - adi,ad5682r
+              - adi,ad5683
+              - adi,ad5683r
+    then:
+      properties:
+        gain-gpios: false
 
 unevaluatedProperties: false
 
 examples:
   - |
+    #include <dt-bindings/gpio/gpio.h>
     spi {
         #address-cells = <1>;
         #size-cells = <0>;
@@ -53,6 +89,8 @@ examples:
             reg = <0>;
             compatible = "adi,ad5310r";
             vcc-supply = <&dac_vref0>;
+            reset-gpios = <&gpio0 0 GPIO_ACTIVE_LOW>;
+            ldac-gpios = <&gpio0 1 GPIO_ACTIVE_LOW>;
         };
     };
 ...

-- 
2.43.0

