From: Davey Hughes <davidralphhughes@gmail.com>
Date: Tue, 27 Oct 2026 06:25:43 -0700
Subject: [PATCH 2/2] drm/amd/display: Test FreeSync flip timing across
 plane resets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-freesync-plane-reset-time-v1-2-bb43b501faf4@gmail.com>
References: <20261027-freesync-plane-reset-time-v1-0-bb43b501faf4@gmail.com>
In-Reply-To: <20261027-freesync-plane-reset-time-v1-0-bb43b501faf4@gmail.com>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Nicholas Kazlauskas <nicholas.kazlauskas@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Davey Hughes <davidralphhughes@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793107546; l=11037;
 i=davidralphhughes@gmail.com; s=20261027; h=from:subject:message-id;
 bh=noQfQHHG6kH0mVBBbepkfdjvsuqRN4qDLINdKPj4CHU=;
 b=2cl7Nd3zslu2tZjleGBfmU2sZwGvAX4dO1xxGCadiGc5raBrd1GgBflDn5V3kXaPf06JgHaXZ
 ngrNrima+q3D258gd0XR3q6nJ++2BVBceG9GKIS5JsBhOH56eyxqwwE
X-Developer-Key: i=davidralphhughes@gmail.com; a=ed25519;
 pk=y45yWVxpjjxFE2cXy96fGlXLfDlt6UKHFHS5szhrFAs=
X-Endpoint-Received: by B4 Relay for davidralphhughes@gmail.com/20261027 with auth_id=1335
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

KUnit can't reach the plane enable path of dm_update_plane_state(), so
the flip timing copy there is untested.

Move the copy into dm_plane_inherit_flip_time() and expose it to KUnit.
Test that a plane reset on the same CRTC keeps its flip timing, and that
a newly enabled plane or one moved to another CRTC starts over.

Also flip a reset plane one 60 Hz frame after its last flip on a
48-165 Hz panel with BTR. With the inherited timing BTR stays off;
without it FreeSync engages BTR.

Signed-off-by: Davey Hughes <davidralphhughes@gmail.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  |  20 ++-
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h  |   3 +
 .../amd/display/amdgpu_dm/tests/amdgpu_dm_test.c   | 190 +++++++++++++++++++++
 3 files changed, 209 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index a69e28685857..d1c1b01584ae 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -5966,6 +5966,20 @@ STATIC_IFN_KUNIT bool should_reset_plane(struct drm_atomic_commit *state,
 }
 EXPORT_IF_KUNIT(should_reset_plane);
 
+/* FreeSync times each frame from the plane's previous flip. */
+STATIC_IFN_KUNIT void
+dm_plane_inherit_flip_time(struct dc_plane_state *dc_plane_state,
+			   struct drm_plane_state *old_plane_state,
+			   struct drm_plane_state *new_plane_state)
+{
+	struct dc_plane_state *old_dc_plane_state =
+		to_dm_plane_state(old_plane_state)->dc_state;
+
+	if (old_dc_plane_state && old_plane_state->crtc == new_plane_state->crtc)
+		dc_plane_state->time = old_dc_plane_state->time;
+}
+EXPORT_IF_KUNIT(dm_plane_inherit_flip_time);
+
 STATIC_IFN_KUNIT int
 dm_update_plane_state(struct dc *dc,
 		      struct drm_atomic_commit *state,
@@ -6076,10 +6090,8 @@ dm_update_plane_state(struct dc *dc,
 			goto out;
 		}
 
-		/* FreeSync times each frame from the plane's previous flip. */
-		if (dm_old_plane_state->dc_state &&
-		    old_plane_crtc == new_plane_crtc)
-			dc_new_plane_state->time = dm_old_plane_state->dc_state->time;
+		dm_plane_inherit_flip_time(dc_new_plane_state, old_plane_state,
+					   new_plane_state);
 
 		drm_dbg_atomic(new_plane_crtc->dev, "Enabling DRM plane: %d on DRM crtc %d\n",
 				 plane->base.id, new_plane_crtc->base.id);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h
index 594d275918d5..18dce8244af1 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h
@@ -1266,6 +1266,9 @@ int dm_update_plane_state(struct dc *dc,
 			  bool enable,
 			  bool *lock_and_validation_needed,
 			  bool *is_top_most_overlay);
+void dm_plane_inherit_flip_time(struct dc_plane_state *dc_plane_state,
+				struct drm_plane_state *old_plane_state,
+				struct drm_plane_state *new_plane_state);
 int amdgpu_dm_atomic_check(struct drm_device *dev,
 			   struct drm_atomic_commit *state);
 void amdgpu_dm_mod_power_update_streams(struct drm_atomic_commit *state,
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
index a497cce332bb..4bdb9831f508 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
@@ -34,6 +34,7 @@
 #include "atom.h"
 #include "amdgpu_dm.h"
 #include "amdgpu_dm_audio.h"
+#include "amdgpu_dm_freesync.h"
 #include "amdgpu_dm_hdcp.h"
 #include "amdgpu_dm_mst_types.h"
 #include "amdgpu_dm_kunit_test_helpers.h"
@@ -3271,6 +3272,190 @@ static void dm_test_update_plane_state_detached(struct kunit *test)
 	KUNIT_EXPECT_NULL(test, new_plane_state->dc_state);
 }
 
+/* Tests for dm_plane_inherit_flip_time() */
+
+struct dm_test_flip_time_ctx {
+	struct dm_plane_state *old_plane_state;
+	struct dm_plane_state *new_plane_state;
+	struct dc_plane_state *dc_plane_state;
+};
+
+/*
+ * A plane reset on one CRTC: the old DC plane has FreeSync flip history and
+ * the new one is freshly created.
+ */
+static struct dm_test_flip_time_ctx *
+dm_test_flip_time_ctx_alloc(struct kunit *test)
+{
+	struct dm_test_flip_time_ctx *ctx;
+	struct dc_plane_state *old_dc;
+	struct drm_crtc *crtc;
+
+	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, ctx);
+	ctx->old_plane_state = kunit_kzalloc(test, sizeof(*ctx->old_plane_state),
+					     GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, ctx->old_plane_state);
+	ctx->new_plane_state = kunit_kzalloc(test, sizeof(*ctx->new_plane_state),
+					     GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, ctx->new_plane_state);
+	ctx->dc_plane_state = kunit_kzalloc(test, sizeof(*ctx->dc_plane_state),
+					    GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, ctx->dc_plane_state);
+	old_dc = kunit_kzalloc(test, sizeof(*old_dc), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, old_dc);
+	crtc = kunit_kzalloc(test, sizeof(*crtc), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, crtc);
+
+	old_dc->time.time_elapsed_in_us[0] = 16667;
+	old_dc->time.index = 1;
+	old_dc->time.prev_update_time_in_us = 1234567;
+	ctx->old_plane_state->dc_state = old_dc;
+	ctx->old_plane_state->base.crtc = crtc;
+	ctx->new_plane_state->base.crtc = crtc;
+
+	return ctx;
+}
+
+static void dm_test_flip_time_inherit(struct dm_test_flip_time_ctx *ctx)
+{
+	dm_plane_inherit_flip_time(ctx->dc_plane_state,
+				   &ctx->old_plane_state->base,
+				   &ctx->new_plane_state->base);
+}
+
+/**
+ * dm_test_flip_time_same_crtc - Test a reset plane keeps its flip history
+ * @test: The KUnit test context
+ */
+static void dm_test_flip_time_same_crtc(struct kunit *test)
+{
+	struct dm_test_flip_time_ctx *ctx = dm_test_flip_time_ctx_alloc(test);
+
+	dm_test_flip_time_inherit(ctx);
+
+	KUNIT_EXPECT_MEMEQ(test, &ctx->dc_plane_state->time,
+			   &ctx->old_plane_state->dc_state->time,
+			   sizeof(ctx->dc_plane_state->time));
+}
+
+/**
+ * dm_test_flip_time_crtc_changed - Test a plane moved between CRTCs starts over
+ * @test: The KUnit test context
+ */
+static void dm_test_flip_time_crtc_changed(struct kunit *test)
+{
+	struct dm_test_flip_time_ctx *ctx = dm_test_flip_time_ctx_alloc(test);
+	struct dc_plane_flip_time *time = &ctx->dc_plane_state->time;
+	struct drm_crtc *other_crtc;
+
+	other_crtc = kunit_kzalloc(test, sizeof(*other_crtc), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, other_crtc);
+	ctx->new_plane_state->base.crtc = other_crtc;
+
+	dm_test_flip_time_inherit(ctx);
+
+	KUNIT_EXPECT_EQ(test, time->prev_update_time_in_us, 0);
+	KUNIT_EXPECT_EQ(test, time->index, 0);
+}
+
+/**
+ * dm_test_flip_time_no_old_dc_state - Test a newly enabled plane starts over
+ * @test: The KUnit test context
+ */
+static void dm_test_flip_time_no_old_dc_state(struct kunit *test)
+{
+	struct dm_test_flip_time_ctx *ctx = dm_test_flip_time_ctx_alloc(test);
+	struct dc_plane_flip_time *time = &ctx->dc_plane_state->time;
+
+	ctx->old_plane_state->dc_state = NULL;
+
+	dm_test_flip_time_inherit(ctx);
+
+	KUNIT_EXPECT_EQ(test, time->prev_update_time_in_us, 0);
+	KUNIT_EXPECT_EQ(test, time->index, 0);
+}
+
+/*
+ * Flip the reset plane one 60 Hz frame after the old plane's last flip on a
+ * 48-165 Hz panel with below-the-range compensation, and report whether
+ * FreeSync engaged BTR.
+ */
+static bool dm_test_flip_time_btr_active(struct kunit *test,
+					 struct dm_test_flip_time_ctx *ctx)
+{
+	struct amdgpu_device *adev = dm_kunit_alloc_adev(test);
+	struct dc_stream_state *stream = dm_kunit_alloc_stream(test, NULL);
+	struct dm_crtc_state *crtc_state;
+	struct mod_vrr_params *vrr;
+	struct amdgpu_crtc *acrtc;
+	u32 flip_time_in_us;
+
+	acrtc = kunit_kzalloc(test, sizeof(*acrtc), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, acrtc);
+	crtc_state = kunit_kzalloc(test, sizeof(*crtc_state), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, crtc_state);
+	adev->dm.adev = adev;
+	/* Only pre-AI flips dereference the module, so a stub will do. */
+	adev->family = AMDGPU_FAMILY_NV;
+	adev->dm.freesync_module = kunit_kzalloc(test, sizeof(struct mod_freesync),
+						 GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, adev->dm.freesync_module);
+
+	/* 165 Hz nominal */
+	stream->ctx = dm_kunit_alloc_dc_with_ctx(test)->ctx;
+	stream->timing.pix_clk_100hz = 4083750;
+	stream->timing.h_total = 2200;
+	stream->timing.v_total = 1125;
+
+	crtc_state->base.crtc = &acrtc->base;
+	crtc_state->base.vrr_enabled = true;
+	crtc_state->stream = stream;
+	crtc_state->vrr_supported = true;
+	crtc_state->freesync_config.min_refresh_in_uhz = 48000000;
+	crtc_state->freesync_config.max_refresh_in_uhz = 165000000;
+	crtc_state->freesync_config.btr = true;
+
+	amdgpu_dm_update_stream_irq_parameters(&adev->dm, crtc_state);
+
+	vrr = &acrtc->dm_irq_params.vrr_params;
+	KUNIT_ASSERT_EQ(test, (int)vrr->state, (int)VRR_STATE_ACTIVE_VARIABLE);
+	KUNIT_ASSERT_TRUE(test, vrr->btr.btr_enabled);
+	KUNIT_ASSERT_FALSE(test, vrr->btr.btr_active);
+
+	flip_time_in_us =
+		ctx->old_plane_state->dc_state->time.prev_update_time_in_us + 16667;
+	amdgpu_dm_update_freesync_state_on_stream(&adev->dm, crtc_state, stream,
+						  ctx->dc_plane_state,
+						  flip_time_in_us);
+
+	return vrr->btr.btr_active;
+}
+
+/**
+ * dm_test_flip_time_btr_inherited - Test a reset plane's next flip stays out of BTR
+ * @test: The KUnit test context
+ */
+static void dm_test_flip_time_btr_inherited(struct kunit *test)
+{
+	struct dm_test_flip_time_ctx *ctx = dm_test_flip_time_ctx_alloc(test);
+
+	dm_test_flip_time_inherit(ctx);
+
+	KUNIT_EXPECT_FALSE(test, dm_test_flip_time_btr_active(test, ctx));
+}
+
+/**
+ * dm_test_flip_time_btr_no_history - Test a plane without flip history enters BTR
+ * @test: The KUnit test context
+ */
+static void dm_test_flip_time_btr_no_history(struct kunit *test)
+{
+	struct dm_test_flip_time_ctx *ctx = dm_test_flip_time_ctx_alloc(test);
+
+	KUNIT_EXPECT_TRUE(test, dm_test_flip_time_btr_active(test, ctx));
+}
+
 /**
  * dm_test_mod_power_update_streams_empty - Test an empty commit updates no streams
  * @test: The KUnit test context
@@ -5361,6 +5546,11 @@ static struct kunit_case amdgpu_dm_tests[] = {
 	KUNIT_CASE(dm_test_aquire_global_lock_waits_commit),
 	KUNIT_CASE(dm_test_update_crtc_state_unchanged),
 	KUNIT_CASE(dm_test_update_plane_state_detached),
+	KUNIT_CASE(dm_test_flip_time_same_crtc),
+	KUNIT_CASE(dm_test_flip_time_crtc_changed),
+	KUNIT_CASE(dm_test_flip_time_no_old_dc_state),
+	KUNIT_CASE(dm_test_flip_time_btr_inherited),
+	KUNIT_CASE(dm_test_flip_time_btr_no_history),
 	KUNIT_CASE(dm_test_mod_power_update_streams_empty),
 	KUNIT_CASE(dm_test_mod_power_update_streams_no_modeset),
 	KUNIT_CASE(dm_test_mod_power_update_streams_enable),

-- 
2.56.0

