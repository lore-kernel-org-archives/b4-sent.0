From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 15 Jan 2025 19:03:07 +0800
Subject: [PATCH 1/4] ASoC: dt-bindings: Add Loongson-1 AC97 Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250115-loongson1-ac97-v1-1-2087b04dcd7f@gmail.com>
References: <20250115-loongson1-ac97-v1-0-2087b04dcd7f@gmail.com>
In-Reply-To: <20250115-loongson1-ac97-v1-0-2087b04dcd7f@gmail.com>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-mips@vger.kernel.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736938989; l=2085;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=sj9gFgnj3eTfVF3m8C07vZrwbwVlXrglvLvbMnZ9jsI=;
 b=xIA/2qQqzVoEkunR/DFz1G4Zb+2kfDoAPliIuHYfHCLR2MfwsA+4jjLa7IX8iWby9ThVmDwdb
 5xsGMr9QsW7Cit8s1ma6T6KsZQ7XHbmBYSLh+9IcFwc9cFhJMhUKJeB
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding document for Loongson-1 AC97 controller.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 .../bindings/sound/loongson,ls1b-ac97.yaml         | 68 ++++++++++++++++++++++
 1 file changed, 68 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/loongson,ls1b-ac97.yaml b/Documentation/devicetree/bindings/sound/loongson,ls1b-ac97.yaml
new file mode 100644
index 000000000000..1c6a2771f942
--- /dev/null
+++ b/Documentation/devicetree/bindings/sound/loongson,ls1b-ac97.yaml
@@ -0,0 +1,68 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/sound/loongson,ls1b-ac97.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Loongson-1 AC97 Controller
+
+maintainers:
+  - Keguang Zhang <keguang.zhang@gmail.com>
+
+description:
+  The Loongson-1 AC97 controller supports 2-channel stereo output and input.
+  It is paired with the DMA engine to handle playback and capture functions.
+
+allOf:
+  - $ref: dai-common.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - const: loongson,ls1b-ac97
+      - items:
+          - enum:
+              - loongson,ls1a-ac97
+              - loongson,ls1c-ac97
+          - const: loongson,ls1b-ac97
+
+  reg:
+    maxItems: 3
+
+  reg-names:
+    items:
+      - const: ac97
+      - const: audio-tx
+      - const: audio-rx
+
+  dmas:
+    maxItems: 2
+
+  dma-names:
+    items:
+      - const: tx
+      - const: rx
+
+  '#sound-dai-cells':
+    const: 0
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - dmas
+  - dma-names
+  - '#sound-dai-cells'
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    audio-controller@1fe74000 {
+        compatible = "loongson,ls1b-ac97";
+        reg = <0x1fe74000 0x60>, <0x1fe72420 0x4>, <0x1fe74c4c 0x4>;
+        reg-names = "ac97", "audio-tx", "audio-rx";
+        dmas = <&dma 1>, <&dma 2>;
+        dma-names = "tx", "rx";
+        #sound-dai-cells = <0>;
+    };

-- 
2.43.0

