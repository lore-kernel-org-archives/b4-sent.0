From: Jahnavi MN <jahnavimn@google.com>
Date: Thu, 16 Jul 2026 13:02:36 +0000
Subject: [PATCH 3/3] rust_binder: Update transaction flags to use
 kernel::impl_flags!
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-b4-rust_binder_impl_flags-v1-3-b4201d3f15b3@google.com>
References: <20260716-b4-rust_binder_impl_flags-v1-0-b4201d3f15b3@google.com>
In-Reply-To: <20260716-b4-rust_binder_impl_flags-v1-0-b4201d3f15b3@google.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Carlos Llamas <cmllamas@google.com>, Alice Ryhl <aliceryhl@google.com>, 
 Benno Lossin <lossin@kernel.org>, Gary Guo <gary@garyguo.net>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Jahnavi MN <jahnavimn@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784206955; l=8816;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=GcxzYl/7E1EvBuuuo65EndTTI/b1qEm8RIoCciK/dwQ=;
 b=8q4Z4Kwau2V3LVZUyqnhDmGnyims9ifNRA+omX0dJUc8ZKHmMVglyDZkAwjXTYffoswfF0zsC
 jxlgIm6KT5JAZkqhtdcwK8oC1R4Kxu/qp7wqICTYHAA5RQhr/XP64yw
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Define `TransactionFlags(u32)` and `TransactionFlag` with 4 variants.
- Change flags field type to `TransactionFlags` in structs.
- Add `is_oneway` helper on `TransactionFlags` to simplify checks.
- Update `can_replace` logic to use type-safe combined flag checks.
- Convert `flags` to `u32` for FFI boundaries and logging.

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/thread.rs      |  6 ++--
 drivers/android/binder/transaction.rs | 56 ++++++++++++++++++++++++++---------
 2 files changed, 45 insertions(+), 17 deletions(-)

diff --git a/drivers/android/binder/thread.rs b/drivers/android/binder/thread.rs
index e5bf1eaeeb17..1d10c6a95ff5 100644
--- a/drivers/android/binder/thread.rs
+++ b/drivers/android/binder/thread.rs
@@ -31,7 +31,7 @@
     process::{GetWorkOrRegister, Process},
     ptr_align,
     stats::GLOBAL_STATS,
-    transaction::{Transaction, TransactionInfo},
+    transaction::{Transaction, TransactionFlag, TransactionFlags, TransactionInfo},
     BinderReturnWriter, DArc, DLArc, DTRWrap, DeliverCode, DeliverToRead,
 };
 
@@ -1244,7 +1244,7 @@ fn read_transaction_info(
         info.from_pid = self.process.task.pid();
         info.from_tid = self.id;
         info.code = td.transaction_data.code;
-        info.flags = td.transaction_data.flags;
+        info.flags = TransactionFlags::from_bits(td.transaction_data.flags);
         info.data_ptr = UserPtr::from_addr(trd_data_ptr.buffer as usize);
         info.data_size = td.transaction_data.data_size as usize;
         info.offsets_ptr = UserPtr::from_addr(trd_data_ptr.offsets as usize);
@@ -1350,7 +1350,7 @@ fn reply_inner(self: &Arc<Self>, info: &mut TransactionInfo) -> BinderResult {
         let out = (|| -> BinderResult<_> {
             let completion = DTRWrap::arc_try_new(DeliverCode::new(BR_TRANSACTION_COMPLETE))?;
             let process = orig.from.process.clone();
-            let allow_fds = orig.flags & TF_ACCEPT_FDS != 0;
+            let allow_fds = orig.flags.contains(TransactionFlag::AcceptFds);
             let reply = Transaction::new_reply(self, process, info, allow_fds)?;
             self.inner.lock().push_work(completion);
             orig.from.deliver_reply(Ok(reply), &orig, None);
diff --git a/drivers/android/binder/transaction.rs b/drivers/android/binder/transaction.rs
index afef5b46eac2..4e2ef99e512f 100644
--- a/drivers/android/binder/transaction.rs
+++ b/drivers/android/binder/transaction.rs
@@ -25,6 +25,33 @@
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
@@ -32,7 +59,7 @@ pub(crate) struct TransactionInfo {
     pub(crate) to_pid: Pid,
     pub(crate) to_tid: Pid,
     pub(crate) code: u32,
-    pub(crate) flags: u32,
+    pub(crate) flags: TransactionFlags,
     pub(crate) data_ptr: UserPtr,
     pub(crate) data_size: usize,
     pub(crate) offsets_ptr: UserPtr,
@@ -49,7 +76,7 @@ pub(crate) struct TransactionInfo {
 impl TransactionInfo {
     #[inline]
     pub(crate) fn is_oneway(&self) -> bool {
-        self.flags & TF_ONE_WAY != 0
+        self.flags.is_oneway()
     }
 }
 
@@ -75,7 +102,7 @@ pub(crate) struct Transaction {
     allocation: SpinLock<Option<Allocation>>,
     is_outstanding: Atomic<bool>,
     code: u32,
-    pub(crate) flags: u32,
+    pub(crate) flags: TransactionFlags,
     data_size: usize,
     offsets_size: usize,
     data_address: usize,
@@ -121,7 +148,7 @@ pub(crate) fn new(
             }
             alloc.set_info_oneway_node(node_ref.node.clone());
         }
-        if info.flags & TF_CLEAR_BUF != 0 {
+        if info.flags.contains(TransactionFlag::ClearBuf) {
             alloc.set_info_clear_on_drop();
         }
         let target_node = node_ref.node.clone();
@@ -161,7 +188,7 @@ pub(crate) fn new_reply(
                     return Err(err);
                 }
             };
-        if info.flags & TF_CLEAR_BUF != 0 {
+        if info.flags.contains(TransactionFlag::ClearBuf) {
             alloc.set_info_clear_on_drop();
         }
         Ok(DTRWrap::arc_pin_init(pin_init!(Transaction {
@@ -194,7 +221,7 @@ pub(crate) fn debug_print_inner(&self, m: &SeqFile, prefix: &str) {
             self.from.id,
             self.to.task.pid(),
             self.code,
-            self.flags,
+            u32::from(self.flags),
             self.start_time.elapsed().as_millis(),
         );
         if let Some(target_node) = &self.target_node {
@@ -273,7 +300,7 @@ pub(crate) fn submit(self: DLArc<Self>, info: &mut TransactionInfo) -> BinderRes
         let _t_outdated;
         let _oneway_node;
 
-        let oneway = self.flags & TF_ONE_WAY != 0;
+        let oneway = self.flags.is_oneway();
         let process = self.to.clone();
         let mut process_inner = process.inner.lock();
 
@@ -284,7 +311,7 @@ pub(crate) fn submit(self: DLArc<Self>, info: &mut TransactionInfo) -> BinderRes
                 crate::trace::trace_transaction(false, &self, None);
                 if process_inner.is_frozen.is_frozen() {
                     process_inner.async_recv = true;
-                    if self.flags & TF_UPDATE_TXN != 0 {
+                    if self.flags.contains(TransactionFlag::UpdateTxn) {
                         if let Some(t_outdated) =
                             target_node.take_outdated_transaction(&self, &mut process_inner)
                         {
@@ -355,7 +382,8 @@ pub(crate) fn can_replace(&self, old: &Transaction) -> bool {
             return false;
         }
 
-        if self.flags & old.flags & (TF_ONE_WAY | TF_UPDATE_TXN) != (TF_ONE_WAY | TF_UPDATE_TXN) {
+        let required = TransactionFlag::OneWay | TransactionFlag::UpdateTxn;
+        if !(self.flags.contains_all(required) && old.flags.contains_all(required)) {
             return false;
         }
 
@@ -392,7 +420,7 @@ fn do_work(
         writer: &mut BinderReturnWriter<'_>,
     ) -> Result<bool> {
         let send_failed_reply = ScopeGuard::new(|| {
-            if self.target_node.is_some() && self.flags & TF_ONE_WAY == 0 {
+            if self.target_node.is_some() && !self.flags.is_oneway() {
                 let reply = Err(BR_FAILED_REPLY);
                 self.from.deliver_reply(reply, &self, None);
             }
@@ -415,7 +443,7 @@ fn do_work(
             tr.cookie = cookie as uapi::binder_uintptr_t;
         };
         tr.code = self.code;
-        tr.flags = self.flags;
+        tr.flags = u32::from(self.flags);
         tr.data_size = self.data_size as uapi::binder_size_t;
         tr.data.ptr.buffer = self.data_address as uapi::binder_uintptr_t;
         tr.offsets_size = self.offsets_size as uapi::binder_size_t;
@@ -425,7 +453,7 @@ fn do_work(
         }
         tr.sender_euid = self.sender_euid.into_uid_in_current_ns();
         tr.sender_pid = 0;
-        if self.target_node.is_some() && self.flags & TF_ONE_WAY == 0 {
+        if self.target_node.is_some() && !self.flags.is_oneway() {
             // Not a reply and not one-way.
             tr.sender_pid = self.from.process.pid_in_current_ns();
         }
@@ -477,7 +505,7 @@ fn cancel(self: DArc<Self>) {
         drop(allocation);
 
         // If this is not a reply or oneway transaction, then send a dead reply.
-        if self.target_node.is_some() && self.flags & TF_ONE_WAY == 0 {
+        if self.target_node.is_some() && !self.flags.is_oneway() {
             let reply = Err(BR_DEAD_REPLY);
             self.from.deliver_reply(reply, &self, None);
         }
@@ -486,7 +514,7 @@ fn cancel(self: DArc<Self>) {
     }
 
     fn should_sync_wakeup(&self) -> bool {
-        self.flags & TF_ONE_WAY == 0
+        !self.flags.is_oneway()
     }
 
     fn debug_print(&self, m: &SeqFile, _prefix: &str, tprefix: &str) -> Result<()> {

-- 
2.55.0.229.g6434b31f56-goog

