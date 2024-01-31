From: Valentin Obst <kernel@valentinobst.de>
Date: Wed, 31 Jan 2024 21:23:30 +0100
Subject: [PATCH v3 08/12] rust: kernel: mark code fragments in docs with
 backticks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240131-doc-fixes-v3-v3-8-0c8af94ed7de@valentinobst.de>
References: <20240131-doc-fixes-v3-v3-0-0c8af94ed7de@valentinobst.de>
In-Reply-To: <20240131-doc-fixes-v3-v3-0-0c8af94ed7de@valentinobst.de>
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Valentin Obst <kernel@valentinobst.de>, Trevor Gross <tmgross@umich.edu>, 
 Martin Rodriguez Reboredo <yakoyoku@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706732646; l=3807;
 i=kernel@valentinobst.de; s=20240131; h=from:subject:message-id;
 bh=J5dTHNR//Nnyw4X8Q/8C/mtX7OP1rzCZ6Zxen8pohMw=;
 b=HpgEriZmFxlMj6UQF50GllImTwzlcqVkT988KRK6iiTbNvDURVqFTmz0Sq4w5/UCq5EkM0OCQ
 kCT334V3M6HC7d3a+bS/t9UEn7IxBQftdV1bPp3QnO60rdWZAnLX9kN
X-Developer-Key: i=kernel@valentinobst.de; a=ed25519;
 pk=3s7U8y0mqkaiurgHSQQTYWOo2tw5HgzCg5vnJVfw37Y=
X-Endpoint-Received: by B4 Relay for kernel@valentinobst.de/20240131 with auth_id=124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix places where comments include code fragments that are not enclosed
in backticks.

Signed-off-by: Valentin Obst <kernel@valentinobst.de>
Reviewed-by: Trevor Gross <tmgross@umich.edu>
Reviewed-by: Martin Rodriguez Reboredo <yakoyoku@gmail.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
---
 rust/kernel/ioctl.rs     | 2 +-
 rust/kernel/sync/lock.rs | 2 +-
 rust/kernel/task.rs      | 2 +-
 rust/kernel/workqueue.rs | 9 +++++----
 4 files changed, 8 insertions(+), 7 deletions(-)

diff --git a/rust/kernel/ioctl.rs b/rust/kernel/ioctl.rs
index 5987ad6d38a7..cfa7d080b531 100644
--- a/rust/kernel/ioctl.rs
+++ b/rust/kernel/ioctl.rs
@@ -1,6 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0
 
-//! ioctl() number definitions.
+//! `ioctl()` number definitions.
 //!
 //! C header: [`include/asm-generic/ioctl.h`](srctree/include/asm-generic/ioctl.h)
 
diff --git a/rust/kernel/sync/lock.rs b/rust/kernel/sync/lock.rs
index 072b8ef2a0fa..10ccc0e39147 100644
--- a/rust/kernel/sync/lock.rs
+++ b/rust/kernel/sync/lock.rs
@@ -28,7 +28,7 @@ pub unsafe trait Backend {
     /// The state required by the lock.
     type State;
 
-    /// The state required to be kept between lock and unlock.
+    /// The state required to be kept between `lock` and `unlock`.
     type GuardState;
 
     /// Initialises the lock.
diff --git a/rust/kernel/task.rs b/rust/kernel/task.rs
index 6726f1056066..ca6e7e31d71c 100644
--- a/rust/kernel/task.rs
+++ b/rust/kernel/task.rs
@@ -132,7 +132,7 @@ fn deref(&self) -> &Self::Target {
     /// Returns the group leader of the given task.
     pub fn group_leader(&self) -> &Task {
         // SAFETY: By the type invariant, we know that `self.0` is a valid task. Valid tasks always
-        // have a valid group_leader.
+        // have a valid `group_leader`.
         let ptr = unsafe { *ptr::addr_of!((*self.0.get()).group_leader) };
 
         // SAFETY: The lifetime of the returned task reference is tied to the lifetime of `self`,
diff --git a/rust/kernel/workqueue.rs b/rust/kernel/workqueue.rs
index 8775c34d12a5..d900dc911149 100644
--- a/rust/kernel/workqueue.rs
+++ b/rust/kernel/workqueue.rs
@@ -168,7 +168,7 @@ impl Queue {
     /// # Safety
     ///
     /// The caller must ensure that the provided raw pointer is not dangling, that it points at a
-    /// valid workqueue, and that it remains valid until the end of 'a.
+    /// valid workqueue, and that it remains valid until the end of `'a`.
     pub unsafe fn from_raw<'a>(ptr: *const bindings::workqueue_struct) -> &'a Queue {
         // SAFETY: The `Queue` type is `#[repr(transparent)]`, so the pointer cast is valid. The
         // caller promises that the pointer is not dangling.
@@ -414,8 +414,8 @@ pub unsafe fn raw_get(ptr: *const Self) -> *mut bindings::work_struct {
 ///
 /// # Safety
 ///
-/// The [`OFFSET`] constant must be the offset of a field in Self of type [`Work<T, ID>`]. The methods on
-/// this trait must have exactly the behavior that the definitions given below have.
+/// The [`OFFSET`] constant must be the offset of a field in `Self` of type [`Work<T, ID>`]. The
+/// methods on this trait must have exactly the behavior that the definitions given below have.
 ///
 /// [`Work<T, ID>`]: Work
 /// [`impl_has_work!`]: crate::impl_has_work
@@ -428,7 +428,8 @@ pub unsafe trait HasWork<T, const ID: u64 = 0> {
 
     /// Returns the offset of the [`Work<T, ID>`] field.
     ///
-    /// This method exists because the [`OFFSET`] constant cannot be accessed if the type is not Sized.
+    /// This method exists because the [`OFFSET`] constant cannot be accessed if the type is not
+    /// `Sized`.
     ///
     /// [`Work<T, ID>`]: Work
     /// [`OFFSET`]: HasWork::OFFSET

-- 
2.43.0

