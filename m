From: Davey Hughes <davidralphhughes@gmail.com>
Date: Tue, 27 Oct 2026 06:25:42 -0700
Subject: [PATCH 1/2] drm/amd/display: Keep FreeSync flip timing across
 plane resets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-freesync-plane-reset-time-v1-1-bb43b501faf4@gmail.com>
References: <20261027-freesync-plane-reset-time-v1-0-bb43b501faf4@gmail.com>
In-Reply-To: <20261027-freesync-plane-reset-time-v1-0-bb43b501faf4@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793107546; l=2469;
 i=davidralphhughes@gmail.com; s=20261027; h=from:subject:message-id;
 bh=w8smsIu+a5d74TM+0w5js6HnzbIYeWoiUunZBo70U9A=;
 b=XuQhEr5d/ly0qNmqbPSFTSRSyE921S+L8DE/BhEQghgfzDXAh6up4MrcGTnI84ugUZDc7qI6u
 uC8VuTaDBF+AwvtgkFbXTH28q9/Ynmh+1D0ZsIeGqEPvBlIcBe66sCF
X-Developer-Key: i=davidralphhughes@gmail.com; a=ed25519;
 pk=y45yWVxpjjxFE2cXy96fGlXLfDlt6UKHFHS5szhrFAs=
X-Endpoint-Received: by B4 Relay for davidralphhughes@gmail.com/20261027 with auth_id=1335
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dm_update_plane_state() replaces the DC plane with a newly allocated one
whenever the plane is reset. The new plane's flip timing is zero, and
mod_freesync_handle_preflip() runs before DC stores the new plane's
first flip timestamp, so FreeSync takes the 32-bit microsecond timestamp
itself as the last render time: the uptime modulo about 71.6 minutes.

On a panel with below-the-range compensation (BTR), that engages BTR and
pins the frame time at the BTR mid-point (13.447 ms on a 48-165 Hz
panel). A panel without BTR (max refresh below twice the min) goes
through the fixed refresh path instead and locks to its max refresh
after six frames.

It takes a reset on every flip to keep the panel there, and color
management changes reset the plane. DRM sets color_mgmt_changed whenever
a color property is given a different blob, even one with the same
contents, and KWin with HDR enabled and its color accuracy setting at
"Prefer efficiency" sets a new GAMMA_LUT blob on every commit. Plane
resets for CRTC color changes, added by
commit 7316c4ad2996 ("drm/amd/display: Reset planes for color management
changes"), and later for plane color properties and colorops, made this
reachable on every flip.

Copy the flip timing from the old DC plane into the new one when the
plane stays on the same CRTC. This covers both the BTR and the fixed
refresh path. A plane that is newly enabled or moved to another CRTC
still starts without history.

Fixes: 180db303ff46 ("drm/amd/display: Add below the range support for FreeSync")
Cc: stable@vger.kernel.org
Signed-off-by: Davey Hughes <davidralphhughes@gmail.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index bdabb4bf14da..a69e28685857 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -6076,6 +6076,11 @@ dm_update_plane_state(struct dc *dc,
 			goto out;
 		}
 
+		/* FreeSync times each frame from the plane's previous flip. */
+		if (dm_old_plane_state->dc_state &&
+		    old_plane_crtc == new_plane_crtc)
+			dc_new_plane_state->time = dm_old_plane_state->dc_state->time;
+
 		drm_dbg_atomic(new_plane_crtc->dev, "Enabling DRM plane: %d on DRM crtc %d\n",
 				 plane->base.id, new_plane_crtc->base.id);
 

-- 
2.56.0

