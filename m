From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Thu, 20 Jul 2023 14:29:24 +0300
Subject: [PATCH v3 24/42] mtd: nand: add support for ts72xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230605-ep93xx-v3-24-3d63a5f1103e@maquefel.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1689852591; l=6240;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=Mcu6XOIf27yl88yMJ5DKfoy1TYVtY2ZKrsI332LEqWY=;
 b=agIHcFgVQ6/WooTScGYRbLZmnJx4lcPMV2ZI2i1PBOFs1khTbLgzmhSfDkx+Tm1D7FU/mlonQAnm
 I7nxdzTrBj3rbtk+lQxGvAQ6CqMSsiVhdplTvJ95p8Eo6QhG7NhM
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Technologic Systems has it's own nand controller implementation in CPLD.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 drivers/mtd/nand/raw/Kconfig                       |   7 +
 drivers/mtd/nand/raw/Makefile                      |   1 +
 drivers/mtd/nand/raw/technologic-nand-controller.c | 162 +++++++++++++++++++++
 3 files changed, 170 insertions(+)

diff --git a/drivers/mtd/nand/raw/Kconfig b/drivers/mtd/nand/raw/Kconfig
index b523354dfb00..94788da1a169 100644
--- a/drivers/mtd/nand/raw/Kconfig
+++ b/drivers/mtd/nand/raw/Kconfig
@@ -456,6 +456,13 @@ config MTD_NAND_RENESAS
 	  Enables support for the NAND controller found on Renesas R-Car
 	  Gen3 and RZ/N1 SoC families.
 
+config MTD_NAND_TS72XX
+	bool "ts72xx NAND controller"
+	depends on ARCH_EP93XX && HAS_IOMEM
+	help
+	  Enables support for NAND controller on ts72xx SBCs.
+	  This is a legacy driver based on gen_nand.
+
 comment "Misc"
 
 config MTD_SM_COMMON
diff --git a/drivers/mtd/nand/raw/Makefile b/drivers/mtd/nand/raw/Makefile
index d93e861d8ba7..b85161c3296b 100644
--- a/drivers/mtd/nand/raw/Makefile
+++ b/drivers/mtd/nand/raw/Makefile
@@ -23,6 +23,7 @@ omap2_nand-objs := omap2.o
 obj-$(CONFIG_MTD_NAND_OMAP2) 		+= omap2_nand.o
 obj-$(CONFIG_MTD_NAND_OMAP_BCH_BUILD)	+= omap_elm.o
 obj-$(CONFIG_MTD_NAND_MARVELL)		+= marvell_nand.o
+obj-$(CONFIG_MTD_NAND_TS72XX)		+= technologic-nand-controller.o
 obj-$(CONFIG_MTD_NAND_PLATFORM)		+= plat_nand.o
 obj-$(CONFIG_MTD_NAND_PASEMI)		+= pasemi_nand.o
 obj-$(CONFIG_MTD_NAND_ORION)		+= orion_nand.o
diff --git a/drivers/mtd/nand/raw/technologic-nand-controller.c b/drivers/mtd/nand/raw/technologic-nand-controller.c
new file mode 100644
index 000000000000..c6a656210099
--- /dev/null
+++ b/drivers/mtd/nand/raw/technologic-nand-controller.c
@@ -0,0 +1,162 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Technologic Systems TS72xx NAND controller driver
+ *
+ * Copyright (C) 2023 Nikita Shubin <nikita.shubin@maquefel.me>
+ *
+ * Derived from: plat_nand.c
+ *  Author: Vitaly Wool <vitalywool@gmail.com>
+ */
+
+#include <linux/err.h>
+#include <linux/io.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+#include <linux/slab.h>
+
+#include <linux/mtd/mtd.h>
+#include <linux/mtd/platnand.h>
+
+#define TS72XX_NAND_CONTROL_ADDR_LINE	22	/* 0xN0400000 */
+#define TS72XX_NAND_BUSY_ADDR_LINE	23	/* 0xN0800000 */
+
+struct ts72xx_nand_data {
+	struct nand_controller	controller;
+	struct nand_chip	chip;
+	void __iomem		*io_base;
+};
+
+static int ts72xx_nand_attach_chip(struct nand_chip *chip)
+{
+	switch (chip->ecc.engine_type) {
+	case NAND_ECC_ENGINE_TYPE_SOFT:
+		if (chip->ecc.algo == NAND_ECC_ALGO_UNKNOWN)
+			chip->ecc.algo = NAND_ECC_ALGO_HAMMING;
+		break;
+	case NAND_ECC_ENGINE_TYPE_ON_HOST:
+		return -EINVAL;
+	default:
+		break;
+	}
+
+	return 0;
+}
+
+static const struct nand_controller_ops ts72xx_nand_ops = {
+	.attach_chip = ts72xx_nand_attach_chip,
+};
+
+static void ts72xx_nand_hwcontrol(struct nand_chip *chip,
+				  int cmd, unsigned int ctrl)
+{
+	if (ctrl & NAND_CTRL_CHANGE) {
+		void __iomem *addr = chip->legacy.IO_ADDR_R;
+		unsigned char bits;
+
+		addr += BIT(TS72XX_NAND_CONTROL_ADDR_LINE);
+
+		bits = readb(addr) & ~GENMASK(2, 0);
+		bits |= (ctrl & NAND_NCE) << 2;	/* bit 0 -> bit 2 */
+		bits |= (ctrl & NAND_CLE);	/* bit 1 -> bit 1 */
+		bits |= (ctrl & NAND_ALE) >> 2;	/* bit 2 -> bit 0 */
+
+		writeb(bits, addr);
+	}
+
+	if (cmd != NAND_CMD_NONE)
+		writeb(cmd, chip->legacy.IO_ADDR_W);
+}
+
+static int ts72xx_nand_device_ready(struct nand_chip *chip)
+{
+	void __iomem *addr = chip->legacy.IO_ADDR_R;
+
+	addr += BIT(TS72XX_NAND_BUSY_ADDR_LINE);
+
+	return !!(readb(addr) & BIT(5));
+}
+
+static int ts72xx_nand_probe(struct platform_device *pdev)
+{
+	struct ts72xx_nand_data *data;
+	struct device_node *child;
+	struct mtd_info *mtd;
+	int err;
+
+	/* Allocate memory for the device structure (and zero it) */
+	data = devm_kzalloc(&pdev->dev, sizeof(*data), GFP_KERNEL);
+	if (!data)
+		return -ENOMEM;
+
+	data->controller.ops = &ts72xx_nand_ops;
+	nand_controller_init(&data->controller);
+	data->chip.controller = &data->controller;
+
+	data->io_base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(data->io_base))
+		return PTR_ERR(data->io_base);
+
+	child = of_get_next_child(pdev->dev.of_node, NULL);
+	if (!child)
+		return dev_err_probe(&pdev->dev, -ENXIO,
+				"ts72xx controller node should have exactly one child\n");
+
+	nand_set_flash_node(&data->chip, child);
+	mtd = nand_to_mtd(&data->chip);
+	mtd->dev.parent = &pdev->dev;
+
+	data->chip.legacy.IO_ADDR_R = data->io_base;
+	data->chip.legacy.IO_ADDR_W = data->io_base;
+	data->chip.legacy.cmd_ctrl = ts72xx_nand_hwcontrol;
+	data->chip.legacy.dev_ready = ts72xx_nand_device_ready;
+
+	platform_set_drvdata(pdev, data);
+
+	/*
+	 * This driver assumes that the default ECC engine should be TYPE_SOFT.
+	 * Set ->engine_type before registering the NAND devices in order to
+	 * provide a driver specific default value.
+	 */
+	data->chip.ecc.engine_type = NAND_ECC_ENGINE_TYPE_SOFT;
+
+	/* Scan to find existence of the device */
+	err = nand_scan(&data->chip, 1);
+	if (err)
+		return err;
+
+	err = mtd_device_parse_register(mtd, NULL, NULL, NULL, 0);
+	if (err) {
+		nand_cleanup(&data->chip);
+		return err;
+	}
+
+	return 0;
+}
+
+static void ts72xx_nand_remove(struct platform_device *pdev)
+{
+	struct ts72xx_nand_data *data = platform_get_drvdata(pdev);
+	struct nand_chip *chip = &data->chip;
+	int ret;
+
+	ret = mtd_device_unregister(nand_to_mtd(chip));
+	WARN_ON(ret);
+	nand_cleanup(chip);
+}
+
+static const struct of_device_id ts72xx_id_table[] = {
+	{ .compatible = "technologic,ts7200-nand" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, ts72xx_id_table);
+
+static struct platform_driver ts72xx_nand_driver = {
+	.driver = {
+		.name = "ts72xx-nand",
+		.of_match_table = ts72xx_id_table,
+	},
+	.probe = ts72xx_nand_probe,
+	.remove_new = ts72xx_nand_remove,
+};
+module_platform_driver(ts72xx_nand_driver);
+

-- 
2.39.2

