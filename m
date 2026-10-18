From: Igor Velkov <iav@iav.lv>
Date: Sun, 18 Oct 2026 07:54:59 +0300
Subject: [PATCH 1/2] dt-bindings: hwmon: pwm-fan: Reference the common fan
 schema
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-helios64-fan-label-v1-1-69a3f96d4efa@iav.lv>
References: <20261018-helios64-fan-label-v1-0-69a3f96d4efa@iav.lv>
In-Reply-To: <20261018-helios64-fan-label-v1-0-69a3f96d4efa@iav.lv>
To: Guenter Roeck <linux@roeck-us.net>, Jean Delvare <jdelvare@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2256; i=iav@iav.lv;
 h=from:subject:message-id; bh=qUXxvAxXaQVads84aZrFPPsu7N7+O4+7hDtPOHnoLsA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlXAnW6rne+PmWWPE+rS8fks8WRg2tay/6tq3q6xGvf/
 SstFYtTO0pZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBE8jcy/FM/t5ZBc7bC86/b
 vp8plRS1uBv+Zfb1cOlEhW7LmXPZ9NMZ/kesmrO6xvuzxpvQFRZFe1/53lfgZJ3xVq7dzrnScKr
 AZi4A
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pwm-fan predates fan-common.yaml and repeats several of its properties.
Reference the common schema, drop the duplicated properties and keep
only the constraints specific to PWM fans.

This also allows label, which the hwmon core exposes as the label
attribute.

Link: https://lore.kernel.org/r/20250106173805.GA501301-robh@kernel.org
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 .../devicetree/bindings/hwmon/pwm-fan.yaml         | 22 +++++-----------------
 1 file changed, 5 insertions(+), 17 deletions(-)

diff --git a/Documentation/devicetree/bindings/hwmon/pwm-fan.yaml b/Documentation/devicetree/bindings/hwmon/pwm-fan.yaml
index 6a24851fd80d..b5407ed52976 100644
--- a/Documentation/devicetree/bindings/hwmon/pwm-fan.yaml
+++ b/Documentation/devicetree/bindings/hwmon/pwm-fan.yaml
@@ -10,19 +10,18 @@ maintainers:
   - Jean Delvare <jdelvare@suse.com>
   - Guenter Roeck <linux@roeck-us.net>
 
+allOf:
+  - $ref: fan-common.yaml#
+
 properties:
   compatible:
     const: pwm-fan
 
   cooling-levels:
     description: PWM duty cycle values corresponding to thermal cooling states.
-    $ref: /schemas/types.yaml#/definitions/uint32-array
     items:
       maximum: 255
 
-  fan-supply:
-    description: Phandle to the regulator that provides power to the fan.
-
   interrupts:
     description:
       This contains an interrupt specifier for each fan tachometer output
@@ -51,26 +50,14 @@ properties:
       Time to wait in microseconds after start when stopped.
 
   pulses-per-revolution:
-    description:
-      Define the number of pulses per fan revolution for each tachometer
-      input as an integer.
-    $ref: /schemas/types.yaml#/definitions/uint32
     minimum: 1
-    maximum: 4
     default: 2
 
-  pwms:
-    description: The PWM that is used to control the fan.
-    maxItems: 1
-
-  "#cooling-cells":
-    const: 2
-
 required:
   - compatible
   - pwms
 
-additionalProperties: false
+unevaluatedProperties: false
 
 examples:
   - |
@@ -114,4 +101,5 @@ examples:
       interrupt-parent = <&gpio5>;
       interrupts = <1 IRQ_TYPE_EDGE_FALLING>;
       pulses-per-revolution = <2>;
+      label = "CPU fan";
     };

-- 
2.43.0

