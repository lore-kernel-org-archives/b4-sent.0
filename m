From: Ke Sun <sunke@kylinos.cn>
Date: Wed, 02 Sep 2026 00:09:03 +0800
Subject: [PATCH 4/9] drm/tyr: add per-file VM pool
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-tyr-ioctls-v1-4-e0fdbf8bd108@kylinos.cn>
References: <20260902-tyr-ioctls-v1-0-e0fdbf8bd108@kylinos.cn>
In-Reply-To: <20260902-tyr-ioctls-v1-0-e0fdbf8bd108@kylinos.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788278954; l=3857;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=GYNt5fASDjvzxxgWZLDWPIxhdkvjI20iaVSTTPTfRwI=;
 b=zNDRrCK4SuOMnUEDGOcfEfklYsW34X7DcrbeHuulWK+S9BJ2TEp/jQ1FknCrKMDLdreWsyCD/
 nGswWYrR5lrDce2bdKmuXNKhOd67JYC7lkzIJftaHcELHGgPGNrZ0Jc
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alvin Sun <alvin.sun@linux.dev>

Add a per-file VM pool using the IdPool for ID allocation
and an XArray for VM storage.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/pool.rs | 102 ++++++++++++++++++++++++++++++++++++++++++++
 drivers/gpu/drm/tyr/tyr.rs  |   1 +
 2 files changed, 103 insertions(+)

diff --git a/drivers/gpu/drm/tyr/pool.rs b/drivers/gpu/drm/tyr/pool.rs
new file mode 100644
index 0000000000000..1745116930c3e
--- /dev/null
+++ b/drivers/gpu/drm/tyr/pool.rs
@@ -0,0 +1,102 @@
+// SPDX-License-Identifier: GPL-2.0 or MIT
+
+//! Per-drm-file VM id pool.
+
+use kernel::{
+    id_pool::IdPool,
+    new_mutex,
+    prelude::*,
+    sync::{
+        Arc,
+        ArcBorrow,
+        Mutex, //
+    },
+    xarray::{
+        AllocKind,
+        XArray, //
+    }, //
+};
+
+use crate::vm::Vm;
+
+/// Maximum number of VMs per open file. Matches panthor's
+/// `PANTHOR_MAX_VMS_PER_FILE`.
+pub(crate) const PANTHOR_MAX_VMS_PER_FILE: u32 = 32;
+
+/// Per-open-file pool of VMs.
+#[pin_data]
+pub(crate) struct VmPool<'drm> {
+    #[pin]
+    ids: Mutex<IdPool>,
+    #[pin]
+    vms: XArray<Arc<Vm<'drm>>>,
+}
+
+impl<'drm> VmPool<'drm> {
+    /// Creates a new [`VmPool`] with capacity for [`PANTHOR_MAX_VMS_PER_FILE`] VMs.
+    pub(crate) fn new() -> Result<impl PinInit<Self>> {
+        let ids = IdPool::with_capacity(PANTHOR_MAX_VMS_PER_FILE as usize, GFP_KERNEL)?;
+        Ok(pin_init!(Self {
+            ids <- new_mutex!(ids),
+            vms <- XArray::new(AllocKind::Alloc),
+        }))
+    }
+
+    /// Inserts a VM into the pool, returning the allocated ID.
+    pub(crate) fn add(&self, vm: ArcBorrow<'_, Vm<'drm>>) -> Result<u32> {
+        let id = {
+            let mut ids = self.ids.lock();
+            ids.find_unused_id(1).ok_or(ENOSPC)?.acquire()
+        };
+
+        let vm: Arc<Vm<'drm>> = vm.into();
+        let mut vms = self.vms.lock();
+        match vms.store(id, vm, GFP_KERNEL) {
+            Ok(previous) => {
+                // Drop the previous entry (expected `None`).
+                drop(previous);
+                Ok(id as u32)
+            }
+            Err(err) => {
+                // Drop the XArray spinlock before acquiring the `ids` mutex.
+                drop(vms);
+                // Release the stored entry and the pooled id.
+                drop(err.value);
+                let mut ids = self.ids.lock();
+                ids.release_id(id);
+                Err(err.error)
+            }
+        }
+    }
+
+    /// Removes the VM with the given ID.
+    pub(crate) fn remove(&self, id: u32) -> Result<Arc<Vm<'drm>>> {
+        let mut vms = self.vms.lock();
+        match vms.remove(id as usize) {
+            Some(vm) => {
+                drop(vms);
+                let mut ids = self.ids.lock();
+                ids.release_id(id as usize);
+                Ok(vm)
+            }
+            None => Err(EINVAL),
+        }
+    }
+
+    /// Gets the VM with the given ID.
+    pub(crate) fn get(&self, id: u32) -> Option<Arc<Vm<'drm>>> {
+        let vms = self.vms.lock();
+        let borrow = vms.get(id as usize)?;
+        Some(Arc::from(borrow))
+    }
+
+    /// Removes and returns the first VM in the pool.
+    pub(crate) fn pop_first(&self) -> Option<Arc<Vm<'drm>>> {
+        for id in 0..PANTHOR_MAX_VMS_PER_FILE {
+            if let Ok(vm) = self.remove(id) {
+                return Some(vm);
+            }
+        }
+        None
+    }
+}
diff --git a/drivers/gpu/drm/tyr/tyr.rs b/drivers/gpu/drm/tyr/tyr.rs
index e7ec450bdc9c0..8c0c18c1a970b 100644
--- a/drivers/gpu/drm/tyr/tyr.rs
+++ b/drivers/gpu/drm/tyr/tyr.rs
@@ -13,6 +13,7 @@
 mod gem;
 mod gpu;
 mod mmu;
+mod pool;
 mod regs;
 mod slot;
 mod vm;

-- 
2.43.0

