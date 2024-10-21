From: Vasileios Bimpikas <vasileios.bimpikas@analog.com>
Date: Mon, 21 Oct 2024 14:54:37 +0100
Subject: [PATCH v2 06/11] net: Add support for ADI SC5xx SoCs with DWC QoS
 ethernet
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241021-sc5xx-driver-series-v2-6-53e2472e11d0@analog.com>
References: <20241021-sc5xx-driver-series-v2-0-53e2472e11d0@analog.com>
In-Reply-To: <20241021-sc5xx-driver-series-v2-0-53e2472e11d0@analog.com>
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
 Oliver Gaskell <Oliver.Gaskell@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729518874; l=7494;
 i=vasileios.bimpikas@analog.com; s=20240927; h=from:subject:message-id;
 bh=Qp1qK+NFQeNhvdxSNvkPPhgA7jxxwlhrb5vsawxnBog=;
 b=4lindLCer7bXjBUZbmlR20YQtRXr6nnSAYz4QBv7v3WOzwVpLhuNynADrXb06El7iGs/aHyW9
 C5UBB3sNSwJCr9dRjBDPjxGDlIP7GpoA+RUFMlpzTMruxfC2Boy2ATj
X-Developer-Key: i=vasileios.bimpikas@analog.com; a=ed25519;
 pk=JkXh+NeXYCpTenwrB0gg5fMpKEnagLOXdsLFiUrqZRo=
X-Endpoint-Received: by B4 Relay for vasileios.bimpikas@analog.com/20240927 with auth_id=220
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Greg Malysa <greg.malysa@timesys.com>

The ADI SC598 includes a Designware QoS 5.20a IP block. This
commit adds support for using the existing ethernet QoS driver
with the SC598 SoC.

Co-developed-by: Ian Roberts <ian.roberts@timesys.com>
Signed-off-by: Ian Roberts <ian.roberts@timesys.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Vasileios Bimpikas <vasileios.bimpikas@analog.com>
Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
Signed-off-by: Arturs Artamonovs <arturs.artamonovs@analog.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
---
 MAINTAINERS                   |   1 +
 drivers/net/Kconfig           |   7 +++
 drivers/net/Makefile          |   1 +
 drivers/net/dwc_eth_qos.c     |   6 +++
 drivers/net/dwc_eth_qos.h     |   2 +
 drivers/net/dwc_eth_qos_adi.c | 102 ++++++++++++++++++++++++++++++++++++++++++
 6 files changed, 119 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index ee41f28914100ac86402af9a10b238edd24916e4..b853eec4d961abcd33fe722f3a7f49bf2f24ee29 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -615,6 +615,7 @@ F:	drivers/clk/adi/
 F:	drivers/gpio/adp5588_gpio.c
 F:	drivers/gpio/gpio-adi-adsp.c
 F:	drivers/i2c/adi_i2c.c
+F:	drivers/net/dwc_eth_qos_adi.c
 F:	drivers/pinctrl/pinctrl-adi-adsp.c
 F:	drivers/serial/serial_adi_uart4.c
 F:	drivers/timer/adi_sc5xx_timer.c
diff --git a/drivers/net/Kconfig b/drivers/net/Kconfig
index 89f7411bdf336d64f8cddadc3f8c077f48481455..6d6060fe48848b6633b2e5c30e87f787559f0692 100644
--- a/drivers/net/Kconfig
+++ b/drivers/net/Kconfig
@@ -237,6 +237,13 @@ config DWC_ETH_QOS
 	  Of Service) IP block. The IP supports many options for bus type,
 	  clocking/reset structure, and feature list.
 
+config DWC_ETH_QOS_ADI
+	bool "Synopsys DWC Ethernet QOS device support for ADI SC59x-64 parts"
+	depends on DWC_ETH_QOS
+	help
+		The Synopsis Designware Ethernet QoS IP block with the specific
+		configuration used in the ADI ADSP-SC59X 64 bit SoCs
+
 config DWC_ETH_QOS_IMX
 	bool "Synopsys DWC Ethernet QOS device support for IMX"
 	depends on DWC_ETH_QOS
diff --git a/drivers/net/Makefile b/drivers/net/Makefile
index f5ab1f5dedf6b867583b841695dd43bb6fc4db6e..5d2b97db9884ee9ce356719de7ea1ffcd7b55cc7 100644
--- a/drivers/net/Makefile
+++ b/drivers/net/Makefile
@@ -19,6 +19,7 @@ obj-$(CONFIG_DM_ETH_PHY) += eth-phy-uclass.o
 obj-$(CONFIG_DRIVER_DM9000) += dm9000x.o
 obj-$(CONFIG_DSA_SANDBOX) += dsa_sandbox.o
 obj-$(CONFIG_DWC_ETH_QOS) += dwc_eth_qos.o
+obj-$(CONFIG_DWC_ETH_QOS_ADI) += dwc_eth_qos_adi.o
 obj-$(CONFIG_DWC_ETH_QOS_IMX) += dwc_eth_qos_imx.o
 obj-$(CONFIG_DWC_ETH_QOS_INTEL) += dwc_eth_qos_intel.o
 obj-$(CONFIG_DWC_ETH_QOS_ROCKCHIP) += dwc_eth_qos_rockchip.o
diff --git a/drivers/net/dwc_eth_qos.c b/drivers/net/dwc_eth_qos.c
index 3415c418a93576396f2090849868a66c75b5747f..d163f566255a536a7805617e8824e892335e56be 100644
--- a/drivers/net/dwc_eth_qos.c
+++ b/drivers/net/dwc_eth_qos.c
@@ -1632,6 +1632,12 @@ static const struct udevice_id eqos_ids[] = {
 		.compatible = "starfive,jh7110-dwmac",
 		.data = (ulong)&eqos_jh7110_config
 	},
+#endif
+#if IS_ENABLED(CONFIG_DWC_ETH_QOS_ADI)
+	{
+		.compatible = "adi,sc59x-dwmac-eqos",
+		.data = (ulong)&eqos_adi_config
+	},
 #endif
 	{ }
 };
diff --git a/drivers/net/dwc_eth_qos.h b/drivers/net/dwc_eth_qos.h
index ce57e22a81f14c46461faa1994a08ed74c940138..0eb9f2f36cacbde7f61260ebc8a421ae6239a7ce 100644
--- a/drivers/net/dwc_eth_qos.h
+++ b/drivers/net/dwc_eth_qos.h
@@ -87,6 +87,7 @@ struct eqos_mac_regs {
 #define EQOS_MAC_MDIO_ADDRESS_CR_MASK			GENMASK(11, 8)
 #define EQOS_MAC_MDIO_ADDRESS_CR_100_150		1
 #define EQOS_MAC_MDIO_ADDRESS_CR_20_35			2
+#define EQOS_MAC_MDIO_ADDRESS_CR_150_250		4
 #define EQOS_MAC_MDIO_ADDRESS_CR_250_300		5
 #define EQOS_MAC_MDIO_ADDRESS_SKAP			BIT(4)
 #define EQOS_MAC_MDIO_ADDRESS_GOC_MASK			GENMASK(3, 2)
@@ -300,3 +301,4 @@ extern struct eqos_config eqos_qcom_config;
 extern struct eqos_config eqos_stm32mp13_config;
 extern struct eqos_config eqos_stm32mp15_config;
 extern struct eqos_config eqos_jh7110_config;
+extern struct eqos_config eqos_adi_config;
diff --git a/drivers/net/dwc_eth_qos_adi.c b/drivers/net/dwc_eth_qos_adi.c
new file mode 100644
index 0000000000000000000000000000000000000000..373e7c25051ccf4af9f5bf0566ca322b796193a7
--- /dev/null
+++ b/drivers/net/dwc_eth_qos_adi.c
@@ -0,0 +1,102 @@
+// SPDX-License-Identifier: GPL-2.0
+/**
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ *
+ * Written and/or maintained by Timesys Corporation
+ *
+ * Author: Greg Malysa <greg.malysa@timesys.com>
+ * Additional Contact: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
+ */
+
+#include <clk.h>
+#include <dm.h>
+#include <net.h>
+#include <phy.h>
+#include <reset.h>
+#include <asm/io.h>
+
+#include <asm/arch-adi/sc5xx/sc5xx.h>
+
+#include "dwc_eth_qos.h"
+
+static int eqos_start_resets_adi(struct udevice *dev)
+{
+	struct eqos_priv *eqos = dev_get_priv(dev);
+	u32 val;
+
+	/*
+	 * Settings need to latch with the DMA reset below. Currently only
+	 * rgmii is supported but other phy interfaces may be supported in
+	 * the future
+	 */
+	sc5xx_enable_rgmii();
+
+	val = readl(&eqos->dma_regs->mode);
+	val |= EQOS_DMA_MODE_SWR;
+	writel(val, &eqos->dma_regs->mode);
+
+	return 0;
+}
+
+static int eqos_probe_resources_adi(struct udevice *dev)
+{
+	struct eqos_priv *eqos = dev_get_priv(dev);
+	phy_interface_t interface;
+
+	interface = eqos->config->interface(dev);
+	if (interface == PHY_INTERFACE_MODE_NA) {
+		pr_err("Invalid PHY interface\n");
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+/**
+ * rgmii tx clock rate is set to 125 MHz regardless of phy mode, and
+ * by default the internal clock is always connected to 125 MHz. According
+ * to the HRM it is invalid for this clock to have any other speed, so
+ * the hardware won't work anyway if this is wrong.
+ */
+static ulong eqos_get_tick_clk_rate_adi(struct udevice *dev)
+{
+	return 125 * 1000000;
+}
+
+static int eqos_get_enetaddr_adi(struct udevice *dev)
+{
+	struct eth_pdata *pdata = dev_get_plat(dev);
+
+	return eth_env_get_enetaddr("ethaddr", pdata->enetaddr);
+}
+
+static struct eqos_ops eqos_adi_ops = {
+	.eqos_inval_desc = eqos_inval_desc_generic,
+	.eqos_flush_desc = eqos_flush_desc_generic,
+	.eqos_inval_buffer = eqos_inval_buffer_generic,
+	.eqos_flush_buffer = eqos_flush_buffer_generic,
+	.eqos_probe_resources = eqos_probe_resources_adi,
+	.eqos_remove_resources = eqos_null_ops,
+	.eqos_start_resets = eqos_start_resets_adi,
+	.eqos_stop_resets = eqos_null_ops,
+	.eqos_start_clks = eqos_null_ops,
+	.eqos_stop_clks = eqos_null_ops,
+	.eqos_calibrate_pads = eqos_null_ops,
+	.eqos_disable_calibration = eqos_null_ops,
+	.eqos_set_tx_clk_speed = eqos_null_ops,
+	.eqos_get_enetaddr = eqos_get_enetaddr_adi,
+	.eqos_get_tick_clk_rate = eqos_get_tick_clk_rate_adi,
+};
+
+// @todo read mdio_wait from device tree
+// @todo read swr_wait from device tree
+struct eqos_config __maybe_unused eqos_adi_config = {
+	.reg_access_always_ok = true,
+	.mdio_wait =  20,
+	.swr_wait = 50,
+	.config_mac = EQOS_MAC_RXQ_CTRL0_RXQ0EN_ENABLED_DCB,
+	.config_mac_mdio = EQOS_MAC_MDIO_ADDRESS_CR_150_250,
+	.axi_bus_width = EQOS_AXI_WIDTH_32,
+	.interface = dev_read_phy_mode,
+	.ops = &eqos_adi_ops,
+};

-- 
2.34.1

