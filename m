From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 10:06:00 +0000
Subject: [PATCH 1/2] drm/rockchip: vop2: Reject double clocked modes on
 RK3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-rk3588-interlace-v1-1-993212e389cd@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795082759; l=1221;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=552SdLdmG+KybFPqh32b97uQLYRUzbBP6Eh4nDlCs5k=;
 b=y6rLEloNTiqrvVs+2r1raoh58iyJiXIURveUiIwb8wYBqizSVv4oGyrBzPmVOtWLfQDH91eyf
 WIChskGgOiGARTrP5etUwuQVMvCNfwJ9qadI5CSNkDji33DJPr3i35q
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pixel repeated modes (DRM_MODE_FLAG_DBLCLK, e.g. 720(1440)x480i) need
each pixel sent twice. RK3588 cannot do that: DSP_CTRL.CORE_DCLK_DIV is
reserved, dclk_core already runs at dclk/4 and the HDMI QP TX has no
pixel repetition. The doubled dclk then sends a timing that does not
match the VIC. Reject such modes on RK3588.

Fixes: 5a028e8f062f ("drm/rockchip: vop2: Add support for rk3588")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
index 76d151b8bc52..1458d8ae79d6 100644
--- a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
+++ b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
@@ -1581,6 +1581,11 @@ static enum drm_mode_status vop2_crtc_mode_valid(struct drm_crtc *crtc,
 	if (mode->hdisplay > vp->data->max_output.width)
 		return MODE_BAD_HVALUE;
 
+	/* RK3588 cannot repeat pixels: no CORE_DCLK_DIV, dclk_core at dclk/4 */
+	if (mode->flags & DRM_MODE_FLAG_DBLCLK &&
+	    vp->vop2->version == VOP_VERSION_RK3588)
+		return MODE_H_ILLEGAL;
+
 	return MODE_OK;
 }
 

-- 
2.55.0

