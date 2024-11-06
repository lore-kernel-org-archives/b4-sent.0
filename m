From: Jens Korinth <jens.korinth@tuta.io>
Subject: [PATCH v2 0/3] rust: Add pr_*_once macros
Date: Thu, 07 Nov 2024 00:28:30 +0100
Message-Id: <20241107-pr_once_macros-v2-0-dc0317ff301e@tuta.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ/7K2cC/03MQQ6CMBCF4auYWVsCLRR15T2MIbVOYYztkCkaE
 8LdbVyZt/oW718hoxBmOO1WEHxTJk4Fer8DP7k0oqJ7Mehat01T92qWgZPHITovnJVtzQFt6G5
 HbaCcZsFAn1/wci0OwlEtk6D7z5iyztRVb/vOqkaF14MWVy0cObHQeYyOnpXnCNv2BZlrqAijA
 AAA
X-Change-ID: 20241107-pr_once_macros-6438e6f5b923
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>
Cc: rust-for-linux@vger.kernel.org, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Dirk Behme <dirk.behme@gmail.com>, Jens Korinth <jens.korinth@tuta.io>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730935742; l=1165;
 i=jens.korinth@tuta.io; s=20241107; h=from:subject:message-id;
 bh=tw5fLm83O0UTmbo9rIYoAbdVNaWkQiP+TDLFds65lNo=;
 b=Sh9XFH3RvKvlt28Wir7l4tE3kbQ9S0dnphTIpAAuVJnAo2M+IMtK3QZsf5WDeQAcRXExciXXb
 3i2L4fJMk+JDO9j/kVH73OXbO+JeQ3pvUI+WAfSgUoHMDRIWt/mALeD
X-Developer-Key: i=jens.korinth@tuta.io; a=ed25519;
 pk=bG0q4Zyj3o4d/r326zKL7ym+/tXzyykcjh+U0M13iyc=
X-Endpoint-Received: by B4 Relay for jens.korinth@tuta.io/20241107 with auth_id=270
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Rust version of pr_[emerg|alert|crit|err|warn|notic|info]_once
functions, which print a message only once.

v2:
- Split patch into do_once_lite part and pr_*_once macros
- Add macro rule for call without condition => renamed to do_once_lite
- Used condition-less call in pr_*_once macros
- Added examples
- Removed TODO in kernel/error.rs using pr_warn_once
v1: https://lore.kernel.org/rust-for-linux/20241106.083113.356536037967804464.fujita.tomonori@gmail.com/

Signed-off-by: Jens Korinth <jens.korinth@tuta.io>
Co-developed-by: FUJITA Tomonori <fujita.tomonori@gmail.com>
Co-developed-by: Boqun Feng <boqun.feng@gmail.com>
---
FUJITA Tomonori (1):
      rust: print: Add pr_*_once macros

Jens Korinth (2):
      rust: print: Add do_once_lite macro
      rust: error: Replace pr_warn by pr_warn_once

 rust/kernel/error.rs |   3 +-
 rust/kernel/print.rs | 143 +++++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 144 insertions(+), 2 deletions(-)
---
base-commit: ae7851c29747fa3765ecb722fe722117a346f988
change-id: 20241107-pr_once_macros-6438e6f5b923

Best regards,
-- 
Jens Korinth <jens.korinth@tuta.io>

