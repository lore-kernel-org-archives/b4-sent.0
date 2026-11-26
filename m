From: Peder Bergan <peder.bergan@gmail.com>
Date: Thu, 26 Nov 2026 17:53:16 +0100
Subject: [PATCH 2/3] drm/panic: Apply the QR mask while drawing data
 modules
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-perf-drm-panic-qr-v1-2-51856937dc4d@gmail.com>
References: <20261126-perf-drm-panic-qr-v1-0-51856937dc4d@gmail.com>
In-Reply-To: <20261126-perf-drm-panic-qr-v1-0-51856937dc4d@gmail.com>
To: Jocelyn Falempe <jfalempe@redhat.com>, 
 Javier Martinez Canillas <javierm@redhat.com>
Cc: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 dri-devel@lists.freedesktop.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795711998; l=3294;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=ZAbo9XJK8sS3xUaaH1sSP/WDCUTJVmN5DS5JCEvtWZk=;
 b=wCS7L6+UV4zWSP45BF52yYOERefTbJ+dfA57nTVQ50Okvuv4wZQY0GGvdRE2tJHV+CNi53p1r
 nrgmXwv9H3aDbXiSKoMijuZF6otTmNKNDMGw70J3hhWDXWKhIeiEvf4
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After placing data and remainder modules, apply_mask() scans the whole
image to invert the unreserved modules covered by checkerboard mask 0.
Data placement already visits every unreserved module once.

Apply mask 0 while drawing each data module and each zero-valued
remainder module. This removes the separate image pass and its buffer
read-modify-write operations. The format information still advertises
mask 0.

Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
 drivers/gpu/drm/drm_panic_helper_qr.rs | 35 +++++++++++-----------------------
 1 file changed, 11 insertions(+), 24 deletions(-)

diff --git a/drivers/gpu/drm/drm_panic_helper_qr.rs b/drivers/gpu/drm/drm_panic_helper_qr.rs
index c6ed395c05bd2..1d96ae855052a 100644
--- a/drivers/gpu/drm/drm_panic_helper_qr.rs
+++ b/drivers/gpu/drm/drm_panic_helper_qr.rs
@@ -691,12 +691,6 @@ fn set(&mut self, x: u8, y: u8) {
         self.data[off] = v;
     }
 
-    /// Invert a module color.
-    fn xor(&mut self, x: u8, y: u8) {
-        let off = y as usize * self.stride as usize + x as usize / 8;
-        self.data[off] ^= 0x80 >> (x % 8);
-    }
-
     /// Draw a light square at (x, y) top left corner.
     fn draw_square(&mut self, x: u8, y: u8, size: u8) {
         for k in 0..size {
@@ -864,37 +858,31 @@ fn next_available(&self, x: u8, y: u8) -> (u8, u8) {
         (x, y)
     }
 
+    /// Draw an unreserved module with checkerboard mask 0.
+    fn draw_data_module(&mut self, x: u8, y: u8, bit: bool) {
+        let invert = (x ^ y) % 2 == 0;
+        if !(bit ^ invert) {
+            self.set(x, y);
+        }
+    }
+
     fn draw_data(&mut self, data: impl Iterator<Item = u8>) {
         let (mut x, mut y) = (self.width - 1, self.width - 1);
         for byte in data {
             for s in 0..8 {
-                if byte & (0x80 >> s) == 0 {
-                    self.set(x, y);
-                }
+                self.draw_data_module(x, y, byte & (0x80 >> s) != 0);
                 (x, y) = self.next_available(x, y);
             }
         }
-        // Set the remaining modules (0, 3 or 7 depending on version).
-        // because 0 correspond to a light module.
+        // The remaining modules encode zero before masking.
         while !self.is_last(x, y) {
             if !self.is_reserved(x, y) {
-                self.set(x, y);
+                self.draw_data_module(x, y, false);
             }
             (x, y) = self.next(x, y);
         }
     }
 
-    /// Apply checkerboard mask to all non-reserved modules.
-    fn apply_mask(&mut self) {
-        for x in 0..self.width {
-            for y in 0..self.width {
-                if (x ^ y) % 2 == 0 && !self.is_reserved(x, y) {
-                    self.xor(x, y);
-                }
-            }
-        }
-    }
-
     /// Draw the QR code with the provided data iterator.
     fn draw_all(&mut self, data: impl Iterator<Item = u8>) {
         // First clear the table, as it may have already some data.
@@ -905,7 +893,6 @@ fn draw_all(&mut self, data: impl Iterator<Item = u8>) {
         self.draw_version_info();
         self.draw_data(data);
         self.draw_maskinfo();
-        self.apply_mask();
     }
 }
 

-- 
2.56.1

