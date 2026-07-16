From: Jahnavi MN <jahnavimn@google.com>
Subject: [PATCH v4 0/7] rust_binder : Implement dynamic debug logging mask
Date: Thu, 16 Jul 2026 08:37:42 +0000
Message-Id: <20260716-rust_binder_debug_mask-v4-0-3d7436c2d2f2@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFaYWGoC/3XO0QqCMBQG4FeRXbfYznRmV71HhDh31FG62FQK8
 d2bQmCE5+4/8H/nTMSjM+jJOZqIw9F4Y7sQ4kNEyqboaqRGh0yAgWQpA+oG3+fKdBpdrlENdd4
 W/k6lkKlIGU8kxCSUnw4r81rh6y3kxvjeuvd6Z+TL9kuKPXLklNFM6YqDSgQk5aW2tn7gsbQtW
 cwRNg5nuw4EB06xjDlDUaD8c8TW2f9HBIdpzLgKU8nsx5nn+QNpHKosTQEAAA==
X-Change-ID: 20260702-rust_binder_debug_mask-636737015624
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784191078; l=4362;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=2cTyGQxiPcEGtvUHu/kbM4yuhwyD6Mvy8x2J7m0KD/U=;
 b=NbxyrcHPGPChOFK7d81dY6wwA/tC6AFbq09ExXq99XVdjszTLOzI4NwpcMNxH6U1M7ENlKn3l
 0inSC6/ae25DA/CtFFVJP2DnQ1OfFudk4dxskywqTqKj/YbQEvUzgQZ
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a user-space application sends malformed data or makes a
lifecycle mistake, the driver rejects it with a generic error code
(like -EINVAL). Without internal logs, the driver acts as a
"black box," forcing developers to guess which check failed.

In the legacy C Binder driver, this issue is solved using a dynamic
debug_mask module parameter that toggles verbose logs for specific
subsystems. This series brings the same critical capability to the
Rust Binder driver to provide developers with clear, real-time
feedback.

Instead of rebuilds, reboots, or guessing:
- Developers can enable logs instantly on a running device by writing to 
  `/sys/module/rust_binder/parameters/debug_mask`.
- It prints the exact reason for failures (such as alignment errors, 
  mismatched call stacks, or invalid handle references) directly into 
  `dmesg`, reducing debugging time from hours to seconds.
- It protects system logs by keeping logging off by default and only 
  enabling it when developers are actively troubleshooting.

Based on top of:
https://git.kernel.org/pub/scm/linux/kernel/git/gregkh/char-misc.git

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
Changes in v4:
- Rebase the entire series on top of the latest char-misc-testing tree.
- Link to v3: https://lore.kernel.org/r/20260713-rust_binder_debug_mask-v3-0-0de91bbbbf69@google.com

Changes in v3:
- Rebase the entire series on top of the latest char-misc-testing tree.
- Define `rust_binder_debug_mask` in Rust as an `Atomic<u32>` and export it to
  C as `extern u32` to avoid raw volatile reads and FFI UB.
- Use `kernel::bits::bit_u32` instead of raw bit shifts.
- Simplify `binder_debug!` macro rules and remove the redundant `raw` helper.
- Wrap the raw mask in `DebugMasks` to use type-safe `.contains(mask)`.
- Link to v2: https://lore.kernel.org/r/20260710-rust_binder_debug_mask-v2-0-2846410e3ae6@google.com

Changes in v2:
- Defined the debug mask categories using bitflags (impl_flags) to
  resolve potential Undefined Behavior and match Rust idioms.
- Added a tgid helper to rust/kernel/task.rs to expose the task
  group ID and optimize default "PID:TID" prefixing.
- Implemented the BINDER_DEBUG_DEATH_NOTIFICATION mask to log OOM
  failures, lifecycle updates, and async delivery to user-space.
- Added pid fields to ThreadError, DeliverCode, and FreezeMessage
  to ensure cancellation logs show the correct process PID instead
  of background kworker PIDs.
- Removed duplicate PID printing across workqueue, transaction
  failure, and stack unwinding logs.
- Refactored log formatting (e.g. formatted BinderError with {:?},
  used "strong"/"weak" strings, and improved message wording).
- Fixed logic bugs (restored missing update_ref block, moved manager
  lookup warnings).
- Cleaned up spurious newlines, corrected indentations, and adjusted
  all commit titles to be shorter and more meaningful.
- Link to v1: https://lore.kernel.org/r/20260703-rust_binder_debug_mask-v1-0-9bdf12b5325c@google.com

---
Jahnavi MN (7):
      rust_binder: Add dynamic debug logging mask
      rust_binder: Implement BINDER_DEBUG_USER_ERROR for freezer-related operation
      rust_binder: Implement BINDER_DEBUG_USER_ERROR for refcounting and death notifications
      rust_binder: Implement BINDER_DEBUG_USER_ERROR for transaction parsing failures
      rust_binder: Implement BINDER_DEBUG_FAILED_TRANSACTION
      rust_binder: Implement BINDER_DEBUG_DEATH_NOTIFICATION
      rust_binder: Implement BINDER_DEBUG_DEAD_TRANSACTION

 drivers/android/binder/debug.rs            |  76 +++++++++++++++++++
 drivers/android/binder/freeze.rs           |  64 +++++++++++-----
 drivers/android/binder/node.rs             |  24 ++++--
 drivers/android/binder/process.rs          |  56 ++++++++++++--
 drivers/android/binder/rust_binder_main.rs |  16 +++-
 drivers/android/binder/rust_binderfs.c     |   3 +
 drivers/android/binder/thread.rs           | 117 ++++++++++++++++++++---------
 drivers/android/binder/transaction.rs      |  15 ++++
 rust/kernel/task.rs                        |   7 ++
 9 files changed, 309 insertions(+), 69 deletions(-)
---
base-commit: 775553d19b163446c38c5ff24dd0a01065376932
change-id: 20260702-rust_binder_debug_mask-636737015624

Best regards,
-- 
Jahnavi MN <jahnavimn@google.com>

