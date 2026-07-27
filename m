From: "LIN, Yijun" <jameslinchina@outlook.com>
Date: Mon, 27 Jul 2026 10:41:36 +0800
Subject: [PATCH] drm/amd/display: fix DCN VUPDATE page-flip completion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260727-dcn-vupdate-flip-completion-v1-1-4a985b8526f1@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MQQqEMAwAwK+EnA10I1rpV8SDtHE34LalVRHEv
 wvOA+bCKkWlooMLixxaNUV08GkA/W+OXyEN6ADZcG8sWwo+0rHnMG9Cy6qZfPrnVTZNkbgfOtM
 aO3DL2ADmIoue7z5O9/0AJKbbLm0AAAA=
X-Change-ID: 20260727-dcn-vupdate-flip-completion-268503078232
To: amd-gfx@lists.freedesktop.org
Cc: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785120113; l=24077;
 i=jameslinchina@outlook.com; s=20260727; h=from:subject:message-id;
 bh=O1WP/FGBQHYmdcWN6O9h1lCysvPsKwDQwsoUklMIaLE=;
 b=05z2OOF7nYRjAqd40dWnd4RQnGpDmlVGN+CfP0L+tc7CWzS26ZfdGYvEffJCrn/ZkmOdnjDfI
 Iqw8wPwRIDVAh4TuPLmhHm+Kche9Pbs89EsODHzG0WvhYyflMXtENpe
X-Developer-Key: i=jameslinchina@outlook.com; a=ed25519;
 pk=qH+dsJvZ6tRhsTArbiKsuFU02LTOouIstmb1ntK/pdc=
X-Endpoint-Received: by B4 Relay for jameslinchina@outlook.com/20260727 with auth_id=896
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

VUPDATE page-flip delivery must wait for the hardware surface flip
latch, but dc_get_flip_pending_on_otg() reused hubp_is_flip_pending().
That predicate also waits for EARLIEST_INUSE to match the mutable
request address because existing DC status paths use it for address
convergence and resource retirement. The address comparison can remain
mismatched after SURFACE_FLIP_PENDING clears, leaving the DRM event
armed forever.

Add a dedicated raw HUBP surface-flip callback while preserving the
existing composite predicate. Snapshot the physical HUBPs feeding the
OTG under dc_lock after programming, store that mask with the event, and
query only stable resource-pool HUBPs from VUPDATE IRQ context. Arm the
event before the optimistic query so the vblank reference keeps the
hardware accessible, without entering IPS or walking current_state from
hardirq.

Fixes: 48ab86360af1 ("drm/amd/display: check GRPH_FLIP status before sending event")
Link: https://gitlab.freedesktop.org/drm/amd/-/work_items/5527
Assisted-by: Codex:GPT-5.6-Sol
Signed-off-by: LIN, Yijun <jameslinchina@outlook.com>
---
This fixes a 7.2-rc4 regression where a DCN VUPDATE page-flip event can
remain armed even though the hardware surface flip has already latched.
KWin then reports "flip_done timed out", and the SDDM Plasma login screen
appears frozen with no usable mouse or keyboard input.

The problem was reproduced on a Lenovo Legion R7000P ADR10 with a Ryzen
9 8940HX Raphael iGPU (1002:164e, DCN 3.1.5), using the internal
2560x1600 panel at 240 Hz. Fedora's 7.2-rc2 kernel was good and 7.2-rc4
was bad.

The captured failure state showed:

  SURFACE_FLIP_PENDING = 0
  EARLIEST_INUSE       = 0xf40c000000
  requested address    = 0xf40a000000

VUPDATE interrupts continued at approximately 240 Hz, but the event was
not delivered because the composite status helper also waited for the
address comparison.

The patch was built and boot-tested on the affected machine. SDDM,
KWin, and Plasma started normally, with no flip_done timeout,
dm_arm_vblank_event warning, GPU reset, or VM fault in the tested boot.

Related report (same 7.2-rc4 flip-timeout class):
https://gitlab.freedesktop.org/drm/amd/-/work_items/5527
---
 drivers/gpu/drm/amd/amdgpu/amdgpu_mode.h           |  1 +
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  | 32 ++++++---
 drivers/gpu/drm/amd/display/dc/core/dc.c           | 76 +++++++++++++++-------
 drivers/gpu/drm/amd/display/dc/dc.h                |  3 +-
 .../gpu/drm/amd/display/dc/hubp/dcn10/dcn10_hubp.c | 17 ++++-
 .../gpu/drm/amd/display/dc/hubp/dcn10/dcn10_hubp.h |  1 +
 .../gpu/drm/amd/display/dc/hubp/dcn20/dcn20_hubp.c | 15 +++++
 .../gpu/drm/amd/display/dc/hubp/dcn20/dcn20_hubp.h |  2 +-
 .../drm/amd/display/dc/hubp/dcn201/dcn201_hubp.c   |  1 +
 .../gpu/drm/amd/display/dc/hubp/dcn21/dcn21_hubp.c |  1 +
 .../gpu/drm/amd/display/dc/hubp/dcn30/dcn30_hubp.c |  1 +
 .../gpu/drm/amd/display/dc/hubp/dcn31/dcn31_hubp.c |  1 +
 .../gpu/drm/amd/display/dc/hubp/dcn32/dcn32_hubp.c |  1 +
 .../gpu/drm/amd/display/dc/hubp/dcn35/dcn35_hubp.c |  2 +-
 .../drm/amd/display/dc/hubp/dcn401/dcn401_hubp.c   |  1 +
 .../gpu/drm/amd/display/dc/hubp/dcn42/dcn42_hubp.c |  1 +
 drivers/gpu/drm/amd/display/dc/inc/hw/hubp.h       |  1 +
 17 files changed, 119 insertions(+), 38 deletions(-)

diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_mode.h b/drivers/gpu/drm/amd/amdgpu/amdgpu_mode.h
index 8069fc41cc7f..2c032aa5ea3e 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_mode.h
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_mode.h
@@ -483,6 +483,7 @@ struct amdgpu_crtc {
 	/* page flipping */
 	struct amdgpu_flip_work *pflip_works;
 	enum amdgpu_flip_status pflip_status;
+	u32 flip_hubp_mask;
 	int deferred_flip_completion;
 	/* parameters access from DM IRQ handler */
 	struct dm_irq_params dm_irq_params;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index 9c564cd5edee..4285a8f184cc 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -682,8 +682,8 @@ static void dm_crtc_high_irq_handler(struct amdgpu_device *adev,
 	 *
 	 * Since GRPH_PFLIP is not used, VUPDATE_NO_LOCK is the flip latch
 	 * point. Deliver any pending pageflip completion event from here,
-	 * once HW has consumed the new address (the OTG no longer reports a
-	 * pending flip).
+	 * once HW has consumed the new address (the HUBPs captured for this
+	 * event no longer report a pending surface flip).
 	 *
 	 * Also handle the case here where there aren't any active planes and
 	 * DCN HUBP may be clock-gated, so the flip-pending status may be
@@ -692,11 +692,13 @@ static void dm_crtc_high_irq_handler(struct amdgpu_device *adev,
 	if (is_dcn && acrtc->pflip_status == AMDGPU_FLIP_SUBMITTED &&
 	    acrtc->event) {
 
-		if (!dc_get_flip_pending_on_otg(adev->dm.dc, acrtc->otg_inst)) {
+		if (!dc_get_flip_pending_on_hubp_mask(adev->dm.dc,
+						     acrtc->flip_hubp_mask)) {
 			drm_crtc_send_vblank_event(&acrtc->base, acrtc->event);
 			acrtc->event = NULL;
 			drm_crtc_vblank_put(&acrtc->base);
 			acrtc->pflip_status = AMDGPU_FLIP_NONE;
+			acrtc->flip_hubp_mask = 0;
 		}
 		/*
 		 * If the flip is still pending, leave it armed and
@@ -711,6 +713,7 @@ static void dm_crtc_high_irq_handler(struct amdgpu_device *adev,
 			drm_crtc_vblank_put(&acrtc->base);
 		}
 		acrtc->pflip_status = AMDGPU_FLIP_NONE;
+		acrtc->flip_hubp_mask = 0;
 	}
 
 	spin_unlock_irqrestore(&adev_to_drm(adev)->event_lock, flags);
@@ -10265,7 +10268,8 @@ static void amdgpu_dm_enable_self_refresh(struct amdgpu_display_manager *dm,
 static void dm_arm_vblank_event(struct amdgpu_crtc *acrtc,
 				struct dm_crtc_state *acrtc_state,
 				bool pflip_update,
-				bool cursor_update)
+				bool cursor_update,
+				u32 flip_hubp_mask)
 {
 	assert_spin_locked(&acrtc->base.dev->event_lock);
 
@@ -10275,6 +10279,7 @@ static void dm_arm_vblank_event(struct amdgpu_crtc *acrtc,
 	if (pflip_update) {
 		drm_crtc_vblank_get(&acrtc->base);
 		WARN_ON(acrtc->pflip_status != AMDGPU_FLIP_NONE);
+		acrtc->flip_hubp_mask = flip_hubp_mask;
 		/* Arm flip completion handling and event delivery after programming. */
 		prepare_flip_isr(acrtc);
 	} else if (cursor_update) {
@@ -10303,6 +10308,7 @@ static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 	int planes_count = 0, vpos, hpos;
 	unsigned long flags;
 	u32 target_vblank, last_flip_vblank;
+	u32 flip_hubp_mask = 0;
 	bool vrr_active = amdgpu_dm_crtc_vrr_active(acrtc_state);
 	bool cursor_update = false;
 	bool pflip_present = false;
@@ -10558,7 +10564,7 @@ static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 	if (amdgpu_ip_version(dm->adev, DCE_HWIP, 0) == 0) {
 		scoped_guard(spinlock_irqsave, &pcrtc->dev->event_lock) {
 			dm_arm_vblank_event(acrtc_attach, acrtc_state,
-					pflip_present, cursor_update);
+					pflip_present, cursor_update, 0);
 		}
 	}
 
@@ -10619,6 +10625,9 @@ static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 					 &bundle->stream_update,
 					 bundle->surface_updates);
 		updated_planes_and_streams = true;
+		if (pflip_present)
+			flip_hubp_mask =
+				dc_get_hubp_mask_on_otg(dm->dc, acrtc_attach->otg_inst);
 
 		/**
 		 * Enable or disable the interrupts on the backend.
@@ -10735,14 +10744,16 @@ static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 	if (amdgpu_ip_version(dm->adev, DCE_HWIP, 0) != 0) {
 		spin_lock_irqsave(&pcrtc->dev->event_lock, flags);
 
-		if (updated_planes_and_streams) {
+		dm_arm_vblank_event(acrtc_attach, acrtc_state,
+				    pflip_present, cursor_update, flip_hubp_mask);
+
+		if (updated_planes_and_streams && pflip_present &&
+		    acrtc_attach->event) {
 			flip_latched_during_prog =
-				!dc_get_flip_pending_on_otg(dm->dc, acrtc_attach->otg_inst);
+				!dc_get_flip_pending_on_hubp_mask(dm->dc,
+								  flip_hubp_mask);
 		}
 
-		dm_arm_vblank_event(acrtc_attach, acrtc_state,
-				    pflip_present, cursor_update);
-
 		/*
 		 * Deliver the event immediately on immediate flip, or on a
 		 * update that has already latched.
@@ -10756,6 +10767,7 @@ static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 			acrtc_attach->event = NULL;
 			drm_crtc_vblank_put(&acrtc_attach->base);
 			acrtc_attach->pflip_status = AMDGPU_FLIP_NONE;
+			acrtc_attach->flip_hubp_mask = 0;
 		}
 		spin_unlock_irqrestore(&pcrtc->dev->event_lock, flags);
 	}
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc.c b/drivers/gpu/drm/amd/display/dc/core/dc.c
index e25b94b65dac..ca6d61b799ae 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc.c
@@ -6166,29 +6166,22 @@ void dc_interrupt_ack(struct dc *dc, enum dc_irq_source src)
 }
 
 /*
- * dc_get_flip_pending_on_otg() - Check if a GRPH_FLIP is still pending on OTG
+ * dc_get_hubp_mask_on_otg() - Snapshot HUBPs feeding an OTG
  *
- * @dc: display core context @otg_inst: OTG instance to query
+ * @dc: display core context
+ * @otg_inst: OTG instance to query
  *
- * Reads the HUBP flip-pending status for the pipe(s) bound to @otg_inst,
- * returning true if any of them has not yet latched its programmed surface
- * address.
- *
- * Unlike dc_plane_get_status(), this does not take or mutate a dc_plane_state,
- * so it is safe to call from interrupt context without racing a concurrent
- * commit that may be updating plane state.
- *
- * Return: true if a flip is still pending on the OTG, false otherwise.
+ * This walks current_state and must be called from a context that serializes
+ * DC commits. The returned mask can be saved with a page-flip event and later
+ * queried from interrupt context without dereferencing current_state.
  */
-bool dc_get_flip_pending_on_otg(struct dc *dc, int otg_inst)
+uint32_t dc_get_hubp_mask_on_otg(struct dc *dc, int otg_inst)
 {
-	bool flip_pending = false;
-	int i;
+	uint32_t hubp_mask = 0;
+	int i, j;
 
 	if (!dc || !dc->current_state)
-		return false;
-
-	dc_exit_ips_for_hw_access(dc);
+		return 0;
 
 	for (i = 0; i < dc->res_pool->pipe_count; i++) {
 		struct pipe_ctx *pipe_ctx = &dc->current_state->res_ctx.pipe_ctx[i];
@@ -6200,14 +6193,52 @@ bool dc_get_flip_pending_on_otg(struct dc *dc, int otg_inst)
 		if (pipe_ctx->stream_res.tg->inst != otg_inst)
 			continue;
 
-		if (hubp && hubp->funcs->hubp_is_flip_pending &&
-		    hubp->funcs->hubp_is_flip_pending(hubp)) {
-			flip_pending = true;
-			break;
+		for (j = 0; hubp && j < dc->res_pool->pipe_count; j++) {
+			if (dc->res_pool->hubps[j] == hubp) {
+				hubp_mask |= 1U << j;
+				break;
+			}
 		}
 	}
 
-	return flip_pending;
+	return hubp_mask;
+}
+
+/*
+ * dc_get_flip_pending_on_hubp_mask() - Check event-specific HUBP latch state
+ *
+ * @dc: display core context
+ * @hubp_mask: HUBPs captured for the page-flip event
+ *
+ * Reads only the hardware surface-flip latch status. In particular, this does
+ * not use the stronger EARLIEST_INUSE address convergence check used by DC
+ * update-status and resource-retirement paths. The caller must keep the
+ * associated vblank event armed so the HUBPs remain accessible.
+ *
+ * Return: true if a captured HUBP still has a flip pending, false otherwise.
+ */
+bool dc_get_flip_pending_on_hubp_mask(struct dc *dc, uint32_t hubp_mask)
+{
+	int i;
+
+	if (!dc || !hubp_mask)
+		return true;
+
+	for (i = 0; i < dc->res_pool->pipe_count; i++) {
+		struct hubp *hubp;
+
+		if (!(hubp_mask & (1U << i)))
+			continue;
+
+		hubp = dc->res_pool->hubps[i];
+		if (!hubp || !hubp->funcs->hubp_is_surface_flip_pending)
+			return true;
+
+		if (hubp->funcs->hubp_is_surface_flip_pending(hubp))
+			return true;
+	}
+
+	return false;
 }
 
 void dc_power_down_on_boot(struct dc *dc)
@@ -8274,4 +8305,3 @@ bool dc_update_planes_and_stream_cleanup(
 			? update_planes_and_stream_cleanup_v3(scratch)
 			: update_planes_and_stream_cleanup_v2(scratch);
 }
-
diff --git a/drivers/gpu/drm/amd/display/dc/dc.h b/drivers/gpu/drm/amd/display/dc/dc.h
index 1dc85f6b6689..3e8c3a6317b1 100644
--- a/drivers/gpu/drm/amd/display/dc/dc.h
+++ b/drivers/gpu/drm/amd/display/dc/dc.h
@@ -2883,7 +2883,8 @@ enum dc_irq_source dc_interrupt_to_irq_source(
 		uint32_t ext_id);
 bool dc_interrupt_set(struct dc *dc, enum dc_irq_source src, bool enable);
 void dc_interrupt_ack(struct dc *dc, enum dc_irq_source src);
-bool dc_get_flip_pending_on_otg(struct dc *dc, int otg_inst);
+uint32_t dc_get_hubp_mask_on_otg(struct dc *dc, int otg_inst);
+bool dc_get_flip_pending_on_hubp_mask(struct dc *dc, uint32_t hubp_mask);
 enum dc_irq_source dc_get_hpd_irq_source_at_index(
 		struct dc *dc, uint32_t link_index);
 
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn10/dcn10_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn10/dcn10_hubp.c
index 7c97a774141f..2e2ab939ad1f 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn10/dcn10_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn10/dcn10_hubp.c
@@ -751,6 +751,20 @@ static void hubp1_setup_interdependent(
 		QoS_LEVEL_FLIP, ttu_attr->qos_level_flip);
 }
 
+bool hubp1_is_surface_flip_pending(struct hubp *hubp)
+{
+	uint32_t flip_pending = 0;
+	struct dcn10_hubp *hubp1 = TO_DCN10_HUBP(hubp);
+
+	if (hubp && hubp->power_gated)
+		return false;
+
+	REG_GET(DCSURF_FLIP_CONTROL,
+			SURFACE_FLIP_PENDING, &flip_pending);
+
+	return flip_pending;
+}
+
 bool hubp1_is_flip_pending(struct hubp *hubp)
 {
 	uint32_t flip_pending = 0;
@@ -1369,6 +1383,7 @@ static const struct hubp_funcs dcn10_hubp_funcs = {
 	.hubp_program_surface_config =
 			hubp1_program_surface_config,
 	.hubp_is_flip_pending = hubp1_is_flip_pending,
+	.hubp_is_surface_flip_pending = hubp1_is_surface_flip_pending,
 	.hubp_setup = hubp1_setup,
 	.hubp_setup_interdependent = hubp1_setup_interdependent,
 	.hubp_set_vm_system_aperture_settings = hubp1_set_vm_system_aperture_settings,
@@ -1419,5 +1434,3 @@ void dcn10_hubp_construct(
 	hubp1->base.opp_id = OPP_ID_INVALID;
 	hubp1->base.mpcc_id = 0xf;
 }
-
-
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn10/dcn10_hubp.h b/drivers/gpu/drm/amd/display/dc/hubp/dcn10/dcn10_hubp.h
index f2571076fc50..06e442986700 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn10/dcn10_hubp.h
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn10/dcn10_hubp.h
@@ -908,6 +908,7 @@ bool hubp1_program_surface_flip_and_addr(
 	bool flip_immediate);
 
 bool hubp1_is_flip_pending(struct hubp *hubp);
+bool hubp1_is_surface_flip_pending(struct hubp *hubp);
 
 void hubp1_cursor_set_attributes(
 		struct hubp *hubp,
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn20/dcn20_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn20/dcn20_hubp.c
index cf2c9f80056e..792cce718f51 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn20/dcn20_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn20/dcn20_hubp.c
@@ -924,6 +924,20 @@ void hubp2_set_flip_control_surface_gsl(struct hubp *hubp, bool enable)
 	REG_UPDATE(DCSURF_FLIP_CONTROL2, SURFACE_GSL_ENABLE, enable ? 1 : 0);
 }
 
+bool hubp2_is_surface_flip_pending(struct hubp *hubp)
+{
+	uint32_t flip_pending = 0;
+	struct dcn20_hubp *hubp2 = TO_DCN20_HUBP(hubp);
+
+	if (hubp && hubp->power_gated)
+		return false;
+
+	REG_GET(DCSURF_FLIP_CONTROL,
+			SURFACE_FLIP_PENDING, &flip_pending);
+
+	return flip_pending;
+}
+
 bool hubp2_is_flip_pending(struct hubp *hubp)
 {
 	uint32_t flip_pending = 0;
@@ -1679,6 +1693,7 @@ static struct hubp_funcs dcn20_hubp_funcs = {
 	.hubp_program_surface_flip_and_addr = hubp2_program_surface_flip_and_addr,
 	.hubp_program_surface_config = hubp2_program_surface_config,
 	.hubp_is_flip_pending = hubp2_is_flip_pending,
+	.hubp_is_surface_flip_pending = hubp2_is_surface_flip_pending,
 	.hubp_setup = hubp2_setup,
 	.hubp_setup_interdependent = hubp2_setup_interdependent,
 	.hubp_set_vm_system_aperture_settings = hubp2_set_vm_system_aperture_settings,
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn20/dcn20_hubp.h b/drivers/gpu/drm/amd/display/dc/hubp/dcn20/dcn20_hubp.h
index 80be394a8852..65b1f3f651a1 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn20/dcn20_hubp.h
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn20/dcn20_hubp.h
@@ -400,6 +400,7 @@ void hubp2_program_surface_config(
 	unsigned int compat_level);
 
 bool hubp2_is_flip_pending(struct hubp *hubp);
+bool hubp2_is_surface_flip_pending(struct hubp *hubp);
 
 void hubp2_set_blank(struct hubp *hubp, bool blank);
 void hubp2_set_blank_regs(struct hubp *hubp, bool blank);
@@ -423,4 +424,3 @@ void hubp2_clear_tiling(struct hubp *hubp);
 
 #endif /* __DC_MEM_INPUT_DCN20_H__ */
 
-
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn201/dcn201_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn201/dcn201_hubp.c
index ec88ee424a7f..62f8a9115892 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn201/dcn201_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn201/dcn201_hubp.c
@@ -115,6 +115,7 @@ static struct hubp_funcs dcn201_hubp_funcs = {
 	.hubp_program_surface_flip_and_addr = hubp1_program_surface_flip_and_addr,
 	.hubp_program_surface_config = hubp201_program_surface_config,
 	.hubp_is_flip_pending = hubp1_is_flip_pending,
+	.hubp_is_surface_flip_pending = hubp1_is_surface_flip_pending,
 	.hubp_setup = hubp201_setup,
 	.hubp_setup_interdependent = hubp2_setup_interdependent,
 	.set_cursor_attributes	= hubp2_cursor_set_attributes,
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn21/dcn21_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn21/dcn21_hubp.c
index 67828505939a..3b92ea311f6f 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn21/dcn21_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn21/dcn21_hubp.c
@@ -818,6 +818,7 @@ static struct hubp_funcs dcn21_hubp_funcs = {
 	.hubp_program_surface_flip_and_addr = hubp21_program_surface_flip_and_addr,
 	.hubp_program_surface_config = hubp1_program_surface_config,
 	.hubp_is_flip_pending = hubp1_is_flip_pending,
+	.hubp_is_surface_flip_pending = hubp1_is_surface_flip_pending,
 	.hubp_setup = hubp21_setup,
 	.hubp_setup_interdependent = hubp2_setup_interdependent,
 	.hubp_set_vm_system_aperture_settings = hubp21_set_vm_system_aperture_settings,
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn30/dcn30_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn30/dcn30_hubp.c
index 3e5ae0eae39f..97c3cb22606e 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn30/dcn30_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn30/dcn30_hubp.c
@@ -633,6 +633,7 @@ static struct hubp_funcs dcn30_hubp_funcs = {
 	.hubp_program_surface_flip_and_addr = hubp3_program_surface_flip_and_addr,
 	.hubp_program_surface_config = hubp3_program_surface_config,
 	.hubp_is_flip_pending = hubp2_is_flip_pending,
+	.hubp_is_surface_flip_pending = hubp2_is_surface_flip_pending,
 	.hubp_setup = hubp3_setup,
 	.hubp_setup_interdependent = hubp2_setup_interdependent,
 	.hubp_set_vm_system_aperture_settings = hubp3_set_vm_system_aperture_settings,
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn31/dcn31_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn31/dcn31_hubp.c
index 189045f85039..dbe4c8978576 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn31/dcn31_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn31/dcn31_hubp.c
@@ -86,6 +86,7 @@ static struct hubp_funcs dcn31_hubp_funcs = {
 	.hubp_program_surface_flip_and_addr = hubp3_program_surface_flip_and_addr,
 	.hubp_program_surface_config = hubp3_program_surface_config,
 	.hubp_is_flip_pending = hubp2_is_flip_pending,
+	.hubp_is_surface_flip_pending = hubp2_is_surface_flip_pending,
 	.hubp_setup = hubp3_setup,
 	.hubp_setup_interdependent = hubp2_setup_interdependent,
 	.hubp_set_vm_system_aperture_settings = hubp3_set_vm_system_aperture_settings,
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn32/dcn32_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn32/dcn32_hubp.c
index a781085b046b..e422dd502067 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn32/dcn32_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn32/dcn32_hubp.c
@@ -193,6 +193,7 @@ static struct hubp_funcs dcn32_hubp_funcs = {
 	.hubp_program_surface_flip_and_addr = hubp3_program_surface_flip_and_addr,
 	.hubp_program_surface_config = hubp3_program_surface_config,
 	.hubp_is_flip_pending = hubp2_is_flip_pending,
+	.hubp_is_surface_flip_pending = hubp2_is_surface_flip_pending,
 	.hubp_setup = hubp3_setup,
 	.hubp_setup_interdependent = hubp2_setup_interdependent,
 	.hubp_set_vm_system_aperture_settings = hubp3_set_vm_system_aperture_settings,
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn35/dcn35_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn35/dcn35_hubp.c
index c879f4901c7d..7b59a729922f 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn35/dcn35_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn35/dcn35_hubp.c
@@ -195,6 +195,7 @@ static struct hubp_funcs dcn35_hubp_funcs = {
 	.hubp_program_surface_flip_and_addr = hubp3_program_surface_flip_and_addr,
 	.hubp_program_surface_config = hubp35_program_surface_config,
 	.hubp_is_flip_pending = hubp2_is_flip_pending,
+	.hubp_is_surface_flip_pending = hubp2_is_surface_flip_pending,
 	.hubp_setup = hubp3_setup,
 	.hubp_setup_interdependent = hubp2_setup_interdependent,
 	.hubp_set_vm_system_aperture_settings = hubp3_set_vm_system_aperture_settings,
@@ -242,4 +243,3 @@ bool hubp35_construct(
 	return true;
 }
 
-
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn401/dcn401_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn401/dcn401_hubp.c
index 302515128358..d886d143c63f 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn401/dcn401_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn401/dcn401_hubp.c
@@ -1036,6 +1036,7 @@ static struct hubp_funcs dcn401_hubp_funcs = {
 	.hubp_program_surface_flip_and_addr = hubp401_program_surface_flip_and_addr,
 	.hubp_program_surface_config = hubp401_program_surface_config,
 	.hubp_is_flip_pending = hubp2_is_flip_pending,
+	.hubp_is_surface_flip_pending = hubp2_is_surface_flip_pending,
 	.hubp_setup2 = hubp401_setup,
 	.hubp_setup_interdependent2 = hubp401_setup_interdependent,
 	.hubp_set_vm_system_aperture_settings = hubp3_set_vm_system_aperture_settings,
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn42/dcn42_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn42/dcn42_hubp.c
index e4602c3ddc66..0355b11cc635 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn42/dcn42_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn42/dcn42_hubp.c
@@ -581,6 +581,7 @@ struct hubp_funcs dcn42_hubp_funcs = {
 	.hubp_program_surface_flip_and_addr = hubp42_program_surface_flip_and_addr,
 	.hubp_program_surface_config = hubp42_program_surface_config,
 	.hubp_is_flip_pending = hubp2_is_flip_pending,
+	.hubp_is_surface_flip_pending = hubp2_is_surface_flip_pending,
 	.hubp_setup2 = hubp42_setup,
 	.hubp_setup_interdependent2 = hubp401_setup_interdependent,
 	.hubp_set_vm_system_aperture_settings = hubp3_set_vm_system_aperture_settings,
diff --git a/drivers/gpu/drm/amd/display/dc/inc/hw/hubp.h b/drivers/gpu/drm/amd/display/dc/inc/hw/hubp.h
index 1c18898aa475..b9f6d36ae23f 100644
--- a/drivers/gpu/drm/amd/display/dc/inc/hw/hubp.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/hw/hubp.h
@@ -218,6 +218,7 @@ struct hubp_funcs {
 		unsigned int compa_level);
 
 	bool (*hubp_is_flip_pending)(struct hubp *hubp);
+	bool (*hubp_is_surface_flip_pending)(struct hubp *hubp);
 
 	void (*set_blank)(struct hubp *hubp, bool blank);
 	void (*set_blank_regs)(struct hubp *hubp, bool blank);

---
base-commit: f39283eab44fb7e304677b2aa1d8c38f151b6566
change-id: 20260727-dcn-vupdate-flip-completion-268503078232

Best regards,
-- 
LIN, Yijun <jameslinchina@outlook.com>

