From: Jens Korinth <jens.korinth@tuta.io>
Date: Tue, 26 Nov 2024 17:40:58 +0100
Subject: [PATCH v4 2/3] rust: print: Add pr_*_once macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-pr_once_macros-v4-2-410b8ca9643e@tuta.io>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732639280; l=3758;
 i=jens.korinth@tuta.io; s=20241107; h=from:subject:message-id;
 bh=Pi+Tmcbnb+4nLebSMaz3h/2DQwX44dKuBXxl7dtHrxU=;
 b=tLIDXQVk9Ed81M09wh7vjimTiQV9TibbL4r8ubUEsTiDvfMDIR3+zmbvpDBUW5nYApxTwvgx+
 lAp9Y0e1OxID3HD/0ybydDYrzUf4/YxAqsN4Mz9axHo5itbq+777MOG
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
index a28077a7cb301193dcca293befb096b2dd153202..f354b32684a2b3c6c5d9aca6ef9f68e52c870bcf 100644
--- a/rust/kernel/print.rs
+++ b/rust/kernel/print.rs
@@ -414,3 +414,129 @@ macro_rules! pr_cont (
         $crate::print_macro!($crate::print::format_strings::CONT, true, $($arg)*)
     )
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
2.47.0

