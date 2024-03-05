From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 05 Mar 2024 15:51:15 +0800
Subject: [PATCH net-next v8 6/9] dt-bindings: net: hisi-femac: add binding
 for Hi3798MV200 FEMAC core
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240305-net-v8-6-166aaeea2107@outlook.com>
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
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709625070; l=785;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=oXZR+lwkSXsM/Qjr88QbgRS9lNfkCukHdVr29JA1ajo=;
 b=itcoDlV36tm20BWjf6gNCXqr5a/EwpHWRe9U6NEoM3heTV4jVsE2/xYuSJdjKLdVwoCAAziuC
 2v7rlQJvjBCBsTybsyTlUvayc42I/YXv3ivj56LRXaIRyndawqolbAt
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HiSilicon FEMAC core is also found on Hi3798MV200 SoC. Document it in
binding.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
index ff6b090ed34e..4f51c5ec90b3 100644
--- a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
+++ b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
@@ -17,6 +17,7 @@ properties:
     items:
       - enum:
           - hisilicon,hi3516cv300-femac
+          - hisilicon,hi3798mv200-femac
       - const: hisilicon,hisi-femac
 
   reg:

-- 
2.43.0

