From: Yang Xiwen <forbidden405@outlook.com>
Date: Wed, 28 Feb 2024 17:02:31 +0800
Subject: [PATCH net-next v6 07/11] dt-bindings: net: hisi-femac: replace
 deprecated phy-mode with recommended phy-connection-type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240228-net-v6-7-6d78d3d598c1@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709110945; l=1121;
 i=forbidden405@outlook.com; s=20240228; h=from:subject:message-id;
 bh=UkM6cazLUUcGm7V+UelgyTmRZYNnC9CwRUbl7j+gA44=;
 b=f5Z5JfMhFzIZrioziMkhpJB/CbSksX9sZDGw/4dP0dQYJHzTEaL2jb0GFBOtYQQ1738WyKZ4X
 GWICiPgPUFOCNGnp3xFLFHiUbPWx0lzBribGIcCjE8z3ivD+rsr8FPV
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=KAWv6ZzFsT54MGllOczJgFiWB+DuayEmyn24iiVVThU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20240228 with auth_id=136
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The old property "phy-mode" should be replaced with the latest
"phy-connection-type".

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
index ba207f2c9ae4..6c5888897876 100644
--- a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
+++ b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
@@ -66,7 +66,7 @@ required:
   - clocks
   - resets
   - reset-names
-  - phy-mode
+  - phy-connection-type
   - phy-handle
   - hisilicon,phy-reset-delays-us
 
@@ -83,7 +83,7 @@ examples:
         resets = <&crg 0xec 0>, <&crg 0xec 3>;
         reset-names = "mac", "phy";
         mac-address = [00 00 00 00 00 00];
-        phy-mode = "mii";
+        phy-connection-type = "mii";
         phy-handle = <&fephy>;
         hisilicon,phy-reset-delays-us = <10000 20000 20000>;
     };

-- 
2.43.0

