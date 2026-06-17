From: David Heidelberg <david@ixit.cz>
Date: Wed, 17 Jun 2026 10:32:19 +0200
Subject: [PATCH v9 1/9] media: qcom: camss: csiphy-3ph: Fix lane mask
 calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-qcom-cphy-v9-1-83da8a8e4e44@ixit.cz>
References: <20260617-qcom-cphy-v9-0-83da8a8e4e44@ixit.cz>
In-Reply-To: <20260617-qcom-cphy-v9-0-83da8a8e4e44@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1187; i=david@ixit.cz;
 h=from:subject:message-id; bh=4gZLnNPEAXXeOriBAOpQ0RLijJCSPBaruO2JK2La25Y=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqMluVDaYt23kX5sYernqkW2OsBYpSt53wLLfQS
 FNNVrQ8LuuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCajJblQAKCRBgAj/E00kg
 cpeWEACHOPgSurC7v8KGNNYxgItBKG1rKNOXQxucd90zRFVR0vaZwNc+haE3e8IfalVBeGQR2Kn
 jzcJ/Op5+YbTkug+N+3vX1bCHkhURxFA2MO5rCAYgDR9qQS73NUn3HOJFYew5wzADDOmmRDnQHl
 SUnhn64zwXaXRSp3D2YRZEi3ALlINLmNzgzR3kxAoNsGeuueVl9CPjqqHqGVZd/PEf/R4r5goBO
 R1toPw9/f/bvvIOvZW7d1byETo+ckbFAMqG0d71QdSICNmv5E/WIBk3blWzbgtuye3K28KZDjd/
 dLEtRacIj/N2QcHFB8g3tVacsaKYKGVKfR6vEuCeOGGK1xzSTbWiU6oUBlTLv5QTSwntc4PWFBe
 5KX9vmCjM1hxu4frm0Q3bWzEmrR7V8a5vUh2hYUWJI81uXSY6ef1FMRNULaIZFr+miBP8+TIwAC
 g79GkR/Cpm73yJprj+QdwLeiInfctf8G5DHJUKnl9C88sPK+U8ddyfVmVQ0Q/W5gD6pvEYBpPUX
 b77FLtIe5k6cFYKfWKeFok1JyNHR/DYK7/kYETYk+82nFf5L2raUDT9dLqVFAPOBN0f5s4UdSDO
 OpnfGzlsmWs9OdNZSQA4fm3QfdbE10NGUiLbEsoEoTLBAF0rBCi4+xSqw8RKL2Iony8PNw3TKMt
 TOx0HDNhjUkdD4w==
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

