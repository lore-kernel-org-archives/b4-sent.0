From: Jahnavi MN <jahnavimn@google.com>
Date: Mon, 13 Jul 2026 12:35:25 +0000
Subject: [PATCH v3 3/7] rust_binder: Implement BINDER_DEBUG_USER_ERROR for
 refcounting and death notifications
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260713-rust_binder_debug_mask-v3-3-0de91bbbbf69@google.com>
References: <20260713-rust_binder_debug_mask-v3-0-0de91bbbbf69@google.com>
In-Reply-To: <20260713-rust_binder_debug_mask-v3-0-0de91bbbbf69@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783946130; l=5500;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=n2ioxy8X3U3e9NVWBVzSAwJusdCsQh1BHz2egIQgfEQ=;
 b=MO8IlYFjrnEoXStu/brtl94lkacOAz7rfHWwj0c74IKkdRpD40p2ooFFo+bYlbZYemMMVmFn3
 4OeRvkYUB9yDw0PAU5zF8cXa3MqWFj/2K7kEmZSZxMc9YOXZ8v55u9o
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

Reviewed-by: Carlos Llamas <cmllamas@google.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/node.rs    | 10 ++++++----
 drivers/android/binder/process.rs | 35 ++++++++++++++++++++++++++++-------
 2 files changed, 34 insertions(+), 11 deletions(-)

diff --git a/drivers/android/binder/node.rs b/drivers/android/binder/node.rs
index fb57c0b20888..3f0757058b84 100644
--- a/drivers/android/binder/node.rs
+++ b/drivers/android/binder/node.rs
@@ -345,7 +345,7 @@ pub(crate) fn inc_ref_done_locked(
     ) -> Option<DLArc<Node>> {
         let inner = self.inner.access_mut(owner_inner);
         if inner.active_inc_refs == 0 {
-            pr_err!("inc_ref_done called when no active inc_refs");
+            binder_debug!(UserError, "inc_ref_done called when no active inc_refs");
             return None;
         }
 
@@ -819,6 +819,7 @@ pub(crate) fn get_count(&self) -> (usize, usize) {
 
     pub(crate) fn clone(&self, strong: bool) -> Result<NodeRef> {
         if strong && self.strong_count == 0 {
+            binder_debug!(UserError, "tried to use weak ref as strong ref");
             return Err(EINVAL);
         }
         Ok(self
@@ -859,9 +860,10 @@ pub(crate) fn update(&mut self, inc: bool, strong: bool) -> bool {
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
index 6dd39939e7ae..38190aaa462d 100644
--- a/drivers/android/binder/process.rs
+++ b/drivers/android/binder/process.rs
@@ -908,7 +908,13 @@ pub(crate) fn get_transaction_node(&self, handle: u32) -> BinderResult<NodeRef>
         if handle == 0 {
             Ok(self.ctx.get_manager_node(true)?)
         } else {
-            Ok(self.get_node_from_handle(handle, true)?)
+            match self.get_node_from_handle(handle, true) {
+                Ok(node_ref) => Ok(node_ref),
+                Err(err) => {
+                    binder_debug!(UserError, "got transaction to invalid handle {handle}");
+                    Err(err.into())
+                }
+            }
         }
     }
 
@@ -983,7 +989,7 @@ pub(crate) fn update_ref(
         } else {
             // All refs are cleared in process exit, so this warning is expected in that case.
             if !self.inner.lock().is_dead {
-                pr_warn!("{}: no such ref {handle}\n", self.pid_in_current_ns());
+                binder_debug!(UserError, "no such ref {handle}");
             }
         }
         Ok(())
@@ -1236,13 +1242,19 @@ pub(crate) fn request_death(
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
 
@@ -1279,17 +1291,26 @@ pub(crate) fn clear_death(&self, reader: &mut UserSliceReader, thread: &Thread)
 
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

