From: David Heidelberg <david@ixit.cz>
Date: Fri, 05 Jun 2026 15:14:43 +0200
Subject: [PATCH v7 5/8] media: qcom: camss: csiphy-3ph: Add Gen2 v1.1 MIPI
 CSI-2 C-PHY init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-qcom-cphy-v7-5-426c37e9008f@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=8232; i=david@ixit.cz;
 h=from:subject:message-id; bh=NeGmnBkhZ68soS2dAMTGfqfmfG9QUzfl7mYceAqvo/k=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqIsvC3naZSok2E8DGgSqGaK23MiBOh/2dsLphu
 YdQMqKBq/OJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaiLLwgAKCRBgAj/E00kg
 cgTCEAC9pF7IgU87ZqphDq4x2a0wGL3VRiB/XVrkdIGZZXGkOEWcVV3eDPBtKuyBtL82zHnJ4mh
 HkuIdVWn/PSaokFiMly2y6dZ0odN/tyuJzJXFasB2O8O3WBt6oBLZAiGgjKSVZN0XoPymHZ55A0
 bmRWOVwoqwGUxhWkphKC6yZqqVL/aaTDa94HhLoUa3K6/2c0W1QVEeeBP/Jpw46jsUipSlJrutB
 gAu/85Z8FeHZW2vVKGxuPhUxiX8KGPcmPAkK8oc+vhpE6Fw8v9bpNu1YaohW5w7X0UdPgmQabbw
 3p9RxmBm3rNAYTRGl40iTMEyW7sSpbiHOYTvl0mDciIFKMjATPQbaAN1NbC7Op3TXM6J+ZNYwTF
 Xd6ohKLLFmQ46oUUERgW+Bd2FBd4J/d1Y1gUDxq5eClsDGdgf20BwmUCun9IoC+nN7A8fFuYrP8
 IVgCs+LRUXFuaw3IYUhkWnGDafXgxFVzS6ORVLXdAvUEtiKzZZs49Yg2G17d58V/nCZ1wL56DJM
 Q86ongHLlzSM/Rv3rTe3AOY556AHW9WJPBRIoz8y2HVjsvpAGFLNfLH1hO8IzN0ctousBSrMhTo
 DpsywL4YJyoWDOBr2TsLk+u0KIDjRxL+5jl1gNavQ3widvzD5KkVaxOPogyUZZu63iNY/DvMzU5
 hNUw9qlb07I6UHg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a PHY configuration sequence for the sdm845 which uses a Qualcomm
Gen 2 version 1.1 CSI-2 PHY.

The PHY can be configured as two phase or three phase in C-PHY or D-PHY
mode. This configuration supports three-phase C-PHY mode.

Acked-by: Cory Keitz <ckeitz@amazon.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 78 +++++++++++++++++++++-
 1 file changed, 76 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index c76b9c352ea02..d9136e422f45f 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -45,16 +45,23 @@
 
 #define CSIPHY_3PH_CMN_CSI_COMMON_CTRLn(offset, n)	((offset) + 0x4 * (n))
 #define CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE	BIT(7)
 #define CSIPHY_3PH_CMN_CSI_COMMON_CTRL6_COMMON_PWRDN_B	BIT(0)
 #define CSIPHY_3PH_CMN_CSI_COMMON_CTRL6_SHOW_REV_ID	BIT(1)
 #define CSIPHY_3PH_CMN_CSI_COMMON_STATUSn(offset, common_status_offset, n) \
 	((offset) + (common_status_offset) + 0x4 * (n))
 
+#define CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(n) \
+	(0x0100 + ((n) * 0x4))
+#define CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(n) \
+	(0x0300 + ((n) * 0x4))
+#define CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(n) \
+	(0x0500 + ((n) * 0x4))
+
 #define CSIPHY_DEFAULT_PARAMS		0
 #define CSIPHY_LANE_ENABLE		1
 #define CSIPHY_SETTLE_CNT_LOWER_BYTE	2
 #define CSIPHY_SETTLE_CNT_HIGHER_BYTE	3
 #define CSIPHY_DNP_PARAMS		4
 #define CSIPHY_2PH_REGS			5
 #define CSIPHY_3PH_REGS			6
 #define CSIPHY_SKEW_CAL			7
@@ -141,16 +148,17 @@ csiphy_lane_regs lane_regs_sa8775p[] = {
 	{0x0460, 0xFD, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0464, 0x7F, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x065C, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0660, 0xFD, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0664, 0x7F, 0x00, CSIPHY_DEFAULT_PARAMS},
 };
 
 /* GEN2 1.0 2PH */
+/* 5 entries: clock + 4 lanes */
 static const struct
 csiphy_lane_regs lane_regs_sdm845[] = {
 	{0x0004, 0x0C, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x002C, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0034, 0x0F, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x001C, 0x0A, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0014, 0x60, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0028, 0x00, 0x00, CSIPHY_DNP_PARAMS},
@@ -215,16 +223,82 @@ csiphy_lane_regs lane_regs_sdm845[] = {
 	{0x0608, 0x00, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
 	{0x060C, 0x00, 0x00, CSIPHY_DNP_PARAMS},
 	{0x0610, 0x52, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0638, 0xFE, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0660, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0664, 0x7F, 0x00, CSIPHY_DEFAULT_PARAMS},
 };
 
+/* GEN2 1.0 3PH */
+/* 3 entries: 3 lanes (C-PHY) */
+static const struct
+csiphy_lane_regs lane_regs_sdm845_3ph[] = {
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(23), 0x43, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(26), 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(27), 0x25, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(1),  0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(3),  0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(2),  0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(5),  0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(20), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(6),  0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(7),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(8),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(9),  0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(10), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(11), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(17), 0x12, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(24), 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(51), 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(25), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(55), 0x51, 0x00, CSIPHY_DEFAULT_PARAMS},
+
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(23), 0x43, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(26), 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(27), 0x25, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(1),  0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(3),  0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(2),  0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(5),  0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(20), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(6),  0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(7),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(8),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(9),  0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(10), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(11), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(17), 0x12, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(24), 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(51), 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(25), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(55), 0x51, 0x00, CSIPHY_DEFAULT_PARAMS},
+
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(23), 0x43, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(26), 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(27), 0x25, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(1),  0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(3),  0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(2),  0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(5),  0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(20), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(6),  0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(7),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(8),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(9),  0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(10), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(11), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(17), 0x12, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(24), 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(51), 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(25), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(55), 0x51, 0x00, CSIPHY_DEFAULT_PARAMS},
+
+};
+
 /* GEN2 1.1 2PH */
 static const struct
 csiphy_lane_regs lane_regs_sc8280xp[] = {
 	{0x0004, 0x0C, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x002C, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0034, 0x0F, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x001C, 0x0A, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0014, 0x60, 0x00, CSIPHY_DEFAULT_PARAMS},
@@ -1166,18 +1240,18 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 	struct csiphy_device_regs *regs = csiphy->regs;
 	u8 settle_cnt;
 	u8 val;
 	int i;
 
 	switch (csiphy->camss->res->version) {
 	case CAMSS_845:
 		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
-			regs->lane_regs = NULL;
-			regs->lane_array_size = 0;
+			regs->lane_regs = &lane_regs_sdm845_3ph[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sdm845_3ph);
 		} else {
 			regs->lane_regs = &lane_regs_sdm845[0];
 			regs->lane_array_size = ARRAY_SIZE(lane_regs_sdm845);
 		}
 		break;
 	case CAMSS_2290:
 	case CAMSS_6150:
 		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {

-- 
2.53.0

