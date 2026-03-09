From: Tim Kovalenko <tim.kovalenko@proton.me>
Date: Mon, 09 Mar 2026 12:34:18 -0400
Subject: [PATCH v4 1/4] rust: ptr: add `KnownSize` trait to support DST
 size info extraction
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-drm-rust-next-v4-1-4ef485b19a4c@proton.me>
References: <20260309-drm-rust-next-v4-0-4ef485b19a4c@proton.me>
In-Reply-To: <20260309-drm-rust-next-v4-0-4ef485b19a4c@proton.me>
To: Alexandre Courbot <acourbot@nvidia.com>, 
 Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Miguel Ojeda <ojeda@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, Boqun Feng <boqun@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Abdiel Janulgue <abdiel.janulgue@gmail.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Robin Murphy <robin.murphy@arm.com>, Boqun Feng <boqun@kernel.org>
Cc: nouveau@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, driver-core@lists.linux.dev
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773074117; l=2158;
 i=tim.kovalenko@proton.me; s=20260212; h=from:subject:message-id;
 bh=FheLpAl87yI4UaHfqa3k20aJCUg9ixwJ8DWS/cDgRg4=;
 b=45N81LFvbnZxj7EBp15VjpGQhHombjwrqodP4FxEVsCd0JDjLKei5FWNCjy3jFam1BlfUrrI7
 tx8XLpQNe94AjeTcEcFGAGgbnHF9RBdYUogAKI4RUMXskNkIfccBCVr
X-Developer-Key: i=tim.kovalenko@proton.me; a=ed25519;
 pk=/+OiulEpgeZifgP4mDE4e5YlV6nMeY+frze/lY/xiHI=
X-Endpoint-Received: by B4 Relay for tim.kovalenko@proton.me/20260212 with auth_id=635
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Gary Guo <gary@garyguo.net>

Add a `KnownSize` trait which is used obtain a size from a raw pointer's
metadata. This makes it possible to obtain size information on a raw slice
pointer. This is similar to Rust `core::mem::size_of_val_raw` which is not
yet stable.

Signed-off-by: Gary Guo <gary@garyguo.net>
Reviewed-by: Benno Lossin <lossin@kernel.org>
Acked-by: Miguel Ojeda <ojeda@kernel.org>
---
 rust/kernel/lib.rs |  1 +
 rust/kernel/ptr.rs | 27 ++++++++++++++++++++++++++-
 2 files changed, 27 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/lib.rs b/rust/kernel/lib.rs
index 3da92f18f4eed16335c3c251e6bff68dcf7e781e..510cc7fe496113f85c34f420b1c4be95596297ad 100644
--- a/rust/kernel/lib.rs
+++ b/rust/kernel/lib.rs
@@ -20,6 +20,7 @@
 #![feature(generic_nonzero)]
 #![feature(inline_const)]
 #![feature(pointer_is_aligned)]
+#![feature(slice_ptr_len)]
 //
 // Stable since Rust 1.80.0.
 #![feature(slice_flatten)]
diff --git a/rust/kernel/ptr.rs b/rust/kernel/ptr.rs
index 5b6a382637fef11e9c0ae9122906422a970d7fcd..cf980a103acf19ee3bd17bb1dfdbcadfe30467ae 100644
--- a/rust/kernel/ptr.rs
+++ b/rust/kernel/ptr.rs
@@ -2,7 +2,10 @@
 
 //! Types and functions to work with pointers and addresses.
 
-use core::mem::align_of;
+use core::mem::{
+    align_of,
+    size_of, //
+};
 use core::num::NonZero;
 
 /// Type representing an alignment, which is always a power of two.
@@ -225,3 +228,25 @@ fn align_up(self, alignment: Alignment) -> Option<Self> {
 }
 
 impl_alignable_uint!(u8, u16, u32, u64, usize);
+
+/// Trait to represent compile-time known size information.
+///
+/// This is a generalization of what [`size_of`] which works for dynamically sized types.
+pub trait KnownSize {
+    /// Get the size of an object of this type in bytes, with the metadata of the given pointer.
+    fn size(p: *const Self) -> usize;
+}
+
+impl<T> KnownSize for T {
+    #[inline(always)]
+    fn size(_: *const Self) -> usize {
+        size_of::<T>()
+    }
+}
+
+impl<T> KnownSize for [T] {
+    #[inline(always)]
+    fn size(p: *const Self) -> usize {
+        p.len() * size_of::<T>()
+    }
+}

-- 
2.53.0

