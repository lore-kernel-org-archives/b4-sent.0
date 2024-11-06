From: Jens Korinth <jens.korinth@tuta.io>
Date: Thu, 07 Nov 2024 00:28:31 +0100
Subject: [PATCH v2 1/3] rust: print: Add do_once_lite macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241107-pr_once_macros-v2-1-dc0317ff301e@tuta.io>
References: <20241107-pr_once_macros-v2-0-dc0317ff301e@tuta.io>
In-Reply-To: <20241107-pr_once_macros-v2-0-dc0317ff301e@tuta.io>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730935742; l=1737;
 i=jens.korinth@tuta.io; s=20241107; h=from:subject:message-id;
 bh=XAaxx9JmqKS+Pe6xMJnXcJZk36ZsLXSLNP4nDUqpGWQ=;
 b=nlo7tRq3zFwZSaKfoh2qn6IK8kzCzxDKbH8xIpf4z5UJL/fZtWhMG3GZ599jVImoik7A/dFDP
 JSxC2eEEyAzCDxybfZKNsgLSjw5p1N2hmIP62lxAGr2QNw+KZEJ+X5v
X-Developer-Key: i=jens.korinth@tuta.io; a=ed25519;
 pk=bG0q4Zyj3o4d/r326zKL7ym+/tXzyykcjh+U0M13iyc=
X-Endpoint-Received: by B4 Relay for jens.korinth@tuta.io/20241107 with auth_id=270
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add do_once_lite macro that executes code only once.
Has two rules, one with a condition to replace [`do_once_lite_if`] in
the kernel, and one without.

Signed-off-by: Jens Korinth <jens.korinth@tuta.io>
---
 rust/kernel/print.rs | 34 ++++++++++++++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/rust/kernel/print.rs b/rust/kernel/print.rs
index a28077a7cb301193dcca293befb096b2dd153202..9c7434b221984ad325138e5dc90ab4340cd0be2e 100644
--- a/rust/kernel/print.rs
+++ b/rust/kernel/print.rs
@@ -414,3 +414,37 @@ macro_rules! pr_cont (
         $crate::print_macro!($crate::print::format_strings::CONT, true, $($arg)*)
     )
 );
+
+/// Executes code only once.
+///
+/// Equivalent to the kernel's [`do_once_lite_if`] macro when called with
+/// a condition expression.
+/// Public but hidden since it should only be used from public macros.
+///
+/// # Examples
+///
+/// ```
+/// kernel::do_once_lite!(pr_warn!("warn once"));
+/// kernel::do_once_lite!({ /* perform_complex_test() */ true }, pr_warn!("warn only once"));
+/// ```
+#[doc(hidden)]
+#[macro_export]
+macro_rules! do_once_lite (
+    ($e:expr) => (
+         $crate::do_once_lite!(true, $e);
+    );
+    ($condition:expr, $e:expr) => (
+        {
+            #[link_section = ".data.once"]
+            static ALREADY_DONE: core::sync::atomic::AtomicBool =
+                core::sync::atomic::AtomicBool::new(false);
+
+            if !ALREADY_DONE.load(core::sync::atomic::Ordering::Relaxed)
+                && $condition
+                && !ALREADY_DONE.swap(true, core::sync::atomic::Ordering::Relaxed)
+            {
+                $e;
+            }
+        }
+    );
+);

-- 
2.44.1

