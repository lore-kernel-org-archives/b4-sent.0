From: Maximilian Passarello <git@0xMax42.io>
Date: Sat, 29 Aug 2026 19:29:42 +0200
Subject: [PATCH] drm/amd/display: set remote MST sink power state on
 payload changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-mst-remote-sink-power-v1-1-b9eab331e0d5@0xMax42.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqDMBBA0avIrB2IQWzjVcSF2kk7FBOZCSqE3
 L2hy7f4P4OSMCmMTQahk5VjqOjaBrbPEt6E/KoGa+xgntbhrgmF9pgIlcMXj3iR4LYY//B9tzr
 joLaHkOf7/53mUn63RxQXZwAAAA==
X-Change-ID: 20260829-mst-remote-sink-power-ca0f7f41b909
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Maximilian Passarello <git@0xMax42.io>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2297; i=git@0xMax42.io;
 s=20251130; h=from:subject:message-id;
 bh=z7GIZHa6GjvkEEzvyXbXQn2iCrZf54tBoOQm4lCih+c=;
 b=owGbwMvMwCWWb8ayoV75uQzjabUkhqzJ4vz/IkqunV5o2zuhMGdJrLBU3wrFuSuC5RYI2RTmM
 EQkPg7sKGVhEONikBVTZOlsXTbvoRJj8/TOAG+YOaxMIEMYuDgFYCL/sxj+l3J9OtnD9EJ5WnmC
 3JLcQ683M5xwz15ekCDGyPtm06wTGQz/LLV/L8i4fuhr4cmg8EW+yget2q8wTUrQt2hkkz7jdzu
 VHwA=
X-Developer-Key: i=git@0xMax42.io; a=openpgp;
 fpr=BB652AF8176BC2EA82C83A5B025EF9E480AC8E43
X-Endpoint-Received: by B4 Relay for git@0xMax42.io/20251130 with auth_id=989
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some downstream MST displays keep their backlight on after DPMS off because
removing the MST payload does not update DP_SET_POWER on the remote sink.

Set the remote sink to D0 before allocating its payload and to D3 before
removing it. Log AUX errors without changing the existing payload flow.

Signed-off-by: Maximilian Passarello <git@0xMax42.io>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
index ab15ceec4daa..ce27024a9593 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
@@ -372,6 +372,7 @@ bool dm_helpers_dp_mst_write_payload_allocation_table(
 	struct drm_dp_mst_topology_state *mst_state;
 	struct drm_dp_mst_atomic_payload *target_payload, *new_payload, old_payload;
 	struct drm_dp_mst_topology_mgr *mst_mgr;
+	int ret;
 
 	aconnector = (struct amdgpu_dm_connector *)stream->dm_stream_context;
 	/* Accessing the connector state is required for vcpi_slots allocation
@@ -388,11 +389,23 @@ bool dm_helpers_dp_mst_write_payload_allocation_table(
 	new_payload = drm_atomic_get_mst_payload_state(mst_state, aconnector->mst_output_port);
 
 	if (enable) {
+		ret = drm_dp_link_power_up(&aconnector->mst_output_port->aux,
+					   aconnector->mst_output_port->dpcd_rev);
+		if (ret < 0)
+			drm_dbg_dp(mst_mgr->dev,
+				   "Failed to power up remote MST sink: %d\n", ret);
+
 		target_payload = new_payload;
 
 		/* It's OK for this to fail */
 		drm_dp_add_payload_part1(mst_mgr, mst_state, new_payload);
 	} else {
+		ret = drm_dp_link_power_down(&aconnector->mst_output_port->aux,
+					     aconnector->mst_output_port->dpcd_rev);
+		if (ret < 0)
+			drm_dbg_dp(mst_mgr->dev,
+				   "Failed to power down remote MST sink: %d\n", ret);
+
 		/* construct old payload by VCPI*/
 		dm_helpers_construct_old_payload(mst_mgr, mst_state,
 						 new_payload, &old_payload);

---
base-commit: 75a5e1b6b3661c3f946885d01eebeb6b031035ef
change-id: 20260829-mst-remote-sink-power-ca0f7f41b909

Best regards,
-- 
Maximilian Passarello <git@0xMax42.io>

