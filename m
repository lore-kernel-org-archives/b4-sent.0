From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Fri, 07 Mar 2025 21:09:00 +0100
Subject: [PATCH v2 2/3] spmi: add a spmi driver for Apple SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250307-spmi-v2-2-eccdb06afb99@gmail.com>
References: <20250307-spmi-v2-0-eccdb06afb99@gmail.com>
In-Reply-To: <20250307-spmi-v2-0-eccdb06afb99@gmail.com>
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Stephen Boyd <sboyd@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Jean-Francois Bortolotti <jeff@borto.fr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741378140; l=7125;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=ijXMaFCOmKcRdNz2Iu4Ta5HuPA6nUGhAm2fK832PyKc=;
 b=xy2/edX38GXnIw4DW8fIc0IaiRkHvkUzvB0TLB875jUkBWPFcSu8vKevksFyR57meRCse7SVH
 Y1+RMggGmzZAJCt3S5WdCfFF8L0bk190CoK6ho/RnHc5JWVU5U3Fdbk
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Jean-Francois Bortolotti <jeff@borto.fr>

The connected PMU contains several useful nvmem cells such as RTC offset,
boot failure counters, reboot/shutdown selector, and a few others.
In addition M3+ machines have their USB-PD controller connected via SPMI.

Signed-off-by: Jean-Francois Bortolotti <jeff@borto.fr>
Co-developed-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 MAINTAINERS                          |   1 +
 drivers/spmi/Kconfig                 |   8 ++
 drivers/spmi/Makefile                |   1 +
 drivers/spmi/spmi-apple-controller.c | 178 +++++++++++++++++++++++++++++++++++
 4 files changed, 188 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 271ff8110df83c2d4fe7fbbfffc0a72259460bc5..9006695261d29fbc1e15659c2b43d7afeee0b656 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2254,6 +2254,7 @@ F:	drivers/nvmem/apple-efuses.c
 F:	drivers/pinctrl/pinctrl-apple-gpio.c
 F:	drivers/pwm/pwm-apple.c
 F:	drivers/soc/apple/*
+F:	drivers/spmi/spmi-apple-controller.c
 F:	drivers/watchdog/apple_wdt.c
 F:	include/dt-bindings/interrupt-controller/apple-aic.h
 F:	include/dt-bindings/pinctrl/apple.h
diff --git a/drivers/spmi/Kconfig b/drivers/spmi/Kconfig
index 73780204631463631cabcbad5bf83e8dbbee94ce..9005fa91d9f4e541403ccc7bf84e0592402ac41e 100644
--- a/drivers/spmi/Kconfig
+++ b/drivers/spmi/Kconfig
@@ -11,6 +11,14 @@ menuconfig SPMI
 
 if SPMI
 
+config SPMI_APPLE
+	tristate "Apple SoC SPMI Controller platform driver"
+	depends on ARCH_APPLE || COMPILE_TEST
+	help
+	  If you say yes to this option, support will be included for the
+	  SPMI controller present on many Apple SoCs, including the
+	  t8103 (M1) and t600x (M1 Pro/Max).
+
 config SPMI_HISI3670
 	tristate "Hisilicon 3670 SPMI Controller"
 	select IRQ_DOMAIN_HIERARCHY
diff --git a/drivers/spmi/Makefile b/drivers/spmi/Makefile
index 7f152167bb05b2c24a0f9669f60278152898eebb..38ac635645ba65aa46cb5e8a50072ed9771e229b 100644
--- a/drivers/spmi/Makefile
+++ b/drivers/spmi/Makefile
@@ -4,6 +4,7 @@
 #
 obj-$(CONFIG_SPMI)	+= spmi.o spmi-devres.o
 
+obj-$(CONFIG_SPMI_APPLE)	+= spmi-apple-controller.o
 obj-$(CONFIG_SPMI_HISI3670)	+= hisi-spmi-controller.o
 obj-$(CONFIG_SPMI_MSM_PMIC_ARB)	+= spmi-pmic-arb.o
 obj-$(CONFIG_SPMI_MTK_PMIF)	+= spmi-mtk-pmif.o
diff --git a/drivers/spmi/spmi-apple-controller.c b/drivers/spmi/spmi-apple-controller.c
new file mode 100644
index 0000000000000000000000000000000000000000..2d4a677aaff6b10fce80f7eacc330605674ea495
--- /dev/null
+++ b/drivers/spmi/spmi-apple-controller.c
@@ -0,0 +1,178 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Apple SoC SPMI device driver
+ *
+ * Copyright The Asahi Linux Contributors
+ *
+ * Inspired by:
+ *		OpenBSD support Copyright (c) 2021 Mark Kettenis <kettenis@openbsd.org>
+ *		Correllium support Copyright (C) 2021 Corellium LLC
+ *		hisi-spmi-controller.c
+ *		spmi-pmic-arb.c Copyright (c) 2021, The Linux Foundation.
+ */
+
+#include <linux/io.h>
+#include <linux/iopoll.h>
+#include <linux/module.h>
+#include <linux/mod_devicetable.h>
+#include <linux/platform_device.h>
+#include <linux/spmi.h>
+
+/* SPMI Controller Registers */
+#define SPMI_STATUS_REG 0
+#define SPMI_CMD_REG 0x4
+#define SPMI_RSP_REG 0x8
+
+#define SPMI_RX_FIFO_EMPTY BIT(24)
+
+#define REG_POLL_INTERVAL 10000
+#define REG_POLL_TIMEOUT (REG_POLL_INTERVAL * 5)
+
+struct apple_spmi {
+	void __iomem *regs;
+};
+
+#define poll_reg(spmi, reg, val, cond) \
+	readl_poll_timeout((spmi)->regs + (reg), (val), (cond), \
+			   REG_POLL_INTERVAL, REG_POLL_TIMEOUT)
+
+static inline u32 read_reg(struct apple_spmi *spmi, int offset)
+{
+	return readl(spmi->regs + offset);
+}
+
+static inline void write_reg(u32 value, struct apple_spmi *spmi, int offset)
+{
+	writel(value, spmi->regs + offset);
+}
+
+static inline u32 apple_spmi_pack_cmd(u8 opc, u8 sid, u16 saddr, size_t len)
+{
+	return opc | sid << 8 | saddr << 16 | (len - 1) | (1 << 15);
+}
+
+/* Wait for Rx FIFO to have something */
+static int apple_spmi_wait_rx_not_empty(struct spmi_controller *ctrl)
+{
+	struct apple_spmi *spmi = spmi_controller_get_drvdata(ctrl);
+	int ret;
+	u32 status;
+
+	ret = poll_reg(spmi, SPMI_STATUS_REG, status, !(status & SPMI_RX_FIFO_EMPTY));
+	if (ret) {
+		dev_err(&ctrl->dev,
+			"%s: Failed to wait for RX FIFO not empty\n", __func__);
+		return ret;
+	}
+
+	return 0;
+}
+
+static int spmi_read_cmd(struct spmi_controller *ctrl, u8 opc, u8 sid,
+			 u16 saddr, u8 *buf, size_t len)
+{
+	struct apple_spmi *spmi = spmi_controller_get_drvdata(ctrl);
+	u32 spmi_cmd = apple_spmi_pack_cmd(opc, sid, saddr, len);
+	u32 rsp;
+	size_t len_read = 0;
+	u8 i;
+	int ret;
+
+	write_reg(spmi_cmd, spmi, SPMI_CMD_REG);
+
+	ret = apple_spmi_wait_rx_not_empty(ctrl);
+	if (ret)
+		return ret;
+
+	/* Discard SPMI reply status */
+	read_reg(spmi, SPMI_RSP_REG);
+
+	/* Read SPMI data reply */
+	while (len_read < len) {
+		rsp = read_reg(spmi, SPMI_RSP_REG);
+		i = 0;
+		while ((len_read < len) && (i < 4)) {
+			buf[len_read++] = ((0xff << (8 * i)) & rsp) >> (8 * i);
+			i += 1;
+		}
+	}
+
+	return 0;
+}
+
+static int spmi_write_cmd(struct spmi_controller *ctrl, u8 opc, u8 sid,
+			  u16 saddr, const u8 *buf, size_t len)
+{
+	struct apple_spmi *spmi = spmi_controller_get_drvdata(ctrl);
+	u32 spmi_cmd = apple_spmi_pack_cmd(opc, sid, saddr, len);
+	size_t i = 0, j;
+	int ret;
+
+	write_reg(spmi_cmd, spmi, SPMI_CMD_REG);
+
+	while (i < len) {
+		j = 0;
+		spmi_cmd = 0;
+		while ((j < 4) & (i < len))
+			spmi_cmd |= buf[i++] << (j++ * 8);
+
+		write_reg(spmi_cmd, spmi, SPMI_CMD_REG);
+	}
+
+	ret = apple_spmi_wait_rx_not_empty(ctrl);
+	if (ret)
+		return ret;
+
+	/* Discard */
+	read_reg(spmi, SPMI_RSP_REG);
+
+	return 0;
+}
+
+static int apple_spmi_probe(struct platform_device *pdev)
+{
+	struct apple_spmi *spmi;
+	struct spmi_controller *ctrl;
+	int ret;
+
+	ctrl = devm_spmi_controller_alloc(&pdev->dev, sizeof(*spmi));
+	if (IS_ERR(ctrl))
+		return -ENOMEM;
+
+	spmi = spmi_controller_get_drvdata(ctrl);
+
+	spmi->regs = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(spmi->regs))
+		return PTR_ERR(spmi->regs);
+
+	ctrl->dev.of_node = pdev->dev.of_node;
+
+	ctrl->read_cmd = spmi_read_cmd;
+	ctrl->write_cmd = spmi_write_cmd;
+
+	ret = devm_spmi_controller_add(&pdev->dev, ctrl);
+	if (ret)
+		return dev_err_probe(&pdev->dev, ret,
+				     "spmi_controller_add failed\n");
+
+	return 0;
+}
+
+static const struct of_device_id apple_spmi_match_table[] = {
+	{ .compatible = "apple,spmi", },
+	{}
+};
+MODULE_DEVICE_TABLE(of, apple_spmi_match_table);
+
+static struct platform_driver apple_spmi_driver = {
+	.probe		= apple_spmi_probe,
+	.driver		= {
+		.name	= "apple-spmi",
+		.of_match_table = apple_spmi_match_table,
+	},
+};
+module_platform_driver(apple_spmi_driver);
+
+MODULE_AUTHOR("Jean-Francois Bortolotti <jeff@borto.fr>");
+MODULE_DESCRIPTION("Apple SoC SPMI driver");
+MODULE_LICENSE("GPL");

-- 
2.48.1

