From: Alvin Sun <alvin.sun@linux.dev>
Date: Tue, 17 Mar 2026 20:03:41 +0800
Subject: [PATCH 2/2] drm/gpuvm: add GpuVaIter and va_mappings() for debugfs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260317-gpuvm-helpers-v1-2-00198fc6eeea@linux.dev>
References: <20260317-gpuvm-helpers-v1-0-00198fc6eeea@linux.dev>
In-Reply-To: <20260317-gpuvm-helpers-v1-0-00198fc6eeea@linux.dev>
To: Danilo Krummrich <dakr@kernel.org>, 
 Matthew Brost <matthew.brost@intel.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 Alice Ryhl <aliceryhl@google.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>
Cc: dri-devel@lists.freedesktop.org, rust-for-linux@vger.kernel.org, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773749102; l=3147;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=Spvb1UU2bxG11YpOXQvMhT8OSF/chs/BSvBYCgTW/Ss=;
 b=V6TKsT27fnH+byF3jmh0dtSkdFUV2SfXMSCFWIniMZEF46nlzSMUI+AMohlqThDzMXs4uC8Ws
 7iOycv8gmuPC29SCyfZfmiJ++jaXmAeF6VIU2m9wc1TpMwsgl0PjCns
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an iterator over VA mappings so drivers can walk and dump GPU VA
state in debugfs.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/drm/gpuvm/mod.rs |  6 +++++
 rust/kernel/drm/gpuvm/va.rs  | 53 ++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 59 insertions(+)

diff --git a/rust/kernel/drm/gpuvm/mod.rs b/rust/kernel/drm/gpuvm/mod.rs
index 3186df9f740cf..41b99d468f9d9 100644
--- a/rust/kernel/drm/gpuvm/mod.rs
+++ b/rust/kernel/drm/gpuvm/mod.rs
@@ -301,6 +301,12 @@ pub fn data(&mut self) -> &mut T {
         // SAFETY: By the type invariants we may access `core`.
         unsafe { &mut *self.0.data.get() }
     }
+
+    /// Returns an iterator over the VA mappings in this GpuVm.
+    #[inline]
+    pub fn va_mappings(&self) -> GpuVaIter<'_, T> {
+        GpuVaIter::new(&self.0)
+    }
 }
 
 impl<T: DriverGpuVm> Deref for GpuVmCore<T> {
diff --git a/rust/kernel/drm/gpuvm/va.rs b/rust/kernel/drm/gpuvm/va.rs
index 8b8fd500b3c5f..3210047f880e3 100644
--- a/rust/kernel/drm/gpuvm/va.rs
+++ b/rust/kernel/drm/gpuvm/va.rs
@@ -1,6 +1,14 @@
 // SPDX-License-Identifier: GPL-2.0 OR MIT
 
 use super::*;
+use crate::interop::list::{
+    CList,
+    CListIter, //
+};
+use core::{
+    marker::PhantomData,
+    mem::offset_of, //
+};
 
 /// Represents that a range of a GEM object is mapped in this [`GpuVm`] instance.
 ///
@@ -118,6 +126,51 @@ pub fn length(&self) -> u64 {
     }
 }
 
+const DRM_GPUVA_LIST_ENTRY_OFFSET: usize = offset_of!(bindings::drm_gpuva, rb.entry);
+type RawGpuVaIter<'a> = CListIter<'a, RawGpuVa, DRM_GPUVA_LIST_ENTRY_OFFSET>;
+
+/// An iterator over the VA mappings in a [`GpuVm`].
+pub struct GpuVaIter<'a, T: DriverGpuVm> {
+    raw_gpuva_iter: RawGpuVaIter<'a>,
+    kern_gpuva_ptr: *mut bindings::drm_gpuva,
+    _marker: PhantomData<&'a T>,
+}
+
+impl<'a, T: DriverGpuVm> GpuVaIter<'a, T> {
+    #[inline]
+    pub(crate) fn new(gpuvm: &'a GpuVm<T>) -> Self {
+        // SAFETY: `gpuvm` is valid.
+        let head = unsafe { &raw mut (*gpuvm.as_raw()).rb.list };
+        // SAFETY: `head` is a valid pointer to a drm_gpuva list head.
+        let clist = unsafe { CList::<RawGpuVa, DRM_GPUVA_LIST_ENTRY_OFFSET>::from_raw(head) };
+        let kern_gpuva_ptr = gpuvm.kernel_alloc_va().as_raw();
+
+        Self {
+            raw_gpuva_iter: clist.iter(),
+            kern_gpuva_ptr,
+            _marker: PhantomData,
+        }
+    }
+}
+
+impl<'a, T: DriverGpuVm> Iterator for GpuVaIter<'a, T> {
+    type Item = &'a GpuVa<T>;
+
+    #[inline]
+    fn next(&mut self) -> Option<Self::Item> {
+        let mut curr = self.raw_gpuva_iter.next()?;
+
+        if curr.as_raw() == self.kern_gpuva_ptr {
+            // Skip kernel reserved node.
+            curr = self.raw_gpuva_iter.next()?;
+        }
+
+        // SAFETY: We have skipped the kernel reserved node, all remaining
+        // entries are valid GpuVa<T> instances.
+        Some(unsafe { GpuVa::from_raw(curr.as_raw()) })
+    }
+}
+
 /// A pre-allocated [`GpuVa`] object.
 ///
 /// # Invariants

-- 
2.43.0

