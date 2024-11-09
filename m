From: Jens Korinth <jens.korinth@tuta.io>
Date: Sat, 09 Nov 2024 21:30:08 +0100
Subject: [PATCH v3 2/3] rust: print: Add pr_*_once macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241109-pr_once_macros-v3-2-6beb24e0cac8@tuta.io>
References: <20241109-pr_once_macros-v3-0-6beb24e0cac8@tuta.io>
In-Reply-To: <20241109-pr_once_macros-v3-0-6beb24e0cac8@tuta.io>
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>
Cc: rust-for-linux@vger.kernel.org, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Dirk Behme <dirk.behme@gmail.com>, Jens Korinth <jens.korinth@tuta.io>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731184236; l=3692;
 i=jens.korinth@tuta.io; s=20241107; h=from:subject:message-id;
 bh=OtTNBoLMR8tEZCYVorV6FLpQhsyJ/UjGZp+w8Qly40s=;
 b=JxqISbT5ZYSKgI9N2txVGBeRJabzM+p419f9C2IsCSVrYn+gviS4f39Rmsu/1WY4ewG1DhxUX
 djm7AVGqiH8DGmFS/B7zLvJpJag8c+nS+QTPUtOGCQFyghSY6mRWXGx
X-Developer-Key: i=jens.korinth@tuta.io; a=ed25519;
 pk=bG0q4Zyj3o4d/r326zKL7ym+/tXzyykcjh+U0M13iyc=
X-Endpoint-Received: by B4 Relay for jens.korinth@tuta.io/20241107 with auth_id=270
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: FUJITA Tomonori <fujita.tomonori@gmail.com>

Add Rust version of pr_[emerg|alert|crit|err|warn|notic|info]_once
functions, which print a message only once.

Signed-off-by: FUJITA Tomonori <fujita.tomonori@gmail.com>
Signed-off-by: Jens Korinth <jens.korinth@tuta.io>
---
 rust/kernel/print.rs | 126 +++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 126 insertions(+)

diff --git a/rust/kernel/print.rs b/rust/kernel/print.rs
index 9c7434b221984ad325138e5dc90ab4340cd0be2e..26542100be1ca843a0f916bd41260e20ec1f1b0e 100644
--- a/rust/kernel/print.rs
+++ b/rust/kernel/print.rs
@@ -448,3 +448,129 @@ macro_rules! do_once_lite (
         }
     );
 );
+
+/// Prints an emergency-level message (level 0) only once.
+///
+/// Equivalent to the kernel's [`pr_emerg_once`] macro.
+///
+/// [`pr_emerg_once`]: srctree/include/linux/printk.h
+///
+/// # Examples
+///
+/// ```
+/// kernel::pr_emerg_once!("hello {}\n", "there");
+/// ```
+#[macro_export]
+macro_rules! pr_emerg_once (
+    ($($arg:tt)*) => (
+        $crate::do_once_lite!($crate::pr_emerg!($($arg)*))
+    )
+);
+
+/// Prints an alert-level message (level 1) only once.
+///
+/// Equivalent to the kernel's [`pr_alert_once`] macro.
+///
+/// [`pr_alert_once`]: srctree/include/linux/printk.h
+///
+/// # Examples
+///
+/// ```
+/// kernel::pr_alert_once!("hello {}\n", "there");
+/// ```
+#[macro_export]
+macro_rules! pr_alert_once (
+    ($($arg:tt)*) => (
+        $crate::do_once_lite!($crate::pr_alert!($($arg)*))
+    )
+);
+
+/// Prints a critical-level message (level 2) only once.
+///
+/// Equivalent to the kernel's [`pr_crit_once`] macro.
+///
+/// [`pr_crit_once`]: srctree/include/linux/printk.h
+///
+/// # Examples
+///
+/// ```
+/// kernel::pr_crit_once!("hello {}\n", "there");
+/// ```
+#[macro_export]
+macro_rules! pr_crit_once (
+    ($($arg:tt)*) => (
+        $crate::do_once_lite!($crate::pr_crit!($($arg)*))
+    )
+);
+
+/// Prints an error-level message (level 3) only once.
+///
+/// Equivalent to the kernel's [`pr_err_once`] macro.
+///
+/// # Examples
+///
+/// [`pr_err_once`]: srctree/include/linux/printk.h
+///
+/// ```
+/// kernel::pr_err_once!("hello {}\n", "there");
+/// ```
+#[macro_export]
+macro_rules! pr_err_once (
+    ($($arg:tt)*) => (
+        $crate::do_once_lite!($crate::pr_err!($($arg)*))
+    )
+);
+
+/// Prints a warning-level message (level 4) only once.
+///
+/// Equivalent to the kernel's [`pr_warn_once`] macro.
+///
+/// [`pr_warn_once`]: srctree/include/linux/printk.h
+///
+/// # Examples
+///
+/// ```
+/// kernel::pr_warn_once!("hello {}\n", "there");
+/// ```
+#[macro_export]
+macro_rules! pr_warn_once (
+    ($($arg:tt)*) => (
+        $crate::do_once_lite!($crate::pr_warn!($($arg)*))
+    )
+);
+
+/// Prints a notice-level message (level 5) only once.
+///
+/// Equivalent to the kernel's [`pr_notice_once`] macro.
+///
+/// [`pr_notice_once`]: srctree/include/linux/printk.h
+///
+/// # Examples
+///
+/// ```
+/// kernel::pr_notice_once!("hello {}\n", "there");
+/// ```
+#[macro_export]
+macro_rules! pr_notice_once (
+    ($($arg:tt)*) => (
+        $crate::do_once_lite!($crate::pr_notice!($($arg)*))
+    )
+);
+
+/// Prints an info-level message (level 6) only once.
+///
+/// Equivalent to the kernel's [`pr_info_once`] macro.
+///
+/// [`pr_info_once`]: srctree/include/linux/printk.h
+///
+/// # Examples
+///
+/// ```
+/// kernel::pr_info_once!("hello {}\n", "there");
+/// ```
+#[macro_export]
+macro_rules! pr_info_once (
+    ($($arg:tt)*) => (
+        $crate::do_once_lite!($crate::pr_info!($($arg)*))
+    )
+);

-- 
2.44.1

