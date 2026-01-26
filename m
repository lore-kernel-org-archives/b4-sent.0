From: SeungJong Ha <engineer.jjhama@gmail.com>
Subject: [PATCH RFC 0/3] rust: tty: introduce TTY subsystem abstractions
 and rttyprintk
Date: Mon, 26 Jan 2026 12:22:07 +0000
Message-Id: <20260126-rust-tty-printk-driver-v1-0-28604e7e100e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG9cd2kC/x3MMQqAMAxA0atIZgO2QgdXwQO4ikNpowahSlpFE
 e9ucXzD/w9EEqYITfGA0MmRt5ChygLcYsNMyD4bdKVNpbRBOWLClG7chUNa0QufJOicd7bWpvZ
 GQY53oYmvfzxA37Uwvu8HyXEbOW0AAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769430128; l=1424;
 i=engineer.jjhama@gmail.com; s=20260103; h=from:subject:message-id;
 bh=2DfOT3UAARODVsJV5czZKsnnyvSjYk3Dn2jTSNBf8po=;
 b=tVTYQ6aHhoTY4AOc9tNlItXqUo1rNgAXfMKxs2A+KpY7m2RRULw/EMmDxnuoXfCv1XIwK/tJW
 pkNj1auCv2PDnbN+k6E18znO+vwB4H8ZuY+CJqmKKyeGEtLA2JNNnxx
X-Developer-Key: i=engineer.jjhama@gmail.com; a=ed25519;
 pk=G5nmjm+RTiWBpyCvc5xjR1b3li/2zipLSMyz+T4fj5E=
X-Endpoint-Received: by B4 Relay for engineer.jjhama@gmail.com/20260103 with auth_id=590
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello,

This RFC patch series introduces Rust abstractions for the
TTY subsystem and implements a sample driver, rttyprintk.

Currently, TTY abstractions are missing in the
Rust for Linux implementation. This series aims to fill that gap.

It consists of two main parts:
- Rust TTY abstractions
- The rttyprintk driver
rttyprintk serves as the first example of a Rust TTY driver.
I chose to port ttyprintk because its simplicity makes it and 
ideal candidate for validating the new abstractions and demonstrating
their usage.

Thank you!

Signed-off-by: SeungJong Ha <engineer.jjhama@gmail.com>
---
SeungJong Ha (3):
      rust: bindings: add TTY subsystem headers
      rust: tty: add TTY subsystem abstractions
      char: rttyprintk: add Rust TTY printk driver

 drivers/char/Kconfig            |  13 ++
 drivers/char/Makefile           |   1 +
 drivers/char/rttyprintk.rs      | 180 +++++++++++++++
 rust/bindings/bindings_helper.h |   3 +
 rust/kernel/lib.rs              |   2 +
 rust/kernel/tty.rs              | 173 +++++++++++++++
 rust/kernel/tty/driver.rs       | 478 ++++++++++++++++++++++++++++++++++++++++
 rust/kernel/tty/port.rs         | 148 +++++++++++++
 8 files changed, 998 insertions(+)
---
base-commit: e741e19d7691c5e6f5c2bbff980d835dccb86054
change-id: 20260126-rust-tty-printk-driver-ccdca3263d61

Best regards,
-- 
SeungJong Ha <engineer.jjhama@gmail.com>

