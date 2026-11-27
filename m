From: Nick Dowsett <nick42d@gmail.com>
Date: Fri, 27 Nov 2026 19:02:51 +0800
Subject: [PATCH v2 3/4] rust: wmi: add Driver trait, Adapter and implement
 RegistrationOps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-rust-wmi-v2-3-5bfafabd6a6e@gmail.com>
References: <20261127-rust-wmi-v2-0-5bfafabd6a6e@gmail.com>
In-Reply-To: <20261127-rust-wmi-v2-0-5bfafabd6a6e@gmail.com>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Armin Wolf <W_Armin@gmx.de>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 platform-driver-x86@vger.kernel.org, Nick Dowsett <nick42d@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795777382; l=6617;
 i=nick42d@gmail.com; s=20261127; h=from:subject:message-id;
 bh=Yr/cV4bFQCpsCIJouPt3fyTS/uUCj24+sQv4ztfNN4g=;
 b=oocXIrckJJYiL4FowQMun3GCoMuuBgUIH3fw3ykOKGrWiNVvBPlI2qqAP/6TvwCBAlgsX1Bje
 xZIYNqPbf6NBC7EgjwrtIopzoeQ9FFuSxec08klN+OQSSshU6ZjOidV
X-Developer-Key: i=nick42d@gmail.com; a=ed25519;
 pk=rewGRrQm8GTjt8ii+wLiI2tUWP5gtTF4pntVEMNXrj8=
X-Endpoint-Received: by B4 Relay for nick42d@gmail.com/20261127 with auth_id=1660
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Implements the `wmi::Driver` trait.
- Adds adapter implementing `driver::DriverLayout` and
  `driver::RegistrationOps` - `wmi::Adapter<T: Driver>`.
- Adds `wmi::Registration<T>` type alias for convenience.

Signed-off-by: Nick Dowsett <nick42d@gmail.com>
---
 rust/kernel/wmi.rs | 127 ++++++++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 125 insertions(+), 2 deletions(-)

diff --git a/rust/kernel/wmi.rs b/rust/kernel/wmi.rs
index f7fbde29177b..235c4a2cef6a 100644
--- a/rust/kernel/wmi.rs
+++ b/rust/kernel/wmi.rs
@@ -8,15 +8,138 @@
     bindings,
     device,
     device_id::RawDeviceId,
+    driver,
+    error,
     prelude::*,
     sync::aref::AlwaysRefCounted,
-    types::Opaque, //
+    types::Opaque,
+    ThisModule, //
 };
 use core::{
     marker::PhantomData,
     ptr::NonNull, //
 };
 
+/// Type alias for [`driver::Registration<Adapter<T>>`], the registration of
+/// a WMI driver wrapping a [`struct wmi_driver`].
+///
+/// When this struct is dropped the driver will be unregistered.
+///
+/// [`struct wmi_driver`]: srctree/include/linux/wmi.h
+pub type Registration<T> = driver::Registration<Adapter<T>>;
+
+/// WMI driver trait.
+///
+/// Drivers must implement this trait in order to register a WMI driver.
+///
+/// # Examples
+///
+/// ```
+/// # use kernel::{device::Core, prelude::*, wmi};
+/// struct MyDriver;
+///
+/// kernel::wmi_device_table!(
+///     MY_DRIVER_WMI_TABLE,
+///     [wmi::DeviceId::new(c"00000000-0000-0000-0000-000000000000")]
+/// );
+///
+/// impl wmi::Driver for MyDriver {
+///     type Data<'bound> = Self;
+///     const ID_TABLE: wmi::IdTable = &MY_DRIVER_WMI_TABLE;
+///
+///     fn probe<'bound>(
+///         _dev: &'bound wmi::Device<Core<'_>>,
+///     ) -> impl PinInit<Self::Data<'bound>, Error> + 'bound {
+///         Err(ENODEV)
+///     }
+/// }
+/// ```
+pub trait Driver {
+    /// The type of the driver's bus device private data.
+    type Data<'bound>: Send + 'bound;
+    /// The table of WMI device IDs supported by the driver.
+    const ID_TABLE: IdTable;
+    /// The `probe` callback is called when the WMI driver is bound to a matching WMI device.
+    /// Allocating driver-specific data structures and initializing interfaces to other kernel
+    /// subsystems should normally be done in this function.
+    fn probe<'bound>(
+        dev: &'bound Device<device::Core<'_>>,
+    ) -> impl PinInit<Self::Data<'bound>, Error> + 'bound;
+}
+
+/// Adapter to allow [`Driver`] to be used with [`driver::Registration`].
+pub struct Adapter<T: Driver>(T);
+
+// SAFETY:
+// - `wmi_driver` is a C struct.
+// - Since `T` is a driver, `T::Data` is by definition the type of its
+//   device private data.
+// - `wmi_driver` embeds a `device_driver` at offset `DEVICE_DRIVER_OFFSET`
+//   as per `core::mem::offset_of!()`.
+unsafe impl<T: Driver> driver::DriverLayout for Adapter<T> {
+    type DriverType = bindings::wmi_driver;
+    type DriverData<'bound> = T::Data<'bound>;
+    const DEVICE_DRIVER_OFFSET: usize = core::mem::offset_of!(Self::DriverType, driver);
+}
+
+// SAFETY: It's always valid to unregister a registered `wmi_driver`.
+unsafe impl<T: Driver> driver::RegistrationOps for Adapter<T> {
+    unsafe fn register(
+        reg: &Opaque<Self::DriverType>,
+        name: &'static CStr,
+        module: &'static ThisModule,
+    ) -> Result {
+        // SAFETY:
+        // - It's safe to set the fields of `wmi_driver` on initialization.
+        // - All set fields meet the invariants of `wmi_driver`.
+        unsafe {
+            // SAFETY: `name` is valid for the static lifetime.
+            (*reg.get()).driver.name = name.as_char_ptr();
+            // SAFETY: This callback will only be called with a pointer to a `wmi_device`
+            // valid for the lifetime of the callback.
+            (*reg.get()).probe = Some(Self::probe_callback);
+            // SAFETY: `T::ID_TABLE` is valid for the static lifetime.
+            (*reg.get()).id_table = T::ID_TABLE.as_ptr();
+            // Per the documentation, new WMI drivers should be allowed to be instantiated
+            // multiple times (see `Documentation/wmi/driver-development-guide.rst`).
+            (*reg.get()).no_singleton = true;
+        }
+
+        // SAFETY: `reg` is a valid `wmi_driver`.
+        error::to_result(unsafe { bindings::__wmi_driver_register(reg.get(), module.as_ptr()) })
+    }
+    unsafe fn unregister(wdrv: &Opaque<Self::DriverType>) {
+        // SAFETY: `wdrv` is a valid `wmi_driver` previously registered with `register()`.
+        unsafe { bindings::wmi_driver_unregister(wdrv.get()) };
+    }
+}
+
+impl<T: Driver> Adapter<T> {
+    /// C wrapper for [`Driver::probe`] function to use it as a C function pointer.
+    ///
+    /// # Safety
+    /// - The caller must ensure that `wdev` is a pointer to a `wmi_device` valid for
+    ///   the lifetime of the callback.
+    unsafe extern "C" fn probe_callback(
+        wdev: *mut bindings::wmi_device,
+        _context: *const c_void,
+    ) -> c_int {
+        // SAFETY:
+        // - As per the safety requirement for the function, `wdev` is a pointer to a
+        //   `struct wmi_device` valid for the lifetime of the callback.
+        //   This is the definition of the Core and CoreInternal marker lifetime.
+        // - `Device` is `#[repr(transparent)]` over `struct wmi_device`.
+        let wdev = unsafe { &*wdev.cast::<Device<device::CoreInternal<'_>>>() };
+        let data = T::probe(wdev);
+        // As per the C driver subsystem documentation, the return type of a driver
+        // probe callback is 0 on success or a kernel error code on failure.
+        error::from_result(|| {
+            wdev.as_ref().set_drvdata(data)?;
+            Ok(0)
+        })
+    }
+}
+
 /// IdTable type for WMI drivers.
 pub type IdTable = &'static dyn crate::device_id::IdTable<DeviceId, ()>;
 
@@ -140,7 +263,7 @@ impl<Ctx: device::DeviceContext> AsRef<device::Device<Ctx>> for Device<Ctx> {
     fn as_ref(&self) -> &device::Device<Ctx> {
         // SAFETY:
         // - By the type invariant on `Device<Ctx>`, `self.as_raw()` is a valid pointer to
-        //   a `wmi_device which embeds a `device`.
+        //   a `wmi_device` which embeds a `device`.
         // - If you have a reference to a `Device<Ctx>`, then the reference count must be
         //   non-zero.
         // - If you have a reference to a `Device<Ctx>`, it is either:

-- 
2.56.1

