From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 22 Apr 2026 15:45:36 +0100
Subject: [PATCH 02/22] dt-bindings: iio: dac: ad5696: add reset/ldac/gain
 gpio support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-ad5313r-iio-support-v1-2-ed7dca001d1b@analog.com>
References: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
In-Reply-To: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
To: Jonathan Cameron <jic23@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michael Auchter <michael.auchter@ni.com>, linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776869181; l=2120;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=qDXGr5kPMnSg1mp9xsUjZzi2MmbbEF4H1bMQgp9WLN8=;
 b=bpuElbtlIoGVy8C+o2ClPMb+s+UJ3cemjXyCpnj2XRDCW4ClPHKJlJog5ww0mtC+E1UVG/NMZ
 15N6u890yWbCYrReNGIe6UVcomjnaI5bbRVqNvKEQAdzNTbSIT0Jx/y
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add GPIO property for RESET, LDAC and GAIN pin. RESET is active-low, LDAC
is used to load DAC channels with values from input registers and GAIN
can double the voltage in output channels. The gain-gpios property is
not available to all supported parts.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../devicetree/bindings/iio/dac/adi,ad5696.yaml    | 34 +++++++++++++++++++++-
 1 file changed, 33 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
index ed79323bfc93..f286e5072abc 100644
--- a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
@@ -42,14 +42,45 @@ properties:
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
@@ -58,6 +89,7 @@ examples:
         compatible = "adi,ad5696";
         reg = <0>;
         vcc-supply = <&dac_vref>;
+        ldac-gpios = <&gpio0 1 GPIO_ACTIVE_LOW>;
       };
     };
 ...

-- 
2.43.0

