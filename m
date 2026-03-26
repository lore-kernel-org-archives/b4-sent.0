From: Alvin Sun <alvin.sun@linux.dev>
Date: Thu, 26 Mar 2026 14:53:05 +0800
Subject: [PATCH 12/13] drm/tyr: add vms and gpuvas debugfs interface
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260326-b4-tyr-debugfs-v1-12-074badd18716@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774508149; l=6265;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=PT8BoEdihc7OlVuRK6n+uUkVOlziBrFRPpEjiw9P2kI=;
 b=CLSwwc7lBTWGbtnfA7WsMpzQ22Qi3qmnhkI6Dl6n48psilB7uc3zezz4XHsLyMyPvZRHiwX9Z
 uLqKay70PVHBW7qWSLA4EkVDs9vWDXCDDsJgem6h7b30xxYnADHj74y
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add vms list to Mmu and vms field to TyrDebugFSData; populate vms in
Firmware::new and register gpuvas read-only file under debugfs
per-device directory.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/debugfs.rs | 59 +++++++++++++++++++++++++++++++++++++++---
 drivers/gpu/drm/tyr/driver.rs  |  5 +++-
 drivers/gpu/drm/tyr/fw.rs      |  5 +++-
 drivers/gpu/drm/tyr/mmu.rs     |  6 ++++-
 4 files changed, 69 insertions(+), 6 deletions(-)

diff --git a/drivers/gpu/drm/tyr/debugfs.rs b/drivers/gpu/drm/tyr/debugfs.rs
index 254ecef43ea9a..edbdb83a5b132 100644
--- a/drivers/gpu/drm/tyr/debugfs.rs
+++ b/drivers/gpu/drm/tyr/debugfs.rs
@@ -8,6 +8,9 @@
     debugfs,
     device::Core,
     drm,
+    drm::gem::IntoGEMObject,
+    fmt,
+    fmt::Write,
     platform,
     prelude::*,
     revocable::LazyRevocable,
@@ -15,16 +18,64 @@
     sync::{
         hazptr::HazptrCtx,
         Arc,
-        ArcBorrow, //
+        ArcBorrow,
+        Mutex, //
     }, //
 };
 
 use crate::driver::TyrDrmDriver;
+use crate::vm::Vm;
 
 pub(crate) static DEBUGFS_ROOT: LazyRevocable<debugfs::Dir> = LazyRevocable::new();
 
 /// Per-device debugfs data.
-pub(crate) struct TyrDebugFSData {}
+#[pin_data]
+pub(crate) struct TyrDebugFSData {
+    #[pin]
+    pub(crate) vms: Mutex<KVec<Arc<Vm>>>,
+}
+
+/// Writes VM debug information for the "gpuvas" debugfs file.
+fn show_vm(vm: &Vm, f: &mut impl Write) -> core::fmt::Result {
+    writeln!(
+        f,
+        "DRM GPU VA space ({:?}) [0x{:016x};0x{:016x}]",
+        vm.gpuvm.name(),
+        vm.va_range.start,
+        vm.va_range.end,
+    )?;
+
+    let kva = vm.gpuvm.kernel_alloc_va();
+    writeln!(
+        f,
+        "Kernel reserved node [0x{:016x};0x{:016x}]",
+        kva.addr(),
+        kva.addr() + kva.length(),
+    )?;
+
+    writeln!(f, " VAs | start              | range              | end                | object             | object offset")?;
+    writeln!(f, "-------------------------------------------------------------------------------------------------------------")?;
+    for va in vm.gpuvm_core.lock().va_mappings() {
+        f.write_fmt(fmt!(
+            "     | 0x{:016x} | 0x{:016x} | 0x{:016x} | {:18p} | 0x{:016x}\n",
+            va.addr(),
+            va.length(),
+            va.addr() + va.length(),
+            va.obj().as_raw(),
+            va.gem_offset(),
+        ))?;
+    }
+    Ok(())
+}
+
+fn show_gpuvas(data: &Arc<TyrDebugFSData>, f: &mut fmt::Formatter<'_>) -> core::fmt::Result {
+    let vms = data.vms.lock();
+    for vm in vms.iter() {
+        show_vm(vm, f)?;
+        writeln!(f)?;
+    }
+    Ok(())
+}
 
 /// Registers per-device debugfs directory under the module's debugfs root.
 pub(crate) fn debugfs_init(
@@ -40,7 +91,9 @@ pub(crate) fn debugfs_init(
         ENOENT
     })?;
     let debugfs_data: Arc<TyrDebugFSData> = debugfs_data.into();
-    let scope_init = root_dir.scope(debugfs_data, &dir_name, |_data, _dir| {});
+    let scope_init = root_dir.scope(debugfs_data, &dir_name, |data, dir| {
+        dir.read_callback_file(c"gpuvas", data, &show_gpuvas);
+    });
 
     kernel::devres::register(pdev.as_ref(), scope_init, GFP_KERNEL)
 }
diff --git a/drivers/gpu/drm/tyr/driver.rs b/drivers/gpu/drm/tyr/driver.rs
index c8c929fda06ac..e1d5e908de876 100644
--- a/drivers/gpu/drm/tyr/driver.rs
+++ b/drivers/gpu/drm/tyr/driver.rs
@@ -154,7 +154,9 @@ fn probe(
         let platform: ARef<platform::Device> = pdev.into();
 
         let mmu = Mmu::new(pdev, iomem.as_arc_borrow(), &gpu_info)?;
-        let debugfs_data = Arc::new(TyrDebugFSData {}, GFP_KERNEL)?;
+        let debugfs_data = Arc::pin_init(try_pin_init!(TyrDebugFSData {
+            vms <- new_mutex!(KVec::new()),
+        }), GFP_KERNEL)?;
         let debugfs_data_clone = debugfs_data.clone();
 
         let firmware = Firmware::new(
@@ -163,6 +165,7 @@ fn probe(
             &uninit_ddev,
             mmu.as_arc_borrow(),
             &gpu_info,
+            debugfs_data.as_arc_borrow(),
         )?;
 
         firmware.boot()?;
diff --git a/drivers/gpu/drm/tyr/fw.rs b/drivers/gpu/drm/tyr/fw.rs
index b62e5ed69c4d4..c46320bb54516 100644
--- a/drivers/gpu/drm/tyr/fw.rs
+++ b/drivers/gpu/drm/tyr/fw.rs
@@ -37,6 +37,7 @@
 };
 
 use crate::{
+    debugfs::TyrDebugFSData,
     driver::{
         IoMem,
         TyrDrmDevice, //
@@ -200,6 +201,7 @@ pub(crate) fn new(
         ddev: &TyrDrmDevice<Uninit>,
         mmu: ArcBorrow<'_, Mmu>,
         gpu_info: &GpuInfo,
+        debugfs_data: ArcBorrow<'_, TyrDebugFSData>,
     ) -> Result<Arc<Firmware>> {
         let vm = Vm::new(pdev, ddev, mmu, gpu_info)?;
 
@@ -238,11 +240,12 @@ pub(crate) fn new(
             Firmware {
                 pdev: pdev.into(),
                 iomem: iomem.into(),
-                vm,
+                vm: vm.clone(),
                 sections,
             },
             GFP_KERNEL,
         )?;
+        debugfs_data.vms.lock().push(vm, GFP_KERNEL)?;
 
         Ok(firmware)
     }
diff --git a/drivers/gpu/drm/tyr/mmu.rs b/drivers/gpu/drm/tyr/mmu.rs
index 52a6bbbb179a2..d5e6af4b804e4 100644
--- a/drivers/gpu/drm/tyr/mmu.rs
+++ b/drivers/gpu/drm/tyr/mmu.rs
@@ -35,7 +35,8 @@
         VmAsData, //
     },
     regs::MAX_AS_REGISTERS,
-    slot::SlotManager, //
+    slot::SlotManager,
+    vm, //
 };
 
 pub(crate) mod address_space;
@@ -51,6 +52,8 @@
 /// threads. Methods may block if another thread holds the lock.
 #[pin_data]
 pub(crate) struct Mmu {
+    #[pin]
+    pub(crate) vms: Mutex<KVec<Arc<vm::Vm>>>,
     /// Manages the allocation of hardware MMU slots to GPU address spaces.
     ///
     /// Tracks which address spaces are currently active in hardware slots and
@@ -75,6 +78,7 @@ pub(crate) fn new(
         let as_manager = AddressSpaceManager::new(pdev, iomem, gpu_info.as_present)?;
         let mmu_init = try_pin_init!(Self{
             as_manager <- new_mutex!(SlotManager::new(as_manager, slot_count)?),
+            vms <- new_mutex!(KVec::new()),
         });
         Arc::pin_init(mmu_init, GFP_KERNEL)
     }

-- 
2.43.0

