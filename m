From: Jens Korinth <jens.korinth@tuta.io>
Date: Tue, 26 Nov 2024 17:40:57 +0100
Subject: [PATCH v4 1/3] rust: Add `OnceLite` for executing code once
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-pr_once_macros-v4-1-410b8ca9643e@tuta.io>
References: <20241126-pr_once_macros-v4-0-410b8ca9643e@tuta.io>
In-Reply-To: <20241126-pr_once_macros-v4-0-410b8ca9643e@tuta.io>
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>
Cc: rust-for-linux@vger.kernel.org, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Dirk Behme <dirk.behme@gmail.com>, linux-kernel@vger.kernel.org, 
 Jens Korinth <jens.korinth@tuta.io>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732639280; l=5613;
 i=jens.korinth@tuta.io; s=20241107; h=from:subject:message-id;
 bh=ZZbfLxiGdfnVZSfH4gl4DNnp7sVkUf0OZWaBN8Z0QC4=;
 b=lrZGPHP1FlTYTI6L86HybkHlhEeW3b8uC8XvcRCWtY3pkUVE7rODcD4EnaEUrTOF+nH+9F0sp
 Ni0meAX6OCoBCIlDwKjsQjQ77kdaUKdQUWSLNyfUFnUbs5nZOZGsB38
X-Developer-Key: i=jens.korinth@tuta.io; a=ed25519;
 pk=bG0q4Zyj3o4d/r326zKL7ym+/tXzyykcjh+U0M13iyc=
X-Endpoint-Received: by B4 Relay for jens.korinth@tuta.io/20241107 with auth_id=270
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Similar to `Once` in Rust's standard library, but with the same
non-blocking behavior as the kernel's `DO_ONCE_LITE` macro. Abstraction
allows easy replacement of the underlying sync mechanisms, see

https://lore.kernel.org/rust-for-linux/20241109-pr_once_macros-v3-0-6beb24e0cac8@tuta.io/.

Suggested-by: Boqun Feng <boqun.feng@gmail.com>
Signed-off-by: Jens Korinth <jens.korinth@tuta.io>
---
 rust/kernel/lib.rs       |   1 +
 rust/kernel/once_lite.rs | 127 +++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 128 insertions(+)

diff --git a/rust/kernel/lib.rs b/rust/kernel/lib.rs
index bf8d7f841f9425d19a24f3910929839cfe705c7f..2b0a80435d24f5e168679ec2e25bd68cd970dcdd 100644
--- a/rust/kernel/lib.rs
+++ b/rust/kernel/lib.rs
@@ -44,6 +44,7 @@
 pub mod list;
 #[cfg(CONFIG_NET)]
 pub mod net;
+pub mod once_lite;
 pub mod page;
 pub mod prelude;
 pub mod print;
diff --git a/rust/kernel/once_lite.rs b/rust/kernel/once_lite.rs
new file mode 100644
index 0000000000000000000000000000000000000000..723c3244fc856fe974ddd33de5415e7ced37f315
--- /dev/null
+++ b/rust/kernel/once_lite.rs
@@ -0,0 +1,127 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! A one-time only global execution primitive.
+//!
+//! This primitive is meant to be used to execute code only once. It is
+//! similar in design to Rust's
+//! [`std::sync:Once`](https://doc.rust-lang.org/std/sync/struct.Once.html),
+//! but borrowing the non-blocking mechanism used in the kernel's
+//! [`DO_ONCE_LITE`] macro.
+//!
+//! An example use case would be to print a message only the first time.
+//!
+//! [`DO_ONCE_LITE`]: srctree/include/linux/once_lite.h
+//!
+//! C header: [`include/linux/once_lite.h`](srctree/include/linux/once_lite.h)
+//!
+//! Reference: <https://doc.rust-lang.org/std/sync/struct.Once.html>
+
+use core::sync::atomic::{AtomicBool, Ordering::Relaxed};
+
+/// A low-level synchronization primitive for one-time global execution.
+///
+/// Based on the
+/// [`std::sync:Once`](https://doc.rust-lang.org/std/sync/struct.Once.html)
+/// interface, but internally equivalent the kernel's [`DO_ONCE_LITE`]
+/// macro. The Rust macro `do_once_lite` replacing it uses `OnceLite`
+/// internally.
+///
+/// [`DO_ONCE_LITE`]: srctree/include/linux/once_lite.h
+///
+/// # Examples
+///
+/// ```rust
+/// static START: kernel::once_lite::OnceLite =
+///     kernel::once_lite::OnceLite::new();
+///
+/// let mut x: i32 = 0;
+///
+/// START.call_once(|| {
+///   // run initialization here
+///   x = 42;
+/// });
+/// while !START.is_completed() { /* busy wait */ }
+/// assert_eq!(x, 42);
+/// ```
+///
+pub struct OnceLite(AtomicBool, AtomicBool);
+
+impl OnceLite {
+    /// Creates a new `OnceLite` value.
+    #[inline(always)]
+    pub const fn new() -> Self {
+        Self(AtomicBool::new(false), AtomicBool::new(false))
+    }
+
+    /// Performs an initialization routine once and only once. The given
+    /// closure will be executed if this is the first time `call_once` has
+    /// been called, and otherwise the routine will not be invoked.
+    ///
+    /// This method will _not_ block the calling thread if another
+    /// initialization is currently running. It is _not_ guaranteed that the
+    /// initialization routine will have completed by the time the calling
+    /// thread continues execution.
+    ///
+    /// Note that this is different from the guarantees made by
+    /// [`std::sync::Once`], but identical to the way the implementation of
+    /// the kernel's [`DO_ONCE_LITE_IF`] macro is behaving at the time of
+    /// writing.
+    ///
+    /// [`std::sync::Once`]: https://doc.rust-lang.org/std/sync/struct.Once.html
+    /// [`DO_ONCE_LITE_IF`]: srctree/include/once_lite.h
+    #[inline(always)]
+    pub fn call_once<F: FnOnce()>(&self, f: F) {
+        if !self.0.load(Relaxed) && !self.0.swap(true, Relaxed) {
+            f()
+        };
+        self.1.store(true, Relaxed);
+    }
+
+    /// Returns `true` if some `call_once` call has completed successfully.
+    /// Specifically, `is_completed` will return `false` in the following
+    /// situations:
+    ///
+    /// 1. `call_once()` was not called at all,
+    /// 2. `call_once()` was called, but has not yet completed.
+    ///
+    /// # Examples
+    ///
+    /// ```rust
+    /// static INIT: kernel::once_lite::OnceLite =
+    ///     kernel::once_lite::OnceLite::new();
+    ///
+    /// assert_eq!(INIT.is_completed(), false);
+    /// INIT.call_once(|| {
+    ///     assert_eq!(INIT.is_completed(), false);
+    /// });
+    /// assert_eq!(INIT.is_completed(), true);
+    /// ```
+    #[inline(always)]
+    pub fn is_completed(&self) -> bool {
+        self.1.load(Relaxed)
+    }
+}
+
+/// Executes code only once.
+///
+/// Equivalent to the kernel's [`DO_ONCE_LITE`] macro: Expression is
+/// evaluated at most once by the first thread, other threads will not be
+/// blocked while executing in first thread, nor are there any guarantees
+/// regarding the visibility of side-effects of the called expression.
+///
+/// [`DO_ONCE_LITE`]: srctree/include/linux/once_lite.h
+///
+/// # Examples
+///
+/// ```
+/// let mut x: i32 = 0;
+/// kernel::do_once_lite!((||{x = 42;})());
+/// ```
+#[macro_export]
+macro_rules! do_once_lite {
+    ($e: expr) => {{
+        #[link_section = ".data.once"]
+        static ONCE: $crate::once_lite::OnceLite = $crate::once_lite::OnceLite::new();
+        ONCE.call_once(|| $e);
+    }};
+}

-- 
2.47.0

