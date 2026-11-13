From: Hugo Sales <hugo@hsal.es>
Date: Fri, 13 Nov 2026 19:40:40 +0000
Subject: [PATCH v2 3/3] drm/amd/display: Send a changed ABM level once per
 commit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-amdgpu-psr-abm-update-next-v2-3-27ce790856ea@hsal.es>
References: <20261113-amdgpu-psr-abm-update-next-v2-0-27ce790856ea@hsal.es>
In-Reply-To: <20261113-amdgpu-psr-abm-update-next-v2-0-27ce790856ea@hsal.es>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: Roman Li <Roman.Li@amd.com>, 
 Nicholas Kazlauskas <Nicholas.Kazlauskas@amd.com>, 
 Chenyu Chen <chen-yu.chen@amd.com>, amd-gfx@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Hugo Sales <hugo@hsal.es>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3679; i=hugo@hsal.es;
 h=from:subject:message-id; bh=LlOJID8gdQUbNTNGo+hW6h93h+A/dK5Q46QGvGs1m3s=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsr6nb9Nb6fzsH797mre8wZ45cQvjs9cK/roRe/7ro
 g7+lT+fbVXrKGVhEONikBVTZNG94cnAMnHyzJyi50tg5rAygQxh4OIUgIkETWZk2HKYKTJOcuaK
 X+/rdgaFT37WYnv3jt05SbH8XNP7F9akWzEynAx055901DCkzPahxNI/vhueVRSuX1Cyf37Ur1i
 5SN+pzABAtEx6
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a commit changes the ABM level and also has planes on that CRTC,
the connector update loop in amdgpu_dm_atomic_commit_tail() sends the new
level to DC, and amdgpu_dm_commit_planes() sends it again. The panel
leaves self-refresh for each send, so one level change takes it out of
PSR or Replay twice

Record the CRTCs whose level the connector loop sent, and skip the second
send for them in amdgpu_dm_commit_planes()

Signed-off-by: Hugo Sales <hugo@hsal.es>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c | 23 +++++++++++++++--------
 1 file changed, 15 insertions(+), 8 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index 262170b611502..3077744b2d2d5 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -3895,7 +3895,8 @@ static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 				    struct drm_device *dev,
 				    struct amdgpu_display_manager *dm,
 				    struct drm_crtc *pcrtc,
-				    bool wait_for_vblank)
+				    bool wait_for_vblank,
+				    bool abm_sent)
 {
 	u32 i;
 	u64 timestamp_ns = ktime_get_ns();
@@ -4245,7 +4246,8 @@ static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 		}
 
 		acrtc_state->stream->abm_level = acrtc_state->abm_level;
-		if (acrtc_state->abm_level != dm_old_crtc_state->abm_level) {
+		/* The connector loop in amdgpu_dm_atomic_commit_tail() may have sent it */
+		if (!abm_sent && acrtc_state->abm_level != dm_old_crtc_state->abm_level) {
 			bundle->stream_update.abm_level = &acrtc_state->abm_level;
 			stream_update_needed = true;
 		}
@@ -5230,6 +5232,7 @@ static void amdgpu_dm_atomic_commit_tail(struct drm_atomic_commit *state)
 	struct drm_connector_state *old_con_state = NULL, *new_con_state = NULL;
 	struct dm_crtc_state *dm_old_crtc_state, *dm_new_crtc_state;
 	int crtc_disable_count = 0;
+	u32 abm_sent = 0;
 
 	trace_amdgpu_dm_atomic_commit_tail_begin(state);
 
@@ -5255,6 +5258,7 @@ static void amdgpu_dm_atomic_commit_tail(struct drm_atomic_commit *state)
 		struct dc_stream_status *status = NULL;
 		bool abm_changed, hdr_changed, scaling_changed, output_color_space_changed = false;
 		struct dm_sr_hold sr_hold = {};
+		bool updated;
 
 		memset(&stream_update, 0, sizeof(stream_update));
 
@@ -5339,14 +5343,16 @@ static void amdgpu_dm_atomic_commit_tail(struct drm_atomic_commit *state)
 		dc_exit_ips_for_hw_access(dm->dc);
 		if (abm_changed)
 			sr_hold = dm_hold_self_refresh(dm, dm_new_crtc_state->stream);
-		dc_update_planes_and_stream(dm->dc,
-					    dummy_updates,
-					    status->plane_count,
-					    dm_new_crtc_state->stream,
-					    &stream_update);
+		updated = dc_update_planes_and_stream(dm->dc,
+						      dummy_updates,
+						      status->plane_count,
+						      dm_new_crtc_state->stream,
+						      &stream_update);
 		dm_release_self_refresh(dm, dm_new_crtc_state->stream, sr_hold);
 		mutex_unlock(&dm->dc_lock);
 		kfree(dummy_updates);
+		if (abm_changed && updated)
+			abm_sent |= drm_crtc_mask(&acrtc->base);
 
 		drm_connector_update_privacy_screen(new_con_state);
 	}
@@ -5440,7 +5446,8 @@ static void amdgpu_dm_atomic_commit_tail(struct drm_atomic_commit *state)
 		dm_new_crtc_state = to_dm_crtc_state(new_crtc_state);
 
 		if (dm_new_crtc_state->stream)
-			amdgpu_dm_commit_planes(state, dev, dm, crtc, wait_for_vblank);
+			amdgpu_dm_commit_planes(state, dev, dm, crtc, wait_for_vblank,
+						abm_sent & drm_crtc_mask(crtc));
 	}
 
 	/* Enable writeback */

-- 
2.56.0

