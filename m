From: Yang Xiwen <forbidden405@outlook.com>
Date: Wed, 28 Feb 2024 17:02:25 +0800
Subject: [PATCH net-next v6 01/11] dt-bindings: net: hisilicon-femac-mdio:
 convert to YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240228-net-v6-1-6d78d3d598c1@outlook.com>
References: <20240228-net-v6-0-6d78d3d598c1@outlook.com>
In-Reply-To: <20240228-net-v6-0-6d78d3d598c1@outlook.com>
To: Yisen Zhuang <yisen.zhuang@huawei.com>, 
 Salil Mehta <salil.mehta@huawei.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709110945; l=2517;
 i=forbidden405@outlook.com; s=20240228; h=from:subject:message-id;
 bh=stv+a/mRLJaLswc2WeXjirfjJSRDl5txIs38K87wIhs=;
 b=i1QaEYVqRNc6pkZ4uX161aYrm7OD2YSAFoOgERKGJfSFK2ZjbiYbDqqEDwyy5cIIYKnLtKI6J
 HK+Uzvx/VM+AbdcME0LUNo5her3rhWVIx26dTSG3v6MXupJM28hiP4z
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=KAWv6ZzFsT54MGllOczJgFiWB+DuayEmyn24iiVVThU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20240228 with auth_id=136
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

convert the old text binding to modern YAML based binding. No semantic
change.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../bindings/net/hisilicon,hisi-femac-mdio.yaml    | 44 ++++++++++++++++++++++
 .../bindings/net/hisilicon-femac-mdio.txt          | 22 -----------
 2 files changed, 44 insertions(+), 22 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac-mdio.yaml b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac-mdio.yaml
new file mode 100644
index 000000000000..36def9d5eecd
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac-mdio.yaml
@@ -0,0 +1,44 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/hisilicon,hisi-femac-mdio.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: HiSilicon FEMAC MDIO bus
+
+maintainers:
+  - Yang Xiwen <forbidden405@formail.com>
+
+allOf:
+  - $ref: mdio.yaml#
+
+properties:
+  compatible:
+    const: hisilicon,hisi-femac-mdio
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - clocks
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    mdio@10091100 {
+        compatible = "hisilicon,hisi-femac-mdio";
+        reg = <0x10091100 0x20>;
+        clocks = <&clk_mdio>;
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        phy@1 {
+            reg = <1>;
+        };
+    };
diff --git a/Documentation/devicetree/bindings/net/hisilicon-femac-mdio.txt b/Documentation/devicetree/bindings/net/hisilicon-femac-mdio.txt
deleted file mode 100644
index 23a39a309d17..000000000000
--- a/Documentation/devicetree/bindings/net/hisilicon-femac-mdio.txt
+++ /dev/null
@@ -1,22 +0,0 @@
-Hisilicon Fast Ethernet MDIO Controller interface
-
-Required properties:
-- compatible: should be "hisilicon,hisi-femac-mdio".
-- reg: address and length of the register set for the device.
-- clocks: A phandle to the reference clock for this device.
-
-- PHY subnode: inherits from phy binding [1]
-[1] Documentation/devicetree/bindings/net/phy.txt
-
-Example:
-mdio: mdio@10091100 {
-	compatible = "hisilicon,hisi-femac-mdio";
-	reg = <0x10091100 0x10>;
-	clocks = <&crg HI3516CV300_MDIO_CLK>;
-	#address-cells = <1>;
-	#size-cells = <0>;
-
-	phy0: phy@1 {
-		reg = <1>;
-	};
-};

-- 
2.43.0

