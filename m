From: Valentin Obst <kernel@valentinobst.de>
Subject: [PATCH v3 00/12] rust: kernel: documentation improvements
Date: Wed, 31 Jan 2024 21:23:22 +0100
Message-Id: <20240131-doc-fixes-v3-v3-0-0c8af94ed7de@valentinobst.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADqsumUC/03MQQ7CIBCF4as0s3YaBqoQV97DuEAYLLGCgYaYN
 L27xJXLLy//26ByiVzhPGxQuMUac+pQhwHcbNODMfpukEJOghShzw5D/HDFptAYG07OONJaQ0/
 ehX9bL6637lDyC9e5sP07kYqOgkiO1GUmJHxySbxcml04rTHle11Hz7DvXxnpvLOfAAAA
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Valentin Obst <kernel@valentinobst.de>, Trevor Gross <tmgross@umich.edu>, 
 Martin Rodriguez Reboredo <yakoyoku@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706732646; l=2912;
 i=kernel@valentinobst.de; s=20240131; h=from:subject:message-id;
 bh=hC2mjadfbWNTXdCp+iDgEDDn3h44Sq3ssmfR5EiK618=;
 b=pjeD6O87EU/R9JZ4wGfJiVtnCZ1taFiqeJwfEpkF7kfmfd7ldXLcsHwS+yxW0OzOBqb0CRUY3
 mXewAIRUDKsD1RkswDY54GjOAJ64IUno5EstWR3bxBzni/XpHqXMVzm
X-Developer-Key: i=kernel@valentinobst.de; a=ed25519;
 pk=3s7U8y0mqkaiurgHSQQTYWOo2tw5HgzCg5vnJVfw37Y=
X-Endpoint-Received: by B4 Relay for kernel@valentinobst.de/20240131 with auth_id=124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch set aims to make small improvements to the documentation of
the kernel crate. It engages in a few different activities:
- fixing trivial typos (commit #1),
- updating code examples to better reflect an idiomatic coding style
  (commits #2,6),
- increasing the consistency within the crate's documentation as a whole
  (commits #3,5,7,8,9,11,12),
- adding more intra-doc links as well as srctree-relative links to C
  header files (commits #4,10).

---
Changes in v3:
- Adjusted word wrapping in "rust: locked_by: shorten doclink preview"
  to make use of the gained space.
- Rebased with `rust-next`.
- Link to v2: https://lore.kernel.org/lkml/20240123150112.124084-1-kernel@valentinobst.de/
Changes in v2:
- Drop commit "rust: kernel: add doclinks with html tags" in response to
  review.
- Fix another list item alignment issue pointed out during review of v1.
  Was added to commit "rust: kernel: fix multiple typos in
  documentation".
- Commit "rust: error: move unsafe block into function call" is now
  "rust: error: improve unsafe code in example" and also rewords the
  SAFETY comment of the code example.
  - Did not add 'Reviewed-By' tags offered in v1 tags due to changes.
- Link to v1: https://lore.kernel.org/lkml/20240116160141.165951-1-kernel@valentinobst.de/

---
Valentin Obst (12):
      rust: kernel: fix multiple typos in documentation
      rust: error: improve unsafe code in example
      rust: ioctl: end top-level module docs with full stop
      rust: kernel: add srctree-relative doclinks
      rust: str: use `NUL` instead of 0 in doc comments
      rust: str: move SAFETY comment in front of unsafe block
      rust: kernel: unify spelling of refcount in docs
      rust: kernel: mark code fragments in docs with backticks
      rust: kernel: add blank lines in front of code blocks
      rust: kernel: add doclinks
      rust: kernel: remove unneeded doclink targets
      rust: locked_by: shorten doclink preview

 rust/kernel/allocator.rs          |  2 +-
 rust/kernel/error.rs              | 10 ++----
 rust/kernel/init.rs               | 16 +++++-----
 rust/kernel/ioctl.rs              |  6 ++--
 rust/kernel/lib.rs                |  2 +-
 rust/kernel/str.rs                |  8 ++---
 rust/kernel/sync/arc.rs           | 14 ++++-----
 rust/kernel/sync/condvar.rs       |  2 ++
 rust/kernel/sync/lock.rs          | 15 ++++++---
 rust/kernel/sync/lock/spinlock.rs |  2 +-
 rust/kernel/sync/locked_by.rs     |  7 +++--
 rust/kernel/task.rs               |  6 ++--
 rust/kernel/types.rs              |  3 ++
 rust/kernel/workqueue.rs          | 64 +++++++++++++++++++--------------------
 14 files changed, 84 insertions(+), 73 deletions(-)
---
base-commit: f090f0d0eea9666a96702b29bc9a64cbabee85c5
change-id: 20240131-doc-fixes-v3-88af6c8c1777

Best regards,
-- 
Valentin Obst <kernel@valentinobst.de>

