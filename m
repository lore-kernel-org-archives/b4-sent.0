From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:12:29 +0000
Subject: [PATCH] drm/tegra: dc: Drop the bandwidth of planes detached along
 with the CRTC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-tegra-dc-bw-detached-planes-v1-1-e81ecc31c031@enser.io>
X-B4-Tracking: v=1; b=H4sIALx5AmsC/yXNwQ7CIBAE0F9p9uxqoWhNf8V4WJa1xRhsAKtJ0
 38X9Pgmk5kVkkQvCYZmhSiLT/4ZCtSuAZ4ojILeFYNu9UkprdEazDJGQsdo3+gkE0/icH5QkIT
 HvqMzdca1mqGMzFFu/vM7uFz/Ti97F851tTYsJUEbKfBUo8rD0u8NRtawbV+EJH4+ogAAAA==
X-Change-ID: 20261122-b4-tegra-dc-bw-detached-planes-573a8a34d02c
To: Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>
Cc: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Dmitry Osipenko <digetx@gmail.com>, 
 dri-devel@lists.freedesktop.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324350; l=2558;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=tnytgEmbcAbEg+Rxnj8ubadIh+RmzXaDqjz9Brhzka0=;
 b=/UeI9zggcODVbkY6Vw7Azm48TE1Cc4+VDfGlkuVPX7wOhPx4Z1hZJ1xjYzeGkOo96s5VDdXBc
 dbkbEXvAKRdD2btXiK55aFoXVgQ+AYA8WWcMzilaByCSGqEkloxywzn
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra_crtc_update_memory_bandwidth() removes a CRTC's display bandwidth
from the interconnect when the CRTC goes inactive, but only for the
planes in the new state's plane_mask. That covers the kernel's own DPMS,
which keeps the planes attached. A compositor may instead deactivate the
CRTC and detach its planes in the same commit, as wlroots does when it
powers an output off. The new mask is then empty, the loop zeroes
nothing, and the early return skips the per-plane update that would
have.

Seen on a Tegra Note 7 (Tegra114) under sway with the output powered
off: the atomic state shows crtc-0 active=0 and plane_mask=0, yet dc0
still requests 245760 kB/s average and 274708 kB/s peak from the memory
controller. That request alone holds the EMC at 204 MHz while nothing is
scanned out.

Walk the planes that were attached before the commit instead. For the
kernel's DPMS the old mask equals the new one, so nothing changes there.

Tested on that board under sway: with the output powered off, dc0's
request drops to 0/0, and powering it back on restores 245760/274708,
over three cycles.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Fixes: 04d5d5df9df7 ("drm/tegra: dc: Support memory bandwidth management")
Signed-off-by: EMCP333 <emcp@enser.io>
---
 drivers/gpu/drm/tegra/dc.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/tegra/dc.c b/drivers/gpu/drm/tegra/dc.c
index c9df14544c..5a52535192 100644
--- a/drivers/gpu/drm/tegra/dc.c
+++ b/drivers/gpu/drm/tegra/dc.c
@@ -2127,9 +2127,13 @@ tegra_crtc_update_memory_bandwidth(struct drm_crtc *crtc,
 		/*
 		 * When CRTC is disabled on DPMS, the state of attached planes
 		 * is kept unchanged. Hence we need to enforce removal of the
-		 * bandwidths from the ICC paths.
+		 * bandwidths from the ICC paths. A compositor may also detach
+		 * the planes in the same commit (wlroots does), and then they
+		 * are gone from the new state's plane_mask, so walk the planes
+		 * that were attached before it.
 		 */
-		drm_atomic_crtc_for_each_plane(plane, crtc) {
+		drm_for_each_plane_mask(plane, crtc->dev,
+					old_crtc_state->plane_mask) {
 			tegra = to_tegra_plane(plane);
 
 			icc_set_bw(tegra->icc_mem, 0, 0);

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-tegra-dc-bw-detached-planes-573a8a34d02c

Best regards,
--  
EMCP333 <emcp@enser.io>

