From: Maud Spierings <maudspierings@gocontroll.com>
Date: Mon, 24 Feb 2025 14:50:58 +0100
Subject: [PATCH 08/14] drm/panel: simple: Add BOE AV123Z7M-N17 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250224-initial_display-v1-8-5ccbbf613543@gocontroll.com>
References: <20250224-initial_display-v1-0-5ccbbf613543@gocontroll.com>
In-Reply-To: <20250224-initial_display-v1-0-5ccbbf613543@gocontroll.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Liu Ying <victor.liu@nxp.com>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740405062; l=1908;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=vOVkRssMq+0b54M++/GbRnRh45tiCsN1h3cNEf5At7g=;
 b=mIAf7wLfiBaXHgCEU4/8qvWOFXgtpexk2cgZKBPGdS9xQHEzRlSLaQGkNSxpz1dAA+cZucueh
 uDLvxXs5uZfBwENboFcPxubRl6D9NJ9o9TOrax33cAGbmns59TckZj6
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the BOE AV123Z7M-N17 12.3" LVDS panel.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 drivers/gpu/drm/panel/panel-simple.c | 32 ++++++++++++++++++++++++++++++++
 1 file changed, 32 insertions(+)

diff --git a/drivers/gpu/drm/panel/panel-simple.c b/drivers/gpu/drm/panel/panel-simple.c
index a52977ab73dc2edab0d1954c702fd797d6a5b969..232b03c1a259eb15e423b9d452d28e2ff95c70f8 100644
--- a/drivers/gpu/drm/panel/panel-simple.c
+++ b/drivers/gpu/drm/panel/panel-simple.c
@@ -1403,6 +1403,35 @@ static const struct panel_desc boe_av101hdt_a10 = {
 	.connector_type = DRM_MODE_CONNECTOR_LVDS,
 };
 
+static const struct display_timing boe_av123z7m_n17_timing = {
+	.pixelclock = { 86600000, 88000000, 90800000, },
+	.hactive = { 1920, 1920, 1920, },
+	.hfront_porch = { 10, 10, 10, },
+	.hback_porch = { 10, 10, 10, },
+	.hsync_len = { 9, 12, 25, },
+	.vactive = { 720, 720, 720, },
+	.vfront_porch = { 7, 10, 13, },
+	.vback_porch = { 7, 10, 13, },
+	.vsync_len = { 7, 11, 14, },
+	.flags = DISPLAY_FLAGS_DE_HIGH | DISPLAY_FLAGS_HSYNC_LOW | DISPLAY_FLAGS_VSYNC_LOW,
+};
+
+static const struct panel_desc boe_av123z7m_n17 = {
+	.timings = &boe_av123z7m_n17_timing,
+	.bpc = 8,
+	.num_timings = 1,
+	.size = {
+		.width = 292,
+		.height = 110,
+	},
+	.delay = {
+		.prepare = 50,
+		.disable = 50,
+	},
+	.bus_format = MEDIA_BUS_FMT_RGB888_1X7X4_SPWG,
+	.connector_type = DRM_MODE_CONNECTOR_LVDS,
+};
+
 static const struct drm_display_mode boe_bp101wx1_100_mode = {
 	.clock = 78945,
 	.hdisplay = 1280,
@@ -4845,6 +4874,9 @@ static const struct of_device_id platform_of_match[] = {
 	}, {
 		.compatible = "boe,av101hdt-a10",
 		.data = &boe_av101hdt_a10,
+	}, {
+		.compatible = "boe,av123z7m-n17",
+		.data = &boe_av123z7m_n17,
 	}, {
 		.compatible = "boe,bp082wx1-100",
 		.data = &boe_bp082wx1_100,

-- 
2.48.1

