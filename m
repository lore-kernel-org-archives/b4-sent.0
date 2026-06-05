From: David Heidelberg <david@ixit.cz>
Date: Fri, 05 Jun 2026 15:14:41 +0200
Subject: [PATCH v7 3/8] media: qcom: camss: Prepare CSID for C-PHY support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-qcom-cphy-v7-3-426c37e9008f@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3748; i=david@ixit.cz;
 h=from:subject:message-id; bh=w/BmjNZrtM9iVXxgRAPn/+3YAOZus8HvqEheY9VGpkA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqIsvC720GloCvKSrUdWoJHW9yH5S8fZZx8ZZUW
 eiwBk+VUtaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaiLLwgAKCRBgAj/E00kg
 cgzPD/90mTBjxORQUjdW/yQkbGV3rbvndX6tqDlR6RRh4H4iOTG9R7A5m5JPoy5Po1J1YurpTDg
 Ios035YiB8640A8THnMWYrHVHzmdGn2CbnoA8DK5ZC7yIvKcfLfnyOae4eMPm/lkRRI8Bv6tuM0
 1guJLlISwtMy8KC4viw3NSecDGrdOw181wa/OyHzw/v64QwHFzJKtb83dt+qykGjibd3A80fmaS
 hNWOM4/iUyJXLQkDh/s/aVc7gRIbamZQIIi69+7p66UkOULUpRXvaFyszgHibppxSPiiiuAWkHT
 EqyzX+JlM4Z9C2nqCHenIi+/DuZjChCvbZ7KXllW9PR13vtfmJbADT2DjMwklLeKFZwTF+d7p+u
 BVcKPZPaBogYZE41ZbJumOsdMFj3JNoOv6PuM7Tezf2dZMALqGKJxAPakuOkXXWj7/+N/pqFkBY
 EeT5A2uxfYIiIi5GS+iXuHWnBf3wi1aArr1EhlE+t3V5g1wJr5GNWWTtKnH2DLgp2/D3A0/yAfu
 S1E20v/R1aTWPBedrrrLJX4/aX6kxSCWlFdVBDXV3c9FYxq6agWRULCQ9a/zkUntKQIVLuGTL9/
 9ArttGJPCRCd6KeUMHQhaD/HCgQHx1QMagliP8f+MZWoAPoXHTLVT8w+/uqYyLB8jvFGgSmYCnW
 aPMKR/UFQ1UgDBg==
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
 drivers/media/platform/qcom/camss/camss-csid.c      | 5 +++++
 drivers/media/platform/qcom/camss/camss-csid.h      | 6 ++++++
 3 files changed, 12 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss-csid-gen2.c b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
index eadcb2f7e3aaa..a5b406cc8ead3 100644
--- a/drivers/media/platform/qcom/camss/camss-csid-gen2.c
+++ b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
@@ -178,16 +178,17 @@ static void __csid_configure_rx(struct csid_device *csid,
 	int val;
 
 	if (!lane_cnt)
 		lane_cnt = 4;
 
 	val = (lane_cnt - 1) << CSI2_RX_CFG0_NUM_ACTIVE_LANES;
 	val |= phy->lane_assign << CSI2_RX_CFG0_DL0_INPUT_SEL;
 	val |= phy->csiphy_id << CSI2_RX_CFG0_PHY_NUM_SEL;
+	val |= csid->phy.phy_sel << CSI2_RX_CFG0_PHY_TYPE_SEL;
 	writel_relaxed(val, csid->base + CSID_CSI2_RX_CFG0);
 
 	val = 1 << CSI2_RX_CFG1_PACKET_ECC_CORRECTION_EN;
 	if (vc > 3)
 		val |= 1 << CSI2_RX_CFG1_VC_MODE;
 	val |= 1 << CSI2_RX_CFG1_MISR_EN;
 	writel_relaxed(val, csid->base + CSID_CSI2_RX_CFG1);
 }
diff --git a/drivers/media/platform/qcom/camss/camss-csid.c b/drivers/media/platform/qcom/camss/camss-csid.c
index 48459b46a981b..bcc34ac9dd212 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.c
+++ b/drivers/media/platform/qcom/camss/camss-csid.c
@@ -1286,16 +1286,21 @@ static int csid_link_setup(struct media_entity *entity,
 			/* do no allow a link from CSIPHY to CSID */
 			if (!csiphy->cfg.csi2)
 				return -EPERM;
 
 			csid->phy.csiphy_id = csiphy->id;
 
 			lane_cfg = &csiphy->cfg.csi2->lane_cfg;
 			csid->phy.lane_cnt = lane_cfg->num_data;
+			if (lane_cfg->phy_cfg == V4L2_MBUS_CSI2_CPHY)
+				csid->phy.phy_sel = CSID_PHY_SEL_CPHY;
+			else
+				csid->phy.phy_sel = CSID_PHY_SEL_DPHY;
+
 			csid->phy.lane_assign = csid_get_lane_assign(lane_cfg, lane_cfg->num_data);
 			csid->tpg_linked = false;
 		}
 	}
 	/* Decide which virtual channels to enable based on which source pads are enabled */
 	if (local->flags & MEDIA_PAD_FL_SOURCE) {
 		struct v4l2_subdev *sd = media_entity_to_v4l2_subdev(entity);
 		struct csid_device *csid = v4l2_get_subdevdata(sd);
diff --git a/drivers/media/platform/qcom/camss/camss-csid.h b/drivers/media/platform/qcom/camss/camss-csid.h
index 5296b10f6bac8..e65590b0df69f 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.h
+++ b/drivers/media/platform/qcom/camss/camss-csid.h
@@ -39,16 +39,21 @@ enum csid_testgen_mode {
 	CSID_PAYLOAD_MODE_USER_SPECIFIED = 6,
 	CSID_PAYLOAD_MODE_NUM_SUPPORTED_GEN1 = 6, /* excluding disabled */
 	CSID_PAYLOAD_MODE_COMPLEX_PATTERN = 7,
 	CSID_PAYLOAD_MODE_COLOR_BOX = 8,
 	CSID_PAYLOAD_MODE_COLOR_BARS = 9,
 	CSID_PAYLOAD_MODE_NUM_SUPPORTED_GEN2 = 9, /* excluding disabled */
 };
 
+enum csid_phy_sel {
+	CSID_PHY_SEL_DPHY = 0,
+	CSID_PHY_SEL_CPHY = 1
+};
+
 struct csid_format_info {
 	u32 code;
 	u8 data_type;
 	u8 decode_format;
 	u8 bpp;
 	u8 spp; /* bus samples per pixel */
 };
 
@@ -65,16 +70,17 @@ struct csid_testgen_config {
 };
 
 struct csid_phy_config {
 	u8 csiphy_id;
 	u8 lane_cnt;
 	u32 lane_assign;
 	u32 en_vc;
 	u8 need_vc_update;
+	enum csid_phy_sel phy_sel;
 };
 
 struct csid_device;
 
 struct csid_hw_ops {
 	/*
 	 * configure_stream - Configures and starts CSID input stream
 	 * @csid: CSID device

-- 
2.53.0

