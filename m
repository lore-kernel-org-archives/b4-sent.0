From: Yang Li <yang.li@amlogic.com>
Date: Thu, 18 Jul 2024 15:42:19 +0800
Subject: [PATCH v2 1/3] dt-bindings: net: bluetooth: Add support for
 Amlogic Bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-btaml-v2-1-1392b2e21183@amlogic.com>
References: <20240718-btaml-v2-0-1392b2e21183@amlogic.com>
In-Reply-To: <20240718-btaml-v2-0-1392b2e21183@amlogic.com>
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>
Cc: linux-bluetooth@vger.kernel.org, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721288574; l=2303;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=NKfAxG46ev+07V5JY7lMTYG79SYAEMUTi1t2oAUebxk=;
 b=jsgDStLviGT7mtA3ZU/XMwos7ZYmLuGJkJ+hvVDc9KbANvD3w8LRmEjz7QsmrH/1NmSgX/PQN
 isyZRrRo3pvA38npP8NqmOjOYsHXjbq8rZcX59+bJBuS+H+DgvQ7elS
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add binding document for Amlogic Bluetooth chipsets attached over UART.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 .../bindings/net/bluetooth/amlogic,w155s2-bt.yaml  | 66 ++++++++++++++++++++++
 1 file changed, 66 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/bluetooth/amlogic,w155s2-bt.yaml b/Documentation/devicetree/bindings/net/bluetooth/amlogic,w155s2-bt.yaml
new file mode 100644
index 000000000000..2e433d5692ff
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/bluetooth/amlogic,w155s2-bt.yaml
@@ -0,0 +1,66 @@
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
+  This binding describes UART-attached Amlogic bluetooth chips.
+
+maintainers:
+  - Yang Li <yang.li@amlogic.com>
+
+properties:
+  compatible:
+    oneOf:
+      - const: amlogic,w155s2-bt
+      - items:
+          - enum:
+              - amlogic,w265s1-bt
+              - amlogic,w265p1-bt
+              - amlogic,w265s2-bt
+          - const: amlogic,w155s2-bt
+
+  bt-enable-gpios:
+    maxItems: 1
+    description: gpio specifier used to enable BT
+
+  bt-supply:
+    description: bluetooth chip 3.3V supply regulator handle
+
+  clocks:
+    maxItems: 1
+    description: clock provided to the controller (32.768KHz)
+
+  antenna-number:
+    default: 1
+    description: device supports up to two antennas
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+  firmware-name:
+    description: specify the path of firmware bin to load
+    $ref: /schemas/types.yaml#/definitions/string-array
+
+required:
+  - compatible
+  - bt-enable-gpios
+  - bt-supply
+  - clocks
+  - firmware-name
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    bluetooth {
+        compatible = "amlogic,w155s2-bt";
+        bt-enable-gpios = <&gpio 17 GPIO_ACTIVE_HIGH>;
+        bt-supply = <&wcn_3v3>;
+        clocks = <&extclk>;
+        firmware-name = "amlogic/aml_w155s2_bt_uart.bin";
+    };
+

-- 
2.42.0

