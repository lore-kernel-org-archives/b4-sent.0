From: Josef Ippisch <josef.ippisch.dev@mailbox.org>
Date: Sun, 19 Jul 2026 10:28:48 +0200
Subject: [PATCH 1/2] rust: debugfs: migrate BinaryWriter requirements to
 zerocopy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260719-migrate-binarywriter-to-zerocopy-intobytes-v1-1-27ed30512e75@mailbox.org>
References: <20260719-migrate-binarywriter-to-zerocopy-intobytes-v1-0-27ed30512e75@mailbox.org>
In-Reply-To: <20260719-migrate-binarywriter-to-zerocopy-intobytes-v1-0-27ed30512e75@mailbox.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: driver-core@lists.linux.dev, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joshua Liebow-Feeser <joshlf@google.com>, 
 Miguel Ojeda <ojeda@kernel.org>, 
 Josef Ippisch <josef.ippisch.dev@mailbox.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784449742; l=2196;
 i=josef.ippisch.dev@mailbox.org; s=20260719; h=from:subject:message-id;
 bh=3xs3RLvMTt7NafjwAYtmrBE3g0qMtkMK7/mKI3G75YU=;
 b=ZC1irnZUYtEuNu0m6ktHGg6njRoFjxiH09nAzVc5EeKGl8TGi8WCqqcPrFMHI5B99nVQlDkmB
 726x5TuFNjMBIvurU7yF+HcT489WTSPLBz4lotGexz7EQVaDSyN6nEh
X-Developer-Key: i=josef.ippisch.dev@mailbox.org; a=ed25519;
 pk=M4DnWHhz9yT9BkhXKzsmw6wTVrK2U1WBK0QiEjHoo1U=
X-Endpoint-Received: by B4 Relay for josef.ippisch.dev@mailbox.org/20260719 with auth_id=884
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate `BinaryWriter`'s default implementation's requirements on T from
`kernel::transmute::AsBytes` to `zerocopy::Immutable` +
`zerocopy::IntoBytes`.

The additional `zerocopy::Immutable` requirement does not further
restrict the types in practice but is rather a more explicit requirement
(that the type does not have interior mutability) and is required by
zerocopy for the `as_bytes()` function.

Suggested-by: Joshua Liebow-Feeser <joshlf@google.com>
Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://github.com/Rust-for-Linux/linux/issues/975
Signed-off-by: Josef Ippisch <josef.ippisch.dev@mailbox.org>
---
 rust/kernel/debugfs/traits.rs | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/rust/kernel/debugfs/traits.rs b/rust/kernel/debugfs/traits.rs
index 8c39524b6a99..ce030ff45a4c 100644
--- a/rust/kernel/debugfs/traits.rs
+++ b/rust/kernel/debugfs/traits.rs
@@ -36,6 +36,11 @@
     str::FromStr,
 };
 
+use zerocopy::{
+    Immutable,
+    IntoBytes, //
+};
+
 /// A trait for types that can be written into a string.
 ///
 /// This works very similarly to `Debug`, and is automatically implemented if `Debug` is
@@ -76,8 +81,8 @@ fn write_to_slice(
     ) -> Result<usize>;
 }
 
-// Base implementation for any `T: AsBytes`.
-impl<T: AsBytes> BinaryWriter for T {
+// Base implementation for any `T: Immutable + IntoBytes`.
+impl<T: Immutable + IntoBytes> BinaryWriter for T {
     fn write_to_slice(
         &self,
         writer: &mut UserSliceWriter,
@@ -147,7 +152,7 @@ fn write_to_slice(
 // Delegate for `Vec<T, A>`.
 impl<T, A> BinaryWriter for Vec<T, A>
 where
-    T: AsBytes,
+    T: Immutable + IntoBytes,
     A: Allocator,
 {
     fn write_to_slice(
@@ -157,7 +162,7 @@ fn write_to_slice(
     ) -> Result<usize> {
         let slice = self.as_slice();
 
-        // SAFETY: `T: AsBytes` allows us to treat `&[T]` as `&[u8]`.
+        // SAFETY: `T: Immutable + IntoBytes` allows us to treat `&[T]` as `&[u8]`.
         let buffer = unsafe {
             core::slice::from_raw_parts(slice.as_ptr().cast(), core::mem::size_of_val(slice))
         };

-- 
2.53.0

