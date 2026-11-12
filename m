From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:33:09 +0000
Subject: [PATCH v2 5/9] drm/rockchip: vop2: Balance window fetches across
 both AXI ports on RK3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-vop2-fixes-v2-5-8218c1cf8ac8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794472385; l=18937;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=wLRGmyxbi57Me7M7zLM78ZmA0J2fyvmOZ9HyFnNQdEo=;
 b=Vzldd8DYPOIgf1Lt1YAzfg9NBpnlTLj+fuTEhlr67VXyLWtba3wEEvAxO5qAyK9vC2P8FaCnj
 DO4t38kIwEwDwPyk3uXuNClTmrTbBDL/TIkwTaQ+zHYwBDwOxOVmt2R
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3588 VOP2 fetches through two AXI read ports. Every window has a
fixed default port in rk3588_vop_win_data: Cluster0/1 and Esmart0/1 use
AXI0, Cluster2/3 and Esmart2/3 use AXI1. The port is chosen by a per
window register (CLUSTER_CTRL[13] / ESMART_AXI_CTRL[1]), though, and it
is programmed on every plane update.

One port can't sustain two full screen 4K@120Hz layers. With the
console on Cluster0 (the primary plane of video port 0) and a video on
Esmart0 (its overlay plane), both on AXI0, HDMI 3840x2160@120 reports
POST_BUF_EMPTY on about half of all lines (~120000 per second) and the
picture is scrambled. The VOP read rate measured with the DDR PMU drops
from the expected 6.3 GB/s to 3.2 GB/s: the fetch collapses instead of
merely saturating. Measured at 4K@120Hz, XR24 primary plane:

  Cluster0 + Esmart0 (AXI0 + AXI0)	~120k POST_BUF_EMPTY/s
  Cluster2 + Esmart2 (AXI1 + AXI1)	~100k/s
  Esmart0 + Esmart1  (AXI0 + AXI0)	~90k/s (XR24 both)
  Cluster0 + Esmart2 (AXI0 + AXI1)	0, 9.2 GB/s read
  Cluster0 + Cluster2 (AXI0 + AXI1)	0, 8.6 GB/s read

Moving Esmart0 to AXI1 at runtime (with no other change) makes the
first case clean. Raising ACLK_VOP from 750 to 850 MHz, or changing
the NoC QoS priority or mode of the VOP ports, makes no difference,
and neither does the buffer placement (both planes scanning out the
same buffer fail the same way). So the limit is per port, and the
fixed assignment puts both layers of the most common configuration on
the same port while the other one sits idle. Lower modes are affected
too: the same port also carries Cluster1 for a second display, and
under DDR contention from other masters a 4K@60Hz port with the
console, an overlay and a second display underflows for short bursts.

Choose the port of a window when it starts fetching instead. The atomic
check assigns the ports from the whole new state and keeps the
assignment in a private object for the next check. The port of a window
is also stored in its plane state, and that is what the plane update
programs: commits on different video ports aren't ordered against each
other, so the private state of a commit may already be replaced and
freed when its planes are updated. A window that keeps fetching keeps
its port, so an active layer is never moved. The windows
that start fetching, the busiest first, each get the port that leaves
the busier port least loaded, preferring the default one on a tie. The
load of a window is its estimated fetch rate: source size x bits per
pixel of all its planes x refresh rate.

A window must not share an AXI read ID with another window on the same
port. The IDs in the table are unique per default port, and mirrored
between the two ports (Cluster0/Cluster2, Esmart0/Esmart2, ...), so a
window can always use the port its mirror isn't on. A window that is
switched off keeps fetching until the next frame start of its video
port, so its read IDs stay in use for a window that starts on another
video port in the same commit, and until the commit that switched it
off is done.

This is only enabled for RK3588, where it was measured.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.c | 330 ++++++++++++++++++++++++++-
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.h |  42 ++++
 drivers/gpu/drm/rockchip/rockchip_vop2_reg.c |   3 +-
 3 files changed, 370 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
index 7c157f5c1734..684fa46924e7 100644
--- a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
+++ b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
@@ -23,6 +23,7 @@
 
 #include <drm/drm.h>
 #include <drm/drm_atomic.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_atomic_uapi.h>
 #include <drm/drm_blend.h>
 #include <drm/drm_crtc.h>
@@ -1231,6 +1232,314 @@ static int vop2_plane_atomic_check(struct drm_plane *plane,
 	return 0;
 }
 
+static bool vop2_win_axi_ids_clash(const struct vop2_win *a, const struct vop2_win *b)
+{
+	u8 ida[] = { a->data->axi_yrgb_r_id, a->data->axi_uv_r_id };
+	u8 idb[] = { b->data->axi_yrgb_r_id, b->data->axi_uv_r_id };
+	int i, j;
+
+	for (i = 0; i < ARRAY_SIZE(ida); i++)
+		for (j = 0; j < ARRAY_SIZE(idb); j++)
+			if (ida[i] == idb[j])
+				return true;
+
+	return false;
+}
+
+/*
+ * The VOP2 on RK3588 has two AXI read ports. Each window has a default port
+ * (&vop2_win_data.axi_bus_id), but the port is selected by a per window
+ * register, so any window can fetch through either one as long as its read
+ * IDs are unique on that port.
+ *
+ * A single port can't sustain much more than one full screen 4K@120Hz
+ * layer: two such layers on the same port (e.g. Cluster0 and Esmart0, the
+ * default primary and overlay planes of video port 0) make the window
+ * line buffers run dry, the fetch rate collapses and the video port
+ * reports POST_BUF_EMPTY on most lines, which scrambles the picture. The
+ * same layers fetched through different ports are fine. Raising ACLK or
+ * the NoC priority of the VOP doesn't help, the limit is per port.
+ *
+ * So the atomic check assigns a port to every window that starts fetching,
+ * from the whole new state: a window that keeps fetching keeps its port,
+ * and the new ones, the busiest first, get the port that leaves the busier
+ * of the two ports least loaded, preferring the default one. A window
+ * never gets a port on which another window may still fetch with one of
+ * its read IDs.
+ *
+ * The assignment of all windows is kept in a private object for the next
+ * atomic check. The plane update takes the port of its window from the
+ * plane state instead: commits on different video ports aren't ordered
+ * against each other, so a later one may have replaced and freed the
+ * private state by the time the planes of this one are updated.
+ */
+#define to_vop2_axi_state(s) container_of(s, struct vop2_axi_state, base)
+#define to_vop2_plane_state(s) container_of(s, struct vop2_plane_state, base)
+
+static struct drm_private_state *vop2_axi_duplicate_state(struct drm_private_obj *obj)
+{
+	struct vop2 *vop2 = container_of(obj, struct vop2, axi_obj);
+	struct vop2_axi_state *state;
+
+	state = kmemdup(to_vop2_axi_state(obj->state),
+			struct_size(state, win, vop2->registered_num_wins),
+			GFP_KERNEL);
+	if (!state)
+		return NULL;
+
+	__drm_atomic_helper_private_obj_duplicate_state(obj, &state->base);
+
+	return &state->base;
+}
+
+static void vop2_axi_destroy_state(struct drm_private_obj *obj,
+				   struct drm_private_state *state)
+{
+	kfree(to_vop2_axi_state(state));
+}
+
+static struct drm_private_state *vop2_axi_create_state(struct drm_private_obj *obj)
+{
+	struct vop2 *vop2 = container_of(obj, struct vop2, axi_obj);
+	struct vop2_axi_state *state;
+	int i;
+
+	state = kzalloc(struct_size(state, win, vop2->registered_num_wins),
+			GFP_KERNEL);
+	if (!state)
+		return ERR_PTR(-ENOMEM);
+
+	for (i = 0; i < vop2->registered_num_wins; i++)
+		state->win[i].bus = vop2->win[i].data->axi_bus_id;
+
+	__drm_atomic_helper_private_obj_create_state(obj, &state->base);
+
+	return &state->base;
+}
+
+static const struct drm_private_state_funcs vop2_axi_state_funcs = {
+	.atomic_create_state = vop2_axi_create_state,
+	.atomic_duplicate_state = vop2_axi_duplicate_state,
+	.atomic_destroy_state = vop2_axi_destroy_state,
+};
+
+/* Bytes per second the window fetches, from all planes of the framebuffer */
+static u64 vop2_plane_axi_load(const struct drm_plane_state *pstate,
+			       const struct drm_display_mode *mode)
+{
+	const struct drm_format_info *info = pstate->fb->format;
+	u64 pixels = (u64)(drm_rect_width(&pstate->src) >> 16) *
+		     (drm_rect_height(&pstate->src) >> 16) *
+		     drm_mode_vrefresh(mode);
+	u32 bits = 0;
+	int i;
+
+	/* Single plane formats like YUV420_8BIT have no cpp */
+	if (info->num_planes == 1)
+		return div_u64(pixels * vop2_get_bpp(info), 8);
+
+	for (i = 0; i < info->num_planes; i++)
+		bits += drm_format_info_bpp(info, i) /
+			(i ? info->hsub * info->vsub : 1);
+
+	return div_u64(pixels * bits, 8);
+}
+
+/* The CRTC state of the plane if its window fetches in the new state */
+static const struct drm_crtc_state *
+vop2_plane_fetch_crtc_state(struct drm_atomic_commit *state,
+			    const struct drm_plane_state *pstate)
+{
+	const struct drm_crtc_state *cstate;
+
+	if (!pstate->crtc || !pstate->fb || !pstate->visible)
+		return NULL;
+
+	cstate = drm_atomic_get_new_crtc_state(state, pstate->crtc);
+
+	return cstate && cstate->active ? cstate : NULL;
+}
+
+/*
+ * Whether a window that doesn't fetch in the new state may still fetch while
+ * a window starts on @crtc. The window registers are latched at the frame
+ * start of their video port: a window switched off in this commit stops
+ * together with the new one only on the same video port, and one switched
+ * off in an earlier commit once that commit is done.
+ */
+static int vop2_win_may_fetch(struct drm_atomic_commit *state,
+			      struct vop2_win *win, const struct drm_crtc *crtc,
+			      bool *fetching)
+{
+	const struct drm_plane_state *old = drm_atomic_get_old_plane_state(state, &win->base);
+	struct drm_crtc_commit *commit;
+	int ret;
+
+	if (old) {
+		*fetching = old->crtc && old->crtc != crtc;
+		return 0;
+	}
+
+	ret = drm_modeset_lock(&win->base.mutex, state->acquire_ctx);
+	if (ret)
+		return ret;
+
+	commit = win->base.state->commit;
+	*fetching = commit && !try_wait_for_completion(&commit->flip_done);
+
+	return 0;
+}
+
+static u8 vop2_axi_pick_bus(u8 def, const u64 *bus_load, const bool *clash, u64 load)
+{
+	if (!clash[def ^ 1] &&
+	    (clash[def] || max(bus_load[def ^ 1] + load, bus_load[def]) <
+			   max(bus_load[def] + load, bus_load[def ^ 1])))
+		return def ^ 1;
+
+	return def;
+}
+
+static int vop2_axi_check(struct vop2 *vop2, struct drm_atomic_commit *state)
+{
+	unsigned int n = vop2->registered_num_wins;
+	const struct vop2_axi_state *old;
+	struct drm_private_state *priv;
+	struct vop2_axi_state *new;
+	unsigned long start = 0;
+	bool changed = false;
+	unsigned int i, j;
+	int ret;
+
+	if (!(vop2->data->feature & VOP2_FEATURE_AXI_BALANCE))
+		return 0;
+
+	for (i = 0; i < n; i++)
+		if (drm_atomic_get_new_plane_state(state, &vop2->win[i].base))
+			changed = true;
+
+	if (!changed)
+		return 0;
+
+	priv = drm_atomic_get_private_obj_state(state, &vop2->axi_obj);
+	if (IS_ERR(priv))
+		return PTR_ERR(priv);
+
+	new = to_vop2_axi_state(priv);
+	old = to_vop2_axi_state(drm_atomic_get_old_private_obj_state(state,
+								     &vop2->axi_obj));
+
+	for (i = 0; i < n; i++) {
+		const struct drm_plane_state *pstate;
+		const struct drm_crtc_state *cstate;
+
+		new->win[i] = old->win[i];
+
+		pstate = drm_atomic_get_new_plane_state(state, &vop2->win[i].base);
+		if (!pstate)
+			continue;
+
+		cstate = vop2_plane_fetch_crtc_state(state, pstate);
+		new->win[i].load = cstate ? vop2_plane_axi_load(pstate, &cstate->adjusted_mode) : 0;
+		new->win[i].active = cstate && old->win[i].active;
+		if (cstate && !old->win[i].active)
+			start |= BIT(i);
+	}
+
+	while (start) {
+		u64 bus_load[VOP2_SYS_AXI_BUS_NUM] = { };
+		bool clash[VOP2_SYS_AXI_BUS_NUM] = { };
+		const struct drm_plane_state *pstate;
+		struct vop2_win *win;
+		unsigned int k = n;
+		u8 bus;
+
+		for_each_set_bit(j, &start, n)
+			if (k == n || new->win[j].load > new->win[k].load)
+				k = j;
+
+		win = &vop2->win[k];
+		pstate = drm_atomic_get_new_plane_state(state, &win->base);
+
+		for (j = 0; j < n; j++) {
+			struct vop2_win *w = &vop2->win[j];
+			bool fetching = new->win[j].active;
+
+			if (j == k || (start & BIT(j)))
+				continue;
+
+			if (fetching)
+				bus_load[new->win[j].bus] += new->win[j].load;
+
+			if (!vop2_win_axi_ids_clash(win, w))
+				continue;
+
+			if (!fetching) {
+				ret = vop2_win_may_fetch(state, w, pstate->crtc, &fetching);
+				if (ret)
+					return ret;
+			}
+
+			if (fetching)
+				clash[new->win[j].bus] = true;
+		}
+
+		bus = vop2_axi_pick_bus(win->data->axi_bus_id, bus_load, clash,
+					new->win[k].load);
+		if (clash[bus]) {
+			drm_dbg_kms(vop2->drm, "%s: no AXI port with free read IDs\n",
+				    win->data->name);
+			return -EINVAL;
+		}
+
+		new->win[k].bus = bus;
+		new->win[k].active = true;
+		start &= ~BIT(k);
+	}
+
+	/* The plane update programs the port from the plane state */
+	for (i = 0; i < n; i++) {
+		struct drm_plane_state *pstate;
+
+		pstate = drm_atomic_get_new_plane_state(state, &vop2->win[i].base);
+		if (pstate)
+			to_vop2_plane_state(pstate)->axi_bus = new->win[i].bus;
+	}
+
+	return 0;
+}
+
+static struct drm_plane_state *vop2_plane_create_state(struct drm_plane *plane)
+{
+	struct vop2_plane_state *vpstate;
+
+	vpstate = kzalloc_obj(*vpstate);
+	if (!vpstate)
+		return ERR_PTR(-ENOMEM);
+
+	__drm_atomic_helper_plane_state_init(&vpstate->base, plane);
+	vpstate->axi_bus = to_vop2_win(plane)->data->axi_bus_id;
+
+	return &vpstate->base;
+}
+
+static struct drm_plane_state *vop2_plane_duplicate_state(struct drm_plane *plane)
+{
+	struct vop2_plane_state *vpstate;
+
+	if (WARN_ON(!plane->state))
+		return NULL;
+
+	vpstate = kmemdup(to_vop2_plane_state(plane->state), sizeof(*vpstate),
+			  GFP_KERNEL);
+	if (!vpstate)
+		return NULL;
+
+	__drm_atomic_helper_plane_duplicate_state(plane, &vpstate->base);
+
+	return &vpstate->base;
+}
+
 static void vop2_plane_atomic_disable(struct drm_plane *plane,
 				      struct drm_atomic_commit *state)
 {
@@ -1418,7 +1727,8 @@ static void vop2_plane_atomic_update(struct drm_plane *plane,
 		afbc_en ? "AFBC" : "", &yrgb_mst);
 
 	if (vop2->version > VOP_VERSION_RK3568) {
-		vop2_win_write(win, VOP2_WIN_AXI_BUS_ID, win->data->axi_bus_id);
+		vop2_win_write(win, VOP2_WIN_AXI_BUS_ID,
+			       to_vop2_plane_state(pstate)->axi_bus);
 		vop2_win_write(win, VOP2_WIN_AXI_YRGB_R_ID, win->data->axi_yrgb_r_id);
 		vop2_win_write(win, VOP2_WIN_AXI_UV_R_ID, win->data->axi_uv_r_id);
 	}
@@ -1565,8 +1875,8 @@ static const struct drm_plane_funcs vop2_plane_funcs = {
 	.update_plane	= drm_atomic_helper_update_plane,
 	.disable_plane	= drm_atomic_helper_disable_plane,
 	.destroy = drm_plane_cleanup,
-	.atomic_create_state = drm_atomic_helper_plane_create_state,
-	.atomic_duplicate_state = drm_atomic_helper_plane_duplicate_state,
+	.atomic_create_state = vop2_plane_create_state,
+	.atomic_duplicate_state = vop2_plane_duplicate_state,
 	.atomic_destroy_state = drm_atomic_helper_plane_destroy_state,
 	.format_mod_supported = rockchip_vop2_mod_supported,
 };
@@ -2086,7 +2396,7 @@ static int vop2_crtc_atomic_check(struct drm_crtc *crtc,
 	if (nplanes > vp->nlayers)
 		return -EINVAL;
 
-	return 0;
+	return vop2_axi_check(vp->vop2, state);
 }
 
 static void vop2_crtc_atomic_begin(struct drm_crtc *crtc,
@@ -3016,6 +3326,13 @@ static int vop2_bind(struct device *dev, struct device *master, void *data)
 	if (ret)
 		return ret;
 
+	if (vop2_data->feature & VOP2_FEATURE_AXI_BALANCE) {
+		ret = drm_atomic_private_obj_init(drm, &vop2->axi_obj,
+						  &vop2_axi_state_funcs);
+		if (ret)
+			goto err_crtcs;
+	}
+
 	if (vop2->version >= VOP_VERSION_RK3576) {
 		struct drm_crtc *crtc;
 
@@ -3060,6 +3377,8 @@ static int vop2_bind(struct device *dev, struct device *master, void *data)
 	return 0;
 
 err_crtcs:
+	if (vop2->axi_obj.state)
+		drm_atomic_private_obj_fini(&vop2->axi_obj);
 	vop2_destroy_crtcs(vop2);
 
 	return ret;
@@ -3074,6 +3393,9 @@ static void vop2_unbind(struct device *dev, struct device *master, void *data)
 	if (vop2->rgb)
 		rockchip_rgb_fini(vop2->rgb);
 
+	if (vop2->axi_obj.state)
+		drm_atomic_private_obj_fini(&vop2->axi_obj);
+
 	vop2_destroy_crtcs(vop2);
 }
 
diff --git a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h
index 1c2d7d97a6c2..48a852fec2bf 100644
--- a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h
+++ b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h
@@ -8,6 +8,7 @@
 #define _ROCKCHIP_DRM_VOP2_H
 
 #include <linux/regmap.h>
+#include <drm/drm_atomic.h>
 #include <drm/drm_modes.h>
 #include <dt-bindings/soc/rockchip,vop2.h>
 #include "rockchip_drm_drv.h"
@@ -29,6 +30,7 @@
 #define VOP2_FEATURE_HAS_VO1_GRF	BIT(2)
 #define VOP2_FEATURE_HAS_VOP_GRF	BIT(3)
 #define VOP2_FEATURE_HAS_SYS_PMU	BIT(4)
+#define VOP2_FEATURE_AXI_BALANCE	BIT(5)
 
 #define WIN_FEATURE_AFBDC		BIT(0)
 #define WIN_FEATURE_CLUSTER		BIT(1)
@@ -221,6 +223,40 @@ struct vop2_win {
 	enum drm_plane_type type;
 };
 
+/**
+ * struct vop2_axi_win - AXI read port use of a window
+ * @load: estimated fetch rate in bytes/s, 0 if the window doesn't fetch
+ * @bus: AXI read port the window fetches through, or last fetched through
+ * @active: the window fetches
+ */
+struct vop2_axi_win {
+	u64 load;
+	u8 bus;
+	bool active;
+};
+
+/**
+ * struct vop2_axi_state - AXI read port assignment of all windows
+ * @base: private object state
+ * @win: one entry per window, indexed like &vop2.win
+ */
+struct vop2_axi_state {
+	struct drm_private_state base;
+	struct vop2_axi_win win[];
+};
+
+/**
+ * struct vop2_plane_state - plane state of a window
+ * @base: DRM plane state
+ * @axi_bus: AXI read port the window fetches through, the default one of
+ *	the window unless the atomic check assigned one
+ *	(VOP2_FEATURE_AXI_BALANCE)
+ */
+struct vop2_plane_state {
+	struct drm_plane_state base;
+	u8 axi_bus;
+};
+
 struct vop2_video_port_data {
 	unsigned int id;
 	u32 feature;
@@ -356,6 +392,12 @@ struct vop2 {
 	 */
 	struct mutex ovl_lock;
 
+	/**
+	 * @axi_obj: AXI read port assignment of the windows (&struct
+	 * vop2_axi_state), with VOP2_FEATURE_AXI_BALANCE only
+	 */
+	struct drm_private_obj axi_obj;
+
 	/* must be put at the end of the struct */
 	struct vop2_win win[];
 };
diff --git a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
index 7c48b440cb29..83203d18865b 100644
--- a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
+++ b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
@@ -2577,7 +2577,8 @@ static const struct vop2_data rk3576_vop = {
 static const struct vop2_data rk3588_vop = {
 	.version = VOP_VERSION_RK3588,
 	.feature = VOP2_FEATURE_HAS_SYS_GRF | VOP2_FEATURE_HAS_VO1_GRF |
-		   VOP2_FEATURE_HAS_VOP_GRF | VOP2_FEATURE_HAS_SYS_PMU,
+		   VOP2_FEATURE_HAS_VOP_GRF | VOP2_FEATURE_HAS_SYS_PMU |
+		   VOP2_FEATURE_AXI_BALANCE,
 	.nr_vps = 4,
 	.max_input = { 4096, 4320 },
 	.max_output = { 4096, 4320 },

-- 
2.55.0

