From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:39 +1000
Subject: [PATCH 04/19] drm/amd/display/amdgpu_dm: Use DC accessors in
 audio/color/backlight paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-4-0fae41718ad2@redhat.com>
References: <20261112-amdgpu-dc-cleanup-v1-0-0fae41718ad2@redhat.com>
In-Reply-To: <20261112-amdgpu-dc-cleanup-v1-0-0fae41718ad2@redhat.com>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Austin Zheng <austin.zheng@amd.com>, 
 Jun Lei <jun.lei@amd.com>, Kenneth Feng <kenneth.feng@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=11767; i=airlied@redhat.com;
 h=from:subject:message-id; bh=TY/q0gWJFs33PtJy4UkFf+VC4XGPXUVbIXrTRglHCl8=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnOSMKNTCMYMukUJzh9MNnzp3z0vhLZK6m4/
 zSOywv7VBKJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZzgAKCRAMdPNZecSG
 vnGED/4oRyfS3FklG+ceX+x2xLDVuiz9i3HmCTgAZ2tVmxVFJbMjIxJOEwELd5LKMnGOQcfwtjc
 vtntcMmToNfq31eYgqUdeuq1bo3/gh1rBz2mASU1vRw29ZhQNZOxuaBFu+jtYPAv/aeUu5xiBsS
 tNvXNkQUAdmRkPSXBIsT79ytYQIjqvT6vOV5gF3uON3GRxFeUshT2Pq1GJmalVHoKQ5XfIXX1gq
 1gSSAXJtU96JPg1oBYxDRHuBtLg4XM99eZvXGOWPuwI2M0AeIWmeUvEvOGNa7uvYFuhptQVo19R
 SULcTeLkxpAG3E5N4qGy9iu8EX297LjWhdrJVTusBBgMLtTbtbU+9pVvy0E/QHRitx3c0GFvpVd
 /cgoQzYC7TN8niPMqbTSIIWMzNBjlXmosrSHjYsqMrMJJYo7hmXvNBOcWEEJZ55YFNWzemIfMXd
 6X/NMDEiVMoQ8b+RsYLbYqqCJwqbUElO/+4nwKU/kcFzVMVZdiQDCDKdgmauhaDdsjz3zrpNdTK
 sgsfKcIAcevv44MmwLU6zTPPlNHTzQtBNgWn70sPclojv2Q2JqZ94hVW34YwpMsaL6NXmwsRKSC
 hQ8/QJfVZQ6fGTvdPnfPmG0iJRaBtZsVyzcta1qlCFo2Yf6WUUaKv9MhmaqOhJrlqBYfZ4Y8c1s
 lRu+niKflWHAYFw==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace direct struct dc member dereferences with the DC accessor
layer in amdgpu_dm_audio.c, amdgpu_dm_color.c, amdgpu_dm_colorop.c
and amdgpu_dm_backlight.c.

Part of making struct dc private to DC.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c    |  6 +++--
 .../amd/display/amdgpu_dm/amdgpu_dm_backlight.c    |  6 ++---
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_color.c    | 28 +++++++++++++---------
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_color.h    |  4 ++--
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_colorop.c  |  4 ++--
 .../drm/amd/display/modules/color/color_gamma.c    |  2 +-
 .../drm/amd/display/modules/color/color_gamma.h    |  2 +-
 7 files changed, 30 insertions(+), 22 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c
index 199f339839b2..97cc52f45a2e 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c
@@ -140,6 +140,7 @@ EXPORT_IF_KUNIT(amdgpu_dm_audio_init_pins);
 int amdgpu_dm_audio_init(struct amdgpu_device *adev)
 {
 	unsigned int inst_array[MAX_AUDIOS];
+	struct resource_pool *res_pool;
 	int audio_count;
 	int i, ret;
 
@@ -148,9 +149,10 @@ int amdgpu_dm_audio_init(struct amdgpu_device *adev)
 
 	adev->mode_info.audio.enabled = true;
 
-	audio_count = adev->dm.dc->res_pool->audio_count;
+	res_pool = dc_get_res_pool(adev->dm.dc);
+	audio_count = res_pool->audio_count;
 	for (i = 0; i < audio_count; i++)
-		inst_array[i] = adev->dm.dc->res_pool->audios[i]->inst;
+		inst_array[i] = res_pool->audios[i]->inst;
 	amdgpu_dm_audio_init_pins(adev, audio_count, inst_array);
 
 	ret = component_add(adev->dev, &amdgpu_dm_audio_component_bind_ops);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
index cb74b00723fd..3d268703c551 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
@@ -296,7 +296,7 @@ struct dc_stream_state *dm_find_stream_with_link(
 	struct amdgpu_display_manager *dm,
 	struct dc_link *link)
 {
-	struct dc_state *cur_dc_state = dm->dc->current_state;
+	struct dc_state *cur_dc_state = dc_get_current_state(dm->dc);
 	struct dc_stream_state *stream = NULL;
 	int i;
 
@@ -383,7 +383,7 @@ void amdgpu_dm_backlight_set_level(struct amdgpu_display_manager *dm,
 	}
 
 	mutex_lock(&dm->dc_lock);
-	if (dm->dc->caps.ips_support && dm->dc->ctx->dmub_srv->idle_allowed) {
+	if (dc_get_caps(dm->dc)->ips_support && dc_get_ctx(dm->dc)->dmub_srv->idle_allowed) {
 		dc_allow_idle_optimizations(dm->dc, false);
 		reallow_idle = true;
 	}
@@ -415,7 +415,7 @@ void amdgpu_dm_backlight_set_level(struct amdgpu_display_manager *dm,
 	amdgpu_dm_replay_set_event(dm, stream, true,
 		replay_event_hw_programming, true);
 
-	if (dm->dc->caps.ips_support && reallow_idle)
+	if (dc_get_caps(dm->dc)->ips_support && reallow_idle)
 		dc_allow_idle_optimizations(dm->dc, true);
 
 	mutex_unlock(&dm->dc_lock);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.c
index f9dc9f46a446..d86b9611568b 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.c
@@ -832,7 +832,7 @@ EXPORT_IF_KUNIT(amdgpu_dm_set_atomic_regamma);
  * Returns:
  * 0 in case of success. -ENOMEM if fails.
  */
-STATIC_IFN_KUNIT int __set_input_tf(struct dc_color_caps *caps,
+STATIC_IFN_KUNIT int __set_input_tf(const struct dc_color_caps *caps,
 				    struct dc_transfer_func *func,
 				    const struct drm_color_lut *lut, uint32_t lut_size)
 {
@@ -870,7 +870,7 @@ EXPORT_IF_KUNIT(__set_input_tf);
  * Returns:
  * 0 in case of success. -ENOMEM if fails.
  */
-STATIC_IFN_KUNIT int __set_input_tf_32(struct dc_color_caps *caps,
+STATIC_IFN_KUNIT int __set_input_tf_32(const struct dc_color_caps *caps,
 				       struct dc_transfer_func *func,
 				       const struct drm_color_lut32 *lut, uint32_t lut_size)
 {
@@ -1168,7 +1168,9 @@ int amdgpu_dm_verify_lut3d_size(struct amdgpu_device *adev,
 	struct dm_plane_state *dm_plane_state = to_dm_plane_state(plane_state);
 	const struct drm_color_lut *shaper = NULL, *lut3d = NULL;
 	uint32_t exp_size, size, dim_size = MAX_COLOR_3DLUT_SIZE;
-	bool has_3dlut = adev->dm.dc->caps.color.dpp.hw_3d_lut || adev->dm.dc->caps.color.mpc.preblend;
+	const struct dc_caps *caps = dc_get_caps(adev->dm.dc);
+	bool has_3dlut =
+		caps->color.dpp.hw_3d_lut || caps->color.mpc.preblend;
 
 	/* shaper LUT is only available if 3D LUT color caps */
 	exp_size = has_3dlut ? MAX_COLOR_LUT_ENTRIES : 0;
@@ -1403,7 +1405,7 @@ EXPORT_IF_KUNIT(amdgpu_dm_update_crtc_color_mgmt);
 static int
 map_crtc_degamma_to_dc_plane(struct dm_crtc_state *crtc,
 			     struct dc_plane_state *dc_plane_state,
-			     struct dc_color_caps *caps)
+			     const struct dc_color_caps *caps)
 {
 	const struct drm_color_lut *degamma_lut;
 	enum dc_transfer_func_predefined tf = TRANSFER_FUNCTION_SRGB;
@@ -1483,7 +1485,7 @@ map_crtc_degamma_to_dc_plane(struct dm_crtc_state *crtc,
 static int
 __set_dm_plane_degamma(struct drm_plane_state *plane_state,
 		       struct dc_plane_state *dc_plane_state,
-		       struct dc_color_caps *color_caps)
+		       const struct dc_color_caps *color_caps)
 {
 	struct dm_plane_state *dm_plane_state = to_dm_plane_state(plane_state);
 	const struct drm_color_lut *degamma_lut;
@@ -1551,7 +1553,7 @@ __set_colorop_in_tf_1d_curve(struct dc_plane_state *dc_plane_state,
 	struct dc_transfer_func *tf = &dc_plane_state->in_transfer_func;
 	struct drm_colorop *colorop = colorop_state->colorop;
 	struct drm_device *drm = colorop->dev;
-	struct dc_color_caps *color_caps = NULL;
+	const struct dc_color_caps *color_caps = NULL;
 	bool is_subsampled_format;
 
 	if (colorop->type != DRM_COLOROP_1D_CURVE)
@@ -1575,7 +1577,7 @@ __set_colorop_in_tf_1d_curve(struct dc_plane_state *dc_plane_state,
 	tf->tf = amdgpu_colorop_tf_to_dc_tf(colorop_state->curve_1d_type);
 
 	if (dc_plane_state->ctx && dc_plane_state->ctx->dc)
-		color_caps = &dc_plane_state->ctx->dc->caps.color;
+		color_caps = &dc_get_caps(dc_plane_state->ctx->dc)->color;
 
 	if (!mod_color_calculate_degamma_params(color_caps, tf, NULL,
 						is_subsampled_format)) {
@@ -1865,7 +1867,9 @@ __set_dm_plane_colorop_3dlut(struct drm_plane_state *plane_state,
 	struct dc_transfer_func *tf = &dc_plane_state->cm.shaper_func;
 	struct drm_atomic_commit *state = plane_state->state;
 	const struct amdgpu_device *adev = drm_to_adev(colorop->dev);
-	bool has_3dlut = adev->dm.dc->caps.color.dpp.hw_3d_lut || adev->dm.dc->caps.color.mpc.preblend;
+	const struct dc_caps *caps = dc_get_caps(adev->dm.dc);
+	bool has_3dlut =
+		caps->color.dpp.hw_3d_lut || caps->color.mpc.preblend;
 	const struct drm_device *dev = colorop->dev;
 	const struct drm_color_lut32 *lut3d;
 	uint32_t lut3d_size;
@@ -2044,7 +2048,9 @@ amdgpu_dm_plane_set_colorop_properties(struct drm_plane_state *plane_state,
 	struct drm_colorop *colorop = plane_state->color_pipeline;
 	struct drm_device *dev = plane_state->plane->dev;
 	struct amdgpu_device *adev = drm_to_adev(dev);
-	bool has_3dlut = adev->dm.dc->caps.color.dpp.hw_3d_lut || adev->dm.dc->caps.color.mpc.preblend;
+	const struct dc_caps *caps = dc_get_caps(adev->dm.dc);
+	bool has_3dlut =
+		caps->color.dpp.hw_3d_lut || caps->color.mpc.preblend;
 	int ret;
 
 	/* Fixed Matrix (YUV to RGB) */
@@ -2156,7 +2162,7 @@ int amdgpu_dm_update_plane_color_mgmt(struct dm_crtc_state *crtc,
 	struct amdgpu_device *adev = drm_to_adev(crtc->base.state->dev);
 	struct dm_plane_state *dm_plane_state = to_dm_plane_state(plane_state);
 	struct drm_color_ctm_3x4 *ctm = NULL;
-	struct dc_color_caps *color_caps = NULL;
+	const struct dc_color_caps *color_caps = NULL;
 	bool has_crtc_cm_degamma;
 	int ret;
 
@@ -2167,7 +2173,7 @@ int amdgpu_dm_update_plane_color_mgmt(struct dm_crtc_state *crtc,
 	}
 
 	if (dc_plane_state->ctx && dc_plane_state->ctx->dc)
-		color_caps = &dc_plane_state->ctx->dc->caps.color;
+		color_caps = &dc_get_caps(dc_plane_state->ctx->dc)->color;
 
 	/* Initially, we can just bypass the DGM block. */
 	dc_plane_state->in_transfer_func.type = TF_TYPE_BYPASS;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.h b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.h
index 3e8a3d3fc855..4bda8c47ae09 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.h
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.h
@@ -74,9 +74,9 @@ int __set_output_tf_32(struct dc_transfer_func *func,
 		       const struct drm_color_lut32 *lut, uint32_t lut_size,
 		       bool has_rom);
 struct dc_color_caps;
-int __set_input_tf(struct dc_color_caps *caps, struct dc_transfer_func *func,
+int __set_input_tf(const struct dc_color_caps *caps, struct dc_transfer_func *func,
 		   const struct drm_color_lut *lut, uint32_t lut_size);
-int __set_input_tf_32(struct dc_color_caps *caps, struct dc_transfer_func *func,
+int __set_input_tf_32(const struct dc_color_caps *caps, struct dc_transfer_func *func,
 		      const struct drm_color_lut32 *lut, uint32_t lut_size);
 enum dc_transfer_func_predefined
 amdgpu_tf_to_dc_tf(enum amdgpu_transfer_function tf);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_colorop.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_colorop.c
index c6bb9fec9217..e912256eebb3 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_colorop.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_colorop.c
@@ -299,8 +299,8 @@ int amdgpu_dm_initialize_default_pipeline(struct drm_plane *plane, struct drm_pr
 {
 	struct drm_device *dev = plane->dev;
 	struct amdgpu_device *adev = drm_to_adev(dev);
-	bool hw_3d_lut = adev->dm.dc->caps.color.dpp.hw_3d_lut ||
-			 adev->dm.dc->caps.color.mpc.preblend;
+	bool hw_3d_lut = dc_get_caps(adev->dm.dc)->color.dpp.hw_3d_lut ||
+			 dc_get_caps(adev->dm.dc)->color.mpc.preblend;
 
 	return amdgpu_dm_build_default_pipeline(dev, plane, hw_3d_lut, list);
 }
diff --git a/drivers/gpu/drm/amd/display/modules/color/color_gamma.c b/drivers/gpu/drm/amd/display/modules/color/color_gamma.c
index 5786ef5787ac..f654003e3191 100644
--- a/drivers/gpu/drm/amd/display/modules/color/color_gamma.c
+++ b/drivers/gpu/drm/amd/display/modules/color/color_gamma.c
@@ -1669,7 +1669,7 @@ static bool map_regamma_hw_to_x_user(
 
 #define _EXTRA_POINTS 3
 
-bool mod_color_calculate_degamma_params(struct dc_color_caps *dc_caps,
+bool mod_color_calculate_degamma_params(const struct dc_color_caps *dc_caps,
 		struct dc_transfer_func *input_tf,
 		const struct dc_gamma *ramp, bool map_user_ramp)
 {
diff --git a/drivers/gpu/drm/amd/display/modules/color/color_gamma.h b/drivers/gpu/drm/amd/display/modules/color/color_gamma.h
index 97e55278940e..8b7bc41c87df 100644
--- a/drivers/gpu/drm/amd/display/modules/color/color_gamma.h
+++ b/drivers/gpu/drm/amd/display/modules/color/color_gamma.h
@@ -111,7 +111,7 @@ bool mod_color_calculate_regamma_params(struct dc_transfer_func *output_tf,
 		const struct hdr_tm_params *fs_params,
 		struct calculate_buffer *cal_buffer);
 
-bool mod_color_calculate_degamma_params(struct dc_color_caps *dc_caps,
+bool mod_color_calculate_degamma_params(const struct dc_color_caps *dc_caps,
 		struct dc_transfer_func *output_tf,
 		const struct dc_gamma *ramp, bool mapUserRamp);
 

-- 
2.56.0

