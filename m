From: Alvin Sun <alvin.sun@linux.dev>
Date: Fri, 31 Jul 2026 01:05:46 +0800
Subject: [PATCH v2 8/9] drm/tyr: add gpuvas debugfs file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-tyr-debugfs-v2-v2-8-aea19eccb996@linux.dev>
References: <20260731-tyr-debugfs-v2-v2-0-aea19eccb996@linux.dev>
In-Reply-To: <20260731-tyr-debugfs-v2-v2-0-aea19eccb996@linux.dev>
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
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Matthew Brost <matthew.brost@intel.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 =?utf-8?q?Ma=C3=ADra_Canal?= <mcanal@igalia.com>, 
 Melissa Wen <mwen@igalia.com>, Wambui Karuga <wambui.karugax@gmail.com>, 
 Eric Anholt <eric@anholt.net>, Ben Gamari <bgamari@gmail.com>, 
 rust-for-linux@vger.kernel.org, driver-core@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785431148; l=6199;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=kYVkz61WE+2pny9snlklEeo0ASdH0aL0mIPndo2QTJk=;
 b=SAW5hfriiBKwOoYyYKHdMATWNLMBel1xSMH9cZA+Z/ZeMFDLTI8ZbQ8poI+EoOQzN4Rp+spMd
 hIpGd4fkWeVBvhVYcRsVFfs6IGaQnNqomaJx9+Rt/+3e0lCiJsuJU75
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a gpuvas debugfs file listing all GPU VAs for the Tyr DRM driver.
Collects VMs into a shared list during firmware init and renders them
via dump_gpuva_info on read.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/debugfs.rs | 65 ++++++++++++++++++++++++++++++++++++++++++
 drivers/gpu/drm/tyr/driver.rs  | 16 +++++++++++
 drivers/gpu/drm/tyr/fw.rs      |  8 ++++++
 drivers/gpu/drm/tyr/tyr.rs     |  1 +
 drivers/gpu/drm/tyr/vm.rs      |  5 ++++
 5 files changed, 95 insertions(+)

diff --git a/drivers/gpu/drm/tyr/debugfs.rs b/drivers/gpu/drm/tyr/debugfs.rs
new file mode 100644
index 0000000000000..d381b1901bd08
--- /dev/null
+++ b/drivers/gpu/drm/tyr/debugfs.rs
@@ -0,0 +1,65 @@
+// SPDX-License-Identifier: GPL-2.0 or MIT
+
+//! Debugfs support for the Tyr DRM driver.
+
+use kernel::{
+    alloc::KVec,
+    drm,
+    new_mutex,
+    prelude::*,
+    seq_file,
+    sync::{
+        Arc,
+        Mutex, //
+    }, //
+};
+
+use crate::{
+    driver::TyrDrmDriver,
+    vm::Vm, //
+};
+
+/// Registry of VMs for debugfs access.
+#[pin_data]
+pub(crate) struct VmRegistry<'drm> {
+    #[pin]
+    vms: Mutex<KVec<Arc<Vm<'drm>>>>,
+}
+
+impl<'drm> VmRegistry<'drm> {
+    pub(crate) fn new() -> impl PinInit<Self> {
+        pin_init!(Self { vms <- new_mutex!(KVec::new()) })
+    }
+
+    pub(crate) fn register(&self, vm: Arc<Vm<'drm>>) -> Result {
+        Ok(self.vms.lock().push(vm, GFP_KERNEL)?)
+    }
+
+    fn for_each(&self, mut f: impl FnMut(&Vm<'drm>) -> Result) -> Result {
+        for vm in self.vms.lock().iter() {
+            f(vm)?;
+        }
+        Ok(())
+    }
+}
+
+/// Debugfs data associated with a device.
+///
+/// Each field corresponds to a debugfs file.
+pub(crate) struct DebugfsData<'drm> {
+    pub(crate) gpuvas: Pin<KBox<VmRegistry<'drm>>>,
+}
+
+/// `DrmSeqShow` implementation for the `gpuvas` debugfs file.
+pub(crate) struct GpuvasShow;
+
+impl drm::debugfs::DrmSeqShow<TyrDrmDriver> for GpuvasShow {
+    fn show(guard: &drm::RegistrationGuard<'_, TyrDrmDriver>, m: &seq_file::SeqFile) -> Result {
+        guard.registration_data_with(|reg_data| {
+            reg_data
+                .debugfs_data
+                .gpuvas
+                .for_each(|vm| vm.dump_gpuva_info(m))
+        })
+    }
+}
diff --git a/drivers/gpu/drm/tyr/driver.rs b/drivers/gpu/drm/tyr/driver.rs
index a6694400be659..6af3e464994b4 100644
--- a/drivers/gpu/drm/tyr/driver.rs
+++ b/drivers/gpu/drm/tyr/driver.rs
@@ -7,6 +7,7 @@
         Clk,
         OptionalClk, //
     },
+    debugfs::ScopedDir,
     device::{
         Bound,
         Core,
@@ -45,6 +46,11 @@
 };
 
 use crate::{
+    debugfs::{
+        DebugfsData,
+        GpuvasShow,
+        VmRegistry, //
+    },
     file::TyrDrmFileData,
     fw::{
         irq::{
@@ -86,6 +92,8 @@ pub(crate) struct TyrDrmRegistrationData<'drm> {
     /// Firmware sections.
     pub(crate) fw: Arc<Firmware<'drm>>,
 
+    pub(crate) debugfs_data: DebugfsData<'drm>,
+
     #[pin]
     clks: Mutex<Clocks>,
 
@@ -167,11 +175,14 @@ fn probe<'bound>(
 
         let mmu = Mmu::new(pdev.as_ref(), iomem.as_arc_borrow(), &gpu_info)?;
 
+        let vms = KBox::pin_init(VmRegistry::new(), GFP_KERNEL)?;
+
         let firmware = Firmware::new(
             pdev.as_ref(),
             iomem.clone(),
             &unreg_dev,
             mmu.as_arc_borrow(),
+            &vms,
             &gpu_info,
         )?;
 
@@ -194,6 +205,7 @@ fn probe<'bound>(
         let reg_data = pin_init!(TyrDrmRegistrationData {
                 pdev,
                 fw: firmware,
+                debugfs_data: DebugfsData { gpuvas: vms },
                 clks <- new_mutex!(Clocks {
                     core: core_clk,
                     stacks: stacks_clk,
@@ -248,6 +260,10 @@ impl drm::Driver for TyrDrmDriver {
     kernel::declare_drm_ioctls! {
         (PANTHOR_DEV_QUERY, drm_panthor_dev_query, ioctl::RENDER_ALLOW, TyrDrmFileData::dev_query),
     }
+
+    fn debugfs_init<'a>(dev: &'a drm::Device<Self, drm::Normal>, dir: &ScopedDir<'a, 'static>) {
+        dir.seq_file::<GpuvasShow, _>(c"gpuvas", dev);
+    }
 }
 
 struct Clocks {
diff --git a/drivers/gpu/drm/tyr/fw.rs b/drivers/gpu/drm/tyr/fw.rs
index 65ac18b92b4f2..3f45767e93853 100644
--- a/drivers/gpu/drm/tyr/fw.rs
+++ b/drivers/gpu/drm/tyr/fw.rs
@@ -47,6 +47,7 @@
 };
 
 use crate::{
+    debugfs::VmRegistry,
     driver::{
         IoMem,
         TyrDrmDevice, //
@@ -251,6 +252,7 @@ pub(crate) fn new(
         iomem: Arc<IoMem<'drm>>,
         ddev: &TyrDrmDevice,
         mmu: ArcBorrow<'_, Mmu<'drm>>,
+        gpuvas: &VmRegistry<'drm>,
         gpu_info: &GpuInfo,
     ) -> Result<Arc<Firmware<'drm>>> {
         let vm = Vm::new(dev, ddev, mmu, gpu_info)?;
@@ -300,6 +302,12 @@ pub(crate) fn new(
             )?)
         })();
 
+        if result.is_ok() {
+            if let Err(e) = gpuvas.register(vm.clone()) {
+                dev_warn!(dev, "failed to register VM: {e:?}\n");
+            }
+        }
+
         if result.is_err() {
             vm.kill();
         }
diff --git a/drivers/gpu/drm/tyr/tyr.rs b/drivers/gpu/drm/tyr/tyr.rs
index e7ec450bdc9c0..6eb13c15d1657 100644
--- a/drivers/gpu/drm/tyr/tyr.rs
+++ b/drivers/gpu/drm/tyr/tyr.rs
@@ -7,6 +7,7 @@
 
 use crate::driver::TyrPlatformDriver;
 
+mod debugfs;
 mod driver;
 mod file;
 mod fw;
diff --git a/drivers/gpu/drm/tyr/vm.rs b/drivers/gpu/drm/tyr/vm.rs
index 74c3d6c8efc49..927d4605b1e8d 100644
--- a/drivers/gpu/drm/tyr/vm.rs
+++ b/drivers/gpu/drm/tyr/vm.rs
@@ -401,6 +401,11 @@ pub(crate) fn activate(&self) -> Result {
             })
     }
 
+    /// Dumps GPU VA space info into a seq_file.
+    pub(crate) fn dump_gpuva_info(&self, m: &kernel::seq_file::SeqFile) -> Result {
+        self.gpuvm_unique.lock().dump_gpuva_info(m)
+    }
+
     /// Deactivate the VM by evicting it from its address space slot.
     fn deactivate(&self) -> Result {
         self.mmu.deactivate_vm(&self.as_data).inspect_err(|e| {

-- 
2.43.0

