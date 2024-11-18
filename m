From: Manas <manas18244@iiitd.ac.in>
Subject: [PATCH v3 0/3] rust: simplify Result<()> uses
Date: Mon, 18 Nov 2024 20:06:57 +0530
Message-Id: <20241118-simplify-result-v3-0-6b1566a77eab@iiitd.ac.in>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAlRO2cC/3XNQQ6CMBCF4auQrh3SKYLUlfcwLkpbZBIE0tZGQ
 ri7hZXGuPxfMt8szFtH1rNztjBnI3kahxTFIWO6U8PdApnUTHBxRMQTeHpMPbUzOOuffQCtjKx
 VyyXXkqWrydmWXrt4vaXuyIfRzfuDiNv634oICGXDsTGi4KpqLkQUTK50TgPbtCg+hfpXEMBBG
 lFzZVSJlfkW1nV9A8Na983yAAAA
X-Change-ID: 20241117-simplify-result-cad98af090c9
To: FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Trevor Gross <tmgross@umich.edu>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, Alice Ryhl <aliceryhl@google.com>
Cc: Shuah Khan <skhan@linuxfoundation.org>, 
 Anup Sharma <anupnewsmail@gmail.com>, netdev@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-block@vger.kernel.org, Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731940618; l=1260;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=QHseiXY+gfW1EiR35D5KxqOHqK4eeKBQcxrZQPzLitA=;
 b=s2Lr7AgQs25d0IvfDjJKsibL0zs8oJ2YK5AHcKdytvGp7n1aGMrCGAuQVem9QwVc13EGdycYI
 hZaY8R/tP5rCbgqqMYIWtb64UcS2AO+vcvLbYO3kPWYkKBZxYBkUkrg
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
Changes in v3:
- Add Link: and Suggested-by: tags in all three commit messages
- Edit in imperative tense for commit messages
- Link to v2: https://lore.kernel.org/r/20241118-simplify-result-v2-0-9d280ada516d@iiitd.ac.in

Changes in v2:
- rust: split patches according to various subsystems
- rust: add rationale for change
- qt2025: removed qt2025 patch from this series and sent it separately
  to netdev subsystem
  Link to qt2025 patch:
  https://lore.kernel.org/netdev/20241118-simplify-result-qt2025-v1-1-f2d9cef17fca@iiitd.ac.in/
- Link to v1: https://lore.kernel.org/r/20241117-simplify-result-v1-1-5b01bd230a6b@iiitd.ac.in

---
Manas (3):
      rust: block: simplify Result<()> in validate_block_size return
      rust: uaccess: simplify Result<()> in bytes_add_one return
      rust: macros: simplify Result<()> in function returns

 rust/kernel/block/mq/gen_disk.rs | 2 +-
 rust/kernel/uaccess.rs           | 2 +-
 rust/macros/lib.rs               | 6 +++---
 3 files changed, 5 insertions(+), 5 deletions(-)
---
base-commit: b2603f8ac8217bc59f5c7f248ac248423b9b99cb
change-id: 20241117-simplify-result-cad98af090c9

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

