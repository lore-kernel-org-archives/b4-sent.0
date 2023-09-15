From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Fri, 15 Sep 2023 11:11:09 +0300
Subject: [PATCH v4 27/42] dt-bindings: ata: Add Cirrus EP93xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230915-ep93xx-v4-27-a1d779dcec10@maquefel.me>
References: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
In-Reply-To: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
To: Damien Le Moal <dlemoal@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-ide@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Arnd Bergmann <arnd@arndb.de>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1694765525; l=1509;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=DbMWLXuGCyyQJHZZBV/rVmcFRfTlaubiqRHcoupCo3g=;
 b=MIdnvAs4OfKYdORcyEWd+gwFSF99cx6WSzEHQUQN35+I+A1RLiEkn5wl2osMsUc86V6tJOT4ZLjU
 h32WR55QB2Fiqq5SW8AEXkylIldlcj7QRPdBm9V1V+COlr+NLZrn
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add YAML bindings for ep93xx SoC PATA.

Acked-by: Damien Le Moal <dlemoal@kernel.org>
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 .../bindings/ata/cirrus,ep9312-pata.yaml           | 42 ++++++++++++++++++++++
 1 file changed, 42 insertions(+)

diff --git a/Documentation/devicetree/bindings/ata/cirrus,ep9312-pata.yaml b/Documentation/devicetree/bindings/ata/cirrus,ep9312-pata.yaml
new file mode 100644
index 000000000000..8130923fdc72
--- /dev/null
+++ b/Documentation/devicetree/bindings/ata/cirrus,ep9312-pata.yaml
@@ -0,0 +1,42 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/ata/cirrus,ep9312-pata.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cirrus Logic EP9312 PATA controller
+
+maintainers:
+  - Damien Le Moal <dlemoal@kernel.org>
+
+properties:
+  compatible:
+    oneOf:
+      - const: cirrus,ep9312-pata
+      - items:
+          - const: cirrus,ep9315-pata
+          - const: cirrus,ep9312-pata
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - interrupts
+
+additionalProperties: false
+
+examples:
+  - |
+    ide@800a0000 {
+        compatible = "cirrus,ep9312-pata";
+        reg = <0x800a0000 0x38>;
+        interrupt-parent = <&vic1>;
+        interrupts = <8>;
+        pinctrl-names = "default";
+        pinctrl-0 = <&ide_default_pins>;
+    };

-- 
2.39.2

