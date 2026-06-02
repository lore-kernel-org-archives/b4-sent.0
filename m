From: David Heidelberg <david@ixit.cz>
Date: Wed, 03 Jun 2026 01:30:42 +0200
Subject: [PATCH v6 4/8] media: qcom: camss: Initialize lanes after lane
 configuration is available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260603-qcom-cphy-v6-4-e50de0b557a8@ixit.cz>
References: <20260603-qcom-cphy-v6-0-e50de0b557a8@ixit.cz>
In-Reply-To: <20260603-qcom-cphy-v6-0-e50de0b557a8@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 "Dr. Git" <drgitx@gmail.com>, Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6018; i=david@ixit.cz;
 h=from:subject:message-id; bh=24+txQXjEyB9lC+2OldI9aNjjI7Fi2LvMIIxQ/zF9IE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqH2eqV6s+ZIBkjJMtGsSxiXMyVQzmZymYkan53
 CRj2Fqfs3eJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCah9nqgAKCRBgAj/E00kg
 cqQMD/9tWrRrtxvqY5hT09PzCfQoBLlREfROuh5xiJ1Pwecu2GsgJw6X7YPQ5fwX23s8FozgxiS
 qy/XWqvJskGj2DBNWcmaEHkM8gz957wwMYOAB2Bt1plGWzpPpT5k5wuutsay3IqVjrRF4dsrIQu
 X885kgPlbIaIjcgeOgrX+Oqg6CrB99ig5mzEW36rwZOFJSOI9PydDkNoky6WIIVKekshhCVAM4f
 loiXeKyOub80/KVyl49X02nCl0qMWZ8thWA5dpIT4mg8ho++EWltNDa6v8Pz5D34Cn/rO8uGQ4M
 vjuanjjNeCuJpBHVD0DAMqebJ0AM6GHn3K66gFQ05WACyog8KRRfSiGP7c2qnK7wgBlSawGgkDO
 OrhqJ+UIQVPcclfCqlOQ22cq4toY+YSvCvqtUEwI5yeOexXfCBuNIo/TNdyFkUc8jqjYBtp9h0v
 m5REvffY7EoIpRFcW7I+itnQshaDS/OH9M01BJ12InEmhAYsQbWXkK9j6hga55wOMXpFteBaTS2
 N6a26YSLJBX/gFZ71FywwtUmD9L0jOSDcYRQ+GA1FV0BF1ye+FlUxBtkU1ria57kliN0I51hx8n
 skL4WcdBtZsoGiSvsgVRJm3Y2+qCIVX1W/bGMkdTDUp953t/9j1m9+x/y9qosbVijVWGLMss5Dn
 GrWnn1rBtQsOjfQ==
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
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 131 +++++++++++++++------
 1 file changed, 93 insertions(+), 38 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index 15876eb973718..938c365eb352f 100644
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

