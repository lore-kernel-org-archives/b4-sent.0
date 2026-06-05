From: Herman van Hazendonk <github.com@herrie.org>
Date: Fri, 05 Jun 2026 11:18:12 +0200
Subject: [PATCH v2 1/2] dt-bindings: power: supply: maxim,max8903: add DC
 and USB input current-limit controls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-submit-power-max8903-dc-limit-v2-1-0c5396e98f14@herrie.org>
References: <20260605-submit-power-max8903-dc-limit-v2-0-0c5396e98f14@herrie.org>
In-Reply-To: <20260605-submit-power-max8903-dc-limit-v2-0-0c5396e98f14@herrie.org>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780651091; l=4290;
 i=github.com@herrie.org; s=20240417; h=from:subject:message-id;
 bh=y3jq3IEz6lBQ6Jj7RCPl1bWyp4QEaitytOHy869VV20=;
 b=2zDwl8KSheKDn+M1O1+82K2Lx0OMt5lwY7UEerjIFfVmedaoT4A3cf0fFVKwLdTk4sMaRhTdc
 bBsErrda6ceA2w2qqX+0lH4uKdlnfsJm2TstiU8ICiNQqmB68SHaQ76
X-Developer-Key: i=github.com@herrie.org; a=ed25519;
 pk=YYxdq8fb5O9vhkW3n2dCH044FPZZO5718v/du7fRhFw=
X-Endpoint-Received: by B4 Relay for github.com@herrie.org/20240417 with auth_id=809
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add three optional properties to the MAX8903 charger binding to
describe board-level GPIO control of the DC and USB input current
limits:

DC input (TA / DOK pin):
  - dc-current-limit-gpios (1..4 GPIOs): mux control lines feeding
    the MAX8903 IDC resistor mux;
  - dc-current-limit-mapping (uint32-matrix of {microamps,
    gpio_bit_pattern} pairs): the available current levels and the
    GPIO bit pattern that selects each level.

USB input (USB / UOK pin):
  - usb-current-limit-gpios: a single GPIO driving the IUSB pin.
    The IUSB pin is silicon-fixed by the MAX8903 datasheet (Pin
    Description): low selects 100 mA, high selects 500 mA. Only
    the GPIO mapping is board-specific; the current values are
    not exposed in DT.

A dependentRequired block ties dc-current-limit-gpios and
dc-current-limit-mapping together so an incomplete DT cannot pass
validation with only one half of the pair.

These let userspace clamp the input draw via the standard
POWER_SUPPLY_PROP_INPUT_CURRENT_LIMIT power_supply attribute. The HP
TouchPad uses both: two TLMM lines select between 0.5 A, 1.0 A,
1.5 A and 2.0 A DC input current limits behind the MAX8903B
charger, and a third TLMM line picks the IUSB 100 mA / 500 mA
limit.

These are purely additive; existing platforms remain unaffected.

Signed-off-by: Herman van Hazendonk <github.com@herrie.org>
---
 .../bindings/power/supply/maxim,max8903.yaml       | 53 ++++++++++++++++++++++
 1 file changed, 53 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/maxim,max8903.yaml b/Documentation/devicetree/bindings/power/supply/maxim,max8903.yaml
index 86af38378999..b3d8c0a5f214 100644
--- a/Documentation/devicetree/bindings/power/supply/maxim,max8903.yaml
+++ b/Documentation/devicetree/bindings/power/supply/maxim,max8903.yaml
@@ -44,9 +44,40 @@ properties:
     maxItems: 1
     description: USB suspend pin (active high, output)
 
+  dc-current-limit-gpios:
+    minItems: 1
+    maxItems: 4
+    description:
+      GPIOs controlling DC input current limit via resistor mux.
+      Used with dc-current-limit-mapping to select charging current.
+
+  dc-current-limit-mapping:
+    $ref: /schemas/types.yaml#/definitions/uint32-matrix
+    minItems: 2
+    maxItems: 16
+    description: |
+      Array of (current_microamps, gpio_bit_pattern) pairs defining available
+      DC current limits. The gpio_bit_pattern is applied to dc-current-limit-gpios
+      to select that current level.
+    items:
+      items:
+        - description: Current limit in microamps
+        - description: GPIO bit pattern value
+
+  usb-current-limit-gpios:
+    maxItems: 1
+    description:
+      GPIO driving the MAX8903 IUSB pin. IUSB is a silicon-fixed
+      two-state input - low selects 100 mA, high selects 500 mA.
+      Only the GPIO mapping is board-specific.
+
 required:
   - compatible
 
+dependentRequired:
+  dc-current-limit-gpios: [dc-current-limit-mapping]
+  dc-current-limit-mapping: [dc-current-limit-gpios]
+
 anyOf:
   - required:
       - dok-gpios
@@ -65,3 +96,25 @@ examples:
       chg-gpios = <&gpio3 15 GPIO_ACTIVE_LOW>;
       cen-gpios = <&gpio2 5 GPIO_ACTIVE_LOW>;
     };
+  - |
+    /* Example with DC and USB current limit control */
+    #include <dt-bindings/gpio/gpio.h>
+    charger {
+      compatible = "maxim,max8903";
+      dok-gpios = <&gpio2 3 GPIO_ACTIVE_LOW>;
+      flt-gpios = <&gpio2 2 GPIO_ACTIVE_LOW>;
+      chg-gpios = <&gpio3 15 GPIO_ACTIVE_LOW>;
+      cen-gpios = <&gpio2 5 GPIO_ACTIVE_LOW>;
+      dcm-gpios = <&gpio2 6 GPIO_ACTIVE_HIGH>;
+
+      /* DC input current limit via IDC resistor mux */
+      dc-current-limit-gpios = <&gpio1 0 GPIO_ACTIVE_HIGH>,
+                               <&gpio1 1 GPIO_ACTIVE_HIGH>;
+      dc-current-limit-mapping = <750000 0>,  /* GPIO[1:0]=0b00 */
+                                 <900000 1>,  /* GPIO[1:0]=0b01 */
+                                 <1400000 3>, /* GPIO[1:0]=0b11 */
+                                 <2000000 2>; /* GPIO[1:0]=0b10 */
+
+      /* USB current limit: IUSB pin, 100 mA (low) / 500 mA (high) */
+      usb-current-limit-gpios = <&gpio1 2 GPIO_ACTIVE_HIGH>;
+    };

-- 
2.43.0

