From: Jahnavi MN <jahnavimn@google.com>
Subject: [PATCH 0/3] rust_binder: Update bitmaps to use kernel::impl_flags!
Date: Thu, 16 Jul 2026 13:02:33 +0000
Message-Id: <20260716-b4-rust_binder_impl_flags-v1-0-b4201d3f15b3@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGnWWGoC/x3MTQqDMBBA4avIrBuIP9HSqxQJiZnogE1lRkUQ7
 25w+S3eO0GQCQU+xQmMOwn9U0b5KmCYXBpRUciGSlet7kqjfKN4k9V6SgHZ0m+ZbZzdKApN7Rv
 0g3ubALlfGCMdz/vbX9cNaGIagmsAAAA=
X-Change-ID: 20260715-b4-rust_binder_impl_flags-e53b4ebca85d
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Carlos Llamas <cmllamas@google.com>, Alice Ryhl <aliceryhl@google.com>, 
 Benno Lossin <lossin@kernel.org>, Gary Guo <gary@garyguo.net>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Jahnavi MN <jahnavimn@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784206955; l=1764;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=g8byhzJ0757bwzJX0AxfBx4wrotg0FZXPBl6jsAufbA=;
 b=Ku6icqBojPj99XZG3oDkVtiv9adTROLYTiA3FYP6WMwKE0AAbZ9CdtqilKtTL3JWgupUT7Opg
 SwC9MfEXs27DOzqfiz+2K8H1mNUMl8uC71jH7m9boO/KgTFAyUTV2Ra
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
Jahnavi MN (3):
      rust_binder: Update defer_work bitmaps to use kernel::impl_flags!
      rust_binder: Update looper_flags bitmaps to use kernel::impl_flags!
      rust_binder: Update transaction flags to use kernel::impl_flags!

 drivers/android/binder/process.rs     | 34 +++++++++++------
 drivers/android/binder/thread.rs      | 69 +++++++++++++++++++++--------------
 drivers/android/binder/transaction.rs | 56 +++++++++++++++++++++-------
 3 files changed, 105 insertions(+), 54 deletions(-)
---
base-commit: 775553d19b163446c38c5ff24dd0a01065376932
change-id: 20260715-b4-rust_binder_impl_flags-e53b4ebca85d

Best regards,
-- 
Jahnavi MN <jahnavimn@google.com>

