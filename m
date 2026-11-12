From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:41 +1000
Subject: [PATCH 06/19] drm/amd/display/amdgpu_dm: Use DC accessors in
 plane/crtc/helpers paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-6-0fae41718ad2@redhat.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=11828; i=airlied@redhat.com;
 h=from:subject:message-id; bh=X5vxAemYcBpcnHPBvguvgKLi49d8QdgA0aUdt0m/rYU=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnPPN+xoE6Iy+p3RCgW6xEXTHNMl9dhcDXwG
 CP0fZ1zx8mJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZzwAKCRAMdPNZecSG
 vjhkEACJilVK+HxFzSbImhEi2XdsRNwgNP9z9rjEs/FvqJCNp89kSg1Jjazafwd3VEoSJCKWHRv
 T1HY8i4F0vsk+6IpkptqumrmBhdNU3SkCdPdGiOz09lfdeaZE5AVpSv4/+DYVaQRU16fUCpS6Wx
 8Lgl5NX5vuMuQzS1dpETa3TseZeZ7eS3R+ZqBDh6xaZMC9olx19u9RcMuxq1xyJ497IUVLXi2bx
 gFaZHuYfYDQu1kRaw/qgAG+1lXVStASZ/tktLUWcYhTn9ltzU7LyRUlFIdPc98u1sCDTh6NzRhf
 RTOP6Cmgty64d/s8rSWLLrq2dglTFrIHzzLmSy2247agNMqwCFWJhgBIl/3kcnkxH5Nc47ZMeCN
 +El4X3RPOV4d3xmkLqTZE5AQZb3p1kDUjTaBdgzP4NcvnKBVP/tb65UFbQin2X843eQh6I4j6YB
 lrirtY0ih2ujT/PNkNon6mspPq0E5IQ/lEyWmoBbbZJfQLzyJ6CXOssUUtf3sepqCXIuccG3GuV
 6GmQxZ1MPcAw06EmqhU8ekR/EGf0th5vLHBAbpwznZPUitdMYhMDsEpSTPvC/PuNqI9WJuyjZHl
 Jk5mGa3XtMBsDCGFbMYvoteC/CFu6nHhjqlUXKv3dxt9asZ4lrF7+oGlJf9SUsuaclPvmdSNXtS
 HygHw6TQ7SAXvCg==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace direct struct dc member dereferences with the DC accessor
layer in amdgpu_dm_plane.c, amdgpu_dm_crtc.c and amdgpu_dm_helpers.c,
including the cap_funcs DCC query (dc_get_dcc_compression_cap), the
hwss prepare_ddc sequence (dc_prepare_ddc) and the clk_mgr use in the
DP compliance test path (dc_get_clk_mgr).

Part of making struct dc private to DC.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c | 16 +++++++--------
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c  | 24 ++++++++++++----------
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c    | 21 ++++++++-----------
 3 files changed, 30 insertions(+), 31 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
index 3e0128a29d77..334e33b1c4f4 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
@@ -180,7 +180,7 @@ STATIC_IFN_KUNIT void amdgpu_dm_idle_worker(struct work_struct *work)
 	while (idle_work->enable) {
 		fsleep(HPD_DETECTION_PERIOD_uS);
 		mutex_lock(&idle_work->dm->dc_lock);
-		if (!idle_work->dm->dc->idle_optimizations_allowed) {
+		if (!dc_is_idle_optimizations_allowed(idle_work->dm->dc)) {
 			mutex_unlock(&idle_work->dm->dc_lock);
 			break;
 		}
@@ -308,8 +308,8 @@ static inline int amdgpu_dm_crtc_set_vblank(struct drm_crtc *crtc, bool enable)
 		 * Call this function to estimate missed vblanks by using timestamps and
 		 * update the vblank counter in DRM.
 		 */
-		if (dc->caps.ips_support &&
-			dc->config.disable_ips != DMUB_IPS_DISABLE_ALL &&
+		if (dc_get_caps(dc)->ips_support &&
+			dc_get_config(dc)->disable_ips != DMUB_IPS_DISABLE_ALL &&
 			sr_supported && vblank->config.disable_immediate)
 			drm_crtc_vblank_restore(crtc);
 	}
@@ -327,7 +327,7 @@ static inline int amdgpu_dm_crtc_set_vblank(struct drm_crtc *crtc, bool enable)
 			rc = amdgpu_irq_put(adev, &adev->vupdate_irq, irq_type);
 			drm_dbg_vbl(crtc->dev, "Put vupdate_irq ret=%d\n", rc);
 		}
-	} else if (dc_supports_vrr(dm->dc->ctx->dce_version)) {
+	} else if (dc_supports_vrr(dc_get_dce_version(dm->dc))) {
 		if (enable) {
 			/* vblank irq on -> Only need vupdate irq in vrr mode
 			 * Not ref-counted since we need explicit enable/disable
@@ -530,7 +530,7 @@ dm_crtc_additional_color_mgmt(struct drm_crtc *crtc)
 {
 	struct amdgpu_device *adev = drm_to_adev(crtc->dev);
 
-	if (adev->dm.dc->caps.color.mpc.ogam_ram)
+	if (dc_get_caps(adev->dm.dc)->color.mpc.ogam_ram)
 		drm_object_attach_property(&crtc->base,
 					   adev->mode_info.regamma_tf_property,
 					   AMDGPU_TRANSFER_FUNCTION_DEFAULT);
@@ -813,8 +813,8 @@ int amdgpu_dm_crtc_init(struct amdgpu_display_manager *dm,
 		acrtc->base.state = crtc_state;
 	}
 
-	acrtc->max_cursor_width = dm->adev->dm.dc->caps.max_cursor_size;
-	acrtc->max_cursor_height = dm->adev->dm.dc->caps.max_cursor_size;
+	acrtc->max_cursor_width = dc_get_caps(dm->adev->dm.dc)->max_cursor_size;
+	acrtc->max_cursor_height = dc_get_caps(dm->adev->dm.dc)->max_cursor_size;
 
 	acrtc->crtc_id = crtc_index;
 	acrtc->base.enabled = false;
@@ -830,7 +830,7 @@ int amdgpu_dm_crtc_init(struct amdgpu_display_manager *dm,
 	 * or the COLOR_PIPELINE property. An atomic commit which attempts to enable
 	 * both is rejected.
 	 */
-	has_degamma = dm->adev->dm.dc->caps.color.dpp.dcn_arch &&
+	has_degamma = dc_get_caps(dm->adev->dm.dc)->color.dpp.dcn_arch &&
 		      dm->adev->dm.dc->ctx->dce_version != DCN_VERSION_4_01;
 
 	drm_crtc_enable_color_mgmt(&acrtc->base, has_degamma ? MAX_COLOR_LUT_ENTRIES : 0,
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
index 3067ac5bb0cd..02a8cfde9f1a 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
@@ -136,7 +136,8 @@ STATIC_IFN_KUNIT void apply_edid_quirks(struct dc_link *link, struct edid *edid,
 		if (dc_is_embedded_signal(link->connector_signal)) {
 			drm_dbg_driver(dev, "Force PHY power down/up level 2 on panel id %X\n",
 				       panel_id);
-			link->ctx->dc->debug.psr_phy_force_phy_power_down_up_level_2 = true;
+			dc_get_debug_options_mutable(link->ctx->dc)->
+					psr_phy_force_phy_power_down_up_level_2 = true;
 		}
 		break;
 	/* Workaround for monitors that get corrupted by the PHY SSC reduction */
@@ -227,7 +228,9 @@ enum dc_edid_status dm_helpers_parse_edid_caps(
 
 	if (edid_caps->edid_hdmi) {
 		edid_caps->qs_bit = connector->display_info.rgb_quant_range_selectable;
-		populate_hdmi_info_from_connector(link->dc->config.enable_frl, &connector->display_info.hdmi, edid_caps);
+		populate_hdmi_info_from_connector(
+			dc_get_config(link->dc)->enable_frl,
+			&connector->display_info.hdmi, edid_caps);
 		drm_dbg_driver(connector->dev, "%s: HDMI_FRL [%s] max_frl_rate %d\n", __func__, connector->name, edid_caps->max_frl_rate);
 		if (edid_caps->frl_dsc_support)
 			drm_dbg_driver(connector->dev, "%s: HDMI_FRL_DSC [%s] frl_dsc_10bpc %d, frl_dsc_12bpc %d, frl_dsc_all_bpp %d, frl_dsc_native_420 %d, frl_dsc_max_slices %d, frl_dsc_max_frl_rate %d, frl_dsc_total_chunk_kbytes %d\n",
@@ -236,8 +239,8 @@ enum dc_edid_status dm_helpers_parse_edid_caps(
 					edid_caps->frl_dsc_max_frl_rate, edid_caps->frl_dsc_total_chunk_kbytes);
 		if (aconnector->hdmi_comp_auto) {
 			edid_caps->panel_patch.hdmi_comp_auto = true;
-			link->ctx->dc->debug.force_frl_max = true;
-			link->ctx->dc->debug.force_frl_dsc = true;
+			dc_get_debug_options_mutable(link->ctx->dc)->force_frl_max = true;
+			dc_get_debug_options_mutable(link->ctx->dc)->force_frl_dsc = true;
 			drm_dbg_driver(connector->dev, "%s: HDMI_FRL [%s] hdmi_comp_auto --> enabled\n", __func__, connector->name);
 		}
 	}
@@ -1291,8 +1294,7 @@ enum dc_edid_status dm_helpers_read_local_edid(
 	else
 		ddc = &aconnector->i2c->base;
 
-	if (link->dc->hwss.prepare_ddc)
-		link->dc->hwss.prepare_ddc(link);
+	dc_prepare_ddc(link);
 
 	dm_helpers_wait_for_edid_ready(link, ddc);
 
@@ -1552,12 +1554,12 @@ bool dm_helpers_dp_handle_test_pattern_request(
 			DP_TEST_PATTERN_COLOR_SPACE_UNDEFINED;
 	enum dc_color_depth requestColorDepth = COLOR_DEPTH_UNDEFINED;
 	enum dc_pixel_encoding requestPixelEncoding = PIXEL_ENCODING_UNDEFINED;
-	struct pipe_ctx *pipes = link->dc->current_state->res_ctx.pipe_ctx;
+	struct pipe_ctx *pipes = dc_get_current_state(link->dc)->res_ctx.pipe_ctx;
 	struct pipe_ctx *pipe_ctx = NULL;
 	struct amdgpu_dm_connector *aconnector = link->priv;
 	struct drm_device *dev = aconnector->base.dev;
-	struct dc_state *dc_state = ctx->dc->current_state;
-	struct clk_mgr *clk_mgr = ctx->dc->clk_mgr;
+	struct dc_state *dc_state = dc_get_current_state(ctx->dc);
+	struct clk_mgr *clk_mgr = dc_get_clk_mgr(ctx->dc);
 	int i;
 
 	for (i = 0; i < MAX_PIPES; i++) {
@@ -1663,8 +1665,8 @@ bool dm_helpers_dp_handle_test_pattern_request(
 	dc_state->bw_ctx.bw.dcn.clk.dramclk_khz = clk_mgr->dc_mode_softmax_enabled ?
 		clk_mgr->bw_params->dc_mode_softmax_memclk : clk_mgr->bw_params->max_memclk_mhz;
 	dc_state->bw_ctx.bw.dcn.clk.idle_dramclk_khz = dc_state->bw_ctx.bw.dcn.clk.dramclk_khz;
-	ctx->dc->clk_mgr->funcs->update_clocks(
-			ctx->dc->clk_mgr,
+	dc_get_clk_mgr(ctx->dc)->funcs->update_clocks(
+			dc_get_clk_mgr(ctx->dc),
 			dc_state,
 			false);
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c
index b224d9596fd2..eba044bc47df 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c
@@ -306,9 +306,6 @@ STATIC_IFN_KUNIT int amdgpu_dm_plane_validate_dcc(struct amdgpu_device *adev,
 	    format >= SURFACE_PIXEL_FORMAT_VIDEO_BEGIN)
 		return -EINVAL;
 
-	if (!dc->cap_funcs.get_dcc_compression_cap)
-		return -EINVAL;
-
 	input.format = format;
 	input.surface_size.width = plane_size->surface_size.width;
 	input.surface_size.height = plane_size->surface_size.height;
@@ -319,7 +316,7 @@ STATIC_IFN_KUNIT int amdgpu_dm_plane_validate_dcc(struct amdgpu_device *adev,
 	else if (rotation == ROTATION_ANGLE_90 || rotation == ROTATION_ANGLE_270)
 		input.scan = SCAN_DIRECTION_VERTICAL;
 
-	if (!dc->cap_funcs.get_dcc_compression_cap(dc, &input, &output))
+	if (!dc_get_dcc_compression_cap(dc, &input, &output))
 		return -EINVAL;
 
 	if (!output.capable)
@@ -1337,7 +1334,7 @@ STATIC_IFN_KUNIT void amdgpu_dm_plane_get_min_max_dc_plane_scaling(struct drm_de
 	struct amdgpu_device *adev = drm_to_adev(dev);
 	struct dc *dc = adev->dm.dc;
 	/* Caps for all supported planes are the same on DCE and DCN 1 - 3 */
-	struct dc_plane_cap *plane_cap = &dc->caps.planes[0];
+	const struct dc_plane_cap *plane_cap = &dc_get_caps(dc)->planes[0];
 
 	switch (fb->format->format) {
 	case DRM_FORMAT_P010:
@@ -1697,7 +1694,7 @@ void amdgpu_dm_plane_handle_cursor_update(struct drm_plane *plane,
 	 * legacy gamma setup.
 	 */
 	if (crtc_state->cm_is_degamma_srgb &&
-	    adev->dm.dc->caps.color.dpp.gamma_corr)
+	    dc_get_caps(adev->dm.dc)->color.dpp.gamma_corr)
 		attributes.attribute_flags.bits.ENABLE_CURSOR_DEGAMMA = 1;
 
 	if (afb)
@@ -1977,7 +1974,7 @@ dm_atomic_plane_attach_color_mgmt_properties(struct amdgpu_display_manager *dm,
 					     struct drm_plane *plane)
 {
 	struct amdgpu_mode_info mode_info = dm->adev->mode_info;
-	struct dpp_color_caps dpp_color_caps = dm->dc->caps.color.dpp;
+	struct dpp_color_caps dpp_color_caps = dc_get_caps(dm->dc)->color.dpp;
 
 	/* Check HW color pipeline capabilities on DPP block (pre-blending)
 	 * before exposing related properties.
@@ -1999,11 +1996,11 @@ dm_atomic_plane_attach_color_mgmt_properties(struct amdgpu_display_manager *dm,
 				   AMDGPU_HDR_MULT_DEFAULT);
 
 	/* Only enable plane CTM if both DPP and MPC gamut remap is available. */
-	if (dm->dc->caps.color.mpc.gamut_remap)
+	if (dc_get_caps(dm->dc)->color.mpc.gamut_remap)
 		drm_object_attach_property(&plane->base,
 					   dm->adev->mode_info.plane_ctm_property, 0);
 
-	if (dpp_color_caps.hw_3d_lut || dm->dc->caps.color.mpc.preblend) {
+	if (dpp_color_caps.hw_3d_lut || dc_get_caps(dm->dc)->color.mpc.preblend) {
 		drm_object_attach_property(&plane->base,
 					   mode_info.plane_shaper_lut_property, 0);
 		drm_object_attach_property(&plane->base,
@@ -2019,7 +2016,7 @@ dm_atomic_plane_attach_color_mgmt_properties(struct amdgpu_display_manager *dm,
 					   MAX_COLOR_3DLUT_SIZE);
 	}
 
-	if (dpp_color_caps.ogam_ram || dm->dc->caps.color.mpc.preblend) {
+	if (dpp_color_caps.ogam_ram || dc_get_caps(dm->dc)->color.mpc.preblend) {
 		drm_object_attach_property(&plane->base,
 					   mode_info.plane_blend_lut_property, 0);
 		drm_object_attach_property(&plane->base,
@@ -2171,7 +2168,7 @@ dm_plane_init_colorops(struct drm_plane *plane)
 		return 0;
 
 	/* initialize pipeline */
-	if (dc->ctx->dce_version >= DCN_VERSION_3_0) {
+	if (dc_get_dce_version(dc) >= DCN_VERSION_3_0) {
 		ret = amdgpu_dm_initialize_default_pipeline(plane, &pipelines[len]);
 		if (ret) {
 			drm_err(plane->dev, "Failed to create color pipeline for plane %d: %pe\n",
@@ -2218,7 +2215,7 @@ int amdgpu_dm_plane_init(struct amdgpu_display_manager *dm,
 	int res = -EPERM;
 	unsigned int supported_rotations;
 	uint64_t *modifiers = NULL;
-	unsigned int primary_zpos = dm->dc->caps.max_slave_planes;
+	unsigned int primary_zpos = dc_get_caps(dm->dc)->max_slave_planes;
 
 	num_formats = amdgpu_dm_plane_get_plane_formats(plane, plane_cap, formats,
 							ARRAY_SIZE(formats));

-- 
2.56.0

