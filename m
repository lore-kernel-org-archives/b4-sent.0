From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/6] net: hisi-femac: add support for Hi3798MV200, remove
 unmaintained compatibles
Date: Fri, 16 Feb 2024 07:48:52 +0800
Message-Id: <20240216-net-v1-0-e0ad972cda99@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOSizmUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDI0Mz3bzUEl3LRCMDi1RD82QTgzQloMqCotS0zAqwKdGxtbUABWErjFU
 AAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708040932; l=983;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=m941Sbuue6lax4UKMmxtO0nmkIxGUQrjsrLye+L4Em0=;
 b=2sOk2vozN8hrgMsvgYl+50Do8EfwMKSRFvFVYxJoAbmYU/vB+BB/DHCRm3UcUly3sw4UNcaqt
 GOLJuJl4xeRDInpTJ7t91J0veyiVl568HonhzYAWms3HjhQcfFCslBW
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (6):
      net: hisilicon: add support for hisi_femac core on Hi3798MV200
      net: hisi_femac: remove unused compatible strings
      dt-bindings: net: remove outdated hisilicon-femac
      dt-bindings: net: add hisilicon-femac
      net: mdio: hisi-femac: make clock optional
      dt-bindings: net: hisilicon-femac-mdio: make clock optional

 .../bindings/net/hisilicon-femac-mdio.txt          |   2 +
 .../devicetree/bindings/net/hisilicon-femac.txt    |  41 -------
 .../devicetree/bindings/net/hisilicon-femac.yaml   | 125 +++++++++++++++++++++
 drivers/net/ethernet/hisilicon/hisi_femac.c        |  93 ++++++++++-----
 drivers/net/mdio/mdio-hisi-femac.c                 |   2 +-
 5 files changed, 196 insertions(+), 67 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240216-net-9a208e17c40f

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

