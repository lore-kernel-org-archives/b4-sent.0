From: Peder Bergan <peder.bergan@gmail.com>
Date: Mon, 16 Nov 2026 13:53:32 +0100
Subject: [PATCH] rust: alloc: check the length precondition in
 Vec::from_raw_parts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-vec-raw-parts-precondition-v1-1-8f633f66b4c1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMv8+moC/yWMSQ6DMAxFr4K8riWCCoteperCMW5JRQOywyAh7
 t6kXb4/vANMNIjBrTpAZQ0WppjBXSrggeJLMPSZoambzjnX4SqMShvOpMlwVuEp9iHlG/r2WpN
 vmVk8ZEEun2H/ye+PP9vi38KpGMvCkwl6pchDiZbZkgp9kMZxYoyyJzjPL3kdRwqkAAAA
X-Change-ID: 20261116-vec-raw-parts-precondition-b540ab5ccceb
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>
Cc: Lorenzo Stoakes <ljs@kernel.org>, Vlastimil Babka <vbabka@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Uladzislau Rezki <urezki@gmail.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794833612; l=2687;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=8AL5TouHwkYVMGdbW1C9LR1cjbYm5Y41STYkvRtrL4E=;
 b=C71Hvp9FqzTymLLh+nECFQ02HlfuynnuaZJoG3z1rj9QjDIEIibvSjG9SM2olgoWXiYtOlLW0
 xl1FNloM/eWBf7daFFqCZOq7Gm5USwEBn9LDHv5AuzgoI2dEBPplWj/
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Vec::from_raw_parts() requires length to be no greater than capacity for
nonzero-sized elements. Check this precondition with
unsafe_precondition_assert!() before constructing the vector so debug
builds diagnose invalid raw parts at this boundary.

Keep the check in the nonzero-sized branch because zero-sized vectors
ignore the capacity argument. Add a KUnit test for reconstructing a
nonempty zero-sized vector with a zero capacity argument.

Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://github.com/Rust-for-Linux/linux/issues/1232
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
Based on alloc-next.

My validation used the x86_64 rust_kvec KUnit suite under QEMU with
CLIPPY=1 and debug assertions enabled and disabled. All six tests passed
in both configurations. A temporary invalid-length probe triggered the
expected precondition diagnostic. The baseline has an unrelated unused
function warning in io/resource.rs, also present after this change.

OpenAI Codex assisted with coding and testing.
---
 rust/kernel/alloc/kvec.rs | 17 ++++++++++++++++-
 1 file changed, 16 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/alloc/kvec.rs b/rust/kernel/alloc/kvec.rs
index cd0c57a9a..b8f4c1692 100644
--- a/rust/kernel/alloc/kvec.rs
+++ b/rust/kernel/alloc/kvec.rs
@@ -23,7 +23,8 @@ use crate::{
     page::{
         AsPageIter,
         PAGE_SIZE, //
-    }, //
+    },
+    unsafe_precondition_assert, //
 };
 
 use core::{
@@ -685,6 +686,8 @@ where
         let layout = if Self::is_zst() {
             ArrayLayout::empty()
         } else {
+            unsafe_precondition_assert!(length <= capacity);
+
             // SAFETY: By the safety requirements of this function, `capacity * size_of::<T>()` is
             // smaller than `isize::MAX`.
             unsafe { ArrayLayout::new_unchecked(capacity) }
@@ -1623,6 +1626,18 @@ mod tests {
     use super::*;
     use crate::prelude::*;
 
+    #[test]
+    fn test_kvec_from_raw_parts_zst() {
+        let ptr = NonNull::<()>::dangling().as_ptr();
+
+        // SAFETY: For a zero-sized type, `ptr` only needs to be dangling and well aligned.
+        // The capacity argument is ignored.
+        let v = unsafe { KVec::from_raw_parts(ptr, 3, 0) };
+
+        assert_eq!(v.len(), 3);
+        assert_eq!(v.capacity(), usize::MAX);
+    }
+
     #[test]
     fn test_kvec_retain() {
         /// Verify correctness for one specific function.

---
base-commit: a2a82cbb73342d605078cb85763472f40156af1f
change-id: 20261116-vec-raw-parts-precondition-b540ab5ccceb

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

