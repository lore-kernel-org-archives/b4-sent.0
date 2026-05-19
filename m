From: Alvin Sun <alvin.sun@linux.dev>
Subject: [PATCH 0/2] rust: use vertical import style in miscdevice
Date: Tue, 19 May 2026 13:34:40 +0800
Message-Id: <20260519-miscdev-use-format-v1-0-11d526ba0edc@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHD2C2oC/x3MSQqAMAxA0atI1gaM4ngVcVFr1CwcaFSE0rtbX
 L7F/x6UnbBCl3hw/IjKsUdQmoBdzb4wyhQNeZZXWUktbqJ24gdvZZwPt5kLWzPW3BQjWSKI4el
 4lvef9kMIH50rfo9kAAAA
X-Change-ID: 20260519-miscdev-use-format-9ab7e83b1c11
To: Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: rust-for-linux@vger.kernel.org, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779168918; l=679;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=Kt1pKARna8/xQ3HmoQXhRxx24kWWvngd4wSdwQk6i9I=;
 b=71h/KZZhVWHxosEJ/I2y58Dbo70gw8FqY2e6wU5kTNxYIUaS+GkBfItvwUOhLHBCUr+fn5Cg7
 gYG+1DOcyvYApGLaHyO7O3ggtGI1EnHTjW/jV327TrlrMv89tgYo+cp
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reformat `use` imports to vertical style for readability and to reduce
merge conflicts when imports are added or removed.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
Alvin Sun (2):
      rust: miscdevice: use vertical import style
      samples: rust_misc_device: use vertical import style

 rust/kernel/miscdevice.rs        | 34 ++++++++++++++++++++++++++++------
 samples/rust/rust_misc_device.rs | 34 ++++++++++++++++++++++++++++------
 2 files changed, 56 insertions(+), 12 deletions(-)
---
base-commit: 5200f5f493f79f14bbdc349e402a40dfb32f23c8
change-id: 20260519-miscdev-use-format-9ab7e83b1c11

Best regards,
-- 
Alvin Sun <alvin.sun@linux.dev>

