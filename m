From: Jahnavi MN <jahnavimn@google.com>
Date: Fri, 03 Jul 2026 15:29:24 +0000
Subject: [PATCH 3/7] rust_binder: Implement the BINDER_DEBUG_USER_ERROR
 logging mask for reference counting and death notification operations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260703-rust_binder_debug_mask-v1-3-9bdf12b5325c@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783092563; l=6269;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=wYISGUiZ62G1sUQWRaNcvf79MLZFjEl4Cs5iopGT7K8=;
 b=JPXSZ3Y4gbZxwTwC4+JLWq4QE45Eq1a4pyD0ZHgE/Wx9ST1J8H4mlJs+Ish07v1UT+TEu/ngX
 GO+s3g34mMMBmEEHXwzGa2/9iCAxh4KafmR54N53vU+nRxPUiauER9J
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds dynamic debug logs for:
- Decrementing handle reference counts that are already zero.
- Mismatched reference states (calling inc_ref_done with no active
  inc_refs, or using a weak reference as a strong reference).
- Requesting or clearing death notifications on invalid references,
  already active notifications, or with mismatched cookies.

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/node.rs    | 16 +++++++++---
 drivers/android/binder/process.rs | 53 +++++++++++++++++++++++++++++++--------
 2 files changed, 55 insertions(+), 14 deletions(-)

diff --git a/drivers/android/binder/node.rs b/drivers/android/binder/node.rs
index 69f757ff7461..d71f55739772 100644
--- a/drivers/android/binder/node.rs
+++ b/drivers/android/binder/node.rs
@@ -343,7 +343,10 @@ pub(crate) fn inc_ref_done_locked(
     ) -> Option<DLArc<Node>> {
         let inner = self.inner.access_mut(owner_inner);
         if inner.active_inc_refs == 0 {
-            pr_err!("inc_ref_done called when no active inc_refs");
+            binder_debug!(
+                crate::debug::BINDER_DEBUG_USER_ERROR,
+                "inc_ref_done called when no active inc_refs"
+            );
             return None;
         }
 
@@ -818,6 +821,10 @@ pub(crate) fn get_count(&self) -> (usize, usize) {
 
     pub(crate) fn clone(&self, strong: bool) -> Result<NodeRef> {
         if strong && self.strong_count == 0 {
+            binder_debug!(
+                crate::debug::BINDER_DEBUG_USER_ERROR,
+                "tried to use weak ref as strong ref"
+            );
             return Err(EINVAL);
         }
         Ok(self
@@ -858,9 +865,10 @@ pub(crate) fn update(&mut self, inc: bool, strong: bool) -> bool {
             *count += 1;
         } else {
             if *count == 0 {
-                pr_warn!(
-                    "pid {} performed invalid decrement on ref\n",
-                    kernel::current!().pid()
+                binder_debug!(
+                    crate::debug::BINDER_DEBUG_USER_ERROR,
+                    "performed invalid decrement on ref (strong: {})",
+                    strong
                 );
                 return false;
             }
diff --git a/drivers/android/binder/process.rs b/drivers/android/binder/process.rs
index c13a04a3afcb..db929cc35585 100644
--- a/drivers/android/binder/process.rs
+++ b/drivers/android/binder/process.rs
@@ -898,10 +898,23 @@ pub(crate) fn insert_or_update_handle(
     }
 
     pub(crate) fn get_transaction_node(&self, handle: u32) -> BinderResult<NodeRef> {
-        if handle == 0 {
-            Ok(self.ctx.get_manager_node(true)?)
+        // When handle is zero, try to get the context manager.
+        let res = if handle == 0 {
+            self.ctx.get_manager_node(true)
         } else {
-            Ok(self.get_node_from_handle(handle, true)?)
+            self.get_node_from_handle(handle, true).map_err(Into::into)
+        };
+
+        match res {
+            Ok(node_ref) => Ok(node_ref),
+            Err(err) => {
+                binder_debug!(
+                    crate::debug::BINDER_DEBUG_USER_ERROR,
+                    "got transaction to invalid handle {}",
+                    handle
+                );
+                Err(err)
+            }
         }
     }
 
@@ -969,10 +982,13 @@ pub(crate) fn update_ref(
                     }
                 }
             }
-        } else {
             // All refs are cleared in process exit, so this warning is expected in that case.
             if !self.inner.lock().is_dead {
-                pr_warn!("{}: no such ref {handle}\n", self.pid_in_current_ns());
+                binder_debug!(
+                    crate::debug::BINDER_DEBUG_USER_ERROR,
+                    "no such ref {}",
+                    handle
+                );
             }
         }
         Ok(())
@@ -1225,13 +1241,20 @@ pub(crate) fn request_death(
         })?;
         let mut refs = self.node_refs.lock();
         let Some(info) = refs.by_handle.get_mut(&handle) else {
-            pr_warn!("BC_REQUEST_DEATH_NOTIFICATION invalid ref {handle}\n");
+            binder_debug!(
+                crate::debug::BINDER_DEBUG_USER_ERROR,
+                "BC_REQUEST_DEATH_NOTIFICATION invalid ref {}",
+                handle
+            );
             return Ok(());
         };
 
         // Nothing to do if there is already a death notification request for this handle.
         if info.death().is_some() {
-            pr_warn!("BC_REQUEST_DEATH_NOTIFICATION death notification already set\n");
+            binder_debug!(
+                crate::debug::BINDER_DEBUG_USER_ERROR,
+                "BC_REQUEST_DEATH_NOTIFICATION death notification already set"
+            );
             return Ok(());
         }
 
@@ -1268,17 +1291,27 @@ pub(crate) fn clear_death(&self, reader: &mut UserSliceReader, thread: &Thread)
 
         let mut refs = self.node_refs.lock();
         let Some(info) = refs.by_handle.get_mut(&handle) else {
-            pr_warn!("BC_CLEAR_DEATH_NOTIFICATION invalid ref {handle}\n");
+            binder_debug!(
+                crate::debug::BINDER_DEBUG_USER_ERROR,
+                "BC_CLEAR_DEATH_NOTIFICATION invalid ref {}",
+                handle
+            );
             return Ok(());
         };
 
         let Some(death) = info.death().take() else {
-            pr_warn!("BC_CLEAR_DEATH_NOTIFICATION death notification not active\n");
+            binder_debug!(
+                crate::debug::BINDER_DEBUG_USER_ERROR,
+                "BC_CLEAR_DEATH_NOTIFICATION death notification not active"
+            );
             return Ok(());
         };
         if death.cookie != cookie {
             *info.death() = Some(death);
-            pr_warn!("BC_CLEAR_DEATH_NOTIFICATION death notification cookie mismatch\n");
+            binder_debug!(
+                crate::debug::BINDER_DEBUG_USER_ERROR,
+                "BC_CLEAR_DEATH_NOTIFICATION death notification cookie mismatch"
+            );
             return Ok(());
         }
 

-- 
2.55.0.rc0.799.gd6f94ed593-goog

