From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:43 +1000
Subject: [PATCH RESEND 02/16] timer: Qualcomm KPSS timer support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-2-05a08d87e476@samcday.com>
References: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
In-Reply-To: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=4404;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=fkCXHf02iVs19zps8lhn7zcn6c95chvxbrw76ilJgQ8=;
 b=iTCrwpnjLQ9Q69cfwgd3hhty5KPUofuxpiFBdiTcwHrqFM+W8E7meyPtTiHGnlUAeY9+gAPFZ
 3Shrdp0qXayA72xBxexOJV7Mw0CuLdIWKCqScjF0TrtjcYQ2r16cnwI
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SoCs like MSM8960 and APQ8064 do not support the generic ARM CP15 timer.
Instead KPSS must be used as a timer source.

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/timer/Kconfig           |  7 +++
 drivers/timer/Makefile          |  1 +
 drivers/timer/qcom-kpss-timer.c | 98 +++++++++++++++++++++++++++++++++++++++++
 3 files changed, 106 insertions(+)

diff --git a/drivers/timer/Kconfig b/drivers/timer/Kconfig
index 500a25638a9..8de8ce6c14a 100644
--- a/drivers/timer/Kconfig
+++ b/drivers/timer/Kconfig
@@ -223,6 +223,13 @@ config ORION_TIMER
 	  Select this to enable an timer for Orion and Armada devices
 	  like Armada XP etc.
 
+config QCOM_KPSS_TIMER
+	bool "Qualcomm KPSS/SCSS timer support"
+	depends on TIMER && ARM
+	help
+	  Select this to enable the Qualcomm KPSS/SCSS digital general
+	  purpose timer used on older 32-bit Snapdragon SoCs.
+
 config RISCV_TIMER
 	bool "RISC-V timer support"
 	depends on TIMER && RISCV
diff --git a/drivers/timer/Makefile b/drivers/timer/Makefile
index d8b3f2b65d4..3bd167d73c2 100644
--- a/drivers/timer/Makefile
+++ b/drivers/timer/Makefile
@@ -21,6 +21,7 @@ obj-$(CONFIG_NOMADIK_MTU_TIMER)	+= nomadik-mtu-timer.o
 obj-$(CONFIG_NPCM_TIMER)        += npcm-timer.o
 obj-$(CONFIG_OMAP_TIMER)	+= omap-timer.o
 obj-$(CONFIG_ORION_TIMER)	+= orion-timer.o
+obj-$(CONFIG_QCOM_KPSS_TIMER)	+= qcom-kpss-timer.o
 obj-$(CONFIG_RENESAS_OSTM_TIMER) += ostm_timer.o
 obj-$(CONFIG_RISCV_TIMER) += riscv_timer.o
 obj-$(CONFIG_ROCKCHIP_TIMER) += rockchip_timer.o
diff --git a/drivers/timer/qcom-kpss-timer.c b/drivers/timer/qcom-kpss-timer.c
new file mode 100644
index 00000000000..543fb2fa44f
--- /dev/null
+++ b/drivers/timer/qcom-kpss-timer.c
@@ -0,0 +1,98 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Qualcomm KPSS/SCSS timer driver
+ * Adapted from Linux drivers/clocksource/timer-qcom.c
+ *
+ * Copyright (C) 2007 Google, Inc.
+ * Copyright (c) 2009-2012,2014, The Linux Foundation. All rights reserved.
+ */
+
+#include <dm.h>
+#include <div64.h>
+#include <errno.h>
+#include <timer.h>
+#include <asm/global_data.h>
+#include <asm/io.h>
+#include <linux/bitops.h>
+
+DECLARE_GLOBAL_DATA_PTR;
+
+#define TIMER_COUNT_VAL   0x04
+#define TIMER_ENABLE      0x08
+#define TIMER_ENABLE_EN   BIT(0)
+#define DGT_CLK_CTL       0x10
+#define DGT_CLK_CTL_DIV_4 0x3
+
+#define QCOM_TIMER_DGT_OFFSET   0x24
+#define QCOM_TIMER_DGT_RATE_DIV 4
+
+struct qcom_kpss_timer_priv {
+	void __iomem *source_base;
+	void __iomem *counter;
+};
+
+static u64 notrace qcom_kpss_timer_get_count(struct udevice *dev)
+{
+	struct qcom_kpss_timer_priv *priv = dev_get_priv(dev);
+
+	return timer_conv_64(readl(priv->counter));
+}
+
+static int qcom_kpss_timer_probe(struct udevice *dev)
+{
+	struct timer_dev_priv *uc_priv = dev_get_uclass_priv(dev);
+	struct qcom_kpss_timer_priv *priv = dev_get_priv(dev);
+	u32 rate;
+	int ret;
+
+	ret = dev_read_u32(dev, "clock-frequency", &rate);
+	if (ret)
+		return ret;
+
+	uc_priv->clock_rate = rate / QCOM_TIMER_DGT_RATE_DIV;
+
+	writel(DGT_CLK_CTL_DIV_4, priv->source_base + DGT_CLK_CTL);
+	writel(TIMER_ENABLE_EN, priv->source_base + TIMER_ENABLE);
+
+	return 0;
+}
+
+static int qcom_kpss_timer_of_to_plat(struct udevice *dev)
+{
+	struct qcom_kpss_timer_priv *priv = dev_get_priv(dev);
+	phys_addr_t base;
+	phys_addr_t source_base;
+	u32 cpu_offset;
+
+	base = dev_read_addr(dev);
+	if (base == FDT_ADDR_T_NONE)
+		return -EINVAL;
+
+	cpu_offset = dev_read_u32_default(dev, "cpu-offset", 0);
+	source_base = base + cpu_offset + QCOM_TIMER_DGT_OFFSET;
+	priv->source_base = map_physmem(source_base, 0x100, MAP_NOCACHE);
+	priv->counter = priv->source_base + TIMER_COUNT_VAL;
+
+	return 0;
+}
+
+static const struct timer_ops qcom_kpss_timer_ops = {
+	.get_count = qcom_kpss_timer_get_count,
+};
+
+static const struct udevice_id qcom_kpss_timer_ids[] = {
+	{ .compatible = "qcom,kpss-timer" },
+	{ .compatible = "qcom,scss-timer" },
+	{ }
+};
+
+U_BOOT_DRIVER(qcom_kpss_timer) = {
+	.name		= "qcom_kpss_timer",
+	.id		= UCLASS_TIMER,
+	.of_match	= qcom_kpss_timer_ids,
+	.of_to_plat	= qcom_kpss_timer_of_to_plat,
+	.probe		= qcom_kpss_timer_probe,
+	.ops		= &qcom_kpss_timer_ops,
+	.priv_auto	= sizeof(struct qcom_kpss_timer_priv),
+	.flags		= DM_FLAG_PRE_RELOC,
+};

-- 
2.54.0

