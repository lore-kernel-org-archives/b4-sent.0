From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:43 +1000
Subject: [PATCH 08/19] drm/amd/display: Use DC accessors in DAL modules
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-8-0fae41718ad2@redhat.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=15562; i=airlied@redhat.com;
 h=from:subject:message-id; bh=O/Iqs39phUOXlAMC4Cq20ZYMq8qiGohAdKjmkGz/5Fc=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnPgnQYHLb/7DJc8EesyMhwcKLvy0Cr1X8Ik
 MpeuU2GnziJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZzwAKCRAMdPNZecSG
 vpOtD/45Dl1HT0eAj50tC69boedTorErp+ZtXAUoHbQXSkNxa3kmrfTuXlf/PJxrDFnoGilkWnE
 wLOmstOChJ4mpMDCoPvDTf0MQRmCO+MWJ285UlXo78rMioAXqdf3Tf6sTNEnWcvYZfvkhxGpeA2
 vnp2N9nizAbrbT5NVhAiukFtfvztnm0O4M2U8/Rif+uHJNoi7f/mXzBdX+Y8PePx8J02qVY78Xm
 aVQIFHq0SbBWNTAXrywG8GpL7lunmzBrP64XRwgrHaOL8y3fT+Ps4/sKV8pJqXmh53hHLkwk7mq
 lsFSmvSOVm99Jt2b6k14bT+RawJP2nN6vr2WeVxQZJokTF6l4PX+dlGCyMJjew7wQnx1FYIr/AW
 Q8a5q+vhfEJzTDX6BCqcWiHSVxU7vsZ3Kt/tnmfYTjvdD2xbTFAzW4tAGtEKypM26bPrDD09ECG
 F9sewjvkpUFhZ3b4i/hOn8v26kkvi1R99/I5Gvfmc73eKZVsCJJhoVlmWBglL2fXTdOa6PVnmdK
 p21h5Y6m3m2ss0Eqws+2i539/uoWCp4Iq/60iwL9MpFCG3y5cqlNEJ75wDCuo15cq/SndIza0Xm
 I7t0dgYaLQVRM4Kxjf/7MHlvBVgeqbQdIN/LUUE8BVMTZ6XoTt6IRXIVVt+OHXXIt7b4SmsGZnf
 gjsW8yA0Vzt/FEg==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate modules/freesync, modules/power and the remaining module
users of struct dc members to the DC accessor layer, replacing the
direct link_service calls (edp_get_psr_residency, edp_send_replay_cmd,
edp_set_coasting_vtotal, dp_setup_replay, get_ddc_aux_inst, ...) with
the dc_link_* wrappers.

Add missing struct dc forward declarations to logger_interface.h and
mod_freesync.h.

Part of making struct dc private to DC.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 .../gpu/drm/amd/display/include/logger_interface.h |  1 +
 .../drm/amd/display/modules/freesync/freesync.c    | 14 +++++------
 .../gpu/drm/amd/display/modules/inc/mod_freesync.h |  2 ++
 drivers/gpu/drm/amd/display/modules/power/power.c  |  5 ++--
 .../gpu/drm/amd/display/modules/power/power_abm.c  | 29 +++++++++++-----------
 .../gpu/drm/amd/display/modules/power/power_psr.c  | 10 ++++----
 .../drm/amd/display/modules/power/power_replay.c   | 25 ++++++++-----------
 7 files changed, 44 insertions(+), 42 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/include/logger_interface.h b/drivers/gpu/drm/amd/display/include/logger_interface.h
index 4c01514b926c..7dc738b60162 100644
--- a/drivers/gpu/drm/amd/display/include/logger_interface.h
+++ b/drivers/gpu/drm/amd/display/include/logger_interface.h
@@ -28,6 +28,7 @@
 
 #include "logger_types.h"
 
+struct dc;
 struct dc_context;
 struct dc_link;
 struct dc_surface_update;
diff --git a/drivers/gpu/drm/amd/display/modules/freesync/freesync.c b/drivers/gpu/drm/amd/display/modules/freesync/freesync.c
index f154a619b533..dafcb42504f8 100644
--- a/drivers/gpu/drm/amd/display/modules/freesync/freesync.c
+++ b/drivers/gpu/drm/amd/display/modules/freesync/freesync.c
@@ -125,11 +125,10 @@ static unsigned int calc_duration_in_us_from_v_total(
 
 static unsigned int calc_max_hardware_v_total(const struct dc_stream_state *stream)
 {
-	unsigned int max_hw_v_total = stream->ctx->dc->caps.max_v_total;
+	unsigned int max_hw_v_total = dc_get_caps(stream->ctx->dc)->max_v_total;
 
-	if (stream->ctx->dc->caps.vtotal_limited_by_fp2) {
+	if (dc_get_caps(stream->ctx->dc)->vtotal_limited_by_fp2)
 		max_hw_v_total -= stream->timing.v_front_porch + 1;
-	}
 
 	return max_hw_v_total;
 }
@@ -1008,7 +1007,7 @@ void mod_freesync_build_vrr_params(struct mod_freesync *mod_freesync,
 	nominal_field_rate_in_uhz =
 			mod_freesync_calc_nominal_field_rate(stream);
 
-	if (stream->ctx->dc->caps.max_v_total != 0 && stream->timing.h_total != 0) {
+	if (dc_get_caps(stream->ctx->dc)->max_v_total != 0 && stream->timing.h_total != 0) {
 		min_hardware_refresh_in_uhz = div64_u64((stream->timing.pix_clk_100hz * 100000000ULL),
 			(stream->timing.h_total * (long long)calc_max_hardware_v_total(stream)));
 	}
@@ -1196,9 +1195,10 @@ void mod_freesync_handle_v_update(struct mod_freesync *mod_freesync,
 	if (in_out_vrr->supported == false)
 		return;
 
-	cur_tick = dm_get_timestamp(core_freesync->dc->ctx);
-	cur_timestamp_in_us = (unsigned int)
-			div_u64(dm_get_elapse_time_in_ns(core_freesync->dc->ctx, cur_tick, 0), 1000);
+	cur_tick = dm_get_timestamp(dc_get_ctx(core_freesync->dc));
+	cur_timestamp_in_us = (unsigned int)div_u64(
+			dm_get_elapse_time_in_ns(dc_get_ctx(core_freesync->dc), cur_tick, 0),
+			1000);
 
 	in_out_vrr->flip_interval.vsyncs_between_flip++;
 	in_out_vrr->flip_interval.v_update_timestamp_in_us = cur_timestamp_in_us;
diff --git a/drivers/gpu/drm/amd/display/modules/inc/mod_freesync.h b/drivers/gpu/drm/amd/display/modules/inc/mod_freesync.h
index c042fb1bf49c..1cf88adb3163 100644
--- a/drivers/gpu/drm/amd/display/modules/inc/mod_freesync.h
+++ b/drivers/gpu/drm/amd/display/modules/inc/mod_freesync.h
@@ -28,6 +28,8 @@
 
 #include "mod_shared.h"
 
+struct dc;
+
 // Access structures
 struct mod_freesync {
 	int dummy;
diff --git a/drivers/gpu/drm/amd/display/modules/power/power.c b/drivers/gpu/drm/amd/display/modules/power/power.c
index d900be8cb5fc..884279696a2d 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power.c
@@ -192,7 +192,8 @@ struct mod_power *mod_power_create(struct dc *dc,
 	}
 
 	// ABM used to contain 4 different configs. There is only 3 since ABM 2.3.
-	if ((dc->res_pool->dmcu != NULL) && (dc->res_pool->dmcu->dmcu_version.abm_version < 0x23))
+	if (dc_get_res_pool(dc)->dmcu != NULL &&
+	    dc_get_res_pool(dc)->dmcu->dmcu_version.abm_version < 0x23)
 		abm_max_config = 4;
 	else
 		abm_max_config = 3;
@@ -480,7 +481,7 @@ bool mod_power_notify_mode_change(struct mod_power *mod_power,
 	link = dc_stream_get_link(stream);
 
 	if (link != NULL && dc_get_edp_link_panel_inst(dc, link, &panel_inst)) {
-		aux_inst = link->dc->link_srv->get_ddc_aux_inst(link);
+		aux_inst = dc_link_get_ddc_aux_inst(link);
 
 		mod_power_update_backlight_on_mode_change(core_power, link, panel_inst, aux_inst, is_hdr);
 
diff --git a/drivers/gpu/drm/amd/display/modules/power/power_abm.c b/drivers/gpu/drm/amd/display/modules/power/power_abm.c
index 5f27dea4aa0a..2b420eac5c56 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power_abm.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power_abm.c
@@ -712,7 +712,7 @@ void initialize_backlight_caps(struct core_power *core_power, unsigned int inst)
 
 	/* Retrieve ACPI extended brightness caps */
 	if (dm_query_extended_brightness_caps
-		(dc->ctx, acpi_display_type, ext_backlight_caps)) {
+		(dc_get_ctx(dc), acpi_display_type, ext_backlight_caps)) {
 		custom_curve_present = validate_ext_backlight_caps(ext_backlight_caps);
 	}
 
@@ -868,7 +868,7 @@ bool mod_power_hw_init_backlight(struct mod_power *mod_power)
 		params.backlight_lut_array_size = core_power->bl_prop[i].num_backlight_levels;
 		params.min_abm_backlight = core_power->bl_prop[i].min_abm_backlight;
 
-		dmcu = dc->res_pool->dmcu;
+		dmcu = dc_get_res_pool(dc)->dmcu;
 
 		// In the case where abm is implemented on dmcub,
 		// dmcu object will be null.
@@ -876,8 +876,8 @@ bool mod_power_hw_init_backlight(struct mod_power *mod_power)
 		if (dmcu) {
 			//DMCU does not support multiple eDP
 			return dmcu_load_iram(dmcu, params);
-		} else if (dc->ctx->dmub_srv) {
-			if (!dmub_init_abm_config(dc->res_pool, params, i))
+		} else if (dc_get_ctx(dc)->dmub_srv) {
+			if (!dmub_init_abm_config(dc_get_res_pool(dc), params, i))
 				return false;
 		} else
 			return false;
@@ -935,7 +935,7 @@ static bool set_backlight_millinits_aux(struct core_power *core_power,
 
 	// only use internal backlight control if dmub capabilities are not present
 	if (link->backlight_control_type == BACKLIGHT_CONTROL_VESA_AUX &&
-		link->dc->caps.dmub_caps.aux_backlight_support)
+		dc_get_caps(link->dc)->dmub_caps.aux_backlight_support)
 		return true;
 
 	return dc_link_set_backlight_level_nits(link, core_power->bl_state[inst].isHDR,
@@ -1041,7 +1041,7 @@ bool mod_power_set_backlight_nits(struct mod_power *mod_power,
 	core_power = MOD_POWER_TO_CORE(mod_power);
 	link = dc_stream_get_link(stream);
 
-	aux_inst = link->dc->link_srv->get_ddc_aux_inst(link);
+	aux_inst = dc_link_get_ddc_aux_inst(link);
 
 	if (!dc_get_edp_link_panel_inst(core_power->dc, stream->link, &panel_inst))
 		return false;
@@ -1128,7 +1128,7 @@ bool mod_power_set_backlight_percent(struct mod_power *mod_power,
 
 	core_power = MOD_POWER_TO_CORE(mod_power);
 	link = dc_stream_get_link(stream);
-	aux_inst = link->dc->link_srv->get_ddc_aux_inst(link);
+	aux_inst = dc_link_get_ddc_aux_inst(link);
 
 	if (!dc_get_edp_link_panel_inst(core_power->dc, stream->link, &panel_inst))
 		return false;
@@ -1658,8 +1658,8 @@ bool mod_power_is_abm_supported(struct mod_power *mod_power,
 	dc = core_power->dc;
 
 	// It's only implemented on dmcub.
-	if (dc->ctx->dmub_srv) {
-		if (!dmub_is_abm_supported(dc->res_pool, inst))
+	if (dc_get_ctx(dc)->dmub_srv) {
+		if (!dmub_is_abm_supported(dc_get_res_pool(dc), inst))
 			return false;
 	} else
 		return false;
@@ -1682,9 +1682,10 @@ bool mod_power_abm_set_event(struct mod_power *mod_power,
 	dc = core_power->dc;
 
 	// It's only implemented on dmcub.
-	if (dc->ctx->dmub_srv) {
-		if (!dmub_set_abm_event(dc->res_pool, full_screen, trans_info,
-				hdr_mode, scaling_enable, scaling_strength_map, inst))
+	if (dc_get_ctx(dc)->dmub_srv) {
+		if (!dmub_set_abm_event(dc_get_res_pool(dc), full_screen,
+				trans_info, hdr_mode, scaling_enable,
+				scaling_strength_map, inst))
 			return false;
 	} else
 		return false;
@@ -1706,8 +1707,8 @@ bool mod_power_abm_set_strength(struct mod_power *mod_power,
 	dc = core_power->dc;
 
 	// It's only implemented on dmcub.
-	if (dc->ctx->dmub_srv) {
-		if (!dmub_set_abm_strength(dc->res_pool, strength, inst))
+	if (dc_get_ctx(dc)->dmub_srv) {
+		if (!dmub_set_abm_strength(dc_get_res_pool(dc), strength, inst))
 			return false;
 	} else
 		return false;
diff --git a/drivers/gpu/drm/amd/display/modules/power/power_psr.c b/drivers/gpu/drm/amd/display/modules/power/power_psr.c
index 96bb77fff05b..af59cf502297 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power_psr.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power_psr.c
@@ -70,13 +70,13 @@ bool mod_power_psr_notify_mode_change(struct mod_power *mod_power,
 
 	psr_config.psr_exit_link_training_required =
 			core_power->map[stream_index].caps->psr_exit_link_training_required;
-	if (dc->ctx->asic_id.chip_family >= AMDGPU_FAMILY_GC_11_0_1)
+	if (dc_get_ctx(dc)->asic_id.chip_family >= AMDGPU_FAMILY_GC_11_0_1)
 		psr_config.allow_smu_optimizations =
 				core_power->psr_smu_optimizations_support && dc_is_embedded_signal(stream->signal);
 	else
 		psr_config.allow_smu_optimizations =
 				core_power->psr_smu_optimizations_support &&
-				mod_power_only_edp(dc->current_state, stream);
+				mod_power_only_edp(dc_get_current_state(dc), stream);
 
 	psr_config.allow_multi_disp_optimizations = core_power->multi_disp_optimizations_support;
 
@@ -455,7 +455,7 @@ void mod_power_psr_residency(struct mod_power *mod_power,
 	link = dc_stream_get_link(stream);
 
 	if (link != NULL)
-		link->dc->link_srv->edp_get_psr_residency(link, residency, mode);
+		dc_link_edp_get_psr_residency(link, residency, mode);
 }
 bool mod_power_psr_get_active_psr_events(struct mod_power *mod_power,
 		const struct dc_stream_state *stream, unsigned int *active_psr_events)
@@ -510,7 +510,7 @@ bool mod_power_psr_set_sink_vtotal_in_psr_active(struct mod_power *mod_power,
 
 	link = dc_stream_get_link(stream);
 
-	return link->dc->link_srv->edp_set_sink_vtotal_in_psr_active(
+	return dc_link_edp_set_sink_vtotal_in_psr_active(
 			link, psr_vtotal_idle, psr_vtotal_su);
 }
 /*
@@ -645,7 +645,7 @@ bool psr_su_set_dsc_slice_height(struct dc *dc, struct dc_link *link,
 
 	config->dsc_slice_height = 0;
 	if (!(link->connector_signal & SIGNAL_TYPE_EDP) ||
-	    !dc->caps.edp_dsc_support ||
+	    !dc_get_caps(dc)->edp_dsc_support ||
 	    link->panel_config.dsc.disable_dsc_edp ||
 	    !link->dpcd_caps.dsc_caps.dsc_basic_caps.fields.dsc_support.DSC_SUPPORT ||
 	    !stream->timing.dsc_cfg.num_slices_v)
diff --git a/drivers/gpu/drm/amd/display/modules/power/power_replay.c b/drivers/gpu/drm/amd/display/modules/power/power_replay.c
index 666585b7e00c..d68f14b18179 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power_replay.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power_replay.c
@@ -372,7 +372,7 @@ bool mod_power_replay_set_coasting_vtotal(struct mod_power *mod_power,
 	if (core_power->num_entities == 0)
 		return false;
 
-	return link->dc->link_srv->edp_set_coasting_vtotal(link, coasting_vtotal, frame_skip_number);
+	return dc_link_edp_set_coasting_vtotal(link, coasting_vtotal, frame_skip_number);
 }
 
 void mod_power_replay_set_timing_sync_supported(struct mod_power *mod_power,
@@ -400,7 +400,7 @@ void mod_power_replay_set_timing_sync_supported(struct mod_power *mod_power,
 
 	cmd_data.sync_data.timing_sync_supported = link->replay_settings.config.replay_timing_sync_supported;
 
-	link->dc->link_srv->edp_send_replay_cmd(link, Replay_Set_Timing_Sync_Supported,
+	dc_link_edp_send_replay_cmd(link, Replay_Set_Timing_Sync_Supported,
 		&cmd_data);
 }
 
@@ -429,7 +429,7 @@ void mod_power_replay_disabled_adaptive_sync_sdp(struct mod_power *mod_power,
 
 	cmd_data.disabled_adaptive_sync_sdp_data.force_disabled = force_disabled;
 
-	link->dc->link_srv->edp_send_replay_cmd(link, Replay_Disabled_Adaptive_Sync_SDP,
+	dc_link_edp_send_replay_cmd(link, Replay_Disabled_Adaptive_Sync_SDP,
 		&cmd_data);
 }
 
@@ -461,7 +461,7 @@ static void mod_power_replay_set_general_cmd(struct mod_power *mod_power,
 	cmd_data.set_general_cmd_data.subtype = general_cmd_type;
 	cmd_data.set_general_cmd_data.param1 = param1;
 	cmd_data.set_general_cmd_data.param2 = param2;
-	link->dc->link_srv->edp_send_replay_cmd(link, Replay_Set_General_Cmd,
+	dc_link_edp_send_replay_cmd(link, Replay_Set_General_Cmd,
 		&cmd_data);
 }
 
@@ -500,7 +500,7 @@ static void mod_power_replay_set_pseudo_vtotal(struct mod_power *mod_power,
 
 	if (link->replay_settings.last_pseudo_vtotal != vtotal) {
 		link->replay_settings.last_pseudo_vtotal = vtotal;
-		link->dc->link_srv->edp_send_replay_cmd(link, Replay_Set_Pseudo_VTotal, &cmd_data);
+		dc_link_edp_send_replay_cmd(link, Replay_Set_Pseudo_VTotal, &cmd_data);
 	}
 }
 
@@ -759,8 +759,7 @@ void mod_power_replay_residency(const struct dc_stream_state *stream,
 	else
 		mode = PR_RESIDENCY_MODE_PHY;
 
-	if (link && link->dc && link->dc->link_srv)
-		link->dc->link_srv->edp_replay_residency(link, residency, is_start, mode);
+	dc_link_edp_replay_residency(link, residency, is_start, mode);
 }
 
 bool mod_power_replay_get_cumulative_residency(const struct dc_stream_state *stream,
@@ -768,10 +767,7 @@ bool mod_power_replay_get_cumulative_residency(const struct dc_stream_state *str
 {
 	const struct dc_link *link = dc_stream_get_link(stream);
 
-	if (!link || !link->dc || !link->dc->link_srv)
-		return false;
-
-	return link->dc->link_srv->edp_replay_get_cumulative_residency(
+	return dc_link_edp_replay_get_cumulative_residency(
 		link, residency_milli_pct);
 }
 
@@ -802,7 +798,8 @@ bool mod_power_replay_set_power_opt_and_coasting_vtotal(struct mod_power *mod_po
 
 	power_opt = mod_power_replay_setup_power_opt(link, active_replay_events, is_ultra_sleep_mode);
 
-	return link->dc->link_srv->edp_set_replay_power_opt_and_coasting_vtotal(link, &power_opt, coasting_vtotal, frame_skip_number);
+	return dc_link_edp_set_replay_power_opt_and_coasting_vtotal(
+			link, &power_opt, coasting_vtotal, frame_skip_number);
 }
 
 void mod_power_replay_notify_mode_change(struct mod_power *mod_power,
@@ -829,14 +826,14 @@ void mod_power_replay_notify_mode_change(struct mod_power *mod_power,
 
 	link->replay_settings.replay_smu_opt_enable =
 		(link->replay_settings.config.replay_smu_opt_supported &&
-		mod_power_only_edp(dc->current_state, stream));
+		mod_power_only_edp(dc_get_current_state(dc), stream));
 
 	if (active_replay_events & replay_event_os_request_force_ffu) {
 		link->replay_settings.config.os_request_force_ffu = true;
 	}
 
 	if (dc_is_embedded_signal(stream->signal))
-		dc->link_srv->dp_setup_replay(link, stream);
+		dc_link_dp_setup_replay(link, stream);
 }
 
 void init_replay_config(struct dc_link *link, struct replay_config *pr_config)

-- 
2.56.0

