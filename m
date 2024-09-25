From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 25 Sep 2024 13:25:18 +0100
Subject: [PATCH v2 08/11] dma: Add driver for ADI SC5xx-family SoC MDMA
 functionality
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240925-sc5xx-driver-series-v2-8-ad9287c25c08@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727267113; l=9583;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=S4rYnHM3J3j2PaANxXoAS/yA+cdfa+nZ4k30IISujDw=;
 b=OhYQ8MqjQk0V+t2FZavSLquY2HLKXiGqci2tQNMaW2JC8UzQDvBHLsd+HA5jwKOXJcZ6D7JVA
 gClUW794nIcAoVM8Kuw3P6jEHreDaGpfbblZOj3d27OuUVLxIQqXW9O
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Greg Malysa <greg.malysa@timesys.com>

Add a rudimentary MDMA driver for the Analog Devices SC5xx SoCs,
primarily intended for use with and tested against the QSPI/OSPI
IP included in the SoC.

Co-developed-by: Ian Roberts <ian.roberts@timesys.com>
Signed-off-by: Ian Roberts <ian.roberts@timesys.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Vasileios Bimpikas <vasileios.bimpikas@analog.com>
Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
Signed-off-by: Arturs Artamonovs <arturs.artamonovs@analog.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
---
 MAINTAINERS           |   1 +
 drivers/dma/Kconfig   |   7 ++
 drivers/dma/Makefile  |   1 +
 drivers/dma/adi_dma.c | 255 ++++++++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 264 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index cbfcc97871..8a54dd4af4 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -612,6 +612,7 @@ F:	doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml
 F:	doc/device-tree-bindings/clock/adi,sc5xx-clocks.yaml
 F:	doc/device-tree-bindings/timer/adi,sc5xx-gptimer.yaml
 F:	drivers/clk/adi/
+F:	drivers/dma/adi_dma.c
 F:	drivers/gpio/adp5588_gpio.c
 F:	drivers/gpio/gpio-adi-adsp.c
 F:	drivers/i2c/adi_i2c.c
diff --git a/drivers/dma/Kconfig b/drivers/dma/Kconfig
index 3c64e89464..4b47be6b01 100644
--- a/drivers/dma/Kconfig
+++ b/drivers/dma/Kconfig
@@ -76,6 +76,13 @@ config XILINX_DPDMA
 	  this file is used as placeholder for driver. The main reason is
 	  to record compatible string and calling power domain driver.
 
+config ADI_DMA
+	bool "ADI DMA driver"
+	depends on DMA && DMA_CHANNELS
+	help
+	  Enable DMA support for Analog Devices SOCs, such as the SC5xx.
+	  Currently this is a minimalistic driver tested against OSPI use only.
+
 if APBH_DMA
 config APBH_DMA_BURST
 	bool "Enable DMA BURST"
diff --git a/drivers/dma/Makefile b/drivers/dma/Makefile
index 48811eaaeb..00d765864c 100644
--- a/drivers/dma/Makefile
+++ b/drivers/dma/Makefile
@@ -13,5 +13,6 @@ obj-$(CONFIG_TI_KSNAV) += keystone_nav.o keystone_nav_cfg.o
 obj-$(CONFIG_TI_EDMA3) += ti-edma3.o
 obj-$(CONFIG_DMA_LPC32XX) += lpc32xx_dma.o
 obj-$(CONFIG_XILINX_DPDMA) += xilinx_dpdma.o
+obj-$(CONFIG_ADI_DMA) += adi_dma.o
 
 obj-y += ti/
diff --git a/drivers/dma/adi_dma.c b/drivers/dma/adi_dma.c
new file mode 100644
index 0000000000..56eceff712
--- /dev/null
+++ b/drivers/dma/adi_dma.c
@@ -0,0 +1,255 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Analog Devices DMA controller driver
+ *
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ *
+ * Written and/or maintained by Timesys Corporation
+ *
+ * Contact: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
+ * Contact: Greg Malysa <greg.malysa@timesys.com>
+ * Contact: Ian Roberts <ian.roberts@timesys.com>
+ *
+ */
+#include <dm.h>
+#include <dma.h>
+#include <dma-uclass.h>
+#include <asm/io.h>
+#include <dm/device_compat.h>
+#include <linux/errno.h>
+
+#define HAS_MDMA	BIT(0)
+
+#define REG_ADDRSTART	0x04
+#define REG_CFG		0x08
+#define REG_XCNT	0x0C
+#define REG_XMOD	0x10
+#define REG_STAT	0x30
+
+#define BITP_DMA_CFG_MSIZE                        8
+#define BITP_DMA_CFG_PSIZE                        4
+#define BITM_DMA_CFG_WNR                 0x00000002
+#define BITM_DMA_CFG_EN                  0x00000001
+#define ENUM_DMA_CFG_XCNT_INT            0x00100000
+
+#define BITP_DMA_STAT_PBWID                      12
+#define BITP_DMA_STAT_ERRC                        4
+#define BITM_DMA_STAT_PBWID              0x00003000
+#define BITM_DMA_STAT_ERRC               0x00000070
+#define BITM_DMA_STAT_PIRQ               0x00000004
+#define BITM_DMA_STAT_IRQERR             0x00000002
+#define BITM_DMA_STAT_IRQDONE            0x00000001
+
+#define DMA_MDMA_SRC_DEFAULT_CONFIG(psize, msize) \
+	(BITM_DMA_CFG_EN | ((psize) << BITP_DMA_CFG_PSIZE) | ((msize) << BITP_DMA_CFG_MSIZE))
+#define DMA_MDMA_DST_DEFAULT_CONFIG(psize, msize) \
+	(BITM_DMA_CFG_EN | BITM_DMA_CFG_WNR | ENUM_DMA_CFG_XCNT_INT | \
+	((psize) << BITP_DMA_CFG_PSIZE) | ((msize) << BITP_DMA_CFG_MSIZE))
+
+struct adi_dma_channel {
+	int id;
+	struct adi_dma *dma;
+	void __iomem *iosrc;
+	void __iomem *iodest;
+};
+
+struct adi_dma {
+	struct udevice *dev;
+	struct adi_dma_channel channels[1];
+	void __iomem *ioaddr;
+	unsigned long hw_cfg;
+};
+
+static const struct udevice_id dma_dt_ids[] = {
+	{ .compatible = "adi,mdma-controller", .data = HAS_MDMA },
+	{ }
+};
+
+static u8 adi_dma_get_msize(u32 n_bytecount, u32 n_address)
+{
+	/* Calculate MSIZE, PSIZE, XCNT and XMOD */
+	u8 n_msize = 0;
+	u32 n_value = n_bytecount | n_address;
+	u32 n_mask = 0x1;
+
+	for (n_msize = 0; n_msize < 5; n_msize++, n_mask <<= 1) {
+		if ((n_value & n_mask) == n_mask)
+			break;
+	}
+
+	return n_msize;
+}
+
+static int adi_dma_get_ch_error(void __iomem *ch)
+{
+	u32 cause = (readl(ch + REG_STAT) &  BITM_DMA_STAT_ERRC) >>
+		    BITP_DMA_STAT_ERRC;
+	switch (cause) {
+	case 0:
+		return -EINVAL;
+	case 1:
+		return -EBUSY;
+	case 2:
+		return -EFAULT;
+	case 3:
+		fallthrough;
+	case 5:
+		fallthrough;
+	case 6:
+		fallthrough;
+	default:
+		return -EIO;
+	}
+}
+
+static int adi_mdma_transfer(struct udevice *dev, int direction,
+			     dma_addr_t dst, dma_addr_t src, size_t len)
+{
+	struct adi_dma *priv = dev_get_priv(dev);
+	void __iomem *chsrc = priv->channels[0].iosrc;
+	void __iomem *chdst = priv->channels[0].iodest;
+
+	int result = 0;
+	u32 reg;
+	u32 bytecount = len;
+
+	u8 n_srcmsize;
+	u8 n_dstmsize;
+	u8 n_srcpsize;
+	u8 n_dstpsize;
+	u8 n_psize;
+	u32 srcconfig;
+	u32 dstconfig;
+	u8 srcpsizemax = (readl(chsrc + REG_STAT) & BITM_DMA_STAT_PBWID) >>
+			 BITP_DMA_STAT_PBWID;
+	u8 dstpsizemax = (readl(chdst + REG_STAT) & BITM_DMA_STAT_PBWID) >>
+			 BITP_DMA_STAT_PBWID;
+
+	const u32 CLRSTAT = (BITM_DMA_STAT_IRQDONE | BITM_DMA_STAT_IRQERR |
+			     BITM_DMA_STAT_PIRQ);
+
+	if (len == 0)
+		return -EINVAL;
+
+	/* Clear DMA status */
+	writel(CLRSTAT, chsrc + REG_STAT);
+	writel(CLRSTAT, chdst + REG_STAT);
+
+	/* Calculate MSIZE, PSIZE, XCNT and XMOD */
+	n_srcmsize = adi_dma_get_msize(bytecount, src);
+	n_dstmsize = adi_dma_get_msize(bytecount, dst);
+	n_srcpsize = min(n_srcmsize, srcpsizemax);
+	n_dstpsize = min(n_dstmsize, dstpsizemax);
+	n_psize = min(n_srcpsize, n_dstpsize);
+
+	srcconfig = DMA_MDMA_SRC_DEFAULT_CONFIG(n_psize, n_srcmsize);
+	dstconfig = DMA_MDMA_DST_DEFAULT_CONFIG(n_psize, n_dstmsize);
+
+	/* Load the DMA descriptors */
+	writel(src,			chsrc + REG_ADDRSTART);
+	writel(bytecount >> n_srcmsize,	chsrc + REG_XCNT);
+	writel(1 << n_srcmsize,		chsrc + REG_XMOD);
+	writel(dst,			chdst + REG_ADDRSTART);
+	writel(bytecount >> n_dstmsize,	chdst + REG_XCNT);
+	writel(1 << n_dstmsize,		chdst + REG_XMOD);
+
+	writel(dstconfig, chdst + REG_CFG);
+	writel(srcconfig, chsrc + REG_CFG);
+
+	/* Wait for DMA to complete while checking for a DMA error */
+	do {
+		reg = readl(chsrc + REG_STAT);
+		if ((reg & BITM_DMA_STAT_IRQERR) == BITM_DMA_STAT_IRQERR) {
+			result = adi_dma_get_ch_error(chsrc);
+			break;
+		}
+		reg = readl(chdst + REG_STAT);
+		if ((reg & BITM_DMA_STAT_IRQERR) == BITM_DMA_STAT_IRQERR) {
+			result = adi_dma_get_ch_error(chdst);
+			break;
+		}
+	} while ((reg & BITM_DMA_STAT_IRQDONE) == 0);
+
+	reg = readl(chsrc + REG_CFG);
+	writel(reg & ~1, chsrc + REG_CFG);
+	reg = readl(chdst + REG_CFG);
+	writel(reg & ~1, chdst + REG_CFG);
+
+	return result;
+}
+
+static int adi_dma_init_channel(struct adi_dma *dma,
+				struct adi_dma_channel *channel, ofnode node)
+{
+	u32 offset;
+
+	if (ofnode_read_u32(node, "adi,id", &channel->id)) {
+		dev_err(dma->dev, "Missing adi,id for channel %s\n",
+			ofnode_get_name(node));
+		return -ENOENT;
+	}
+
+	if (ofnode_read_u32(node, "adi,src-offset", &offset)) {
+		dev_err(dma->dev, "Missing adi,src-offset for channel %s\n",
+			ofnode_get_name(node));
+		return -ENOENT;
+	}
+
+	channel->iosrc = dma->ioaddr + offset;
+	channel->dma = dma;
+
+	if (dma->hw_cfg & HAS_MDMA) {
+		if (ofnode_read_u32(node, "adi,dest-offset", &offset)) {
+			dev_err(dma->dev,
+				"Missing adi,dest-offset for channel %s\n",
+				ofnode_get_name(node));
+			return -ENOENT;
+		}
+		channel->iodest = dma->ioaddr + offset;
+	}
+
+	return 0;
+}
+
+static int adi_dma_probe(struct udevice *dev)
+{
+	struct dma_dev_priv *uc_priv = dev_get_uclass_priv(dev);
+	struct adi_dma *priv = dev_get_priv(dev);
+	ofnode node, child;
+
+	priv->hw_cfg = dev_get_driver_data(dev);
+	if (priv->hw_cfg & HAS_MDMA)
+		uc_priv->supported = DMA_SUPPORTS_MEM_TO_MEM;
+
+	priv->ioaddr = dev_remap_addr(dev);
+	if (!priv->ioaddr)
+		return -EINVAL;
+
+	node = dev_read_first_subnode(dev);
+	if (!ofnode_valid(node)) {
+		dev_err(dev,
+			"Error: device tree DMA channel config missing!\n");
+		return -ENODEV;
+	}
+
+	node = dev_ofnode(dev);
+	ofnode_for_each_subnode(child, node) {
+		adi_dma_init_channel(priv, priv->channels, child);
+		break; //Only 1 channel supported for now
+	}
+
+	return 0;
+}
+
+static const struct dma_ops adi_dma_ops = {
+	.transfer = adi_mdma_transfer,
+};
+
+U_BOOT_DRIVER(adi_dma) = {
+	.name = "adi_dma",
+	.id = UCLASS_DMA,
+	.of_match = dma_dt_ids,
+	.ops = &adi_dma_ops,
+	.probe = adi_dma_probe,
+	.priv_auto = sizeof(struct adi_dma),
+};

-- 
2.34.1

