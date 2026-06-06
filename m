From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 05 Jun 2026 22:42:46 -0700
Subject: [PATCH net-next v4 15/16] dt-bindings: net: add onsemi's S2500
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260605-s2500-mac-phy-support-v4-15-de0fbc13c6d8@onsemi.com>
References: <20260605-s2500-mac-phy-support-v4-0-de0fbc13c6d8@onsemi.com>
In-Reply-To: <20260605-s2500-mac-phy-support-v4-0-de0fbc13c6d8@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780724562; l=2795;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=HUXIze6RdB6ERxDfpaDuHws8RvRgXJ4TnBjjVkgB2pc=;
 b=aDrRaIi0388pStuo00JchezrNyo+dUok5/9yDCvmHd8t+I/CLsVWxLoD8eykZxPWt76fJrJCb
 B0p7gJWjcqJAefgMFEU+hs7Ibl1+aGhEfUIMm8+27ltYmUh4U5EIEwB
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add YAML device tree binding for the onsemi S2500 IEEE 802.3cg
compliant Ethernet transceiver device.

We use IRQF_TRIGGER_FALLING, though OPEN Alliance 10BASE-T1x
Serial Interface specification calls for IRQF_TRIGGER_LOW.

This is to match IRQF_TRIGGER_FALLING used by OA TC6 framework code.
This bug fix requires changes to the stable branch. At that time,
this will be changed to IRQF_TRIGGER_LOW.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
 .../devicetree/bindings/net/onnn,s2500.yaml        | 67 ++++++++++++++++++++++
 1 file changed, 67 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/onnn,s2500.yaml b/Documentation/devicetree/bindings/net/onnn,s2500.yaml
new file mode 100644
index 000000000000..11edf10508d9
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/onnn,s2500.yaml
@@ -0,0 +1,67 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/onnn,s2500.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: onsemi S2500 10BASE-T1S MACPHY Ethernet Controllers
+
+maintainers:
+  - Piergiorgio Beruto <pier.beruto@onsemi.com>
+  - Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>
+
+description:
+  The S2500 combines a Media Access Controller (MAC) and an
+  Ethernet PHY to enable 10BASE‑T1S networks. The Ethernet Media Access
+  Controller (MAC) module implements a 10 Mbps half duplex Ethernet MAC,
+  compatible with the IEEE 802.3 standard and a 10BASE-T1S physical layer
+  transceiver integrated into the S2500. The communication between
+  the host and the MAC-PHY is specified in the OPEN Alliance 10BASE-T1x
+  MACPHY Serial Interface (TC6).
+
+allOf:
+  - $ref: /schemas/net/ethernet-controller.yaml#
+  - $ref: /schemas/spi/spi-peripheral-props.yaml#
+
+properties:
+  compatible:
+    const: onnn,s2500
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    description:
+      Interrupt from MAC-PHY asserted in the event of Receive Chunks
+      Available, Transmit Chunk Credits Available and Extended Status
+      Event.
+    maxItems: 1
+
+  spi-max-frequency:
+    maximum: 25000000
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
+    spi {
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      ethernet@0 {
+        compatible = "onnn,s2500";
+        reg = <0>;
+        pinctrl-names = "default";
+        pinctrl-0 = <&eth0_pins>;
+        interrupt-parent = <&gpio>;
+        interrupts = <25 IRQ_TYPE_EDGE_FALLING>;
+        spi-max-frequency = <15000000>;
+      };
+    };

-- 
2.43.0

