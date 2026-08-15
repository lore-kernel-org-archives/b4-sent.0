From: Younes Akhouayri <git@younes.io>
Date: Sat, 15 Aug 2026 22:12:27 +0200
Subject: [PATCH v3] rust: num: restrict bool conversion to unsigned Bounded
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260815-fix-rust-bounded-from-bool-submit-v3-1-fdca23008397@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/5WOyw7CIBBFf8WwdrRMfRBX/odxAWWwYxQM0EZj+
 u9C3bh1eSZ3zr1vkSgyJXFYvEWkkRMHX6BdLkTXa38hYFtYYIO7RsktOH5CHFIGEwZvyYKL4V4
 g3CAN5s4ZWu1Uu7PK7aUSxfOIVJ7mjtP5yyV5pS5XcU0YnQhM1L7r6ylEvrBfzy2enrlGek45x
 Ne8c5RV9c+kUYIEpRBxb9ymMfr4KlFKKw6iThrxbyMWo9bt1hjsEK38NU7T9AFuyygEWQEAAA=
 =
X-Change-ID: 20260815-fix-rust-bounded-from-bool-submit-3af836d8f718
To: Alexandre Courbot <acourbot@nvidia.com>, 
 Yury Norov <yury.norov@gmail.com>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: rust-for-linux@vger.kernel.org, stable@vger.kernel.org, 
 Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786824760; l=3556;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=hDsraM88osjHhb8cyIuZyLTVAbeH3KoVJUu1U+pSxrI=;
 b=pgh5d5B5ofuaXK+WzUYleA/XAqs85VWO3ZOAWaCPLXWdPjZlNgIVBMGEwU3jXGddB7LQSI94p
 TxFK4pc4/YSDRgiSSOGjCyph8ayQKRNau4IVZ7hUeYu7qr6097xk7hR
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From<bool> turns true into 1. A signed Bounded with N = 1 can hold
only -1 and 0. The current implementation can therefore create a value
that breaks Bounded's invariant. Deref relies on that invariant and
calls unreachable_unchecked() when it is broken, so safe Rust can reach
undefined behavior.

The other primitive conversions require the source and destination to
have the same signedness. Treat bool as an unsigned one-bit value and
allow this conversion only for unsigned Bounded types.

Fixes: 01e345e82ec3 ("rust: num: add Bounded integer wrapping type")
Closes: https://lore.kernel.org/rust-for-linux/OzuVxu0--J-9@younes.io/
Cc: stable@vger.kernel.org
Assisted-by: Codex:gpt-5.6-sol
Signed-off-by: Younes Akhouayri <git@younes.io>
---
Only allow From<bool> for unsigned Bounded types.
---
Changes in v3:
- Restrict From<bool> to unsigned Bounded types, matching the other
  primitive conversions.
- Remove the BoolFits helper and signed-width list.
- Link to v2: https://lore.kernel.org/rust-for-linux/20260815-fix-rust-bounded-from-bool-submit-v2-1-aa35bb2c22d1@younes.io/

Changes in v2:
- Use vertical formatting for the nested `num` import.
- Link to v1: https://lore.kernel.org/rust-for-linux/20260815-fix-rust-bounded-from-bool-submit-v1-1-882227bf40ba@younes.io/
---
 rust/kernel/num/bounded.rs | 20 ++++++++++++++------
 1 file changed, 14 insertions(+), 6 deletions(-)

diff --git a/rust/kernel/num/bounded.rs b/rust/kernel/num/bounded.rs
index d192610a687d..f2413dc7458b 100644
--- a/rust/kernel/num/bounded.rs
+++ b/rust/kernel/num/bounded.rs
@@ -13,7 +13,10 @@
 };
 
 use kernel::{
-    num::Integer,
+    num::{
+        Integer,
+        Unsigned, //
+    },
     prelude::*, //
 };
 
@@ -174,13 +177,16 @@ fn fits_within<T: Integer>(value: T, num_bits: u32) -> bool {
 /// // `u8` (regardless of the passed value).
 /// // let _ = Bounded::<u32, 6>::from(10u8);
 ///
-/// // Booleans can be converted into single-bit `Bounded`s.
+/// // Booleans can be converted into unsigned `Bounded`s.
 ///
 /// let v = Bounded::<u64, 1>::from(false);
 /// assert_eq!(v.get(), 0);
 ///
 /// let v = Bounded::<u64, 1>::from(true);
 /// assert_eq!(v.get(), 1);
+///
+/// // This does not build because `i8` is signed.
+/// // let _ = Bounded::<i8, 2>::from(true);
 /// ```
 ///
 /// Infallible conversions from a [`Bounded`] to a primitive integer are also supported, and
@@ -1109,7 +1115,7 @@ fn from(value: Bounded<T, N>) -> $type {
     i8 i16 i32 i64 isize
 );
 
-// Single-bit `Bounded`s can be converted from/to a boolean.
+// Single-bit `Bounded`s can be converted to a boolean.
 
 impl<T> From<Bounded<T, 1>> for bool
 where
@@ -1120,13 +1126,15 @@ fn from(value: Bounded<T, 1>) -> Self {
     }
 }
 
+// Booleans can be converted to unsigned `Bounded`s.
+
 impl<T, const N: u32> From<bool> for Bounded<T, N>
 where
-    T: Integer + From<bool>,
+    T: Integer<Signedness = Unsigned> + From<bool>,
 {
     fn from(value: bool) -> Self {
-        // SAFETY: A boolean can be represented using a single bit, and thus fits within any
-        // integer type for any `N` > 0.
+        // SAFETY: A boolean is represented by `0` or `1`, so it fits within any valid unsigned
+        // `Bounded` width.
         unsafe { Self::__new(T::from(value)) }
     }
 }

---
base-commit: 47f27155f17498fccb1f222f79089642337498a9
change-id: 20260815-fix-rust-bounded-from-bool-submit-3af836d8f718

Best regards,
--  
Younes Akhouayri <git@younes.io>

