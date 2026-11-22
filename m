From: Alvin Sun <alvin.sun@linux.dev>
Date: Sun, 22 Nov 2026 20:50:29 +0800
Subject: [PATCH v7 10/10] drm/tyr: add BO-related ioctls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-tyr-ioctls-v7-10-3a2af624b992@linux.dev>
References: <20261122-tyr-ioctls-v7-0-3a2af624b992@linux.dev>
In-Reply-To: <20261122-tyr-ioctls-v7-0-3a2af624b992@linux.dev>
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
 Lyude Paul <lyude@redhat.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Johan Hovold <johan@kernel.org>
Cc: Sami Tolvanen <samitolvanen@google.com>, rust-for-linux@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, driver-core@lists.linux.dev, 
 Ke Sun <sunke@kylinos.cn>, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795352551; l=5762;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=AzMnZarF2DGhywSoCR7Qyzkxwwb8F+ZXDPQo3lLLLzc=;
 b=LopV2a8Yja0UfwXM6/qSsFB1NHzY05tsSXBa7Ki9j9YbtkOcDfQaLGZ9bpJpMymMurEnWVQpM
 xMaGjhtDzLZDeyoICMHhum929cq1qp2Vh6HiNNxInmcgdWuqQKBpzQO
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement BO_CREATE and BO_MMAP_OFFSET so userspace can allocate GPU
buffers and obtain a DRM mmap offset for the generic mmap path.
BO_CREATE page-aligns the requested size and accepts NO_MMAP or WB_MMAP,
which are mutually exclusive; an exclusive VM returns EOPNOTSUPP.
BO_MMAP_OFFSET rejects NO_MMAP objects, which must never be CPU-mapped.

Co-developed-by: Sami Tolvanen <samitolvanen@google.com>
Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/driver.rs |  2 +
 drivers/gpu/drm/tyr/file.rs   | 94 +++++++++++++++++++++++++++++++++++++++++++
 drivers/gpu/drm/tyr/gem.rs    |  2 -
 3 files changed, 96 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/tyr/driver.rs b/drivers/gpu/drm/tyr/driver.rs
index 6869ab345d8fd..8632e6e820c97 100644
--- a/drivers/gpu/drm/tyr/driver.rs
+++ b/drivers/gpu/drm/tyr/driver.rs
@@ -237,6 +237,8 @@ impl drm::Driver for TyrDrmDriver {
         (PANTHOR_VM_DESTROY, drm_panthor_vm_destroy, ioctl::RENDER_ALLOW, TyrDrmFileData::vm_destroy),
         (PANTHOR_VM_BIND, drm_panthor_vm_bind, ioctl::RENDER_ALLOW, TyrDrmFileData::vm_bind),
         (PANTHOR_VM_GET_STATE, drm_panthor_vm_get_state, ioctl::RENDER_ALLOW, TyrDrmFileData::vm_get_state),
+        (PANTHOR_BO_CREATE, drm_panthor_bo_create, ioctl::RENDER_ALLOW, TyrDrmFileData::bo_create),
+        (PANTHOR_BO_MMAP_OFFSET, drm_panthor_bo_mmap_offset, ioctl::RENDER_ALLOW, TyrDrmFileData::bo_mmap_offset),
     }
 }
 
diff --git a/drivers/gpu/drm/tyr/file.rs b/drivers/gpu/drm/tyr/file.rs
index 8fccb42ab9e56..db57df68449cd 100644
--- a/drivers/gpu/drm/tyr/file.rs
+++ b/drivers/gpu/drm/tyr/file.rs
@@ -242,6 +242,100 @@ pub(crate) fn vm_get_state(
             Ok(0)
         })
     }
+
+    pub(crate) fn bo_create(
+        ddev: &TyrDrmDevice<Registered>,
+        reg_data: &TyrDrmRegistrationData<'_>,
+        bocreate: &mut uapi::drm_panthor_bo_create,
+        file: &TyrDrmFile,
+    ) -> Result<u32> {
+        if bocreate.size == 0 || bocreate.pad != 0 {
+            dev_dbg!(
+                ddev.as_ref(),
+                "Invalid BO_CREATE params: size={}, pad={}\n",
+                bocreate.size,
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
+            dev_dbg!(
+                ddev.as_ref(),
+                "Invalid BO_CREATE flags: {:#x}\n",
+                bocreate.flags
+            );
+            return Err(EINVAL);
+        }
+        if bocreate.flags & no_mmap != 0 && bocreate.flags & wb_mmap != 0 {
+            dev_dbg!(ddev.as_ref(), "BO_CREATE: NO_MMAP conflicts with WB_MMAP\n");
+            return Err(EINVAL);
+        }
+
+        if bocreate.exclusive_vm_id != 0 {
+            dev_dbg!(ddev.as_ref(), "BO_CREATE: exclusive_vm_id not supported\n");
+            return Err(EOPNOTSUPP);
+        }
+
+        let size = usize::try_from(bocreate.size).map_err(|_| {
+            dev_dbg!(
+                ddev.as_ref(),
+                "BO_CREATE size {:#x} too large\n",
+                bocreate.size
+            );
+            EINVAL
+        })?;
+        let bo = file.inner_with(|pfile| {
+            crate::gem::new_object(
+                ddev,
+                pfile.reg.pdev.as_ref(),
+                size,
+                bocreate.flags,
+                reg_data.coherent,
+            )
+        })?;
+        bocreate.handle = bo.create_handle(file)?;
+        bocreate.size = u64::from_safe_cast(bo.size());
+
+        Ok(0)
+    }
+
+    pub(crate) fn bo_mmap_offset(
+        ddev: &TyrDrmDevice<Registered>,
+        _reg_data: &TyrDrmRegistrationData<'_>,
+        bommap: &mut uapi::drm_panthor_bo_mmap_offset,
+        file: &TyrDrmFile,
+    ) -> Result<u32> {
+        if bommap.pad != 0 {
+            dev_dbg!(
+                ddev.as_ref(),
+                "BO mmap offset pad not zero: {}\n",
+                bommap.pad
+            );
+            return Err(EINVAL);
+        }
+
+        let bo = crate::gem::lookup_handle(file, bommap.handle).inspect_err(|_| {
+            dev_dbg!(ddev.as_ref(), "Invalid BO mmap handle: {}\n", bommap.handle);
+        })?;
+        if bo.flags() & uapi::drm_panthor_bo_flags_DRM_PANTHOR_BO_NO_MMAP != 0 {
+            dev_dbg!(ddev.as_ref(), "BO mmap offset on NO_MMAP object\n");
+            return Err(EPERM);
+        }
+        bommap.offset = bo.create_mmap_offset().inspect_err(|_| {
+            dev_err!(
+                ddev.as_ref(),
+                "Failed to create mmap offset for handle {}\n",
+                bommap.handle
+            );
+        })?;
+
+        Ok(0)
+    }
 }
 
 fn vm_bind_exec_op(vm: &Vm<'_>, file: &TyrDrmFile, op: &VmBindOp) -> Result {
diff --git a/drivers/gpu/drm/tyr/gem.rs b/drivers/gpu/drm/tyr/gem.rs
index 55e2d67b96d98..d2ef121c8b1b6 100644
--- a/drivers/gpu/drm/tyr/gem.rs
+++ b/drivers/gpu/drm/tyr/gem.rs
@@ -45,7 +45,6 @@ pub(crate) struct BoData {
 
 impl BoData {
     /// Returns the flags the BO was created with.
-    #[expect(dead_code)]
     pub(crate) fn flags(&self) -> u32 {
         self.flags
     }
@@ -83,7 +82,6 @@ pub(crate) fn should_map_wc(coherent: bool, flags: u32) -> bool {
 }
 
 /// Create a new GEM buffer object.
-#[expect(dead_code)]
 pub(crate) fn new_object(
     ddev: &TyrDrmDevice,
     pdev: &Device<Bound>,

-- 
2.43.0

