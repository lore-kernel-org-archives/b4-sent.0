From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 22 Apr 2026 15:45:40 +0100
Subject: [PATCH 06/22] dt-bindings: iio: dac: ad5686: rework on power
 supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-ad5313r-iio-support-v1-6-ed7dca001d1b@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776869181; l=1922;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=9yk2gkX45ghKrgYSGht1grG7IvZtcYAKJWf3zLMMNP4=;
 b=dcBqGtLLVkbxf4wEq7VPlN9iVaG0HiLPdYiiUkS9NeZGHpveLr/vt4Lbdz7p1ltswxjyeDR3G
 nAN4LC5D/vfCmOzorRCWQNWxC15iFdmcs6icw4r37pUpeBeCcHf1FLk
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add supplies for VDD, VLOGIC and VREF input voltage pins. The vcc-supply
property is deprecated. Certain devices require vref-supply to be
available once an internal reference voltage is absent. Still, this patch
does not add those as 'required' so that the ABI is not broken.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../devicetree/bindings/iio/dac/adi,ad5686.yaml      | 20 ++++++++++++++++++--
 1 file changed, 18 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml
index 543ee181f7b3..3292d5190b70 100644
--- a/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml
@@ -40,8 +40,22 @@ properties:
   reg:
     maxItems: 1
 
+  vdd-supply:
+    description: Input power supply.
+
+  vlogic-supply:
+    description:
+      Digital power supply. If not supplied, it is assumed to be the same as
+      vdd-supply. VLOGIC may be hardwired to VDD in some board designs or
+      internally connected in small packages.
+
+  vref-supply:
+    description:
+      Reference voltage supply. If not supplied the internal reference is used.
+
   vcc-supply:
-    description: If not supplied the internal reference is used.
+    deprecated: true
+    description: Use vref-supply instead.
 
   reset-gpios:
     description: Active-low RESET pin to reset the device.
@@ -89,7 +103,9 @@ examples:
         dac@0 {
             reg = <0>;
             compatible = "adi,ad5310r";
-            vcc-supply = <&dac_vref0>;
+            vdd-supply = <&dac_vdd>;
+            vlogic-supply = <&dac_vlogic>;
+            vref-supply = <&dac_vref>;
             reset-gpios = <&gpio0 0 GPIO_ACTIVE_LOW>;
             ldac-gpios = <&gpio0 1 GPIO_ACTIVE_LOW>;
         };

-- 
2.43.0

