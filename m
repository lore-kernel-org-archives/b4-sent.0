From: Markus Probst <markus.probst@posteo.de>
Date: Wed, 05 Aug 2026 21:34:11 +0200
Subject: [PATCH RESEND v23 2/3] rust: leds: add Mode trait
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-rust_leds-v23-2-b2fea4290ee6@posteo.de>
References: <20260805-rust_leds-v23-0-b2fea4290ee6@posteo.de>
In-Reply-To: <20260805-rust_leds-v23-0-b2fea4290ee6@posteo.de>
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
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5626;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=nc2dY/Fz8fnYk1jCgiVliPMUCfhD5G60Nz9Ipye79EA=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBqc5A4iSOWrfMwCyI+YzOs71qNy4nNXmsKFnHDO
 V9yYA9TAOGJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCanOQOBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9I7QBAAk32MFiyt/+aQyB7qGd8KDGE62iV6v7P
 +X66/1wiamy+cXbBqky5e0MTOkWAc88lsPRwyunYAmE3tQc3/fytnIBwIcjrhXw1jBq/zMbFBvJ
 Jt6qCRMLIV/r02tgYnQxLIDbCdE1IbUbIXKc9+e7XX3AE2srEDRGWWOXpC2sjiXd8xK3kWk46st
 N88Ywtf9GbjOv8lNiJwRfwwRIVutbbXnxxw8aLMb4Z+C6Wk7Zb+glPztf4uZjjTj/JcQzH5BjcN
 MtHhhaisNK0qe0EvW2hF8xyUdPQejkqkWvt9ktDejrqNpl6kbTCS5vhV3vD8rJ/F9A+CbFX7kxv
 iS8uq2BIWYS9OmVnjnAMKdEmLD8I3VzIWUTWhYgy6KCvkw7XDXZzYDtOcp2zXwNVbHkyJUCAz/k
 irVsSakXvmOKhnHf4BqQtzHbljrMv06F0Lq28oL52Z4P1pgjjDWYL6pyedb4ADdUpRrPPI9cDXv
 MbNEroHefHbPjUEZsbLhEcKUDvnsjjc99MdqDvRCQZIwYhBMxeQygMokG+/K0FTSque+i96Yzf4
 IwGR3d7dm2g8KuEz47Lvqd6EqXesReOpfJtMB7orvxJtJWBNk4C4RjEmCbeLJxfNvHk6t+fP9tL
 o31yvzwnaH6d2DXnD7Zdy7euJB+8UUjT3wg8LRtBb/j2X2a0rfuI=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the `led::Mode` trait to allow for other types of led class devices
in `led::LedOps`.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 rust/kernel/led.rs        | 27 +++++++++++++++++++++++----
 rust/kernel/led/normal.rs | 22 +++++++++++++++-------
 2 files changed, 38 insertions(+), 11 deletions(-)

diff --git a/rust/kernel/led.rs b/rust/kernel/led.rs
index 596975e103b8..5d7e6d08ad2a 100644
--- a/rust/kernel/led.rs
+++ b/rust/kernel/led.rs
@@ -32,7 +32,10 @@
 
 mod normal;
 
-pub use normal::Device;
+pub use normal::{
+    Device,
+    Normal, //
+};
 
 /// The name of the led is determined by the driver.
 pub enum Named {}
@@ -161,6 +164,7 @@ pub fn name(self, name: &'init CStr) -> Self {
 /// #[vtable]
 /// impl led::LedOps for MyLedOps {
 ///     type Bus = platform::Device<device::Bound>;
+///     type Mode = led::Normal;
 ///     const BLOCKING: bool = false;
 ///     const MAX_BRIGHTNESS: u32 = 255;
 ///
@@ -182,6 +186,11 @@ pub trait LedOps: Send + Sync + Sized {
     #[allow(private_bounds)]
     type Bus: AsBusDevice<Bound>;
 
+    /// The led mode to use.
+    ///
+    /// See [`Mode`].
+    type Mode: Mode;
+
     /// If set true, [`LedOps::brightness_set`] and [`LedOps::blink_set`] must perform the
     /// operation immediately. If set false, they must not sleep.
     const BLOCKING: bool;
@@ -194,7 +203,7 @@ pub trait LedOps: Send + Sync + Sized {
     fn brightness_set<'bound>(
         &self,
         dev: &'bound Self::Bus,
-        classdev: &Device<'bound, Self>,
+        classdev: &<Self::Mode as Mode>::Device<'bound, Self>,
         brightness: u32,
     ) -> Result<()>;
 
@@ -202,7 +211,7 @@ fn brightness_set<'bound>(
     fn brightness_get<'bound>(
         &self,
         dev: &'bound Self::Bus,
-        classdev: &Device<'bound, Self>,
+        classdev: &<Self::Mode as Mode>::Device<'bound, Self>,
     ) -> Result<u32> {
         let _ = (dev, classdev);
         build_error!(VTABLE_DEFAULT_ERROR)
@@ -219,7 +228,7 @@ fn brightness_get<'bound>(
     fn blink_set<'bound>(
         &self,
         dev: &'bound Self::Bus,
-        classdev: &Device<'bound, Self>,
+        classdev: &<Self::Mode as Mode>::Device<'bound, Self>,
         delay_on: &mut usize,
         delay_off: &mut usize,
     ) -> Result<()> {
@@ -283,6 +292,16 @@ fn try_from(value: u32) -> core::result::Result<Self, Self::Error> {
     }
 }
 
+/// The led mode.
+///
+/// Each led mode has its own led class device type with different capabilities.
+///
+/// See [`Normal`].
+pub trait Mode: private::Sealed {
+    /// The class device for the led mode.
+    type Device<'bound, T: LedOps<Mode = Self> + 'bound>;
+}
+
 mod private {
     pub trait Sealed {}
 }
diff --git a/rust/kernel/led/normal.rs b/rust/kernel/led/normal.rs
index 816db7c57689..25190486a62d 100644
--- a/rust/kernel/led/normal.rs
+++ b/rust/kernel/led/normal.rs
@@ -6,11 +6,19 @@
 
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
 #[pin_data(PinnedDrop)]
-pub struct Device<'bound, T: LedOps + 'bound> {
+pub struct Device<'bound, T: LedOps<Mode = Normal> + 'bound> {
     #[pin]
     ops: T,
     #[pin]
@@ -20,7 +28,7 @@ pub struct Device<'bound, T: LedOps + 'bound> {
 
 impl<'init, S: DeviceBuilderState> DeviceBuilder<'init, S> {
     /// Registers a new [`Device`].
-    pub fn build<'bound: 'init, T: LedOps + 'bound>(
+    pub fn build<'bound: 'init, T: LedOps<Mode = Normal> + 'bound>(
         self,
         parent: &'bound T::Bus,
         ops: impl PinInit<T, Error> + 'init,
@@ -87,7 +95,7 @@ pub fn build<'bound: 'init, T: LedOps + 'bound>(
     }
 }
 
-impl<'bound, T: LedOps + 'bound> Device<'bound, T> {
+impl<'bound, T: LedOps<Mode = Normal> + 'bound> Device<'bound, T> {
     /// # Safety
     /// `led_cdev` must be a valid pointer to a `led_classdev` embedded within a
     /// `led::Device`.
@@ -107,17 +115,17 @@ fn parent(&self) -> &'bound device::Device<Bound> {
 }
 
 // SAFETY: A `led::Device` can be unregistered from any thread.
-unsafe impl<'bound, T: LedOps + 'bound + Send> Send for Device<'bound, T> {}
+unsafe impl<'bound, T: LedOps<Mode = Normal> + 'bound + Send> Send for Device<'bound, T> {}
 
 // SAFETY: `led::Device` can be shared among threads because all methods of `led::Device`
 // are thread safe.
-unsafe impl<'bound, T: LedOps + 'bound + Sync> Sync for Device<'bound, T> {}
+unsafe impl<'bound, T: LedOps<Mode = Normal> + 'bound + Sync> Sync for Device<'bound, T> {}
 
 struct Adapter<T: LedOps> {
     _p: PhantomData<T>,
 }
 
-impl<T: LedOps> Adapter<T> {
+impl<T: LedOps<Mode = Normal>> Adapter<T> {
     /// # Safety
     /// `led_cdev` must be a valid pointer to a `led_classdev` embedded within a
     /// `led::Device`.
@@ -210,7 +218,7 @@ impl<T: LedOps> Adapter<T> {
 }
 
 #[pinned_drop]
-impl<'bound, T: LedOps + 'bound> PinnedDrop for Device<'bound, T> {
+impl<'bound, T: LedOps<Mode = Normal> + 'bound> PinnedDrop for Device<'bound, T> {
     fn drop(self: Pin<&mut Self>) {
         let raw = self.classdev.get();
         // SAFETY: The existence of `self` guarantees that `self.classdev.get()` is a pointer to a

-- 
2.54.0

