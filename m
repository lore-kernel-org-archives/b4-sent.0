From: David Heidelberg <david@ixit.cz>
Date: Wed, 29 Jul 2026 22:19:58 +0200
Subject: [PATCH RESEND v9 3/9] media: qcom: camss: csiphy-3ph: Use odd bits
 for configuring C-PHY lanes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-qcom-cphy-v9-3-1f8d9fdab037@ixit.cz>
References: <20260729-qcom-cphy-v9-0-1f8d9fdab037@ixit.cz>
In-Reply-To: <20260729-qcom-cphy-v9-0-1f8d9fdab037@ixit.cz>
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
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3113; i=david@ixit.cz;
 h=from:subject:message-id; bh=TVUoRIJn5ULvYNpapsB4ZItCc34ZCZTZby6Hd3C8I2o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqamB0Yqcez/mNdnAcduqI4tpOAQ1ejiV2+n9XR
 F/0yqnJKjWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCampgdAAKCRBgAj/E00kg
 cm2/D/9e2x0ckwzqSxpJSi08fBpCJPDxWDexw7MWhp5JULyyT3P4F7QZl39C6ps/IZyXJK1mjmY
 xslQHNNr5rvxgXap2RYrU5r7m01yGhD6eQulYkvOWNDTTMVADNrwA8vscpS18HaWbxzWG7Eq2qQ
 m/cDHI49g4M4m4QZTw1ZCqFDoPj2ZkqQk+RDvor1xsPUvVIF8o19iccPAiHjpT4OvPoz8j+fj94
 cdp2vLCabyGrxuzYSVIgmK23lVAQ4j65Ujorfwdpp1oVUqdsQdPRiFD9ZnxY9rdbqeAh3e79uhk
 +KsRWk1u/f/3hIOKLh2mUlLxUr646DIdaGcS5BIW2Vq1dJwVNv+p8l6Ckvs7Iz1q8aRZxfDOnhX
 PZJLnTCOirjmCjZb+jTBB7OkKR9HAj7/iX+oQnUZfZyu/9XXrbpDJKlUPGoLcYhS+oWAtERmFu5
 IAXU4F8i1pgcx387VE/+UN6UKzAxYX2oquGJHJjnOgqPb7DSJIXQdEkJe9HI8oF8L8fl2IPQEhS
 K1ZHli7e40bZBj037ONzF9I4zsBayHtBWHAwPKCxD+5ZOkMNf/t7109vemvyAo5i1/+cHaG65S5
 iMCQ5v2PEiYAjLqJ8sKDg+R2rNHkB5D4c+pA5sg0CT/X+NDnK9vsN9MWF5/L2FYcuMzY0t4o8gc
 nfwMYNl/WZjzzqw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

So far, only D-PHY mode was supported, which uses even bits when enabling
or masking lanes. For C-PHY configuration, the hardware instead requires
using the odd bits.

Since there can be unrecognized configuration allow returning failure.

Acked-by: Cory Keitz <ckeitz@amazon.com>
Reviewed-by: Bryan O'Donoghue <bod@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 25 ++++++++++++++--------
 1 file changed, 16 insertions(+), 9 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index 7c8c0e41bc62f..dfcd9ed2eb7a3 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -9,16 +9,17 @@
  */
 
 #include "camss.h"
 #include "camss-csiphy.h"
 
 #include <linux/delay.h>
 #include <linux/interrupt.h>
 #include <linux/io.h>
+#include <linux/media-bus-format.h>
 
 #define CSIPHY_3PH_LNn_CFG1(n)			(0x000 + 0x100 * (n))
 #define CSIPHY_3PH_LNn_CFG1_SWI_REC_DLY_PRG	(BIT(7) | BIT(6))
 #define CSIPHY_3PH_LNn_CFG2(n)			(0x004 + 0x100 * (n))
 #define CSIPHY_3PH_LNn_CFG2_LP_REC_EN_INT	BIT(3)
 #define CSIPHY_3PH_LNn_CFG3(n)			(0x008 + 0x100 * (n))
 #define CSIPHY_3PH_LNn_CFG4(n)			(0x00c + 0x100 * (n))
 #define CSIPHY_3PH_LNn_CFG4_T_HS_CLK_MISS	0xa4
@@ -1108,23 +1109,32 @@ static void csiphy_gen2_config_lanes(struct csiphy_device *csiphy,
 		writel_relaxed(val, csiphy->base + r->reg_addr);
 		if (r->delay_us)
 			udelay(r->delay_us);
 	}
 }
 
 static u8 csiphy_get_lane_mask(struct csiphy_lanes_cfg *lane_cfg)
 {
-	u8 lane_mask;
-	int i;
+	u8 lane_mask = 0;
+	u8 offset = 0;
 
-	lane_mask = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
+	switch (lane_cfg->phy_cfg) {
+	case V4L2_MBUS_CSI2_CPHY:
+		offset = 1;
+		break;
+	case V4L2_MBUS_CSI2_DPHY:
+		lane_mask = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
+		break;
+	default:
+		break;
+	}
 
-	for (i = 0; i < lane_cfg->num_data; i++)
-		lane_mask |= BIT(lane_cfg->data[i].pos * 2);
+	for (int i = 0; i < lane_cfg->num_data; i++)
+		lane_mask |= BIT((lane_cfg->data[i].pos * 2) + offset);
 
 	return lane_mask;
 }
 
 static bool csiphy_is_gen2(u32 version)
 {
 	bool ret = false;
 
@@ -1155,20 +1165,17 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 	struct csiphy_lanes_cfg *c = &cfg->csi2->lane_cfg;
 	struct csiphy_device_regs *regs = csiphy->regs;
 	u8 settle_cnt;
 	u8 val;
 	int i;
 
 	settle_cnt = csiphy_settle_cnt_calc(link_freq, csiphy->timer_clk_rate);
 
-	val = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
-	for (i = 0; i < c->num_data; i++)
-		val |= BIT(c->data[i].pos * 2);
-
+	val = csiphy_get_lane_mask(c);
 	writel_relaxed(val, csiphy->base +
 		       CSIPHY_3PH_CMN_CSI_COMMON_CTRLn(regs->offset, 5));
 
 	val = CSIPHY_3PH_CMN_CSI_COMMON_CTRL6_COMMON_PWRDN_B;
 	writel_relaxed(val, csiphy->base +
 		       CSIPHY_3PH_CMN_CSI_COMMON_CTRLn(regs->offset, 6));
 
 	val = 0x02;

-- 
2.53.0

