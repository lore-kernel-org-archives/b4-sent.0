From: SeungJong Ha <engineer.jjhama@gmail.com>
Date: Mon, 26 Jan 2026 12:22:10 +0000
Subject: [PATCH RFC 3/3] char: rttyprintk: add Rust TTY printk driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-rust-tty-printk-driver-v1-3-28604e7e100e@gmail.com>
References: <20260126-rust-tty-printk-driver-v1-0-28604e7e100e@gmail.com>
In-Reply-To: <20260126-rust-tty-printk-driver-v1-0-28604e7e100e@gmail.com>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 SeungJong Ha <engineer.jjhama@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769430128; l=7897;
 i=engineer.jjhama@gmail.com; s=20260103; h=from:subject:message-id;
 bh=a2DRGFsUADXLosl2ifUZW9MiZCCY2Vpnl3B7hhzcS3s=;
 b=SrHjZWCLbU+bFkMTCRhqi6lLL4GS37SdtqxBHuAv5wz9+GYL9gQLMDzJLiOgy9cTAibetIEXA
 aQy0JHLOBzVA8mUOJmBcs+je03mqo4kwxlqKz2fgz0trjvyIP6cm2+k
X-Developer-Key: i=engineer.jjhama@gmail.com; a=ed25519;
 pk=G5nmjm+RTiWBpyCvc5xjR1b3li/2zipLSMyz+T4fj5E=
X-Endpoint-Received: by B4 Relay for engineer.jjhama@gmail.com/20260103 with auth_id=590
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a Rust implementation of the ttyprintk driver, demonstrating the new
TTY Rust abstractions.

This driver creates /dev/rttyprintk which allows user messages to be
written to the kernel log via printk, similar to the existing C
ttyprintk driver.

Features:
- Uses the new kernel::tty abstractions for type-safe TTY operations
- Implements TtyDevice with open/close/write/write_room/hangup callbacks
- Uses DriverPort with SpinLock-protected TpkState for thread-safe
  buffer management
- Buffers up to 508 bytes per line, flushing on newline or buffer full
- Messages are logged at KERN_INFO level with [U] prefix

The driver serves as a reference implementation for Rust TTY drivers
and demonstrates:
- Pin-initialization patterns for TTY drivers and ports
- Arc-based shared state between driver callbacks
- Safe handling of driver_data and driver_state
- Integration with kernel printk for output

Signed-off-by: SeungJong Ha <engineer.jjhama@gmail.com>
---
 drivers/char/Kconfig       |  13 ++++
 drivers/char/Makefile      |   1 +
 drivers/char/rttyprintk.rs | 180 +++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 194 insertions(+)

diff --git a/drivers/char/Kconfig b/drivers/char/Kconfig
index d2cfc584e202..66a482024ff4 100644
--- a/drivers/char/Kconfig
+++ b/drivers/char/Kconfig
@@ -31,6 +31,19 @@ config TTY_PRINTK_LEVEL
 	help
 	  Printk log level to use for ttyprintk messages.
 
+config TTY_DEV_RUST_PRINTK
+	tristate "Rust TTY driver to output user messages via printk"
+	depends on RUST && TTY
+	default n
+	help
+	  If you say Y here, the support for writing user messages (i.e.
+	  console messages) via printk is available, implemented in Rust.
+
+	  This is the Rust implementation of the ttyprintk driver,
+	  demonstrating rkernel domain isolation for kernel modules.
+
+	  If unsure, say N.
+
 config PRINTER
 	tristate "Parallel printer support"
 	depends on PARPORT
diff --git a/drivers/char/Makefile b/drivers/char/Makefile
index 1291369b9126..608bb6d724a0 100644
--- a/drivers/char/Makefile
+++ b/drivers/char/Makefile
@@ -5,6 +5,7 @@
 
 obj-y				+= mem.o random.o
 obj-$(CONFIG_TTY_PRINTK)	+= ttyprintk.o
+obj-$(CONFIG_TTY_DEV_RUST_PRINTK)	+= rttyprintk.o
 obj-y				+= misc.o
 obj-$(CONFIG_TEST_MISC_MINOR)	+= misc_minor_kunit.o
 obj-$(CONFIG_ATARI_DSP56K)	+= dsp56k.o
diff --git a/drivers/char/rttyprintk.rs b/drivers/char/rttyprintk.rs
new file mode 100644
index 000000000000..f5394f605cf4
--- /dev/null
+++ b/drivers/char/rttyprintk.rs
@@ -0,0 +1,180 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Rust TTY printk driver.
+//!
+//! Allows user messages to be written to the kernel log via printk.
+
+use kernel::{
+    bindings,
+    c_str,
+    new_spinlock,
+    prelude::*,
+    sync::{
+        Arc,
+        SpinLock,
+    },
+    tty::{
+        self,
+        port,
+        DriverPort,
+        Tty,
+    },
+};
+
+module! {
+    type: RttyPrintk,
+    name: "rttyprintk",
+    authors: ["SeungJong Ha"],
+    description: "Rust TTY driver to output user messages via printk",
+    license: "GPL",
+}
+
+const TPK_STR_SIZE: usize = 508;
+const TPK_MAX_ROOM: u32 = 4096;
+
+/// Mutable state protected by spinlock.
+struct TpkState {
+    curr: usize,
+    buffer: [u8; TPK_STR_SIZE + 4],
+}
+
+impl TpkState {
+    const fn new() -> Self {
+        Self {
+            curr: 0,
+            buffer: [0u8; TPK_STR_SIZE + 4],
+        }
+    }
+
+    fn flush(&mut self) {
+        if self.curr > 0 {
+            self.buffer[self.curr] = 0;
+            // SAFETY: buffer is null-terminated.
+            unsafe {
+                bindings::_printk(c_str!("\x016[U] %s\n").as_char_ptr(), self.buffer.as_ptr());
+            }
+            self.curr = 0;
+        }
+    }
+
+    fn do_write(&mut self, buf: &[u8]) -> usize {
+        for (i, &c) in buf.iter().enumerate() {
+            if self.curr >= TPK_STR_SIZE {
+                self.buffer[self.curr] = b'\\';
+                self.curr += 1;
+                self.flush();
+            }
+
+            match c {
+                b'\r' => {
+                    self.flush();
+                    if buf.get(i + 1) == Some(&b'\n') {
+                        continue;
+                    }
+                }
+                b'\n' => self.flush(),
+                _ => {
+                    self.buffer[self.curr] = c;
+                    self.curr += 1;
+                }
+            }
+        }
+        buf.len()
+    }
+}
+
+struct TpkPortOps;
+type TpkPort = DriverPort<TpkPortOps>;
+
+#[vtable]
+impl port::Operations for TpkPortOps {
+    type PortData = SpinLock<TpkState>;
+
+    fn shutdown(port: &TpkPort) {
+        port.data().lock().flush();
+    }
+}
+
+struct TpkDevice;
+type TpkTty = Tty<Arc<TpkPort>, Arc<TpkPort>>;
+
+#[vtable]
+impl tty::Operations for TpkDevice {
+    type DriverData = Arc<TpkPort>;
+    type DriverState = Arc<TpkPort>;
+    type PortOps = TpkPortOps;
+
+    fn open(tty: &TpkTty, _file: *mut bindings::file) -> Result<()> {
+        // Clone the Arc from driver_state and set it as driver_data.
+        // This mirrors the original ttyprintk.c pattern where tty->driver_data is set
+        // to the port in open(). In practice, since Arc allows shared access and
+        // SpinLock protects the state, we could just use driver_state() directly.
+        // However, we follow the original C code structure for consistency.
+        let port = tty.driver_state().ok_or(ENXIO)?;
+        tty.set_driver_data(port);
+        Ok(())
+    }
+
+    fn close(tty: &TpkTty, _file: *mut bindings::file) {
+        // Take and drop driver_data, mirroring tpk_close() which sets
+        // tty->driver_data = NULL. The Arc will be dropped, decrementing refcount.
+        tty.take_driver_data();
+    }
+
+    fn write(tty: &TpkTty, buf: &[u8]) -> Result<usize> {
+        // Access port via driver_data (set in open), following original ttyprintk.c.
+        // SpinLock inside TpkState protects concurrent writes.
+        let port = tty.driver_data().ok_or(ENXIO)?;
+        Ok(port.data().lock().do_write(buf))
+    }
+
+    fn write_room(_tty: &TpkTty) -> u32 {
+        TPK_MAX_ROOM
+    }
+
+    fn hangup(_tty: &TpkTty) {}
+}
+
+struct RttyPrintk {
+    #[allow(dead_code)]
+    driver: Pin<KBox<tty::TtyDriver<TpkDevice>>>,
+}
+
+impl kernel::Module for RttyPrintk {
+    fn init(module: &'static kernel::ThisModule) -> Result<Self> {
+        pr_info!("Rust TTY printk driver initializing\n");
+
+        let port = Arc::pin_init(
+            TpkPort::new(new_spinlock!(TpkState::new(), "tpk_lock")),
+            GFP_KERNEL,
+        )?;
+
+        let opts = tty::Options {
+            driver_name: c_str!("rttyprintk"),
+            name: c_str!("rttyprintk"),
+            major: tty::TTYAUX_MAJOR,
+            minor_start: 4,
+            driver_type: tty::DriverType::Console,
+            flags: tty::flags::RESET_TERMIOS | tty::flags::REAL_RAW | tty::flags::UNNUMBERED_NODE,
+        };
+
+        // link_port needs a reference, set_driver_state takes ownership of the Arc.
+        let builder = tty::TtyDriverBuilder::<TpkDevice>::new(opts, module)?
+            .link_port(&port, 0)
+            .set_driver_state(port);
+
+        let driver = KBox::pin_init(builder.build(), GFP_KERNEL)?;
+
+        pr_info!("Rust TTY printk driver registered at /dev/rttyprintk\n");
+
+        Ok(Self { driver })
+    }
+}
+
+impl Drop for RttyPrintk {
+    fn drop(&mut self) {
+        // Reclaim the driver state before the driver is unregistered.
+        self.driver.take_driver_state();
+        pr_info!("Rust TTY printk driver unloading\n");
+    }
+}

-- 
2.43.0

