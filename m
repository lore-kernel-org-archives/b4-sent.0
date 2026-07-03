From: Jahnavi MN <jahnavimn@google.com>
Date: Fri, 03 Jul 2026 15:29:25 +0000
Subject: [PATCH 4/7] rust_binder: Implement the BINDER_DEBUG_USER_ERROR
 logging mask for transaction parsing and protocol validation failures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260703-rust_binder_debug_mask-v1-4-9bdf12b5325c@google.com>
References: <20260703-rust_binder_debug_mask-v1-0-9bdf12b5325c@google.com>
In-Reply-To: <20260703-rust_binder_debug_mask-v1-0-9bdf12b5325c@google.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Carlos Llamas <cmllamas@google.com>, Alice Ryhl <aliceryhl@google.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Jahnavi MN <jahnavimn@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783092563; l=9574;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=rtNHxB4vjfIuxKSvuYNWGRnSLX4qWj6HY18AAyIfobM=;
 b=LbOnZm9gjDvJxeTauRY6od7Hhaooky+UsM7Xa+hFdPc9TA/CrUz4FVMwonfKFlb1PYSQNH1pB
 DMpQcypkM8NCUuZtb3HnMLKJPCINP/3AgUVVuH6MdTfRW8GkkFtpJoC
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds dynamic debug logs in `thread.rs` for:
- File descriptor array (FDA) parent offset and parent buffer address
  alignment misalignments.
- Memory copy, write, and translation failures during transaction
  serialization (including out-of-bounds pointer fixups).
- Incoming transactions or replies that do not match the expected
  thread calling stack (such as out-of-order replies).

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/thread.rs | 88 +++++++++++++++++++++++++++++++++-------
 1 file changed, 73 insertions(+), 15 deletions(-)

diff --git a/drivers/android/binder/thread.rs b/drivers/android/binder/thread.rs
index c908dde5796a..ecf05cebcb3e 100644
--- a/drivers/android/binder/thread.rs
+++ b/drivers/android/binder/thread.rs
@@ -721,11 +721,12 @@ fn translate_object(
                 let alloc_offset = match sg_state.unused_buffer_space.claim_next(obj_length) {
                     Ok(alloc_offset) => alloc_offset,
                     Err(err) => {
-                        pr_warn!(
-                            "Failed to claim space for a BINDER_TYPE_PTR. (offset: {}, limit: {}, size: {})",
+                        binder_debug!(
+                            crate::debug::BINDER_DEBUG_USER_ERROR,
+                            "failed to claim space for a BINDER_TYPE_PTR (offset: {}, limit: {}, size: {})",
                             sg_state.unused_buffer_space.offset,
                             sg_state.unused_buffer_space.limit,
-                            obj_length,
+                            obj_length
                         );
                         return Err(err.into());
                     }
@@ -804,6 +805,10 @@ fn translate_object(
                 let fds_len = num_fds.checked_mul(size_of::<u32>()).ok_or(EINVAL)?;
 
                 if !is_aligned(parent_offset, size_of::<u32>()) {
+                    binder_debug!(
+                        crate::debug::BINDER_DEBUG_USER_ERROR,
+                        "FDA parent offset not aligned correctly"
+                    );
                     return Err(EINVAL.into());
                 }
 
@@ -822,6 +827,10 @@ fn translate_object(
                 };
 
                 if !is_aligned(parent_entry.sender_uaddr, size_of::<u32>()) {
+                    binder_debug!(
+                        crate::debug::BINDER_DEBUG_USER_ERROR,
+                        "FDA parent buffer not aligned correctly"
+                    );
                     return Err(EINVAL.into());
                 }
 
@@ -905,8 +914,9 @@ fn apply_sg(&self, alloc: &mut Allocation, sg_state: &mut ScatterGatherState) ->
 
                 let target_offset_end = fixup_offset.checked_add(fixup_len).ok_or(EINVAL)?;
                 if fixup_offset < end_of_previous_fixup || offset_end < target_offset_end {
-                    pr_warn!(
-                        "Fixups oob {} {} {} {}",
+                    binder_debug!(
+                        crate::debug::BINDER_DEBUG_USER_ERROR,
+                        "fixups oob {} {} {} {}",
                         fixup_offset,
                         end_of_previous_fixup,
                         offset_end,
@@ -918,18 +928,31 @@ fn apply_sg(&self, alloc: &mut Allocation, sg_state: &mut ScatterGatherState) ->
                 let copy_off = end_of_previous_fixup;
                 let copy_len = fixup_offset - end_of_previous_fixup;
                 if let Err(err) = alloc.copy_into(&mut reader, copy_off, copy_len) {
-                    pr_warn!("Failed copying into alloc: {:?}", err);
+                    binder_debug!(
+                        crate::debug::BINDER_DEBUG_USER_ERROR,
+                        "failed copying into alloc: {:?}",
+                        err
+                    );
                     return Err(err.into());
                 }
                 if let PointerFixupEntry::Fixup { pointer_value, .. } = fixup {
                     let res = alloc.write::<u64>(fixup_offset, pointer_value);
                     if let Err(err) = res {
-                        pr_warn!("Failed copying ptr into alloc: {:?}", err);
+                        binder_debug!(
+                            crate::debug::BINDER_DEBUG_USER_ERROR,
+                            "failed copying ptr into alloc: {:?}",
+                            err
+                        );
                         return Err(err.into());
                     }
                 }
                 if let Err(err) = reader.skip(fixup_len) {
-                    pr_warn!("Failed skipping {} from reader: {:?}", fixup_len, err);
+                    binder_debug!(
+                        crate::debug::BINDER_DEBUG_USER_ERROR,
+                        "failed skipping {} from reader: {:?}",
+                        fixup_len,
+                        err
+                    );
                     return Err(err.into());
                 }
                 end_of_previous_fixup = target_offset_end;
@@ -937,7 +960,11 @@ fn apply_sg(&self, alloc: &mut Allocation, sg_state: &mut ScatterGatherState) ->
             let copy_off = end_of_previous_fixup;
             let copy_len = offset_end - end_of_previous_fixup;
             if let Err(err) = alloc.copy_into(&mut reader, copy_off, copy_len) {
-                pr_warn!("Failed copying remainder into alloc: {:?}", err);
+                binder_debug!(
+                    crate::debug::BINDER_DEBUG_USER_ERROR,
+                    "failed copying remainder into alloc: {:?}",
+                    err
+                );
                 return Err(err.into());
             }
         }
@@ -1041,7 +1068,10 @@ pub(crate) fn copy_transaction_data(
                 let offset: usize = offset.try_into().map_err(|_| EINVAL)?;
 
                 if offset < end_of_previous_object || !is_aligned(offset, size_of::<u32>()) {
-                    pr_warn!("Got transaction with invalid offset.");
+                    binder_debug!(
+                        crate::debug::BINDER_DEBUG_USER_ERROR,
+                        "got transaction with invalid offset"
+                    );
                     return Err(EINVAL.into());
                 }
 
@@ -1066,7 +1096,11 @@ pub(crate) fn copy_transaction_data(
                 ) {
                     Ok(()) => end_of_previous_object = offset + object.size(),
                     Err(err) => {
-                        pr_warn!("Error while translating object.");
+                        binder_debug!(
+                            crate::debug::BINDER_DEBUG_USER_ERROR,
+                            "error while translating object: {:?}",
+                            err
+                        );
                         return Err(err);
                     }
                 }
@@ -1087,14 +1121,22 @@ pub(crate) fn copy_transaction_data(
 
         if let Some(sg_state) = sg_state.as_mut() {
             if let Err(err) = self.apply_sg(&mut alloc, sg_state) {
-                pr_warn!("Failure in apply_sg: {:?}", err);
+                binder_debug!(
+                    crate::debug::BINDER_DEBUG_USER_ERROR,
+                    "failure in apply_sg: {:?}",
+                    err
+                );
                 return Err(err);
             }
         }
 
         if let Some((off_out, secctx)) = secctx.as_mut() {
             if let Err(err) = alloc.write(secctx_off, secctx.as_bytes()) {
-                pr_warn!("Failed to write security context: {:?}", err);
+                binder_debug!(
+                    crate::debug::BINDER_DEBUG_USER_ERROR,
+                    "failed to write security context: {:?}",
+                    err
+                );
                 return Err(err.into());
             }
             **off_out = secctx_off;
@@ -1283,7 +1325,10 @@ fn transaction_inner(self: &Arc<Self>, info: &mut TransactionInfo) -> BinderResu
         {
             let mut inner = self.inner.lock();
             if !transaction.is_stacked_on(&inner.current_transaction) {
-                pr_warn!("Transaction stack changed during transaction!");
+                binder_debug!(
+                    crate::debug::BINDER_DEBUG_USER_ERROR,
+                    "got new transaction with bad transaction stack"
+                );
                 return Err(EINVAL.into());
             }
             inner.current_transaction = Some(transaction.clone_arc());
@@ -1306,8 +1351,21 @@ fn transaction_inner(self: &Arc<Self>, info: &mut TransactionInfo) -> BinderResu
     }
 
     fn reply_inner(self: &Arc<Self>, info: &mut TransactionInfo) -> BinderResult {
-        let orig = self.inner.lock().pop_transaction_to_reply(self)?;
+        let orig = match self.inner.lock().pop_transaction_to_reply(self) {
+            Ok(orig) => orig,
+            Err(err) => {
+                binder_debug!(
+                    crate::debug::BINDER_DEBUG_USER_ERROR,
+                    "got reply transaction with no transaction stack"
+                );
+                return Err(err.into());
+            }
+        };
         if !orig.from.is_current_transaction(&orig) {
+            binder_debug!(
+                crate::debug::BINDER_DEBUG_USER_ERROR,
+                "got reply transaction with bad transaction stack"
+            );
             return Err(EINVAL.into());
         }
 

-- 
2.55.0.rc0.799.gd6f94ed593-goog

