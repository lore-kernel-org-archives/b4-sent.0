From: Igor Korotin <igor.korotin.linux@gmail.com>
Date: Mon, 23 Mar 2026 16:06:55 +0000
Subject: [PATCH] MAINTAINERS: Update Rust I2C Subsystem entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260323-update-rust-i2c-maintainers-v1-1-0744ce44f846@gmail.com>
X-B4-Tracking: v=1; b=H4sIAB5lwWkC/x3MQQqDQAxA0atI1g3YjHbAq5QughM1i46SjFIQ7
 97BxV+8zT/BxVQchuYEk0Nd11zxfDQwLpxnQU3VQC292kAB9y1xEbTdCyqN+GXNpSbmSIn7yN0
 Ue4lQD5vJpL/7/v5c1x83NwjHbQAAAA==
X-Change-ID: 20260323-update-rust-i2c-maintainers-2da57a4f75e7
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Igor Korotin <igor.korotin.linux@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774282017; l=1022;
 i=igor.korotin.linux@gmail.com; s=20260125; h=from:subject:message-id;
 bh=zQS73+5EdEVUJZ0XO99JSJWsy7CEqxEYjO2sGkn7GjE=;
 b=+taKkTNdyAwhDG25FXbsIrnfPWPHM9J75EPx0e31becbEMSebkdNCGNdeHKNih+rIsEBX1rbv
 HNjPjEE38bkAnf5QTQzowJp+g7VUxkldqB9H7JeX3Z4/xCDLo5OyhQG
X-Developer-Key: i=igor.korotin.linux@gmail.com; a=ed25519;
 pk=SjZ//wxnynZgJJgTqANyU10A7hdQQdDXLvXIr+zWroE=
X-Endpoint-Received: by B4 Relay for igor.korotin.linux@gmail.com/20260125 with auth_id=615
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Change Igor Korotin's e-mail address
- Add git tree entry

Signed-off-by: Igor Korotin <igor.korotin.linux@gmail.com>
---
 MAINTAINERS | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 77fdfcb55f06..302ddd2d8ec6 100644
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
+T:	git https://github.com/ipv6forever/linux.git rust-i2c-next
 F:	rust/kernel/i2c.rs
 F:	samples/rust/rust_driver_i2c.rs
 F:	samples/rust/rust_i2c_client.rs

---
base-commit: bf074eb6891be799174ff42e0051492681fdc045
change-id: 20260323-update-rust-i2c-maintainers-2da57a4f75e7

Best regards,
-- 
Igor Korotin <igor.korotin.linux@gmail.com>

