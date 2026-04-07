From: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
Subject: [PATCH v4 0/3] rust: workqueue: add safe cancellation and status
 methods
Date: Tue, 07 Apr 2026 16:07:49 +0530
Message-Id: <20260407-workqueue-v3-final-v4-0-c27da7e5f175@multicorewareinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAH3e1GkC/32NSQ7CMBAEvxLNGaNRbMxy4h8oB+OMyYjEDnYWU
 JS/Y/IAbl0tdfUCiSJTgkuxQKSJEwefQe0KsI3xDxJcZ4YSS40KpZhDfL5GGklMUjj2phXOKNQ
 1ubs+WsjDPpLj9ya9VZkbTkOIn+1jkr/2ry4HFNo5K88HrE+ort3YDmxDpNlEYm/3NnRQrev6B
 aSgyQe/AAAA
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn.roy.baron@gmail.com>, 
 Alice Ryhl <aliceryhl@google.com>, Tejun Heo <tj@kernel.org>, 
 Lai Jiangshan <jiangshanlai@gmail.com>, Boqun Feng <boqun@kernel.org>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aakash Bollineni <aakash.bollineni@multicorewareinc.com>, 
 kernel test robot <lkp@intel.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775558278; l=2704;
 i=aakash.bollineni@multicorewareinc.com; s=20260402;
 h=from:subject:message-id; bh=ysMbBy2kApPtTeFdJEI+hTEKpUB+Nd4w1DUl1XEONNM=;
 b=DAh5yG5vBFiE7/cni55InX3MEAzYtsHh6u+c84wUq2q47b9a+mpjRH04W+lyAabONcFqkrYrC
 yQIhvoFsroeBjM+PlqV0QH8Qf5ShL3/9RQ8BIdv1X36Jgb8+B7mWhWX
X-Developer-Key: i=aakash.bollineni@multicorewareinc.com; a=ed25519;
 pk=r3Gonl+2k+8RozN9U/XwfICQdnRlAcLeeAfsExmurdE=
X-Endpoint-Received: by B4 Relay for aakash.bollineni@multicorewareinc.com/20260402 with auth_id=711
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the fourth version of the patch series for modernizing the Linux
kernel Rust workqueue infrastructure.

Changes in v4:
- Fixed rustfmt and formatting errors in samples/rust/rust_workqueue_test.rs
  reported by the kernel test robot.
- Added Reported-by and Closes tags to the third patch for robot tracking.
- Improved the commit structure to cleanly separate API changes from tests.
- Link to v3: https://lore.kernel.org/r/20260403-workqueue-v3-final-v3-0-6ffc3950d804@multicorewareinc.com

Changes in v3:
- Fixed a critical initialization bug in the DelayedWork C-helper where
  the timer function was not correctly registered, causing KUnit crashes.
- Consolidated Arc refcount inspection into a shared `arc_count` helper
  in `rust/kernel/workqueue.rs` (gated by CONFIG_KUNIT).
- Updated internal KUnit tests and sample module to use the shared helper.
- Split the sample test's `TestItem` into `TestWorkItem` and
  `TestDelayedWorkItem` for clearer trait dispatch and safety.
- Integrated the sample stress test into the kernel build system via
  the SAMPLES_RUST Kconfig.
- Improved documentation and safety comments based on feedback from
  Onur and Miguel Ojeda.

Aakash Bollineni (3):
  rust: helpers: add workqueue helpers
  rust: workqueue: add safe cancellation and status methods
  rust: workqueue: add KUnit and sample stress tests

To: Miguel Ojeda <ojeda@kernel.org>
To: Alex Gaynor <alex.gaynor@gmail.com>
To: Wedson Almeida Filho <wedsonaf@gmail.com>
To: Boqun Feng <boqun.feng@gmail.com>
To: Gary Guo <gary@garyguo.net>
To: Björn Roy Baron <bjorn.roy.baron@gmail.com>
To: Benno Lossin <benno.lossin@proton.me>
To: Andreas Hindborg <a.hindborg@samsung.com>
To: Alice Ryhl <aliceryhl@google.com>
To: Tejun Heo <tj@kernel.org>
To: Lai Jiangshan <jiangshanlai@gmail.com>
Cc: rust-for-linux@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

Signed-off-by: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
---
Aakash Bollineni (3):
      rust: helpers: add workqueue helpers
      rust: workqueue: add safe cancellation and status methods
      rust: workqueue: add KUnit and sample stress tests

 rust/helpers/workqueue.c            |  32 +++
 rust/kernel/workqueue.rs            | 463 +++++++++++++++++++++++++++++++++---
 samples/rust/Kconfig                |  10 +
 samples/rust/Makefile               |   2 +
 samples/rust/rust_workqueue_test.rs | 192 +++++++++++++++
 5 files changed, 664 insertions(+), 35 deletions(-)
---
base-commit: bf074eb6891be799174ff42e0051492681fdc045
change-id: 20260403-workqueue-v3-final-fa406defb67c

Best regards,
-- 
Aakash Bollineni <aakash.bollineni@multicorewareinc.com>

