From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 15 Jan 2025 19:03:08 +0800
Subject: [PATCH 2/4] ASoC: dt-bindings: Add Realtek ALC203 Codec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250115-loongson1-ac97-v1-2-2087b04dcd7f@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736938989; l=1261;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=RCYZ5LwKO9wo5eHWNA2+bL7kJQC8yTwQR/Y3fcfAXio=;
 b=W3ztVz5GeNHcTQgp9c+Ac07IJ+el8Q2afuKTc7RmJnXeWuVnE2RXiTOWWrV5cPCdZ2JaOD91T
 +l0p7EjqdnaBHZkGCeSGIMZ3gyWCCXvYMiOiVXaX12jdkMkq5JF6f5P
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding document for Realtek ALC203 codec.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 .../devicetree/bindings/sound/realtek,alc203.yaml  | 33 ++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/realtek,alc203.yaml b/Documentation/devicetree/bindings/sound/realtek,alc203.yaml
new file mode 100644
index 000000000000..5be8e9ee1ed4
--- /dev/null
+++ b/Documentation/devicetree/bindings/sound/realtek,alc203.yaml
@@ -0,0 +1,33 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/sound/realtek,alc203.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Realtek ALC203 AC97 Audio Codec
+
+maintainers:
+  - Keguang Zhang <keguang.zhang@gmail.com>
+
+description:
+  ALC203 is a full duplex AC97 2.3 compatible stereo audio codec.
+
+properties:
+  compatible:
+    const: realtek,alc203
+
+  '#sound-dai-cells':
+    const: 0
+
+required:
+  - compatible
+  - '#sound-dai-cells'
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    audio-codec {
+        compatible = "realtek,alc203";
+        #sound-dai-cells = <0>;
+    };

-- 
2.43.0

