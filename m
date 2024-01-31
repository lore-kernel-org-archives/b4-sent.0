From: Valentin Obst <kernel@valentinobst.de>
Date: Wed, 31 Jan 2024 21:23:33 +0100
Subject: [PATCH v3 11/12] rust: kernel: remove unneeded doclink targets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240131-doc-fixes-v3-v3-11-0c8af94ed7de@valentinobst.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706732646; l=2616;
 i=kernel@valentinobst.de; s=20240131; h=from:subject:message-id;
 bh=BwWMsMRSeC1kKnnmhQv6fYuKaj3M32UFlVEb1WuNzkc=;
 b=wGvATBsFaAo4TY5WjEUO/KspVCL0ZjLBOnY1oLObO9aK45Ya/Q4PX1qIKBNDOAs/Gdt0eTaX4
 wkWoULzhHoiBhoqQzhNokpuv3kiGrC+SwHm+BrqDtAZihlX+0ppEWpR
X-Developer-Key: i=kernel@valentinobst.de; a=ed25519;
 pk=3s7U8y0mqkaiurgHSQQTYWOo2tw5HgzCg5vnJVfw37Y=
X-Endpoint-Received: by B4 Relay for kernel@valentinobst.de/20240131 with auth_id=124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove explicit targets for doclinks in cases where rustdoc can
determine the correct target by itself. The goal is to reduce unneeded
verbosity in the source code.

Signed-off-by: Valentin Obst <kernel@valentinobst.de>
Reviewed-by: Trevor Gross <tmgross@umich.edu>
Reviewed-by: Martin Rodriguez Reboredo <yakoyoku@gmail.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
---
 rust/kernel/workqueue.rs | 10 ----------
 1 file changed, 10 deletions(-)

diff --git a/rust/kernel/workqueue.rs b/rust/kernel/workqueue.rs
index ed3af3491b47..73d6fa544ca6 100644
--- a/rust/kernel/workqueue.rs
+++ b/rust/kernel/workqueue.rs
@@ -426,13 +426,10 @@ pub unsafe fn raw_get(ptr: *const Self) -> *mut bindings::work_struct {
 /// The [`OFFSET`] constant must be the offset of a field in `Self` of type [`Work<T, ID>`]. The
 /// methods on this trait must have exactly the behavior that the definitions given below have.
 ///
-/// [`Work<T, ID>`]: Work
 /// [`impl_has_work!`]: crate::impl_has_work
 /// [`OFFSET`]: HasWork::OFFSET
 pub unsafe trait HasWork<T, const ID: u64 = 0> {
     /// The offset of the [`Work<T, ID>`] field.
-    ///
-    /// [`Work<T, ID>`]: Work
     const OFFSET: usize;
 
     /// Returns the offset of the [`Work<T, ID>`] field.
@@ -440,7 +437,6 @@ pub unsafe trait HasWork<T, const ID: u64 = 0> {
     /// This method exists because the [`OFFSET`] constant cannot be accessed if the type is not
     /// [`Sized`].
     ///
-    /// [`Work<T, ID>`]: Work
     /// [`OFFSET`]: HasWork::OFFSET
     #[inline]
     fn get_work_offset(&self) -> usize {
@@ -452,8 +448,6 @@ fn get_work_offset(&self) -> usize {
     /// # Safety
     ///
     /// The provided pointer must point at a valid struct of type `Self`.
-    ///
-    /// [`Work<T, ID>`]: Work
     #[inline]
     unsafe fn raw_get_work(ptr: *mut Self) -> *mut Work<T, ID> {
         // SAFETY: The caller promises that the pointer is valid.
@@ -465,8 +459,6 @@ unsafe fn raw_get_work(ptr: *mut Self) -> *mut Work<T, ID> {
     /// # Safety
     ///
     /// The pointer must point at a [`Work<T, ID>`] field in a struct of type `Self`.
-    ///
-    /// [`Work<T, ID>`]: Work
     #[inline]
     unsafe fn work_container_of(ptr: *mut Work<T, ID>) -> *mut Self
     where
@@ -495,8 +487,6 @@ unsafe fn work_container_of(ptr: *mut Work<T, ID>) -> *mut Self
 ///     impl HasWork<MyStruct, 17> for MyStruct { self.work_field }
 /// }
 /// ```
-///
-/// [`HasWork<T, ID>`]: HasWork
 #[macro_export]
 macro_rules! impl_has_work {
     ($(impl$(<$($implarg:ident),*>)?

-- 
2.43.0

