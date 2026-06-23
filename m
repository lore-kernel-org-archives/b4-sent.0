From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 23 Jun 2026 11:55:42 +0100
Subject: [PATCH v4 02/12] dt-bindings: iio: dac: ad5696: rework on power
 supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260623-ad5686-new-features-v4-2-28962a57db0f@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782212158; l=2556;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=M2ZxcKplq9dYBzPvJ4Kk2806O8GaXfgsF0JAQRB+TJs=;
 b=Tj/qTi1p5DdFHOViHzZH1raVk/h6R+VDZAk2oeiBbIpA2PdTF+ZOQyih1xOkcf0iLY09umcmJ
 X/Ut76t+787CqjfQZjNX6+9xky+lhGpp92hA/Mku9IPoMpIwvW2Cl2f
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add supplies for VDD, VLOGIC and VREF input voltage pins. The vcc-supply
property is deprecated, once it does not really exist as none of the
devices describe any power input with that name. VCC is also misleading as
it sounds like the input power supply, but it is being used as an external
voltage reference, which should be called VREF. Certain devices require
vref-supply to be available once an internal reference voltage is absent.
For correct operation vdd and vlogic supplies are required.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../devicetree/bindings/iio/dac/adi,ad5696.yaml    | 34 ++++++++++++++++++++--
 1 file changed, 31 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
index cc343cdf6085..e10f8596f9d3 100644
--- a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
@@ -33,9 +33,22 @@ properties:
   reg:
     maxItems: 1
 
+  vdd-supply:
+    description: Input power supply.
+
+  vlogic-supply:
+    description:
+      Digital power supply. On some tiny package variants for single-channel
+      devices, this supply is internally connected to vdd; in that case, specify
+      this property with the same regulator as vdd.
+
+  vref-supply:
+    description:
+      Reference voltage supply. If not supplied the internal reference is used.
+
   vcc-supply:
-    description: |
-      The regulator supply for DAC reference voltage.
+    deprecated: true
+    description: Use vref-supply instead.
 
   reset-gpios:
     description: Active-low RESET pin to reset the device.
@@ -62,8 +75,21 @@ properties:
 required:
   - compatible
   - reg
+  - vdd-supply
+  - vlogic-supply
 
 allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - adi,ad5693
+              - adi,ad5694
+              - adi,ad5696
+    then:
+      required:
+        - vref-supply
   - if:
       properties:
         compatible:
@@ -90,7 +116,9 @@ examples:
       ad5696: dac@0 {
         compatible = "adi,ad5696";
         reg = <0>;
-        vcc-supply = <&dac_vref>;
+        vdd-supply = <&dac_vdd>;
+        vlogic-supply = <&dac_vlogic>;
+        vref-supply = <&dac_vref>;
         ldac-gpios = <&gpio0 1 GPIO_ACTIVE_LOW>;
       };
     };

-- 
2.43.0

