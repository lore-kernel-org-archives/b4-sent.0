From: Frank Li <Frank.Li@nxp.com>
Date: Mon, 11 May 2026 12:11:32 -0400
Subject: [PATCH v2] ASoC: dt-bindings: Convert eukrea-tlv320.txt to yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-eukrea-v2-1-cac317290978@nxp.com>
X-B4-Tracking: v=1; b=H4sIALP/AWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzMDU0ND3dTS7KLURN1Uw1STFLOUNAtTg2QloOKCotS0zAqwQdGxtbUAvv0
 jIlgAAAA=
X-Change-ID: 20260511-eukrea-e1e4d6df850c
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778515897; l=3623;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=Rwk/LOK0vxBQRx6CqkcwOGhaMlXZZ3H+Gmi3nQ8Ktjk=;
 b=yfLg9ZvkAKOdqtkLmmxjVBHQDEJoPg6f4s9MKabAOeMpcMsz63Modt+sltRQVkvuMojoNyw6/
 6y9bKqbFnHnCLkSVeziMmnJYU6xtSUMaxat65v2JW5HoDTBNuduF9sW
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert eukrea-tlv320.txt to yaml format.

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
change in v2
- Add comments about "The AUDMUX port numbering should start at 1"
  v1: https://lore.kernel.org/linux-devicetree/CAEnQRZACes8EptdEgg0i0vzdcxgUJwZAfQHU0DEhMnXtA-g01Q@mail.gmail.com/
---
 .../bindings/sound/eukrea,asoc-tlv320.yaml         | 55 ++++++++++++++++++++++
 .../devicetree/bindings/sound/eukrea-tlv320.txt    | 26 ----------
 2 files changed, 55 insertions(+), 26 deletions(-)

diff --git a/Documentation/devicetree/bindings/sound/eukrea,asoc-tlv320.yaml b/Documentation/devicetree/bindings/sound/eukrea,asoc-tlv320.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..a95cd0323f6e489765deb8c1d1eee966750ac7aa
--- /dev/null
+++ b/Documentation/devicetree/bindings/sound/eukrea,asoc-tlv320.yaml
@@ -0,0 +1,55 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/sound/eukrea,asoc-tlv320.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Audio complex for Eukrea boards with tlv320aic23 codec.
+
+maintainers:
+  - Frank Li <Frank.Li@nxp.com>
+
+properties:
+  compatible:
+    const: eukrea,asoc-tlv320
+
+  eukrea,model:
+    $ref: /schemas/types.yaml#/definitions/string
+    description:
+      The user-visible name of this sound complex.
+
+  ssi-controller:
+    $ref: /schemas/types.yaml#/definitions/phandle
+    description:
+      The phandle of the SSI controller.
+
+  fsl,mux-int-port:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: |
+      The internal port of the i.MX audio muxer (AUDMUX).
+      Note: The AUDMUX port numbering should start at 1, which is consistent with
+      hardware manual.
+
+  fsl,mux-ext-port:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: |
+      The external port of the i.MX audio muxer.
+      Note: The AUDMUX port numbering should start at 1, which is consistent with
+      hardware manual.
+
+required:
+  - compatible
+  - eukrea,model
+  - ssi-controller
+
+additionalProperties: false
+
+examples:
+  - |
+    sound {
+        compatible = "eukrea,asoc-tlv320";
+        eukrea,model = "imx51-eukrea-tlv320aic23";
+        ssi-controller = <&ssi2>;
+        fsl,mux-int-port = <2>;
+        fsl,mux-ext-port = <3>;
+    };
diff --git a/Documentation/devicetree/bindings/sound/eukrea-tlv320.txt b/Documentation/devicetree/bindings/sound/eukrea-tlv320.txt
deleted file mode 100644
index 6dfa88c4dc1e8b3aea1e39b79eaa62185e64c240..0000000000000000000000000000000000000000
--- a/Documentation/devicetree/bindings/sound/eukrea-tlv320.txt
+++ /dev/null
@@ -1,26 +0,0 @@
-Audio complex for Eukrea boards with tlv320aic23 codec.
-
-Required properties:
-
-  - compatible		: "eukrea,asoc-tlv320"
-
-  - eukrea,model	: The user-visible name of this sound complex.
-
-  - ssi-controller	: The phandle of the SSI controller.
-
-  - fsl,mux-int-port	: The internal port of the i.MX audio muxer (AUDMUX).
-
-  - fsl,mux-ext-port	: The external port of the i.MX audio muxer.
-
-Note: The AUDMUX port numbering should start at 1, which is consistent with
-hardware manual.
-
-Example:
-
-	sound {
-		compatible = "eukrea,asoc-tlv320";
-		eukrea,model = "imx51-eukrea-tlv320aic23";
-		ssi-controller = <&ssi2>;
-		fsl,mux-int-port = <2>;
-		fsl,mux-ext-port = <3>;
-	};

---
base-commit: b7719f5647f279b131c888e70c77dd9287b322d8
change-id: 20260511-eukrea-e1e4d6df850c

Best regards,
--
Frank Li <Frank.Li@nxp.com>

