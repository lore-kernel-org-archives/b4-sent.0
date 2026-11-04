From: Andrew Gigena <mail@andrewgigena.dev>
Date: Wed, 04 Nov 2026 20:54:16 +0000
Subject: [PATCH 3/4] media: qcom: camss: Add support for SM8150
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sm8150-v7-4-rc1-camss-v1-3-7a9534a9a22f@andrewgigena.dev>
References: <20261104-sm8150-v7-4-rc1-camss-v1-0-7a9534a9a22f@andrewgigena.dev>
In-Reply-To: <20261104-sm8150-v7-4-rc1-camss-v1-0-7a9534a9a22f@andrewgigena.dev>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Robert Foss <rfoss@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, Andrew Gigena <mail@andrewgigena.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793825658; l=10844;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=lRRRM9G/UkEIiNuQEda8IevwBO+dcuXD9tObtK2BcXI=;
 b=zI9u6gbCfT61dNs24XgPNKq5p7TGIeKndSEfpvI4HucA1+uyMFdmAnCNbcyLdQrvYGYsE+ppV
 +m2BlkCvZGbBvh+L/at52cavfXAh8e+GjeIlKnnoeurbVHzWlQi+YY+
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add CAMSS platform data for the Qualcomm SM8150 SoC. The camera
subsystem contains four CSIPHY, four CSID (two full and two lite), two
VFE and two VFE-Lite instances.

The hardware reuses the existing 3-phase 1.0 CSIPHY, Gen2 CSID and
VFE 17x implementations; the CSIPHY uses the SC8280XP lane register
layout. Add CAMSS_8150 to the version enum and to the shared code
paths, then add the per-block clock, regulator, power domain,
interrupt and interconnect resources.

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>
---
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     |   2 +
 drivers/media/platform/qcom/camss/camss-vfe.c      |   2 +
 drivers/media/platform/qcom/camss/camss.c          | 262 +++++++++++++++++++++
 drivers/media/platform/qcom/camss/camss.h          |   1 +
 4 files changed, 267 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index dac8d2ecf799..851decb0691e 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -1141,6 +1141,7 @@ static bool csiphy_is_gen2(u32 version)
 	case CAMSS_8650:
 	case CAMSS_8775P:
 	case CAMSS_X1E80100:
+	case CAMSS_8150:
 		ret = true;
 		break;
 	}
@@ -1236,6 +1237,7 @@ static int csiphy_init(struct csiphy_device *csiphy)
 		regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8250);
 		break;
 	case CAMSS_8280XP:
+	case CAMSS_8150:
 		regs->lane_regs = &lane_regs_sc8280xp[0];
 		regs->lane_array_size = ARRAY_SIZE(lane_regs_sc8280xp);
 		break;
diff --git a/drivers/media/platform/qcom/camss/camss-vfe.c b/drivers/media/platform/qcom/camss/camss-vfe.c
index 2680a9914765..dd28058e98a7 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe.c
@@ -354,6 +354,7 @@ static u32 vfe_src_pad_code(struct vfe_line *line, u32 sink_code,
 	case CAMSS_8650:
 	case CAMSS_8775P:
 	case CAMSS_X1E80100:
+	case CAMSS_8150:
 		switch (sink_code) {
 		case MEDIA_BUS_FMT_YUYV8_1X16:
 		{
@@ -2010,6 +2011,7 @@ static int vfe_bpl_align_rdi(struct vfe_device *vfe)
 	case CAMSS_8280XP:
 	case CAMSS_8300:
 	case CAMSS_845:
+	case CAMSS_8150:
 	case CAMSS_8550:
 	case CAMSS_8650:
 	case CAMSS_8775P:
diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index c54185c93a8a..7035f5b333ff 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -1940,6 +1940,254 @@ static const struct resources_icc icc_res_sm6350[] = {
 	},
 };
 
+static const struct camss_subdev_resources csiphy_res_sm8150[] = {
+	/* CSIPHY0 */
+	{
+		.regulators = {},
+		.clock = { "csiphy0", "csiphy0_timer" },
+		.clock_rate = { { 400000000 },
+				{ 300000000 } },
+		.reg = { "csiphy0" },
+		.interrupt = { "csiphy0" },
+		.csiphy = {
+			.id = 0,
+			.hw_ops = &csiphy_ops_3ph_1_0,
+			.formats = &csiphy_formats_sdm845
+		}
+	},
+	/* CSIPHY1 */
+	{
+		.regulators = {},
+		.clock = { "csiphy1", "csiphy1_timer" },
+		.clock_rate = { { 400000000 },
+				{ 300000000 } },
+		.reg = { "csiphy1" },
+		.interrupt = { "csiphy1" },
+		.csiphy = {
+			.id = 1,
+			.hw_ops = &csiphy_ops_3ph_1_0,
+			.formats = &csiphy_formats_sdm845
+		}
+	},
+	/* CSIPHY2 */
+	{
+		.regulators = {},
+		.clock = { "csiphy2", "csiphy2_timer" },
+		.clock_rate = { { 400000000 },
+				{ 300000000 } },
+		.reg = { "csiphy2" },
+		.interrupt = { "csiphy2" },
+		.csiphy = {
+			.id = 2,
+			.hw_ops = &csiphy_ops_3ph_1_0,
+			.formats = &csiphy_formats_sdm845
+		}
+	},
+	/* CSIPHY3 */
+	{
+		.regulators = {},
+		.clock = { "csiphy3", "csiphy3_timer" },
+		.clock_rate = { { 400000000 },
+				{ 300000000 } },
+		.reg = { "csiphy3" },
+		.interrupt = { "csiphy3" },
+		.csiphy = {
+			.id = 3,
+			.hw_ops = &csiphy_ops_3ph_1_0,
+			.formats = &csiphy_formats_sdm845
+		}
+	},
+};
+
+static const struct camss_subdev_resources csid_res_sm8150[] = {
+	/* CSID0 */
+	{
+		.regulators = {
+			{ .supply = "vdda-phy", .init_load_uA = 0 },
+			{ .supply = "vdda-pll", .init_load_uA = 0 }
+		},
+		.clock = { "vfe0_csid", "vfe0_cphy_rx", "vfe0", "vfe0_axi" },
+		.clock_rate = { { 400000000, 480000000, 600000000 },
+				{ 0 },
+				{ 0 },
+				{ 0 } },
+		.reg = { "csid0" },
+		.interrupt = { "csid0" },
+		.csid = {
+			.hw_ops = &csid_ops_gen2,
+			.parent_dev_ops = &vfe_parent_dev_ops,
+			.formats = &csid_formats_gen2
+		}
+	},
+	/* CSID1 */
+	{
+		.regulators = {
+			{ .supply = "vdda-phy", .init_load_uA = 0 },
+			{ .supply = "vdda-pll", .init_load_uA = 0 }
+		},
+		.clock = { "vfe1_csid", "vfe1_cphy_rx", "vfe1", "vfe1_axi" },
+		.clock_rate = { { 400000000, 480000000, 600000000 },
+				{ 0 },
+				{ 0 },
+				{ 0 } },
+		.reg = { "csid1" },
+		.interrupt = { "csid1" },
+		.csid = {
+			.hw_ops = &csid_ops_gen2,
+			.parent_dev_ops = &vfe_parent_dev_ops,
+			.formats = &csid_formats_gen2
+		}
+	},
+	/* CSID_LITE0 */
+	{
+		.regulators = {
+			{ .supply = "vdda-phy", .init_load_uA = 0 },
+			{ .supply = "vdda-pll", .init_load_uA = 0 }
+		},
+		.clock = { "vfe_lite0_csid", "vfe_lite0_cphy_rx", "vfe_lite0" },
+		.clock_rate = { { 400000000, 480000000, 600000000 },
+				{ 0 },
+				{ 0 }, },
+		.reg = { "csid_lite0" },
+		.interrupt = { "csid_lite0" },
+		.csid = {
+			.is_lite = true,
+			.hw_ops = &csid_ops_gen2,
+			.parent_dev_ops = &vfe_parent_dev_ops,
+			.formats = &csid_formats_gen2
+		}
+	},
+	/* CSID_LITE1 */
+	{
+		.regulators = {
+			{ .supply = "vdda-phy", .init_load_uA = 0 },
+			{ .supply = "vdda-pll", .init_load_uA = 0 }
+		},
+		.clock = { "vfe_lite1_csid", "vfe_lite1_cphy_rx", "vfe_lite1" },
+		.clock_rate = { { 400000000, 480000000, 600000000 },
+				{ 0 },
+				{ 0 }, },
+		.reg = { "csid_lite1" },
+		.interrupt = { "csid_lite1" },
+		.csid = {
+			.is_lite = true,
+			.hw_ops = &csid_ops_gen2,
+			.parent_dev_ops = &vfe_parent_dev_ops,
+			.formats = &csid_formats_gen2
+		}
+	}
+};
+
+static const struct camss_subdev_resources vfe_res_sm8150[] = {
+	/* VFE0 */
+	{
+		.regulators = {},
+		.clock = { "gcc_axi_hf", "gcc_axi_sf", "cpas_ahb", "camnoc_axi",
+			   "vfe0", "vfe0_axi" },
+		.clock_rate = { { 0 },
+				{ 0 },
+				{ 19200000, 80000000},
+				{ 19200000, 150000000, 266666667, 320000000, 400000000, 480000000 },
+				{ 400000000, 558000000, 637000000, 847000000, 950000000 },
+				{ 0 }, },
+		.reg = { "vfe0" },
+		.interrupt = { "vfe0" },
+		.vfe = {
+			.line_num = 4,
+			.is_lite = false,
+			.has_pd = true,
+			.pd_name = "ife0",
+			.hw_ops = &vfe_ops_170,
+			.formats_rdi = &vfe_formats_rdi_845,
+			.formats_pix = &vfe_formats_pix_845
+		}
+	},
+	/* VFE1 */
+	{
+		.regulators = {},
+		.clock = { "gcc_axi_hf", "gcc_axi_sf", "cpas_ahb", "camnoc_axi",
+			   "vfe1", "vfe1_axi" },
+		.clock_rate = { { 0 },
+				{ 0 },
+				{ 19200000, 80000000},
+				{ 19200000, 150000000, 266666667, 320000000, 400000000, 480000000 },
+				{ 400000000, 558000000, 637000000, 847000000, 950000000 },
+				{ 0 }, },
+		.reg = { "vfe1" },
+		.interrupt = { "vfe1" },
+		.vfe = {
+			.line_num = 4,
+			.is_lite = false,
+			.has_pd = true,
+			.pd_name = "ife1",
+			.hw_ops = &vfe_ops_170,
+			.formats_rdi = &vfe_formats_rdi_845,
+			.formats_pix = &vfe_formats_pix_845
+		}
+	},
+	/* VFE_LITE_0 */
+	{
+		.regulators = {},
+		.clock = { "gcc_axi_hf", "gcc_axi_sf", "cpas_ahb", "camnoc_axi", "vfe_lite0" },
+		.clock_rate = { { 0 },
+				{ 0 },
+				{ 19200000, 80000000},
+				{ 19200000, 150000000, 266666667, 320000000, 400000000, 480000000 },
+				{ 320000000, 400000000, 480000000, 600000000 }, },
+		.reg = { "vfe_lite0" },
+		.interrupt = { "vfe_lite0" },
+		.vfe = {
+			.is_lite = true,
+			.line_num = 4,
+			.hw_ops = &vfe_ops_170,
+			.formats_rdi = &vfe_formats_rdi_845,
+			.formats_pix = &vfe_formats_pix_845
+		}
+	},
+	/* VFE_LITE_1 */
+	{
+		.regulators = {},
+		.clock = { "gcc_axi_hf", "gcc_axi_sf", "cpas_ahb", "camnoc_axi", "vfe_lite1" },
+		.clock_rate = { { 0 },
+				{ 0 },
+				{ 19200000, 80000000},
+				{ 19200000, 150000000, 266666667, 320000000, 400000000, 480000000 },
+				{ 320000000, 400000000, 480000000, 600000000 }, },
+		.reg = { "vfe_lite1" },
+		.interrupt = { "vfe_lite1" },
+		.vfe = {
+			.is_lite = true,
+			.line_num = 4,
+			.hw_ops = &vfe_ops_170,
+			.formats_rdi = &vfe_formats_rdi_845,
+			.formats_pix = &vfe_formats_pix_845
+		}
+	}
+};
+
+static const struct resources_icc icc_res_sm8150[] = {
+	{
+		.name = "cam_ahb",
+		.icc_bw_tbl.avg = 38400,
+		.icc_bw_tbl.peak = 76800,
+	},
+	{
+		.name = "cam_hf_0_mnoc",
+		.icc_bw_tbl.avg = 2097152,
+		.icc_bw_tbl.peak = 2097152,
+	},
+	{
+		.name = "cam_hf_1_mnoc",
+		.icc_bw_tbl.avg = 2097152,
+		.icc_bw_tbl.peak = 2097152,
+	},
+	{
+		.name = "cam_sf_0_mnoc",
+		.icc_bw_tbl.avg = 2097152,
+		.icc_bw_tbl.peak = 2097152,
+	},
+};
+
 static const struct camss_subdev_resources csiphy_res_8250[] = {
 	/* CSIPHY0 */
 	{
@@ -5725,6 +5973,19 @@ static const struct camss_resources sm6350_resources = {
 	.vfe_num = ARRAY_SIZE(vfe_res_sm6350),
 };
 
+static const struct camss_resources sm8150_resources = {
+	.version = CAMSS_8150,
+	.pd_name = "top",
+	.csiphy_res = csiphy_res_sm8150,
+	.csid_res = csid_res_sm8150,
+	.vfe_res = vfe_res_sm8150,
+	.icc_res = icc_res_sm8150,
+	.icc_path_num = ARRAY_SIZE(icc_res_sm8150),
+	.csiphy_num = ARRAY_SIZE(csiphy_res_sm8150),
+	.csid_num = ARRAY_SIZE(csid_res_sm8150),
+	.vfe_num = ARRAY_SIZE(vfe_res_sm8150),
+};
+
 static const struct camss_resources sm8250_resources = {
 	.version = CAMSS_8250,
 	.pd_name = "top",
@@ -5824,6 +6085,7 @@ static const struct of_device_id camss_dt_match[] = {
 	{ .compatible = "qcom,sdm845-camss", .data = &sdm845_resources },
 	{ .compatible = "qcom,sm6150-camss", .data = &sm6150_resources },
 	{ .compatible = "qcom,sm6350-camss", .data = &sm6350_resources },
+	{ .compatible = "qcom,sm8150-camss", .data = &sm8150_resources },
 	{ .compatible = "qcom,sm8250-camss", .data = &sm8250_resources },
 	{ .compatible = "qcom,sm8550-camss", .data = &sm8550_resources },
 	{ .compatible = "qcom,sm8650-camss", .data = &sm8650_resources },
diff --git a/drivers/media/platform/qcom/camss/camss.h b/drivers/media/platform/qcom/camss/camss.h
index 7dc2fd9f03e0..74d8cc2921be 100644
--- a/drivers/media/platform/qcom/camss/camss.h
+++ b/drivers/media/platform/qcom/camss/camss.h
@@ -89,6 +89,7 @@ enum camss_version {
 	CAMSS_8x39,
 	CAMSS_8x53,
 	CAMSS_8x96,
+	CAMSS_8150,
 	CAMSS_8250,
 	CAMSS_8280XP,
 	CAMSS_8300,

-- 
2.56.0

