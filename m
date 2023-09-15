From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Fri, 15 Sep 2023 11:10:47 +0300
Subject: [PATCH v4 05/42] dt-bindings: pinctrl: Add Cirrus EP93xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230915-ep93xx-v4-5-a1d779dcec10@maquefel.me>
References: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
In-Reply-To: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Nikita Shubin <nikita.shubin@maquefel.me>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Arnd Bergmann <arnd@arndb.de>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1694765525; l=2116;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=bK/ofpUsuxYmv6fuKZVUudz6ww/jwSK1B72cojrFW8s=;
 b=7OJUtaO82nOu4x7xPTuOK6Typ/ue8WcYNbIdDDYu+jw77DmKDfacr16Q9zQpmCDXjBWMNh1Kr81Y
 DKJhsmNqDFEG9p+ap5iKNA4Co975BwINjRWVn9BzsV4pw8/Itwsx
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add YAML bindings for ep93xx SoC pinctrl.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
Reviewed-by: Linus Walleij <linus.walleij@linaro.org>
---
 .../bindings/pinctrl/cirrus,ep9301-pinctrl.yaml    | 57 ++++++++++++++++++++++
 1 file changed, 57 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/cirrus,ep9301-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/cirrus,ep9301-pinctrl.yaml
new file mode 100644
index 000000000000..1dbdc5ccc232
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/cirrus,ep9301-pinctrl.yaml
@@ -0,0 +1,57 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/cirrus,ep9301-pinctrl.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cirrus ep93xx pins mux controller
+
+maintainers:
+  - Nikita Shubin <nikita.shubin@maquefel.me>
+  - Alexander Sverdlin <alexander.sverdlin@gmail.com>
+
+properties:
+  compatible:
+    oneOf:
+      - const: cirrus,ep9301-pinctrl
+      - items:
+          - enum:
+              - cirrus,ep9302-pinctrl
+              - cirrus,ep9307-pinctrl
+              - cirrus,ep9312-pinctrl
+              - cirrus,ep9315-pinctrl
+          - const: cirrus,ep9301-pinctrl
+
+patternProperties:
+  '^pins-':
+    type: object
+    description: pin node
+    $ref: pinmux-node.yaml#
+
+    properties:
+      function:
+        enum: [ spi, ac97, i2s, pwm, keypad, pata, lcd, gpio ]
+
+      groups:
+        enum: [ ssp, ac97, i2s_on_ssp, i2s_on_ac97, pwm1, gpio1agrp,
+                gpio2agrp, gpio3agrp, gpio4agrp, gpio6agrp, gpio7agrp,
+                rasteronsdram0grp, rasteronsdram3grp, keypadgrp, idegrp ]
+
+    required:
+      - function
+      - groups
+
+required:
+  - compatible
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    pinctrl {
+      compatible = "cirrus,ep9312-pinctrl", "cirrus,ep9301-pinctrl";
+      spi_default_pins: pins-spi {
+        function = "spi";
+        groups = "ssp";
+      };
+    };

-- 
2.39.2

