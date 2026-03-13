From: Markus Probst <markus.probst@posteo.de>
Date: Fri, 13 Mar 2026 20:03:11 +0100
Subject: [PATCH v3 7/7] leds: add synology microp led driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260313-synology_microp_initial-v3-7-ad6ac463a201@posteo.de>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=11929;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=T1SW+a7NjbONWvSTUMQ0xLoz4Oyv2hqygRcc9ZCC+ZU=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBptF98zekI0a25/58vV5A6eVvauiqKTck4qWoj8
 EOrIJXbs9iJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCabRffBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9JWpQ/+MMLFUuexZCRkzzNVhWFcWjJFmlbHYtz
 evXkZs3grpliS1P2jSxdk21crtz39Kw2DmCGFvLJkiiDKi53Z0HnMklLRj2vbZ6wf8zHNAgOK1s
 zUWlotwm0XjA77baY/WSoH9Kwdx8Dhoa+Wyo8qxVGCGdQQduHuuIdCNlRrD/VplHp7o20QV9/u/
 Fe+wjZX6PYAlT/RhZ8DrZPN1iYev0rEP5w4ajZXU7m66qOrdKz6YjPuLflgaX/CSn0WpPfyuhxV
 XN1E2Y2YQruRjEhLtqifYnuDOrAim/rfZlch/EvFpQ0MLSqY/B2Sv+D3RAa6zr5V/Bcfi+mc67e
 pjDexD2ifn+Lz3m8VLuGg2Pvtln+BiNQ03DXp/PQxu5VX53LeMkBZtpVf7Vc4lrimfznhTf6iaj
 3Zlq7c6pa5ajkPXh84CdKvSzuxywVx3d8ZaN3rTEMmlyZtuocuBZKHAWIeuFcZ2fAmT3RyHs1kt
 rRdOEICPlryhhn9o4IpfGbQGExqAivOyDECgUzkwaByMrDENolvglxW0E7rsl56RqfeMNdkMlK8
 QBSxbqTdHyHo91OrHPyi2XptfDIV4N0BmlPHAWYb9lPuiGtIc9WCnKC7BI/EJucrOHlxtpDrG2o
 GpjiGlaB4QDHFrNqy/Ye/Q9HfgUcYjh6OHrG1IPkqG+qyTKVHKRE=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver to control the power, status, alert and usb LEDs on
Synology NAS devices. This will be bound to a mfd sub-device, registered
by the synology microp core driver.

Tested successfully on a Synology DS923+.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 MAINTAINERS                          |   1 +
 drivers/leds/Kconfig                 |  11 ++
 drivers/leds/Makefile                |   1 +
 drivers/leds/leds_synology_microp.rs | 303 +++++++++++++++++++++++++++++++++++
 4 files changed, 316 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 32932ecab9cf..1d9240055d29 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25544,6 +25544,7 @@ M:	Markus Probst <markus.probst@posteo.de>
 S:	Maintained
 F:	Documentation/devicetree/bindings/leds/synology,microp.yaml
 F:	Documentation/devicetree/bindings/mfd/synology,microp.yaml
+F:	drivers/leds/leds_synology_microp.rs
 F:	drivers/mfd/synology_microp.rs
 
 SYNOPSYS ARC ARCHITECTURE
diff --git a/drivers/leds/Kconfig b/drivers/leds/Kconfig
index 597d7a79c988..9a9609b924fe 100644
--- a/drivers/leds/Kconfig
+++ b/drivers/leds/Kconfig
@@ -1029,6 +1029,17 @@ config LEDS_ACER_A500
 	  This option enables support for the Power Button LED of
 	  Acer Iconia Tab A500.
 
+config LEDS_SYNOLOGY_MICROP
+	tristate "Synology Microp led driver"
+	depends on MFD_SYNOLOGY_MICROP
+	depends on RUST
+	depends on LEDS_CLASS && LEDS_CLASS_MULTICOLOR
+	help
+	  Enable support for the MCU found in Synology NAS devices.
+
+	  This is needed to control the power, status, alert and usb leds on the
+	  NAS device.
+
 source "drivers/leds/blink/Kconfig"
 
 comment "Flash and Torch LED drivers"
diff --git a/drivers/leds/Makefile b/drivers/leds/Makefile
index 8fdb45d5b439..200101eb26d5 100644
--- a/drivers/leds/Makefile
+++ b/drivers/leds/Makefile
@@ -89,6 +89,7 @@ obj-$(CONFIG_LEDS_SC27XX_BLTC)		+= leds-sc27xx-bltc.o
 obj-$(CONFIG_LEDS_ST1202)		+= leds-st1202.o
 obj-$(CONFIG_LEDS_SUN50I_A100)		+= leds-sun50i-a100.o
 obj-$(CONFIG_LEDS_SUNFIRE)		+= leds-sunfire.o
+obj-$(CONFIG_LEDS_SYNOLOGY_MICROP)	+= leds_synology_microp.o
 obj-$(CONFIG_LEDS_SYSCON)		+= leds-syscon.o
 obj-$(CONFIG_LEDS_TCA6507)		+= leds-tca6507.o
 obj-$(CONFIG_LEDS_TI_LMU_COMMON)	+= leds-ti-lmu-common.o
diff --git a/drivers/leds/leds_synology_microp.rs b/drivers/leds/leds_synology_microp.rs
new file mode 100644
index 000000000000..d2e94e992981
--- /dev/null
+++ b/drivers/leds/leds_synology_microp.rs
@@ -0,0 +1,303 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Synology Microp led driver
+
+use kernel::{
+    device::Bound,
+    devres::{self, Devres},
+    led::{
+        self,
+        LedOps,
+        MultiColorSubLed, //
+    },
+    new_mutex,
+    platform,
+    prelude::*,
+    serdev,
+    sync::Mutex, //
+};
+use pin_init::pin_init_scope;
+
+kernel::module_platform_driver! {
+    type: SynologyMicropLedDriver,
+    name: "synology_microp_leds",
+    authors: ["Markus Probst <markus.probst@posteo.de>"],
+    description: "Synology Microp led driver",
+    license: "GPL v2",
+}
+
+#[pin_data]
+struct SynologyMicropLedDriver {
+    #[pin]
+    status: Devres<led::MultiColorDevice<StatusLedHandler>>,
+    #[pin]
+    power: Devres<led::Device<LedHandler>>,
+}
+
+impl platform::Driver for SynologyMicropLedDriver {
+    type IdInfo = ();
+
+    fn probe(
+        dev: &platform::Device<kernel::device::Core>,
+        _id_info: Option<&Self::IdInfo>,
+    ) -> impl PinInit<Self, Error> {
+        pin_init_scope(move || {
+            let fwnode = dev.as_ref().fwnode().ok_or(EINVAL)?;
+
+            if let Some(alert_fwnode) = fwnode.get_child_by_name(c"alert-led") {
+                devres::register(
+                    dev.as_ref(),
+                    led::DeviceBuilder::new()
+                        .fwnode(Some(alert_fwnode))
+                        .devicename(c"synology-microp/alert-led")
+                        .color(led::Color::Orange)
+                        .build(
+                            &**dev,
+                            try_pin_init!(LedHandler {
+                                blink <- new_mutex!(false),
+                                command: Command::Alert,
+                            }),
+                        ),
+                    GFP_KERNEL,
+                )?;
+            }
+
+            if let Some(alert_fwnode) = fwnode.get_child_by_name(c"usb-led") {
+                devres::register(
+                    dev.as_ref(),
+                    led::DeviceBuilder::new()
+                        .fwnode(Some(alert_fwnode))
+                        .devicename(c"synology-microp/usb-led")
+                        .color(led::Color::Green)
+                        .build(
+                            &**dev,
+                            try_pin_init!(LedHandler {
+                                blink <- new_mutex!(false),
+                                command: Command::Usb,
+                            }),
+                        ),
+                    GFP_KERNEL,
+                )?;
+            }
+
+            Ok(try_pin_init!(Self {
+                status <- led::DeviceBuilder::new()
+                    .fwnode(Some(fwnode.get_child_by_name(c"status-led").ok_or(EINVAL)?))
+                    .devicename(c"synology-microp/status-led")
+                    .color(led::Color::Multi)
+                    .build_multicolor(
+                        &**dev,
+                        try_pin_init!(StatusLedHandler {
+                            blink <- new_mutex!(false),
+                        }),
+                        StatusLedHandler::SUBLEDS,
+                    ),
+                power <- led::DeviceBuilder::new()
+                    .fwnode(Some(fwnode.get_child_by_name(c"power-led").ok_or(EINVAL)?))
+                    .devicename(c"synology-microp/power-led")
+                    .color(led::Color::Blue)
+                    .default_trigger(c"timer")
+                    .build(
+                        &**dev,
+                        try_pin_init!(LedHandler {
+                            blink <- new_mutex!(true),
+                            command: Command::Power,
+                        }),
+                    ),
+            }))
+        })
+    }
+}
+
+enum StatusLedColor {
+    Green,
+    Orange,
+}
+
+enum State {
+    On,
+    Blink,
+    Off,
+}
+
+enum Command {
+    Power(State),
+    Status(StatusLedColor, State),
+    Alert(State),
+    Usb(State),
+}
+
+impl Command {
+    fn write(self, dev: &platform::Device<Bound>) -> Result {
+        // SAFETY: Since we have no of and no acpi match table, we assume this is a mfd sub-device
+        // and our parent is a serial device bus device, bound to the synology microp core driver.
+        let parent = unsafe { dev.as_ref().parent_unchecked::<serdev::Device<Bound>>() };
+        parent.write_all(
+            match self {
+                Self::Power(State::On) => &[0x34],
+                Self::Power(State::Blink) => &[0x35],
+                Self::Power(State::Off) => &[0x36],
+
+                Self::Status(_, State::Off) => &[0x37],
+                Self::Status(StatusLedColor::Green, State::On) => &[0x38],
+                Self::Status(StatusLedColor::Green, State::Blink) => &[0x39],
+                Self::Status(StatusLedColor::Orange, State::On) => &[0x3A],
+                Self::Status(StatusLedColor::Orange, State::Blink) => &[0x3B],
+
+                Self::Alert(State::On) => &[0x4C, 0x41, 0x31],
+                Self::Alert(State::Blink) => &[0x4C, 0x41, 0x32],
+                Self::Alert(State::Off) => &[0x4C, 0x41, 0x33],
+
+                Self::Usb(State::On) => &[0x40],
+                Self::Usb(State::Blink) => &[0x41],
+                Self::Usb(State::Off) => &[0x42],
+            },
+            serdev::Timeout::Max,
+        )?;
+        Ok(())
+    }
+}
+
+#[pin_data]
+struct LedHandler {
+    #[pin]
+    blink: Mutex<bool>,
+    command: fn(State) -> Command,
+}
+
+#[vtable]
+impl LedOps for LedHandler {
+    type Bus = platform::Device<Bound>;
+    type Mode = led::Normal;
+    const BLOCKING: bool = true;
+    const MAX_BRIGHTNESS: u32 = 1;
+
+    fn brightness_set(
+        &self,
+        dev: &Self::Bus,
+        _classdev: &led::Device<Self>,
+        brightness: u32,
+    ) -> Result<()> {
+        let mut blink = self.blink.lock();
+        (self.command)(if brightness == 0 {
+            *blink = false;
+            State::Off
+        } else if *blink {
+            State::Blink
+        } else {
+            State::On
+        })
+        .write(dev)?;
+
+        Ok(())
+    }
+
+    fn blink_set(
+        &self,
+        dev: &Self::Bus,
+        _classdev: &led::Device<Self>,
+        delay_on: &mut usize,
+        delay_off: &mut usize,
+    ) -> Result<()> {
+        let mut blink = self.blink.lock();
+
+        (self.command)(if *delay_on == 0 && *delay_off != 0 {
+            State::Off
+        } else if *delay_on != 0 && *delay_off == 0 {
+            State::On
+        } else {
+            *blink = true;
+            *delay_on = 167;
+            *delay_off = 167;
+
+            State::Blink
+        })
+        .write(dev)
+    }
+}
+
+#[pin_data]
+struct StatusLedHandler {
+    #[pin]
+    blink: Mutex<bool>,
+}
+
+impl StatusLedHandler {
+    const SUBLEDS: &[MultiColorSubLed] = &[
+        MultiColorSubLed::new(led::Color::Green).initial_intensity(1),
+        MultiColorSubLed::new(led::Color::Orange),
+    ];
+}
+
+#[vtable]
+impl LedOps for StatusLedHandler {
+    type Bus = platform::Device<Bound>;
+    type Mode = led::MultiColor;
+    const BLOCKING: bool = true;
+    const MAX_BRIGHTNESS: u32 = 1;
+
+    fn brightness_set(
+        &self,
+        dev: &Self::Bus,
+        classdev: &led::MultiColorDevice<Self>,
+        brightness: u32,
+    ) -> Result<()> {
+        let mut blink = self.blink.lock();
+        if brightness == 0 {
+            *blink = false;
+        }
+
+        let (color, subled_brightness) = if classdev.subleds()[1].intensity == 0 {
+            (StatusLedColor::Green, classdev.subleds()[0].brightness)
+        } else {
+            (StatusLedColor::Orange, classdev.subleds()[1].brightness)
+        };
+
+        Command::Status(
+            color,
+            if subled_brightness == 0 {
+                State::Off
+            } else if *blink {
+                State::Blink
+            } else {
+                State::On
+            },
+        )
+        .write(dev)
+    }
+
+    fn blink_set(
+        &self,
+        dev: &Self::Bus,
+        classdev: &led::MultiColorDevice<Self>,
+        delay_on: &mut usize,
+        delay_off: &mut usize,
+    ) -> Result<()> {
+        let mut blink = self.blink.lock();
+        *blink = true;
+
+        let (color, subled_intensity) = if classdev.subleds()[1].intensity == 0 {
+            (StatusLedColor::Green, classdev.subleds()[0].intensity)
+        } else {
+            (StatusLedColor::Orange, classdev.subleds()[1].intensity)
+        };
+        Command::Status(
+            color,
+            if *delay_on == 0 && *delay_off != 0 {
+                *blink = false;
+                State::Off
+            } else if subled_intensity == 0 {
+                State::Off
+            } else if *delay_on != 0 && *delay_off == 0 {
+                *blink = false;
+                State::On
+            } else {
+                *delay_on = 167;
+                *delay_off = 167;
+
+                State::Blink
+            },
+        )
+        .write(dev)
+    }
+}

-- 
2.52.0

