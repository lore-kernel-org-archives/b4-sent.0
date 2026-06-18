From: David Heidelberg <david@ixit.cz>
Date: Thu, 18 Jun 2026 16:33:28 +0200
Subject: [PATCH RFC] dt-bindings: sound: Convert cirrus,cs35l36 to DT
 schema
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260618-dt-cirrus-cs35l36-v1-1-1a43515666ad@ixit.cz>
X-B4-Tracking: v=1; b=H4sIALcBNGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDM0ML3ZQS3eTMoqLSYt3kYmPTHGMzXUvLZBMzs7QkQ+O0FCWgvoKi1LT
 MCrCZ0UpBbs5KsbW1APrRZxNoAAAA
X-Change-ID: 20260618-dt-cirrus-cs35l36-99c466fb13fd
To: David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, patches@opensource.cirrus.com, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=14156; i=david@ixit.cz;
 h=from:subject:message-id; bh=g23zOnCMQPaNqnE58HL52klKPYJXZPiR6z567szNqJM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqNAG9dPZMDGKaT5u1kZEGxxTXMntUtokuCqaXW
 lj5fTqroDGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCajQBvQAKCRBgAj/E00kg
 ciBMD/0eaLmO5Eq6JKW/NNoodMaqDdqHF6I+ZPVQQJV10/D3Oa+4xsYASxfJzaDyZrMhNRTxfwi
 OKVEyPF6CpXeXpNIOKOEpRUju4L9sIpJWViYXyWO9CF0ixxWbCeMcCYvZa8kQJ3nsF0TWz6hQgJ
 TTLXFJzBkyTgUrxlrA1GVn2Tki5Iuj2rpAVK81KuZDMEiAv7/R0yY5U3wDZTQUctqUK9hCnYKDh
 gLXEuSlza3FK0cFaPXbTV8e8DCts1l6O+ZdCnsgoxY/0wNDCfN7OCzHiW2pR4KxT2QePDucQZsL
 G0tdFrCR+1mBvuSVKA//bfRhCcwOPR0rAfFDH50pRhrcOG1tdKQOWgGpOBPtjg3QdApx7NSjQZd
 2poTx08bYpmn2wlrzKdm1VkdXSZs6JT5LybrIg//J+Zr1aX/jQGsvILUsQ5B0S6MBAt8MrhPjug
 pB4VR5G8QIJiRSeXkNDiaM20aNamzRed+mMfdXo3nU+pKYKJSZ0I9ljUYhrzemn8stm7DJ8ZVBk
 0uv0YdSVP3EvzJ3jj3yku592wi7PtE5TXFaQZkWit6FxOPiFFTngntwLQ5LHUUxyLTOqEXUzFyg
 Dez39tfsNZgb7UCdg8hxl9xHxsOg3KLtnaCpXzX+qozrv5v+0VR4Yv4LON8ou3y4m5zU4+spH4V
 q7KOiFcX2qTR4Yw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert CS35L36 Speaker Amplifier.

Changes:
 - maintainers email to the generic Cirrus email
 - Both the codec and downstream worked just fine without
   VP-supply provided. Align with datasheet for similar models.
 - add dai-common.yaml to cover for '#sound-dai-cells',
   'sound-name-prefix'

Co-developed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Relevant for Pixel 3 / 3XL / 4.
---
 .../devicetree/bindings/sound/cirrus,cs35l36.yaml  | 224 +++++++++++++++++++++
 .../devicetree/bindings/sound/cs35l36.txt          | 168 ----------------
 2 files changed, 224 insertions(+), 168 deletions(-)

diff --git a/Documentation/devicetree/bindings/sound/cirrus,cs35l36.yaml b/Documentation/devicetree/bindings/sound/cirrus,cs35l36.yaml
new file mode 100644
index 0000000000000..af0acaaefb68e
--- /dev/null
+++ b/Documentation/devicetree/bindings/sound/cirrus,cs35l36.yaml
@@ -0,0 +1,224 @@
+# SPDX-License-Identifier: GPL-2.0-only
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/cirrus,cs35l36.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cirrus Logic CS35L36 Speaker Amplifier
+
+maintainers:
+  - patches@opensource.cirrus.com
+  - Bjorn Helgaas <bhelgaas@google.com>
+
+description: |
+  CS35L36 is a boosted mono Class D amplifier
+
+allOf:
+  - $ref: /schemas/sound/dai-common.yaml#
+
+properties:
+  compatible:
+    enum:
+      - cirrus,cs35l36
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  VA-supply:
+    description: Voltage regulator of analog internal section
+
+  VP-supply:
+    description: Voltage regulator of boost converter
+
+  reset-gpios:
+    maxItems: 1
+
+  cirrus,boost-ctl-millivolt:
+    description: Boost converter output voltage in millivolts (step 50)
+    $ref: /schemas/types.yaml#/definitions/uint32
+    minimum: 2550
+    maximum: 12000
+
+  cirrus,boost-peak-milliamp:
+    description: Boost-converter peak current limit in mA (step 50)
+    $ref: /schemas/types.yaml#/definitions/uint32
+    default: 4500
+    minimum: 1600
+    maximum: 4500
+
+  cirrus,boost-ind-nanohenry:
+    description: Initial inductor estimation reference value in nanohenry (1000=1μH, 1200=1.2μH)
+    $ref: /schemas/types.yaml#/definitions/uint32
+    default: 1000
+
+  cirrus,multi-amp-mode:
+    description: Hi-Z ASP port when more than one amplifier in system.
+    type: boolean
+
+  cirrus,boost-ctl-select:
+    description: Boost converter control source selection
+    $ref: /schemas/types.yaml#/definitions/uint32
+    default: 0x01
+    enum:
+      - 0x00 # Control Port
+      - 0x01 # Class
+      - 0x10 # Sync
+
+  cirrus,amp-pcm-inv:
+    description: Invert incoming PCM data when true.
+    type: boolean
+
+  cirrus,imon-pol-inv:
+    description: Invert polarity of outbound IMON feedback when true.
+    type: boolean
+
+  cirrus,vmon-pol-inv:
+    description: Invert polarity of outbound VMON feedback when true.
+    type: boolean
+
+  cirrus,dcm-mode-enable:
+    description: Enable boost converter automatic Discontinuous Conduction Mode.
+    type: boolean
+
+  cirrus,weak-fet-disable:
+    description: Reduce output driver strength in Weak-FET Drive Mode when true.
+    type: boolean
+
+  cirrus,classh-wk-fet-delay:
+    description: Weak-FET entry delay in ms
+    $ref: /schemas/types.yaml#/definitions/uint32
+    default: 100
+    enum:
+      - 0 # 0
+      - 1 # 5
+      - 2 # 10
+      - 3 # 50
+      - 4 # 100
+      - 5 # 200
+      - 6 # 500
+      - 7 # 1000
+
+  cirrus,classh-weak-fet-thld-millivolt:
+    description: Weak-FET drive threshold in mV
+    $ref: /schemas/types.yaml#/definitions/uint32
+    enum: [50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700]
+
+  cirrus,temp-warn-threshold:
+    description: Overtemperature warning threshold
+    $ref: /schemas/types.yaml#/definitions/uint32
+    default: 2
+    enum:
+      - 0 # 105°C
+      - 1 # 115°C
+      - 2 # 125°C
+      - 3 # 135°C
+
+  cirrus,irq-drive-select:
+    description: Interrupt output driver type
+    $ref: /schemas/types.yaml#/definitions/uint32
+    default: 1
+    enum:
+      - 0 # open-drain
+      - 1 # push-pull
+
+  cirrus,irq-gpio-select:
+    description: Programmable IRQ pin selection
+    $ref: /schemas/types.yaml#/definitions/uint32
+    enum:
+      - 0 # PDM_DATA/SWIRE_SD/INT
+      - 1 # GPIO
+
+  cirrus,vpbr-config:
+    description: Brownout prevention configuration sub-node
+    type: object
+    additionalProperties: false
+
+    properties:
+      cirrus,vpbr-en:
+        description: VBST brownout prevention enable
+        $ref: /schemas/types.yaml#/definitions/uint32
+        default: 0
+        enum:
+          - 0 # disabled
+          - 1 # enabled
+
+      cirrus,vpbr-thld:
+        description: Initial VPBR threshold voltage
+        $ref: /schemas/types.yaml#/definitions/uint32
+
+      cirrus,vpbr-atk-rate:
+        description: Attenuation attack step rate
+        $ref: /schemas/types.yaml#/definitions/uint32
+
+      cirrus,vpbr-atk-vol:
+        description: VP brownout prevention step size
+        $ref: /schemas/types.yaml#/definitions/uint32
+
+      cirrus,vpbr-max-attn:
+        description: Maximum attenuation during VP brownout prevention
+        $ref: /schemas/types.yaml#/definitions/uint32
+
+      cirrus,vpbr-wait:
+        description: Delay between brownout clearance and attenuation release
+        $ref: /schemas/types.yaml#/definitions/uint32
+
+      cirrus,vpbr-rel-rate:
+        description: Attenuation release step rate
+        $ref: /schemas/types.yaml#/definitions/uint32
+
+      cirrus,vpbr-mute-en:
+        description: Mute audio if maximum attenuation reached
+        $ref: /schemas/types.yaml#/definitions/uint32
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - VA-supply
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        codec@40 {
+            compatible = "cirrus,cs35l36";
+            reg = <0x40>;
+            VA-supply = <&dummy_vreg>;
+            VP-supply = <&dummy_vreg>;
+            reset-gpios = <&gpio0 54 GPIO_ACTIVE_HIGH>;
+            interrupts = <3 IRQ_TYPE_LEVEL_LOW>;
+
+            cirrus,boost-ind-nanohenry = <1000>;
+            cirrus,boost-ctl-millivolt = <10000>;
+            cirrus,boost-peak-milliamp = <4500>;
+            cirrus,boost-ctl-select = <0x00>;
+            cirrus,weak-fet-delay = <4>;
+            cirrus,weak-fet-thld = <0x01>;
+            cirrus,temp-warn-threshold = <1>;
+            cirrus,multi-amp-mode;
+            cirrus,irq-drive-select = <1>;
+            cirrus,irq-gpio-select = <0x01>;
+
+            cirrus,vpbr-config {
+                cirrus,vpbr-en = <0>;
+                cirrus,vpbr-thld = <0x05>;
+                cirrus,vpbr-atk-rate = <0x02>;
+                cirrus,vpbr-atk-vol = <0x01>;
+                cirrus,vpbr-max-attn = <0x09>;
+                cirrus,vpbr-wait = <0x01>;
+                cirrus,vpbr-rel-rate = <0x05>;
+                cirrus,vpbr-mute-en = <0x00>;
+            };
+        };
+    };
+...
diff --git a/Documentation/devicetree/bindings/sound/cs35l36.txt b/Documentation/devicetree/bindings/sound/cs35l36.txt
deleted file mode 100644
index d34117b8558e5..0000000000000
--- a/Documentation/devicetree/bindings/sound/cs35l36.txt
+++ /dev/null
@@ -1,168 +0,0 @@
-CS35L36 Speaker Amplifier
-
-Required properties:
-
-  - compatible : "cirrus,cs35l36"
-
-  - reg : the I2C address of the device for I2C
-
-  - VA-supply, VP-supply : power supplies for the device,
-  as covered in
-  Documentation/devicetree/bindings/regulator/regulator.txt.
-
-  - cirrus,boost-ctl-millivolt : Boost Voltage Value.  Configures the boost
-  converter's output voltage in mV. The range is from 2550mV to 12000mV with
-  increments of 50mV.
-  (Default) VP
-
-  - cirrus,boost-peak-milliamp : Boost-converter peak current limit in mA.
-  Configures the peak current by monitoring the current through the boost FET.
-  Range starts at 1600mA and goes to a maximum of 4500mA with increments of
-  50mA.
-  (Default) 4.50 Amps
-
-  - cirrus,boost-ind-nanohenry : Inductor estimation LBST reference value.
-  Seeds the digital boost converter's inductor estimation block with the initial
-  inductance value to reference.
-
-  1000 = 1uH (Default)
-  1200 = 1.2uH
-
-Optional properties:
-  - cirrus,multi-amp-mode : Boolean to determine if there are more than
-  one amplifier in the system. If more than one it is best to Hi-Z the ASP
-  port to prevent bus contention on the output signal
-
-  - cirrus,boost-ctl-select : Boost converter control source selection.
-  Selects the source of the BST_CTL target VBST voltage for the boost
-  converter to generate.
-  0x00 - Control Port Value
-  0x01 - Class H Tracking (Default)
-  0x10 - MultiDevice Sync Value
-
-  - cirrus,amp-pcm-inv : Boolean to determine Amplifier will invert incoming
-  PCM data
-
-  - cirrus,imon-pol-inv : Boolean to determine Amplifier will invert the
-  polarity of outbound IMON feedback data
-
-  - cirrus,vmon-pol-inv : Boolean to determine Amplifier will invert the
-  polarity of outbound VMON feedback data
-
-  - cirrus,dcm-mode-enable : Boost converter automatic DCM Mode enable.
-  This enables the digital boost converter to operate in a low power
-  (Discontinuous Conduction) mode during low loading conditions.
-
-  - cirrus,weak-fet-disable : Boolean : The strength of the output drivers is
-  reduced when operating in a Weak-FET Drive Mode and must not be used to drive
-  a large load.
-
-  - cirrus,classh-wk-fet-delay :  Weak-FET entry delay. Controls the delay
-  (in ms) before the Class H algorithm switches to the weak-FET voltage
-  (after the audio falls and remains below the value specified in WKFET_AMP_THLD).
-
-  0 = 0ms
-  1 = 5ms
-  2 = 10ms
-  3 = 50ms
-  4 = 100ms (Default)
-  5 = 200ms
-  6 = 500ms
-  7 = 1000ms
-
-  - cirrus,classh-weak-fet-thld-millivolt : Weak-FET amplifier drive threshold.
-  Configures the signal threshold at which the PWM output stage enters
-  weak-FET operation. The range is 50mV to 700mV in 50mV increments.
-
-  - cirrus,temp-warn-threshold :  Amplifier overtemperature warning threshold.
-  Configures the threshold at which the overtemperature warning condition occurs.
-  When the threshold is met, the overtemperature warning attenuation is applied
-  and the TEMP_WARN_EINT interrupt status bit is set.
-  If TEMP_WARN_MASK = 0, INTb is asserted.
-
-  0 = 105C
-  1 = 115C
-  2 = 125C (Default)
-  3 = 135C
-
-  - cirrus,irq-drive-select : Selects the driver type of the selected interrupt
-  output.
-
-  0 = Open-drain
-  1 = Push-pull (Default)
-
-  - cirrus,irq-gpio-select : Selects the pin to serve as the programmable
-  interrupt output.
-
-  0 = PDM_DATA / SWIRE_SD / INT (Default)
-  1 = GPIO
-
-Optional properties for the "cirrus,vpbr-config" Sub-node
-
-  - cirrus,vpbr-en : VBST brownout prevention enable. Configures whether the
-  VBST brownout prevention algorithm is enabled or disabled.
-
-  0 = VBST brownout prevention disabled (default)
-  1 = VBST brownout prevention enabled
-
-  See Section 7.31.1 VPBR Config for configuration options & further details
-
-  - cirrus,vpbr-thld : Initial VPBR threshold. Configures the VP brownout
-  threshold voltage
-
-  - cirrus,cirrus,vpbr-atk-rate : Attenuation attack step rate. Configures the
-  amount delay between consecutive volume attenuation steps when a brownout
-  condition is present and the VP brownout condition is in an attacking state.
-
-  - cirrus,vpbr-atk-vol : VP brownout prevention step size. Configures the VP
-  brownout prevention attacking attenuation step size when operating in either
-  digital volume or analog gain modes.
-
-  - cirrus,vpbr-max-attn : Maximum attenuation that the VP brownout prevention
-  can apply to the audio signal.
-
-  - cirrus,vpbr-wait : Configures the delay time between a brownout condition
-  no longer being present and the VP brownout prevention entering an attenuation
-  release state.
-
-  - cirrus,vpbr-rel-rate : Attenuation release step rate. Configures the delay
-  between consecutive volume attenuation release steps when a brownout condition
-  is not longer present and the VP brownout is in an attenuation release state.
-
-  - cirrus,vpbr-mute-en : During the attack state, if the vpbr-max-attn value
-  is reached, the error condition still remains, and this bit is set, the audio
-  is muted.
-
-Example:
-
-cs35l36: cs35l36@40 {
-	compatible = "cirrus,cs35l36";
-	reg = <0x40>;
-	VA-supply = <&dummy_vreg>;
-	VP-supply = <&dummy_vreg>;
-	reset-gpios = <&gpio0 54 0>;
-	interrupt-parent = <&gpio8>;
-	interrupts = <3 IRQ_TYPE_LEVEL_LOW>;
-
-	cirrus,boost-ind-nanohenry = <1000>;
-	cirrus,boost-ctl-millivolt = <10000>;
-	cirrus,boost-peak-milliamp = <4500>;
-	cirrus,boost-ctl-select = <0x00>;
-	cirrus,weak-fet-delay = <0x04>;
-	cirrus,weak-fet-thld = <0x01>;
-	cirrus,temp-warn-threshold = <0x01>;
-	cirrus,multi-amp-mode;
-	cirrus,irq-drive-select = <0x01>;
-	cirrus,irq-gpio-select = <0x01>;
-
-	cirrus,vpbr-config {
-		cirrus,vpbr-en = <0x00>;
-		cirrus,vpbr-thld = <0x05>;
-		cirrus,vpbr-atk-rate = <0x02>;
-		cirrus,vpbr-atk-vol = <0x01>;
-		cirrus,vpbr-max-attn = <0x09>;
-		cirrus,vpbr-wait = <0x01>;
-		cirrus,vpbr-rel-rate = <0x05>;
-		cirrus,vpbr-mute-en = <0x00>;
-	};
-};

---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260618-dt-cirrus-cs35l36-99c466fb13fd

Best regards,
-- 
David Heidelberg <david@ixit.cz>

