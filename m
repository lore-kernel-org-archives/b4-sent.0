From: David Heidelberg <david@ixit.cz>
Date: Sun, 02 Aug 2026 14:42:40 +0200
Subject: [PATCH RFC 1/3] dt-bindings: sound: Add NXP TFA98XX TFA2 amplifier
 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-tfa98xx-upstream-v1-1-4dd55cdd658a@ixit.cz>
References: <20260802-tfa98xx-upstream-v1-0-4dd55cdd658a@ixit.cz>
In-Reply-To: <20260802-tfa98xx-upstream-v1-0-4dd55cdd658a@ixit.cz>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1851; i=david@ixit.cz;
 h=from:subject:message-id; bh=ViUxE0LC3t90pmsmZSY5+bZF4yD/3WG8f30yBWITCnw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbztFvRluDR502lw7/NRrEIgLQC8sh6Ek71XsZ
 KJ5ZupFntWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam87RQAKCRBgAj/E00kg
 cqA9EAC3OE2BeZ1AqxbrtO7HUJMae20TUw2B+T7GH0/Jb0n7YF0GznXb20tw+/pmLxx/NG6zx9m
 dmh+aphYXRhoEUn2rXsxLcRn/t24DYiYV+hJ9R8qHCf1HuEZoh5LssODei9PV4G2wpW1kfQfWgP
 20k56fREItfh9gy5OLAIEieYrjsn2yWghPpP8WrlSh9T9cxikj46tj4SQBSO0xTN36hLqVO1Cq4
 SmtdSNIVLtheR04tcqHsclcMMX976B9AtuSjKxADuxAvj4vb5lg92Nfczy8L7/NetJiPpPLjAUD
 iPdhmz68WU6BRCigOtceqlVlSRLCKDIx29ChAoFuF05d8v6zvw1iogWBvrJ/CXJjIyDxkx64Gpg
 xm7RCFKOZde+9NmH23IGYBFd723uu/3aOFbg+mhErJAg2qZLY+UylfAL7MOjIICswuiIY+LrF2x
 S4o227Um7/LPcTxOZjnObBTLKyFV1jBB2bV6gIlpGH6nUVlojNcLlApgpwF0UjS3bMyd8yBbgMh
 TwOqTuaRh9PWLn2aHRKrimiVG7HmdIAbNytKAA2HoOw1Vp6xwz4OEgeP8hhRgZe4FHmjlAzspFR
 X0+yG5gf8gdNhMPe8arbn9t4oz9vas7KfSYAqOEdvzlr6o5CevuLMzcvKTGDm/t7uTgitgJFYTa
 l4JRlZ1Wba33U0g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a YAML devicetree binding schema for the NXP/Goodix TFA98XX TFA2
family of I2C-controlled smart speaker amplifiers with on-chip DSP.

The binding covers supported chip variants (TFA9872 through
TFA9912) and documents the optional reset and IRQ GPIO properties.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../devicetree/bindings/sound/nxp,tfa98xx.yaml     | 54 ++++++++++++++++++++++
 1 file changed, 54 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/nxp,tfa98xx.yaml b/Documentation/devicetree/bindings/sound/nxp,tfa98xx.yaml
new file mode 100644
index 0000000000000..e80c046894454
--- /dev/null
+++ b/Documentation/devicetree/bindings/sound/nxp,tfa98xx.yaml
@@ -0,0 +1,54 @@
+# SPDX-License-Identifier: (GPL-2.0-only)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/sound/nxp,tfa98xx.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: NXP/Goodix TFA98xx (TFA2) smart speaker amplifiers
+
+maintainers:
+  - David Heidelberg <david@ixit.cz>
+
+description:
+  The TFA98xx (TFA2) family are I2C-controlled class-D speaker amplifiers
+  with an integrated CoolFlux DSP.
+
+allOf:
+  - $ref: dai-common.yaml#
+
+properties:
+  compatible:
+    enum:
+      - nxp,tfa9894
+
+  reg:
+    maxItems: 1
+
+  reset-gpios:
+    maxItems: 1
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
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        audio-codec@34 {
+            compatible = "nxp,tfa9894";
+            reg = <0x34>;
+            reset-gpios = <&tlmm 69 GPIO_ACTIVE_HIGH>;
+            #sound-dai-cells = <0>;
+        };
+    };

-- 
2.53.0

