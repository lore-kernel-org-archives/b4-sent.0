From: Yang Li <yang.li@amlogic.com>
Date: Fri, 09 Aug 2024 13:42:24 +0800
Subject: [PATCH v4 1/3] dt-bindings: net: bluetooth: Add support for
 Amlogic Bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240809-btaml-v4-1-376b284405a7@amlogic.com>
References: <20240809-btaml-v4-0-376b284405a7@amlogic.com>
In-Reply-To: <20240809-btaml-v4-0-376b284405a7@amlogic.com>
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>
Cc: linux-bluetooth@vger.kernel.org, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Yang Li <yang.li@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723182152; l=2227;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=fCyoX+AnuaJrE//USqykfOes2DIAQw09k3gJ7c/oY2k=;
 b=aL6xK80lWiSlJEJWs2YuSWUEg7xxYXgeh1tuWbihxwS4rTcu1gNUY6tn2Stndbag2jIR8tmME
 rgobOu7U6wDCQ1mzD2grD2XR+dBdFoPlmKIyQrFJV2jhduSSQRTEmvS
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add binding document for Amlogic Bluetooth chipsets attached over UART.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 .../bindings/net/bluetooth/amlogic,w155s2-bt.yaml  | 63 ++++++++++++++++++++++
 1 file changed, 63 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/bluetooth/amlogic,w155s2-bt.yaml b/Documentation/devicetree/bindings/net/bluetooth/amlogic,w155s2-bt.yaml
new file mode 100644
index 000000000000..6fd7557039d2
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/bluetooth/amlogic,w155s2-bt.yaml
@@ -0,0 +1,63 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2024 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/bluetooth/amlogic,w155s2-bt.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic Bluetooth chips
+
+description:
+  The W155S2 is an Amlogic Bluetooth and Wi-Fi combo chip. It works on
+  the standard H4 protocol via a 4-wire UART interface, with baud rates
+  up to 4 Mbps.
+
+maintainers:
+  - Yang Li <yang.li@amlogic.com>
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - enum:
+              - amlogic,w265s1-bt
+              - amlogic,w265p1-bt
+          - const: amlogic,w155s2-bt
+      - enum:
+          - amlogic,w155s2-bt
+          - amlogic,w265s2-bt
+
+  clocks:
+    maxItems: 1
+    description: clock provided to the controller (32.768KHz)
+
+  enable-gpios:
+    maxItems: 1
+
+  vddio-supply:
+    description: VDD_IO supply regulator handle
+
+  firmware-name:
+    maxItems: 1
+    description: specify the path of firmware bin to load
+
+required:
+  - compatible
+  - clocks
+  - enable-gpios
+  - vddio-supply
+  - firmware-name
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    bluetooth {
+        compatible = "amlogic,w155s2-bt";
+        clocks = <&extclk>;
+        enable-gpios = <&gpio 17 GPIO_ACTIVE_HIGH>;
+        vddio-supply = <&wcn_3v3>;
+        firmware-name = "amlogic/aml_w155s2_bt_uart.bin";
+    };
+

-- 
2.42.0

