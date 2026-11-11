From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 11 Nov 2026 03:27:15 -0500
Subject: [PATCH v2 1/4] dt-bindings: mips: Add Siflower SF19A2890 based
 boards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-sf19a2890-mips-v2-1-36730fa4f5a6@telaak.dev>
References: <20261111-sf19a2890-mips-v2-0-36730fa4f5a6@telaak.dev>
In-Reply-To: <20261111-sf19a2890-mips-v2-0-36730fa4f5a6@telaak.dev>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Burton <paulburton@kernel.org>
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794385652; l=1790;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=OJIfjvntJEidxFP5868AVEMpXF93c+J2djXrcnoJSGI=;
 b=DqSD4UneyGa3ETBdesCJcKE3tvHGtKtPGwRZiCznN7pDZy87/hlF3OSBY73UvMrBp2a0fQIlo
 uJI2xm1oyDTBA8q0y+sFGsGFf2Pe/tbPrJH3gT7Ta1B7dWBgP0hyUPv
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
 MAINTAINERS                                        |  7 ++++++
 2 files changed, 33 insertions(+)

diff --git a/Documentation/devicetree/bindings/mips/siflower.yaml b/Documentation/devicetree/bindings/mips/siflower.yaml
new file mode 100644
index 000000000000..33110f742cb7
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
index 93abbb315065..7fb18c2d6959 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25698,6 +25698,13 @@ N:	sifive
 K:	fu[57]40
 K:	[^@]sifive
 
+SIFLOWER SF19A2890 SOC SUPPORT
+M:	Joseph Telaak <joseph@telaak.dev>
+L:	linux-mips@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/mips/siflower.yaml
+N:	sf19a2890
+
 SILEAD TOUCHSCREEN DRIVER
 M:	Hans de Goede <hansg@kernel.org>
 L:	linux-input@vger.kernel.org

-- 
Git-155)

