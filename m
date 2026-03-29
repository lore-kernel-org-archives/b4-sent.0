From: Markus Probst <markus.probst@posteo.de>
Date: Sun, 29 Mar 2026 20:02:18 +0200
Subject: [PATCH v5 4/4] platform: Add initial synology microp driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260329-synology_microp_initial-v5-4-27cb80bdf591@posteo.de>
References: <20260329-synology_microp_initial-v5-0-27cb80bdf591@posteo.de>
In-Reply-To: <20260329-synology_microp_initial-v5-0-27cb80bdf591@posteo.de>
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Saravana Kannan <saravanak@kernel.org>
Cc: platform-driver-x86@vger.kernel.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-acpi@vger.kernel.org, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=20314;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=yrzjZbZgwaJ2bp4M2Fjq+W1D7x0HPjApLfr85u17qBg=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBpyWk9BO5iJDlwUL2Yn3JUsufOSJeCw/uvs9A1D
 /bhkBKvZ0WJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCaclpPRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9JgKhAAkHvqRfb6r3jvhGFlV89rvBLDCjVTL/l
 J8KINrZLjzuMxj+c0ZoZMcWR0i9Nkx2EtjyaYnSEqJabbpoE2FyzRRsV/2T6gyCMaBz2/AwAL/W
 rbovlhFR1jScibAQTji6ekDceeAJKNxhj7/QrADbQsoPYEcEk74v1naMEmwNn+DlIh+xNqJd/pm
 C+0Oee00GbiO7l+svtQ4tI9/LV7hiQL2q3ABMAlobIr96K9oIZfNlUZGzXHJUmNajgiGcQ2RyFX
 UdzjSYuTHy4anAy8qFWIJHfdQfyUbknC74EWgkCzfDTab3Ep1uRQ4Vps0+ckSK5IaB4EHomlmtm
 XUSdcwYhsAJKOq4o+cHk4EynK1DbwWyfO6UFUm9EufgFBIqOF/xB9BvL/KsGEbAjrfZZHEAHxv/
 vxD70rSWwP1YEgQZKusOnj/RJDmKJvfHZ7FDpwyGkgxniQxOqI9iSMK/xXVjF6SYaw+P91YsffT
 qBqTiTTHQUaCcn9Kyu4Ck04W6s4NmdNVyaQGopx/0caiFvTK3RP24BgrJ5985lFbon74gqcUMMV
 xabGTwUYiOu35KKN0gXJdPy41astzLBBkS0UPN0za/MPtp9ZqBaADa9eXTDpODPAoGrapFerW8C
 VBNj5z/eGfa5w5xSLyIVj+FcKHQDW63osYPmBxR/i7wux87YixX0=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a initial synology microp driver, written in Rust.
The driver targets a microcontroller found in Synology NAS devices. It
currently only supports controlling of the power led, status led, alert
led and usb led. Other components such as fan control or handling
on-device buttons will be added once the required rust abstractions are
there.

This driver can be used both on arm and x86, thus it goes into the root
directory of drivers/platform.

Tested successfully on a Synology DS923+.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 MAINTAINERS                                        |   6 +
 drivers/platform/Kconfig                           |   2 +
 drivers/platform/Makefile                          |   1 +
 drivers/platform/synology_microp/Kconfig           |  13 +
 drivers/platform/synology_microp/Makefile          |   3 +
 drivers/platform/synology_microp/TODO              |   7 +
 drivers/platform/synology_microp/command.rs        |  55 ++++
 drivers/platform/synology_microp/led.rs            | 276 +++++++++++++++++++++
 drivers/platform/synology_microp/model.rs          | 171 +++++++++++++
 .../platform/synology_microp/synology_microp.rs    |  54 ++++
 10 files changed, 588 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 83b5a45de729..24cc4f63cce6 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25544,6 +25544,12 @@ F:	drivers/dma-buf/sync_*
 F:	include/linux/sync_file.h
 F:	include/uapi/linux/sync_file.h
 
+SYNOLOGY MICROP DRIVER
+M:	Markus Probst <markus.probst@posteo.de>
+S:	Maintained
+F:	Documentation/devicetree/bindings/embedded-controller/synology,ds923p-microp.yaml
+F:	drivers/platform/synology_microp/
+
 SYNOPSYS ARC ARCHITECTURE
 M:	Vineet Gupta <vgupta@kernel.org>
 L:	linux-snps-arc@lists.infradead.org
diff --git a/drivers/platform/Kconfig b/drivers/platform/Kconfig
index 312788f249c9..996050566a4a 100644
--- a/drivers/platform/Kconfig
+++ b/drivers/platform/Kconfig
@@ -22,3 +22,5 @@ source "drivers/platform/arm64/Kconfig"
 source "drivers/platform/raspberrypi/Kconfig"
 
 source "drivers/platform/wmi/Kconfig"
+
+source "drivers/platform/synology_microp/Kconfig"
diff --git a/drivers/platform/Makefile b/drivers/platform/Makefile
index fa322e7f8716..2381872e9133 100644
--- a/drivers/platform/Makefile
+++ b/drivers/platform/Makefile
@@ -15,3 +15,4 @@ obj-$(CONFIG_SURFACE_PLATFORMS)	+= surface/
 obj-$(CONFIG_ARM64_PLATFORM_DEVICES)	+= arm64/
 obj-$(CONFIG_BCM2835_VCHIQ)	+= raspberrypi/
 obj-$(CONFIG_ACPI_WMI)		+= wmi/
+obj-$(CONFIG_SYNOLOGY_MICROP)	+= synology_microp/
diff --git a/drivers/platform/synology_microp/Kconfig b/drivers/platform/synology_microp/Kconfig
new file mode 100644
index 000000000000..0c145a5b7174
--- /dev/null
+++ b/drivers/platform/synology_microp/Kconfig
@@ -0,0 +1,13 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+config SYNOLOGY_MICROP
+	tristate "Synology Microp driver"
+	depends on LEDS_CLASS && LEDS_CLASS_MULTICOLOR
+	depends on RUST_SERIAL_DEV_BUS_ABSTRACTIONS
+	help
+	  Enable support for the MCU found in Synology NAS devices.
+
+	  This is needed to properly shutdown and reboot the device, as well as
+	  additional functionality like fan and LED control.
+
+	  This driver is work in progress and may not be fully functional.
diff --git a/drivers/platform/synology_microp/Makefile b/drivers/platform/synology_microp/Makefile
new file mode 100644
index 000000000000..63585ccf76e4
--- /dev/null
+++ b/drivers/platform/synology_microp/Makefile
@@ -0,0 +1,3 @@
+# SPDX-License-Identifier: GPL-2.0
+
+obj-y += synology_microp.o
diff --git a/drivers/platform/synology_microp/TODO b/drivers/platform/synology_microp/TODO
new file mode 100644
index 000000000000..1961a33115db
--- /dev/null
+++ b/drivers/platform/synology_microp/TODO
@@ -0,0 +1,7 @@
+TODO:
+- add missing components:
+  - handle on-device buttons (Power, Factory reset, "USB Copy")
+  - handle fan failure
+  - beeper
+  - fan speed control
+  - correctly perform device power-off and restart on Synology devices
diff --git a/drivers/platform/synology_microp/command.rs b/drivers/platform/synology_microp/command.rs
new file mode 100644
index 000000000000..5b3dd715afac
--- /dev/null
+++ b/drivers/platform/synology_microp/command.rs
@@ -0,0 +1,55 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use kernel::{
+    device::Bound,
+    error::Result,
+    serdev, //
+};
+
+use crate::led;
+
+#[derive(Copy, Clone)]
+#[expect(
+    clippy::enum_variant_names,
+    reason = "future variants will not end with Led"
+)]
+pub(crate) enum Command {
+    PowerLed(led::State),
+    StatusLed(led::StatusLedColor, led::State),
+    AlertLed(led::State),
+    UsbLed(led::State),
+    EsataLed(led::State),
+}
+
+impl Command {
+    pub(crate) fn write(self, dev: &serdev::Device<Bound>) -> Result {
+        dev.write_all(
+            match self {
+                Self::PowerLed(led::State::On) => &[0x34],
+                Self::PowerLed(led::State::Blink) => &[0x35],
+                Self::PowerLed(led::State::Off) => &[0x36],
+
+                Self::StatusLed(_, led::State::Off) => &[0x37],
+                Self::StatusLed(led::StatusLedColor::Green, led::State::On) => &[0x38],
+                Self::StatusLed(led::StatusLedColor::Green, led::State::Blink) => &[0x39],
+                Self::StatusLed(led::StatusLedColor::Orange, led::State::On) => &[0x3A],
+                Self::StatusLed(led::StatusLedColor::Orange, led::State::Blink) => &[0x3B],
+
+                Self::AlertLed(led::State::On) => &[0x4C, 0x41, 0x31],
+                Self::AlertLed(led::State::Blink) => &[0x4C, 0x41, 0x32],
+                Self::AlertLed(led::State::Off) => &[0x4C, 0x41, 0x33],
+
+                Self::UsbLed(led::State::On) => &[0x40],
+                Self::UsbLed(led::State::Blink) => &[0x41],
+                Self::UsbLed(led::State::Off) => &[0x42],
+
+                Self::EsataLed(led::State::On) => &[0x4C, 0x45, 0x31],
+                Self::EsataLed(led::State::Blink) => &[0x4C, 0x45, 0x32],
+                Self::EsataLed(led::State::Off) => &[0x4C, 0x45, 0x33],
+            },
+            serdev::Timeout::Max,
+        )?;
+        dev.wait_until_sent(serdev::Timeout::Max);
+        Ok(())
+    }
+}
diff --git a/drivers/platform/synology_microp/led.rs b/drivers/platform/synology_microp/led.rs
new file mode 100644
index 000000000000..a78a95588456
--- /dev/null
+++ b/drivers/platform/synology_microp/led.rs
@@ -0,0 +1,276 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use kernel::{
+    device::Bound,
+    devres::{
+        self,
+        Devres, //
+    },
+    led::{
+        self,
+        LedOps,
+        MultiColorSubLed, //
+    },
+    new_mutex,
+    prelude::*,
+    serdev,
+    str::CString,
+    sync::Mutex, //
+};
+use pin_init::pin_init_scope;
+
+use crate::{
+    command::Command,
+    model::Model, //
+};
+
+#[pin_data]
+pub(crate) struct Data {
+    #[pin]
+    status: Devres<led::MultiColorDevice<StatusLedHandler>>,
+    power_name: CString,
+    #[pin]
+    power: Devres<led::Device<LedHandler>>,
+}
+
+impl Data {
+    pub(super) fn register<'a>(
+        dev: &'a serdev::Device<Bound>,
+        model: &'a Model,
+    ) -> impl PinInit<Self, Error> + 'a {
+        pin_init_scope(move || {
+            if let Some(color) = model.led_alert {
+                let name = CString::try_from_fmt(fmt!("{}:alarm", color.as_c_str().to_str()?))?;
+                devres::register(
+                    dev.as_ref(),
+                    led::DeviceBuilder::new().color(color).name(&name).build(
+                        dev,
+                        try_pin_init!(LedHandler {
+                            blink <- new_mutex!(false),
+                            command: Command::AlertLed,
+                        }),
+                    ),
+                    GFP_KERNEL,
+                )?;
+            }
+
+            if model.led_usb_copy {
+                devres::register(
+                    dev.as_ref(),
+                    led::DeviceBuilder::new()
+                        .color(led::Color::Green)
+                        .name(c"green:usb")
+                        .build(
+                            dev,
+                            try_pin_init!(LedHandler {
+                                blink <- new_mutex!(false),
+                                command: Command::UsbLed,
+                            }),
+                        ),
+                    GFP_KERNEL,
+                )?;
+            }
+
+            if model.led_esata {
+                devres::register(
+                    dev.as_ref(),
+                    led::DeviceBuilder::new()
+                        .color(led::Color::Green)
+                        .name(c"green:esata")
+                        .build(
+                            dev,
+                            try_pin_init!(LedHandler {
+                                blink <- new_mutex!(false),
+                                command: Command::EsataLed,
+                            }),
+                        ),
+                    GFP_KERNEL,
+                )?;
+            }
+
+            Ok(try_pin_init!(Self {
+                status <- led::DeviceBuilder::new()
+                    .color(led::Color::Multi)
+                    .name(c"multicolor:status")
+                    .build_multicolor(
+                        dev,
+                        try_pin_init!(StatusLedHandler {
+                            blink <- new_mutex!(false),
+                        }),
+                        StatusLedHandler::SUBLEDS,
+                    ),
+                power_name: CString::try_from_fmt(fmt!(
+                    "{}:power",
+                    model.led_power.as_c_str().to_str()?
+                ))?,
+                power <- led::DeviceBuilder::new()
+                    .color(model.led_power)
+                    .name(power_name)
+                    .build(
+                        dev,
+                        try_pin_init!(LedHandler {
+                            blink <- new_mutex!(true),
+                            command: Command::PowerLed,
+                        }),
+                    ),
+            }))
+        })
+    }
+}
+
+#[derive(Copy, Clone)]
+pub(crate) enum StatusLedColor {
+    Green,
+    Orange,
+}
+
+#[derive(Copy, Clone)]
+pub(crate) enum State {
+    On,
+    Blink,
+    Off,
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
+    type Bus = serdev::Device<Bound>;
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
+    type Bus = serdev::Device<Bound>;
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
+        Command::StatusLed(
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
+        Command::StatusLed(
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
diff --git a/drivers/platform/synology_microp/model.rs b/drivers/platform/synology_microp/model.rs
new file mode 100644
index 000000000000..b972aae2b805
--- /dev/null
+++ b/drivers/platform/synology_microp/model.rs
@@ -0,0 +1,171 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use kernel::{
+    led::{
+        self,
+        Color, //
+    },
+    of::DeviceId, //
+};
+
+pub(crate) struct Architecture;
+
+impl Architecture {
+    const fn new() -> Self {
+        Self
+    }
+}
+
+pub(crate) struct Model {
+    #[expect(
+        dead_code,
+        reason = "needed later for architecture specific properties, like poweroff behaviour"
+    )]
+    pub(crate) arch: Architecture,
+    pub(crate) led_power: led::Color,
+    pub(crate) led_alert: Option<led::Color>,
+    pub(crate) led_usb_copy: bool,
+    pub(crate) led_esata: bool,
+}
+
+impl Model {
+    const fn new(arch: Architecture) -> Self {
+        Self {
+            arch,
+            led_power: led::Color::Blue,
+            led_alert: None,
+            led_usb_copy: false,
+            led_esata: false,
+        }
+    }
+
+    const fn led_power(self, color: led::Color) -> Self {
+        Self {
+            led_power: color,
+            ..self
+        }
+    }
+
+    const fn led_alert(self, color: led::Color) -> Self {
+        Self {
+            led_alert: Some(color),
+            ..self
+        }
+    }
+
+    const fn led_esata(self) -> Self {
+        Self {
+            led_esata: true,
+            ..self
+        }
+    }
+
+    const fn led_usb_copy(self) -> Self {
+        Self {
+            led_usb_copy: true,
+            ..self
+        }
+    }
+}
+
+macro_rules! models {
+    [
+        $($arch:ident $(.$arch_func:ident( $($arch_arg:tt)* ))*
+            @ [
+                $($model:ident $(.$func:ident( $($arg:tt)* ))*, )*
+            ],
+        )*
+    ] => {
+        models![
+            $(
+                {
+                    Architecture::new()
+                    $(
+                        .$arch_func($($arch_arg)*)
+                    )*
+                }
+                @
+                [
+                    $(
+                        $model $(.$func($($arg)*))*,
+                    )*
+                ],
+            )*
+        ]
+    };
+    [
+        $($arch:block
+            @ [
+                $($model:ident $(.$func:ident( $($arg:tt)* ))*, )*
+            ],
+        )*
+    ] => {
+        [
+            $(
+                $((
+                    DeviceId::new(::kernel::c_str!(
+                        ::core::concat!(
+                            "synology,",
+                            ::core::stringify!($model),
+                            "-microp",
+                        )
+                    )),
+                    Model::new($arch)
+                    $(
+                        .$func($($arg)*)
+                    )*
+                ),)*
+            )*
+        ]
+    };
+}
+
+kernel::of_device_table!(
+    pub(crate) OF_TABLE,
+    MODULE_OF_TABLE,
+    Model,
+    models![
+        apollolake @ [
+            ds918p,
+        ],
+        evansport @ [
+            ds214play,
+        ],
+        geminilakenk @ [
+            ds225p.led_usb_copy(),
+            ds425p,
+        ],
+        pineview @ [
+            ds710p.led_esata(),
+            ds1010p.led_alert(Color::Orange),
+        ],
+        r1000 @ [
+            ds923p,
+            ds723p,
+            ds1522p,
+            rs422p.led_power(Color::Green),
+        ],
+        r1000nk @ [
+            ds725p,
+        ],
+        rtd1296 @ [
+            ds118,
+        ],
+        rtd1619b @ [
+            ds124,
+            ds223.led_usb_copy(),
+            ds223j,
+        ],
+        v1000 @ [
+            ds1823xsp,
+            rs822p.led_power(Color::Green),
+            rs1221p.led_power(Color::Green),
+            rs1221rpp.led_power(Color::Green),
+        ],
+        v1000nk @ [
+            ds925p,
+            ds1525p,
+            ds1825p,
+        ],
+    ]
+);
diff --git a/drivers/platform/synology_microp/synology_microp.rs b/drivers/platform/synology_microp/synology_microp.rs
new file mode 100644
index 000000000000..51152cc14b1e
--- /dev/null
+++ b/drivers/platform/synology_microp/synology_microp.rs
@@ -0,0 +1,54 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Synology Microp driver
+
+use kernel::{
+    device,
+    of,
+    prelude::*,
+    serdev, //
+};
+use pin_init::pin_init_scope;
+
+use crate::model::Model;
+
+pub(crate) mod command;
+mod led;
+mod model;
+
+kernel::module_serdev_device_driver! {
+    type: SynologyMicropDriver,
+    name: "synology_microp",
+    authors: ["Markus Probst <markus.probst@posteo.de>"],
+    description: "Synology Microp driver",
+    license: "GPL v2",
+}
+
+#[pin_data]
+struct SynologyMicropDriver {
+    #[pin]
+    led: led::Data,
+}
+
+#[vtable]
+impl serdev::Driver for SynologyMicropDriver {
+    type IdInfo = Model;
+    const OF_ID_TABLE: Option<of::IdTable<Self::IdInfo>> = Some(&model::OF_TABLE);
+
+    fn probe(
+        dev: &serdev::Device<device::Core>,
+        model: Option<&Model>,
+    ) -> impl PinInit<Self, kernel::error::Error> {
+        pin_init_scope(move || {
+            let model = model.ok_or(EINVAL)?;
+
+            dev.set_baudrate(9600).map_err(|_| EINVAL)?;
+            dev.set_flow_control(false);
+            dev.set_parity(serdev::Parity::None)?;
+
+            Ok(try_pin_init!(Self {
+                led <- led::Data::register(dev, model),
+            }))
+        })
+    }
+}

-- 
2.52.0

