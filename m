From: Hugo Sales <hugo@hsal.es>
Date: Sat, 14 Nov 2026 23:09:18 +0000
Subject: [PATCH 7/8] drm/amd/display: Stop reading connector->modes from
 atomic_check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261114-amdgpu-modes-four-v1-7-f11e2a6cd407@hsal.es>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=59840; i=hugo@hsal.es;
 h=from:subject:message-id; bh=sZBa/Hn/9N0t/MM7I1KG2Fgn9oKCsPrkp2LPO+Qmf3w=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsn68kvgady7jme/aI9O+30uQjTy/PllywzvxH61lF
 7TWMRduqOTtKGVhEONikBVTZNG94cnAMnHyzJyi50tg5rAygQxh4OIUgImUdzAyvFLZ2HCOe3mI
 /KqoLkb3CFOrS9tMuhW3bN4Xd3Xtm3f/HjH8dzjhw+HMsGKh9u/8usfOUVxTVYqsa4oO/z97V//
 vp65CNgCooU43
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Have amdgpu_dm_create_validate_stream_for_sink() and
amdgpu_dm_get_highest_refresh_rate_mode() read the copies that
amdgpu_dm_connector_update_mode_copies() writes under connection_mutex,
instead of walking connector->modes without mode_config.mutex. Their
atomic_check callers hold connection_mutex, and both lookups now assert
the lock they need. A missing copy counts as an empty list

Use the copies only for a sink with the EDID recorded with them. After a
monitor swap the HPD handlers run an atomic commit before the next
probe, and the old copies would have scaling drive the new monitor at
the old native timing. Without copies, create_stream_for_sink() uses the
requested mode's own timing, as before the first probe

A sink without EDID never matches. create_stream_for_sink() used to
scale such a sink to the first entry of connector->modes, the largest of
the drm_add_modes_noedid() defaults, and now drives the requested mode's
own timing

A hotplug can swap dc_sink while atomic_check runs, so the copies are
checked against the sink of the stream being built.
create_stream_for_sink() passes its own, and
dm_set_freesync_video_config() passes new_stream->sink

The probe and hotplug paths hold mode_config.mutex and pass in_probe,
renamed from use_probed_modes since the other case no longer walks any
list. For them amdgpu_dm_get_highest_refresh_rate_mode() walks
probed_modes, falling back to the copy when it is empty. On a first
probe, with no copy yet, mode_valid checks FreeSync video modes with
their own vtotal, which is fine since their pixel clock and htotal match
the base mode

Link: https://lore.kernel.org/r/auh8pUx_kXUYSdZ8@intel.com
Signed-off-by: Hugo Sales <hugo@hsal.es>
---
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.c    | 131 ++++--
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.h    |   5 +-
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c     | 523 ++++++++++++++-------
 .../amd/display/amdgpu_dm/tests/amdgpu_dm_test.c   |  30 +-
 4 files changed, 474 insertions(+), 215 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
index bddab6a462563..c1b814c9fa865 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
@@ -1177,6 +1177,22 @@ amdgpu_dm_probed_freesync_vid_base_listed(struct list_head *modes,
 	return false;
 }
 
+/*
+ * Whether the mode copies were taken from a probe of @sink, or of a sink with
+ * the same EDID, as after a replug of the same monitor. A sink without EDID
+ * never matches, since nothing tells two of them apart. A hotplug can swap
+ * dc_sink while atomic_check runs, so atomic_check passes the sink of the
+ * stream it builds or checks rather than reading dc_sink again
+ */
+static bool amdgpu_dm_mode_copies_match(const struct amdgpu_dm_connector *aconnector,
+					const struct dc_sink *sink)
+{
+	u32 size = amdgpu_dm_sink_edid_size(sink);
+
+	return size && size == aconnector->mode_copies_edid_size &&
+	       !memcmp(sink->dc_edid.raw_edid, aconnector->mode_copies_edid, size);
+}
+
 /**
  * DOC: FreeSync Video
  *
@@ -1209,35 +1225,49 @@ amdgpu_dm_probed_freesync_vid_base_listed(struct list_head *modes,
  */
 struct drm_display_mode *
 amdgpu_dm_get_highest_refresh_rate_mode(struct amdgpu_dm_connector *aconnector,
-		bool use_probed_modes, const struct dc_sink *sink)
+		bool in_probe, const struct dc_sink *sink)
 {
+	struct drm_mode_config *config = &aconnector->base.dev->mode_config;
+	struct list_head *probed = &aconnector->base.probed_modes;
 	struct drm_display_mode *m_pref;
-	struct list_head *list_head = use_probed_modes ?
-		&aconnector->base.probed_modes :
-		&aconnector->base.modes;
 
 	if (aconnector->base.connector_type == DRM_MODE_CONNECTOR_WRITEBACK)
 		return NULL;
 
 	/*
-	 * A probe reads its own probed_modes, not the copy of the last one. The
-	 * copy stands in while probed_modes is empty
+	 * With @in_probe this walks probed_modes, which needs
+	 * &drm_mode_config.mutex. Other callers read only the copies, which are
+	 * written under both locks, so either is enough. atomic_check holds
+	 * connection_mutex and mode_valid holds &drm_mode_config.mutex
 	 */
-	if (aconnector->freesync_vid_base.clock != 0 &&
-	    !(use_probed_modes && !list_empty(list_head)))
-		return &aconnector->freesync_vid_base;
+	if (in_probe)
+		lockdep_assert_held(&config->mutex);
+	else
+		lockdep_assert(lockdep_is_held(&config->mutex) ||
+			       lockdep_is_held(&config->connection_mutex.mutex.base));
 
-	m_pref = amdgpu_dm_find_preferred_mode(list_head);
-	if (!m_pref) {
+	/*
+	 * During a probe, probed_modes holds this probe's modes, which the
+	 * previous probe's copy may not match
+	 */
+	if (in_probe && !list_empty(probed)) {
+		m_pref = amdgpu_dm_find_preferred_mode(probed);
 		/* Probably an EDID with no preferred mode. Fallback to first entry */
-		m_pref = list_first_entry_or_null(list_head, struct drm_display_mode, head);
-		if (!m_pref) {
-			drm_dbg_driver(aconnector->base.dev, "No preferred mode found in EDID\n");
-			return NULL;
-		}
+		if (!m_pref)
+			m_pref = list_first_entry(probed, struct drm_display_mode, head);
+
+		return amdgpu_dm_find_highest_refresh_mode(probed, m_pref);
 	}
 
-	return amdgpu_dm_find_highest_refresh_mode(list_head, m_pref);
+	/*
+	 * atomic_check can't take &drm_mode_config.mutex, so it reads only the
+	 * copy, and only for the sink it was taken from
+	 */
+	if (aconnector->freesync_vid_base.clock != 0 &&
+	    amdgpu_dm_mode_copies_match(aconnector, sink))
+		return &aconnector->freesync_vid_base;
+
+	return NULL;
 }
 EXPORT_IF_KUNIT(amdgpu_dm_get_highest_refresh_rate_mode);
 
@@ -1724,12 +1754,24 @@ create_stream_for_sink(struct drm_connector *connector,
 
 	mode_refresh = drm_mode_vrefresh(&mode);
 
+	/*
+	 * After a monitor swap, the copies describe the previous monitor until
+	 * the next probe. Check them against the sink this stream is for, which
+	 * a hotplug may swap at any time since atomic_check doesn't hold
+	 * &drm_mode_config.mutex
+	 */
+	if (aconnector && preferred_mode && !amdgpu_dm_mode_copies_match(aconnector, sink)) {
+		drm_dbg_driver(dev, "Preferred mode copy is from another sink\n");
+		preferred_mode = NULL;
+	}
+
 	if (aconnector && preferred_mode) {
-		recalculate_timing = amdgpu_freesync_vid_mode &&
-				 amdgpu_dm_is_freesync_video_mode(&mode, aconnector, sink);
-		if (recalculate_timing) {
+		if (amdgpu_freesync_vid_mode &&
+		    amdgpu_dm_is_freesync_video_mode(&mode, aconnector, sink))
 			freesync_mode = amdgpu_dm_get_highest_refresh_rate_mode(aconnector,
 										false, sink);
+		if (freesync_mode) {
+			recalculate_timing = true;
 			drm_mode_copy(&saved_mode, &mode);
 			saved_mode.picture_aspect_ratio = mode.picture_aspect_ratio;
 			drm_mode_copy(&mode, freesync_mode);
@@ -2676,27 +2718,25 @@ __amdgpu_dm_create_validate_stream_for_sink(struct drm_connector *connector,
 	return NULL;
 }
 
+/*
+ * atomic_check builds streams with the preferred mode copied at the end of
+ * the last probe. amdgpu_dm_connector_fill_modes() writes it with
+ * connection_mutex held, which atomic_check holds for every connector in the
+ * commit. create_stream_for_sink() uses it only for the sink it was taken
+ * from
+ */
 STATIC_IFN_KUNIT const struct drm_display_mode *
-amdgpu_dm_connector_preferred_mode(struct drm_connector *connector,
-				   struct drm_display_mode *native_buf)
+amdgpu_dm_connector_preferred_mode(struct drm_connector *connector)
 {
-	const struct drm_display_mode *mode;
+	struct amdgpu_dm_connector *aconnector;
 
 	if (connector->connector_type == DRM_MODE_CONNECTOR_WRITEBACK)
 		return NULL;
 
-	list_for_each_entry(mode, &connector->modes, head) {
-		if (mode->type & DRM_MODE_TYPE_PREFERRED)
-			return mode;
-	}
-
-	mode = amdgpu_dm_panel_native_mode(connector, &connector->modes, native_buf);
-	if (mode)
-		return mode;
+	drm_modeset_lock_assert_held(&connector->dev->mode_config.connection_mutex);
 
-	mode = list_first_entry_or_null(&connector->modes,
-					struct drm_display_mode, head);
-	if (!mode) {
+	aconnector = to_amdgpu_dm_connector(connector);
+	if (!aconnector->preferred_mode.clock) {
 		/*
 		 * This may not be an error, the use case is when we have no
 		 * usermode calls to reset and set mode upon hotplug. In this
@@ -2704,9 +2744,10 @@ amdgpu_dm_connector_preferred_mode(struct drm_connector *connector,
 		 * and the modelist may not be filled in time
 		 */
 		drm_dbg_driver(connector->dev, "No preferred mode found\n");
+		return NULL;
 	}
 
-	return mode;
+	return &aconnector->preferred_mode;
 }
 EXPORT_IF_KUNIT(amdgpu_dm_connector_preferred_mode);
 
@@ -2717,17 +2758,17 @@ amdgpu_dm_create_validate_stream_for_sink(struct drm_connector *connector,
 					  const struct dc_stream_state *old_stream)
 {
 	const struct drm_display_mode *preferred_mode;
-	struct drm_display_mode native_buf;
 
 	/*
 	 * __amdgpu_dm_create_validate_stream_for_sink() checks this as well,
-	 * but without a state there is no commit, so skip the preferred mode
-	 * lookup too
+	 * but without a state there is no commit, and the caller may not hold
+	 * connection_mutex, which the preferred mode lookup asserts, so skip
+	 * the lookup too
 	 */
 	if (!dm_state)
 		return NULL;
 
-	preferred_mode = amdgpu_dm_connector_preferred_mode(connector, &native_buf);
+	preferred_mode = amdgpu_dm_connector_preferred_mode(connector);
 	return __amdgpu_dm_create_validate_stream_for_sink(connector, drm_mode,
 							   preferred_mode, dm_state,
 							   old_stream);
@@ -2775,12 +2816,12 @@ enum drm_mode_status amdgpu_dm_connector_mode_valid(struct drm_connector *connec
 	drm_mode_set_crtcinfo(test_mode, 0);
 
 	/*
-	 * During a probe connector->modes still holds the previous probe's
-	 * modes, possibly of another sink, and the probe knows its preferred
-	 * mode only once mode_valid has seen every mode. Validate each mode
-	 * with its own timing, even where atomic_check drives another one, the
-	 * preferred mode's with scaling on or the native one for eDP and LVDS
-	 * common modes
+	 * The preferred mode copy is from the previous probe, possibly of
+	 * another sink, and the probe knows its preferred mode only once
+	 * mode_valid has seen every mode. Validate each mode with its own
+	 * timing, even where atomic_check drives another one, the preferred
+	 * mode's with scaling on or the native one for eDP and LVDS common
+	 * modes
 	 */
 	stream = __amdgpu_dm_create_validate_stream_for_sink(connector, test_mode,
 							     NULL, dm_state, NULL);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h
index 7f475403ad220..ebaef4a6c4bc0 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h
@@ -137,7 +137,7 @@ amdgpu_dm_get_output_color_space(const struct dc_crtc_timing *dc_crtc_timing,
 
 struct drm_display_mode *
 amdgpu_dm_get_highest_refresh_rate_mode(struct amdgpu_dm_connector *aconnector,
-			      bool use_probed_modes, const struct dc_sink *sink);
+			      bool in_probe, const struct dc_sink *sink);
 
 struct amdgpu_i2c_adapter *
 amdgpu_dm_create_i2c(struct ddc_service *ddc_service, bool oem);
@@ -209,8 +209,7 @@ create_stream_for_sink(struct drm_connector *connector,
 		       enum dc_pixel_encoding requested_encoding,
 		       bool is_hdmi_ep);
 const struct drm_display_mode *
-amdgpu_dm_connector_preferred_mode(struct drm_connector *connector,
-				   struct drm_display_mode *native_buf);
+amdgpu_dm_connector_preferred_mode(struct drm_connector *connector);
 enum drm_connector_status
 amdgpu_dm_connector_poll(struct amdgpu_dm_connector *aconnector, bool force);
 enum drm_connector_status
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
index 832fce79f8acd..71ad7e4ea5c9e 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
@@ -2393,6 +2393,75 @@ static void dm_test_get_property_unknown(struct kunit *test)
 				other, &val), -EINVAL);
 }
 
+/*
+ * A sink with an EDID, recorded as the sink the mode copies came from, as
+ * amdgpu_dm_connector_update_mode_copies() records it
+ */
+static struct dc_sink *dm_test_copies_sink(struct kunit *test,
+					   struct amdgpu_dm_connector *aconnector)
+{
+	struct dc_sink *sink = kunit_kzalloc(test, sizeof(*sink), GFP_KERNEL);
+
+	KUNIT_ASSERT_NOT_NULL(test, sink);
+	memset(sink->dc_edid.raw_edid, 0x5a, 128);
+	sink->dc_edid.length = 128;
+	aconnector->mode_copies_edid_size = 128;
+	memcpy(aconnector->mode_copies_edid, sink->dc_edid.raw_edid, 128);
+
+	return sink;
+}
+
+static struct drm_device *dm_test_alloc_drm(struct kunit *test);
+
+/*
+ * Look up the highest refresh rate mode with the lock its callers hold,
+ * &drm_mode_config.mutex in a probe and connection_mutex in atomic_check. A
+ * connector without a device gets one for the locks
+ */
+static struct drm_display_mode *
+dm_test_highest_locked(struct kunit *test, struct amdgpu_dm_connector *aconnector,
+		       bool in_probe, const struct dc_sink *sink)
+{
+	struct drm_mode_config *config;
+	struct drm_display_mode *mode;
+
+	if (!aconnector->base.dev)
+		aconnector->base.dev = dm_test_alloc_drm(test);
+	config = &aconnector->base.dev->mode_config;
+
+	if (in_probe) {
+		mutex_lock(&config->mutex);
+		mode = amdgpu_dm_get_highest_refresh_rate_mode(aconnector, true, sink);
+		mutex_unlock(&config->mutex);
+	} else {
+		drm_modeset_lock(&config->connection_mutex, NULL);
+		mode = amdgpu_dm_get_highest_refresh_rate_mode(aconnector, false, sink);
+		drm_modeset_unlock(&config->connection_mutex);
+	}
+
+	return mode;
+}
+
+/* Ask as atomic_check does, with connection_mutex held */
+static bool dm_test_is_fs_video_locked(struct kunit *test,
+				       const struct drm_display_mode *mode,
+				       struct amdgpu_dm_connector *aconnector,
+				       const struct dc_sink *sink)
+{
+	struct drm_modeset_lock *lock;
+	bool ret;
+
+	if (!aconnector->base.dev)
+		aconnector->base.dev = dm_test_alloc_drm(test);
+	lock = &aconnector->base.dev->mode_config.connection_mutex;
+
+	drm_modeset_lock(lock, NULL);
+	ret = amdgpu_dm_is_freesync_video_mode(mode, aconnector, sink);
+	drm_modeset_unlock(lock);
+
+	return ret;
+}
+
 /* Tests for amdgpu_dm_get_highest_refresh_rate_mode() */
 
 /**
@@ -2417,6 +2486,7 @@ static void dm_test_highest_refresh_writeback_null(struct kunit *test)
 static void dm_test_highest_refresh_cached_base(struct kunit *test)
 {
 	struct amdgpu_dm_connector *aconnector;
+	struct dc_sink *sink;
 
 	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, aconnector);
@@ -2424,13 +2494,18 @@ static void dm_test_highest_refresh_cached_base(struct kunit *test)
 	aconnector->base.connector_type = DRM_MODE_CONNECTOR_HDMIA;
 	aconnector->freesync_vid_base.clock = 148500;
 
-	KUNIT_EXPECT_PTR_EQ(test, amdgpu_dm_get_highest_refresh_rate_mode(aconnector, false, NULL),
+	sink = dm_test_copies_sink(test, aconnector);
+
+	KUNIT_EXPECT_PTR_EQ(test, dm_test_highest_locked(test, aconnector, false, sink),
 			    &aconnector->freesync_vid_base);
 }
 
 /**
  * dm_test_highest_refresh_preferred_mode - Test preferred mode is selected
  * @test: The KUnit test context
+ *
+ * With no copy taken yet, the probe path picks the preferred mode from
+ * probed_modes and leaves the copy alone
  */
 static void dm_test_highest_refresh_preferred_mode(struct kunit *test)
 {
@@ -2444,6 +2519,7 @@ static void dm_test_highest_refresh_preferred_mode(struct kunit *test)
 
 	aconnector->base.connector_type = DRM_MODE_CONNECTOR_HDMIA;
 	INIT_LIST_HEAD(&aconnector->base.modes);
+	INIT_LIST_HEAD(&aconnector->base.probed_modes);
 
 	mode->type = DRM_MODE_TYPE_PREFERRED;
 	mode->clock = 148500;
@@ -2451,10 +2527,11 @@ static void dm_test_highest_refresh_preferred_mode(struct kunit *test)
 	mode->vdisplay = 1080;
 	mode->htotal = 2200;
 	mode->vtotal = 1125;
-	list_add_tail(&mode->head, &aconnector->base.modes);
+	list_add_tail(&mode->head, &aconnector->base.probed_modes);
 
-	KUNIT_EXPECT_PTR_EQ(test, amdgpu_dm_get_highest_refresh_rate_mode(aconnector, false, NULL),
+	KUNIT_EXPECT_PTR_EQ(test, dm_test_highest_locked(test, aconnector, true, NULL),
 			    mode);
+	KUNIT_EXPECT_EQ(test, aconnector->freesync_vid_base.clock, 0);
 }
 
 /* Tests for amdgpu_dm_connector_update_mode_copies() */
@@ -2480,8 +2557,6 @@ dm_test_copy_add_mode(struct kunit *test, struct list_head *modes,
 	return mode;
 }
 
-static struct drm_device *dm_test_alloc_drm(struct kunit *test);
-
 /*
  * Take the copies as amdgpu_dm_connector_fill_modes() does, with
  * &drm_mode_config.mutex held. A connector without a device gets one for the
@@ -2505,7 +2580,7 @@ static void dm_test_copy_locked(struct kunit *test, struct amdgpu_dm_connector *
  * @test: The KUnit test context
  *
  * The copy is from the previous probe, possibly of another monitor, so a
- * caller that passes use_probed_modes must get this probe's mode
+ * caller that passes in_probe must get this probe's mode
  */
 static void dm_test_highest_refresh_probed_skips_copy(struct kunit *test)
 {
@@ -2525,7 +2600,7 @@ static void dm_test_highest_refresh_probed_skips_copy(struct kunit *test)
 				     2720, 1481, 241500, DRM_MODE_TYPE_PREFERRED);
 
 	KUNIT_EXPECT_PTR_EQ(test,
-			    amdgpu_dm_get_highest_refresh_rate_mode(aconnector, true, NULL),
+			    dm_test_highest_locked(test, aconnector, true, NULL),
 			    mode);
 }
 
@@ -2843,6 +2918,7 @@ static void dm_test_fill_modes_copies_probe(struct kunit *test)
 static void dm_test_is_freesync_video_mode_null_mode(struct kunit *test)
 {
 	struct amdgpu_dm_connector *aconnector;
+	struct dc_sink *sink;
 
 	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, aconnector);
@@ -2850,7 +2926,8 @@ static void dm_test_is_freesync_video_mode_null_mode(struct kunit *test)
 	aconnector->base.connector_type = DRM_MODE_CONNECTOR_HDMIA;
 	aconnector->freesync_vid_base.clock = 148500;
 
-	KUNIT_EXPECT_FALSE(test, amdgpu_dm_is_freesync_video_mode(NULL, aconnector, NULL));
+	sink = dm_test_copies_sink(test, aconnector);
+	KUNIT_EXPECT_FALSE(test, dm_test_is_fs_video_locked(test, NULL, aconnector, sink));
 }
 
 /**
@@ -2860,6 +2937,7 @@ static void dm_test_is_freesync_video_mode_null_mode(struct kunit *test)
 static void dm_test_is_freesync_video_mode_match(struct kunit *test)
 {
 	struct amdgpu_dm_connector *aconnector;
+	struct dc_sink *sink;
 	struct drm_display_mode candidate = {};
 
 	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
@@ -2887,7 +2965,8 @@ static void dm_test_is_freesync_video_mode_match(struct kunit *test)
 	candidate.vsync_end = 1089;
 	candidate.vtotal = 1125;
 
-	KUNIT_EXPECT_TRUE(test, amdgpu_dm_is_freesync_video_mode(&candidate, aconnector, NULL));
+	sink = dm_test_copies_sink(test, aconnector);
+	KUNIT_EXPECT_TRUE(test, dm_test_is_fs_video_locked(test, &candidate, aconnector, sink));
 }
 
 /**
@@ -2897,6 +2976,7 @@ static void dm_test_is_freesync_video_mode_match(struct kunit *test)
 static void dm_test_is_freesync_video_mode_no_match(struct kunit *test)
 {
 	struct amdgpu_dm_connector *aconnector;
+	struct dc_sink *sink;
 	struct drm_display_mode candidate = {};
 
 	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
@@ -2916,7 +2996,8 @@ static void dm_test_is_freesync_video_mode_no_match(struct kunit *test)
 	candidate.htotal = 1650;
 	candidate.vtotal = 750;
 
-	KUNIT_EXPECT_FALSE(test, amdgpu_dm_is_freesync_video_mode(&candidate, aconnector, NULL));
+	sink = dm_test_copies_sink(test, aconnector);
+	KUNIT_EXPECT_FALSE(test, dm_test_is_fs_video_locked(test, &candidate, aconnector, sink));
 }
 
 /* Tests for amdgpu_dm_update_cacp_caps() */
@@ -4167,6 +4248,27 @@ static struct dm_test_fill_ctx *dm_test_fill_ctx_alloc(struct kunit *test)
 	return ctx;
 }
 
+/* atomic_check fills the stream with connection_mutex held */
+static void dm_test_fill_stream_locked(struct dc_stream_state *stream,
+				       const struct drm_display_mode *mode_in,
+				       const struct drm_connector *connector,
+				       const struct dc_sink *sink,
+				       const struct drm_connector_state *connector_state,
+				       const struct dc_stream_state *old_stream,
+				       int requested_bpc,
+				       enum dc_pixel_encoding requested_encoding,
+				       bool is_hdmi_ep)
+{
+	struct drm_modeset_lock *lock = &connector->dev->mode_config.connection_mutex;
+
+	drm_modeset_lock(lock, NULL);
+	fill_stream_properties_from_drm_display_mode(stream, mode_in, connector, sink,
+						     connector_state, old_stream,
+						     requested_bpc, requested_encoding,
+						     is_hdmi_ep);
+	drm_modeset_unlock(lock);
+}
+
 /**
  * dm_test_fill_stream_borders_zeroed - Test the timing borders are cleared
  * @test: The KUnit test context
@@ -4182,9 +4284,9 @@ static void dm_test_fill_stream_borders_zeroed(struct kunit *test)
 	timing->v_border_top = 7;
 	timing->v_border_bottom = 8;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
+				   PIXEL_ENCODING_RGB, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->h_border_left, 0);
 	KUNIT_EXPECT_EQ(test, (int)timing->h_border_right, 0);
@@ -4204,9 +4306,9 @@ static void dm_test_fill_stream_rgb_defaults(struct kunit *test)
 	struct dm_test_fill_ctx *ctx = dm_test_fill_ctx_alloc(test);
 	struct dc_crtc_timing *timing = &ctx->stream->timing;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
+				   PIXEL_ENCODING_RGB, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->pixel_encoding, (int)PIXEL_ENCODING_RGB);
 	KUNIT_EXPECT_EQ(test, (int)timing->timing_3d_format,
@@ -4231,9 +4333,9 @@ static void dm_test_fill_stream_sync_polarity_positive(struct kunit *test)
 
 	ctx->mode->flags = DRM_MODE_FLAG_PHSYNC | DRM_MODE_FLAG_PVSYNC;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
+				   PIXEL_ENCODING_RGB, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->flags.HSYNC_POSITIVE_POLARITY, 1);
 	KUNIT_EXPECT_EQ(test, (int)timing->flags.VSYNC_POSITIVE_POLARITY, 1);
@@ -4251,9 +4353,9 @@ static void dm_test_fill_stream_sync_polarity_negative(struct kunit *test)
 	/* No sync flags set on the mode → polarity stays negative (0). */
 	ctx->mode->flags = 0;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
+				   PIXEL_ENCODING_RGB, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->flags.HSYNC_POSITIVE_POLARITY, 0);
 	KUNIT_EXPECT_EQ(test, (int)timing->flags.VSYNC_POSITIVE_POLARITY, 0);
@@ -4281,9 +4383,9 @@ static void dm_test_fill_stream_inherits_old_stream(struct kunit *test)
 	/* Mode flags would force positive polarity if the old stream were ignored. */
 	ctx->mode->flags = DRM_MODE_FLAG_PHSYNC | DRM_MODE_FLAG_PVSYNC;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, old_stream, 8,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, old_stream, 8,
+				   PIXEL_ENCODING_RGB, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->vic, 16);
 	KUNIT_EXPECT_EQ(test, (int)timing->flags.HSYNC_POSITIVE_POLARITY, 1);
@@ -4312,9 +4414,9 @@ static void dm_test_fill_stream_timing_from_crtc(struct kunit *test)
 	ctx->mode->crtc_vsync_end = 1089;
 	ctx->mode->crtc_clock = 148500;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
+				   PIXEL_ENCODING_RGB, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->h_addressable, 1920);
 	KUNIT_EXPECT_EQ(test, (int)timing->h_total, 2200);
@@ -4340,9 +4442,9 @@ static void dm_test_fill_stream_color_depth_requested_bpc(struct kunit *test)
 
 	ctx->aconnector->base.display_info.bpc = 12;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 10,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 10,
+				   PIXEL_ENCODING_RGB, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->display_color_depth,
 			(int)COLOR_DEPTH_101010);
@@ -4358,9 +4460,9 @@ static void dm_test_fill_stream_content_type(struct kunit *test)
 
 	ctx->conn_state->content_type = DRM_MODE_CONTENT_TYPE_GRAPHICS;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
+				   PIXEL_ENCODING_RGB, false);
 
 	KUNIT_EXPECT_EQ(test, (int)ctx->stream->content_type,
 			(int)DISPLAY_CONTENT_TYPE_GRAPHICS);
@@ -4377,9 +4479,9 @@ static void dm_test_fill_stream_aspect_ratio(struct kunit *test)
 
 	ctx->mode->picture_aspect_ratio = HDMI_PICTURE_ASPECT_16_9;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
+				   PIXEL_ENCODING_RGB, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->aspect_ratio,
 			(int)ASPECT_RATIO_16_9);
@@ -4398,9 +4500,9 @@ static void dm_test_fill_stream_encoding_from_caller_ycbcr420(struct kunit *test
 	struct dm_test_fill_ctx *ctx = dm_test_fill_ctx_alloc(test);
 	struct dc_crtc_timing *timing = &ctx->stream->timing;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
-		PIXEL_ENCODING_YCBCR420, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
+				   PIXEL_ENCODING_YCBCR420, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->pixel_encoding,
 			(int)PIXEL_ENCODING_YCBCR420);
@@ -4417,9 +4519,9 @@ static void dm_test_fill_stream_encoding_from_caller_ycbcr422(struct kunit *test
 	struct dm_test_fill_ctx *ctx = dm_test_fill_ctx_alloc(test);
 	struct dc_crtc_timing *timing = &ctx->stream->timing;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
-		PIXEL_ENCODING_YCBCR422, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
+				   PIXEL_ENCODING_YCBCR422, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->pixel_encoding,
 			(int)PIXEL_ENCODING_YCBCR422);
@@ -4436,9 +4538,9 @@ static void dm_test_fill_stream_encoding_from_caller_ycbcr444(struct kunit *test
 	struct dm_test_fill_ctx *ctx = dm_test_fill_ctx_alloc(test);
 	struct dc_crtc_timing *timing = &ctx->stream->timing;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
-		PIXEL_ENCODING_YCBCR444, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
+				   PIXEL_ENCODING_YCBCR444, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->pixel_encoding,
 			(int)PIXEL_ENCODING_YCBCR444);
@@ -4461,9 +4563,9 @@ static void dm_test_fill_stream_hdmi_ep_clamps_depth(struct kunit *test)
 	ctx->aconnector->base.display_info.max_tmds_clock = 160000;
 	ctx->mode->crtc_clock = 148500;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 10,
-		PIXEL_ENCODING_RGB, true);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 10,
+				   PIXEL_ENCODING_RGB, true);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->display_color_depth,
 			(int)COLOR_DEPTH_888);
@@ -4485,9 +4587,9 @@ static void dm_test_fill_stream_non_hdmi_ep_keeps_depth(struct kunit *test)
 	ctx->aconnector->base.display_info.max_tmds_clock = 160000;
 	ctx->mode->crtc_clock = 148500;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 10,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, NULL, 10,
+				   PIXEL_ENCODING_RGB, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->display_color_depth,
 			(int)COLOR_DEPTH_101010);
@@ -4519,9 +4621,9 @@ static void dm_test_fill_stream_hdmi_infoframe(struct kunit *test)
 
 	ctx->stream->signal = SIGNAL_TYPE_HDMI_TYPE_A;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, old_stream, 8,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, NULL, ctx->conn_state, old_stream, 8,
+				   PIXEL_ENCODING_RGB, false);
 
 	/* The HDMI block overwrote the old stream's VIC of 99 with the AVI code. */
 	KUNIT_EXPECT_EQ(test, (int)timing->vic, 16);
@@ -4531,13 +4633,15 @@ static void dm_test_fill_stream_hdmi_infoframe(struct kunit *test)
  * dm_test_fill_stream_freesync_video - Test timing taken from the mode for FS video
  * @test: The KUnit test context
  *
- * When the mode matches the connector's cached freesync base mode the timing is
- * taken from the drm mode fields (not crtc_*), including a 10x pixel clock.
+ * When the mode matches the connector's cached freesync base mode, taken from
+ * a probe of the sink passed in, the timing is taken from the drm mode fields
+ * (not crtc_*), including a 10x pixel clock.
  */
 static void dm_test_fill_stream_freesync_video(struct kunit *test)
 {
 	struct dm_test_fill_ctx *ctx = dm_test_fill_ctx_alloc(test);
 	struct dc_crtc_timing *timing = &ctx->stream->timing;
+	struct dc_sink *sink = dm_test_copies_sink(test, ctx->aconnector);
 
 	/* Cached high mode == the mode passed in => freesync video mode. */
 	ctx->aconnector->freesync_vid_base.clock = 148500;
@@ -4560,9 +4664,9 @@ static void dm_test_fill_stream_freesync_video(struct kunit *test)
 	ctx->mode->vsync_end = 1089;
 	ctx->mode->vtotal = 1125;
 
-	fill_stream_properties_from_drm_display_mode(ctx->stream, ctx->mode,
-		&ctx->aconnector->base, NULL, ctx->conn_state, NULL, 8,
-		PIXEL_ENCODING_RGB, false);
+	dm_test_fill_stream_locked(ctx->stream, ctx->mode,
+				   &ctx->aconnector->base, sink, ctx->conn_state, NULL, 8,
+				   PIXEL_ENCODING_RGB, false);
 
 	KUNIT_EXPECT_EQ(test, (int)timing->h_addressable, 1920);
 	KUNIT_EXPECT_EQ(test, (int)timing->v_addressable, 1080);
@@ -4644,6 +4748,29 @@ static struct dm_test_stream_ctx *dm_test_stream_ctx_alloc(struct kunit *test)
 	return dm_test_stream_ctx_alloc_type(test, DRM_MODE_CONNECTOR_DisplayPort);
 }
 
+/* atomic_check builds streams with connection_mutex held */
+static struct dc_stream_state *
+dm_test_create_stream_locked(struct drm_connector *connector,
+			     const struct drm_display_mode *drm_mode,
+			     const struct drm_display_mode *preferred_mode,
+			     const struct dm_connector_state *dm_state,
+			     const struct dc_stream_state *old_stream,
+			     int requested_bpc,
+			     enum dc_pixel_encoding requested_encoding,
+			     bool is_hdmi_ep)
+{
+	struct drm_modeset_lock *lock = &connector->dev->mode_config.connection_mutex;
+	struct dc_stream_state *stream;
+
+	drm_modeset_lock(lock, NULL);
+	stream = create_stream_for_sink(connector, drm_mode, preferred_mode, dm_state,
+					old_stream, requested_bpc, requested_encoding,
+					is_hdmi_ep);
+	drm_modeset_unlock(lock);
+
+	return stream;
+}
+
 /**
  * dm_test_create_stream_fake_sink_success - Test a stream is built from a fake sink
  * @test: The KUnit test context
@@ -4653,9 +4780,9 @@ static void dm_test_create_stream_fake_sink_success(struct kunit *test)
 	struct dm_test_stream_ctx *ctx = dm_test_stream_ctx_alloc(test);
 	struct dc_stream_state *stream;
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					NULL, ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      NULL, ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 	dc_stream_release(stream);
@@ -4670,9 +4797,9 @@ static void dm_test_create_stream_sets_dm_context(struct kunit *test)
 	struct dm_test_stream_ctx *ctx = dm_test_stream_ctx_alloc(test);
 	struct dc_stream_state *stream;
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					NULL, ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      NULL, ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 	KUNIT_EXPECT_PTR_EQ(test, stream->dm_stream_context, ctx->aconnector);
@@ -4688,9 +4815,9 @@ static void dm_test_create_stream_virtual_signal(struct kunit *test)
 	struct dm_test_stream_ctx *ctx = dm_test_stream_ctx_alloc(test);
 	struct dc_stream_state *stream;
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					NULL, ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      NULL, ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 	KUNIT_EXPECT_EQ(test, (int)stream->signal, (int)SIGNAL_TYPE_VIRTUAL);
@@ -4708,9 +4835,9 @@ static void dm_test_create_stream_scaling_src(struct kunit *test)
 	struct dm_test_stream_ctx *ctx = dm_test_stream_ctx_alloc(test);
 	struct dc_stream_state *stream;
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					NULL, ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      NULL, ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 	KUNIT_EXPECT_EQ(test, (int)stream->src.width, 1920);
@@ -4740,9 +4867,9 @@ static void dm_test_create_stream_existing_sink(struct kunit *test)
 
 	ctx->aconnector->dc_sink = sink;
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					NULL, ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      NULL, ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 	KUNIT_EXPECT_PTR_EQ(test, stream->sink, sink);
@@ -4751,7 +4878,43 @@ static void dm_test_create_stream_existing_sink(struct kunit *test)
 	dc_sink_release(sink);
 }
 
-/* Append a copy of the context mode to the connector's mode list. */
+static void dm_test_release_sink(void *sink)
+{
+	dc_sink_release(sink);
+}
+
+/*
+ * Attach a sink with an EDID on @link to @aconnector, as a detect would, and
+ * record it as the sink the mode copies came from. The sink is released when
+ * the test ends
+ */
+static struct dc_sink *dm_test_attach_copies_sink(struct kunit *test,
+						  struct amdgpu_dm_connector *aconnector,
+						  struct dc_link *link)
+{
+	struct dc_sink_init_data init = {
+		.link = link,
+		.sink_signal = link->connector_signal,
+	};
+	struct dc_sink *sink = dc_sink_create(&init);
+
+	KUNIT_ASSERT_NOT_NULL(test, sink);
+	KUNIT_ASSERT_EQ(test, kunit_add_action_or_reset(test, dm_test_release_sink, sink), 0);
+	sink->sink_signal = SIGNAL_TYPE_VIRTUAL;
+	memset(sink->dc_edid.raw_edid, 0x5a, 128);
+	sink->dc_edid.length = 128;
+
+	aconnector->dc_sink = sink;
+	aconnector->mode_copies_edid_size = 128;
+	memcpy(aconnector->mode_copies_edid, sink->dc_edid.raw_edid, 128);
+
+	return sink;
+}
+
+/*
+ * Append a copy of the context mode to the connector's mode list and take the
+ * copies that amdgpu_dm_connector_fill_modes() takes after a probe
+ */
 static void dm_test_stream_add_mode(struct kunit *test, struct dm_test_stream_ctx *ctx,
 				    u32 type)
 {
@@ -4761,6 +4924,9 @@ static void dm_test_stream_add_mode(struct kunit *test, struct dm_test_stream_ct
 	drm_mode_copy(mode, ctx->mode);
 	mode->type = type;
 	list_add_tail(&mode->head, &ctx->aconnector->base.modes);
+	if (!ctx->aconnector->dc_sink)
+		dm_test_attach_copies_sink(test, ctx->aconnector, ctx->link);
+	dm_test_copy_locked(test, ctx->aconnector);
 }
 
 /* Give the context mode a full set of CRTC timings. */
@@ -4807,11 +4973,10 @@ static void dm_test_create_stream_preferred_mode(struct kunit *test)
 	dm_test_stream_set_timings(ctx);
 	dm_test_stream_add_mode(test, ctx, DRM_MODE_TYPE_PREFERRED);
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					list_first_entry(&ctx->aconnector->base.modes,
-							 struct drm_display_mode, head),
-					ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      &ctx->aconnector->preferred_mode,
+					      ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 	KUNIT_EXPECT_EQ(test, (int)stream->timing.h_addressable, 1920);
@@ -4837,11 +5002,10 @@ static void dm_test_create_stream_scaled_keeps_refresh(struct kunit *test)
 	dm_test_stream_add_mode(test, ctx, DRM_MODE_TYPE_PREFERRED);
 	ctx->dm_state->scaling = RMX_FULL;
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					list_first_entry(&ctx->aconnector->base.modes,
-							 struct drm_display_mode, head),
-					ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      &ctx->aconnector->preferred_mode,
+					      ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 	KUNIT_EXPECT_EQ(test, (int)stream->timing.h_addressable, 1920);
@@ -4870,9 +5034,9 @@ static void dm_test_create_stream_timing_override(struct kunit *test)
 	ctx->aconnector->timing_changed = true;
 	ctx->aconnector->timing_requested = timing;
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					NULL, ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      NULL, ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 	KUNIT_EXPECT_EQ(test, (int)stream->timing.h_addressable, 1280);
@@ -4899,9 +5063,9 @@ static void dm_test_create_stream_dp_vsc_colorimetry(struct kunit *test)
 	ctx->link->dpcd_caps.dpcd_rev.raw = 0x14;
 	ctx->link->dpcd_caps.dprx_feature.bits.VSC_SDP_COLORIMETRY_SUPPORTED = 1;
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					NULL, ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      NULL, ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 	KUNIT_EXPECT_EQ(test, (int)stream->signal, (int)SIGNAL_TYPE_DISPLAY_PORT);
@@ -4927,9 +5091,9 @@ static void dm_test_create_stream_dp_colorimetry_quirk(struct kunit *test)
 	ctx->link->dpcd_caps.dpcd_rev.raw = 0x14;
 	ctx->link->dpcd_caps.dprx_feature.bits.VSC_SDP_COLORIMETRY_SUPPORTED = 1;
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					NULL, ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      NULL, ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 	KUNIT_EXPECT_FALSE(test, stream->use_vsc_sdp_for_colorimetry);
@@ -4954,9 +5118,9 @@ static void dm_test_create_stream_hdmi_vsif(struct kunit *test)
 	ctx->link->connector_signal = SIGNAL_TYPE_HDMI_TYPE_A;
 	sink = dm_test_stream_add_sink(test, ctx, SIGNAL_TYPE_HDMI_TYPE_A);
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					NULL, ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      NULL, ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 	KUNIT_EXPECT_EQ(test, (int)stream->signal, (int)SIGNAL_TYPE_HDMI_TYPE_A);
@@ -4990,8 +5154,8 @@ dm_test_native_mode_stream(struct kunit *test, int connector_type, unsigned int
 	static const u8 edid[EDID_LENGTH];
 	struct dm_test_stream_ctx *ctx = dm_test_stream_ctx_alloc_type(test, connector_type);
 	struct amdgpu_encoder *aenc;
-	struct drm_display_mode *native, native_buf;
 	struct dc_stream_state *stream;
+	struct drm_display_mode *native;
 
 	aenc = drmm_kzalloc(ctx->drm, sizeof(*aenc), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, aenc);
@@ -5009,8 +5173,6 @@ dm_test_native_mode_stream(struct kunit *test, int connector_type, unsigned int
 	native->vsync_start = 2403;
 	native->vsync_end = 2409;
 	native->vtotal = 2469;
-	/* Cached by the first, unlimited probe */
-	drm_mode_copy(&ctx->aconnector->freesync_vid_base, native);
 
 	drm_mode_copy(ctx->mode, native);
 	ctx->mode->hdisplay = 1920;
@@ -5038,12 +5200,12 @@ dm_test_native_mode_stream(struct kunit *test, int connector_type, unsigned int
 		ctx->aconnector->drm_edid = drm_edid_alloc(edid, sizeof(edid));
 		KUNIT_ASSERT_NOT_NULL(test, ctx->aconnector->drm_edid);
 	}
+	dm_test_copy_locked(test, ctx->aconnector);
 
-	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					amdgpu_dm_connector_preferred_mode(&ctx->aconnector->base,
-									   &native_buf),
-					ctx->dm_state, NULL, 8,
-					PIXEL_ENCODING_RGB, false);
+	stream = dm_test_create_stream_locked(&ctx->aconnector->base, ctx->mode,
+					      &ctx->aconnector->preferred_mode,
+					      ctx->dm_state, NULL, 8,
+					      PIXEL_ENCODING_RGB, false);
 
 	drm_edid_free(ctx->aconnector->drm_edid);
 	ctx->aconnector->drm_edid = NULL;
@@ -6784,7 +6946,8 @@ static void dm_test_add_fs_modes_no_preferred_mode(struct kunit *test)
 
 /*
  * Build a DisplayPort connector whose highest-refresh mode is a fixed
- * 1920x1080@60 timing. A non-zero freesync_vid_base.clock makes
+ * 1920x1080@60 timing. While probed_modes is empty, a non-zero
+ * freesync_vid_base.clock taken from the connector's dc_sink makes
  * amdgpu_dm_get_highest_refresh_rate_mode() return that timing directly,
  * giving the test full control of the reference mode.
  */
@@ -6802,6 +6965,7 @@ static struct amdgpu_dm_connector *dm_test_fs_setup(struct kunit *test)
 	m->vsync_start = 1084;
 	m->vsync_end = 1089;
 	m->vtotal = 1125;
+	aconnector->dc_sink = dm_test_copies_sink(test, aconnector);
 
 	return aconnector;
 }
@@ -6845,11 +7009,16 @@ static void dm_test_add_fs_modes_generates(struct kunit *test)
 static void dm_test_add_fs_modes_out_of_range(struct kunit *test)
 {
 	struct amdgpu_dm_connector *aconnector = dm_test_fs_setup(test);
+	unsigned int count;
 
 	aconnector->min_vfreq = 100;
 	aconnector->max_vfreq = 120;
 
-	KUNIT_EXPECT_EQ(test, (int)add_fs_modes(aconnector), 0);
+	mutex_lock(&aconnector->base.dev->mode_config.mutex);
+	count = add_fs_modes(aconnector);
+	mutex_unlock(&aconnector->base.dev->mode_config.mutex);
+
+	KUNIT_EXPECT_EQ(test, count, 0);
 	KUNIT_EXPECT_EQ(test, aconnector->probed_freesync_vid_base.clock, 0);
 }
 
@@ -6865,12 +7034,17 @@ static void dm_test_add_fs_modes_out_of_range(struct kunit *test)
 static void dm_test_add_fs_modes_skips_illegal(struct kunit *test)
 {
 	struct amdgpu_dm_connector *aconnector = dm_test_fs_setup(test);
+	unsigned int count;
 
 	aconnector->freesync_vid_base.vtotal = 1133;
 	aconnector->min_vfreq = 59;
 	aconnector->max_vfreq = 60;
 
-	KUNIT_EXPECT_EQ(test, (int)add_fs_modes(aconnector), 0);
+	mutex_lock(&aconnector->base.dev->mode_config.mutex);
+	count = add_fs_modes(aconnector);
+	mutex_unlock(&aconnector->base.dev->mode_config.mutex);
+
+	KUNIT_EXPECT_EQ(test, count, 0);
 }
 
 /**
@@ -7535,6 +7709,24 @@ static void dm_test_create_validate_stream_null_dm_state(struct kunit *test)
 
 /* Tests for amdgpu_dm_create_validate_stream_for_sink() */
 
+/* atomic_check holds connection_mutex for every connector it validates */
+static struct dc_stream_state *
+dm_test_validate_locked(struct drm_connector *connector,
+			const struct drm_display_mode *drm_mode,
+			const struct dm_connector_state *dm_state,
+			const struct dc_stream_state *old_stream)
+{
+	struct drm_modeset_lock *lock = &connector->dev->mode_config.connection_mutex;
+	struct dc_stream_state *stream;
+
+	drm_modeset_lock(lock, NULL);
+	stream = amdgpu_dm_create_validate_stream_for_sink(connector, drm_mode,
+							   dm_state, old_stream);
+	drm_modeset_unlock(lock);
+
+	return stream;
+}
+
 /*
  * Build a connector embedded in an amdgpu_device (so drm_to_adev() resolves)
  * carrying a dc_link but a deliberately low atomic-requested bpc. Every
@@ -7670,16 +7862,16 @@ static void dm_test_create_validate_stream_no_valid_bpc(struct kunit *test)
 
 	ctx->link->connector_signal = SIGNAL_TYPE_DISPLAY_PORT;
 
-	stream = amdgpu_dm_create_validate_stream_for_sink(&ctx->aconnector->base,
-							   ctx->mode,
-							   ctx->dm_state, NULL);
+	stream = dm_test_validate_locked(&ctx->aconnector->base,
+					 ctx->mode,
+					 ctx->dm_state, NULL);
 	KUNIT_EXPECT_NULL(test, stream);
 
 	/* Same result when the sink-reported bpc is the limiting cap. */
 	ctx->dm_state->base.max_requested_bpc = 16;
 	ctx->aconnector->base.display_info.bpc = 4;
-	stream = amdgpu_dm_create_validate_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-							   ctx->dm_state, NULL);
+	stream = dm_test_validate_locked(&ctx->aconnector->base, ctx->mode,
+					 ctx->dm_state, NULL);
 	KUNIT_EXPECT_NULL(test, stream);
 }
 
@@ -7704,9 +7896,9 @@ static void dm_test_create_validate_stream_hdmi_ycbcr(struct kunit *test)
 		BIT(DRM_OUTPUT_COLOR_FORMAT_YCBCR422);
 	dm_test_set_420_also_mode(test, ctx->drm, &ctx->aconnector->base, ctx->mode);
 
-	stream = amdgpu_dm_create_validate_stream_for_sink(&ctx->aconnector->base,
-							   ctx->mode,
-							   ctx->dm_state, NULL);
+	stream = dm_test_validate_locked(&ctx->aconnector->base,
+					 ctx->mode,
+					 ctx->dm_state, NULL);
 	KUNIT_EXPECT_NULL(test, stream);
 }
 
@@ -7726,9 +7918,9 @@ static void dm_test_create_validate_stream_force_ycbcr420(struct kunit *test)
 	ctx->link->connector_signal = SIGNAL_TYPE_DISPLAY_PORT;
 	ctx->aconnector->force_yuv_pixel_format = PIXEL_ENCODING_YCBCR420;
 
-	stream = amdgpu_dm_create_validate_stream_for_sink(&ctx->aconnector->base,
-							   ctx->mode,
-							   ctx->dm_state, NULL);
+	stream = dm_test_validate_locked(&ctx->aconnector->base,
+					 ctx->mode,
+					 ctx->dm_state, NULL);
 	KUNIT_EXPECT_NULL(test, stream);
 }
 
@@ -7751,9 +7943,9 @@ static void dm_test_create_validate_stream_force_ycbcr422(struct kunit *test)
 	ctx->aconnector->base.display_info.color_formats =
 		BIT(DRM_OUTPUT_COLOR_FORMAT_YCBCR422);
 
-	stream = amdgpu_dm_create_validate_stream_for_sink(&ctx->aconnector->base,
-							   ctx->mode,
-							   ctx->dm_state, NULL);
+	stream = dm_test_validate_locked(&ctx->aconnector->base,
+					 ctx->mode,
+					 ctx->dm_state, NULL);
 	KUNIT_EXPECT_NULL(test, stream);
 }
 
@@ -7776,9 +7968,9 @@ static void dm_test_create_validate_stream_force_ycbcr444(struct kunit *test)
 	ctx->aconnector->base.display_info.color_formats =
 		BIT(DRM_OUTPUT_COLOR_FORMAT_YCBCR444);
 
-	stream = amdgpu_dm_create_validate_stream_for_sink(&ctx->aconnector->base,
-							   ctx->mode,
-							   ctx->dm_state, NULL);
+	stream = dm_test_validate_locked(&ctx->aconnector->base,
+					 ctx->mode,
+					 ctx->dm_state, NULL);
 	KUNIT_EXPECT_NULL(test, stream);
 }
 
@@ -7925,10 +8117,10 @@ static void dm_test_create_validate_stream_prune_timing(struct kunit *test)
 	c->tgfuncs->validate_timing = dm_test_cvs_validate_timing_fail;
 
 	KUNIT_EXPECT_NULL(test,
-			  amdgpu_dm_create_validate_stream_for_sink(&c->aconnector->base,
-								    c->mode,
-								    c->dm_state,
-								    NULL));
+			  dm_test_validate_locked(&c->aconnector->base,
+						  c->mode,
+						  c->dm_state,
+						  NULL));
 }
 
 /**
@@ -7947,10 +8139,10 @@ static void dm_test_create_validate_stream_prune_context(struct kunit *test)
 	c->link_srv->validate_mode_timing = dm_test_cvs_validate_mode_timing_ok;
 
 	KUNIT_EXPECT_NULL(test,
-			  amdgpu_dm_create_validate_stream_for_sink(&c->aconnector->base,
-								    c->mode,
-								    c->dm_state,
-								    NULL));
+			  dm_test_validate_locked(&c->aconnector->base,
+						  c->mode,
+						  c->dm_state,
+						  NULL));
 }
 
 static enum dc_pixel_encoding dm_test_cvs_first_encoding;
@@ -7979,10 +8171,10 @@ static void dm_test_create_validate_stream_hdmi_rgb_first(struct kunit *test)
 	dm_test_cvs_first_encoding = PIXEL_ENCODING_UNDEFINED;
 
 	KUNIT_EXPECT_NULL(test,
-			  amdgpu_dm_create_validate_stream_for_sink(&c->aconnector->base,
-								    c->mode,
-								    c->dm_state,
-								    NULL));
+			  dm_test_validate_locked(&c->aconnector->base,
+						  c->mode,
+						  c->dm_state,
+						  NULL));
 	KUNIT_EXPECT_EQ(test, (int)dm_test_cvs_first_encoding, (int)PIXEL_ENCODING_RGB);
 }
 
@@ -7997,15 +8189,13 @@ static bool dm_test_cvs_record_first_h_addressable(struct timing_generator *tg,
 	return false;
 }
 
-/*
- * A 3840x2160 preferred mode in connector->modes, as a probe of another sink
- * leaves it until the next probe prunes it
- */
-static void dm_test_cvs_add_preferred_4k(struct kunit *test, struct dm_test_cvs_dc *c)
+/* A 3840x2160 preferred mode copy, taken from a probe of the connector's sink */
+static void dm_test_cvs_set_preferred_copy(struct kunit *test, struct dm_test_cvs_dc *c)
 {
-	struct drm_display_mode *pref = drm_mode_create(c->drm);
+	struct drm_display_mode *pref = &c->aconnector->preferred_mode;
+
+	dm_test_attach_copies_sink(test, c->aconnector, c->link);
 
-	KUNIT_ASSERT_NOT_NULL(test, pref);
 	pref->hdisplay = 3840;
 	pref->hsync_start = 4016;
 	pref->hsync_end = 4104;
@@ -8017,44 +8207,45 @@ static void dm_test_cvs_add_preferred_4k(struct kunit *test, struct dm_test_cvs_
 	pref->clock = 594000;
 	pref->type = DRM_MODE_TYPE_PREFERRED;
 	drm_mode_set_crtcinfo(pref, CRTC_INTERLACE_HALVE_V);
-	list_add_tail(&pref->head, &c->aconnector->base.modes);
 }
 
 /**
- * dm_test_create_validate_stream_scaled_preferred - Test atomic_check scales to the preferred mode
+ * dm_test_create_validate_stream_scaled_copy - Test atomic_check scales to the copy
  * @test: The KUnit test context
  *
  * With scaling on, the stream for a 1920x1080 mode takes the CRTC timing of
- * the preferred mode in connector->modes
+ * the preferred mode copy
  */
-static void dm_test_create_validate_stream_scaled_preferred(struct kunit *test)
+static void dm_test_create_validate_stream_scaled_copy(struct kunit *test)
 {
 	struct dm_test_cvs_dc *c = dm_test_cvs_dc_alloc(test);
 
 	c->dm_state->scaling = RMX_FULL;
-	dm_test_cvs_add_preferred_4k(test, c);
+	dm_test_cvs_set_preferred_copy(test, c);
 	c->tgfuncs->validate_timing = dm_test_cvs_record_first_h_addressable;
 	dm_test_cvs_first_h_addressable = 0;
 
 	KUNIT_EXPECT_NULL(test,
-			  amdgpu_dm_create_validate_stream_for_sink(&c->aconnector->base,
-								    c->mode,
-								    c->dm_state,
-								    NULL));
+			  dm_test_validate_locked(&c->aconnector->base,
+						  c->mode,
+						  c->dm_state,
+						  NULL));
 	KUNIT_EXPECT_EQ(test, dm_test_cvs_first_h_addressable, 3840);
 }
 
 /**
- * dm_test_mode_valid_ignores_preferred_mode - Test mode_valid uses the mode's own timing
+ * dm_test_mode_valid_ignores_preferred_copy - Test mode_valid uses the mode's own timing
  * @test: The KUnit test context
  *
- * During a probe connector->modes still holds the previous sink's preferred
- * mode. Even with scaling on, the mode is validated with its own 1920x1080
- * timing rather than that mode's 3840x2160 one
+ * mode_valid runs inside a probe, before the copy is refreshed, so the copy
+ * may come from another sink. Even with scaling on, the mode is validated
+ * with its own 1920x1080 timing rather than the copy's 3840x2160 one
  */
-static void dm_test_mode_valid_ignores_preferred_mode(struct kunit *test)
+static void dm_test_mode_valid_ignores_preferred_copy(struct kunit *test)
 {
 	struct dm_test_cvs_dc *c = dm_test_cvs_dc_alloc(test);
+	struct mutex *lock = &c->aconnector->base.dev->mode_config.mutex;
+	enum drm_mode_status status;
 	struct dc_sink *em_sink;
 
 	em_sink = kunit_kzalloc(test, sizeof(*em_sink), GFP_KERNEL);
@@ -8068,13 +8259,15 @@ static void dm_test_mode_valid_ignores_preferred_mode(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, c->aconnector->base.state);
 	to_dm_connector_state(c->aconnector->base.state)->scaling = RMX_FULL;
 
-	dm_test_cvs_add_preferred_4k(test, c);
+	dm_test_cvs_set_preferred_copy(test, c);
 	c->tgfuncs->validate_timing = dm_test_cvs_record_first_h_addressable;
 	dm_test_cvs_first_h_addressable = 0;
 
-	KUNIT_EXPECT_EQ(test,
-			amdgpu_dm_connector_mode_valid(&c->aconnector->base, c->mode),
-			MODE_ERROR);
+	mutex_lock(lock);
+	status = amdgpu_dm_connector_mode_valid(&c->aconnector->base, c->mode);
+	mutex_unlock(lock);
+
+	KUNIT_EXPECT_EQ(test, status, MODE_ERROR);
 	KUNIT_EXPECT_EQ(test, dm_test_cvs_first_h_addressable, 1920);
 }
 
@@ -11309,8 +11502,8 @@ static struct kunit_case amdgpu_dm_connector_tests[] = {
 	KUNIT_CASE(dm_test_create_validate_stream_prune_timing),
 	KUNIT_CASE(dm_test_create_validate_stream_prune_context),
 	KUNIT_CASE(dm_test_create_validate_stream_hdmi_rgb_first),
-	KUNIT_CASE(dm_test_create_validate_stream_scaled_preferred),
-	KUNIT_CASE(dm_test_mode_valid_ignores_preferred_mode),
+	KUNIT_CASE(dm_test_create_validate_stream_scaled_copy),
+	KUNIT_CASE(dm_test_mode_valid_ignores_preferred_copy),
 	/* amdgpu_dm_update_connector_after_detect */
 	KUNIT_CASE(dm_test_update_after_detect_mst_noop),
 	KUNIT_CASE(dm_test_update_after_detect_sink_unchanged),
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
index fab6df40ed989..8eaa5909068bc 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
@@ -3213,6 +3213,23 @@ static void dm_test_aquire_global_lock_waits_commit(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, ret, 0);
 }
 
+/* Pick the config with connection_mutex held, as atomic_check does */
+static void dm_test_fs_video_config_locked(struct kunit *test,
+					   struct amdgpu_dm_connector *aconnector,
+					   struct dm_crtc_state *crtc_state,
+					   const struct dc_stream_state *stream)
+{
+	struct drm_modeset_lock *lock;
+
+	if (!aconnector->base.dev)
+		aconnector->base.dev = adev_to_drm(dm_kunit_alloc_adev(test));
+	lock = &aconnector->base.dev->mode_config.connection_mutex;
+
+	drm_modeset_lock(lock, NULL);
+	dm_set_freesync_video_config(aconnector, crtc_state, stream);
+	drm_modeset_unlock(lock);
+}
+
 /**
  * dm_test_freesync_video_config_no_old_stream - Test the fixed config needs no old stream
  * @test: The KUnit test context
@@ -3229,6 +3246,7 @@ static void dm_test_freesync_video_config_no_old_stream(struct kunit *test)
 	struct drm_display_mode *base, *mode;
 	struct dm_crtc_state *crtc_state;
 	struct dc_stream_state *stream;
+	struct dc_sink *sink;
 
 	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, aconnector);
@@ -3236,6 +3254,8 @@ static void dm_test_freesync_video_config_no_old_stream(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, crtc_state);
 	stream = kunit_kzalloc(test, sizeof(*stream), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, stream);
+	sink = kunit_kzalloc(test, sizeof(*sink), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, sink);
 
 	aconnector->base.connector_type = DRM_MODE_CONNECTOR_HDMIA;
 	base = &aconnector->freesync_vid_base;
@@ -3249,20 +3269,26 @@ static void dm_test_freesync_video_config_no_old_stream(struct kunit *test)
 	base->vsync_end = 1089;
 	base->vtotal = 1125;
 
+	memset(sink->dc_edid.raw_edid, 0x5a, 128);
+	sink->dc_edid.length = 128;
+	aconnector->mode_copies_edid_size = 128;
+	memcpy(aconnector->mode_copies_edid, sink->dc_edid.raw_edid, 128);
+	stream->sink = sink;
+
 	crtc_state->freesync_config.state = VRR_STATE_INACTIVE;
 	mode = &crtc_state->base.mode;
 	drm_mode_copy(mode, base);
 
 	amdgpu_freesync_vid_mode = 1;
 
-	dm_set_freesync_video_config(aconnector, crtc_state, stream);
+	dm_test_fs_video_config_locked(test, aconnector, crtc_state, stream);
 	KUNIT_EXPECT_EQ(test, (int)crtc_state->freesync_config.state,
 			(int)VRR_STATE_INACTIVE);
 
 	mode->vsync_start += 225;
 	mode->vsync_end += 225;
 	mode->vtotal += 225;
-	dm_set_freesync_video_config(aconnector, crtc_state, stream);
+	dm_test_fs_video_config_locked(test, aconnector, crtc_state, stream);
 	KUNIT_EXPECT_EQ(test, (int)crtc_state->freesync_config.state,
 			(int)VRR_STATE_ACTIVE_FIXED);
 	KUNIT_EXPECT_EQ(test, crtc_state->freesync_config.fixed_refresh_in_uhz, 50000000U);

-- 
2.56.0

