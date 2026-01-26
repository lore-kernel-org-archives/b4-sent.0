From: SeungJong Ha <engineer.jjhama@gmail.com>
Date: Mon, 26 Jan 2026 12:22:08 +0000
Subject: [PATCH RFC 1/3] rust: bindings: add TTY subsystem headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-rust-tty-printk-driver-v1-1-28604e7e100e@gmail.com>
References: <20260126-rust-tty-printk-driver-v1-0-28604e7e100e@gmail.com>
In-Reply-To: <20260126-rust-tty-printk-driver-v1-0-28604e7e100e@gmail.com>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 SeungJong Ha <engineer.jjhama@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769430128; l=837;
 i=engineer.jjhama@gmail.com; s=20260103; h=from:subject:message-id;
 bh=0vsfQQeWd++TfCsHXwKaK0gI8PJ/Xoa6JfQ9dg4v4UA=;
 b=Fy5475B4L9nOFeWUdI7UbNWWUKSEoKi0rb8FZIOg8/+VcC6R7PMXlB6lEd0lU4tXJ8tXtXEzr
 zCGJ67IKU46AR7F9h4/Xo6gH557CrdzWZSCDFwLWadrygVxhTLW6jp9
X-Developer-Key: i=engineer.jjhama@gmail.com; a=ed25519;
 pk=G5nmjm+RTiWBpyCvc5xjR1b3li/2zipLSMyz+T4fj5E=
X-Endpoint-Received: by B4 Relay for engineer.jjhama@gmail.com/20260103 with auth_id=590
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the TTY subsystem by including the following headers:
- linux/tty.h
- linux/tty_driver.h
- linux/tty_port.h

These bindings are needed for the upcoming Rust TTY driver abstractions.

Signed-off-by: SeungJong Ha <engineer.jjhama@gmail.com>
---
 rust/bindings/bindings_helper.h | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/rust/bindings/bindings_helper.h b/rust/bindings/bindings_helper.h
index a067038b4b42..dc326eb84955 100644
--- a/rust/bindings/bindings_helper.h
+++ b/rust/bindings/bindings_helper.h
@@ -81,6 +81,9 @@
 #include <linux/security.h>
 #include <linux/slab.h>
 #include <linux/task_work.h>
+#include <linux/tty.h>
+#include <linux/tty_driver.h>
+#include <linux/tty_port.h>
 #include <linux/tracepoint.h>
 #include <linux/usb.h>
 #include <linux/wait.h>

-- 
2.43.0

