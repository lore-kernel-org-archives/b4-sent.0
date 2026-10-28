From: Davey Hughes <davidralphhughes@gmail.com>
Date: Wed, 28 Oct 2026 15:54:12 -0700
Subject: [PATCH v2 1/2] drm/amd/display: Keep FreeSync flip timing across
 plane resets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-freesync-plane-reset-time-v2-1-545a0f9b17df@gmail.com>
References: <20261028-freesync-plane-reset-time-v2-0-545a0f9b17df@gmail.com>
In-Reply-To: <20261028-freesync-plane-reset-time-v2-0-545a0f9b17df@gmail.com>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Nicholas Kazlauskas <nicholas.kazlauskas@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Davey Hughes <davidralphhughes@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793228055; l=3815;
 i=davidralphhughes@gmail.com; s=20261027; h=from:subject:message-id;
 bh=ja1BU9fsikeUf2TrYBZm4ugZRVrlmO4LmC6UBmc9kCU=;
 b=52jaZa7nAksrfqKCubKGFlIUTkSLslZ6JnrdzNfxz6/3Qjdx5UpHTyZGX4OcaDH7Zw/LHJiec
 gpzq4JEvxlXCJULbSWWJFPyJtD7xc+7qHezEzh52Gqmc7e+OULF6kcd
X-Developer-Key: i=davidralphhughes@gmail.com; a=ed25519;
 pk=y45yWVxpjjxFE2cXy96fGlXLfDlt6UKHFHS5szhrFAs=
X-Endpoint-Received: by B4 Relay for davidralphhughes@gmail.com/20261027 with auth_id=1335
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dm_update_plane_state() replaces the DC plane with a newly allocated one
whenever the plane is reset. The new plane's flip timing is zero, and
mod_freesync_handle_preflip() runs before DC stores the new plane's
first flip timestamp, so FreeSync takes the 32-bit microsecond timestamp
itself as the last render time: the monotonic clock modulo about 71.6
minutes.

On a panel with below-the-range compensation (BTR), that engages BTR and
pins the frame time at the BTR mid-point (13.447 ms on a 48-165 Hz
panel). A panel without BTR (max refresh below twice the min) goes
through the fixed refresh path instead and locks to its max refresh
after six frames.

It takes a reset on every flip to keep the panel there, and color
management changes reset the plane. DRM sets color_mgmt_changed whenever
a color property is given a different blob, even one with the same
contents, and KWin 6.8.1 with HDR enabled and its color accuracy setting
at "Prefer efficiency" sets a new GAMMA_LUT blob on every commit
(current KWin master no longer does). Plane resets for CRTC color
changes, added by
commit 7316c4ad2996 ("drm/amd/display: Reset planes for color management
changes"), and later for plane color properties and colorops, made this
reachable on every flip.

Copy the flip timing from the old DC plane into the new one when the
plane stays on the same CRTC. Do it in amdgpu_dm_commit_planes() before
the preflip, after drm_atomic_helper_wait_for_dependencies() has waited
for the previous commit, so the copy holds that commit's flip and does
not race with DC writing it. This covers both the BTR and the fixed
refresh path. A plane that is newly enabled or moved to another CRTC
still starts without history.

Fixes: 180db303ff46 ("drm/amd/display: Add below the range support for FreeSync")
Cc: stable@vger.kernel.org
Signed-off-by: Davey Hughes <davidralphhughes@gmail.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index bdabb4bf14da..7a0afe6d1b8a 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -3848,6 +3848,25 @@ STATIC_IFN_KUNIT void dm_arm_vblank_event_pre_programming(struct amdgpu_crtc *ac
 }
 EXPORT_IF_KUNIT(dm_arm_vblank_event_pre_programming);
 
+/*
+ * FreeSync times each frame from the plane's previous flip, and a plane
+ * reset gives the new DC plane zeroed flip timing, so copy it over. Do
+ * this at commit time, not in atomic check: by then the previous commit
+ * has finished writing it.
+ */
+static void
+dm_plane_inherit_flip_time(struct dc_plane_state *dc_plane_state,
+			   struct drm_plane_state *old_plane_state,
+			   struct drm_plane_state *new_plane_state)
+{
+	struct dc_plane_state *old_dc_plane_state =
+		to_dm_plane_state(old_plane_state)->dc_state;
+
+	if (old_dc_plane_state && old_dc_plane_state != dc_plane_state &&
+	    old_plane_state->crtc == new_plane_state->crtc)
+		dc_plane_state->time = old_dc_plane_state->time;
+}
+
 static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 				    struct drm_device *dev,
 				    struct amdgpu_display_manager *dm,
@@ -3952,6 +3971,9 @@ static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 		if (!dc_plane)
 			continue;
 
+		dm_plane_inherit_flip_time(dc_plane, old_plane_state,
+					   new_plane_state);
+
 		bundle->surface_updates[planes_count].surface = dc_plane;
 		if (new_pcrtc_state->color_mgmt_changed || new_plane_state->color_mgmt_changed) {
 			bundle->surface_updates[planes_count].gamma = &dc_plane->gamma_correction;

-- 
2.56.0

