From: Markus Probst <markus.probst@posteo.de>
Date: Fri, 16 Oct 2026 20:08:03 +0200
Subject: [PATCH v27 2/4] rust: leds: Add Mode trait
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-rust_leds-v27-2-2c296d8a8e5b@posteo.de>
References: <20261016-rust_leds-v27-0-2c296d8a8e5b@posteo.de>
In-Reply-To: <20261016-rust_leds-v27-0-2c296d8a8e5b@posteo.de>
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Dave Ertman <david.m.ertman@intel.com>, Leon Romanovsky <leon@kernel.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Ira Weiny <iweiny@kernel.org>, Boqun Feng <boqun@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-leds@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4103;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=T5jFSZhnJXyl8J1nAaebPNgFMg1/74G8qletYMXyqFc=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBq0mgFWc/4vVj1smifRSMEWAs169P8StA5fMJBh
 yQ+cIXHM5qJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCatJoBRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9KswhAAuuk+TRejynPCTcrPhj9ASdkWFIAiw0b
 oDbcI6sEhsqygJUexRBrtHJxKvGTbmUM5el8cxRHa4DGBmRKSxHV2VjyLKrZQUfRcDy0+3H2vgl
 yacKuB+TCV/S9WlSRqfiqUy9fk5RQ5QUyeJadqR4cNK/Y4JtdKW8ciY9NkdXs9EWnVkJ/cXWPmy
 e6/FuB8PlwiVps2q/aFI4mdAipoms6pu5/gFFU20FkX8wSCvfMOs6tb7psWWcW1Nvdm821twzT5
 qugZaHR7sgsVMIOJA6M5CQQ4N/cHbvkvB3KWtArdP0bQwc0PA1JhKWLzYcitCzpDsbrH2X+I8hH
 xEIZbVhEIR4vymK4Amh0GRJuzQZ9jrDzDrjObMBULAEfP4yJ68uTlyWa2GuSKauy+SYwoJ0EBXq
 dObEiI4saXWNec2GbUK3F1ykN0OVX9DZjyJUs801bRSZ8YwbXgW9L/f2oSWv4NMKz/aMa10wloS
 HMdHgqYnaYyofgZK0mSiEAw0pGeyrjTuErAWuOG1SbJaJGiKPlMU/X02EmwHegsBaxq8r3WadXK
 h1CgAOCoO2qy+LDfZcc/F6BrqXk8PooIFd9pV3yglU5wUufjT1qgAiyoMHqAgC/O6ZYtbHhlnTm
 WTw/P0l2d9SbAzT/eu5vmEv8B5XCGcupiAg8IyFdixvyBEKZbToM=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the `led::Mode` trait to allow for other types of led class devices
in `led::LedOps`.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 rust/kernel/led.rs        | 32 ++++++++++++++++++++++++++------
 rust/kernel/led/normal.rs | 12 ++++++++++--
 2 files changed, 36 insertions(+), 8 deletions(-)

diff --git a/rust/kernel/led.rs b/rust/kernel/led.rs
index deda8cc548a8..c17f8ef75006 100644
--- a/rust/kernel/led.rs
+++ b/rust/kernel/led.rs
@@ -7,6 +7,7 @@
 use core::{
     marker::PhantomData,
     mem::transmute,
+    ops::Deref,
     ptr::NonNull, //
 };
 
@@ -31,7 +32,10 @@
 
 mod normal;
 
-pub use normal::Device;
+pub use normal::{
+    Device,
+    Normal, //
+};
 
 /// The name of the led is determined by the driver.
 pub enum Named {}
@@ -156,6 +160,7 @@ pub fn name(self, name: &'init CStr) -> Self {
 ///
 /// #[vtable]
 /// impl led::LedOps for MyLedOps {
+///     type Mode = led::Normal;
 ///     const BLOCKING: bool = false;
 ///     const MAX_BRIGHTNESS: u32 = 255;
 ///
@@ -176,16 +181,21 @@ pub trait LedOps: Send + Sync + Sized {
     const BLOCKING: bool;
     /// The max brightness level.
     const MAX_BRIGHTNESS: u32;
-
     /// Sets the brightness level.
     ///
     /// See also [`LedOps::BLOCKING`].
-    fn brightness_set<'bound>(self: &Device<'bound, Self>, brightness: u32) -> Result<()>;
-
+    fn brightness_set<'bound>(
+        self: &<Self::Mode as Mode>::Device<'bound, Self>,
+        brightness: u32,
+    ) -> Result<()>;
     /// Gets the current brightness level.
-    fn brightness_get<'bound>(self: &Device<'bound, Self>) -> Result<u32> {
+    fn brightness_get<'bound>(self: &<Self::Mode as Mode>::Device<'bound, Self>) -> Result<u32> {
         build_error!(VTABLE_DEFAULT_ERROR)
     }
+    /// The led mode to use.
+    ///
+    /// See [`Mode`].
+    type Mode: Mode;
 
     /// Activates hardware accelerated blinking.
     ///
@@ -196,7 +206,7 @@ fn brightness_get<'bound>(self: &Device<'bound, Self>) -> Result<u32> {
     ///
     /// See also [`LedOps::BLOCKING`].
     fn blink_set<'bound>(
-        self: &Device<'bound, Self>,
+        self: &<Self::Mode as Mode>::Device<'bound, Self>,
         delay_on: &mut usize,
         delay_off: &mut usize,
     ) -> Result<()> {
@@ -260,6 +270,16 @@ fn try_from(value: u32) -> core::result::Result<Self, Self::Error> {
     }
 }
 
+/// The led mode.
+///
+/// Each led mode has its own led class device type with different capabilities.
+///
+/// See [`Normal`].
+pub trait Mode: private::Sealed {
+    /// The class device for the led mode.
+    type Device<'bound, T: LedOps<Mode = Self> + 'bound>: Deref<Target = T>;
+}
+
 mod private {
     pub trait Sealed {}
 }
diff --git a/rust/kernel/led/normal.rs b/rust/kernel/led/normal.rs
index a22c29cfd262..992353319522 100644
--- a/rust/kernel/led/normal.rs
+++ b/rust/kernel/led/normal.rs
@@ -8,6 +8,14 @@
 
 use super::*;
 
+/// The led mode for the `struct led_classdev`. Leds with this mode can only have a fixed color.
+pub enum Normal {}
+
+impl Mode for Normal {
+    type Device<'bound, T: LedOps<Mode = Self> + 'bound> = Device<'bound, T>;
+}
+impl private::Sealed for Normal {}
+
 /// The led class device representation.
 ///
 /// This structure represents the Rust abstraction for a led class device.
@@ -22,7 +30,7 @@ pub struct Device<'bound, T: 'bound = ()> {
 
 impl<'init, S: DeviceBuilderState> DeviceBuilder<'init, S> {
     /// Registers a new [`Device`].
-    pub fn build<'bound: 'init, T: LedOps + 'bound>(
+    pub fn build<'bound: 'init, T: LedOps<Mode = Normal> + 'bound>(
         self,
         parent: &'bound device::Device<Bound>,
         ops: impl PinInit<T, Error> + 'init,
@@ -120,7 +128,7 @@ struct Adapter<T: LedOps> {
     _p: PhantomData<T>,
 }
 
-impl<T: LedOps> Adapter<T> {
+impl<T: LedOps<Mode = Normal>> Adapter<T> {
     /// # Safety
     /// `led_cdev` must be a valid pointer to a `led_classdev` embedded within a
     /// `led::Device`.

-- 
2.55.0

