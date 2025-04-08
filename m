From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 08 Apr 2025 21:13:12 +0200
Subject: [PATCH v2 1/2] dt-bindings: net: wireless: Add Realtek RTL8188ETV
 USB WiFi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250408-rtl-onboard-v2-1-0b6730b90e31@posteo.net>
References: <20250408-rtl-onboard-v2-0-0b6730b90e31@posteo.net>
In-Reply-To: <20250408-rtl-onboard-v2-0-0b6730b90e31@posteo.net>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Matthias Kaehlcke <mka@chromium.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, Bitterblue Smith <rtl8821cerfe2@gmail.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744139638; l=2077;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=4nIhUGSI5Ng3z4pAy5LHnkaqH2Vjs66teKpBTHo1jxU=;
 b=+vY+V/NyRm4aQpt4QGCRdBd1HVGT5r1dsJSfIREdxcTqOB3DKIiMrYUpU1cEl4rcc02hiyeDx
 48hktykm3uHDQtYx43hY+hvBe+POUGq04XV6kV1FXjHHpE9PxKasWPO
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is an on-board USB device that requires a 3.3V supply.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

V2:
- Use my current email address
- Remove TODO comment
- Rename schema file to realtek,rtl8188e.yaml. This is the same
  granularity at which the rtl8xxxu driver is split into files, making
  it unnecessary to rename the schema file if another similar chip is added
  in the future.
- Change license identifier from (GPL-2.0 OR BSD-2-Clause) to (GPL-2.0-only
  OR BSD-2-Clause) because GPL-2.0 is ambiguous
---
 .../bindings/net/wireless/realtek,rtl8188e.yaml    | 50 ++++++++++++++++++++++
 1 file changed, 50 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/wireless/realtek,rtl8188e.yaml b/Documentation/devicetree/bindings/net/wireless/realtek,rtl8188e.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..2769731e07083b14e2f7388858dcded92c442018
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/wireless/realtek,rtl8188e.yaml
@@ -0,0 +1,50 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/wireless/realtek,rtl8188e.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Realtek RTL8188E USB WiFi
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net>
+
+description:
+  Realtek RTL8188E is a family of USB-connected 2.4 GHz WiFi modules.
+
+allOf:
+  - $ref: /schemas/usb/usb-device.yaml#
+
+properties:
+  compatible:
+    const: usbbda,179  # RTL8188ETV
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

