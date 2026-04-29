From: Markus Probst <markus.probst@posteo.de>
Date: Wed, 29 Apr 2026 20:21:34 +0200
Subject: [PATCH v7 4/4] samples: rust: add Rust serial device bus sample
 device driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-rust_serdev-v7-4-0d89c791b5c8@posteo.de>
References: <20260429-rust_serdev-v7-0-0d89c791b5c8@posteo.de>
In-Reply-To: <20260429-rust_serdev-v7-0-0d89c791b5c8@posteo.de>
To: Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Kari Argillander <kari.argillander@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Boqun Feng <boqun@kernel.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Boqun Feng <boqun@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-pm@vger.kernel.org, 
 driver-core@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4264;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=ou+gfdCBhxJ76kbzVf5IO+8JF7WjVK31ujX01kwK5wI=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBp8kxHkRff2LTNQNrlQO0C+eM5ZARNc0YvxmC3C
 /WpacjS6BaJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCafJMRxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9KC5A//T2TNQEKCMsoAwbNcLxxRapj3uV7GPbO
 8BEqs/fzM9BqbwUJwARU0Us8W9CdsSS6oz33F9i3p0c1j2rGk0tgZl4vFIm1km0uHkB0N3nmotf
 bO6dfN3G2BTM2VNHWkbaTuwgODb+d3j0kdV0yApfGJGKfD3p9YPwAVbesu6tFjoovu0tGYs81LW
 gGrFkpTwdZU2L4lAMTY7sO5T6KpO0jsA1R1HHSrjcUU+s9DjQH5GNmLMtS+TM8B4qMYe6UlqZpI
 h2BgEsvIMbsEHOihCPqATpDdzit3OP4Yoboo6McEgiwli0iLFmSwJS/58BYQsDVTD4Bi7BUATzc
 Ws8hOu4EmcnJsfUiHxnLTbL9pa2xMZRo6QfF+T57+/mOAdELmA+VVxqwWvEW8sXwkloA6YMSa5+
 An5f5onlM7fBaL+qb847q6DGE6ehmBHozJQOQMRPg9xD/1pLrcBPrgZQmsMZAQSBbAg2LkiChsI
 rPmDLEDlbvI32XiRZ7f9SBUDhsHwyUMTXNReZNsqT0g3H7QN4tDc5Blk1dk/TFtkjnY5urgkGo/
 bMus5gDlqM/O6F+a+Ej+qxD9fo7CcIaX5oMjidAUEub7NM4CVcgiWnySYuZAi1/YYSXtZZoInKp
 y7CXvweyox2RUSwjJP8V9mrCQ7x9F5XMxRR7iOZdhk1TgeC+gSKo=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a sample Rust serial device bus device driver illustrating the usage
of the serial device bus abstractions.

This drivers probes through either a match of device / driver name or a
match within the OF ID table.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 samples/rust/Kconfig               | 11 +++++
 samples/rust/Makefile              |  1 +
 samples/rust/rust_driver_serdev.rs | 86 ++++++++++++++++++++++++++++++++++++++
 3 files changed, 98 insertions(+)

diff --git a/samples/rust/Kconfig b/samples/rust/Kconfig
index c49ab9106345..31d62533ef25 100644
--- a/samples/rust/Kconfig
+++ b/samples/rust/Kconfig
@@ -161,6 +161,17 @@ config SAMPLE_RUST_DRIVER_AUXILIARY
 
 	  If unsure, say N.
 
+config SAMPLE_RUST_DRIVER_SERDEV
+	tristate "Serial Device Bus Device Driver"
+	select RUST_SERIAL_DEV_BUS_ABSTRACTIONS
+	help
+	  This option builds the Rust serial device bus driver sample.
+
+	  To compile this as a module, choose M here:
+	  the module will be called rust_driver_serdev.
+
+	  If unsure, say N.
+
 config SAMPLE_RUST_SOC
 	tristate "SoC Driver"
 	select SOC_BUS
diff --git a/samples/rust/Makefile b/samples/rust/Makefile
index 6c0aaa58cccc..b986b681cde5 100644
--- a/samples/rust/Makefile
+++ b/samples/rust/Makefile
@@ -14,6 +14,7 @@ obj-$(CONFIG_SAMPLE_RUST_DRIVER_PLATFORM)	+= rust_driver_platform.o
 obj-$(CONFIG_SAMPLE_RUST_DRIVER_USB)		+= rust_driver_usb.o
 obj-$(CONFIG_SAMPLE_RUST_DRIVER_FAUX)		+= rust_driver_faux.o
 obj-$(CONFIG_SAMPLE_RUST_DRIVER_AUXILIARY)	+= rust_driver_auxiliary.o
+obj-$(CONFIG_SAMPLE_RUST_DRIVER_SERDEV)		+= rust_driver_serdev.o
 obj-$(CONFIG_SAMPLE_RUST_CONFIGFS)		+= rust_configfs.o
 obj-$(CONFIG_SAMPLE_RUST_SOC)			+= rust_soc.o
 
diff --git a/samples/rust/rust_driver_serdev.rs b/samples/rust/rust_driver_serdev.rs
new file mode 100644
index 000000000000..956ca62831fe
--- /dev/null
+++ b/samples/rust/rust_driver_serdev.rs
@@ -0,0 +1,86 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Rust Serial device bus device driver sample.
+
+use kernel::{
+    acpi,
+    device::{
+        Bound,
+        Core, //
+    },
+    of,
+    prelude::*,
+    serdev,
+    sync::aref::ARef, //
+};
+
+struct SampleDriver {
+    sdev: ARef<serdev::Device>,
+}
+
+kernel::of_device_table!(
+    OF_TABLE,
+    MODULE_OF_TABLE,
+    <SampleDriver as serdev::Driver<'_>>::IdInfo,
+    [(of::DeviceId::new(c"test,rust_driver_serdev"), ())]
+);
+
+kernel::acpi_device_table!(
+    ACPI_TABLE,
+    MODULE_ACPI_TABLE,
+    <SampleDriver as serdev::Driver<'_>>::IdInfo,
+    [(acpi::DeviceId::new(c"LNUXBEEF"), ())]
+);
+
+#[vtable]
+impl<'a> serdev::Driver<'a> for SampleDriver {
+    type IdInfo = ();
+    const OF_ID_TABLE: Option<of::IdTable<Self::IdInfo>> = Some(&OF_TABLE);
+    const ACPI_ID_TABLE: Option<acpi::IdTable<Self::IdInfo>> = Some(&ACPI_TABLE);
+
+    fn probe(
+        sdev: &'a serdev::Device<Core>,
+        _info: Option<&'a Self::IdInfo>,
+    ) -> impl PinInit<Self, Error> + 'a {
+        let dev = sdev.as_ref();
+
+        dev_dbg!(dev, "Probe Rust Serial device bus device driver sample.\n");
+
+        if sdev
+            .set_baudrate(
+                dev.fwnode()
+                    .and_then(|fwnode| fwnode.property_read(c"baudrate").optional())
+                    .unwrap_or(115200),
+            )
+            .is_err()
+        {
+            return Err(EINVAL);
+        }
+        sdev.set_flow_control(false);
+        sdev.set_parity(serdev::Parity::None)?;
+
+        Ok(Self { sdev: sdev.into() })
+    }
+
+    fn receive(sdev: &serdev::Device<Bound>, _this: Pin<&Self>, data: &[u8]) -> usize {
+        let _ = sdev.write_all(data, serdev::Timeout::Max);
+        data.len()
+    }
+}
+
+impl Drop for SampleDriver {
+    fn drop(&mut self) {
+        dev_dbg!(
+            self.sdev.as_ref(),
+            "Remove Rust Serial device bus device driver sample.\n"
+        );
+    }
+}
+
+kernel::module_serdev_device_driver! {
+    type: SampleDriver,
+    name: "rust_driver_serdev",
+    authors: ["Markus Probst"],
+    description: "Rust Serial device bus device driver",
+    license: "GPL v2",
+}

-- 
2.53.0

