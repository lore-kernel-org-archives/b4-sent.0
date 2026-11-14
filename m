From: Hugo Sales <hugo@hsal.es>
Date: Sat, 14 Nov 2026 23:09:17 +0000
Subject: [PATCH 6/8] drm/amd/display: Pick the FreeSync video config for
 the new stream's sink
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-amdgpu-modes-four-v1-6-f11e2a6cd407@hsal.es>
References: <20261114-amdgpu-modes-four-v1-0-f11e2a6cd407@hsal.es>
In-Reply-To: <20261114-amdgpu-modes-four-v1-0-f11e2a6cd407@hsal.es>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Ray Wu <ray.wu@amd.com>, Fangzhi Zuo <jerry.zuo@amd.com>, 
 Roman Li <roman.li@amd.com>, Alex Hung <alex.hung@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Ville_Syrj=C3=A4l=C3=A4?= <ville.syrjala@linux.intel.com>, 
 Aurabindo Pillai <aurabindo.pillai@amd.com>, Hugo Sales <hugo@hsal.es>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8860; i=hugo@hsal.es;
 h=from:subject:message-id; bh=K1OqMu2z0cS5OKNcUtjzHIpeJClxFpuOC0WXXrEQz9E=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsn68kohk5o4VXfumTEz13P3WF+8ET+c9+HZjSlaK6
 tf/00KeLzPsKGVhEONikBVTZNG94cnAMnHyzJyi50tg5rAygQxh4OIUgIlEnWJkeP8mqlkg4E+P
 yuL2PQd1Ep7/mz7PS2vxkd5dnpqrq282rGRk2N11vlpwVeRHpYz9NgEOR9wYN90VWZL0pfGMRIU
 bm1cBAwCzxEzp
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dm_update_crtc_state() picks the fixed refresh config for a FreeSync
video mode in its first pass, while it removes the old stream, and
create_stream_for_sink() picks that mode's timing in the second pass,
for the new stream's sink. The two answers agree only because neither
lookup depends on the sink yet. An upcoming patch makes them depend on
it, and atomic_check doesn't hold mode_config.mutex, so a hotplug can
swap dc_sink between the two passes

Move the choice to dm_set_freesync_video_config(), called whenever a
stream is added, and ask about new_stream->sink. A CRTC that the commit
turns off no longer gets the fixed config

A DPMS off commit now only clears the fixed config, and the DPMS on
commit, which adds the stream again, sets it. Before, the DPMS on
commit inherited it through the duplicated CRTC state. A CRTC turned on
straight into a FreeSync video mode now gets the fixed config too, which
the old code never set

This only applies with the amdgpu.freesync_video=1 module parameter,
which is off by default

Signed-off-by: Hugo Sales <hugo@hsal.es>
---
Before this patch, a CRTC turned on straight into a FreeSync video mode
never got the fixed refresh config, since the first pass sets it only
in a commit with an old stream. That looks like a bug from commit
6f59f229f8ed ("drm/amd/display: Skip modeset for front porch change"),
but I haven't confirmed it on hardware. Was leaving it unset intended?
If not, I can split the fix out into its own patch with a Fixes tag

dm_set_freesync_video_config() reads new_stream->sink, which
dc_stream_state marks deprecated. The stream holds the only reference
to the sink it was built for, and keeping a second one in dm_crtc_state
would need its own retain and release on duplicate and destroy. I can
do that, or have amdgpu_dm_create_validate_stream_for_sink() return the
sink, if you'd rather not read the field
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  | 39 +++++++++++----
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h  |  3 ++
 .../amd/display/amdgpu_dm/tests/amdgpu_dm_test.c   | 58 ++++++++++++++++++++++
 3 files changed, 91 insertions(+), 9 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index d67384eba1553..706a63b93ef6b 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -5516,6 +5516,33 @@ STATIC_IFN_KUNIT int do_aquire_global_lock(struct drm_device *dev,
 }
 EXPORT_IF_KUNIT(do_aquire_global_lock);
 
+/*
+ * Use the fixed refresh config for a FreeSync video mode other than its base.
+ * create_stream_for_sink() picked @new_stream's timing for new_stream->sink,
+ * so decide for that sink too, even if a hotplug swapped dc_sink after the
+ * old stream was built. dc_stream_state marks sink deprecated, but
+ * dm_update_crtc_state() keeps no other record of the sink the stream was
+ * built for
+ */
+STATIC_IFN_KUNIT void
+dm_set_freesync_video_config(struct amdgpu_dm_connector *aconnector,
+			     struct dm_crtc_state *dm_new_crtc_state,
+			     const struct dc_stream_state *new_stream)
+{
+	const struct drm_display_mode *mode = &dm_new_crtc_state->base.mode;
+	struct drm_display_mode *high_mode;
+
+	if (!amdgpu_freesync_vid_mode ||
+	    !amdgpu_dm_is_freesync_video_mode(mode, aconnector, new_stream->sink))
+		return;
+
+	high_mode = amdgpu_dm_get_highest_refresh_rate_mode(aconnector, false,
+							    new_stream->sink);
+	if (high_mode && !drm_mode_equal(mode, high_mode))
+		amdgpu_dm_set_freesync_fixed_config(dm_new_crtc_state);
+}
+EXPORT_IF_KUNIT(dm_set_freesync_video_config);
+
 STATIC_IFN_KUNIT int dm_update_crtc_state(struct amdgpu_display_manager *dm,
 					  struct drm_atomic_commit *state,
 					  struct drm_crtc *crtc,
@@ -5664,15 +5691,6 @@ STATIC_IFN_KUNIT int dm_update_crtc_state(struct amdgpu_display_manager *dm,
 			amdgpu_dm_set_freesync_fixed_config(dm_new_crtc_state);
 
 			goto skip_modeset;
-		} else if (amdgpu_freesync_vid_mode && aconnector &&
-			   amdgpu_dm_is_freesync_video_mode(&new_crtc_state->mode,
-						  aconnector, aconnector->dc_sink)) {
-			struct drm_display_mode *high_mode;
-
-			high_mode = amdgpu_dm_get_highest_refresh_rate_mode(aconnector, false,
-									    aconnector->dc_sink);
-			if (!drm_mode_equal(&new_crtc_state->mode, high_mode))
-				amdgpu_dm_set_freesync_fixed_config(dm_new_crtc_state);
 		}
 
 		ret = dm_atomic_get_state(state, &dm_state);
@@ -5735,6 +5753,9 @@ STATIC_IFN_KUNIT int dm_update_crtc_state(struct amdgpu_display_manager *dm,
 			}
 
 			*needs_dc_state_realloc = true;
+
+			dm_set_freesync_video_config(aconnector, dm_new_crtc_state,
+						     new_stream);
 		}
 	}
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h
index 97a74178513a9..926f1794d24e5 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h
@@ -1286,6 +1286,9 @@ void amdgpu_dm_update_hdcp(struct drm_atomic_commit *state);
 int amdgpu_dm_atomic_setup_commit(struct drm_atomic_commit *state);
 int do_aquire_global_lock(struct drm_device *dev,
 			  struct drm_atomic_commit *state);
+void dm_set_freesync_video_config(struct amdgpu_dm_connector *aconnector,
+				  struct dm_crtc_state *dm_new_crtc_state,
+				  const struct dc_stream_state *new_stream);
 int dm_update_crtc_state(struct amdgpu_display_manager *dm,
 			 struct drm_atomic_commit *state,
 			 struct drm_crtc *crtc,
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
index b9272b28f53c7..fab6df40ed989 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
@@ -3213,6 +3213,63 @@ static void dm_test_aquire_global_lock_waits_commit(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, ret, 0);
 }
 
+/**
+ * dm_test_freesync_video_config_no_old_stream - Test the fixed config needs no old stream
+ * @test: The KUnit test context
+ *
+ * A DPMS off commit clears the fixed refresh config while it removes the old
+ * stream, so the DPMS on commit has no old stream and starts from an inactive
+ * config. A 50 Hz FreeSync video mode of a 1080p60 base must get the fixed
+ * config back from the new stream alone, and the base itself must not get it
+ */
+static void dm_test_freesync_video_config_no_old_stream(struct kunit *test)
+{
+	uint saved_vid_mode = amdgpu_freesync_vid_mode;
+	struct amdgpu_dm_connector *aconnector;
+	struct drm_display_mode *base, *mode;
+	struct dm_crtc_state *crtc_state;
+	struct dc_stream_state *stream;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	crtc_state = kunit_kzalloc(test, sizeof(*crtc_state), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, crtc_state);
+	stream = kunit_kzalloc(test, sizeof(*stream), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, stream);
+
+	aconnector->base.connector_type = DRM_MODE_CONNECTOR_HDMIA;
+	base = &aconnector->freesync_vid_base;
+	base->clock = 148500;
+	base->hdisplay = 1920;
+	base->hsync_start = 2008;
+	base->hsync_end = 2052;
+	base->htotal = 2200;
+	base->vdisplay = 1080;
+	base->vsync_start = 1084;
+	base->vsync_end = 1089;
+	base->vtotal = 1125;
+
+	crtc_state->freesync_config.state = VRR_STATE_INACTIVE;
+	mode = &crtc_state->base.mode;
+	drm_mode_copy(mode, base);
+
+	amdgpu_freesync_vid_mode = 1;
+
+	dm_set_freesync_video_config(aconnector, crtc_state, stream);
+	KUNIT_EXPECT_EQ(test, (int)crtc_state->freesync_config.state,
+			(int)VRR_STATE_INACTIVE);
+
+	mode->vsync_start += 225;
+	mode->vsync_end += 225;
+	mode->vtotal += 225;
+	dm_set_freesync_video_config(aconnector, crtc_state, stream);
+	KUNIT_EXPECT_EQ(test, (int)crtc_state->freesync_config.state,
+			(int)VRR_STATE_ACTIVE_FIXED);
+	KUNIT_EXPECT_EQ(test, crtc_state->freesync_config.fixed_refresh_in_uhz, 50000000U);
+
+	amdgpu_freesync_vid_mode = saved_vid_mode;
+}
+
 /**
  * dm_test_update_crtc_state_unchanged - Test unchanged state needs no validation
  * @test: The KUnit test context
@@ -5359,6 +5416,7 @@ static struct kunit_case amdgpu_dm_tests[] = {
 	KUNIT_CASE(dm_test_aquire_global_lock_no_crtc),
 	KUNIT_CASE(dm_test_aquire_global_lock_no_commit),
 	KUNIT_CASE(dm_test_aquire_global_lock_waits_commit),
+	KUNIT_CASE(dm_test_freesync_video_config_no_old_stream),
 	KUNIT_CASE(dm_test_update_crtc_state_unchanged),
 	KUNIT_CASE(dm_test_update_plane_state_detached),
 	KUNIT_CASE(dm_test_mod_power_update_streams_empty),

-- 
2.56.0

