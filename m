From: Mitchell Levy <levymitchell0@gmail.com>
Date: Fri, 04 Oct 2024 15:01:38 -0700
Subject: [PATCH 2/2] rust: lockdep: Use Pin for all LockClassKey usages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241004-rust-lockdep-v1-2-e9a5c45721fc@gmail.com>
References: <20241004-rust-lockdep-v1-0-e9a5c45721fc@gmail.com>
In-Reply-To: <20241004-rust-lockdep-v1-0-e9a5c45721fc@gmail.com>
To: Boqun Feng <boqun.feng@gmail.com>, Miguel Ojeda <ojeda@kernel.org>, 
 Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Andreas Hindborg <a.hindborg@kernel.org>
Cc: linux-block@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mitchell Levy <levymitchell0@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728079319; l=6324;
 i=levymitchell0@gmail.com; s=20240719; h=from:subject:message-id;
 bh=egblrpL7foe9PRdbj/s3OB75zKKFl+jmHi9rcTsQviA=;
 b=LdiL3W4op5Qu1coC1Ds9URaXOy062w9QiB15UUnMDuMQjAyH3+2kMrnlBzksDqKylGYFr18Ti
 nqFq0B0wN48AlL1Atuu3qY0QTiQ/I3HHVbVixZD/5GBoVGQB8BqFDhS
X-Developer-Key: i=levymitchell0@gmail.com; a=ed25519;
 pk=n6kBmUnb+UNmjVkTnDwrLwTJAEKUfs2e8E+MFPZI93E=
X-Endpoint-Received: by B4 Relay for levymitchell0@gmail.com/20240719 with auth_id=188
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reintroduce dynamically-allocated LockClassKeys such that they are
automatically (de)registered. Require that all usages of LockClassKeys
ensure that they are Pin'd.

Link: https://lore.kernel.org/rust-for-linux/20240815074519.2684107-1-nmi@metaspace.dk/
Suggested-by: Benno Lossin <benno.lossin@proton.me>
Suggested-by: Boqun Feng <boqun.feng@gmail.com>
Signed-off-by: Mitchell Levy <levymitchell0@gmail.com>
---
 rust/helpers/helpers.c      |  1 +
 rust/helpers/sync.c         | 13 +++++++++++++
 rust/kernel/sync.rs         | 30 +++++++++++++++++++++++++++---
 rust/kernel/sync/condvar.rs | 11 +++++++----
 rust/kernel/sync/lock.rs    |  4 ++--
 rust/kernel/workqueue.rs    |  2 +-
 6 files changed, 51 insertions(+), 10 deletions(-)

diff --git a/rust/helpers/helpers.c b/rust/helpers/helpers.c
index 30f40149f3a9..2e8a2abfca33 100644
--- a/rust/helpers/helpers.c
+++ b/rust/helpers/helpers.c
@@ -20,6 +20,7 @@
 #include "signal.c"
 #include "slab.c"
 #include "spinlock.c"
+#include "sync.c"
 #include "task.c"
 #include "uaccess.c"
 #include "wait.c"
diff --git a/rust/helpers/sync.c b/rust/helpers/sync.c
new file mode 100644
index 000000000000..ff7e68b48810
--- /dev/null
+++ b/rust/helpers/sync.c
@@ -0,0 +1,13 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include <linux/lockdep.h>
+
+void rust_helper_lockdep_register_key(struct lock_class_key *k)
+{
+	lockdep_register_key(k);
+}
+
+void rust_helper_lockdep_unregister_key(struct lock_class_key *k)
+{
+	lockdep_unregister_key(k);
+}
diff --git a/rust/kernel/sync.rs b/rust/kernel/sync.rs
index d270db9b9894..3903573143b3 100644
--- a/rust/kernel/sync.rs
+++ b/rust/kernel/sync.rs
@@ -5,6 +5,8 @@
 //! This module contains the kernel APIs related to synchronisation that have been ported or
 //! wrapped for usage by Rust code in the kernel.
 
+use crate::pin_init;
+use crate::prelude::*;
 use crate::types::Opaque;
 
 mod arc;
@@ -20,15 +22,35 @@
 
 /// Represents a lockdep class. It's a wrapper around C's `lock_class_key`.
 #[repr(transparent)]
-pub struct LockClassKey(Opaque<bindings::lock_class_key>);
+#[pin_data(PinnedDrop)]
+pub struct LockClassKey {
+    #[pin]
+    inner: Opaque<bindings::lock_class_key>,
+}
 
 // SAFETY: `bindings::lock_class_key` is designed to be used concurrently from multiple threads and
 // provides its own synchronization.
 unsafe impl Sync for LockClassKey {}
 
 impl LockClassKey {
+    /// Initializes a dynamically allocated lock class key. In the common case of using a
+    /// statically allocated lock class key, the static_lock_class! macro should be used instead.
+    pub fn new_dynamic() -> impl PinInit<Self> {
+        pin_init!(Self {
+            // SAFETY: lockdep_register_key expects an uninitialized block of memory
+            inner <- Opaque::ffi_init(|slot| unsafe { bindings::lockdep_register_key(slot) })
+        })
+    }
+
     pub(crate) fn as_ptr(&self) -> *mut bindings::lock_class_key {
-        self.0.get()
+        self.inner.get()
+    }
+}
+
+#[pinned_drop]
+impl PinnedDrop for LockClassKey {
+    fn drop(self: Pin<&mut Self>) {
+        unsafe { bindings::lockdep_unregister_key(self.as_ptr()) }
     }
 }
 
@@ -37,9 +59,11 @@ pub(crate) fn as_ptr(&self) -> *mut bindings::lock_class_key {
 #[macro_export]
 macro_rules! static_lock_class {
     () => {{
+        // SAFETY: lockdep expects uninitialized memory when it's handed a statically allocated
+        // lock_class_key
         static CLASS: $crate::sync::LockClassKey =
             unsafe { ::core::mem::MaybeUninit::uninit().assume_init() };
-        &CLASS
+        $crate::prelude::Pin::static_ref(&CLASS)
     }};
 }
 
diff --git a/rust/kernel/sync/condvar.rs b/rust/kernel/sync/condvar.rs
index 2b306afbe56d..0469a9d81b7e 100644
--- a/rust/kernel/sync/condvar.rs
+++ b/rust/kernel/sync/condvar.rs
@@ -14,9 +14,12 @@
     time::Jiffies,
     types::Opaque,
 };
-use core::ffi::{c_int, c_long};
-use core::marker::PhantomPinned;
-use core::ptr;
+use core::{
+    ffi::{c_int, c_long},
+    marker::PhantomPinned,
+    pin::Pin,
+    ptr,
+};
 use macros::pin_data;
 
 /// Creates a [`CondVar`] initialiser with the given name and a newly-created lock class.
@@ -102,7 +105,7 @@ unsafe impl Sync for CondVar {}
 
 impl CondVar {
     /// Constructs a new condvar initialiser.
-    pub fn new(name: &'static CStr, key: &'static LockClassKey) -> impl PinInit<Self> {
+    pub fn new(name: &'static CStr, key: Pin<&'static LockClassKey>) -> impl PinInit<Self> {
         pin_init!(Self {
             _pin: PhantomPinned,
             // SAFETY: `slot` is valid while the closure is called and both `name` and `key` have
diff --git a/rust/kernel/sync/lock.rs b/rust/kernel/sync/lock.rs
index f6c34ca4d819..305c41321369 100644
--- a/rust/kernel/sync/lock.rs
+++ b/rust/kernel/sync/lock.rs
@@ -7,7 +7,7 @@
 
 use super::LockClassKey;
 use crate::{init::PinInit, pin_init, str::CStr, types::Opaque, types::ScopeGuard};
-use core::{cell::UnsafeCell, marker::PhantomData, marker::PhantomPinned};
+use core::{cell::UnsafeCell, marker::PhantomData, marker::PhantomPinned, pin::Pin};
 use macros::pin_data;
 
 pub mod mutex;
@@ -106,7 +106,7 @@ unsafe impl<T: ?Sized + Send, B: Backend> Sync for Lock<T, B> {}
 
 impl<T, B: Backend> Lock<T, B> {
     /// Constructs a new lock initialiser.
-    pub fn new(t: T, name: &'static CStr, key: &'static LockClassKey) -> impl PinInit<Self> {
+    pub fn new(t: T, name: &'static CStr, key: Pin<&'static LockClassKey>) -> impl PinInit<Self> {
         pin_init!(Self {
             data: UnsafeCell::new(t),
             _pin: PhantomPinned,
diff --git a/rust/kernel/workqueue.rs b/rust/kernel/workqueue.rs
index 553a5cba2adc..1720a99f53be 100644
--- a/rust/kernel/workqueue.rs
+++ b/rust/kernel/workqueue.rs
@@ -367,7 +367,7 @@ impl<T: ?Sized, const ID: u64> Work<T, ID> {
     /// Creates a new instance of [`Work`].
     #[inline]
     #[allow(clippy::new_ret_no_self)]
-    pub fn new(name: &'static CStr, key: &'static LockClassKey) -> impl PinInit<Self>
+    pub fn new(name: &'static CStr, key: Pin<&'static LockClassKey>) -> impl PinInit<Self>
     where
         T: WorkItem<ID>,
     {

-- 
2.34.1

