From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 20 Feb 2024 03:57:36 +0800
Subject: [PATCH net-next v3 1/6] net: mdio: hisi-femac: make clock optional
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240220-net-v3-1-b68e5b75e765@outlook.com>
References: <20240220-net-v3-0-b68e5b75e765@outlook.com>
In-Reply-To: <20240220-net-v3-0-b68e5b75e765@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708372656; l=720;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=RxVNNMcUcOL8zwGYeNVp22tshMMwMwhDPBBRMx/bOA4=;
 b=QWnp8vXIvEWNQsFkYpybTyS4CueV5P2ocmQp+rpM8gO/MOJ7eUrbcJ7WOKB/E6zOZoJRTGhvC
 k7ZhNuV9xxjAdXlEfVk9tD3gFbUtvtZSwi27S8xqJ2cgUP0CKSYT57b
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clocks are optional.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/net/mdio/mdio-hisi-femac.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/mdio/mdio-hisi-femac.c b/drivers/net/mdio/mdio-hisi-femac.c
index 6703f626ee83..a2620b200381 100644
--- a/drivers/net/mdio/mdio-hisi-femac.c
+++ b/drivers/net/mdio/mdio-hisi-femac.c
@@ -93,7 +93,7 @@ static int hisi_femac_mdio_probe(struct platform_device *pdev)
 		goto err_out_free_mdiobus;
 	}
 
-	data->clk = devm_clk_get(&pdev->dev, NULL);
+	data->clk = devm_clk_get_optional(&pdev->dev, NULL);
 	if (IS_ERR(data->clk)) {
 		ret = PTR_ERR(data->clk);
 		goto err_out_free_mdiobus;

-- 
2.43.0

