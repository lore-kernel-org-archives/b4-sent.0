From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH net-next v8 0/9] net: hisi-femac: add support for
 Hi3798MV200, remove unmaintained compatibles
Date: Tue, 05 Mar 2024 15:51:09 +0800
Message-Id: <20240305-net-v8-0-166aaeea2107@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO3O5mUC/23OTU7EMAwF4KuMsqbIcf5ZcQ80izZxmQhoUNupB
 o16d9JmQUdhaT1/z76zicZIE3s53dlIS5xiGvJgn07MX9rhnZoY8swQUAJy3Qw0N65FsMSNl9C
 zvPk9Uh9ve8sb2xYGus3snJNLnOY0/uz1C9/zh6aFN9AQtMEZ9KF17jVd58+UPp59+tobFvxHY
 VbWdUF2BrTyWCtxUAhFiaw6bUl1RpHRqlbyqLAouX1Irba9Ez04qJU6KlGUykqKDjEI54GLWum
 jskXprHQwNoignPW8VuZPCeBFme2WsiiUM0EG+ajWdf0F8mrwd+YBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709625070; l=3362;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=LFNIOfkegJnCP0scLIaYXcJC1OdZyxYPTASiv2DQEnU=;
 b=OIoCiihOooTHqeLzR80GsvBLxaIHvbwecEUurwhEPN6INbXAd4Z+XfSTl3VYtdkD2r/6cCDHX
 kSTupnXZTvlA1GeZMWr3Rj5y64pgAls5FjHbHd9edhPDmBFiFyqzs37
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v8:
- remove MODULE_ALIAS: rewrite commit msg (Krzysztof Kozlowski)
- driver: use only SoC compatibles (Krzysztof Kozlowski)
- Link to v7: https://lore.kernel.org/r/20240301-net-v7-0-45823597d4d4@outlook.com

Changes in v7:
- dt-bindings: squash a bunch of patches to YAML conversion (Krzysztof Kozlowski)
- dt-bindings: drop phy-mode->phy-connection-type conversion (Andrew Lunnm, Krzysztof Kozlowski)
- driver: drop SoC compatibles
- misc: some minor clean ups
- driver: remove MODULE_ALIAS()
- Link to v6: https://lore.kernel.org/r/20240228-net-v6-0-6d78d3d598c1@outlook.com

Changes in v6:
- add missing "not" in commit logs (Andrew)
- rework binding changes, split it into several commits (Krzysztof Kozlowski)
- Link to v5: https://lore.kernel.org/r/20240223-net-v5-0-43b22d39c013@outlook.com

Changes in v5:
- hisi-femac-mdio: remove clock completely (Krzysztof Kozlowski)
- dt-bindings: mdio: apply comments from Krzysztof Kozlowski

Changes in v4:
- edit commit log to show why mdio bus clk is optional (Krzysztof Kozlowski)
- add clk_bulk_disable_unprepare() during error path (Maxime Chevallier)
- remove of_node_put() (Simon Horman)
- remove histb-clock.h header in binding example as it's goign to be deprecated.
- rearrange patches so binding comes before driver
- Link to v3: https://lore.kernel.org/r/20240220-net-v3-0-b68e5b75e765@outlook.com

Changes in v3:
- rearrange patches to fix bot error. (Rob Herring)
- rewrite commit logs (Andrew Lunn)
- use clk_bulk_ APIs (Andrew Lunn)
- fix uninitialization use of ret (assign to -ENODEV before goto) (Simon Horman)
- Link to v2: https://lore.kernel.org/r/20240216-net-v2-0-89bd4b7065c2@outlook.com

Changes in v2:
- replace email.
- hisi-femac: s/BUS/MACIF (Andrew Lunn)
- hisi-femac: add "hisilicon,hisi-femac" compatible since the driver
  seems generic enough for various SoCs
- hisi-femac-mdio: convert binding to YAML (Krzysztof Kozlowski)
- rewrite commit logs (Krzysztof Kozlowski)
- Link to v1: https://lore.kernel.org/r/20240216-net-v1-0-e0ad972cda99@outlook.com

---
Yang Xiwen (9):
      dt-bindings: net: hisilicon-femac-mdio: convert to YAML
      dt-bindings: net: hisilicon,hisi-femac-mdio: remove clocks
      net: mdio: hisi-femac: remove clock
      dt-bindings: net: convert hisi-femac.txt to YAML
      dt-bindings: net: hisi-femac: add mandatory MDIO bus subnode
      dt-bindings: net: hisi-femac: add binding for Hi3798MV200 FEMAC core
      net: hisi_femac: remove unused compatible strings
      net: hisi_femac: add support for hisi_femac core on Hi3798MV200
      net: hisi_femac: remove unneeded MODULE_ALIAS()

 .../bindings/net/hisilicon,hisi-femac-mdio.yaml    |  39 +++++++
 .../bindings/net/hisilicon,hisi-femac.yaml         | 120 +++++++++++++++++++++
 .../bindings/net/hisilicon-femac-mdio.txt          |  22 ----
 .../devicetree/bindings/net/hisilicon-femac.txt    |  41 -------
 drivers/net/ethernet/hisilicon/hisi_femac.c        |  77 ++++++++++---
 drivers/net/mdio/mdio-hisi-femac.c                 |  18 +---
 6 files changed, 220 insertions(+), 97 deletions(-)
---
base-commit: 90d35da658da8cff0d4ecbb5113f5fac9d00eb72
change-id: 20240216-net-9a208e17c40f

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

