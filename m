From: Yang Xiwen <forbidden405@outlook.com>
Date: Wed, 28 Feb 2024 17:02:28 +0800
Subject: [PATCH net-next v6 04/11] dt-bindings: net: convert hisi-femac.txt
 to YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240228-net-v6-4-6d78d3d598c1@outlook.com>
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
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709110945; l=4845;
 i=forbidden405@outlook.com; s=20240228; h=from:subject:message-id;
 bh=PSEYqEoYzlBBu6yX+HTyEhlHFF2ZYTm301mnnQnq38Y=;
 b=ZP584DCe7m2JsV2i8t41Oc/Bj1Kq+fSH3N/8PxPPsyp++ETHiLDLeL1UpRhPuRsFdrWujvWQt
 vUQNDB2HqcADmTzrtd9dSG3y+D/ioASCxCIHwVpApWhcwq0OohvsMmo
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=KAWv6ZzFsT54MGllOczJgFiWB+DuayEmyn24iiVVThU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20240228 with auth_id=136
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

convert the old text biinding to new YAML. No semantic change.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../bindings/net/hisilicon,hisi-femac.yaml         | 82 ++++++++++++++++++++++
 .../devicetree/bindings/net/hisilicon-femac.txt    | 41 -----------
 2 files changed, 82 insertions(+), 41 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
new file mode 100644
index 000000000000..016e9e409a30
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
@@ -0,0 +1,82 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/hisilicon,hisi-femac.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Hisilicon Fast Ethernet MAC controller
+
+maintainers:
+  - Yang Xiwen <forbidden405@foxmail.com>
+
+allOf:
+  - $ref: ethernet-controller.yaml
+
+properties:
+  compatible:
+    items:
+      - enum:
+          - hisilicon,hi3516cv300-femac
+      - enum:
+          - hisilicon,hisi-femac-v1
+          - hisilicon,hisi-femac-v2
+
+  reg:
+    items:
+      - description: The first region is the MAC core register base and size.
+      - description: The second region is the global MAC control register.
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    items:
+      - description: MAC main clock
+
+  resets:
+    items:
+      - description: MAC reset signal
+      - description: PHY reset signal
+
+  reset-names:
+    items:
+      - const: mac
+      - const: phy
+
+  hisilicon,phy-reset-delays-us:
+    description: PHY reset timing requirement (in micro seconds).
+      The integrated PHY usually have a special reset timing sequence and must
+      interact with MAC controller to accomplish the entire reset procedure. So
+      these properties belong to MAC controller, not PHY.
+    items:
+      - description: pre-reset delay for PHY
+      - description: reset pulse for PHY
+      - description: post-reset delay for PHY
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - resets
+  - reset-names
+  - phy-mode
+  - phy-handle
+  - hisilicon,phy-reset-delays-us
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    ethernet@10090000 {
+        compatible = "hisilicon,hi3516cv300-femac", "hisilicon,hisi-femac-v2";
+        reg = <0x10090000 0x1000>, <0x10091300 0x200>;
+        interrupts = <12>;
+        clocks = <&clk_femac>;
+        resets = <&crg 0xec 0>, <&crg 0xec 3>;
+        reset-names = "mac", "phy";
+        mac-address = [00 00 00 00 00 00];
+        phy-mode = "mii";
+        phy-handle = <&fephy>;
+        hisilicon,phy-reset-delays-us = <10000 20000 20000>;
+    };
diff --git a/Documentation/devicetree/bindings/net/hisilicon-femac.txt b/Documentation/devicetree/bindings/net/hisilicon-femac.txt
deleted file mode 100644
index 5f96976f3cea..000000000000
--- a/Documentation/devicetree/bindings/net/hisilicon-femac.txt
+++ /dev/null
@@ -1,41 +0,0 @@
-Hisilicon Fast Ethernet MAC controller
-
-Required properties:
-- compatible: should contain one of the following version strings:
-	* "hisilicon,hisi-femac-v1"
-	* "hisilicon,hisi-femac-v2"
-	and the soc string "hisilicon,hi3516cv300-femac".
-- reg: specifies base physical address(s) and size of the device registers.
-  The first region is the MAC core register base and size.
-  The second region is the global MAC control register.
-- interrupts: should contain the MAC interrupt.
-- clocks: A phandle to the MAC main clock.
-- resets: should contain the phandle to the MAC reset signal(required) and
-	the PHY reset signal(optional).
-- reset-names: should contain the reset signal name "mac"(required)
-	and "phy"(optional).
-- phy-mode: see ethernet.txt [1].
-- phy-handle: see ethernet.txt [1].
-- hisilicon,phy-reset-delays-us: triplet of delays if PHY reset signal given.
-	The 1st cell is reset pre-delay in micro seconds.
-	The 2nd cell is reset pulse in micro seconds.
-	The 3rd cell is reset post-delay in micro seconds.
-
-The MAC address will be determined using the optional properties
-defined in ethernet.txt[1].
-
-[1] Documentation/devicetree/bindings/net/ethernet.txt
-
-Example:
-	hisi_femac: ethernet@10090000 {
-		compatible = "hisilicon,hi3516cv300-femac","hisilicon,hisi-femac-v2";
-		reg = <0x10090000 0x1000>,<0x10091300 0x200>;
-		interrupts = <12>;
-		clocks = <&crg HI3518EV200_ETH_CLK>;
-		resets = <&crg 0xec 0>,<&crg 0xec 3>;
-		reset-names = "mac","phy";
-		mac-address = [00 00 00 00 00 00];
-		phy-mode = "mii";
-		phy-handle = <&phy0>;
-		hisilicon,phy-reset-delays-us = <10000 20000 20000>;
-	};

-- 
2.43.0

