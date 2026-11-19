From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 05:21:43 +0000
Subject: [PATCH v4 2/8] drm/rockchip: vop2: Don't use uninitialised
 dividers on RK3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-vop2-fixes-v4-2-4b8f5e7148c9@gmail.com>
References: <20261119-vop2-fixes-v4-0-4b8f5e7148c9@gmail.com>
In-Reply-To: <20261119-vop2-fixes-v4-0-4b8f5e7148c9@gmail.com>
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sascha Hauer <s.hauer@pengutronix.de>
Cc: Piotr Zalewski <pZ010001011111@proton.me>, 
 Chaoyi Chen <chaoyi.chen@rock-chips.com>, 
 Damon Ding <damon.ding@rock-chips.com>, dri-devel@lists.freedesktop.org, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795065702; l=2236;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Ze0km6e6xf3MFauTWjdHWZ99JiujLW3xneM4AQe1tWE=;
 b=+UqdyznPcKcYgRt8RzywfDvjv/VOsLvuOc961gMgxE6mcHvRsoJivL++FDyye0QctGV3M0clJ
 zJfV+GciK/xBJGuvmPr9Vo2kh45hbtAHFSFBKWRTIbBtCQ9IdaBi1f7
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rk3588_calc_cru_cfg() converts all four dividers with ilog2(), but every
interface only sets the ones it uses: dclk_out_div is left uninitialised
for HDMI, eDP and DPI, if_dclk_div for DP, MIPI and DPI, and
if_pixclk_div for DP and DPI. For HDMI and eDP the uninitialised
dclk_out_div is then written to RK3588_VP_CLK_CTRL.

Set the dividers an interface doesn't use to 1.

Fixes: 5a028e8f062f ("drm/rockchip: vop2: Add support for rk3588")
Suggested-by: Damon Ding <damon.ding@rock-chips.com>
Reviewed-by: Damon Ding <damon.ding@rock-chips.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_vop2_reg.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
index c44648e1bc0d..f340aba5bfd1 100644
--- a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
+++ b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
@@ -1597,6 +1597,7 @@ static unsigned long rk3588_calc_cru_cfg(struct vop2_video_port *vp, int id,
 		 */
 		*if_pixclk_div = 2;
 		*if_dclk_div = 4;
+		*dclk_out_div = 1;
 	} else if (vop2_output_if_is_edp(id)) {
 		/*
 		 * edp_pixclk = edp_dclk > dclk_core
@@ -1609,6 +1610,7 @@ static unsigned long rk3588_calc_cru_cfg(struct vop2_video_port *vp, int id,
 		 */
 		*if_pixclk_div = K;
 		*if_dclk_div = K;
+		*dclk_out_div = 1;
 	} else if (vop2_output_if_is_dp(id)) {
 		if (output_mode == ROCKCHIP_OUT_MODE_YUV420)
 			dclk_out_rate = v_pixclk >> 3;
@@ -1622,6 +1624,8 @@ static unsigned long rk3588_calc_cru_cfg(struct vop2_video_port *vp, int id,
 			return 0;
 		}
 		*dclk_out_div = dclk_rate / dclk_out_rate;
+		*if_pixclk_div = 1;
+		*if_dclk_div = 1;
 	} else if (vop2_output_if_is_mipi(id)) {
 		if_pixclk_rate = dclk_core_rate / K;
 		/*
@@ -1643,8 +1647,12 @@ static unsigned long rk3588_calc_cru_cfg(struct vop2_video_port *vp, int id,
 		 * mipi pixclk == dclk_out
 		 */
 		*if_pixclk_div = 1;
+		*if_dclk_div = 1;
 	} else if (vop2_output_if_is_dpi(id)) {
 		dclk_rate = v_pixclk;
+		*dclk_out_div = 1;
+		*if_pixclk_div = 1;
+		*if_dclk_div = 1;
 	}
 
 	*dclk_core_div = dclk_rate / dclk_core_rate;

-- 
2.55.0

