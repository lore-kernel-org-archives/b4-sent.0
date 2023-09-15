From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Fri, 15 Sep 2023 11:10:49 +0300
Subject: [PATCH v4 07/42] dt-bindings: power: reset: Add ep93xx reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230915-ep93xx-v4-7-a1d779dcec10@maquefel.me>
References: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
In-Reply-To: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Nikita Shubin <nikita.shubin@maquefel.me>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Arnd Bergmann <arnd@arndb.de>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1694765525; l=1426;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=I52sOmITYDAEad5VX3+fpK9zHNrJkryMKM/Emu0XkSM=;
 b=ZtroFVL5l1BXjZW9O7+Rvy4kPDH1r3mWCx53MerJIRqRsyqoeay/OjfOjFrXU/QtPDu3EVDszrKH
 F5WJpICTCOIlM1RKp8v7GkkVjVPteUPoBV3E1dJmO5b4s/h3kDWz
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add YAML bindings for ep93xx reset.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 .../bindings/power/reset/cirrus,ep9301-reboot.yaml | 34 ++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/reset/cirrus,ep9301-reboot.yaml b/Documentation/devicetree/bindings/power/reset/cirrus,ep9301-reboot.yaml
new file mode 100644
index 000000000000..a5a718dec4b5
--- /dev/null
+++ b/Documentation/devicetree/bindings/power/reset/cirrus,ep9301-reboot.yaml
@@ -0,0 +1,34 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/power/reset/cirrus,ep9301-reboot.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cirrus EP93xx SoC family reset controller
+
+maintainers:
+  - Alexander Sverdlin <alexander.sverdlin@gmail.com>
+  - Nikita Shubin <nikita.shubin@maquefel.me>
+
+properties:
+  compatible:
+    oneOf:
+      - const: cirrus,ep9301-reboot
+      - items:
+          - enum:
+              - cirrus,ep9302-reboot
+              - cirrus,ep9307-reboot
+              - cirrus,ep9312-reboot
+              - cirrus,ep9315-reboot
+          - const: cirrus,ep9301-reboot
+
+required:
+  - compatible
+
+additionalProperties: false
+
+examples:
+  - |
+    reboot {
+        compatible = "cirrus,ep9301-reboot";
+    };

-- 
2.39.2

