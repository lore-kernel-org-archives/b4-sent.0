From: Andrew Gigena <mail@andrewgigena.dev>
Date: Fri, 06 Nov 2026 18:35:38 +0000
Subject: [PATCH v3 6/7] phy: qcom-mipi-csi2: Add SM8150 CSI2 DPHY support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-sm8150-v7.4-rc1-camss-v3-6-0103e8a0bbcd@andrewgigena.dev>
References: <20261106-sm8150-v7.4-rc1-camss-v3-0-0103e8a0bbcd@andrewgigena.dev>
In-Reply-To: <20261106-sm8150-v7.4-rc1-camss-v3-0-0103e8a0bbcd@andrewgigena.dev>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Robert Foss <rfoss@kernel.org>, Andi Shyti <andi.shyti@linaro.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-phy@lists.infradead.org, 
 Andrew Gigena <mail@andrewgigena.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793990195; l=10225;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=fAFtbuNKrv0SCgpDRGKPsktmDHYGiaUp7Ava6AeGnlc=;
 b=VAG5fKZPSbi0SHPgrNKQFBE+LBfJrV3lrDvIKjb+aoy3awnqy8KYfv8K41EH57gBArh3uy9w0
 vkqIMpYTnVnDcQj6a8CVt+rp7d1s34v9Aw6VOGMTVpsm7FThq0I01WT
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SM8150 platform data to the CSI2 DPHY driver so that SM8150 can use
the dedicated PHY driver instead of the CAMSS-integrated CSIPHY.

The SM8150 CSIPHY uses the SC8280XP lane register layout, as already
used by the CAMSS driver, so reuse that table, dropping the DNP entries,
which the new PHY driver does not program. The PHY is fed by the "core"
and "timer" clocks, the vdda-phy and vdda-pll supplies, and the Titan top
power domain, which is not scaled.

The timer clock is pinned to 300 MHz via a new timer_rate_hz soc field
(SM8150 timer only supports 19.2/300 MHz). SM8150 is ordered before
X1E80100 as it predates it (7 nm vs 4 nm). A detach of the
platform-attached single power domain is done before attaching by name,
so single-domain SoCs do not fail with -EEXIST.

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>
---
 drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c | 97 ++++++++++++++++++++++
 drivers/phy/qualcomm/phy-qcom-mipi-csi2-core.c     | 16 +++-
 drivers/phy/qualcomm/phy-qcom-mipi-csi2.h          |  4 +
 3 files changed, 116 insertions(+), 1 deletion(-)

diff --git a/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c b/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c
index 966d79c98f9b..b8b6589cee35 100644
--- a/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c
+++ b/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c
@@ -45,6 +45,73 @@
 #define CSIPHY_SETTLE_CNT_LOWER_BYTE			2
 #define CSIPHY_SKEW_CAL					7
 
+/* 7nm 2PH v 1.1 2p5Gbps 4 lane DPHY mode */
+static const struct
+mipi_csi2phy_lane_regs lane_regs_sm8150[] = {
+	{.reg_addr = 0x0004, .reg_data = 0x0c, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x002c, .reg_data = 0x01, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0034, .reg_data = 0x0f, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x001c, .reg_data = 0x0a, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0014, .reg_data = 0x60, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x003c, .reg_data = 0xb8, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0000, .reg_data = 0x90, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0008, .reg_data = 0x0e, .param_type = CSIPHY_SETTLE_CNT_LOWER_BYTE},
+	{.reg_addr = 0x0010, .reg_data = 0x52, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0038, .reg_data = 0xfe, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0060, .reg_data = 0x00, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0064, .reg_data = 0x7f, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0704, .reg_data = 0x0c, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x072c, .reg_data = 0x01, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0734, .reg_data = 0x0f, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x071c, .reg_data = 0x0a, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0714, .reg_data = 0x60, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0728, .reg_data = 0x04, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x073c, .reg_data = 0xb8, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0700, .reg_data = 0x80, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0708, .reg_data = 0x0e, .param_type = CSIPHY_SETTLE_CNT_LOWER_BYTE},
+	{.reg_addr = 0x070c, .reg_data = 0xa5, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0710, .reg_data = 0x52, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0738, .reg_data = 0x1f, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0760, .reg_data = 0x00, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0764, .reg_data = 0x7f, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0204, .reg_data = 0x0c, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x022c, .reg_data = 0x01, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0234, .reg_data = 0x0f, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x021c, .reg_data = 0x0a, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0214, .reg_data = 0x60, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x023c, .reg_data = 0xb8, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0200, .reg_data = 0x90, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0208, .reg_data = 0x0e, .param_type = CSIPHY_SETTLE_CNT_LOWER_BYTE},
+	{.reg_addr = 0x0210, .reg_data = 0x52, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0238, .reg_data = 0xfe, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0260, .reg_data = 0x00, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0264, .reg_data = 0x7f, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0404, .reg_data = 0x0c, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x042c, .reg_data = 0x01, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0434, .reg_data = 0x0f, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x041c, .reg_data = 0x0a, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0414, .reg_data = 0x60, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x043c, .reg_data = 0xb8, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0400, .reg_data = 0x90, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0408, .reg_data = 0x0e, .param_type = CSIPHY_SETTLE_CNT_LOWER_BYTE},
+	{.reg_addr = 0x0410, .reg_data = 0x52, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0438, .reg_data = 0xfe, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0460, .reg_data = 0x00, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0464, .reg_data = 0x7f, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0604, .reg_data = 0x0c, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x062c, .reg_data = 0x01, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0634, .reg_data = 0x0f, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x061c, .reg_data = 0x0a, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0614, .reg_data = 0x60, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x063c, .reg_data = 0xb8, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0600, .reg_data = 0x90, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0608, .reg_data = 0x0e, .param_type = CSIPHY_SETTLE_CNT_LOWER_BYTE},
+	{.reg_addr = 0x0610, .reg_data = 0x52, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0638, .reg_data = 0xfe, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0660, .reg_data = 0x00, .param_type = CSIPHY_DEFAULT_PARAMS},
+	{.reg_addr = 0x0664, .reg_data = 0x7f, .param_type = CSIPHY_DEFAULT_PARAMS},
+};
+
 /* 4nm 2PH v 2.1.2 2p5Gbps 4 lane DPHY mode */
 static const struct
 mipi_csi2phy_lane_regs lane_regs_x1e80100[] = {
@@ -352,6 +419,36 @@ static const struct mipi_csi2phy_hw_ops phy_qcom_mipi_csi2_ops_3ph_1_0 = {
 	.lanes_disable = phy_qcom_mipi_csi2_lanes_disable,
 };
 
+static const char * const sm8150_clks[] = {
+	"core",
+	"timer"
+};
+
+static const char * const sm8150_supplies[] = {
+	"vdda-phy",
+	"vdda-pll"
+};
+
+static struct mipi_csi2_genpd sm8150_genpds[] = {
+	{ .name = "top", .scaled = false },
+};
+
+const struct mipi_csi2phy_soc_cfg mipi_csi2_dphy_sm8150 = {
+	.ops = &phy_qcom_mipi_csi2_ops_3ph_1_0,
+	.reg_info = {
+		.init_seq = lane_regs_sm8150,
+		.lane_array_size = ARRAY_SIZE(lane_regs_sm8150),
+		.common_regs_offset = 0x800,
+	},
+	.supply_names = (const char **)sm8150_supplies,
+	.num_supplies = ARRAY_SIZE(sm8150_supplies),
+	.clk_names = (const char **)sm8150_clks,
+	.num_clk = ARRAY_SIZE(sm8150_clks),
+	.timer_rate_hz = 300000000,
+	.genpds = sm8150_genpds,
+	.num_genpds = ARRAY_SIZE(sm8150_genpds),
+};
+
 static const char * const x1e_clks[] = {
 	"core",
 	"timer",
diff --git a/drivers/phy/qualcomm/phy-qcom-mipi-csi2-core.c b/drivers/phy/qualcomm/phy-qcom-mipi-csi2-core.c
index c0a4fa20eaf0..3a45b8766311 100644
--- a/drivers/phy/qualcomm/phy-qcom-mipi-csi2-core.c
+++ b/drivers/phy/qualcomm/phy-qcom-mipi-csi2-core.c
@@ -68,7 +68,11 @@ phy_qcom_mipi_csi2_set_clock_rates(struct mipi_csi2phy_device *csi2phy,
 		goto unset_opp_rate;
 	}
 
-	timer_rate = clk_round_rate(csi2phy->timer_clk, link_freq / 4);
+	if (csi2phy->soc_cfg->timer_rate_hz)
+		timer_rate = clk_round_rate(csi2phy->timer_clk,
+					    csi2phy->soc_cfg->timer_rate_hz);
+	else
+		timer_rate = clk_round_rate(csi2phy->timer_clk, link_freq / 4);
 	if (timer_rate <= 0) {
 		ret = -ENODEV;
 		goto unset_opp_rate;
@@ -233,6 +237,15 @@ static int phy_qcom_mipi_csi2_attach_pm_domains(struct mipi_csi2phy_device *csi2
 	const char **pd_names;
 	int i;
 
+	/*
+	 * platform_probe() auto-attaches a single power domain during probe.
+	 * Detach it first so devm_pm_domain_attach_list() can attach all
+	 * domains by name (otherwise it returns -EEXIST for single-domain
+	 * SoCs such as SM8150).
+	 */
+	if (csi2phy->dev->pm_domain)
+		dev_pm_domain_detach(csi2phy->dev, false);
+
 	pd_names = devm_kzalloc(csi2phy->dev,
 				sizeof(char *) * csi2phy->soc_cfg->num_genpds,
 				GFP_KERNEL);
@@ -443,6 +456,7 @@ static int phy_qcom_mipi_csi2_probe(struct platform_device *pdev)
 }
 
 static const struct of_device_id phy_qcom_mipi_csi2_of_match_table[] = {
+	{ .compatible	= "qcom,sm8150-csi2-phy", .data = &mipi_csi2_dphy_sm8150 },
 	{ .compatible	= "qcom,x1e80100-csi2-phy", .data = &mipi_csi2_dphy_4nm_x1e },
 	{ }
 };
diff --git a/drivers/phy/qualcomm/phy-qcom-mipi-csi2.h b/drivers/phy/qualcomm/phy-qcom-mipi-csi2.h
index 7e55ae007370..4da9f12d4f8d 100644
--- a/drivers/phy/qualcomm/phy-qcom-mipi-csi2.h
+++ b/drivers/phy/qualcomm/phy-qcom-mipi-csi2.h
@@ -68,6 +68,9 @@ struct mipi_csi2phy_soc_cfg {
 	const char ** const clk_names;
 	const unsigned int num_clk;
 
+	/* 0 = derive timer rate from link_freq/4; non-zero = fixed rate */
+	unsigned long timer_rate_hz;
+
 	const struct mipi_csi2_genpd *genpds;
 	const unsigned int num_genpds;
 };
@@ -92,6 +95,7 @@ struct mipi_csi2phy_device {
 	u32 hw_version;
 };
 
+extern const struct mipi_csi2phy_soc_cfg mipi_csi2_dphy_sm8150;
 extern const struct mipi_csi2phy_soc_cfg mipi_csi2_dphy_4nm_x1e;
 
 #endif /* __PHY_QCOM_MIPI_CSI2_H__ */

-- 
2.56.0

