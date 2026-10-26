From: Ke Sun <sunke@kylinos.cn>
Date: Tue, 27 Oct 2026 00:41:00 +0800
Subject: [PATCH v5 07/11] drm/tyr: add VM-related ioctls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-tyr-ioctls-v5-7-59dfe98cb003@kylinos.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793032870; l=20879;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=wO5ByhX8MEBBvyXJMM6yY0YJ8J/TfwmhgC1RrfQn9vk=;
 b=pofd/TNwUdTHWY2S5PHVvCjEbsQPcQW0VY6NtQvmnpMX79Fg0Evnl6zQQKcCUs87W4l2Y8NKM
 FN1u+rnKd+2CMHbjw8ptFDfZW8sn9iAKcN6JsRi/pyeSBcMF2wOeQ/l
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alvin Sun <alvin.sun@linux.dev>

Implement VM_CREATE, VM_DESTROY, VM_BIND and VM_GET_STATE. VM_CREATE
hands the new VM to the per-file pool and, on insertion failure, the
caller tears it down, so an aborted creation never leaks a VM.
VM_DESTROY removes the VM from the pool and kills it, even if in-flight
jobs still hold references (matching panthor: such jobs are expected
to fault). VM_BIND runs synchronously for now.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/driver.rs |  12 +-
 drivers/gpu/drm/tyr/file.rs   | 320 ++++++++++++++++++++++++++++++++++++++++--
 drivers/gpu/drm/tyr/gem.rs    |   1 -
 drivers/gpu/drm/tyr/vm.rs     |  69 +++++++--
 4 files changed, 381 insertions(+), 21 deletions(-)

diff --git a/drivers/gpu/drm/tyr/driver.rs b/drivers/gpu/drm/tyr/driver.rs
index e2b6d63491b91..c0f17bc4ce2c9 100644
--- a/drivers/gpu/drm/tyr/driver.rs
+++ b/drivers/gpu/drm/tyr/driver.rs
@@ -33,7 +33,7 @@
         Mutex, //
     },
     time,
-    types::CovariantForLt, //
+    types::ForLt, //
 };
 
 use crate::{
@@ -74,6 +74,9 @@ pub(crate) struct TyrDrmRegistrationData<'drm> {
     /// Firmware sections.
     pub(crate) fw: Firmware<'drm>,
 
+    /// Memory management unit for address space slots.
+    pub(crate) mmu: Arc<Mmu<'drm>>,
+
     #[pin]
     clks: Mutex<Clocks>,
 
@@ -172,6 +175,7 @@ fn probe<'bound>(
                     pin_init!(TyrDrmRegistrationData {
                         pdev,
                         fw: firmware,
+                        mmu,
                         clks <- new_mutex!(Clocks {
                             core: core_clk,
                             stacks: stacks_clk,
@@ -210,7 +214,7 @@ fn drop(self: Pin<&mut Self>) {}
 impl drm::Driver for TyrDrmDriver {
     type Data = ();
     type RegistrationData<'drm> = TyrDrmRegistrationData<'drm>;
-    type File = CovariantForLt!(TyrDrmFileData);
+    type File = ForLt!(TyrDrmFileData<'_>);
     type Object = Bo;
     type ParentDevice<Ctx: DeviceContext> = platform::Device<Ctx>;
 
@@ -219,6 +223,10 @@ impl drm::Driver for TyrDrmDriver {
 
     kernel::declare_drm_ioctls! {
         (PANTHOR_DEV_QUERY, drm_panthor_dev_query, ioctl::RENDER_ALLOW, TyrDrmFileData::dev_query),
+        (PANTHOR_VM_CREATE, drm_panthor_vm_create, ioctl::RENDER_ALLOW, TyrDrmFileData::vm_create),
+        (PANTHOR_VM_DESTROY, drm_panthor_vm_destroy, ioctl::RENDER_ALLOW, TyrDrmFileData::vm_destroy),
+        (PANTHOR_VM_BIND, drm_panthor_vm_bind, ioctl::RENDER_ALLOW, TyrDrmFileData::vm_bind),
+        (PANTHOR_VM_GET_STATE, drm_panthor_vm_get_state, ioctl::RENDER_ALLOW, TyrDrmFileData::vm_get_state),
     }
 }
 
diff --git a/drivers/gpu/drm/tyr/file.rs b/drivers/gpu/drm/tyr/file.rs
index 933a365cb016e..22a74b4abf3de 100644
--- a/drivers/gpu/drm/tyr/file.rs
+++ b/drivers/gpu/drm/tyr/file.rs
@@ -1,39 +1,64 @@
 // SPDX-License-Identifier: GPL-2.0 or MIT
 
+use core::mem::offset_of;
+
 use kernel::{
     drm::{
         self,
+        gem::BaseObject,
         Registered, //
     },
     prelude::*,
-    uaccess::UserSlice,
+    sizes::SizeConstants,
+    transmute::FromBytes,
+    uaccess::{
+        UserSlice,
+        UserSliceReader, //
+    },
     uapi, //
 };
 
-use crate::driver::{
-    TyrDrmDevice,
-    TyrDrmDriver,
-    TyrDrmRegistrationData, //
+use crate::{
+    driver::{
+        TyrDrmDevice,
+        TyrDrmDriver,
+        TyrDrmRegistrationData, //
+    },
+    vm::{
+        UserVaRequest,
+        Vm,
+        VmBindOpType,
+        VmMapFlags,
+        VmPool, //
+    }, //
 };
 
 #[pin_data]
-pub(crate) struct TyrDrmFileData {}
+pub(crate) struct TyrDrmFileData<'a> {
+    reg: &'a TyrDrmRegistrationData<'a>,
+
+    #[pin]
+    vm_pool: VmPool<'a>,
+}
 
 /// Convenience type alias for our DRM `File` type.
 pub(crate) type TyrDrmFile = drm::file::File<TyrDrmDriver>;
 
-impl drm::file::DriverFile<'_> for TyrDrmFileData {
+impl<'a> drm::file::DriverFile<'a> for TyrDrmFileData<'a> {
     type Driver = TyrDrmDriver;
 
     fn open(
         _device: &TyrDrmDevice<Registered>,
-        _reg_data: &TyrDrmRegistrationData<'_>,
+        reg_data: &'a TyrDrmRegistrationData<'a>,
     ) -> impl PinInit<Self, Error> {
-        Ok(Self {})
+        try_pin_init!(Self {
+            reg: reg_data,
+            vm_pool <- VmPool::new(reg_data.pdev.as_ref()),
+        })
     }
 }
 
-impl TyrDrmFileData {
+impl TyrDrmFileData<'_> {
     pub(crate) fn dev_query(
         _ddev: &TyrDrmDevice<Registered>,
         reg_data: &TyrDrmRegistrationData<'_>,
@@ -65,4 +90,279 @@ pub(crate) fn dev_query(
             }
         }
     }
+
+    pub(crate) fn vm_create(
+        ddev: &TyrDrmDevice<Registered>,
+        _reg_data: &TyrDrmRegistrationData<'_>,
+        vmcreate: &mut uapi::drm_panthor_vm_create,
+        file: &TyrDrmFile,
+    ) -> Result<u32> {
+        if vmcreate.flags != 0 {
+            dev_dbg!(
+                ddev.as_ref(),
+                "Invalid VM create flags: {:#x}\n",
+                vmcreate.flags
+            );
+            return Err(EINVAL);
+        }
+
+        let ret: Result<u32, Error> = file.inner_with(|pfile| {
+            let vm = Vm::new_for_user(
+                pfile.reg.pdev.as_ref(),
+                ddev,
+                pfile.reg.mmu.as_arc_borrow(),
+                &pfile.reg.gpu_info,
+                UserVaRequest::from_uapi(vmcreate.user_va_range),
+            )?;
+            let user_va_range = vm.layout.user.end;
+            let id = pfile.vm_pool.add(vm).map_err(|e| {
+                e.vm.kill();
+                e.error
+            })?;
+            vmcreate.user_va_range = user_va_range;
+            vmcreate.id = id;
+
+            Ok(0)
+        });
+        ret
+    }
+
+    pub(crate) fn vm_destroy(
+        ddev: &TyrDrmDevice<Registered>,
+        _reg_data: &TyrDrmRegistrationData<'_>,
+        vmdestroy: &mut uapi::drm_panthor_vm_destroy,
+        file: &TyrDrmFile,
+    ) -> Result<u32> {
+        if vmdestroy.pad != 0 {
+            dev_dbg!(
+                ddev.as_ref(),
+                "Invalid VM destroy pad: {:#x}\n",
+                vmdestroy.pad
+            );
+            return Err(EINVAL);
+        }
+
+        let ret: Result<u32, Error> = file.inner_with(|pfile| {
+            pfile.vm_pool.remove(vmdestroy.id)?;
+            Ok(0)
+        });
+        ret
+    }
+
+    pub(crate) fn vm_bind(
+        ddev: &TyrDrmDevice<Registered>,
+        _reg_data: &TyrDrmRegistrationData<'_>,
+        vmbind: &mut uapi::drm_panthor_vm_bind,
+        file: &TyrDrmFile,
+    ) -> Result<u32> {
+        let async_flag = uapi::drm_panthor_vm_bind_flags_DRM_PANTHOR_VM_BIND_ASYNC;
+
+        if vmbind.flags & !async_flag != 0 {
+            dev_dbg!(
+                ddev.as_ref(),
+                "Invalid VM_BIND flags: {:#x}\n",
+                vmbind.flags
+            );
+            return Err(EINVAL);
+        }
+
+        if vmbind.flags & async_flag != 0 {
+            dev_dbg!(ddev.as_ref(), "Async VM_BIND not supported\n");
+            return Err(EOPNOTSUPP);
+        }
+
+        let count = vmbind.ops.count as usize;
+        if count == 0 {
+            return Ok(0);
+        }
+
+        // Accept any stride that covers the trailing `syncs` array
+        // descriptor, so userspace built against older headers works.
+        static_assert!(
+            size_of::<VmBindOp>()
+                == offset_of!(uapi::drm_panthor_vm_bind_op, syncs)
+                    + size_of::<uapi::drm_panthor_obj_array>()
+        );
+        let min_size = offset_of!(uapi::drm_panthor_vm_bind_op, syncs)
+            + size_of::<uapi::drm_panthor_obj_array>();
+        if min_size > vmbind.ops.stride as usize {
+            dev_dbg!(
+                ddev.as_ref(),
+                "Invalid VM_BIND op stride {} (expected at least {})\n",
+                vmbind.ops.stride,
+                size_of::<VmBindOp>()
+            );
+            return Err(EINVAL);
+        }
+        let stride = vmbind.ops.stride as usize;
+
+        let total_len = stride.checked_mul(count).ok_or_else(|| {
+            dev_dbg!(ddev.as_ref(), "VM_BIND ops length overflow\n");
+            EINVAL
+        })?;
+        let mut reader =
+            UserSlice::new(UserPtr::from_addr(vmbind.ops.array as usize), total_len).reader();
+        let mut ops = KVec::new();
+        for _ in 0..count {
+            ops.push(reader.read::<VmBindOp>()?, GFP_KERNEL)?;
+            read_padding_zero(&mut reader, stride - size_of::<VmBindOp>())?;
+        }
+
+        let ret: Result<u32, Error> = file.inner_with(|pfile| {
+            let vm = pfile.vm_pool.get(vmbind.vm_id).ok_or_else(|| {
+                dev_dbg!(ddev.as_ref(), "Invalid VM_BIND vm_id: {}\n", vmbind.vm_id);
+                EINVAL
+            })?;
+
+            for (i, op) in ops.iter().enumerate() {
+                if let Err(e) = vm_bind_exec_op(&vm, file, op) {
+                    dev_dbg!(ddev.as_ref(), "VM_BIND op {} failed: {:?}\n", i, e);
+                    vmbind.ops.count = i as u32;
+                    return Err(e);
+                }
+            }
+
+            Ok(0)
+        });
+        ret
+    }
+
+    pub(crate) fn vm_get_state(
+        ddev: &TyrDrmDevice<Registered>,
+        _reg_data: &TyrDrmRegistrationData<'_>,
+        vmgetstate: &mut uapi::drm_panthor_vm_get_state,
+        file: &TyrDrmFile,
+    ) -> Result<u32> {
+        file.inner_with(|pfile| {
+            let vm = pfile.vm_pool.get(vmgetstate.vm_id).ok_or_else(|| {
+                dev_dbg!(
+                    ddev.as_ref(),
+                    "Invalid VM_GET_STATE vm_id: {}\n",
+                    vmgetstate.vm_id
+                );
+                EINVAL
+            })?;
+            vmgetstate.state = if vm.is_unusable() {
+                uapi::drm_panthor_vm_state_DRM_PANTHOR_VM_STATE_UNUSABLE
+            } else {
+                uapi::drm_panthor_vm_state_DRM_PANTHOR_VM_STATE_USABLE
+            };
+            Ok(0)
+        })
+    }
+}
+
+fn vm_bind_exec_op(vm: &Vm<'_>, file: &TyrDrmFile, op: &VmBindOp) -> Result {
+    if op.size == 0 {
+        return Ok(());
+    }
+
+    if op.syncs.count != 0 {
+        dev_dbg!(vm.dev(), "VM_BIND op syncs not supported\n");
+        return Err(EINVAL);
+    }
+
+    let end = match op.va.checked_add(op.size) {
+        Some(end) => end,
+        None => {
+            dev_dbg!(vm.dev(), "VM_BIND op VA range overflow\n");
+            return Err(EINVAL);
+        }
+    };
+    if op.va < vm.layout.user.start || end > vm.layout.user.end {
+        dev_dbg!(
+            vm.dev(),
+            "VM_BIND op VA range {:#x}..{:#x} outside user range\n",
+            op.va,
+            end
+        );
+        return Err(EINVAL);
+    }
+
+    if (op.va | op.size | op.bo_offset) & (u64::SZ_4K - 1) != 0 {
+        dev_dbg!(vm.dev(), "VM_BIND op not GPU-page-aligned\n");
+        return Err(EINVAL);
+    }
+
+    match VmBindOpType::try_from(op.flags) {
+        Ok(VmBindOpType::Map) => {
+            // Once the VM is unusable only MAP ops are rejected; UNMAP
+            // stays available for cleanup (see the UAPI docs).
+            if vm.is_unusable() {
+                dev_err!(vm.dev(), "VM_BIND map op on unusable VM\n");
+                return Err(EINVAL);
+            }
+
+            let map_flags = match VmMapFlags::try_from(op.flags & !VmBindOpType::MASK) {
+                Ok(flags) => flags,
+                Err(_) => {
+                    dev_dbg!(vm.dev(), "VM_BIND op invalid map flags {:#x}\n", op.flags);
+                    return Err(EINVAL);
+                }
+            };
+            let bo = crate::gem::lookup_handle(file, op.bo_handle).map_err(|_| {
+                dev_dbg!(vm.dev(), "VM_BIND op invalid BO handle {}\n", op.bo_handle);
+                EINVAL
+            })?;
+            // Validate the BO window before mapping.
+            let bo_size = bo.size() as u64;
+            if op.size > bo_size || op.bo_offset > bo_size - op.size {
+                dev_dbg!(vm.dev(), "VM_BIND op BO range out of bounds\n");
+                return Err(EINVAL);
+            }
+            vm.map_bo_range(&bo, op.bo_offset, op.size, op.va, map_flags)
+        }
+        Ok(VmBindOpType::Unmap) => {
+            // Unmap must not carry map-specific flags or BO references.
+            if op.flags & !VmBindOpType::MASK != 0 || op.bo_handle != 0 || op.bo_offset != 0 {
+                dev_dbg!(
+                    vm.dev(),
+                    "VM_BIND UNMAP carries flags/BO refs: flags={:#x} bo_handle={} bo_offset={}\n",
+                    op.flags,
+                    op.bo_handle,
+                    op.bo_offset
+                );
+                return Err(EINVAL);
+            }
+            vm.unmap_range(op.va, op.size)
+        }
+        Err(_) => {
+            dev_dbg!(
+                vm.dev(),
+                "VM_BIND op type {:#x} not supported\n",
+                op.flags & VmBindOpType::MASK
+            );
+            Err(EINVAL)
+        }
+    }
+}
+
+/// Reads `len` bytes of array padding, rejecting any nonzero byte with `E2BIG`.
+fn read_padding_zero(reader: &mut UserSliceReader, len: usize) -> Result {
+    let mut buf = [0u8; 64];
+    let mut remaining = len;
+    while remaining > 0 {
+        let chunk = remaining.min(buf.len());
+        reader.read_slice(&mut buf[..chunk])?;
+        if buf[..chunk].iter().any(|&b| b != 0) {
+            return Err(E2BIG);
+        }
+        remaining -= chunk;
+    }
+    Ok(())
 }
+
+#[repr(transparent)]
+struct VmBindOp(uapi::drm_panthor_vm_bind_op);
+
+impl core::ops::Deref for VmBindOp {
+    type Target = uapi::drm_panthor_vm_bind_op;
+
+    fn deref(&self) -> &Self::Target {
+        &self.0
+    }
+}
+
+// SAFETY: `VmBindOp` contains only integers, so any bit pattern is valid;
+// the `#[repr(transparent)]` wrapper has the same layout as the UAPI struct.
+unsafe impl FromBytes for VmBindOp {}
diff --git a/drivers/gpu/drm/tyr/gem.rs b/drivers/gpu/drm/tyr/gem.rs
index 0e0989a48678f..60f6363995a5a 100644
--- a/drivers/gpu/drm/tyr/gem.rs
+++ b/drivers/gpu/drm/tyr/gem.rs
@@ -77,7 +77,6 @@ pub(crate) fn new_object(ddev: &TyrDrmDevice, size: usize, flags: u32) -> Result
 }
 
 /// Look up a GEM object by handle for a DRM file.
-#[expect(dead_code)]
 pub(crate) fn lookup_handle(file: &TyrDrmFile, handle: u32) -> Result<ARef<Bo>> {
     Bo::lookup_handle(file, handle)
 }
diff --git a/drivers/gpu/drm/tyr/vm.rs b/drivers/gpu/drm/tyr/vm.rs
index b2fcda1e61073..5c3be79b2c595 100644
--- a/drivers/gpu/drm/tyr/vm.rs
+++ b/drivers/gpu/drm/tyr/vm.rs
@@ -54,6 +54,11 @@
     },
     sync::{
         aref::ARef,
+        atomic::{
+            Acquire,
+            Atomic,
+            Release, //
+        },
         Arc,
         ArcBorrow,
         Mutex, //
@@ -173,7 +178,6 @@ pub(crate) enum UserVaRequest {
 
 impl UserVaRequest {
     /// UAPI boundary normalization: `0` -> [`Auto`](Self::Auto).
-    #[expect(dead_code)]
     pub(crate) fn from_uapi(v: u64) -> Self {
         match NonZeroU64::new(v) {
             Some(size) => Self::Fixed(size),
@@ -182,6 +186,38 @@ pub(crate) fn from_uapi(v: u64) -> Self {
     }
 }
 
+/// Operation type, packed into the top nibble of
+/// `drm_panthor_vm_bind_op::flags`.
+#[derive(Debug, Clone, Copy, PartialEq, Eq)]
+pub(crate) enum VmBindOpType {
+    /// Map a BO range into the VM.
+    Map,
+    /// Unmap a VA range.
+    Unmap,
+}
+
+impl VmBindOpType {
+    /// Bits occupied by the op type in `drm_panthor_vm_bind_op::flags`.
+    pub(crate) const MASK: u32 =
+        uapi::drm_panthor_vm_bind_op_flags_DRM_PANTHOR_VM_BIND_OP_TYPE_MASK as u32;
+}
+
+impl TryFrom<u32> for VmBindOpType {
+    type Error = Error;
+
+    fn try_from(flags: u32) -> Result<Self, Self::Error> {
+        const MAP: u32 = uapi::drm_panthor_vm_bind_op_flags_DRM_PANTHOR_VM_BIND_OP_TYPE_MAP as u32;
+        const UNMAP: u32 =
+            uapi::drm_panthor_vm_bind_op_flags_DRM_PANTHOR_VM_BIND_OP_TYPE_UNMAP as u32;
+
+        match flags & Self::MASK {
+            MAP => Ok(Self::Map),
+            UNMAP => Ok(Self::Unmap),
+            _ => Err(EINVAL),
+        }
+    }
+}
+
 /// Final user/kernel VA layout for a VM.
 pub(crate) struct VmLayout {
     /// Full GPU VA range covered by this VM.
@@ -424,6 +460,8 @@ pub(crate) struct Vm<'drm> {
     gpuvm: ARef<GpuVm<GpuVmData<'drm>>>,
     /// VA layout for this VM.
     pub(crate) layout: VmLayout,
+    /// Whether the VM is unusable.
+    unusable: Atomic<bool>,
 }
 
 impl<'drm> Vm<'drm> {
@@ -445,7 +483,6 @@ pub(crate) fn new_for_fw(
     }
 
     /// Creates a user VM, splitting the GPU VA range per `user_va`.
-    #[expect(dead_code)]
     pub(crate) fn new_for_user(
         dev: &'drm Device<Bound>,
         ddev: &TyrDrmDevice,
@@ -512,6 +549,7 @@ fn new_internal(
                 gpuvm,
                 gpuvm_unique <- new_mutex!(gpuvm_unique),
                 layout,
+                unusable: Atomic::new(false),
             }),
             GFP_KERNEL,
         )?;
@@ -542,6 +580,7 @@ fn deactivate(&self) -> Result {
 
     /// Kills the VM by deactivating it and unmapping all regions.
     pub(crate) fn kill(&self) {
+        self.mark_unusable();
         let _ = self.deactivate();
         let _ = self
             .unmap_range(
@@ -553,6 +592,15 @@ pub(crate) fn kill(&self) {
             });
     }
 
+    /// Marks the VM unusable.
+    fn mark_unusable(&self) {
+        self.unusable.store(true, Release);
+    }
+
+    pub(crate) fn is_unusable(&self) -> bool {
+        self.unusable.load(Acquire)
+    }
+
     /// Executes a virtual memory operation.
     ///
     /// This handles both map and unmap operations by coordinating between the
@@ -664,6 +712,17 @@ pub(crate) fn map_bo_range(
         };
         let result = {
             let mut gpuvm_unique = self.gpuvm_unique.lock();
+            // Check under the GPUVM lock, which the kill path also takes to
+            // unmap, so this serializes against a concurrent teardown.
+            if self.is_unusable() {
+                dev_err!(
+                    self.dev,
+                    "Failed to map VA {:#x}..{:#x}: VM is unusable\n",
+                    req.region.start,
+                    req.region.end
+                );
+                return Err(EINVAL);
+            }
             self.exec_op(gpuvm_unique.as_mut().get_mut(), req, &mut resources)
         };
         // We flush the defer cleanup list now. Things will be different in
@@ -1100,15 +1159,12 @@ pub(crate) struct VmPool<'drm> {
 /// Error returned when a VM cannot be added to the pool. The caller
 /// owns the teardown of the VM in [`AddError::vm`].
 pub(crate) struct AddError<'drm> {
-    #[expect(dead_code)]
     pub(crate) error: Error,
-    #[expect(dead_code)]
     pub(crate) vm: Arc<Vm<'drm>>,
 }
 
 impl<'drm> VmPool<'drm> {
     /// Creates a new [`VmPool`].
-    #[expect(dead_code)]
     pub(crate) fn new(dev: &'drm Device<Bound>) -> impl PinInit<Self> {
         let ids = IdPool::new();
         pin_init!(Self {
@@ -1124,7 +1180,6 @@ pub(crate) fn new(dev: &'drm Device<Bound>) -> impl PinInit<Self> {
     /// returned in an [`AddError`] so the caller owns the teardown.
     // TODO: allocate IDs with the XArray directly (once it grows range
     // allocation, the equivalent of C's `XA_LIMIT`) and drop the IdPool.
-    #[expect(dead_code)]
     pub(crate) fn add(&self, vm: Arc<Vm<'drm>>) -> Result<u32, AddError<'drm>> {
         let id = (|| {
             let mut ids = self.ids.lock();
@@ -1174,7 +1229,6 @@ pub(crate) fn add(&self, vm: Arc<Vm<'drm>>) -> Result<u32, AddError<'drm>> {
     }
 
     /// Removes and kills the VM with the given ID.
-    #[expect(dead_code)]
     pub(crate) fn remove(&self, id: u32) -> Result<()> {
         let mut vms = self.vms.lock();
         let vm = match vms.remove(usize::from_safe_cast(id)) {
@@ -1191,7 +1245,6 @@ pub(crate) fn remove(&self, id: u32) -> Result<()> {
     }
 
     /// Gets a shared reference to the VM with the given ID.
-    #[expect(dead_code)]
     pub(crate) fn get(&self, id: u32) -> Option<Arc<Vm<'drm>>> {
         let vms = self.vms.lock();
         let borrow = vms.get(usize::from_safe_cast(id))?;

-- 
2.43.0

