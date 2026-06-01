From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:54 +1000
Subject: [PATCH RESEND 13/16] clk: qcom: MSM8960 GCC driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-13-05a08d87e476@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=7487;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=+41wPb73qFNhdU7PfVeCuHhc+QdAhsR46cnPa++2Ri0=;
 b=yqHrwFkOia5FnZ4hGI9ONST/ZD13/9FbKq+oEc0PM/BBY0LyCojfOlhQv2TWImrXw/DB9qsHV
 FCbSFgkdvUlDvtGdG+1iWGf68UM5gDMJcdbBG7Xmuf6LioBGu9QADg9
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This older GCC does not use RCGR/CBCR, but rather NS/MD/HALT registers.
We can't benefit as much from shared qcom clk infra, nor the `clk dump`
helpers (which assume newer RCGR/PLL register layout).

We start with just the UART clocks.

Signed-off-by: Sam Day <me@samcday.com>
---
 configs/qcom_armv7_defconfig     |   1 +
 drivers/clk/qcom/Kconfig         |   8 ++
 drivers/clk/qcom/Makefile        |   1 +
 drivers/clk/qcom/clock-msm8960.c | 189 +++++++++++++++++++++++++++++++++++++++
 4 files changed, 199 insertions(+)

diff --git a/configs/qcom_armv7_defconfig b/configs/qcom_armv7_defconfig
index aef8838c8a8..91525138ec9 100644
--- a/configs/qcom_armv7_defconfig
+++ b/configs/qcom_armv7_defconfig
@@ -34,6 +34,7 @@ CONFIG_OF_UPSTREAM_BUILD_VENDOR=y
 CONFIG_ENV_USE_DEFAULT_ENV_TEXT_FILE=y
 CONFIG_ENV_DEFAULT_ENV_TEXT_FILE="board/qualcomm/default.env"
 CONFIG_CLK=y
+CONFIG_CLK_QCOM_MSM8960=y
 CONFIG_USB_FUNCTION_FASTBOOT=y
 CONFIG_FASTBOOT_BUF_ADDR=0x0
 CONFIG_FASTBOOT_FLASH=y
diff --git a/drivers/clk/qcom/Kconfig b/drivers/clk/qcom/Kconfig
index 0a2ce55aaa2..3526a4c218b 100644
--- a/drivers/clk/qcom/Kconfig
+++ b/drivers/clk/qcom/Kconfig
@@ -55,6 +55,14 @@ config CLK_QCOM_MILOS
 	  on the Snapdragon Milos SoC. This driver supports the clocks
 	  and resets exposed by the GCC hardware block.
 
+config CLK_QCOM_MSM8960
+	bool "Qualcomm MSM8960 GCC"
+	select CLK_QCOM
+	help
+	  Say Y here to enable support for the Global Clock Controller
+	  on the Snapdragon MSM8960 SoC. This driver supports the clocks
+	  and resets exposed by the GCC hardware block.
+
 config CLK_QCOM_QCM2290
 	bool "Qualcomm QCM2290 GCC"
 	select CLK_QCOM
diff --git a/drivers/clk/qcom/Makefile b/drivers/clk/qcom/Makefile
index b96d61b603e..60a39a7cb39 100644
--- a/drivers/clk/qcom/Makefile
+++ b/drivers/clk/qcom/Makefile
@@ -10,6 +10,7 @@ obj-$(CONFIG_CLK_QCOM_IPQ4019) += clock-ipq4019.o
 obj-$(CONFIG_CLK_QCOM_IPQ5424) += clock-ipq5424.o
 obj-$(CONFIG_CLK_QCOM_IPQ9574) += clock-ipq9574.o
 obj-$(CONFIG_CLK_QCOM_MILOS) += clock-milos.o
+obj-$(CONFIG_CLK_QCOM_MSM8960) += clock-msm8960.o
 obj-$(CONFIG_CLK_QCOM_QCM2290) += clock-qcm2290.o
 obj-$(CONFIG_CLK_QCOM_QCS404) += clock-qcs404.o
 obj-$(CONFIG_CLK_QCOM_QCS8300) += clock-qcs8300.o
diff --git a/drivers/clk/qcom/clock-msm8960.c b/drivers/clk/qcom/clock-msm8960.c
new file mode 100644
index 00000000000..b17fc48fd02
--- /dev/null
+++ b/drivers/clk/qcom/clock-msm8960.c
@@ -0,0 +1,189 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+#include <clk-uclass.h>
+#include <dm.h>
+#include <errno.h>
+#include <asm/io.h>
+#include <linux/bitops.h>
+#include <linux/delay.h>
+#include <dt-bindings/clock/qcom,gcc-msm8960.h>
+
+#include "clock-qcom.h"
+
+#define GPLL8_STATUS        0x3158
+#define APCS_GPLL_ENA_VOTE  0x34c0
+#define GPLL8_STATUS_ACTIVE BIT(16)
+
+#define GSBI5_H_NS    0x2a40
+#define GSBI5_UART_MD 0x2a50
+#define GSBI5_UART_NS 0x2a54
+#define GSBI5_HALT    0x2fd0
+
+#define GSBI5_UART_HALT_BIT 22
+#define GSBI5_H_HALT_BIT    23
+
+#define GSBI_H_CLK_EN    BIT(4)
+#define GSBI_H_HWC_EN    BIT(6)
+#define GSBI_UART_CLK_EN BIT(9)
+#define GSBI_UART_SRC_EN BIT(11)
+
+#define RCG_SRC_SEL_MASK  GENMASK(2, 0)
+#define RCG_PRE_DIV_MASK  GENMASK(4, 3)
+#define RCG_MN_MODE_MASK  GENMASK(6, 5)
+#define RCG_MN_MODE_DUAL  (2 << 5)
+#define RCG_MN_RESET      BIT(7)
+#define RCG_MN_EN         BIT(8)
+#define RCG_MND_MASK      GENMASK(15, 0)
+#define RCG_N_VAL_SHIFT   16
+#define RCG_M_VAL_SHIFT   16
+#define RCG_PRE_DIV_SHIFT 3
+
+#define MSM8960_SRC_PLL8 3
+
+static const struct pll_vote_clk pll8_vote_clk = {
+	.status = GPLL8_STATUS,
+	.status_bit = GPLL8_STATUS_ACTIVE,
+	.ena_vote = APCS_GPLL_ENA_VOTE,
+	.vote_bit = BIT(8),
+};
+
+static const struct freq_tbl gsbi_uart_freqs[] = {
+	{  1843200, MSM8960_SRC_PLL8, 2,  6, 625 },
+	{  3686400, MSM8960_SRC_PLL8, 2, 12, 625 },
+	{  7372800, MSM8960_SRC_PLL8, 2, 24, 625 },
+	{ 14745600, MSM8960_SRC_PLL8, 2, 48, 625 },
+	{ }
+};
+
+static const struct gate_clk msm8960_clks[] = {
+	GATE_CLK(GSBI5_H_CLK, GSBI5_H_NS, GSBI_H_CLK_EN),
+	GATE_CLK(GSBI5_UART_CLK, GSBI5_UART_NS, GSBI_UART_CLK_EN),
+};
+
+static int msm8960_branch_wait(phys_addr_t base, unsigned int halt_bit)
+{
+	u32 count;
+
+	for (count = 0; count < 200; count++) {
+		if (!(readl(base + GSBI5_HALT) & BIT(halt_bit)))
+			return 0;
+		udelay(1);
+	}
+
+	log_warning("MSM8960 GCC branch clock %u stuck off\n", halt_bit);
+	return -EBUSY;
+}
+
+static int msm8960_enable_gsbi5_h_clk(phys_addr_t base)
+{
+	setbits_le32(base + GSBI5_H_NS, GSBI_H_CLK_EN);
+
+	if (readl(base + GSBI5_H_NS) & GSBI_H_HWC_EN)
+		return 0;
+
+	return msm8960_branch_wait(base, GSBI5_H_HALT_BIT);
+}
+
+static void msm8960_rcg_set_rate(phys_addr_t base, const struct freq_tbl *freq)
+{
+	u32 md;
+	u32 ns;
+
+	setbits_le32(base + GSBI5_UART_NS, RCG_MN_RESET);
+
+	md = (freq->m << RCG_M_VAL_SHIFT) | (~freq->n & RCG_MND_MASK);
+	writel(md, base + GSBI5_UART_MD);
+
+	ns = readl(base + GSBI5_UART_NS);
+	ns &= ~(RCG_SRC_SEL_MASK | RCG_PRE_DIV_MASK | RCG_MN_MODE_MASK |
+		RCG_MN_EN | (RCG_MND_MASK << RCG_N_VAL_SHIFT));
+
+	if (freq->n) {
+		ns |= RCG_MN_EN | RCG_MN_MODE_DUAL;
+		ns |= (~(freq->n - freq->m) & RCG_MND_MASK) << RCG_N_VAL_SHIFT;
+	}
+
+	ns |= (freq->pre_div - 1) << RCG_PRE_DIV_SHIFT;
+	ns |= freq->src;
+	writel(ns, base + GSBI5_UART_NS);
+
+	clrbits_le32(base + GSBI5_UART_NS, RCG_MN_RESET);
+}
+
+static ulong msm8960_gsbi5_uart_set_rate(struct msm_clk_priv *priv, ulong rate)
+{
+	const struct freq_tbl *freq = qcom_find_freq(gsbi_uart_freqs, rate);
+	int ret;
+
+	if (!freq || !freq->freq)
+		return 0;
+
+	clk_enable_gpll0(priv->base, &pll8_vote_clk);
+	msm8960_rcg_set_rate(priv->base, freq);
+
+	setbits_le32(priv->base + GSBI5_UART_NS, GSBI_UART_SRC_EN |
+		      GSBI_UART_CLK_EN);
+	ret = msm8960_branch_wait(priv->base, GSBI5_UART_HALT_BIT);
+	if (ret)
+		return 0;
+
+	ret = msm8960_enable_gsbi5_h_clk(priv->base);
+	if (ret)
+		return 0;
+
+	return freq->freq;
+}
+
+static ulong msm8960_clk_set_rate(struct clk *clk, ulong rate)
+{
+	struct msm_clk_priv *priv = dev_get_priv(clk->dev);
+
+	switch (clk->id) {
+	case GSBI5_UART_SRC:
+	case GSBI5_UART_CLK:
+		return msm8960_gsbi5_uart_set_rate(priv, rate);
+	default:
+		return 0;
+	}
+}
+
+static int msm8960_clk_enable(struct clk *clk)
+{
+	struct msm_clk_priv *priv = dev_get_priv(clk->dev);
+
+	switch (clk->id) {
+	case GSBI5_H_CLK:
+		return msm8960_enable_gsbi5_h_clk(priv->base);
+	case GSBI5_UART_SRC:
+		setbits_le32(priv->base + GSBI5_UART_NS, GSBI_UART_SRC_EN);
+		return 0;
+	case GSBI5_UART_CLK:
+		setbits_le32(priv->base + GSBI5_UART_NS, GSBI_UART_CLK_EN);
+		return msm8960_branch_wait(priv->base, GSBI5_UART_HALT_BIT);
+	default:
+		return -ENOENT;
+	}
+}
+
+static struct msm_clk_data msm8960_clk_data = {
+	.clks = msm8960_clks,
+	.num_clks = ARRAY_SIZE(msm8960_clks),
+	.set_rate = msm8960_clk_set_rate,
+	.enable = msm8960_clk_enable,
+};
+
+static const struct udevice_id gcc_msm8960_of_match[] = {
+	{
+		.compatible = "qcom,gcc-msm8960",
+		.data = (ulong)&msm8960_clk_data,
+	},
+	{ }
+};
+
+U_BOOT_DRIVER(gcc_msm8960) = {
+	.name = "gcc_msm8960",
+	.id = UCLASS_NOP,
+	.of_match = gcc_msm8960_of_match,
+	.bind = qcom_cc_bind,
+	.flags = DM_FLAG_PRE_RELOC,
+};

-- 
2.54.0

