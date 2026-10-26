From: Ke Sun <sunke@kylinos.cn>
Date: Tue, 27 Oct 2026 00:41:03 +0800
Subject: [PATCH v5 10/11] drm/tyr: gem: flush write-combine BOs from
 probe-time coherence
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-tyr-ioctls-v5-10-59dfe98cb003@kylinos.cn>
References: <20261027-tyr-ioctls-v5-0-59dfe98cb003@kylinos.cn>
In-Reply-To: <20261027-tyr-ioctls-v5-0-59dfe98cb003@kylinos.cn>
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
 Lorenzo Stoakes <ljs@kernel.org>, Lyude Paul <lyude@redhat.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>
Cc: Sami Tolvanen <samitolvanen@google.com>, rust-for-linux@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, driver-core@lists.linux.dev, 
 Ke Sun <sunke@kylinos.cn>, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793032870; l=9726;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=WTCCiW45KNyulvM4+A7xNmlcKjm/jh90uXe+LDeJ+2g=;
 b=qZFdthzUHROr6eAi7JzFBQ6H492moXwX5AjdC6T5QxRkLvvrlf5xUmwP37xTsvl8PbGh/bCl8
 EqXie58rx2ZAgQun3wo0E/MS1523YzdcBf7o96i+bWdcBiKOIdvB+yK
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

Tyr maps shmem-backed buffers write-combine, but the shmem layer
zero-inits new pages through a cached mapping. On a non-coherent device
those stale cache lines can land over later uncached writes, so the GPU
or userspace reads a freshly written value back as zero.

Read the device's coherence once at probe and map buffers write-back
when it's coherent, write-combine otherwise. BO_CREATE fetches the
sgtable at creation time so dma_map_sgtable() flushes the zeroed pages
before anyone accesses them uncached.

Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
[ Drop the map_wc-conditional sg_table call, now fetched
  unconditionally in BO_CREATE. - Alvin ]
Co-developed-by: Alvin Sun <alvin.sun@linux.dev>
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/driver.rs | 10 ++++++++++
 drivers/gpu/drm/tyr/file.rs   |  5 +++--
 drivers/gpu/drm/tyr/fw.rs     |  4 +++-
 drivers/gpu/drm/tyr/gem.rs    | 34 +++++++++++++++++++++++++---------
 drivers/gpu/drm/tyr/vm.rs     |  9 ++++++---
 5 files changed, 47 insertions(+), 15 deletions(-)

diff --git a/drivers/gpu/drm/tyr/driver.rs b/drivers/gpu/drm/tyr/driver.rs
index f4f31b24180b4..633d1cab3cea9 100644
--- a/drivers/gpu/drm/tyr/driver.rs
+++ b/drivers/gpu/drm/tyr/driver.rs
@@ -88,6 +88,12 @@ pub(crate) struct TyrDrmRegistrationData<'drm> {
 
     /// GPU information read from hardware during probe.
     pub(crate) gpu_info: GpuInfo,
+
+    /// Whether the device is reported as DMA-coherent by firmware.
+    ///
+    /// Cached at probe via `device_get_dma_attr()`. Drives the BO
+    /// cacheability policy in `crate::gem::should_map_wc`.
+    pub(crate) coherent: bool,
 }
 
 fn issue_soft_reset(dev: &Device, iomem: &IoMem<'_>) -> Result {
@@ -152,6 +158,8 @@ fn probe<'bound>(
             // other threads of execution.
             unsafe { pdev.dma_set_mask_and_coherent(DmaMask::try_new(pa_bits)?)? };
 
+            let coherent = pdev.as_ref().dma_attr().is_coherent();
+
             let unreg_dev = drm::UnregisteredDevice::<TyrDrmDriver>::new(pdev, Ok(()))?;
 
             let mmu = Mmu::new(pdev.as_ref(), iomem.as_arc_borrow(), &gpu_info)?;
@@ -162,6 +170,7 @@ fn probe<'bound>(
                 &unreg_dev,
                 mmu.as_arc_borrow(),
                 &gpu_info,
+                coherent,
             )?;
 
             firmware.boot()?;
@@ -187,6 +196,7 @@ fn probe<'bound>(
                         }),
                         iomem,
                         gpu_info,
+                        coherent,
                     }),
                 )},
                 _: { dev_dbg!(pdev, "Tyr initialized correctly.") },
diff --git a/drivers/gpu/drm/tyr/file.rs b/drivers/gpu/drm/tyr/file.rs
index 9ffb42f0d8851..d4d6a6742b2e1 100644
--- a/drivers/gpu/drm/tyr/file.rs
+++ b/drivers/gpu/drm/tyr/file.rs
@@ -113,6 +113,7 @@ pub(crate) fn vm_create(
                 pfile.reg.mmu.as_arc_borrow(),
                 &pfile.reg.gpu_info,
                 UserVaRequest::from_uapi(vmcreate.user_va_range),
+                pfile.reg.coherent,
             )?;
             let user_va_range = vm.layout.user.end;
             let id = pfile.vm_pool.add(vm).map_err(|e| {
@@ -253,7 +254,7 @@ pub(crate) fn vm_get_state(
 
     pub(crate) fn bo_create(
         ddev: &TyrDrmDevice<Registered>,
-        _reg_data: &TyrDrmRegistrationData<'_>,
+        reg_data: &TyrDrmRegistrationData<'_>,
         bocreate: &mut uapi::drm_panthor_bo_create,
         file: &TyrDrmFile,
     ) -> Result<u32> {
@@ -284,7 +285,7 @@ pub(crate) fn bo_create(
             );
             EINVAL
         })?;
-        let bo = crate::gem::new_object(ddev, size, bocreate.flags)?;
+        let bo = crate::gem::new_object(ddev, size, bocreate.flags, reg_data.coherent)?;
         bocreate.handle = bo.create_handle(file)?;
         bocreate.size = bo.size() as u64;
 
diff --git a/drivers/gpu/drm/tyr/fw.rs b/drivers/gpu/drm/tyr/fw.rs
index 81e8103368bc2..b24560ae10a4e 100644
--- a/drivers/gpu/drm/tyr/fw.rs
+++ b/drivers/gpu/drm/tyr/fw.rs
@@ -217,8 +217,9 @@ pub(crate) fn new(
         ddev: &TyrDrmDevice,
         mmu: ArcBorrow<'_, Mmu<'drm>>,
         gpu_info: &GpuInfo,
+        coherent: bool,
     ) -> Result<Firmware<'drm>> {
-        let vm = Vm::new_for_fw(dev, ddev, mmu, gpu_info)?;
+        let vm = Vm::new_for_fw(dev, ddev, mmu, gpu_info, coherent)?;
         vm.activate()?;
 
         let sections = (|| -> Result<KVec<Section<'drm>>> {
@@ -235,6 +236,7 @@ pub(crate) fn new(
                     size,
                     KernelBoVaAlloc::Explicit(va),
                     parsed.vm_map_flags,
+                    coherent,
                 )?;
 
                 let section_start = parsed.data_range.start as usize;
diff --git a/drivers/gpu/drm/tyr/gem.rs b/drivers/gpu/drm/tyr/gem.rs
index 14f3e182b98e2..fad0720ce7123 100644
--- a/drivers/gpu/drm/tyr/gem.rs
+++ b/drivers/gpu/drm/tyr/gem.rs
@@ -63,19 +63,35 @@ fn new(_dev: &TyrDrmDevice, _size: usize, args: BoCreateArgs) -> impl PinInit<Se
 /// Type alias for Tyr GEM buffer objects.
 pub(crate) type Bo = gem::shmem::Object<BoData>;
 
+/// Returns whether a BO should be mapped write-combine given the device's
+/// DMA coherence.
+pub(crate) fn should_map_wc(coherent: bool) -> bool {
+    if coherent {
+        return false;
+    }
+
+    true
+}
+
 /// Create a new GEM buffer object.
-pub(crate) fn new_object(ddev: &TyrDrmDevice, size: usize, flags: u32) -> Result<ARef<Bo>> {
+pub(crate) fn new_object(
+    ddev: &TyrDrmDevice,
+    size: usize,
+    flags: u32,
+    coherent: bool,
+) -> Result<ARef<Bo>> {
     if size == 0 {
         return Err(EINVAL);
     }
 
     let aligned_size = size.checked_next_multiple_of(PAGE_SIZE).ok_or(EINVAL)?;
 
+    let map_wc = should_map_wc(coherent);
     let bo = Bo::new(
         ddev,
         aligned_size,
         shmem::ObjectConfig {
-            map_wc: true,
+            map_wc,
             parent_resv_obj: None,
         },
         BoCreateArgs { flags },
@@ -94,18 +110,17 @@ pub(crate) fn lookup_handle(file: &TyrDrmFile, handle: u32) -> Result<ARef<Bo>>
 }
 
 /// Creates a dummy GEM object to serve as the root of a GPUVM.
-pub(crate) fn new_dummy_object(ddev: &TyrDrmDevice) -> Result<ARef<Bo>> {
-    let bo = Bo::new(
+pub(crate) fn new_dummy_object(ddev: &TyrDrmDevice, coherent: bool) -> Result<ARef<Bo>> {
+    // FIXME: use a Rust resv-object abstraction once available, rather than a real BO.
+    Bo::new(
         ddev,
         4096,
         shmem::ObjectConfig {
-            map_wc: true,
+            map_wc: should_map_wc(coherent),
             parent_resv_obj: None,
         },
         BoCreateArgs { flags: 0 },
-    )?;
-
-    Ok(bo)
+    )
 }
 
 /// Specifies how to choose a GPU virtual address for a [`KernelBo`].
@@ -143,6 +158,7 @@ pub(crate) fn new(
         size: u64,
         va_alloc: KernelBoVaAlloc,
         flags: VmMapFlags,
+        coherent: bool,
     ) -> Result<Self> {
         if size == 0 {
             dev_err!(vm.dev(), "Cannot create KernelBo with size 0");
@@ -158,7 +174,7 @@ pub(crate) fn new(
             ddev,
             bo_size,
             shmem::ObjectConfig {
-                map_wc: true,
+                map_wc: should_map_wc(coherent),
                 parent_resv_obj: None,
             },
             BoCreateArgs { flags: 0 },
diff --git a/drivers/gpu/drm/tyr/vm.rs b/drivers/gpu/drm/tyr/vm.rs
index 5c3be79b2c595..fc034514c2ce9 100644
--- a/drivers/gpu/drm/tyr/vm.rs
+++ b/drivers/gpu/drm/tyr/vm.rs
@@ -473,13 +473,14 @@ pub(crate) fn new_for_fw(
         ddev: &TyrDrmDevice,
         mmu: ArcBorrow<'_, Mmu<'drm>>,
         gpu_info: &GpuInfo,
+        coherent: bool,
     ) -> Result<Arc<Vm<'drm>>> {
         // As in panthor: the CSF MCU is a Cortex-M7 and can only address 4G.
         let layout = VmLayout {
             full: 0..u64::SZ_4G,
             user: 0..0u64,
         };
-        Self::new_internal(dev, ddev, mmu, gpu_info, layout)
+        Self::new_internal(dev, ddev, mmu, gpu_info, layout, coherent)
     }
 
     /// Creates a user VM, splitting the GPU VA range per `user_va`.
@@ -489,6 +490,7 @@ pub(crate) fn new_for_user(
         mmu: ArcBorrow<'_, Mmu<'drm>>,
         gpu_info: &GpuInfo,
         user_va: UserVaRequest,
+        coherent: bool,
     ) -> Result<Arc<Vm<'drm>>> {
         let mmu_features = MMU_FEATURES::from_raw(gpu_info.mmu_features);
         let va_bits = mmu_features.va_bits().get();
@@ -502,7 +504,7 @@ pub(crate) fn new_for_user(
                 range.end
             );
         })?;
-        Self::new_internal(dev, ddev, mmu, gpu_info, layout)
+        Self::new_internal(dev, ddev, mmu, gpu_info, layout, coherent)
     }
 
     /// Initializes a VM with the given layout.
@@ -512,6 +514,7 @@ fn new_internal(
         mmu: ArcBorrow<'_, Mmu<'drm>>,
         gpu_info: &GpuInfo,
         layout: VmLayout,
+        coherent: bool,
     ) -> Result<Arc<Vm<'drm>>> {
         let mmu_features = MMU_FEATURES::from_raw(gpu_info.mmu_features);
         let va_bits = mmu_features.va_bits().get();
@@ -520,7 +523,7 @@ fn new_internal(
         let reserve_range = 0..0u64;
 
         // dummy_obj is used to initialize the GPUVM tree.
-        let dummy_obj = gem::new_dummy_object(ddev).inspect_err(|e| {
+        let dummy_obj = gem::new_dummy_object(ddev, coherent).inspect_err(|e| {
             dev_err!(dev, "Failed to create dummy GEM object: {:?}", e);
         })?;
 

-- 
2.43.0

