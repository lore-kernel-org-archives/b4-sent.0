From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Thu, 19 Nov 2026 14:01:46 +0530
Subject: [PATCH v3 1/2] ASoC: dt-bindings: Add NXP TFA9865 amplifier
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-vantage-tfa9865-v3-1-5257fa45df57@yahoo.com>
References: <20261119-vantage-tfa9865-v3-0-5257fa45df57@yahoo.com>
In-Reply-To: <20261119-vantage-tfa9865-v3-0-5257fa45df57@yahoo.com>
To: Venkat Yadlapati <venkat.yadlapati@yahoo.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, phone-devel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795077105; l=2798;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=clpAsQwAhx2GufbyRotHi6YglHtWhSHyZbTP5u+hrn4=;
 b=/w+ia3EORqiN+fnnjmEraObbtwY6JW5F27rGABNfYWmN9b8kUKHywwGI/Xs/SCkqcfDFZP6iE
 n8pnbpAG8kGAAmTIrValDCJfY/qj+dm4z6BO0LdFgaGBI3Zyi+9aDpk
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TFA9865 is a mono class-D speaker amplifier with a boost converter
and voltage/current sensing but no DSP. It is controlled over I2C and
receives audio over I2S/TDM.

An LLM was used to help write this commit message.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 .../devicetree/bindings/sound/nxp,tfa9865.yaml     | 63 ++++++++++++++++++++++
 MAINTAINERS                                        |  7 +++
 2 files changed, 70 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/nxp,tfa9865.yaml b/Documentation/devicetree/bindings/sound/nxp,tfa9865.yaml
new file mode 100644
index 000000000000..ff8fd35d9d10
--- /dev/null
+++ b/Documentation/devicetree/bindings/sound/nxp,tfa9865.yaml
@@ -0,0 +1,63 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/sound/nxp,tfa9865.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: NXP/Goodix TFA9865 Audio Amplifier
+
+maintainers:
+  - Venkat Yadlapati <venkat.yadlapati@yahoo.com>
+
+description:
+  The TFA9865 is a mono class-D speaker amplifier with an integrated boost
+  converter and voltage/current sensing. It is controlled over I2C and
+  receives audio over I2S/TDM.
+
+allOf:
+  - $ref: dai-common.yaml#
+
+properties:
+  compatible:
+    const: nxp,tfa9865
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  reset-gpios:
+    maxItems: 1
+
+  vddd-supply:
+    description: Digital supply (1.8 V)
+
+  '#sound-dai-cells':
+    const: 0
+
+required:
+  - compatible
+  - reg
+  - '#sound-dai-cells'
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
+        audio-codec@35 {
+            compatible = "nxp,tfa9865";
+            reg = <0x35>;
+            interrupts-extended = <&tlmm 201 IRQ_TYPE_EDGE_FALLING>;
+            reset-gpios = <&tlmm 183 GPIO_ACTIVE_LOW>;
+            sound-name-prefix = "Speaker";
+            #sound-dai-cells = <0>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 222b7fc2c3aa..bbe812e4257c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -20386,6 +20386,13 @@ F:	drivers/gpu/drm/bridge/tda998x_drv.c
 F:	include/dt-bindings/display/tda998x.h
 K:	"nxp,tda998x"
 
+NXP TFA9865 AMPLIFIER DRIVER
+M:	Venkat Yadlapati <venkat.yadlapati@yahoo.com>
+L:	linux-sound@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/sound/nxp,tfa9865.yaml
+F:	sound/soc/codecs/tfa9865.c
+
 NXP TFA9879 DRIVER
 M:	Peter Rosin <peda@lysator.liu.se>
 L:	linux-sound@vger.kernel.org

-- 
2.56.1

