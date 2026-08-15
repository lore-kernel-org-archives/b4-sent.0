From: Younes Akhouayri <git@younes.io>
Date: Sat, 15 Aug 2026 10:06:42 +0200
Subject: [PATCH] rust: num: reject bool conversion to signed one-bit
 Bounded
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260815-fix-rust-bounded-from-bool-submit-v1-1-882227bf40ba@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWN2w6CMBBEf4Xssxu5RGz8FcNDS7ewRlqzbQ0J4
 d8t+HgmM3M2iCRMER7VBkJfjhx8geZSwThrPxGyLQxt3fa1am7oeEXJMaEJ2Vuy6CQsBcIbYzY
 LJ+y0U11vlbs3CsrPR6iMTsdz+HNpvmhMx/HRMDoSGtF+nI8oCE/sr6fF05pg33+AtpQtqAAAA
 A==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786781218; l=4446;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=XpIa9KEUmh79aDTOOC/bb1K0iRRekhqcG4MhqMsCDT4=;
 b=d8wUtrjPLQxRdi8Xk0F441WyLJPxkTsZobYpkNk9eee4bv6pyI5eI0Oyt+dy4t0ir4wB1D9iJ
 LSTsqUZXUJZCypCXCMm8ny1QLC0AaOE+Mg9JRqSjcqg3q1FAwIVjxMY
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From<bool> turns true into 1. A signed Bounded with N = 1 can hold
only -1 and 0. From<bool> therefore creates a value that the type does
not allow. Deref assumes the value is valid and calls
unreachable_unchecked() when it is not. Safe Rust can therefore reach
undefined behavior.

Rust cannot write N >= 2 directly in this From implementation. Add a
private BoolFits trait. It accepts every valid unsigned width and signed
widths from 2 through 128. The current Integer types do not use more
than 128 bits, so this keeps every valid conversion.

Fixes: 01e345e82ec3 ("rust: num: add Bounded integer wrapping type")
Closes: https://lore.kernel.org/rust-for-linux/OzuVxu0--J-9@younes.io/
Cc: stable@vger.kernel.org
Assisted-by: Codex:gpt-5.6-sol
Signed-off-by: Younes Akhouayri <git@younes.io>
---
Do not allow From<bool> for signed Bounded values with N = 1.
Keep it available for signed Bounded values with N >= 2.
---
 rust/kernel/num/bounded.rs | 50 +++++++++++++++++++++++++++++++++++++++++-----
 1 file changed, 45 insertions(+), 5 deletions(-)

diff --git a/rust/kernel/num/bounded.rs b/rust/kernel/num/bounded.rs
index d192610a687d..1856fe6c9865 100644
--- a/rust/kernel/num/bounded.rs
+++ b/rust/kernel/num/bounded.rs
@@ -13,7 +13,7 @@
 };
 
 use kernel::{
-    num::Integer,
+    num::{Integer, Signed, Unsigned},
     prelude::*, //
 };
 
@@ -174,13 +174,26 @@ fn fits_within<T: Integer>(value: T, num_bits: u32) -> bool {
 /// // `u8` (regardless of the passed value).
 /// // let _ = Bounded::<u32, 6>::from(10u8);
 ///
-/// // Booleans can be converted into single-bit `Bounded`s.
+/// // Booleans can be converted into unsigned single-bit `Bounded`s.
 ///
 /// let v = Bounded::<u64, 1>::from(false);
 /// assert_eq!(v.get(), 0);
 ///
 /// let v = Bounded::<u64, 1>::from(true);
 /// assert_eq!(v.get(), 1);
+///
+/// // Signed integers need at least two bits to represent both `0` and `1`.
+/// let v = Bounded::<i8, 2>::from(true);
+/// assert_eq!(v.get(), 1);
+/// ```
+///
+/// A signed single-bit [`Bounded`] cannot represent `1`, so converting a boolean into one does not
+/// build.
+///
+/// ```compile_fail,E0277
+/// use kernel::num::Bounded;
+///
+/// let _: Bounded<i8, 1> = true.into();
 /// ```
 ///
 /// Infallible conversions from a [`Bounded`] to a primitive integer are also supported, and
@@ -1109,7 +1122,33 @@ fn from(value: Bounded<T, N>) -> $type {
     i8 i16 i32 i64 isize
 );
 
-// Single-bit `Bounded`s can be converted from/to a boolean.
+// Conversions between `Bounded`s and booleans.
+
+/// Marker for signedness types for which a valid `N`-bit integer can represent a boolean.
+trait BoolFits<const N: u32> {}
+
+impl<const N: u32> BoolFits<N> for Unsigned {}
+
+macro_rules! impl_signed_bool_fits {
+    ($($num_bits:literal)*) => {
+        $(
+        impl BoolFits<$num_bits> for Signed {}
+        )*
+    };
+}
+
+// `N >= 2` cannot be expressed as a trait bound without `generic_const_exprs`, so enumerate every
+// width supported by the current `Integer` implementations.
+impl_signed_bool_fits!(
+    2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
+    17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32
+    33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48
+    49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64
+    65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80
+    81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96
+    97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112
+    113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128
+);
 
 impl<T> From<Bounded<T, 1>> for bool
 where
@@ -1123,10 +1162,11 @@ fn from(value: Bounded<T, 1>) -> Self {
 impl<T, const N: u32> From<bool> for Bounded<T, N>
 where
     T: Integer + From<bool>,
+    T::Signedness: BoolFits<N>,
 {
     fn from(value: bool) -> Self {
-        // SAFETY: A boolean can be represented using a single bit, and thus fits within any
-        // integer type for any `N` > 0.
+        // SAFETY: `__new` enforces that `N` is a valid width, and the `BoolFits` bound guarantees
+        // that the integer representation of `value` fits within any such `N`.
         unsafe { Self::__new(T::from(value)) }
     }
 }

---
base-commit: 47f27155f17498fccb1f222f79089642337498a9
change-id: 20260815-fix-rust-bounded-from-bool-submit-3af836d8f718

Best regards,
--  
Younes Akhouayri <git@younes.io>

