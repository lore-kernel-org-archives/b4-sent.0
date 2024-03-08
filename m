From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 08 Mar 2024 16:39:50 +0800
Subject: [PATCH net-next v10 8/8] net: hisi_femac: remove unneeded
 MODULE_ALIAS()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240308-net-v10-8-3684df40897e@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709887184; l=759;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=uL7LyY/J5pSqlD2z/1TEbFEFBkXEinuPTyuh1Re7jzE=;
 b=UsaE+jHuRZvUIbRpHxIgOLRJQR07lC6/TlyHzgQ8F/LfgY0Z6IZAc7htq8eSvgpbBS1NNAthj
 id3ugYnbDvCD6U2Q8FeGN4bBdiE7TQLcatKlfcIXH7XUc0XuLFkhhX2
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We already have MODULE_DEVICE_TABLE() that creates the correct alias.
Remove unneeded MODULE_ALIAS().

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/net/ethernet/hisilicon/hisi_femac.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/net/ethernet/hisilicon/hisi_femac.c b/drivers/net/ethernet/hisilicon/hisi_femac.c
index 9bf4beba7987..f0f2a3cd8d1d 100644
--- a/drivers/net/ethernet/hisilicon/hisi_femac.c
+++ b/drivers/net/ethernet/hisilicon/hisi_femac.c
@@ -969,4 +969,3 @@ module_platform_driver(hisi_femac_driver);
 MODULE_DESCRIPTION("Hisilicon Fast Ethernet MAC driver");
 MODULE_AUTHOR("Dongpo Li <lidongpo@hisilicon.com>");
 MODULE_LICENSE("GPL v2");
-MODULE_ALIAS("platform:hisi-femac");

-- 
2.43.0

