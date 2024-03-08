From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 08 Mar 2024 16:39:48 +0800
Subject: [PATCH net-next v10 6/8] dt-bindings: net: hisi-femac: add binding
 for Hi3798MV200 FEMAC core
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240308-net-v10-6-3684df40897e@outlook.com>
References: <20240308-net-v10-0-3684df40897e@outlook.com>
In-Reply-To: <20240308-net-v10-0-3684df40897e@outlook.com>
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
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709887184; l=1017;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=UOldq5CRtsm/LbzVGbDAknoLyxLVr+a/RNgHhOeLLzY=;
 b=UjLXcDkC1iGFxi4r1mMdTBtvkykYwtbSeS3izlFvAwHbVZVcNHy9Ytu+vGzY+PRDPV8xlTyEn
 Eni2Eu0RJFpAO/Wuqel4d92H1pW0z83RdLmqmmF+4pOr9ysOIsBI19t
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HiSilicon FEMAC core is also found on Hi3798MV200 SoC. Document it in
binding. While at it, make "hisilicon,hi3516cv200-femac" as the fallback
compatible.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
index 5cd2331668bc..cee10d263d0b 100644
--- a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
+++ b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
@@ -14,8 +14,12 @@ allOf:
 
 properties:
   compatible:
-    enum:
-      - hisilicon,hi3516cv300-femac
+    oneOf:
+      - items:
+          - enum:
+              - hisilicon,hi3798mv200-femac
+          - const: hisilicon,hi3516cv300-femac
+      - const: hisilicon,hi3516cv300-femac
 
   reg:
     items:

-- 
2.43.0

