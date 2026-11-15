From: Erwin Springer <aot.lerwin@gmail.com>
Date: Sun, 15 Nov 2026 16:43:35 +0100
Subject: [PATCH v2] drm/i915/display: Ignore disabled planes in async flip
 checks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-i915-async-planes-v2-1-c5163dfea5b2@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NzQqDMBCEX0Vyboobf6g99T2Kh7hZdYsmklipi
 O/eaO+9DHww880mAnmmIO7JJjwtHNjZCOqSCOy17UiyiSxUqkoAKCRXMXRYLcpp0JaCNEWmUFc
 5thmKuJs8tfw5nc/6x+HdvAjnQ3Q0eg6z8+t5usDR++dfQII0kOXVzaRN2dCjGzUPV3SjqPd9/
 wIx7/NoxAAAAA==
X-Change-ID: 20261115-i915-async-planes-d532ca94cf3c
To: Jani Nikula <jani.nikula@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Joonas Lahtinen <joonas.lahtinen@linux.intel.com>, 
 Tvrtko Ursulin <tursulin@ursulin.net>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: intel-gfx@lists.freedesktop.org, intel-xe@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Erwin Springer <aot.lerwin@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794757416; l=3821;
 i=aot.lerwin@gmail.com; s=20261115; h=from:subject:message-id;
 bh=mp77voJK9qaE913+ZVMfV5BypZtyZmNXVgJbz4MPjx0=;
 b=OA43Y8dQG94I+l83wmcmVvaLNFvJPaCZx/sIKsmc/F8ew3ZhgCYzQ8a1L8XPVE94KkqPcZ8Tw
 0iwCSmNx3ceBBcQQ6Sq7Onj82WLsAhdLD3mLJoVUynF3Lcvgdzm1Cvi
X-Developer-Key: i=aot.lerwin@gmail.com; a=ed25519;
 pk=nbZwBfXFrLeFJg8vZmODCUcYskhldfPhOapnbey95tI=
X-Endpoint-Received: by B4 Relay for aot.lerwin@gmail.com/20261115 with auth_id=1534
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Atomic async flips may carry properties that don't change, so compositors
tend to send their whole plane state with every commit. KWin for example
adds all planes of the pipe, including the ones that are disabled and stay
disabled (CRTC_ID=0, FB_ID=0).

intel_async_flip_check_uapi() fails the commit as soon as the state
contains any plane of the pipe that can't do async flips:

  [drm:intel_atomic_check [i915]] [PLANE:66:plane 2A] async flip not supported
  [drm:drm_atomic_check_only.cold] atomic driver check for ... failed: -22

So with such a compositor tearing never works on a pipe with sprite or
cursor planes, even though only the FB of the primary plane changes. KWin
silently falls back to vsynced flips, about 60 rejected commits per second.

A plane without a framebuffer before and after the commit takes no part in
the flip. Skip it in both async flip checks.

A plane that is disabled in uapi may still be used by the hardware as the
Y plane of a planar framebuffer on another plane (planar_linked_plane on
ICL+). Don't skip such a plane in the uapi check, so the commit is still
rejected there as before, instead of the linked planes being pulled into
the state later and tripping the drm_WARN_ON() in
intel_async_flip_check_hw().

Tested on Raptor Lake-U (Iris Xe) with the patch applied to the i915 of
Linux 7.3.4, unmodified KWin 6.8.2 and a fullscreen client that requests
tearing through wp_tearing_control_v1. Before, none of about 350 frames per
run was presented without vsync. With the patch 3334 of 3340 frames tear
and the message above is gone. What is still rejected is the first flip
after the modifier or format changed, once per run, as intended.

Signed-off-by: Erwin Springer <aot.lerwin@gmail.com>
---
Changes in v2:
- Don't skip a disabled plane that is in use as the Y plane of a planar
  framebuffer, it would trip the drm_WARN_ON() in
  intel_async_flip_check_hw() (found by the Sashiko review)
  The device test was done with v1, no planar framebuffer was in use
  there. v2 is compile-tested (W=1).
- Link to v1: https://patch.msgid.link/20261115-i915-async-planes-v1-1-d13498d0b6be@gmail.com
---
 drivers/gpu/drm/i915/display/intel_display.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/gpu/drm/i915/display/intel_display.c b/drivers/gpu/drm/i915/display/intel_display.c
index f4d9148ef..9be7596fa 100644
--- a/drivers/gpu/drm/i915/display/intel_display.c
+++ b/drivers/gpu/drm/i915/display/intel_display.c
@@ -6281,6 +6281,16 @@ static int intel_async_flip_check_uapi(struct intel_atomic_state *state,
 		if (plane->pipe != crtc->pipe)
 			continue;
 
+		/*
+		 * Userspace may add planes it doesn't change to the commit.
+		 * A plane that is disabled and stays disabled takes no part
+		 * in the async flip, unless it is in use as the Y plane of
+		 * a planar format on another plane.
+		 */
+		if (!old_plane_state->uapi.fb && !new_plane_state->uapi.fb &&
+		    !old_plane_state->planar_linked_plane)
+			continue;
+
 		/*
 		 * TODO: Async flip is only supported through the page flip IOCTL
 		 * as of now. So support currently added for primary plane only.
@@ -6346,6 +6356,10 @@ static int intel_async_flip_check_hw(struct intel_atomic_state *state, struct in
 		if (plane->pipe != crtc->pipe)
 			continue;
 
+		/* Disabled planes that stay disabled take no part in the flip. */
+		if (!old_plane_state->hw.fb && !new_plane_state->hw.fb)
+			continue;
+
 		/*
 		 * Only async flip capable planes should be in the state
 		 * if we're really about to ask the hardware to perform

---
base-commit: 419bb0e4cadd214a0847010c02ade95e5fc511f7
change-id: 20261115-i915-async-planes-d532ca94cf3c

Best regards,
--  
Erwin Springer <aot.lerwin@gmail.com>

