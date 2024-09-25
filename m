From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 25 Sep 2024 13:25:21 +0100
Subject: [PATCH v2 11/11] mmc: Add support for ADI SC5XX-family processor
 SDHCI peripherals
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240925-sc5xx-driver-series-v2-11-ad9287c25c08@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727267113; l=7264;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=A43dmfuUIGXeXNwBnvcW1AuOUPG4hddAy7bdAiY6V3c=;
 b=ll0ZJeqK22S8jsl98jTy5253hDf5UeCGuPTb/nYHYbgf2e4gX4xqoRrPiLHhtHGRP+1MemiOi
 CXqIEmajf6tA8UtKRfCh8VQO7vfVwm+3BJ4D13wZ3OsH5tzcARGNsHG
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Ian Roberts <ian.roberts@timesys.com>
Signed-off-by: Ian Roberts <ian.roberts@timesys.com>
Signed-off-by: Vasileios Bimpikas <vasileios.bimpikas@analog.com>
Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
Signed-off-by: Arturs Artamonovs <arturs.artamonovs@analog.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 MAINTAINERS             |   1 +
 drivers/mmc/Kconfig     |   9 +++
 drivers/mmc/Makefile    |   1 +
 drivers/mmc/adi_sdhci.c | 154 ++++++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 165 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 669b9953c3..7ba20a8e49 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -616,6 +616,7 @@ F:	drivers/dma/adi_dma.c
 F:	drivers/gpio/adp5588_gpio.c
 F:	drivers/gpio/gpio-adi-adsp.c
 F:	drivers/i2c/adi_i2c.c
+F:	drivers/mmc/adi_sdhci.c
 F:	drivers/net/dwc_eth_qos_adi.c
 F:	drivers/pinctrl/pinctrl-adi-adsp.c
 F:	drivers/remoteproc/adi_sc5xx_rproc.c
diff --git a/drivers/mmc/Kconfig b/drivers/mmc/Kconfig
index 982e84dc3b..6ac65a8ba8 100644
--- a/drivers/mmc/Kconfig
+++ b/drivers/mmc/Kconfig
@@ -281,6 +281,15 @@ config MMC_DW_ROCKCHIP
 	  SD 3.0, SDIO 3.0 and MMC 4.5 and supports common eMMC chips as well
 	  as removeable SD and micro-SD cards.
 
+config MMC_SDHCI_ADI
+	bool "ADI SD/MMC controller support"
+	depends on ARCH_SC5XX
+	depends on DM_MMC && OF_CONTROL
+	depends on MMC_SDHCI && MMC_SDHCI_ADMA
+	help
+	  This enables support for the SD/MMC controller included in some Analog
+	  Devices SC5XX Socs.
+
 config MMC_DW_SOCFPGA
 	bool "SOCFPGA specific extensions for Synopsys DW Memory Card Interface"
 	depends on ARCH_SOCFPGA
diff --git a/drivers/mmc/Makefile b/drivers/mmc/Makefile
index 72c3fb66ce..eac8c28ee5 100644
--- a/drivers/mmc/Makefile
+++ b/drivers/mmc/Makefile
@@ -69,6 +69,7 @@ obj-$(CONFIG_MMC_SDHCI_MV)		+= mv_sdhci.o
 obj-$(CONFIG_MMC_SDHCI_NPCM)            += npcm_sdhci.o
 obj-$(CONFIG_MMC_SDHCI_PIC32)		+= pic32_sdhci.o
 obj-$(CONFIG_MMC_SDHCI_ROCKCHIP)	+= rockchip_sdhci.o
+obj-$(CONFIG_MMC_SDHCI_ADI)		+= adi_sdhci.o
 obj-$(CONFIG_MMC_SDHCI_S5P)		+= s5p_sdhci.o
 obj-$(CONFIG_MMC_SDHCI_STI)		+= sti_sdhci.o
 obj-$(CONFIG_MMC_SDHCI_TANGIER)		+= tangier_sdhci.o
diff --git a/drivers/mmc/adi_sdhci.c b/drivers/mmc/adi_sdhci.c
new file mode 100644
index 0000000000..311089a5f5
--- /dev/null
+++ b/drivers/mmc/adi_sdhci.c
@@ -0,0 +1,154 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2022 - Analog Devices, Inc.
+ *
+ * Written and/or maintained by Timesys Corporation
+ *
+ * Contact: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
+ * Contact: Greg Malysa <greg.malysa@timesys.com>
+ *
+ * Based on Rockchip's sdhci.c file
+ */
+
+#include <clk.h>
+#include <dm.h>
+#include <malloc.h>
+#include <sdhci.h>
+#include <asm/cache.h>
+
+/* 400KHz is max freq for card ID etc. Use that as min */
+#define EMMC_MIN_FREQ	400000
+
+/* Check if an operation crossed a boundary of size ADMA_BOUNDARY_ALIGN */
+#define ADMA_BOUNDARY_ALGN SZ_128M
+#define BOUNDARY_OK(addr, len) \
+	(((addr) | (ADMA_BOUNDARY_ALGN - 1)) == (((addr) + (len) - 1) | \
+	(ADMA_BOUNDARY_ALGN - 1)))
+
+/* We split a descriptor for every crossing of the ADMA alignment boundary,
+ * so we need an additional descriptor for every expected crossing.
+ * As I understand it, the max expected transaction size is:
+ *  CONFIG_SYS_MMC_MAX_BLK_COUNT * MMC_MAX_BLOCK_LEN
+ *
+ * With the way the SDHCI-ADMA driver is implemented, if ADMA_MAX_LEN was a
+ * clean power of two, we'd only ever need +1 descriptor as the first
+ * descriptor that got split would then bring the remaining DMA
+ * destination addresses into alignment. Unfortunately, it's currently
+ * hardcoded to a non-power-of-two value.
+ *
+ * If that ever becomes parameterized, ADMA max length can be set to
+ * 0x10000, and set this to 1.
+ */
+#define ADMA_POTENTIAL_CROSSINGS \
+	DIV_ROUND_UP((CONFIG_SYS_MMC_MAX_BLK_COUNT * MMC_MAX_BLOCK_LEN), \
+		 ADMA_BOUNDARY_ALGN)
+/* +1 descriptor for each crossing.
+ */
+#define ADMA_TABLE_EXTRA_SZ (ADMA_POTENTIAL_CROSSINGS * ADMA_DESC_LEN)
+
+struct adi_sdhc_plat {
+	struct mmc_config cfg;
+	struct mmc mmc;
+};
+
+struct adi_sdhc {
+	struct sdhci_host host;
+	void *base;
+};
+
+void adi_dwcmshc_adma_write_desc(struct sdhci_host *host, void **desc,
+				 dma_addr_t addr, int len, bool end)
+{
+	int tmplen, offset;
+
+	if (likely(!len || BOUNDARY_OK(addr, len))) {
+		sdhci_adma_write_desc(host, desc, addr, len, end);
+		return;
+	}
+
+	offset = addr & (ADMA_BOUNDARY_ALGN - 1);
+	tmplen = ADMA_BOUNDARY_ALGN - offset;
+	sdhci_adma_write_desc(host, desc, addr, tmplen, false);
+
+	addr += tmplen;
+	len -= tmplen;
+	sdhci_adma_write_desc(host, desc, addr, len, end);
+}
+
+struct sdhci_ops adi_dwcmshc_sdhci_ops = {
+	.adma_write_desc = adi_dwcmshc_adma_write_desc,
+};
+
+static int adi_dwcmshc_sdhci_probe(struct udevice *dev)
+{
+	struct mmc_uclass_priv *upriv = dev_get_uclass_priv(dev);
+	struct adi_sdhc_plat *plat = dev_get_plat(dev);
+	struct adi_sdhc *prv = dev_get_priv(dev);
+	struct sdhci_host *host = &prv->host;
+	int max_frequency, ret;
+	struct clk clk;
+
+	max_frequency = dev_read_u32_default(dev, "max-frequency", 0);
+	ret = clk_get_by_index(dev, 0, &clk);
+
+	host->quirks = 0;
+	host->max_clk = max_frequency;
+	/*
+	 * The sdhci-driver only supports 4bit and 8bit, as sdhci_setup_cfg
+	 * doesn't allow us to clear MMC_MODE_4BIT.  Consequently, we don't
+	 * check for other bus-width values.
+	 */
+	if (host->bus_width == 8)
+		host->host_caps |= MMC_MODE_8BIT;
+
+	host->mmc = &plat->mmc;
+	host->mmc->priv = &prv->host;
+	host->mmc->dev = dev;
+	upriv->mmc = host->mmc;
+
+	host->ops = &adi_dwcmshc_sdhci_ops;
+	host->adma_desc_table = memalign(ARCH_DMA_MINALIGN,
+					 ADMA_TABLE_SZ + ADMA_TABLE_EXTRA_SZ);
+	host->adma_addr = virt_to_phys(host->adma_desc_table);
+
+	ret = sdhci_setup_cfg(&plat->cfg, host, 0, EMMC_MIN_FREQ);
+	if (ret)
+		return ret;
+
+	return sdhci_probe(dev);
+}
+
+static int adi_dwcmshc_sdhci_of_to_plat(struct udevice *dev)
+{
+	struct sdhci_host *host = dev_get_priv(dev);
+
+	host->name = dev->name;
+	host->ioaddr = dev_read_addr_ptr(dev);
+	host->bus_width = dev_read_u32_default(dev, "bus-width", 4);
+
+	return 0;
+}
+
+static int adi_sdhci_bind(struct udevice *dev)
+{
+	struct adi_sdhc_plat *plat = dev_get_plat(dev);
+
+	return sdhci_bind(dev, &plat->mmc, &plat->cfg);
+}
+
+static const struct udevice_id adi_dwcmshc_sdhci_ids[] = {
+	{ .compatible = "adi,dwc-sdhci" },
+	{ }
+};
+
+U_BOOT_DRIVER(adi_dwcmshc_sdhci_drv) = {
+	.name		= "adi_sdhci",
+	.id		= UCLASS_MMC,
+	.of_match	= adi_dwcmshc_sdhci_ids,
+	.of_to_plat	= adi_dwcmshc_sdhci_of_to_plat,
+	.ops		= &sdhci_ops,
+	.bind		= adi_sdhci_bind,
+	.probe		= adi_dwcmshc_sdhci_probe,
+	.priv_auto	= sizeof(struct adi_sdhc),
+	.plat_auto	= sizeof(struct adi_sdhc_plat),
+};

-- 
2.34.1

