From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 16 Feb 2024 07:48:58 +0800
Subject: [PATCH 6/6] dt-bindings: net: hisilicon-femac-mdio: make clock
 optional
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-net-v1-6-e0ad972cda99@outlook.com>
References: <20240216-net-v1-0-e0ad972cda99@outlook.com>
In-Reply-To: <20240216-net-v1-0-e0ad972cda99@outlook.com>
To: Yisen Zhuang <yisen.zhuang@huawei.com>, 
 Salil Mehta <salil.mehta@huawei.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Yang Xiwen <forbidden405@foxmail.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708040932; l=878;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=F5kHPrADx5NPlmJ1rkhSxa9z6ULOnV4wfItxfOuEBlU=;
 b=6HbzsNnWkAYAwbHHS3hcLyUnHF83hhbSg5L2TOq54PaHAnk9Ka1K2HjwZiA7DlrEZPmXrP4v7
 jwdNlMUA7JtCEQ1ky6bp7ra5L0oVS5+wgJ8w07CFJ6/fkTIprmD+tCa
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clock is optional.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/net/hisilicon-femac-mdio.txt | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/hisilicon-femac-mdio.txt b/Documentation/devicetree/bindings/net/hisilicon-femac-mdio.txt
index 23a39a309d17..cd37f43abd45 100644
--- a/Documentation/devicetree/bindings/net/hisilicon-femac-mdio.txt
+++ b/Documentation/devicetree/bindings/net/hisilicon-femac-mdio.txt
@@ -3,6 +3,8 @@ Hisilicon Fast Ethernet MDIO Controller interface
 Required properties:
 - compatible: should be "hisilicon,hisi-femac-mdio".
 - reg: address and length of the register set for the device.
+
+Optional properties:
 - clocks: A phandle to the reference clock for this device.
 
 - PHY subnode: inherits from phy binding [1]

-- 
2.43.0

