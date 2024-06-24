From: George Chan <gchan9527@gmail.com>
Date: Mon, 24 Jun 2024 20:13:15 +0800
Subject: [PATCH RFT v3 4/5] media: qcom: camss: Add sc7180 resources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240624-b4-sc7180-camss-v3-4-89ece6471431@gmail.com>
References: <20240624-b4-sc7180-camss-v3-0-89ece6471431@gmail.com>
In-Reply-To: <20240624-b4-sc7180-camss-v3-0-89ece6471431@gmail.com>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, cros-qcom-dts-watchers@chromium.org, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719231232; l=6912;
 i=gchan9527@gmail.com; s=20240621; h=from:subject:message-id;
 bh=+8YENQxMt00FwdhDAnrxPsB/bJGJg/aEMbwelAZpgaE=;
 b=XNUC0ew7jgY+a/WjeGEYH7S0fevKnPNaSupLMdr6fzAf5rei1jQ8QVc6YCBHuy02cYVsMQ638
 zltz1CfqDndA3WXZShkXGbpVZlRfrX84TeAkp0qU9gv17y5BnA7+VGW
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=Ac2fkTqgUBlj2sns9hRIWJTYhWHO1BsmHbdBb5UpUUY=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20240621 with auth_id=176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit describes the hardware layout for the sc7180 for the
following hardware blocks:

- 2 x VFE
- 1 x VFE Lite
- 2 x CSID
- 1 x CSID Lite
- 4 x CSI PHY

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 drivers/media/platform/qcom/camss/camss.c | 251 ++++++++++++++++++++++++++++++
 1 file changed, 251 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index 1f1f44f6fbb2..9ed810afc048 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -834,6 +834,244 @@ static const struct camss_subdev_resources vfe_res_845[] = {
 	}
 };
 
+static const struct camss_subdev_resources csiphy_res_7180[] = {
+	/* CSIPHY0 */
+	{
+		.regulators = {},
+		.clock = {
+			"csiphy0",
+			 "csiphy0_timer"
+		},
+		.clock_rate = {
+			{ 150000000, 270000000, 360000000 },
+			{ 300000000 },
+		},
+		.reg = { "csiphy0" },
+		.interrupt = { "csiphy0" },
+		.csiphy = {
+			.hw_ops = &csiphy_ops_3ph_1_0,
+			.formats = &csiphy_formats_sdm845
+		}
+	},
+	/* CSIPHY1 */
+	{
+		.regulators = {},
+		.clock = {
+			"csiphy1",
+			"csiphy1_timer"
+		},
+		.clock_rate = {
+			{ 150000000, 270000000, 360000000 },
+			{ 300000000 },
+		},
+		.reg = { "csiphy1" },
+		.interrupt = { "csiphy1" },
+		.csiphy = {
+			.hw_ops = &csiphy_ops_3ph_1_0,
+			.formats = &csiphy_formats_sdm845
+		}
+	},
+	/* CSIPHY2 */
+	{
+		.regulators = {},
+		.clock = {
+			"csiphy2",
+			"csiphy2_timer"
+		},
+		.clock_rate = {
+			{ 150000000, 270000000, 360000000 },
+			{ 300000000 },
+		},
+		.reg = { "csiphy2" },
+		.interrupt = { "csiphy2" },
+		.csiphy = {
+			.hw_ops = &csiphy_ops_3ph_1_0,
+			.formats = &csiphy_formats_sdm845
+		}
+	},
+	/* CSIPHY3 */
+	{
+		.regulators = {},
+		.clock = {
+			"csiphy3",
+			"csiphy3_timer"
+		},
+		.clock_rate = {
+			{ 150000000, 270000000, 360000000 },
+			{ 300000000 },
+		},
+		.reg = { "csiphy3" },
+		.interrupt = { "csiphy3" },
+		.csiphy = {
+			.hw_ops = &csiphy_ops_3ph_1_0,
+			.formats = &csiphy_formats_sdm845
+		}
+	}
+};
+
+static const struct camss_subdev_resources csid_res_7180[] = {
+	/* CSID0 */
+	{
+		.regulators = { "vdda-phy", "vdda-pll" },
+		.clock = {
+			"soc_ahb",
+			"vfe0",
+			"vfe0_cphy_rx",
+			"csi0"
+		},
+		.clock_rate = {
+			{ 0 },
+			{ 240000000, 360000000, 432000000, 600000000 },
+			{ 150000000, 270000000, 360000000 },
+			{ 150000000, 270000000, 360000000, 480000000 },
+		},
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
+		.regulators = { "vdda-phy", "vdda-pll" },
+		.clock = {
+			"soc_ahb",
+			"vfe1",
+			"vfe1_cphy_rx",
+			"csi1",
+		},
+		.clock_rate = {
+			{ 0 },
+			{ 240000000, 360000000, 432000000, 600000000 },
+			{ 150000000, 270000000, 360000000 },
+			{ 150000000, 270000000, 360000000, 480000000 },
+		},
+		.reg = { "csid1" },
+		.interrupt = { "csid1" },
+		.csid = {
+			.hw_ops = &csid_ops_gen2,
+			.parent_dev_ops = &vfe_parent_dev_ops,
+			.formats = &csid_formats_gen2
+		}
+	},
+	/* CSID2 */
+	{
+		.regulators = { "vdda-phy", "vdda-pll" },
+		.clock = {
+			"soc_ahb",
+			"vfe_lite",
+			"vfe_lite_cphy_rx",
+			"csi2",
+		},
+		.clock_rate = {
+			{ 0 },
+			{ 240000000, 360000000, 432000000, 600000000 },
+			{ 150000000, 270000000, 360000000 },
+			{ 150000000, 270000000, 360000000, 480000000 },
+		},
+		.reg = { "csid2" },
+		.interrupt = { "csid2" },
+		.csid = {
+			.is_lite = true,
+			.hw_ops = &csid_ops_gen2,
+			.parent_dev_ops = &vfe_parent_dev_ops,
+			.formats = &csid_formats_gen2
+		}
+	}
+};
+
+static const struct camss_subdev_resources vfe_res_7180[] = {
+	/* VFE0 */
+	{
+		.regulators = {},
+		.clock = {
+			"camnoc_axi",
+			"cpas_ahb",
+			"soc_ahb",
+			"vfe0",
+			"vfe0_axi",
+			"csi0",
+		},
+		.clock_rate = {
+			{ 0 },
+			{ 0 },
+			{ 0 },
+			{ 19200000, 240000000, 360000000, 432000000, 600000000 },
+			{ 0 },
+			{ 150000000, 270000000, 360000000, 480000000 },
+		},
+		.reg = { "vfe0" },
+		.interrupt = { "vfe0" },
+		.vfe = {
+			.line_num = 4,
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
+		.clock = {
+			"camnoc_axi",
+			"cpas_ahb",
+			"soc_ahb",
+			"vfe1",
+			"vfe1_axi",
+			"csi1",
+		},
+		.clock_rate = {
+			{ 0 },
+			{ 0 },
+			{ 0 },
+			{ 19200000, 240000000, 360000000, 432000000, 600000000 },
+			{ 0 },
+			{ 150000000, 270000000, 360000000, 480000000 },
+		},
+		.reg = { "vfe1" },
+		.interrupt = { "vfe1" },
+		.vfe = {
+			.line_num = 4,
+			.has_pd = true,
+			.pd_name = "ife1",
+			.hw_ops = &vfe_ops_170,
+			.formats_rdi = &vfe_formats_rdi_845,
+			.formats_pix = &vfe_formats_pix_845
+		}
+	},
+	/* VFE-lite */
+	{
+		.regulators = {},
+		.clock = {
+			"camnoc_axi",
+			"cpas_ahb",
+			"soc_ahb",
+			"vfe_lite",
+			"csi2",
+		},
+		.clock_rate = {
+			{ 0 },
+			{ 0 },
+			{ 0 },
+			{ 19200000, 240000000, 360000000, 432000000, 600000000 },
+			{ 150000000, 270000000, 360000000, 480000000 },
+		},
+		.reg = { "vfe_lite" },
+		.interrupt = { "vfe_lite" },
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
 static const struct camss_subdev_resources csiphy_res_8250[] = {
 	/* CSIPHY0 */
 	{
@@ -2411,6 +2649,18 @@ static const struct camss_resources sdm845_resources = {
 	.link_entities = camss_link_entities
 };
 
+static const struct camss_resources sc7180_resources = {
+	.version = CAMSS_7180,
+	.pd_name = "top",
+	.csiphy_res = csiphy_res_7180,
+	.csid_res = csid_res_7180,
+	.vfe_res = vfe_res_7180,
+	.csiphy_num = ARRAY_SIZE(csiphy_res_7180),
+	.csid_num = ARRAY_SIZE(csid_res_7180),
+	.vfe_num = ARRAY_SIZE(vfe_res_7180),
+	.link_entities = camss_link_entities
+};
+
 static const struct camss_resources sm8250_resources = {
 	.version = CAMSS_8250,
 	.pd_name = "top",
@@ -2445,6 +2695,7 @@ static const struct of_device_id camss_dt_match[] = {
 	{ .compatible = "qcom,msm8996-camss", .data = &msm8996_resources },
 	{ .compatible = "qcom,sdm660-camss", .data = &sdm660_resources },
 	{ .compatible = "qcom,sdm845-camss", .data = &sdm845_resources },
+	{ .compatible = "qcom,sc7180-camss", .data = &sc7180_resources },
 	{ .compatible = "qcom,sm8250-camss", .data = &sm8250_resources },
 	{ .compatible = "qcom,sc8280xp-camss", .data = &sc8280xp_resources },
 	{ }

-- 
2.34.1

