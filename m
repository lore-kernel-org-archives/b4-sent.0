From: Mitchell Levy <levymitchell0@gmail.com>
Date: Fri, 04 Oct 2024 15:01:37 -0700
Subject: [PATCH 1/2] rust: lockdep: Remove support for dynamically
 allocated LockClassKeys
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241004-rust-lockdep-v1-1-e9a5c45721fc@gmail.com>
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
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Mitchell Levy <levymitchell0@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728079319; l=1817;
 i=levymitchell0@gmail.com; s=20240719; h=from:subject:message-id;
 bh=sPd80p5ID1e1fg5bg8nSOM9q7MeynA1KNnT/FYVqLZ0=;
 b=+P16WMaS1TptJcNjuLo6USG7helplG+QSPK9e9AOKqDmUSTTXHLfIItjWKVGXWBqjWeXUpkTl
 I/CNBV2TN7GC6h3bsOa85emNKu/4Fj9zFkR7uoxnP92z2fa+aWkvwhA
X-Developer-Key: i=levymitchell0@gmail.com; a=ed25519;
 pk=n6kBmUnb+UNmjVkTnDwrLwTJAEKUfs2e8E+MFPZI93E=
X-Endpoint-Received: by B4 Relay for levymitchell0@gmail.com/20240719 with auth_id=188
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, dynamically allocated LockCLassKeys can be used from the Rust
side without having them registered. This is a soundness issue, so
remove them.

Suggested-by: Alice Ryhl <aliceryhl@google.com>
Link: https://lore.kernel.org/rust-for-linux/20240815074519.2684107-3-nmi@metaspace.dk/
Cc: stable@vger.kernel.org
Signed-off-by: Mitchell Levy <levymitchell0@gmail.com>
---
 rust/kernel/lib.rs  |  2 +-
 rust/kernel/sync.rs | 14 ++------------
 2 files changed, 3 insertions(+), 13 deletions(-)

diff --git a/rust/kernel/lib.rs b/rust/kernel/lib.rs
index 22a3bfa5a9e9..b5f4b3ce6b48 100644
--- a/rust/kernel/lib.rs
+++ b/rust/kernel/lib.rs
@@ -44,8 +44,8 @@
 pub mod page;
 pub mod prelude;
 pub mod print;
-pub mod sizes;
 pub mod rbtree;
+pub mod sizes;
 mod static_assert;
 #[doc(hidden)]
 pub mod std_vendor;
diff --git a/rust/kernel/sync.rs b/rust/kernel/sync.rs
index 0ab20975a3b5..d270db9b9894 100644
--- a/rust/kernel/sync.rs
+++ b/rust/kernel/sync.rs
@@ -27,28 +27,18 @@
 unsafe impl Sync for LockClassKey {}
 
 impl LockClassKey {
-    /// Creates a new lock class key.
-    pub const fn new() -> Self {
-        Self(Opaque::uninit())
-    }
-
     pub(crate) fn as_ptr(&self) -> *mut bindings::lock_class_key {
         self.0.get()
     }
 }
 
-impl Default for LockClassKey {
-    fn default() -> Self {
-        Self::new()
-    }
-}
-
 /// Defines a new static lock class and returns a pointer to it.
 #[doc(hidden)]
 #[macro_export]
 macro_rules! static_lock_class {
     () => {{
-        static CLASS: $crate::sync::LockClassKey = $crate::sync::LockClassKey::new();
+        static CLASS: $crate::sync::LockClassKey =
+            unsafe { ::core::mem::MaybeUninit::uninit().assume_init() };
         &CLASS
     }};
 }

-- 
2.34.1

