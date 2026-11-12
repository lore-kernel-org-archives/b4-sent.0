From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:33:11 +0000
Subject: [PATCH v2 7/9] drm/rockchip: vop2: Find the first mixer of a video
 port with Esmart3 too
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-vop2-fixes-v2-7-8218c1cf8ac8@gmail.com>
References: <20261112-vop2-fixes-v2-0-8218c1cf8ac8@gmail.com>
In-Reply-To: <20261112-vop2-fixes-v2-0-8218c1cf8ac8@gmail.com>
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sascha Hauer <s.hauer@pengutronix.de>
Cc: Piotr Zalewski <pZ010001011111@proton.me>, 
 Chaoyi Chen <chaoyi.chen@rock-chips.com>, dri-devel@lists.freedesktop.org, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794472385; l=2016;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=XuhTBwXc6OuQQ9kwuxgdwauJ6jcO4D6ro+WdnRqi4fQ=;
 b=18nBynrhRwhtGRC6mxBqGiMn2xlhq/tEdUkOMoV9Rv7z5FSChLqmiNez7wtf+BZIPo37LbFKO
 z2y4vYhk9o4BVKCOejcIHO/Ziq6t6xRgVO3EG6lnE9/VXe6qWMBIU7p
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vop2_find_start_mixer_id_for_vp() looks for the first layer that holds a
window of the video port, but for_each_set_bit() takes the number of bits
to search, and ROCKCHIP_VOP2_ESMART3 is the highest window id, so Esmart3
is never found. A video port whose bottom layer shows Esmart3 then starts
its alpha setup at the mixer of a higher layer, or, if Esmart3 is its
only window, past all layers, and programs mixers of other video ports.

Add ROCKCHIP_VOP2_MAX_LAYER_ID after the last window id and search up to
it.

Fixes: d3fe9aa49585 ("drm/rockchip: vop2: Use OVL_LAYER_SEL configuration instead of use win_mask calculate used layers")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.h | 1 +
 drivers/gpu/drm/rockchip/rockchip_vop2_reg.c | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h
index ccbfbdb8d246..290990632388 100644
--- a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h
+++ b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h
@@ -857,6 +857,7 @@ enum vop2_layer_phy_id {
 	ROCKCHIP_VOP2_CLUSTER3,
 	ROCKCHIP_VOP2_ESMART2,
 	ROCKCHIP_VOP2_ESMART3,
+	ROCKCHIP_VOP2_MAX_LAYER_ID,
 	ROCKCHIP_VOP2_PHY_ID_INVALID = -1,
 };
 
diff --git a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
index 83203d18865b..088c1f3a972f 100644
--- a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
+++ b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
@@ -1889,7 +1889,7 @@ static int vop2_find_start_mixer_id_for_vp(struct vop2_video_port *vp)
 
 	for (i = 0; i < 31; i += 4) {
 		match = false;
-		for_each_set_bit(phys_id, &win_mask, ROCKCHIP_VOP2_ESMART3) {
+		for_each_set_bit(phys_id, &win_mask, ROCKCHIP_VOP2_MAX_LAYER_ID) {
 			win = vop2_find_win_by_phys_id(vop2, phys_id);
 			if (win->data->layer_sel_id[vp->id] == ((layer_sel >> i) & 0xf)) {
 				match = true;

-- 
2.55.0

