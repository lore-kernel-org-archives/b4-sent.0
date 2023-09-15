From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Fri, 15 Sep 2023 11:11:13 +0300
Subject: [PATCH v4 31/42] dt-bindings: wdt: Add ts72xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230915-ep93xx-v4-31-a1d779dcec10@maquefel.me>
References: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
In-Reply-To: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Nikita Shubin <nikita.shubin@maquefel.me>
Cc: linux-watchdog@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Arnd Bergmann <arnd@arndb.de>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1694765525; l=1618;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=RU7BGPJdygzLxD9nFWrzFwn5EiUB5p7KsaAjUEvthxc=;
 b=9/inJrUTu3vAqYIQHoNTHYl4Zrw/sih1PaakLy8UueZLlnKgAdqfNOiElOg9HMW5oKNXJFxpUAVu
 7Ln1mKxqCFy0c92qVlcOItuOwPNakPEUA8fErTSMDN2uiyPTHcK3
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DT binding for Technologic Systems TS-72xx watchdog.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 .../bindings/watchdog/technologic,ts7200-wdt.yaml  | 45 ++++++++++++++++++++++
 1 file changed, 45 insertions(+)

diff --git a/Documentation/devicetree/bindings/watchdog/technologic,ts7200-wdt.yaml b/Documentation/devicetree/bindings/watchdog/technologic,ts7200-wdt.yaml
new file mode 100644
index 000000000000..7e4bfef152f8
--- /dev/null
+++ b/Documentation/devicetree/bindings/watchdog/technologic,ts7200-wdt.yaml
@@ -0,0 +1,45 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/watchdog/technologic,ts7200-wdt.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Technologic Systems TS-72xx based SBCs watchdog
+
+maintainers:
+  - Nikita Shubin <nikita.shubin@maquefel.me>
+
+allOf:
+  - $ref: watchdog.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - const: technologic,ts7200-wdt
+      - items:
+          - enum:
+              - technologic,ts7300-wdt
+              - technologic,ts7260-wdt
+              - technologic,ts7250-wdt
+          - const: technologic,ts7200-wdt
+
+  reg:
+    items:
+      - description: control register
+      - description: feed register
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    watchdog@23800000 {
+      compatible = "technologic,ts7200-wdt";
+      reg = <0x23800000 0x01>, <0x23c00000 0x01>;
+      timeout-sec = <30>;
+    };
+
+...

-- 
2.39.2

