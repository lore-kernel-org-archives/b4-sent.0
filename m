From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Tue, 26 Mar 2024 12:18:37 +0300
Subject: [PATCH v9 10/38] dt-bindings: watchdog: Add Cirrus EP93x
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240326-ep93xx-v9-10-156e2ae5dfc8@maquefel.me>
References: <20240326-ep93xx-v9-0-156e2ae5dfc8@maquefel.me>
In-Reply-To: <20240326-ep93xx-v9-0-156e2ae5dfc8@maquefel.me>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Nikita Shubin <nikita.shubin@maquefel.me>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
Cc: linux-watchdog@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Arnd Bergmann <arnd@arndb.de>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711444837; l=1622;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=oi1524pxijJgURrfk58fykAJeXaA1N46ukZR7iTBG5Q=;
 b=FpHUmegdhxnoV91FGq5qRysw2a3NDcqHZ+2Lith/TKm2MvPHozojQhycrNcAuCp/Ao2Tkj6nAbfQ
 EDnrg5TkAxRG7DB80wHcTLGYBaCphz6ixJTDSXr5ycnRWX4eS2Cu
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree bindings for the Cirrus Logic EP93xx watchdog block
used in these SoCs.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 .../bindings/watchdog/cirrus,ep9301-wdt.yaml       | 42 ++++++++++++++++++++++
 1 file changed, 42 insertions(+)

diff --git a/Documentation/devicetree/bindings/watchdog/cirrus,ep9301-wdt.yaml b/Documentation/devicetree/bindings/watchdog/cirrus,ep9301-wdt.yaml
new file mode 100644
index 000000000000..5dbe891c70c6
--- /dev/null
+++ b/Documentation/devicetree/bindings/watchdog/cirrus,ep9301-wdt.yaml
@@ -0,0 +1,42 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/watchdog/cirrus,ep9301-wdt.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cirrus Logic EP93xx Watchdog Timer
+
+maintainers:
+  - Nikita Shubin <nikita.shubin@maquefel.me>
+  - Alexander Sverdlin <alexander.sverdlin@gmail.com>
+
+allOf:
+  - $ref: watchdog.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - const: cirrus,ep9301-wdt
+      - items:
+          - enum:
+              - cirrus,ep9302-wdt
+              - cirrus,ep9307-wdt
+              - cirrus,ep9312-wdt
+              - cirrus,ep9315-wdt
+          - const: cirrus,ep9301-wdt
+
+  reg:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    watchdog@80940000 {
+        compatible = "cirrus,ep9301-wdt";
+        reg = <0x80940000 0x08>;
+    };

-- 
2.41.0

