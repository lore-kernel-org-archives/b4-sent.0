From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 03 Apr 2025 16:07:48 +0200
Subject: [PATCH 1/2] dt-bindings: net: wireless: Add Realtek RTL8188 USB
 WiFi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250403-rtl-onboard-v1-1-10ca9a6a4ee0@posteo.net>
References: <20250403-rtl-onboard-v1-0-10ca9a6a4ee0@posteo.net>
In-Reply-To: <20250403-rtl-onboard-v1-0-10ca9a6a4ee0@posteo.net>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.neuschaefer@gmx.net>, 
 Matthias Kaehlcke <mka@chromium.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743689273; l=1657;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=6b1it+r1AmIIbl9MaNmUVNJ7dqm/3ZZS4M5ZCpj+F30=;
 b=YDrrRB67eDRetNqSjtCKWOBuVpglvJnAwdFk9FRsZxPSlWBLXb2QLQpdO4Coc2iJyUZVpCj99
 BguwI22F9v+Dt7+EJp0PmVOUy58EegxjWqnkphLZu27KL4mR7ZcOqYU
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is an on-board USB device that requires a 3.3V supply.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 .../bindings/net/wireless/realtek,rtl8188.yaml     | 51 ++++++++++++++++++++++
 1 file changed, 51 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/wireless/realtek,rtl8188.yaml b/Documentation/devicetree/bindings/net/wireless/realtek,rtl8188.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..b637c71e3c4d81b47d338394b2e0a7772035c2c7
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/wireless/realtek,rtl8188.yaml
@@ -0,0 +1,51 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/wireless/realtek,rtl8188.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Realtek RTL8188 USB WiFi
+
+maintainers:
+  - J. Neuschäfer <j.neuschaefer@gmx.net>
+
+description:
+  The Realtek RTL8188 is a USB-connected 2.4 GHz WiFi module.
+  TODO- website or soemthing
+
+allOf:
+  - $ref: /schemas/usb/usb-device.yaml#
+
+properties:
+  compatible:
+    const: usbbda,179
+
+  reg: true
+
+  vdd-supply:
+    description:
+      Regulator for the 3V3 supply.
+
+required:
+  - compatible
+  - reg
+  - vdd-supply
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    usb {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        wifi: wifi@1 {
+            compatible = "usbbda,179";
+            reg = <1>;
+            vdd-supply = <&vcc3v3>;
+        };
+    };
+
+...

-- 
2.48.0.rc1.219.gb6b6757d772

