From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 01:51:28 +0100
Subject: [PATCH WIP v4 9/9] media: qcom: camss: Account for C-PHY when
 calculating link frequency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-qcom-cphy-v4-9-e53316d2cc65@ixit.cz>
References: <20260301-qcom-cphy-v4-0-e53316d2cc65@ixit.cz>
In-Reply-To: <20260301-qcom-cphy-v4-0-e53316d2cc65@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>, Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6125; i=david@ixit.cz;
 h=from:subject:message-id; bh=Cjh/ZCc+QxiGxE0P3pin9rU82Q1mGW8XbN3n2VAfbWs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpo42JiWMCDeyS6nMb0DJdISneQyIuieGWA7N6t
 mYYFQY5OOeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaONiQAKCRBgAj/E00kg
 cslrD/wPuUhKj65xd6W8NpE9LwqpaN2hXZGJRjBidegodg/nYCj+4Hz/Bw4idpLc/piu2N6Lh3s
 urukhvNP7ick7mXQciySdDUgQf9pEbe4WUX8HYm/+OxRkGTOlpt0rq6onGlLEKeIYXt6iK8CtJX
 zFXsGZuJpGLaGWJeCPO/5tkBXwl5rLeq+ipNKfJbeDWxC3P2r4q4K7R0QJycYqnT1OI2qrgee/3
 FyUIKocC+BgGedGKSK6F4PehKz5pSRXXH/0A0dbrDwutRnAbYDLw6aEnK5OVDvn2EiW2Ufk1AP0
 1NRWnZFmSo0MvxiDN73n4DuJo41yBmx2vcAYd07S2r4ed2s/IsBz4slXgRo6bE8PReqmrZShPwo
 5R9eqdqVvVSpT5rodLlxiAOQZBJgsNrYyWd+jzK6VOtvS44A/TYgNv8Kd46+HDsjkcRTF+jXozm
 gwWCmDRMIt7toZHvJrVO8JM0LL+3LPJ13HtIp4mOdWpKnXa6szklZcghCL6i9D0Jq0N1/yxp+px
 S1dFnx4TDDGHrw0+6jQPK/lsKDzAIKwXoGECKNOZ5yuhwFzrMCoPIGda49aj0vAKfyzINqjlRHM
 kLI9TcTynzGM4Ee92zGuYhvmxd5HoGS7MpbA3IeKBiDwngLYpQc/0dQ4QocjYAlIi75rk6Ta/2S
 KAx7UQ0Yx+JRJCw==
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
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csid.c   | 11 +++++++----
 drivers/media/platform/qcom/camss/camss-csiphy.c |  6 ++----
 drivers/media/platform/qcom/camss/camss.c        | 18 +++++++++++++++---
 drivers/media/platform/qcom/camss/camss.h        |  2 +-
 4 files changed, 25 insertions(+), 12 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csid.c b/drivers/media/platform/qcom/camss/camss-csid.c
index b50b0cfe280c1..2fc17c6a15e2e 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.c
+++ b/drivers/media/platform/qcom/camss/camss-csid.c
@@ -534,18 +534,21 @@ const struct csid_format_info *csid_get_fmt_entry(const struct csid_format_info
  * csid_set_clock_rates - Calculate and set clock rates on CSID module
  * @csiphy: CSID device
  */
-static int csid_set_clock_rates(struct csid_device *csid)
+static int csid_set_clock_rates(struct v4l2_subdev *sd, struct csid_device *csid)
 {
 	struct device *dev = csid->camss->dev;
+	struct csiphy_device *csiphy = v4l2_get_subdevdata(sd);
+	struct csiphy_lanes_cfg *lane_cfg = &csiphy->cfg.csi2->lane_cfg;
 	const struct csid_format_info *fmt;
+
 	s64 link_freq;
 	int i, j;
 	int ret;
 
 	fmt = csid_get_fmt_entry(csid->res->formats->formats, csid->res->formats->nformats,
 				 csid->fmt[MSM_CSIPHY_PAD_SINK].code);
-	link_freq = camss_get_link_freq(&csid->subdev.entity, fmt->bpp,
-					csid->phy.lane_cnt);
+
+	link_freq = camss_get_link_freq(&csid->subdev.entity, fmt->bpp, lane_cfg);
 	if (link_freq < 0)
 		link_freq = 0;
 
@@ -703,7 +706,7 @@ static int csid_set_power(struct v4l2_subdev *sd, int on)
 			return ret;
 		}
 
-		ret = csid_set_clock_rates(csid);
+		ret = csid_set_clock_rates(sd, csid);
 		if (ret < 0) {
 			regulator_bulk_disable(csid->num_supplies,
 					       csid->supplies);
diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.c b/drivers/media/platform/qcom/camss/camss-csiphy.c
index 938600f3defe1..ea9dd2cd2e740 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.c
@@ -143,9 +143,8 @@ static int csiphy_set_clock_rates(struct csiphy_device *csiphy)
 
 	u8 bpp = csiphy_get_bpp(csiphy->res->formats->formats, csiphy->res->formats->nformats,
 				csiphy->fmt[MSM_CSIPHY_PAD_SINK].code);
-	u8 num_lanes = csiphy->cfg.csi2->lane_cfg.num_data;
 
-	link_freq = camss_get_link_freq(&csiphy->subdev.entity, bpp, num_lanes);
+	link_freq = camss_get_link_freq(&csiphy->subdev.entity, bpp, &csiphy->cfg.csi2->lane_cfg);
 	if (link_freq < 0)
 		link_freq  = 0;
 
@@ -270,10 +269,9 @@ static int csiphy_stream_on(struct csiphy_device *csiphy)
 	u8 lane_mask = csiphy->res->hw_ops->get_lane_mask(&cfg->csi2->lane_cfg);
 	u8 bpp = csiphy_get_bpp(csiphy->res->formats->formats, csiphy->res->formats->nformats,
 				csiphy->fmt[MSM_CSIPHY_PAD_SINK].code);
-	u8 num_lanes = csiphy->cfg.csi2->lane_cfg.num_data;
 	u8 val;
 
-	link_freq = camss_get_link_freq(&csiphy->subdev.entity, bpp, num_lanes);
+	link_freq = camss_get_link_freq(&csiphy->subdev.entity, bpp, &csiphy->cfg.csi2->lane_cfg);
 
 	if (link_freq < 0) {
 		dev_err(csiphy->camss->dev,
diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index ea0c8cf3cd806..4c13bae17007e 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -32,6 +32,14 @@
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
@@ -4280,20 +4288,24 @@ struct media_pad *camss_find_sensor_pad(struct media_entity *entity)
  * camss_get_link_freq - Get link frequency from sensor
  * @entity: Media entity in the current pipeline
  * @bpp: Number of bits per pixel for the current format
- * @lanes: Number of lanes in the link to the sensor
+ * @lane_cfg: CSI2 lane configuration
  *
  * Return link frequency on success or a negative error code otherwise
  */
 s64 camss_get_link_freq(struct media_entity *entity, unsigned int bpp,
-			unsigned int lanes)
+			struct csiphy_lanes_cfg *lane_cfg)
 {
 	struct media_pad *sensor_pad;
+	u8 num_lanes = lane_cfg->num_data;
+	bool cphy = lane_cfg->phy_cfg == V4L2_MBUS_CSI2_CPHY;
+	unsigned int div = num_lanes * 2 * (cphy ? CAMSS_CPHY_DIVISOR :
+						     CAMSS_DPHY_DIVISOR);
 
 	sensor_pad = camss_find_sensor_pad(entity);
 	if (!sensor_pad)
 		return -ENODEV;
 
-	return v4l2_get_link_freq(sensor_pad, bpp, 2 * lanes);
+	return v4l2_get_link_freq(sensor_pad, CAMSS_COMMON_PHY_DIVIDENT * bpp, div);
 }
 
 /*
diff --git a/drivers/media/platform/qcom/camss/camss.h b/drivers/media/platform/qcom/camss/camss.h
index 6d048414c919e..67be42b4c9174 100644
--- a/drivers/media/platform/qcom/camss/camss.h
+++ b/drivers/media/platform/qcom/camss/camss.h
@@ -163,7 +163,7 @@ int camss_enable_clocks(int nclocks, struct camss_clock *clock,
 void camss_disable_clocks(int nclocks, struct camss_clock *clock);
 struct media_pad *camss_find_sensor_pad(struct media_entity *entity);
 s64 camss_get_link_freq(struct media_entity *entity, unsigned int bpp,
-			unsigned int lanes);
+			struct csiphy_lanes_cfg *lane_cfg);
 int camss_get_pixel_clock(struct media_entity *entity, u64 *pixel_clock);
 int camss_pm_domain_on(struct camss *camss, int id);
 void camss_pm_domain_off(struct camss *camss, int id);

-- 
2.51.0

