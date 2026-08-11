From: Alvin Sun <alvin.sun@linux.dev>
Date: Tue, 11 Aug 2026 14:39:43 +0800
Subject: [PATCH v10 01/10] rust: module: move module types into `module.rs`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-fix-fops-owner-v10-1-7e71776f9dbe@linux.dev>
References: <20260811-fix-fops-owner-v10-0-7e71776f9dbe@linux.dev>
In-Reply-To: <20260811-fix-fops-owner-v10-0-7e71776f9dbe@linux.dev>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Arnd Bergmann <arnd@arndb.de>, Brendan Higgins <brendan.higgins@linux.dev>, 
 David Gow <david@davidgow.net>, Rae Moar <raemoar63@gmail.com>, 
 Breno Leitao <leitao@debian.org>, Jens Axboe <axboe@kernel.dk>, 
 Dave Ertman <david.m.ertman@intel.com>, Leon Romanovsky <leon@kernel.org>, 
 Igor Korotin <igor.korotin@linux.dev>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Carlos Llamas <cmllamas@google.com>
Cc: rust-for-linux@vger.kernel.org, linux-modules@vger.kernel.org, 
 driver-core@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 nova-gpu@lists.linux.dev, linux-kselftest@vger.kernel.org, 
 kunit-dev@googlegroups.com, linux-block@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-pci@vger.kernel.org, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786430463; l=10393;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=1YTeZVLATNwjBM3mInj+MrWbU8MnHTpzhn3R//d7HTc=;
 b=u25RTiv29ff9S/2sq4DPEEhelQImggVHcA6NhcWbAQgIjDG9Jdip2s4+KbDRmePdcojhpP2rW
 PMwFuoSuCzIB4gcDvmWnXpGpQ0cWCW2LGi8fduwRTfy409U8VGa1crn
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move `Module`, `InPlaceModule`, `ModuleMetadata` and `ThisModule` from
`lib.rs` into a new `rust/kernel/module.rs`. Re-export them from `lib.rs`
to avoid tree-wide changes.

Switch six bus driver registrations from `module.0` to the public
`ThisModule::as_ptr()` accessor, since the field is no longer visible
outside the new `module` submodule.

No functional change.

Assisted-by: opencode:glm-5.2
Suggested-by: Gary Guo <gary@garyguo.net>
Link: https://lore.kernel.org/all/DJFIQPLOVO4T.1K8T0VZM30LDA@garyguo.net/
Reviewed-by: Gary Guo <gary@garyguo.net>
Acked-by: Danilo Krummrich <dakr@kernel.org>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
Acked-by: Petr Pavlu <petr.pavlu@suse.com>
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/auxiliary.rs |  2 +-
 rust/kernel/i2c.rs       |  2 +-
 rust/kernel/lib.rs       | 75 +++++-------------------------------------------
 rust/kernel/module.rs    | 71 +++++++++++++++++++++++++++++++++++++++++++++
 rust/kernel/net/phy.rs   |  6 +++-
 rust/kernel/pci.rs       |  2 +-
 rust/kernel/platform.rs  |  2 +-
 rust/kernel/usb.rs       |  2 +-
 8 files changed, 88 insertions(+), 74 deletions(-)

diff --git a/rust/kernel/auxiliary.rs b/rust/kernel/auxiliary.rs
index c42928d5a2393..cc9745fbf179e 100644
--- a/rust/kernel/auxiliary.rs
+++ b/rust/kernel/auxiliary.rs
@@ -69,7 +69,7 @@ unsafe fn register(
 
         // SAFETY: `adrv` is guaranteed to be a valid `DriverType`.
         to_result(unsafe {
-            bindings::__auxiliary_driver_register(adrv.get(), module.0, name.as_char_ptr())
+            bindings::__auxiliary_driver_register(adrv.get(), module.as_ptr(), name.as_char_ptr())
         })
     }
 
diff --git a/rust/kernel/i2c.rs b/rust/kernel/i2c.rs
index 624b971ca8b0b..dd9271af5eb8b 100644
--- a/rust/kernel/i2c.rs
+++ b/rust/kernel/i2c.rs
@@ -142,7 +142,7 @@ unsafe fn register(
         }
 
         // SAFETY: `idrv` is guaranteed to be a valid `DriverType`.
-        to_result(unsafe { bindings::i2c_register_driver(module.0, idrv.get()) })
+        to_result(unsafe { bindings::i2c_register_driver(module.as_ptr(), idrv.get()) })
     }
 
     unsafe fn unregister(idrv: &Opaque<Self::DriverType>) {
diff --git a/rust/kernel/lib.rs b/rust/kernel/lib.rs
index 9512af7156df2..2e175dcb145aa 100644
--- a/rust/kernel/lib.rs
+++ b/rust/kernel/lib.rs
@@ -94,6 +94,7 @@
 pub mod maple_tree;
 pub mod miscdevice;
 pub mod mm;
+pub mod module;
 pub mod module_param;
 #[cfg(CONFIG_NET)]
 pub mod net;
@@ -140,79 +141,17 @@
 #[doc(hidden)]
 pub use bindings;
 pub use macros;
+pub use module::{
+    InPlaceModule,
+    Module,
+    ModuleMetadata,
+    ThisModule, //
+};
 pub use uapi;
 
 /// Prefix to appear before log messages printed from within the `kernel` crate.
 const __LOG_PREFIX: &[u8] = b"rust_kernel\0";
 
-/// The top level entrypoint to implementing a kernel module.
-///
-/// For any teardown or cleanup operations, your type may implement [`Drop`].
-pub trait Module: Sized + Sync + Send {
-    /// Called at module initialization time.
-    ///
-    /// Use this method to perform whatever setup or registration your module
-    /// should do.
-    ///
-    /// Equivalent to the `module_init` macro in the C API.
-    fn init(module: &'static ThisModule) -> error::Result<Self>;
-}
-
-/// A module that is pinned and initialised in-place.
-pub trait InPlaceModule: Sync + Send {
-    /// Creates an initialiser for the module.
-    ///
-    /// It is called when the module is loaded.
-    fn init(module: &'static ThisModule) -> impl pin_init::PinInit<Self, error::Error>;
-}
-
-impl<T: Module> InPlaceModule for T {
-    fn init(module: &'static ThisModule) -> impl pin_init::PinInit<Self, error::Error> {
-        let initer = move |slot: *mut Self| {
-            let m = <Self as Module>::init(module)?;
-
-            // SAFETY: `slot` is valid for write per the contract with `pin_init_from_closure`.
-            unsafe { slot.write(m) };
-            Ok(())
-        };
-
-        // SAFETY: On success, `initer` always fully initialises an instance of `Self`.
-        unsafe { pin_init::pin_init_from_closure(initer) }
-    }
-}
-
-/// Metadata attached to a [`Module`] or [`InPlaceModule`].
-pub trait ModuleMetadata {
-    /// The name of the module as specified in the `module!` macro.
-    const NAME: &'static crate::str::CStr;
-}
-
-/// Equivalent to `THIS_MODULE` in the C API.
-///
-/// C header: [`include/linux/init.h`](srctree/include/linux/init.h)
-pub struct ThisModule(*mut bindings::module);
-
-// SAFETY: `THIS_MODULE` may be used from all threads within a module.
-unsafe impl Sync for ThisModule {}
-
-impl ThisModule {
-    /// Creates a [`ThisModule`] given the `THIS_MODULE` pointer.
-    ///
-    /// # Safety
-    ///
-    /// The pointer must be equal to the right `THIS_MODULE`.
-    pub const unsafe fn from_ptr(ptr: *mut bindings::module) -> ThisModule {
-        ThisModule(ptr)
-    }
-
-    /// Access the raw pointer for this module.
-    ///
-    /// It is up to the user to use it correctly.
-    pub const fn as_ptr(&self) -> *mut bindings::module {
-        self.0
-    }
-}
-
 #[cfg(not(testlib))]
 #[panic_handler]
 fn panic(info: &core::panic::PanicInfo<'_>) -> ! {
diff --git a/rust/kernel/module.rs b/rust/kernel/module.rs
new file mode 100644
index 0000000000000..be242a82e86d2
--- /dev/null
+++ b/rust/kernel/module.rs
@@ -0,0 +1,71 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Module-related types and helpers.
+
+/// The entrypoint to implementing a kernel module.
+///
+/// For any teardown or cleanup operations, your type may implement [`Drop`].
+pub trait Module: Sized + Sync + Send {
+    /// Called at module initialization time.
+    ///
+    /// Use this method to perform whatever setup or registration your module
+    /// should do.
+    ///
+    /// Equivalent to the `module_init` macro in the C API.
+    fn init(module: &'static ThisModule) -> crate::error::Result<Self>;
+}
+
+/// A module that is pinned and initialised in-place.
+pub trait InPlaceModule: Sync + Send {
+    /// Creates an initialiser for the module.
+    ///
+    /// It is called when the module is loaded.
+    fn init(module: &'static ThisModule) -> impl pin_init::PinInit<Self, crate::error::Error>;
+}
+
+impl<T: Module> InPlaceModule for T {
+    fn init(module: &'static ThisModule) -> impl pin_init::PinInit<Self, crate::error::Error> {
+        let initer = move |slot: *mut Self| {
+            let m = <Self as Module>::init(module)?;
+
+            // SAFETY: `slot` is valid for write per the contract with `pin_init_from_closure`.
+            unsafe { slot.write(m) };
+            Ok(())
+        };
+
+        // SAFETY: On success, `initer` always fully initialises an instance of `Self`.
+        unsafe { pin_init::pin_init_from_closure(initer) }
+    }
+}
+
+/// Metadata attached to a [`Module`] or [`InPlaceModule`].
+pub trait ModuleMetadata {
+    /// The name of the module as specified in the `module!` macro.
+    const NAME: &'static crate::str::CStr;
+}
+
+/// Equivalent to `THIS_MODULE` in the C API.
+///
+/// C header: [`include/linux/init.h`](srctree/include/linux/init.h)
+pub struct ThisModule(*mut crate::bindings::module);
+
+// SAFETY: `THIS_MODULE` may be used from all threads within a module.
+unsafe impl Sync for ThisModule {}
+
+impl ThisModule {
+    /// Creates a [`ThisModule`] given the `THIS_MODULE` pointer.
+    ///
+    /// # Safety
+    ///
+    /// The pointer must be equal to the right `THIS_MODULE`.
+    pub const unsafe fn from_ptr(ptr: *mut crate::bindings::module) -> ThisModule {
+        ThisModule(ptr)
+    }
+
+    /// Access the raw pointer for this module.
+    ///
+    /// It is up to the user to use it correctly.
+    pub const fn as_ptr(&self) -> *mut crate::bindings::module {
+        self.0
+    }
+}
diff --git a/rust/kernel/net/phy.rs b/rust/kernel/net/phy.rs
index 3ca99db5cccf2..8b7036b8fe480 100644
--- a/rust/kernel/net/phy.rs
+++ b/rust/kernel/net/phy.rs
@@ -659,7 +659,11 @@ pub fn register(
         // the `drivers` slice are initialized properly. `drivers` will not be moved.
         // So it's just an FFI call.
         to_result(unsafe {
-            bindings::phy_drivers_register(drivers[0].0.get(), drivers.len().try_into()?, module.0)
+            bindings::phy_drivers_register(
+                drivers[0].0.get(),
+                drivers.len().try_into()?,
+                module.as_ptr(),
+            )
         })?;
         // INVARIANT: The `drivers` slice is successfully registered to the kernel via `phy_drivers_register`.
         Ok(Registration { drivers })
diff --git a/rust/kernel/pci.rs b/rust/kernel/pci.rs
index 5071cae6543fd..4def9ca1824ce 100644
--- a/rust/kernel/pci.rs
+++ b/rust/kernel/pci.rs
@@ -86,7 +86,7 @@ unsafe fn register(
 
         // SAFETY: `pdrv` is guaranteed to be a valid `DriverType`.
         to_result(unsafe {
-            bindings::__pci_register_driver(pdrv.get(), module.0, name.as_char_ptr())
+            bindings::__pci_register_driver(pdrv.get(), module.as_ptr(), name.as_char_ptr())
         })
     }
 
diff --git a/rust/kernel/platform.rs b/rust/kernel/platform.rs
index d41555a4b31d2..5a5f4156d79be 100644
--- a/rust/kernel/platform.rs
+++ b/rust/kernel/platform.rs
@@ -83,7 +83,7 @@ unsafe fn register(
 
         // SAFETY: `pdrv` is guaranteed to be a valid `DriverType`.
         to_result(unsafe {
-            bindings::__platform_driver_register(pdrv.get(), module.0, name.as_char_ptr())
+            bindings::__platform_driver_register(pdrv.get(), module.as_ptr(), name.as_char_ptr())
         })
     }
 
diff --git a/rust/kernel/usb.rs b/rust/kernel/usb.rs
index 7aff0c82d0afc..870423806e4f5 100644
--- a/rust/kernel/usb.rs
+++ b/rust/kernel/usb.rs
@@ -63,7 +63,7 @@ unsafe fn register(
 
         // SAFETY: `udrv` is guaranteed to be a valid `DriverType`.
         to_result(unsafe {
-            bindings::usb_register_driver(udrv.get(), module.0, name.as_char_ptr())
+            bindings::usb_register_driver(udrv.get(), module.as_ptr(), name.as_char_ptr())
         })
     }
 

-- 
2.43.0

