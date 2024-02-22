From: Mathys-Gasnier <mathys35.gasnier@gmail.com>
Date: Thu, 22 Feb 2024 17:26:44 +0100
Subject: [PATCH v3] rust: locks: Add `get_mut` method to `Lock`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240222-rust-locks-get-mut-v3-1-d38a6f4bde3d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMN112UC/23NQQ6CMBCF4auQrh3TGUqqrryHcQFDgUagpgWiI
 dzdghsWLP+XzDezCMZbE8QtmYU3kw3W9THSUyK4yfvagC1jC5KkJOIF/BgGaB2/AtRmgG4cgBV
 JTSix1LmIh29vKvvZ0MczdmPD4Px3+zHhuv45ktcjbkJAYJNmWHFaGqXvdZfb9syuEys30Y5AO
 iQoEhlzmSqmQstiTyzL8gNvQQPR9wAAAA==
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathys-Gasnier <mathys35.gasnier@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708619203; l=2400;
 i=mathys35.gasnier@gmail.com; s=20240118; h=from:subject:message-id;
 bh=ky/U3Y/MfgLzPcLAna8JPEAOaEfDevCIfhcVRsmkGug=;
 b=+QNhsp6z7HFvXcgU9rqBsgzmYXhbx8BMMQKZVVl3iF27daLZJUjw+acCHkIHotOIKO9yiW8qw
 t1cr1passtyA4d6GfP0rDl+TbeGP4C0ecOarsbaGF95e1sfZ2j6smYK
X-Developer-Key: i=mathys35.gasnier@gmail.com; a=ed25519;
 pk=C5tqKAA3Ua7li5s3a+q2aDelT2j98/yjGg2nEVGArXE=
X-Endpoint-Received: by B4 Relay for mathys35.gasnier@gmail.com/20240118 with auth_id=129
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Having a mutable reference guarantees that no other threads have
access to the lock, so we can take advantage of that to grant callers
access to the protected data without the the cost of acquiring and
releasing the locks. Since the lifetime of the data is tied to the
mutable reference, the borrow checker guarantees that the usage is safe.

Signed-off-by: Mathys-Gasnier <mathys35.gasnier@gmail.com>
---
Changes in v3:
- Changing the function to take a `Pin<&mut self>` instead of a `&mut self`
- Removed reviewed-by's since big changes were made. Please take another
  look.
- Link to v2: https://lore.kernel.org/r/20240212-rust-locks-get-mut-v2-1-5ccd34c2b70b@gmail.com

Changes in v2:
- Improved doc comment. 
- Link to v1: https://lore.kernel.org/r/20240209-rust-locks-get-mut-v1-1-ce351fc3de47@gmail.com
---
 rust/kernel/sync/lock.rs | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/sync/lock.rs b/rust/kernel/sync/lock.rs
index f12a684bc957..0c8faf36d654 100644
--- a/rust/kernel/sync/lock.rs
+++ b/rust/kernel/sync/lock.rs
@@ -7,7 +7,11 @@
 
 use super::LockClassKey;
 use crate::{bindings, init::PinInit, pin_init, str::CStr, types::Opaque, types::ScopeGuard};
-use core::{cell::UnsafeCell, marker::PhantomData, marker::PhantomPinned};
+use core::{
+    cell::UnsafeCell,
+    marker::{PhantomData, PhantomPinned},
+    pin::Pin,
+};
 use macros::pin_data;
 
 pub mod mutex;
@@ -121,6 +125,16 @@ pub fn lock(&self) -> Guard<'_, T, B> {
         // SAFETY: The lock was just acquired.
         unsafe { Guard::new(self, state) }
     }
+
+    /// Gets the data contained in the lock
+    /// Having a mutable reference to the lock guarantees that no other threads have access to the lock.
+    /// Making it safe to get a mutable reference to the lock content.
+    pub fn get_mut(self: Pin<&mut Self>) -> &mut T {
+        // SAFETY: Since the data is not pinned (No structural pinning for data).
+        // It is safe to get a mutable reference to the data and we never move the state.
+        let lock = unsafe { self.get_unchecked_mut() };
+        lock.data.get_mut()
+    }
 }
 
 /// A lock guard.

---
base-commit: 711cbfc717650532624ca9f56fbaf191bed56e67
change-id: 20240118-rust-locks-get-mut-c42072101d7a

Best regards,
-- 
Mathys-Gasnier <mathys35.gasnier@gmail.com>

