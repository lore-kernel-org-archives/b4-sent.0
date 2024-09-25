From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 25 Sep 2024 13:25:16 +0100
Subject: [PATCH v2 06/11] net: Add support for ADI SC5xx SoCs with DWC QoS
 ethernet
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240925-sc5xx-driver-series-v2-6-ad9287c25c08@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727267113; l=7132;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=GyHP3JEspLCCCa0em6eaaDnWw7RPwKOUsI2lEJ44MGU=;
 b=uQYJoHhSugUo3jhytZRuzizZCJa+4hBnxAr946j4L9CaJWndmOWOJ0zB2etyEjoWfpNZ9Kwil
 r4WMVpdM4iuA1FwXoHcn+cGg1bxEg1yWtvYIQ6E7oAEZ5gP+TrOLxGd
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
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
index 101c0d6ed3..2eb3c79cc0 100644
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
index 69ae7c0750..7a69433ad4 100644
--- a/drivers/net/Kconfig
+++ b/drivers/net/Kconfig
@@ -236,6 +236,13 @@ config DWC_ETH_QOS
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
index 425dd721f9..b297dff9ca 100644
--- a/drivers/net/Makefile
+++ b/drivers/net/Makefile
@@ -19,6 +19,7 @@ obj-$(CONFIG_DM_ETH_PHY) += eth-phy-uclass.o
 obj-$(CONFIG_DRIVER_DM9000) += dm9000x.o
 obj-$(CONFIG_DSA_SANDBOX) += dsa_sandbox.o
 obj-$(CONFIG_DWC_ETH_QOS) += dwc_eth_qos.o
+obj-$(CONFIG_DWC_ETH_QOS_ADI) += dwc_eth_qos_adi.o
 obj-$(CONFIG_DWC_ETH_QOS_IMX) += dwc_eth_qos_imx.o
 obj-$(CONFIG_DWC_ETH_QOS_ROCKCHIP) += dwc_eth_qos_rockchip.o
 obj-$(CONFIG_DWC_ETH_QOS_QCOM) += dwc_eth_qos_qcom.o
diff --git a/drivers/net/dwc_eth_qos.c b/drivers/net/dwc_eth_qos.c
index 43f0ec7637..0d9da40bb2 100644
--- a/drivers/net/dwc_eth_qos.c
+++ b/drivers/net/dwc_eth_qos.c
@@ -1566,6 +1566,12 @@ static const struct udevice_id eqos_ids[] = {
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
index a06390a698..b9c6791964 100644
--- a/drivers/net/dwc_eth_qos.h
+++ b/drivers/net/dwc_eth_qos.h
@@ -84,6 +84,7 @@ struct eqos_mac_regs {
 #define EQOS_MAC_MDIO_ADDRESS_CR_MASK			GENMASK(11, 8)
 #define EQOS_MAC_MDIO_ADDRESS_CR_100_150		1
 #define EQOS_MAC_MDIO_ADDRESS_CR_20_35			2
+#define EQOS_MAC_MDIO_ADDRESS_CR_150_250		4
 #define EQOS_MAC_MDIO_ADDRESS_CR_250_300		5
 #define EQOS_MAC_MDIO_ADDRESS_SKAP			BIT(4)
 #define EQOS_MAC_MDIO_ADDRESS_GOC_MASK			GENMASK(3, 2)
@@ -294,3 +295,4 @@ extern struct eqos_config eqos_qcom_config;
 extern struct eqos_config eqos_stm32mp13_config;
 extern struct eqos_config eqos_stm32mp15_config;
 extern struct eqos_config eqos_jh7110_config;
+extern struct eqos_config eqos_adi_config;
diff --git a/drivers/net/dwc_eth_qos_adi.c b/drivers/net/dwc_eth_qos_adi.c
new file mode 100644
index 0000000000..373e7c2505
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

