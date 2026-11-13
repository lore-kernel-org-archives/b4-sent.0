From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:39:21 +0000
Subject: [PATCH v3 4/8] drm/rockchip: vop2: Fix the HDMI sync polarity bit
 order on RK3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-vop2-fixes-v3-4-08ae37e83b5c@gmail.com>
References: <20261113-vop2-fixes-v3-0-08ae37e83b5c@gmail.com>
In-Reply-To: <20261113-vop2-fixes-v3-0-08ae37e83b5c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794587957; l=1424;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=UGsUFXw5YCEmRTpiw/otu9BINYjzUVbOqG/Y9ftnmx4=;
 b=6Dmcvc9cKlPBL5ogCbcn9fM+YHzcY68rXAT61AwNeTTAOlVNuJLADIMDaq1o8ZWo8lib94SxW
 b48ZjBNy9qPAy7ZL0AWu90nR+lgltj7uWvUY7PlTIkKGQLoRzeIY9NK
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In GRF_VO1_CON0 the HDMI vsync polarity bit comes before the hsync one
(bits 5 and 6 for HDMI0, 7 and 8 for HDMI1), but rk3588_get_hdmi_pol()
puts hsync first. Modes with mixed sync polarities go out with both
syncs inverted: the HDMI controller sees 1920x1080@144 +HSync -VSync
as -HSync +VSync in VIDEO_INTERFACE_STATUS0.

Fixes: 5a028e8f062f ("drm/rockchip: vop2: Add support for rk3588")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_vop2_reg.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
index 3e654cb99ddf..6d08988d7007 100644
--- a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
+++ b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
@@ -1683,13 +1683,13 @@ static u32 rk3588_get_mipi_port_mux(int vp_id)
 		return 0;
 }
 
-/* The sync polarity bits in GRF_VO1_CON0 are set for a negative sync */
+/* GRF_VO1_CON0: vsync bit below the hsync bit, each set for a negative sync */
 static u32 rk3588_get_hdmi_pol(u32 polflags)
 {
 	u32 val;
 
-	val = (polflags & BIT(HSYNC_POSITIVE)) ? 0 : BIT(HSYNC_POSITIVE);
-	val |= (polflags & BIT(VSYNC_POSITIVE)) ? 0 : BIT(VSYNC_POSITIVE);
+	val = (polflags & BIT(VSYNC_POSITIVE)) ? 0 : BIT(0);
+	val |= (polflags & BIT(HSYNC_POSITIVE)) ? 0 : BIT(1);
 
 	return val;
 }

-- 
2.55.0

