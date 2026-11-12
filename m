From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:54 +1000
Subject: [PATCH 19/19] drm/amd/display: Replace dc_get_caps with
 purpose-built capability queries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-19-0fae41718ad2@redhat.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=40782; i=airlied@redhat.com;
 h=from:subject:message-id; bh=ukKc9BBeYE4L/xxlxBukjGwgOkub9F17tFzZKgZxeOw=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnRJ+FG2a8R1qb3j5BwxwiCl3ZfP43bazxPg
 F/oTNKL1UOJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZ0QAKCRAMdPNZecSG
 vusmD/oDOQCsXMzqjLk2VcaeWacH4De2j6crX4GNCDAkIeWXIP+ajz2OH0VSbR4r6onnxvsWgFz
 gCk0kSzUwX+gGU2MRfCryLMuKsITSNWtnVyzwiKoLRRG2CoHtpg7khYhBWiWTdlb2BadXKMs+r3
 Ug8/RZXRL3WqxUnoyyK/5y67+jleroIRQgetnBE6iTAnQUGrALYQhdMwqeXea5uBoJCneWpfL/r
 R+RwseGexJT4s6LlAauruWZTW4MaS+tuZ1nD1/q7VBz1yqdaSGmbW9IIg/j2xevDAM4yI6VN4EW
 R0deCrrQa7oTYjGHCPGLvXQWK1545WsMDLqIjPFvMxDK3EpB0eAY8tFpQNNrReeYRfOer6Fmpbo
 15Taqs4hBDupMN9JI6aCWeXYicYNj2z7qU2Je+g/EV4yVIE3PW8FDu/Ru2YqSKA3mfEp+ZKbbzY
 MdGw1ljG97JmGAUZ0VKAzLHTKhRoSanqg3QLBwDdbUb8uCH4BLapgWsjOdPr4alQRpZJldFnXyv
 u3R+XoRDdVFgcWMzrasZV2VKDNOZMI0gWJzK6jxp709BRsDCR9K+gRbUvL5xaa9HWys4+ABMOmk
 IgBIcr/xkZZmM67lm92B0FmHbJh9ZReacHuCNxGfAiElAOd9zTQPNxEmntEcTnKf1Z0tetEdUcT
 YgoU5OPCaZdGHhw==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split the caps view accessor into per-capability queries so DM and the
DAL modules no longer read through struct dc_caps:

- scalar getters for is_apu, ips/dmcub support, max links/streams/
  planes/slave planes/cursor size/v_total, vtotal_limited_by_fp2,
  i2c speed, PCON/DSC/fused-io support, SubVP processing delay and
  MALL size
- dc_dmub_supports_psr()/dc_dmub_supports_aux_backlight() for the
  DMUB capability bits
- dc_get_color_caps() copies out the color pipeline capabilities
- dc_get_plane_caps() returns the static plane capability array

The KUnit tests keep installing fake capabilities through the
dc_test_caps() view of their own fake DC.

No production code outside the dc directory reads struct dc members
through a caps view anymore.

Part of making the struct dc sub-structures opaque outside DC.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  |  48 +++++-----
 .../amd/display/amdgpu_dm/amdgpu_dm_backlight.c    |   4 +-
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_color.c    |  38 ++++----
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_colorop.c  |   7 +-
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.c    |   2 +-
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c |  17 ++--
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c  |   6 +-
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c |   2 +-
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_hdcp.c |  10 +-
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c  |  10 +-
 .../amd/display/amdgpu_dm/amdgpu_dm_mst_types.c    |   2 +-
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c    |  26 ++++--
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c  |   4 +-
 drivers/gpu/drm/amd/display/dc/core/dc_accessors.c | 103 ++++++++++++++++++++-
 drivers/gpu/drm/amd/display/dc/inc/dc.h            |  36 ++++++-
 .../drm/amd/display/modules/freesync/freesync.c    |   6 +-
 .../gpu/drm/amd/display/modules/power/power_abm.c  |   2 +-
 .../gpu/drm/amd/display/modules/power/power_psr.c  |   2 +-
 18 files changed, 241 insertions(+), 84 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index 6bfa3e9fe5ae..bc3f9f5f8565 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -204,7 +204,7 @@ STATIC_IFN_KUNIT int dm_crtc_get_scanoutpos(struct amdgpu_device *adev, int crtc
 		return 0;
 	}
 
-	if (dc && dc_get_caps(dc)->ips_support && dc_is_idle_optimizations_allowed(dc))
+	if (dc && dc_get_ips_support(dc) && dc_is_idle_optimizations_allowed(dc))
 		dc_allow_idle_optimizations(dc, false);
 
 	/*
@@ -709,7 +709,7 @@ static int amdgpu_dm_init(struct amdgpu_device *adev)
 	/* temporary enable immediate restore for FAMS2 */
 	debug_opts->fams2_imm_restore_drr = true;
 
-	if (dc_get_caps(adev->dm.dc)->dp_hdmi21_pcon_support)
+	if (dc_get_dp_hdmi21_pcon_support(adev->dm.dc))
 		drm_info(adev_to_drm(adev), "DP-HDMI FRL PCON supported\n");
 
 	r = dm_dmub_hw_init(adev);
@@ -753,18 +753,18 @@ static int amdgpu_dm_init(struct amdgpu_device *adev)
 
 	amdgpu_dm_init_color_mod();
 
-	if (dc_get_caps(adev->dm.dc)->max_links > 0) {
+	if (dc_get_max_links(adev->dm.dc) > 0) {
 		adev->dm.vblank_control_workqueue =
 			create_singlethread_workqueue("dm_vblank_control_workqueue");
 		if (!adev->dm.vblank_control_workqueue)
 			drm_err(adev_to_drm(adev), "failed to initialize vblank_workqueue.\n");
 	}
 
-	if (dc_get_caps(adev->dm.dc)->ips_support &&
+	if (dc_get_ips_support(adev->dm.dc) &&
 	    dc_get_disable_ips(adev->dm.dc) != DMUB_IPS_DISABLE_ALL)
 		adev->dm.idle_workqueue = idle_create_workqueue(adev);
 
-	if (dc_get_caps(adev->dm.dc)->max_links > 0 && adev->family >= AMDGPU_FAMILY_RV) {
+	if (dc_get_max_links(adev->dm.dc) > 0 && adev->family >= AMDGPU_FAMILY_RV) {
 		adev->dm.hdcp_workqueue = hdcp_create_workqueue(adev, &init_params.cp_psp, adev->dm.dc);
 
 		if (!adev->dm.hdcp_workqueue)
@@ -776,7 +776,7 @@ static int amdgpu_dm_init(struct amdgpu_device *adev)
 
 		dc_init_callbacks(adev->dm.dc, &init_params);
 	}
-	if (dc_get_caps(adev->dm.dc)->max_links > 0) {
+	if (dc_get_max_links(adev->dm.dc) > 0) {
 		adev->dm.hdmi_frl_status_polling_wq =
 			create_singlethread_workqueue("hdmi_frl_status_polling_wq");
 		if (!adev->dm.hdmi_frl_status_polling_wq)
@@ -840,8 +840,8 @@ static int amdgpu_dm_init(struct amdgpu_device *adev)
 	/* TODO: Add_display_info? */
 
 	/* TODO use dynamic cursor width */
-	adev_to_drm(adev)->mode_config.cursor_width = dc_get_caps(adev->dm.dc)->max_cursor_size;
-	adev_to_drm(adev)->mode_config.cursor_height = dc_get_caps(adev->dm.dc)->max_cursor_size;
+	adev_to_drm(adev)->mode_config.cursor_width = dc_get_max_cursor_size(adev->dm.dc);
+	adev_to_drm(adev)->mode_config.cursor_height = dc_get_max_cursor_size(adev->dm.dc);
 
 	if (drm_vblank_init(adev_to_drm(adev), adev->dm.display_indexes_num)) {
 		drm_err(adev_to_drm(adev),
@@ -949,7 +949,7 @@ static void amdgpu_dm_fini(struct amdgpu_device *adev)
 					&adev->dm.boot_time_crc_info.cpu_addr);
 
 	if (adev->dm.hpd_rx_offload_wq && adev->dm.dc) {
-		for (i = 0; i < dc_get_caps(adev->dm.dc)->max_links; i++) {
+		for (i = 0; i < dc_get_max_links(adev->dm.dc); i++) {
 			if (adev->dm.hpd_rx_offload_wq[i].wq) {
 				destroy_workqueue(adev->dm.hpd_rx_offload_wq[i].wq);
 				adev->dm.hpd_rx_offload_wq[i].wq = NULL;
@@ -1672,7 +1672,7 @@ static int dm_suspend(struct amdgpu_ip_block *ip_block)
 
 	dc_set_power_state(dm->dc, DC_ACPI_CM_POWER_STATE_D3);
 
-	if (dc_get_caps(dm->dc)->ips_support && adev->in_s0ix)
+	if (dc_get_ips_support(dm->dc) && adev->in_s0ix)
 		dc_allow_idle_optimizations(dm->dc, true);
 
 	dc_dmub_srv_set_power_state(dc_get_ctx(dm->dc)->dmub_srv, DC_ACPI_CM_POWER_STATE_D3);
@@ -1897,7 +1897,7 @@ static int dm_resume(struct amdgpu_ip_block *ip_block)
 	int i, r, j;
 	struct dc_commit_streams_params commit_params = {};
 
-	if (dc_get_caps(dm->dc)->ips_support) {
+	if (dc_get_ips_support(dm->dc)) {
 		if (!amdgpu_in_reset(adev))
 			mutex_lock(&dm->dc_lock);
 
@@ -2343,7 +2343,7 @@ STATIC_IFN_KUNIT int initialize_plane(struct amdgpu_display_manager *dm,
 	 * for a CRTC - like overlay or underlay planes.
 	 */
 	possible_crtcs = 1 << plane_id;
-	if (plane_id >= dc_get_caps(dm->dc)->max_streams)
+	if (plane_id >= dc_get_max_streams(dm->dc))
 		possible_crtcs = 0xff;
 
 	ret = amdgpu_dm_plane_init(dm, plane, possible_crtcs, plane_cap);
@@ -2380,25 +2380,28 @@ static int amdgpu_dm_initialize_drm_device(struct amdgpu_device *adev)
 	u32 link_cnt;
 	s32 primary_planes;
 	enum dc_connection_type new_connection_type = dc_connection_none;
+	const struct dc_plane_cap *plane_caps;
+	unsigned int plane_count;
 	const struct dc_plane_cap *plane;
 	bool psr_feature_enabled = false;
 	bool replay_feature_enabled = false;
-	int max_overlay = dc_get_caps(dm->dc)->max_slave_planes;
+	int max_overlay = dc_get_max_slave_planes(dm->dc);
 
-	dm->display_indexes_num = dc_get_caps(dm->dc)->max_streams;
+	dm->display_indexes_num = dc_get_max_streams(dm->dc);
 	/* Update the actual used number of crtc */
 	adev->mode_info.num_crtc = adev->dm.display_indexes_num;
 
 	amdgpu_dm_set_irq_funcs(adev);
 
-	link_cnt = dc_get_caps(dm->dc)->max_links;
+	link_cnt = dc_get_max_links(dm->dc);
+	plane_caps = dc_get_plane_caps(dm->dc, &plane_count);
 	if (amdgpu_dm_mode_config_init(dm->adev)) {
 		drm_err(adev_to_drm(adev), "DM: Failed to initialize mode config\n");
 		return -EINVAL;
 	}
 
 	/* There is one primary plane per CRTC */
-	primary_planes = dc_get_caps(dm->dc)->max_streams;
+	primary_planes = dc_get_max_streams(dm->dc);
 	if (primary_planes > AMDGPU_MAX_PLANES) {
 		drm_err(adev_to_drm(adev), "DM: Plane nums out of 6 planes\n");
 		return -EINVAL;
@@ -2409,7 +2412,7 @@ static int amdgpu_dm_initialize_drm_device(struct amdgpu_device *adev)
 	 * Order is reversed to match iteration order in atomic check.
 	 */
 	for (i = (primary_planes - 1); i >= 0; i--) {
-		plane = &dc_get_caps(dm->dc)->planes[i];
+		plane = &plane_caps[i];
 
 		if (initialize_plane(dm, mode_info, i,
 				     DRM_PLANE_TYPE_PRIMARY, plane)) {
@@ -2427,8 +2430,8 @@ static int amdgpu_dm_initialize_drm_device(struct amdgpu_device *adev)
 	 * Only support DCN for now, and only expose one so we don't encourage
 	 * userspace to use up all the pipes.
 	 */
-	for (i = 0; i < dc_get_caps(dm->dc)->max_planes; ++i) {
-		const struct dc_plane_cap *plane = &dc_get_caps(dm->dc)->planes[i];
+	for (i = 0; i < plane_count; ++i) {
+		const struct dc_plane_cap *plane = &plane_caps[i];
 
 		/* Do not create overlay if MPO disabled */
 		if (amdgpu_dc_debug_mask & DC_DISABLE_MPO)
@@ -2450,7 +2453,7 @@ static int amdgpu_dm_initialize_drm_device(struct amdgpu_device *adev)
 		}
 	}
 
-	for (i = 0; i < dc_get_caps(dm->dc)->max_streams; i++)
+	for (i = 0; i < dc_get_max_streams(dm->dc); i++)
 		if (amdgpu_dm_crtc_init(dm, mode_info->planes[i], i)) {
 			drm_err(adev_to_drm(adev), "KMS: Failed to initialize crtc\n");
 			goto fail;
@@ -3681,6 +3684,7 @@ STATIC_IFN_KUNIT void amdgpu_dm_update_cursor(struct drm_plane *plane,
 	uint64_t address = afb ? afb->address : 0;
 	struct dc_cursor_position position = {0};
 	struct dc_cursor_attributes attributes;
+	struct dc_color_caps color_caps;
 	int ret;
 
 	if (!plane->state->fb && !old_plane_state->fb)
@@ -3707,6 +3711,7 @@ STATIC_IFN_KUNIT void amdgpu_dm_update_cursor(struct drm_plane *plane,
 	amdgpu_crtc->cursor_width = plane->state->crtc_w;
 	amdgpu_crtc->cursor_height = plane->state->crtc_h;
 
+	dc_get_color_caps(adev->dm.dc, &color_caps);
 	memset(&attributes, 0, sizeof(attributes));
 	attributes.address.high_part = upper_32_bits(address);
 	attributes.address.low_part  = lower_32_bits(address);
@@ -3719,8 +3724,7 @@ STATIC_IFN_KUNIT void amdgpu_dm_update_cursor(struct drm_plane *plane,
 	/* Enable cursor degamma ROM on DCN3+ for implicit sRGB degamma in DRM
 	 * legacy gamma setup.
 	 */
-	if (crtc_state->cm_is_degamma_srgb &&
-	    dc_get_caps(adev->dm.dc)->color.dpp.gamma_corr)
+	if (crtc_state->cm_is_degamma_srgb && color_caps.dpp.gamma_corr)
 		attributes.attribute_flags.bits.ENABLE_CURSOR_DEGAMMA = 1;
 
 	if (afb)
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
index 194e52fdd9f5..efa1fe24d952 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
@@ -383,7 +383,7 @@ void amdgpu_dm_backlight_set_level(struct amdgpu_display_manager *dm,
 	}
 
 	mutex_lock(&dm->dc_lock);
-	if (dc_get_caps(dm->dc)->ips_support && dc_get_ctx(dm->dc)->dmub_srv->idle_allowed) {
+	if (dc_get_ips_support(dm->dc) && dc_get_ctx(dm->dc)->dmub_srv->idle_allowed) {
 		dc_allow_idle_optimizations(dm->dc, false);
 		reallow_idle = true;
 	}
@@ -415,7 +415,7 @@ void amdgpu_dm_backlight_set_level(struct amdgpu_display_manager *dm,
 	amdgpu_dm_replay_set_event(dm, stream, true,
 		replay_event_hw_programming, true);
 
-	if (dc_get_caps(dm->dc)->ips_support && reallow_idle)
+	if (dc_get_ips_support(dm->dc) && reallow_idle)
 		dc_allow_idle_optimizations(dm->dc, true);
 
 	mutex_unlock(&dm->dc_lock);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.c
index d86b9611568b..fd547e64f5d1 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_color.c
@@ -1168,9 +1168,11 @@ int amdgpu_dm_verify_lut3d_size(struct amdgpu_device *adev,
 	struct dm_plane_state *dm_plane_state = to_dm_plane_state(plane_state);
 	const struct drm_color_lut *shaper = NULL, *lut3d = NULL;
 	uint32_t exp_size, size, dim_size = MAX_COLOR_3DLUT_SIZE;
-	const struct dc_caps *caps = dc_get_caps(adev->dm.dc);
-	bool has_3dlut =
-		caps->color.dpp.hw_3d_lut || caps->color.mpc.preblend;
+	struct dc_color_caps color_caps;
+	bool has_3dlut;
+
+	dc_get_color_caps(adev->dm.dc, &color_caps);
+	has_3dlut = color_caps.dpp.hw_3d_lut || color_caps.mpc.preblend;
 
 	/* shaper LUT is only available if 3D LUT color caps */
 	exp_size = has_3dlut ? MAX_COLOR_LUT_ENTRIES : 0;
@@ -1553,7 +1555,7 @@ __set_colorop_in_tf_1d_curve(struct dc_plane_state *dc_plane_state,
 	struct dc_transfer_func *tf = &dc_plane_state->in_transfer_func;
 	struct drm_colorop *colorop = colorop_state->colorop;
 	struct drm_device *drm = colorop->dev;
-	const struct dc_color_caps *color_caps = NULL;
+	struct dc_color_caps color_caps = { };
 	bool is_subsampled_format;
 
 	if (colorop->type != DRM_COLOROP_1D_CURVE)
@@ -1577,9 +1579,9 @@ __set_colorop_in_tf_1d_curve(struct dc_plane_state *dc_plane_state,
 	tf->tf = amdgpu_colorop_tf_to_dc_tf(colorop_state->curve_1d_type);
 
 	if (dc_plane_state->ctx && dc_plane_state->ctx->dc)
-		color_caps = &dc_get_caps(dc_plane_state->ctx->dc)->color;
+		dc_get_color_caps(dc_plane_state->ctx->dc, &color_caps);
 
-	if (!mod_color_calculate_degamma_params(color_caps, tf, NULL,
+	if (!mod_color_calculate_degamma_params(&color_caps, tf, NULL,
 						is_subsampled_format)) {
 		drm_err(drm, "Failed to calculate degamma params\n");
 		return -EINVAL;
@@ -1867,9 +1869,11 @@ __set_dm_plane_colorop_3dlut(struct drm_plane_state *plane_state,
 	struct dc_transfer_func *tf = &dc_plane_state->cm.shaper_func;
 	struct drm_atomic_commit *state = plane_state->state;
 	const struct amdgpu_device *adev = drm_to_adev(colorop->dev);
-	const struct dc_caps *caps = dc_get_caps(adev->dm.dc);
-	bool has_3dlut =
-		caps->color.dpp.hw_3d_lut || caps->color.mpc.preblend;
+	struct dc_color_caps color_caps;
+	bool has_3dlut;
+
+	dc_get_color_caps(adev->dm.dc, &color_caps);
+	has_3dlut = color_caps.dpp.hw_3d_lut || color_caps.mpc.preblend;
 	const struct drm_device *dev = colorop->dev;
 	const struct drm_color_lut32 *lut3d;
 	uint32_t lut3d_size;
@@ -2048,9 +2052,11 @@ amdgpu_dm_plane_set_colorop_properties(struct drm_plane_state *plane_state,
 	struct drm_colorop *colorop = plane_state->color_pipeline;
 	struct drm_device *dev = plane_state->plane->dev;
 	struct amdgpu_device *adev = drm_to_adev(dev);
-	const struct dc_caps *caps = dc_get_caps(adev->dm.dc);
-	bool has_3dlut =
-		caps->color.dpp.hw_3d_lut || caps->color.mpc.preblend;
+	struct dc_color_caps color_caps;
+	bool has_3dlut;
+
+	dc_get_color_caps(adev->dm.dc, &color_caps);
+	has_3dlut = color_caps.dpp.hw_3d_lut || color_caps.mpc.preblend;
 	int ret;
 
 	/* Fixed Matrix (YUV to RGB) */
@@ -2162,7 +2168,7 @@ int amdgpu_dm_update_plane_color_mgmt(struct dm_crtc_state *crtc,
 	struct amdgpu_device *adev = drm_to_adev(crtc->base.state->dev);
 	struct dm_plane_state *dm_plane_state = to_dm_plane_state(plane_state);
 	struct drm_color_ctm_3x4 *ctm = NULL;
-	const struct dc_color_caps *color_caps = NULL;
+	struct dc_color_caps color_caps = { };
 	bool has_crtc_cm_degamma;
 	int ret;
 
@@ -2173,7 +2179,7 @@ int amdgpu_dm_update_plane_color_mgmt(struct dm_crtc_state *crtc,
 	}
 
 	if (dc_plane_state->ctx && dc_plane_state->ctx->dc)
-		color_caps = &dc_get_caps(dc_plane_state->ctx->dc)->color;
+		dc_get_color_caps(dc_plane_state->ctx->dc, &color_caps);
 
 	/* Initially, we can just bypass the DGM block. */
 	dc_plane_state->in_transfer_func.type = TF_TYPE_BYPASS;
@@ -2182,7 +2188,7 @@ int amdgpu_dm_update_plane_color_mgmt(struct dm_crtc_state *crtc,
 	/* After, we start to update values according to color props */
 	has_crtc_cm_degamma = (crtc->cm_has_degamma || crtc->cm_is_degamma_srgb);
 
-	ret = __set_dm_plane_degamma(plane_state, dc_plane_state, color_caps);
+	ret = __set_dm_plane_degamma(plane_state, dc_plane_state, &color_caps);
 	if (ret == -ENOMEM)
 		return ret;
 
@@ -2209,7 +2215,7 @@ int amdgpu_dm_update_plane_color_mgmt(struct dm_crtc_state *crtc,
 		 * linearize (implicit degamma) from sRGB/BT709 according to
 		 * the input space.
 		 */
-		ret = map_crtc_degamma_to_dc_plane(crtc, dc_plane_state, color_caps);
+		ret = map_crtc_degamma_to_dc_plane(crtc, dc_plane_state, &color_caps);
 		if (ret)
 			return ret;
 	}
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_colorop.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_colorop.c
index e912256eebb3..bf0294682f93 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_colorop.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_colorop.c
@@ -299,8 +299,11 @@ int amdgpu_dm_initialize_default_pipeline(struct drm_plane *plane, struct drm_pr
 {
 	struct drm_device *dev = plane->dev;
 	struct amdgpu_device *adev = drm_to_adev(dev);
-	bool hw_3d_lut = dc_get_caps(adev->dm.dc)->color.dpp.hw_3d_lut ||
-			 dc_get_caps(adev->dm.dc)->color.mpc.preblend;
+	struct dc_color_caps color_caps;
+	bool hw_3d_lut;
+
+	dc_get_color_caps(adev->dm.dc, &color_caps);
+	hw_3d_lut = color_caps.dpp.hw_3d_lut || color_caps.mpc.preblend;
 
 	return amdgpu_dm_build_default_pipeline(dev, plane, hw_3d_lut, list);
 }
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
index d1a672c721c4..814d9380890a 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
@@ -1303,7 +1303,7 @@ static void apply_dsc_policy_for_stream(struct amdgpu_dm_connector *aconnector,
 
 	if (sink->sink_signal == SIGNAL_TYPE_EDP &&
 	    !aconnector->dc_link->panel_config.dsc.disable_dsc_edp &&
-	    dc_get_caps(dc)->edp_dsc_support &&
+	    dc_get_edp_dsc_support(dc) &&
 	    aconnector->dsc_settings.dsc_force_enable != DSC_CLK_FORCE_DISABLE) {
 
 		apply_dsc_policy_for_edp(aconnector, sink, stream, dsc_caps, max_dsc_target_bpp_limit_override);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
index a10f374f16df..283de9ef8108 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
@@ -308,7 +308,7 @@ static inline int amdgpu_dm_crtc_set_vblank(struct drm_crtc *crtc, bool enable)
 		 * Call this function to estimate missed vblanks by using timestamps and
 		 * update the vblank counter in DRM.
 		 */
-		if (dc_get_caps(dc)->ips_support &&
+		if (dc_get_ips_support(dc) &&
 			dc_get_disable_ips(dc) != DMUB_IPS_DISABLE_ALL &&
 			sr_supported && vblank->config.disable_immediate)
 			drm_crtc_vblank_restore(crtc);
@@ -529,8 +529,11 @@ static void
 dm_crtc_additional_color_mgmt(struct drm_crtc *crtc)
 {
 	struct amdgpu_device *adev = drm_to_adev(crtc->dev);
+	struct dc_color_caps color_caps;
 
-	if (dc_get_caps(adev->dm.dc)->color.mpc.ogam_ram)
+	dc_get_color_caps(adev->dm.dc, &color_caps);
+
+	if (color_caps.mpc.ogam_ram)
 		drm_object_attach_property(&crtc->base,
 					   adev->mode_info.regamma_tf_property,
 					   AMDGPU_TRANSFER_FUNCTION_DEFAULT);
@@ -770,9 +773,12 @@ int amdgpu_dm_crtc_init(struct amdgpu_display_manager *dm,
 {
 	struct amdgpu_crtc *acrtc = NULL;
 	struct drm_plane *cursor_plane;
+	struct dc_color_caps color_caps;
 	bool has_degamma;
 	int res = -ENOMEM;
 
+	dc_get_color_caps(dm->dc, &color_caps);
+
 	cursor_plane = kzalloc_obj(*cursor_plane);
 	if (!cursor_plane)
 		goto fail;
@@ -809,12 +815,11 @@ int amdgpu_dm_crtc_init(struct amdgpu_display_manager *dm,
 			res = PTR_ERR(crtc_state);
 			goto error_ism_fini;
 		}
-
 		acrtc->base.state = crtc_state;
 	}
 
-	acrtc->max_cursor_width = dc_get_caps(dm->adev->dm.dc)->max_cursor_size;
-	acrtc->max_cursor_height = dc_get_caps(dm->adev->dm.dc)->max_cursor_size;
+	acrtc->max_cursor_width = dc_get_max_cursor_size(dm->adev->dm.dc);
+	acrtc->max_cursor_height = dc_get_max_cursor_size(dm->adev->dm.dc);
 
 	acrtc->crtc_id = crtc_index;
 	acrtc->base.enabled = false;
@@ -830,7 +835,7 @@ int amdgpu_dm_crtc_init(struct amdgpu_display_manager *dm,
 	 * or the COLOR_PIPELINE property. An atomic commit which attempts to enable
 	 * both is rejected.
 	 */
-	has_degamma = dc_get_caps(dm->adev->dm.dc)->color.dpp.dcn_arch &&
+	has_degamma = color_caps.dpp.dcn_arch &&
 		      dc_get_dce_version(dm->adev->dm.dc) != DCN_VERSION_4_01;
 
 	drm_crtc_enable_color_mgmt(&acrtc->base, has_degamma ? MAX_COLOR_LUT_ENTRIES : 0,
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c
index 99400740cd66..d2e9559af417 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c
@@ -4459,8 +4459,8 @@ static int capabilities_show(struct seq_file *m, void *unused)
 {
 	struct amdgpu_device *adev = (struct amdgpu_device *)m->private;
 	struct dc *dc = adev->dm.dc;
-	bool mall_supported = dc_get_caps(dc)->mall_size_total;
-	bool subvp_supported = dc_get_caps(dc)->subvp_fw_processing_delay_us;
+	bool mall_supported = dc_get_mall_size_total(dc);
+	bool subvp_supported = dc_get_subvp_fw_processing_delay_us(dc);
 	unsigned int mall_in_use = false;
 	unsigned int subvp_in_use = false;
 
@@ -4708,7 +4708,7 @@ void dtn_debugfs_init(struct amdgpu_device *adev)
 	debugfs_create_file_unsafe("amdgpu_dm_disable_hpd", 0644, root, adev,
 				   &disable_hpd_ops);
 
-	if (dc_get_caps(adev->dm.dc)->ips_support) {
+	if (dc_get_ips_support(adev->dm.dc)) {
 		debugfs_create_file_unsafe("amdgpu_dm_ips_status", 0644, root, adev,
 					   &ips_status_fops);
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
index 9aee6fe047ba..4310cb6cca3f 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
@@ -336,7 +336,7 @@ int dm_dmub_hw_init(struct amdgpu_device *adev)
 	hw_params.fb_info = fb_info;
 
 	/* Enable usb4 dpia in the FW APU */
-	if (dc_get_caps(dc)->is_apu &&
+	if (dc_is_apu(dc) &&
 		dc_get_usb4_dpia_count(dc) != 0 &&
 		!dc_get_debug_options(dc)->dpia_debug.bits.disable_dpia) {
 		hw_params.dpia_supported = true;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_hdcp.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_hdcp.c
index 73b56e078cbe..c71adc10c67e 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_hdcp.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_hdcp.c
@@ -43,7 +43,7 @@ STATIC_IFN_KUNIT bool lp_write_i2c(void *handle, uint32_t address, const uint8_t
 	struct dc_link *link = handle;
 	struct i2c_payload i2c_payloads[] = {{true, address, size, (void *)data} };
 	struct i2c_command cmd = {i2c_payloads, 1, I2C_COMMAND_ENGINE_HW,
-				  dc_get_caps(link->dc)->i2c_speed_in_khz};
+				  dc_get_i2c_speed_in_khz(link->dc)};
 
 	return dm_helpers_submit_i2c(link->ctx, link, &cmd);
 }
@@ -56,7 +56,7 @@ STATIC_IFN_KUNIT bool lp_read_i2c(void *handle, uint32_t address, uint8_t offset
 	struct i2c_payload i2c_payloads[] = {{true, address, 1, &offset},
 					     {false, address, size, data} };
 	struct i2c_command cmd = {i2c_payloads, 2, I2C_COMMAND_ENGINE_HW,
-				  dc_get_caps(link->dc)->i2c_speed_in_khz};
+				  dc_get_i2c_speed_in_khz(link->dc)};
 
 	return dm_helpers_submit_i2c(link->ctx, link, &cmd);
 }
@@ -308,7 +308,7 @@ void hdcp_update_display(struct hdcp_workqueue *hdcp_work,
 	hdcp_w->aconnector[conn_index] = aconnector;
 
 	hdcp_get_link_display_adjustments(enable_encryption, content_type,
-			dc_get_caps(dc)->fused_io_supported,
+			dc_get_fused_io_support(dc),
 			dc_get_debug_options(dc)->hdcp_lc_force_fw_enable,
 			dc_get_debug_options(dc)->hdcp_lc_enable_sw_fallback,
 			&link_adjust, &display_adjust);
@@ -677,7 +677,7 @@ void update_config(void *handle, struct cp_psp_stream_config *config)
 	link->adjust.retry_limit = MAX_NUM_OF_ATTEMPTS;
 	link->adjust.hdcp1.disable = 0;
 	link->adjust.hdcp2.use_fw_locality_check =
-		(dc_get_caps(dc)->fused_io_supported ||
+		(dc_get_fused_io_support(dc) ||
 		 dc_get_debug_options(dc)->hdcp_lc_force_fw_enable);
 	link->adjust.hdcp2.use_sw_locality_fallback =
 		dc_get_debug_options(dc)->hdcp_lc_enable_sw_fallback;
@@ -842,7 +842,7 @@ static const struct bin_attribute data_attr = {
 struct hdcp_workqueue *hdcp_create_workqueue(struct amdgpu_device *adev,
 					     struct cp_psp *cp_psp, struct dc *dc)
 {
-	int max_caps = dc_get_caps(dc)->max_links;
+	int max_caps = dc_get_max_links(dc);
 	struct hdcp_workqueue *hdcp_work;
 	int i = 0;
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
index 57e1dcf6bb45..375826ef16e9 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
@@ -808,7 +808,7 @@ static inline int dm_irq_state(struct amdgpu_device *adev,
 
 	st = (state == AMDGPU_IRQ_STATE_ENABLE);
 
-	if (dc && dc_get_caps(dc)->ips_support && dc_is_idle_optimizations_allowed(dc))
+	if (dc && dc_get_ips_support(dc) && dc_is_idle_optimizations_allowed(dc))
 		dc_allow_idle_optimizations(dc, false);
 
 	amdgpu_dm_irq_set(adev, irq_source, st);
@@ -1226,7 +1226,7 @@ EXPORT_IF_KUNIT(dm_handle_hpd_rx_offload_work);
 struct hpd_rx_irq_offload_work_queue *amdgpu_dm_hpd_rx_irq_create_workqueue(struct amdgpu_device *adev)
 {
 	struct dc *dc = adev->dm.dc;
-	int max_caps = dc_get_caps(dc)->max_links;
+	int max_caps = dc_get_max_links(dc);
 	int i = 0;
 	struct hpd_rx_irq_offload_work_queue *hpd_rx_offload_wq = NULL;
 
@@ -1265,7 +1265,7 @@ void amdgpu_dm_hpd_rx_irq_work_suspend(struct amdgpu_display_manager *dm)
 	int i;
 
 	if (dm->hpd_rx_offload_wq) {
-		for (i = 0; i < dc_get_caps(dm->dc)->max_links; i++)
+		for (i = 0; i < dc_get_max_links(dm->dc); i++)
 			flush_workqueue(dm->hpd_rx_offload_wq[i].wq);
 	}
 }
@@ -1321,7 +1321,7 @@ void amdgpu_dm_hdmi_hpd_debounce_work(struct work_struct *work)
 
 	/* Re-detect the display */
 	scoped_guard(mutex, &adev->dm.dc_lock) {
-		if (dc_get_caps(dc)->ips_support && dc_get_ctx(dc)->dmub_srv->idle_allowed) {
+		if (dc_get_ips_support(dc) && dc_get_ctx(dc)->dmub_srv->idle_allowed) {
 			dc_allow_idle_optimizations(dc, false);
 			reallow_idle = true;
 		}
@@ -1359,7 +1359,7 @@ void amdgpu_dm_hdmi_hpd_debounce_work(struct work_struct *work)
 	}
 
 	scoped_guard(mutex, &adev->dm.dc_lock) {
-		if (reallow_idle && dc_get_caps(dc)->ips_support)
+		if (reallow_idle && dc_get_ips_support(dc))
 			dc_allow_idle_optimizations(dc, true);
 	}
 }
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
index d533b72f1861..b3fd02867f92 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
@@ -1239,7 +1239,7 @@ STATIC_IFN_KUNIT bool get_conv_frl_bw(struct amdgpu_dm_connector *aconnector,
 	unsigned int dsc_max_sink_bw_in_kbps = 0;
 
 	if (aconnector->dc_sink &&
-	    dc_get_caps(aconnector->dc_link->dc)->dp_hdmi21_pcon_support &&
+	    dc_get_dp_hdmi21_pcon_support(aconnector->dc_link->dc) &&
 	    aconnector->mst_downstream_port_caps.bytes.byte0.bits.DWN_STRM_PORTX_TYPE == DOWN_STREAM_DETAILED_HDMI) {
 		max_conv_bw_in_kbps = dc_link_bw_kbps_from_raw_frl_link_rate_data(
 				aconnector->dc_link->dc,
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c
index eba044bc47df..206071965b44 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c
@@ -1333,8 +1333,13 @@ STATIC_IFN_KUNIT void amdgpu_dm_plane_get_min_max_dc_plane_scaling(struct drm_de
 {
 	struct amdgpu_device *adev = drm_to_adev(dev);
 	struct dc *dc = adev->dm.dc;
+	const struct dc_plane_cap *plane_caps;
+	unsigned int plane_count;
 	/* Caps for all supported planes are the same on DCE and DCN 1 - 3 */
-	const struct dc_plane_cap *plane_cap = &dc_get_caps(dc)->planes[0];
+	const struct dc_plane_cap *plane_cap;
+
+	plane_caps = dc_get_plane_caps(dc, &plane_count);
+	plane_cap = &plane_caps[0];
 
 	switch (fb->format->format) {
 	case DRM_FORMAT_P010:
@@ -1646,6 +1651,7 @@ void amdgpu_dm_plane_handle_cursor_update(struct drm_plane *plane,
 	uint64_t address = afb ? afb->address : 0;
 	struct dc_cursor_position position = {0};
 	struct dc_cursor_attributes attributes;
+	struct dc_color_caps color_caps;
 	int ret;
 
 	if (!plane->state->fb && !old_plane_state->fb)
@@ -1681,6 +1687,7 @@ void amdgpu_dm_plane_handle_cursor_update(struct drm_plane *plane,
 	amdgpu_crtc->cursor_width = plane->state->crtc_w;
 	amdgpu_crtc->cursor_height = plane->state->crtc_h;
 
+	dc_get_color_caps(adev->dm.dc, &color_caps);
 	memset(&attributes, 0, sizeof(attributes));
 	attributes.address.high_part = upper_32_bits(address);
 	attributes.address.low_part  = lower_32_bits(address);
@@ -1693,8 +1700,7 @@ void amdgpu_dm_plane_handle_cursor_update(struct drm_plane *plane,
 	/* Enable cursor degamma ROM on DCN3+ for implicit sRGB degamma in DRM
 	 * legacy gamma setup.
 	 */
-	if (crtc_state->cm_is_degamma_srgb &&
-	    dc_get_caps(adev->dm.dc)->color.dpp.gamma_corr)
+	if (crtc_state->cm_is_degamma_srgb && color_caps.dpp.gamma_corr)
 		attributes.attribute_flags.bits.ENABLE_CURSOR_DEGAMMA = 1;
 
 	if (afb)
@@ -1974,7 +1980,11 @@ dm_atomic_plane_attach_color_mgmt_properties(struct amdgpu_display_manager *dm,
 					     struct drm_plane *plane)
 {
 	struct amdgpu_mode_info mode_info = dm->adev->mode_info;
-	struct dpp_color_caps dpp_color_caps = dc_get_caps(dm->dc)->color.dpp;
+	struct dc_color_caps color_caps;
+	struct dpp_color_caps dpp_color_caps;
+
+	dc_get_color_caps(dm->dc, &color_caps);
+	dpp_color_caps = color_caps.dpp;
 
 	/* Check HW color pipeline capabilities on DPP block (pre-blending)
 	 * before exposing related properties.
@@ -1996,11 +2006,11 @@ dm_atomic_plane_attach_color_mgmt_properties(struct amdgpu_display_manager *dm,
 				   AMDGPU_HDR_MULT_DEFAULT);
 
 	/* Only enable plane CTM if both DPP and MPC gamut remap is available. */
-	if (dc_get_caps(dm->dc)->color.mpc.gamut_remap)
+	if (color_caps.mpc.gamut_remap)
 		drm_object_attach_property(&plane->base,
 					   dm->adev->mode_info.plane_ctm_property, 0);
 
-	if (dpp_color_caps.hw_3d_lut || dc_get_caps(dm->dc)->color.mpc.preblend) {
+	if (dpp_color_caps.hw_3d_lut || color_caps.mpc.preblend) {
 		drm_object_attach_property(&plane->base,
 					   mode_info.plane_shaper_lut_property, 0);
 		drm_object_attach_property(&plane->base,
@@ -2016,7 +2026,7 @@ dm_atomic_plane_attach_color_mgmt_properties(struct amdgpu_display_manager *dm,
 					   MAX_COLOR_3DLUT_SIZE);
 	}
 
-	if (dpp_color_caps.ogam_ram || dc_get_caps(dm->dc)->color.mpc.preblend) {
+	if (dpp_color_caps.ogam_ram || color_caps.mpc.preblend) {
 		drm_object_attach_property(&plane->base,
 					   mode_info.plane_blend_lut_property, 0);
 		drm_object_attach_property(&plane->base,
@@ -2215,7 +2225,7 @@ int amdgpu_dm_plane_init(struct amdgpu_display_manager *dm,
 	int res = -EPERM;
 	unsigned int supported_rotations;
 	uint64_t *modifiers = NULL;
-	unsigned int primary_zpos = dc_get_caps(dm->dc)->max_slave_planes;
+	unsigned int primary_zpos = dc_get_max_slave_planes(dm->dc);
 
 	num_formats = amdgpu_dm_plane_get_plane_formats(plane, plane_cap, formats,
 							ARRAY_SIZE(formats));
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c
index f71f66b04d5e..271ea6fe05d1 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c
@@ -37,7 +37,7 @@ bool link_supports_psrsu(struct dc_link *link)
 {
 	struct dc *dc = link->ctx->dc;
 
-	if (!dc_get_caps(dc)->dmcub_support)
+	if (!dc_get_dmcub_support(dc))
 		return false;
 
 	if (dc_get_dce_version(dc) < DCN_VERSION_3_1)
@@ -111,7 +111,7 @@ bool amdgpu_dm_set_psr_caps(struct dc_link *link, struct amdgpu_dm_connector *ac
 	/* Reset psr version first */
 	link->psr_settings.psr_version = DC_PSR_VERSION_UNSUPPORTED;
 
-	if (!dc_get_caps(dc)->dmub_caps.psr)
+	if (!dc_dmub_supports_psr(dc))
 		return false;
 
 	if (!(link->connector_signal & SIGNAL_TYPE_EDP))
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
index eb34a76262b1..c2f1d428a8d7 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
@@ -52,9 +52,108 @@ enum dce_version dc_get_dce_version(const struct dc *dc)
 	return dc->ctx->dce_version;
 }
 
-const struct dc_caps *dc_get_caps(const struct dc *dc)
+bool dc_is_apu(const struct dc *dc)
 {
-	return &dc->caps;
+	return dc->caps.is_apu;
+}
+
+bool dc_get_ips_support(const struct dc *dc)
+{
+	return dc->caps.ips_support;
+}
+
+bool dc_get_dmcub_support(const struct dc *dc)
+{
+	return dc->caps.dmcub_support;
+}
+
+unsigned int dc_get_max_links(const struct dc *dc)
+{
+	return dc->caps.max_links;
+}
+
+unsigned int dc_get_max_streams(const struct dc *dc)
+{
+	return dc->caps.max_streams;
+}
+
+unsigned int dc_get_max_planes(const struct dc *dc)
+{
+	return dc->caps.max_planes;
+}
+
+unsigned int dc_get_max_slave_planes(const struct dc *dc)
+{
+	return dc->caps.max_slave_planes;
+}
+
+unsigned int dc_get_max_cursor_size(const struct dc *dc)
+{
+	return dc->caps.max_cursor_size;
+}
+
+unsigned int dc_get_max_v_total(const struct dc *dc)
+{
+	return dc->caps.max_v_total;
+}
+
+bool dc_get_vtotal_limited_by_fp2(const struct dc *dc)
+{
+	return dc->caps.vtotal_limited_by_fp2;
+}
+
+unsigned int dc_get_i2c_speed_in_khz(const struct dc *dc)
+{
+	return dc->caps.i2c_speed_in_khz;
+}
+
+bool dc_get_dp_hdmi21_pcon_support(const struct dc *dc)
+{
+	return dc->caps.dp_hdmi21_pcon_support;
+}
+
+bool dc_get_edp_dsc_support(const struct dc *dc)
+{
+	return dc->caps.edp_dsc_support;
+}
+
+bool dc_get_fused_io_support(const struct dc *dc)
+{
+	return dc->caps.fused_io_supported;
+}
+
+unsigned int dc_get_subvp_fw_processing_delay_us(const struct dc *dc)
+{
+	return dc->caps.subvp_fw_processing_delay_us;
+}
+
+unsigned int dc_get_mall_size_total(const struct dc *dc)
+{
+	return dc->caps.mall_size_total;
+}
+
+bool dc_dmub_supports_psr(const struct dc *dc)
+{
+	return dc->caps.dmub_caps.psr;
+}
+
+bool dc_dmub_supports_aux_backlight(const struct dc *dc)
+{
+	return dc->caps.dmub_caps.aux_backlight_support;
+}
+
+void dc_get_color_caps(const struct dc *dc, struct dc_color_caps *caps)
+{
+	*caps = dc->caps.color;
+}
+
+const struct dc_plane_cap *dc_get_plane_caps(const struct dc *dc,
+		unsigned int *count)
+{
+	if (count)
+		*count = dc->caps.max_planes;
+
+	return dc->caps.planes;
 }
 
 unsigned int dc_get_disable_ips(const struct dc *dc)
diff --git a/drivers/gpu/drm/amd/display/dc/inc/dc.h b/drivers/gpu/drm/amd/display/dc/inc/dc.h
index 31baba820f6c..7a49f2ee1d77 100644
--- a/drivers/gpu/drm/amd/display/dc/inc/dc.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/dc.h
@@ -2351,8 +2351,38 @@ struct dc_context *dc_get_ctx(const struct dc *dc);
 /* The ASIC display engine version. */
 enum dce_version dc_get_dce_version(const struct dc *dc);
 
-/* Capabilities detected at dc_create() time. Read-only. */
-const struct dc_caps *dc_get_caps(const struct dc *dc);
+/*
+ * Capabilities detected at dc_create() time. Read-only; prefer the
+ * purpose-built queries below over reaching into the caps structure.
+ */
+bool dc_is_apu(const struct dc *dc);
+bool dc_get_ips_support(const struct dc *dc);
+bool dc_get_dmcub_support(const struct dc *dc);
+unsigned int dc_get_max_links(const struct dc *dc);
+unsigned int dc_get_max_streams(const struct dc *dc);
+unsigned int dc_get_max_planes(const struct dc *dc);
+unsigned int dc_get_max_slave_planes(const struct dc *dc);
+unsigned int dc_get_max_cursor_size(const struct dc *dc);
+unsigned int dc_get_max_v_total(const struct dc *dc);
+bool dc_get_vtotal_limited_by_fp2(const struct dc *dc);
+unsigned int dc_get_i2c_speed_in_khz(const struct dc *dc);
+bool dc_get_dp_hdmi21_pcon_support(const struct dc *dc);
+bool dc_get_edp_dsc_support(const struct dc *dc);
+bool dc_get_fused_io_support(const struct dc *dc);
+unsigned int dc_get_subvp_fw_processing_delay_us(const struct dc *dc);
+unsigned int dc_get_mall_size_total(const struct dc *dc);
+bool dc_dmub_supports_psr(const struct dc *dc);
+bool dc_dmub_supports_aux_backlight(const struct dc *dc);
+
+/* Copy out the color pipeline capabilities. */
+void dc_get_color_caps(const struct dc *dc, struct dc_color_caps *caps);
+
+/*
+ * Return the static plane capability array and its entry count.
+ * Valid until the DC is destroyed.
+ */
+const struct dc_plane_cap *dc_get_plane_caps(const struct dc *dc,
+		unsigned int *count);
 
 /*
  * Select which eDP connectors get hotplug detection enabled; see
@@ -2512,7 +2542,7 @@ void dc_set_dml2_alt_ch_cfg(struct dc *dc,
 /* Return an enumerated dc_link.
  * dc_link order is constant and determined at
  * boot time.  They cannot be created or destroyed.
- * Use dc_get_caps() to get number of links.
+ * Use dc_get_max_links() to get number of links.
  */
 struct dc_link *dc_get_link_at_index(struct dc *dc, uint32_t link_index);
 
diff --git a/drivers/gpu/drm/amd/display/modules/freesync/freesync.c b/drivers/gpu/drm/amd/display/modules/freesync/freesync.c
index dafcb42504f8..7deb641c7ae8 100644
--- a/drivers/gpu/drm/amd/display/modules/freesync/freesync.c
+++ b/drivers/gpu/drm/amd/display/modules/freesync/freesync.c
@@ -125,9 +125,9 @@ static unsigned int calc_duration_in_us_from_v_total(
 
 static unsigned int calc_max_hardware_v_total(const struct dc_stream_state *stream)
 {
-	unsigned int max_hw_v_total = dc_get_caps(stream->ctx->dc)->max_v_total;
+	unsigned int max_hw_v_total = dc_get_max_v_total(stream->ctx->dc);
 
-	if (dc_get_caps(stream->ctx->dc)->vtotal_limited_by_fp2)
+	if (dc_get_vtotal_limited_by_fp2(stream->ctx->dc))
 		max_hw_v_total -= stream->timing.v_front_porch + 1;
 
 	return max_hw_v_total;
@@ -1007,7 +1007,7 @@ void mod_freesync_build_vrr_params(struct mod_freesync *mod_freesync,
 	nominal_field_rate_in_uhz =
 			mod_freesync_calc_nominal_field_rate(stream);
 
-	if (dc_get_caps(stream->ctx->dc)->max_v_total != 0 && stream->timing.h_total != 0) {
+	if (dc_get_max_v_total(stream->ctx->dc) != 0 && stream->timing.h_total != 0) {
 		min_hardware_refresh_in_uhz = div64_u64((stream->timing.pix_clk_100hz * 100000000ULL),
 			(stream->timing.h_total * (long long)calc_max_hardware_v_total(stream)));
 	}
diff --git a/drivers/gpu/drm/amd/display/modules/power/power_abm.c b/drivers/gpu/drm/amd/display/modules/power/power_abm.c
index ae2fa3b12e1a..652b7ad198f3 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power_abm.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power_abm.c
@@ -935,7 +935,7 @@ static bool set_backlight_millinits_aux(struct core_power *core_power,
 
 	// only use internal backlight control if dmub capabilities are not present
 	if (link->backlight_control_type == BACKLIGHT_CONTROL_VESA_AUX &&
-		dc_get_caps(link->dc)->dmub_caps.aux_backlight_support)
+		dc_dmub_supports_aux_backlight(link->dc))
 		return true;
 
 	return dc_link_set_backlight_level_nits(link, core_power->bl_state[inst].isHDR,
diff --git a/drivers/gpu/drm/amd/display/modules/power/power_psr.c b/drivers/gpu/drm/amd/display/modules/power/power_psr.c
index 219b199350cd..3cd06e0d267b 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power_psr.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power_psr.c
@@ -645,7 +645,7 @@ bool psr_su_set_dsc_slice_height(struct dc *dc, struct dc_link *link,
 
 	config->dsc_slice_height = 0;
 	if (!(link->connector_signal & SIGNAL_TYPE_EDP) ||
-	    !dc_get_caps(dc)->edp_dsc_support ||
+	    !dc_get_edp_dsc_support(dc) ||
 	    link->panel_config.dsc.disable_dsc_edp ||
 	    !link->dpcd_caps.dsc_caps.dsc_basic_caps.fields.dsc_support.DSC_SUPPORT ||
 	    !stream->timing.dsc_cfg.num_slices_v)

-- 
2.56.0

