From: Jahnavi MN <jahnavimn@google.com>
Date: Thu, 16 Jul 2026 08:37:49 +0000
Subject: [PATCH v4 7/7] rust_binder: Implement
 BINDER_DEBUG_DEAD_TRANSACTION
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-rust_binder_debug_mask-v4-7-3d7436c2d2f2@google.com>
References: <20260716-rust_binder_debug_mask-v4-0-3d7436c2d2f2@google.com>
In-Reply-To: <20260716-rust_binder_debug_mask-v4-0-3d7436c2d2f2@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784191078; l=12116;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=HUSRohfF0RC2eO/wDrADgQuF2C8u3Zj482GgfOMn2ic=;
 b=9t+WIVTZyOJmhsO2p11t9eoVLdWJunmnyEsRiX+NPVm+aFy77EnSRNS43GGT/BFg/lYWQ96DV
 nRZBGbfir82BcOiF7P9iB8kTZf+eEUYS+aIljXgI1qo8zp+v2ZPVDjI
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

Reviewed-by: Alice Ryhl <aliceryhl@google.com>
Reviewed-by: Carlos Llamas <cmllamas@google.com>
Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/freeze.rs           | 24 +++++++++++------
 drivers/android/binder/node.rs             |  9 ++++++-
 drivers/android/binder/rust_binder_main.rs | 14 ++++++++--
 drivers/android/binder/thread.rs           | 42 +++++++++++++++++++++++-------
 drivers/android/binder/transaction.rs      |  7 +++++
 5 files changed, 76 insertions(+), 20 deletions(-)

diff --git a/drivers/android/binder/freeze.rs b/drivers/android/binder/freeze.rs
index 318a9d2bb261..66912b4cb527 100644
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
+            pid = self.pid,
+            DeadTransaction,
+            "undelivered freeze notification, {:016x}",
+            self.cookie.0
+        );
+    }
 
     fn should_sync_wakeup(&self) -> bool {
         false
@@ -258,7 +266,7 @@ pub(crate) fn request_freeze_notif(
         }
 
         *info.freeze() = Some(cookie);
-        let msg = FreezeMessage::init(msg, cookie);
+        let msg = FreezeMessage::init(msg, cookie, self.task.pid());
         drop(node_refs_guard);
         let _ = self.push_work(msg);
         Ok(())
@@ -279,7 +287,7 @@ pub(crate) fn freeze_notif_done(self: &Arc<Self>, reader: &mut UserSliceReader)
         };
         let mut clear_msg = None;
         if freeze.num_pending_duplicates > 0 {
-            clear_msg = Some(FreezeMessage::init(alloc, cookie));
+            clear_msg = Some(FreezeMessage::init(alloc, cookie, self.task.pid()));
             freeze.num_pending_duplicates -= 1;
             freeze.num_cleared_duplicates += 1;
         } else {
@@ -294,7 +302,7 @@ pub(crate) fn freeze_notif_done(self: &Arc<Self>, reader: &mut UserSliceReader)
             let is_frozen = freeze.node.owner.inner.lock().is_frozen.is_fully_frozen();
             if freeze.is_clearing || freeze.last_is_frozen != Some(is_frozen) {
                 // Immediately send another FreezeMessage.
-                clear_msg = Some(FreezeMessage::init(alloc, cookie));
+                clear_msg = Some(FreezeMessage::init(alloc, cookie, self.task.pid()));
             }
             freeze.is_pending = false;
         }
@@ -347,7 +355,7 @@ pub(crate) fn clear_freeze_notif(self: &Arc<Self>, reader: &mut UserSliceReader)
         *info.freeze() = None;
         let mut msg = None;
         if !listener.is_pending {
-            msg = Some(FreezeMessage::init(alloc, cookie));
+            msg = Some(FreezeMessage::init(alloc, cookie, self.task.pid()));
         }
         drop(node_refs_guard);
 
@@ -427,7 +435,7 @@ pub(crate) fn prepare_freeze_messages(&self) -> Result<FreezeMessages, AllocErro
                 continue;
             };
             let msg_alloc = FreezeMessage::new(GFP_KERNEL)?;
-            let msg = FreezeMessage::init(msg_alloc, cookie);
+            let msg = FreezeMessage::init(msg_alloc, cookie, proc.task.pid());
             batch.push((proc, msg), GFP_KERNEL)?;
         }
 
diff --git a/drivers/android/binder/node.rs b/drivers/android/binder/node.rs
index 8a87dc366aa9..c73cdf82100f 100644
--- a/drivers/android/binder/node.rs
+++ b/drivers/android/binder/node.rs
@@ -1122,7 +1122,14 @@ fn do_work(
         Ok(cmd != BR_DEAD_BINDER)
     }
 
-    fn cancel(self: DArc<Self>) {}
+    fn cancel(self: DArc<Self>) {
+        binder_debug!(
+            pid = self.process.task.pid(),
+            DeadTransaction,
+            "undelivered death notification, {:016x}",
+            self.cookie
+        );
+    }
 
     fn should_sync_wakeup(&self) -> bool {
         false
diff --git a/drivers/android/binder/rust_binder_main.rs b/drivers/android/binder/rust_binder_main.rs
index 29829cb210a4..15c7b65928d8 100644
--- a/drivers/android/binder/rust_binder_main.rs
+++ b/drivers/android/binder/rust_binder_main.rs
@@ -221,6 +221,7 @@ fn arc_pin_init(init: impl PinInit<T>) -> Result<DLArc<T>, kernel::error::Error>
 struct DeliverCode {
     code: u32,
     skip: Atomic<bool>,
+    pid: i32,
 }
 
 kernel::list::impl_list_arc_safe! {
@@ -228,10 +229,11 @@ struct DeliverCode {
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
 
@@ -256,7 +258,15 @@ fn do_work(
         Ok(true)
     }
 
-    fn cancel(self: DArc<Self>) {}
+    fn cancel(self: DArc<Self>) {
+        if !self.skip.load(Relaxed) {
+            binder_debug!(
+                pid = self.pid,
+                DeadTransaction,
+                "undelivered TRANSACTION_COMPLETE"
+            );
+        }
+    }
 
     fn should_sync_wakeup(&self) -> bool {
         false
diff --git a/drivers/android/binder/thread.rs b/drivers/android/binder/thread.rs
index 38b90c79c057..edc2613d13b5 100644
--- a/drivers/android/binder/thread.rs
+++ b/drivers/android/binder/thread.rs
@@ -279,7 +279,7 @@ struct InnerThread {
 const LOOPER_POLL: u32 = 0x40;
 
 impl InnerThread {
-    fn new() -> Result<Self> {
+    fn new(pid: i32) -> Result<Self> {
         fn next_err_id() -> u32 {
             static EE_ID: Atomic<u32> = Atomic::new(0);
             EE_ID.fetch_add(1, Relaxed)
@@ -290,8 +290,8 @@ fn next_err_id() -> u32 {
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
@@ -445,7 +445,7 @@ impl ListItem<0> for Thread {
 
 impl Thread {
     pub(crate) fn new(id: i32, process: Arc<Process>) -> Result<Arc<Self>> {
-        let inner = InnerThread::new()?;
+        let inner = InnerThread::new(process.task.pid())?;
 
         Arc::pin_init(
             try_pin_init!(Thread {
@@ -1115,6 +1115,12 @@ fn unwind_transaction_stack(self: &Arc<Self>) {
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
@@ -1305,7 +1311,10 @@ fn transaction_inner(self: &Arc<Self>, info: &mut TransactionInfo) -> BinderResu
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
 
@@ -1357,7 +1366,10 @@ fn reply_inner(self: &Arc<Self>, info: &mut TransactionInfo) -> BinderResult {
 
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
@@ -1397,7 +1409,8 @@ fn oneway_transaction_inner(self: &Arc<Self>, info: &mut TransactionInfo) -> Bin
         } else {
             BR_TRANSACTION_COMPLETE
         };
-        let list_completion = DTRWrap::arc_try_new(DeliverCode::new(code))?;
+        let list_completion =
+            DTRWrap::arc_try_new(DeliverCode::new(code, self.process.task.pid()))?;
         let completion = list_completion.clone_arc();
         self.inner.lock().push_work(list_completion);
         match transaction.submit(info) {
@@ -1653,14 +1666,16 @@ pub(crate) fn release(self: &Arc<Self>) {
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
@@ -1687,7 +1702,16 @@ fn do_work(
         Ok(true)
     }
 
-    fn cancel(self: DArc<Self>) {}
+    fn cancel(self: DArc<Self>) {
+        let code = self.error_code.load(Relaxed);
+        if code != BR_OK {
+            binder_debug!(
+                pid = self.pid,
+                DeadTransaction,
+                "undelivered TRANSACTION_ERROR: {code}"
+            );
+        }
+    }
 
     fn should_sync_wakeup(&self) -> bool {
         false
diff --git a/drivers/android/binder/transaction.rs b/drivers/android/binder/transaction.rs
index 069c792d2200..0528070fe700 100644
--- a/drivers/android/binder/transaction.rs
+++ b/drivers/android/binder/transaction.rs
@@ -488,6 +488,13 @@ fn cancel(self: DArc<Self>) {
         if self.target_node.is_some() && self.flags & TF_ONE_WAY == 0 {
             let reply = Err(BR_DEAD_REPLY);
             self.from.deliver_reply(reply, &self, None);
+        } else {
+            binder_debug!(
+                pid = self.to.task.pid(),
+                DeadTransaction,
+                "undelivered transaction {}, process died",
+                self.debug_id
+            );
         }
 
         self.drop_outstanding_txn();

-- 
2.55.0.229.g6434b31f56-goog

