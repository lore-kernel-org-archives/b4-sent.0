From: Ke Sun <sunke@kylinos.cn>
Date: Tue, 20 Oct 2026 16:25:21 +0800
Subject: [PATCH v4 04/11] drm/tyr: add per-file VM pool
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-tyr-ioctls-v4-4-704de77da223@kylinos.cn>
References: <20261020-tyr-ioctls-v4-0-704de77da223@kylinos.cn>
In-Reply-To: <20261020-tyr-ioctls-v4-0-704de77da223@kylinos.cn>
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
 linux-kernel@vger.kernel.org, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792484721; l=6136;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=rJMDF0E+r5CboO26qM5Av79VG6Xqis2m0v/SvkplpIY=;
 b=o8eHUnvbgftKrmserToYOPjYqdYw5svjt/W7B+4ZCNdVZW9SKp0WIFIA/p2BzF5VSPGuy/PgN
 S12ippHW8iRCiV9PEamc8sQWo1jZsgV/Ec28IJnLIDblWQEl15ddZcH
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alvin Sun <alvin.sun@linux.dev>

Userspace needs multiple independent GPU address spaces per file,
addressed by ID through the VM ioctls as in panthor. Store them in an
IdPool (capped at 32 for panthor parity) plus an XArray. On a failed
insertion the caller tears the VM down through the returned error, so
an aborted creation never leaks a VM. The pool kills every VM still
stored when the file closes.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/vm.rs | 138 +++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 137 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/tyr/vm.rs b/drivers/gpu/drm/tyr/vm.rs
index c5e307b1e2416..6935e4db667b9 100644
--- a/drivers/gpu/drm/tyr/vm.rs
+++ b/drivers/gpu/drm/tyr/vm.rs
@@ -33,6 +33,7 @@
         }, //
     },
     fmt,
+    id_pool::IdPool,
     impl_flags,
     io::PhysAddr,
     iommu::pgtable::{
@@ -53,7 +54,11 @@
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
@@ -948,3 +953,134 @@ fn pt_unmap(dev: &Device, pt: &IoPageTable<'_, ARM64LPAES1>, range: Range<u64>)
 
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
+    /// Parent device, for error reporting.
+    dev: &'drm Device<Bound>,
+    #[pin]
+    ids: Mutex<IdPool>,
+    #[pin]
+    vms: XArray<Arc<Vm<'drm>>>,
+}
+
+/// Error returned when a VM cannot be added to the pool. The caller
+/// owns the teardown of the VM in [`AddError::vm`].
+pub(crate) struct AddError<'drm> {
+    pub(crate) error: Error,
+    pub(crate) vm: Arc<Vm<'drm>>,
+}
+
+impl<'drm> VmPool<'drm> {
+    /// Creates a new [`VmPool`].
+    #[expect(dead_code)]
+    pub(crate) fn new(dev: &'drm Device<Bound>) -> impl PinInit<Self> {
+        let ids = IdPool::new();
+        pin_init!(Self {
+            dev,
+            ids <- new_mutex!(ids),
+            vms <- XArray::new(AllocKind::Alloc),
+        })
+    }
+
+    /// Stores the VM and returns the allocated ID.
+    ///
+    /// On failure - ID space exhausted or a store failure - the VM is
+    /// returned in an [`AddError`] so the caller owns the teardown.
+    // TODO: allocate IDs with the XArray directly (once it grows range
+    // allocation, the equivalent of C's `XA_LIMIT`) and drop the IdPool.
+    #[expect(dead_code)]
+    pub(crate) fn add(&self, vm: Arc<Vm<'drm>>) -> Result<u32, AddError<'drm>> {
+        let id = (|| {
+            let mut ids = self.ids.lock();
+            let unused = ids.find_unused_id(1).ok_or(ENOSPC)?;
+            if unused.as_usize() > MAX_VMS_PER_FILE {
+                return Err(ENOSPC);
+            }
+            Ok(unused.acquire())
+        })();
+        let id = match id {
+            Ok(id) => id,
+            Err(error) => return Err(AddError { error, vm }),
+        };
+
+        let mut vms = self.vms.lock();
+        match vms.store(id, vm, GFP_KERNEL) {
+            Ok(prev_vm) => {
+                if let Some(prev_vm) = prev_vm {
+                    // An existing VM at the freshly allocated slot means the
+                    // IdPool and the XArray are out of sync: the stored VM is
+                    // a pool entry, so the pool kills it and the caller's VM
+                    // is handed back for the caller to kill.
+                    let stored = vms.remove(id);
+                    drop(vms);
+                    prev_vm.kill();
+                    self.ids.lock().release_id(id);
+                    dev_err!(
+                        self.dev,
+                        "IdPool/XArray out of sync at VM pool id {id} (stored VM conflict)"
+                    );
+                    return Err(AddError {
+                        error: EBUSY,
+                        vm: stored.expect("VM was just stored"),
+                    });
+                }
+                Ok(id as u32)
+            }
+            Err(err) => {
+                // Drop the XArray spinlock before acquiring the `ids` mutex.
+                drop(vms);
+                // Release the pooled id; the VM never entered the pool, so it
+                // is returned to the caller for teardown.
+                self.ids.lock().release_id(id);
+                Err(AddError { error: err.error, vm: err.value })
+            }
+        }
+    }
+
+    /// Removes and kills the VM with the given ID.
+    #[expect(dead_code)]
+    pub(crate) fn remove(&self, id: u32) -> Result<()> {
+        let mut vms = self.vms.lock();
+        let vm = match vms.remove(id as usize) {
+            Some(vm) => vm,
+            None => return Err(EINVAL),
+        };
+        // Drop the XArray spinlock before killing, since `kill()` may sleep.
+        drop(vms);
+        // Kill the VM before handing the id back to the pool, so a VM is
+        // never reusable while still alive.
+        vm.kill();
+        self.ids.lock().release_id(id as usize);
+        Ok(())
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
+        // Kill every VM left in the pool. The ID range is bounded by
+        // `MAX_VMS_PER_FILE`, so this loop is cheap and runs at file close.
+        for id in 1..=MAX_VMS_PER_FILE {
+            // Release the XArray lock guard before killing: `kill()` may sleep.
+            let vm = this.vms.lock().remove(id);
+            if let Some(vm) = vm {
+                vm.kill();
+            }
+        }
+    }
+}

-- 
2.43.0

