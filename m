From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 16 Feb 2024 18:02:01 +0800
Subject: [PATCH v2 2/6] net: hisi_femac: remove unused compatible strings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-net-v2-2-89bd4b7065c2@outlook.com>
References: <20240216-net-v2-0-89bd4b7065c2@outlook.com>
In-Reply-To: <20240216-net-v2-0-89bd4b7065c2@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708077720; l=1155;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=VItgdwH/S2ChRp+ovLIh4GSJZrDbNQYqIUlou/CYzgk=;
 b=iObYojUwZgCh1QaGVSGrNP8JRUwhiyKAgKlMEUVTARxkeuANaOrGu2f04uB8xcwGZxG5OoxMl
 xF1BqLxsEnuDYCpw+8JgdWPhR03wrB+obioeQVAYuclAjxo0AqqUzTA
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The only documented SoC Hi3516DV300 does not receive any updates from 8
years ago. With the recent driver changes, it unlikely works for this
SoC anymore. Remove the binding for this SoC.

Also it's hard to get the version number and it's unknown how the
version can be used. Remove them until it's really needed.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/net/ethernet/hisilicon/hisi_femac.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/net/ethernet/hisilicon/hisi_femac.c b/drivers/net/ethernet/hisilicon/hisi_femac.c
index 15e90c7d6421..09a649af691f 100644
--- a/drivers/net/ethernet/hisilicon/hisi_femac.c
+++ b/drivers/net/ethernet/hisilicon/hisi_femac.c
@@ -990,9 +990,7 @@ static int hisi_femac_drv_resume(struct platform_device *pdev)
 #endif
 
 static const struct of_device_id hisi_femac_match[] = {
-	{.compatible = "hisilicon,hisi-femac-v1",},
-	{.compatible = "hisilicon,hisi-femac-v2",},
-	{.compatible = "hisilicon,hi3516cv300-femac",},
+	{.compatible = "hisilicon,hisi-femac",},
 	{.compatible = "hisilicon,hi3798mv200-femac",},
 	{},
 };

-- 
2.43.0

