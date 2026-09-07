From: Ke Sun <sunke@kylinos.cn>
Date: Tue, 08 Sep 2026 00:47:52 +0800
Subject: [PATCH v2 5/9] drm/tyr: add user and MCU VM specifications
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-tyr-ioctls-v2-5-88bea777df67@kylinos.cn>
References: <20260908-tyr-ioctls-v2-0-88bea777df67@kylinos.cn>
In-Reply-To: <20260908-tyr-ioctls-v2-0-88bea777df67@kylinos.cn>
To: rust-for-linux@vger.kernel.org
Cc: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
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
 Simona Vetter <simona@ffwll.ch>, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, dri-devel@lists.freedesktop.org, 
 Ke Sun <sunke@kylinos.cn>, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788799692; l=13328;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=LWBtN12EESI502HFoJUAp2/6XICDPpkFfaH/DGUZKa8=;
 b=IBuZp9zawXEMk1wICkFi2QOfds8vuGJyGo+EW9VIkODdbliANCbcMhXig02Eq4O31BBJhosAI
 K0BNwkW5qa3AR0pYVoCgKXO5jGq8WU2quUCUXIzgZeXRkjg2bKsr6qN
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alvin Sun <alvin.sun@linux.dev>

The MCU and user VMs need different VA layouts. Give each a dedicated
constructor: new_for_fw() builds the kernel-only 4G layout, while
new_for_user() splits the address space by task_size or a user-provided
size, rejecting oversized requests rather than clamping. The resulting
user range is what VM_CREATE reports back as user_va_range.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/fw.rs |  37 +++++-----
 drivers/gpu/drm/tyr/vm.rs | 179 +++++++++++++++++++++++++++++++++++++++++-----
 2 files changed, 178 insertions(+), 38 deletions(-)

diff --git a/drivers/gpu/drm/tyr/fw.rs b/drivers/gpu/drm/tyr/fw.rs
index 47d25c901bd01..6aba9f6e6bc63 100644
--- a/drivers/gpu/drm/tyr/fw.rs
+++ b/drivers/gpu/drm/tyr/fw.rs
@@ -51,7 +51,6 @@
         KernelBoVaAlloc, //
     },
     gpu::GpuInfo,
-
     mmu::Mmu,
     regs::{
         gpu_control::{
@@ -66,7 +65,10 @@
             JOB_IRQ_RAWSTAT, //
         }, //
     },
-    vm::Vm, //
+    vm::{
+        Vm,
+        VmOwner, //
+    }, //
 };
 
 mod parser;
@@ -149,7 +151,10 @@ pub(crate) struct Firmware<'drm> {
     iomem: Arc<IoMem<'drm>>,
 
     /// MCU VM.
-    vm: Arc<Vm<'drm>>,
+    ///
+    /// As the VM's owner, this field kills the firmware mappings when the
+    /// firmware is dropped.
+    vm: VmOwner<'drm>,
 
     /// List of firmware sections.
     #[expect(dead_code)]
@@ -160,9 +165,6 @@ impl<'drm> Drop for Firmware<'drm> {
     fn drop(&mut self) {
         // Stop the MCU before releasing its firmware mappings and memory.
         let _ = self.stop();
-
-        // AS slots retain a VM ref, we need to kill the circular ref manually.
-        self.vm.kill();
     }
 }
 
@@ -220,10 +222,10 @@ pub(crate) fn new(
         mmu: ArcBorrow<'_, Mmu<'drm>>,
         gpu_info: &GpuInfo,
     ) -> Result<Firmware<'drm>> {
-        let vm = Vm::new(dev, ddev, mmu, gpu_info)?;
+        let vm = Vm::new_for_fw(dev, ddev, mmu, gpu_info)?;
         vm.activate()?;
 
-        let result = (|| {
+        let sections = (|| -> Result<KVec<Section<'drm>>> {
             let (fw, parsed_sections) = Self::load(dev, ddev, gpu_info)?;
             let mut sections = KVec::new();
             for parsed in parsed_sections {
@@ -233,7 +235,7 @@ pub(crate) fn new(
 
                 let mut mem = KernelBo::new(
                     ddev,
-                    vm.clone(),
+                    vm.get(),
                     size,
                     KernelBoVaAlloc::Explicit(va),
                     parsed.vm_map_flags,
@@ -253,18 +255,15 @@ pub(crate) fn new(
                 sections.push(Section { data, mem }, GFP_KERNEL)?;
             }
 
-            Ok(Firmware {
-                iomem,
-                vm: vm.clone(),
-                sections,
-            })
+            Ok(sections)
         })();
 
-        if result.is_err() {
-            vm.kill();
-        }
-
-        result
+        // On error, `vm` (the owner) is dropped and kills the MCU VM.
+        Ok(Firmware {
+            iomem,
+            vm,
+            sections: sections?,
+        })
     }
 
     pub(crate) fn boot(&self) -> Result {
diff --git a/drivers/gpu/drm/tyr/vm.rs b/drivers/gpu/drm/tyr/vm.rs
index ae58135eeffdc..db9e2ccc55056 100644
--- a/drivers/gpu/drm/tyr/vm.rs
+++ b/drivers/gpu/drm/tyr/vm.rs
@@ -9,6 +9,7 @@
 
 use core::marker::PhantomData;
 use core::mem::ManuallyDrop;
+use core::num::NonZeroU64;
 use core::ops::Range;
 
 use kernel::{
@@ -45,6 +46,8 @@
     new_mutex,
     prelude::*,
     sizes::{
+        LargeSizeConstants,
+        SizeConstants,
         SZ_1G,
         SZ_2M,
         SZ_4K, //
@@ -160,6 +163,25 @@ fn try_from(value: u32) -> Result<Self, Self::Error> {
     }
 }
 
+/// User VA size request for a user VM.
+pub(crate) enum UserVaRequest {
+    /// Split based on `task_size()` and the GPU VA range.
+    Auto,
+    /// Caller-specified size; construction guarantees `> 0`.
+    Fixed(NonZeroU64),
+}
+
+impl UserVaRequest {
+    /// UAPI boundary normalization: `0` -> [`Auto`](Self::Auto).
+    #[expect(dead_code)]
+    pub(crate) fn from_uapi(v: u64) -> Self {
+        match NonZeroU64::new(v) {
+            Some(size) => Self::Fixed(size),
+            None => Self::Auto,
+        }
+    }
+}
+
 /// Owns a [`Vm`]'s destruction: the VM is killed exactly once, when this
 /// value is dropped, regardless of how many `Arc<Vm>` references remain.
 ///
@@ -169,7 +191,6 @@ fn try_from(value: u32) -> Result<Self, Self::Error> {
 
 impl<'drm> VmOwner<'drm> {
     /// A reference for callers that want to use the VM, not own it.
-    #[expect(dead_code)]
     pub(crate) fn get(&self) -> Arc<Vm<'drm>> {
         Arc::clone(&self.0)
     }
@@ -211,6 +232,84 @@ fn drop(&mut self) {
     }
 }
 
+/// Final user/kernel VA layout for a VM.
+pub(crate) struct VmLayout {
+    /// Full GPU VA range covered by this VM.
+    pub(crate) full: Range<u64>,
+    /// User-accessible VA range. Empty for MCU VMs.
+    pub(crate) user: Range<u64>,
+}
+
+impl VmLayout {
+    /// Kernel VA range, reserved for future kernel object allocation.
+    #[expect(dead_code)]
+    pub(crate) fn kernel(&self) -> Range<u64> {
+        self.user.end..self.full.end
+    }
+
+    /// Compute a user/kernel split for a user VM from the full GPU VA range and
+    /// a user request.
+    pub(crate) fn compute(full: Range<u64>, req: UserVaRequest) -> Result<Self> {
+        // Minimum VA space reserved for kernel objects (heaps, ring buffers, ...).
+        const MIN_KERNEL_VA: u64 = u64::SZ_256M;
+
+        if full.end <= MIN_KERNEL_VA {
+            pr_err!(
+                "Invalid VA range {:#x}..{:#x}, kernel VA min required: >{:#x}\n",
+                full.start,
+                full.end,
+                MIN_KERNEL_VA
+            );
+            return Err(EINVAL);
+        }
+
+        let user_max = full.end - MIN_KERNEL_VA;
+
+        let user_end = match req {
+            UserVaRequest::Fixed(v) => {
+                let user_size = v.get();
+                if user_size > user_max {
+                    pr_err!(
+                        "Requested user VA range {:#x} exceeds maximum {:#x}\n",
+                        user_size,
+                        user_max
+                    );
+                    return Err(EINVAL);
+                }
+                user_size
+            }
+            UserVaRequest::Auto => {
+                let task_size = current!().mm().map(|mm| mm.task_size());
+                let candidate = match task_size {
+                    // `task_size()` returns usize; widen to u64 for the comparison.
+                    Some(t) if (t as u64) < full.end => t as u64,
+                    None | Some(_) => {
+                        // If the range exceeds 4G, split it in two so CPU and
+                        // GPU share the same addresses (SVM).
+                        if full.end > u64::SZ_4G {
+                            full.end / 2
+                        } else {
+                            user_max
+                        }
+                    }
+                };
+                candidate.min(user_max)
+            }
+        };
+
+        let delta = full.end - user_end;
+        // Pick a kernel VA range that's a power of two, to have a clear split.
+        let kernel_va_range = 1u64 << delta.ilog2();
+        let kernel_va_start = full.end - kernel_va_range;
+        let full_start = full.start;
+
+        Ok(Self {
+            full,
+            user: full_start..kernel_va_start,
+        })
+    }
+}
+
 /// Arguments for a virtual memory map operation.
 struct VmMapArgs<'drm> {
     /// Access permissions and caching behavior for the mapping.
@@ -386,26 +485,64 @@ pub(crate) struct Vm<'drm> {
     /// Non-core part of the GPUVM. Can be used for stuff that doesn't modify the
     /// internal mapping tree, like GpuVm::obtain()
     gpuvm: ARef<GpuVm<GpuVmData<'drm>>>,
-    /// VA range for this VM.
-    va_range: Range<u64>,
+    /// VA layout for this VM.
+    pub(crate) layout: VmLayout,
 }
 
 impl<'drm> Vm<'drm> {
-    /// Creates a new GPU virtual address space.
+    /// Creates the MCU/firmware VM.
     ///
-    /// The VM is initialized with a page table configured according to the GPU's
-    /// address translation capabilities and registered with the GPUVM framework.
-    pub(crate) fn new(
+    /// The MCU VM is entirely kernel-managed: it has no user-accessible range.
+    pub(crate) fn new_for_fw(
+        dev: &'drm Device<Bound>,
+        ddev: &TyrDrmDevice,
+        mmu: ArcBorrow<'_, Mmu<'drm>>,
+        gpu_info: &GpuInfo,
+    ) -> Result<VmOwner<'drm>> {
+        // As in panthor: the CSF MCU is a Cortex-M7 and can only address 4G.
+        let layout = VmLayout {
+            full: 0..u64::SZ_4G,
+            user: 0..0u64,
+        };
+        Self::new_internal(dev, ddev, mmu, gpu_info, layout)
+    }
+
+    /// Creates a user VM, splitting the GPU VA range per `user_va`.
+    #[expect(dead_code)]
+    pub(crate) fn new_for_user(
         dev: &'drm Device<Bound>,
         ddev: &TyrDrmDevice,
         mmu: ArcBorrow<'_, Mmu<'drm>>,
         gpu_info: &GpuInfo,
-    ) -> Result<Arc<Vm<'drm>>> {
+        user_va: UserVaRequest,
+    ) -> Result<VmOwner<'drm>> {
+        let mmu_features = MMU_FEATURES::from_raw(gpu_info.mmu_features);
+        let va_bits = mmu_features.va_bits().get();
+        let range = 0..(1u64 << va_bits);
+
+        let layout = VmLayout::compute(range.clone(), user_va).inspect_err(|_| {
+            dev_err!(
+                dev,
+                "Failed to split GPU VA range {:#x}..{:#x} into user and kernel regions\n",
+                range.start,
+                range.end
+            );
+        })?;
+        Self::new_internal(dev, ddev, mmu, gpu_info, layout)
+    }
+
+    /// Initializes a VM with the given layout and hands back its owner.
+    fn new_internal(
+        dev: &'drm Device<Bound>,
+        ddev: &TyrDrmDevice,
+        mmu: ArcBorrow<'_, Mmu<'drm>>,
+        gpu_info: &GpuInfo,
+        layout: VmLayout,
+    ) -> Result<VmOwner<'drm>> {
         let mmu_features = MMU_FEATURES::from_raw(gpu_info.mmu_features);
         let va_bits = mmu_features.va_bits().get();
         let pa_bits = mmu_features.pa_bits().get();
 
-        let range = 0..(1u64 << va_bits);
         let reserve_range = 0..0u64;
 
         // dummy_obj is used to initialize the GPUVM tree.
@@ -417,7 +554,7 @@ pub(crate) fn new(
             c"Tyr::GpuVm",
             ddev,
             &*dummy_obj,
-            range.clone(),
+            layout.full.clone(),
             reserve_range,
             GpuVmData::<'drm> {
                 _phantom: PhantomData::<&()>,
@@ -437,12 +574,12 @@ pub(crate) fn new(
                 mmu: mmu.into(),
                 gpuvm,
                 gpuvm_unique <- new_mutex!(gpuvm_unique),
-                va_range: range,
+                layout,
             }),
             GFP_KERNEL,
         )?;
 
-        Ok(vm)
+        Ok(VmOwner(ManuallyDrop::new(vm)))
     }
 
     /// Returns the parent device used by this VM for DMA mapping and page-table operations.
@@ -467,11 +604,15 @@ fn deactivate(&self) -> Result {
     }
 
     /// Kills the VM by deactivating it and unmapping all regions.
-    pub(crate) fn kill(&self) {
-        // TODO: Turn the VM into a state where it can't be used.
+    ///
+    /// Only called from [`VmOwner`]'s `Drop`.
+    fn kill(&self) {
         let _ = self.deactivate();
         let _ = self
-            .unmap_range(self.va_range.start, self.va_range.end - self.va_range.start)
+            .unmap_range(
+                self.layout.full.start,
+                self.layout.full.end - self.layout.full.start,
+            )
             .inspect_err(|e| {
                 dev_err!(self.dev, "Failed to unmap range during deactivate: {:?}", e);
             });
@@ -608,14 +749,14 @@ pub(crate) fn unmap_range(&self, va: u64, size: u64) -> Result {
 
         let end = va.checked_add(size).ok_or(EINVAL)?;
 
-        if va < self.va_range.start || end > self.va_range.end {
+        if va < self.layout.full.start || end > self.layout.full.end {
             dev_err!(
                 self.dev,
                 "Unmap range {:#x}..{:#x} exceeds VM range {:#x}..{:#x}",
                 va,
                 end,
-                self.va_range.start,
-                self.va_range.end
+                self.layout.full.start,
+                self.layout.full.end
             );
             return Err(EINVAL);
         }
@@ -625,7 +766,7 @@ pub(crate) fn unmap_range(&self, va: u64, size: u64) -> Result {
             region: va..end,
         };
 
-        let full_vm = va == self.va_range.start && end == self.va_range.end;
+        let full_vm = va == self.layout.full.start && end == self.layout.full.end;
 
         let mut resources = VmOpResources {
             preallocated_gpuvas: if full_vm {

-- 
2.43.0

