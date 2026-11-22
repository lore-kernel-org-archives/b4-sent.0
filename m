From: Nick Dowsett <nick42d@gmail.com>
Date: Sun, 22 Nov 2026 12:35:41 +0800
Subject: [PATCH 4/4] platform/x86: clevo-laptop: register 5-step white
 keyboard backlight LED device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-clevo-laptop-v1-4-881debf4d4b0@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795322140; l=5814;
 i=nick42d@gmail.com; h=from:subject:message-id;
 bh=w57T94ShI0LShB2wRkuNbPlY4Amo9JRyqK2KuAoMqHs=;
 b=DKQ/TUsRuX2U3+TE48LKKw1KN+3UVUItfycAQrEs8Oltw7SsALlGlZo28PWc58J8UxbMamZ9j
 bR2yvY1GiytAwRQVKkLV3MSX3ZotBxc618ab7aPfD26+hGl3zrbmtTY
X-Developer-Key: i=nick42d@gmail.com; a=ed25519;
 pk=1uIkNexEofzEXNN3Y3QW5z8IrgjWaP0yH6Es51jxWOg=
X-Endpoint-Received: by B4 Relay for nick42d@gmail.com/default with auth_id=1596
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Add `SetWhiteBrightness` EC command and `Brightness` wrapper.
- Implement `LedOps` (`FixedColorLedOperations`) and register a
  `white:kbd_backlight` LED class device during WMI probe.

Signed-off-by: Nick Dowsett <nick42d@gmail.com>
---
 drivers/platform/x86/clevo-laptop.rs | 100 +++++++++++++++++++++++++++++++++--
 1 file changed, 95 insertions(+), 5 deletions(-)

diff --git a/drivers/platform/x86/clevo-laptop.rs b/drivers/platform/x86/clevo-laptop.rs
index 6f08bf295c07..0a9cb96e7811 100644
--- a/drivers/platform/x86/clevo-laptop.rs
+++ b/drivers/platform/x86/clevo-laptop.rs
@@ -10,8 +10,14 @@
 //! Inspired by Tuxedo Computers' drivers.
 
 use kernel::{
+    self,
     device,
     dmi,
+    led::{
+        self,
+        LedOps,
+        Normal, //
+    },
     prelude::*,
     time::{
         delay::fsleep,
@@ -31,6 +37,7 @@
 const CLEVO_EC_CMD_GET_SPECS: u8 = 0x0D;
 const CLEVO_EC_CMD_GET_BIOS_FEATURES_1: u8 = 0x52;
 const CLEVO_EC_CMD_GET_BIOS_FEATURES_2: u8 = 0x7A;
+const CLEVO_EC_CMD_SET_KB_WHITE_LEDS: u8 = 0x27;
 const CLEVO_BIOS_FEATURE_CODE_WHITE_ONLY_KB: u32 = 0x4000_0000;
 const CLEVO_BIOS_FEATURE_CODE_3_ZONE_RGB_KB: u32 = 0x0040_0000;
 const CLEVO_BIOS_FEATURE_CODE_WHITE_ONLY_KB_MAX_5: u32 = 0x4000;
@@ -63,7 +70,7 @@ trait EcQuery {
 #[pin_data]
 struct ClevoLaptopModule {
     #[pin]
-    _wmi_driver: wmi::Registration<WmiDriver>,
+    _wmi_driver: wmi::Registration<WmiDriver<'static>>,
 }
 
 impl kernel::InPlaceModule for ClevoLaptopModule {
@@ -83,12 +90,14 @@ fn init(module: &'static ThisModule) -> impl PinInit<Self, Error> {
 
 /// RAII guard for Clevo WMI driver holding all subsystem devices e.g LED device.
 #[pin_data]
-struct WmiDriver {}
+struct WmiDriver<'a> {
+    _led: LedRegistration<'a>,
+}
 
 kernel::wmi_device_table!(WMI_TABLE, [wmi::DeviceId::new(CLEVO_WMI_METHOD_GUID)]);
 
-impl wmi::Driver for WmiDriver {
-    type Data<'bound> = WmiDriver;
+impl wmi::Driver for WmiDriver<'_> {
+    type Data<'bound> = WmiDriver<'bound>;
     const ID_TABLE: wmi::IdTable = &WMI_TABLE;
     fn probe<'bound>(
         dev: &'bound wmi::Device<device::Core<'_>>,
@@ -109,11 +118,64 @@ fn probe<'bound>(
                 return Err(ENODEV);
             }
 
-            Ok(try_pin_init!(WmiDriver {}))
+            if let Err(e) = backend.query(SetWhiteBrightness(Brightness::OFF)) {
+                dev_dbg!(
+                    dev,
+                    "Error {e:?} setting keyboard brightness on initialization.\n"
+                );
+            }
+
+            let led_dev = KBox::pin_init(
+                led::DeviceBuilder::new()
+                    .name(c"white:kbd_backlight")
+                    .color(led::Color::White)
+                    .build(
+                        dev.as_ref(),
+                        try_pin_init!(FixedColorLedOperations { backend }),
+                    ),
+                GFP_KERNEL,
+            )?;
+
+            Ok(try_pin_init!(WmiDriver {
+                _led: LedRegistration::White5Step { _dev: led_dev },
+            }))
         })
     }
 }
 
+/// RAII guard for Clevo LED device holding the appropriate sysfs device for the backlight type.
+enum LedRegistration<'a> {
+    White5Step {
+        _dev: Pin<
+            KBox<led::Device<'a, FixedColorLedOperations<'a, { Brightness::MAX_WHITE_5.raw() }>>>,
+        >,
+    },
+}
+
+/// Represents how to perform LED operations for a Clevo single-color LED keyboard, generic over
+/// `MAX_BRIGHTNESS`.
+#[pin_data]
+struct FixedColorLedOperations<'a, const MAX_BRIGHTNESS: u8> {
+    backend: EcInterface<'a>,
+}
+#[vtable]
+impl<'a, const MAX_BRIGHTNESS: u8> LedOps for FixedColorLedOperations<'a, MAX_BRIGHTNESS> {
+    const BLOCKING: bool = true;
+    const MAX_BRIGHTNESS: u32 = MAX_BRIGHTNESS as u32;
+    type Mode = Normal;
+
+    fn brightness_set<'bound>(
+        self: &<Self::Mode as led::Mode>::Device<'bound, Self>,
+        brightness: u32,
+    ) -> Result<()> {
+        let clamped = u8::try_from(brightness)
+            .unwrap_or(MAX_BRIGHTNESS)
+            .min(MAX_BRIGHTNESS);
+        self.backend
+            .query(SetWhiteBrightness(Brightness::new(clamped)))
+    }
+}
+
 /// Interface to Clevo Embedded Controller.
 enum EcInterface<'a> {
     Wmi(&'a wmi::Device<device::Bound>),
@@ -182,6 +244,20 @@ fn detect_backlight_type(&self) -> Result<Option<KbBacklightType>> {
     }
 }
 
+/// Keyboard backlight brightness level.
+#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Copy, Clone)]
+struct Brightness(u8);
+impl Brightness {
+    const OFF: Self = Self(0);
+    const MAX_WHITE_5: Self = Self(5);
+    const fn new(val: u8) -> Self {
+        Self(val)
+    }
+    const fn raw(self) -> u8 {
+        self.0
+    }
+}
+
 /// Keyboard backlight type - e.g Fixed Color
 #[derive(PartialEq)]
 #[repr(u8)]
@@ -219,6 +295,8 @@ fn as_bytes(&self) -> &[u8] {
     }
 }
 
+#[derive(Debug, Clone, Copy, PartialEq, Eq)]
+struct SetWhiteBrightness(Brightness);
 #[derive(Debug, Clone, Copy, PartialEq, Eq)]
 struct GetSpecs;
 #[derive(Debug, Clone, Copy, PartialEq, Eq)]
@@ -226,6 +304,18 @@ fn as_bytes(&self) -> &[u8] {
 #[derive(Debug, Clone, Copy, PartialEq, Eq)]
 struct GetBiosFeatures2;
 
+impl EcQuery for SetWhiteBrightness {
+    type Output = ();
+    fn cmd(&self) -> u8 {
+        CLEVO_EC_CMD_SET_KB_WHITE_LEDS
+    }
+    fn args(&self) -> EcMethodArgs {
+        EcMethodArgs::Scalar(self.0.raw().into())
+    }
+    fn deserialize_output(_output: &[u8]) -> Result<Self::Output> {
+        Ok(())
+    }
+}
 impl EcQuery for GetBiosFeatures1 {
     type Output = BiosFeatures1;
     fn cmd(&self) -> u8 {

-- 
2.56.1

