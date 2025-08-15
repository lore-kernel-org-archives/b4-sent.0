From: Nickolay Goppen <setotau@yandex.ru>
Date: Fri, 15 Aug 2025 19:56:52 +0300
Subject: [PATCH 2/2] clk: qcom: gcc-sdm660: Add missing LPASS/CDSP vote
 clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250815-gcc-sdm660-vote-clocks-and-gdscs-v1-2-c5a8af040093@yandex.ru>
References: <20250815-gcc-sdm660-vote-clocks-and-gdscs-v1-0-c5a8af040093@yandex.ru>
In-Reply-To: <20250815-gcc-sdm660-vote-clocks-and-gdscs-v1-0-c5a8af040093@yandex.ru>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nickolay Goppen <setotau@yandex.ru>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755277013; l=3670;
 i=setotau@yandex.ru; s=20250815; h=from:subject:message-id;
 bh=X6/ri844i2ly7ZOG0yiJaP7SUffxbwteMISWIbXh6r0=;
 b=HuolyR9GWC21w2uCY+YDwdApm9VK5PTQTV9zv+Iyv+j47UnMQ0TChMXhDiz1mi/kNU9pS0Cxk
 zccW+gYqsH8Cgdmf0cWJnjd3tkEahbU7MOkwgIfABI2afTNaz1wxDrM
X-Developer-Key: i=setotau@yandex.ru; a=ed25519;
 pk=Og7YO6LfW+M2QfcJfjaUaXc8oOr5zoK8+4AtX5ICr4o=
X-Endpoint-Received: by B4 Relay for setotau@yandex.ru/20250815 with auth_id=492
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For the proper functioning of SMMUs related to the audio/compute DSPs,
it makes sense that the clocks and power domains they rely on for
communication should be online.

Add the vote clocks & GDSCs that, when enabled, ensure all such
requirements are met, through various internal mechanisms.

Co-developed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Nickolay Goppen <setotau@yandex.ru>
---
 drivers/clk/qcom/gcc-sdm660.c | 72 +++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 72 insertions(+)

diff --git a/drivers/clk/qcom/gcc-sdm660.c b/drivers/clk/qcom/gcc-sdm660.c
index 01a76f1b5b4c146937a4f5fa0011309fd6ed6be8..20253a06a5839b7265548b4f9fdc1ffc9cf6f9f5 100644
--- a/drivers/clk/qcom/gcc-sdm660.c
+++ b/drivers/clk/qcom/gcc-sdm660.c
@@ -2247,6 +2247,45 @@ static struct clk_branch gcc_usb_phy_cfg_ahb2phy_clk = {
 	},
 };
 
+static struct clk_branch hlos1_vote_lpass_adsp_smmu_clk = {
+	.halt_reg = 0x7d014,
+	.halt_check = BRANCH_VOTED,
+	.clkr = {
+		.enable_reg = 0x7d014,
+		.enable_mask = BIT(0),
+		.hw.init = &(const struct clk_init_data) {
+			.name = "hlos1_vote_lpass_adsp_smmu_clk",
+			.ops = &clk_branch2_ops,
+		},
+	},
+};
+
+static struct clk_branch hlos1_vote_turing_adsp_smmu_clk = {
+	.halt_reg = 0x7d048,
+	.halt_check = BRANCH_VOTED,
+	.clkr = {
+		.enable_reg = 0x7d048,
+		.enable_mask = BIT(0),
+		.hw.init = &(const struct clk_init_data) {
+			.name = "hlos1_vote_turing_adsp_smmu_clk",
+			.ops = &clk_branch2_ops,
+		},
+	},
+};
+
+static struct clk_branch hlos2_vote_turing_adsp_smmu_clk = {
+	.halt_reg = 0x7e048,
+	.halt_check = BRANCH_VOTED,
+	.clkr = {
+		.enable_reg = 0x7e048,
+		.enable_mask = BIT(0),
+		.hw.init = &(const struct clk_init_data) {
+			.name = "hlos2_vote_turing_adsp_smmu_clk",
+			.ops = &clk_branch2_ops,
+		},
+	},
+};
+
 static struct gdsc ufs_gdsc = {
 	.gdscr = 0x75004,
 	.gds_hw_ctrl = 0x0,
@@ -2277,6 +2316,33 @@ static struct gdsc pcie_0_gdsc = {
 	.flags = VOTABLE,
 };
 
+static struct gdsc hlos1_vote_turing_adsp_gdsc = {
+	.gdscr = 0x7d04c,
+	.pd = {
+		.name = "hlos1_vote_turing_adsp_gdsc",
+	},
+	.pwrsts = PWRSTS_OFF_ON,
+	.flags = VOTABLE,
+};
+
+static struct gdsc hlos2_vote_turing_adsp_gdsc = {
+	.gdscr = 0x7e04c,
+	.pd = {
+		.name = "hlos2_vote_turing_adsp_gdsc",
+	},
+	.pwrsts = PWRSTS_OFF_ON,
+	.flags = VOTABLE,
+};
+
+static struct gdsc hlos1_vote_lpass_adsp_gdsc = {
+	.gdscr = 0x7d034,
+	.pd = {
+		.name = "hlos1_vote_lpass_adsp_gdsc",
+	},
+	.pwrsts = PWRSTS_OFF_ON,
+	.flags = VOTABLE,
+};
+
 static struct clk_hw *gcc_sdm660_hws[] = {
 	&xo.hw,
 	&gpll0_early_div.hw,
@@ -2409,12 +2475,18 @@ static struct clk_regmap *gcc_sdm660_clocks[] = {
 	[USB30_MASTER_CLK_SRC] = &usb30_master_clk_src.clkr,
 	[USB30_MOCK_UTMI_CLK_SRC] = &usb30_mock_utmi_clk_src.clkr,
 	[USB3_PHY_AUX_CLK_SRC] = &usb3_phy_aux_clk_src.clkr,
+	[GCC_HLOS1_VOTE_LPASS_ADSP_SMMU_CLK] = &hlos1_vote_lpass_adsp_smmu_clk.clkr,
+	[GCC_HLOS1_VOTE_TURING_ADSP_SMMU_CLK] = &hlos1_vote_turing_adsp_smmu_clk.clkr,
+	[GCC_HLOS2_VOTE_TURING_ADSP_SMMU_CLK] = &hlos2_vote_turing_adsp_smmu_clk.clkr,
 };
 
 static struct gdsc *gcc_sdm660_gdscs[] = {
 	[UFS_GDSC] = &ufs_gdsc,
 	[USB_30_GDSC] = &usb_30_gdsc,
 	[PCIE_0_GDSC] = &pcie_0_gdsc,
+	[HLOS1_VOTE_TURING_ADSP_GDSC] = &hlos1_vote_turing_adsp_gdsc,
+	[HLOS2_VOTE_TURING_ADSP_GDSC] = &hlos2_vote_turing_adsp_gdsc,
+	[HLOS1_VOTE_LPASS_ADSP_GDSC] = &hlos1_vote_lpass_adsp_gdsc,
 };
 
 static const struct qcom_reset_map gcc_sdm660_resets[] = {

-- 
2.50.1

