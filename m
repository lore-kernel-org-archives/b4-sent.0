From: David Heidelberg <david@ixit.cz>
Date: Fri, 05 Jun 2026 15:14:42 +0200
Subject: [PATCH v7 4/8] media: qcom: camss: Initialize lanes after lane
 configuration is available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-qcom-cphy-v7-4-426c37e9008f@ixit.cz>
References: <20260605-qcom-cphy-v7-0-426c37e9008f@ixit.cz>
In-Reply-To: <20260605-qcom-cphy-v7-0-426c37e9008f@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 "Dr. Git" <drgitx@gmail.com>, Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Frank Li <Frank.Li@nxp.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6060; i=david@ixit.cz;
 h=from:subject:message-id; bh=DuKX1oNfR8y3OMNQXdywJD7AgjuKHAViX5JlE8vDsfY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqIsvCgCJC3yL9/K5cZeg/SiUsk+Z6+amT/A89e
 B3eoqBiReiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaiLLwgAKCRBgAj/E00kg
 cljmD/9j5rAl6uqQbG0Uk9dv/YJZMUsRUYoXcFEkVmixARShoie+URorkdRIY4T0GqFKDry0qgR
 Vt70IIh5tzBGs2BRcQZzTS89sv4JLMODKKJWhIsXKh5TzGR2WyAlhpvcnopgaVm3RetrOtidL3I
 k3A7cUr1UUgG28YDyNVM+KLDqzE0EyUf3rW6RboK9tQPfVWi1W8DKd6+Fn7IrGfeUcEBi7ZHTMW
 w7ek4R8uTV6ezm4agIU2eUCHH4LHTcWc39UtWRvnaQ0Hiwc9jFpLqhcXBUCD/B5wocJ6K1tbjkM
 elcumWpuViKpd16ThNR0cMbTkacz7/cb2liafmNaFGEw7zgh9YhztV7YtKzblkBlOK/jo+blMKS
 wRXWi4zxE04Ba1vabgt1nca1DtdrDC6zRsTv607Xgwajrr13WL4aW71XY320Sip+08U6QLKwswn
 SjdW+N3wBgTxtf881yrunNpQfBmqECZzgEgielmDkZrq3RXunrYm0HwyRzjmC0SV2/Bay+svOUa
 HLAgEfACbAkFSUZ3QdoGL1WmGuimcDLLoy5VIZtkDoMv/wQ3ttPD7cg5ZChPp6iUYE8sClhaNsv
 QIOtr8oq03GHkQOVkGNAY6+v/ytoIhFK8DDLUr/v7/+dpa4f1gAxDvtq7bCAq/STBSrtqDHA7CT
 MBppX68jitgydzQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The lanes must not be initialized before the driver has access to
the lane configuration, as it depends on whether D-PHY or C-PHY mode
is in use. Move the lane initialization to csiphy_lanes_enable which is
called when the configuration structures are available.

Co-developed-by: Petr Hodina <phodina@protonmail.com>
Signed-off-by: Petr Hodina <phodina@protonmail.com>
Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Acked-by: Cory Keitz <ckeitz@amazon.com>
Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 131 +++++++++++++++------
 1 file changed, 93 insertions(+), 38 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index fa24fc9706748..c76b9c352ea02 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -1163,16 +1163,108 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 				s64 link_freq, u8 lane_mask)
 {
 	struct csiphy_lanes_cfg *c = &cfg->csi2->lane_cfg;
 	struct csiphy_device_regs *regs = csiphy->regs;
 	u8 settle_cnt;
 	u8 val;
 	int i;
 
+	switch (csiphy->camss->res->version) {
+	case CAMSS_845:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		} else {
+			regs->lane_regs = &lane_regs_sdm845[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sdm845);
+		}
+		break;
+	case CAMSS_2290:
+	case CAMSS_6150:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		} else {
+			regs->lane_regs = &lane_regs_qcm2290[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_qcm2290);
+		}
+		break;
+	case CAMSS_6350:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		} else {
+			regs->lane_regs = &lane_regs_sm6350[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm6350);
+		}
+		break;
+	case CAMSS_7280:
+	case CAMSS_8250:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		} else {
+			regs->lane_regs = &lane_regs_sm8250[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8250);
+		}
+		break;
+	case CAMSS_8280XP:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		} else {
+			regs->lane_regs = &lane_regs_sc8280xp[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sc8280xp);
+		}
+		break;
+	case CAMSS_X1E80100:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		} else {
+			regs->lane_regs = &lane_regs_x1e80100[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_x1e80100);
+		}
+		break;
+	case CAMSS_8550:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		} else {
+			regs->lane_regs = &lane_regs_sm8550[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8550);
+		}
+		break;
+	case CAMSS_8650:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		} else {
+			regs->lane_regs = &lane_regs_sm8650[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8650);
+		}
+		break;
+	case CAMSS_8300:
+	case CAMSS_8775P:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		} else {
+			regs->lane_regs = &lane_regs_sa8775p[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sa8775p);
+		}
+		break;
+	default:
+		break;
+	}
+
+	if (!regs->lane_regs && c->phy_cfg == V4L2_MBUS_CSI2_CPHY)
+		WARN_ONCE(1, "Missing lane_regs definition for C-PHY!\n");
+
 	settle_cnt = csiphy_settle_cnt_calc(link_freq, csiphy->timer_clk_rate);
 
 	val = 0;
 
 	switch (c->phy_cfg) {
 	case V4L2_MBUS_CSI2_CPHY:
 		for (i = 0; i < c->num_data; i++)
 			val |= BIT((c->data[i].pos * 2) + 1);
@@ -1231,63 +1323,26 @@ static int csiphy_init(struct csiphy_device *csiphy)
 	struct device *dev = csiphy->camss->dev;
 	struct csiphy_device_regs *regs;
 
 	regs = devm_kmalloc(dev, sizeof(*regs), GFP_KERNEL);
 	if (!regs)
 		return -ENOMEM;
 
 	csiphy->regs = regs;
-	regs->offset = 0x800;
 	regs->common_status_offset = 0xb0;
 
 	switch (csiphy->camss->res->version) {
-	case CAMSS_845:
-		regs->lane_regs = &lane_regs_sdm845[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sdm845);
-		break;
-	case CAMSS_2290:
-	case CAMSS_6150:
-		regs->lane_regs = &lane_regs_qcm2290[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_qcm2290);
-		break;
-	case CAMSS_6350:
-		regs->lane_regs = &lane_regs_sm6350[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sm6350);
-		break;
-	case CAMSS_7280:
-	case CAMSS_8250:
-		regs->lane_regs = &lane_regs_sm8250[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8250);
-		break;
-	case CAMSS_8280XP:
-		regs->lane_regs = &lane_regs_sc8280xp[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sc8280xp);
-		break;
 	case CAMSS_X1E80100:
-		regs->lane_regs = &lane_regs_x1e80100[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_x1e80100);
-		regs->offset = 0x1000;
-		break;
 	case CAMSS_8550:
-		regs->lane_regs = &lane_regs_sm8550[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8550);
-		regs->offset = 0x1000;
-		break;
 	case CAMSS_8650:
-		regs->lane_regs = &lane_regs_sm8650[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8650);
 		regs->offset = 0x1000;
 		break;
-	case CAMSS_8300:
-	case CAMSS_8775P:
-		regs->lane_regs = &lane_regs_sa8775p[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sa8775p);
-		break;
 	default:
+		regs->offset = 0x800;
 		break;
 	}
 
 	return 0;
 }
 
 const struct csiphy_hw_ops csiphy_ops_3ph_1_0 = {
 	.get_lane_mask = csiphy_get_lane_mask,

-- 
2.53.0

