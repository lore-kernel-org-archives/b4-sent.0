From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:18:54 +0000
Subject: [PATCH 6/8] drm/rockchip: vop2: Find the first mixer of a video
 port with Esmart3 too
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-vop2-fixes-v1-6-d336e9dd90d3@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295129; l=1329;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=SPA5csf/bAh0B83cKoZHeqtof5v0uoSMoUIlfdJ5VbM=;
 b=i+wS43YteQlCqC153QQbNpaUW9KYpgHXaMG3J+LGfX0EkNm9iK+dlaut6m4/8oQ3xynCZDNX1
 5gr1Z+2z7P6Cqe7qW/WBCv9w8qWQfP23ve9Xq9XwUN+ZBKtHQ4+U8qk
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

Search all window ids.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_vop2_reg.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
index 83203d18865b..2843bfb36341 100644
--- a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
+++ b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
@@ -1889,7 +1889,7 @@ static int vop2_find_start_mixer_id_for_vp(struct vop2_video_port *vp)
 
 	for (i = 0; i < 31; i += 4) {
 		match = false;
-		for_each_set_bit(phys_id, &win_mask, ROCKCHIP_VOP2_ESMART3) {
+		for_each_set_bit(phys_id, &win_mask, ROCKCHIP_VOP2_ESMART3 + 1) {
 			win = vop2_find_win_by_phys_id(vop2, phys_id);
 			if (win->data->layer_sel_id[vp->id] == ((layer_sel >> i) & 0xf)) {
 				match = true;

-- 
2.55.0

