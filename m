From: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
Subject: [PATCH v3 0/3] rust: workqueue: add safe cancellation and status
 methods
Date: Fri, 03 Apr 2026 16:37:04 +0530
Message-Id: <20260403-workqueue-v3-final-v3-0-6ffc3950d804@multicorewareinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFifz2kC/x3MQQqAIBBA0avIrBsQDYOuEi2sxhoKLcUKorsnL
 d/i/wcSRaYErXgg0smJgy/QlYBxsX4m5KkYlFRG1lLjFeJ6ZMqEp0bH3m7obC3NRG4wzQgl3CM
 5vv9p17/vB5qje3ZkAAAA
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aakash Bollineni <aakash.bollineni@multicorewareinc.com>, 
 work@onurozkan.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775214425; l=1788;
 i=aakash.bollineni@multicorewareinc.com; s=20260402;
 h=from:subject:message-id; bh=kGjTkENdy7q+OeO2qD7i5AO0Twg8psQ5VZ2hFy8EUUg=;
 b=U5o+s463TSUeUoNOKa0O5zwWQ2idkBezsyuWRy8QsLH0Q3o+9/EzOTx0cz5V8XbIKIF+HUeP8
 dIDCJZbkekYCujYdEGLXPTP6jrE5lZOKJfRkgqR2b+FaIQGUBA8edlp
X-Developer-Key: i=aakash.bollineni@multicorewareinc.com; a=ed25519;
 pk=r3Gonl+2k+8RozN9U/XwfICQdnRlAcLeeAfsExmurdE=
X-Endpoint-Received: by B4 Relay for aakash.bollineni@multicorewareinc.com/20260402 with auth_id=711
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the third version of the patch series for modernizing the Linux
kernel Rust workqueue infrastructure.

Changes since v2:
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

Signed-off-by: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
---
Aakash Bollineni (3):
      rust: helpers: add workqueue helpers
      rust: workqueue: add safe cancellation and status methods
      rust: workqueue: add KUnit and sample stress tests

 rust/helpers/workqueue.c            |  32 +++
 rust/kernel/workqueue.rs            | 473 +++++++++++++++++++++++++++++++++---
 samples/rust/Kconfig                |  10 +
 samples/rust/Makefile               |   2 +
 samples/rust/rust_workqueue_test.rs | 186 ++++++++++++++
 5 files changed, 668 insertions(+), 35 deletions(-)
---
base-commit: bf074eb6891be799174ff42e0051492681fdc045
change-id: 20260403-workqueue-v3-final-fa406defb67c

Best regards,
-- 
Aakash Bollineni <aakash.bollineni@multicorewareinc.com>

