From: David Heidelberg <david@ixit.cz>
Date: Wed, 29 Jul 2026 22:20:03 +0200
Subject: [PATCH RESEND v9 8/9] media: qcom: camss: Account for C-PHY when
 calculating link frequency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-qcom-cphy-v9-8-1f8d9fdab037@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=7330; i=david@ixit.cz;
 h=from:subject:message-id; bh=sVPrk/XzjkPG3qz+AM7isEZRhSTJ3CSoEJ0qxo3ZGDs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqamB190yKAT8G4Qi5LhHPvhJz4PX/HihZQCnAg
 27NVqX1TR2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCampgdQAKCRBgAj/E00kg
 cpqpEACP8kfD8qkvGK/ZXzg6RV3lSN+UAqYTk/qF3H1gb5foX1NlwbPfOezIcBIo+k3vbxmdSnb
 7kiAFXniB1RYhbM5sqA9bc+/AjXWOcTF6s+7dFC27sB5o5R9iWZSa5jMFowdl6zcz27fop66Nod
 0lI4L1305FbQnqw0N+mvS0NLxeak2OP1NjVN8AC2QUsVn9c/q6/TpJLAyGGSsFBr3+XbBNYKuD3
 OchVDc+6QrjE7v7Ii68XhTRlGXwFQNGrf3NqwaWus6GeoB1x+shnCyzPjTlIoJYZ3AqbBecxZUJ
 K51wCHQCb5W7Ts7o6HOP+AlA+3SfGa4XnQrYIycen8J6M7PO+F7JaN/nAy5Vm/8aWp2JfVdWVKC
 Qj1aQFzhFTbwpkq5FmHp2tyote2gNTyx6p6Og15XDLAHsjUSOXfxGO+AJ/ZT1yPscbszarKegmR
 y9ny9dngm3VvHEpK5WMb5lUQALklVlv2KxQ/ThjLR9x37ucVHb6pklTKC5FaRZbOIqXlaEkAfgI
 BTXmJhECCffkDa/OyyGskvcmIm/bDNcOsmpGoT9BhJsls5gjZq7ts4lJ4APA53iB3xM0wktWemC
 pFVTZM2uVWbn2TWpKvClc8qaf8GtyuF6WvL82454KRCgxtsdOXLBCbZuQoz1gR3cBA69TBewQ4z
 ClhqgzmY/OzQEuQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ensure that the link frequency divider correctly accounts for C-PHY
operation. The divider differs between D-PHY and C-PHY, as described
in the MIPI CSI-2 specification.

For more details, see:
https://docs.kernel.org/driver-api/media/tx-rx.html#pixel-rate

Suggested-by: Sakari Ailus <sakari.ailus@linux.intel.com>
Link: https://docs.kernel.org/driver-api/media/tx-rx.html#pixel-rate
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csid.c   |  6 ++++--
 drivers/media/platform/qcom/camss/camss-csiphy.c |  6 ++++--
 drivers/media/platform/qcom/camss/camss.c        | 15 +++++++++++++--
 drivers/media/platform/qcom/camss/camss.h        |  2 +-
 4 files changed, 22 insertions(+), 7 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csid.c b/drivers/media/platform/qcom/camss/camss-csid.c
index bcc34ac9dd212..c8cb6f1a3d3bc 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.c
+++ b/drivers/media/platform/qcom/camss/camss-csid.c
@@ -535,24 +535,26 @@ const struct csid_format_info *csid_get_fmt_entry(const struct csid_format_info
 /*
  * csid_set_clock_rates - Calculate and set clock rates on CSID module
  * @csiphy: CSID device
  */
 static int csid_set_clock_rates(struct csid_device *csid)
 {
 	struct device *dev = csid->camss->dev;
 	const struct csid_format_info *fmt;
+	const bool cphy = (csid->phy.phy_sel == CSID_PHY_SEL_CPHY);
+
 	s64 link_freq;
 	int i, j;
 	int ret;
 
 	fmt = csid_get_fmt_entry(csid->res->formats->formats, csid->res->formats->nformats,
 				 csid->fmt[MSM_CSIPHY_PAD_SINK].code);
-	link_freq = camss_get_link_freq(&csid->subdev.entity, fmt->bpp,
-					csid->phy.lane_cnt);
+
+	link_freq = camss_get_link_freq(&csid->subdev.entity, fmt->bpp, csid->phy.lane_cnt, cphy);
 	if (link_freq < 0)
 		link_freq = 0;
 
 	for (i = 0; i < csid->nclocks; i++) {
 		struct camss_clock *clock = &csid->clock[i];
 
 		if (!strcmp(clock->name, "csi0") ||
 		    !strcmp(clock->name, "csi1") ||
diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.c b/drivers/media/platform/qcom/camss/camss-csiphy.c
index 539ac4888b608..a136cd27880a6 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.c
@@ -139,18 +139,19 @@ static int csiphy_set_clock_rates(struct csiphy_device *csiphy)
 	struct device *dev = csiphy->camss->dev;
 	s64 link_freq;
 	int i, j;
 	int ret;
 
 	u8 bpp = csiphy_get_bpp(csiphy->res->formats->formats, csiphy->res->formats->nformats,
 				csiphy->fmt[MSM_CSIPHY_PAD_SINK].code);
 	u8 num_lanes = csiphy->cfg.csi2->lane_cfg.num_data;
+	const bool cphy = (csiphy->cfg.csi2->lane_cfg.phy_cfg == V4L2_MBUS_CSI2_CPHY);
 
-	link_freq = camss_get_link_freq(&csiphy->subdev.entity, bpp, num_lanes);
+	link_freq = camss_get_link_freq(&csiphy->subdev.entity, bpp, num_lanes, cphy);
 	if (link_freq < 0)
 		link_freq  = 0;
 
 	for (i = 0; i < csiphy->nclocks; i++) {
 		struct camss_clock *clock = &csiphy->clock[i];
 
 		if (csiphy->rate_set[i]) {
 			u64 min_rate = link_freq / 4;
@@ -265,19 +266,20 @@ static int csiphy_set_power(struct v4l2_subdev *sd, int on)
 static int csiphy_stream_on(struct csiphy_device *csiphy)
 {
 	struct csiphy_config *cfg = &csiphy->cfg;
 	s64 link_freq;
 	u8 lane_mask = csiphy->res->hw_ops->get_lane_mask(&cfg->csi2->lane_cfg);
 	u8 bpp = csiphy_get_bpp(csiphy->res->formats->formats, csiphy->res->formats->nformats,
 				csiphy->fmt[MSM_CSIPHY_PAD_SINK].code);
 	u8 num_lanes = csiphy->cfg.csi2->lane_cfg.num_data;
+	const bool cphy = (csiphy->cfg.csi2->lane_cfg.phy_cfg == V4L2_MBUS_CSI2_CPHY);
 	u8 val;
 
-	link_freq = camss_get_link_freq(&csiphy->subdev.entity, bpp, num_lanes);
+	link_freq = camss_get_link_freq(&csiphy->subdev.entity, bpp, num_lanes, cphy);
 
 	if (link_freq < 0) {
 		dev_err(csiphy->camss->dev,
 			"Cannot get CSI2 transmitter's link frequency\n");
 		return -EINVAL;
 	}
 
 	if (csiphy->base_clk_mux) {
diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index 072c428e25166..66171069057f8 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -27,16 +27,24 @@
 #include <media/v4l2-mc.h>
 #include <media/v4l2-fwnode.h>
 
 #include "camss.h"
 
 #define CAMSS_CLOCK_MARGIN_NUMERATOR 105
 #define CAMSS_CLOCK_MARGIN_DENOMINATOR 100
 
+/*
+ * C-PHY encodes data by 16/7 ~ 2.28 bits/symbol
+ * D-PHY doesn't encode data, thus 16/16 = 1 b/s
+ */
+#define CAMSS_COMMON_PHY_DIVIDENT 16
+#define CAMSS_CPHY_DIVISOR 7
+#define CAMSS_DPHY_DIVISOR 16
+
 static const struct parent_dev_ops vfe_parent_dev_ops;
 
 static const struct camss_subdev_resources csiphy_res_8x16[] = {
 	/* CSIPHY0 */
 	{
 		.regulators = {},
 		.clock = { "top_ahb", "ispif_ahb", "ahb", "csiphy0_timer" },
 		.clock_rate = { { 0 },
@@ -4619,29 +4627,32 @@ struct media_pad *camss_find_sensor_pad(struct media_entity *entity)
 	}
 }
 
 /**
  * camss_get_link_freq - Get link frequency from sensor
  * @entity: Media entity in the current pipeline
  * @bpp: Number of bits per pixel for the current format
  * @lanes: Number of lanes in the link to the sensor
+ * @cphy: If C-PHY encoding is used.
  *
  * Return link frequency on success or a negative error code otherwise
  */
 s64 camss_get_link_freq(struct media_entity *entity, unsigned int bpp,
-			unsigned int lanes)
+			unsigned int lanes, const bool cphy)
 {
 	struct media_pad *sensor_pad;
+	unsigned int div = lanes * 2 * (cphy ? CAMSS_CPHY_DIVISOR :
+					       CAMSS_DPHY_DIVISOR);
 
 	sensor_pad = camss_find_sensor_pad(entity);
 	if (!sensor_pad)
 		return -ENODEV;
 
-	return v4l2_get_link_freq(sensor_pad, bpp, 2 * lanes);
+	return v4l2_get_link_freq(sensor_pad, CAMSS_COMMON_PHY_DIVIDENT * bpp, div);
 }
 
 /*
  * camss_get_pixel_clock - Get pixel clock rate from sensor
  * @entity: Media entity in the current pipeline
  * @pixel_clock: Received pixel clock value
  *
  * Return 0 on success or a negative error code otherwise
diff --git a/drivers/media/platform/qcom/camss/camss.h b/drivers/media/platform/qcom/camss/camss.h
index 93d691c8ac63b..12b14ba8fcec3 100644
--- a/drivers/media/platform/qcom/camss/camss.h
+++ b/drivers/media/platform/qcom/camss/camss.h
@@ -164,17 +164,17 @@ struct parent_dev_ops {
 };
 
 void camss_add_clock_margin(u64 *rate);
 int camss_enable_clocks(int nclocks, struct camss_clock *clock,
 			struct device *dev);
 void camss_disable_clocks(int nclocks, struct camss_clock *clock);
 struct media_pad *camss_find_sensor_pad(struct media_entity *entity);
 s64 camss_get_link_freq(struct media_entity *entity, unsigned int bpp,
-			unsigned int lanes);
+			unsigned int lanes, const bool cphy);
 int camss_get_pixel_clock(struct media_entity *entity, u64 *pixel_clock);
 int camss_pm_domain_on(struct camss *camss, int id);
 void camss_pm_domain_off(struct camss *camss, int id);
 int camss_vfe_get(struct camss *camss, int id);
 void camss_vfe_put(struct camss *camss, int id);
 void camss_delete(struct camss *camss);
 void camss_buf_done(struct camss *camss, int hw_id, int port_id);
 void camss_reg_update(struct camss *camss, int hw_id,

-- 
2.53.0

