From: Vincent Knecht <vincent.knecht@mailoo.org>
Date: Sun, 25 May 2025 21:25:02 +0200
Subject: [PATCH v2 2/4] media: qcom: camss: Add support for MSM8939
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250525-camss-8x39-vbif-v2-2-6d3d5c5af456@mailoo.org>
References: <20250525-camss-8x39-vbif-v2-0-6d3d5c5af456@mailoo.org>
In-Reply-To: <20250525-camss-8x39-vbif-v2-0-6d3d5c5af456@mailoo.org>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Vincent Knecht <vincent.knecht@mailoo.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748201103; l=10640;
 i=vincent.knecht@mailoo.org; s=20250414; h=from:subject:message-id;
 bh=jbH/Tk3iZ/KQ/Qiij4iLe3xjaFaj87pxQYwOH/s8V1k=;
 b=Ex7M+g1p3/wJj38HMcZMFCHR347hkCI/hzhDQihRP4WuZsKH4dRDwU1qLfmSurvS/lAuATNqY
 pEfKfxFy7XVAj4O398/+mW8umGLCvdxLZEiCesrveEd+d0Wz0u0ET0s
X-Developer-Key: i=vincent.knecht@mailoo.org; a=ed25519;
 pk=MFCVQkhL3+d3NHDzNPWpyZ4isxJvT+QTqValj5gSkm4=
X-Endpoint-Received: by B4 Relay for vincent.knecht@mailoo.org/20250414 with auth_id=377
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The camera subsystem for the MSM8939 is the same as MSM8916 except with
3 CSID instead of 2, and some higher clock rates.

As a quirk, this SoC needs writing values to 2 VFE VBIF registers
(see downstream msm8939-camera.dtsi vbif-{regs,settings} properties).
This fixes black stripes across sensor and garbage in CSID TPG outputs.

Add support for the MSM8939 camera subsystem.

Signed-off-by: Vincent Knecht <vincent.knecht@mailoo.org>
---
 drivers/media/platform/qcom/camss/camss-csiphy.c   |   1 +
 drivers/media/platform/qcom/camss/camss-ispif.c    |   8 +-
 drivers/media/platform/qcom/camss/camss-vfe-vbif.c |   7 +
 drivers/media/platform/qcom/camss/camss-vfe.c      |   1 +
 drivers/media/platform/qcom/camss/camss.c          | 157 +++++++++++++++++++++
 drivers/media/platform/qcom/camss/camss.h          |   1 +
 6 files changed, 173 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.c b/drivers/media/platform/qcom/camss/camss-csiphy.c
index c622efcc92ff3781d7fc3ace0253c2d64c91e847..6311fc2975aa1345e430a477c8a6476f1d7e5663 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.c
@@ -605,6 +605,7 @@ int msm_csiphy_subdev_init(struct camss *camss,
 		return PTR_ERR(csiphy->base);
 
 	if (camss->res->version == CAMSS_8x16 ||
+	    camss->res->version == CAMSS_8x39 ||
 	    camss->res->version == CAMSS_8x53 ||
 	    camss->res->version == CAMSS_8x96) {
 		csiphy->base_clk_mux =
diff --git a/drivers/media/platform/qcom/camss/camss-ispif.c b/drivers/media/platform/qcom/camss/camss-ispif.c
index 2dc585c6123dd248a5bacd9c7a88cb5375644311..aaf3caa42d33dcb641651e7f5bc0c2a564d85bfa 100644
--- a/drivers/media/platform/qcom/camss/camss-ispif.c
+++ b/drivers/media/platform/qcom/camss/camss-ispif.c
@@ -1112,6 +1112,8 @@ int msm_ispif_subdev_init(struct camss *camss,
 	/* Number of ISPIF lines - same as number of CSID hardware modules */
 	if (camss->res->version == CAMSS_8x16)
 		ispif->line_num = 2;
+	else if (camss->res->version == CAMSS_8x39)
+		ispif->line_num = 3;
 	else if (camss->res->version == CAMSS_8x96 ||
 		 camss->res->version == CAMSS_8x53 ||
 		 camss->res->version == CAMSS_660)
@@ -1128,7 +1130,8 @@ int msm_ispif_subdev_init(struct camss *camss,
 		ispif->line[i].ispif = ispif;
 		ispif->line[i].id = i;
 
-		if (camss->res->version == CAMSS_8x16) {
+		if (camss->res->version == CAMSS_8x16 ||
+		    camss->res->version == CAMSS_8x39) {
 			ispif->line[i].formats = ispif_formats_8x16;
 			ispif->line[i].nformats =
 					ARRAY_SIZE(ispif_formats_8x16);
@@ -1162,7 +1165,8 @@ int msm_ispif_subdev_init(struct camss *camss,
 	ispif->irq = ret;
 	snprintf(ispif->irq_name, sizeof(ispif->irq_name), "%s_%s",
 		 dev_name(dev), MSM_ISPIF_NAME);
-	if (camss->res->version == CAMSS_8x16)
+	if (camss->res->version == CAMSS_8x16 ||
+	    camss->res->version == CAMSS_8x39)
 		ret = devm_request_irq(dev, ispif->irq, ispif_isr_8x16,
 			       IRQF_TRIGGER_RISING, ispif->irq_name, ispif);
 	else if (camss->res->version == CAMSS_8x96 ||
diff --git a/drivers/media/platform/qcom/camss/camss-vfe-vbif.c b/drivers/media/platform/qcom/camss/camss-vfe-vbif.c
index 2ae61b7baa148f0ad63fe3b8751aeb7b8fc12d81..d461880e5379c21746b5b191910becdbab36d3f5 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe-vbif.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe-vbif.c
@@ -14,6 +14,9 @@
 #include "camss-vfe.h"
 #include "camss-vfe-vbif.h"
 
+#define VBIF_FIXED_SORT_EN	0x30
+#define VBIF_FIXED_SORT_SEL0	0x34
+
 void vfe_vbif_reg_write(struct vfe_device *vfe, u32 reg, u32 val)
 {
 	writel_relaxed(val, vfe->vbif_base + reg);
@@ -22,6 +25,10 @@ void vfe_vbif_reg_write(struct vfe_device *vfe, u32 reg, u32 val)
 int vfe_vbif_apply_settings(struct vfe_device *vfe)
 {
 	switch (vfe->camss->res->version) {
+	case CAMSS_8x39:
+		vfe_vbif_reg_write(vfe, VBIF_FIXED_SORT_EN, 0xfff);
+		vfe_vbif_reg_write(vfe, VBIF_FIXED_SORT_SEL0, 0x555000);
+		break;
 	default:
 		break;
 	}
diff --git a/drivers/media/platform/qcom/camss/camss-vfe.c b/drivers/media/platform/qcom/camss/camss-vfe.c
index 3138562d399444c5cf2ae96bf16b75b85ff5c5ca..ac3a9579e3e6910eee8c1ec11c4fff6e1bc94443 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe.c
@@ -290,6 +290,7 @@ static u32 vfe_src_pad_code(struct vfe_line *line, u32 sink_code,
 
 	switch (vfe->camss->res->version) {
 	case CAMSS_8x16:
+	case CAMSS_8x39:
 	case CAMSS_8x53:
 		switch (sink_code) {
 		case MEDIA_BUS_FMT_YUYV8_1X16:
diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index 06f42875702f02f9d8d83d06ddaa972eacb593f8..6a68876a00a8d6eaf3ef55e8fde0d266f567879a 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -154,6 +154,149 @@ static const struct camss_subdev_resources vfe_res_8x16[] = {
 	}
 };
 
+static const struct camss_subdev_resources csiphy_res_8x39[] = {
+	/* CSIPHY0 */
+	{
+		.regulators = { "vdda" },
+		.clock = { "top_ahb", "ispif_ahb", "ahb", "csiphy0_timer" },
+		.clock_rate = { { 0 },
+				{ 40000000, 80000000 },
+				{ 0 },
+				{ 100000000, 200000000 } },
+		.reg = { "csiphy0", "csiphy0_clk_mux" },
+		.interrupt = { "csiphy0" },
+		.csiphy = {
+			.id = 0,
+			.hw_ops = &csiphy_ops_2ph_1_0,
+			.formats = &csiphy_formats_8x16
+		}
+	},
+
+	/* CSIPHY1 */
+	{
+		.regulators = { "vdda" },
+		.clock = { "top_ahb", "ispif_ahb", "ahb", "csiphy1_timer" },
+		.clock_rate = { { 0 },
+				{ 40000000, 80000000 },
+				{ 0 },
+				{ 100000000, 200000000 } },
+		.reg = { "csiphy1", "csiphy1_clk_mux" },
+		.interrupt = { "csiphy1" },
+		.csiphy = {
+			.id = 1,
+			.hw_ops = &csiphy_ops_2ph_1_0,
+			.formats = &csiphy_formats_8x16
+		}
+	}
+};
+
+static const struct camss_subdev_resources csid_res_8x39[] = {
+	/* CSID0 */
+	{
+		.regulators = {},
+		.clock = { "top_ahb", "ispif_ahb", "csi0_ahb", "ahb",
+			   "csi0", "csi0_phy", "csi0_pix", "csi0_rdi" },
+		.clock_rate = { { 0 },
+				{ 40000000, 80000000 },
+				{ 0 },
+				{ 0 },
+				{ 100000000, 200000000 },
+				{ 0 },
+				{ 0 },
+				{ 0 } },
+		.reg = { "csid0" },
+		.interrupt = { "csid0" },
+		.csid = {
+			.hw_ops = &csid_ops_4_1,
+			.parent_dev_ops = &vfe_parent_dev_ops,
+			.formats = &csid_formats_4_1
+		}
+	},
+
+	/* CSID1 */
+	{
+		.regulators = {},
+		.clock = { "top_ahb", "ispif_ahb", "csi1_ahb", "ahb",
+			   "csi1", "csi1_phy", "csi1_pix", "csi1_rdi" },
+		.clock_rate = { { 0 },
+				{ 40000000, 80000000 },
+				{ 0 },
+				{ 0 },
+				{ 100000000, 200000000 },
+				{ 0 },
+				{ 0 },
+				{ 0 } },
+		.reg = { "csid1" },
+		.interrupt = { "csid1" },
+		.csid = {
+			.hw_ops = &csid_ops_4_1,
+			.parent_dev_ops = &vfe_parent_dev_ops,
+			.formats = &csid_formats_4_1
+		}
+	},
+
+	/* CSID2 */
+	{
+		.regulators = {},
+		.clock = { "top_ahb", "ispif_ahb", "csi2_ahb", "ahb",
+			   "csi2", "csi2_phy", "csi2_pix", "csi2_rdi" },
+		.clock_rate = { { 0 },
+				{ 40000000, 80000000 },
+				{ 0 },
+				{ 0 },
+				{ 100000000, 200000000 },
+				{ 0 },
+				{ 0 },
+				{ 0 } },
+		.reg = { "csid2" },
+		.interrupt = { "csid2" },
+		.csid = {
+			.hw_ops = &csid_ops_4_1,
+			.parent_dev_ops = &vfe_parent_dev_ops,
+			.formats = &csid_formats_4_1
+		}
+	},
+};
+
+static const struct camss_subdev_resources ispif_res_8x39 = {
+	/* ISPIF */
+	.clock = { "top_ahb", "ispif_ahb", "ahb",
+		   "csi0", "csi0_pix", "csi0_rdi",
+		   "csi1", "csi1_pix", "csi1_rdi",
+		   "csi2", "csi2_pix", "csi2_rdi" },
+	.clock_for_reset = { "vfe0", "csi_vfe0" },
+	.reg = { "ispif", "csi_clk_mux" },
+	.interrupt = { "ispif" },
+};
+
+static const struct camss_subdev_resources vfe_res_8x39[] = {
+	/* VFE0 */
+	{
+		.regulators = {},
+		.clock = { "top_ahb", "ispif_ahb", "vfe0", "csi_vfe0",
+			   "vfe_ahb", "vfe_axi", "ahb" },
+		.clock_rate = { { 0 },
+				{ 40000000, 80000000 },
+				{ 50000000, 80000000, 100000000, 160000000,
+				  177780000, 200000000, 266670000, 320000000,
+				  400000000, 465000000, 480000000, 600000000 },
+				{ 0 },
+				{ 0 },
+				{ 0 },
+				{ 0 } },
+		.reg = { "vfe0" },
+		.interrupt = { "vfe0" },
+		.vfe = {
+			.line_num = 3,
+			.has_vbif = true,
+			.vbif_name = "vfe0_vbif",
+			.hw_ops = &vfe_ops_4_1,
+			.formats_rdi = &vfe_formats_rdi_8x16,
+			.formats_pix = &vfe_formats_pix_8x16
+		}
+	}
+};
+
 static const struct camss_subdev_resources csid_res_8x53[] = {
 	/* CSID0 */
 	{
@@ -3585,6 +3728,7 @@ static int camss_probe(struct platform_device *pdev)
 		return -ENOMEM;
 
 	if (camss->res->version == CAMSS_8x16 ||
+	    camss->res->version == CAMSS_8x39 ||
 	    camss->res->version == CAMSS_8x53 ||
 	    camss->res->version == CAMSS_8x96) {
 		camss->ispif = devm_kcalloc(dev, 1, sizeof(*camss->ispif), GFP_KERNEL);
@@ -3727,6 +3871,18 @@ static const struct camss_resources msm8916_resources = {
 	.link_entities = camss_link_entities
 };
 
+static const struct camss_resources msm8939_resources = {
+	.version = CAMSS_8x39,
+	.csiphy_res = csiphy_res_8x39,
+	.csid_res = csid_res_8x39,
+	.ispif_res = &ispif_res_8x39,
+	.vfe_res = vfe_res_8x39,
+	.csiphy_num = ARRAY_SIZE(csiphy_res_8x39),
+	.csid_num = ARRAY_SIZE(csid_res_8x39),
+	.vfe_num = ARRAY_SIZE(vfe_res_8x39),
+	.link_entities = camss_link_entities
+};
+
 static const struct camss_resources msm8953_resources = {
 	.version = CAMSS_8x53,
 	.icc_res = icc_res_8x53,
@@ -3863,6 +4019,7 @@ static const struct camss_resources x1e80100_resources = {
 
 static const struct of_device_id camss_dt_match[] = {
 	{ .compatible = "qcom,msm8916-camss", .data = &msm8916_resources },
+	{ .compatible = "qcom,msm8939-camss", .data = &msm8939_resources },
 	{ .compatible = "qcom,msm8953-camss", .data = &msm8953_resources },
 	{ .compatible = "qcom,msm8996-camss", .data = &msm8996_resources },
 	{ .compatible = "qcom,sc7280-camss", .data = &sc7280_resources },
diff --git a/drivers/media/platform/qcom/camss/camss.h b/drivers/media/platform/qcom/camss/camss.h
index 63c0afee154a02194820016ccf554620d6521c8b..be11cf3af478627fa48827e70d5f0673939e1e63 100644
--- a/drivers/media/platform/qcom/camss/camss.h
+++ b/drivers/media/platform/qcom/camss/camss.h
@@ -80,6 +80,7 @@ enum camss_version {
 	CAMSS_660,
 	CAMSS_7280,
 	CAMSS_8x16,
+	CAMSS_8x39,
 	CAMSS_8x53,
 	CAMSS_8x96,
 	CAMSS_8250,

-- 
2.49.0

