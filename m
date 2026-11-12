From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:45 +1000
Subject: [PATCH 10/19] drm/amd/display/amdgpu_dm: Use DC accessors in the
 DM core paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-10-0fae41718ad2@redhat.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=18158; i=airlied@redhat.com;
 h=from:subject:message-id; bh=t+KQpPhNQQ89vABgyW9SfxyEZpMxPkveh1H937vVcz8=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnPhUjQM7SNZz+ftBiL7E8G8loc0VwmAEIDp
 /zgVjbjltSJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZzwAKCRAMdPNZecSG
 vghCEACaXfSSWB1rloHdRd8nWji5d54MALvfJb06CZsyXRqaqYTawQsUUFdfb+8XbBdayfQYZrg
 wSwGdIOPORKzoWmxGyQsXIejFdzDU90+WW5GDeu+QiBvhRlgZgXgeHcD9ZkjPIMRus++GOjXko4
 6tXHMuHsqxmkQwKhBWWrNdrPWfia/JHZzsh86F1nX3d7VIS22IpPTxjtSBInlctu4+Pa1Y3VlZR
 SjFVZvCTY9cgH1iG76OnOKgR/RBLpacx6ZpCdyVoJ1KAKeMPPGJUxp1jjum54i++ePR3sPLhUsK
 Q64g4NW9n08vf0S+x8no4rvCbPEg4MdGSzVp/Wo95kfY0sp/l1XsPPhanxigk488ljrEAWZTg6O
 M7uUpXsDrPYiJfWMli/1UbPczK4ucjxYVvVQ9rkh4iekIvvDFjDoLx6DzNaKXPsdDrIokyMCwM8
 UeWV2GwnBtRpL2MzcMWH+kJ86ZrPaiOsMregfVmwGBBs6rx5ofzYdJMs/bx+eWPuTBJNFvO0gaL
 ExLN3STy+ifqjjGEFbxjU5hPWa52uhUGFb5hRSI60tbL/Q3o/DlSmn/a/6295xMMJYi4J5AzyGI
 YHqpj2dUJvVuK1Lj/fxLiFqDjAbVrw/QjkzDG8PvXKofYeM+2FJK6gd4XsTVZuC4bt5XhPXpEB4
 jyepcGymxq2+JwA==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace direct struct dc member dereferences with the DC accessor
layer in amdgpu_dm.c: dmub context access, caps reads (cursor size,
plane/stream/link counts, IPS, planes array), the module parameter
debug overrides, current_state access across suspend/resume and
master-sync, link iteration, and the DMCU/ABM resource pool reads.

With this, no production code outside DC dereferences struct dc
members anymore; only the amdgpu_dm KUnit tests remain.

Part of making struct dc private to DC.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c | 141 ++++++++++++----------
 1 file changed, 74 insertions(+), 67 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index 94d45e5d2a3b..cab39aa4d41f 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -150,7 +150,7 @@ static int amdgpu_dm_atomic_check(struct drm_device *dev,
 
 static inline void amdgpu_dm_exit_ips_for_hw_access(struct dc *dc)
 {
-	if (dc->ctx->dmub_srv && !dc->ctx->dmub_srv->idle_exit_counter)
+	if (dc_get_ctx(dc)->dmub_srv && !dc_get_ctx(dc)->dmub_srv->idle_exit_counter)
 		dc_exit_ips_for_hw_access(dc);
 }
 
@@ -204,7 +204,7 @@ STATIC_IFN_KUNIT int dm_crtc_get_scanoutpos(struct amdgpu_device *adev, int crtc
 		return 0;
 	}
 
-	if (dc && dc->caps.ips_support && dc->idle_optimizations_allowed)
+	if (dc && dc_get_caps(dc)->ips_support && dc_is_idle_optimizations_allowed(dc))
 		dc_allow_idle_optimizations(dc, false);
 
 	/*
@@ -486,6 +486,7 @@ static int amdgpu_dm_init(struct amdgpu_device *adev)
 {
 	struct dc_init_data init_data;
 	struct dc_callback_init init_params;
+	struct dc_debug_options *debug_opts;
 	int r;
 
 	adev->dm.ddev = adev_to_drm(adev);
@@ -650,62 +651,65 @@ static int amdgpu_dm_init(struct amdgpu_device *adev)
 
 	if (adev->dm.dc) {
 		drm_info(adev_to_drm(adev), "Display Core v%s initialized on %s\n", DC_VER,
-			 dce_version_to_string(adev->dm.dc->ctx->dce_version));
+			 dce_version_to_string(dc_get_dce_version(adev->dm.dc)));
 	} else {
 		drm_info(adev_to_drm(adev), "Display Core failed to initialize with v%s!\n", DC_VER);
 		goto error;
 	}
 
+	debug_opts = dc_get_debug_options_mutable(adev->dm.dc);
+
 	if (amdgpu_dc_debug_mask & DC_DISABLE_PIPE_SPLIT) {
-		adev->dm.dc->debug.force_single_disp_pipe_split = false;
-		adev->dm.dc->debug.pipe_split_policy = MPC_SPLIT_AVOID;
+		debug_opts->force_single_disp_pipe_split = false;
+		debug_opts->pipe_split_policy = MPC_SPLIT_AVOID;
 	}
 
 	if (adev->asic_type != CHIP_CARRIZO && adev->asic_type != CHIP_STONEY)
-		adev->dm.dc->debug.disable_stutter = amdgpu_pp_feature_mask & PP_STUTTER_MODE ? false : true;
+		debug_opts->disable_stutter =
+			amdgpu_pp_feature_mask & PP_STUTTER_MODE ? false : true;
 	if (dm_should_disable_stutter(adev->pdev))
-		adev->dm.dc->debug.disable_stutter = true;
+		debug_opts->disable_stutter = true;
 
 	if (amdgpu_dc_debug_mask & DC_DISABLE_STUTTER)
-		adev->dm.dc->debug.disable_stutter = true;
+		debug_opts->disable_stutter = true;
 
 	if (amdgpu_dc_debug_mask & DC_DISABLE_DSC)
-		adev->dm.dc->debug.disable_dsc = true;
+		debug_opts->disable_dsc = true;
 
 	if (amdgpu_dc_debug_mask & DC_DISABLE_CLOCK_GATING)
-		adev->dm.dc->debug.disable_clock_gate = true;
+		debug_opts->disable_clock_gate = true;
 
 	if (amdgpu_dc_debug_mask & DC_FORCE_SUBVP_MCLK_SWITCH)
-		adev->dm.dc->debug.force_subvp_mclk_switch = true;
+		debug_opts->force_subvp_mclk_switch = true;
 
 	if (amdgpu_dc_debug_mask & DC_DISABLE_SUBVP_FAMS) {
-		adev->dm.dc->debug.force_disable_subvp = true;
-		adev->dm.dc->debug.fams2_config.bits.enable = false;
+		debug_opts->force_disable_subvp = true;
+		debug_opts->fams2_config.bits.enable = false;
 	}
 
 	if (amdgpu_dc_debug_mask & DC_ENABLE_DML2) {
-		adev->dm.dc->debug.using_dml2 = true;
-		adev->dm.dc->debug.using_dml21 = true;
+		debug_opts->using_dml2 = true;
+		debug_opts->using_dml21 = true;
 	}
 
 	if (amdgpu_dc_debug_mask & DC_HDCP_LC_FORCE_FW_ENABLE)
-		adev->dm.dc->debug.hdcp_lc_force_fw_enable = true;
+		debug_opts->hdcp_lc_force_fw_enable = true;
 
 	if (amdgpu_dc_debug_mask & DC_HDCP_LC_ENABLE_SW_FALLBACK)
-		adev->dm.dc->debug.hdcp_lc_enable_sw_fallback = true;
+		debug_opts->hdcp_lc_enable_sw_fallback = true;
 
 	if (amdgpu_dc_debug_mask & DC_SKIP_DETECTION_LT)
-		adev->dm.dc->debug.skip_detection_link_training = true;
+		debug_opts->skip_detection_link_training = true;
 
-	adev->dm.dc->debug.visual_confirm = amdgpu_dc_visual_confirm;
+	debug_opts->visual_confirm = amdgpu_dc_visual_confirm;
 
 	/* TODO: Remove after DP2 receiver gets proper support of Cable ID feature */
-	adev->dm.dc->debug.ignore_cable_id = true;
+	debug_opts->ignore_cable_id = true;
 
 	/* temporary enable immediate restore for FAMS2 */
-	adev->dm.dc->debug.fams2_imm_restore_drr = true;
+	debug_opts->fams2_imm_restore_drr = true;
 
-	if (adev->dm.dc->caps.dp_hdmi21_pcon_support)
+	if (dc_get_caps(adev->dm.dc)->dp_hdmi21_pcon_support)
 		drm_info(adev_to_drm(adev), "DP-HDMI FRL PCON supported\n");
 
 	r = dm_dmub_hw_init(adev);
@@ -749,18 +753,18 @@ static int amdgpu_dm_init(struct amdgpu_device *adev)
 
 	amdgpu_dm_init_color_mod();
 
-	if (adev->dm.dc->caps.max_links > 0) {
+	if (dc_get_caps(adev->dm.dc)->max_links > 0) {
 		adev->dm.vblank_control_workqueue =
 			create_singlethread_workqueue("dm_vblank_control_workqueue");
 		if (!adev->dm.vblank_control_workqueue)
 			drm_err(adev_to_drm(adev), "failed to initialize vblank_workqueue.\n");
 	}
 
-	if (adev->dm.dc->caps.ips_support &&
-	    adev->dm.dc->config.disable_ips != DMUB_IPS_DISABLE_ALL)
+	if (dc_get_caps(adev->dm.dc)->ips_support &&
+	    dc_get_config(adev->dm.dc)->disable_ips != DMUB_IPS_DISABLE_ALL)
 		adev->dm.idle_workqueue = idle_create_workqueue(adev);
 
-	if (adev->dm.dc->caps.max_links > 0 && adev->family >= AMDGPU_FAMILY_RV) {
+	if (dc_get_caps(adev->dm.dc)->max_links > 0 && adev->family >= AMDGPU_FAMILY_RV) {
 		adev->dm.hdcp_workqueue = hdcp_create_workqueue(adev, &init_params.cp_psp, adev->dm.dc);
 
 		if (!adev->dm.hdcp_workqueue)
@@ -772,7 +776,7 @@ static int amdgpu_dm_init(struct amdgpu_device *adev)
 
 		dc_init_callbacks(adev->dm.dc, &init_params);
 	}
-	if (adev->dm.dc->caps.max_links > 0) {
+	if (dc_get_caps(adev->dm.dc)->max_links > 0) {
 		adev->dm.hdmi_frl_status_polling_wq =
 			create_singlethread_workqueue("hdmi_frl_status_polling_wq");
 		if (!adev->dm.hdmi_frl_status_polling_wq)
@@ -836,8 +840,8 @@ static int amdgpu_dm_init(struct amdgpu_device *adev)
 	/* TODO: Add_display_info? */
 
 	/* TODO use dynamic cursor width */
-	adev_to_drm(adev)->mode_config.cursor_width = adev->dm.dc->caps.max_cursor_size;
-	adev_to_drm(adev)->mode_config.cursor_height = adev->dm.dc->caps.max_cursor_size;
+	adev_to_drm(adev)->mode_config.cursor_width = dc_get_caps(adev->dm.dc)->max_cursor_size;
+	adev_to_drm(adev)->mode_config.cursor_height = dc_get_caps(adev->dm.dc)->max_cursor_size;
 
 	if (drm_vblank_init(adev_to_drm(adev), adev->dm.display_indexes_num)) {
 		drm_err(adev_to_drm(adev),
@@ -925,7 +929,7 @@ static void amdgpu_dm_fini(struct amdgpu_device *adev)
 
 	if (adev->dm.dc) {
 		dc_deinit_callbacks(adev->dm.dc);
-		dc_dmub_srv_destroy(&adev->dm.dc->ctx->dmub_srv);
+		dc_dmub_srv_destroy(&dc_get_ctx(adev->dm.dc)->dmub_srv);
 		if (dc_enable_dmub_notifications(adev->dm.dc)) {
 			kfree(adev->dm.dmub_notify);
 			adev->dm.dmub_notify = NULL;
@@ -945,7 +949,7 @@ static void amdgpu_dm_fini(struct amdgpu_device *adev)
 					&adev->dm.boot_time_crc_info.cpu_addr);
 
 	if (adev->dm.hpd_rx_offload_wq && adev->dm.dc) {
-		for (i = 0; i < adev->dm.dc->caps.max_links; i++) {
+		for (i = 0; i < dc_get_caps(adev->dm.dc)->max_links; i++) {
 			if (adev->dm.hpd_rx_offload_wq[i].wq) {
 				destroy_workqueue(adev->dm.hpd_rx_offload_wq[i].wq);
 				adev->dm.hpd_rx_offload_wq[i].wq = NULL;
@@ -1157,11 +1161,11 @@ static void amdgpu_dm_boot_time_crc_init(struct amdgpu_device *adev)
 	const uint32_t fb_size = 3 * 1024 * 1024;	/* 3MB for DCC pattern */
 
 	if (!adev || !adev->dm.dc || !adev->dm.dc->ctx ||
-		!adev->dm.dc->ctx->dmub_srv) {
+		!dc_get_ctx(adev->dm.dc)->dmub_srv) {
 		return;
 	}
 
-	dmub = adev->dm.dc->ctx->dmub_srv->dmub;
+	dmub = dc_get_ctx(adev->dm.dc)->dmub_srv->dmub;
 	bootcrc_info = &adev->dm.boot_time_crc_info;
 
 	if (!dmub || !dmub->hw_funcs.get_fw_boot_option) {
@@ -1205,7 +1209,7 @@ STATIC_IFN_KUNIT int dm_late_init(struct amdgpu_ip_block *ip_block)
 	int i;
 	struct dmcu *dmcu = NULL;
 
-	dmcu = adev->dm.dc->res_pool->dmcu;
+	dmcu = dc_get_res_pool(adev->dm.dc)->dmcu;
 
 	/* Init the boot time CRC (skip in resume) */
 	if ((adev->in_suspend == 0) &&
@@ -1233,13 +1237,13 @@ STATIC_IFN_KUNIT int dm_late_init(struct amdgpu_ip_block *ip_block)
 	if (dmcu) {
 		if (!dmcu_load_iram(dmcu, params))
 			return -EINVAL;
-	} else if (adev->dm.dc->ctx->dmub_srv) {
+	} else if (dc_get_ctx(adev->dm.dc)->dmub_srv) {
 		struct dc_link *edp_links[MAX_NUM_EDP];
 		int edp_num;
 
 		dc_get_edp_links(adev->dm.dc, edp_links, &edp_num);
 		for (i = 0; i < edp_num; i++) {
-			if (!dmub_init_abm_config(adev->dm.dc->res_pool, params, i))
+			if (!dmub_init_abm_config(dc_get_res_pool(adev->dm.dc), params, i))
 				return -EINVAL;
 		}
 	}
@@ -1460,7 +1464,7 @@ STATIC_IFN_KUNIT void dm_gpureset_toggle_interrupts(struct amdgpu_device *adev,
 				drm_warn(adev_to_drm(adev), "Failed to %s pflip interrupts\n",
 					 enable ? "enable" : "disable");
 
-			if (dc_supports_vrr(adev->dm.dc->ctx->dce_version)) {
+			if (dc_supports_vrr(dc_get_dce_version(adev->dm.dc))) {
 				if (enable) {
 					if (amdgpu_dm_crtc_vrr_active(
 							to_dm_crtc_state(acrtc->base.state)))
@@ -1620,7 +1624,7 @@ static int dm_suspend(struct amdgpu_ip_block *ip_block)
 		amdgpu_dm_ism_force_full_power(dm);
 		dc_allow_idle_optimizations(adev->dm.dc, false);
 
-		dm->cached_dc_state = dc_state_create_copy(dm->dc->current_state);
+		dm->cached_dc_state = dc_state_create_copy(dc_get_current_state(dm->dc));
 		if (!dm->cached_dc_state) {
 			drm_err(adev_to_drm(adev),
 				"Failed to allocate cached DC state during suspend\n");
@@ -1671,10 +1675,10 @@ static int dm_suspend(struct amdgpu_ip_block *ip_block)
 
 	dc_set_power_state(dm->dc, DC_ACPI_CM_POWER_STATE_D3);
 
-	if (dm->dc->caps.ips_support && adev->in_s0ix)
+	if (dc_get_caps(dm->dc)->ips_support && adev->in_s0ix)
 		dc_allow_idle_optimizations(dm->dc, true);
 
-	dc_dmub_srv_set_power_state(dm->dc->ctx->dmub_srv, DC_ACPI_CM_POWER_STATE_D3);
+	dc_dmub_srv_set_power_state(dc_get_ctx(dm->dc)->dmub_srv, DC_ACPI_CM_POWER_STATE_D3);
 
 	return 0;
 }
@@ -1837,8 +1841,8 @@ STATIC_IFN_KUNIT void amdgpu_dm_dump_links_and_sinks(struct amdgpu_device *adev)
 	if (!dc)
 		return;
 
-	for (li = 0; li < dc->link_count; li++) {
-		struct dc_link *l = dc->links[li];
+	for (li = 0; li < dc_get_link_count(dc); li++) {
+		struct dc_link *l = dc_get_link_at_index(dc, li);
 		const char *name = NULL;
 		int rs;
 
@@ -1896,14 +1900,15 @@ static int dm_resume(struct amdgpu_ip_block *ip_block)
 	int i, r, j;
 	struct dc_commit_streams_params commit_params = {};
 
-	if (dm->dc->caps.ips_support) {
+	if (dc_get_caps(dm->dc)->ips_support) {
 		if (!amdgpu_in_reset(adev))
 			mutex_lock(&dm->dc_lock);
 
 		/* Need to set POWER_STATE_D0 first or it will not execute
 		 * idle_power_optimizations command to DMUB.
 		 */
-		dc_dmub_srv_set_power_state(dm->dc->ctx->dmub_srv, DC_ACPI_CM_POWER_STATE_D0);
+		dc_dmub_srv_set_power_state(dc_get_ctx(dm->dc)->dmub_srv,
+					 DC_ACPI_CM_POWER_STATE_D0);
 		dc_dmub_srv_apply_idle_power_optimizations(dm->dc, false);
 
 		if (!amdgpu_in_reset(adev))
@@ -1914,7 +1919,7 @@ static int dm_resume(struct amdgpu_ip_block *ip_block)
 		dc_state = dm->cached_dc_state;
 
 		/*
-		 * The dc->current_state is backed up into dm->cached_dc_state
+		 * The dc_get_current_state(dc) is backed up into dm->cached_dc_state
 		 * before we commit 0 streams.
 		 *
 		 * DC will clear link encoder assignments on the real state
@@ -1928,7 +1933,7 @@ static int dm_resume(struct amdgpu_ip_block *ip_block)
 		 * We lose the previous assignments, but we had already
 		 * commit 0 streams anyway.
 		 */
-		link_enc_cfg_copy(adev->dm.dc->current_state, dc_state);
+		link_enc_cfg_copy(dc_get_current_state(adev->dm.dc), dc_state);
 
 		r = dm_dmub_hw_init(adev);
 		if (r) {
@@ -1939,7 +1944,8 @@ static int dm_resume(struct amdgpu_ip_block *ip_block)
 			return r;
 		}
 
-		dc_dmub_srv_set_power_state(dm->dc->ctx->dmub_srv, DC_ACPI_CM_POWER_STATE_D0);
+		dc_dmub_srv_set_power_state(dc_get_ctx(dm->dc)->dmub_srv,
+					 DC_ACPI_CM_POWER_STATE_D0);
 		dc_set_power_state(dm->dc, DC_ACPI_CM_POWER_STATE_D0);
 
 		dc_resume(dm->dc);
@@ -1998,7 +2004,7 @@ static int dm_resume(struct amdgpu_ip_block *ip_block)
 	}
 
 	/* power on hardware */
-	dc_dmub_srv_set_power_state(dm->dc->ctx->dmub_srv, DC_ACPI_CM_POWER_STATE_D0);
+	dc_dmub_srv_set_power_state(dc_get_ctx(dm->dc)->dmub_srv, DC_ACPI_CM_POWER_STATE_D0);
 	dc_set_power_state(dm->dc, DC_ACPI_CM_POWER_STATE_D0);
 
 	/* program HPD filter */
@@ -2340,7 +2346,7 @@ STATIC_IFN_KUNIT int initialize_plane(struct amdgpu_display_manager *dm,
 	 * for a CRTC - like overlay or underlay planes.
 	 */
 	possible_crtcs = 1 << plane_id;
-	if (plane_id >= dm->dc->caps.max_streams)
+	if (plane_id >= dc_get_caps(dm->dc)->max_streams)
 		possible_crtcs = 0xff;
 
 	ret = amdgpu_dm_plane_init(dm, plane, possible_crtcs, plane_cap);
@@ -2380,22 +2386,22 @@ static int amdgpu_dm_initialize_drm_device(struct amdgpu_device *adev)
 	const struct dc_plane_cap *plane;
 	bool psr_feature_enabled = false;
 	bool replay_feature_enabled = false;
-	int max_overlay = dm->dc->caps.max_slave_planes;
+	int max_overlay = dc_get_caps(dm->dc)->max_slave_planes;
 
-	dm->display_indexes_num = dm->dc->caps.max_streams;
+	dm->display_indexes_num = dc_get_caps(dm->dc)->max_streams;
 	/* Update the actual used number of crtc */
 	adev->mode_info.num_crtc = adev->dm.display_indexes_num;
 
 	amdgpu_dm_set_irq_funcs(adev);
 
-	link_cnt = dm->dc->caps.max_links;
+	link_cnt = dc_get_caps(dm->dc)->max_links;
 	if (amdgpu_dm_mode_config_init(dm->adev)) {
 		drm_err(adev_to_drm(adev), "DM: Failed to initialize mode config\n");
 		return -EINVAL;
 	}
 
 	/* There is one primary plane per CRTC */
-	primary_planes = dm->dc->caps.max_streams;
+	primary_planes = dc_get_caps(dm->dc)->max_streams;
 	if (primary_planes > AMDGPU_MAX_PLANES) {
 		drm_err(adev_to_drm(adev), "DM: Plane nums out of 6 planes\n");
 		return -EINVAL;
@@ -2406,7 +2412,7 @@ static int amdgpu_dm_initialize_drm_device(struct amdgpu_device *adev)
 	 * Order is reversed to match iteration order in atomic check.
 	 */
 	for (i = (primary_planes - 1); i >= 0; i--) {
-		plane = &dm->dc->caps.planes[i];
+		plane = &dc_get_caps(dm->dc)->planes[i];
 
 		if (initialize_plane(dm, mode_info, i,
 				     DRM_PLANE_TYPE_PRIMARY, plane)) {
@@ -2424,8 +2430,8 @@ static int amdgpu_dm_initialize_drm_device(struct amdgpu_device *adev)
 	 * Only support DCN for now, and only expose one so we don't encourage
 	 * userspace to use up all the pipes.
 	 */
-	for (i = 0; i < dm->dc->caps.max_planes; ++i) {
-		struct dc_plane_cap *plane = &dm->dc->caps.planes[i];
+	for (i = 0; i < dc_get_caps(dm->dc)->max_planes; ++i) {
+		const struct dc_plane_cap *plane = &dc_get_caps(dm->dc)->planes[i];
 
 		/* Do not create overlay if MPO disabled */
 		if (amdgpu_dc_debug_mask & DC_DISABLE_MPO)
@@ -2447,7 +2453,7 @@ static int amdgpu_dm_initialize_drm_device(struct amdgpu_device *adev)
 		}
 	}
 
-	for (i = 0; i < dm->dc->caps.max_streams; i++)
+	for (i = 0; i < dc_get_caps(dm->dc)->max_streams; i++)
 		if (amdgpu_dm_crtc_init(dm, mode_info->planes[i], i)) {
 			drm_err(adev_to_drm(adev), "KMS: Failed to initialize crtc\n");
 			goto fail;
@@ -3717,7 +3723,7 @@ STATIC_IFN_KUNIT void amdgpu_dm_update_cursor(struct drm_plane *plane,
 	 * legacy gamma setup.
 	 */
 	if (crtc_state->cm_is_degamma_srgb &&
-	    adev->dm.dc->caps.color.dpp.gamma_corr)
+	    dc_get_caps(adev->dm.dc)->color.dpp.gamma_corr)
 		attributes.attribute_flags.bits.ENABLE_CURSOR_DEGAMMA = 1;
 
 	if (afb)
@@ -4843,8 +4849,9 @@ dm_set_writeback(struct amdgpu_display_manager *dm,
 	}
 
 	for (i = 0; i < MAX_PIPES; i++) {
-		if (dm->dc->current_state->res_ctx.pipe_ctx[i].stream == crtc_state->stream) {
-			pipe = &dm->dc->current_state->res_ctx.pipe_ctx[i];
+		if (dc_get_current_state(dm->dc)->res_ctx.pipe_ctx[i].stream ==
+		    crtc_state->stream) {
+			pipe = &dc_get_current_state(dm->dc)->res_ctx.pipe_ctx[i];
 			break;
 		}
 	}
@@ -6795,14 +6802,14 @@ void amdgpu_dm_trigger_timing_sync(struct drm_device *dev)
 	int i;
 
 	mutex_lock(&adev->dm.dc_lock);
-	if (dc->current_state) {
-		for (i = 0; i < dc->current_state->stream_count; ++i)
-			dc->current_state->streams[i]
+	if (dc_get_current_state(dc)) {
+		for (i = 0; i < dc_get_current_state(dc)->stream_count; ++i)
+			dc_get_current_state(dc)->streams[i]
 				->triggered_crtc_reset.enabled =
 				adev->dm.force_timing_sync;
 
-		dm_enable_per_frame_crtc_master_sync(dc->current_state);
-		dc_trigger_sync(dc, dc->current_state);
+		dm_enable_per_frame_crtc_master_sync(dc_get_current_state(dc));
+		dc_trigger_sync(dc, dc_get_current_state(dc));
 	}
 	mutex_unlock(&adev->dm.dc_lock);
 }
@@ -6872,8 +6879,8 @@ void amdgpu_dm_update_memclk_states(struct amdgpu_device *adev)
 	if (!dc)
 		return;
 
-	if (dc->ctx->dce_version != DCN_VERSION_3_2 &&
-	    dc->ctx->dce_version != DCN_VERSION_3_21)
+	if (dc_get_dce_version(dc) != DCN_VERSION_3_2 &&
+	    dc_get_dce_version(dc) != DCN_VERSION_3_21)
 		return;
 
 	mutex_lock(&adev->dm.dc_lock);

-- 
2.56.0

