From: Michael Riesch <michael.riesch@collabora.com>
Date: Tue, 14 Oct 2025 15:01:57 +0200
Subject: [PATCH v12 11/18] media: rockchip: rkcif: add support for rk3568
 vicap dvp capture
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240220-rk3568-vicap-v12-11-c6dbece6bb98@collabora.com>
References: <20240220-rk3568-vicap-v12-0-c6dbece6bb98@collabora.com>
In-Reply-To: <20240220-rk3568-vicap-v12-0-c6dbece6bb98@collabora.com>
To: Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 =?utf-8?q?Th=C3=A9o_Lebrun?= <theo.lebrun@bootlin.com>, 
 Thomas Petazzoni <thomas.petazzoni@bootlin.com>, 
 Gerald Loacker <gerald.loacker@wolfvision.net>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Markus Elfring <Markus.Elfring@web.de>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh+dt@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Collabora Kernel Team <kernel@collabora.com>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Alexander Shiyan <eagle.alexander923@gmail.com>, 
 Val Packett <val@packett.cool>, Rob Herring <robh@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, 
 Michael Riesch <michael.riesch@collabora.com>, 
 Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760446963; l=10872;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=ZDvA55eFuTvHZDXBIDU39HmOOFX4CnFS7u4BodrXIAw=;
 b=LC9E8qKsniyCaw0BOrOpULlKzD8S/ofkBrCmonSj0HCiFGd2e6t5DDf6FczOcNzd6P4C4Hhw2
 n/dO7AJPJfrByPfkg1GEb1mcrNgFYIhpGIWpUhwgc2Va6culD4HOxSS
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3568 Video Capture (VICAP) unit features a Digital Video Port
(DVP). Add support for it.

Tested-by: Gerald Loacker <gerald.loacker@wolfvision.net>
Reviewed-by: Gerald Loacker <gerald.loacker@wolfvision.net>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 .../platform/rockchip/rkcif/rkcif-capture-dvp.c    | 276 +++++++++++++++++++++
 .../platform/rockchip/rkcif/rkcif-capture-dvp.h    |   1 +
 drivers/media/platform/rockchip/rkcif/rkcif-dev.c  |   1 +
 3 files changed, 278 insertions(+)

diff --git a/drivers/media/platform/rockchip/rkcif/rkcif-capture-dvp.c b/drivers/media/platform/rockchip/rkcif/rkcif-capture-dvp.c
index b40135035ab8..dbaf7636aeeb 100644
--- a/drivers/media/platform/rockchip/rkcif/rkcif-capture-dvp.c
+++ b/drivers/media/platform/rockchip/rkcif/rkcif-capture-dvp.c
@@ -332,6 +332,282 @@ const struct rkcif_dvp_match_data rkcif_px30_vip_dvp_match_data = {
 	},
 };
 
+static const struct rkcif_input_fmt rk3568_dvp_in_fmts[] = {
+	{
+		.mbus_code = MEDIA_BUS_FMT_YUYV8_2X8,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YUYV,
+		.fmt_type = RKCIF_FMT_TYPE_YUV,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_YUYV8_2X8,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YUYV,
+		.fmt_type = RKCIF_FMT_TYPE_YUV,
+		.field = V4L2_FIELD_INTERLACED,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_YVYU8_2X8,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YVYU,
+		.fmt_type = RKCIF_FMT_TYPE_YUV,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_YVYU8_2X8,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YVYU,
+		.fmt_type = RKCIF_FMT_TYPE_YUV,
+		.field = V4L2_FIELD_INTERLACED,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_UYVY8_2X8,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_UYVY,
+		.fmt_type = RKCIF_FMT_TYPE_YUV,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_UYVY8_2X8,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_UYVY,
+		.fmt_type = RKCIF_FMT_TYPE_YUV,
+		.field = V4L2_FIELD_INTERLACED,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_VYUY8_2X8,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_VYUY,
+		.fmt_type = RKCIF_FMT_TYPE_YUV,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_VYUY8_2X8,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_VYUY,
+		.fmt_type = RKCIF_FMT_TYPE_YUV,
+		.field = V4L2_FIELD_INTERLACED,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_YUYV8_1X16,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YUYV |
+			       RKCIF_FORMAT_INPUT_MODE_BT1120 |
+			       RKCIF_FORMAT_BT1120_TRANSMIT_PROGRESS,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_YUYV8_1X16,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YUYV |
+			       RKCIF_FORMAT_INPUT_MODE_BT1120,
+		.field = V4L2_FIELD_INTERLACED,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_YVYU8_1X16,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YVYU |
+			       RKCIF_FORMAT_INPUT_MODE_BT1120 |
+			       RKCIF_FORMAT_BT1120_TRANSMIT_PROGRESS,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_YVYU8_1X16,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YVYU |
+			       RKCIF_FORMAT_INPUT_MODE_BT1120,
+		.field = V4L2_FIELD_INTERLACED,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_UYVY8_1X16,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YUYV |
+			       RKCIF_FORMAT_INPUT_MODE_BT1120 |
+			       RKCIF_FORMAT_BT1120_YC_SWAP |
+			       RKCIF_FORMAT_BT1120_TRANSMIT_PROGRESS,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_UYVY8_1X16,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YUYV |
+			       RKCIF_FORMAT_BT1120_YC_SWAP |
+			       RKCIF_FORMAT_INPUT_MODE_BT1120,
+		.field = V4L2_FIELD_INTERLACED,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_VYUY8_1X16,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YVYU |
+			       RKCIF_FORMAT_INPUT_MODE_BT1120 |
+			       RKCIF_FORMAT_BT1120_YC_SWAP |
+			       RKCIF_FORMAT_BT1120_TRANSMIT_PROGRESS,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_VYUY8_1X16,
+		.dvp_fmt_val = RKCIF_FORMAT_YUV_INPUT_422 |
+			       RKCIF_FORMAT_YUV_INPUT_ORDER_YVYU |
+			       RKCIF_FORMAT_BT1120_YC_SWAP |
+			       RKCIF_FORMAT_INPUT_MODE_BT1120,
+		.field = V4L2_FIELD_INTERLACED,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SBGGR8_1X8,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_8,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SGBRG8_1X8,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_8,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SGRBG8_1X8,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_8,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SRGGB8_1X8,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_8,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SBGGR10_1X10,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_10,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SGBRG10_1X10,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_10,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SGRBG10_1X10,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_10,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SRGGB10_1X10,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_10,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SBGGR12_1X12,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_12,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SGBRG12_1X12,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_12,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SGRBG12_1X12,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_12,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_SRGGB12_1X12,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_12,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_RGB888_1X24,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_Y8_1X8,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_8,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_Y10_1X10,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_10,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+	{
+		.mbus_code = MEDIA_BUS_FMT_Y12_1X12,
+		.dvp_fmt_val = RKCIF_FORMAT_INPUT_MODE_RAW |
+			       RKCIF_FORMAT_RAW_DATA_WIDTH_12,
+		.fmt_type = RKCIF_FMT_TYPE_RAW,
+		.field = V4L2_FIELD_NONE,
+	},
+};
+
+static void rk3568_dvp_grf_setup(struct rkcif_device *rkcif)
+{
+	u32 con1 = RK3568_GRF_WRITE_ENABLE(RK3568_GRF_VI_CON1_CIF_DATAPATH |
+					   RK3568_GRF_VI_CON1_CIF_CLK_DELAYNUM);
+
+	if (!rkcif->grf)
+		return;
+
+	con1 |= rkcif->interfaces[RKCIF_DVP].dvp.dvp_clk_delay &
+		RK3568_GRF_VI_CON1_CIF_CLK_DELAYNUM;
+
+	if (rkcif->interfaces[RKCIF_DVP].vep.bus.parallel.flags &
+	    V4L2_MBUS_PCLK_SAMPLE_DUALEDGE)
+		con1 |= RK3568_GRF_VI_CON1_CIF_DATAPATH;
+
+	regmap_write(rkcif->grf, RK3568_GRF_VI_CON1, con1);
+}
+
+const struct rkcif_dvp_match_data rkcif_rk3568_vicap_dvp_match_data = {
+	.in_fmts = rk3568_dvp_in_fmts,
+	.in_fmts_num = ARRAY_SIZE(rk3568_dvp_in_fmts),
+	.out_fmts = dvp_out_fmts,
+	.out_fmts_num = ARRAY_SIZE(dvp_out_fmts),
+	.setup = rk3568_dvp_grf_setup,
+	.has_scaler = false,
+	.regs = {
+		[RKCIF_DVP_CTRL] = 0x00,
+		[RKCIF_DVP_INTEN] = 0x04,
+		[RKCIF_DVP_INTSTAT] = 0x08,
+		[RKCIF_DVP_FOR] = 0x0c,
+		[RKCIF_DVP_LINE_NUM_ADDR] = 0x2c,
+		[RKCIF_DVP_FRM0_ADDR_Y] = 0x14,
+		[RKCIF_DVP_FRM0_ADDR_UV] = 0x18,
+		[RKCIF_DVP_FRM1_ADDR_Y] = 0x1c,
+		[RKCIF_DVP_FRM1_ADDR_UV] = 0x20,
+		[RKCIF_DVP_VIR_LINE_WIDTH] = 0x24,
+		[RKCIF_DVP_SET_SIZE] = 0x28,
+		[RKCIF_DVP_CROP] = 0x34,
+		[RKCIF_DVP_FRAME_STATUS] = 0x3c,
+		[RKCIF_DVP_LAST_LINE] = 0x44,
+		[RKCIF_DVP_LAST_PIX] = 0x48,
+	},
+};
+
 static inline unsigned int rkcif_dvp_get_addr(struct rkcif_device *rkcif,
 					      unsigned int index)
 {
diff --git a/drivers/media/platform/rockchip/rkcif/rkcif-capture-dvp.h b/drivers/media/platform/rockchip/rkcif/rkcif-capture-dvp.h
index 7b2da11497c3..a4ed37833bd6 100644
--- a/drivers/media/platform/rockchip/rkcif/rkcif-capture-dvp.h
+++ b/drivers/media/platform/rockchip/rkcif/rkcif-capture-dvp.h
@@ -14,6 +14,7 @@
 #include "rkcif-common.h"
 
 extern const struct rkcif_dvp_match_data rkcif_px30_vip_dvp_match_data;
+extern const struct rkcif_dvp_match_data rkcif_rk3568_vicap_dvp_match_data;
 
 int rkcif_dvp_register(struct rkcif_device *rkcif);
 
diff --git a/drivers/media/platform/rockchip/rkcif/rkcif-dev.c b/drivers/media/platform/rockchip/rkcif/rkcif-dev.c
index 207802073fd3..addc118ff8bf 100644
--- a/drivers/media/platform/rockchip/rkcif/rkcif-dev.c
+++ b/drivers/media/platform/rockchip/rkcif/rkcif-dev.c
@@ -48,6 +48,7 @@ static const char *const rk3568_vicap_clks[] = {
 static const struct rkcif_match_data rk3568_vicap_match_data = {
 	.clks = rk3568_vicap_clks,
 	.clks_num = ARRAY_SIZE(rk3568_vicap_clks),
+	.dvp = &rkcif_rk3568_vicap_dvp_match_data,
 };
 
 static const struct of_device_id rkcif_plat_of_match[] = {

-- 
2.39.5

