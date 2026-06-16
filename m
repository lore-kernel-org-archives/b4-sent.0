From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 16 Jun 2026 09:21:07 +0100
Subject: [PATCH v3 01/12] dt-bindings: iio: dac: ad5696: add
 reset/ldac/gain support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-ad5686-new-features-v3-1-f829fb7e9262@analog.com>
References: <20260616-ad5686-new-features-v3-0-f829fb7e9262@analog.com>
In-Reply-To: <20260616-ad5686-new-features-v3-0-f829fb7e9262@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781598070; l=2592;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=7Cug+QHjt1jD5xYv/KPDnzhbYiS8SoQ8CGYq1vLLIrg=;
 b=L055HawAj+bNyaqmwMRo4zS2BN+drP9SATPW5SENDRx5nrlqJEWTtNzD+qBNOQHCpwzg0CGRz
 3X1iUYHlR0xBi74iw9CEtJwm4pll81XpCDy7UnlgUs3qBe2tjzyNtZd
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
 .../devicetree/bindings/iio/dac/adi,ad5696.yaml    | 41 +++++++++++++++++++++-
 1 file changed, 40 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
index b5a88b03dc2f..c55158c464fd 100644
--- a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
@@ -37,14 +37,52 @@ properties:
     description: |
       The regulator supply for DAC reference voltage.
 
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
 
-additionalProperties: false
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            anyOf:
+              - const: adi,ad5311r
+              - const: adi,ad5691r
+              - const: adi,ad5692r
+              - const: adi,ad5693
+              - const: adi,ad5693r
+    then:
+      properties:
+        gain-gpios: false
+
+unevaluatedProperties: false
 
 examples:
   - |
+    #include <dt-bindings/gpio/gpio.h>
     i2c {
       #address-cells = <1>;
       #size-cells = <0>;
@@ -53,6 +91,7 @@ examples:
         compatible = "adi,ad5696";
         reg = <0>;
         vcc-supply = <&dac_vref>;
+        ldac-gpios = <&gpio0 1 GPIO_ACTIVE_LOW>;
       };
     };
 ...

-- 
2.43.0

