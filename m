From: Nick Dowsett <nick42d@gmail.com>
Date: Sun, 22 Nov 2026 12:35:38 +0800
Subject: [PATCH 1/4] platform/x86: clevo-laptop: add minimal WMI driver
 skeleton and Kbuild plumbing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-clevo-laptop-v1-1-881debf4d4b0@gmail.com>
References: <20261122-clevo-laptop-v1-0-881debf4d4b0@gmail.com>
In-Reply-To: <20261122-clevo-laptop-v1-0-881debf4d4b0@gmail.com>
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: Armin Wolf <W_Armin@gmx.de>, Werner Sembach <wse@tuxedocomputers.com>, 
 linux-kernel@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, Nick Dowsett <nick42d@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795322140; l=4849;
 i=nick42d@gmail.com; h=from:subject:message-id;
 bh=e9AdSz41EP3ywu8H4Pe835LANDmSykHvhG+wsu9VTm0=;
 b=anPBWXAgeDelXVKsG1nyDfq5seJYrlBDPkqh3KwKnpA+NHh8NhWsZkOp8Ma8DT8s/zy84t9RA
 rOGeCqw3QfpCihA5a8gVD9q+r1aJgvG9SSAbJGB4mhukqD3/VjtEWSA
X-Developer-Key: i=nick42d@gmail.com; a=ed25519;
 pk=1uIkNexEofzEXNN3Y3QW5z8IrgjWaP0yH6Es51jxWOg=
X-Endpoint-Received: by B4 Relay for nick42d@gmail.com/default with auth_id=1596
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Add `drivers/platform/x86/clevo-laptop.rs` with module implementation,
  DMI board check, and Driver registration.
- Add Kconfig and MAINTAINERS entries and Makefile wiring.

Signed-off-by: Nick Dowsett <nick42d@gmail.com>
---
 MAINTAINERS                          |  6 +++
 drivers/platform/x86/Kconfig         | 17 +++++++++
 drivers/platform/x86/Makefile        |  3 ++
 drivers/platform/x86/clevo-laptop.rs | 72 ++++++++++++++++++++++++++++++++++++
 4 files changed, 98 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 44540a1eb2b8..1130c293e84d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -6566,6 +6566,12 @@ F:	scripts/Makefile.clang
 F:	scripts/clang-tools/
 K:	\b(?i:clang|llvm)\b
 
+CLEVO LAPTOP DRIVER
+M:	Nick Dowsett <nick42d@gmail.com>
+L:	platform-driver-x86@vger.kernel.org
+S:	Maintained
+F:	drivers/platform/x86/clevo-laptop.rs
+
 CLK API
 M:	Russell King <linux@armlinux.org.uk>
 L:	linux-clk@vger.kernel.org
diff --git a/drivers/platform/x86/Kconfig b/drivers/platform/x86/Kconfig
index 9ce384e0475e..18aa4550c9f4 100644
--- a/drivers/platform/x86/Kconfig
+++ b/drivers/platform/x86/Kconfig
@@ -1059,6 +1059,23 @@ config OXP_EC
 
 source "drivers/platform/x86/tuxedo/Kconfig"
 
+config CLEVO_LAPTOP
+	tristate "Clevo Laptop Platform Driver"
+	depends on RUST
+	depends on ACPI_WMI=y
+	depends on DMI
+	depends on LEDS_CLASS
+	help
+	  This driver provides platform support for Clevo barebones and
+	  rebranded laptops (Tuxedo, Metabox, Sager, XMG, etc.).
+	  Currently only Clevo NLx0AU boards (e.g. Metabox Edge NL57AU)
+	  with a 5-step white keyboard backlight are supported over WMI.
+	  It is intended to be extended with additional Clevo models and
+	  EC features over time.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called clevo-laptop.
+
 endif # X86_PLATFORM_DEVICES
 
 config P2SB
diff --git a/drivers/platform/x86/Makefile b/drivers/platform/x86/Makefile
index 229057234d00..070af05a2064 100644
--- a/drivers/platform/x86/Makefile
+++ b/drivers/platform/x86/Makefile
@@ -158,6 +158,9 @@ obj-$(CONFIG_SILICOM_PLATFORM)		+= silicom-platform.o
 # TUXEDO
 obj-y					+= tuxedo/
 
+# Clevo
+obj-$(CONFIG_CLEVO_LAPTOP)		+= clevo-laptop.o
+
 # Winmate
 obj-$(CONFIG_WINMATE_FM07_KEYS)		+= winmate-fm07-keys.o
 
diff --git a/drivers/platform/x86/clevo-laptop.rs b/drivers/platform/x86/clevo-laptop.rs
new file mode 100644
index 000000000000..1d862c57b3fe
--- /dev/null
+++ b/drivers/platform/x86/clevo-laptop.rs
@@ -0,0 +1,72 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Clevo Laptop Driver.
+//!
+//! Currently supports only the 5-step white keyboard backlight on Clevo
+//! NLx0AU boards (e.g., Metabox Edge NL57AU).
+//!
+//! Copyright (C) 2026 Nick Dowsett <nick42d@gmail.com>.
+//!
+//! Inspired by Tuxedo Computers' drivers.
+
+use kernel::{
+    device,
+    dmi,
+    prelude::*,
+    wmi, //
+};
+
+/// # Note
+///
+/// This GUID is non-unique (shared by Uniwill for example) and cannot be trusted
+/// to uniquely identify a Clevo device.
+const CLEVO_WMI_METHOD_GUID: &CStr = c"ABBC0F6D-8EA1-11D1-00A0-C90629100000";
+/// DMI board name allowlist, restricted to tested boards since the WMI GUID is not
+/// unique.
+const SUPPORTED_BOARDS: &[&CStr] = &[c"NLx0AU"];
+
+module! {
+    type: ClevoLaptopModule,
+    name: "clevo-laptop",
+    authors: ["Nick Dowsett <nick42d@gmail.com>"],
+    description: "Clevo Laptop Driver (Keyboard Backlight)",
+    license: "GPL",
+}
+
+/// RAII guard for Clevo Laptop Module holding all subsystem drivers e.g WMI.
+#[pin_data]
+struct ClevoLaptopModule {
+    #[pin]
+    _wmi_driver: wmi::Registration<WmiDriver>,
+}
+
+impl kernel::InPlaceModule for ClevoLaptopModule {
+    fn init(module: &'static ThisModule) -> impl PinInit<Self, Error> {
+        pin_init::pin_init_scope(move || {
+            if dmi::get_system_info(dmi::Field::BoardName)
+                .is_none_or(|board| !SUPPORTED_BOARDS.contains(&board))
+            {
+                return Err(ENODEV);
+            }
+            Ok(try_pin_init!(Self {
+                _wmi_driver <- wmi::Registration::new(c"clevo-laptop", module),
+            }))
+        })
+    }
+}
+
+/// RAII guard for Clevo WMI driver holding all subsystem devices e.g LED device.
+#[pin_data]
+struct WmiDriver {}
+
+kernel::wmi_device_table!(WMI_TABLE, [wmi::DeviceId::new(CLEVO_WMI_METHOD_GUID)]);
+
+impl wmi::Driver for WmiDriver {
+    type Data<'bound> = WmiDriver;
+    const ID_TABLE: wmi::IdTable = &WMI_TABLE;
+    fn probe<'bound>(
+        _dev: &'bound wmi::Device<device::Core<'_>>,
+    ) -> impl PinInit<Self::Data<'bound>, Error> + 'bound {
+        try_pin_init!(WmiDriver {})
+    }
+}

-- 
2.56.1

