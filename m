From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 05:21:46 +0000
Subject: [PATCH v4 5/8] drm/rockchip: vop2: Only accept AFBC YTR for 8 bit
 RGB on RK3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-vop2-fixes-v4-5-4b8f5e7148c9@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795065702; l=1440;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=uMnTJIcFwj1gG3DgCMEJ8nNkx4JZMnStu+mMXXYuIVg=;
 b=1b22BtMFBoMuRj7piWq/bszlAYD84J3qIiaw2Tx3rGku6UHS7m+1JvGyHTqRz8zZpjR1a7xiW
 OBiBKooC9EqA/jC3N9CpVVNkiQiMuuJJ0UTke/Pvj0wL3Y+UDB3OR34
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to the TRM, the AFBC decoder of the RK3588 Cluster windows
supports the lossless colour transform (YTR) only for the 8 bit RGB
formats. An RGB565 buffer with YTR gives a black picture and
POST_BUF_EMPTY, while the same buffer without YTR displays fine.

Don't accept YTR for any other format on RK3588.

Fixes: 5a028e8f062f ("drm/rockchip: vop2: Add support for rk3588")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
index e8ef83d6924b..1408b539c311 100644
--- a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
+++ b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
@@ -396,6 +396,15 @@ static bool rockchip_vop2_mod_supported(struct drm_plane *plane, u32 format,
 		return false;
 	}
 
+	/* AFBC YTR on 3588 is for 8bpc RGB only */
+	if (vop2->version == VOP_VERSION_RK3588 && drm_is_afbc(modifier) &&
+	    (modifier & AFBC_FORMAT_MOD_YTR) &&
+	    vop2_convert_afbc_format(format) != VOP2_AFBC_FMT_ARGB8888 &&
+	    vop2_convert_afbc_format(format) != VOP2_AFBC_FMT_RGB888) {
+		drm_dbg_kms(vop2->drm, "Only support YTR with 8bpc RGB formats\n");
+		return false;
+	}
+
 	/* Linear is otherwise supported everywhere */
 	if (modifier == DRM_FORMAT_MOD_LINEAR)
 		return true;

-- 
2.55.0

