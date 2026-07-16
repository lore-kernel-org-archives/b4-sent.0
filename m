From: Jahnavi MN <jahnavimn@google.com>
Date: Thu, 16 Jul 2026 13:02:34 +0000
Subject: [PATCH 1/3] rust_binder: Update defer_work bitmaps to use
 kernel::impl_flags!
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-b4-rust_binder_impl_flags-v1-1-b4201d3f15b3@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784206955; l=3623;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=/uxVIdRsjjzzayVpGS2ftrtM8UPE7MkaSdizzzP0eRo=;
 b=zbpP0nXpy6VPAfq11Yz/3KU5NwqiCk3ADs9Ti8zOM85dpUUFLvs5IuzYThnIbkXkcwoG5Q6Br
 3Er+j6wOXlfB8L/tJcXLwmWlluf9eKBJDvO4YIj8lsOfnjIjCgNZADZ
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Define `DeferWorks(u8)` and `DeferWork` enum using `bit_u8` offsets.
- Change `ProcessInner.defer_work` type from `u8` to `DeferWorks`.
- Update `Process::release()` and `Process::flush()` to check for empty
  states using `DeferWorks::empty()`.
- Update the workqueue runner to inspect flags using `.contains()`.

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/process.rs | 34 ++++++++++++++++++++++------------
 1 file changed, 22 insertions(+), 12 deletions(-)

diff --git a/drivers/android/binder/process.rs b/drivers/android/binder/process.rs
index 0555c4bd503e..84747d998636 100644
--- a/drivers/android/binder/process.rs
+++ b/drivers/android/binder/process.rs
@@ -16,6 +16,7 @@
 
 use kernel::{
     bindings,
+    bits::bit_u8,
     cred::Credential,
     error::Error,
     fs::file::{self, File},
@@ -70,9 +71,18 @@ fn new(address: usize, size: usize) -> Self {
     }
 }
 
-// bitflags for defer_work.
-const PROC_DEFER_FLUSH: u8 = 1;
-const PROC_DEFER_RELEASE: u8 = 2;
+kernel::impl_flags!(
+    /// Represents multiple deferred work flags.
+    #[derive(Debug, Clone, Default, Copy, PartialEq, Eq)]
+    pub struct DeferWorks(u8);
+
+    /// Represents a single deferred work category.
+    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
+    pub enum DeferWork {
+        Flush = bit_u8(0),
+        Release = bit_u8(1),
+    }
+);
 
 #[derive(Copy, Clone)]
 pub(crate) enum IsFrozen {
@@ -121,7 +131,7 @@ pub(crate) struct ProcessInner {
     started_thread_count: u32,
 
     /// Bitmap of deferred work to do.
-    defer_work: u8,
+    defer_work: DeferWorks,
 
     /// Number of transactions to be transmitted before processes in freeze_wait
     /// are woken up.
@@ -151,7 +161,7 @@ fn new() -> Self {
             requested_thread_count: 0,
             max_threads: 0,
             started_thread_count: 0,
-            defer_work: 0,
+            defer_work: DeferWorks::default(),
             outstanding_txns: 0,
             is_frozen: IsFrozen::No,
             sync_recv: false,
@@ -489,13 +499,13 @@ fn run(me: Arc<Self>) {
         {
             let mut inner = me.inner.lock();
             defer = inner.defer_work;
-            inner.defer_work = 0;
+            inner.defer_work = DeferWorks::default();
         }
 
-        if defer & PROC_DEFER_FLUSH != 0 {
+        if defer.contains(DeferWork::Flush) {
             me.deferred_flush();
         }
-        if defer & PROC_DEFER_RELEASE != 0 {
+        if defer.contains(DeferWork::Release) {
             me.deferred_release();
         }
     }
@@ -1649,8 +1659,8 @@ pub(crate) fn release(this: Arc<Process>, _file: &File) {
         let should_schedule;
         {
             let mut inner = this.inner.lock();
-            should_schedule = inner.defer_work == 0;
-            inner.defer_work |= PROC_DEFER_RELEASE;
+            should_schedule = inner.defer_work == DeferWorks::empty();
+            inner.defer_work |= DeferWork::Release;
             binderfs_file = inner.binderfs_file.take();
         }
 
@@ -1667,8 +1677,8 @@ pub(crate) fn flush(this: ArcBorrow<'_, Process>) -> Result {
         let should_schedule;
         {
             let mut inner = this.inner.lock();
-            should_schedule = inner.defer_work == 0;
-            inner.defer_work |= PROC_DEFER_FLUSH;
+            should_schedule = inner.defer_work == DeferWorks::empty();
+            inner.defer_work |= DeferWork::Flush;
         }
 
         if should_schedule {

-- 
2.55.0.229.g6434b31f56-goog

