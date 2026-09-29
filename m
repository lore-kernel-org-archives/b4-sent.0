From: Ke Sun <sunke@kylinos.cn>
Date: Tue, 29 Sep 2026 10:16:01 +0800
Subject: [PATCH v3 11/11] drm/tyr: gem: map cached BOs for
 DRM_PANTHOR_BO_WB_MMAP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260929-tyr-ioctls-v3-11-26955fb111d5@kylinos.cn>
References: <20260929-tyr-ioctls-v3-0-26955fb111d5@kylinos.cn>
In-Reply-To: <20260929-tyr-ioctls-v3-0-26955fb111d5@kylinos.cn>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Lyude Paul <lyude@redhat.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>
Cc: Sami Tolvanen <samitolvanen@google.com>, rust-for-linux@vger.kernel.org, 
 linux-mm@kvack.org, dri-devel@lists.freedesktop.org, 
 driver-core@lists.linux.dev, Ke Sun <sunke@kylinos.cn>, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790648153; l=4490;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=g7NGH5IK+aKtnhOkcQHFTWmHIOxfBCihbd0P5WoqQL0=;
 b=3TYcDisu+8tPh0DWXNRfpV5bBe9WRoBYxN9JY4oYTdWJov6P7C+AhjOGumle2IqoLRv1/fWqp
 NZbE20qeANwD0kgYkAYQ5k5+Da55KLb3OBdWAViztwHGvzRBpjBMc9R
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

Userspace may request a cacheable CPU mapping for a buffer it accesses
frequently. Accept DRM_PANTHOR_BO_WB_MMAP in bo_create and map the
buffer cached when the flag is set. Coherent devices already map
cached. NO_MMAP and WB_MMAP together are rejected with EINVAL.

On non-coherent platforms userspace owns the CPU cache maintenance
around GPU access to these buffers.

Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
[ Split the BO_CREATE validation and add the WB_MMAP flag checks
  from the original. - Alvin ]
Co-developed-by: Alvin Sun <alvin.sun@linux.dev>
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/file.rs | 25 +++++++++++++++++++------
 drivers/gpu/drm/tyr/gem.rs  | 18 +++++++++++-------
 2 files changed, 30 insertions(+), 13 deletions(-)

diff --git a/drivers/gpu/drm/tyr/file.rs b/drivers/gpu/drm/tyr/file.rs
index 526eb1d53de42..9ed16c5a8099a 100644
--- a/drivers/gpu/drm/tyr/file.rs
+++ b/drivers/gpu/drm/tyr/file.rs
@@ -256,19 +256,32 @@ pub(crate) fn bo_create(
         bocreate: &mut uapi::drm_panthor_bo_create,
         file: &TyrDrmFile,
     ) -> Result<u32> {
-        if bocreate.size == 0
-            || bocreate.pad != 0
-            || bocreate.flags & !uapi::drm_panthor_bo_flags_DRM_PANTHOR_BO_NO_MMAP != 0
-        {
+        if bocreate.size == 0 || bocreate.pad != 0 {
             dev_err!(
                 ddev.as_ref(),
-                "Invalid BO_CREATE params: size={}, pad={}, flags={:#x}\n",
+                "Invalid BO_CREATE params: size={}, pad={}\n",
                 bocreate.size,
-                bocreate.pad,
+                bocreate.pad
+            );
+            return Err(EINVAL);
+        }
+
+        let no_mmap = uapi::drm_panthor_bo_flags_DRM_PANTHOR_BO_NO_MMAP;
+        let wb_mmap = uapi::drm_panthor_bo_flags_DRM_PANTHOR_BO_WB_MMAP;
+        let valid_flags = no_mmap | wb_mmap;
+
+        if bocreate.flags & !valid_flags != 0 {
+            dev_err!(
+                ddev.as_ref(),
+                "Invalid BO_CREATE flags: {:#x}\n",
                 bocreate.flags
             );
             return Err(EINVAL);
         }
+        if bocreate.flags & no_mmap != 0 && bocreate.flags & wb_mmap != 0 {
+            dev_err!(ddev.as_ref(), "BO_CREATE: NO_MMAP conflicts with WB_MMAP\n");
+            return Err(EINVAL);
+        }
 
         if bocreate.exclusive_vm_id != 0 {
             dev_err!(ddev.as_ref(), "BO_CREATE: exclusive_vm_id not supported\n");
diff --git a/drivers/gpu/drm/tyr/gem.rs b/drivers/gpu/drm/tyr/gem.rs
index 95e5537e7174b..21b59690d1fc1 100644
--- a/drivers/gpu/drm/tyr/gem.rs
+++ b/drivers/gpu/drm/tyr/gem.rs
@@ -17,7 +17,8 @@
     sync::{
         aref::ARef,
         Arc, //
-    }, //
+    },
+    uapi, //
 };
 
 use crate::{
@@ -63,13 +64,16 @@ fn new(_dev: &TyrDrmDevice, _size: usize, args: BoCreateArgs) -> impl PinInit<Se
 /// Type alias for Tyr GEM buffer objects.
 pub(crate) type Bo = gem::shmem::Object<BoData>;
 
-/// Returns whether a BO should be mapped write-combine given the device's
-/// DMA coherence.
-pub(crate) fn should_map_wc(coherent: bool) -> bool {
+/// Returns whether a BO should be mapped write-combine.
+pub(crate) fn should_map_wc(coherent: bool, flags: u32) -> bool {
     if coherent {
         return false;
     }
 
+    if flags & uapi::drm_panthor_bo_flags_DRM_PANTHOR_BO_WB_MMAP != 0 {
+        return false;
+    }
+
     true
 }
 
@@ -86,7 +90,7 @@ pub(crate) fn new_object(
 
     let aligned_size = size.checked_next_multiple_of(PAGE_SIZE).ok_or(EINVAL)?;
 
-    let map_wc = should_map_wc(coherent);
+    let map_wc = should_map_wc(coherent, flags);
     let bo = Bo::new(
         ddev,
         aligned_size,
@@ -118,7 +122,7 @@ pub(crate) fn new_dummy_object(ddev: &TyrDrmDevice, coherent: bool) -> Result<AR
         ddev,
         4096,
         shmem::ObjectConfig {
-            map_wc: should_map_wc(coherent),
+            map_wc: should_map_wc(coherent, 0),
             parent_resv_obj: None,
         },
         BoCreateArgs { flags: 0 },
@@ -176,7 +180,7 @@ pub(crate) fn new(
             ddev,
             bo_size,
             shmem::ObjectConfig {
-                map_wc: should_map_wc(coherent),
+                map_wc: should_map_wc(coherent, 0),
                 parent_resv_obj: None,
             },
             BoCreateArgs { flags: 0 },

-- 
2.43.0

