From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Mon, 09 Sep 2024 11:10:42 +0300
Subject: [PATCH v12 17/38] net: cirrus: add DT support for Cirrus EP93xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240909-ep93xx-v12-17-e86ab2423d4b@maquefel.me>
References: <20240909-ep93xx-v12-0-e86ab2423d4b@maquefel.me>
In-Reply-To: <20240909-ep93xx-v12-0-e86ab2423d4b@maquefel.me>
To: Hartley Sweeten <hsweeten@visionengravers.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Andrew Lunn <andrew@lunn.ch>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725869532; l=4277;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=b1GOTD5HubzYgxiOB7lYJxNswjw8j/5q0+HrSptbhew=;
 b=mtcLwS9yizPIJVjVatckrcoFuJbmN1udf8DStPtBM2/KQZ3lN7zV38mFiKS3DwV9ClV0eZ5VMK6k
 +UKiK85sCKTsOnyZPF5jsqQUTgIgQ6lC6ycPKd16JRnWnZ2uZgqK
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- add OF ID match table
- get phy_id from the device tree, as part of mdio
- copy_addr is now always used, as there is no SoC/board that aren't
- dropped platform header

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
Tested-by: Alexander Sverdlin <alexander.sverdlin@gmail.com>
Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Reviewed-by: Linus Walleij <linus.walleij@linaro.org>
---
 drivers/net/ethernet/cirrus/ep93xx_eth.c | 63 ++++++++++++++++----------------
 1 file changed, 32 insertions(+), 31 deletions(-)

diff --git a/drivers/net/ethernet/cirrus/ep93xx_eth.c b/drivers/net/ethernet/cirrus/ep93xx_eth.c
index 1f495cfd7959..2523d9c9d1b8 100644
--- a/drivers/net/ethernet/cirrus/ep93xx_eth.c
+++ b/drivers/net/ethernet/cirrus/ep93xx_eth.c
@@ -16,13 +16,12 @@
 #include <linux/ethtool.h>
 #include <linux/interrupt.h>
 #include <linux/moduleparam.h>
+#include <linux/of.h>
 #include <linux/platform_device.h>
 #include <linux/delay.h>
 #include <linux/io.h>
 #include <linux/slab.h>
 
-#include <linux/platform_data/eth-ep93xx.h>
-
 #define DRV_MODULE_NAME		"ep93xx-eth"
 
 #define RX_QUEUE_ENTRIES	64
@@ -738,25 +737,6 @@ static const struct net_device_ops ep93xx_netdev_ops = {
 	.ndo_set_mac_address	= eth_mac_addr,
 };
 
-static struct net_device *ep93xx_dev_alloc(struct ep93xx_eth_data *data)
-{
-	struct net_device *dev;
-
-	dev = alloc_etherdev(sizeof(struct ep93xx_priv));
-	if (dev == NULL)
-		return NULL;
-
-	eth_hw_addr_set(dev, data->dev_addr);
-
-	dev->ethtool_ops = &ep93xx_ethtool_ops;
-	dev->netdev_ops = &ep93xx_netdev_ops;
-
-	dev->features |= NETIF_F_SG | NETIF_F_HW_CSUM;
-
-	return dev;
-}
-
-
 static void ep93xx_eth_remove(struct platform_device *pdev)
 {
 	struct net_device *dev;
@@ -786,27 +766,47 @@ static void ep93xx_eth_remove(struct platform_device *pdev)
 
 static int ep93xx_eth_probe(struct platform_device *pdev)
 {
-	struct ep93xx_eth_data *data;
 	struct net_device *dev;
 	struct ep93xx_priv *ep;
 	struct resource *mem;
+	void __iomem *base_addr;
+	struct device_node *np;
+	u32 phy_id;
 	int irq;
 	int err;
 
 	if (pdev == NULL)
 		return -ENODEV;
-	data = dev_get_platdata(&pdev->dev);
 
 	mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
 	irq = platform_get_irq(pdev, 0);
 	if (!mem || irq < 0)
 		return -ENXIO;
 
-	dev = ep93xx_dev_alloc(data);
+	base_addr = ioremap(mem->start, resource_size(mem));
+	if (!base_addr)
+		return dev_err_probe(&pdev->dev, -EIO, "Failed to ioremap ethernet registers\n");
+
+	np = of_parse_phandle(pdev->dev.of_node, "phy-handle", 0);
+	if (!np)
+		return dev_err_probe(&pdev->dev, -ENODEV, "Please provide \"phy-handle\"\n");
+
+	err = of_property_read_u32(np, "reg", &phy_id);
+	of_node_put(np);
+	if (err)
+		return dev_err_probe(&pdev->dev, -ENOENT, "Failed to locate \"phy_id\"\n");
+
+	dev = alloc_etherdev(sizeof(struct ep93xx_priv));
 	if (dev == NULL) {
 		err = -ENOMEM;
 		goto err_out;
 	}
+
+	eth_hw_addr_set(dev, base_addr + 0x50);
+	dev->ethtool_ops = &ep93xx_ethtool_ops;
+	dev->netdev_ops = &ep93xx_netdev_ops;
+	dev->features |= NETIF_F_SG | NETIF_F_HW_CSUM;
+
 	ep = netdev_priv(dev);
 	ep->dev = dev;
 	SET_NETDEV_DEV(dev, &pdev->dev);
@@ -822,15 +822,10 @@ static int ep93xx_eth_probe(struct platform_device *pdev)
 		goto err_out;
 	}
 
-	ep->base_addr = ioremap(mem->start, resource_size(mem));
-	if (ep->base_addr == NULL) {
-		dev_err(&pdev->dev, "Failed to ioremap ethernet registers\n");
-		err = -EIO;
-		goto err_out;
-	}
+	ep->base_addr = base_addr;
 	ep->irq = irq;
 
-	ep->mii.phy_id = data->phy_id;
+	ep->mii.phy_id = phy_id;
 	ep->mii.phy_id_mask = 0x1f;
 	ep->mii.reg_num_mask = 0x1f;
 	ep->mii.dev = dev;
@@ -857,12 +852,18 @@ static int ep93xx_eth_probe(struct platform_device *pdev)
 	return err;
 }
 
+static const struct of_device_id ep93xx_eth_of_ids[] = {
+	{ .compatible = "cirrus,ep9301-eth" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, ep93xx_eth_of_ids);
 
 static struct platform_driver ep93xx_eth_driver = {
 	.probe		= ep93xx_eth_probe,
 	.remove_new	= ep93xx_eth_remove,
 	.driver		= {
 		.name	= "ep93xx-eth",
+		.of_match_table = ep93xx_eth_of_ids,
 	},
 };
 

-- 
2.43.2

