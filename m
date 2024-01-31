From: Valentin Obst <kernel@valentinobst.de>
Date: Wed, 31 Jan 2024 21:23:29 +0100
Subject: [PATCH v3 07/12] rust: kernel: unify spelling of refcount in docs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240131-doc-fixes-v3-v3-7-0c8af94ed7de@valentinobst.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706732646; l=3612;
 i=kernel@valentinobst.de; s=20240131; h=from:subject:message-id;
 bh=QKfC4Yx2YuMhbVoUU+HsBYOAmy4hrhjLwyi1rK9J+vA=;
 b=cJ0rU/cLrFYxQveHJSf8kBibCQ+wP0mbRY7IOhdp9xuHNGZCB9eWtfFYX5GKRhGxstervDr2Z
 09J+P5+4MjYAYHLcf/aEy8xWjKU5IFP6K1Dt5JmFEeqja6W78i2fmGO
X-Developer-Key: i=kernel@valentinobst.de; a=ed25519;
 pk=3s7U8y0mqkaiurgHSQQTYWOo2tw5HgzCg5vnJVfw37Y=
X-Endpoint-Received: by B4 Relay for kernel@valentinobst.de/20240131 with auth_id=124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace instances of 'ref-count[ed]' with 'refcount[ed]' to increase
consistency within the Rust documentation. The latter form is used more
widely in the rest of the kernel:

```console
$ rg '(\*|//).*?\srefcount(|ed)[\s,.]' | wc -l
1605
$ rg '(\*|//).*?\sref-count(|ed)[\s,.]' | wc -l
43
```

(numbers are for Commit 052d534373b7)

Signed-off-by: Valentin Obst <kernel@valentinobst.de>
Reviewed-by: Trevor Gross <tmgross@umich.edu>
Reviewed-by: Martin Rodriguez Reboredo <yakoyoku@gmail.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
---
 rust/kernel/sync/arc.rs | 8 ++++----
 rust/kernel/task.rs     | 4 ++--
 2 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/rust/kernel/sync/arc.rs b/rust/kernel/sync/arc.rs
index 77cdbcf7bd2e..6c46b1affca5 100644
--- a/rust/kernel/sync/arc.rs
+++ b/rust/kernel/sync/arc.rs
@@ -56,7 +56,7 @@
 ///     b: u32,
 /// }
 ///
-/// // Create a ref-counted instance of `Example`.
+/// // Create a refcounted instance of `Example`.
 /// let obj = Arc::try_new(Example { a: 10, b: 20 })?;
 ///
 /// // Get a new pointer to `obj` and increment the refcount.
@@ -510,7 +510,7 @@ fn deref(&self) -> &Self::Target {
 /// # test().unwrap();
 /// ```
 ///
-/// In the following example we first allocate memory for a ref-counted `Example` but we don't
+/// In the following example we first allocate memory for a refcounted `Example` but we don't
 /// initialise it on allocation. We do initialise it later with a call to [`UniqueArc::write`],
 /// followed by a conversion to `Arc<Example>`. This is particularly useful when allocation happens
 /// in one context (e.g., sleepable) and initialisation in another (e.g., atomic):
@@ -560,7 +560,7 @@ impl<T> UniqueArc<T> {
     /// Tries to allocate a new [`UniqueArc`] instance.
     pub fn try_new(value: T) -> Result<Self, AllocError> {
         Ok(Self {
-            // INVARIANT: The newly-created object has a ref-count of 1.
+            // INVARIANT: The newly-created object has a refcount of 1.
             inner: Arc::try_new(value)?,
         })
     }
@@ -574,7 +574,7 @@ pub fn try_new_uninit() -> Result<UniqueArc<MaybeUninit<T>>, AllocError> {
             data <- init::uninit::<T, AllocError>(),
         }? AllocError))?;
         Ok(UniqueArc {
-            // INVARIANT: The newly-created object has a ref-count of 1.
+            // INVARIANT: The newly-created object has a refcount of 1.
             // SAFETY: The pointer from the `Box` is valid.
             inner: unsafe { Arc::from_inner(Box::leak(inner).into()) },
         })
diff --git a/rust/kernel/task.rs b/rust/kernel/task.rs
index a3a4007db682..6726f1056066 100644
--- a/rust/kernel/task.rs
+++ b/rust/kernel/task.rs
@@ -39,7 +39,7 @@ macro_rules! current {
 ///
 /// All instances are valid tasks created by the C portion of the kernel.
 ///
-/// Instances of this type are always ref-counted, that is, a call to `get_task_struct` ensures
+/// Instances of this type are always refcounted, that is, a call to `get_task_struct` ensures
 /// that the allocation remains valid at least until the matching call to `put_task_struct`.
 ///
 /// # Examples
@@ -163,7 +163,7 @@ pub fn wake_up(&self) {
     }
 }
 
-// SAFETY: The type invariants guarantee that `Task` is always ref-counted.
+// SAFETY: The type invariants guarantee that `Task` is always refcounted.
 unsafe impl crate::types::AlwaysRefCounted for Task {
     fn inc_ref(&self) {
         // SAFETY: The existence of a shared reference means that the refcount is nonzero.

-- 
2.43.0

