From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Thu, 20 Jul 2023 14:29:22 +0300
Subject: [PATCH v3 22/42] dma: cirrus: add DT support for Cirrus EP93xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230605-ep93xx-v3-22-3d63a5f1103e@maquefel.me>
References: <20230605-ep93xx-v3-0-3d63a5f1103e@maquefel.me>
In-Reply-To: <20230605-ep93xx-v3-0-3d63a5f1103e@maquefel.me>
To: Hartley Sweeten <hsweeten@visionengravers.com>, 
 Lennert Buytenhek <kernel@wantstofly.org>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Lukasz Majewski <lukma@denx.de>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Nikita Shubin <nikita.shubin@maquefel.me>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@linutronix.de>, 
 Alessandro Zummo <a.zummo@towertech.it>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Sebastian Reichel <sre@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Mark Brown <broonie@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Vinod Koul <vkoul@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Damien Le Moal <dlemoal@kernel.org>, Sergey Shtylyov <s.shtylyov@omp.ru>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Arnd Bergmann <arnd@arndb.de>, 
 Olof Johansson <olof@lixom.net>, soc@kernel.org, 
 Liam Girdwood <lgirdwood@gmail.com>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, Andy Shevchenko <andy@kernel.org>, 
 Michael Peters <mpeters@embeddedTS.com>, Kris Bahnsen <kris@embeddedTS.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-rtc@vger.kernel.org, 
 linux-watchdog@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-pwm@vger.kernel.org, linux-spi@vger.kernel.org, 
 netdev@vger.kernel.org, dmaengine@vger.kernel.org, 
 linux-mtd@lists.infradead.org, linux-ide@vger.kernel.org, 
 linux-input@vger.kernel.org, alsa-devel@alsa-project.org
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1689852591; l=6877;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=Q54A7sVkI/IbwRjo56tAXtqK4EnifqnuJhkrT/M+cqk=;
 b=kUkeyK+easjHjaYYKYrZA2DfE76vfQBnaBtNnVU8gi1hrFaI3Ojm3MURz8q9fZxHR99C49v5LdLC
 GUIPIt4yA1sfmEh79rsMOnL2V983f+1lJlTJr9y7vFYhk+DFeKMv
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- drop subsys_initcall code
- add OF ID match table with data
- add of_probe for device tree

Co-developed-by: Alexander Sverdlin <alexander.sverdlin@gmail.com>
Signed-off-by: Alexander Sverdlin <alexander.sverdlin@gmail.com>
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 drivers/dma/ep93xx_dma.c                 | 131 ++++++++++++++++++++++++++++---
 include/linux/platform_data/dma-ep93xx.h |   4 +
 2 files changed, 122 insertions(+), 13 deletions(-)

diff --git a/drivers/dma/ep93xx_dma.c b/drivers/dma/ep93xx_dma.c
index 5338a94f1a69..1b38180e2a2c 100644
--- a/drivers/dma/ep93xx_dma.c
+++ b/drivers/dma/ep93xx_dma.c
@@ -20,6 +20,8 @@
 #include <linux/dmaengine.h>
 #include <linux/module.h>
 #include <linux/mod_devicetable.h>
+#include <linux/of_device.h>
+#include <linux/overflow.h>
 #include <linux/platform_device.h>
 #include <linux/slab.h>
 
@@ -104,6 +106,11 @@
 #define DMA_MAX_CHAN_BYTES		0xffff
 #define DMA_MAX_CHAN_DESCRIPTORS	32
 
+enum ep93xx_dma_type {
+	M2P_DMA,
+	M2M_DMA,
+};
+
 struct ep93xx_dma_engine;
 static int ep93xx_dma_slave_config_write(struct dma_chan *chan,
 					 enum dma_transfer_direction dir,
@@ -216,6 +223,11 @@ struct ep93xx_dma_engine {
 	struct ep93xx_dma_chan	channels[];
 };
 
+struct ep93xx_edma_data {
+	u32	id;
+	size_t	num_channels;
+};
+
 static inline struct device *chan2dev(struct ep93xx_dma_chan *edmac)
 {
 	return &edmac->chan.dev->device;
@@ -1315,22 +1327,82 @@ static void ep93xx_dma_issue_pending(struct dma_chan *chan)
 	ep93xx_dma_advance_work(to_ep93xx_dma_chan(chan));
 }
 
-static int __init ep93xx_dma_probe(struct platform_device *pdev)
+
+#ifdef CONFIG_OF
+static struct ep93xx_dma_engine *ep93xx_dma_of_probe(struct platform_device *pdev)
 {
-	struct ep93xx_dma_platform_data *pdata = dev_get_platdata(&pdev->dev);
+	struct device_node *np = pdev->dev.of_node;
+	const struct ep93xx_edma_data *data;
 	struct ep93xx_dma_engine *edma;
 	struct dma_device *dma_dev;
-	size_t edma_size;
-	int ret, i;
+	int i;
+
+	data = of_device_get_match_data(&pdev->dev);
+	if (!data)
+		return ERR_PTR(dev_err_probe(&pdev->dev, -ENODEV, "No device match found\n"));
 
-	edma_size = pdata->num_channels * sizeof(struct ep93xx_dma_chan);
-	edma = kzalloc(sizeof(*edma) + edma_size, GFP_KERNEL);
+	edma = devm_kzalloc(&pdev->dev,
+					  struct_size(edma, channels, data->num_channels),
+				      GFP_KERNEL);
 	if (!edma)
-		return -ENOMEM;
+		return ERR_PTR(-ENOMEM);
 
+	edma->m2m = data->id;
+	edma->num_channels = data->num_channels;
 	dma_dev = &edma->dma_dev;
+
+	INIT_LIST_HEAD(&dma_dev->channels);
+	for (i = 0; i < edma->num_channels; i++) {
+		struct ep93xx_dma_chan *edmac = &edma->channels[i];
+
+		edmac->chan.device = dma_dev;
+		edmac->regs = devm_platform_ioremap_resource(pdev, i);
+		edmac->irq = platform_get_irq(pdev, i);
+		edmac->edma = edma;
+
+		edmac->clk = of_clk_get(np, i);
+
+		if (IS_ERR(edmac->clk)) {
+			dev_warn(&pdev->dev, "failed to get clock\n");
+			continue;
+		}
+
+		spin_lock_init(&edmac->lock);
+		INIT_LIST_HEAD(&edmac->active);
+		INIT_LIST_HEAD(&edmac->queue);
+		INIT_LIST_HEAD(&edmac->free_list);
+		tasklet_setup(&edmac->tasklet, ep93xx_dma_tasklet);
+
+		list_add_tail(&edmac->chan.device_node,
+			      &dma_dev->channels);
+	}
+
+	return edma;
+}
+#else
+static int ep93xx_dma_of_probe(struct platform_device *pdev,
+			struct ep93xx_dma_engine *edma)
+{
+	return -EINVAL;
+}
+#endif
+
+static struct ep93xx_dma_engine *ep93xx_init_from_pdata(struct platform_device *pdev)
+{
+	struct ep93xx_dma_platform_data *pdata = dev_get_platdata(&pdev->dev);
+	struct ep93xx_dma_engine *edma;
+	struct dma_device *dma_dev;
+	int i;
+
+	edma = devm_kzalloc(&pdev->dev,
+			    struct_size(edma, channels, pdata->num_channels),
+			    GFP_KERNEL);
+	if (!edma)
+		return ERR_PTR(-ENOMEM);
+
 	edma->m2m = platform_get_device_id(pdev)->driver_data;
 	edma->num_channels = pdata->num_channels;
+	dma_dev = &edma->dma_dev;
 
 	INIT_LIST_HEAD(&dma_dev->channels);
 	for (i = 0; i < pdata->num_channels; i++) {
@@ -1359,6 +1431,25 @@ static int __init ep93xx_dma_probe(struct platform_device *pdev)
 			      &dma_dev->channels);
 	}
 
+	return edma;
+}
+
+static int ep93xx_dma_probe(struct platform_device *pdev)
+{
+	struct ep93xx_dma_engine *edma;
+	struct dma_device *dma_dev;
+	int ret, i;
+
+	if (platform_get_device_id(pdev))
+		edma = ep93xx_init_from_pdata(pdev);
+	else
+		edma = ep93xx_dma_of_probe(pdev);
+
+	if (!edma)
+		return PTR_ERR(edma);
+
+	dma_dev = &edma->dma_dev;
+
 	dma_cap_zero(dma_dev->cap_mask);
 	dma_cap_set(DMA_SLAVE, dma_dev->cap_mask);
 	dma_cap_set(DMA_CYCLIC, dma_dev->cap_mask);
@@ -1410,6 +1501,23 @@ static int __init ep93xx_dma_probe(struct platform_device *pdev)
 	return ret;
 }
 
+static const struct ep93xx_edma_data edma_m2p = {
+	.id = M2P_DMA,
+	.num_channels = 10,
+};
+
+static const struct ep93xx_edma_data edma_m2m = {
+	.id = M2M_DMA,
+	.num_channels = 2,
+};
+
+static const struct of_device_id ep93xx_dma_of_ids[] = {
+	{ .compatible = "cirrus,ep9301-dma-m2p", .data = &edma_m2p },
+	{ .compatible = "cirrus,ep9301-dma-m2m", .data = &edma_m2m },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, ep93xx_dma_of_ids);
+
 static const struct platform_device_id ep93xx_dma_driver_ids[] = {
 	{ "ep93xx-dma-m2p", 0 },
 	{ "ep93xx-dma-m2m", 1 },
@@ -1419,15 +1527,12 @@ static const struct platform_device_id ep93xx_dma_driver_ids[] = {
 static struct platform_driver ep93xx_dma_driver = {
 	.driver		= {
 		.name	= "ep93xx-dma",
+		.of_match_table = ep93xx_dma_of_ids,
 	},
 	.id_table	= ep93xx_dma_driver_ids,
+	.probe		= ep93xx_dma_probe,
 };
 
-static int __init ep93xx_dma_module_init(void)
-{
-	return platform_driver_probe(&ep93xx_dma_driver, ep93xx_dma_probe);
-}
-subsys_initcall(ep93xx_dma_module_init);
-
+module_platform_driver(ep93xx_dma_driver);
 MODULE_AUTHOR("Mika Westerberg <mika.westerberg@iki.fi>");
 MODULE_DESCRIPTION("EP93xx DMA driver");
diff --git a/include/linux/platform_data/dma-ep93xx.h b/include/linux/platform_data/dma-ep93xx.h
index 54b41d1468ef..b5b4bd5f9a9e 100644
--- a/include/linux/platform_data/dma-ep93xx.h
+++ b/include/linux/platform_data/dma-ep93xx.h
@@ -5,6 +5,7 @@
 #include <linux/types.h>
 #include <linux/dmaengine.h>
 #include <linux/dma-mapping.h>
+#include <linux/of.h>
 #include <dt-bindings/dma/cirrus,ep93xx-dma.h>
 
 /**
@@ -51,6 +52,9 @@ struct ep93xx_dma_platform_data {
 
 static inline bool ep93xx_dma_chan_is_m2p(struct dma_chan *chan)
 {
+	if (of_device_is_compatible(dev_of_node(chan->device->dev), "cirrus,ep9301-dma-m2p"))
+		return true;
+
 	return !strcmp(dev_name(chan->device->dev), "ep93xx-dma-m2p");
 }
 

-- 
2.39.2

