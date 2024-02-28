From: Yang Xiwen <forbidden405@outlook.com>
Date: Wed, 28 Feb 2024 17:02:30 +0800
Subject: [PATCH net-next v6 06/11] dt-bindings: net: hisi-femac: add
 missing clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240228-net-v6-6-6d78d3d598c1@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709110945; l=1390;
 i=forbidden405@outlook.com; s=20240228; h=from:subject:message-id;
 bh=SAqU1dlvXmk1RmH1J0egzZj4SE6kA1y4eeXVDLyRO28=;
 b=MGeGh9vcJucfrOUy4UwkspwQpi6g+ejOsZjXYNkCGbkGxi9GrfpIG3GLwKNpiugvRIWqvDzaP
 POnOPWZIkENBl/NuvWCi2MNDZF/rqcDOSrXw5JMfyzs/kW8gyXs7teC
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=KAWv6ZzFsT54MGllOczJgFiWB+DuayEmyn24iiVVThU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20240228 with auth_id=136
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A few clocks are missing in old binding file. Add them to match the real
hardware.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../devicetree/bindings/net/hisilicon,hisi-femac.yaml         | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
index be8e34b48243..ba207f2c9ae4 100644
--- a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
+++ b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
@@ -30,6 +30,14 @@ properties:
   clocks:
     items:
       - description: MAC main clock
+      - description: MAC bus interface clock
+      - description: PHY clock
+
+  clock-names:
+    items:
+      - const: mac
+      - const: macif
+      - const: phy
 
   resets:
     items:
@@ -70,7 +78,8 @@ examples:
         compatible = "hisilicon,hi3516cv300-femac", "hisilicon,hisi-femac";
         reg = <0x10090000 0x1000>, <0x10091300 0x200>;
         interrupts = <12>;
-        clocks = <&clk_femac>;
+        clocks = <&clk_femac>, <&clk_femacif>, <&clk_fephy>;
+        clock-names = "mac", "macif", "phy";
         resets = <&crg 0xec 0>, <&crg 0xec 3>;
         reset-names = "mac", "phy";
         mac-address = [00 00 00 00 00 00];

-- 
2.43.0

