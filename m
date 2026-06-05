From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 05 Jun 2026 16:41:27 +0400
Subject: [PATCH v3 2/4] dt-bindings: net: qca,ar803x: Add clocks for
 IPQ5018 PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-ipq5018-gephy-clocks-v3-2-f232d9ca0966@outlook.com>
References: <20260605-ipq5018-gephy-clocks-v3-0-f232d9ca0966@outlook.com>
In-Reply-To: <20260605-ipq5018-gephy-clocks-v3-0-f232d9ca0966@outlook.com>
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
 George Moussalem <george.moussalem@outlook.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780663297; l=1860;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=9Z6aakN1HhLaGxa1OIpuGJQY0KdKMjoTdfWwUAWMHF8=;
 b=35vQ31A2+T17FdYHX7YbK3+f5sFkkYEKYcD//bJOBSMWqZ/OLQc7yybfbzinL6bN6VT3HtvsI
 HtS42u2mHmVAmzwfUK7DmlabPItaAz96c6JMzn7Fm1rl0Jok8KiZmES
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Further testing revealed that the RX and TX clocks of the IPQ5018 PHY
need to be explicitly enabled. As such, add the required clocks to the
schema.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 Documentation/devicetree/bindings/net/qca,ar803x.yaml | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/qca,ar803x.yaml b/Documentation/devicetree/bindings/net/qca,ar803x.yaml
index 7ae5110e7aa2..53f648c4135f 100644
--- a/Documentation/devicetree/bindings/net/qca,ar803x.yaml
+++ b/Documentation/devicetree/bindings/net/qca,ar803x.yaml
@@ -28,6 +28,16 @@ allOf:
         reg:
           const: 7  # This PHY is always at MDIO address 7 in the IPQ5018 SoC
 
+        clocks:
+          items:
+            - description: RX clock
+            - description: TX clock
+
+        clock-names:
+          items:
+            - const: rx
+            - const: tx
+
         resets:
           items:
             - description:
@@ -42,6 +52,11 @@ allOf:
             of this PHY are directly connected to an RJ45 connector.
           type: boolean
 
+      required:
+        - clocks
+        - clock-names
+        - resets
+
 properties:
   compatible:
     enum:
@@ -162,6 +177,7 @@ examples:
         };
     };
   - |
+    #include <dt-bindings/clock/qcom,gcc-ipq5018.h>
     #include <dt-bindings/reset/qcom,gcc-ipq5018.h>
 
     mdio {
@@ -172,6 +188,9 @@ examples:
             compatible = "ethernet-phy-id004d.d0c0";
             reg = <7>;
 
+            clocks = <&gcc GCC_GEPHY_RX_CLK>,
+                     <&gcc GCC_GEPHY_TX_CLK>;
+            clock-names = "rx", "tx";
             resets = <&gcc GCC_GEPHY_MISC_ARES>;
         };
     };

-- 
2.53.0

