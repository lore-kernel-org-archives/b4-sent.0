From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 25 Sep 2024 13:25:17 +0100
Subject: [PATCH v2 07/11] watchdog: Add support for ADI SC5XX-family
 watchdog peripheral
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240925-sc5xx-driver-series-v2-7-ad9287c25c08@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727267113; l=6077;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=5aimifPFebHsCoxuExhYmfYUuiNXyJ1OL02UoESBDso=;
 b=xIbwkHK6+/Er5oYPaHqrFEyvKMsSmVo2AEXksTLYmxMyX+gFXeQWJ/xcb0xesmrgKqbYf2SOv
 b9sGrUh3h7oA5JCbRdB6T4FEpQ9T9jJEdfaGIFkCzsMzFzsgJdhac2G
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
 MAINTAINERS                |   1 +
 drivers/watchdog/Kconfig   |   9 +++
 drivers/watchdog/Makefile  |   1 +
 drivers/watchdog/adi_wdt.c | 145 +++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 156 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 2eb3c79cc0..cbfcc97871 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -620,6 +620,7 @@ F:	drivers/pinctrl/pinctrl-adi-adsp.c
 F:	drivers/serial/serial_adi_uart4.c
 F:	drivers/timer/adi_sc5xx_timer.c
 F:	drivers/usb/musb-new/sc5xx.c
+F:	drivers/watchdog/adi_wdt.c
 F:	include/configs/sc5*
 F:	include/env/adi/
 
diff --git a/drivers/watchdog/Kconfig b/drivers/watchdog/Kconfig
index 0c3e991331..4601a6f3b1 100644
--- a/drivers/watchdog/Kconfig
+++ b/drivers/watchdog/Kconfig
@@ -95,6 +95,15 @@ config WDT_APPLE
 	  The watchdog will perform a full SoC reset resulting in a
 	  reboot of the entire system.
 
+config WDT_ADI
+	bool "Analog Devices watchdog timer support"
+	select WDT
+	select SPL_WDT if SPL
+	depends on ARCH_SC5XX
+	help
+	  Enable this to support Watchdog Timer on ADI SC57X, SC58X, SC59X,
+	  and SC59X_64 processors
+
 config WDT_ARMADA_37XX
 	bool "Marvell Armada 37xx watchdog timer support"
 	depends on WDT && ARMADA_3700
diff --git a/drivers/watchdog/Makefile b/drivers/watchdog/Makefile
index 7b39adcf0f..7ad61b513c 100644
--- a/drivers/watchdog/Makefile
+++ b/drivers/watchdog/Makefile
@@ -50,3 +50,4 @@ obj-$(CONFIG_WDT_STM32MP) += stm32mp_wdt.o
 obj-$(CONFIG_WDT_SUNXI) += sunxi_wdt.o
 obj-$(CONFIG_WDT_TANGIER) += tangier_wdt.o
 obj-$(CONFIG_WDT_XILINX) += xilinx_wwdt.o
+obj-$(CONFIG_WDT_ADI) += adi_wdt.o
diff --git a/drivers/watchdog/adi_wdt.c b/drivers/watchdog/adi_wdt.c
new file mode 100644
index 0000000000..67d17dc692
--- /dev/null
+++ b/drivers/watchdog/adi_wdt.c
@@ -0,0 +1,145 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2022 - Analog Devices, Inc.
+ *
+ * Written and/or maintained by Timesys Corporation
+ *
+ * Converted to driver model by Nathan Barrett-Morrison
+ *
+ * Contact: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
+ * Contact: Greg Malysa <greg.malysa@timesys.com>
+ *
+ * adi_wtd.c - driver for ADI on-chip watchdog
+ *
+ */
+
+#include <clk.h>
+#include <dm.h>
+#include <wdt.h>
+#include <linux/delay.h>
+#include <linux/ioport.h>
+#include <linux/io.h>
+
+#define WDOG_CTL  0x0
+#define WDOG_CNT  0x4
+#define WDOG_STAT 0x8
+
+#define RCU_CTL   0x0
+#define RCU_STAT  0x4
+
+#define SEC_GCTL  0x0
+#define SEC_FCTL  0x10
+#define SEC_SCTL0 0x800
+
+#define WDEN      0x0010
+#define WDDIS     0x0AD0
+
+struct adi_wdt_priv {
+	void __iomem *rcu_base;
+	void __iomem *sec_base;
+	void __iomem *wdt_base;
+	struct clk clock;
+};
+
+static int adi_wdt_reset(struct udevice *dev)
+{
+	struct adi_wdt_priv *priv = dev_get_priv(dev);
+
+	writel(0, priv->wdt_base + WDOG_STAT);
+
+	return 0;
+}
+
+static int adi_wdt_start(struct udevice *dev, u64 timeout_ms, ulong flags)
+{
+	struct adi_wdt_priv *priv = dev_get_priv(dev);
+	u32 sctl_val;
+
+	/* Disable SYSCD_RESETb input and clear the RCU0 reset status */
+	writel(0xf, priv->rcu_base + RCU_STAT);
+	writel(0x0, priv->rcu_base + RCU_CTL);
+
+	/* reset the SEC controller */
+	writel(0x2, priv->sec_base + SEC_GCTL);
+	writel(0x2, priv->sec_base + SEC_FCTL);
+
+	udelay(50);
+
+	/* enable SEC fault event */
+	writel(0x1, priv->sec_base + SEC_GCTL);
+
+	/* ANOMALY 36100004 Spurious External Fault event occurs when FCTL
+	 * is re-programmed when currently active fault is not cleared
+	 */
+	writel(0xc0, priv->sec_base + SEC_FCTL);
+	writel(0xc1, priv->sec_base + SEC_FCTL);
+
+	/* enable SEC fault source for watchdog0 */
+	sctl_val = readl((priv->sec_base + SEC_SCTL0) + 3 * 8) | 0x6;
+	writel(sctl_val, (priv->sec_base + SEC_SCTL0) + 3 * 8);
+
+	/* Enable SYSCD_RESETb input */
+	writel(0x100, priv->rcu_base + RCU_CTL);
+
+	/* enable watchdog0 */
+	writel(WDDIS, priv->wdt_base + WDOG_CTL);
+
+	writel(timeout_ms / 1000 *
+	       (clk_get_rate(&priv->clock) / (IS_ENABLED(CONFIG_SC58X) ? 2 : 1)),
+	       priv->wdt_base + WDOG_CNT);
+
+	writel(0, priv->wdt_base + WDOG_STAT);
+	writel(WDEN, priv->wdt_base + WDOG_CTL);
+
+	return 0;
+}
+
+static int adi_wdt_probe(struct udevice *dev)
+{
+	struct adi_wdt_priv *priv = dev_get_priv(dev);
+	int ret;
+	struct resource res;
+
+	ret = dev_read_resource_byname(dev, "rcu", &res);
+	if (ret)
+		return ret;
+	priv->rcu_base = devm_ioremap(dev, res.start, resource_size(&res));
+
+	ret = dev_read_resource_byname(dev, "sec", &res);
+	if (ret)
+		return ret;
+	priv->sec_base = devm_ioremap(dev, res.start, resource_size(&res));
+
+	ret = dev_read_resource_byname(dev, "wdt", &res);
+	if (ret)
+		return ret;
+	priv->wdt_base = devm_ioremap(dev, res.start, resource_size(&res));
+
+	ret = clk_get_by_name(dev, "sclk0", &priv->clock);
+	if (ret < 0) {
+		printf("Can't get WDT clk: %d\n", ret);
+		return ret;
+	}
+
+	return 0;
+}
+
+static const struct wdt_ops adi_wdt_ops = {
+	.start		= adi_wdt_start,
+	.reset		= adi_wdt_reset,
+};
+
+static const struct udevice_id adi_wdt_ids[] = {
+	{ .compatible = "adi,wdt" },
+	{}
+};
+
+U_BOOT_DRIVER(adi_wdt) = {
+	.name		= "adi_wdt",
+	.id		= UCLASS_WDT,
+	.of_match	= adi_wdt_ids,
+	.probe		= adi_wdt_probe,
+	.ops		= &adi_wdt_ops,
+	.priv_auto = sizeof(struct adi_wdt_priv),
+	.flags		= DM_FLAG_PRE_RELOC,
+};

-- 
2.34.1

