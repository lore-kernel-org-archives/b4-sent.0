From: Ciprian Regus <ciprian.regus@analog.com>
Date: Thu, 04 Jun 2026 19:32:46 +0300
Subject: [PATCH net-next v3 01/13] dt-bindings: net: Add ADIN1140
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-adin1140-driver-v3-1-5debdb3173c4@analog.com>
References: <20260604-adin1140-driver-v3-0-5debdb3173c4@analog.com>
In-Reply-To: <20260604-adin1140-driver-v3-0-5debdb3173c4@analog.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, devicetree@vger.kernel.org, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780590774; l=3033;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=SD0s7kL32zflcmzvhYpP4wswiaVrrA6tg9sWjWntb8Q=;
 b=z38lZROWZ8zoI1AIs66jVBqr6GbNaNYX226IDC0RneKOM2jFm53b0jOekbp2eH7xKxuQg3+OP
 qJ1piLfRjJ5CEU2G+9suuJSxcwuXJbs28i70wH3LtX+z3cl4OTxbxSd
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADIN1140 is a single port 10BASE-T1S Ethernet controller that
includes both the MAC and a PHY in the same package.

Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>

---
v3 changelog:
 - set adi,ad3306 as a fallback compatible.
v2 changelog:
 - Reorder the compatible entries in the dt schema (ad3306, adin1140).
 - Removed "dt-bindings" from the commit title and message.
 - Updated the DT example to use IRQ_TYPE_LEVEL_LOW instead of
   IRQ_TYPE_EDGE_FALLING for the interrupt trigger condition.
 - "implements" -> "tries to implement" in the description.
 - Removed the MAINTAINERS entry, as it will be added in a later patch
   in the series.
 - Reordered as the first patch of the series
---
 .../devicetree/bindings/net/adi,adin1140.yaml      | 71 ++++++++++++++++++++++
 1 file changed, 71 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/adi,adin1140.yaml b/Documentation/devicetree/bindings/net/adi,adin1140.yaml
new file mode 100644
index 000000000000..739429c46253
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/adi,adin1140.yaml
@@ -0,0 +1,71 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/adi,adin1140.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: ADI ADIN1140 10BASE-T1S MAC-PHY
+
+maintainers:
+  - Ciprian Regus <ciprian.regus@analog.com>
+
+description: |
+  The ADIN1140 (also called AD3306) is a low power single port
+  10BASE-T1S MAC-PHY. It integrates an Ethernet PHY with a MAC
+  and all the associated analog circuitry.
+  The device tries to implement the Open Alliance TC6 10BASE-T1x MAC-PHY
+  Serial Interface specification and is compliant with the
+  IEEE 802.3cg-2019 Ethernet standard for 10 Mbps single pair
+  Ethernet (SPE). The device has a 4-wire SPI interface for
+  communication between the MAC and host processor.
+
+allOf:
+  - $ref: /schemas/net/ethernet-controller.yaml#
+  - $ref: /schemas/spi/spi-peripheral-props.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - const: adi,adin1140
+          - const: adi,ad3306
+      - const: adi,ad3306
+
+  reg:
+    maxItems: 1
+
+  spi-max-frequency:
+    maximum: 25000000
+
+  interrupts:
+    maxItems: 1
+    description: Interrupt from the MAC-PHY for receive data available
+      and error conditions
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - spi-max-frequency
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        ethernet@0 {
+            compatible = "adi,ad3306";
+            reg = <0>;
+            spi-max-frequency = <23000000>;
+
+            interrupt-parent = <&gpio>;
+            interrupts = <6 IRQ_TYPE_LEVEL_LOW>;
+
+            local-mac-address = [ 00 11 22 33 44 55 ];
+        };
+    };

-- 
2.43.0

