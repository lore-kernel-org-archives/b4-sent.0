From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/6] net: hisi-femac: add support for Hi3798MV200,
 remove unmaintained compatibles
Date: Fri, 16 Feb 2024 18:01:59 +0800
Message-Id: <20240216-net-v2-0-89bd4b7065c2@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJcyz2UC/1WMQQ7CIBBFr9LMWsxAGiuuvIfpgsDUTtSOASSah
 ruL3bl8P/+9FRJFpgSnboVIhRPL0sDsOvCzW66kODQGg6ZHow9qoaysM3gkPfgeJ2jPZ6SJ31v
 lMjaeOWWJny1a9G/994tWqAhdsIPxwVl7lle+i9z2Xh4w1lq/1dQLkpgAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708077720; l=1447;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=4csa7aTSDQipjQQRAGTCioYnRiR1XMs3x6cVhQ5/Ans=;
 b=b2egZ3PgqKEpipPpPARcNfiNidRYvOIV4ankzyZlv7kGLkClHpB2yRACkfh8rt1OUht43KKF6
 dnmswJm420OCX0eWmdU3AZ4JtbaZ4T/m34LcE1h7nMisoWFlN29ErWU
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- replace email.
- hisi-femac: s/BUS/MACIF (Andrew Lunn)
- hisi-femac: add "hisilicon,hisi-femac" compatible since the driver
  seems generic enough for various SoCs
- hisi-femac-mdio: convert binding to YAML (Krzysztof Kozlowski)
- rewrite commit logs (Krzysztof Kozlowski)
- Link to v1: https://lore.kernel.org/r/20240216-net-v1-0-e0ad972cda99@outlook.com

---
Yang Xiwen (6):
      net: hisilicon: add support for hisi_femac core on Hi3798MV200
      net: hisi_femac: remove unused compatible strings
      dt-bindings: net: remove outdated hisilicon-femac
      dt-bindings: net: add hisilicon,hisi-femac
      net: mdio: hisi-femac: make clock optional
      dt-bindings: net: hisilicon-femac-mdio: convert to YAML

 .../bindings/net/hisilicon,hisi-femac-mdio.yaml    |  48 +++++++++
 .../bindings/net/hisilicon,hisi-femac.yaml         | 117 +++++++++++++++++++++
 .../bindings/net/hisilicon-femac-mdio.txt          |  22 ----
 .../devicetree/bindings/net/hisilicon-femac.txt    |  41 --------
 drivers/net/ethernet/hisilicon/hisi_femac.c        |  94 ++++++++++++-----
 drivers/net/mdio/mdio-hisi-femac.c                 |   2 +-
 6 files changed, 235 insertions(+), 89 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240216-net-9a208e17c40f

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

