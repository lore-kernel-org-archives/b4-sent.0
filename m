From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 05 Mar 2024 15:51:11 +0800
Subject: [PATCH net-next v8 2/9] dt-bindings: net:
 hisilicon,hisi-femac-mdio: remove clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240305-net-v8-2-166aaeea2107@outlook.com>
References: <20240305-net-v8-0-166aaeea2107@outlook.com>
In-Reply-To: <20240305-net-v8-0-166aaeea2107@outlook.com>
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
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709625070; l=1118;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=zFRj07D287wM/dCKue4SsEqnuuC7qPQ9ydZbNJ2lxsQ=;
 b=7ZM4LlkywvpT9Sg2uxbbVgwRYe4NPQiS1o5MQjDpWXhrIUZxZGr4XbmI8qnJxc9sNvNQakdDF
 Nx5LVi1axk8D/vNnIk4rx6nGwBtNvo0krW4GnkCj7E+1tOoTRdSCKzr
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This integrated MDIO bus does not have a dedicated clock. Remove it. The
old binding is wrong.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/net/hisilicon,hisi-femac-mdio.yaml | 5 -----
 1 file changed, 5 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac-mdio.yaml b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac-mdio.yaml
index 36def9d5eecd..dea1bcc27381 100644
--- a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac-mdio.yaml
+++ b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac-mdio.yaml
@@ -19,13 +19,9 @@ properties:
   reg:
     maxItems: 1
 
-  clocks:
-    maxItems: 1
-
 required:
   - compatible
   - reg
-  - clocks
 
 unevaluatedProperties: false
 
@@ -34,7 +30,6 @@ examples:
     mdio@10091100 {
         compatible = "hisilicon,hisi-femac-mdio";
         reg = <0x10091100 0x20>;
-        clocks = <&clk_mdio>;
         #address-cells = <1>;
         #size-cells = <0>;
 

-- 
2.43.0

