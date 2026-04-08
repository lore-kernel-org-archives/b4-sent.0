From: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
Subject: [PATCH v6 0/3] rust: workqueue: add safe cancellation and status
 methods
Date: Wed, 08 Apr 2026 16:06:37 +0530
Message-Id: <20260408-workqueue-v5-sent-v6-0-0dc184c5343d@multicorewareinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIALUv1mkC/32NQQ6CMBBFr0K6dkxBiuDKexgWTTvIRGlxCkVDu
 LuVA7h8L/nvryIgEwZxyVbBGCmQdwmqQyZMr90dgWxiUciikqU8w+L58ZpxRogKAroJdN0oq3J
 jyk6JtBsZO3rvzVubuKcwef7sFzH/2X+1mIMEK211UkXdGC2vw/ycyHjGRTOSM0fjB9Fu2/YFy
 7iSQb0AAAA=
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn.roy.baron@gmail.com>, 
 Alice Ryhl <aliceryhl@google.com>, Tejun Heo <tj@kernel.org>, 
 Lai Jiangshan <jiangshanlai@gmail.com>, Boqun Feng <boqun@kernel.org>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775644627; l=2705;
 i=aakash.bollineni@multicorewareinc.com; s=20260402;
 h=from:subject:message-id; bh=a9FizM6TYahbipOTTxKYodoWPtBuAQAEBGwVzf9mKJA=;
 b=DZIfOHuE5RheOtbfsuBI8e/LrqL4NiMIPHf2wR3m0HWGBeg5vWXZPIvZQFWfjYXNacf6Ks1qY
 zrHR7cpV626Cv9MJ1RdDB1M77GOprChHcsdFOXTO5u9mSZxUpJyAQvr
X-Developer-Key: i=aakash.bollineni@multicorewareinc.com; a=ed25519;
 pk=r3Gonl+2k+8RozN9U/XwfICQdnRlAcLeeAfsExmurdE=
X-Endpoint-Received: by B4 Relay for aakash.bollineni@multicorewareinc.com/20260402 with auth_id=711
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Changes in v6:
- Refactored rust_helper_init_delayed_work to ensure robust, single-pass initialization 
  using standard kernel macros, avoiding redundant lockdep and timer setup.
- Simplified impl_has_delayed_work! macro by using direct pointer casting for 
  work_container_of.
- Added missing # Safety documentation blocks to reclaim methods for Arc and KBox.
- Improved documentation readability by adding vertical whitespace to all examples.
- Cleaned up link syntax by using direct inline links and removing redundant reference lists.
- Removed unused rust_helper_get_dwork_timer_fn C helper.
- Link to v5: https://lore.kernel.org/r/20260407-workqueue-v5-sent-v1-0-d0d635289ca0@multicorewareinc.com

PLEASE IGNORE v4. This version (v5) corrects a critical KUnit build error 
and formatting regressions that were present in the previous submission.

Changes in v5:
- Fixed missing arc_count helper in rust/kernel/workqueue.rs that caused KUnit
  build failures.
- Fixed formatting in samples/rust/rust_workqueue_test.rs via rustfmt.

Changes in v4:
- Fixed Reported-by/Closes tags and metadata for robot tracking.
- Improved commit structure to separate API changes from tests.

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

 rust/helpers/workqueue.c            |  27 ++
 rust/kernel/workqueue.rs            | 500 +++++++++++++++++++++++++++++++++---
 samples/rust/Kconfig                |  10 +
 samples/rust/Makefile               |   2 +
 samples/rust/rust_workqueue_test.rs | 191 ++++++++++++++
 5 files changed, 695 insertions(+), 35 deletions(-)
---
base-commit: bf074eb6891be799174ff42e0051492681fdc045
change-id: 20260407-workqueue-v5-sent-a895d51cc4f5

Best regards,
-- 
Aakash Bollineni <aakash.bollineni@multicorewareinc.com>

