From: Jahnavi MN <jahnavimn@google.com>
Date: Sun, 19 Jul 2026 09:56:59 +0000
Subject: [PATCH v2 2/2] rust_binder: Update transaction flags to use
 kernel::impl_flags!
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260719-b4-rust_binder_impl_flags-v2-2-7a5debdfa39c@google.com>
References: <20260719-b4-rust_binder_impl_flags-v2-0-7a5debdfa39c@google.com>
In-Reply-To: <20260719-b4-rust_binder_impl_flags-v2-0-7a5debdfa39c@google.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Carlos Llamas <cmllamas@google.com>, Alice Ryhl <aliceryhl@google.com>, 
 Benno Lossin <lossin@kernel.org>, Gary Guo <gary@garyguo.net>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Jahnavi MN <jahnavimn@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784455020; l=9219;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=An+Z09A906s/tyyin0FuLA6y0ENPk4CNLdXSHAc41d4=;
 b=q7GeN+JvzAhFeWVEMJrGG6Q6L8l2IXS66LgAiNMtdjGf+MZH5/9vRCxmIFjT2cOHn9Az17UY+
 k5lqr+XY98tBzXpQnj4n0/bB0Yw/zmgDkpjLue09ig6OZ5xyPsqzKdy
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Define `TransactionFlags(u32)` and `TransactionFlag` with 4 variants.
- Change flags field type to `TransactionFlags` in structs.
- Add `is_oneway` helper on `TransactionFlags` to simplify checks.
- Update `can_replace` logic to use type-safe combined flag checks.
- Convert `flags` to `u32` for FFI boundaries and logging.

Reviewed-by: Alice Ryhl <aliceryhl@google.com>
Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/thread.rs      |  6 ++--
 drivers/android/binder/transaction.rs | 58 ++++++++++++++++++++++++++---------
 2 files changed, 46 insertions(+), 18 deletions(-)

diff --git a/drivers/android/binder/thread.rs b/drivers/android/binder/thread.rs
index ef692fe79201..6c838884fc07 100644
--- a/drivers/android/binder/thread.rs
+++ b/drivers/android/binder/thread.rs
@@ -30,7 +30,7 @@
     process::{GetWorkOrRegister, Process},
     ptr_align,
     stats::GLOBAL_STATS,
-    transaction::{Transaction, TransactionInfo},
+    transaction::{Transaction, TransactionFlag, TransactionFlags, TransactionInfo},
     BinderReturnWriter, DArc, DLArc, DTRWrap, DeliverCode, DeliverToRead,
 };
 
@@ -1266,7 +1266,7 @@ fn read_transaction_info(
         info.from_pid = self.process.task.pid();
         info.from_tid = self.id;
         info.code = td.transaction_data.code;
-        info.flags = td.transaction_data.flags;
+        info.flags = TransactionFlags::from_bits(td.transaction_data.flags);
         info.data_ptr = UserPtr::from_addr(trd_data_ptr.buffer as usize);
         info.data_size = td.transaction_data.data_size as usize;
         info.offsets_ptr = UserPtr::from_addr(trd_data_ptr.offsets as usize);
@@ -1408,7 +1408,7 @@ fn reply_inner(self: &Arc<Self>, info: &mut TransactionInfo) -> BinderResult {
                 self.process.task.pid(),
             ))?;
             let process = orig.from.process.clone();
-            let allow_fds = orig.flags & TF_ACCEPT_FDS != 0;
+            let allow_fds = orig.flags.contains(TransactionFlag::AcceptFds);
             let reply = Transaction::new_reply(self, process, info, allow_fds)?;
             // Not notifying: Reply to current thread.
             let _ = self.inner.lock().push_work(completion);
diff --git a/drivers/android/binder/transaction.rs b/drivers/android/binder/transaction.rs
index 13dfb5c5c955..245f1556b5db 100644
--- a/drivers/android/binder/transaction.rs
+++ b/drivers/android/binder/transaction.rs
@@ -27,6 +27,33 @@
     BinderReturnWriter, DArc, DLArc, DTRWrap, DeliverToRead,
 };
 
+kernel::impl_flags!(
+    /// Represents multiple transaction flags.
+    #[derive(Debug, Clone, Default, Copy, PartialEq, Eq, Zeroable)]
+    pub struct TransactionFlags(u32);
+
+    /// Represents a single transaction flag.
+    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
+    pub enum TransactionFlag {
+        OneWay = TF_ONE_WAY,
+        AcceptFds = TF_ACCEPT_FDS,
+        ClearBuf = TF_CLEAR_BUF,
+        UpdateTxn = TF_UPDATE_TXN,
+    }
+);
+
+impl TransactionFlags {
+    /// Creates a `TransactionFlags` from a raw `u32` value.
+    pub(crate) fn from_bits(bits: u32) -> Self {
+        Self(bits)
+    }
+
+    /// Checks if the Oneway flag is set.
+    pub(crate) fn is_oneway(self) -> bool {
+        self.contains(TransactionFlag::OneWay)
+    }
+}
+
 #[derive(Zeroable)]
 pub(crate) struct TransactionInfo {
     pub(crate) from_pid: Pid,
@@ -34,7 +61,7 @@ pub(crate) struct TransactionInfo {
     pub(crate) to_pid: Pid,
     pub(crate) to_tid: Pid,
     pub(crate) code: u32,
-    pub(crate) flags: u32,
+    pub(crate) flags: TransactionFlags,
     pub(crate) data_ptr: UserPtr,
     pub(crate) data_size: usize,
     pub(crate) offsets_ptr: UserPtr,
@@ -51,7 +78,7 @@ pub(crate) struct TransactionInfo {
 impl TransactionInfo {
     #[inline]
     pub(crate) fn is_oneway(&self) -> bool {
-        self.flags & TF_ONE_WAY != 0
+        self.flags.is_oneway()
     }
 
     pub(crate) fn report_netlink(&self, reply: u32, ctx: &crate::Context) {
@@ -84,7 +111,7 @@ fn report_netlink_inner(&self, reply: u32, ctx: &crate::Context) -> kernel::erro
         if self.is_reply {
             report.is_reply()?;
         }
-        report.flags(self.flags)?;
+        report.flags(u32::from(self.flags))?;
         report.code(self.code)?;
         report.data_size(self.data_size as u32)?;
 
@@ -115,7 +142,7 @@ pub(crate) struct Transaction {
     allocation: SpinLock<Option<Allocation>>,
     is_outstanding: Atomic<bool>,
     code: u32,
-    pub(crate) flags: u32,
+    pub(crate) flags: TransactionFlags,
     data_size: usize,
     offsets_size: usize,
     data_address: usize,
@@ -161,7 +188,7 @@ pub(crate) fn new(
             }
             alloc.set_info_oneway_node(node_ref.node.clone());
         }
-        if info.flags & TF_CLEAR_BUF != 0 {
+        if info.flags.contains(TransactionFlag::ClearBuf) {
             alloc.set_info_clear_on_drop();
         }
         let target_node = node_ref.node.clone();
@@ -201,7 +228,7 @@ pub(crate) fn new_reply(
                     return Err(err);
                 }
             };
-        if info.flags & TF_CLEAR_BUF != 0 {
+        if info.flags.contains(TransactionFlag::ClearBuf) {
             alloc.set_info_clear_on_drop();
         }
         Ok(DTRWrap::arc_pin_init(pin_init!(Transaction {
@@ -234,7 +261,7 @@ pub(crate) fn debug_print_inner(&self, m: &SeqFile, prefix: &str) {
             self.from.id,
             self.to.task.pid(),
             self.code,
-            self.flags,
+            u32::from(self.flags),
             self.start_time.elapsed().as_millis(),
         );
         if let Some(target_node) = &self.target_node {
@@ -313,7 +340,7 @@ pub(crate) fn submit(self: DLArc<Self>, info: &mut TransactionInfo) -> BinderRes
         let _t_outdated;
         let _oneway_node;
 
-        let oneway = self.flags & TF_ONE_WAY != 0;
+        let oneway = self.flags.is_oneway();
         let process = self.to.clone();
         let mut process_inner = process.inner.lock();
 
@@ -324,7 +351,7 @@ pub(crate) fn submit(self: DLArc<Self>, info: &mut TransactionInfo) -> BinderRes
                 crate::trace::trace_transaction(false, &self, None);
                 if process_inner.is_frozen.is_frozen() {
                     process_inner.async_recv = true;
-                    if self.flags & TF_UPDATE_TXN != 0 {
+                    if self.flags.contains(TransactionFlag::UpdateTxn) {
                         if let Some(t_outdated) =
                             target_node.take_outdated_transaction(&self, &mut process_inner)
                         {
@@ -399,7 +426,8 @@ pub(crate) fn can_replace(&self, old: &Transaction) -> bool {
             return false;
         }
 
-        if self.flags & old.flags & (TF_ONE_WAY | TF_UPDATE_TXN) != (TF_ONE_WAY | TF_UPDATE_TXN) {
+        let required = TransactionFlag::OneWay | TransactionFlag::UpdateTxn;
+        if !(self.flags.contains_all(required) && old.flags.contains_all(required)) {
             return false;
         }
 
@@ -436,7 +464,7 @@ fn do_work(
         writer: &mut BinderReturnWriter<'_>,
     ) -> Result<bool> {
         let send_failed_reply = ScopeGuard::new(|| {
-            if self.target_node.is_some() && self.flags & TF_ONE_WAY == 0 {
+            if self.target_node.is_some() && !self.flags.is_oneway() {
                 let reply = Err(BR_FAILED_REPLY);
                 self.from.deliver_reply(reply, &self, None);
             }
@@ -467,7 +495,7 @@ fn do_work(
             tr.cookie = cookie as uapi::binder_uintptr_t;
         };
         tr.code = self.code;
-        tr.flags = self.flags;
+        tr.flags = u32::from(self.flags);
         tr.data_size = self.data_size as uapi::binder_size_t;
         tr.data.ptr.buffer = self.data_address as uapi::binder_uintptr_t;
         tr.offsets_size = self.offsets_size as uapi::binder_size_t;
@@ -477,7 +505,7 @@ fn do_work(
         }
         tr.sender_euid = self.sender_euid.into_uid_in_current_ns();
         tr.sender_pid = 0;
-        if self.target_node.is_some() && self.flags & TF_ONE_WAY == 0 {
+        if self.target_node.is_some() && !self.flags.is_oneway() {
             // Not a reply and not one-way.
             tr.sender_pid = self.from.process.pid_in_current_ns();
         }
@@ -529,7 +557,7 @@ fn cancel(self: DArc<Self>) {
         drop(allocation);
 
         // If this is not a reply or oneway transaction, then send a dead reply.
-        if self.target_node.is_some() && self.flags & TF_ONE_WAY == 0 {
+        if self.target_node.is_some() && !self.flags.is_oneway() {
             let reply = Err(BR_DEAD_REPLY);
             self.from.deliver_reply(reply, &self, None);
         } else {
@@ -545,7 +573,7 @@ fn cancel(self: DArc<Self>) {
     }
 
     fn should_sync_wakeup(&self) -> bool {
-        self.flags & TF_ONE_WAY == 0
+        !self.flags.is_oneway()
     }
 
     fn debug_print(&self, m: &SeqFile, _prefix: &str, tprefix: &str) -> Result<()> {

-- 
2.55.0.229.g6434b31f56-goog

