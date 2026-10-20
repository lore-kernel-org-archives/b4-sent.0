From: Vladyslav Yamkovyi <hex@aleph0.ai>
Date: Tue, 20 Oct 2026 11:19:12 +0200
Subject: [PATCH v2] drm/i915/psr: Use register notifications during async
 flips
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-fix-psr-async-trans-push-v2-1-5282017ba8ea@aleph0.ai>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42OQQ6CMBBFr0K6drSFUKIr72FYtGVqaxSaDhAJ4
 e626AFcTf7k/Ze/MsLokdilWFnE2ZMf+hTKQ8GMU/0dwXcps5KXUnBRgfVvCBRB0dIbGKPqCcJ
 EDrRVsq552XDTsFQPERO7q2/tN9OkH2jG7MuEVoSgk8G4/OriC0YfTr+bCedpHOKyr5tFNv0xZ
 BYgALE5a1sJLaW9qicGx4/Ks3bbtg9bn1139AAAAA==
X-Change-ID: 20261013-fix-psr-async-trans-push-bfa6550270c7
In-Reply-To: <20261013-fix-psr-async-trans-push-v1-1-ee79bf31b66f@aleph0.ai>
References: <20261013-fix-psr-async-trans-push-v1-1-ee79bf31b66f@aleph0.ai>
To: Jani Nikula <jani.nikula@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, intel-gfx@lists.freedesktop.org
Cc: dri-devel@lists.freedesktop.org, 
 Ankit Nautiyal <ankit.k.nautiyal@intel.com>, 
 Simona Vetter <simona@ffwll.ch>, Tvrtko Ursulin <tursulin@ursulin.net>, 
 David Airlie <airlied@gmail.com>, linux-kernel@vger.kernel.org, 
 intel-xe@lists.freedesktop.org, 
 Joonas Lahtinen <joonas.lahtinen@linux.intel.com>, 
 =?utf-8?q?Ville_Syrj=C3=A4l=C3=A4?= <ville.syrjala@linux.intel.com>, 
 =?utf-8?q?Jouni_H=C3=B6gander?= <jouni.hogander@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792487951; l=6884;
 i=hex@aleph0.ai; s=20261013; h=from:subject:message-id;
 bh=qpQHd14VRb2xAvTSBwHDgWqfyncSp1FaXBXGgUUAOR4=;
 b=N9q0FCAIL40xYH6e3ysER68/zdF08bff0J3B0g++9pHWpnzPOrl5b9jE4iWCxVClDB2Pq9jc3
 ZEuPm9BsqKhBCMzuw/O1FlrV06JnEaw7uuQQKY+0v2aC0tRJI8ZOjJy
X-Developer-Key: i=hex@aleph0.ai; a=ed25519;
 pk=faUPQ+UBdMQ6ZcbVM9ytjGUZvrhV8mzf+ctgaoVsZy0=
X-Endpoint-Received: by B4 Relay for hex@aleph0.ai/20261013 with auth_id=1170
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Async flips skip the TRANS_PUSH sent by intel_pipe_update_end().
On platforms using TRANS_PUSH for PSR frame-change notifications,
an async flip from self refresh can therefore lose its completion
event and freeze scanout.

Select register-based frame-change notifications for an async request
and while any plane remains in async mode. Restore TRANS_PUSH when
the CRTC returns to synchronous operation. Update the selector under
the PSR lock before programming the planes, preserving the current
VRR enable state.

Fixes: 129a4da11707 ("drm/i915/psr: Use TRANS_PUSH to trigger frame change event")
Link: https://gitlab.freedesktop.org/drm/xe/kernel/-/work_items/9582
Link: https://lore.kernel.org/dri-devel/20261013-fix-psr-async-trans-push-v1-1-ee79bf31b66f@aleph0.ai/
Cc: stable@vger.kernel.org
Signed-off-by: Vladyslav Yamkovyi <hex@aleph0.ai>
---
v2: Don't send a push for async flips; instead stop using TRANS_PUSH as
the PSR frame change event while async flips are in use (Ville). No push
is sent for async flips, so intel_vrr_check_push_sent() is unaffected
(Jouni).

Tested on Panther Lake (eDP, PSR2, Panel Replay with and without VRR).

I could not determine whether LNL_TRANS_PUSH_PSR_PR_EN may be changed
while the PSR/PR source is enabled (Bspec 69984 is not public).
The patch changes it in pre-plane update, after the previous commit's
hardware programming has completed and before the planes are programmed.
Exiting PSR around the switch added about one refresh interval at fixed
refresh and about 40 ms with Panel Replay+VRR in local tests.
Is changing the selector without exiting PSR supported?
---
 drivers/gpu/drm/i915/display/intel_display.c | 11 +++++++++++
 drivers/gpu/drm/i915/display/intel_psr.c     | 10 +++++++++-
 drivers/gpu/drm/i915/display/intel_vrr.c     | 17 ++++++++++++++++-
 drivers/gpu/drm/i915/display/intel_vrr.h     |  2 ++
 4 files changed, 38 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/i915/display/intel_display.c b/drivers/gpu/drm/i915/display/intel_display.c
index d5d4453f283b..92e2b6100ec8 100644
--- a/drivers/gpu/drm/i915/display/intel_display.c
+++ b/drivers/gpu/drm/i915/display/intel_display.c
@@ -7412,6 +7412,8 @@ static void intel_atomic_dsb_prepare(struct intel_atomic_state *state,
 				     struct intel_crtc *crtc)
 {
 	struct intel_display *display = to_intel_display(state);
+	const struct intel_crtc_state *old_crtc_state =
+		intel_atomic_get_old_crtc_state(state, crtc);
 	struct intel_crtc_state *new_crtc_state =
 		intel_atomic_get_new_crtc_state(state, crtc);
 
@@ -7438,6 +7440,15 @@ static void intel_atomic_dsb_prepare(struct intel_atomic_state *state,
 		!intel_crtc_needs_modeset(new_crtc_state) &&
 		!intel_crtc_needs_fastset(new_crtc_state);
 
+	/*
+	 * DSB frame-change notification uses the old CRTC state, whereas
+	 * DSB wait handling uses the new policy. Change the notification
+	 * mechanism on the CPU path before programming the planes.
+	 */
+	if (intel_psr_use_trans_push(old_crtc_state) !=
+	    intel_psr_use_trans_push(new_crtc_state))
+		new_crtc_state->use_dsb = false;
+
 	intel_color_prepare_commit(state, crtc);
 }
 
diff --git a/drivers/gpu/drm/i915/display/intel_psr.c b/drivers/gpu/drm/i915/display/intel_psr.c
index 00d0146b2600..4c862fa8d795 100644
--- a/drivers/gpu/drm/i915/display/intel_psr.c
+++ b/drivers/gpu/drm/i915/display/intel_psr.c
@@ -3187,6 +3187,12 @@ void intel_psr_pre_plane_update(struct intel_atomic_state *state,
 				wm_optimization_wa(intel_dp, new_crtc_state);
 		}
 
+		if (psr->enabled &&
+		    intel_psr_use_trans_push(old_crtc_state) !=
+		    intel_psr_use_trans_push(new_crtc_state))
+			intel_vrr_psr_frame_change_update(old_crtc_state,
+							  new_crtc_state);
+
 		mutex_unlock(&psr->lock);
 	}
 }
@@ -4660,7 +4666,9 @@ bool intel_psr_use_trans_push(const struct intel_crtc_state *crtc_state)
 {
 	struct intel_display *display = to_intel_display(crtc_state);
 
-	return HAS_PSR_TRANS_PUSH_FRAME_CHANGE(display) && crtc_state->has_psr;
+	/* Keep register notifications while any plane remains in async mode. */
+	return HAS_PSR_TRANS_PUSH_FRAME_CHANGE(display) && crtc_state->has_psr &&
+		!crtc_state->uapi.async_flip && !crtc_state->async_flip_planes;
 }
 
 bool intel_psr_pr_async_video_timing_supported(struct intel_dp *intel_dp)
diff --git a/drivers/gpu/drm/i915/display/intel_vrr.c b/drivers/gpu/drm/i915/display/intel_vrr.c
index d43a06907d18..4f691ca50ea3 100644
--- a/drivers/gpu/drm/i915/display/intel_vrr.c
+++ b/drivers/gpu/drm/i915/display/intel_vrr.c
@@ -758,7 +758,7 @@ static u32 trans_vrr_push(const struct intel_crtc_state *crtc_state,
 	if (send_push)
 		trans_vrr_push |= TRANS_PUSH_SEND;
 
-	if (HAS_PSR_TRANS_PUSH_FRAME_CHANGE(display))
+	if (intel_psr_use_trans_push(crtc_state))
 		trans_vrr_push |= LNL_TRANS_PUSH_PSR_PR_EN;
 
 	return trans_vrr_push;
@@ -1059,6 +1059,21 @@ void intel_vrr_psr_frame_change_enable(const struct intel_crtc_state *crtc_state
 		       trans_vrr_push(crtc_state, false));
 }
 
+void intel_vrr_psr_frame_change_update(const struct intel_crtc_state *old_crtc_state,
+				       const struct intel_crtc_state *new_crtc_state)
+{
+	struct intel_display *display = to_intel_display(old_crtc_state);
+	enum transcoder cpu_transcoder = old_crtc_state->cpu_transcoder;
+	u32 push = trans_vrr_push(old_crtc_state, false);
+
+	/* VRR enable/disable has not run yet; preserve the old timing state. */
+	push &= ~LNL_TRANS_PUSH_PSR_PR_EN;
+	if (intel_psr_use_trans_push(new_crtc_state))
+		push |= LNL_TRANS_PUSH_PSR_PR_EN;
+
+	intel_de_write(display, TRANS_PUSH(display, cpu_transcoder), push);
+}
+
 bool intel_vrr_is_fixed_rr(const struct intel_crtc_state *crtc_state)
 {
 	return crtc_state->vrr.flipline &&
diff --git a/drivers/gpu/drm/i915/display/intel_vrr.h b/drivers/gpu/drm/i915/display/intel_vrr.h
index 19c7990be1b2..c2ca4db5acfe 100644
--- a/drivers/gpu/drm/i915/display/intel_vrr.h
+++ b/drivers/gpu/drm/i915/display/intel_vrr.h
@@ -35,6 +35,8 @@ void intel_vrr_dcb_increment_flip_count(struct intel_crtc_state *crtc_state,
 bool intel_vrr_is_push_sent(const struct intel_crtc_state *crtc_state);
 void intel_vrr_disable(const struct intel_crtc_state *old_crtc_state);
 void intel_vrr_psr_frame_change_enable(const struct intel_crtc_state *crtc_state);
+void intel_vrr_psr_frame_change_update(const struct intel_crtc_state *old_crtc_state,
+				       const struct intel_crtc_state *new_crtc_state);
 void intel_vrr_get_config(struct intel_crtc_state *crtc_state);
 int intel_vrr_vmax_vtotal(const struct intel_crtc_state *crtc_state);
 int intel_vrr_vmin_vtotal(const struct intel_crtc_state *crtc_state);

---
base-commit: 24d867f5e671c78760ab39087a57c25ad98e1f42
change-id: 20261013-fix-psr-async-trans-push-bfa6550270c7

