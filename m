From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 09 Jun 2025 15:44:35 +0400
Subject: [PATCH v4 2/5] dt-bindings: net: qca,ar803x: Add IPQ5018 Internal
 GE PHY support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250609-ipq5018-ge-phy-v4-2-1d3a125282c3@outlook.com>
References: <20250609-ipq5018-ge-phy-v4-0-1d3a125282c3@outlook.com>
In-Reply-To: <20250609-ipq5018-ge-phy-v4-0-1d3a125282c3@outlook.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749469488; l=3044;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=8tq+dyWpkAV6yK1dP84pLDMuXHf2dAyZEQjNMgwHVw0=;
 b=87I9Ecn2ro99Wz5ynmhR1MFNCLL7yD2Es0ZMuKZnHjaeb7nc3MCirvC5lzxdBOVQrw9x/kn43
 TqB1RdJtMePA6ntMWXETxRsi5j9TaUyaMTlVnYFUO23IGyEDMuXg/Ku
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the IPQ5018 Internal Gigabit Ethernet PHY found in the IPQ5018
SoC. Its output pins provide an MDI interface to either an external
switch in a PHY to PHY link scenario or is directly attached to an RJ45
connector.

The PHY supports 10/100/1000 mbps link modes, CDT, auto-negotiation and
802.3az EEE.

For operation, the LDO controller found in the IPQ5018 SoC for which
there is provision in the mdio-4019 driver.

Two common archictures across IPQ5018 boards are:
1. IPQ5018 PHY --> MDI --> RJ45 connector
2. IPQ5018 PHY --> MDI --> External PHY
In a phy to phy architecture, the DAC needs to be configured to
accommodate for the short cable length. As such, add an optional boolean
property so the driver sets preset DAC register values accordingly.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../devicetree/bindings/net/qca,ar803x.yaml        | 44 ++++++++++++++++++++++
 1 file changed, 44 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/qca,ar803x.yaml b/Documentation/devicetree/bindings/net/qca,ar803x.yaml
index 3acd09f0da863137f8a05e435a1fd28a536c2acd..4ecba383baef34ca171c6e98dceede47071bb43d 100644
--- a/Documentation/devicetree/bindings/net/qca,ar803x.yaml
+++ b/Documentation/devicetree/bindings/net/qca,ar803x.yaml
@@ -16,8 +16,37 @@ description: |
 
 allOf:
   - $ref: ethernet-phy.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - ethernet-phy-id004d.d0c0
+
+    then:
+      properties:
+        reg:
+          const: 7  # This PHY is always at MDIO address 7 in the IPQ5018 SoC
+
+        resets:
+          items:
+            - description:
+                GE PHY MISC reset which triggers a reset across MDC, DSP, RX, and TX lines.
+
+        qcom,dac-preset-short-cable:
+          description:
+            Set if this phy is connected to another phy to adjust the values for
+            MDAC and EDAC to adjust amplitude, bias current settings, and error
+            detection and correction algorithm to accommodate for short cable length.
+            If not set, DAC values are not modified and it is assumed the MDI output pins
+            of this PHY are directly connected to an RJ45 connector.
+          type: boolean
 
 properties:
+  compatible:
+    enum:
+      - ethernet-phy-id004d.d0c0
+
   qca,clk-out-frequency:
     description: Clock output frequency in Hertz.
     $ref: /schemas/types.yaml#/definitions/uint32
@@ -132,3 +161,18 @@ examples:
             };
         };
     };
+  - |
+    #include <dt-bindings/reset/qcom,gcc-ipq5018.h>
+
+    mdio {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        /* add alias to set qcom,dac-preset-short-cable on boards that need it */
+        ge_phy: ethernet-phy@7 {
+            compatible = "ethernet-phy-id004d.d0c0";
+            reg = <7>;
+
+            resets = <&gcc GCC_GEPHY_MISC_ARES>;
+        };
+    };

-- 
2.49.0

