From: Alvin Sun <alvin.sun@linux.dev>
Subject: [PATCH v3 0/7] rust: use vertical import style and remove
 redundant imports
Date: Thu, 21 May 2026 14:57:06 +0800
Message-Id: <20260521-miscdev-use-format-v3-0-56240ca70d0c@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMKsDmoC/33NzQ6CMAzA8VchO1uzjg/Bk+9hPIytSBMBs8GCI
 by7gxMH4/HftL8uwpNj8uKaLMJRYM9DHyM9JcK0un8SsI0tlFSFzLGCjr2xFGDyBM3gOj1Cpes
 LlWmNBlHEw7ejhucdvT9it+zHwX32HwG36V8uIEhAtLkqai3JmtuL+2k+xzWxcUEdCCV/EioSR
 WZNVjYG0yw/Euu6fgGytJ6W9wAAAA==
X-Change-ID: 20260519-miscdev-use-format-9ab7e83b1c11
To: Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Brendan Higgins <brendan.higgins@linux.dev>, David Gow <david@davidgow.net>, 
 Rae Moar <raemoar63@gmail.com>
Cc: rust-for-linux@vger.kernel.org, linux-block@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, kunit-dev@googlegroups.com, 
 Alvin Sun <alvin.sun@linux.dev>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779346631; l=2046;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=GpYuZvdDKSuZ1FkselZsxzc4wSkWmWm7XFBxDLF6Dfo=;
 b=9TEu8Yc9XNqL9wX0FvAYfA0lvscmTHZs2twn+GcDzJhNe5UnPm8lthdGPe11tTpP2XTfpTgo3
 JcXbyTOrc1gDOUZSajW+eZGDIefXk0kBSHzEZIvvVqnOjic1rkaxH4B
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adopt the vertical import style and drop redundant imports already
re-exported via `kernel::prelude`.

Changes include:
- Convert use statements to vertical import style in miscdevice,
  samples, doctest, and block/mq
- Remove imports covered by prelude and apply minor formatting

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
Changes in v3:
- Add trailing // to last items and closing braces in block/mq imports
- Add rnull vertical import style
- Add doctest vertical import style
- Link to v2: https://lore.kernel.org/r/20260520-miscdev-use-format-v2-0-64dc48fc1345@linux.dev

Changes in v2:
- Reformat use statements and drop redundant imports in
  rust/kernel/block/mq
- Drop redundant imports in rust/kernel/miscdevice
- Link to v1: https://lore.kernel.org/r/20260519-miscdev-use-format-v1-0-11d526ba0edc@linux.dev

---
Alvin Sun (7):
      rust: miscdevice: use vertical import style
      samples: rust_misc_device: use vertical import style
      rust: miscdevice: remove redundant imports
      rust: block: mq: use vertical import style
      rust: block: mq: remove redundant imports and format
      rust: block: rnull: use vertical import style
      rust: doctest: use vertical import style

 drivers/block/rnull/configfs.rs    | 27 +++++++++++++++++++++------
 drivers/block/rnull/rnull.rs       | 15 +++++++++++----
 rust/kernel/block/mq/gen_disk.rs   | 24 ++++++++++++++++++------
 rust/kernel/block/mq/operations.rs | 14 ++++++++++----
 rust/kernel/block/mq/request.rs    | 16 +++++++++++-----
 rust/kernel/block/mq/tag_set.rs    | 28 ++++++++++++++--------------
 rust/kernel/miscdevice.rs          | 23 +++++++++++++++++------
 samples/rust/rust_misc_device.rs   | 34 ++++++++++++++++++++++++++++------
 scripts/rustdoc_test_gen.rs        | 11 +++++++++--
 9 files changed, 139 insertions(+), 53 deletions(-)
---
base-commit: 5200f5f493f79f14bbdc349e402a40dfb32f23c8
change-id: 20260519-miscdev-use-format-9ab7e83b1c11

Best regards,
-- 
Alvin Sun <alvin.sun@linux.dev>

