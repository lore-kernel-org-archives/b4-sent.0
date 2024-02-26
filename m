From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Mon, 26 Feb 2024 10:30:08 +0300
Subject: [PATCH v8 12/38] dt-bindings: pwm: Add Cirrus EP93xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240226-ep93xx-v8-12-3136dca7238f@maquefel.me>
References: <20240226-ep93xx-v8-0-3136dca7238f@maquefel.me>
In-Reply-To: <20240226-ep93xx-v8-0-3136dca7238f@maquefel.me>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Nikita Shubin <nikita.shubin@maquefel.me>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Arnd Bergmann <arnd@arndb.de>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708932678; l=1848;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=yiCeIO46pBt38m6arFX6dYafL64TrLSuKy+InISqKkU=;
 b=/ooglb4B595ly1L082Ry8IkNCo2FqMyYUuZBjAA4pBKqQuMeqXfwyaDAqC2zLCdk67XIZ0r7Jza2
 bx0wekPRCzRkP5IVJgjj/p3YFFBPCcoQazlGDwGnviUNI/OWl5ha
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add YAML bindings for ep93xx SoC PWM.

Acked-by: Uwe Kleine-König <u.kleine-koenig@pengutronix.de>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 .../devicetree/bindings/pwm/cirrus,ep9301-pwm.yaml | 53 ++++++++++++++++++++++
 1 file changed, 53 insertions(+)

diff --git a/Documentation/devicetree/bindings/pwm/cirrus,ep9301-pwm.yaml b/Documentation/devicetree/bindings/pwm/cirrus,ep9301-pwm.yaml
new file mode 100644
index 000000000000..903210ef9c31
--- /dev/null
+++ b/Documentation/devicetree/bindings/pwm/cirrus,ep9301-pwm.yaml
@@ -0,0 +1,53 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pwm/cirrus,ep9301-pwm.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cirrus Logic ep93xx PWM controller
+
+maintainers:
+  - Alexander Sverdlin <alexander.sverdlin@gmail.com>
+  - Nikita Shubin <nikita.shubin@maquefel.me>
+
+allOf:
+  - $ref: pwm.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - const: cirrus,ep9301-pwm
+      - items:
+          - enum:
+              - cirrus,ep9302-pwm
+              - cirrus,ep9307-pwm
+              - cirrus,ep9312-pwm
+              - cirrus,ep9315-pwm
+          - const: cirrus,ep9301-pwm
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    items:
+      - description: SoC PWM clock
+
+  "#pwm-cells":
+    const: 3
+
+required:
+  - compatible
+  - reg
+  - clocks
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/cirrus,ep9301-syscon.h>
+    pwm@80910000 {
+        compatible = "cirrus,ep9301-pwm";
+        reg = <0x80910000 0x10>;
+        clocks = <&syscon EP93XX_CLK_PWM>;
+        #pwm-cells = <3>;
+    };

-- 
2.41.0

