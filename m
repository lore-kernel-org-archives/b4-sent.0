From: Igor Korotin <igor.korotin.linux@gmail.com>
Subject: [PATCH 0/5] rust: extend I2C functionality
Date: Sat, 31 Jan 2026 14:12:42 +0000
Message-Id: <20260131-i2c-adapter-v1-0-5a436e34cd1a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANoNfmkC/yXOywrCMBCF4VcJszYlF2O0iPge0kVMpjXUXpxUE
 Urf3dgu/wPzMTMkpIgJSjYD4SemOPQ55I6Bf7i+QR5DblBCHYTUkkfluQtunJB40MegtfB7rwz
 ki5Gwjt9Vu1VbE77eGZ22ETpMya1oyc6bKawU2khZGCuMMlzy4Fq6tkg9PouBmsufvruE3A9dF
 6eSOevzL7W1J6OhWpYfLGRRwMYAAAA=
X-Change-ID: 20260131-i2c-adapter-d38d330c4c25
To: Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Wolfram Sang <wsa+renesas@sang-engineering.com>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-i2c@vger.kernel.org, markus.probst@posteo.de, 
 Igor Korotin <igor.korotin.linux@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769868772; l=2298;
 i=igor.korotin.linux@gmail.com; s=20260125; h=from:subject:message-id;
 bh=YWgwSGL7NFu8wA5Ois87/WxkNSDJhp8JTOnbIFhNw4M=;
 b=NYx1gpxD4caOuoDAMtgUPYxZAFyMYfRR1NZcLY5lk90c5c4Dk/xcpMcA0pxsTfdE2c/F9U+Ci
 344uPpFIbNPDh2BY+DwOy+smwVsM0zAkFirPRxMMYN66XCfMMf0J/1F
X-Developer-Key: i=igor.korotin.linux@gmail.com; a=ed25519;
 pk=SjZ//wxnynZgJJgTqANyU10A7hdQQdDXLvXIr+zWroE=
X-Endpoint-Received: by B4 Relay for igor.korotin.linux@gmail.com/20260125 with auth_id=615
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series extend the existing I2C functionality with:
- Abstractions allowing to implement I2C algorithms used by I2C adapters;
- Abstractions allowing to create and add new I2C adapters;
- Safe wrappers upon I2C and SMbus transferring C API: read/write
  bytes/words/byte arrays.

The patch series contains additional new sample driver `rust_i2c_adapter`
presenting the new functionality. 

Patch series depend on 
message-id: <20260107103511.570525-1-dakr@kernel.org>

Signed-off-by: Igor Korotin <igor.korotin.linux@gmail.com>
---
Igor Korotin (5):
      rust: i2c: split client and adapter code into separate files
      rust: bits: add define_flags macro
      rust: i2c: Add I2C Adapter registration abstractions
      rust: i2c: add I2C wrappers
      samples: rust: add Rust I2C adapter registration sample

 MAINTAINERS                      |   4 +-
 include/linux/i2c.h              |   6 +
 rust/helpers/helpers.c           |   1 +
 rust/helpers/i2c.c               |  15 ++
 rust/kernel/bits.rs              |  57 ++++++++
 rust/kernel/i2c.rs               | 254 ++-------------------------------
 rust/kernel/i2c/adapter.rs       | 200 ++++++++++++++++++++++++++
 rust/kernel/i2c/algo.rs          | 300 +++++++++++++++++++++++++++++++++++++++
 rust/kernel/i2c/client.rs        | 284 ++++++++++++++++++++++++++++++++++++
 samples/rust/Kconfig             |  12 ++
 samples/rust/Makefile            |   1 +
 samples/rust/rust_driver_i2c.rs  |  10 +-
 samples/rust/rust_i2c_adapter.rs | 170 ++++++++++++++++++++++
 samples/rust/rust_i2c_client.rs  |  15 +-
 14 files changed, 1069 insertions(+), 260 deletions(-)
---
base-commit: a7c013f779530190d0c1e1aa5e7c8a61f0bd479e
change-id: 20260131-i2c-adapter-d38d330c4c25
prerequisite-message-id: <20260107103511.570525-1-dakr@kernel.org>
prerequisite-patch-id: 6e4d28a06d842ddfc7db82f410532a35b8fe317d
prerequisite-patch-id: 9739295d85b688257fca29be1e1217a05a69c9e7
prerequisite-patch-id: 78eaed3746a40713f44f13508fcf43653b0a4528
prerequisite-patch-id: 99f1881bc896896297a903affcfa4f62cab1a307
prerequisite-patch-id: ea8baa9d648f1178d6f39d140b98bddf3c183f6f
prerequisite-patch-id: f8a9e049d204bde04e80151a67dfff5ec2633e7a

Best regards,
-- 
Igor Korotin <igor.korotin.linux@gmail.com>

