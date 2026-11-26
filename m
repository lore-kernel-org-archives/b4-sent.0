From: Peder Bergan <peder.bergan@gmail.com>
Date: Thu, 26 Nov 2026 17:53:15 +0100
Subject: [PATCH 1/3] drm/panic: Check QR alignment centers one axis at a
 time
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-perf-drm-panic-qr-v1-1-51856937dc4d@gmail.com>
References: <20261126-perf-drm-panic-qr-v1-0-51856937dc4d@gmail.com>
In-Reply-To: <20261126-perf-drm-panic-qr-v1-0-51856937dc4d@gmail.com>
To: Jocelyn Falempe <jfalempe@redhat.com>, 
 Javier Martinez Canillas <javierm@redhat.com>
Cc: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 dri-devel@lists.freedesktop.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795711998; l=1856;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=s2q8rdTFeCLN5bHoYDEz1EAk1bfn2gf/0qI/0v1epNE=;
 b=ZfZ7KBdVFd7SeRGeNdUGHSQKNc2jubIGoqCU/aVY3tNkQJpKdCNopEjtU6bmADCEHL6TVamaZ
 4ielgeyFJfxBPfkTgdA2+BeQYzZMT3X3IAypVkonb7abK1vIyyXfo6a
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

is_alignment() scans pairs of alignment centers each time it tests
whether a module is reserved. At version 40 there are seven centers
per axis, so a lookup can visit 49 pairs.

Each center covers a five-module span, and adjacent centers are at
least 12 modules apart. Find the unique matching center on each axis
and apply the existing finder-pattern exclusion to that pair. The
lookup now needs at most 14 center tests.

Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
 drivers/gpu/drm/drm_panic_helper_qr.rs | 19 ++++++++-----------
 1 file changed, 8 insertions(+), 11 deletions(-)

diff --git a/drivers/gpu/drm/drm_panic_helper_qr.rs b/drivers/gpu/drm/drm_panic_helper_qr.rs
index 4941731fb60fa..c6ed395c05bd2 100644
--- a/drivers/gpu/drm/drm_panic_helper_qr.rs
+++ b/drivers/gpu/drm/drm_panic_helper_qr.rs
@@ -746,17 +746,14 @@ fn draw_alignments(&mut self) {
 
     fn is_alignment(&self, x: u8, y: u8) -> bool {
         let positions = self.version.alignment_pattern();
-        for &ax in positions.iter() {
-            for &ay in positions.iter() {
-                if self.is_finder(ax, ay) {
-                    continue;
-                }
-                if x >= ax - 2 && x <= ax + 2 && y >= ay - 2 && y <= ay + 2 {
-                    return true;
-                }
-            }
-        }
-        false
+        // Centers are at least 12 modules apart, so their five-module spans are disjoint.
+        let Some(&ax) = positions.iter().find(|&&center| x.abs_diff(center) <= 2) else {
+            return false;
+        };
+        let Some(&ay) = positions.iter().find(|&&center| y.abs_diff(center) <= 2) else {
+            return false;
+        };
+        !self.is_finder(ax, ay)
     }
 
     // Timing pattern: 2 dotted line between the finder patterns.

-- 
2.56.1

