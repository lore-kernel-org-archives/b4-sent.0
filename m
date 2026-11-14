From: Hugo Sales <hugo@hsal.es>
Date: Sat, 14 Nov 2026 23:09:14 +0000
Subject: [PATCH 3/8] drm/amd/display: Validate modes with their own timing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-amdgpu-modes-four-v1-3-f11e2a6cd407@hsal.es>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=24983; i=hugo@hsal.es;
 h=from:subject:message-id; bh=Rk90VzfmUI+RlSiWjUDEw/T3mxLoTo+bZU0iGnJSVuw=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsn68kniuyblLxOw5a9YeiyZtJXWTW9uVA1evOaqwL
 G4n68QvBxZ0lLIwiHExyIopsuje8GRgmTh5Zk7R8yUwc1iZQIYwcHEKwESSvRn+u71i1Q3Js0/p
 k738OClkwXnZe38WKoXbLrUXj3oWuHJ5H8NfecckdfnzTifEzVdfvWbq1WPMEvhS+WgC77L3z0/
 4iJgwAwC4vUfV
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

amdgpu_dm_connector_mode_valid() builds a stream through
create_stream_for_sink(), which takes the preferred mode from
connector->modes. During a probe that list still holds the previous
probe's modes, so after a monitor swap with no probe in between, as
across suspend or behind a KVM switch, mode_valid finds the old
monitor's preferred mode. With scaling on it validates that timing in
place of each mode's own, which can prune every mode of the new monitor
or pass modes its link can't carry. This probe's preferred mode won't do
either, since if it fails validation it prunes every other mode with it

Validate each mode with its own timing, as the first probe already does
on connectors other than eDP and LVDS. create_stream_for_sink() now
takes the preferred mode from its caller. atomic_check still looks it
up, with the eDP and LVDS fallback from
commit ab9e2cfa0e54 ("drm/amd/display: Fall back to the native mode, not
the first, on eDP/LVDS"), and mode_valid passes none

With scaling on, two kinds of mode get a different answer. A scaled
pairing that needs another encoding, such as one whose preferred timing
is YCbCr 4:2:0 only, now fails in atomic_check instead of being pruned
at probe time. A mode the link can carry only at the preferred mode's
timing, such as a smaller mode with a higher refresh rate, is now
pruned. Before, it passed and then ran at the preferred mode's refresh
rate. With scaling off, the same modes pass as before

Signed-off-by: Hugo Sales <hugo@hsal.es>
---
On eDP and LVDS with scaling off, the common modes amdgpu_dm adds differ
from the native mode only in their active area. They keep its pixel
clock and totals, so atomic_check drives them at the native timing.
mode_valid used to validate that timing and now validates their own, but
both need the same link bandwidth, so the same modes pass

With no preferred mode from mode_valid, the "No preferred mode found"
message no longer prints for every depth it tries. Writeback connectors,
which never used the preferred mode, stop looking it up

An upcoming patch makes the preferred mode lookup assert connection_mutex.
The early return on a missing state in
amdgpu_dm_create_validate_stream_for_sink() then also keeps that assert
away from callers without one

The @native_buf argument of amdgpu_dm_connector_preferred_mode() keeps
the eDP and LVDS fallback working until an upcoming patch has the
lookup return the copy taken after the probe, which already holds the
native mode. That patch drops the argument again
---
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.c    | 214 +++++++++++++--------
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.h    |   4 +
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c     | 120 +++++++++++-
 3 files changed, 249 insertions(+), 89 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
index da2ee6179cb67..e477ef61ce109 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
@@ -1052,6 +1052,62 @@ create_fake_sink(struct drm_device *dev, struct dc_link *link)
 	return sink;
 }
 
+/*
+ * After a probe with size limits smaller than the preferred mode, @modes no
+ * longer has that mode, and the first mode left would become the stream
+ * timing. fbdev emulation probes with limits that video= can set below the
+ * native size. Only eDP and LVDS panels get a fallback here, since they take
+ * only their native size. On other connectors mode_valid can also reject the
+ * preferred mode, and then the first valid mode is the right one
+ *
+ * Take a mode of the native size from @modes if one is left, since mode_valid
+ * may have rejected the preferred timing itself. The probe sorts the list, so
+ * the first one has the highest refresh rate left. If the limits pruned them
+ * all, fill @native_buf from the copy of the preferred mode that
+ * amdgpu_dm_get_native_mode() keeps in the encoder and refreshes on every
+ * probe, before the limits apply
+ *
+ * @native_buf: storage for the native mode when no mode of its size is left
+ * in @modes
+ *
+ * Returns a mode of the native size from @modes if there is one, otherwise
+ * @native_buf filled with the encoder's native mode, or NULL for other
+ * connectors or when the encoder has no native mode
+ */
+static const struct drm_display_mode *
+amdgpu_dm_panel_native_mode(struct drm_connector *connector, struct list_head *modes,
+			    struct drm_display_mode *native_buf)
+{
+	struct amdgpu_dm_connector *aconnector = to_amdgpu_dm_connector(connector);
+	const struct drm_display_mode *enc_native;
+	struct drm_encoder *encoder;
+	struct drm_display_mode *m;
+
+	if (!aconnector->drm_edid ||
+	    (connector->connector_type != DRM_MODE_CONNECTOR_eDP &&
+	     connector->connector_type != DRM_MODE_CONNECTOR_LVDS))
+		return NULL;
+
+	encoder = amdgpu_dm_connector_to_encoder(connector);
+	if (!encoder)
+		return NULL;
+
+	enc_native = &to_amdgpu_encoder(encoder)->native_mode;
+	if (!enc_native->clock)
+		return NULL;
+
+	list_for_each_entry(m, modes, head) {
+		if (m->hdisplay == enc_native->hdisplay &&
+		    m->vdisplay == enc_native->vdisplay)
+			return m;
+	}
+
+	drm_mode_init(native_buf, enc_native);
+	drm_mode_set_crtcinfo(native_buf, CRTC_INTERLACE_HALVE_V);
+
+	return native_buf;
+}
+
 /**
  * DOC: FreeSync Video
  *
@@ -1474,6 +1530,7 @@ EXPORT_IF_KUNIT(amdgpu_dm_update_stream_scaling_settings);
 STATIC_IFN_KUNIT struct dc_stream_state *
 create_stream_for_sink(struct drm_connector *connector,
 		       const struct drm_display_mode *drm_mode,
+		       const struct drm_display_mode *preferred_mode,
 		       const struct dm_connector_state *dm_state,
 		       const struct dc_stream_state *old_stream,
 		       int requested_bpc,
@@ -1482,8 +1539,6 @@ create_stream_for_sink(struct drm_connector *connector,
 {
 	struct drm_device *dev = connector->dev;
 	struct amdgpu_dm_connector *aconnector = NULL;
-	struct drm_display_mode *preferred_mode = NULL;
-	struct drm_display_mode *connector_mode;
 	const struct drm_connector_state *con_state = &dm_state->base;
 	struct dc_stream_state *stream = NULL;
 	struct drm_display_mode mode;
@@ -1539,75 +1594,9 @@ create_stream_for_sink(struct drm_connector *connector,
 	stream->timing.flags.LTE_340MCSC_SCRAMBLE =
 		connector->display_info.hdmi.scdc.scrambling.low_rates;
 
-	list_for_each_entry(connector_mode, &connector->modes, head) {
-		/* Search for preferred mode */
-		if (connector_mode->type & DRM_MODE_TYPE_PREFERRED) {
-			preferred_mode = connector_mode;
-			break;
-		}
-	}
-
-	/*
-	 * After a probe with size limits smaller than the preferred mode,
-	 * connector->modes no longer has that mode, and the first mode left
-	 * would become the stream timing. fbdev emulation probes with limits
-	 * that video= can set below the native size. Only eDP and LVDS panels
-	 * get a fallback here, since they take only their native size. On other
-	 * connectors mode_valid can also reject the preferred mode, and then
-	 * the first valid mode is the right one
-	 *
-	 * Take a mode of the native size from connector->modes if one is left,
-	 * since mode_valid may have rejected the preferred timing itself. The
-	 * probe sorts the list, so the first one has the highest refresh rate
-	 * left. If the limits pruned them all, use the copy of the preferred
-	 * mode that amdgpu_dm_get_native_mode() keeps in the encoder. It is
-	 * made on every probe, before the limits apply
-	 */
-	if (!preferred_mode && aconnector && aconnector->drm_edid &&
-	    (connector->connector_type == DRM_MODE_CONNECTOR_eDP ||
-	     connector->connector_type == DRM_MODE_CONNECTOR_LVDS)) {
-		struct drm_encoder *encoder = amdgpu_dm_connector_to_encoder(connector);
-		const struct drm_display_mode *enc_native =
-			encoder ? &to_amdgpu_encoder(encoder)->native_mode : NULL;
-
-		if (enc_native && enc_native->clock) {
-			list_for_each_entry(connector_mode, &connector->modes, head) {
-				if (connector_mode->hdisplay == enc_native->hdisplay &&
-				    connector_mode->vdisplay == enc_native->vdisplay) {
-					preferred_mode = connector_mode;
-					break;
-				}
-			}
-
-			/*
-			 * saved_mode is only used for FreeSync video modes, and
-			 * that path doesn't read preferred_mode
-			 */
-			if (!preferred_mode) {
-				drm_mode_init(&saved_mode, enc_native);
-				drm_mode_set_crtcinfo(&saved_mode, CRTC_INTERLACE_HALVE_V);
-				preferred_mode = &saved_mode;
-			}
-		}
-	}
-
-	if (!preferred_mode)
-		preferred_mode = list_first_entry_or_null(
-				&connector->modes,
-				struct drm_display_mode,
-				head);
-
 	mode_refresh = drm_mode_vrefresh(&mode);
 
-	if (preferred_mode == NULL) {
-		/*
-		 * This may not be an error, the use case is when we have no
-		 * usermode calls to reset and set mode upon hotplug. In this
-		 * case, we call set mode ourselves to restore the previous mode
-		 * and the modelist may not be filled in time.
-		 */
-		drm_dbg_driver(dev, "No preferred mode found\n");
-	} else if (aconnector) {
+	if (aconnector && preferred_mode) {
 		recalculate_timing = amdgpu_freesync_vid_mode &&
 				 amdgpu_dm_is_freesync_video_mode(&mode, aconnector);
 		if (recalculate_timing) {
@@ -2337,11 +2326,12 @@ dm_validate_stream_color_format(const struct drm_connector_state *drm_state,
 		DC_OK : DC_UNSUPPORTED_VALUE;
 }
 
-struct dc_stream_state *
-amdgpu_dm_create_validate_stream_for_sink(struct drm_connector *connector,
-					  const struct drm_display_mode *drm_mode,
-					  const struct dm_connector_state *dm_state,
-					  const struct dc_stream_state *old_stream)
+static struct dc_stream_state *
+__amdgpu_dm_create_validate_stream_for_sink(struct drm_connector *connector,
+					    const struct drm_display_mode *drm_mode,
+					    const struct drm_display_mode *preferred_mode,
+					    const struct dm_connector_state *dm_state,
+					    const struct dc_stream_state *old_stream)
 {
 	/*
 	 * Ordered lists of the encodings and bit depths we are willing to
@@ -2383,8 +2373,8 @@ amdgpu_dm_create_validate_stream_for_sink(struct drm_connector *connector,
 	 * meaningful for the writeback path).
 	 */
 	if (!aconnector) {
-		stream = create_stream_for_sink(connector, drm_mode, dm_state,
-						old_stream, requested_bpc,
+		stream = create_stream_for_sink(connector, drm_mode, preferred_mode,
+						dm_state, old_stream, requested_bpc,
 						PIXEL_ENCODING_RGB, is_hdmi_ep);
 		if (!stream)
 			drm_err(adev_to_drm(adev), "Failed to create stream for sink!\n");
@@ -2514,6 +2504,7 @@ amdgpu_dm_create_validate_stream_for_sink(struct drm_connector *connector,
 				    encoding_mask, bpc_mask, requested_bpc);
 
 			stream = create_stream_for_sink(connector, drm_mode,
+							preferred_mode,
 							dm_state, old_stream,
 							bpc, enc, is_hdmi_ep);
 			if (stream == NULL) {
@@ -2555,6 +2546,63 @@ amdgpu_dm_create_validate_stream_for_sink(struct drm_connector *connector,
 	 */
 	return NULL;
 }
+
+STATIC_IFN_KUNIT const struct drm_display_mode *
+amdgpu_dm_connector_preferred_mode(struct drm_connector *connector,
+				   struct drm_display_mode *native_buf)
+{
+	const struct drm_display_mode *mode;
+
+	if (connector->connector_type == DRM_MODE_CONNECTOR_WRITEBACK)
+		return NULL;
+
+	list_for_each_entry(mode, &connector->modes, head) {
+		if (mode->type & DRM_MODE_TYPE_PREFERRED)
+			return mode;
+	}
+
+	mode = amdgpu_dm_panel_native_mode(connector, &connector->modes, native_buf);
+	if (mode)
+		return mode;
+
+	mode = list_first_entry_or_null(&connector->modes,
+					struct drm_display_mode, head);
+	if (!mode) {
+		/*
+		 * This may not be an error, the use case is when we have no
+		 * usermode calls to reset and set mode upon hotplug. In this
+		 * case, we call set mode ourselves to restore the previous mode
+		 * and the modelist may not be filled in time
+		 */
+		drm_dbg_driver(connector->dev, "No preferred mode found\n");
+	}
+
+	return mode;
+}
+EXPORT_IF_KUNIT(amdgpu_dm_connector_preferred_mode);
+
+struct dc_stream_state *
+amdgpu_dm_create_validate_stream_for_sink(struct drm_connector *connector,
+					  const struct drm_display_mode *drm_mode,
+					  const struct dm_connector_state *dm_state,
+					  const struct dc_stream_state *old_stream)
+{
+	const struct drm_display_mode *preferred_mode;
+	struct drm_display_mode native_buf;
+
+	/*
+	 * __amdgpu_dm_create_validate_stream_for_sink() checks this as well,
+	 * but without a state there is no commit, so skip the preferred mode
+	 * lookup too
+	 */
+	if (!dm_state)
+		return NULL;
+
+	preferred_mode = amdgpu_dm_connector_preferred_mode(connector, &native_buf);
+	return __amdgpu_dm_create_validate_stream_for_sink(connector, drm_mode,
+							   preferred_mode, dm_state,
+							   old_stream);
+}
 EXPORT_IF_KUNIT(amdgpu_dm_create_validate_stream_for_sink);
 
 enum drm_mode_status amdgpu_dm_connector_mode_valid(struct drm_connector *connector,
@@ -2569,6 +2617,7 @@ enum drm_mode_status amdgpu_dm_connector_mode_valid(struct drm_connector *connec
 	 * here via the amdgpu_dm_connector_helper_funcs
 	 */
 	struct amdgpu_dm_connector *aconnector = to_amdgpu_dm_connector(connector);
+	struct dm_connector_state *dm_state = to_dm_connector_state(connector->state);
 
 	if ((mode->flags & DRM_MODE_FLAG_INTERLACE) ||
 			(mode->flags & DRM_MODE_FLAG_DBLSCAN))
@@ -2596,9 +2645,16 @@ enum drm_mode_status amdgpu_dm_connector_mode_valid(struct drm_connector *connec
 
 	drm_mode_set_crtcinfo(test_mode, 0);
 
-	stream = amdgpu_dm_create_validate_stream_for_sink(connector, test_mode,
-						 to_dm_connector_state(connector->state),
-						 NULL);
+	/*
+	 * During a probe connector->modes still holds the previous probe's
+	 * modes, possibly of another sink, and the probe knows its preferred
+	 * mode only once mode_valid has seen every mode. Validate each mode
+	 * with its own timing, even where atomic_check drives another one, the
+	 * preferred mode's with scaling on or the native one for eDP and LVDS
+	 * common modes
+	 */
+	stream = __amdgpu_dm_create_validate_stream_for_sink(connector, test_mode,
+							     NULL, dm_state, NULL);
 	drm_mode_destroy(connector->dev, test_mode);
 	if (stream) {
 		dc_stream_release(stream);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h
index 7bfbb68538335..e7ed9a0bf56fb 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.h
@@ -196,11 +196,15 @@ void fill_stream_properties_from_drm_display_mode(
 struct dc_stream_state *
 create_stream_for_sink(struct drm_connector *connector,
 		       const struct drm_display_mode *drm_mode,
+		       const struct drm_display_mode *preferred_mode,
 		       const struct dm_connector_state *dm_state,
 		       const struct dc_stream_state *old_stream,
 		       int requested_bpc,
 		       enum dc_pixel_encoding requested_encoding,
 		       bool is_hdmi_ep);
+const struct drm_display_mode *
+amdgpu_dm_connector_preferred_mode(struct drm_connector *connector,
+				   struct drm_display_mode *native_buf);
 enum drm_connector_status
 amdgpu_dm_connector_poll(struct amdgpu_dm_connector *aconnector, bool force);
 enum drm_connector_status
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
index 5af111698e355..e8cabe25a192d 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
@@ -4277,7 +4277,7 @@ static void dm_test_create_stream_fake_sink_success(struct kunit *test)
 	struct dc_stream_state *stream;
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					ctx->dm_state, NULL, 8,
+					NULL, ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
@@ -4294,7 +4294,7 @@ static void dm_test_create_stream_sets_dm_context(struct kunit *test)
 	struct dc_stream_state *stream;
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					ctx->dm_state, NULL, 8,
+					NULL, ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
@@ -4312,7 +4312,7 @@ static void dm_test_create_stream_virtual_signal(struct kunit *test)
 	struct dc_stream_state *stream;
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					ctx->dm_state, NULL, 8,
+					NULL, ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
@@ -4332,7 +4332,7 @@ static void dm_test_create_stream_scaling_src(struct kunit *test)
 	struct dc_stream_state *stream;
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					ctx->dm_state, NULL, 8,
+					NULL, ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
@@ -4364,7 +4364,7 @@ static void dm_test_create_stream_existing_sink(struct kunit *test)
 	ctx->aconnector->dc_sink = sink;
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					ctx->dm_state, NULL, 8,
+					NULL, ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
@@ -4431,6 +4431,8 @@ static void dm_test_create_stream_preferred_mode(struct kunit *test)
 	dm_test_stream_add_mode(test, ctx, DRM_MODE_TYPE_PREFERRED);
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
+					list_first_entry(&ctx->aconnector->base.modes,
+							 struct drm_display_mode, head),
 					ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
@@ -4459,6 +4461,8 @@ static void dm_test_create_stream_scaled_keeps_refresh(struct kunit *test)
 	ctx->dm_state->scaling = RMX_FULL;
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
+					list_first_entry(&ctx->aconnector->base.modes,
+							 struct drm_display_mode, head),
 					ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
@@ -4490,7 +4494,7 @@ static void dm_test_create_stream_timing_override(struct kunit *test)
 	ctx->aconnector->timing_requested = timing;
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					ctx->dm_state, NULL, 8,
+					NULL, ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
@@ -4519,7 +4523,7 @@ static void dm_test_create_stream_dp_vsc_colorimetry(struct kunit *test)
 	ctx->link->dpcd_caps.dprx_feature.bits.VSC_SDP_COLORIMETRY_SUPPORTED = 1;
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					ctx->dm_state, NULL, 8,
+					NULL, ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
@@ -4547,7 +4551,7 @@ static void dm_test_create_stream_dp_colorimetry_quirk(struct kunit *test)
 	ctx->link->dpcd_caps.dprx_feature.bits.VSC_SDP_COLORIMETRY_SUPPORTED = 1;
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					ctx->dm_state, NULL, 8,
+					NULL, ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
@@ -4574,7 +4578,7 @@ static void dm_test_create_stream_hdmi_vsif(struct kunit *test)
 	sink = dm_test_stream_add_sink(test, ctx, SIGNAL_TYPE_HDMI_TYPE_A);
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
-					ctx->dm_state, NULL, 8,
+					NULL, ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
@@ -4609,8 +4613,8 @@ dm_test_native_mode_stream(struct kunit *test, int connector_type, unsigned int
 	static const u8 edid[EDID_LENGTH];
 	struct dm_test_stream_ctx *ctx = dm_test_stream_ctx_alloc_type(test, connector_type);
 	struct amdgpu_encoder *aenc;
+	struct drm_display_mode *native, native_buf;
 	struct dc_stream_state *stream;
-	struct drm_display_mode *native;
 
 	aenc = drmm_kzalloc(ctx->drm, sizeof(*aenc), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, aenc);
@@ -4659,6 +4663,8 @@ dm_test_native_mode_stream(struct kunit *test, int connector_type, unsigned int
 	}
 
 	stream = create_stream_for_sink(&ctx->aconnector->base, ctx->mode,
+					amdgpu_dm_connector_preferred_mode(&ctx->aconnector->base,
+									   &native_buf),
 					ctx->dm_state, NULL, 8,
 					PIXEL_ENCODING_RGB, false);
 
@@ -7479,6 +7485,98 @@ static void dm_test_create_validate_stream_hdmi_rgb_first(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, (int)dm_test_cvs_first_encoding, (int)PIXEL_ENCODING_RGB);
 }
 
+static u32 dm_test_cvs_first_h_addressable;
+
+static bool dm_test_cvs_record_first_h_addressable(struct timing_generator *tg,
+						   const struct dc_crtc_timing *timing)
+{
+	if (!dm_test_cvs_first_h_addressable)
+		dm_test_cvs_first_h_addressable = timing->h_addressable;
+
+	return false;
+}
+
+/*
+ * A 3840x2160 preferred mode in connector->modes, as a probe of another sink
+ * leaves it until the next probe prunes it
+ */
+static void dm_test_cvs_add_preferred_4k(struct kunit *test, struct dm_test_cvs_dc *c)
+{
+	struct drm_display_mode *pref = drm_mode_create(c->drm);
+
+	KUNIT_ASSERT_NOT_NULL(test, pref);
+	pref->hdisplay = 3840;
+	pref->hsync_start = 4016;
+	pref->hsync_end = 4104;
+	pref->htotal = 4400;
+	pref->vdisplay = 2160;
+	pref->vsync_start = 2168;
+	pref->vsync_end = 2178;
+	pref->vtotal = 2250;
+	pref->clock = 594000;
+	pref->type = DRM_MODE_TYPE_PREFERRED;
+	drm_mode_set_crtcinfo(pref, CRTC_INTERLACE_HALVE_V);
+	list_add_tail(&pref->head, &c->aconnector->base.modes);
+}
+
+/**
+ * dm_test_create_validate_stream_scaled_preferred - Test atomic_check scales to the preferred mode
+ * @test: The KUnit test context
+ *
+ * With scaling on, the stream for a 1920x1080 mode takes the CRTC timing of
+ * the preferred mode in connector->modes
+ */
+static void dm_test_create_validate_stream_scaled_preferred(struct kunit *test)
+{
+	struct dm_test_cvs_dc *c = dm_test_cvs_dc_alloc(test);
+
+	c->dm_state->scaling = RMX_FULL;
+	dm_test_cvs_add_preferred_4k(test, c);
+	c->tgfuncs->validate_timing = dm_test_cvs_record_first_h_addressable;
+	dm_test_cvs_first_h_addressable = 0;
+
+	KUNIT_EXPECT_NULL(test,
+			  amdgpu_dm_create_validate_stream_for_sink(&c->aconnector->base,
+								    c->mode,
+								    c->dm_state,
+								    NULL));
+	KUNIT_EXPECT_EQ(test, dm_test_cvs_first_h_addressable, 3840);
+}
+
+/**
+ * dm_test_mode_valid_ignores_preferred_mode - Test mode_valid uses the mode's own timing
+ * @test: The KUnit test context
+ *
+ * During a probe connector->modes still holds the previous sink's preferred
+ * mode. Even with scaling on, the mode is validated with its own 1920x1080
+ * timing rather than that mode's 3840x2160 one
+ */
+static void dm_test_mode_valid_ignores_preferred_mode(struct kunit *test)
+{
+	struct dm_test_cvs_dc *c = dm_test_cvs_dc_alloc(test);
+	struct dc_sink *em_sink;
+
+	em_sink = kunit_kzalloc(test, sizeof(*em_sink), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, em_sink);
+	c->aconnector->dc_em_sink = em_sink;
+	c->aconnector->base.force = DRM_FORCE_ON;
+
+	/* drm_connector_cleanup() kfree()s connector->state */
+	KUNIT_ASSERT_NULL(test, c->aconnector->base.state);
+	amdgpu_dm_connector_funcs_reset(&c->aconnector->base);
+	KUNIT_ASSERT_NOT_NULL(test, c->aconnector->base.state);
+	to_dm_connector_state(c->aconnector->base.state)->scaling = RMX_FULL;
+
+	dm_test_cvs_add_preferred_4k(test, c);
+	c->tgfuncs->validate_timing = dm_test_cvs_record_first_h_addressable;
+	dm_test_cvs_first_h_addressable = 0;
+
+	KUNIT_EXPECT_EQ(test,
+			amdgpu_dm_connector_mode_valid(&c->aconnector->base, c->mode),
+			MODE_ERROR);
+	KUNIT_EXPECT_EQ(test, dm_test_cvs_first_h_addressable, 1920);
+}
+
 /* Further tests for amdgpu_dm_connector_mode_valid() */
 
 /**
@@ -10695,6 +10793,8 @@ static struct kunit_case amdgpu_dm_connector_tests[] = {
 	KUNIT_CASE(dm_test_create_validate_stream_prune_timing),
 	KUNIT_CASE(dm_test_create_validate_stream_prune_context),
 	KUNIT_CASE(dm_test_create_validate_stream_hdmi_rgb_first),
+	KUNIT_CASE(dm_test_create_validate_stream_scaled_preferred),
+	KUNIT_CASE(dm_test_mode_valid_ignores_preferred_mode),
 	/* amdgpu_dm_update_connector_after_detect */
 	KUNIT_CASE(dm_test_update_after_detect_mst_noop),
 	KUNIT_CASE(dm_test_update_after_detect_sink_unchanged),

-- 
2.56.0

