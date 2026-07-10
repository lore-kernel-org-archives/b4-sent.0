From: Jahnavi MN <jahnavimn@google.com>
Date: Fri, 10 Jul 2026 14:32:58 +0000
Subject: [PATCH v2 7/7] rust_binder: Implement
 BINDER_DEBUG_DEAD_TRANSACTION
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-rust_binder_debug_mask-v2-7-2846410e3ae6@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783693978; l=12052;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=/yUSMdRwz5YpDWDgyZQe6oyUnLIUP1mYxzl8tnYI+0w=;
 b=3Tbv0Gx90Nqf0NjUIoH8CF+knO4x9P9cSPfN/LcM9Q6Ks1X3fJh1PhQYEMFXuQcFzcmCtQbFC
 MHI9SbWBsGmCZYt0CM+Nq7NDjaY/IfrdIQvqapBGyl6AhU2CrJrALnX
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds dynamic debug logs for:
- Releasing active transactions during thread stack unwinding.
- Discarded transaction error codes when a thread exits.
- Undelivered transaction acknowledgments (TRANSACTION_COMPLETE)
  upon thread exit.
- Undelivered process death and freeze notifications when processes
  exit or die.
- Undelivered transactions canceled due to target process death.

We now store the process PID in `ThreadError`, `DeliverCode`, and
`FreezeMessage` to ensure the correct PID is logged on cancellation.
This is necessary because `cancel()` runs from background `kworkers`,
which would otherwise print the wrong PID.

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/freeze.rs           | 24 ++++++++++------
 drivers/android/binder/node.rs             |  9 +++++-
 drivers/android/binder/rust_binder_main.rs | 14 ++++++++--
 drivers/android/binder/thread.rs           | 44 ++++++++++++++++++++++++------
 drivers/android/binder/transaction.rs      |  7 +++++
 5 files changed, 78 insertions(+), 20 deletions(-)

diff --git a/drivers/android/binder/freeze.rs b/drivers/android/binder/freeze.rs
index 70b192ec199a..8bc0bff54d81 100644
--- a/drivers/android/binder/freeze.rs
+++ b/drivers/android/binder/freeze.rs
@@ -60,6 +60,7 @@ fn allow_duplicate(&self, node: &DArc<Node>) -> bool {
 /// Represents a notification that the freeze state has changed.
 pub(crate) struct FreezeMessage {
     cookie: FreezeCookie,
+    pid: i32,
 }
 
 kernel::list::impl_list_arc_safe! {
@@ -73,8 +74,8 @@ fn new(flags: kernel::alloc::Flags) -> Result<UninitFM, AllocError> {
         UniqueArc::new_uninit(flags)
     }
 
-    fn init(ua: UninitFM, cookie: FreezeCookie) -> DLArc<FreezeMessage> {
-        match ua.pin_init_with(DTRWrap::new(FreezeMessage { cookie })) {
+    fn init(ua: UninitFM, cookie: FreezeCookie, pid: i32) -> DLArc<FreezeMessage> {
+        match ua.pin_init_with(DTRWrap::new(FreezeMessage { cookie, pid })) {
             Ok(msg) => ListArc::from(msg),
             Err(err) => match err {},
         }
@@ -140,7 +141,14 @@ fn do_work(
         }
     }
 
-    fn cancel(self: DArc<Self>) {}
+    fn cancel(self: DArc<Self>) {
+        binder_debug!(
+            pid=self.pid,
+            DeadTransaction,
+            "undelivered freeze notification, {:016x}",
+            self.cookie.0
+        );
+    }
 
     fn should_sync_wakeup(&self) -> bool {
         false
@@ -264,7 +272,7 @@ pub(crate) fn request_freeze_notif(
         }
 
         *info.freeze() = Some(cookie);
-        let msg = FreezeMessage::init(msg, cookie);
+        let msg = FreezeMessage::init(msg, cookie, self.task.pid());
         drop(node_refs_guard);
         let _ = self.push_work(msg);
         Ok(())
@@ -285,7 +293,7 @@ pub(crate) fn freeze_notif_done(self: &Arc<Self>, reader: &mut UserSliceReader)
         };
         let mut clear_msg = None;
         if freeze.num_pending_duplicates > 0 {
-            clear_msg = Some(FreezeMessage::init(alloc, cookie));
+            clear_msg = Some(FreezeMessage::init(alloc, cookie, self.task.pid()));
             freeze.num_pending_duplicates -= 1;
             freeze.num_cleared_duplicates += 1;
         } else {
@@ -300,7 +308,7 @@ pub(crate) fn freeze_notif_done(self: &Arc<Self>, reader: &mut UserSliceReader)
             let is_frozen = freeze.node.owner.inner.lock().is_frozen.is_fully_frozen();
             if freeze.is_clearing || freeze.last_is_frozen != Some(is_frozen) {
                 // Immediately send another FreezeMessage.
-                clear_msg = Some(FreezeMessage::init(alloc, cookie));
+                clear_msg = Some(FreezeMessage::init(alloc, cookie, self.task.pid()));
             }
             freeze.is_pending = false;
         }
@@ -353,7 +361,7 @@ pub(crate) fn clear_freeze_notif(self: &Arc<Self>, reader: &mut UserSliceReader)
         *info.freeze() = None;
         let mut msg = None;
         if !listener.is_pending {
-            msg = Some(FreezeMessage::init(alloc, cookie));
+            msg = Some(FreezeMessage::init(alloc, cookie, self.task.pid()));
         }
         drop(node_refs_guard);
 
@@ -433,7 +441,7 @@ pub(crate) fn prepare_freeze_messages(&self) -> Result<FreezeMessages, AllocErro
                 continue;
             };
             let msg_alloc = FreezeMessage::new(GFP_KERNEL)?;
-            let msg = FreezeMessage::init(msg_alloc, cookie);
+            let msg = FreezeMessage::init(msg_alloc, cookie, proc.task.pid());
             batch.push((proc, msg), GFP_KERNEL)?;
         }
 
diff --git a/drivers/android/binder/node.rs b/drivers/android/binder/node.rs
index 898412cfddd9..b2d9d518e32b 100644
--- a/drivers/android/binder/node.rs
+++ b/drivers/android/binder/node.rs
@@ -1128,7 +1128,14 @@ fn do_work(
         Ok(cmd != BR_DEAD_BINDER)
     }
 
-    fn cancel(self: DArc<Self>) {}
+    fn cancel(self: DArc<Self>) {
+        binder_debug!(
+            pid=self.process.task.pid(),
+            DeadTransaction,
+            "undelivered death notification, {:016x}",
+            self.cookie
+        );
+    }
 
     fn should_sync_wakeup(&self) -> bool {
         false
diff --git a/drivers/android/binder/rust_binder_main.rs b/drivers/android/binder/rust_binder_main.rs
index 995e6131bb77..31213b67b206 100644
--- a/drivers/android/binder/rust_binder_main.rs
+++ b/drivers/android/binder/rust_binder_main.rs
@@ -222,6 +222,7 @@ fn arc_pin_init(init: impl PinInit<T>) -> Result<DLArc<T>, kernel::error::Error>
 struct DeliverCode {
     code: u32,
     skip: Atomic<bool>,
+    pid: i32,
 }
 
 kernel::list::impl_list_arc_safe! {
@@ -229,10 +230,11 @@ struct DeliverCode {
 }
 
 impl DeliverCode {
-    fn new(code: u32) -> Self {
+    fn new(code: u32, pid: i32) -> Self {
         Self {
             code,
             skip: Atomic::new(false),
+            pid,
         }
     }
 
@@ -257,7 +259,15 @@ fn do_work(
         Ok(true)
     }
 
-    fn cancel(self: DArc<Self>) {}
+    fn cancel(self: DArc<Self>) {
+        if !self.skip.load(Relaxed) {
+            binder_debug!(
+                pid=self.pid,
+                DeadTransaction,
+                "undelivered TRANSACTION_COMPLETE"
+            );
+        }
+    }
 
     fn should_sync_wakeup(&self) -> bool {
         false
diff --git a/drivers/android/binder/thread.rs b/drivers/android/binder/thread.rs
index d7038b58c2ad..b93c37ad6845 100644
--- a/drivers/android/binder/thread.rs
+++ b/drivers/android/binder/thread.rs
@@ -281,7 +281,7 @@ struct InnerThread {
 const LOOPER_POLL: u32 = 0x40;
 
 impl InnerThread {
-    fn new() -> Result<Self> {
+    fn new(pid: i32) -> Result<Self> {
         fn next_err_id() -> u32 {
             static EE_ID: Atomic<u32> = Atomic::new(0);
             EE_ID.fetch_add(1, Relaxed)
@@ -292,8 +292,8 @@ fn next_err_id() -> u32 {
             looper_need_return: false,
             is_dead: false,
             process_work_list: false,
-            reply_work: ThreadError::try_new()?,
-            return_work: ThreadError::try_new()?,
+            reply_work: ThreadError::try_new(pid)?,
+            return_work: ThreadError::try_new(pid)?,
             work_list: List::new(),
             current_transaction: None,
             extended_error: ExtendedError::new(next_err_id(), BR_OK, 0),
@@ -452,7 +452,7 @@ impl ListItem<0> for Thread {
 
 impl Thread {
     pub(crate) fn new(id: i32, process: Arc<Process>) -> Result<Arc<Self>> {
-        let inner = InnerThread::new()?;
+        let inner = InnerThread::new(process.task.pid())?;
 
         Arc::pin_init(
             try_pin_init!(Thread {
@@ -1154,6 +1154,12 @@ fn unwind_transaction_stack(self: &Arc<Self>) {
             let mut inner = thread.inner.lock();
             inner.pop_transaction_to_reply(thread.as_ref())
         } {
+            binder_debug!(
+                DeadTransaction,
+                "release transaction {} in, still active",
+                transaction.debug_id
+            );
+
             let reply = Err(BR_DEAD_REPLY);
             if !transaction
                 .from
@@ -1354,7 +1360,10 @@ fn transaction_inner(self: &Arc<Self>, info: &mut TransactionInfo) -> BinderResu
         // TODO: We need to ensure that there isn't a pending transaction in the work queue. How
         // could this happen?
         let top = self.top_of_transaction_stack()?;
-        let list_completion = DTRWrap::arc_try_new(DeliverCode::new(BR_TRANSACTION_COMPLETE))?;
+        let list_completion = DTRWrap::arc_try_new(DeliverCode::new(
+            BR_TRANSACTION_COMPLETE,
+            self.process.task.pid(),
+        ))?;
         let completion = list_completion.clone_arc();
         let transaction = Transaction::new(node_ref, top, self, info)?;
 
@@ -1412,7 +1421,10 @@ fn reply_inner(self: &Arc<Self>, info: &mut TransactionInfo) -> BinderResult {
 
         // We need to complete the transaction even if we cannot complete building the reply.
         let out = (|| -> BinderResult<_> {
-            let completion = DTRWrap::arc_try_new(DeliverCode::new(BR_TRANSACTION_COMPLETE))?;
+            let completion = DTRWrap::arc_try_new(DeliverCode::new(
+                BR_TRANSACTION_COMPLETE,
+                self.process.task.pid(),
+            ))?;
             let process = orig.from.process.clone();
             let allow_fds = orig.flags & TF_ACCEPT_FDS != 0;
             let reply = Transaction::new_reply(self, process, info, allow_fds)?;
@@ -1453,7 +1465,10 @@ fn oneway_transaction_inner(self: &Arc<Self>, info: &mut TransactionInfo) -> Bin
         } else {
             BR_TRANSACTION_COMPLETE
         };
-        let list_completion = DTRWrap::arc_try_new(DeliverCode::new(code))?;
+        let list_completion = DTRWrap::arc_try_new(DeliverCode::new(
+            code,
+            self.process.task.pid(),
+        ))?;
         let completion = list_completion.clone_arc();
         // Not notifying: Reply to current thread.
         let _ = self.inner.lock().push_work(list_completion);
@@ -1692,14 +1707,16 @@ pub(crate) fn release(self: &Arc<Self>) {
 #[pin_data]
 struct ThreadError {
     error_code: Atomic<u32>,
+    pid: i32,
     #[pin]
     links_track: AtomicTracker,
 }
 
 impl ThreadError {
-    fn try_new() -> Result<DArc<Self>> {
+    fn try_new(pid: i32) -> Result<DArc<Self>> {
         DTRWrap::arc_pin_init(pin_init!(Self {
             error_code: Atomic::new(BR_OK),
+            pid,
             links_track <- AtomicTracker::new(),
         }))
         .map(ListArc::into_arc)
@@ -1726,7 +1743,16 @@ fn do_work(
         Ok(true)
     }
 
-    fn cancel(self: DArc<Self>) {}
+    fn cancel(self: DArc<Self>) {
+        let code = self.error_code.load(Relaxed);
+        if code != BR_OK {
+            binder_debug!(
+                pid=self.pid,
+                DeadTransaction,
+                "undelivered TRANSACTION_ERROR: {code}"
+            );
+        }
+    }
 
     fn should_sync_wakeup(&self) -> bool {
         false
diff --git a/drivers/android/binder/transaction.rs b/drivers/android/binder/transaction.rs
index f058d3d50eb7..c8f2b3e2ef57 100644
--- a/drivers/android/binder/transaction.rs
+++ b/drivers/android/binder/transaction.rs
@@ -532,6 +532,13 @@ fn cancel(self: DArc<Self>) {
         if self.target_node.is_some() && self.flags & TF_ONE_WAY == 0 {
             let reply = Err(BR_DEAD_REPLY);
             self.from.deliver_reply(reply, &self, None);
+        } else {
+            binder_debug!(
+                pid=self.to.task.pid(),
+                DeadTransaction,
+                "undelivered transaction {}, process died",
+                self.debug_id
+            );
         }
 
         self.drop_outstanding_txn();

-- 
2.55.0.795.g602f6c329a-goog

