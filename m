From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:18:49 +0000
Subject: [PATCH 1/8] drm/rockchip: vop2: Don't use uninitialised dividers
 on RK3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-vop2-fixes-v1-1-d336e9dd90d3@gmail.com>
References: <20261110-vop2-fixes-v1-0-d336e9dd90d3@gmail.com>
In-Reply-To: <20261110-vop2-fixes-v1-0-d336e9dd90d3@gmail.com>
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sascha Hauer <s.hauer@pengutronix.de>
Cc: dri-devel@lists.freedesktop.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295129; l=2150;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=+pfuSp1M99YrjvoyOVjakpSrJdneJ0OxzWPX/oIDiA8=;
 b=Ijs7lPZRCA6KdrR800EY6IwB81foe4E/RT1X3/IF8fwrzC3MnaeOGjcesbSuRis4oavX3TfY1
 ArfuXNwoZzbBKfToIyuwcVmpEGLigdMXgYvf1tYYxONrIeTigZJTUNV
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rk3588_calc_cru_cfg() converts all four dividers to their register
encoding with ilog2(), but only sets the ones the interface uses:
dclk_out_div is left uninitialised for HDMI, eDP and DPI, and
if_pixclk_div/if_dclk_div for DP and DPI. The garbage is then written to
RK3588_VP_CLK_CTRL; on an Orange Pi 5 the dclk_out divider of the HDMI
video port reads back as 3 (/8) in every mode.

Start all dividers at 1. dclk_out only feeds DP and MIPI (and HDMI with
DSC, which is not supported), so for the other interfaces keep it at the
dclk_core rate, as the vendor kernel does for HDMI with DSC, instead of
letting it run at the full DCLK rate.

Fixes: 5a028e8f062f ("drm/rockchip: vop2: Add support for rk3588")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_vop2_reg.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
index c44648e1bc0d..659fd0a3ab63 100644
--- a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
+++ b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
@@ -1579,6 +1579,15 @@ static unsigned long rk3588_calc_cru_cfg(struct vop2_video_port *vp, int id,
 	unsigned long if_pixclk_rate;
 	int K = 1;
 
+	/*
+	 * Not every interface uses every divider: dclk_out only feeds DP and
+	 * MIPI, the interface dividers are unused for DP. Start from 1 so that
+	 * no divider is left uninitialised when its value is converted below.
+	 */
+	*dclk_out_div = 1;
+	*if_pixclk_div = 1;
+	*if_dclk_div = 1;
+
 	if (vop2_output_if_is_hdmi(id)) {
 		/*
 		 * K = 2: dclk_core = if_pixclk_rate > if_dclk_rate
@@ -1648,6 +1657,9 @@ static unsigned long rk3588_calc_cru_cfg(struct vop2_video_port *vp, int id,
 	}
 
 	*dclk_core_div = dclk_rate / dclk_core_rate;
+	/* An unused dclk_out must not run faster than dclk_core */
+	if (!vop2_output_if_is_dp(id) && !vop2_output_if_is_mipi(id))
+		*dclk_out_div = *dclk_core_div;
 	*if_pixclk_div = ilog2(*if_pixclk_div);
 	*if_dclk_div = ilog2(*if_dclk_div);
 	*dclk_core_div = ilog2(*dclk_core_div);

-- 
2.55.0

