From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 21 Nov 2026 07:55:48 +0000
Subject: [PATCH] drm/rockchip: vop2: Give each RK3588 video port its own
 cluster
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-vop2-axi-primary-v1-1-8d5c74905207@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5EQBBA0atIracS1QuDq4hFa4WSoFM9hIi7a
 2P5Fv+fEFiFA5TJCcqbBFnmCPok4AY794zSRoNJTUZkCLfFG7S7oFeZrB5YfKlzjU3bImeImVf
 uZP8vq/p1WJuR3e/5wHXdfoi3WXQAAAA=
X-Change-ID: 20261121-vop2-axi-primary-971fcba0d98e
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sascha Hauer <s.hauer@pengutronix.de>
Cc: dri-devel@lists.freedesktop.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chaoyi Chen <chaoyi.chen@rock-chips.com>, 
 Damon Ding <damon.ding@rock-chips.com>, 
 Cristian Ciocaltea <cristian.ciocaltea@collabora.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795247747; l=2484;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=UR8Iq6V+Z+wSboGx6S1Fg+4yyPj7jK+nIZtEYEItTcg=;
 b=BzumBlQkZjOG0TMxnd3EtaRuRxZfKAHpRClLRwaJBDZUqFH4KPBUDGCnKKSnEDXOiwOrH/jJL
 6sQahfkkNrbBNjoPQ8VYFezMHCfJgh8R52jxwiRw3NBZ8PTHffQuEGm
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Damon Ding asked for POST_BUF_EMPTY to be fixed in the layer setup, and
Chaoyi Chen pointed out that a video port's layers must stay on one AXI
port. On RK3588 Cluster0/1 fetch through AXI0 and Cluster2/3 through
AXI1. Each video port takes the first free primary window, so VP0 and
VP2 get Cluster0 and Cluster1, both on AXI0. A 4K120 and a 4K60 XR24
primary need about 6 GB/s there, one port delivers about 4.5 GB/s, and
VP0 underflows in every frame. aclk_vop at 750 or 850 MHz is the same.

On RK3588 give VP N Cluster N as primary plane. Boards without VP1 now
get Cluster2 instead of Cluster1 as VP2's primary. RK3568 and RK3576 are
unchanged.

Fixes: 5a028e8f062f ("drm/rockchip: vop2: Add support for rk3588")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on Orange Pi 5, HDMI 4K120 + DP 4K60, v7.3 plus local HDMI FRL and
750 MHz aclk_vop (not in mainline): 7207 bad frames in 60 s before, 0 after.
Applies with Chaoyi Chen's 8K series [1]: VP0 keeps Cluster0 and Cluster1.

[1] https://lore.kernel.org/all/20261116084555.1061-4-kernel@airkyi.com/

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed every change.
---
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
index 76d151b8bc52..303d9b987a7c 100644
--- a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
+++ b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
@@ -2583,6 +2583,12 @@ static bool vop2_is_mirror_win(struct vop2_win *win)
 	}
 }
 
+/* RK3588 primary per video port; Cluster0/1 on AXI0, Cluster2/3 on AXI1. */
+static const u8 rk3588_vp_primary[] = {
+	ROCKCHIP_VOP2_CLUSTER0, ROCKCHIP_VOP2_CLUSTER1,
+	ROCKCHIP_VOP2_CLUSTER2, ROCKCHIP_VOP2_CLUSTER3,
+};
+
 static int vop2_create_crtcs(struct vop2 *vop2)
 {
 	const struct vop2_data *vop2_data = vop2->data;
@@ -2655,6 +2661,10 @@ static int vop2_create_crtcs(struct vop2 *vop2)
 			if (!(win->data->possible_vp_mask & BIT(vp->id)))
 				continue;
 
+			if (vop2->version == VOP_VERSION_RK3588 &&
+			    win->data->phys_id != rk3588_vp_primary[vp->id])
+				continue;
+
 			if (vop2_is_mirror_win(win))
 				continue;
 

---
base-commit: c408466a4dfaee4b12587e926c5b85e68c8b3c40
change-id: 20261121-vop2-axi-primary-971fcba0d98e

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

