From: Mitchell Levy <levymitchell0@gmail.com>
Subject: [PATCH 0/2] rust: lockdep: Fix soundness issue affecting
 LockClassKeys
Date: Fri, 04 Oct 2024 15:01:36 -0700
Message-Id: <20241004-rust-lockdep-v1-0-e9a5c45721fc@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMBlAGcC/3XMQQ6CMBCF4auQWTumLZKAK+9hWJTpCBOBkhYbD
 eHuVvYu/5e8b4PIQTjCtdggcJIofs6hTwXQYOeeUVxuMMpcVKMqDK+44ujp6XhBV3KpKqOp7iz
 kyxL4Ie+Du7e5B4mrD59DT/q3/oGSRo3OUENGW1t35tZPVsYz+Qnafd+/qun5vqgAAAA=
To: Boqun Feng <boqun.feng@gmail.com>, Miguel Ojeda <ojeda@kernel.org>, 
 Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Andreas Hindborg <a.hindborg@kernel.org>
Cc: linux-block@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Mitchell Levy <levymitchell0@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728079319; l=2325;
 i=levymitchell0@gmail.com; s=20240719; h=from:subject:message-id;
 bh=yA8zi+D/kjXfBz7wwbF2jGW3GGImBGWDMebbbCkbJtk=;
 b=yz5wfUx3V0h0nT096o9DYbVaoFL3T8pflNc7g21tFsCTJnfM/kKGtgWLYSVQnxXTNAjq8L9Uv
 njm4iXSHk3bBh7tUymQ2ZfjzzviLMkJFU/H+29VLkmZkeDi7mJ6ihe6
X-Developer-Key: i=levymitchell0@gmail.com; a=ed25519;
 pk=n6kBmUnb+UNmjVkTnDwrLwTJAEKUfs2e8E+MFPZI93E=
X-Endpoint-Received: by B4 Relay for levymitchell0@gmail.com/20240719 with auth_id=188
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series is aimed at fixing a soundness issue with how dynamically
allocated LockClassKeys are handled. Currently, LockClassKeys can be
used without being Pin'd, which can break lockdep since it relies on
address stability. Similarly, these keys are not automatically
(de)registered with lockdep.

At the suggestion of Alice Ryhl, this series includes a patch for
-stable kernels that disables dynamically allocated keys. This prevents
backported patches from using the unsound implementation.

Currently, this series requires that all dynamically allocated
LockClassKeys have a lifetime of 'static (i.e., they must be leaked
after allocation). This is because Lock does not currently keep a
reference to the LockClassKey, instead passing it to C via FFI. This
causes a problem because the rust compiler would allow creating a
'static Lock with a 'a LockClassKey (with 'a < 'static) while C would
expect the LockClassKey to live as long as the lock. This problem
represents an avenue for future work.

---
Changes from RFC:
- Split into two commits so that dynamically allocated LockClassKeys are
removed from stable kernels. (Thanks Alice Ryhl)
- Extract calls to C lockdep functions into helpers so things build
properly when LOCKDEP=n. (Thanks Benno Lossin)
- Remove extraneous `get_ref()` calls. (Thanks Benno Lossin)
- Provide better documentation for `new_dynamic()`. (Thanks Benno
Lossin)
- Ran rustfmt to fix formatting and some extraneous changes. (Thanks
Alice Ryhl and Benno Lossin)
- Link to RFC: https://lore.kernel.org/r/20240905-rust-lockdep-v1-1-d2c9c21aa8b2@gmail.com

---
Mitchell Levy (2):
      rust: lockdep: Remove support for dynamically allocated LockClassKeys
      rust: lockdep: Use Pin for all LockClassKey usages

 rust/helpers/helpers.c      |  1 +
 rust/helpers/sync.c         | 13 +++++++++++++
 rust/kernel/lib.rs          |  2 +-
 rust/kernel/sync.rs         | 34 ++++++++++++++++++++++++----------
 rust/kernel/sync/condvar.rs | 11 +++++++----
 rust/kernel/sync/lock.rs    |  4 ++--
 rust/kernel/workqueue.rs    |  2 +-
 7 files changed, 49 insertions(+), 18 deletions(-)
---
base-commit: 9852d85ec9d492ebef56dc5f229416c925758edc
change-id: 20240905-rust-lockdep-d3e30521c8ba

Best regards,
-- 
Mitchell Levy <levymitchell0@gmail.com>

