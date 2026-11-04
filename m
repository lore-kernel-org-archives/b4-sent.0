From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:16:53 -0500
Subject: [PATCH 1/4] dt-bindings: mips: Add Siflower SF19A2890 based boards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sf19a2890-mips-v1-1-eae80820af68@telaak.dev>
References: <20261104-sf19a2890-mips-v1-0-eae80820af68@telaak.dev>
In-Reply-To: <20261104-sf19a2890-mips-v1-0-eae80820af68@telaak.dev>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Burton <paulburton@kernel.org>
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776620; l=1813;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=/zLPz9LJOGnGoujKr8TLBR8riYXrOQytAU9btqLp/no=;
 b=kXocI+41xx19J/VdPTUYkAiGklfF3xKIIJigxtR8zURZliE/Eh4Bq4YfxUAXf4zZjFJJ/Wzg0
 JvRiebyyR1BCydeDXrX92PRHBqLzE6arUu83aMaplv3R+54zrQJo1Sw
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SF19A2890 is a MIPS interAptiv SoC from Siflower (two cores, two
VPEs each) for home routers. Document its compatible and the first
board using it, the GL.iNet GL-SFT1200 ("Opal") travel router.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 .../devicetree/bindings/mips/siflower.yaml         | 26 ++++++++++++++++++++++
 MAINTAINERS                                        |  8 +++++++
 2 files changed, 34 insertions(+)

diff --git a/Documentation/devicetree/bindings/mips/siflower.yaml b/Documentation/devicetree/bindings/mips/siflower.yaml
new file mode 100644
index 000000000..33110f742
--- /dev/null
+++ b/Documentation/devicetree/bindings/mips/siflower.yaml
@@ -0,0 +1,26 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mips/siflower.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Siflower MIPS SoCs
+
+maintainers:
+  - Joseph Telaak <joseph@telaak.dev>
+
+properties:
+  $nodename:
+    const: '/'
+
+  compatible:
+    oneOf:
+      - description: Boards with the Siflower SF19A2890 SoC
+        items:
+          - enum:
+              - glinet,gl-sft1200
+          - const: siflower,sf19a2890
+
+additionalProperties: true
+
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 93abbb315..2a7a083f2 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25698,6 +25698,14 @@ N:	sifive
 K:	fu[57]40
 K:	[^@]sifive
 
+SIFLOWER SF19A2890 SOC SUPPORT
+M:	Joseph Telaak <joseph@telaak.dev>
+L:	linux-mips@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/mips/siflower.yaml
+F:	drivers/gpio/gpio-siflower.c
+N:	sf19a2890
+
 SILEAD TOUCHSCREEN DRIVER
 M:	Hans de Goede <hansg@kernel.org>
 L:	linux-input@vger.kernel.org

-- 
Git-155)

