From: Jameson Pair <jkpair@gmail.com>
Date: Thu, 12 Nov 2026 14:46:05 -0600
Subject: [PATCH] drm/amd/display: Add ASUS ROG Bulwark DG310 PCON to
 FreeSync allowlist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-dg310-pcon-vrr-v1-1-4888b7097218@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMwQ6CMAwA0F9peqYJrejifsVwwNFhPQzSKSEh/
 LtRj+/ydqzqphUj7Oi6WrW5YARuANNjKJOSjRgBpZULMwuN04lbWtJcaHWnTsI1hKE7S87YAC6
 u2bZfeOv/ru/7U9Pru+BxfAAxIWJ2cgAAAA==
X-Change-ID: 20261112-dg310-pcon-vrr-427977a452ff
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 amd-gfx@lists.freedesktop.org
Cc: Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 Antheas Kapenekakis <lkml@antheas.dev>, Jameson Pair <jkpair@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794516392; l=2493;
 i=jkpair@gmail.com; s=20261112; h=from:subject:message-id;
 bh=IaHtGZwdEM/yO/9DxMrgKbM58p1r4Zl9A8RjAoZx16k=;
 b=iowwwB+Cy2pUmh2L/LEBmRWRiZaCMSqauWHoCFrUBz2dTP8vuv6NwHxqu0KaHbiPcq78BpOqg
 8gjvHU7Q9eoDNOIGWxjdW1NiOLKfbLLpz9TFlDgJwU8/iFwP2X4tTmu
X-Developer-Key: i=jkpair@gmail.com; a=ed25519;
 pk=GeD1yXy+BumOgxcXosI+5+L+1j8T0KNZzjWrBe1gnqQ=
X-Endpoint-Received: by B4 Relay for jkpair@gmail.com/20261112 with auth_id=1504
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ASUS ROG Bulwark DG310 dock exposes its HDMI 2.1 output through a
DP-to-HDMI PCON with branch OUI bc:be:fb. The PCON sets
MSA_TIMING_PAR_IGNORED and ADAPTIVE_SYNC_SDP_SUPPORTED, but it is not in
dm_freesync_pcon_whitelist[], so FreeSync is never enabled on sinks
behind it.

Branch DPCD 0x500-0x50b: bc be fb fb 48 44 4d 49 62 01 40 84
(device id "\xfbHDMIb", hw rev 0x01, fw rev 0x40 0x84)

Tested on an ASUS ROG Xbox Ally X20 -> DG310 -> Samsung S90F (AMD VSDB
v3, 48-144 Hz) with a 7.3-based kernel that also finds the AMD VSDB in
every CTA extension, as the common EDID parser does since commit
ac10a874fc8a ("drm/edid: Parse AMD VSDB for FreeSync refresh range").
With this change VRR is reported capable and works; without it the
connector stays VRR-incapable.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Jameson Pair <jkpair@gmail.com>
---
One-line allowlist addition for the DP-to-HDMI PCON in the ASUS ROG
Bulwark DG310 dock, so FreeSync works on HDMI sinks behind it.
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c | 1 +
 drivers/gpu/drm/amd/display/include/ddc_service_types.h   | 1 +
 2 files changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
index 3067ac5bb0cd..0c0d7b850c04 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
@@ -1712,6 +1712,7 @@ STATIC_IFN_KUNIT const uint32_t dm_freesync_pcon_whitelist[] = {
 	DP_BRANCH_DEVICE_ID_90CC24,
 	DP_BRANCH_DEVICE_ID_001CF8,
 	DP_BRANCH_DEVICE_ID_001FF2,
+	DP_BRANCH_DEVICE_ID_BCBEFB,
 };
 EXPORT_IF_KUNIT(dm_freesync_pcon_whitelist);
 
diff --git a/drivers/gpu/drm/amd/display/include/ddc_service_types.h b/drivers/gpu/drm/amd/display/include/ddc_service_types.h
index 827e9bd7c5cf..dafecbd606a5 100644
--- a/drivers/gpu/drm/amd/display/include/ddc_service_types.h
+++ b/drivers/gpu/drm/amd/display/include/ddc_service_types.h
@@ -37,6 +37,7 @@
 #define DP_BRANCH_DEVICE_ID_001CF8 0x001CF8
 #define DP_BRANCH_DEVICE_ID_0060AD 0x0060AD
 #define DP_BRANCH_DEVICE_ID_001FF2 0x001FF2
+#define DP_BRANCH_DEVICE_ID_BCBEFB 0xBCBEFB
 #define DP_BRANCH_HW_REV_10 0x10
 #define DP_BRANCH_HW_REV_20 0x20
 

---
base-commit: 47df73aa49d1988c8f684b7caf8be6570e966844
change-id: 20261112-dg310-pcon-vrr-427977a452ff

Best regards,
--  
Jameson Pair <jkpair@gmail.com>

