From: Jahnavi MN <jahnavimn@google.com>
Date: Fri, 10 Jul 2026 14:32:52 +0000
Subject: [PATCH v2 1/7] rust_binder: Add dynamic debug logging mask
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-rust_binder_debug_mask-v2-1-2846410e3ae6@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783693978; l=7235;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=V8G5VlmbPuzQIlaKadckk+0i1PL6tZeZ1UAId3VRBo0=;
 b=AVM411SDzFuJOCXMOOjfzFOUySkRfpt6XPlBzhhTHtjvwW/cBAVMQtfV3dpB8wPLtgY65zy+0
 6teLnELS+eZD3U7dpyBxA9AM7bgah49rglB6VuWpApwXomw19dcarWD
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement a dynamic debug logging mask (`debug_mask`) for the
`rust_binder` module to allow dynamic runtime configuration of log
levels. This enables parity with the legacy C driver's debug mask.

Since the Rust `module!` macro in the current kernel build does not yet
support declaring module parameters directly in Rust, we define the
`debug_mask` variable in a C companion file to expose it to the kernel
runtime and import it using FFI with volatile reads.

To verify the setup, instrument process lifecycle events (open, flush,
and release) in `process.rs` under the new `BINDER_DEBUG_OPEN_CLOSE`
logging mask. These entry-point events are chosen for initial validation
because they represent the start of the Binder lifecycle and occur
at low frequency, allowing simple runtime verification of the dynamic
toggle without log noise.

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/debug.rs            | 80 ++++++++++++++++++++++++++++++
 drivers/android/binder/process.rs          |  7 ++-
 drivers/android/binder/rust_binder_main.rs |  2 +
 drivers/android/binder/rust_binderfs.c     |  3 ++
 rust/kernel/task.rs                        |  7 +++
 5 files changed, 98 insertions(+), 1 deletion(-)

diff --git a/drivers/android/binder/debug.rs b/drivers/android/binder/debug.rs
new file mode 100644
index 000000000000..da48bce3df54
--- /dev/null
+++ b/drivers/android/binder/debug.rs
@@ -0,0 +1,80 @@
+// SPDX-License-Identifier: GPL-2.0
+// Copyright (C) 2026 Google LLC.
+
+//! Binder debugging helpers.
+
+#![allow(dead_code)]
+
+kernel::impl_flags!(
+    /// Represents multiple debug mask flags.
+    #[derive(Debug, Clone, Default, Copy, PartialEq, Eq)]
+    pub struct DebugMasks(u32);
+
+    /// Represents a single debug mask category.
+    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
+    pub enum DebugMask {
+        UserError = 1 << 0,
+        FailedTransaction = 1 << 1,
+        DeadTransaction = 1 << 2,
+        OpenClose = 1 << 3,
+        DeadBinder = 1 << 4,
+        DeathNotification = 1 << 5,
+        ReadWrite = 1 << 6,
+        UserRefs = 1 << 7,
+        Threads = 1 << 8,
+        Transaction = 1 << 9,
+        TransactionComplete = 1 << 10,
+        FreeBuffer = 1 << 11,
+        InternalRefs = 1 << 12,
+        PriorityCap = 1 << 13,
+        Spinlocks = 1 << 14,
+    }
+);
+
+extern "C" {
+    // Declared as static mut because the value is mutated dynamically by C sysfs.
+    static mut rust_binder_debug_mask: u32;
+}
+
+/// Checks if the given debug logging category is enabled in the mask.
+pub(crate) fn debug_mask_enabled(mask: DebugMask) -> bool {
+    // SAFETY: `rust_binder_debug_mask` is defined in C and can be mutated at any time.
+    // We read it via volatile to ensure we fetch the current value from memory.
+    let current_mask = unsafe { core::ptr::read_volatile(&raw const rust_binder_debug_mask) };
+    (current_mask & (mask as u32)) != 0
+}
+
+/// Prints a debug log if the specified mask category is enabled.
+#[macro_export]
+macro_rules! binder_debug {
+    // 1. Internal helper rule to do the raw print.
+    (raw, $($arg:tt)*) => {
+        kernel::pr_info!($($arg)*);
+    };
+
+    // 2. Rule to explicitly specify a PID (used in kworkers).
+    (pid=$pid:expr, $mask:ident, $($arg:tt)*) => {
+        if $crate::debug::debug_mask_enabled($crate::debug::DebugMask::$mask) {
+            $crate::binder_debug!(
+                raw,
+                "{}: {}\n",
+                $pid,
+                kernel::prelude::fmt!($($arg)*)
+            );
+        }
+    };
+
+    // 3. Default rule (automatically prepends "PID:TID" of the current calling thread).
+    ($mask:ident, $($arg:tt)*) => {
+        if $crate::debug::debug_mask_enabled($crate::debug::DebugMask::$mask) {
+            let thread = kernel::current!();
+            $crate::binder_debug!(
+                raw,
+                "{}:{} {}\n",
+                thread.tgid(),
+                thread.pid(),
+                kernel::prelude::fmt!($($arg)*)
+            );
+        }
+    };
+}
diff --git a/drivers/android/binder/process.rs b/drivers/android/binder/process.rs
index f855d8d9818c..836a0db92354 100644
--- a/drivers/android/binder/process.rs
+++ b/drivers/android/binder/process.rs
@@ -1349,6 +1349,7 @@ pub(crate) fn lock_with_nodes(&self) -> WithNodes<'_> {
     }
 
     fn deferred_flush(&self) {
+        binder_debug!(pid=self.task.pid(), OpenClose, "flushing process");
         let inner = self.inner.lock();
         for thread in inner.threads.values() {
             thread.exit_looper();
@@ -1356,6 +1357,8 @@ fn deferred_flush(&self) {
     }
 
     fn deferred_release(self: Arc<Self>) {
+        binder_debug!(pid=self.task.pid(), OpenClose, "releasing process");
+
         let is_manager = {
             let mut inner = self.inner.lock();
             inner.is_dead = true;
@@ -1658,7 +1661,9 @@ fn ioctl_write_read(
 /// The file operations supported by `Process`.
 impl Process {
     pub(crate) fn open(ctx: ArcBorrow<'_, Context>, file: &File) -> Result<Arc<Process>> {
-        Self::new(ctx.into(), ARef::from(file.cred()))
+        let proc = Self::new(ctx.into(), ARef::from(file.cred()))?;
+        binder_debug!(OpenClose, "opened process");
+        Ok(proc)
     }
 
     pub(crate) fn release(this: Arc<Process>, _file: &File) {
diff --git a/drivers/android/binder/rust_binder_main.rs b/drivers/android/binder/rust_binder_main.rs
index df47aba05133..995e6131bb77 100644
--- a/drivers/android/binder/rust_binder_main.rs
+++ b/drivers/android/binder/rust_binder_main.rs
@@ -31,6 +31,8 @@
 mod context;
 mod deferred_close;
 mod defs;
+#[macro_use]
+mod debug;
 mod error;
 mod netlink;
 mod node;
diff --git a/drivers/android/binder/rust_binderfs.c b/drivers/android/binder/rust_binderfs.c
index ade1c4d92499..fa8b38465550 100644
--- a/drivers/android/binder/rust_binderfs.c
+++ b/drivers/android/binder/rust_binderfs.c
@@ -51,6 +51,9 @@ DEFINE_SHOW_ATTRIBUTE(rust_binder_proc);
 char *rust_binder_devices_param = CONFIG_ANDROID_BINDER_DEVICES;
 module_param_named(rust_devices, rust_binder_devices_param, charp, 0444);
 
+u32 rust_binder_debug_mask = 7;
+module_param_named(debug_mask, rust_binder_debug_mask, uint, 0644);
+
 static dev_t binderfs_dev;
 static DEFINE_MUTEX(binderfs_minors_mutex);
 static DEFINE_IDA(binderfs_minors);
diff --git a/rust/kernel/task.rs b/rust/kernel/task.rs
index 38273f4eedb5..1b290c61714d 100644
--- a/rust/kernel/task.rs
+++ b/rust/kernel/task.rs
@@ -210,6 +210,13 @@ pub fn pid(&self) -> Pid {
         unsafe { *ptr::addr_of!((*self.as_ptr()).pid) }
     }
 
+    /// Returns the TGID (Thread Group ID / Process ID) of the given task.
+    pub fn tgid(&self) -> Pid {
+        // SAFETY: The tgid of a task never changes after initialization, so reading this field is
+        // not a data race.
+        unsafe { *ptr::addr_of!((*self.as_ptr()).tgid) }
+    }
+
     /// Returns the UID of the given task.
     #[inline]
     pub fn uid(&self) -> Kuid {

-- 
2.55.0.795.g602f6c329a-goog

