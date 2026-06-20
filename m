From: Stephen <stevester.codes@gmail.com>
Date: Sat, 20 Jun 2026 10:06:19 -0600
Subject: [PATCH RFC 1/3] drm/amd/display: quirk malformed CH7218 PCON
 topology
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260620-ch7218-rfc-v1-b4-v1-1-3412debf44b6@gmail.com>
To: amd-gfx@lists.freedesktop.org
Cc: Stephen <stevester.codes@gmail.com>, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Harry Wentland <harry.wentland@amd.com>, 
 Leo Li <sunpeng.li@amd.com>, Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 =?utf-8?q?Tomasz_Paku=C5=82a?= <tomasz.pakula.oficjalny@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781971578; l=4344;
 i=stevester.codes@gmail.com; s=ch7218-rfc; h=from:subject:message-id;
 bh=jeGNZJ9+o/AHn9lk6MUcdhMGJQEt2lPQ9MdS1Ws/0rk=;
 b=ashBtRxYlhnhRo1J1cKCvKoDCNUKcm/GSSLJzVdHb0bTs2DEyf8TDex8vsyJXd5N4KMWxP1OL
 IMbTk2tOT6JCeix/HJpj0hJLXBKtOSpBd8QJr+OkHiR3Cf1Qn1yfzvD
X-Developer-Key: i=stevester.codes@gmail.com; a=ed25519;
 pk=3Y74rGwtdwPNG9fzfw+7DSf/KWLeW8BsYVkyhPcx5pY=
X-Endpoint-Received: by B4 Relay for stevester.codes@gmail.com/ch7218-rfc with auth_id=834
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some Chrontel CH7218 DP-to-HDMI 2.1 adapters expose a branch
device ID of 0x2b02f0 and branch name CH7218, but report no
downstream port at DPCD 0x005 and report the detailed downstream
port at 0x080 as DP.

This leaves AMDGPU treating the link as non-HDMI and bypasses the
PCON capability path.

When this malformed runtime state is detected, classify the link as a
DP-HDMI converter and restore the documented converter ceilings needed
by the existing PCON path: 12 bpc, 48 Gbps FRL, and YCbCr passthrough
capability. This does not program the PCON or synthesize source-control
FRL state.

Signed-off-by: Stephen <stevester.codes@gmail.com>
---
 .../display/dc/link/protocols/link_dp_capability.c | 47 ++++++++++++++++++++--
 .../drm/amd/display/include/ddc_service_types.h    |  1 +
 2 files changed, 45 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c
index 47abb4066709..c2b48abfe7e6 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c
@@ -1158,6 +1158,31 @@ static void read_and_intersect_post_frl_lt_status(
 	}
 }
 
+static bool is_ch7218_pcon(const struct dc_link *link)
+{
+	return link->dpcd_caps.branch_dev_id == DP_BRANCH_DEVICE_ID_2B02F0 &&
+		!memcmp(link->dpcd_caps.branch_dev_name, "CH7218",
+			sizeof(link->dpcd_caps.branch_dev_name));
+}
+
+static void apply_ch7218_pcon_caps_quirk(struct dc_link *link)
+{
+	if (!link->dc->caps.dp_hdmi21_pcon_support)
+		return;
+
+	/*
+	 * Some CH7218 firmware reports no downstream port, or reports the
+	 * detailed downstream port as DP, while the device identity and EDID
+	 * describe a DP-to-HDMI 2.1 PCON. Restore only the documented converter
+	 * capability ceilings here; do not touch the PCON link state.
+	 */
+	link->dpcd_caps.dongle_caps.dp_hdmi_max_bpc = 12;
+	link->dpcd_caps.dongle_caps.dp_hdmi_frl_max_link_bw_in_kbps = 48000000;
+	link->dpcd_caps.dongle_caps.is_dp_hdmi_ycbcr422_pass_through = true;
+	link->dpcd_caps.dongle_caps.is_dp_hdmi_ycbcr420_pass_through = true;
+	link->dpcd_caps.dongle_caps.extendedCapValid = true;
+}
+
 static void get_active_converter_info(
 	uint8_t data, struct dc_link *link)
 {
@@ -1166,10 +1191,19 @@ static void get_active_converter_info(
 
 	/* decode converter info*/
 	if (!ds_port.fields.PORT_PRESENT) {
-		link->dpcd_caps.dongle_type = DISPLAY_DONGLE_NONE;
+		if (is_ch7218_pcon(link)) {
+			link->dpcd_caps.is_branch_dev = true;
+			link->dpcd_caps.dongle_type =
+				DISPLAY_DONGLE_DP_HDMI_CONVERTER;
+			link->dpcd_caps.dongle_caps.dongle_type =
+				link->dpcd_caps.dongle_type;
+			apply_ch7218_pcon_caps_quirk(link);
+		} else {
+			link->dpcd_caps.dongle_type = DISPLAY_DONGLE_NONE;
+			link->dpcd_caps.is_branch_dev = false;
+		}
 		set_dongle_type(link->ddc,
 				link->dpcd_caps.dongle_type);
-		link->dpcd_caps.is_branch_dev = false;
 		return;
 	}
 
@@ -1200,7 +1234,14 @@ static void get_active_converter_info(
 			switch (port_caps->bits.DWN_STRM_PORTX_TYPE) {
 			/*Handle DP case as DONGLE_NONE*/
 			case DOWN_STREAM_DETAILED_DP:
-				link->dpcd_caps.dongle_type = DISPLAY_DONGLE_NONE;
+				link->dpcd_caps.dongle_type = is_ch7218_pcon(link) ?
+					DISPLAY_DONGLE_DP_HDMI_CONVERTER :
+					DISPLAY_DONGLE_NONE;
+				link->dpcd_caps.dongle_caps.dongle_type =
+					link->dpcd_caps.dongle_type;
+				if (link->dpcd_caps.dongle_type ==
+						DISPLAY_DONGLE_DP_HDMI_CONVERTER)
+					apply_ch7218_pcon_caps_quirk(link);
 				break;
 			case DOWN_STREAM_DETAILED_VGA:
 				link->dpcd_caps.dongle_type =
diff --git a/drivers/gpu/drm/amd/display/include/ddc_service_types.h b/drivers/gpu/drm/amd/display/include/ddc_service_types.h
index 53210e3aa0e0..4164f8a5ae56 100644
--- a/drivers/gpu/drm/amd/display/include/ddc_service_types.h
+++ b/drivers/gpu/drm/amd/display/include/ddc_service_types.h
@@ -37,6 +37,7 @@
 #define DP_BRANCH_DEVICE_ID_001CF8 0x001CF8
 #define DP_BRANCH_DEVICE_ID_0060AD 0x0060AD
 #define DP_BRANCH_DEVICE_ID_001FF2 0x001FF2
+#define DP_BRANCH_DEVICE_ID_2B02F0 0x2B02F0
 #define DP_BRANCH_HW_REV_10 0x10
 #define DP_BRANCH_HW_REV_20 0x20
 

-- 
2.54.0

