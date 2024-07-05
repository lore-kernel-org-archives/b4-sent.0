From: Yang Li <yang.li@amlogic.com>
Date: Fri, 05 Jul 2024 19:20:44 +0800
Subject: [PATCH 1/4] dt-bindings: net: bluetooth: Add support for Amlogic
 Bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240705-btaml-v1-1-7f1538f98cef@amlogic.com>
References: <20240705-btaml-v1-0-7f1538f98cef@amlogic.com>
In-Reply-To: <20240705-btaml-v1-0-7f1538f98cef@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720178456; l=2284;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=9LhSM/sGy9FBnVW5ZXfyCBNi8BxU5wP7j6d7UIGPrbU=;
 b=GywkG4KO65SkzM2yOtSrlbEfdOHCEaL8uN4ft+XKfEfaqBrtv7MlRds1SSK8iS0plPFRm0/TK
 9FoUz5U23tsCTk+SjEZeuPFRypBj+wCo7PsEWBKycLv4GR7ndSZ8fHy
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add binding document for Amlogic Bluetooth chipsets attached over UART.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 .../bindings/net/bluetooth/amlogic,w155s2-bt.yaml  | 62 ++++++++++++++++++++++
 1 file changed, 62 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/bluetooth/amlogic,w155s2-bt.yaml b/Documentation/devicetree/bindings/net/bluetooth/amlogic,w155s2-bt.yaml
new file mode 100644
index 000000000000..d59e3206af62
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/bluetooth/amlogic,w155s2-bt.yaml
@@ -0,0 +1,62 @@
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
+  amlogic,wcn-pwrseq:
+    default: 0
+    description: specify the power sequence used to power on Bluetooth
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+  amlogic,firmware:
+    description: specify the path of firmware bin to load
+    $ref: /schemas/types.yaml#/definitions/string-array
+
+  amlogic,antenna-number:
+    default: 1
+    description: number of antenna
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+  amlogic,a2dp-sink-enable:
+    default: 0
+    description: enable sink mode with controller
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+required:
+  - compatible
+  - amlogic,wcn-pwrseq
+  - amlogic,firmware
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    serial {
+        bluetooth {
+            compatible = "amlogic,w155s2-bt";
+            amlogic,wcn-pwrseq = <1>;
+            amlogic,firmware = "amlogic/aml_w155s2_bt_uart.bin";
+        };
+    };

-- 
2.42.0

