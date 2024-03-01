From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 01 Mar 2024 11:35:59 +0800
Subject: [PATCH net-next v7 6/9] dt-bindings: net: hisi-femac: add binding
 for Hi3798MV200 FEMAC core
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240301-net-v7-6-45823597d4d4@outlook.com>
References: <20240301-net-v7-0-45823597d4d4@outlook.com>
In-Reply-To: <20240301-net-v7-0-45823597d4d4@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709264157; l=785;
 i=forbidden405@outlook.com; s=20240228; h=from:subject:message-id;
 bh=oXZR+lwkSXsM/Qjr88QbgRS9lNfkCukHdVr29JA1ajo=;
 b=Xe2EbEmxy306rUj0zxTs1+ZIHcBeTzy6aBpoU+vjM15EPa4WcnOXJ4gQXix5klVOt6vaLbR0d
 BrieYEBsQrtAkM6rV7RqoqGr3eUFHKcdLkHEV9rJqG1uDiyrtlIEkh3
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=KAWv6ZzFsT54MGllOczJgFiWB+DuayEmyn24iiVVThU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20240228 with auth_id=136
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

