From: Jahnavi MN <jahnavimn@google.com>
Subject: [PATCH v2 0/7] rust_binder : Implement dynamic debug logging mask
Date: Fri, 10 Jul 2026 14:32:51 +0000
Message-Id: <20260710-rust_binder_debug_mask-v2-0-2846410e3ae6@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJMCUWoC/3WNwQ6CMBAFf4Xs2Zp2KyV68j8MIZQupVFa0wLRE
 P7dSuLR40zy5q2QKDpKcClWiLS45ILPgIcCuqH1lpgzmQE5Kl5xZHFOU6OdNxQbQ3q2zdimO1N
 SVbLiolR4gjx+Rurdaw/f6syDS1OI7/1nEV/7S8p/yUUwzs7a9AJ1KbHsrjYE+6BjF0aot237A
 Pv13G+9AAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783693978; l=3639;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=FYPaH+l+XTQ5sU7Qv4cn8DYzP7Jz4mGDL005ddMunCU=;
 b=iymmeidSegkN0WgX29oEAgF/EVrw8oCYVHfMf2H9kNpNWthk3+z1WhirYD4PsnJQKm8RGUJP+
 /ogUSKq11B9DL1cL2i0cWBblc+I/xLYpfmwgMpexNnfFIzfIEM0zhkr
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
https://lore.kernel.org/rust-for-linux/20260707-upgrade-poll-v6-0-4b8fae7bf1d9@google.com/

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
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

 drivers/android/binder/debug.rs            |  80 ++++++++++++++++
 drivers/android/binder/freeze.rs           |  70 ++++++++++----
 drivers/android/binder/node.rs             |  30 +++++-
 drivers/android/binder/process.rs          |  62 ++++++++++--
 drivers/android/binder/rust_binder_main.rs |  16 +++-
 drivers/android/binder/rust_binderfs.c     |   3 +
 drivers/android/binder/thread.rs           | 149 ++++++++++++++++++++++-------
 drivers/android/binder/transaction.rs      |  15 +++
 rust/kernel/task.rs                        |   7 ++
 9 files changed, 363 insertions(+), 69 deletions(-)
---
base-commit: bf694eb01b1313f5510645ca34be4ed034ae08de
change-id: 20260702-rust_binder_debug_mask-636737015624

Best regards,
-- 
Jahnavi MN <jahnavimn@google.com>

