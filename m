From: Vladyslav Yamkovyi <hex@aleph0.ai>
Date: Tue, 13 Oct 2026 17:16:07 +0200
Subject: [PATCH] drm/i915/psr: Send a frame change notification for async
 flips
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-fix-psr-async-trans-push-v1-1-ee79bf31b66f@aleph0.ai>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y2MwQrCMBBEf6Xs2cUk0hb8FfGQpFsTwRh206KU/
 ruJehreMPM2EOJIAuduA6Y1SnymCvrQgQ823QjjVBmMMoNW+oRzfGEWRivv5LGwTYJ5kYButkP
 fKzMqP0K9Z6a6/aov1x/L4u7kS/O1hbNC6KrBh1ZN/MAS8/GfsO8fv7BJdJ4AAAA=
X-Change-ID: 20261013-fix-psr-async-trans-push-bfa6550270c7
To: Jani Nikula <jani.nikula@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, intel-gfx@lists.freedesktop.org
Cc: Joonas Lahtinen <joonas.lahtinen@linux.intel.com>, 
 Tvrtko Ursulin <tursulin@ursulin.net>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 =?utf-8?q?Jouni_H=C3=B6gander?= <jouni.hogander@intel.com>, 
 Ankit Nautiyal <ankit.k.nautiyal@intel.com>, intel-xe@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Vladyslav Yamkovyi <hex@aleph0.ai>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791904567; l=3338;
 i=hex@aleph0.ai; s=20261013; h=from:subject:message-id;
 bh=6OzSRSOPWRw5dMbojgR3kH8JziugVnnnlVANwZ+FMbg=;
 b=7JBBQ1l0eVLUQse6LiBcfstEJhvVF2lQK3NJy6s5xem1JCwHHrEd+peS8XqwjpYw5M9wbfkFM
 7VyRBgJ/a7iBgLXdBJP/CTV1qHiP4Ok2925QSZ6IpSAU6X35x3fOhuz
X-Developer-Key: i=hex@aleph0.ai; a=ed25519;
 pk=faUPQ+UBdMQ6ZcbVM9ytjGUZvrhV8mzf+ctgaoVsZy0=
X-Endpoint-Received: by B4 Relay for hex@aleph0.ai/20261013 with auth_id=1170
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On platforms using TRANS_PUSH for PSR frame-change notifications,
intel_pipe_update_end() exits early for asynchronous flips, before sending
the push. The register-based notification is disabled on these platforms,
and an ORIGIN_FLIP frontbuffer flush does not force PSR to exit.

This can leave an accepted async flip without a completion event after
PSR2 enters DEEP_SLEEP. On Panther Lake, scanout freezes and the kernel
reports "[CRTC:152:pipe A] flip_done timed out". Intel IGT kms_async_flips
reproduces the failure with the compositor inactive when a 200 ms idle
interval is inserted before an asynchronous atomic flip.

Send the PSR frame-change notification after plane programming and before
releasing the existing PSR lock. Restrict the push to CRTC states that use
TRANS_PUSH for PSR, leaving other async flips and the synchronous and DSB
paths unchanged.

Closes: https://gitlab.freedesktop.org/drm/xe/kernel/-/work_items/9582
Fixes: 129a4da11707 ("drm/i915/psr: Use TRANS_PUSH to trigger frame change event")
Cc: stable@vger.kernel.org
Assisted-by: LLM sparse smatch
Signed-off-by: Vladyslav Yamkovyi <hex@aleph0.ai>
---
Based on drm-tip (2026-10-13); also applies to v7.3-rc7.

Runtime-tested on Panther Lake (xe, eDP-1, 2880x1800) with Ubuntu-based
7.3.0-rc6 kernels, before and after this fix. IGT kms_async_flips,
async-flip-with-page-flip-events-tiled-atomic, dynamic subtest
pipe-A-eDP-1-4-rc-ccs, fails with Flip Timeout before the fix and passes
afterwards. An LD_PRELOAD interposer inserts one 200 ms idle interval
before the eighth async atomic commit without changing its request or
flags. Both runs enter PSR2 Early Transport DEEP_SLEEP with selective
fetch enabled before that commit.

Clang 23.1.2, W=1 builds and Sparse/Smatch checks of the CRTC, PSR and VRR
translation units for i915 and Xe produced no new diagnostics.

OpenAI Codex (GPT-6-Astra) assisted diagnosis, reproducer and fix
development, validation and patch preparation, following requests to
reproduce the freeze independently, trace its driver cause and prepare a
tested upstream fix. I take direct responsibility for this contribution,
have carefully reviewed the change and ensured rigorous local testing.
---
 drivers/gpu/drm/i915/display/intel_crtc.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/i915/display/intel_crtc.c b/drivers/gpu/drm/i915/display/intel_crtc.c
index 10ed9bdfee76..8ef24cddbaa6 100644
--- a/drivers/gpu/drm/i915/display/intel_crtc.c
+++ b/drivers/gpu/drm/i915/display/intel_crtc.c
@@ -736,8 +736,16 @@ void intel_pipe_update_end(struct intel_atomic_state *state,
 
 	drm_WARN_ON(display->drm, new_crtc_state->use_dsb);
 
-	if (new_crtc_state->do_async_flip)
+	if (new_crtc_state->do_async_flip) {
+		/*
+		 * LNL+ uses TRANS_PUSH for PSR frame-change notifications.
+		 * Async flips skip the vblank path below, but still need to
+		 * notify PSR after programming the new surface address.
+		 */
+		if (intel_psr_use_trans_push(new_crtc_state))
+			intel_vrr_send_push(NULL, new_crtc_state);
 		goto out;
+	}
 
 	trace_intel_pipe_update_end(crtc, end_vbl_count, scanline_end);
 

---
base-commit: eb1bf4700d3b25a1a1e670ef31cc06969fa08019
change-id: 20261013-fix-psr-async-trans-push-bfa6550270c7

