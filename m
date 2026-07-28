From: Josef Ippisch <josef.ippisch.dev@mailbox.org>
Date: Tue, 28 Jul 2026 19:31:19 +0200
Subject: [PATCH v2 1/2] rust: debugfs: migrate debugfs traits requirements
 to zerocopy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-migrate-binarywriter-to-zerocopy-intobytes-v2-1-0a4ec1d3ead4@mailbox.org>
References: <20260728-migrate-binarywriter-to-zerocopy-intobytes-v2-0-0a4ec1d3ead4@mailbox.org>
In-Reply-To: <20260728-migrate-binarywriter-to-zerocopy-intobytes-v2-0-0a4ec1d3ead4@mailbox.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785259881; l=3770;
 i=josef.ippisch.dev@mailbox.org; s=20260719; h=from:subject:message-id;
 bh=b0rPo5lephIkpP3OY5hEVhiK4Wy3dfjH0joonztLXsg=;
 b=O+4wwtSdsv+Zg5qykk0A+jrxPa4WM/mZmy2BaVx5IboCrP5TOgD8MHSarlYY+nVV+12YKdURW
 SNgw0QZ3tDCA1jF9J+TX+Hl0AE07lw3MJCTRyhGfBbwxNfVP4hg1t4t
X-Developer-Key: i=josef.ippisch.dev@mailbox.org; a=ed25519;
 pk=M4DnWHhz9yT9BkhXKzsmw6wTVrK2U1WBK0QiEjHoo1U=
X-Endpoint-Received: by B4 Relay for josef.ippisch.dev@mailbox.org/20260719 with auth_id=884
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate `BinaryWriter` and `BinaryReaderMut`'s default implementation's
requirements on T from `kernel::transmute` traits to `zerocopy` traits.

The additional `zerocopy::Immutable` requirement on `BinaryWriter` does not
further restrict the types in practice but is rather a more explicit
requirement (that the type does not have interior mutability) and is
required by zerocopy for the `as_bytes()` function.

Suggested-by: Joshua Liebow-Feeser <joshlf@google.com>
Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://github.com/Rust-for-Linux/linux/issues/975
Link: https://github.com/Rust-for-Linux/linux/issues/1241
Signed-off-by: Josef Ippisch <josef.ippisch.dev@mailbox.org>
---
 rust/kernel/debugfs/traits.rs | 24 +++++++++++-------------
 1 file changed, 11 insertions(+), 13 deletions(-)

diff --git a/rust/kernel/debugfs/traits.rs b/rust/kernel/debugfs/traits.rs
index 8c39524b6a99..b794f7dd7e14 100644
--- a/rust/kernel/debugfs/traits.rs
+++ b/rust/kernel/debugfs/traits.rs
@@ -18,10 +18,6 @@
         Arc,
         Mutex, //
     },
-    transmute::{
-        AsBytes,
-        FromBytes, //
-    },
     uaccess::{
         UserSliceReader,
         UserSliceWriter, //
@@ -36,6 +32,8 @@
     str::FromStr,
 };
 
+use zerocopy::Immutable;
+
 /// A trait for types that can be written into a string.
 ///
 /// This works very similarly to `Debug`, and is automatically implemented if `Debug` is
@@ -76,8 +74,8 @@ fn write_to_slice(
     ) -> Result<usize>;
 }
 
-// Base implementation for any `T: AsBytes`.
-impl<T: AsBytes> BinaryWriter for T {
+// Base implementation for any `T: Immutable + IntoBytes`.
+impl<T: Immutable + IntoBytes> BinaryWriter for T {
     fn write_to_slice(
         &self,
         writer: &mut UserSliceWriter,
@@ -147,7 +145,7 @@ fn write_to_slice(
 // Delegate for `Vec<T, A>`.
 impl<T, A> BinaryWriter for Vec<T, A>
 where
-    T: AsBytes,
+    T: Immutable + IntoBytes,
     A: Allocator,
 {
     fn write_to_slice(
@@ -157,7 +155,7 @@ fn write_to_slice(
     ) -> Result<usize> {
         let slice = self.as_slice();
 
-        // SAFETY: `T: AsBytes` allows us to treat `&[T]` as `&[u8]`.
+        // SAFETY: `T: Immutable + IntoBytes` allows us to treat `&[T]` as `&[u8]`.
         let buffer = unsafe {
             core::slice::from_raw_parts(slice.as_ptr().cast(), core::mem::size_of_val(slice))
         };
@@ -230,14 +228,14 @@ fn read_from_slice_mut(
     ) -> Result<usize>;
 }
 
-// Base implementation for any `T: AsBytes + FromBytes`.
-impl<T: AsBytes + FromBytes> BinaryReaderMut for T {
+// Base implementation for any `T: FromBytes + IntoBytes`.
+impl<T: FromBytes + IntoBytes> BinaryReaderMut for T {
     fn read_from_slice_mut(
         &mut self,
         reader: &mut UserSliceReader,
         offset: &mut file::Offset,
     ) -> Result<usize> {
-        reader.read_slice_file(self.as_bytes_mut(), offset)
+        reader.read_slice_file(self.as_mut_bytes(), offset)
     }
 }
 
@@ -255,7 +253,7 @@ fn read_from_slice_mut(
 // Delegate for `Vec<T, A>`: Support a `Vec<T, A>` with an outer lock.
 impl<T, A> BinaryReaderMut for Vec<T, A>
 where
-    T: AsBytes + FromBytes,
+    T: FromBytes + IntoBytes,
     A: Allocator,
 {
     fn read_from_slice_mut(
@@ -265,7 +263,7 @@ fn read_from_slice_mut(
     ) -> Result<usize> {
         let slice = self.as_mut_slice();
 
-        // SAFETY: `T: AsBytes + FromBytes` allows us to treat `&mut [T]` as `&mut [u8]`.
+        // SAFETY: `T: FromBytes + IntoBytes` allow us to treat `&mut [T]` as `&mut [u8]`.
         let buffer = unsafe {
             core::slice::from_raw_parts_mut(
                 slice.as_mut_ptr().cast(),

-- 
2.53.0

