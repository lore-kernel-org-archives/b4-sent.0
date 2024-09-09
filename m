From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Mon, 09 Sep 2024 11:10:59 +0300
Subject: [PATCH v12 34/38] ata: pata_ep93xx: remove legacy pinctrl use
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240909-ep93xx-v12-34-e86ab2423d4b@maquefel.me>
References: <20240909-ep93xx-v12-0-e86ab2423d4b@maquefel.me>
In-Reply-To: <20240909-ep93xx-v12-0-e86ab2423d4b@maquefel.me>
To: Hartley Sweeten <hsweeten@visionengravers.com>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Sergey Shtylyov <s.shtylyov@omp.ru>, 
 Damien Le Moal <dlemoal@kernel.org>, Niklas Cassel <cassel@kernel.org>, 
 Nikita Shubin <nikita.shubin@maquefel.me>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>
Cc: Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-ide@vger.kernel.org
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725869532; l=5459;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=JKdRtMOxmJOigA+HsuRSo4me4xtHq4Wfii+aJcJbkDg=;
 b=dRR1PJcolKnPBKJMTxCD9BUbTS7hDXe3eOkV8MmETyRZlpGLTNZb6Pu1LqpXemp78af57RMxy71e
 NHMNwg/YC2WNwn085f6YUufuWbXvvB/3uBp5M50IfYYbPtZ8zteR
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop legacy acquire/release since we are using pinctrl for this now.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
Reviewed-by: Sergey Shtylyov <s.shtylyov@omp.ru>
Acked-by: Damien Le Moal <dlemoal@kernel.org>
Reviewed-by: Linus Walleij <linus.walleij@linaro.org>
Reviewed-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
---
 arch/arm/mach-ep93xx/core.c       | 72 ---------------------------------------
 drivers/ata/pata_ep93xx.c         | 25 ++++----------
 include/linux/soc/cirrus/ep93xx.h |  4 ---
 3 files changed, 6 insertions(+), 95 deletions(-)

diff --git a/arch/arm/mach-ep93xx/core.c b/arch/arm/mach-ep93xx/core.c
index 4ddf1a4cba33..9c6154bb37b5 100644
--- a/arch/arm/mach-ep93xx/core.c
+++ b/arch/arm/mach-ep93xx/core.c
@@ -779,78 +779,6 @@ void __init ep93xx_register_ide(void)
 	platform_device_register(&ep93xx_ide_device);
 }
 
-int ep93xx_ide_acquire_gpio(struct platform_device *pdev)
-{
-	int err;
-	int i;
-
-	err = gpio_request(EP93XX_GPIO_LINE_EGPIO2, dev_name(&pdev->dev));
-	if (err)
-		return err;
-	err = gpio_request(EP93XX_GPIO_LINE_EGPIO15, dev_name(&pdev->dev));
-	if (err)
-		goto fail_egpio15;
-	for (i = 2; i < 8; i++) {
-		err = gpio_request(EP93XX_GPIO_LINE_E(i), dev_name(&pdev->dev));
-		if (err)
-			goto fail_gpio_e;
-	}
-	for (i = 4; i < 8; i++) {
-		err = gpio_request(EP93XX_GPIO_LINE_G(i), dev_name(&pdev->dev));
-		if (err)
-			goto fail_gpio_g;
-	}
-	for (i = 0; i < 8; i++) {
-		err = gpio_request(EP93XX_GPIO_LINE_H(i), dev_name(&pdev->dev));
-		if (err)
-			goto fail_gpio_h;
-	}
-
-	/* GPIO ports E[7:2], G[7:4] and H used by IDE */
-	ep93xx_devcfg_clear_bits(EP93XX_SYSCON_DEVCFG_EONIDE |
-				 EP93XX_SYSCON_DEVCFG_GONIDE |
-				 EP93XX_SYSCON_DEVCFG_HONIDE);
-	return 0;
-
-fail_gpio_h:
-	for (--i; i >= 0; --i)
-		gpio_free(EP93XX_GPIO_LINE_H(i));
-	i = 8;
-fail_gpio_g:
-	for (--i; i >= 4; --i)
-		gpio_free(EP93XX_GPIO_LINE_G(i));
-	i = 8;
-fail_gpio_e:
-	for (--i; i >= 2; --i)
-		gpio_free(EP93XX_GPIO_LINE_E(i));
-	gpio_free(EP93XX_GPIO_LINE_EGPIO15);
-fail_egpio15:
-	gpio_free(EP93XX_GPIO_LINE_EGPIO2);
-	return err;
-}
-EXPORT_SYMBOL(ep93xx_ide_acquire_gpio);
-
-void ep93xx_ide_release_gpio(struct platform_device *pdev)
-{
-	int i;
-
-	for (i = 2; i < 8; i++)
-		gpio_free(EP93XX_GPIO_LINE_E(i));
-	for (i = 4; i < 8; i++)
-		gpio_free(EP93XX_GPIO_LINE_G(i));
-	for (i = 0; i < 8; i++)
-		gpio_free(EP93XX_GPIO_LINE_H(i));
-	gpio_free(EP93XX_GPIO_LINE_EGPIO15);
-	gpio_free(EP93XX_GPIO_LINE_EGPIO2);
-
-
-	/* GPIO ports E[7:2], G[7:4] and H used by GPIO */
-	ep93xx_devcfg_set_bits(EP93XX_SYSCON_DEVCFG_EONIDE |
-			       EP93XX_SYSCON_DEVCFG_GONIDE |
-			       EP93XX_SYSCON_DEVCFG_HONIDE);
-}
-EXPORT_SYMBOL(ep93xx_ide_release_gpio);
-
 /*************************************************************************
  * EP93xx ADC
  *************************************************************************/
diff --git a/drivers/ata/pata_ep93xx.c b/drivers/ata/pata_ep93xx.c
index 13246a92e29f..a8555f630097 100644
--- a/drivers/ata/pata_ep93xx.c
+++ b/drivers/ata/pata_ep93xx.c
@@ -922,28 +922,18 @@ static int ep93xx_pata_probe(struct platform_device *pdev)
 	void __iomem *ide_base;
 	int err;
 
-	err = ep93xx_ide_acquire_gpio(pdev);
-	if (err)
-		return err;
-
 	/* INT[3] (IRQ_EP93XX_EXT3) line connected as pull down */
 	irq = platform_get_irq(pdev, 0);
-	if (irq < 0) {
-		err = irq;
-		goto err_rel_gpio;
-	}
+	if (irq < 0)
+		return irq;
 
 	ide_base = devm_platform_get_and_ioremap_resource(pdev, 0, &mem_res);
-	if (IS_ERR(ide_base)) {
-		err = PTR_ERR(ide_base);
-		goto err_rel_gpio;
-	}
+	if (IS_ERR(ide_base))
+		return PTR_ERR(ide_base);
 
 	drv_data = devm_kzalloc(&pdev->dev, sizeof(*drv_data), GFP_KERNEL);
-	if (!drv_data) {
-		err = -ENOMEM;
-		goto err_rel_gpio;
-	}
+	if (!drv_data)
+		return -ENOMEM;
 
 	drv_data->pdev = pdev;
 	drv_data->ide_base = ide_base;
@@ -1002,8 +992,6 @@ static int ep93xx_pata_probe(struct platform_device *pdev)
 
 err_rel_dma:
 	ep93xx_pata_release_dma(drv_data);
-err_rel_gpio:
-	ep93xx_ide_release_gpio(pdev);
 	return err;
 }
 
@@ -1015,7 +1003,6 @@ static void ep93xx_pata_remove(struct platform_device *pdev)
 	ata_host_detach(host);
 	ep93xx_pata_release_dma(drv_data);
 	ep93xx_pata_clear_regs(drv_data->ide_base);
-	ep93xx_ide_release_gpio(pdev);
 }
 
 static const struct of_device_id ep93xx_pata_of_ids[] = {
diff --git a/include/linux/soc/cirrus/ep93xx.h b/include/linux/soc/cirrus/ep93xx.h
index f6376edc1b33..142c33a2d7db 100644
--- a/include/linux/soc/cirrus/ep93xx.h
+++ b/include/linux/soc/cirrus/ep93xx.h
@@ -37,15 +37,11 @@ struct ep93xx_regmap_adev {
 	container_of((_adev), struct ep93xx_regmap_adev, adev)
 
 #ifdef CONFIG_ARCH_EP93XX
-int ep93xx_ide_acquire_gpio(struct platform_device *pdev);
-void ep93xx_ide_release_gpio(struct platform_device *pdev);
 int ep93xx_i2s_acquire(void);
 void ep93xx_i2s_release(void);
 unsigned int ep93xx_chip_revision(void);
 
 #else
-static inline int ep93xx_ide_acquire_gpio(struct platform_device *pdev) { return 0; }
-static inline void ep93xx_ide_release_gpio(struct platform_device *pdev) {}
 static inline int ep93xx_i2s_acquire(void) { return 0; }
 static inline void ep93xx_i2s_release(void) {}
 static inline unsigned int ep93xx_chip_revision(void) { return 0; }

-- 
2.43.2

