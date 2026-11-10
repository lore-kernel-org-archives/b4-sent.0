From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:18:56 +0000
Subject: [PATCH 8/8] drm/rockchip: vop2: Fix the AFBC offsets of a source
 that starts inside a superblock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-vop2-fixes-v1-8-d336e9dd90d3@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295129; l=2213;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Z5XfF2nsYcotAweg654B6mvuS3zpVj/f+2xNB/MTWGs=;
 b=rWMJW3meaRAT2SDZPbZW89VwvWdgRqpSz2+s9aUUSf7UtPXPtZPUbF8MeNdmuKygJeiCabiD7
 t4aMFOmel0xCYngzbJGZJM5md+9lCSLgY2cUk7UDDL3ock25CW2GBH7
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AFBC decoder of a window takes the position of the source in the
framebuffer (AFBC_PIC_OFFSET), the number of superblock columns to
decode (AFBC_TILE_NUM) and the offset of the first pixel inside its
superblock (the transform offset). For a source that doesn't start at
x = 0:

- The tile number only counts the superblocks of the source width, one
  short when the source starts inside a superblock and ends inside
  another one.
- The transform offset is the whole x position, truncated to the 8 bit
  field, instead of the position in the 16 pixel wide superblock.

Count the superblock columns from the first one the source touches, and
take the x offset in the superblock, like the vendor kernel does for the
not mirrored cases. The X mirrored and rotated cases are left as they are.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
index 9ad138457204..dfb76bfbc358 100644
--- a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
+++ b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
@@ -486,7 +486,7 @@ static u32 vop2_afbc_transform_offset(struct drm_plane_state *pstate,
 		ty = act_yoffset;
 		break;
 	case DRM_MODE_REFLECT_Y:
-		tx = act_xoffset;
+		tx = act_xoffset & 0xf;
 		ty = bottom_crop_line_num - act_yoffset;
 		break;
 	case DRM_MODE_ROTATE_90:
@@ -498,7 +498,7 @@ static u32 vop2_afbc_transform_offset(struct drm_plane_state *pstate,
 		ty = vir_width - width - act_xoffset;
 		break;
 	case 0:
-		tx = act_xoffset;
+		tx = act_xoffset & 0xf;
 		ty = act_yoffset;
 		break;
 	}
@@ -1577,7 +1577,8 @@ static void vop2_plane_atomic_update(struct drm_plane *plane,
 		if (fb->modifier & AFBC_FORMAT_MOD_YTR)
 			afbc_format |= (1 << 4);
 
-		afbc_tile_num = ALIGN(src_w, block_w) / block_w;
+		/* Superblock columns the source covers, the first one partly */
+		afbc_tile_num = ALIGN(src_w + (src->x1 >> 16) % block_w, block_w) / block_w;
 
 		/*
 		 * AFBC pic_vir_width is count by pixel, this is different

-- 
2.55.0

