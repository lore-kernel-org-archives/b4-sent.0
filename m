From: Markus Probst <markus.probst@posteo.de>
Date: Fri, 13 Mar 2026 20:03:06 +0100
Subject: [PATCH v3 2/7] rust: add basic mfd abstractions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260313-synology_microp_initial-v3-2-ad6ac463a201@posteo.de>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=11227;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=ZJYERfpm0n00oI7yjkATxc2bgro8TlTIhPLy6Dly0cY=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBptF9zrNeiJ0tRgQoSJcNbO14e0jlYP/jaFWJju
 I4P2fGImzCJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCabRfcxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9L+JQ//QYfpUWXxcV3wTaX3/5kvn1Eyhkd1hT7
 mKG40Y7ioOAYLZ4qgrmScMXXQyMJUVWbuD4XMkfoGGntf6rHQ1QX/cpVMaXcdyYREzp7tt78ybQ
 uZicXLXmohsMVNRWJDMxmO/63NycSrtfMCMr8gu/5gDIH95KsvXCe7uJrptggQHxo2ZEqPqcEGf
 PeMOzfT4SSIwP67OikPQS5xJjA+7AmffJmr40JtXWR4gJPOWnalcgrDTMHSS2AZ/ac+u8W52tQN
 AybHeoUVAW5sKEZ4a7+3VGUSSn5azkmaejdfPYhxWeyCWlDcwYErImDqwajSph64DWOwCHNDCcq
 6/2eAV2jKYKcjBlQxNfQDGBo7zrI4UBWsJbv6LP8hQfw9qNi4spR6pOk8R3EU+cGVNwRUUWDCck
 sEbFxItpjzI1B6oMeBxADL15eDlh3ULVFcQfqWmwUiSjQecodWUf2VHGOMT1UpBdhJmIe1byWaA
 OK/CSYIhQ9lngfAujisyAhS1auD2cmCzsMXnMq55igM0BxAmEvuH/nCvUgDbo18IoYiNP7diKVS
 qW2wcp9ELPmTgOPheeoR1lc+Sl31YInzk+z1qeaQMjSNESX8rnqpwr/1sHQqYisXiP39zqiu/6B
 UmL94ll1jsleQjm2V6QA+rNopg9F6U9/joL1GDIrJyKUtBpYEt0k=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the basic mfd rust abstractions required to register mfd
sub-devices, including:
- `mfd::Cell` - a safe wrapper for `struct mfd_cell`
- `mfd::CellAcpiMatch` - a safe wrapper for `struct mfd_cell_acpi_match`
- `const MFD_CELLS: Option<&'static [mfd::Cell]>` in each bus device,
  except auxiliary

The mfd sub-device registration will be done after a successful call to
probe in each bus device, except auxiliary. This guarantees that
`mfd_add_devices` will only be run at most once per device. It also
ensures that the sub-devices will be probed after the drvdata of the
device has been set.

In order to register mfd sub-devices for a device, the driver needs to
set `const MFD_CELLS` in their Driver trait implementation to Some.
A build_assert guarantees that this can only be set to Some, if
CONFIG_MFD_CORE is enabled.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 MAINTAINERS                     |   6 +++
 rust/bindings/bindings_helper.h |   1 +
 rust/kernel/i2c.rs              |   7 +++
 rust/kernel/lib.rs              |   1 +
 rust/kernel/mfd.rs              | 114 ++++++++++++++++++++++++++++++++++++++++
 rust/kernel/pci.rs              |   7 +++
 rust/kernel/platform.rs         |   7 +++
 rust/kernel/serdev.rs           |   6 +++
 rust/kernel/usb.rs              |   7 +++
 9 files changed, 156 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 749d63ca18fa..fa49e40836ab 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -18082,6 +18082,12 @@ F:	drivers/mfd/
 F:	include/dt-bindings/mfd/
 F:	include/linux/mfd/
 
+MULTIFUNCTION DEVICES (MFD) [RUST]
+M:	Markus Probst <markus.probst@posteo.de>
+S:	Maintained
+T:	git git://git.kernel.org/pub/scm/linux/kernel/git/lee/mfd.git
+F:	rust/kernel/mfd.rs
+
 MULTIMEDIA CARD (MMC) ETC. OVER SPI
 S:	Orphan
 F:	drivers/mmc/host/mmc_spi.c
diff --git a/rust/bindings/bindings_helper.h b/rust/bindings/bindings_helper.h
index f597fe3352f5..b7c17d1d9ece 100644
--- a/rust/bindings/bindings_helper.h
+++ b/rust/bindings/bindings_helper.h
@@ -65,6 +65,7 @@
 #include <linux/jump_label.h>
 #include <linux/led-class-multicolor.h>
 #include <linux/mdio.h>
+#include <linux/mfd/core.h>
 #include <linux/mm.h>
 #include <linux/miscdevice.h>
 #include <linux/of_device.h>
diff --git a/rust/kernel/i2c.rs b/rust/kernel/i2c.rs
index bb5b830f48c3..e733b651d878 100644
--- a/rust/kernel/i2c.rs
+++ b/rust/kernel/i2c.rs
@@ -14,6 +14,7 @@
     devres::Devres,
     driver,
     error::*,
+    mfd,
     of,
     prelude::*,
     types::{
@@ -167,6 +168,9 @@ extern "C" fn probe_callback(idev: *mut bindings::i2c_client) -> kernel::ffi::c_
             let data = T::probe(idev, info);
 
             idev.as_ref().set_drvdata(data)?;
+
+            idev.as_ref().mfd_add_devices(T::MFD_CELLS)?;
+
             Ok(0)
         })
     }
@@ -328,6 +332,9 @@ pub trait Driver: Send {
     /// The table of ACPI device ids supported by the driver.
     const ACPI_ID_TABLE: Option<acpi::IdTable<Self::IdInfo>> = None;
 
+    /// The mfd cells for mfd devices.
+    const MFD_CELLS: Option<&'static [mfd::Cell]> = None;
+
     /// I2C driver probe.
     ///
     /// Called when a new i2c client is added or discovered.
diff --git a/rust/kernel/lib.rs b/rust/kernel/lib.rs
index 311fdf984b87..bacc54ca6aea 100644
--- a/rust/kernel/lib.rs
+++ b/rust/kernel/lib.rs
@@ -114,6 +114,7 @@
 pub mod led;
 pub mod list;
 pub mod maple_tree;
+pub mod mfd;
 pub mod miscdevice;
 pub mod mm;
 pub mod module_param;
diff --git a/rust/kernel/mfd.rs b/rust/kernel/mfd.rs
new file mode 100644
index 000000000000..6c47d9211bf2
--- /dev/null
+++ b/rust/kernel/mfd.rs
@@ -0,0 +1,114 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Abstractions for the mfd subsystem.
+//!
+//! C header: [`include/linux/mfd/core.h`](srctree/include/linux/mfd/core.h)
+
+use core::{mem::MaybeUninit, ptr};
+
+use crate::{
+    device::{
+        CoreInternal,
+        Device, //
+    },
+    error::to_result,
+    prelude::*, //
+};
+
+/// A mfd cell.
+///
+/// # Invariants
+///
+/// A [`Cell`] instance represents a valid `struct mfd_cell`.
+#[repr(transparent)]
+pub struct Cell(bindings::mfd_cell);
+
+impl Cell {
+    /// Creates a new mfd cell.
+    pub const fn new(name: &'static CStr) -> Self {
+        Self(bindings::mfd_cell {
+            name: name.as_ptr().cast::<u8>(),
+
+            // SAFETY: Always safe to call.
+            // This is the const equivalent to `bindings::mfd_cell::default()`.
+            ..unsafe { MaybeUninit::zeroed().assume_init() }
+        })
+    }
+
+    /// Sets `of_compatible` and optionally `of_reg` and `use_of_reg` on the mfd cell.
+    pub const fn of(self, compatible: &'static CStr, reg: Option<u64>) -> Self {
+        Self(bindings::mfd_cell {
+            of_compatible: compatible.as_ptr().cast::<u8>(),
+            // TODO: Use `unwrap_or` once stabilized in const fn.
+            of_reg: if let Some(reg) = reg { reg } else { 0 },
+            use_of_reg: reg.is_some(),
+
+            ..self.0
+        })
+    }
+
+    /// Sets `acpi_match` on the mfd cell.
+    pub const fn acpi(self, acpi_match: &'static CellAcpiMatch) -> Self {
+        Self(bindings::mfd_cell {
+            acpi_match: &raw const acpi_match.0,
+
+            ..self.0
+        })
+    }
+}
+
+/// A mfd cell acpi match entry.
+///
+/// # Invariants
+///
+/// A [`CellAcpiMatch`] instance represents a valid `struct mfd_cell_acpi_match`.
+#[repr(transparent)]
+pub struct CellAcpiMatch(bindings::mfd_cell_acpi_match);
+
+impl CellAcpiMatch {
+    /// Creates a new mfd cell acpi match entry, using a ACPI PNP ID.
+    pub const fn pnpid(pnpid: &'static CStr) -> Self {
+        Self(bindings::mfd_cell_acpi_match {
+            pnpid: pnpid.as_ptr().cast::<u8>(),
+            adr: 0,
+        })
+    }
+
+    /// Creates a new mfd cell acpi match entry, using a ACPI ADR.
+    pub const fn adr(adr: u64) -> Self {
+        Self(bindings::mfd_cell_acpi_match {
+            pnpid: ptr::null(),
+            adr,
+        })
+    }
+}
+
+impl Device<CoreInternal> {
+    /// Registers child mfd devices.
+    // Always inline to optimize out error path of `build_assert`.
+    #[inline(always)]
+    pub(crate) fn mfd_add_devices(&self, cells: Option<&'static [Cell]>) -> Result {
+        if let Some(cells) = cells {
+            build_assert!(cfg!(CONFIG_MFD_CORE));
+
+            // SAFETY:
+            // - `self.as_raw()` is guaranteed to be a pointer to a valid `device`.
+            // - `cells.as_ptr()` is a guaranteed to be a pointer to a valid `mfd_cell` array
+            //   with the length of `cells.len()`.
+            to_result(unsafe {
+                bindings::devm_mfd_add_devices(
+                    self.as_raw(),
+                    bindings::PLATFORM_DEVID_AUTO,
+                    // CAST: `Cell` is a transparent wrapper of `mfd_cell`.
+                    cells.as_ptr().cast::<bindings::mfd_cell>(),
+                    i32::try_from(cells.len())?,
+                    ptr::null_mut(),
+                    0,
+                    ptr::null_mut(),
+                )
+            })?;
+        }
+
+        Ok(())
+    }
+}
diff --git a/rust/kernel/pci.rs b/rust/kernel/pci.rs
index af74ddff6114..6c4cf6cf970b 100644
--- a/rust/kernel/pci.rs
+++ b/rust/kernel/pci.rs
@@ -17,6 +17,7 @@
         from_result,
         to_result, //
     },
+    mfd,
     prelude::*,
     str::CStr,
     types::Opaque,
@@ -116,6 +117,9 @@ extern "C" fn probe_callback(
             let data = T::probe(pdev, info);
 
             pdev.as_ref().set_drvdata(data)?;
+
+            pdev.as_ref().mfd_add_devices(T::MFD_CELLS)?;
+
             Ok(0)
         })
     }
@@ -303,6 +307,9 @@ pub trait Driver: Send {
     /// The table of device ids supported by the driver.
     const ID_TABLE: IdTable<Self::IdInfo>;
 
+    /// The mfd cells for mfd devices.
+    const MFD_CELLS: Option<&'static [mfd::Cell]> = None;
+
     /// PCI driver probe.
     ///
     /// Called when a new pci device is added or discovered. Implementers should
diff --git a/rust/kernel/platform.rs b/rust/kernel/platform.rs
index 8917d4ee499f..e2bcf8ef093c 100644
--- a/rust/kernel/platform.rs
+++ b/rust/kernel/platform.rs
@@ -25,6 +25,7 @@
         self,
         IrqRequest, //
     },
+    mfd,
     of,
     prelude::*,
     types::Opaque,
@@ -104,6 +105,9 @@ extern "C" fn probe_callback(pdev: *mut bindings::platform_device) -> kernel::ff
             let data = T::probe(pdev, info);
 
             pdev.as_ref().set_drvdata(data)?;
+
+            pdev.as_ref().mfd_add_devices(T::MFD_CELLS)?;
+
             Ok(0)
         })
     }
@@ -218,6 +222,9 @@ pub trait Driver: Send {
     /// The table of ACPI device ids supported by the driver.
     const ACPI_ID_TABLE: Option<acpi::IdTable<Self::IdInfo>> = None;
 
+    /// The mfd cells for mfd devices.
+    const MFD_CELLS: Option<&'static [mfd::Cell]> = None;
+
     /// Platform driver probe.
     ///
     /// Called when a new platform device is added or discovered.
diff --git a/rust/kernel/serdev.rs b/rust/kernel/serdev.rs
index d9fea4bd4439..6e702c734ded 100644
--- a/rust/kernel/serdev.rs
+++ b/rust/kernel/serdev.rs
@@ -14,6 +14,7 @@
         to_result,
         VTABLE_DEFAULT_ERROR, //
     },
+    mfd,
     of,
     prelude::*,
     sync::Completion,
@@ -180,6 +181,8 @@ extern "C" fn probe_callback(sdev: *mut bindings::serdev_device) -> kernel::ffi:
 
             private_data.probe_complete.complete_all();
 
+            sdev.as_ref().mfd_add_devices(T::MFD_CELLS)?;
+
             result.map(|()| 0)
         })
     }
@@ -339,6 +342,9 @@ pub trait Driver: Send {
     /// The table of ACPI device ids supported by the driver.
     const ACPI_ID_TABLE: Option<acpi::IdTable<Self::IdInfo>> = None;
 
+    /// The mfd cells for mfd devices.
+    const MFD_CELLS: Option<&'static [mfd::Cell]> = None;
+
     /// Serial device bus device driver probe.
     ///
     /// Called when a new serial device bus device is added or discovered.
diff --git a/rust/kernel/usb.rs b/rust/kernel/usb.rs
index 0e1b9a88f4f1..a64ed6a530f1 100644
--- a/rust/kernel/usb.rs
+++ b/rust/kernel/usb.rs
@@ -17,6 +17,7 @@
         from_result,
         to_result, //
     },
+    mfd,
     prelude::*,
     types::{
         AlwaysRefCounted,
@@ -96,6 +97,9 @@ extern "C" fn probe_callback(
 
             let dev: &device::Device<device::CoreInternal> = intf.as_ref();
             dev.set_drvdata(data)?;
+
+            dev.mfd_add_devices(T::MFD_CELLS)?;
+
             Ok(0)
         })
     }
@@ -309,6 +313,9 @@ pub trait Driver {
     /// The table of device ids supported by the driver.
     const ID_TABLE: IdTable<Self::IdInfo>;
 
+    /// The mfd cells for mfd devices.
+    const MFD_CELLS: Option<&'static [mfd::Cell]> = None;
+
     /// USB driver probe.
     ///
     /// Called when a new USB interface is bound to this driver.

-- 
2.52.0

