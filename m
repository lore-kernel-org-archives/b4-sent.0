From: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
Date: Tue, 07 Apr 2026 16:07:51 +0530
Subject: [PATCH v4 2/3] rust: workqueue: add safe cancellation and status
 methods
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260407-workqueue-v3-final-v4-2-c27da7e5f175@multicorewareinc.com>
References: <20260407-workqueue-v3-final-v4-0-c27da7e5f175@multicorewareinc.com>
In-Reply-To: <20260407-workqueue-v3-final-v4-0-c27da7e5f175@multicorewareinc.com>
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn.roy.baron@gmail.com>, 
 Alice Ryhl <aliceryhl@google.com>, Tejun Heo <tj@kernel.org>, 
 Lai Jiangshan <jiangshanlai@gmail.com>, Boqun Feng <boqun@kernel.org>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775558278; l=18687;
 i=aakash.bollineni@multicorewareinc.com; s=20260402;
 h=from:subject:message-id; bh=WSWED5bbLZL5zS2OHEwoyfXY5cHu6AZstK42St966aQ=;
 b=0YR7FAaZHSUCWG3zp1/uNh91Pca/hLHbTMOwEYDrwowV9/TPe9G8zefy2ODIRbwGl+MDI3Bs0
 4pHF+cyR5QwBUu67P9/SYNgv7xU0vtEylr+EiBJTDznD1XOlUtDBldq
X-Developer-Key: i=aakash.bollineni@multicorewareinc.com; a=ed25519;
 pk=r3Gonl+2k+8RozN9U/XwfICQdnRlAcLeeAfsExmurdE=
X-Endpoint-Received: by B4 Relay for aakash.bollineni@multicorewareinc.com/20260402 with auth_id=711
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Modernize the Rust workqueue by adding methods for status checking
and cancellation of work and delayed work items.

Specifically, this patch adds:
- is_pending(): Returns true if the work item is currently enqueued.
- cancel(): Attempts to cancel the work item before it runs.
- cancel_sync(): Synchronously cancels the work item, waiting for it
  to finish if it's already running.
Reclaims ownership if the work was pending.

Signed-off-by: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
---
 rust/kernel/workqueue.rs | 333 ++++++++++++++++++++++++++++++++++++++++++-----
 1 file changed, 298 insertions(+), 35 deletions(-)

diff --git a/rust/kernel/workqueue.rs b/rust/kernel/workqueue.rs
index 706e833e9702..94a52c278776 100644
--- a/rust/kernel/workqueue.rs
+++ b/rust/kernel/workqueue.rs
@@ -448,8 +448,26 @@ pub unsafe trait WorkItemPointer<const ID: u64>: RawWorkItem<ID> {
     /// The provided `work_struct` pointer must originate from a previous call to [`__enqueue`]
     /// where the `queue_work_on` closure returned true, and the pointer must still be valid.
     ///
+    /// The implementation must ensure that the pointer is reclaimed (e.g., via `from_raw`)
+    /// before calling the `run` method of the underlying [`WorkItem`].
+    ///
     /// [`__enqueue`]: RawWorkItem::__enqueue
     unsafe extern "C" fn run(ptr: *mut bindings::work_struct);
+
+    /// Reclaims ownership of the pointer from the work item.
+    ///
+    /// This is called when a work item is successfully cancelled, allowing the caller
+    /// to recover the original pointer (e.g., `Arc` or `KBox`) that was "leaked"
+    /// during enqueuing.
+    ///
+    /// # Safety
+    ///
+    /// The provided `work_struct` pointer must originate from a previous call to [`__enqueue`]
+    /// where the `queue_work_on` closure returned true, and the work item must have been
+    /// successfully cancelled (i.e., `cancel_work` returned true).
+    ///
+    /// [`__enqueue`]: RawWorkItem::__enqueue
+    unsafe fn reclaim(ptr: *mut bindings::work_struct) -> Self;
 }
 
 /// Defines the method that should be called when this work item is executed.
@@ -516,6 +534,156 @@ pub fn new(name: &'static CStr, key: Pin<&'static LockClassKey>) -> impl PinInit
         })
     }
 
+    /// Returns whether the work item is currently pending.
+    ///
+    /// # Warning
+    ///
+    /// This method is inherently racy. A work item can be enqueued or start running
+    /// immediately after this check returns. Do not rely on this for correctness
+    /// logic (e.g., as a guard for unsafe operations); use it only for debugging or
+    /// non-critical status reporting.
+    ///
+    /// # Examples
+    ///
+    /// ```
+    /// # use kernel::workqueue::{self, new_work, Work, WorkItem, HasWork};
+    /// # use kernel::impl_has_work;
+    /// # use kernel::sync::Arc;
+    /// # #[pin_data]
+    /// # struct MyStruct { #[pin] work: Work<MyStruct> }
+    /// # impl_has_work! { impl HasWork<Self> for MyStruct { self.work } }
+    /// # impl WorkItem for MyStruct {
+    /// #     type Pointer = Arc<MyStruct>;
+    /// #     fn run(_this: Arc<MyStruct>) {}
+    /// # }
+    /// let my_struct = Arc::pin_init(pin_init!(MyStruct {
+    ///     work <- new_work!("MyStruct::work"),
+    /// }), kernel::alloc::flags::GFP_KERNEL).unwrap();
+    /// assert!(!my_struct.work.is_pending());
+    /// workqueue::system().enqueue(my_struct.clone());
+    /// assert!(my_struct.work.is_pending());
+    /// # let _ = my_struct.work.cancel();
+    /// ```
+    #[inline]
+    pub fn is_pending(&self) -> bool {
+        // SAFETY: `self.work` is a valid pointer to a `work_struct`.
+        unsafe { bindings::work_pending(self.work.get()) }
+    }
+
+    /// Cancels the work item.
+    ///
+    /// If the work item was successfully cancelled (i.e., it was pending and had not yet
+    /// started running), the original pointer is reclaimed and returned.
+    ///
+    /// # Guarantees
+    ///
+    /// This method is non-blocking and may return while the work item is still running
+    /// on another CPU. If it returns `None`, the work item might be about to start,
+    /// is currently running, or has already finished.
+    ///
+    /// # Safety
+    ///
+    /// This is safe because ownership is only reclaimed if the kernel confirms (via
+    /// `cancel_work` returning true) that the work item is no longer in any queue and
+    /// will not be executed by the workqueue for this specific enqueue event.
+    ///
+    /// [`cancel_sync`]: Work::cancel_sync
+    ///
+    /// # Examples
+    ///
+    /// ```
+    /// # use kernel::workqueue::{self, new_work, Work, WorkItem, HasWork};
+    /// # use kernel::impl_has_work;
+    /// # use kernel::sync::Arc;
+    /// # #[pin_data]
+    /// # struct MyStruct { #[pin] work: Work<MyStruct> }
+    /// # impl_has_work! { impl HasWork<Self> for MyStruct { self.work } }
+    /// # impl WorkItem for MyStruct {
+    /// #     type Pointer = Arc<MyStruct>;
+    /// #     fn run(_this: Arc<MyStruct>) {}
+    /// # }
+    /// let my_struct = Arc::pin_init(pin_init!(MyStruct {
+    ///     work <- new_work!("MyStruct::work"),
+    /// }), kernel::alloc::flags::GFP_KERNEL).unwrap();
+    /// workqueue::system().enqueue(my_struct.clone());
+    /// assert!(my_struct.work.is_pending());
+    /// let reclaimed = my_struct.work.cancel();
+    /// assert!(reclaimed.is_some());
+    /// assert!(!my_struct.work.is_pending());
+    /// ```
+    pub fn cancel(&self) -> Option<T::Pointer>
+    where
+        T: WorkItem<ID>,
+    {
+        let work_ptr = self.work.get();
+        // SAFETY: `work_ptr` is a valid pointer to a `work_struct`.
+        if unsafe { bindings::cancel_work(work_ptr) } {
+            // SAFETY: The work item was successfully cancelled and is guaranteed not to run,
+            // so we can safely reclaim the ownership leaked during `enqueue`.
+            Some(unsafe { T::Pointer::reclaim(work_ptr) })
+        } else {
+            None
+        }
+    }
+
+    /// Synchronously cancels the work item.
+    ///
+    /// This method waits for the work item to finish if it is currently running.
+    /// If the work item was successfully cancelled from the queue, the pointer is
+    /// reclaimed and returned.
+    ///
+    /// # Guarantees
+    ///
+    /// After this method returns, the work item is guaranteed to be:
+    /// - Not pending in any queue.
+    /// - Not running on any CPU.
+    ///
+    /// This makes it safe to use during teardown (e.g., driver `remove` or object `drop`)
+    /// to ensure no background tasks are accessing resources that are about to be freed.
+    ///
+    /// # Safety
+    ///
+    /// Same as [`cancel`], it only reclaims ownership if the kernel confirms the work
+    /// was still pending and is now removed.
+    ///
+    /// [`cancel`]: Work::cancel
+    ///
+    /// # Examples
+    ///
+    /// ```
+    /// # use kernel::workqueue::{self, new_work, Work, WorkItem, HasWork};
+    /// # use kernel::impl_has_work;
+    /// # use kernel::sync::Arc;
+    /// # #[pin_data]
+    /// # struct MyStruct { #[pin] work: Work<MyStruct> }
+    /// # impl_has_work! { impl HasWork<Self> for MyStruct { self.work } }
+    /// # impl WorkItem for MyStruct {
+    /// #     type Pointer = Arc<MyStruct>;
+    /// #     fn run(_this: Arc<MyStruct>) {}
+    /// # }
+    /// let my_struct = Arc::pin_init(pin_init!(MyStruct {
+    ///     work <- new_work!("MyStruct::work"),
+    /// }), kernel::alloc::flags::GFP_KERNEL).unwrap();
+    /// workqueue::system().enqueue(my_struct.clone());
+    /// let reclaimed = my_struct.work.cancel_sync();
+    /// assert!(reclaimed.is_some());
+    /// ```
+    pub fn cancel_sync(&self) -> Option<T::Pointer>
+    where
+        T: WorkItem<ID>,
+    {
+        let work_ptr = self.work.get();
+        // SAFETY: `work_ptr` is a valid pointer to a `work_struct`.
+        if unsafe { bindings::cancel_work_sync(work_ptr) } {
+            // SAFETY: The work item was successfully cancelled/waited for, and is guaranteed
+            // not to run again unless re-enqueued. We reclaim the ownership leaked during
+            // `enqueue`.
+            Some(unsafe { T::Pointer::reclaim(work_ptr) })
+        } else {
+            None
+        }
+    }
+
     /// Get a pointer to the inner `work_struct`.
     ///
     /// # Safety
@@ -674,25 +842,14 @@ pub fn new(
         pin_init!(Self {
             dwork <- Opaque::ffi_init(|slot: *mut bindings::delayed_work| {
                 // SAFETY: The `WorkItemPointer` implementation promises that `run` can be used as
-                // the work item function.
+                // the work item function. We use the C-helper to ensure the timer function
+                // and data are initialized correctly according to kernel macros.
                 unsafe {
-                    bindings::init_work_with_key(
-                        core::ptr::addr_of_mut!((*slot).work),
+                    bindings::init_delayed_work(
+                        slot,
                         Some(T::Pointer::run),
-                        false,
                         work_name.as_char_ptr(),
                         work_key.as_ptr(),
-                    )
-                }
-
-                // SAFETY: The `delayed_work_timer_fn` function pointer can be used here because
-                // the timer is embedded in a `struct delayed_work`, and only ever scheduled via
-                // the core workqueue code, and configured to run in irqsafe context.
-                unsafe {
-                    bindings::timer_init_key(
-                        core::ptr::addr_of_mut!((*slot).timer),
-                        Some(bindings::delayed_work_timer_fn),
-                        bindings::TIMER_IRQSAFE,
                         timer_name.as_char_ptr(),
                         timer_key.as_ptr(),
                     )
@@ -702,6 +859,89 @@ pub fn new(
         })
     }
 
+    /// Returns whether the work item is currently pending.
+    ///
+    /// # Warning
+    ///
+    /// This method is inherently racy. See [`Work::is_pending`].
+    ///
+    /// # Examples
+    ///
+    /// See [`Work::is_pending`].
+    ///
+    /// [`Work::is_pending`]: Work::is_pending
+    #[inline]
+    pub fn is_pending(&self) -> bool {
+        // SAFETY: `self.dwork` is reaching into a valid Opaque<bindings::delayed_work>.
+        unsafe {
+            let ptr: *mut bindings::delayed_work = self.dwork.get();
+            bindings::work_pending(core::ptr::addr_of_mut!((*ptr).work))
+        }
+    }
+
+    /// Cancels the delayed work item.
+    ///
+    /// If the work item was successfully cancelled (i.e., it was pending and had not yet
+    /// started running), the original pointer is reclaimed and returned.
+    ///
+    /// # Guarantees
+    ///
+    /// See [`Work::cancel`].
+    ///
+    /// # Safety
+    ///
+    /// Same as [`Work::cancel`].
+    ///
+    /// [`cancel_sync`]: DelayedWork::cancel_sync
+    /// [`Work::cancel`]: Work::cancel
+    ///
+    /// # Examples
+    ///
+    /// See [`Work::cancel`].
+    pub fn cancel(&self) -> Option<T::Pointer>
+    where
+        T: WorkItem<ID>,
+    {
+        let dwork_ptr = self.dwork.get();
+        // SAFETY: `dwork_ptr` is a valid pointer to a `delayed_work`.
+        if unsafe { bindings::cancel_delayed_work(dwork_ptr) } {
+            // SAFETY: The work item was successfully cancelled and is guaranteed not to run,
+            // so we can safely reclaim the ownership leaked during `enqueue`.
+            Some(unsafe { T::Pointer::reclaim(core::ptr::addr_of_mut!((*dwork_ptr).work)) })
+        } else {
+            None
+        }
+    }
+
+    /// Synchronously cancels the delayed work item.
+    ///
+    /// This method waits for the work item to finish if it is currently running.
+    /// If the work item was successfully cancelled from the queue, the pointer is
+    /// reclaimed and returned.
+    ///
+    /// # Guarantees
+    ///
+    /// See [`Work::cancel_sync`].
+    ///
+    /// # Safety
+    ///
+    /// Same as [`Work::cancel_sync`].
+    pub fn cancel_sync(&self) -> Option<T::Pointer>
+    where
+        T: WorkItem<ID>,
+    {
+        let dwork_ptr = self.dwork.get();
+        // SAFETY: `dwork_ptr` is a valid pointer to a `delayed_work`.
+        if unsafe { bindings::cancel_delayed_work_sync(dwork_ptr) } {
+            // SAFETY: The work item was successfully cancelled/waited for, and is guaranteed
+            // not to run again unless re-enqueued. We reclaim the ownership leaked during
+            // `enqueue`.
+            Some(unsafe { T::Pointer::reclaim(core::ptr::addr_of_mut!((*dwork_ptr).work)) })
+        } else {
+            None
+        }
+    }
+
     /// Get a pointer to the inner `delayed_work`.
     ///
     /// # Safety
@@ -781,22 +1021,11 @@ unsafe fn raw_get_work(
             unsafe fn work_container_of(
                 ptr: *mut $crate::workqueue::Work<$work_type $(, $id)?>,
             ) -> *mut Self {
-                // SAFETY: The caller promises that the pointer points at a field of the right type
-                // in the right kind of struct.
-                let ptr = unsafe { $crate::workqueue::Work::raw_get(ptr) };
-
-                // SAFETY: The caller promises that the pointer points at a field of the right type
-                // in the right kind of struct.
-                let delayed_work = unsafe {
-                    $crate::container_of!(ptr, $crate::bindings::delayed_work, work)
-                };
-
-                let delayed_work: *mut $crate::workqueue::DelayedWork<$work_type $(, $id)?> =
-                    delayed_work.cast();
-
-                // SAFETY: The caller promises that the pointer points at a field of the right type
-                // in the right kind of struct.
-                unsafe { $crate::container_of!(delayed_work, Self, $field) }
+                // SAFETY: The caller promises that the pointer points at the `work` field
+                // of a `delayed_work` struct, which is itself the `dwork` field of a
+                // `DelayedWork` wrapper, which is the `$field` field of a `Self` struct.
+                let ptr = ptr.cast::<$crate::workqueue::DelayedWork<$work_type $(, $id)?>>();
+                unsafe { $crate::container_of!(ptr, Self, $field) }
             }
         }
     )*};
@@ -827,6 +1056,15 @@ unsafe impl<T, const ID: u64> WorkItemPointer<ID> for Arc<T>
 
         T::run(arc)
     }
+
+    unsafe fn reclaim(ptr: *mut bindings::work_struct) -> Self {
+        // The `__enqueue` method always uses a `work_struct` stored in a `Work<T, ID>`.
+        let ptr = ptr.cast::<Work<T, ID>>();
+        // SAFETY: This computes the pointer that `__enqueue` got from `Arc::into_raw`.
+        let ptr = unsafe { T::work_container_of(ptr) };
+        // SAFETY: This pointer comes from `Arc::into_raw` and we've been given back ownership.
+        unsafe { Arc::from_raw(ptr) }
+    }
 }
 
 // SAFETY: The `work_struct` raw pointer is guaranteed to be valid for the duration of the call to
@@ -874,7 +1112,8 @@ unsafe impl<T, const ID: u64> RawDelayedWorkItem<ID> for Arc<T>
 {
 }
 
-// SAFETY: TODO.
+// SAFETY: The `WorkItemPointer` implementation for `Pin<KBox<T>>` is safe because `KBox::from_raw`
+// correctly reconstructs the box that was leaked during `enqueue` (via `KBox::into_raw`).
 unsafe impl<T, const ID: u64> WorkItemPointer<ID> for Pin<KBox<T>>
 where
     T: WorkItem<ID, Pointer = Self>,
@@ -883,18 +1122,35 @@ unsafe impl<T, const ID: u64> WorkItemPointer<ID> for Pin<KBox<T>>
     unsafe extern "C" fn run(ptr: *mut bindings::work_struct) {
         // The `__enqueue` method always uses a `work_struct` stored in a `Work<T, ID>`.
         let ptr = ptr.cast::<Work<T, ID>>();
-        // SAFETY: This computes the pointer that `__enqueue` got from `Arc::into_raw`.
+        // SAFETY: This computes the pointer that `__enqueue` got from `KBox::into_raw`.
         let ptr = unsafe { T::work_container_of(ptr) };
-        // SAFETY: This pointer comes from `Arc::into_raw` and we've been given back ownership.
+        // SAFETY: This pointer comes from `KBox::into_raw` and we've been given back ownership.
         let boxed = unsafe { KBox::from_raw(ptr) };
         // SAFETY: The box was already pinned when it was enqueued.
         let pinned = unsafe { Pin::new_unchecked(boxed) };
 
         T::run(pinned)
     }
+
+    unsafe fn reclaim(ptr: *mut bindings::work_struct) -> Self {
+        // The `__enqueue` method always uses a `work_struct` stored in a `Work<T, ID>`.
+        let ptr = ptr.cast::<Work<T, ID>>();
+        // SAFETY: This computes the pointer that `__enqueue` got from `KBox::into_raw`.
+        let ptr = unsafe { T::work_container_of(ptr) };
+        // SAFETY: This pointer comes from `KBox::into_raw` and we've been given back ownership.
+        let boxed = unsafe { KBox::from_raw(ptr) };
+        // SAFETY: The box was already pinned when it was enqueued.
+        unsafe { Pin::new_unchecked(boxed) }
+    }
 }
 
-// SAFETY: TODO.
+// SAFETY: The `work_struct` raw pointer is guaranteed to be valid for the duration of the call to
+// the closure because we have exclusive ownership of the `KBox`, and we don't drop it ourselves.
+// If `queue_work_on` returns true, it is further guaranteed to be valid until a call to the
+// function pointer in `work_struct` because we leak the memory it points to, and only reclaim it
+// if the closure returns false (not reachable for KBox as it must succeed) or in
+// `WorkItemPointer::run`, which is what the function pointer in the `work_struct` must be
+// pointing to.
 unsafe impl<T, const ID: u64> RawWorkItem<ID> for Pin<KBox<T>>
 where
     T: WorkItem<ID, Pointer = Self>,
@@ -1022,3 +1278,10 @@ pub fn system_bh_highpri() -> &'static Queue {
     // SAFETY: `system_bh_highpri_wq` is a C global, always available.
     unsafe { Queue::from_raw(bindings::system_bh_highpri_wq) }
 }
+
+/// Returns the strong count of an [`Arc`] for testing purposes.
+///
+/// # Safety
+///
+/// This is intended for use in KUnit tests and sample modules ONLY.
+#[cfg(CONFIG_KUNIT)]

-- 
2.43.0

