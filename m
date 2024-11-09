From: Jens Korinth <jens.korinth@tuta.io>
Subject: [PATCH v3 0/3] rust: Add pr_*_once macros
Date: Sat, 09 Nov 2024 21:30:06 +0100
Message-Id: <20241109-pr_once_macros-v3-0-6beb24e0cac8@tuta.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE7GL2cC/3XOPQ7CMAyG4augzKTKD22BiXugqgrBoUakrpxQg
 VDvTmBiQZ7ewY++l0jACEnsVy/BMGNCGkvY9Ur4wY0XkHguLYwyG61VKyfuafTQR+eZkmw2dgt
 NqE87Y0V5mhgCPr7gsSsdmKLMA4P7ZWy52qqqbdq6kVqG+xWzqzJFGonxcIkOb5Wn+CEHTJn4+
 Z04mw/8d81spJJnr6xuQ7BKwyHfi4skumVZ3mEA3HvtAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731184236; l=1315;
 i=jens.korinth@tuta.io; s=20241107; h=from:subject:message-id;
 bh=2H6S41IRcCn9Cb+JAGXeMkPfayPmFqX4nU3fok/DcA0=;
 b=fCkxcu4Pb9MFk+4BXy+Xgx27D/0StGavmNENGRTa0pKZ3YkyQoZvvKdfHXSc6LHzvU5HBTOZT
 Ji5dF3s5F6/ATS3xBKheY2zPx+T+ZS2GOWKrHk5pU8PSBhQDc3aV6F+
X-Developer-Key: i=jens.korinth@tuta.io; a=ed25519;
 pk=bG0q4Zyj3o4d/r326zKL7ym+/tXzyykcjh+U0M13iyc=
X-Endpoint-Received: by B4 Relay for jens.korinth@tuta.io/20241107 with auth_id=270
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Rust version of pr_[emerg|alert|crit|err|warn|notic|info]_once
functions, which print a message only once.

v3:
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
      rust: print: Add do_once_lite macro
      rust: error: Replace pr_warn by pr_warn_once

 rust/kernel/error.rs |   3 +-
 rust/kernel/print.rs | 160 +++++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 161 insertions(+), 2 deletions(-)
---
base-commit: ae7851c29747fa3765ecb722fe722117a346f988
change-id: 20241107-pr_once_macros-6438e6f5b923

Best regards,
-- 
Jens Korinth <jens.korinth@tuta.io>

