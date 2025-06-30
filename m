From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 30 Jun 2025 21:05:24 +0200
Subject: [PATCH v2 4/5] media: i2c: imx214: Move imx214_pll_update to
 imx214_ctrls_init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250630-imx214_fixes-v2-4-cd1a76c412c0@apitzsch.eu>
References: <20250630-imx214_fixes-v2-0-cd1a76c412c0@apitzsch.eu>
In-Reply-To: <20250630-imx214_fixes-v2-0-cd1a76c412c0@apitzsch.eu>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Ricardo Ribalda <ribalda@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Markus Elfring <Markus.Elfring@web.de>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751310420; l=8652;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=5/bWzlVBtH+nQfO/AKXIKfueLmQW3UKc3ZPKKCLKQb0=;
 b=bP/lN2uDQc3NNs+LocPphCatBxJTrHjbK9zESrbs7X4fNbr80Grwv978iSRhe0OfulMOV8uio
 LuvGQ7ZnoObA0EdmIKR0rpPFS5Y4C6MFa7d/qfbL/DIokgmpv7qhhkE
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It is more logical to call the PLL update in imx214_ctrls_init(). So
let's move it there.

Reviewed-by: Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 219 +++++++++++++++++++++++----------------------
 1 file changed, 110 insertions(+), 109 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index b84197ee5177d609b1395e14e1404ffa5b9a6dbf..63cf30acdc241de2f9ab3db339590da4af3d5102 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -881,6 +881,109 @@ static const struct v4l2_ctrl_ops imx214_ctrl_ops = {
 	.s_ctrl = imx214_set_ctrl,
 };
 
+static int imx214_pll_calculate(struct imx214 *imx214, struct ccs_pll *pll,
+				unsigned int link_freq)
+{
+	struct ccs_pll_limits limits = {
+		.min_ext_clk_freq_hz = 6000000,
+		.max_ext_clk_freq_hz = 27000000,
+
+		.vt_fr = {
+			.min_pre_pll_clk_div = 1,
+			.max_pre_pll_clk_div = 15,
+			/* Value is educated guess as we don't have a spec */
+			.min_pll_ip_clk_freq_hz = 6000000,
+			/* Value is educated guess as we don't have a spec */
+			.max_pll_ip_clk_freq_hz = 12000000,
+			.min_pll_multiplier = 12,
+			.max_pll_multiplier = 1200,
+			.min_pll_op_clk_freq_hz = 338000000,
+			.max_pll_op_clk_freq_hz = 1200000000,
+		},
+		.vt_bk = {
+			.min_sys_clk_div = 2,
+			.max_sys_clk_div = 4,
+			.min_pix_clk_div = 5,
+			.max_pix_clk_div = 10,
+			.min_pix_clk_freq_hz = 30000000,
+			.max_pix_clk_freq_hz = 120000000,
+		},
+		.op_bk = {
+			.min_sys_clk_div = 1,
+			.max_sys_clk_div = 2,
+			.min_pix_clk_div = 6,
+			.max_pix_clk_div = 10,
+			.min_pix_clk_freq_hz = 30000000,
+			.max_pix_clk_freq_hz = 120000000,
+		},
+
+		.min_line_length_pck_bin = IMX214_PPL_DEFAULT,
+		.min_line_length_pck = IMX214_PPL_DEFAULT,
+	};
+	unsigned int num_lanes = imx214->bus_cfg.bus.mipi_csi2.num_data_lanes;
+
+	/*
+	 * There are no documented constraints on the sys clock frequency, for
+	 * either branch. Recover them based on the PLL output clock frequency
+	 * and sys_clk_div limits on one hand, and the pix clock frequency and
+	 * the pix_clk_div limits on the other hand.
+	 */
+	limits.vt_bk.min_sys_clk_freq_hz =
+		max(limits.vt_fr.min_pll_op_clk_freq_hz / limits.vt_bk.max_sys_clk_div,
+		    limits.vt_bk.min_pix_clk_freq_hz * limits.vt_bk.min_pix_clk_div);
+	limits.vt_bk.max_sys_clk_freq_hz =
+		min(limits.vt_fr.max_pll_op_clk_freq_hz / limits.vt_bk.min_sys_clk_div,
+		    limits.vt_bk.max_pix_clk_freq_hz * limits.vt_bk.max_pix_clk_div);
+
+	limits.op_bk.min_sys_clk_freq_hz =
+		max(limits.vt_fr.min_pll_op_clk_freq_hz / limits.op_bk.max_sys_clk_div,
+		    limits.op_bk.min_pix_clk_freq_hz * limits.op_bk.min_pix_clk_div);
+	limits.op_bk.max_sys_clk_freq_hz =
+		min(limits.vt_fr.max_pll_op_clk_freq_hz / limits.op_bk.min_sys_clk_div,
+		    limits.op_bk.max_pix_clk_freq_hz * limits.op_bk.max_pix_clk_div);
+
+	memset(pll, 0, sizeof(*pll));
+
+	pll->bus_type = CCS_PLL_BUS_TYPE_CSI2_DPHY;
+	pll->op_lanes = num_lanes;
+	pll->vt_lanes = num_lanes;
+	pll->csi2.lanes = num_lanes;
+
+	pll->binning_horizontal = 1;
+	pll->binning_vertical = 1;
+	pll->scale_m = 1;
+	pll->scale_n = 1;
+	pll->bits_per_pixel =
+		IMX214_CSI_DATA_FORMAT_RAW10 & IMX214_BITS_PER_PIXEL_MASK;
+	pll->flags = CCS_PLL_FLAG_LANE_SPEED_MODEL;
+	pll->link_freq = link_freq;
+	pll->ext_clk_freq_hz = clk_get_rate(imx214->xclk);
+
+	return ccs_pll_calculate(imx214->dev, &limits, pll);
+}
+
+static int imx214_pll_update(struct imx214 *imx214)
+{
+	u64 link_freq;
+	int ret;
+
+	link_freq = imx214->bus_cfg.link_frequencies[imx214->link_freq->val];
+	ret = imx214_pll_calculate(imx214, &imx214->pll, link_freq);
+	if (ret) {
+		dev_err(imx214->dev, "PLL calculations failed: %d\n", ret);
+		return ret;
+	}
+
+	ret = v4l2_ctrl_s_ctrl_int64(imx214->pixel_rate,
+				     imx214->pll.pixel_rate_pixel_array);
+	if (ret) {
+		dev_err(imx214->dev, "failed to set pixel rate\n");
+		return ret;
+	}
+
+	return 0;
+}
+
 static int imx214_ctrls_init(struct imx214 *imx214)
 {
 	static const struct v4l2_area unit_size = {
@@ -1003,6 +1106,13 @@ static int imx214_ctrls_init(struct imx214 *imx214)
 		return ret;
 	}
 
+	ret = imx214_pll_update(imx214);
+	if (ret < 0) {
+		v4l2_ctrl_handler_free(ctrl_hdlr);
+		dev_err(imx214->dev, "failed to update PLL\n");
+		return ret;
+	}
+
 	imx214->sd.ctrl_handler = ctrl_hdlr;
 
 	return 0;
@@ -1115,109 +1225,6 @@ static int imx214_s_stream(struct v4l2_subdev *subdev, int enable)
 	return ret;
 }
 
-static int imx214_pll_calculate(struct imx214 *imx214, struct ccs_pll *pll,
-				unsigned int link_freq)
-{
-	struct ccs_pll_limits limits = {
-		.min_ext_clk_freq_hz = 6000000,
-		.max_ext_clk_freq_hz = 27000000,
-
-		.vt_fr = {
-			.min_pre_pll_clk_div = 1,
-			.max_pre_pll_clk_div = 15,
-			/* Value is educated guess as we don't have a spec */
-			.min_pll_ip_clk_freq_hz = 6000000,
-			/* Value is educated guess as we don't have a spec */
-			.max_pll_ip_clk_freq_hz = 12000000,
-			.min_pll_multiplier = 12,
-			.max_pll_multiplier = 1200,
-			.min_pll_op_clk_freq_hz = 338000000,
-			.max_pll_op_clk_freq_hz = 1200000000,
-		},
-		.vt_bk = {
-			.min_sys_clk_div = 2,
-			.max_sys_clk_div = 4,
-			.min_pix_clk_div = 5,
-			.max_pix_clk_div = 10,
-			.min_pix_clk_freq_hz = 30000000,
-			.max_pix_clk_freq_hz = 120000000,
-		},
-		.op_bk = {
-			.min_sys_clk_div = 1,
-			.max_sys_clk_div = 2,
-			.min_pix_clk_div = 6,
-			.max_pix_clk_div = 10,
-			.min_pix_clk_freq_hz = 30000000,
-			.max_pix_clk_freq_hz = 120000000,
-		},
-
-		.min_line_length_pck_bin = IMX214_PPL_DEFAULT,
-		.min_line_length_pck = IMX214_PPL_DEFAULT,
-	};
-	unsigned int num_lanes = imx214->bus_cfg.bus.mipi_csi2.num_data_lanes;
-
-	/*
-	 * There are no documented constraints on the sys clock frequency, for
-	 * either branch. Recover them based on the PLL output clock frequency
-	 * and sys_clk_div limits on one hand, and the pix clock frequency and
-	 * the pix_clk_div limits on the other hand.
-	 */
-	limits.vt_bk.min_sys_clk_freq_hz =
-		max(limits.vt_fr.min_pll_op_clk_freq_hz / limits.vt_bk.max_sys_clk_div,
-		    limits.vt_bk.min_pix_clk_freq_hz * limits.vt_bk.min_pix_clk_div);
-	limits.vt_bk.max_sys_clk_freq_hz =
-		min(limits.vt_fr.max_pll_op_clk_freq_hz / limits.vt_bk.min_sys_clk_div,
-		    limits.vt_bk.max_pix_clk_freq_hz * limits.vt_bk.max_pix_clk_div);
-
-	limits.op_bk.min_sys_clk_freq_hz =
-		max(limits.vt_fr.min_pll_op_clk_freq_hz / limits.op_bk.max_sys_clk_div,
-		    limits.op_bk.min_pix_clk_freq_hz * limits.op_bk.min_pix_clk_div);
-	limits.op_bk.max_sys_clk_freq_hz =
-		min(limits.vt_fr.max_pll_op_clk_freq_hz / limits.op_bk.min_sys_clk_div,
-		    limits.op_bk.max_pix_clk_freq_hz * limits.op_bk.max_pix_clk_div);
-
-	memset(pll, 0, sizeof(*pll));
-
-	pll->bus_type = CCS_PLL_BUS_TYPE_CSI2_DPHY;
-	pll->op_lanes = num_lanes;
-	pll->vt_lanes = num_lanes;
-	pll->csi2.lanes = num_lanes;
-
-	pll->binning_horizontal = 1;
-	pll->binning_vertical = 1;
-	pll->scale_m = 1;
-	pll->scale_n = 1;
-	pll->bits_per_pixel =
-		IMX214_CSI_DATA_FORMAT_RAW10 & IMX214_BITS_PER_PIXEL_MASK;
-	pll->flags = CCS_PLL_FLAG_LANE_SPEED_MODEL;
-	pll->link_freq = link_freq;
-	pll->ext_clk_freq_hz = clk_get_rate(imx214->xclk);
-
-	return ccs_pll_calculate(imx214->dev, &limits, pll);
-}
-
-static int imx214_pll_update(struct imx214 *imx214)
-{
-	u64 link_freq;
-	int ret;
-
-	link_freq = imx214->bus_cfg.link_frequencies[imx214->link_freq->val];
-	ret = imx214_pll_calculate(imx214, &imx214->pll, link_freq);
-	if (ret) {
-		dev_err(imx214->dev, "PLL calculations failed: %d\n", ret);
-		return ret;
-	}
-
-	ret = v4l2_ctrl_s_ctrl_int64(imx214->pixel_rate,
-				     imx214->pll.pixel_rate_pixel_array);
-	if (ret) {
-		dev_err(imx214->dev, "failed to set pixel rate\n");
-		return ret;
-	}
-
-	return 0;
-}
-
 static int imx214_get_frame_interval(struct v4l2_subdev *subdev,
 				     struct v4l2_subdev_state *sd_state,
 				     struct v4l2_subdev_frame_interval *fival)
@@ -1457,12 +1464,6 @@ static int imx214_probe(struct i2c_client *client)
 	pm_runtime_set_active(imx214->dev);
 	pm_runtime_enable(imx214->dev);
 
-	ret = imx214_pll_update(imx214);
-	if (ret < 0) {
-		dev_err_probe(dev, ret, "failed to update PLL\n");
-		goto error_subdev_cleanup;
-	}
-
 	ret = v4l2_async_register_subdev_sensor(&imx214->sd);
 	if (ret < 0) {
 		dev_err_probe(dev, ret,

-- 
2.50.0

