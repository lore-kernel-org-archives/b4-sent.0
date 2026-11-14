From: Hugo Sales <hugo@hsal.es>
Date: Sat, 14 Nov 2026 23:09:19 +0000
Subject: [PATCH 8/8] drm/amd/display: Add KUnit tests for the mode copies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-amdgpu-modes-four-v1-8-f11e2a6cd407@hsal.es>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=10931; i=hugo@hsal.es;
 h=from:subject:message-id; bh=0Ok0LbQjfbD5jZ0plsL2pNY0UFR/TkJW9zWYDxB4hFk=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsn68kigO08yI/TLvq0xof9B+n5cWN1k3BC/1tjXsP
 NSterF28r6OUhYGMS4GWTFFFt0bngwsEyfPzCl6vgRmDisTyBAGLk4BmEjMG4b/uYnKJ/dc/95i
 u41zRQwz24XdNQuV4rZuswg/mlUQJrzeguGv7IsPt/583LnNq6JPevI2vz9Xlki6feBmVvk94Uf
 Gopl7GAAHek47
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test that atomic_check reads the mode copies, not connector->modes, and
only for the sink they came from. The highest refresh rate lookup
returns nothing without a copy, even with modes in connector->modes, and
nothing for a sink with another EDID or none, while a replugged sink
with the same EDID keeps the copy. Scaling ignores a preferred mode copy
from another sink, and dm_set_freesync_video_config() sets the fixed
refresh config only when the copies match the new stream's sink

Signed-off-by: Hugo Sales <hugo@hsal.es>
---
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c     | 120 +++++++++++++++++++++
 .../amd/display/amdgpu_dm/tests/amdgpu_dm_test.c   |  69 ++++++++++++
 2 files changed, 189 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
index 71ad7e4ea5c9e..6fbf85e50872c 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
@@ -2534,6 +2534,95 @@ static void dm_test_highest_refresh_preferred_mode(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, aconnector->freesync_vid_base.clock, 0);
 }
 
+/**
+ * dm_test_highest_refresh_skips_modes - Test atomic_check callers never walk base.modes
+ * @test: The KUnit test context
+ *
+ * base.modes needs &drm_mode_config.mutex, which atomic_check doesn't hold.
+ * Without a copy the lookup returns NULL, even though base.modes has a mode
+ */
+static void dm_test_highest_refresh_skips_modes(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector;
+	struct dc_sink *sink;
+	struct drm_display_mode *mode;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	mode = kunit_kzalloc(test, sizeof(*mode), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, mode);
+
+	aconnector->base.connector_type = DRM_MODE_CONNECTOR_HDMIA;
+	INIT_LIST_HEAD(&aconnector->base.modes);
+	INIT_LIST_HEAD(&aconnector->base.probed_modes);
+
+	mode->type = DRM_MODE_TYPE_PREFERRED;
+	mode->clock = 148500;
+	mode->hdisplay = 1920;
+	mode->vdisplay = 1080;
+	mode->htotal = 2200;
+	mode->vtotal = 1125;
+	list_add_tail(&mode->head, &aconnector->base.modes);
+
+	sink = dm_test_copies_sink(test, aconnector);
+	KUNIT_EXPECT_NULL(test, dm_test_highest_locked(test, aconnector, false, sink));
+	KUNIT_EXPECT_EQ(test, aconnector->freesync_vid_base.clock, 0);
+}
+
+/**
+ * dm_test_highest_refresh_other_sink - Test a copy from another sink is ignored
+ * @test: The KUnit test context
+ *
+ * After a monitor swap the copy describes the previous monitor until the next
+ * probe, so a sink with another EDID, or with none, gets no freesync base. A
+ * new sink with the same EDID, as after a replug, keeps it
+ */
+static void dm_test_highest_refresh_other_sink(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector;
+	struct drm_display_mode *mode;
+	struct dc_sink *probed, *other, *replugged, *no_edid;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	mode = kunit_kzalloc(test, sizeof(*mode), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, mode);
+	other = kunit_kzalloc(test, sizeof(*other), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, other);
+	replugged = kunit_kzalloc(test, sizeof(*replugged), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, replugged);
+	no_edid = kunit_kzalloc(test, sizeof(*no_edid), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, no_edid);
+
+	aconnector->base.connector_type = DRM_MODE_CONNECTOR_HDMIA;
+	INIT_LIST_HEAD(&aconnector->base.probed_modes);
+	aconnector->freesync_vid_base.clock = 148500;
+	aconnector->freesync_vid_base.hdisplay = 1920;
+	aconnector->freesync_vid_base.vdisplay = 1080;
+	aconnector->freesync_vid_base.htotal = 2200;
+	aconnector->freesync_vid_base.vtotal = 1125;
+	drm_mode_copy(mode, &aconnector->freesync_vid_base);
+
+	probed = dm_test_copies_sink(test, aconnector);
+	replugged->dc_edid = probed->dc_edid;
+	other->dc_edid = probed->dc_edid;
+	other->dc_edid.raw_edid[12]++;
+
+	KUNIT_EXPECT_PTR_EQ(test,
+			    dm_test_highest_locked(test, aconnector, false, probed),
+			    &aconnector->freesync_vid_base);
+	KUNIT_EXPECT_TRUE(test, dm_test_is_fs_video_locked(test, mode, aconnector, probed));
+	KUNIT_EXPECT_PTR_EQ(test,
+			    dm_test_highest_locked(test, aconnector, false, replugged),
+			    &aconnector->freesync_vid_base);
+
+	KUNIT_EXPECT_NULL(test, dm_test_highest_locked(test, aconnector, false, other));
+	KUNIT_EXPECT_FALSE(test, dm_test_is_fs_video_locked(test, mode, aconnector, other));
+	KUNIT_EXPECT_NULL(test,
+			  dm_test_highest_locked(test, aconnector, false, no_edid));
+	KUNIT_EXPECT_NULL(test, dm_test_highest_locked(test, aconnector, false, NULL));
+}
+
 /* Tests for amdgpu_dm_connector_update_mode_copies() */
 
 static struct drm_display_mode *
@@ -8233,6 +8322,34 @@ static void dm_test_create_validate_stream_scaled_copy(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, dm_test_cvs_first_h_addressable, 3840);
 }
 
+/**
+ * dm_test_create_validate_stream_stale_copy - Test atomic_check ignores a stale copy
+ * @test: The KUnit test context
+ *
+ * After a monitor swap the connector has a sink with another EDID, and the
+ * copy describes the previous monitor. Its timing must not be applied, even
+ * with scaling on
+ */
+static void dm_test_create_validate_stream_stale_copy(struct kunit *test)
+{
+	struct dm_test_cvs_dc *c = dm_test_cvs_dc_alloc(test);
+
+	/* drm_mode_convert_umode() fills in the CRTC timing of atomic modes */
+	drm_mode_set_crtcinfo(c->mode, CRTC_INTERLACE_HALVE_V);
+	c->dm_state->scaling = RMX_FULL;
+	dm_test_cvs_set_preferred_copy(test, c);
+	c->aconnector->dc_sink->dc_edid.raw_edid[12]++;
+	c->tgfuncs->validate_timing = dm_test_cvs_record_first_h_addressable;
+	dm_test_cvs_first_h_addressable = 0;
+
+	KUNIT_EXPECT_NULL(test,
+			  dm_test_validate_locked(&c->aconnector->base,
+						  c->mode,
+						  c->dm_state,
+						  NULL));
+	KUNIT_EXPECT_EQ(test, dm_test_cvs_first_h_addressable, 1920);
+}
+
 /**
  * dm_test_mode_valid_ignores_preferred_copy - Test mode_valid uses the mode's own timing
  * @test: The KUnit test context
@@ -11271,6 +11388,8 @@ static struct kunit_case amdgpu_dm_connector_tests[] = {
 	KUNIT_CASE(dm_test_highest_refresh_cached_base),
 	KUNIT_CASE(dm_test_highest_refresh_preferred_mode),
 	KUNIT_CASE(dm_test_highest_refresh_probed_skips_copy),
+	KUNIT_CASE(dm_test_highest_refresh_skips_modes),
+	KUNIT_CASE(dm_test_highest_refresh_other_sink),
 	/* amdgpu_dm_connector_update_mode_copies */
 	KUNIT_CASE(dm_test_update_mode_copies_highest_refresh),
 	KUNIT_CASE(dm_test_update_mode_copies_no_preferred),
@@ -11503,6 +11622,7 @@ static struct kunit_case amdgpu_dm_connector_tests[] = {
 	KUNIT_CASE(dm_test_create_validate_stream_prune_context),
 	KUNIT_CASE(dm_test_create_validate_stream_hdmi_rgb_first),
 	KUNIT_CASE(dm_test_create_validate_stream_scaled_copy),
+	KUNIT_CASE(dm_test_create_validate_stream_stale_copy),
 	KUNIT_CASE(dm_test_mode_valid_ignores_preferred_copy),
 	/* amdgpu_dm_update_connector_after_detect */
 	KUNIT_CASE(dm_test_update_after_detect_mst_noop),
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
index 8eaa5909068bc..b6b3964ce497d 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
@@ -3296,6 +3296,74 @@ static void dm_test_freesync_video_config_no_old_stream(struct kunit *test)
 	amdgpu_freesync_vid_mode = saved_vid_mode;
 }
 
+/**
+ * dm_test_freesync_video_config_new_sink - Test the fixed config follows the new stream's sink
+ * @test: The KUnit test context
+ *
+ * The mode is a 50 Hz FreeSync video mode of a 1080p60 base. The fixed config
+ * is set only when the copies match the sink the new stream was built for,
+ * the sink create_stream_for_sink() checked when it picked the timing
+ */
+static void dm_test_freesync_video_config_new_sink(struct kunit *test)
+{
+	uint saved_vid_mode = amdgpu_freesync_vid_mode;
+	struct amdgpu_dm_connector *aconnector;
+	struct drm_display_mode *base, *mode;
+	struct dm_crtc_state *crtc_state;
+	struct dc_stream_state *stream;
+	struct dc_sink *sink, *other;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	crtc_state = kunit_kzalloc(test, sizeof(*crtc_state), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, crtc_state);
+	stream = kunit_kzalloc(test, sizeof(*stream), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, stream);
+	sink = kunit_kzalloc(test, sizeof(*sink), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, sink);
+	other = kunit_kzalloc(test, sizeof(*other), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, other);
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
+	mode = &crtc_state->base.mode;
+	drm_mode_copy(mode, base);
+	mode->vsync_start += 225;
+	mode->vsync_end += 225;
+	mode->vtotal += 225;
+
+	memset(sink->dc_edid.raw_edid, 0x5a, 128);
+	sink->dc_edid.length = 128;
+	other->dc_edid = sink->dc_edid;
+	other->dc_edid.raw_edid[12]++;
+	aconnector->mode_copies_edid_size = 128;
+	memcpy(aconnector->mode_copies_edid, sink->dc_edid.raw_edid, 128);
+
+	amdgpu_freesync_vid_mode = 1;
+
+	stream->sink = other;
+	dm_test_fs_video_config_locked(test, aconnector, crtc_state, stream);
+	KUNIT_EXPECT_EQ(test, (int)crtc_state->freesync_config.state,
+			(int)VRR_STATE_UNSUPPORTED);
+
+	stream->sink = sink;
+	dm_test_fs_video_config_locked(test, aconnector, crtc_state, stream);
+	KUNIT_EXPECT_EQ(test, (int)crtc_state->freesync_config.state,
+			(int)VRR_STATE_ACTIVE_FIXED);
+
+	amdgpu_freesync_vid_mode = saved_vid_mode;
+}
+
 /**
  * dm_test_update_crtc_state_unchanged - Test unchanged state needs no validation
  * @test: The KUnit test context
@@ -5443,6 +5511,7 @@ static struct kunit_case amdgpu_dm_tests[] = {
 	KUNIT_CASE(dm_test_aquire_global_lock_no_commit),
 	KUNIT_CASE(dm_test_aquire_global_lock_waits_commit),
 	KUNIT_CASE(dm_test_freesync_video_config_no_old_stream),
+	KUNIT_CASE(dm_test_freesync_video_config_new_sink),
 	KUNIT_CASE(dm_test_update_crtc_state_unchanged),
 	KUNIT_CASE(dm_test_update_plane_state_detached),
 	KUNIT_CASE(dm_test_mod_power_update_streams_empty),

-- 
2.56.0

