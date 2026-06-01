From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 01 Jun 2026 17:19:08 +0400
Subject: [PATCH 1/3] dt-bindings: net: qca,ipq5018: Split IPQ5018 PHY
 bindings from ar803x
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-ipq5018-gephy-clocks-v1-1-2df8287712c3@outlook.com>
References: <20260601-ipq5018-gephy-clocks-v1-0-2df8287712c3@outlook.com>
In-Reply-To: <20260601-ipq5018-gephy-clocks-v1-0-2df8287712c3@outlook.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780319950; l=4946;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=zsshv5XwQ6s+2bhZxuItk5jzaYFbE1IDzznh2Ip/hvg=;
 b=l/HtaEnkoaMuqY27S6XK3iW/CtF8Y5Lumxm6quNMv57kyg72AeNvJssVOdckwf8TZ//qPOpPg
 Gn8NB0CNlcaAQ/G/6m2dgIUeOTeHsdvwjsTLLT3rghcKnQIOF4OHipd
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the definition for the Qualcomm IPQ5018 Internal PHY out of the
qca,ar803x.yaml binding file and isolate them in a dedicated
qca,ipq5018.yaml file. This is necessary due to the restriction of max
one clock in ethernet-phy.yaml which ar803x references as further
testing revealed that the RX and TX clocks of the IPQ5018 PHY need to
be explicitly enabled.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../devicetree/bindings/net/qca,ar803x.yaml        | 43 -------------
 .../devicetree/bindings/net/qca,ipq5018.yaml       | 75 ++++++++++++++++++++++
 2 files changed, 75 insertions(+), 43 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/qca,ar803x.yaml b/Documentation/devicetree/bindings/net/qca,ar803x.yaml
index 7ae5110e7aa2..3acd09f0da86 100644
--- a/Documentation/devicetree/bindings/net/qca,ar803x.yaml
+++ b/Documentation/devicetree/bindings/net/qca,ar803x.yaml
@@ -16,37 +16,8 @@ description: |
 
 allOf:
   - $ref: ethernet-phy.yaml#
-  - if:
-      properties:
-        compatible:
-          contains:
-            enum:
-              - ethernet-phy-id004d.d0c0
-
-    then:
-      properties:
-        reg:
-          const: 7  # This PHY is always at MDIO address 7 in the IPQ5018 SoC
-
-        resets:
-          items:
-            - description:
-                GE PHY MISC reset which triggers a reset across MDC, DSP, RX, and TX lines.
-
-        qcom,dac-preset-short-cable:
-          description:
-            Set if this phy is connected to another phy to adjust the values for
-            MDAC and EDAC to adjust amplitude, bias current settings, and error
-            detection and correction algorithm to accommodate for short cable length.
-            If not set, DAC values are not modified and it is assumed the MDI output pins
-            of this PHY are directly connected to an RJ45 connector.
-          type: boolean
 
 properties:
-  compatible:
-    enum:
-      - ethernet-phy-id004d.d0c0
-
   qca,clk-out-frequency:
     description: Clock output frequency in Hertz.
     $ref: /schemas/types.yaml#/definitions/uint32
@@ -161,17 +132,3 @@ examples:
             };
         };
     };
-  - |
-    #include <dt-bindings/reset/qcom,gcc-ipq5018.h>
-
-    mdio {
-        #address-cells = <1>;
-        #size-cells = <0>;
-
-        ge_phy: ethernet-phy@7 {
-            compatible = "ethernet-phy-id004d.d0c0";
-            reg = <7>;
-
-            resets = <&gcc GCC_GEPHY_MISC_ARES>;
-        };
-    };
diff --git a/Documentation/devicetree/bindings/net/qca,ipq5018.yaml b/Documentation/devicetree/bindings/net/qca,ipq5018.yaml
new file mode 100644
index 000000000000..7cdc96f6d389
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/qca,ipq5018.yaml
@@ -0,0 +1,75 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/qca,ipq5018.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm Atheros IPQ5018 Internal PHY
+
+maintainers:
+  - George Moussalem <george.moussalem@outlook.com>
+
+description: |
+  The IPQ5018 PHY is part of the IPQ5018 SoC and is always wired to GMAC0.
+  The PHY supports 10/100/1000 mbps link modes, CDT, auto-negotiation and
+  802.3az EEE.
+
+properties:
+  compatible:
+    const: ethernet-phy-id004d.d0c0
+
+  reg:
+    const: 7  # This PHY is always at MDIO address 7 in the IPQ5018 SoC
+
+  clocks:
+    items:
+      - description: RX clock
+      - description: TX clock
+
+  clock-names:
+    items:
+      - const: rx
+      - const: tx
+
+  resets:
+    items:
+      - description:
+          GE PHY MISC reset which triggers a reset across MDC, DSP, RX, and TX lines.
+
+  qcom,dac-preset-short-cable:
+    description: |
+      Set if this phy is connected to another phy to adjust the values for
+      MDAC and EDAC to adjust amplitude, bias current settings, and error
+      detection and correction algorithm to accommodate for short cable length.
+      If not set, DAC values are not modified and it is assumed the MDI output pins
+      of this PHY are directly connected to an RJ45 connector.
+    type: boolean
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+  - resets
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/qcom,gcc-ipq5018.h>
+    #include <dt-bindings/reset/qcom,gcc-ipq5018.h>
+
+    mdio {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        ge_phy: ethernet-phy@7 {
+            compatible = "ethernet-phy-id004d.d0c0";
+            reg = <7>;
+
+            clocks = <&gcc GCC_GEPHY_RX_CLK>,
+                     <&gcc GCC_GEPHY_TX_CLK>;
+            clock-names = "rx", "tx";
+            resets = <&gcc GCC_GEPHY_MISC_ARES>;
+        };
+    };

-- 
2.53.0

