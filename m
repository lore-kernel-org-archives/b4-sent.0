From: David Heidelberg <david@ixit.cz>
Date: Wed, 29 Jul 2026 22:19:56 +0200
Subject: [PATCH RESEND v9 1/9] media: qcom: camss: csiphy-3ph: Fix lane
 mask calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-qcom-cphy-v9-1-1f8d9fdab037@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1187; i=david@ixit.cz;
 h=from:subject:message-id; bh=4gZLnNPEAXXeOriBAOpQ0RLijJCSPBaruO2JK2La25Y=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqamB0D/WEwBLCTjLj8KeBnVkmz70gKtjM+vX5r
 RH9WRRTRUSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCampgdAAKCRBgAj/E00kg
 ctcuEADJTLBzW99W5nyfBGx+t44Y8VhURBxCKlTzKZkxgbLt5NkzPvIi6k+LQCiQtbR4KE1BRH6
 +uTClKFxsyUslZKgBaJi3qVPY8AYPgS3MHlW8d42aUJPTh96LVCqeGrbomLOXiDelfrT9dEaPUQ
 +DM04Bv3QQ0YfbFsXuDxOWSqSelGbCtwBtF3jBkTzoe5TNdkyrJMvKEznMMK7IB5CmA2zzHb3Q3
 ksADiLAg6cmC1wi8qK5mbEZPcRz4kKY0OEEeFxvDyGoPfoel4xcH0/WxI/UK6HW16hQG6die2KG
 mdStvJ3Lz8DArQFDi5UyiDByIhIT0h01TUEuICOgOUnmPWSNd4d20HfThUqu7tiNgfx5rbFMJhB
 AEXSOr7d29BlGY9bFt8AYCim5rsTTxbUjWV4JQ47+8rJlPm9VqOpFWRAX2oUNKu9cj+3v9aSqUA
 2CuMLDbNJ40KomJalvlLhnyKgoVnxt1Ybatq1kznQ+dHCU/m6l+jrZQAYf/RxnPdXCgsP01q7Qs
 uNBnSJUlS/Rz9TBRvchvYqwb4j8MHu6Faq0DWPr8xSoBsr414WbIGCPX6HJFEqLdM6eAqM5ESfG
 p2usBT8qhMLnMroY8EW10nkCdY/QUfaT8dIPfJupi0HlNTbWhhYFtcX6M6FHW0kYZB//0s7ABHn
 Dx25ZG6RMV703Yw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The lane mask must be multiplied by 2, but this was accidentally omitted.

Reviewed-by: Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>
Suggested-by: Nihal Kumar Gupta <nihal.gupta@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index dac8d2ecf7995..7c8c0e41bc62f 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -1114,17 +1114,17 @@ static void csiphy_gen2_config_lanes(struct csiphy_device *csiphy,
 static u8 csiphy_get_lane_mask(struct csiphy_lanes_cfg *lane_cfg)
 {
 	u8 lane_mask;
 	int i;
 
 	lane_mask = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
 
 	for (i = 0; i < lane_cfg->num_data; i++)
-		lane_mask |= 1 << lane_cfg->data[i].pos;
+		lane_mask |= BIT(lane_cfg->data[i].pos * 2);
 
 	return lane_mask;
 }
 
 static bool csiphy_is_gen2(u32 version)
 {
 	bool ret = false;
 

-- 
2.53.0

