From: Yang Xiwen <forbidden405@outlook.com>
Date: Wed, 28 Feb 2024 17:02:29 +0800
Subject: [PATCH net-next v6 05/11] dt-bindings: net: hisi-femac: remove
 core specific versioning
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240228-net-v6-5-6d78d3d598c1@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709110945; l=1304;
 i=forbidden405@outlook.com; s=20240228; h=from:subject:message-id;
 bh=QaLk+lI8wjJQd0lZBh2cmavdezy+qKZvyIpwbApopOY=;
 b=l5U1wW1kB4lGB6SEiVqjtKkYCq6xwMOu/+uEl3FnZaD8SWhssPq8y+GR5HJB9WRVS9mUOBF3S
 hSoU8mLvtiMDm+eSIIVtjBnCUvFQjIfZ2P5Rd0igQM/4494n5xVi07M
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=KAWv6ZzFsT54MGllOczJgFiWB+DuayEmyn24iiVVThU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20240228 with auth_id=136
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The version numbers are not documented publicly. The version also does
not change programming interface. Remove it until it's really needed.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
index 016e9e409a30..be8e34b48243 100644
--- a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
+++ b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
@@ -17,9 +17,7 @@ properties:
     items:
       - enum:
           - hisilicon,hi3516cv300-femac
-      - enum:
-          - hisilicon,hisi-femac-v1
-          - hisilicon,hisi-femac-v2
+      - const: hisilicon,hisi-femac
 
   reg:
     items:
@@ -69,7 +67,7 @@ unevaluatedProperties: false
 examples:
   - |
     ethernet@10090000 {
-        compatible = "hisilicon,hi3516cv300-femac", "hisilicon,hisi-femac-v2";
+        compatible = "hisilicon,hi3516cv300-femac", "hisilicon,hisi-femac";
         reg = <0x10090000 0x1000>, <0x10091300 0x200>;
         interrupts = <12>;
         clocks = <&clk_femac>;

-- 
2.43.0

