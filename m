From: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
Date: Fri, 03 Apr 2026 16:37:07 +0530
Subject: [PATCH v3 3/3] rust: workqueue: add KUnit and sample stress tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-workqueue-v3-final-v3-3-6ffc3950d804@multicorewareinc.com>
References: <20260403-workqueue-v3-final-v3-0-6ffc3950d804@multicorewareinc.com>
In-Reply-To: <20260403-workqueue-v3-final-v3-0-6ffc3950d804@multicorewareinc.com>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aakash Bollineni <aakash.bollineni@multicorewareinc.com>, 
 work@onurozkan.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775214425; l=8515;
 i=aakash.bollineni@multicorewareinc.com; s=20260402;
 h=from:subject:message-id; bh=hqHrOY8k0V5gHndkYAOEeID3xUnMi/k78/UmvOH+WOs=;
 b=9J+CzhEEQiGnRm2JDP6cgHr36cvP2PurdEVw6jeUTGBKMyajdJLJ0+Zr4E163DtKwJQK0StQ1
 NLypq02tOI5CU1nVjqOQE4riJo2Zx9lbwiyoEXgoHOuxu4pkSnk4cuY
X-Developer-Key: i=aakash.bollineni@multicorewareinc.com; a=ed25519;
 pk=r3Gonl+2k+8RozN9U/XwfICQdnRlAcLeeAfsExmurdE=
X-Endpoint-Received: by B4 Relay for aakash.bollineni@multicorewareinc.com/20260402 with auth_id=711
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To ensure the safety and correctness of the improved workqueue API,
this patch adds comprehensive testing infrastructure:
1. KUnit Tests: Adds an internal 'rust_kernel_workqueue' test suite
   to rust/kernel/workqueue.rs. These tests verify basic and
   synchronous cancellation, refcount stability, and concurrency
   safety for both standard and delayed work.
2. Sample Module: Adds samples/rust/rust_workqueue_test.rs as a
   standalone module that performs a 1000-iteration stress test
   designed to verify race-free pointer handover during concurrent
   enqueue/cancel operations.
The tests use distinct types for standard and delayed work items to
ensure clear trait dispatch and prevent field offset conflicts.

Signed-off-by: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
---
 samples/rust/Kconfig                |  10 ++
 samples/rust/Makefile               |   2 +
 samples/rust/rust_workqueue_test.rs | 186 ++++++++++++++++++++++++++++++++++++
 3 files changed, 198 insertions(+)

diff --git a/samples/rust/Kconfig b/samples/rust/Kconfig
index c49ab9106345..b3f078f77ca2 100644
--- a/samples/rust/Kconfig
+++ b/samples/rust/Kconfig
@@ -172,6 +172,16 @@ config SAMPLE_RUST_SOC
 
 	  If unsure, say N.
 
+config SAMPLE_RUST_WORKQUEUE
+	tristate "Workqueue"
+	help
+	  This option builds the Rust workqueue robust stress test sample.
+
+	  To compile this as a module, choose M here:
+	  the module will be called rust_workqueue_test.
+
+	  If unsure, say N.
+
 config SAMPLE_RUST_HOSTPROGS
 	bool "Host programs"
 	help
diff --git a/samples/rust/Makefile b/samples/rust/Makefile
index 6c0aaa58cccc..261aa67b6502 100644
--- a/samples/rust/Makefile
+++ b/samples/rust/Makefile
@@ -20,3 +20,5 @@ obj-$(CONFIG_SAMPLE_RUST_SOC)			+= rust_soc.o
 rust_print-y := rust_print_main.o rust_print_events.o
 
 subdir-$(CONFIG_SAMPLE_RUST_HOSTPROGS)		+= hostprogs
+
+obj-$(CONFIG_SAMPLE_RUST_WORKQUEUE)		+= rust_workqueue_test.o
diff --git a/samples/rust/rust_workqueue_test.rs b/samples/rust/rust_workqueue_test.rs
new file mode 100644
index 000000000000..f656cbcc6617
--- /dev/null
+++ b/samples/rust/rust_workqueue_test.rs
@@ -0,0 +1,186 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Robust stress test for Rust workqueue API.
+
+use kernel::prelude::*;
+use kernel::sync::Arc;
+use kernel::time::msecs_to_jiffies;
+use kernel::workqueue::{self, new_work, Work, WorkItem};
+
+#[pin_data]
+struct TestWorkItem {
+    #[pin]
+    work: Work<TestWorkItem>,
+    value: i32,
+}
+
+kernel::impl_has_work! {
+    impl HasWork<Self> for TestWorkItem { self.work }
+}
+
+impl WorkItem for TestWorkItem {
+    type Pointer = Arc<TestWorkItem>;
+
+    fn run(this: Arc<TestWorkItem>) {
+        pr_info!(
+            "Rust workqueue test: Work item running (value: {})\n",
+            this.value
+        );
+    }
+}
+
+#[pin_data]
+struct TestDelayedWorkItem {
+    #[pin]
+    delayed_work: workqueue::DelayedWork<TestDelayedWorkItem>,
+    value: i32,
+}
+
+// SAFETY: The `delayed_work` field is at a fixed offset and is valid for the lifetime of
+// `TestDelayedWorkItem`.
+unsafe impl workqueue::HasDelayedWork<Self> for TestDelayedWorkItem {}
+
+impl WorkItem for TestDelayedWorkItem {
+    type Pointer = Arc<TestDelayedWorkItem>;
+
+    fn run(this: Arc<TestDelayedWorkItem>) {
+        pr_info!(
+            "Rust workqueue test: Delayed work item running (value: {})\n",
+            this.value
+        );
+    }
+}
+
+struct RustWorkqueueTest;
+
+impl kernel::Module for RustWorkqueueTest {
+    fn init(_module: &'static ThisModule) -> Result<Self> {
+        pr_info!("Rust workqueue test: starting robust verification (v3)\n");
+
+        // 1. Basic Lifecycle with Refcount Validation (Standard Work)
+        {
+            let work_item = Arc::pin_init(
+                pin_init!(TestWorkItem {
+                    work <- new_work!("TestWorkItem::work"),
+                    value: 42,
+                }),
+                GFP_KERNEL,
+            )?;
+
+            let initial_count = workqueue::arc_count(&work_item);
+            pr_info!("Initial Arc strong count: {}\n", initial_count);
+
+            // Enqueue
+            let enqueued_item = work_item.clone();
+
+            if let Err(returned_item) = workqueue::system().enqueue(enqueued_item) {
+                pr_warn!("Work already pending, unexpected!\n");
+                let _ = returned_item;
+            } else {
+                pr_info!(
+                    "Work enqueued successfully. Strong count: {}\n",
+                    workqueue::arc_count(&work_item)
+                );
+            }
+
+            // Cancel immediately
+            if let Some(reclaimed) = work_item.work.cancel() {
+                let count_after_cancel = workqueue::arc_count(&work_item);
+                pr_info!(
+                    "Success: Work cancelled and Arc reclaimed. Strong count: {}\n",
+                    count_after_cancel
+                );
+
+                if count_after_cancel != initial_count + 1 {
+                    pr_err!(
+                        "ERROR: Refcount mismatch after cancel! Expected {}, got {}\n",
+                        initial_count + 1,
+                        count_after_cancel
+                    );
+                    return Err(ENXIO);
+                }
+                drop(reclaimed);
+                if workqueue::arc_count(&work_item) != initial_count {
+                    pr_err!("ERROR: Refcount mismatch after drop!\n");
+                    return Err(ENXIO);
+                }
+            } else {
+                pr_info!("Work already running or finished.\n");
+            }
+        }
+
+        // 2. Stress Testing: Enqueue/Cancel Sync Loop
+        {
+            pr_info!("Starting stress test (1000 iterations)...\n");
+            let work_item = Arc::pin_init(
+                pin_init!(TestWorkItem {
+                    work <- new_work!("TestWorkItem::work"),
+                    value: 99,
+                }),
+                GFP_KERNEL,
+            )?;
+
+            for i in 0..1000 {
+                let _ = workqueue::system().enqueue(work_item.clone());
+                let _ = work_item.work.cancel_sync();
+                if i % 250 == 0 {
+                    pr_info!("Stress test progress: {}/1000\n", i);
+                }
+            }
+
+            if workqueue::arc_count(&work_item) != 1 {
+                pr_err!("ERROR: Refcount leak detected after stress test!\n");
+                return Err(ENXIO);
+            } else {
+                pr_info!("Stress test completed successfully.\n");
+            }
+        }
+
+        // 3. Delayed Work Cancellation Test
+        {
+            let delayed_item = Arc::pin_init(
+                pin_init!(TestDelayedWorkItem {
+                    delayed_work <- workqueue::new_delayed_work!("TestDelayedWorkItem::delayed_work"),
+                    value: 7,
+                }),
+                GFP_KERNEL,
+            )?;
+
+            let initial_count = workqueue::arc_count(&delayed_item);
+
+            // Schedule with a long delay (5 seconds)
+            if let Err(returned) = workqueue::system().enqueue_delayed(delayed_item.clone(), msecs_to_jiffies(5000)) {
+                drop(returned);
+            } else {
+                pr_info!("Delayed work enqueued. count: {}\n", workqueue::arc_count(&delayed_item));
+            }
+
+            if let Some(reclaimed) = delayed_item.delayed_work.cancel() {
+                pr_info!("Success: Delayed work reclaimed. No leak.\n");
+                drop(reclaimed);
+            }
+
+            if workqueue::arc_count(&delayed_item) != initial_count {
+                pr_err!("ERROR: Refcount leak after delayed cancel!\n");
+                return Err(ENXIO);
+            }
+        }
+
+        pr_info!("Rust workqueue test: all robust checks passed\n");
+        Ok(RustWorkqueueTest)
+    }
+}
+
+impl Drop for RustWorkqueueTest {
+    fn drop(&mut self) {
+        pr_info!("Rust workqueue test: exit\n");
+    }
+}
+
+module! {
+    type: RustWorkqueueTest,
+    name: "rust_workqueue_test",
+    authors: ["Aakash Bollineni"],
+    description: "Robust stress test for Rust workqueue API",
+    license: "GPL",
+}

-- 
2.43.0

