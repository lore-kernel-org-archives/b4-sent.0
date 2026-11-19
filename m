From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 10:06:01 +0000
Subject: [PATCH 2/2] drm/bridge: synopsys: dw-hdmi-qp: Allow interlaced
 modes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-rk3588-interlace-v1-2-993212e389cd@gmail.com>
References: <20261119-rk3588-interlace-v1-0-993212e389cd@gmail.com>
In-Reply-To: <20261119-rk3588-interlace-v1-0-993212e389cd@gmail.com>
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sascha Hauer <s.hauer@pengutronix.de>
Cc: dri-devel@lists.freedesktop.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Cristian Ciocaltea <cristian.ciocaltea@collabora.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795082759; l=903;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=JdB991WB7QVchwubHLTwNcdcVa5HjMmWEsErXD/u8W4=;
 b=r1/DJHRQSz10f0nFji6A4bZTO3kA+yUy0oqg26h+aDwBGKbD0rsj3WPPSyhvvxyQxwovoRIya
 j5yeRuZ4inLAoHkuHDnBLuPDOaRosszuCF9yE+p8H5r4Py/QfrknRww
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

drm_bridge_connector drops interlaced modes unless every bridge sets
interlace_allowed. The controller only forwards the CRTC timing, so set it.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c b/drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c
index 984220928836..75b5adbe8178 100644
--- a/drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c
+++ b/drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c
@@ -1169,6 +1169,7 @@ struct dw_hdmi_qp *dw_hdmi_qp_bind(struct platform_device *pdev,
 	hdmi->bridge.type = DRM_MODE_CONNECTOR_HDMIA;
 	hdmi->bridge.vendor = "Synopsys";
 	hdmi->bridge.product = "DW HDMI QP TX";
+	hdmi->bridge.interlace_allowed = true;
 
 	if (hdmi->no_hpd) {
 		hdmi->bridge.supported_hdmi_ver = HDMI_VERSION_1_4;

-- 
2.55.0

