From: Jahnavi MN <jahnavimn@google.com>
Date: Fri, 10 Jul 2026 14:32:54 +0000
Subject: [PATCH v2 3/7] rust_binder: Implement BINDER_DEBUG_USER_ERROR for
 refcounting and death notifications
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-rust_binder_debug_mask-v2-3-2846410e3ae6@google.com>
References: <20260710-rust_binder_debug_mask-v2-0-2846410e3ae6@google.com>
In-Reply-To: <20260710-rust_binder_debug_mask-v2-0-2846410e3ae6@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783693978; l=5625;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=zAMgy2SoPMFXZ1AHIKVgSFCivXysxf/SNJjlgUrLIj4=;
 b=wz0M+F7EXrCHNob2H7H7yZTWpLGmu31vnMY7k9mVDNgfkAA0aaxGY999sYK1VON3tZC7zEO5/
 X07RZFqjUl4BB54zt12FJE9LBM9mp839yVEwmyVaJH+aGXSqXI3XJ2d
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
 drivers/android/binder/node.rs    | 16 +++++++++++----
 drivers/android/binder/process.rs | 41 ++++++++++++++++++++++++++++++++-------
 2 files changed, 46 insertions(+), 11 deletions(-)

diff --git a/drivers/android/binder/node.rs b/drivers/android/binder/node.rs
index 2b0618938a0a..dfad3697f672 100644
--- a/drivers/android/binder/node.rs
+++ b/drivers/android/binder/node.rs
@@ -345,7 +345,10 @@ pub(crate) fn inc_ref_done_locked(
     ) -> Option<DLArc<Node>> {
         let inner = self.inner.access_mut(owner_inner);
         if inner.active_inc_refs == 0 {
-            pr_err!("inc_ref_done called when no active inc_refs");
+            binder_debug!(
+                UserError,
+                "inc_ref_done called when no active inc_refs"
+            );
             return None;
         }
 
@@ -821,6 +824,10 @@ pub(crate) fn get_count(&self) -> (usize, usize) {
 
     pub(crate) fn clone(&self, strong: bool) -> Result<NodeRef> {
         if strong && self.strong_count == 0 {
+            binder_debug!(
+                UserError,
+                "tried to use weak ref as strong ref"
+            );
             return Err(EINVAL);
         }
         Ok(self
@@ -861,9 +868,10 @@ pub(crate) fn update(&mut self, inc: bool, strong: bool) -> bool {
             *count += 1;
         } else {
             if *count == 0 {
-                pr_warn!(
-                    "pid {} performed invalid decrement on ref\n",
-                    kernel::current!().pid()
+                binder_debug!(
+                    UserError,
+                    "performed invalid {} decrement on ref",
+                    if strong { "strong" } else { "weak" }
                 );
                 return false;
             }
diff --git a/drivers/android/binder/process.rs b/drivers/android/binder/process.rs
index 836a0db92354..db2b0230d19f 100644
--- a/drivers/android/binder/process.rs
+++ b/drivers/android/binder/process.rs
@@ -920,7 +920,16 @@ pub(crate) fn get_transaction_node(&self, handle: u32) -> BinderResult<NodeRef>
             }
             Ok(node_ref)
         } else {
-            Ok(self.get_node_from_handle(handle, true)?)
+            match self.get_node_from_handle(handle, true) {
+                Ok(node_ref) => Ok(node_ref),
+                Err(err) => {
+                    binder_debug!(
+                        UserError,
+                        "got transaction to invalid handle {handle}"
+                    );
+                    Err(err.into())
+                }
+            }
         }
     }
 
@@ -1005,7 +1014,10 @@ pub(crate) fn update_ref(
         } else {
             // All refs are cleared in process exit, so this warning is expected in that case.
             if !self.inner.lock().is_dead {
-                pr_warn!("{}: no such ref {handle}\n", self.pid_in_current_ns());
+                binder_debug!(
+                    UserError,
+                    "no such ref {handle}"
+                );
             }
         }
         Ok(())
@@ -1258,13 +1270,19 @@ pub(crate) fn request_death(
         })?;
         let mut refs = self.node_refs.lock();
         let Some(info) = refs.by_handle.get_mut(&handle) else {
-            pr_warn!("BC_REQUEST_DEATH_NOTIFICATION invalid ref {handle}\n");
+            binder_debug!(
+                UserError,
+                "BC_REQUEST_DEATH_NOTIFICATION invalid ref {handle}"
+            );
             return Ok(());
         };
 
         // Nothing to do if there is already a death notification request for this handle.
         if info.death().is_some() {
-            pr_warn!("BC_REQUEST_DEATH_NOTIFICATION death notification already set\n");
+            binder_debug!(
+                UserError,
+                "BC_REQUEST_DEATH_NOTIFICATION death notification already set"
+            );
             return Ok(());
         }
 
@@ -1301,17 +1319,26 @@ pub(crate) fn clear_death(&self, reader: &mut UserSliceReader, thread: &Thread)
 
         let mut refs = self.node_refs.lock();
         let Some(info) = refs.by_handle.get_mut(&handle) else {
-            pr_warn!("BC_CLEAR_DEATH_NOTIFICATION invalid ref {handle}\n");
+            binder_debug!(
+                UserError,
+                "BC_CLEAR_DEATH_NOTIFICATION invalid ref {handle}"
+            );
             return Ok(());
         };
 
         let Some(death) = info.death().take() else {
-            pr_warn!("BC_CLEAR_DEATH_NOTIFICATION death notification not active\n");
+            binder_debug!(
+                UserError,
+                "BC_CLEAR_DEATH_NOTIFICATION death notification not active"
+            );
             return Ok(());
         };
         if death.cookie != cookie {
             *info.death() = Some(death);
-            pr_warn!("BC_CLEAR_DEATH_NOTIFICATION death notification cookie mismatch\n");
+            binder_debug!(
+                UserError,
+                "BC_CLEAR_DEATH_NOTIFICATION death notification cookie mismatch"
+            );
             return Ok(());
         }
 

-- 
2.55.0.795.g602f6c329a-goog

