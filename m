From: Igor Korotin <igor.korotin@linux.dev>
Date: Sat, 04 Apr 2026 18:01:27 +0100
Subject: [PATCH v2] MAINTAINERS: add Rust I2C tree and update Igor
 Korotin's email
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260404-update-rust-i2c-maintainers-v2-1-42f929828eb1@linux.dev>
X-B4-Tracking: v=1; b=H4sIAOZD0WkC/33MywrCMBCF4Vcps3YkSUOrrnwPcRGmk3bAXpikR
 Sh9d4MrVy7O4ufAt0NiFU5wq3ZQ3iTJPJVwpwpoCFPPKF1pcMY1pnYNrksXMqOuKaM4wjHIlMt
 YE9rQRns1RGQJirAoR3l/9cezdNR5xDwoh1+z/mtuFi2a1nti7+PFN/e+3K8zzSMcxwefJJiWw
 AAAAA==
X-Change-ID: 20260326-update-rust-i2c-maintainers-1a7f190ccc1c
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Wolfram Sang <wsa+renesas@sang-engineering.com>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Igor Korotin <igor.korotin@linux.dev>, 
 Igor Korotin <igor.korotin@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775322087; l=2018;
 i=igor.korotin@linux.dev; s=20260125; h=from:subject:message-id;
 bh=xCIEH7BDQOWe++khXPx4h519mVjvTQzY/l30EjdlPtM=;
 b=thSs31gc9SQlyHIiiskN6qH7mSIRnHu5esRoQWmylAj3Tr0UkV0mFPCnLayLrKwHq4fCArboF
 QzJws/PqyaiDBYFEBHUI4ToXM4e/yonkb5GRCXq/ZkzHZZXDjMRJzaI
X-Developer-Key: i=igor.korotin@linux.dev; a=ed25519;
 pk=SjZ//wxnynZgJJgTqANyU10A7hdQQdDXLvXIr+zWroE=
X-Endpoint-Received: by B4 Relay for igor.korotin@linux.dev/20260125 with auth_id=720
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a git tree entry for Rust I2C development and update the
e-mail address.

The tree will be used to collect patches and provide a basis
for integration and testing, including linux-next.

Signed-off-by: Igor Korotin <igor.korotin.linux@gmail.com>
---
Changelog
---------
v2:
- Add an entry in .mailmap linking the e-mail igor.korotin@linux.dev 
with the igor.korotin.linux@gmail.com
- Improve commit message to provide more context
- Update GitHub username from ipv6forever to ikrtn, thus update git
link. 
---
 .mailmap    | 1 +
 MAINTAINERS | 3 ++-
 2 files changed, 3 insertions(+), 1 deletion(-)

diff --git a/.mailmap b/.mailmap
index 5ac7074c455f..3a11f89b3d5b 100644
--- a/.mailmap
+++ b/.mailmap
@@ -327,6 +327,7 @@ Henrik Rydberg <rydberg@bitmath.org>
 Herbert Xu <herbert@gondor.apana.org.au>
 Huacai Chen <chenhuacai@kernel.org> <chenhc@lemote.com>
 Huacai Chen <chenhuacai@kernel.org> <chenhuacai@loongson.cn>
+Igor Korotin <igor.korotin@linux.dev> <igor.korotin.linux@gmail.com>
 Ike Panhc <ikepanhc@gmail.com> <ike.pan@canonical.com>
 J. Bruce Fields <bfields@fieldses.org> <bfields@redhat.com>
 J. Bruce Fields <bfields@fieldses.org> <bfields@citi.umich.edu>
diff --git a/MAINTAINERS b/MAINTAINERS
index 77fdfcb55f06..f5bf555bd32c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -12021,11 +12021,12 @@ F:	include/uapi/linux/i2c-*.h
 F:	include/uapi/linux/i2c.h
 
 I2C SUBSYSTEM [RUST]
-M:	Igor Korotin <igor.korotin.linux@gmail.com>
+M:	Igor Korotin <igor.korotin@linux.dev>
 R:	Danilo Krummrich <dakr@kernel.org>
 R:	Daniel Almeida <daniel.almeida@collabora.com>
 L:	rust-for-linux@vger.kernel.org
 S:	Maintained
+T:	git https://github.com/ikrtn/linux.git rust-i2c-next
 F:	rust/kernel/i2c.rs
 F:	samples/rust/rust_driver_i2c.rs
 F:	samples/rust/rust_i2c_client.rs

---
base-commit: bf074eb6891be799174ff42e0051492681fdc045
change-id: 20260326-update-rust-i2c-maintainers-1a7f190ccc1c

Best regards,
-- 
Igor Korotin <igor.korotin@linux.dev>

