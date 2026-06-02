From: David Heidelberg <david@ixit.cz>
Date: Wed, 03 Jun 2026 01:30:41 +0200
Subject: [PATCH v6 3/8] media: qcom: camss: Prepare CSID for C-PHY support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260603-qcom-cphy-v6-3-e50de0b557a8@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3063; i=david@ixit.cz;
 h=from:subject:message-id; bh=S/NCEpJ9Qg9rdkYHEby0/Ggz1JWYH66XExTkL5xCQFM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqH2eqmiThGqOenOAQV/pT5wh7aaQ+uc23W6WCc
 W45LO893pqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCah9nqgAKCRBgAj/E00kg
 cusYD/95uE6PTfjvRU0xvq+WTCLJjA3pdhBhpXuNoZB5+KoawdkbIRN9lOyDY3Ks+dW+z6Tqom8
 kIKKPySLiBR9dOXzeMLP4soTk0J0eKUZa0dSXc0XCkVOWgKEPD70GvE3X9aE+Lp13UzVu07+KHJ
 gYRdy0oYb98OaBaJEDLIuu67eNNjGaRUrv/g12dTbbJgxj9g88nW0omvb/kw1aCNKvDqxNzj1Kf
 BqQrQm5Qi3b9Blal/huvec1tkx/9chP3oNSIB2PKWC/xy8LuExpE1JllMlclSQQOOSfwDVrInXw
 KfoS4oEcHAjDzTdd53UouVhurniU1q6ocqHfqQ4RppgVGWzkZyFz+X57yq9G5sh712y45gsLS5X
 7Vbku/+G7QiL98WQOudmk1NYQjPhFdRQHUptC0IY8K9z3UX3I4WpYK2PEV3ctyypG8AoZ07TlyT
 cFAxvOBeaTPKPCDeuw5ZDRKrWYFVM/Y5hH0Unpm+9lNtvXUbjmOLI67AvFkShve7zKLrTVD/fIY
 ofIQBZsA68sCtjRiZIT4/TU2bCy0YWTBh0b5e7CO/Mpwl1PwI1y22MrRLUT7madBlg11elX5yyK
 /fzZ6eEsSw3lRQTCQ8vRwUa4shzVihIjdLcVlc60xNWd36zo+90lzlgF05D5uYg3dC8prU2JXiF
 r19/OgJHHk/Od6w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inherit C-PHY information from CSIPHY, so we can configure CSID
properly.

CSI2_RX_CFG0_PHY_TYPE_SEL must be set to 1, when C-PHY mode is used.

Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Acked-by: Cory Keitz <ckeitz@amazon.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csid-gen2.c | 1 +
 drivers/media/platform/qcom/camss/camss-csid.c      | 1 +
 drivers/media/platform/qcom/camss/camss-csid.h      | 1 +
 3 files changed, 3 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss-csid-gen2.c b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
index eadcb2f7e3aaa..52ef730b10553 100644
--- a/drivers/media/platform/qcom/camss/camss-csid-gen2.c
+++ b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
@@ -178,16 +178,17 @@ static void __csid_configure_rx(struct csid_device *csid,
 	int val;
 
 	if (!lane_cnt)
 		lane_cnt = 4;
 
 	val = (lane_cnt - 1) << CSI2_RX_CFG0_NUM_ACTIVE_LANES;
 	val |= phy->lane_assign << CSI2_RX_CFG0_DL0_INPUT_SEL;
 	val |= phy->csiphy_id << CSI2_RX_CFG0_PHY_NUM_SEL;
+	val |= csid->phy.cphy << CSI2_RX_CFG0_PHY_TYPE_SEL;
 	writel_relaxed(val, csid->base + CSID_CSI2_RX_CFG0);
 
 	val = 1 << CSI2_RX_CFG1_PACKET_ECC_CORRECTION_EN;
 	if (vc > 3)
 		val |= 1 << CSI2_RX_CFG1_VC_MODE;
 	val |= 1 << CSI2_RX_CFG1_MISR_EN;
 	writel_relaxed(val, csid->base + CSID_CSI2_RX_CFG1);
 }
diff --git a/drivers/media/platform/qcom/camss/camss-csid.c b/drivers/media/platform/qcom/camss/camss-csid.c
index 48459b46a981b..8d5c872f84ed5 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.c
+++ b/drivers/media/platform/qcom/camss/camss-csid.c
@@ -1286,16 +1286,17 @@ static int csid_link_setup(struct media_entity *entity,
 			/* do no allow a link from CSIPHY to CSID */
 			if (!csiphy->cfg.csi2)
 				return -EPERM;
 
 			csid->phy.csiphy_id = csiphy->id;
 
 			lane_cfg = &csiphy->cfg.csi2->lane_cfg;
 			csid->phy.lane_cnt = lane_cfg->num_data;
+			csid->phy.cphy = (lane_cfg->phy_cfg == V4L2_MBUS_CSI2_CPHY);
 			csid->phy.lane_assign = csid_get_lane_assign(lane_cfg, lane_cfg->num_data);
 			csid->tpg_linked = false;
 		}
 	}
 	/* Decide which virtual channels to enable based on which source pads are enabled */
 	if (local->flags & MEDIA_PAD_FL_SOURCE) {
 		struct v4l2_subdev *sd = media_entity_to_v4l2_subdev(entity);
 		struct csid_device *csid = v4l2_get_subdevdata(sd);
diff --git a/drivers/media/platform/qcom/camss/camss-csid.h b/drivers/media/platform/qcom/camss/camss-csid.h
index 5296b10f6bac8..00e2669db64c9 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.h
+++ b/drivers/media/platform/qcom/camss/camss-csid.h
@@ -65,16 +65,17 @@ struct csid_testgen_config {
 };
 
 struct csid_phy_config {
 	u8 csiphy_id;
 	u8 lane_cnt;
 	u32 lane_assign;
 	u32 en_vc;
 	u8 need_vc_update;
+	bool cphy;
 };
 
 struct csid_device;
 
 struct csid_hw_ops {
 	/*
 	 * configure_stream - Configures and starts CSID input stream
 	 * @csid: CSID device

-- 
2.53.0

