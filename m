From: Stephen <stevester.codes@gmail.com>
Date: Sat, 20 Jun 2026 10:06:20 -0600
Subject: [PATCH RFC 2/3] drm/amd/display: quirk CH7218 DP DSC support bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260620-ch7218-rfc-v1-b4-v1-2-3412debf44b6@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781971578; l=2578;
 i=stevester.codes@gmail.com; s=ch7218-rfc; h=from:subject:message-id;
 bh=Wc9ztP52gNTYdJ4wsmOM8HQQjA0R6jvwruxjJM/wHLQ=;
 b=3Jkb/AMcaFdC1OEyapnfvht+r4QwOtzefWW3+l4LHe978HIZxHkJjlptDjog0QkBQ66v1m8ae
 S9EbYCQLM6aCqJj2w9CKI9TLeBspAEP9/7ToLIIYdGfX1A2/cYXK01O
X-Developer-Key: i=stevester.codes@gmail.com; a=ed25519;
 pk=3Y74rGwtdwPNG9fzfw+7DSf/KWLeW8BsYVkyhPcx5pY=
X-Endpoint-Received: by B4 Relay for stevester.codes@gmail.com/ch7218-rfc with auth_id=834
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some CH7218 firmware clears DP_DSC_SUPPORT at DPCD 0x060 while
returning a populated DSC decoder capability block. Without the support
bit, AMDGPU rejects DSC on the DP side and cannot validate high-bandwidth
RGB modes that require DSC over the DP link.

For the malformed CH7218 PCON only, set the DSC support bit after
verifying that the DSC capability block contains non-zero decoder data.
Do not infer DSC support for other devices and do not synthesize DSC
passthrough support.

Signed-off-by: Stephen <stevester.codes@gmail.com>
---
 .../display/dc/link/protocols/link_dp_capability.c   | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c
index c2b48abfe7e6..ad4fb94281a8 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c
@@ -1183,6 +1183,25 @@ static void apply_ch7218_pcon_caps_quirk(struct dc_link *link)
 	link->dpcd_caps.dongle_caps.extendedCapValid = true;
 }
 
+static void apply_ch7218_dsc_caps_quirk(struct dc_link *link)
+{
+	struct dpcd_dsc_capabilities *dsc_caps = &link->dpcd_caps.dsc_caps;
+
+	if (!is_ch7218_pcon(link) ||
+	    dsc_caps->dsc_basic_caps.fields.dsc_support.DSC_SUPPORT ||
+	    (!dsc_caps->dsc_basic_caps.raw[DP_DSC_REV - DP_DSC_SUPPORT] &&
+	     !dsc_caps->dsc_basic_caps.raw[DP_DSC_SLICE_CAP_1 - DP_DSC_SUPPORT] &&
+	     !dsc_caps->dsc_basic_caps.raw[DP_DSC_MAX_BITS_PER_PIXEL_LOW - DP_DSC_SUPPORT]))
+		return;
+
+	/*
+	 * Some CH7218 firmware clears DP_DSC_SUPPORT while returning a populated
+	 * DSC decoder capability block. Do not infer DSC support for other
+	 * devices and do not enable DSC passthrough here.
+	 */
+	dsc_caps->dsc_basic_caps.fields.dsc_support.DSC_SUPPORT = true;
+}
+
 static void get_active_converter_info(
 	uint8_t data, struct dc_link *link)
 {
@@ -2068,6 +2087,7 @@ static bool retrieve_link_cap(struct dc_link *link)
 				link->dpcd_caps.dsc_caps.dsc_basic_caps.raw,
 				sizeof(link->dpcd_caps.dsc_caps.dsc_basic_caps.raw));
 		if (status == DC_OK) {
+			apply_ch7218_dsc_caps_quirk(link);
 			is_fec_supported = link->dpcd_caps.fec_cap.bits.FEC_CAPABLE;
 			is_dsc_basic_supported = link->dpcd_caps.dsc_caps.dsc_basic_caps.fields.dsc_support.DSC_SUPPORT;
 			is_dsc_passthrough_supported = link->dpcd_caps.dsc_caps.dsc_basic_caps.fields.dsc_support.DSC_PASSTHROUGH_SUPPORT;

-- 
2.54.0

