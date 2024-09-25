From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 25 Sep 2024 13:25:19 +0100
Subject: [PATCH v2 09/11] remoteproc: Add in SHARC loading for ADI
 SC5XX-family processors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240925-sc5xx-driver-series-v2-9-ad9287c25c08@analog.com>
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
 20240828-sc5xx-upstreaming-patches-v1-0-44d9adfdf327@analog.com, 
 Piotr Wojtaszczyk <piotr.wojtaszczyk@timesys.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727267113; l=11171;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=6lHpqUwO0w8SQf8kN/+4hEamBbDGDJRxRYVSW7HDtrc=;
 b=Z79OaZtBojxKA+Y6X2cwPYszjVpJtex/2JIc2dy5/bXR0Mn3Ac+rzTO06MPsLSPFZeRdK42Uu
 r5zzvXdbWy7Bmm5Y+y68NWC/3QTJk5tPlL23HuCsDawj7WF1MHTwFLw
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Nathan Barrett-Morrison <nathan.morrison@timesys.com>

This adds the ability to load ldr-formatted files to the SHARC
coprocessors using the rproc interface. Only a minimal subset
of rproc functionality is supported: loading and starting
the remote core.

Secure boot and signed ldr verification are not available
at this time through the U-Boot interface.

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Ian Roberts <ian.roberts@timesys.com>
Signed-off-by: Ian Roberts <ian.roberts@timesys.com>
Co-developed-by: Piotr Wojtaszczyk <piotr.wojtaszczyk@timesys.com>
Signed-off-by: Piotr Wojtaszczyk <piotr.wojtaszczyk@timesys.com>
Signed-off-by: Vasileios Bimpikas <vasileios.bimpikas@analog.com>
Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
Signed-off-by: Arturs Artamonovs <arturs.artamonovs@analog.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
---
 MAINTAINERS                          |   1 +
 drivers/remoteproc/Kconfig           |  11 ++
 drivers/remoteproc/Makefile          |   1 +
 drivers/remoteproc/adi_sc5xx_rproc.c | 276 +++++++++++++++++++++++++++++++++++
 4 files changed, 289 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 8a54dd4af4..ec0da58fe4 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -618,6 +618,7 @@ F:	drivers/gpio/gpio-adi-adsp.c
 F:	drivers/i2c/adi_i2c.c
 F:	drivers/net/dwc_eth_qos_adi.c
 F:	drivers/pinctrl/pinctrl-adi-adsp.c
+F:	drivers/remoteproc/adi_sc5xx_rproc.c
 F:	drivers/serial/serial_adi_uart4.c
 F:	drivers/timer/adi_sc5xx_timer.c
 F:	drivers/usb/musb-new/sc5xx.c
diff --git a/drivers/remoteproc/Kconfig b/drivers/remoteproc/Kconfig
index a49802c132..3f7cebaeb7 100644
--- a/drivers/remoteproc/Kconfig
+++ b/drivers/remoteproc/Kconfig
@@ -13,6 +13,7 @@ config REMOTEPROC
 	depends on DM
 
 # Please keep the configuration alphabetically sorted.
+
 config K3_SYSTEM_CONTROLLER
 	bool "Support for TI' K3 System Controller"
 	select REMOTEPROC
@@ -22,6 +23,16 @@ config K3_SYSTEM_CONTROLLER
 	help
 	  Say 'y' here to add support for TI' K3 System Controller.
 
+config REMOTEPROC_ADI_SC5XX
+	bool "Support for ADI SC5xx SHARC cores"
+	select REMOTEPROC
+	depends on DM
+	depends on ARCH_SC5XX
+	depends on SYSCON
+	help
+	  Say 'y' here to add support for loading code onto SHARC cores in
+	  an ADSP-SC5xx SoC from Analog Devices
+
 config REMOTEPROC_SANDBOX
 	bool "Support for Test processor for Sandbox"
 	select REMOTEPROC
diff --git a/drivers/remoteproc/Makefile b/drivers/remoteproc/Makefile
index e09ed1aa4d..c2aaf6f8c3 100644
--- a/drivers/remoteproc/Makefile
+++ b/drivers/remoteproc/Makefile
@@ -8,6 +8,7 @@ obj-$(CONFIG_$(SPL_)REMOTEPROC) += rproc-uclass.o rproc-elf-loader.o
 
 # Remote proc drivers - Please keep this list alphabetically sorted.
 obj-$(CONFIG_K3_SYSTEM_CONTROLLER) += k3_system_controller.o
+obj-$(CONFIG_REMOTEPROC_ADI_SC5XX) += adi_sc5xx_rproc.o
 obj-$(CONFIG_REMOTEPROC_SANDBOX) += sandbox_testproc.o
 obj-$(CONFIG_REMOTEPROC_STM32_COPRO) += stm32_copro.o
 obj-$(CONFIG_REMOTEPROC_TI_K3_ARM64) += ti_k3_arm64_rproc.o
diff --git a/drivers/remoteproc/adi_sc5xx_rproc.c b/drivers/remoteproc/adi_sc5xx_rproc.c
new file mode 100644
index 0000000000..fc9730ef32
--- /dev/null
+++ b/drivers/remoteproc/adi_sc5xx_rproc.c
@@ -0,0 +1,276 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2022 - Analog Devices, Inc.
+ *
+ * Written and/or maintained by Timesys Corporation
+ *
+ * Contact: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
+ * Contact: Greg Malysa <greg.malysa@timesys.com>
+ *
+ * Analog Devices SC5xx remoteproc driver for loading code onto SHARC cores
+ */
+
+#include <dm.h>
+#include <regmap.h>
+#include <remoteproc.h>
+#include <syscon.h>
+#include <dm/device_compat.h>
+#include <linux/delay.h>
+
+/* Register offsets */
+#ifdef CONFIG_SC58X
+#define ADI_RCU_REG_CTL		0x00
+#define ADI_RCU_REG_STAT	0x04
+#define ADI_RCU_REG_CRCTL	0x08
+#define ADI_RCU_REG_CRSTAT	0x0c
+#define ADI_RCU_REG_SIDIS	0x10
+#define ADI_RCU_REG_SISTAT	0x14
+#define ADI_RCU_REG_BCODE	0x1c
+#define ADI_RCU_REG_SVECT0	0x20
+#define ADI_RCU_REG_SVECT1	0x24
+#define ADI_RCU_REG_SVECT2	0x28
+#define ADI_RCU_REG_MSG		0x60
+#define ADI_RCU_REG_MSG_SET	0x64
+#define ADI_RCU_REG_MSG_CLR	0x68
+#else
+#define ADI_RCU_REG_CTL		0x00
+#define ADI_RCU_REG_STAT	0x04
+#define ADI_RCU_REG_CRCTL	0x08
+#define ADI_RCU_REG_CRSTAT	0x0c
+#define ADI_RCU_REG_SRRQSTAT	0x18
+#define ADI_RCU_REG_SIDIS	0x1c
+#define ADI_RCU_REG_SISTAT	0x20
+#define ADI_RCU_REG_SVECT_LCK	0x24
+#define ADI_RCU_REG_BCODE	0x28
+#define ADI_RCU_REG_SVECT0	0x2c
+#define ADI_RCU_REG_SVECT1	0x30
+#define ADI_RCU_REG_SVECT2	0x34
+#define ADI_RCU_REG_MSG		0x6c
+#define ADI_RCU_REG_MSG_SET	0x70
+#define ADI_RCU_REG_MSG_CLR	0x74
+#endif /* CONFIG_SC58X */
+
+/* Register bit definitions */
+#define ADI_RCU_CTL_SYSRST		BIT(0)
+
+/* Bit values for the RCU0_MSG register */
+#define RCU0_MSG_C0IDLE			0x00000100		/* Core 0 Idle */
+#define RCU0_MSG_C1IDLE			0x00000200		/* Core 1 Idle */
+#define RCU0_MSG_C2IDLE			0x00000400		/* Core 2 Idle */
+#define RCU0_MSG_CRR0			0x00001000		/* Core 0 reset request */
+#define RCU0_MSG_CRR1			0x00002000		/* Core 1 reset request */
+#define RCU0_MSG_CRR2			0x00004000		/* Core 2 reset request */
+#define RCU0_MSG_C1ACTIVATE		0x00080000		/* Core 1 Activated */
+#define RCU0_MSG_C2ACTIVATE		0x00100000		/* Core 2 Activated */
+
+struct sc5xx_rproc_data {
+	/* Address to load to svect when rebooting core */
+	u32 load_addr;
+
+	/* RCU parameters */
+	struct regmap *rcu;
+	u32 svect_offset;
+	u32 coreid;
+};
+
+struct block_code_flag {
+	u32 bcode:4,		/* 0-3 */
+	    bflag_save:1,	/* 4 */
+	    bflag_aux:1,	/* 5 */
+	    breserved:1,	/* 6 */
+	    bflag_forward:1,	/* 7 */
+	    bflag_fill:1,	/* 8 */
+	    bflag_quickboot:1,	/* 9 */
+	    bflag_callback:1,	/* 10 */
+	    bflag_init:1,	/* 11 */
+	    bflag_ignore:1,	/* 12 */
+	    bflag_indirect:1,	/* 13 */
+	    bflag_first:1,	/* 14 */
+	    bflag_final:1,	/* 15 */
+	    bhdrchk:8,		/* 16-23 */
+	    bhdrsign:8;		/* 0xAD, 0xAC or 0xAB */
+};
+
+struct ldr_hdr {
+	struct block_code_flag bcode_flag;
+	u32 target_addr;
+	u32 byte_count;
+	u32 argument;
+};
+
+static int is_final(struct ldr_hdr *hdr)
+{
+	return hdr->bcode_flag.bflag_final;
+}
+
+static int is_empty(struct ldr_hdr *hdr)
+{
+	return hdr->bcode_flag.bflag_ignore || (hdr->byte_count == 0);
+}
+
+static int adi_valid_firmware(struct ldr_hdr *adi_ldr_hdr)
+{
+	if (!adi_ldr_hdr->byte_count &&
+	    (adi_ldr_hdr->bcode_flag.bhdrsign == 0xAD ||
+	     adi_ldr_hdr->bcode_flag.bhdrsign == 0xAC ||
+	     adi_ldr_hdr->bcode_flag.bhdrsign == 0xAB))
+		return 1;
+
+	return 0;
+}
+
+static int sharc_load(struct udevice *dev, ulong addr, ulong size)
+{
+	struct sc5xx_rproc_data *priv = dev_get_priv(dev);
+	size_t offset;
+	u8 *buf = (u8 *)addr;
+	struct ldr_hdr *ldr = (struct ldr_hdr *)addr;
+	struct ldr_hdr *block_hdr;
+	struct ldr_hdr *next_hdr;
+
+	if (!adi_valid_firmware(ldr)) {
+		dev_err(dev, "Firmware at 0x%lx does not appear to be an LDR image\n", addr);
+		dev_err(dev, "Note: Signed firmware is not currently supported\n");
+		return -EINVAL;
+	}
+
+	do {
+		block_hdr = (struct ldr_hdr *)buf;
+		offset = sizeof(struct ldr_hdr) + (block_hdr->bcode_flag.bflag_fill ?
+							0 : block_hdr->byte_count);
+		next_hdr = (struct ldr_hdr *)(buf + offset);
+
+		if (block_hdr->bcode_flag.bflag_first)
+			priv->load_addr = (unsigned long)block_hdr->target_addr;
+
+		if (!is_empty(block_hdr)) {
+			if (block_hdr->bcode_flag.bflag_fill) {
+				memset((void *)(phys_addr_t)block_hdr->target_addr,
+				       block_hdr->argument,
+				       block_hdr->byte_count);
+			} else {
+				memcpy((void *)(phys_addr_t)block_hdr->target_addr,
+				       buf + sizeof(struct ldr_hdr),
+				       block_hdr->byte_count);
+			}
+		}
+
+		if (is_final(block_hdr))
+			break;
+
+		buf += offset;
+	} while (1);
+
+	return 0;
+}
+
+static void sharc_reset(struct sc5xx_rproc_data *priv)
+{
+	u32 coreid = priv->coreid;
+	u32 val;
+
+	/* First put core in reset.
+	 * Clear CRSTAT bit for given coreid.
+	 */
+	regmap_write(priv->rcu, ADI_RCU_REG_CRSTAT, 1 << coreid);
+
+	/* Set SIDIS to disable the system interface */
+	regmap_read(priv->rcu, ADI_RCU_REG_SIDIS, &val);
+	regmap_write(priv->rcu, ADI_RCU_REG_SIDIS, val | (1 << (coreid - 1)));
+
+	/*
+	 * Wait for access to coreX have been disabled and all the pending
+	 * transactions have completed
+	 */
+	udelay(50);
+
+	/* Set CRCTL bit to put core in reset */
+	regmap_read(priv->rcu, ADI_RCU_REG_CRCTL, &val);
+	regmap_write(priv->rcu, ADI_RCU_REG_CRCTL, val | (1 << coreid));
+
+	/* Poll until Core is in reset */
+	while (!(regmap_read(priv->rcu, ADI_RCU_REG_CRSTAT, &val), val & (1 << coreid)))
+		;
+
+	/* Clear SIDIS to reenable the system interface */
+	regmap_read(priv->rcu, ADI_RCU_REG_SIDIS, &val);
+	regmap_write(priv->rcu, ADI_RCU_REG_SIDIS, val & ~(1 << (coreid - 1)));
+
+	udelay(50);
+
+	/* Take Core out of reset */
+	regmap_read(priv->rcu, ADI_RCU_REG_CRCTL, &val);
+	regmap_write(priv->rcu, ADI_RCU_REG_CRCTL, val & ~(1 << coreid));
+
+	/* Wait for done */
+	udelay(50);
+}
+
+static int sharc_start(struct udevice *dev)
+{
+	struct sc5xx_rproc_data *priv = dev_get_priv(dev);
+
+	/* Write load address to appropriate SVECT for core */
+	regmap_write(priv->rcu, priv->svect_offset, priv->load_addr);
+
+	sharc_reset(priv);
+
+	/* Clear the IDLE bit when start the SHARC core */
+	regmap_write(priv->rcu, ADI_RCU_REG_MSG_CLR, RCU0_MSG_C0IDLE << priv->coreid);
+
+	/* Notify CCES */
+	regmap_write(priv->rcu, ADI_RCU_REG_MSG_SET, RCU0_MSG_C1ACTIVATE << (priv->coreid - 1));
+	return 0;
+}
+
+static const struct dm_rproc_ops sc5xx_ops = {
+	.load = sharc_load,
+	.start = sharc_start,
+};
+
+static int sc5xx_probe(struct udevice *dev)
+{
+	struct sc5xx_rproc_data *priv = dev_get_priv(dev);
+	u32 coreid;
+
+	if (dev_read_u32(dev, "coreid", &coreid)) {
+		dev_err(dev, "Missing property coreid\n");
+		return -ENOENT;
+	}
+
+	priv->coreid = coreid;
+	switch (coreid) {
+	case 1:
+		priv->svect_offset = ADI_RCU_REG_SVECT1;
+		break;
+	case 2:
+		priv->svect_offset = ADI_RCU_REG_SVECT2;
+		break;
+	default:
+		dev_err(dev, "Invalid value %d for coreid, must be 1 or 2\n", coreid);
+		return -EINVAL;
+	}
+
+	priv->rcu = syscon_regmap_lookup_by_phandle(dev, "adi,rcu");
+	if (IS_ERR(priv->rcu))
+		return PTR_ERR(priv->rcu);
+
+	dev_err(dev, "sc5xx remoteproc core %d available\n", priv->coreid);
+
+	return 0;
+}
+
+static const struct udevice_id sc5xx_ids[] = {
+	{ .compatible = "adi,sc5xx-rproc" },
+	{ }
+};
+
+U_BOOT_DRIVER(adi_sc5xx_rproc) = {
+	.name = "adi_sc5xx_rproc",
+	.of_match = sc5xx_ids,
+	.id = UCLASS_REMOTEPROC,
+	.ops = &sc5xx_ops,
+	.probe = sc5xx_probe,
+	.priv_auto = sizeof(struct sc5xx_rproc_data),
+	.flags = 0,
+};

-- 
2.34.1

