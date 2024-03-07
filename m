From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 07 Mar 2024 19:34:53 +0800
Subject: [PATCH net-next v9 7/9] net: hisi_femac: remove unused compatible
 strings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240307-net-v9-7-6e0cf3e6584d@outlook.com>
References: <20240307-net-v9-0-6e0cf3e6584d@outlook.com>
In-Reply-To: <20240307-net-v9-0-6e0cf3e6584d@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709811287; l=937;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=aaQRrOl6ezTfgk2jYZxmgPEEzwU/YKquwXnutXaPBpI=;
 b=9FmgJapGP/SG0VJpetSvFJunm3iKivW4ooCiGKaNyiSaMV0kNsulIlll/qR3Wo4DsR8YaMdHe
 7U+G0o6jo5BAbyGMdUnJi7WHhyLRztA+jgo/S2rZyGcN/Lhq/YDVZa+
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's hard to get the version number for each FEMAC core and it's unknown
how the version can be used. Remove them until it's really needed.

While at it, remove fallback compatibles and only use SoC compatible.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/net/ethernet/hisilicon/hisi_femac.c | 2 --
 1 file changed, 2 deletions(-)

diff --git a/drivers/net/ethernet/hisilicon/hisi_femac.c b/drivers/net/ethernet/hisilicon/hisi_femac.c
index 2406263c9dd3..9bf4beba7987 100644
--- a/drivers/net/ethernet/hisilicon/hisi_femac.c
+++ b/drivers/net/ethernet/hisilicon/hisi_femac.c
@@ -945,8 +945,6 @@ static int hisi_femac_drv_resume(struct platform_device *pdev)
 #endif
 
 static const struct of_device_id hisi_femac_match[] = {
-	{.compatible = "hisilicon,hisi-femac-v1",},
-	{.compatible = "hisilicon,hisi-femac-v2",},
 	{.compatible = "hisilicon,hi3516cv300-femac",},
 	{},
 };

-- 
2.43.0

