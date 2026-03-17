From: Michael Riesch <michael.riesch@collabora.com>
Date: Tue, 17 Mar 2026 10:32:21 +0100
Subject: [PATCH v2 3/9] media: rockchip: rkcif: add support for rk3588
 vicap mipi capture
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250430-rk3588-vicap-v2-3-77de5ee9048e@collabora.com>
References: <20250430-rk3588-vicap-v2-0-77de5ee9048e@collabora.com>
In-Reply-To: <20250430-rk3588-vicap-v2-0-77de5ee9048e@collabora.com>
To: Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Jagan Teki <jagan@amarulasolutions.com>, 
 =?utf-8?q?=D0=9A=D1=83=D0=B7=D0=BD=D0=B5=D1=86=D0=BE=D0=B2_=D0=9C=D0=B8=D1=85=D0=B0=D0=B8=D0=BB?= <mai.kuznetsov.misha@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Collabora Kernel Team <kernel@collabora.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773739942; l=8077;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=d03027InleX9FrXweJNrh6cSAZZgQVUSSox74qHfGLs=;
 b=zYtBgMUvgQKm1EKcqv2xbtbzCSj6raqboIz5N5y5VMQnr+RVrkPM4NDAzRSw1tf+sKxd4Vv6q
 nan1FfILBOeAi0Tihh2pVLaIQ8SMm23hpenNjH1o9MKEYAPCRyYnzF9
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3588 Video Capture (VICAP) unit features a Digital Video Port
(DVP) and six MIPI CSI-2 capture interfaces. Add initial support
for this variant to the rkcif driver and enable the MIPI CSI-2
capture interfaces.

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 .../platform/rockchip/rkcif/rkcif-capture-mipi.c   | 136 +++++++++++++++++++++
 .../platform/rockchip/rkcif/rkcif-capture-mipi.h   |   1 +
 .../media/platform/rockchip/rkcif/rkcif-common.h   |   2 +-
 drivers/media/platform/rockchip/rkcif/rkcif-dev.c  |  18 +++
 4 files changed, 156 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.c b/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.c
index 9e67160a16e4..aa70d3e9db04 100644
--- a/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.c
+++ b/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.c
@@ -30,10 +30,18 @@
 #define RK3568_MIPI_CTRL0_CROP_EN     BIT(5)
 #define RK3568_MIPI_CTRL0_WRDDR(type) ((type) << 1)
 
+#define RK3588_MIPI_CTRL0_DMA_EN      BIT(28)
+#define RK3588_MIPI_CTRL0_HIGH_ALIGN  BIT(27)
+#define RK3588_MIPI_CTRL0_WRDDR(type) ((type) << 5)
+#define RK3588_MIPI_CTRL0_CROP_EN     BIT(4)
+#define RK3588_MIPI_CTRL0_PARSE(type) ((type) << 1)
+
 #define RKCIF_MIPI_CTRL0_DT_ID(id)    ((id) << 10)
 #define RKCIF_MIPI_CTRL0_VC_ID(id)    ((id) << 8)
 #define RKCIF_MIPI_CTRL0_CAP_EN	      BIT(0)
 
+#define RKCIF_MIPI_CTRL_CAP_EN        BIT(0)
+
 #define RKCIF_MIPI_INT_FRAME0_END(id) BIT(8 + (id) * 2 + 0)
 #define RKCIF_MIPI_INT_FRAME1_END(id) BIT(8 + (id) * 2 + 1)
 
@@ -481,6 +489,132 @@ const struct rkcif_mipi_match_data rkcif_rk3568_vicap_mipi_match_data = {
 	},
 };
 
+static u32
+rkcif_rk3588_mipi_ctrl0(struct rkcif_stream *stream,
+			const struct rkcif_output_fmt *active_out_fmt)
+{
+	u32 ctrl0 = 0;
+
+	ctrl0 |= RK3588_MIPI_CTRL0_DMA_EN;
+	ctrl0 |= RKCIF_MIPI_CTRL0_DT_ID(active_out_fmt->mipi.dt);
+	ctrl0 |= RK3588_MIPI_CTRL0_CROP_EN;
+	ctrl0 |= RKCIF_MIPI_CTRL0_CAP_EN;
+
+	switch (active_out_fmt->mipi.type) {
+	case RKCIF_MIPI_TYPE_RAW8:
+		break;
+	case RKCIF_MIPI_TYPE_RAW10:
+		ctrl0 |= RK3588_MIPI_CTRL0_PARSE(0x1);
+		if (!active_out_fmt->mipi.compact)
+			ctrl0 |= RK3588_MIPI_CTRL0_WRDDR(0x1);
+		break;
+	case RKCIF_MIPI_TYPE_RAW12:
+		ctrl0 |= RK3588_MIPI_CTRL0_PARSE(0x2);
+		if (!active_out_fmt->mipi.compact)
+			ctrl0 |= RK3588_MIPI_CTRL0_WRDDR(0x1);
+		break;
+	case RKCIF_MIPI_TYPE_RGB888:
+		break;
+	case RKCIF_MIPI_TYPE_YUV422SP:
+		ctrl0 |= RK3588_MIPI_CTRL0_WRDDR(0x4);
+		break;
+	case RKCIF_MIPI_TYPE_YUV420SP:
+		ctrl0 |= RK3588_MIPI_CTRL0_WRDDR(0x5);
+		break;
+	case RKCIF_MIPI_TYPE_YUV400:
+		ctrl0 |= RK3588_MIPI_CTRL0_WRDDR(0x3);
+		break;
+	default:
+		break;
+	}
+
+	return ctrl0;
+}
+
+const struct rkcif_mipi_match_data rkcif_rk3588_vicap_mipi_match_data = {
+	.mipi_num = 6,
+	.mipi_ctrl0 = rkcif_rk3588_mipi_ctrl0,
+	.regs = {
+		[RKCIF_MIPI_CTRL] = 0x20,
+		[RKCIF_MIPI_INTEN] = 0x74,
+		[RKCIF_MIPI_INTSTAT] = 0x78,
+	},
+	.regs_id = {
+		[RKCIF_ID0] = {
+			[RKCIF_MIPI_CTRL0] = 0x00,
+			[RKCIF_MIPI_CTRL1] = 0x04,
+			[RKCIF_MIPI_FRAME0_ADDR_Y] = 0x24,
+			[RKCIF_MIPI_FRAME0_ADDR_UV] = 0x2c,
+			[RKCIF_MIPI_FRAME0_VLW_Y] = 0x34,
+			[RKCIF_MIPI_FRAME0_VLW_UV] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_FRAME1_ADDR_Y] = 0x28,
+			[RKCIF_MIPI_FRAME1_ADDR_UV] = 0x30,
+			[RKCIF_MIPI_FRAME1_VLW_Y] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_FRAME1_VLW_UV] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_CROP_START] = 0x8c,
+		},
+		[RKCIF_ID1] = {
+			[RKCIF_MIPI_CTRL0] = 0x08,
+			[RKCIF_MIPI_CTRL1] = 0x0c,
+			[RKCIF_MIPI_FRAME0_ADDR_Y] = 0x38,
+			[RKCIF_MIPI_FRAME0_ADDR_UV] = 0x40,
+			[RKCIF_MIPI_FRAME0_VLW_Y] = 0x48,
+			[RKCIF_MIPI_FRAME0_VLW_UV] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_FRAME1_ADDR_Y] = 0x3c,
+			[RKCIF_MIPI_FRAME1_ADDR_UV] = 0x44,
+			[RKCIF_MIPI_FRAME1_VLW_Y] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_FRAME1_VLW_UV] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_CROP_START] = 0x90,
+		},
+		[RKCIF_ID2] = {
+			[RKCIF_MIPI_CTRL0] = 0x10,
+			[RKCIF_MIPI_CTRL1] = 0x14,
+			[RKCIF_MIPI_FRAME0_ADDR_Y] = 0x4c,
+			[RKCIF_MIPI_FRAME0_ADDR_UV] = 0x54,
+			[RKCIF_MIPI_FRAME0_VLW_Y] = 0x5c,
+			[RKCIF_MIPI_FRAME0_VLW_UV] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_FRAME1_ADDR_Y] = 0x50,
+			[RKCIF_MIPI_FRAME1_ADDR_UV] = 0x58,
+			[RKCIF_MIPI_FRAME1_VLW_Y] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_FRAME1_VLW_UV] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_CROP_START] = 0x94,
+		},
+		[RKCIF_ID3] = {
+			[RKCIF_MIPI_CTRL0] = 0x18,
+			[RKCIF_MIPI_CTRL1] = 0x1c,
+			[RKCIF_MIPI_FRAME0_ADDR_Y] = 0x60,
+			[RKCIF_MIPI_FRAME0_ADDR_UV] = 0x68,
+			[RKCIF_MIPI_FRAME0_VLW_Y] = 0x70,
+			[RKCIF_MIPI_FRAME0_VLW_UV] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_FRAME1_ADDR_Y] = 0x64,
+			[RKCIF_MIPI_FRAME1_ADDR_UV] = 0x6c,
+			[RKCIF_MIPI_FRAME1_VLW_Y] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_FRAME1_VLW_UV] = RKCIF_REGISTER_NOTSUPPORTED,
+			[RKCIF_MIPI_CROP_START] = 0x98,
+		},
+	},
+	.blocks = {
+		{
+			.offset = 0x100,
+		},
+		{
+			.offset = 0x200,
+		},
+		{
+			.offset = 0x300,
+		},
+		{
+			.offset = 0x400,
+		},
+		{
+			.offset = 0x500,
+		},
+		{
+			.offset = 0x600,
+		},
+	},
+};
+
 static inline unsigned int rkcif_mipi_get_reg(struct rkcif_interface *interface,
 					      unsigned int index)
 {
@@ -631,6 +765,8 @@ static int rkcif_mipi_start_streaming(struct rkcif_stream *stream)
 	rkcif_mipi_stream_write(stream, RKCIF_MIPI_CTRL1, ctrl1);
 	rkcif_mipi_stream_write(stream, RKCIF_MIPI_CTRL0, ctrl0);
 
+	rkcif_mipi_write(interface, RKCIF_MIPI_CTRL, RKCIF_MIPI_CTRL_CAP_EN);
+
 	ret = 0;
 
 out:
diff --git a/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.h b/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.h
index 7f16eadc474c..7edaca44f653 100644
--- a/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.h
+++ b/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.h
@@ -13,6 +13,7 @@
 #include "rkcif-common.h"
 
 extern const struct rkcif_mipi_match_data rkcif_rk3568_vicap_mipi_match_data;
+extern const struct rkcif_mipi_match_data rkcif_rk3588_vicap_mipi_match_data;
 
 int rkcif_mipi_register(struct rkcif_device *rkcif);
 
diff --git a/drivers/media/platform/rockchip/rkcif/rkcif-common.h b/drivers/media/platform/rockchip/rkcif/rkcif-common.h
index dd92cfbc879f..4d9211ba9bda 100644
--- a/drivers/media/platform/rockchip/rkcif/rkcif-common.h
+++ b/drivers/media/platform/rockchip/rkcif/rkcif-common.h
@@ -27,7 +27,7 @@
 #include "rkcif-regs.h"
 
 #define RKCIF_DRIVER_NAME "rockchip-cif"
-#define RKCIF_CLK_MAX	  4
+#define RKCIF_CLK_MAX	  5
 
 enum rkcif_format_type {
 	RKCIF_FMT_TYPE_INVALID,
diff --git a/drivers/media/platform/rockchip/rkcif/rkcif-dev.c b/drivers/media/platform/rockchip/rkcif/rkcif-dev.c
index b4cf1146f131..c8542398b7f0 100644
--- a/drivers/media/platform/rockchip/rkcif/rkcif-dev.c
+++ b/drivers/media/platform/rockchip/rkcif/rkcif-dev.c
@@ -53,6 +53,20 @@ static const struct rkcif_match_data rk3568_vicap_match_data = {
 	.mipi = &rkcif_rk3568_vicap_mipi_match_data,
 };
 
+static const char *const rk3588_vicap_clks[] = {
+	"aclk",
+	"hclk",
+	"dclk",
+	"iclk0",
+	"iclk1",
+};
+
+static const struct rkcif_match_data rk3588_vicap_match_data = {
+	.clks = rk3588_vicap_clks,
+	.clks_num = ARRAY_SIZE(rk3588_vicap_clks),
+	.mipi = &rkcif_rk3588_vicap_mipi_match_data,
+};
+
 static const struct of_device_id rkcif_plat_of_match[] = {
 	{
 		.compatible = "rockchip,px30-vip",
@@ -62,6 +76,10 @@ static const struct of_device_id rkcif_plat_of_match[] = {
 		.compatible = "rockchip,rk3568-vicap",
 		.data = &rk3568_vicap_match_data,
 	},
+	{
+		.compatible = "rockchip,rk3588-vicap",
+		.data = &rk3588_vicap_match_data,
+	},
 	{}
 };
 MODULE_DEVICE_TABLE(of, rkcif_plat_of_match);

-- 
2.39.5

