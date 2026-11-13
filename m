From: Hugo Sales <hugo@hsal.es>
Date: Fri, 13 Nov 2026 19:40:39 +0000
Subject: [PATCH v2 2/3] drm/amd/display: Leave self-refresh before an ABM
 level update
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-amdgpu-psr-abm-update-next-v2-2-27ce790856ea@hsal.es>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=7318; i=hugo@hsal.es;
 h=from:subject:message-id; bh=aPK+/O58ErSzPhBOIOuBjn+oOrhfRqck5lqxBkYi52s=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsr6nb2N8qsSrJa2eI6bcF5rD5Xf6hqKc4wzmk1wLq
 6UOl9hz8naUsjCIcTHIiimy6N7wZGCZOHlmTtHzJTBzWJlAhjBwcQrARKqkGRka+xtD5rhHL3Dm
 jLLht5C7Nc8g+crSpomfZ02Krz6iPfMnw1+RV4EJ3PklVeFrmYRfy53szz1+Irfy9eqXW7P4Z07
 LO8QBAF1PRQU=
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Writing panel_power_savings while the eDP is in PSR hangs DMUB on a
Cezanne laptop (DCN 2.1)

An abm_level change on its own is a fast update, so the commit skips
amdgpu_dm_commit_streams(), where amdgpu_dm_mod_power_update_streams()
sets the events that keep the panel out of self-refresh. The ABM level
then reaches DMUB through amdgpu_dm_commit_planes(), or through the
connector update loop in amdgpu_dm_atomic_commit_tail(), with the panel
still in self-refresh

Raise the PSR and Replay hw_programming events before both updates and
clear them once DC has the new level. Leaving them for
amdgpu_dm_enable_self_refresh() would keep PSR off on an idle desktop
until an unrelated commit came along. An event that a full update, a
modeset or a PSR SU dirty rect change set before the update stays set,
for that code to clear

Fixes: 8c322309e48e ("drm/amd/display: Enable PSR")
Signed-off-by: Hugo Sales <hugo@hsal.es>
---
v1 was tested on an ASUS ROG Flow X13 (GV301QH, Cezanne, DCN 2.1, PSR1 eDP)
with PSR turned on through amdgpu.dcfeaturemask=0xa and "drm/amd/display:
Don't require DMUB PSR caps before DCN 3.0" [1], which DCN 2.1 needs for
PSR to come up at all, but, as far as I can tell, the same bug would
manifest on other DMUB versions that use PSR and ABM

On 7.3 without this patch, writing 3 to panel_power_savings while
psr_state reads 6 makes DMUB fail within a second. The log fills with
"DMCUB error - collecting diagnostic data" and the panel shows vertical
lines. amdgpu doesn't attempt a GPU reset, and the errors go on until a
reboot

With the fix, I let psr_state reach 6 before each of these steps:

- turn ABM on, from level 0 to 3
- change the level, from 4 to 1
- turn ABM off, from 1 to 0, which takes the immediate disable path
- switch power-profiles-daemon to balanced and back to power-saver,
  which sets a new level each time

None of them logged a DMCUB error. Both kernels had [2] applied as well

I tested v2 the same way. I let psr_state reach 6 before each of these
writes: 0 to 4, 4 to 1, 1 to 4, 4 to 0, and the back-to-back writes
1 2 3 4 and 0 3 0. None logged a DMCUB error. psr_state left 6 within
7 ms of each write, and PSR was enabled again about 115 ms later. With
ABM on, the panel went back into self-refresh about 18 seconds after the
write

Commit 8c322309e48e ("drm/amd/display: Enable PSR") only paused PSR for
full updates. The power module events used here came with commit
3c108046e1d6 ("drm/amd/display: Add power module on Linux"), so a
backport before that needs another way to leave PSR

[1] https://lore.kernel.org/r/20261029171219.2842014-1-hugo@hsal.es
[2] https://lore.kernel.org/r/20261029165420.2255749-1-hugo@hsal.es
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c | 60 +++++++++++++++++++++++
 1 file changed, 60 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index dfbc384fbbdb4..262170b611502 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -3841,6 +3841,56 @@ STATIC_IFN_KUNIT void dm_arm_vblank_event_pre_programming(struct amdgpu_crtc *ac
 }
 EXPORT_IF_KUNIT(dm_arm_vblank_event_pre_programming);
 
+struct dm_sr_hold {
+	bool psr;
+	bool replay;
+};
+
+/*
+ * DMUB can hang if an ABM level reaches it while the panel is in
+ * self-refresh. A commit that changes only the ABM level is a fast update and
+ * skips the hold in amdgpu_dm_mod_power_update_streams(), so hold PSR and
+ * Replay off around the DC update. Holds that something else already set stay
+ * as they are, for their owner to clear. dc_lock keeps the backlight path,
+ * amdgpu_dm_mod_power_update_streams() and the self-refresh code in
+ * amdgpu_dm_commit_planes() from changing them in between.
+ * amdgpu_dm_mod_power_setup_streams() sets them without dc_lock, but only for
+ * a modeset stream, earlier in the same commit tail
+ */
+static struct dm_sr_hold dm_hold_self_refresh(struct amdgpu_display_manager *dm,
+					      struct dc_stream_state *stream)
+{
+	struct dm_sr_hold hold;
+
+	lockdep_assert_held(&dm->dc_lock);
+
+	hold.psr = !amdgpu_dm_psr_event_is_set(dm, stream, psr_event_hw_programming);
+	hold.replay = !amdgpu_dm_replay_event_is_set(dm, stream, replay_event_hw_programming);
+
+	if (hold.psr)
+		amdgpu_dm_psr_set_event(dm, stream, true, psr_event_hw_programming, true);
+	if (hold.replay)
+		amdgpu_dm_replay_set_event(dm, stream, true, replay_event_hw_programming, true);
+
+	return hold;
+}
+
+/*
+ * Nothing else may commit on an idle desktop, so drop the hold right after the
+ * update rather than leaving it to amdgpu_dm_enable_self_refresh()
+ */
+static void dm_release_self_refresh(struct amdgpu_display_manager *dm,
+				    struct dc_stream_state *stream,
+				    struct dm_sr_hold hold)
+{
+	lockdep_assert_held(&dm->dc_lock);
+
+	if (hold.psr)
+		amdgpu_dm_psr_set_event(dm, stream, false, psr_event_hw_programming, false);
+	if (hold.replay)
+		amdgpu_dm_replay_set_event(dm, stream, false, replay_event_hw_programming, false);
+}
+
 static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 				    struct drm_device *dev,
 				    struct amdgpu_display_manager *dm,
@@ -3868,6 +3918,7 @@ static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 	bool dirty_rects_changed = false;
 	bool updated_planes_and_streams = false;
 	bool stream_update_needed = false;
+	struct dm_sr_hold sr_hold = {};
 	struct {
 		struct dc_surface_update surface_updates[MAX_SURFACES];
 		struct dc_plane_info plane_infos[MAX_SURFACES];
@@ -4224,11 +4275,16 @@ static void amdgpu_dm_commit_planes(struct drm_atomic_commit *state,
 			amdgpu_dm_replay_set_event(dm, acrtc_state->stream, true,
 				replay_event_immediate_flip, true);
 		}
+		if (bundle->stream_update.abm_level) {
+			dc_exit_ips_for_hw_access(dm->dc);
+			sr_hold = dm_hold_self_refresh(dm, acrtc_state->stream);
+		}
 		update_planes_and_stream_adapter(dm->dc,
 					 planes_count,
 					 acrtc_state->stream,
 					 stream_update_needed ? &bundle->stream_update : NULL,
 					 bundle->surface_updates);
+		dm_release_self_refresh(dm, acrtc_state->stream, sr_hold);
 		updated_planes_and_streams = true;
 
 		/**
@@ -5198,6 +5254,7 @@ static void amdgpu_dm_atomic_commit_tail(struct drm_atomic_commit *state)
 		struct dc_info_packet hdr_packet;
 		struct dc_stream_status *status = NULL;
 		bool abm_changed, hdr_changed, scaling_changed, output_color_space_changed = false;
+		struct dm_sr_hold sr_hold = {};
 
 		memset(&stream_update, 0, sizeof(stream_update));
 
@@ -5280,11 +5337,14 @@ static void amdgpu_dm_atomic_commit_tail(struct drm_atomic_commit *state)
 
 		mutex_lock(&dm->dc_lock);
 		dc_exit_ips_for_hw_access(dm->dc);
+		if (abm_changed)
+			sr_hold = dm_hold_self_refresh(dm, dm_new_crtc_state->stream);
 		dc_update_planes_and_stream(dm->dc,
 					    dummy_updates,
 					    status->plane_count,
 					    dm_new_crtc_state->stream,
 					    &stream_update);
+		dm_release_self_refresh(dm, dm_new_crtc_state->stream, sr_hold);
 		mutex_unlock(&dm->dc_lock);
 		kfree(dummy_updates);
 

-- 
2.56.0

