From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 10:07:04 +0000
Subject: [PATCH] drm/edid: Add the modes of CTA Type VII video timing data
 blocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-edid-t7vtdb-v1-1-d6b8229d2041@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDXRCm1dRSxoB2OBtCUS6d0Vy
 7f4/waPjtBDk93g8CRP25rA8wzM3K8TMrLJIApRc841Q0uWBXkGO7BKKCVNqVUhBaRidzjS9d3
 a7rc/hgVNeBcQ4wNN8JaHbwAAAA==
X-Change-ID: 20261119-edid-t7vtdb-52887c398072
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jani Nikula <jani.nikula@linux.intel.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795082823; l=3314;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=ScVtHOJIDgPl4/O/zIOpx/r4EUsECXNNFCTxoFJH0aM=;
 b=0P6zzqbJo5NuJRTPk89GnQsec3NRNlPrNNgLUOrRKeu3N5oa3HbD4o3/o7LvNytREOD5g8bf6
 v3gigHSBGaWCrzJ5OmZya3++7pxgbh/Jgh+m4jAvYXwpf69Fratuv3z
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CTA-861-H lets a CTA extension carry DisplayID Type VII timings (T7VTDB,
extended tag 0x22). HDMI 2.1 TVs list modes such as 3840x2160@144Hz
there, but only Type VII timings in DisplayID extensions are parsed, so
these modes are missing. Add them. In a T7VTDB bit 7 of the timing
flags means YCbCr 4:2:0 support instead of preferred timing, so these
modes are never marked preferred. The 4:2:0 flag is not used, as 4:2:0
capable modes are tracked by VIC.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi 5 (RK3588S, 7.3-based kernel): the three T7VTDB
timings of an HDMI 2.1 TV are listed. With an EDID override adding a
T7VTDB timing with bit 7 set, the mode is listed and not preferred.

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed every change.
---
 drivers/gpu/drm/drm_edid.c | 34 ++++++++++++++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/drivers/gpu/drm/drm_edid.c b/drivers/gpu/drm/drm_edid.c
index b8f882a17c8f..ff47b34d4efb 100644
--- a/drivers/gpu/drm/drm_edid.c
+++ b/drivers/gpu/drm/drm_edid.c
@@ -4215,6 +4215,7 @@ static int add_detailed_modes(struct drm_connector *connector,
 #define CTA_EXT_DB_HDR_STATIC_METADATA	6
 #define CTA_EXT_DB_420_VIDEO_DATA	14
 #define CTA_EXT_DB_420_VIDEO_CAP_MAP	15
+#define CTA_EXT_DB_T7VTDB		0x22
 #define CTA_EXT_DB_HF_EEODB		0x78
 #define CTA_EXT_DB_HF_SCDB		0x79
 
@@ -7206,6 +7207,38 @@ static int add_displayid_detailed_modes(struct drm_connector *connector,
 	return num_modes;
 }
 
+/* CTA-861-H T7VTDB: a revision byte, then one DisplayID Type VII timing */
+static int add_cta_t7vtdb_modes(struct drm_connector *connector,
+				const struct drm_edid *drm_edid)
+{
+	const struct displayid_detailed_timings_1 *timings;
+	struct drm_display_mode *newmode;
+	const struct cea_db *db;
+	struct cea_db_iter iter;
+	int num_modes = 0;
+
+	cea_db_iter_edid_begin(drm_edid, &iter);
+	cea_db_iter_for_each(db, &iter) {
+		if (!cea_db_is_extended_tag(db, CTA_EXT_DB_T7VTDB) ||
+		    cea_db_payload_len(db) < 2 + sizeof(*timings))
+			continue;
+
+		timings = (const void *)(cea_db_data(db) + 2);
+		newmode = drm_mode_displayid_detailed(connector->dev, timings, true);
+		if (!newmode)
+			continue;
+
+		/* Bit 7 of the flags is YCbCr 4:2:0 support here, not preferred */
+		newmode->type &= ~DRM_MODE_TYPE_PREFERRED;
+
+		drm_mode_probed_add(connector, newmode);
+		num_modes++;
+	}
+	cea_db_iter_end(&iter);
+
+	return num_modes;
+}
+
 static int _drm_edid_connector_add_modes(struct drm_connector *connector,
 					 const struct drm_edid *drm_edid)
 {
@@ -7235,6 +7268,7 @@ static int _drm_edid_connector_add_modes(struct drm_connector *connector,
 	num_modes += add_cea_modes(connector, drm_edid);
 	num_modes += add_alternate_cea_modes(connector, drm_edid);
 	num_modes += add_displayid_detailed_modes(connector, drm_edid);
+	num_modes += add_cta_t7vtdb_modes(connector, drm_edid);
 	if (drm_edid->edid->features & DRM_EDID_FEATURE_CONTINUOUS_FREQ)
 		num_modes += add_inferred_modes(connector, drm_edid);
 

---
base-commit: fac7a5f16230779cfb0d50ca49e9467cc94a2ea9
change-id: 20261119-edid-t7vtdb-52887c398072

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

