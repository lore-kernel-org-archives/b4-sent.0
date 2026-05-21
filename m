From: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
Subject: [PATCH v7 0/3] rust-helpers: add workqueue helpers
Date: Thu, 21 May 2026 14:24:20 +0530
Message-Id: <20260521-workqueue-v5-sent-v7-0-fb4b4dde35ec@multicorewareinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADzIDmoC/33NQQ6CMBCF4auQrq1poYXiynsYF2Q6SKO02kLRE
 O5uYeVCXf4vmW9mEtAbDOSQzcRjNME4m6LaZQS6xl6QGp2a5CwvmWAVnZy/PkYckUZJA9qBNqq
 WWnIA0UqS7u4eW/PczNM5dWfC4PxrexH5uv7TIqeMaqbLQuaqhoYd+/E2GHAep8ajsbAH15MVj
 uUnpr5hZcKYBq4EyEIU+ge2LMsbtoKrTAoBAAA=
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779353663; l=2149;
 i=aakash.bollineni@multicorewareinc.com; s=20260402;
 h=from:subject:message-id; bh=JkRJHVk7qN/2HRUS21hbOKzxptWiZsFdwOwUimf7mFY=;
 b=Jz4Y9g9j6UIWH09s9vu9Px451gKp+Dcy24rChDOv6wSSkxijYjo0gbYhydgI4K6TbkshWbxSE
 WXR7+/rYyh+Ag3k58euJBGYfcdgsm4EV1wbMMT5mYpS6zKYO0V46HYT
X-Developer-Key: i=aakash.bollineni@multicorewareinc.com; a=ed25519;
 pk=r3Gonl+2k+8RozN9U/XwfICQdnRlAcLeeAfsExmurdE=
X-Endpoint-Received: by B4 Relay for aakash.bollineni@multicorewareinc.com/20260402 with auth_id=711
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Changes in v7:
- Fixed KUnit and rustfmtcheck errors reported by the 0-DAY CI Kernel Test Robot by correctly restoring the `arc_count` function and removing orphaned `#[cfg]` attributes.
- Added an explicit `depends on KUNIT` to `CONFIG_SAMPLE_RUST_WORKQUEUE` in `samples/rust/Kconfig` to prevent randconfig build failures when the sample is enabled but KUnit is disabled.
- Fixed an E0277 trait bounds compilation error for `TestDelayedWorkItem` by utilizing the `impl_has_delayed_work!` macro instead of a manual unsafe implementation.
- Link to v6: https://lore.kernel.org/r/20260408-workqueue-v5-sent-v6-0-0dc184c5343d@multicorewareinc.com

rust: workqueue: add safe cancellation and status methods

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

---
Aakash Bollineni (3):
      rust: helpers: add workqueue helpers
      rust: workqueue: add safe cancellation and status methods
      rust: workqueue: add KUnit and sample stress tests

 rust/helpers/workqueue.c            |  27 ++
 rust/kernel/workqueue.rs            | 500 +++++++++++++++++++++++++++++++++---
 samples/rust/Kconfig                |  11 +
 samples/rust/Makefile               |   2 +
 samples/rust/rust_workqueue_test.rs | 191 ++++++++++++++
 5 files changed, 696 insertions(+), 35 deletions(-)
---
base-commit: bf074eb6891be799174ff42e0051492681fdc045
change-id: 20260407-workqueue-v5-sent-a895d51cc4f5

Best regards,
-- 
Aakash Bollineni <aakash.bollineni@multicorewareinc.com>

