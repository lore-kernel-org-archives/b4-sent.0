From: Moritz Zielke <moritz.zielke@gmail.com>
Date: Wed, 03 Dec 2025 18:03:26 +0100
Subject: [PATCH] rust: io: convert ResourceSize to newtype
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251203-res-size-newtype-v1-1-22ed0b8a7a18@gmail.com>
X-B4-Tracking: v=1; b=H4sIAF1tMGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDIwNj3aLUYt3izKpU3bzU8pLKglRds7RUQxODpGQDA2MLJaC2gqLUtMw
 KsJHRsbW1AEJBicRiAAAA
X-Change-ID: 20251203-res-size-newtype-6fe140bc0038
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Moritz Zielke <moritz.zielke@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764781437; l=3636;
 i=moritz.zielke@gmail.com; s=20251030; h=from:subject:message-id;
 bh=5TmYhrgh6SV5dKVgNEgNSkZcUX+Zbc71raKvBWcrl+U=;
 b=q54C1dhu/J84OMY9kchh8i60QvcahqNvAWPY54/1lDdLZ/+MIIHD8+9DGbfn8iF6oftY9OhFY
 /ICpuULcbqWDiJS4XI2AaAiU1GjJOhpew4F2+zT1a+eBCZPr0n5KwtL
X-Developer-Key: i=moritz.zielke@gmail.com; a=ed25519;
 pk=TFwYpZ0YPwD8idGzvlafpvAW4DDA0FrkMEjcfZVXkN0=
X-Endpoint-Received: by B4 Relay for moritz.zielke@gmail.com/20251030 with auth_id=558
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Makes ResourceSize a newtype wrapper around the type for which it
previously was an alias. This should help prevent mistakes by
restricting what operations are possible with ResourceSize.

Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://github.com/Rust-for-Linux/linux/issues/1203
Signed-off-by: Moritz Zielke <moritz.zielke@gmail.com>
---
I think with [1] the prerequisites for making ResourceSize a newtype
have been applied to the driver-core-testing branch of driver-core.
So I developed this patch against driver-core-testing. 

[1] https://lore.kernel.org/lkml/DE0C1KA14PDQ.Q2CJDDTQPWOK@kernel.org/
---
 rust/kernel/io.rs          | 38 ++++++++++++++++++++++++++++++++++++--
 rust/kernel/io/resource.rs |  6 +++---
 2 files changed, 39 insertions(+), 5 deletions(-)

diff --git a/rust/kernel/io.rs b/rust/kernel/io.rs
index 98e8b84e68d1..490f60680090 100644
--- a/rust/kernel/io.rs
+++ b/rust/kernel/io.rs
@@ -4,6 +4,8 @@
 //!
 //! C header: [`include/asm-generic/io.h`](srctree/include/asm-generic/io.h)
 
+use core::num::TryFromIntError;
+
 use crate::{
     bindings,
     prelude::*, //
@@ -23,9 +25,41 @@
 
 /// Resource Size type.
 ///
-/// This is a type alias to either `u32` or `u64` depending on the config option
+/// This is a transparent wrapper around either `u32` or `u64` depending on the config option
 /// `CONFIG_PHYS_ADDR_T_64BIT`, and it can be a u64 even on 32-bit architectures.
-pub type ResourceSize = bindings::resource_size_t;
+#[repr(transparent)]
+#[derive(Copy, Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Default)]
+pub struct ResourceSize(bindings::phys_addr_t);
+
+impl From<ffi::c_uint> for ResourceSize {
+    #[inline]
+    fn from(value: ffi::c_uint) -> Self {
+        Self(value.into())
+    }
+}
+
+impl From<bindings::resource_size_t> for ResourceSize {
+    #[inline]
+    fn from(value: bindings::resource_size_t) -> Self {
+        Self(value.into())
+    }
+}
+
+impl TryFrom<ResourceSize> for usize {
+    type Error = TryFromIntError;
+
+    #[inline]
+    fn try_from(value: ResourceSize) -> Result<Self, Self::Error> {
+        usize::try_from(value.0)
+    }
+}
+
+impl From<ResourceSize> for bindings::resource_size_t {
+    #[inline]
+    fn from(value: ResourceSize) -> Self {
+        value.0
+    }
+}
 
 /// Raw representation of an MMIO region.
 ///
diff --git a/rust/kernel/io/resource.rs b/rust/kernel/io/resource.rs
index 56cfde97ce87..841bb00b8418 100644
--- a/rust/kernel/io/resource.rs
+++ b/rust/kernel/io/resource.rs
@@ -58,7 +58,7 @@ fn drop(&mut self) {
         };
 
         // SAFETY: Safe as per the invariant of `Region`.
-        unsafe { release_fn(start, size) };
+        unsafe { release_fn(start, size.into()) };
     }
 }
 
@@ -114,7 +114,7 @@ pub fn request_region(
             bindings::__request_region(
                 self.0.get(),
                 start,
-                size,
+                size.into(),
                 name.as_char_ptr(),
                 flags.0 as c_int,
             )
@@ -130,7 +130,7 @@ pub fn request_region(
     pub fn size(&self) -> ResourceSize {
         let inner = self.0.get();
         // SAFETY: Safe as per the invariants of `Resource`.
-        unsafe { bindings::resource_size(inner) }
+        unsafe { bindings::resource_size(inner) }.into()
     }
 
     /// Returns the start address of the resource.

---
base-commit: 473b9f331718267815649cd93801da832200db71
change-id: 20251203-res-size-newtype-6fe140bc0038

Best regards,
-- 
Moritz Zielke <moritz.zielke@gmail.com>

