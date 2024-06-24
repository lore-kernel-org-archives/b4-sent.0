From: George Chan <gchan9527@gmail.com>
Date: Mon, 24 Jun 2024 20:13:13 +0800
Subject: [PATCH RFT v3 2/5] media: camss: csiphy-3ph: Add Gen2 v1.2.2
 two-phase MIPI CSI-2 DPHY init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240624-b4-sc7180-camss-v3-2-89ece6471431@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719231232; l=7706;
 i=gchan9527@gmail.com; s=20240621; h=from:subject:message-id;
 bh=NbmBjYKr5lRpZv7KeqzZo4iMsQiqW3p1yaxq+IYoLcg=;
 b=hACCsWt0rsUMPeaMuxSANj5DkEPXsuoF8LaJYEdABk4f+QEJtyGRUpT3X2dXK4V1U+7Euy49w
 1vmhbDwAE68D8CWZxS3fVXGkcUmHrIUYb9d9GTnRZuuS9GKWPeruExm
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=Ac2fkTqgUBlj2sns9hRIWJTYhWHO1BsmHbdBb5UpUUY=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20240621 with auth_id=176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a PHY configuration sequence for the sc7180 which uses a Qualcomm
Gen 2 version 1.2.2 CSI-2 PHY.

The PHY can be configured as two phase or three phase in C-PHY or D-PHY
mode. This configuration supports two-phase D-PHY mode.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 135 +++++++++++++++++++++
 drivers/media/platform/qcom/camss/camss.h          |   1 +
 2 files changed, 136 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index df7e93a5a4f6..e2dd9b23f857 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -348,6 +348,136 @@ csiphy_reg_t lane_regs_sm8250[5][20] = {
 	},
 };
 
+/* GEN2 1.2.2 2PH */
+struct
+csiphy_reg_t lane_regs_sc7180[5][23] = {
+	{
+		{0x0030, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0904, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0910, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0900, 0x0f, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0908, 0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0904, 0x07, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x002c, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0034, 0x0f, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0010, 0x50, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x001c, 0x0a, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0014, 0x60, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0028, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x003c, 0xb8, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0000, 0x91, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0004, 0x0c, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0020, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0008, 0x10, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
+		{0x0010, 0x52, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0038, 0xfe, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x005c, 0xc0, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0060, 0x0d, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0800, 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0000, 0x00, 0x00, CSIPHY_DNP_PARAMS},
+	},
+	{
+		{0x0730, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0c84, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0c90, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0c80, 0x0f, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0c88, 0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0c84, 0x07, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x072c, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0734, 0x0f, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0710, 0x50, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x071c, 0x0a, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0714, 0x60, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0728, 0x04, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x073c, 0xb8, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0700, 0x80, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0704, 0x0c, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0720, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0708, 0x04, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
+		{0x070c, 0xff, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0710, 0x52, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0738, 0x1f, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0800, 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0000, 0x00, 0x00, CSIPHY_DNP_PARAMS},
+		{0x0000, 0x00, 0x00, CSIPHY_DNP_PARAMS},
+	},
+	{
+		{0x0230, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0a04, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0a10, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0a00, 0x0f, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0a08, 0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0a04, 0x07, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x022c, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0234, 0x0f, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0210, 0x50, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x021c, 0x0a, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0214, 0x60, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0228, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x023c, 0xb8, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0200, 0x91, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0204, 0x0c, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0220, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0208, 0x04, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
+		{0x0210, 0x52, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0238, 0xfe, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x025c, 0xc0, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0260, 0x0d, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0800, 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0000, 0x00, 0x00, CSIPHY_DNP_PARAMS},
+	},
+	{
+		{0x0430, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0b04, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0b10, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0b00, 0x0f, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0b08, 0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0b04, 0x07, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x042c, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0434, 0x0f, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0410, 0x50, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x041c, 0x0a, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0414, 0x60, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0428, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x043c, 0xb8, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0400, 0x91, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0404, 0x0c, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0420, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0408, 0x04, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
+		{0x0410, 0x52, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0438, 0xfe, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x045c, 0xc0, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0460, 0x0d, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0800, 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0000, 0x00, 0x00, CSIPHY_DNP_PARAMS},
+	},
+	{
+		{0x0630, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0c04, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0c10, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0c00, 0x0f, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0c08, 0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0c04, 0x07, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x062c, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0634, 0x0f, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0610, 0x50, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x061c, 0x0a, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0614, 0x60, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0628, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x063c, 0xb8, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0600, 0x91, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0604, 0x0c, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0620, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0608, 0x04, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
+		{0x0610, 0x52, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0638, 0xfe, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x065c, 0xc0, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0660, 0x0d, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0800, 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
+		{0x0000, 0x00, 0x00, CSIPHY_DNP_PARAMS},
+	},
+};
+
 static void csiphy_hw_version_read(struct csiphy_device *csiphy,
 				   struct device *dev)
 {
@@ -509,6 +639,10 @@ static void csiphy_gen2_config_lanes(struct csiphy_device *csiphy,
 		r = &lane_regs_sdm845[0][0];
 		array_size = ARRAY_SIZE(lane_regs_sdm845[0]);
 		break;
+	case CAMSS_7180:
+		r = &lane_regs_sc7180[0][0];
+		array_size = ARRAY_SIZE(lane_regs_sc7180[0]);
+		break;
 	case CAMSS_8250:
 		r = &lane_regs_sm8250[0][0];
 		array_size = ARRAY_SIZE(lane_regs_sm8250[0]);
@@ -558,6 +692,7 @@ static bool csiphy_is_gen2(u32 version)
 
 	switch (version) {
 	case CAMSS_845:
+	case CAMSS_7180:
 	case CAMSS_8250:
 	case CAMSS_8280XP:
 		ret = true;
diff --git a/drivers/media/platform/qcom/camss/camss.h b/drivers/media/platform/qcom/camss/camss.h
index 73c47c07fc30..867e275db4be 100644
--- a/drivers/media/platform/qcom/camss/camss.h
+++ b/drivers/media/platform/qcom/camss/camss.h
@@ -77,6 +77,7 @@ enum camss_version {
 	CAMSS_8x96,
 	CAMSS_660,
 	CAMSS_845,
+	CAMSS_7180,
 	CAMSS_8250,
 	CAMSS_8280XP,
 };

-- 
2.34.1

