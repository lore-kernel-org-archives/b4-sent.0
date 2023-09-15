From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Fri, 15 Sep 2023 11:11:02 +0300
Subject: [PATCH v4 20/42] spi: ep93xx: add DT support for Cirrus EP93xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230915-ep93xx-v4-20-a1d779dcec10@maquefel.me>
References: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
In-Reply-To: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
To: Mark Brown <broonie@kernel.org>
Cc: linux-spi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1694765525; l=2702;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=ZWn5JZLALLuK4G847aw+YC2k8LjRei15o646pYI1xGQ=;
 b=VKuO2C7qqnyexAG+u0v3ihHQPeM3GpjzYwML0vh5RImwhqpNidBkpO19Zr6afoPhy3CgGrNhI8x6
 TRiy+d7QBMwum8/bwpdMp672/UeEibNZuKKC+CV9kx5RpHfG9mCG
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- add OF ID match table

Instead of platform use_dma flag - check if DT dmas property is present to
decide to use dma ot not.

Reviewed-by: Linus Walleij <linus.walleij@linaro.org>
Tested-by: Alexander Sverdlin <alexander.sverdlin@gmail.com>
Acked-by: Alexander Sverdlin <alexander.sverdlin@gmail.com>
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 drivers/spi/spi-ep93xx.c | 28 +++++++++++++++++++++++++++-
 1 file changed, 27 insertions(+), 1 deletion(-)

diff --git a/drivers/spi/spi-ep93xx.c b/drivers/spi/spi-ep93xx.c
index 1615fd22f9a2..f93cd506bf17 100644
--- a/drivers/spi/spi-ep93xx.c
+++ b/drivers/spi/spi-ep93xx.c
@@ -22,6 +22,7 @@
 #include <linux/bitops.h>
 #include <linux/interrupt.h>
 #include <linux/module.h>
+#include <linux/property.h>
 #include <linux/platform_device.h>
 #include <linux/sched.h>
 #include <linux/scatterlist.h>
@@ -644,6 +645,23 @@ static void ep93xx_spi_release_dma(struct ep93xx_spi *espi)
 		free_page((unsigned long)espi->zeropage);
 }
 
+#ifdef CONFIG_OF
+static struct ep93xx_spi_info dt_spi_info;
+
+static struct ep93xx_spi_info *ep93xx_spi_get_platdata(struct platform_device *pdev)
+{
+	if (device_property_present(&pdev->dev, "dmas"))
+		dt_spi_info.use_dma = 1;
+
+	return &dt_spi_info;
+}
+#else
+static struct ep93xx_spi_info *ep93xx_spi_get_platdata(struct platform_device *pdev)
+{
+	return dev_get_platdata(&pdev->dev);
+}
+#endif
+
 static int ep93xx_spi_probe(struct platform_device *pdev)
 {
 	struct spi_master *master;
@@ -653,7 +671,7 @@ static int ep93xx_spi_probe(struct platform_device *pdev)
 	int irq;
 	int error;
 
-	info = dev_get_platdata(&pdev->dev);
+	info = ep93xx_spi_get_platdata(pdev);
 	if (!info) {
 		dev_err(&pdev->dev, "missing platform data\n");
 		return -EINVAL;
@@ -726,6 +744,7 @@ static int ep93xx_spi_probe(struct platform_device *pdev)
 	/* make sure that the hardware is disabled */
 	writel(0, espi->mmio + SSPCR1);
 
+	device_set_node(&master->dev, dev_fwnode(&pdev->dev));
 	error = devm_spi_register_master(&pdev->dev, master);
 	if (error) {
 		dev_err(&pdev->dev, "failed to register SPI master\n");
@@ -753,9 +772,16 @@ static void ep93xx_spi_remove(struct platform_device *pdev)
 	ep93xx_spi_release_dma(espi);
 }
 
+static const struct of_device_id ep93xx_spi_of_ids[] = {
+	{ .compatible = "cirrus,ep9301-spi" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, ep93xx_spi_of_ids);
+
 static struct platform_driver ep93xx_spi_driver = {
 	.driver		= {
 		.name	= "ep93xx-spi",
+		.of_match_table = ep93xx_spi_of_ids,
 	},
 	.probe		= ep93xx_spi_probe,
 	.remove_new	= ep93xx_spi_remove,

-- 
2.39.2

