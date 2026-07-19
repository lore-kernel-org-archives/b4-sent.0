From: Jahnavi MN <jahnavimn@google.com>
Subject: [PATCH v3 0/2] rust_binder: Update bitmaps to use
 kernel::impl_flags!
Date: Sun, 19 Jul 2026 11:51:08 +0000
Message-Id: <20260719-b4-rust_binder_impl_flags-v3-0-f8d0b3ea1b87@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACy6XGoC/33NSwqDMBCA4atI1k0xidHaVe9RiuQxiQE1klhpE
 e/eKBTajct/hvlmQRGCg4iu2YICzC46P6RgpwypVgwWsNOpEc1pmVeEY1ng8IxTI92gITSuH7v
 GdMJGDJzJAqQSF65Ruh8DGPfa7fsjdevi5MN7fzWTbfpVywN1JjhPa5oTzQzhkt2s97aDs/I92
 tiZ/lL1EUUTVQmuQWojWK3+qHVdP8AW/xwOAQAA
X-Change-ID: 20260715-b4-rust_binder_impl_flags-e53b4ebca85d
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Carlos Llamas <cmllamas@google.com>, Alice Ryhl <aliceryhl@google.com>, 
 Benno Lossin <lossin@kernel.org>, Gary Guo <gary@garyguo.net>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Jahnavi MN <jahnavimn@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784461872; l=2086;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=NH3oBXw92CbGPFLrybesXiSZiX5ttYhNIw0Bo5XZuYA=;
 b=aG8RbXd+w+vqO72ZJr8tkZNAmFk+zeT3g3jwSD1SwKjNevKhRZJ08yH+o3r2AFq2dtRt09f9L
 0T9t+Gv9VowD31i0vdH3CSWwH5k8T5jp8RlT+xCHdR5Q1oqJHFFKm01
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In the current Rust Binder driver, internal state variables (thread
looper states, deferred work, and transaction configurations) are
represented as raw integers and manipulated using manual bitwise
operations.

This approach lacks type safety. Because the compiler treats all
integers identically, it is possible to pass a thread looper flag
into a function expecting a transaction flag without triggering
compile-time warnings. These cross-contamination errors compile
cleanly but can cause runtime bugs or undefined behavior.

This patch series resolves this issue by migrating these raw integer
bitmaps (`defer_work`, `looper_flags`, `flags`) to strongly-typed
bitmasks using the `kernel::impl_flags!` macro. Functions now accept
specific, distinct types rather than generic integers, preventing
flags from being mixed up. This transition also replaces manual
bitwise arithmetic with readable, safe methods.

Based on top of:
https://git.kernel.org/pub/scm/linux/kernel/git/gregkh/char-misc.git

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
Changes in v3:
- Rewrite commit messages to explain the motivation for the changes.
- Link to v2: https://lore.kernel.org/r/20260719-b4-rust_binder_impl_flags-v2-0-7a5debdfa39c@google.com

Changes in v2:
- Drop Patch 1 (defer_work) as it was merged into char-misc-testing.
- Rebase remaining two patches on latest char-misc-testing tree.
- Link to v1: https://lore.kernel.org/r/20260716-b4-rust_binder_impl_flags-v1-0-b4201d3f15b3@google.com

---
Jahnavi MN (2):
      rust_binder: Update looper_flags bitmaps to use kernel::impl_flags!
      rust_binder: Update transaction flags to use kernel::impl_flags!

 drivers/android/binder/thread.rs      | 68 ++++++++++++++++++++---------------
 drivers/android/binder/transaction.rs | 58 ++++++++++++++++++++++--------
 2 files changed, 83 insertions(+), 43 deletions(-)
---
base-commit: 2cedf2272f1bb42471e646868ac572cc5752bd91
change-id: 20260715-b4-rust_binder_impl_flags-e53b4ebca85d

Best regards,
-- 
Jahnavi MN <jahnavimn@google.com>

