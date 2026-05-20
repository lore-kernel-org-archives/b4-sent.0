From: Alvin Sun <alvin.sun@linux.dev>
Date: Wed, 20 May 2026 10:40:12 +0800
Subject: [PATCH v2 5/5] rust: block: mq: remove redundant imports and
 format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260520-miscdev-use-format-v2-5-64dc48fc1345@linux.dev>
References: <20260520-miscdev-use-format-v2-0-64dc48fc1345@linux.dev>
In-Reply-To: <20260520-miscdev-use-format-v2-0-64dc48fc1345@linux.dev>
To: Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-block@vger.kernel.org, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779244810; l=4389;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=VQ6SfO+yEalvsJozTTACmmQGrJq83YqYX2ySQ0d/Qu0=;
 b=WRfLGPOL/DVrS8+DRP30zCJWVbE2Uy0pEboRR5fzDRRDC72tTz7hNau3hIfotmTRLyddhwQvu
 OPVaIXkouRRC4qBuVV/glYg/MmhM6qB6LKqQCcTFOT/3OY16iJ44IgE
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop `Result`, `Pin`, `pin_data`, `pinned_drop`, `PinInit`, and
`try_pin_init` imports already provided by `kernel::prelude`.

Simplify `error` imports and flatten parameters formatting.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/block/mq/gen_disk.rs   |  7 +++----
 rust/kernel/block/mq/operations.rs |  5 +----
 rust/kernel/block/mq/request.rs    |  2 +-
 rust/kernel/block/mq/tag_set.rs    | 22 ++++------------------
 4 files changed, 9 insertions(+), 27 deletions(-)

diff --git a/rust/kernel/block/mq/gen_disk.rs b/rust/kernel/block/mq/gen_disk.rs
index 6f599f654f37f..a2c45bde75a7c 100644
--- a/rust/kernel/block/mq/gen_disk.rs
+++ b/rust/kernel/block/mq/gen_disk.rs
@@ -12,9 +12,8 @@
         TagSet, //
     },
     error::{
-        self,
         from_err_ptr,
-        Result, //
+        to_result, //
     },
     fmt::{
         self,
@@ -67,7 +66,7 @@ pub fn rotational(mut self, rotational: bool) -> Self {
     /// and that it is a power of two.
     pub fn validate_block_size(size: u32) -> Result {
         if !(512..=bindings::PAGE_SIZE as u32).contains(&size) || !size.is_power_of_two() {
-            Err(error::code::EINVAL)
+            Err(EINVAL)
         } else {
             Ok(())
         }
@@ -177,7 +176,7 @@ pub fn build<T: Operations>(
         // operation, so we will not race.
         unsafe { bindings::set_capacity(gendisk, self.capacity_sectors) };
 
-        crate::error::to_result(
+        to_result(
             // SAFETY: `gendisk` points to a valid and initialized instance of
             // `struct gendisk`.
             unsafe {
diff --git a/rust/kernel/block/mq/operations.rs b/rust/kernel/block/mq/operations.rs
index 187b0b7791db9..0343069b373c7 100644
--- a/rust/kernel/block/mq/operations.rs
+++ b/rust/kernel/block/mq/operations.rs
@@ -10,10 +10,7 @@
         request::RequestDataWrapper,
         Request, //
     },
-    error::{
-        from_result,
-        Result, //
-    },
+    error::from_result,
     prelude::*,
     sync::{
         aref::ARef,
diff --git a/rust/kernel/block/mq/request.rs b/rust/kernel/block/mq/request.rs
index 4e0579660e906..d10fb7627c870 100644
--- a/rust/kernel/block/mq/request.rs
+++ b/rust/kernel/block/mq/request.rs
@@ -7,7 +7,7 @@
 use crate::{
     bindings,
     block::mq::Operations,
-    error::Result,
+    prelude::*,
     sync::{
         aref::{
             ARef,
diff --git a/rust/kernel/block/mq/tag_set.rs b/rust/kernel/block/mq/tag_set.rs
index c1fd3e047af50..df3f90bfbb817 100644
--- a/rust/kernel/block/mq/tag_set.rs
+++ b/rust/kernel/block/mq/tag_set.rs
@@ -4,8 +4,6 @@
 //!
 //! C header: [`include/linux/blk-mq.h`](srctree/include/linux/blk-mq.h)
 
-use core::pin::Pin;
-
 use crate::{
     bindings,
     block::mq::{
@@ -13,22 +11,14 @@
         request::RequestDataWrapper,
         Operations, //
     },
-    error::{
-        self,
-        Result, //
-    },
-    prelude::try_pin_init,
+    error::to_result,
+    prelude::*,
     types::Opaque, //
 };
 use core::{
     convert::TryInto,
     marker::PhantomData, //
 };
-use pin_init::{
-    pin_data,
-    pinned_drop,
-    PinInit, //
-};
 
 /// A wrapper for the C `struct blk_mq_tag_set`.
 ///
@@ -47,11 +37,7 @@ pub struct TagSet<T: Operations> {
 
 impl<T: Operations> TagSet<T> {
     /// Try to create a new tag set
-    pub fn new(
-        nr_hw_queues: u32,
-        num_tags: u32,
-        num_maps: u32,
-    ) -> impl PinInit<Self, error::Error> {
+    pub fn new(nr_hw_queues: u32, num_tags: u32, num_maps: u32) -> impl PinInit<Self, Error> {
         let tag_set: bindings::blk_mq_tag_set = pin_init::zeroed();
         let tag_set: Result<_> = core::mem::size_of::<RequestDataWrapper>()
             .try_into()
@@ -77,7 +63,7 @@ pub fn new(
                 // SAFETY: we do not move out of `tag_set`.
                 let tag_set: &mut Opaque<_> = unsafe { Pin::get_unchecked_mut(tag_set) };
                 // SAFETY: `tag_set` is a reference to an initialized `blk_mq_tag_set`.
-                error::to_result( unsafe { bindings::blk_mq_alloc_tag_set(tag_set.get())})
+                to_result( unsafe { bindings::blk_mq_alloc_tag_set(tag_set.get())})
             }),
             _p: PhantomData,
         })

-- 
2.43.0

