From: Stephen <stevester.codes@gmail.com>
Date: Sat, 20 Jun 2026 10:06:21 -0600
Subject: [PATCH RFC 3/3] drm/amd/display: use HDMI RGB deep color for PCONs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260620-ch7218-rfc-v1-b4-v1-3-3412debf44b6@gmail.com>
To: amd-gfx@lists.freedesktop.org
Cc: Stephen <stevester.codes@gmail.com>, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Harry Wentland <harry.wentland@amd.com>, 
 Leo Li <sunpeng.li@amd.com>, Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 =?utf-8?q?Tomasz_Paku=C5=82a?= <tomasz.pakula.oficjalny@gmail.com>
References: <20260620-ch7218-rfc-v1-b4-v1-1-3412debf44b6@gmail.com>
In-Reply-To: <20260620-ch7218-rfc-v1-b4-v1-1-3412debf44b6@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781971578; l=4269;
 i=stevester.codes@gmail.com; s=ch7218-rfc; h=from:subject:message-id;
 bh=U409nPgAq2LHqdJTGL6nxmnc+OvZgy/z3WvXz6cKcNA=;
 b=kdMvKSD0HIGgxsrc/zR8mbLTXIX9+Sx+Hv9xQZgZt5FVy89xm9Pg556o79gN5i9ti6usHaY8n
 Jrt+bEH0PUdCSMBCgSlSrvYaFdwllrV4pBNoX4HXrt+bafd0kMpXyVF
X-Developer-Key: i=stevester.codes@gmail.com; a=ed25519;
 pk=3Y74rGwtdwPNG9fzfw+7DSf/KWLeW8BsYVkyhPcx5pY=
X-Endpoint-Received: by B4 Relay for stevester.codes@gmail.com/ch7218-rfc with auth_id=834
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DP-to-HDMI PCON connectors are exposed to DRM as DP connectors, but the
downstream sink capability for RGB deep color is carried in the HDMI CTA
deep-color flags. If AMDGPU only uses the base EDID bpc field for RGB
output, HDMI sinks behind PCONs can be capped at 8 bpc even when the CTA
block advertises RGB 10/12 bpc support.

For RGB output through a recognized DP-HDMI converter, derive the
candidate bpc from edid_hdmi_rgb444_dc_modes before applying the
requested max bpc cap. Keep YCbCr420 on the existing y420 deep-color
path and leave native DP behavior unchanged.

Signed-off-by: Stephen <stevester.codes@gmail.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c | 41 ++++++++++++++++++-----
 1 file changed, 33 insertions(+), 8 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index 8f80420e9f0b..3b814b839ddf 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -6769,22 +6769,44 @@ static void update_stream_scaling_settings(struct drm_device *dev,
 
 static enum dc_color_depth
 convert_color_depth_from_display_info(const struct drm_connector *connector,
-				      bool is_y420, int requested_bpc)
+				      enum dc_pixel_encoding pixel_encoding,
+				      int requested_bpc)
 {
+	const struct drm_display_info *info = &connector->display_info;
+	bool is_hdmi_pcon = false;
 	u8 bpc;
 
-	if (is_y420) {
+	if (connector->connector_type != DRM_MODE_CONNECTOR_WRITEBACK) {
+		const struct amdgpu_dm_connector *aconnector =
+			to_amdgpu_dm_connector(connector);
+
+		is_hdmi_pcon = aconnector->dc_link &&
+			aconnector->dc_link->dpcd_caps.dongle_type ==
+			DISPLAY_DONGLE_DP_HDMI_CONVERTER;
+	}
+
+	if (pixel_encoding == PIXEL_ENCODING_YCBCR420) {
 		bpc = 8;
 
 		/* Cap display bpc based on HDMI 2.0 HF-VSDB */
-		if (connector->display_info.hdmi.y420_dc_modes & DRM_EDID_YCBCR420_DC_48)
+		if (info->hdmi.y420_dc_modes & DRM_EDID_YCBCR420_DC_48)
+			bpc = 16;
+		else if (info->hdmi.y420_dc_modes & DRM_EDID_YCBCR420_DC_36)
+			bpc = 12;
+		else if (info->hdmi.y420_dc_modes & DRM_EDID_YCBCR420_DC_30)
+			bpc = 10;
+	} else if (pixel_encoding == PIXEL_ENCODING_RGB && is_hdmi_pcon) {
+		bpc = 8;
+
+		/* The downstream sink is HDMI even though DRM exposes DP. */
+		if (info->edid_hdmi_rgb444_dc_modes & DRM_EDID_HDMI_DC_48)
 			bpc = 16;
-		else if (connector->display_info.hdmi.y420_dc_modes & DRM_EDID_YCBCR420_DC_36)
+		else if (info->edid_hdmi_rgb444_dc_modes & DRM_EDID_HDMI_DC_36)
 			bpc = 12;
-		else if (connector->display_info.hdmi.y420_dc_modes & DRM_EDID_YCBCR420_DC_30)
+		else if (info->edid_hdmi_rgb444_dc_modes & DRM_EDID_HDMI_DC_30)
 			bpc = 10;
 	} else {
-		bpc = (uint8_t)connector->display_info.bpc;
+		bpc = (uint8_t)info->bpc;
 		/* Assume 8 bpc by default if no bpc is specified. */
 		bpc = bpc ? bpc : 8;
 	}
@@ -7004,7 +7026,7 @@ static void fill_stream_properties_from_drm_display_mode(
 	timing_out->timing_3d_format = TIMING_3D_FORMAT_NONE;
 	timing_out->display_color_depth = convert_color_depth_from_display_info(
 		connector,
-		(timing_out->pixel_encoding == PIXEL_ENCODING_YCBCR420),
+		timing_out->pixel_encoding,
 		requested_bpc);
 	timing_out->scan_type = SCANNING_TYPE_NODATA;
 	timing_out->hdmi_vic = 0;
@@ -8761,6 +8783,7 @@ static int dm_encoder_helper_atomic_check(struct drm_encoder *encoder,
 	struct drm_dp_mst_port *mst_port;
 	struct drm_dp_mst_topology_state *mst_state;
 	enum dc_color_depth color_depth;
+	enum dc_pixel_encoding pixel_encoding = PIXEL_ENCODING_RGB;
 	int clock, bpp = 0;
 	bool is_y420 = false;
 
@@ -8801,8 +8824,10 @@ static int dm_encoder_helper_atomic_check(struct drm_encoder *encoder,
 
 		is_y420 = drm_mode_is_420_also(&connector->display_info, adjusted_mode) &&
 			  aconnector->force_yuv420_output;
+		if (is_y420)
+			pixel_encoding = PIXEL_ENCODING_YCBCR420;
 		color_depth = convert_color_depth_from_display_info(connector,
-								    is_y420,
+								    pixel_encoding,
 								    max_bpc);
 		bpp = convert_dc_color_depth_into_bpc(color_depth) * 3;
 		clock = adjusted_mode->clock;

-- 
2.54.0

