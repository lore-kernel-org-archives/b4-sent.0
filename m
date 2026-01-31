From: Igor Korotin <igor.korotin.linux@gmail.com>
Date: Sat, 31 Jan 2026 14:12:47 +0000
Subject: [PATCH 5/5] samples: rust: add Rust I2C adapter registration
 sample
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260131-i2c-adapter-v1-5-5a436e34cd1a@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769868772; l=7280;
 i=igor.korotin.linux@gmail.com; s=20260125; h=from:subject:message-id;
 bh=UoiJITbB7wSdqa0+19oS9e0ghILI5njDjJv+rjpQTNo=;
 b=OJMA6QqqxEoPFMUi/s6s6vUTrFKJwRrspekSjPnBxBTRXVy2rYv7XsxvuwQ2sLrxN9izdsPPP
 eVuBxGsChbWCKUGKyTtelRLz2VjTCBrCm7z+Z8P954G66OF/8b0QJBK
X-Developer-Key: i=igor.korotin.linux@gmail.com; a=ed25519;
 pk=SjZ//wxnynZgJJgTqANyU10A7hdQQdDXLvXIr+zWroE=
X-Endpoint-Received: by B4 Relay for igor.korotin.linux@gmail.com/20260125 with auth_id=615
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new `rust_i2c_adapter` sample, showing how to create a new
i2c adapter using `i2c::adapter::Registration`

Signed-off-by: Igor Korotin <igor.korotin.linux@gmail.com>
---
 MAINTAINERS                      |   3 +-
 samples/rust/Kconfig             |  12 +++
 samples/rust/Makefile            |   1 +
 samples/rust/rust_i2c_adapter.rs | 170 +++++++++++++++++++++++++++++++++++++++
 4 files changed, 184 insertions(+), 2 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 60662984176d..bae13f1f9a23 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -11888,8 +11888,7 @@ L:	rust-for-linux@vger.kernel.org
 S:	Maintained
 F:	rust/i2c/*
 F:	rust/kernel/i2c.rs
-F:	samples/rust/rust_driver_i2c.rs
-F:	samples/rust/rust_i2c_client.rs
+F:	samples/rust/rust_*i2c*.rs
 
 I2C SUBSYSTEM HOST DRIVERS
 M:	Andi Shyti <andi.shyti@kernel.org>
diff --git a/samples/rust/Kconfig b/samples/rust/Kconfig
index 3efa51bfc8ef..a5157b50e27c 100644
--- a/samples/rust/Kconfig
+++ b/samples/rust/Kconfig
@@ -107,6 +107,18 @@ config SAMPLE_RUST_I2C_CLIENT
 
 	  If unsure, say N.
 
+config SAMPLE_RUST_I2C_ADAPTER
+	tristate "I2C Adapter Registration"
+	depends on I2C=y
+	help
+	  This option builds the Rust I2C adapter manual creation
+	  sample.
+
+	  To compile this as a module, choose M here:
+	  the module will be called rust_i2c_adapter.
+
+	  If unsure, say N.
+
 config SAMPLE_RUST_DRIVER_PCI
 	tristate "PCI Driver"
 	depends on PCI
diff --git a/samples/rust/Makefile b/samples/rust/Makefile
index f65885d1d62b..7026eb46ae50 100644
--- a/samples/rust/Makefile
+++ b/samples/rust/Makefile
@@ -9,6 +9,7 @@ obj-$(CONFIG_SAMPLE_RUST_DEBUGFS_SCOPED)	+= rust_debugfs_scoped.o
 obj-$(CONFIG_SAMPLE_RUST_DMA)			+= rust_dma.o
 obj-$(CONFIG_SAMPLE_RUST_DRIVER_I2C)		+= rust_driver_i2c.o
 obj-$(CONFIG_SAMPLE_RUST_I2C_CLIENT)		+= rust_i2c_client.o
+obj-$(CONFIG_SAMPLE_RUST_I2C_ADAPTER)		+= rust_i2c_adapter.o
 obj-$(CONFIG_SAMPLE_RUST_DRIVER_PCI)		+= rust_driver_pci.o
 obj-$(CONFIG_SAMPLE_RUST_DRIVER_PLATFORM)	+= rust_driver_platform.o
 obj-$(CONFIG_SAMPLE_RUST_DRIVER_USB)		+= rust_driver_usb.o
diff --git a/samples/rust/rust_i2c_adapter.rs b/samples/rust/rust_i2c_adapter.rs
new file mode 100644
index 000000000000..542766e27d6f
--- /dev/null
+++ b/samples/rust/rust_i2c_adapter.rs
@@ -0,0 +1,170 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Rust I2C adapter registration sample.
+//!
+//! An I2C adapter in Rust cannot exist on its own. To register a new I2C adapter,
+//! it must be bound to a parent device. In this sample driver, a platform device
+//! is used as the parent.
+
+//! ACPI match table test
+//!
+//! This demonstrates how to test an ACPI-based Rust I2C adapter registration driver
+//! using QEMU with a custom SSDT.
+//!
+//! Steps:
+//!
+//! 1. **Create an SSDT source file** (`ssdt.dsl`) with the following content:
+//!
+//!     ```asl
+//!     DefinitionBlock ("", "SSDT", 2, "TEST", "VIRTACPI", 0x00000001)
+//!     {
+//!         Scope (\_SB)
+//!         {
+//!             Device (T432)
+//!             {
+//!                 Name (_HID, "LNUXBEEF")  // ACPI hardware ID to match
+//!                 Name (_UID, 1)
+//!                 Name (_STA, 0x0F)        // Device present, enabled
+//!                 Name (_CRS, ResourceTemplate ()
+//!                 {
+//!                     Memory32Fixed (ReadWrite, 0xFED00000, 0x1000)
+//!                 })
+//!             }
+//!         }
+//!     }
+//!     ```
+//!
+//! 2. **Compile the table**:
+//!
+//!     ```sh
+//!     iasl -tc ssdt.dsl
+//!     ```
+//!
+//!     This generates `ssdt.aml`
+//!
+//! 3. **Run QEMU** with the compiled AML file:
+//!
+//!     ```sh
+//!     qemu-system-x86_64 -m 512M \
+//!         -enable-kvm \
+//!         -kernel path/to/bzImage \
+//!         -append "root=/dev/sda console=ttyS0" \
+//!         -hda rootfs.img \
+//!         -serial stdio \
+//!         -acpitable file=ssdt.aml
+//!     ```
+//!
+//!     Requirements:
+//!     - The `rust_i2c_adapter` must be present either:
+//!         - built directly into the kernel (`bzImage`), or
+//!         - available as a `.ko` file and loadable from `rootfs.img`
+//!
+//! 4. **Verify it worked** by checking `dmesg`:
+//!
+//!     ```
+//!     rust_i2c_adapter LNUXBEEF:00: Probe Rust I2C Adapter registration sample.
+//!     ```
+//!
+
+use kernel::{
+    acpi,
+    device,
+    devres::Devres,
+    i2c::adapter::{
+        I2cAdapter,
+        I2cAdapterOptions,
+        Registration, //
+    },
+    i2c::algo::{
+        flags, //
+        I2cAlgorithm,
+        I2cFlags,
+        I2cSmbusData,
+    },
+    platform,
+    prelude::*,
+    sync::aref::ARef, //
+};
+
+#[pin_data]
+struct SampleDriver {
+    parent_dev: ARef<platform::Device>,
+    #[pin]
+    i2c_adap: Devres<Registration<SampleDevice>>,
+}
+
+struct SampleDevice {}
+
+#[vtable]
+impl I2cAlgorithm for SampleDevice {
+    fn smbus_xfer(
+        _adap: &I2cAdapter<device::Normal>,
+        _addr: u16,
+        _flags: u16,
+        _read_write: u8,
+        _command: u8,
+        _size: usize,
+        _data: &I2cSmbusData,
+    ) -> Result {
+        dev_info!(_adap.as_ref(), "SMBus xfer: request handler called");
+        Ok(())
+    }
+
+    fn functionality(_adap: &I2cAdapter<device::Normal>) -> I2cFlags {
+        flags::I2C_FUNC_SMBUS_READ_BYTE | flags::I2C_FUNC_SMBUS_WRITE_BYTE
+    }
+}
+
+kernel::acpi_device_table!(
+    ACPI_TABLE,
+    MODULE_ACPI_TABLE,
+    <SampleDriver as platform::Driver>::IdInfo,
+    [(acpi::DeviceId::new(c"LNUXBEEF"), ())]
+);
+
+impl platform::Driver for SampleDriver {
+    type IdInfo = ();
+
+    const ACPI_ID_TABLE: Option<acpi::IdTable<Self::IdInfo>> = Some(&ACPI_TABLE);
+
+    fn probe(
+        pdev: &platform::Device<device::Core>,
+        _id_info: Option<&Self::IdInfo>,
+    ) -> impl PinInit<Self, Error> {
+        pin_init::pin_init_scope(move || {
+            dev_info!(
+                pdev.as_ref(),
+                "Probe Rust I2C Adapter registration sample.\n"
+            );
+
+            Ok(try_pin_init!(Self {
+                parent_dev: pdev.into(),
+                i2c_adap <- {
+                    let name = I2cAdapterOptions{ name: c"rust_i2c_adapter"};
+                    Registration::register(pdev.as_ref(), name)
+                },
+            }))
+        })
+    }
+
+    fn unbind(pdev: &platform::Device<device::Core>, _this: Pin<&Self>) {
+        dev_info!(
+            pdev.as_ref(),
+            "Unbind start: Rust I2C Adapter registration sample.\n"
+        );
+        // The i2c_adap (Devres<Registration<SampleDevice>>) will be automatically
+        // dropped here, which will call i2c_del_adapter() in its Drop impl
+        dev_info!(
+            pdev.as_ref(),
+            "Unbind complete: Rust I2C Adapter registration sample.\n"
+        );
+    }
+}
+
+kernel::module_platform_driver! {
+    type: SampleDriver,
+    name: "rust_i2c_adapter",
+    authors: ["Igor Korotin"],
+    description: "Sample I2C Adapter registration",
+    license: "GPL",
+}

-- 
2.43.0

