From: David Heidelberg <david@ixit.cz>
Date: Wed, 10 Jun 2026 20:28:25 +0200
Subject: [PATCH v8 5/9] media: qcom: camss: Initialize lanes after lane
 configuration is available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-qcom-cphy-v8-5-cd4387785179@ixit.cz>
References: <20260610-qcom-cphy-v8-0-cd4387785179@ixit.cz>
In-Reply-To: <20260610-qcom-cphy-v8-0-cd4387785179@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 "Dr. Git" <drgitx@gmail.com>, Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Nihal Kumar Gupta <nihal.gupta@oss.qualcomm.com>
Cc: Frank Li <Frank.Li@nxp.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6446; i=david@ixit.cz;
 h=from:subject:message-id; bh=g/o3rVD1r6gJeV04eBIyOcKsTC0b/LLqeKtjGiZ/dKQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqKazHRlNWfHKH2CuOLPnY54+Ri366QxPUKxh3v
 vV7Vjel8CqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaimsxwAKCRBgAj/E00kg
 cmdzD/9YJj//xkw6XepXz1MYhPeIJvQOzug+1jXfOzmvxCosBsvElvqHLTAwqgNiFhJxBJe4mWk
 SLKmPmMaWwKpmAJBo25NtIHG4pbSHtBKGTD20Mnz37LDbzxVyvy7UnSS1v56nBZzNXid9KvpSA9
 8B7ZAjcMddUQoe/ACXpCXh+tKb6Z5/35BkIm5YMHXeTTxRXQgKtGrhErsU4jYxvqmUgFPqngLw5
 yY0Kh25GoKLWh/KRy/BZLMa9p/MqXv+wsjYYfqju0m26PDrVn5mmGvxpPfXPpptB7DbsPjtMyvN
 r3AHgy0OT2wMozRq6Mw4Y7zFJOXH2uspyIkPsrK+KRuoU1gRMBjpmS+ye9hLPTcsTj1GDXWq61Z
 sOQAcSz6T1l7T362ANT6nlh/HU6lRA5swyEjrhz4PAEq5sZJEOyp+Yf6k/3HBHnjK6/BFbxuIB+
 TWT28K+jCVfK8Gx0ZmQSfN00rsWP5we+a+kLIN6UH6+vTK/UKLDFU0pe+md+Bqu24d/uA1qI4s9
 eCFmCxmE6mRBb0NQtr5dF+U1RugV1cT7bQHbQYDeHVgX915dNIF+MNuwcOS8xSRRU9jBV0ETyxh
 OT75m+8dGQjaV6mKtpG/uELXp3iYvUsPsa7O59EJXaaVV9PkjMxNBG4buBg9V4TZlciDwlVQdbM
 W/nxsKgprv/qb1g==
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
index dfcd9ed2eb7a3..5c07aa9d19c51 100644
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
+		if (c->phy_cfg == V4L2_MBUS_CSI2_DPHY) {
+			regs->lane_regs = &lane_regs_sdm845[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sdm845);
+		} else if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		}
+		break;
+	case CAMSS_2290:
+	case CAMSS_6150:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_DPHY) {
+			regs->lane_regs = &lane_regs_qcm2290[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_qcm2290);
+		} else if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		}
+		break;
+	case CAMSS_6350:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_DPHY) {
+			regs->lane_regs = &lane_regs_sm6350[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm6350);
+		} else if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		}
+		break;
+	case CAMSS_7280:
+	case CAMSS_8250:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_DPHY) {
+			regs->lane_regs = &lane_regs_sm8250[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8250);
+		} else if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		}
+		break;
+	case CAMSS_8280XP:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_DPHY) {
+			regs->lane_regs = &lane_regs_sc8280xp[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sc8280xp);
+		} else if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		}
+		break;
+	case CAMSS_X1E80100:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_DPHY) {
+			regs->lane_regs = &lane_regs_x1e80100[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_x1e80100);
+		} else if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		}
+		break;
+	case CAMSS_8550:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_DPHY) {
+			regs->lane_regs = &lane_regs_sm8550[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8550);
+		} else if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		}
+		break;
+	case CAMSS_8650:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_DPHY) {
+			regs->lane_regs = &lane_regs_sm8650[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8650);
+		} else if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		}
+		break;
+	case CAMSS_8300:
+	case CAMSS_8775P:
+		if (c->phy_cfg == V4L2_MBUS_CSI2_DPHY) {
+			regs->lane_regs = &lane_regs_sa8775p[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sa8775p);
+		} else if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = NULL;
+			regs->lane_array_size = 0;
+		}
+		break;
+	default:
+		break;
+	}
+
+	if (!regs->lane_regs)
+		WARN_ONCE(1, "Missing lane_regs definition!\n");
+
 	settle_cnt = csiphy_settle_cnt_calc(link_freq, csiphy->timer_clk_rate);
 
 	val = csiphy_get_lane_mask(c);
 	writel_relaxed(val, csiphy->base +
 		       CSIPHY_3PH_CMN_CSI_COMMON_CTRLn(regs->offset, 5));
 
 	val = CSIPHY_3PH_CMN_CSI_COMMON_CTRL6_COMMON_PWRDN_B;
 	writel_relaxed(val, csiphy->base +
@@ -1215,63 +1307,26 @@ static int csiphy_init(struct csiphy_device *csiphy)
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

