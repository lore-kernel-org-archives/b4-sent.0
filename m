From: Demeter Barna <me@fromdisposition.org>
Date: Sat, 14 Nov 2026 02:21:55 +0000
Subject: [PATCH 1/9] clk: qcom: Add SM8350 GCC driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-sm8350-support-v1-1-414271f59474@fromdisposition.org>
References: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
In-Reply-To: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Lukasz Majewski <lukma@nabladev.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Biswapriyo Nath <nathbappai@gmail.com>, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Erikas Bitovtas <xerikasxx@gmail.com>, Johan Jonker <jbx6244@gmail.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Michael Srba <Michael.Srba@seznam.cz>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Demeter Barna <me@fromdisposition.org>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794622936; l=12501;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=+KXBqJyjMpDrSsLUr+U/TTWndFA+DGFbRxRxmVgZoH8=;
 b=Z3elKw3rbzda03ZzewVutVwAd1v9Hs9M4/1po2rXvx+MbBUAdYkbX6QpAj5FUI9OzabNYV60J
 OdgSsmVoJW6DOpYhDuEQeKWoXFkLgmB4PH0HuwdSd6K7Zbn4oGdeuKA
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a clock driver for the SM8350 SoC, with the clocks, resets and GDSCs
of the QUP wrappers, UFS, the primary USB controller and SDCC2.

The data are those of Linux's gcc-sm8350 driver (tag v7.4-rc1).

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 drivers/clk/qcom/Kconfig        |   8 ++
 drivers/clk/qcom/Makefile       |   1 +
 drivers/clk/qcom/clock-sm8350.c | 281 ++++++++++++++++++++++++++++++++++++++++
 3 files changed, 290 insertions(+)

diff --git a/drivers/clk/qcom/Kconfig b/drivers/clk/qcom/Kconfig
index 0d8f5028a4..e18d7c1c58 100644
--- a/drivers/clk/qcom/Kconfig
+++ b/drivers/clk/qcom/Kconfig
@@ -160,6 +160,14 @@ config CLK_QCOM_SM8250
 	  on the Snapdragon SM8250 SoC. This driver supports the clocks
 	  and resets exposed by the GCC hardware block.
 
+config CLK_QCOM_SM8350
+	bool "Qualcomm SM8350 GCC"
+	select CLK_QCOM
+	help
+	  Say Y here to enable support for the Global Clock Controller
+	  on the Snapdragon SM8350 SoC. This driver supports the clocks
+	  and resets exposed by the GCC hardware block.
+
 config CLK_QCOM_SM8550
 	bool "Qualcomm SM8550 GCC"
 	select CLK_QCOM
diff --git a/drivers/clk/qcom/Makefile b/drivers/clk/qcom/Makefile
index 73cafc3f93..53788f1370 100644
--- a/drivers/clk/qcom/Makefile
+++ b/drivers/clk/qcom/Makefile
@@ -24,6 +24,7 @@ obj-$(CONFIG_CLK_QCOM_SM6350) += clock-sm6350.o
 obj-$(CONFIG_CLK_QCOM_SM7150) += clock-sm7150.o
 obj-$(CONFIG_CLK_QCOM_SM8150) += clock-sm8150.o
 obj-$(CONFIG_CLK_QCOM_SM8250) += clock-sm8250.o
+obj-$(CONFIG_CLK_QCOM_SM8350) += clock-sm8350.o
 obj-$(CONFIG_CLK_QCOM_SM8550) += clock-sm8550.o
 obj-$(CONFIG_CLK_QCOM_SM8650) += clock-sm8650.o
 obj-$(CONFIG_CLK_QCOM_X1E80100) += clock-x1e80100.o
diff --git a/drivers/clk/qcom/clock-sm8350.c b/drivers/clk/qcom/clock-sm8350.c
new file mode 100644
index 0000000000..b643d3347e
--- /dev/null
+++ b/drivers/clk/qcom/clock-sm8350.c
@@ -0,0 +1,281 @@
+// SPDX-License-Identifier: BSD-3-Clause
+/*
+ * Clock drivers for Qualcomm sm8350
+ *
+ * (C) Copyright 2024 Linaro Ltd.
+ * (C) Copyright 2026 Demeter Barna <me@fromdisposition.org>
+ *
+ * Based on Linux Kernel driver
+ */
+
+#include <clk-uclass.h>
+#include <dm.h>
+#include <linux/bitops.h>
+#include <dt-bindings/clock/qcom,gcc-sm8350.h>
+
+#include "clock-qcom.h"
+
+/* bi_tcxo */
+#define TCXO_RATE	19200000
+
+static const struct freq_tbl ftbl_gcc_qupv3_wrap0_s0_clk_src[] = {
+	F(7372800, CFG_CLK_SRC_GPLL0_EVEN, 1, 384, 15625),
+	F(14745600, CFG_CLK_SRC_GPLL0_EVEN, 1, 768, 15625),
+	F(19200000, CFG_CLK_SRC_CXO, 1, 0, 0),
+	F(29491200, CFG_CLK_SRC_GPLL0_EVEN, 1, 1536, 15625),
+	F(32000000, CFG_CLK_SRC_GPLL0_EVEN, 1, 8, 75),
+	F(48000000, CFG_CLK_SRC_GPLL0_EVEN, 1, 4, 25),
+	F(64000000, CFG_CLK_SRC_GPLL0_EVEN, 1, 16, 75),
+	F(75000000, CFG_CLK_SRC_GPLL0_EVEN, 4, 0, 0),
+	F(80000000, CFG_CLK_SRC_GPLL0_EVEN, 1, 4, 15),
+	F(96000000, CFG_CLK_SRC_GPLL0_EVEN, 1, 8, 25),
+	F(100000000, CFG_CLK_SRC_GPLL0, 6, 0, 0),
+	{ }
+};
+
+static const struct freq_tbl ftbl_gcc_usb30_prim_master_clk_src[] = {
+	F(66666667, CFG_CLK_SRC_GPLL0_EVEN, 4.5, 0, 0),
+	F(133333333, CFG_CLK_SRC_GPLL0, 4.5, 0, 0),
+	F(200000000, CFG_CLK_SRC_GPLL0, 3, 0, 0),
+	F(240000000, CFG_CLK_SRC_GPLL0, 2.5, 0, 0),
+	{ }
+};
+
+static const struct freq_tbl ftbl_gcc_ufs_card_ice_core_clk_src[] = {
+	F(75000000, CFG_CLK_SRC_GPLL0_EVEN, 4, 0, 0),
+	F(150000000, CFG_CLK_SRC_GPLL0, 4, 0, 0),
+	F(300000000, CFG_CLK_SRC_GPLL0, 2, 0, 0),
+	{ }
+};
+
+static const struct freq_tbl ftbl_gcc_sdcc2_apps_clk_src[] = {
+	F(400000, CFG_CLK_SRC_CXO, 12, 1, 4),
+	F(25000000, CFG_CLK_SRC_GPLL0_EVEN, 12, 0, 0),
+	F(50000000, CFG_CLK_SRC_GPLL0_EVEN, 6, 0, 0),
+	F(100000000, CFG_CLK_SRC_GPLL0_EVEN, 3, 0, 0),
+	F(202000000, CFG_CLK_SRC_GPLL9, 4, 0, 0),
+	{ }
+};
+
+static struct pll_vote_clk gpll9_vote_clk = {
+	.status = 0x1c000,
+	.status_bit = BIT(31),
+	.ena_vote = 0x52018,
+	.vote_bit = BIT(9),
+};
+
+static ulong sm8350_set_rate(struct clk *clk, ulong rate)
+{
+	struct msm_clk_priv *priv = dev_get_priv(clk->dev);
+	const struct freq_tbl *freq;
+
+	switch (clk->id) {
+	case GCC_QUPV3_WRAP0_S3_CLK: /* debug UART */
+		freq = qcom_find_freq(ftbl_gcc_qupv3_wrap0_s0_clk_src, rate);
+		clk_rcg_set_rate_mnd(priv->base, 0x173a0,
+				     freq->pre_div, freq->m, freq->n, freq->src, 16);
+		return freq->freq;
+	case GCC_USB30_PRIM_MASTER_CLK:
+		freq = qcom_find_freq(ftbl_gcc_usb30_prim_master_clk_src, rate);
+		clk_rcg_set_rate_mnd(priv->base, 0xf020,
+				     freq->pre_div, freq->m, freq->n, freq->src, 8);
+		return freq->freq;
+	case GCC_USB30_PRIM_MOCK_UTMI_CLK:
+		clk_rcg_set_rate(priv->base, 0xf038, 0, CFG_CLK_SRC_CXO);
+		return TCXO_RATE;
+	case GCC_UFS_PHY_UNIPRO_CORE_CLK:
+		freq = qcom_find_freq(ftbl_gcc_ufs_card_ice_core_clk_src, rate);
+		clk_rcg_set_rate_mnd(priv->base, 0x77084,
+				     freq->pre_div, freq->m, freq->n, freq->src, 0);
+		return freq->freq;
+	case GCC_SDCC2_APPS_CLK:
+		/* GPLL9 feeds the highest SDCC2 rate */
+		clk_enable_gpll0(priv->base, &gpll9_vote_clk);
+		freq = qcom_find_freq(ftbl_gcc_sdcc2_apps_clk_src, rate);
+		clk_rcg_set_rate_mnd(priv->base, 0x1400c,
+				     freq->pre_div, freq->m, freq->n, freq->src, 8);
+		return freq->freq;
+	default:
+		return 0;
+	}
+}
+
+static const struct gate_clk sm8350_clks[] = {
+	GATE_CLK(GCC_AGGRE_UFS_PHY_AXI_CLK,          0x770cc, 0x00000001),
+	GATE_CLK(GCC_AGGRE_UFS_PHY_AXI_HW_CTL_CLK,   0x770cc, 0x00000002),
+	GATE_CLK(GCC_AGGRE_USB3_PRIM_AXI_CLK,        0x0f080, 0x00000001),
+	GATE_CLK(GCC_CFG_NOC_USB3_PRIM_AXI_CLK,      0x0f07c, 0x00000001),
+	GATE_CLK(GCC_QUPV3_WRAP0_CORE_2X_CLK,        0x52008, 0x00000200),
+	GATE_CLK(GCC_QUPV3_WRAP0_CORE_CLK,           0x52008, 0x00000100),
+	GATE_CLK(GCC_QUPV3_WRAP0_S0_CLK,             0x52008, 0x00000400),
+	GATE_CLK(GCC_QUPV3_WRAP0_S1_CLK,             0x52008, 0x00000800),
+	GATE_CLK(GCC_QUPV3_WRAP0_S2_CLK,             0x52008, 0x00001000),
+	GATE_CLK(GCC_QUPV3_WRAP0_S3_CLK,             0x52008, 0x00002000),
+	GATE_CLK(GCC_QUPV3_WRAP0_S4_CLK,             0x52008, 0x00004000),
+	GATE_CLK(GCC_QUPV3_WRAP0_S5_CLK,             0x52008, 0x00008000),
+	GATE_CLK(GCC_QUPV3_WRAP0_S6_CLK,             0x52008, 0x00010000),
+	GATE_CLK(GCC_QUPV3_WRAP0_S7_CLK,             0x52008, 0x00020000),
+	GATE_CLK(GCC_QUPV3_WRAP1_CORE_2X_CLK,        0x52008, 0x00040000),
+	GATE_CLK(GCC_QUPV3_WRAP1_CORE_CLK,           0x52008, 0x00080000),
+	GATE_CLK(GCC_QUPV3_WRAP1_S0_CLK,             0x52008, 0x00400000),
+	GATE_CLK(GCC_QUPV3_WRAP1_S1_CLK,             0x52008, 0x00800000),
+	GATE_CLK(GCC_QUPV3_WRAP1_S2_CLK,             0x52008, 0x01000000),
+	GATE_CLK(GCC_QUPV3_WRAP1_S3_CLK,             0x52008, 0x02000000),
+	GATE_CLK(GCC_QUPV3_WRAP1_S4_CLK,             0x52008, 0x04000000),
+	GATE_CLK(GCC_QUPV3_WRAP1_S5_CLK,             0x52008, 0x08000000),
+	GATE_CLK(GCC_QUPV3_WRAP2_CORE_2X_CLK,        0x52010, 0x00000008),
+	GATE_CLK(GCC_QUPV3_WRAP2_CORE_CLK,           0x52010, 0x00000001),
+	GATE_CLK(GCC_QUPV3_WRAP2_S0_CLK,             0x52010, 0x00000010),
+	GATE_CLK(GCC_QUPV3_WRAP2_S1_CLK,             0x52010, 0x00000020),
+	GATE_CLK(GCC_QUPV3_WRAP2_S2_CLK,             0x52010, 0x00000040),
+	GATE_CLK(GCC_QUPV3_WRAP2_S3_CLK,             0x52010, 0x00000080),
+	GATE_CLK(GCC_QUPV3_WRAP2_S4_CLK,             0x52010, 0x00000100),
+	GATE_CLK(GCC_QUPV3_WRAP2_S5_CLK,             0x52010, 0x00000200),
+	GATE_CLK(GCC_QUPV3_WRAP_0_M_AHB_CLK,         0x52008, 0x00000040),
+	GATE_CLK(GCC_QUPV3_WRAP_0_S_AHB_CLK,         0x52008, 0x00000080),
+	GATE_CLK(GCC_QUPV3_WRAP_1_M_AHB_CLK,         0x52008, 0x00100000),
+	GATE_CLK(GCC_QUPV3_WRAP_1_S_AHB_CLK,         0x52008, 0x00200000),
+	GATE_CLK(GCC_QUPV3_WRAP_2_M_AHB_CLK,         0x52010, 0x00000004),
+	GATE_CLK(GCC_QUPV3_WRAP_2_S_AHB_CLK,         0x52010, 0x00000002),
+	GATE_CLK(GCC_SDCC2_AHB_CLK,                  0x14008, 0x00000001),
+	GATE_CLK(GCC_SDCC2_APPS_CLK,                 0x14004, 0x00000001),
+	GATE_CLK(GCC_UFS_1_CLKREF_EN,                0x8c000, 0x00000001),
+	GATE_CLK(GCC_UFS_PHY_AHB_CLK,                0x77018, 0x00000001),
+	GATE_CLK(GCC_UFS_PHY_AXI_CLK,                0x77010, 0x00000001),
+	GATE_CLK(GCC_UFS_PHY_AXI_HW_CTL_CLK,         0x77010, 0x00000002),
+	GATE_CLK(GCC_UFS_PHY_ICE_CORE_CLK,           0x77064, 0x00000001),
+	GATE_CLK(GCC_UFS_PHY_ICE_CORE_HW_CTL_CLK,    0x77064, 0x00000002),
+	GATE_CLK(GCC_UFS_PHY_PHY_AUX_CLK,            0x7709c, 0x00000001),
+	GATE_CLK(GCC_UFS_PHY_PHY_AUX_HW_CTL_CLK,     0x7709c, 0x00000002),
+	GATE_CLK(GCC_UFS_PHY_RX_SYMBOL_0_CLK,        0x77020, 0x00000001),
+	GATE_CLK(GCC_UFS_PHY_RX_SYMBOL_1_CLK,        0x770b8, 0x00000001),
+	GATE_CLK(GCC_UFS_PHY_TX_SYMBOL_0_CLK,        0x7701c, 0x00000001),
+	GATE_CLK(GCC_UFS_PHY_UNIPRO_CORE_CLK,        0x7705c, 0x00000001),
+	GATE_CLK(GCC_UFS_PHY_UNIPRO_CORE_HW_CTL_CLK, 0x7705c, 0x00000002),
+	GATE_CLK(GCC_USB30_PRIM_MASTER_CLK,          0x0f010, 0x00000001),
+	GATE_CLK(GCC_USB30_PRIM_MOCK_UTMI_CLK,       0x0f01c, 0x00000001),
+	GATE_CLK(GCC_USB30_PRIM_SLEEP_CLK,           0x0f018, 0x00000001),
+	GATE_CLK(GCC_USB3_PRIM_PHY_AUX_CLK,          0x0f054, 0x00000001),
+	GATE_CLK(GCC_USB3_PRIM_PHY_COM_AUX_CLK,      0x0f058, 0x00000001),
+	GATE_CLK(GCC_USB3_PRIM_PHY_PIPE_CLK,         0x0f05c, 0x00000001),
+};
+
+static int sm8350_enable(struct clk *clk)
+{
+	struct msm_clk_priv *priv = dev_get_priv(clk->dev);
+
+	return qcom_gate_clk_en(priv, clk->id);
+}
+
+static const struct qcom_reset_map sm8350_gcc_resets[] = {
+	[GCC_QUSB2PHY_PRIM_BCR] = { 0x12000 },
+	[GCC_SDCC2_BCR] = { 0x14000 },
+	[GCC_UFS_PHY_BCR] = { 0x77000 },
+	[GCC_USB30_PRIM_BCR] = { 0xf000 },
+};
+
+static const struct qcom_power_map sm8350_gdscs[] = {
+	[UFS_PHY_GDSC] = { 0x77004 },
+	[USB30_PRIM_GDSC] = { 0xf004 },
+};
+
+/* GPLL4 and GPLL9 are left out: clk dump names the PLLs by their index here */
+static const phys_addr_t sm8350_gpll_addrs[] = {
+	0x00100000,
+};
+
+static const phys_addr_t sm8350_rcg_addrs[] = {
+	0x00117010,
+	0x00117140,
+	0x00117270,
+	0x001173a0,
+	0x001174d0,
+	0x00117600,
+	0x00117730,
+	0x00117860,
+	0x00118010,
+	0x00118140,
+	0x00118270,
+	0x001183a0,
+	0x001184d0,
+	0x00118600,
+	0x0011e010,
+	0x0011e140,
+	0x0011e270,
+	0x0011e3a0,
+	0x0011e4d0,
+	0x0011e600,
+	0x0011400c,
+	0x00177024,
+	0x0017706c,
+	0x001770a0,
+	0x00177084,
+	0x0010f020,
+	0x0010f038,
+	0x0010f064,
+};
+
+static const char *const sm8350_rcg_names[] = {
+	"GCC_QUPV3_WRAP0_S0_CMD_RCGR",
+	"GCC_QUPV3_WRAP0_S1_CMD_RCGR",
+	"GCC_QUPV3_WRAP0_S2_CMD_RCGR",
+	"GCC_QUPV3_WRAP0_S3_CMD_RCGR",
+	"GCC_QUPV3_WRAP0_S4_CMD_RCGR",
+	"GCC_QUPV3_WRAP0_S5_CMD_RCGR",
+	"GCC_QUPV3_WRAP0_S6_CMD_RCGR",
+	"GCC_QUPV3_WRAP0_S7_CMD_RCGR",
+	"GCC_QUPV3_WRAP1_S0_CMD_RCGR",
+	"GCC_QUPV3_WRAP1_S1_CMD_RCGR",
+	"GCC_QUPV3_WRAP1_S2_CMD_RCGR",
+	"GCC_QUPV3_WRAP1_S3_CMD_RCGR",
+	"GCC_QUPV3_WRAP1_S4_CMD_RCGR",
+	"GCC_QUPV3_WRAP1_S5_CMD_RCGR",
+	"GCC_QUPV3_WRAP2_S0_CMD_RCGR",
+	"GCC_QUPV3_WRAP2_S1_CMD_RCGR",
+	"GCC_QUPV3_WRAP2_S2_CMD_RCGR",
+	"GCC_QUPV3_WRAP2_S3_CMD_RCGR",
+	"GCC_QUPV3_WRAP2_S4_CMD_RCGR",
+	"GCC_QUPV3_WRAP2_S5_CMD_RCGR",
+	"GCC_SDCC2_APPS_CMD_RCGR",
+	"GCC_UFS_PHY_AXI_CMD_RCGR",
+	"GCC_UFS_PHY_ICE_CORE_CMD_RCGR",
+	"GCC_UFS_PHY_PHY_AUX_CMD_RCGR",
+	"GCC_UFS_PHY_UNIPRO_CORE_CMD_RCGR",
+	"GCC_USB30_PRIM_MASTER_CMD_RCGR",
+	"GCC_USB30_PRIM_MOCK_UTMI_CMD_RCGR",
+	"GCC_USB3_PRIM_PHY_AUX_CMD_RCGR",
+};
+
+static struct msm_clk_data sm8350_gcc_data = {
+	.resets = sm8350_gcc_resets,
+	.num_resets = ARRAY_SIZE(sm8350_gcc_resets),
+	.clks = sm8350_clks,
+	.num_clks = ARRAY_SIZE(sm8350_clks),
+	.power_domains = sm8350_gdscs,
+	.num_power_domains = ARRAY_SIZE(sm8350_gdscs),
+
+	.dbg_pll_addrs = sm8350_gpll_addrs,
+	.num_plls = ARRAY_SIZE(sm8350_gpll_addrs),
+	.dbg_rcg_addrs = sm8350_rcg_addrs,
+	.num_rcgs = ARRAY_SIZE(sm8350_rcg_addrs),
+	.dbg_rcg_names = sm8350_rcg_names,
+
+	.enable = sm8350_enable,
+	.set_rate = sm8350_set_rate,
+};
+
+static const struct udevice_id gcc_sm8350_of_match[] = {
+	{
+		.compatible = "qcom,gcc-sm8350",
+		.data = (ulong)&sm8350_gcc_data,
+	},
+	{ }
+};
+
+U_BOOT_DRIVER(gcc_sm8350) = {
+	.name		= "gcc_sm8350",
+	.id		= UCLASS_NOP,
+	.of_match	= gcc_sm8350_of_match,
+	.bind		= qcom_cc_bind,
+	.flags		= DM_FLAG_PRE_RELOC | DM_FLAG_DEFAULT_PD_CTRL_OFF,
+};

-- 
2.53.0

