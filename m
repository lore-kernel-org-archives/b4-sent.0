From: Markus Probst <markus.probst@posteo.de>
Date: Fri, 13 Mar 2026 20:03:10 +0100
Subject: [PATCH v3 6/7] mfd: Add synology microp core driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260313-synology_microp_initial-v3-6-ad6ac463a201@posteo.de>
References: <20260313-synology_microp_initial-v3-0-ad6ac463a201@posteo.de>
In-Reply-To: <20260313-synology_microp_initial-v3-0-ad6ac463a201@posteo.de>
To: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Igor Korotin <igor.korotin.linux@gmail.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Robert Moore <robert.moore@intel.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-pci@vger.kernel.org, linux-leds@vger.kernel.org, 
 linux-acpi@vger.kernel.org, acpica-devel@lists.linux.dev, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3772;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=n1TKkDCU7sA420yu0PCrb8RGAbqzgpwd288LpkGJk1c=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBptF97W5uQx7vZUUUd4QTbEpR69O3l4q/MbVaPB
 MN4wBOFIiyJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCabRfexsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9IsyhAAhBUVFnog6ffMupKTG44AV8/+txW6AW1
 EvUWNHUFE8jVpTzG30B+pT3z9Ay1Wm6uXoBrrg9hRXLYdZczOyEPw5SHpbBQ02+xqwRi732nBd0
 NE+9GUMnsEI2Z64+5sNuqjEJCQRQT4shpdDV8fJ4QGegPLRoTcl/ns/JG7Uxik+98RCzJFKuEoH
 qPiaqjizLGlQSjWRxmToWO8wcORGh27vMzKUR1xRqWWHEBQKN6FbgK3+C+CO8sOSoamqMnhkTq9
 z4rxYOrOtA1J/ZiHlNLd55BEQhTXDyKTriwjm8POPEKXAeahPGy4nCXLK9RTKDrGIGERH7DEZCN
 IhdOEF8AYgjZG4A3F5xy5RxRRAZB2zeEYD8UqGhGthVmmPlD8eo2oBUgox3iNh7BkxER5SqYa6P
 EKkEKwJZkzbeXT2JmQ3uCNTuGiiA0sLzO0JYPeYNvnwgVtswPVgMZv4zeokBKJe+6tNFBUFcwvn
 nbQsJYfMsuR6Z/vbZXek0ofgoaTKNDfjbBNyojNybEwKLF35it2wvyfwiwfgRVDpRYcZhswpP22
 3+DBMH2MreBmpoTD6ut+vAqGJmAwhRoEPu1P9B4sgWnWkBn6BAq7nTNm3d8nD6OGaw/CbnVpR7x
 W3cW1RzC4tFC/zCLdW9w6BMAaK9wt8vl1wEqBVbCxRHWXTqCAl7Y=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a synology microp core driver, written in Rust.
The driver targets a microcontroller found in Synology NAS devices. It
only provides the base for sub-devices, like LEDs.

Tested successfully on a Synology DS923+.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 MAINTAINERS                    |  7 +++++++
 drivers/mfd/Kconfig            | 11 ++++++++++
 drivers/mfd/Makefile           |  2 ++
 drivers/mfd/synology_microp.rs | 46 ++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 66 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index fa49e40836ab..32932ecab9cf 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25539,6 +25539,13 @@ F:	drivers/dma-buf/sync_*
 F:	include/linux/sync_file.h
 F:	include/uapi/linux/sync_file.h
 
+SYNOLOGY MICROP DRIVER
+M:	Markus Probst <markus.probst@posteo.de>
+S:	Maintained
+F:	Documentation/devicetree/bindings/leds/synology,microp.yaml
+F:	Documentation/devicetree/bindings/mfd/synology,microp.yaml
+F:	drivers/mfd/synology_microp.rs
+
 SYNOPSYS ARC ARCHITECTURE
 M:	Vineet Gupta <vgupta@kernel.org>
 L:	linux-snps-arc@lists.infradead.org
diff --git a/drivers/mfd/Kconfig b/drivers/mfd/Kconfig
index 7192c9d1d268..8b8b391d1b47 100644
--- a/drivers/mfd/Kconfig
+++ b/drivers/mfd/Kconfig
@@ -1320,6 +1320,17 @@ config MFD_SY7636A
 	  To enable support for building sub-devices as modules,
 	  choose M here.
 
+config MFD_SYNOLOGY_MICROP
+	tristate "Synology Microp core driver"
+	depends on RUST
+	select RUST_SERIAL_DEV_BUS_ABSTRACTIONS
+	select MFD_CORE
+	help
+	  Enable support for the MCU found in Synology NAS devices.
+
+	  This driver only provides the base for sub-devices. For additional
+	  functionality, you have to enable support for the sub-devices as well.
+
 config MFD_RDC321X
 	tristate "RDC R-321x southbridge"
 	select MFD_CORE
diff --git a/drivers/mfd/Makefile b/drivers/mfd/Makefile
index e75e8045c28a..f754be7163cd 100644
--- a/drivers/mfd/Makefile
+++ b/drivers/mfd/Makefile
@@ -304,3 +304,5 @@ obj-$(CONFIG_MFD_RSMU_SPI)	+= rsmu_spi.o rsmu_core.o
 obj-$(CONFIG_MFD_UPBOARD_FPGA)	+= upboard-fpga.o
 
 obj-$(CONFIG_MFD_LOONGSON_SE)	+= loongson-se.o
+
+obj-$(CONFIG_MFD_SYNOLOGY_MICROP)	+= synology_microp.o
diff --git a/drivers/mfd/synology_microp.rs b/drivers/mfd/synology_microp.rs
new file mode 100644
index 000000000000..b9b5fff5c18d
--- /dev/null
+++ b/drivers/mfd/synology_microp.rs
@@ -0,0 +1,46 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Synology Microp core driver
+
+use kernel::{
+    device,
+    mfd,
+    of,
+    prelude::*,
+    serdev, //
+};
+
+kernel::module_serdev_device_driver! {
+    type: SynologyMicropCoreDriver,
+    name: "synology_microp",
+    authors: ["Markus Probst <markus.probst@posteo.de>"],
+    description: "Synology Microp core driver",
+    license: "GPL v2",
+}
+
+struct SynologyMicropCoreDriver;
+
+kernel::of_device_table!(
+    OF_TABLE,
+    MODULE_OF_TABLE,
+    <SynologyMicropCoreDriver as serdev::Driver>::IdInfo,
+    [(of::DeviceId::new(c"synology,microp"), ()),]
+);
+
+#[vtable]
+impl serdev::Driver for SynologyMicropCoreDriver {
+    type IdInfo = ();
+    const OF_ID_TABLE: Option<of::IdTable<Self::IdInfo>> = Some(&OF_TABLE);
+    const MFD_CELLS: Option<&'static [mfd::Cell]> =
+        Some(&[mfd::Cell::new(c"synology_microp_leds").of(c"synology,microp-leds", None)]);
+
+    fn probe(
+        dev: &serdev::Device<device::Core>,
+        _id_info: Option<&Self::IdInfo>,
+    ) -> impl PinInit<Self, kernel::error::Error> {
+        let _ = dev.set_baudrate(9600);
+        dev.set_flow_control(false);
+        dev.set_parity(serdev::Parity::None)?;
+        Ok(Self)
+    }
+}

-- 
2.52.0

