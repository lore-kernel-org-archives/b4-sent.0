From: Jens Korinth <jens.korinth@tuta.io>
Subject: [PATCH v4 0/3] rust: Add pr_*_once macros
Date: Tue, 26 Nov 2024 17:40:56 +0100
Message-Id: <20241126-pr_once_macros-v4-0-410b8ca9643e@tuta.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABj6RWcC/3WOy27CMBBFfwV5jSM/Ege64j+qCjlmTKbCGTQ2U
 SuUf6/DBiRU3dVZnKN7FxkYIYuPzV0wzJiRpgrtdiPC6KczSDxVFkaZVmvVyysfaQpwTD4wZel
 auwMXu2FvrKjSlSHizyP4+VU5MiVZRgb/mrF1nVVN7/rOSS3j7RuLbwolmojxcE4eL02gtCZHz
 IX493FxNmv43zezkUqegrK6j9EqDYdyq10ksX6Z7au8f5Ntld0Ag2lBBR92T3lZlj+dj1SJKgE
 AAA==
X-Change-ID: 20241107-pr_once_macros-6438e6f5b923
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>
Cc: rust-for-linux@vger.kernel.org, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Dirk Behme <dirk.behme@gmail.com>, linux-kernel@vger.kernel.org, 
 Jens Korinth <jens.korinth@tuta.io>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732639280; l=2042;
 i=jens.korinth@tuta.io; s=20241107; h=from:subject:message-id;
 bh=TXCvQS2ahX/hhNk47wS2krc25xjMQW0mokjRm+QW2hE=;
 b=+0qPh84yAX2uxWGdAqymsJMknJSFQEqTR+ty5Cxq5muulovNz9qxkB+KHN6/KaW75+hkRrciO
 APeLtr9QfIqD4ow8u7CW0FBMWgU2BhifyaydUz/ZMdCRAmZ4IpDOHR4
X-Developer-Key: i=jens.korinth@tuta.io; a=ed25519;
 pk=bG0q4Zyj3o4d/r326zKL7ym+/tXzyykcjh+U0M13iyc=
X-Endpoint-Received: by B4 Relay for jens.korinth@tuta.io/20241107 with auth_id=270
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Rust version of pr_[emerg|alert|crit|err|warn|notic|info]_once
functions, which print a message only once.

Introduces a `OnceLite` abstraction similar to Rust's
[`std::sync::Once`](https://doc.rust-lang.org/std/sync/struct.Once.html)
but using the non-blocking mechanism from the kernel's `DO_ONCE_LITE`
macro, which is used to define the `do_once_lite` Rust macro.

First use case are an implementation of `pr_*_once` message macros to
print a message only once.

v4:
- Move `do_once_lite` macro implementation to `OnceLite` abstraction
- Use `OnceLite` in `do_once_lite`
- More documentation, examples
v3: https://lore.kernel.org/rust-for-linux/20241109-pr_once_macros-v3-0-6beb24e0cac8@tuta.io/
- Fix rustdoc error, formatting issues
- Fix missing Signed-off-by
v2: https://lore.kernel.org/r/20241107-pr_once_macros-v2-0-dc0317ff301e@tuta.io
- Split patch into do_once_lite part and pr_*_once macros
- Add macro rule for call without condition => renamed to do_once_lite
- Used condition-less call in pr_*_once macros
- Added examples
- Removed TODO in kernel/error.rs using pr_warn_once
v1: https://lore.kernel.org/rust-for-linux/20241106.083113.356536037967804464.fujita.tomonori@gmail.com/

Co-developed-by: FUJITA Tomonori <fujita.tomonori@gmail.com>
Co-developed-by: Boqun Feng <boqun.feng@gmail.com>
Signed-off-by: Jens Korinth <jens.korinth@tuta.io>
---
FUJITA Tomonori (1):
      rust: print: Add pr_*_once macros

Jens Korinth (2):
      rust: Add `OnceLite` for executing code once
      rust: error: Replace pr_warn by pr_warn_once

 rust/kernel/error.rs     |   3 +-
 rust/kernel/lib.rs       |   1 +
 rust/kernel/once_lite.rs | 127 +++++++++++++++++++++++++++++++++++++++++++++++
 rust/kernel/print.rs     | 126 ++++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 255 insertions(+), 2 deletions(-)
---
base-commit: b2603f8ac8217bc59f5c7f248ac248423b9b99cb
change-id: 20241107-pr_once_macros-6438e6f5b923

Best regards,
-- 
Jens Korinth <jens.korinth@tuta.io>

