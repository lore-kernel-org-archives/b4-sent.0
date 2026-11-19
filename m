From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 05:21:44 +0000
Subject: [PATCH v4 3/8] drm/rockchip: vop2: Fix the HDMI sync polarity on
 RK3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-vop2-fixes-v4-3-4b8f5e7148c9@gmail.com>
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
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>, 
 Cristian Ciocaltea <cristian.ciocaltea@collabora.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795065702; l=1551;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=y/BLNj95neZ1kNSGI9NFsr8jsXQo+g+IgIthS+l+Duk=;
 b=0qcKw8upSrWwQ8ZwYNtXRiuBPfNZd2/78sN+W/kwWn5wJf2395l6zxYIq3H7fHd7F5A73Ge9U
 0HF/gIGeYyIA5uVSUAcyJE0xTnGgqnZrPlh99x/pnx2lJq89gmP3/6F
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rk3588_get_hdmi_pol() is passed the POLFLAG bits of the mode but tests
them as DRM mode flags, so the HDMI sync polarity bits in GRF_VO1_CON0
come out wrong: +HSync/+VSync modes get one of them set and
-HSync/-VSync modes none.

The bits are set for a negative sync. Test the POLFLAG bits instead.

Fixes: 5a028e8f062f ("drm/rockchip: vop2: Add support for rk3588")
Reviewed-by: Chaoyi Chen <chaoyi.chen@rock-chips.com>
Reviewed-by: Damon Ding <damon.ding@rock-chips.com>
Cc: Cristian Ciocaltea <cristian.ciocaltea@collabora.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_vop2_reg.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
index f340aba5bfd1..3e654cb99ddf 100644
--- a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
+++ b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
@@ -1683,12 +1683,13 @@ static u32 rk3588_get_mipi_port_mux(int vp_id)
 		return 0;
 }
 
-static u32 rk3588_get_hdmi_pol(u32 flags)
+/* The sync polarity bits in GRF_VO1_CON0 are set for a negative sync */
+static u32 rk3588_get_hdmi_pol(u32 polflags)
 {
 	u32 val;
 
-	val = (flags & DRM_MODE_FLAG_NHSYNC) ? BIT(HSYNC_POSITIVE) : 0;
-	val |= (flags & DRM_MODE_FLAG_NVSYNC) ? BIT(VSYNC_POSITIVE) : 0;
+	val = (polflags & BIT(HSYNC_POSITIVE)) ? 0 : BIT(HSYNC_POSITIVE);
+	val |= (polflags & BIT(VSYNC_POSITIVE)) ? 0 : BIT(VSYNC_POSITIVE);
 
 	return val;
 }

-- 
2.55.0

