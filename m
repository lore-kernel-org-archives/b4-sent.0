From: Igor Korotin <igor.korotin.linux@gmail.com>
Date: Sat, 31 Jan 2026 14:12:46 +0000
Subject: [PATCH 4/5] rust: i2c: add I2C wrappers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260131-i2c-adapter-v1-4-5a436e34cd1a@gmail.com>
References: <20260131-i2c-adapter-v1-0-5a436e34cd1a@gmail.com>
In-Reply-To: <20260131-i2c-adapter-v1-0-5a436e34cd1a@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769868772; l=6310;
 i=igor.korotin.linux@gmail.com; s=20260125; h=from:subject:message-id;
 bh=xiNYPB3pS7P0xBQVQAX6qDtWUnKw7npZg8SdNzhXYa4=;
 b=Ckru9qcxNiYGmCdDkhI5Mp1Q6P6bSRliUUAAG3x2YwBrN/6CsaVzRzwyYvPr8nGcyykkr7P8o
 OVAJmGG4V0cDQMzxLD+rP9JKr9S/AG074vB3APb3xYv9NS8WTiImeKy
X-Developer-Key: i=igor.korotin.linux@gmail.com; a=ed25519;
 pk=SjZ//wxnynZgJJgTqANyU10A7hdQQdDXLvXIr+zWroE=
X-Endpoint-Received: by B4 Relay for igor.korotin.linux@gmail.com/20260125 with auth_id=615
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add safe Rust wrappers for common I2C/SMbus operations on I2C clients.

These wrappers provide safe abstractions over low-level C API calls:
- SMbus byte operations: read/write byte and byte data
- SMbus word operations: read/write word data
- SMbus block operations: read/write I2C block data
- Master I2C operations: master receive and master send

All operations include proper error handling through the Result type.

Signed-off-by: Igor Korotin <igor.korotin.linux@gmail.com>
---
 rust/helpers/helpers.c    |  1 +
 rust/helpers/i2c.c        | 15 ++++++++
 rust/kernel/i2c/client.rs | 92 +++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 108 insertions(+)

diff --git a/rust/helpers/helpers.c b/rust/helpers/helpers.c
index 79c72762ad9c..6f6b0ff8713a 100644
--- a/rust/helpers/helpers.c
+++ b/rust/helpers/helpers.c
@@ -29,6 +29,7 @@
 #include "err.c"
 #include "irq.c"
 #include "fs.c"
+#include "i2c.c"
 #include "io.c"
 #include "jump_label.c"
 #include "kunit.c"
diff --git a/rust/helpers/i2c.c b/rust/helpers/i2c.c
new file mode 100644
index 000000000000..05bbd26eaaf8
--- /dev/null
+++ b/rust/helpers/i2c.c
@@ -0,0 +1,15 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include <linux/i2c.h>
+
+__rust_helper int rust_helper_i2c_master_recv(const struct i2c_client *client,
+				  char *buf, int count)
+{
+	return i2c_master_recv(client, buf, count);
+}
+
+__rust_helper int rust_helper_i2c_master_send(const struct i2c_client *client,
+				  const char *buf, int count)
+{
+	return i2c_master_send(client, buf, count);
+}
diff --git a/rust/kernel/i2c/client.rs b/rust/kernel/i2c/client.rs
index a597793ff038..76fa01cb0351 100644
--- a/rust/kernel/i2c/client.rs
+++ b/rust/kernel/i2c/client.rs
@@ -140,6 +140,98 @@ unsafe impl Send for I2cClient {}
 // (i.e. `I2cClient<Normal>) are thread safe.
 unsafe impl Sync for I2cClient {}
 
+impl I2cClient<device::Normal> {
+    /// The C `i2c_smbus_read_byte` function wrapper for SMbus "read byte" protocol
+    pub fn i2c_smbus_read_byte(&self) -> Result<u8> {
+        // SAFETY: self is a valid reference to a I2cClient<Normal>
+        let result = unsafe { bindings::i2c_smbus_read_byte(self.as_raw()) };
+        to_result(result)?;
+        Ok(result as u8)
+    }
+
+    /// The C `i2c_smbus_write_byte` function wrapper for SMbus "write byte" protocol
+    pub fn i2c_smbus_write_byte(&self, value: u8) -> Result {
+        // SAFETY: self is a valid reference to a I2cClient<Normal>
+        to_result(unsafe { bindings::i2c_smbus_write_byte(self.as_raw(), value) })
+    }
+
+    /// The C `i2c_smbus_read_byte_data` function wrapper for SMbus "read byte" protocol
+    pub fn i2c_smbus_read_byte_data(&self, command: u8) -> Result<u8> {
+        // SAFETY: self is a valid reference to a I2cClient<Normal>
+        let result = unsafe { bindings::i2c_smbus_read_byte_data(self.as_raw(), command) };
+        to_result(result)?;
+        Ok(result as u8)
+    }
+
+    /// The C `i2c_smbus_write_byte_data` function wrapper for SMbus "write byte" protocol
+    pub fn i2c_smbus_write_byte_data(&self, command: u8, value: u8) -> Result {
+        // SAFETY: self is a valid reference to a I2cClient<Normal>
+        to_result(unsafe { bindings::i2c_smbus_write_byte_data(self.as_raw(), command, value) })
+    }
+
+    /// The C `i2c_smbus_read_word_data` function wrapper for SMbus "read word" protocol
+    pub fn i2c_smbus_read_word_data(&self, command: u8) -> Result<u16> {
+        // SAFETY: self is a valid reference to a I2cClient<Normal>
+        let result = unsafe { bindings::i2c_smbus_read_word_data(self.as_raw(), command) };
+        to_result(result)?;
+        Ok(result as u16)
+    }
+
+    /// The C `i2c_smbus_write_word_data` function wrapper for SMbus "write word" protocol
+    pub fn i2c_smbus_write_word_data(&self, command: u8, value: u16) -> Result {
+        // SAFETY: self is a valid reference to a I2cClient<Normal>
+        to_result(unsafe { bindings::i2c_smbus_write_word_data(self.as_raw(), command, value) })
+    }
+
+    /// The C `i2c_smbus_read_i2c_block_data` function wrapper for SMbus "block read" protocol
+    pub fn i2c_smbus_read_i2c_block_data(&self, command: u8, values: &mut [u8]) -> Result<usize> {
+        // SAFETY: self is a valid reference to a I2cClient<Normal>
+        let result = unsafe {
+            bindings::i2c_smbus_read_i2c_block_data(
+                self.as_raw(),
+                command,
+                values.len() as u8,
+                values.as_mut_ptr(),
+            )
+        };
+        to_result(result)?;
+        Ok(result as usize)
+    }
+
+    /// The C `i2c_smbus_write_i2c_block_data` function wrapper for SMbus "block write" protocol
+    pub fn i2c_smbus_write_i2c_block_data(&self, command: u8, values: &[u8]) -> Result {
+        // SAFETY: self is a valid reference to a I2cClient<Normal>
+        to_result(unsafe {
+            bindings::i2c_smbus_write_i2c_block_data(
+                self.as_raw(),
+                command,
+                values.len() as u8,
+                values.as_ptr(),
+            )
+        })
+    }
+
+    /// The C `i2c_master_recv` function wrapper to issue a single I2C message in master
+    /// receive mode
+    pub fn i2c_master_recv(&self, buf: &mut [u8]) -> Result<usize> {
+        // SAFETY: self is a valid reference to a I2cClient<Normal>
+        let result =
+            unsafe { bindings::i2c_master_recv(self.as_raw(), buf.as_mut_ptr(), buf.len() as i32) };
+        to_result(result)?;
+        Ok(result as usize)
+    }
+
+    /// The C `i2c_master_send` function wrapper to issue a single I2C message in master
+    /// transmit mode
+    pub fn i2c_master_send(&self, buf: &[u8]) -> Result<usize> {
+        // SAFETY: self is a valid reference to a I2cClient<Normal>
+        let result =
+            unsafe { bindings::i2c_master_send(self.as_raw(), buf.as_ptr(), buf.len() as i32) };
+        to_result(result)?;
+        Ok(result as usize)
+    }
+}
+
 /// The registration of an i2c client device.
 ///
 /// This type represents the registration of a [`struct i2c_client`]. When an instance of this

-- 
2.43.0

