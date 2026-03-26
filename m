From: Alvin Sun <alvin.sun@linux.dev>
Date: Thu, 26 Mar 2026 14:53:04 +0800
Subject: [PATCH 11/13] drm/tyr: add debugfs infrastructure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260326-b4-tyr-debugfs-v1-11-074badd18716@linux.dev>
References: <20260326-b4-tyr-debugfs-v1-0-074badd18716@linux.dev>
In-Reply-To: <20260326-b4-tyr-debugfs-v1-0-074badd18716@linux.dev>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Sumit Semwal <sumit.semwal@linaro.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>
Cc: rust-for-linux@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774508149; l=5182;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=1btG0Sx25zF2F6OgaSoKvjV0c11Rx1gJQLvaM+XCMnw=;
 b=4BzP84uRMvtQIqd5l1fJvBht5EyLCC3NM+logl6kdz1/5RHPRvas5W18l7V0suTgaTItFl3vL
 ut/W8HeWWYqArHFrV3+rTxb4JteVf0SpQ/puwwai7tneKvmUuyrPM2o
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add module debugfs root, per-device directory and TyrDebugFSData; wire
into driver and call debugfs_init.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/debugfs.rs | 46 ++++++++++++++++++++++++++++++++++++++++++
 drivers/gpu/drm/tyr/driver.rs  | 11 +++++++++-
 drivers/gpu/drm/tyr/tyr.rs     | 39 ++++++++++++++++++++++++++++++++---
 3 files changed, 92 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/tyr/debugfs.rs b/drivers/gpu/drm/tyr/debugfs.rs
new file mode 100644
index 0000000000000..254ecef43ea9a
--- /dev/null
+++ b/drivers/gpu/drm/tyr/debugfs.rs
@@ -0,0 +1,46 @@
+// SPDX-License-Identifier: GPL-2.0 or MIT
+
+//! Debugfs support for the Tyr DRM driver.
+
+use core::pin;
+
+use kernel::{
+    debugfs,
+    device::Core,
+    drm,
+    platform,
+    prelude::*,
+    revocable::LazyRevocable,
+    str::CString,
+    sync::{
+        hazptr::HazptrCtx,
+        Arc,
+        ArcBorrow, //
+    }, //
+};
+
+use crate::driver::TyrDrmDriver;
+
+pub(crate) static DEBUGFS_ROOT: LazyRevocable<debugfs::Dir> = LazyRevocable::new();
+
+/// Per-device debugfs data.
+pub(crate) struct TyrDebugFSData {}
+
+/// Registers per-device debugfs directory under the module's debugfs root.
+pub(crate) fn debugfs_init(
+    ddev: &drm::Device<TyrDrmDriver>,
+    pdev: &platform::Device<Core>,
+    debugfs_data: ArcBorrow<'_, TyrDebugFSData>,
+) -> Result {
+    let idx = ddev.primary_index();
+    let dir_name = CString::try_from_fmt(fmt!("{}", idx))?;
+    let ctx = pin::pin!(HazptrCtx::new());
+    let root_dir = DEBUGFS_ROOT.try_access(ctx).ok_or_else(|| {
+        pr_err!("DEBUGFS_ROOT is not set");
+        ENOENT
+    })?;
+    let debugfs_data: Arc<TyrDebugFSData> = debugfs_data.into();
+    let scope_init = root_dir.scope(debugfs_data, &dir_name, |_data, _dir| {});
+
+    kernel::devres::register(pdev.as_ref(), scope_init, GFP_KERNEL)
+}
diff --git a/drivers/gpu/drm/tyr/driver.rs b/drivers/gpu/drm/tyr/driver.rs
index 593f71c550e08..c8c929fda06ac 100644
--- a/drivers/gpu/drm/tyr/driver.rs
+++ b/drivers/gpu/drm/tyr/driver.rs
@@ -38,6 +38,7 @@
 };
 
 use crate::{
+    debugfs::TyrDebugFSData,
     file::TyrDrmFileData,
     fw::Firmware,
     gem::BoData,
@@ -75,6 +76,9 @@ pub(crate) struct TyrDrmDeviceData {
     ///
     /// This is mainly queried by userspace, i.e.: Mesa.
     pub(crate) gpu_info: GpuInfo,
+
+    /// Per-device debugfs data.
+    pub(crate) debugfs_data: Arc<TyrDebugFSData>,
 }
 
 // Both `Clk` and `Regulator` do not implement `Send` or `Sync`, but they
@@ -150,6 +154,8 @@ fn probe(
         let platform: ARef<platform::Device> = pdev.into();
 
         let mmu = Mmu::new(pdev, iomem.as_arc_borrow(), &gpu_info)?;
+        let debugfs_data = Arc::new(TyrDebugFSData {}, GFP_KERNEL)?;
+        let debugfs_data_clone = debugfs_data.clone();
 
         let firmware = Firmware::new(
             pdev,
@@ -174,9 +180,12 @@ fn probe(
                     _sram: sram_regulator,
                 }),
                 gpu_info,
+                debugfs_data: debugfs_data_clone,
         });
-
         let ddev = Registration::new_foreign_owned(uninit_ddev, pdev.as_ref(), data, 0)?;
+
+        crate::debugfs::debugfs_init(ddev, pdev, debugfs_data.as_arc_borrow())?;
+
         let driver = TyrPlatformDriverData {
             _device: ddev.into(),
         };
diff --git a/drivers/gpu/drm/tyr/tyr.rs b/drivers/gpu/drm/tyr/tyr.rs
index 18b0668bb2178..cda4955db4dc9 100644
--- a/drivers/gpu/drm/tyr/tyr.rs
+++ b/drivers/gpu/drm/tyr/tyr.rs
@@ -5,8 +5,20 @@
 //! The name "Tyr" is inspired by Norse mythology, reflecting Arm's tradition of
 //! naming their GPUs after Nordic mythological figures and places.
 
-use crate::driver::TyrPlatformDriverData;
+use crate::{
+    debugfs::DEBUGFS_ROOT,
+    driver::TyrPlatformDriverData, //
+};
+use kernel::{
+    driver::Registration,
+    error,
+    platform,
+    prelude::*,
+    revocable::HazPtrRevokeHandle,
+    InPlaceModule, //
+};
 
+mod debugfs;
 mod driver;
 mod file;
 mod fw;
@@ -17,8 +29,29 @@
 mod slot;
 mod vm;
 
-kernel::module_platform_driver! {
-    type: TyrPlatformDriverData,
+pub(crate) const MODULE_NAME: &kernel::str::CStr = <LocalModule as kernel::ModuleMetadata>::NAME;
+
+#[pin_data]
+struct TyrModule {
+    _debugfs_root: HazPtrRevokeHandle<'static, kernel::debugfs::Dir>,
+    #[pin]
+    _driver: Registration<platform::Adapter<TyrPlatformDriverData>>,
+}
+
+impl InPlaceModule for TyrModule {
+    fn init(module: &'static kernel::ThisModule) -> impl PinInit<Self, error::Error> {
+        let dir = kernel::debugfs::Dir::new(kernel::c_str!("tyr"));
+        let debugfs_root_handle = Pin::static_ref(&DEBUGFS_ROOT).init(dir);
+
+        try_pin_init!(Self {
+            _driver <- Registration::new(MODULE_NAME, module),
+            _debugfs_root <- debugfs_root_handle,
+        })
+    }
+}
+
+module! {
+    type: TyrModule,
     name: "tyr",
     authors: ["The Tyr driver authors"],
     description: "Arm Mali Tyr DRM driver",

-- 
2.43.0

