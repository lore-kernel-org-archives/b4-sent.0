From: Alvin Sun <alvin.sun@linux.dev>
Date: Thu, 26 Mar 2026 14:52:55 +0800
Subject: [PATCH 02/13] rust: revocable: add lazily instantiated revocable
 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260326-b4-tyr-debugfs-v1-2-074badd18716@linux.dev>
References: <20260326-b4-tyr-debugfs-v1-0-074badd18716@linux.dev>
In-Reply-To: <20260326-b4-tyr-debugfs-v1-0-074badd18716@linux.dev>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Sumit Semwal <sumit.semwal@linaro.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>
Cc: rust-for-linux@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774508149; l=3394;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=JCy0YveUUx2PxZVI94KUIjqKl/C8px/HZ+jhmQr0Dks=;
 b=/3wc7yexWjygUwGQE3Uq9UvBOv7UVYqCidZ6dkDG/T4jCh7C7NSN54PIOyTvEvIBhdHsuoEmV
 EFCaKay4NliAGoNOCHPfG28dtvIK8pEfICjBJcJdoJp2L9VwdKAzotv
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Gary Guo <gary@garyguo.net>

Add a `LazyRevocable` type, an variant to `Revocable` where
the data is initialized lazily. This type can be constructed as const and
put into statics.

Signed-off-by: Gary Guo <gary@garyguo.net>
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/revocable.rs | 80 +++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 79 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/revocable.rs b/rust/kernel/revocable.rs
index 0f4ae673256d5..70733ff5961cd 100644
--- a/rust/kernel/revocable.rs
+++ b/rust/kernel/revocable.rs
@@ -7,7 +7,12 @@
 
 use pin_init::Wrapper;
 
-use crate::{bindings, prelude::*, sync::rcu, types::Opaque};
+use crate::{
+    bindings,
+    prelude::*,
+    sync::{rcu, SetOnce},
+    types::Opaque,
+};
 use core::{
     marker::PhantomData,
     ops::Deref,
@@ -261,3 +266,76 @@ fn deref(&self) -> &Self::Target {
         unsafe { &*self.data_ref }
     }
 }
+
+/// A handle to perform revocation on a [`Revocable`].
+///
+/// The associated `Revocable` is revoked when the handle is dropped.
+pub struct RevokeHandle<'a, T>(&'a Revocable<T>);
+
+impl<'a, T> RevokeHandle<'a, T> {
+    /// Create a revoke-on-drop handle on an existing revocable.
+    pub fn new(revocable: &'a Revocable<T>) -> Self {
+        Self(revocable)
+    }
+
+    /// Dismiss the handle.
+    ///
+    /// This method consumes ownership without revoking the `Revocable`.
+    pub fn dismiss(self) {
+        core::mem::forget(self);
+    }
+}
+
+impl<'a, T> Drop for RevokeHandle<'a, T> {
+    fn drop(&mut self) {
+        self.0.revoke();
+    }
+}
+
+/// An object that is initialized and can become inaccessible at runtime.
+///
+/// [`Revocable`] is initialized at the beginning, and can be made inaccessible at runtime.
+/// `LazyRevocable` is uninitialized at the beginning, and can be initialized later; it can be
+/// revoked in a similar manner to [`Revocable`]. Once revoked, it cannot be initialized again.
+#[pin_data]
+pub struct LazyRevocable<T> {
+    #[pin]
+    once: SetOnce<Revocable<T>>,
+}
+
+impl<T> LazyRevocable<T> {
+    /// Creates a new lazy revocable instance.
+    ///
+    /// The instance starts uninitialized, where all accesses would fail.
+    pub const fn new() -> Self {
+        LazyRevocable {
+            once: SetOnce::new(),
+        }
+    }
+
+    /// Initialize a `LazyRevocable` and obtain a handle to revoke the content if successful.
+    ///
+    /// An error would be returned if the revocable has already been initialized.
+    pub fn init<E: Into<Error>>(
+        self: Pin<&Self>,
+        init: impl PinInit<T, E>,
+    ) -> Result<RevokeHandle<'_, T>> {
+        // SAFETY: `once` is structurally pinned.
+        let once = unsafe { self.map_unchecked(|x| &x.once) };
+        let revocable = once.pin_init(Revocable::new(init))?;
+        Ok(RevokeHandle::new(revocable))
+    }
+
+    /// Tries to access the revocable wrapped object.
+    ///
+    /// Returns `None` if the object has not been initialized, or it has been revoked and is therefore no longer accessible.
+    pub fn try_access(&self) -> Option<RevocableGuard<'_, T>> {
+        self.once.as_ref()?.try_access()
+    }
+}
+
+impl<T> Default for LazyRevocable<T> {
+    fn default() -> Self {
+        Self::new()
+    }
+}

-- 
2.43.0

