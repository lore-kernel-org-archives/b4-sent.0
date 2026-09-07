From: Ke Sun <sunke@kylinos.cn>
Date: Tue, 08 Sep 2026 00:47:51 +0800
Subject: [PATCH v2 4/9] drm/tyr: add per-file VM pool
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-tyr-ioctls-v2-4-88bea777df67@kylinos.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788799692; l=6892;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=E5fAToBpW3fHYqXQ6LGiOZHomFP/OX5vReY6bzJsSvg=;
 b=/QTBTvhX2T9UgC1tr/jeIEsYz/XsFx949EuBDEIsCSIpGS0QvOWaEgti35ACCW4yDWb3TyIiN
 cmwwPpJeyItAczO/lPVp4oRzhYzxwsRNOtPfoGmGNyPagUZbuQnAzCk
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alvin Sun <alvin.sun@linux.dev>

Userspace needs multiple independent GPU address spaces per file,
addressed by ID through the VM ioctls as in panthor. Store them in an
IdPool (capped at 32 for panthor parity) plus an XArray. Each VM is
stored with its VmOwner, so it is killed exactly once - on destroy or
file close - regardless of remaining shared references.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/vm.rs | 157 +++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 156 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/tyr/vm.rs b/drivers/gpu/drm/tyr/vm.rs
index c5e307b1e2416..ae58135eeffdc 100644
--- a/drivers/gpu/drm/tyr/vm.rs
+++ b/drivers/gpu/drm/tyr/vm.rs
@@ -8,6 +8,7 @@
 //! mapped into hardware address space (AS) slots for GPU execution.
 
 use core::marker::PhantomData;
+use core::mem::ManuallyDrop;
 use core::ops::Range;
 
 use kernel::{
@@ -33,6 +34,7 @@
         }, //
     },
     fmt,
+    id_pool::IdPool,
     impl_flags,
     io::PhysAddr,
     iommu::pgtable::{
@@ -53,7 +55,11 @@
         ArcBorrow,
         Mutex, //
     },
-    uapi, //
+    uapi,
+    xarray::{
+        AllocKind,
+        XArray, //
+    }, //
 };
 
 use crate::{
@@ -154,6 +160,57 @@ fn try_from(value: u32) -> Result<Self, Self::Error> {
     }
 }
 
+/// Owns a [`Vm`]'s destruction: the VM is killed exactly once, when this
+/// value is dropped, regardless of how many `Arc<Vm>` references remain.
+///
+/// Callers that only need to use the VM take an `Arc<Vm>` via
+/// [`VmOwner::get()`], which keeps it alive but does not kill it.
+pub(crate) struct VmOwner<'drm>(ManuallyDrop<Arc<Vm<'drm>>>);
+
+impl<'drm> VmOwner<'drm> {
+    /// A reference for callers that want to use the VM, not own it.
+    #[expect(dead_code)]
+    pub(crate) fn get(&self) -> Arc<Vm<'drm>> {
+        Arc::clone(&self.0)
+    }
+
+    /// Transfers the VM to the pool without killing it, leaving only the
+    /// shared reference. The pool reconstructs the owner with
+    /// [`VmOwner::from_shared()`] when the VM is removed.
+    fn into_shared(mut self) -> Arc<Vm<'drm>> {
+        // SAFETY: `self.0` is initialized, and `forget(self)` below prevents
+        // the outer wrapper from being dropped, so the taken `Arc` is moved
+        // out exactly once and nothing is leaked or double-dropped.
+        let vm = unsafe { ManuallyDrop::take(&mut self.0) };
+        core::mem::forget(self);
+        vm
+    }
+
+    /// Reconstructs an owner from a shared reference.
+    ///
+    /// The caller must currently own the VM's destruction.
+    fn from_shared(vm: Arc<Vm<'drm>>) -> Self {
+        Self(ManuallyDrop::new(vm))
+    }
+}
+
+impl<'drm> core::ops::Deref for VmOwner<'drm> {
+    type Target = Vm<'drm>;
+
+    fn deref(&self) -> &Vm<'drm> {
+        &self.0
+    }
+}
+
+impl Drop for VmOwner<'_> {
+    fn drop(&mut self) {
+        self.0.kill();
+        // SAFETY: `self.0` is initialized and we are in `drop`, so it is safe
+        // to drop the inner `Arc` now that the VM has been killed.
+        unsafe { ManuallyDrop::drop(&mut self.0) };
+    }
+}
+
 /// Arguments for a virtual memory map operation.
 struct VmMapArgs<'drm> {
     /// Access permissions and caching behavior for the mapping.
@@ -948,3 +1005,101 @@ fn pt_unmap(dev: &Device, pt: &IoPageTable<'_, ARM64LPAES1>, range: Range<u64>)
 
     Ok(())
 }
+
+/// Maximum number of VMs a single file may hold, matching panthor's
+/// `PANTHOR_MAX_VMS_PER_FILE`.
+const MAX_VMS_PER_FILE: usize = 32;
+
+/// Per-open-file pool of VMs.
+#[pin_data(PinnedDrop)]
+pub(crate) struct VmPool<'drm> {
+    #[pin]
+    ids: Mutex<IdPool>,
+    #[pin]
+    vms: XArray<Arc<Vm<'drm>>>,
+}
+
+impl<'drm> VmPool<'drm> {
+    /// Creates a new [`VmPool`].
+    #[expect(dead_code)]
+    pub(crate) fn new() -> impl PinInit<Self> {
+        let ids = IdPool::new();
+        pin_init!(Self {
+            ids <- new_mutex!(ids),
+            vms <- XArray::new(AllocKind::Alloc),
+        })
+    }
+
+    /// Takes ownership of `vm` and stores it, returning the allocated ID.
+    ///
+    /// On failure - ID space exhausted or store failure - the VM is killed
+    /// here and only the error is returned.
+    // TODO: allocate IDs with the XArray directly (once it grows range
+    // allocation, the equivalent of C's `XA_LIMIT`) and drop the IdPool.
+    #[expect(dead_code)]
+    pub(crate) fn add(&self, vm: VmOwner<'drm>) -> Result<u32> {
+        let id = {
+            let mut ids = self.ids.lock();
+            let unused = ids.find_unused_id(1).ok_or(ENOSPC)?;
+            if unused.as_usize() > MAX_VMS_PER_FILE {
+                return Err(ENOSPC);
+            }
+            unused.acquire()
+        };
+
+        let vm = vm.into_shared();
+        let mut vms = self.vms.lock();
+        match vms.store(id, vm, GFP_KERNEL) {
+            Ok(prev_vm) => {
+                drop(prev_vm);
+                Ok(id as u32)
+            }
+            Err(err) => {
+                // Drop the XArray spinlock before acquiring the `ids` mutex.
+                drop(vms);
+                // Kill the VM and release the pooled id before returning.
+                drop(VmOwner::from_shared(err.value));
+                self.ids.lock().release_id(id);
+                Err(err.error)
+            }
+        }
+    }
+
+    /// Removes the VM with the given ID, handing back its owner.
+    ///
+    /// Dropping the returned [`VmOwner`] kills the VM immediately.
+    #[expect(dead_code)]
+    pub(crate) fn remove(&self, id: u32) -> Result<VmOwner<'drm>> {
+        let mut vms = self.vms.lock();
+        match vms.remove(id as usize) {
+            Some(vm) => {
+                drop(vms);
+                self.ids.lock().release_id(id as usize);
+                Ok(VmOwner::from_shared(vm))
+            }
+            None => Err(EINVAL),
+        }
+    }
+
+    /// Gets a shared reference to the VM with the given ID.
+    #[expect(dead_code)]
+    pub(crate) fn get(&self, id: u32) -> Option<Arc<Vm<'drm>>> {
+        let vms = self.vms.lock();
+        let borrow = vms.get(id as usize)?;
+        Some(Arc::from(borrow))
+    }
+}
+
+#[pinned_drop]
+impl PinnedDrop for VmPool<'_> {
+    fn drop(self: Pin<&mut Self>) {
+        let this = self.project();
+        // Kill every VM still owned by the pool. The ID range is bounded by
+        // `MAX_VMS_PER_FILE`, so this loop is cheap and runs at file close.
+        for id in 1..=MAX_VMS_PER_FILE {
+            // Release the XArray lock guard before killing: `kill()` may sleep.
+            let vm = this.vms.lock().remove(id);
+            drop(vm.map(VmOwner::from_shared));
+        }
+    }
+}

-- 
2.43.0

