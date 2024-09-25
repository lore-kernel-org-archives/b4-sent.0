From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 25 Sep 2024 13:25:14 +0100
Subject: [PATCH v2 04/11] usb: musb-new: Add support for Analog Devices
 SC5xx SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240925-sc5xx-driver-series-v2-4-ad9287c25c08@analog.com>
References: <20240925-sc5xx-driver-series-v2-0-ad9287c25c08@analog.com>
In-Reply-To: <20240925-sc5xx-driver-series-v2-0-ad9287c25c08@analog.com>
To: Tom Rini <trini@konsulko.com>, 
 Nathan Barrett-Morrison <nathan.morrison@timesys.com>, 
 Greg Malysa <greg.malysa@timesys.com>, 
 Ian Roberts <ian.roberts@timesys.com>, 
 Vasileios Bimpikas <vasileios.bimpikas@analog.com>, 
 Utsav Agarwal <utsav.agarwal@analog.com>, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, 
 Marek Vasut <marex@denx.de>, Heiko Schocher <hs@denx.de>, 
 Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>, Stefan Roese <sr@denx.de>, 
 Jagan Teki <jagan@amarulasolutions.com>, Peng Fan <peng.fan@nxp.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>
Cc: u-boot@lists.denx.de, adsp-linux@analog.com, 
 Oliver Gaskell <Oliver.Gaskell@analog.com>, 
 20240828-sc5xx-upstreaming-patches-v1-0-44d9adfdf327@analog.com
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727267113; l=7873;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=b7wb8WS5I6V981wo48TjA/DkbgZGEkdQ2gZVo9uTppY=;
 b=JcMMuKlgu+WF5FOE8SYh3uuEQdXlkitz/Oh/kkGHV6UxN5MlEm/vCRVWMnK+nMPr36vQ0raUM
 Jlum2Cwv7IeC2v9AhnCAM7ce3ves+QJ+vuGpW1zLvlHo1XNy3TQtm1A
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Nathan Barrett-Morrison <nathan.morrison@timesys.com>

This adds support for the MUSB-based USB controller found in the
Analog Devices SC57x and SC58x SoCs.

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Ian Roberts <ian.roberts@timesys.com>
Signed-off-by: Ian Roberts <ian.roberts@timesys.com>
Signed-off-by: Vasileios Bimpikas <vasileios.bimpikas@analog.com>
Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
Signed-off-by: Arturs Artamonovs <arturs.artamonovs@analog.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
---
 MAINTAINERS                   |   1 +
 drivers/usb/musb-new/Kconfig  |   7 ++
 drivers/usb/musb-new/Makefile |   1 +
 drivers/usb/musb-new/sc5xx.c  | 202 ++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 211 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 225012025c..6b3b0bb9b3 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -617,6 +617,7 @@ F:	drivers/gpio/gpio-adi-adsp.c
 F:	drivers/pinctrl/pinctrl-adi-adsp.c
 F:	drivers/serial/serial_adi_uart4.c
 F:	drivers/timer/adi_sc5xx_timer.c
+F:	drivers/usb/musb-new/sc5xx.c
 F:	include/configs/sc5*
 F:	include/env/adi/
 
diff --git a/drivers/usb/musb-new/Kconfig b/drivers/usb/musb-new/Kconfig
index c52afd41a7..ad9072a532 100644
--- a/drivers/usb/musb-new/Kconfig
+++ b/drivers/usb/musb-new/Kconfig
@@ -22,6 +22,13 @@ config USB_MUSB_GADGET
 	  Enables the MUSB USB dual-role controller in gadget mode.
 
 if USB_MUSB_HOST || USB_MUSB_GADGET
+config USB_MUSB_SC5XX
+        bool "Analog Devices MUSB support"
+        depends on (SC57X || SC58X)
+	help
+	 Say y here to enable support for the USB controller on
+	 ADI SC57X/SC58X processors.
+
 config USB_MUSB_DA8XX
 	bool "Enable DA8xx MUSB Controller"
 	depends on ARCH_DAVINCI
diff --git a/drivers/usb/musb-new/Makefile b/drivers/usb/musb-new/Makefile
index 396ff02654..6638772dac 100644
--- a/drivers/usb/musb-new/Makefile
+++ b/drivers/usb/musb-new/Makefile
@@ -14,6 +14,7 @@ obj-$(CONFIG_USB_MUSB_PIC32) += pic32.o
 obj-$(CONFIG_USB_MUSB_SUNXI) += sunxi.o
 obj-$(CONFIG_USB_MUSB_TI) += ti-musb.o
 obj-$(CONFIG_USB_MUSB_UX500) += ux500.o
+obj-$(CONFIG_USB_MUSB_SC5XX) += sc5xx.o
 
 ccflags-y := $(call cc-option,-Wno-unused-variable) \
 		$(call cc-option,-Wno-unused-but-set-variable) \
diff --git a/drivers/usb/musb-new/sc5xx.c b/drivers/usb/musb-new/sc5xx.c
new file mode 100644
index 0000000000..16201480b4
--- /dev/null
+++ b/drivers/usb/musb-new/sc5xx.c
@@ -0,0 +1,202 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2022 - Analog Devices, Inc.
+ *
+ * ADI SC5XX MUSB "glue layer"
+ *
+ * Written and/or maintained by Timesys Corporation
+ *
+ * Loosely ported from Linux driver:
+ * Author: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
+ *
+ */
+
+#include <dm.h>
+#include <dm/device_compat.h>
+#include <linux/bitops.h>
+#include <linux/io.h>
+#include <linux/usb/musb.h>
+#include "linux-compat.h"
+#include "musb_core.h"
+#include "musb_uboot.h"
+
+#define MUSB_SOFTRST		0x7f
+#define  MUSB_SOFTRST_NRST	BIT(0)
+#define  MUSB_SOFTRST_NRSTX	BIT(1)
+
+#define REG_USB_VBUS_CTL	0x380
+#define REG_USB_ID_CTL		0x382
+#define REG_USB_PHY_CTL		0x394
+#define REG_USB_PLL_OSC		0x398
+#define REG_USB_UTMI_CTL	0x39c
+
+/* controller data */
+struct sc5xx_musb_data {
+	struct musb_host_data mdata;
+	struct device dev;
+};
+
+#define to_sc5xx_musb_data(d)	\
+	container_of(d, struct sc5xx_musb_data, dev)
+
+static void sc5xx_musb_disable(struct musb *musb)
+{
+	/* no way to shut the controller */
+}
+
+static int sc5xx_musb_enable(struct musb *musb)
+{
+	/* soft reset by NRSTx */
+	musb_writeb(musb->mregs, MUSB_SOFTRST, MUSB_SOFTRST_NRSTX);
+	/* set mode */
+	musb_platform_set_mode(musb, musb->board_mode);
+
+	return 0;
+}
+
+static irqreturn_t sc5xx_interrupt(int irq, void *hci)
+{
+	struct musb  *musb = hci;
+	irqreturn_t ret = IRQ_NONE;
+	u8 devctl;
+
+	musb->int_usb = musb_readb(musb->mregs, MUSB_INTRUSB);
+	musb->int_tx = musb_readw(musb->mregs, MUSB_INTRTX);
+	musb->int_rx = musb_readw(musb->mregs, MUSB_INTRRX);
+
+	if (musb->int_usb & MUSB_INTR_VBUSERROR) {
+		musb->int_usb &= ~MUSB_INTR_VBUSERROR;
+		devctl = musb_readw(musb->mregs, MUSB_DEVCTL);
+		devctl |= MUSB_DEVCTL_SESSION;
+		musb_writeb(musb->mregs, MUSB_DEVCTL, devctl);
+	}
+	if (musb->int_usb || musb->int_tx || musb->int_rx) {
+		musb_writeb(musb->mregs, MUSB_INTRUSB, musb->int_usb);
+		musb_writew(musb->mregs, MUSB_INTRTX, musb->int_tx);
+		musb_writew(musb->mregs, MUSB_INTRRX, musb->int_rx);
+		ret = musb_interrupt(musb);
+	}
+
+	if (musb->int_usb & MUSB_INTR_DISCONNECT && is_host_active(musb))
+		musb_writeb(musb->mregs, REG_USB_VBUS_CTL, 0x0);
+
+	return ret;
+}
+
+static int sc5xx_musb_set_mode(struct musb *musb, u8 mode)
+{
+	struct device *dev = musb->controller;
+	struct sc5xx_musb_data *pdata = to_sc5xx_musb_data(dev);
+
+	switch (mode) {
+	case MUSB_HOST:
+		musb_writeb(musb->mregs, REG_USB_ID_CTL, 0x1);
+		break;
+	case MUSB_PERIPHERAL:
+		musb_writeb(musb->mregs, REG_USB_ID_CTL, 0x3);
+		break;
+	case MUSB_OTG:
+		musb_writeb(musb->mregs, REG_USB_ID_CTL, 0x0);
+		break;
+	default:
+		dev_err(dev, "unsupported mode %d\n", mode);
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+static int sc5xx_musb_init(struct musb *musb)
+{
+	struct sc5xx_musb_data *pdata = to_sc5xx_musb_data(musb->controller);
+
+	musb->isr = sc5xx_interrupt;
+
+	musb_writel(musb->mregs, REG_USB_PLL_OSC, 20 << 1);
+	musb_writeb(musb->mregs, REG_USB_VBUS_CTL, 0x0);
+	musb_writeb(musb->mregs, REG_USB_PHY_CTL, 0x80);
+	musb_writel(musb->mregs, REG_USB_UTMI_CTL,
+		    0x40 | musb_readl(musb->mregs, REG_USB_UTMI_CTL));
+
+	return 0;
+}
+
+const struct musb_platform_ops sc5xx_musb_ops = {
+	.init		= sc5xx_musb_init,
+	.set_mode	= sc5xx_musb_set_mode,
+	.disable	= sc5xx_musb_disable,
+	.enable		= sc5xx_musb_enable,
+};
+
+static struct musb_hdrc_config sc5xx_musb_config = {
+	.multipoint     = 1,
+	.dyn_fifo       = 1,
+	.num_eps        = 16,
+	.ram_bits       = 12,
+};
+
+/* has one MUSB controller which can be host or gadget */
+static struct musb_hdrc_platform_data sc5xx_musb_plat = {
+	.mode           = MUSB_HOST,
+	.config         = &sc5xx_musb_config,
+	.power          = 100,
+	.platform_ops	= &sc5xx_musb_ops,
+};
+
+static int musb_usb_probe(struct udevice *dev)
+{
+	struct usb_bus_priv *priv = dev_get_uclass_priv(dev);
+	struct sc5xx_musb_data *pdata = dev_get_priv(dev);
+	struct musb_host_data *mdata = &pdata->mdata;
+	void __iomem *mregs;
+	int ret;
+
+	priv->desc_before_addr = true;
+
+	mregs = dev_remap_addr(dev);
+	if (!mregs)
+		return -EINVAL;
+
+	/* init controller */
+	if (IS_ENABLED(CONFIG_USB_MUSB_HOST)) {
+		mdata->host = musb_init_controller(&sc5xx_musb_plat,
+						   &pdata->dev, mregs);
+		if (!mdata->host)
+			return -EIO;
+
+		ret = musb_lowlevel_init(mdata);
+	} else {
+		sc5xx_musb_plat.mode = MUSB_PERIPHERAL;
+		mdata->host = musb_register(&sc5xx_musb_plat, &pdata->dev, mregs);
+		if (!mdata->host)
+			return -EIO;
+	}
+	return ret;
+}
+
+static int musb_usb_remove(struct udevice *dev)
+{
+	struct sc5xx_musb_data *pdata = dev_get_priv(dev);
+
+	musb_stop(pdata->mdata.host);
+
+	return 0;
+}
+
+static const struct udevice_id sc5xx_musb_ids[] = {
+	{ .compatible = "adi,sc5xx-musb" },
+	{ }
+};
+
+U_BOOT_DRIVER(usb_musb) = {
+	.name		= "sc5xx-musb",
+	.id		= UCLASS_USB,
+	.of_match	= sc5xx_musb_ids,
+	.probe		= musb_usb_probe,
+	.remove		= musb_usb_remove,
+#ifdef CONFIG_USB_MUSB_HOST
+	.ops		= &musb_usb_ops,
+#endif
+	.plat_auto	= sizeof(struct usb_plat),
+	.priv_auto	= sizeof(struct sc5xx_musb_data),
+};

-- 
2.34.1

