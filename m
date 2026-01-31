From: Igor Korotin <igor.korotin.linux@gmail.com>
Date: Sat, 31 Jan 2026 14:12:44 +0000
Subject: [PATCH 2/5] rust: bits: add define_flags macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260131-i2c-adapter-v1-2-5a436e34cd1a@gmail.com>
References: <20260131-i2c-adapter-v1-0-5a436e34cd1a@gmail.com>
In-Reply-To: <20260131-i2c-adapter-v1-0-5a436e34cd1a@gmail.com>
To: Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Wolfram Sang <wsa+renesas@sang-engineering.com>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-i2c@vger.kernel.org, markus.probst@posteo.de, 
 Igor Korotin <igor.korotin.linux@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769868772; l=2311;
 i=igor.korotin.linux@gmail.com; s=20260125; h=from:subject:message-id;
 bh=sn8tyhgAOXgu5sl9ZR6vPMjhDT98q30bKO29ZzpI3ac=;
 b=yEMAIEqB8thmwTAB8YbWq5ph+DxUCzWFu6c9XkTqwOAGPvGImN/YzflWGoHFNqjokbugMGrXA
 tOVxoF2cyRiApPT1aIc7zoqf5nUuZTZRBRKaHXq/FBe13LhUl20XPdX
X-Developer-Key: i=igor.korotin.linux@gmail.com; a=ed25519;
 pk=SjZ//wxnynZgJJgTqANyU10A7hdQQdDXLvXIr+zWroE=
X-Endpoint-Received: by B4 Relay for igor.korotin.linux@gmail.com/20260125 with auth_id=615
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

introduce define_flags macro that incorporates BitOr BitAnd and Not
implementations.

Signed-off-by: Igor Korotin <igor.korotin.linux@gmail.com>
---
 rust/kernel/bits.rs | 57 +++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 57 insertions(+)

diff --git a/rust/kernel/bits.rs b/rust/kernel/bits.rs
index 553d50265883..6750aef18708 100644
--- a/rust/kernel/bits.rs
+++ b/rust/kernel/bits.rs
@@ -201,3 +201,60 @@ pub const fn [<genmask_ $ty>](range: RangeInclusive<u32>) -> $ty {
     /// assert_eq!(genmask_u8(0..=7), u8::MAX);
     /// ```
 );
+
+/// defines flags
+#[macro_export]
+macro_rules! define_flags {
+    (
+        $gen_name:ident($gen_type:ident),
+        $($variant:ident = $binding:expr,)+
+    ) => {
+        /// Flags that can be combined with the operators `|`, `&`, and `!`.
+        ///
+        /// Values can be used from the [`flags`] module.
+        #[derive(Clone, Copy, PartialEq)]
+        pub struct $gen_name($gen_type);
+
+        impl $gen_name {
+            /// Get the raw representation of this flag.
+            pub(crate) fn as_raw(self) -> $gen_type {
+                self.0
+            }
+
+            /// Check whether `flags` is contained in `self`.
+            pub fn contains(self, flags: $gen_name) -> bool {
+                (self & flags) == flags
+            }
+        }
+
+        impl core::ops::BitOr for $gen_name {
+            type Output = $gen_name;
+            fn bitor(self, rhs: Self) -> Self::Output {
+                Self(self.0 | rhs.0)
+            }
+        }
+
+        impl core::ops::BitAnd for $gen_name {
+            type Output = $gen_name;
+            fn bitand(self, rhs: Self) -> Self::Output {
+                Self(self.0 & rhs.0)
+            }
+        }
+
+        impl core::ops::Not for $gen_name {
+            type Output = $gen_name;
+            fn not(self) -> Self::Output {
+                Self(!self.0)
+            }
+        }
+
+        #[allow(missing_docs)]
+        pub mod flags {
+            use super::$gen_name;
+            $(
+                #[allow(missing_docs)]
+                pub const $variant: $gen_name = $gen_name($binding as $gen_type);
+            )+
+        }
+    }
+}

-- 
2.43.0

