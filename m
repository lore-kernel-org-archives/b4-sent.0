From: Nuno Sa <nuno.sa@analog.com>
Date: Mon, 28 Oct 2024 16:43:39 +0100
Subject: [PATCH v2 2/4] ASoC: dt-bindings: document the adau1373 Codec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241028-adau1373-shutdown-v2-2-647f56bbd182@analog.com>
References: <20241028-adau1373-shutdown-v2-0-647f56bbd182@analog.com>
In-Reply-To: <20241028-adau1373-shutdown-v2-0-647f56bbd182@analog.com>
To: linux-sound@vger.kernel.org, devicetree@vger.kernel.org
Cc: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730130219; l=4205;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=e6/jgIZWmuR3Nbe5npqQP5ffqfzdhUaw8odBN01/3Ho=;
 b=lvBiVXRZY3VExRrlBxINZ1pqhMupcpXaQk5ZpwwgexekX6liDiyNNn0djQ23mLseD9DjN1l7p
 XP3tv6GnLZxBeAkxMQQkOpib53Ep/fneXSjm7shVDQG2oJxAu4BLnKm
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the adau1373 Low Power Codec with Speaker and
Headphone Amplifier.

While at it, properly add a MAINTAINERS entry for ADI sound bindings.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 .../devicetree/bindings/sound/adi,adau1373.yaml    | 111 +++++++++++++++++++++
 MAINTAINERS                                        |   1 +
 2 files changed, 112 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/adi,adau1373.yaml b/Documentation/devicetree/bindings/sound/adi,adau1373.yaml
new file mode 100644
index 000000000000..97552bf5d951
--- /dev/null
+++ b/Documentation/devicetree/bindings/sound/adi,adau1373.yaml
@@ -0,0 +1,111 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/sound/adi,adau1373.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices ADAU1373 CODEC
+
+maintainers:
+  - Nuno Sá <nuno.sa@analog.com>
+
+description: |
+  Analog Devices ADAU1373 Low power codec with speaker and headphone amplifiers.
+  https://www.analog.com/media/en/technical-documentation/data-sheets/ADAU1373.pdf
+
+allOf:
+  - $ref: dai-common.yaml#
+
+properties:
+  compatible:
+    enum:
+      - adi,adau1373
+
+  reg:
+    maxItems: 1
+
+  "#sound-dai-cells":
+    const: 0
+
+  powerdown-gpios:
+    description: GPIO used for hardware power-down.
+    maxItems: 1
+
+  adi,micbias1-microvolt:
+    description:
+      This property sets the microphone bias voltage for the first microphone.
+    enum: [1800000, 2200000, 2600000, 2900000]
+    default: 2900000
+
+  adi,micbias2-microvolt:
+    description:
+      This property sets the microphone bias voltage for the second microphone.
+    enum: [1800000, 2200000, 2600000, 2900000]
+    default: 2900000
+
+  adi,input1-differential:
+    description: This property sets the first analog input as differential.
+    type: boolean
+
+  adi,input2-differential:
+    description: This property sets the second analog input as differential.
+    type: boolean
+
+  adi,input3-differential:
+    description: This property sets the third analog input as differential.
+    type: boolean
+
+  adi,input4-differential:
+    description: This property sets the fourth analog input as differential.
+    type: boolean
+
+  adi,lineout-differential:
+    description: This property sets the line output as differential.
+    type: boolean
+
+  adi,lineout-gnd-sense:
+    description: This property enables the line output ground sense control.
+    type: boolean
+
+  adi,drc-settings:
+    description:
+      This setting is used to control the dynamic range of the signal. The
+      device provides a maximum of three full band DRCs with 13 entries each.
+    $ref: /schemas/types.yaml#/definitions/uint8-array
+    oneOf:
+      - minItems: 13
+        maxItems: 13
+      - minItems: 26
+        maxItems: 26
+      - minItems: 39
+        maxItems: 39
+
+required:
+  - "#sound-dai-cells"
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+        audio-codec@1a {
+            compatible = "adi,adau1373";
+            reg = <0x1a>;
+            #sound-dai-cells = <0>;
+            powerdown-gpios = <&gpio 100 GPIO_ACTIVE_LOW>;
+            adi,input2-differential;
+            adi,input1-differential;
+            adi,lineout-differential;
+            adi,micbias2-microvolt = <1800000>;
+            adi,drc-settings = /bits/ 8 <
+                0xff 0xff 0x1 0x2 0xa 0xa 0xd 0x1 0xff 0xff 0x5 0xd 0xff
+            >;
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 9d6272c00fbd..24bc5fcac74a 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1521,6 +1521,7 @@ L:	linux-sound@vger.kernel.org
 S:	Supported
 W:	http://wiki.analog.com/
 W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/sound/adi,*
 F:	sound/soc/codecs/ad1*
 F:	sound/soc/codecs/ad7*
 F:	sound/soc/codecs/adau*

-- 
2.47.0

