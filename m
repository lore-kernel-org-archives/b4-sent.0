From: Hugo Sales <hugo@hsal.es>
Date: Sat, 14 Nov 2026 23:09:15 +0000
Subject: [PATCH 4/8] drm/amd/display: Copy the preferred and highest
 refresh modes after probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-amdgpu-modes-four-v1-4-f11e2a6cd407@hsal.es>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=36491; i=hugo@hsal.es;
 h=from:subject:message-id; bh=bQY0OUl/GFo3ImDoCf6LQiBPSTRX1a5B+X9wGQ8cWcU=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsn68krALPzg/cVpeWMd79Su6zUIr3D66+tznmV3PP
 uV1W1bH9EMdpSwMYlwMsmKKLLo3PBlYJk6emVP0fAnMHFYmkCEMXJwCMBFrZ0aGGeFrlDJ2fWf9
 +T18auQlsSXqa2dvWh1t7VWb+Xil5bonrgy/WT+U3p6WwHqkf+Ntjs8ijkcFzRcviKpuLbF0ajj
 wSFadCwCvgEro
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

atomic_check walks connector->modes for the preferred mode and the
highest refresh rate mode without mode_config.mutex, so a probe on
another thread can rebuild the list under it

Add amdgpu_dm_connector_fill_modes() as the fill_modes hook of SST and
MST connectors. After the probe it copies both modes and the dc_sink's
EDID into struct amdgpu_dm_connector, under connection_mutex, which
atomic_check holds. On eDP and LVDS the preferred copy falls back to the
panel's native mode, as atomic_check's lookup does

The highest refresh rate copy is the mode add_fs_modes() built the
FreeSync video modes from, which it now records in
probed_freesync_vid_base, if validation kept it

amdgpu_dm_get_highest_refresh_rate_mode() returns the copy, except to
the probe's own callers, add_fs_modes() and the max_vfreq fallback,
which need the ongoing probe's modes. For an EDID without a preferred
mode, those callers now fall back to the first mode of this probe, not
of the previous one

An upcoming patch switches the readers to the copies, for a sink with
the same EDID only

Link: https://lore.kernel.org/r/auh8pUx_kXUYSdZ8@intel.com
Signed-off-by: Hugo Sales <hugo@hsal.es>
---
Comparing the whole EDID costs about as much as a CRC32 of it and can't
collide. The copy sits inline, as raw_edid does in dc_sink, so it needs
no allocation

A dc_sink pointer match won't do, since dm_resume() and a replug replace
dc_sink, and the copies of the same monitor would be dropped on every
resume

dm_resume() and the MST connector's ->early_unregister() release dc_sink
without mode_config.mutex, so reading its EDID here can race with them,
as ->get_modes() and ->mode_valid() already do. I have an upcoming
series that takes mode_config.mutex around those releases
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h  |  20 +-
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.c    | 197 ++++++--
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.h    |   3 +
 .../amd/display/amdgpu_dm/amdgpu_dm_mst_types.c    |   2 +-
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c     | 516 +++++++++++++++++++++
 5 files changed, 702 insertions(+), 36 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h
index f8503ebf28f47..97a74178513a9 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.h
@@ -902,8 +902,26 @@ struct amdgpu_dm_connector {
 	struct dsc_preferred_settings dsc_settings;
 	struct psr_caps psr_caps;
 	union dp_downstream_port_present mst_downstream_port_present;
-	/* Cached display modes */
+	/*
+	 * Copies of the preferred mode in base.modes and of the highest
+	 * refresh rate mode at its size, with the EDID of the dc_sink they
+	 * came from, or a size of 0 if it had none. After each probe,
+	 * amdgpu_dm_connector_fill_modes() writes them with
+	 * &drm_mode_config.mutex and &drm_mode_config.connection_mutex held,
+	 * so either lock is enough to read them. atomic_check holds only the
+	 * modeset locks, so it reads these instead of base.modes
+	 */
+	struct drm_display_mode preferred_mode;
 	struct drm_display_mode freesync_vid_base;
+	u8 mode_copies_edid[DC_MAX_EDID_BUFFER_SIZE];
+	u32 mode_copies_edid_size;
+	/*
+	 * The mode add_fs_modes() built the FreeSync video modes from in the
+	 * last probe, or zeroed if it built none. It comes from the EDID,
+	 * while base.modes can also hold a command line mode. Protected by
+	 * &drm_mode_config.mutex
+	 */
+	struct drm_display_mode probed_freesync_vid_base;
 
 	int sr_skip_count;
 	bool disallow_edp_enter_psr;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
index e477ef61ce109..491965266b786 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
@@ -1108,6 +1108,74 @@ amdgpu_dm_panel_native_mode(struct drm_connector *connector, struct list_head *m
 	return native_buf;
 }
 
+static struct drm_display_mode *amdgpu_dm_find_preferred_mode(struct list_head *modes)
+{
+	struct drm_display_mode *m;
+
+	list_for_each_entry(m, modes, head) {
+		if (m->type & DRM_MODE_TYPE_PREFERRED)
+			return m;
+	}
+
+	return NULL;
+}
+
+/*
+ * Find the mode with the highest refresh rate at the size of @m_pref. For
+ * some monitors the preferred mode is not the one with the highest supported
+ * refresh rate
+ */
+static struct drm_display_mode *
+amdgpu_dm_find_highest_refresh_mode(struct list_head *modes,
+				    struct drm_display_mode *m_pref)
+{
+	int highest_refresh = drm_mode_vrefresh(m_pref);
+	struct drm_display_mode *best = m_pref, *m;
+
+	list_for_each_entry(m, modes, head) {
+		int current_refresh = drm_mode_vrefresh(m);
+
+		if (m->hdisplay == m_pref->hdisplay &&
+		    m->vdisplay == m_pref->vdisplay &&
+		    highest_refresh < current_refresh) {
+			highest_refresh = current_refresh;
+			best = m;
+		}
+	}
+
+	return best;
+}
+
+/* The size of @sink's EDID, 0 without a sink or EDID */
+static u32 amdgpu_dm_sink_edid_size(const struct dc_sink *sink)
+{
+	return sink ? min_t(u32, sink->dc_edid.length, sizeof(sink->dc_edid.raw_edid)) : 0;
+}
+
+/*
+ * Whether @modes still holds @vid_base, at the size of @preferred. Validation
+ * may have pruned the FreeSync video modes and their base after add_fs_modes()
+ * recorded it
+ */
+static bool
+amdgpu_dm_probed_freesync_vid_base_listed(struct list_head *modes,
+					  const struct drm_display_mode *vid_base,
+					  const struct drm_display_mode *preferred)
+{
+	const struct drm_display_mode *m;
+
+	if (!vid_base->clock || vid_base->hdisplay != preferred->hdisplay ||
+	    vid_base->vdisplay != preferred->vdisplay)
+		return false;
+
+	list_for_each_entry(m, modes, head) {
+		if (drm_mode_equal(m, vid_base))
+			return true;
+	}
+
+	return false;
+}
+
 /**
  * DOC: FreeSync Video
  *
@@ -1142,8 +1210,7 @@ struct drm_display_mode *
 amdgpu_dm_get_highest_refresh_rate_mode(struct amdgpu_dm_connector *aconnector,
 		bool use_probed_modes)
 {
-	struct drm_display_mode *m, *m_pref = NULL;
-	u16 current_refresh, highest_refresh;
+	struct drm_display_mode *m_pref;
 	struct list_head *list_head = use_probed_modes ?
 		&aconnector->base.probed_modes :
 		&aconnector->base.modes;
@@ -1151,47 +1218,25 @@ amdgpu_dm_get_highest_refresh_rate_mode(struct amdgpu_dm_connector *aconnector,
 	if (aconnector->base.connector_type == DRM_MODE_CONNECTOR_WRITEBACK)
 		return NULL;
 
-	if (aconnector->freesync_vid_base.clock != 0)
+	/*
+	 * A probe reads its own probed_modes, not the copy of the last one. The
+	 * copy stands in while probed_modes is empty
+	 */
+	if (aconnector->freesync_vid_base.clock != 0 &&
+	    !(use_probed_modes && !list_empty(list_head)))
 		return &aconnector->freesync_vid_base;
 
-	/* Find the preferred mode */
-	list_for_each_entry(m, list_head, head) {
-		if (m->type & DRM_MODE_TYPE_PREFERRED) {
-			m_pref = m;
-			break;
-		}
-	}
-
+	m_pref = amdgpu_dm_find_preferred_mode(list_head);
 	if (!m_pref) {
 		/* Probably an EDID with no preferred mode. Fallback to first entry */
-		m_pref = list_first_entry_or_null(
-				&aconnector->base.modes, struct drm_display_mode, head);
+		m_pref = list_first_entry_or_null(list_head, struct drm_display_mode, head);
 		if (!m_pref) {
 			drm_dbg_driver(aconnector->base.dev, "No preferred mode found in EDID\n");
 			return NULL;
 		}
 	}
 
-	highest_refresh = drm_mode_vrefresh(m_pref);
-
-	/*
-	 * Find the mode with highest refresh rate with same resolution.
-	 * For some monitors, preferred mode is not the mode with highest
-	 * supported refresh rate.
-	 */
-	list_for_each_entry(m, list_head, head) {
-		current_refresh  = drm_mode_vrefresh(m);
-
-		if (m->hdisplay == m_pref->hdisplay &&
-		    m->vdisplay == m_pref->vdisplay &&
-		    highest_refresh < current_refresh) {
-			highest_refresh = current_refresh;
-			m_pref = m;
-		}
-	}
-
-	drm_mode_copy(&aconnector->freesync_vid_base, m_pref);
-	return m_pref;
+	return amdgpu_dm_find_highest_refresh_mode(list_head, m_pref);
 }
 EXPORT_IF_KUNIT(amdgpu_dm_get_highest_refresh_rate_mode);
 
@@ -1223,6 +1268,87 @@ bool amdgpu_dm_is_freesync_video_mode(const struct drm_display_mode *mode,
 }
 EXPORT_IF_KUNIT(amdgpu_dm_is_freesync_video_mode);
 
+STATIC_IFN_KUNIT void
+amdgpu_dm_connector_update_mode_copies(struct amdgpu_dm_connector *aconnector)
+{
+	struct drm_mode_config *config = &aconnector->base.dev->mode_config;
+	struct list_head *modes = &aconnector->base.modes;
+	const struct drm_display_mode *preferred, *highest;
+	struct drm_display_mode native_buf;
+	const struct dc_sink *sink;
+
+	lockdep_assert_held(&config->mutex);
+
+	drm_modeset_lock(&config->connection_mutex, NULL);
+
+	sink = aconnector->dc_sink;
+	aconnector->mode_copies_edid_size = amdgpu_dm_sink_edid_size(sink);
+	if (aconnector->mode_copies_edid_size)
+		memcpy(aconnector->mode_copies_edid, sink->dc_edid.raw_edid,
+		       aconnector->mode_copies_edid_size);
+
+	preferred = amdgpu_dm_find_preferred_mode(modes);
+	if (!preferred)
+		preferred = amdgpu_dm_panel_native_mode(&aconnector->base, modes, &native_buf);
+	if (!preferred)
+		preferred = list_first_entry_or_null(modes, struct drm_display_mode, head);
+
+	if (!preferred) {
+		memset(&aconnector->preferred_mode, 0, sizeof(aconnector->preferred_mode));
+		memset(&aconnector->freesync_vid_base, 0, sizeof(aconnector->freesync_vid_base));
+		goto unlock;
+	}
+
+	drm_mode_copy(&aconnector->preferred_mode, preferred);
+
+	/*
+	 * The FreeSync video modes differ from their base only in vtotal, and
+	 * atomic_check matches them against this copy. A command line mode at
+	 * the preferred size with a higher refresh rate would win the search
+	 * below, so take the base add_fs_modes() used, if validation kept it
+	 * and it has the preferred mode's size
+	 */
+	if (amdgpu_dm_probed_freesync_vid_base_listed(modes,
+						      &aconnector->probed_freesync_vid_base,
+						      &aconnector->preferred_mode))
+		highest = &aconnector->probed_freesync_vid_base;
+	else
+		highest = amdgpu_dm_find_highest_refresh_mode(modes, &aconnector->preferred_mode);
+
+	drm_mode_copy(&aconnector->freesync_vid_base, highest);
+
+unlock:
+	drm_modeset_unlock(&config->connection_mutex);
+}
+EXPORT_IF_KUNIT(amdgpu_dm_connector_update_mode_copies);
+
+/*
+ * atomic_check needs the preferred and highest refresh rate modes, but
+ * &drm_mode_config.mutex protects base.modes and atomic_check can't take it.
+ * Copy them after each probe. amdgpu_dm_connector_update_mode_copies() also
+ * takes &drm_mode_config.connection_mutex, so atomic_check can read the copies
+ * with the lock it holds
+ */
+int amdgpu_dm_connector_fill_modes(struct drm_connector *connector,
+				   u32 max_width, u32 max_height)
+{
+	struct amdgpu_dm_connector *aconnector = to_amdgpu_dm_connector(connector);
+	int count;
+
+	lockdep_assert_held(&connector->dev->mode_config.mutex);
+
+	/* The probe helper skips ->get_modes() for a disconnected connector */
+	memset(&aconnector->probed_freesync_vid_base, 0,
+	       sizeof(aconnector->probed_freesync_vid_base));
+
+	count = drm_helper_probe_single_connector_modes(connector, max_width,
+							max_height);
+	amdgpu_dm_connector_update_mode_copies(aconnector);
+
+	return count;
+}
+EXPORT_IF_KUNIT(amdgpu_dm_connector_fill_modes);
+
 #if defined(CONFIG_DRM_AMD_DC_FP)
 static void update_dsc_caps(struct amdgpu_dm_connector *aconnector,
 			    struct dc_sink *sink, struct dc_stream_state *stream,
@@ -2150,7 +2276,7 @@ EXPORT_IF_KUNIT(amdgpu_dm_connector_funcs_force);
 static const struct drm_connector_funcs amdgpu_dm_connector_funcs = {
 	.reset = amdgpu_dm_connector_funcs_reset,
 	.detect = amdgpu_dm_connector_detect,
-	.fill_modes = drm_helper_probe_single_connector_modes,
+	.fill_modes = amdgpu_dm_connector_fill_modes,
 	.destroy = amdgpu_dm_connector_destroy,
 	.atomic_duplicate_state = amdgpu_dm_connector_atomic_duplicate_state,
 	.atomic_destroy_state = drm_atomic_helper_connector_destroy_state,
@@ -3199,6 +3325,9 @@ STATIC_IFN_KUNIT uint add_fs_modes(struct amdgpu_dm_connector *aconnector)
 			drm_mode_destroy(aconnector->base.dev, new_mode);
 	}
  out:
+	if (new_modes_count)
+		drm_mode_copy(&aconnector->probed_freesync_vid_base, m);
+
 	return new_modes_count;
 }
 EXPORT_IF_KUNIT(add_fs_modes);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h
index e7ed9a0bf56fb..ee8d7eabd7c13 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h
@@ -51,6 +51,8 @@ struct drm_edid;
 struct drm_property;
 
 void amdgpu_dm_connector_funcs_reset(struct drm_connector *connector);
+int amdgpu_dm_connector_fill_modes(struct drm_connector *connector,
+				   u32 max_width, u32 max_height);
 
 struct drm_connector_state *
 amdgpu_dm_connector_atomic_duplicate_state(struct drm_connector *connector);
@@ -170,6 +172,7 @@ void amdgpu_dm_connector_ddc_get_modes(struct drm_connector *connector,
 int amdgpu_dm_connector_get_modes(struct drm_connector *connector);
 void amdgpu_dm_prune_primary_tile_modes(struct drm_connector *connector);
 uint add_fs_modes(struct amdgpu_dm_connector *aconnector);
+void amdgpu_dm_connector_update_mode_copies(struct amdgpu_dm_connector *aconnector);
 void amdgpu_dm_connector_add_freesync_modes(struct drm_connector *connector,
 					    const struct drm_edid *drm_edid);
 void hdmi_cec_unset_edid(struct amdgpu_dm_connector *aconnector);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
index 5697645ef7cca..83021470c8b2c 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
@@ -256,7 +256,7 @@ amdgpu_dm_mst_connector_early_unregister(struct drm_connector *connector)
 EXPORT_IF_KUNIT(amdgpu_dm_mst_connector_early_unregister);
 
 static const struct drm_connector_funcs dm_dp_mst_connector_funcs = {
-	.fill_modes = drm_helper_probe_single_connector_modes,
+	.fill_modes = amdgpu_dm_connector_fill_modes,
 	.destroy = dm_dp_mst_connector_destroy,
 	.reset = amdgpu_dm_connector_funcs_reset,
 	.atomic_duplicate_state = amdgpu_dm_connector_atomic_duplicate_state,
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
index e8cabe25a192d..49e85aec3c665 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
@@ -2457,6 +2457,383 @@ static void dm_test_highest_refresh_preferred_mode(struct kunit *test)
 			    mode);
 }
 
+/* Tests for amdgpu_dm_connector_update_mode_copies() */
+
+static struct drm_display_mode *
+dm_test_copy_add_mode(struct kunit *test, struct list_head *modes,
+		      u16 hdisplay, u16 vdisplay, u16 htotal, u16 vtotal,
+		      int clock, u32 type)
+{
+	struct drm_display_mode *mode;
+
+	mode = kunit_kzalloc(test, sizeof(*mode), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, mode);
+
+	mode->hdisplay = hdisplay;
+	mode->vdisplay = vdisplay;
+	mode->htotal = htotal;
+	mode->vtotal = vtotal;
+	mode->clock = clock;
+	mode->type = type;
+	list_add_tail(&mode->head, modes);
+
+	return mode;
+}
+
+static struct drm_device *dm_test_alloc_drm(struct kunit *test);
+
+/*
+ * Take the copies as amdgpu_dm_connector_fill_modes() does, with
+ * &drm_mode_config.mutex held. A connector without a device gets one for the
+ * locks, without registering the connector with it
+ */
+static void dm_test_copy_locked(struct kunit *test, struct amdgpu_dm_connector *aconnector)
+{
+	struct drm_mode_config *config;
+
+	if (!aconnector->base.dev)
+		aconnector->base.dev = dm_test_alloc_drm(test);
+	config = &aconnector->base.dev->mode_config;
+
+	mutex_lock(&config->mutex);
+	amdgpu_dm_connector_update_mode_copies(aconnector);
+	mutex_unlock(&config->mutex);
+}
+
+/**
+ * dm_test_highest_refresh_probed_skips_copy - Test a probe reads probed_modes
+ * @test: The KUnit test context
+ *
+ * The copy is from the previous probe, possibly of another monitor, so a
+ * caller that passes use_probed_modes must get this probe's mode
+ */
+static void dm_test_highest_refresh_probed_skips_copy(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector;
+	struct drm_display_mode *mode;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	aconnector->base.connector_type = DRM_MODE_CONNECTOR_HDMIA;
+	INIT_LIST_HEAD(&aconnector->base.modes);
+	INIT_LIST_HEAD(&aconnector->base.probed_modes);
+	aconnector->freesync_vid_base.clock = 148500;
+	aconnector->freesync_vid_base.hdisplay = 1920;
+	aconnector->freesync_vid_base.vdisplay = 1080;
+
+	mode = dm_test_copy_add_mode(test, &aconnector->base.probed_modes, 2560, 1440,
+				     2720, 1481, 241500, DRM_MODE_TYPE_PREFERRED);
+
+	KUNIT_EXPECT_PTR_EQ(test,
+			    amdgpu_dm_get_highest_refresh_rate_mode(aconnector, true),
+			    mode);
+}
+
+/**
+ * dm_test_update_mode_copies_highest_refresh - Test the copies taken from base.modes
+ * @test: The KUnit test context
+ *
+ * The preferred mode is copied as is. The highest refresh rate copy comes from
+ * the preferred size only, even when another size has a higher refresh rate
+ */
+static void dm_test_update_mode_copies_highest_refresh(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector;
+	struct list_head *modes;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	modes = &aconnector->base.modes;
+	INIT_LIST_HEAD(modes);
+
+	dm_test_copy_add_mode(test, modes, 1280, 720, 1650, 750, 297000, 0);
+	dm_test_copy_add_mode(test, modes, 1920, 1080, 2200, 1125, 148500,
+			      DRM_MODE_TYPE_PREFERRED);
+	dm_test_copy_add_mode(test, modes, 1920, 1080, 2200, 1125, 297000, 0);
+
+	dm_test_copy_locked(test, aconnector);
+
+	KUNIT_EXPECT_EQ(test, aconnector->preferred_mode.clock, 148500);
+	KUNIT_EXPECT_EQ(test, (int)aconnector->preferred_mode.hdisplay, 1920);
+	KUNIT_EXPECT_TRUE(test, aconnector->preferred_mode.type & DRM_MODE_TYPE_PREFERRED);
+	KUNIT_EXPECT_EQ(test, aconnector->freesync_vid_base.clock, 297000);
+	KUNIT_EXPECT_EQ(test, (int)aconnector->freesync_vid_base.hdisplay, 1920);
+	KUNIT_EXPECT_EQ(test, (int)aconnector->freesync_vid_base.vdisplay, 1080);
+}
+
+/**
+ * dm_test_update_mode_copies_no_preferred - Test the first mode stands in for a preferred one
+ * @test: The KUnit test context
+ */
+static void dm_test_update_mode_copies_no_preferred(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector;
+	struct list_head *modes;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	modes = &aconnector->base.modes;
+	INIT_LIST_HEAD(modes);
+
+	dm_test_copy_add_mode(test, modes, 1920, 1080, 2200, 1125, 148500, 0);
+	dm_test_copy_add_mode(test, modes, 1280, 720, 1650, 750, 297000, 0);
+
+	dm_test_copy_locked(test, aconnector);
+
+	KUNIT_EXPECT_EQ(test, (int)aconnector->preferred_mode.hdisplay, 1920);
+	KUNIT_EXPECT_EQ(test, aconnector->freesync_vid_base.clock, 148500);
+}
+
+/**
+ * dm_test_update_mode_copies_records_edid - Test the copies record the sink's EDID
+ * @test: The KUnit test context
+ *
+ * atomic_check compares the EDID of the sink it builds a stream for with the
+ * one the copies were taken with
+ */
+static void dm_test_update_mode_copies_records_edid(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector;
+	struct dc_sink *sink;
+	u8 *edid;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	sink = kunit_kzalloc(test, sizeof(*sink), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, sink);
+	INIT_LIST_HEAD(&aconnector->base.modes);
+	aconnector->dc_sink = sink;
+
+	edid = sink->dc_edid.raw_edid;
+	memset(edid, 0xa5, 256);
+	sink->dc_edid.length = 256;
+
+	dm_test_copy_add_mode(test, &aconnector->base.modes, 1920, 1080, 2200, 1125,
+			      148500, DRM_MODE_TYPE_PREFERRED);
+
+	dm_test_copy_locked(test, aconnector);
+
+	KUNIT_EXPECT_EQ(test, aconnector->mode_copies_edid_size, 256);
+	KUNIT_EXPECT_MEMEQ(test, aconnector->mode_copies_edid, edid, 256);
+}
+
+/**
+ * dm_test_update_mode_copies_no_edid - Test copies without a sink EDID record none
+ * @test: The KUnit test context
+ *
+ * Without a sink, or with one that has no EDID, nothing identifies the
+ * monitor, so the copies must not match any sink later
+ */
+static void dm_test_update_mode_copies_no_edid(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector;
+	struct dc_sink *sink;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	sink = kunit_kzalloc(test, sizeof(*sink), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, sink);
+	INIT_LIST_HEAD(&aconnector->base.modes);
+	aconnector->mode_copies_edid_size = 128;
+	memset(aconnector->mode_copies_edid, 0x5a, 128);
+
+	dm_test_copy_add_mode(test, &aconnector->base.modes, 1920, 1080, 2200, 1125,
+			      148500, DRM_MODE_TYPE_PREFERRED);
+
+	dm_test_copy_locked(test, aconnector);
+	KUNIT_EXPECT_EQ(test, aconnector->mode_copies_edid_size, 0);
+
+	aconnector->dc_sink = sink;
+	aconnector->mode_copies_edid_size = 128;
+	memset(aconnector->mode_copies_edid, 0x5a, 128);
+
+	dm_test_copy_locked(test, aconnector);
+	KUNIT_EXPECT_EQ(test, aconnector->mode_copies_edid_size, 0);
+}
+
+/**
+ * dm_test_update_mode_copies_empty - Test an empty mode list clears both copies
+ * @test: The KUnit test context
+ *
+ * A disconnected connector ends its probe with no modes. Copies from an
+ * earlier probe must not survive that
+ */
+static void dm_test_update_mode_copies_empty(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	INIT_LIST_HEAD(&aconnector->base.modes);
+	aconnector->preferred_mode.clock = 148500;
+	aconnector->freesync_vid_base.clock = 297000;
+
+	dm_test_copy_locked(test, aconnector);
+
+	KUNIT_EXPECT_EQ(test, aconnector->preferred_mode.clock, 0);
+	KUNIT_EXPECT_EQ(test, aconnector->freesync_vid_base.clock, 0);
+}
+
+/**
+ * dm_test_update_mode_copies_freesync_vid_base - Test the FreeSync base beats a command line mode
+ * @test: The KUnit test context
+ *
+ * A video= mode at the preferred size with a higher refresh rate than any EDID
+ * mode is in base.modes, but the FreeSync video modes were built from
+ * probed_freesync_vid_base, so that is the copy atomic_check gets
+ */
+static void dm_test_update_mode_copies_freesync_vid_base(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector;
+	struct list_head *modes;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	modes = &aconnector->base.modes;
+	INIT_LIST_HEAD(modes);
+
+	dm_test_copy_add_mode(test, modes, 1920, 1080, 2200, 1125, 148500,
+			      DRM_MODE_TYPE_PREFERRED);
+	dm_test_copy_add_mode(test, modes, 1920, 1080, 2200, 1125, 297000, 0);
+	dm_test_copy_add_mode(test, modes, 1920, 1080, 2200, 1125, 346500,
+			      DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_USERDEF);
+
+	dm_test_copy_locked(test, aconnector);
+	KUNIT_EXPECT_EQ(test, aconnector->freesync_vid_base.clock, 346500);
+
+	aconnector->probed_freesync_vid_base.hdisplay = 1920;
+	aconnector->probed_freesync_vid_base.vdisplay = 1080;
+	aconnector->probed_freesync_vid_base.htotal = 2200;
+	aconnector->probed_freesync_vid_base.vtotal = 1125;
+	aconnector->probed_freesync_vid_base.clock = 297000;
+
+	dm_test_copy_locked(test, aconnector);
+	KUNIT_EXPECT_EQ(test, aconnector->freesync_vid_base.clock, 297000);
+	KUNIT_EXPECT_EQ(test, aconnector->preferred_mode.clock, 148500);
+}
+
+/**
+ * dm_test_update_mode_copies_freesync_vid_base_pruned - Test a pruned FreeSync base is not copied
+ * @test: The KUnit test context
+ *
+ * add_fs_modes() records probed_freesync_vid_base before validation. If
+ * validation pruned its size, or the base itself, the copy must be the highest
+ * refresh rate mode at the preferred size that base.modes still holds
+ */
+static void dm_test_update_mode_copies_freesync_vid_base_pruned(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector;
+	struct list_head *modes;
+
+	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	aconnector->base.connector_type = DRM_MODE_CONNECTOR_HDMIA;
+	modes = &aconnector->base.modes;
+	INIT_LIST_HEAD(modes);
+
+	dm_test_copy_add_mode(test, modes, 1920, 1200, 2080, 1235, 154000, 0);
+	dm_test_copy_add_mode(test, modes, 1920, 1200, 2080, 1235, 308000, 0);
+
+	aconnector->probed_freesync_vid_base.hdisplay = 3840;
+	aconnector->probed_freesync_vid_base.vdisplay = 2400;
+	aconnector->probed_freesync_vid_base.htotal = 4000;
+	aconnector->probed_freesync_vid_base.vtotal = 2469;
+	aconnector->probed_freesync_vid_base.clock = 592500;
+
+	dm_test_copy_locked(test, aconnector);
+	KUNIT_EXPECT_EQ(test, (int)aconnector->preferred_mode.hdisplay, 1920);
+	KUNIT_EXPECT_EQ(test, (int)aconnector->freesync_vid_base.hdisplay, 1920);
+	KUNIT_EXPECT_EQ(test, (int)aconnector->freesync_vid_base.vdisplay, 1200);
+	KUNIT_EXPECT_EQ(test, aconnector->freesync_vid_base.clock, 308000);
+
+	aconnector->probed_freesync_vid_base.hdisplay = 1920;
+	aconnector->probed_freesync_vid_base.vdisplay = 1200;
+	aconnector->probed_freesync_vid_base.htotal = 2080;
+	aconnector->probed_freesync_vid_base.vtotal = 1235;
+	aconnector->probed_freesync_vid_base.clock = 231000;
+
+	dm_test_copy_locked(test, aconnector);
+	KUNIT_EXPECT_EQ(test, aconnector->freesync_vid_base.clock, 308000);
+}
+
+/* Tests for amdgpu_dm_connector_fill_modes() */
+
+static int dm_test_fill_modes_get_modes(struct drm_connector *connector)
+{
+	static const int refresh[] = { 60, 120 };
+	struct drm_display_mode *mode;
+	int i;
+
+	for (i = 0; i < ARRAY_SIZE(refresh); i++) {
+		mode = drm_cvt_mode(connector->dev, 1920, 1080, refresh[i],
+				    false, false, false);
+		if (!mode)
+			return i;
+		if (i == 0)
+			mode->type |= DRM_MODE_TYPE_PREFERRED;
+		drm_mode_probed_add(connector, mode);
+	}
+
+	return i;
+}
+
+static const struct drm_connector_helper_funcs dm_test_fill_modes_helper_funcs = {
+	.get_modes = dm_test_fill_modes_get_modes,
+};
+
+static const struct drm_connector_funcs dm_test_fill_modes_funcs = {
+	.fill_modes = amdgpu_dm_connector_fill_modes,
+	.atomic_duplicate_state = drm_atomic_helper_connector_duplicate_state,
+	.atomic_destroy_state = drm_atomic_helper_connector_destroy_state,
+};
+
+/**
+ * dm_test_fill_modes_copies_probe - Test fill_modes copies the modes of its probe
+ * @test: The KUnit test context
+ *
+ * The hook returns the probe helper's mode count and takes the copies and the
+ * sink's EDID from the modes that probe left in base.modes
+ */
+static void dm_test_fill_modes_copies_probe(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector;
+	struct drm_connector *connector;
+	struct drm_device *drm;
+	struct device *dev;
+	struct dc_sink *sink;
+	int count;
+
+	dev = drm_kunit_helper_alloc_device(test);
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, dev);
+	drm = __drm_kunit_helper_alloc_drm_device(test, dev, sizeof(*drm), 0,
+						  DRIVER_MODESET);
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, drm);
+
+	aconnector = drmm_kzalloc(drm, sizeof(*aconnector), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aconnector);
+	connector = &aconnector->base;
+	KUNIT_ASSERT_EQ(test, drmm_connector_init(drm, connector, &dm_test_fill_modes_funcs,
+						  DRM_MODE_CONNECTOR_HDMIA, NULL), 0);
+	drm_connector_helper_add(connector, &dm_test_fill_modes_helper_funcs);
+
+	sink = kunit_kzalloc(test, sizeof(*sink), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, sink);
+	memset(sink->dc_edid.raw_edid, 0x5a, 128);
+	sink->dc_edid.length = 128;
+	aconnector->dc_sink = sink;
+
+	mutex_lock(&drm->mode_config.mutex);
+	count = connector->funcs->fill_modes(connector, 4096, 4096);
+	mutex_unlock(&drm->mode_config.mutex);
+
+	KUNIT_EXPECT_EQ(test, count, 2);
+	KUNIT_EXPECT_EQ(test, (int)aconnector->preferred_mode.hdisplay, 1920);
+	KUNIT_EXPECT_EQ(test, drm_mode_vrefresh(&aconnector->preferred_mode), 60);
+	KUNIT_EXPECT_EQ(test, drm_mode_vrefresh(&aconnector->freesync_vid_base), 120);
+	KUNIT_EXPECT_EQ(test, aconnector->mode_copies_edid_size, 128);
+	KUNIT_EXPECT_MEMEQ(test, aconnector->mode_copies_edid, sink->dc_edid.raw_edid, 128);
+}
+
 /* Tests for amdgpu_dm_is_freesync_video_mode() */
 
 /**
@@ -4800,6 +5177,127 @@ static void dm_test_create_stream_native_mode_no_edid_edp(struct kunit *test)
 							     DM_TEST_NATIVE_NO_EDID));
 }
 
+/*
+ * Copy the modes after a probe with size limits below the native mode. The
+ * probe left a 1920x1200 mode in base.modes, and with @listed also a 3840x2400
+ * mode at half the native clock, while the encoder keeps the 3840x2400 native
+ * mode
+ */
+static struct amdgpu_dm_connector *
+dm_test_copy_pruned(struct kunit *test, int connector_type, bool listed)
+{
+	static const u8 edid[EDID_LENGTH];
+	struct dm_test_stream_ctx *ctx = dm_test_stream_ctx_alloc_type(test, connector_type);
+	struct amdgpu_dm_connector *aconnector = ctx->aconnector;
+	struct list_head *modes = &aconnector->base.modes;
+	struct drm_display_mode *native, *mode;
+	struct amdgpu_encoder *aenc;
+
+	aenc = drmm_kzalloc(ctx->drm, sizeof(*aenc), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, aenc);
+	KUNIT_ASSERT_EQ(test, drmm_encoder_init(ctx->drm, &aenc->base, NULL,
+						DRM_MODE_ENCODER_TMDS, NULL), 0);
+	KUNIT_ASSERT_EQ(test, drm_connector_attach_encoder(&aconnector->base, &aenc->base), 0);
+
+	native = &aenc->native_mode;
+	native->clock = 592500;
+	native->hdisplay = 3840;
+	native->hsync_start = 3888;
+	native->hsync_end = 3920;
+	native->htotal = 4000;
+	native->vdisplay = 2400;
+	native->vsync_start = 2403;
+	native->vsync_end = 2409;
+	native->vtotal = 2469;
+
+	mode = drm_mode_duplicate(ctx->drm, native);
+	KUNIT_ASSERT_NOT_NULL(test, mode);
+	mode->hdisplay = 1920;
+	mode->vdisplay = 1200;
+	list_add_tail(&mode->head, modes);
+
+	if (listed) {
+		mode = drm_mode_duplicate(ctx->drm, native);
+		KUNIT_ASSERT_NOT_NULL(test, mode);
+		mode->clock /= 2;
+		list_add_tail(&mode->head, modes);
+	}
+
+	aconnector->drm_edid = drm_edid_alloc(edid, sizeof(edid));
+	KUNIT_ASSERT_NOT_NULL(test, aconnector->drm_edid);
+
+	dm_test_copy_locked(test, aconnector);
+
+	drm_edid_free(aconnector->drm_edid);
+	aconnector->drm_edid = NULL;
+
+	return aconnector;
+}
+
+/**
+ * dm_test_update_mode_copies_pruned_edp - Test eDP copies the encoder's native mode
+ * @test: The KUnit test context
+ *
+ * With the native size pruned from base.modes, the preferred mode copy must be
+ * the panel's native mode, with its CRTC timing set, so that atomic_check
+ * still scales to it
+ */
+static void dm_test_update_mode_copies_pruned_edp(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector =
+		dm_test_copy_pruned(test, DRM_MODE_CONNECTOR_eDP, false);
+
+	KUNIT_EXPECT_EQ(test, (int)aconnector->preferred_mode.hdisplay, 3840);
+	KUNIT_EXPECT_EQ(test, (int)aconnector->preferred_mode.vdisplay, 2400);
+	KUNIT_EXPECT_EQ(test, aconnector->preferred_mode.clock, 592500);
+	KUNIT_EXPECT_EQ(test, aconnector->preferred_mode.crtc_clock, 592500);
+	KUNIT_EXPECT_EQ(test, (int)aconnector->preferred_mode.crtc_htotal, 4000);
+	KUNIT_EXPECT_EQ(test, (int)aconnector->freesync_vid_base.hdisplay, 3840);
+	KUNIT_EXPECT_EQ(test, aconnector->freesync_vid_base.clock, 592500);
+}
+
+/**
+ * dm_test_update_mode_copies_pruned_lvds - Test LVDS copies the encoder's native mode
+ * @test: The KUnit test context
+ */
+static void dm_test_update_mode_copies_pruned_lvds(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector =
+		dm_test_copy_pruned(test, DRM_MODE_CONNECTOR_LVDS, false);
+
+	KUNIT_EXPECT_EQ(test, (int)aconnector->preferred_mode.hdisplay, 3840);
+	KUNIT_EXPECT_EQ(test, aconnector->preferred_mode.clock, 592500);
+}
+
+/**
+ * dm_test_update_mode_copies_pruned_listed_edp - Test eDP copies a listed native size mode
+ * @test: The KUnit test context
+ *
+ * mode_valid may have rejected the encoder's native timing, so a mode of the
+ * native size left in base.modes must be copied in its place
+ */
+static void dm_test_update_mode_copies_pruned_listed_edp(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector =
+		dm_test_copy_pruned(test, DRM_MODE_CONNECTOR_eDP, true);
+
+	KUNIT_EXPECT_EQ(test, (int)aconnector->preferred_mode.hdisplay, 3840);
+	KUNIT_EXPECT_EQ(test, aconnector->preferred_mode.clock, 296250);
+}
+
+/**
+ * dm_test_update_mode_copies_pruned_hdmi - Test HDMI copies the first mode
+ * @test: The KUnit test context
+ */
+static void dm_test_update_mode_copies_pruned_hdmi(struct kunit *test)
+{
+	struct amdgpu_dm_connector *aconnector =
+		dm_test_copy_pruned(test, DRM_MODE_CONNECTOR_HDMIA, true);
+
+	KUNIT_EXPECT_EQ(test, (int)aconnector->preferred_mode.hdisplay, 1920);
+	KUNIT_EXPECT_EQ(test, (int)aconnector->preferred_mode.vdisplay, 1200);
+}
+
 /* Tests for amdgpu_dm_connector_detect() */
 
 /*
@@ -6332,6 +6830,8 @@ static void dm_test_add_fs_modes_generates(struct kunit *test)
 
 	KUNIT_EXPECT_EQ(test, count, 8);
 	KUNIT_EXPECT_EQ(test, duplicate_count, 0);
+	KUNIT_EXPECT_EQ(test, aconnector->probed_freesync_vid_base.clock, 148500);
+	KUNIT_EXPECT_EQ(test, aconnector->probed_freesync_vid_base.vtotal, 1125);
 }
 
 /**
@@ -6350,6 +6850,7 @@ static void dm_test_add_fs_modes_out_of_range(struct kunit *test)
 	aconnector->max_vfreq = 120;
 
 	KUNIT_EXPECT_EQ(test, (int)add_fs_modes(aconnector), 0);
+	KUNIT_EXPECT_EQ(test, aconnector->probed_freesync_vid_base.clock, 0);
 }
 
 /**
@@ -10576,6 +11077,17 @@ static struct kunit_case amdgpu_dm_connector_tests[] = {
 	KUNIT_CASE(dm_test_highest_refresh_writeback_null),
 	KUNIT_CASE(dm_test_highest_refresh_cached_base),
 	KUNIT_CASE(dm_test_highest_refresh_preferred_mode),
+	KUNIT_CASE(dm_test_highest_refresh_probed_skips_copy),
+	/* amdgpu_dm_connector_update_mode_copies */
+	KUNIT_CASE(dm_test_update_mode_copies_highest_refresh),
+	KUNIT_CASE(dm_test_update_mode_copies_no_preferred),
+	KUNIT_CASE(dm_test_update_mode_copies_records_edid),
+	KUNIT_CASE(dm_test_update_mode_copies_no_edid),
+	KUNIT_CASE(dm_test_update_mode_copies_empty),
+	KUNIT_CASE(dm_test_update_mode_copies_freesync_vid_base),
+	KUNIT_CASE(dm_test_update_mode_copies_freesync_vid_base_pruned),
+	/* amdgpu_dm_connector_fill_modes */
+	KUNIT_CASE(dm_test_fill_modes_copies_probe),
 	/* amdgpu_dm_is_freesync_video_mode */
 	KUNIT_CASE(dm_test_is_freesync_video_mode_null_mode),
 	KUNIT_CASE(dm_test_is_freesync_video_mode_match),
@@ -10664,6 +11176,10 @@ static struct kunit_case amdgpu_dm_connector_tests[] = {
 	KUNIT_CASE(dm_test_create_stream_native_preferred_edp),
 	KUNIT_CASE(dm_test_create_stream_native_mode_no_clock_edp),
 	KUNIT_CASE(dm_test_create_stream_native_mode_no_edid_edp),
+	KUNIT_CASE(dm_test_update_mode_copies_pruned_edp),
+	KUNIT_CASE(dm_test_update_mode_copies_pruned_lvds),
+	KUNIT_CASE(dm_test_update_mode_copies_pruned_listed_edp),
+	KUNIT_CASE(dm_test_update_mode_copies_pruned_hdmi),
 	/* amdgpu_dm_connector_detect */
 	KUNIT_CASE(dm_test_detect_force_on),
 	KUNIT_CASE(dm_test_detect_force_on_digital),

-- 
2.56.0

