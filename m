From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Thu, 20 Jul 2023 14:29:26 +0300
Subject: [PATCH v3 26/42] ata: pata_ep93xx: add device tree support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230605-ep93xx-v3-26-3d63a5f1103e@maquefel.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1689852591; l=2575;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=k/Fzw6JdkE/3suqIiyO5Zhyi7BJas3Z1DAR17iWACYM=;
 b=k+ORk4S+LFBcP5CmCkp0oZYl98QLD0d1fLzPkLcanD+VxyScBfMYMDLH2SX/gub+L0/xrW3NXAvd
 oDttOcshA50/3i3jd3h3wByJH3KV5lorfsUjlKEZR9ua8Z6c8eLB
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Add OF ID match table
- Drop ep93xx_chip_revision and use soc_device_match instead

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 drivers/ata/pata_ep93xx.c | 26 ++++++++++++++++++++------
 1 file changed, 20 insertions(+), 6 deletions(-)

diff --git a/drivers/ata/pata_ep93xx.c b/drivers/ata/pata_ep93xx.c
index c6e043e05d43..a88824dfc5fa 100644
--- a/drivers/ata/pata_ep93xx.c
+++ b/drivers/ata/pata_ep93xx.c
@@ -40,9 +40,11 @@
 #include <linux/ata.h>
 #include <linux/libata.h>
 #include <linux/platform_device.h>
+#include <linux/sys_soc.h>
 #include <linux/delay.h>
 #include <linux/dmaengine.h>
 #include <linux/ktime.h>
+#include <linux/mod_devicetable.h>
 
 #include <linux/platform_data/dma-ep93xx.h>
 #include <linux/soc/cirrus/ep93xx.h>
@@ -910,6 +912,12 @@ static struct ata_port_operations ep93xx_pata_port_ops = {
 	.port_start		= ep93xx_pata_port_start,
 };
 
+static const struct soc_device_attribute ep93xx_soc_table[] = {
+	{ .revision = "E1", .data = (void *)ATA_UDMA3 },
+	{ .revision = "E2", .data = (void *)ATA_UDMA4 },
+	{ /* sentinel */ }
+};
+
 static int ep93xx_pata_probe(struct platform_device *pdev)
 {
 	struct ep93xx_pata_data *drv_data;
@@ -939,7 +947,7 @@ static int ep93xx_pata_probe(struct platform_device *pdev)
 
 	drv_data = devm_kzalloc(&pdev->dev, sizeof(*drv_data), GFP_KERNEL);
 	if (!drv_data) {
-		err = -ENXIO;
+		err = -ENOMEM;
 		goto err_rel_gpio;
 	}
 
@@ -976,12 +984,11 @@ static int ep93xx_pata_probe(struct platform_device *pdev)
 	 * so this driver supports only UDMA modes.
 	 */
 	if (drv_data->dma_rx_channel && drv_data->dma_tx_channel) {
-		int chip_rev = ep93xx_chip_revision();
+		const struct soc_device_attribute *match;
 
-		if (chip_rev == EP93XX_CHIP_REV_E1)
-			ap->udma_mask = ATA_UDMA3;
-		else if (chip_rev == EP93XX_CHIP_REV_E2)
-			ap->udma_mask = ATA_UDMA4;
+		match = soc_device_match(ep93xx_soc_table);
+		if (match)
+			ap->udma_mask = (unsigned int) match->data;
 		else
 			ap->udma_mask = ATA_UDMA2;
 	}
@@ -1016,9 +1023,16 @@ static int ep93xx_pata_remove(struct platform_device *pdev)
 	return 0;
 }
 
+static const struct of_device_id ep93xx_pata_of_ids[] = {
+	{ .compatible = "cirrus,ep9312-pata" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, ep93xx_pata_of_ids);
+
 static struct platform_driver ep93xx_pata_platform_driver = {
 	.driver = {
 		.name = DRV_NAME,
+		.of_match_table = ep93xx_pata_of_ids,
 	},
 	.probe = ep93xx_pata_probe,
 	.remove = ep93xx_pata_remove,

-- 
2.39.2

