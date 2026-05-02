From: Ciprian Regus <ciprian.regus@analog.com>
Date: Sun, 03 May 2026 02:24:54 +0300
Subject: [PATCH net-next 5/5] dt-bindings: net: Add bindings for the
 ADIN1140
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260503-adin1140-driver-v1-5-dd043cdd88f0@analog.com>
References: <20260503-adin1140-driver-v1-0-dd043cdd88f0@analog.com>
In-Reply-To: <20260503-adin1140-driver-v1-0-dd043cdd88f0@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777764335; l=2909;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=fsypCuzG+8KsvoEcvGQ6yCJv/rH7hOitcPb70G23Ry8=;
 b=IfQ3JGxqRuCDGFpO/P9bRwjhIFJQOyUBMejKbfs/rBS33QxPU7X5rXn5hE4r4EhqBykipUBB2
 dkVrqgIOr5ZAehaPGZErUqfkPGoO24jQjlt5vghv6N9DQoutLODifLf
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DT bindings for the ADIN1140 10BASE-T1S MACPHY. Update the
MAINTAINERS entry to include the bindings file as well.

Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>
---
 .../devicetree/bindings/net/adi,adin1140.yaml      | 69 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 70 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/adi,adin1140.yaml b/Documentation/devicetree/bindings/net/adi,adin1140.yaml
new file mode 100644
index 000000000000..26cd40d36f9b
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/adi,adin1140.yaml
@@ -0,0 +1,69 @@
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
+  The device implements the Open Alliance TC6 10BASE-T1x MAC-PHY
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
+    enum:
+      - adi,adin1140
+      - adi,ad3306
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
+            compatible = "adi,adin1140";
+            reg = <0>;
+            spi-max-frequency = <23000000>;
+
+            interrupt-parent = <&gpio>;
+            interrupts = <6 IRQ_TYPE_EDGE_FALLING>;
+
+            local-mac-address = [ 00 11 22 33 44 55 ];
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index f9784c25beac..55e1e78fe04e 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1848,6 +1848,7 @@ M:	Ciprian Regus <ciprian.regus@analog.com>
 L:	netdev@vger.kernel.org
 S:	Maintained
 W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/net/adi,adin1140.yaml
 F:	drivers/net/ethernet/adi/adin1140.c
 
 ANALOG DEVICES INC ETHERNET PHY DRIVERS

-- 
2.43.0

