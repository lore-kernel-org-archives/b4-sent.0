From: Markus Probst <markus.probst@posteo.de>
Date: Sun, 31 May 2026 00:51:02 +0200
Subject: [PATCH v11 1/3] rust: add basic serial device bus abstractions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260531-rust_serdev-v11-1-dee8e0d830f1@posteo.de>
References: <20260531-rust_serdev-v11-0-dee8e0d830f1@posteo.de>
In-Reply-To: <20260531-rust_serdev-v11-0-dee8e0d830f1@posteo.de>
To: Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Kari Argillander <kari.argillander@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Boqun Feng <boqun@kernel.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Boqun Feng <boqun@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-pm@vger.kernel.org, 
 driver-core@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=26523;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=DbWPEtpuFHER0txfyHEd2k+ZqSU25kUpzsnxtF2df30=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBqG2nbAXLk4x5W+iBEFEX3fQhHfll9bCoRmAxHr
 2SVs/MkNXyJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCahtp2xsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9KanA/9HP+GQXop2ghjIrgtvcB70eRP2yJPhZx
 B4/wPF1nEa3nf+jAZeVtWOiqm9WA5XZ8QBR9cdwXnOBnKIdJiam9KxU1eFhMTJK4smJ8H5h+yHl
 s6vhILFJ5HFNABvZiMSpouSN8xjG3PsNr8KKkMc6zEk05zVrgB1BPQw8oaBH9baN3y1EtQ4AUVn
 TC3kg+3RM+DDcT7TB5tVd6XmxkkFH3bw3/6ZgWgkp3PSuyQjqXFcd/f/zb+3/x7smVJtvmhsl+l
 2JT0csyFMAfVRODuZ8N1MDPlLxmRr53uh0Qr1cHR6zEheb8jiBFya8hSNJ9Cvg8u+NALJx9iQ/h
 /hpAvhkO6GajHBYmljLOEVJzra8d1hlAqw+VofOm2ARPVNlusuYAYsfybBogEWORM2YMzLwIsya
 w8OIyvSO0h+HpSB/nuDG6BuP85O1hllbw9HBj/5ZCR2DYH28L+qrtRrwj/kMwNf2RAjRY/PSmJ7
 jwRY6oYs+4BSLeKIbR2fdJ39I+KpfZ9z0gSP07eM/8g77d2Jfwm/oV7Ia+DQJ0V6Ch2T+ijJxF+
 VeKC0DGmq904UpAnyfcayNHhHTHSF2iBEOZzurhkliLbLu2er86+a4z+zWWLEe1LTScsxhbhN+Y
 PNkGCJJ75NSs9GWJ0+LJ+iG1dZa13EciLGLuPxreCiv8t8o6Akm8=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the basic serial device bus abstractions required to write a
serial device bus device driver with or without the need for initial device
data. This includes the following data structures:

The `serdev::Driver` trait represents the interface to the driver.

The `serdev::Device` abstraction represents a `struct serdev_device`.

In order to provide the Serdev specific parts to a generic
`driver::Registration` the `driver::RegistrationOps` trait is
implemented by `serdev::Adapter`.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 MAINTAINERS                     |   2 +
 drivers/tty/serdev/Kconfig      |   7 +
 rust/bindings/bindings_helper.h |   1 +
 rust/helpers/helpers.c          |   1 +
 rust/helpers/serdev.c           |  22 ++
 rust/kernel/lib.rs              |   2 +
 rust/kernel/serdev.rs           | 590 ++++++++++++++++++++++++++++++++++++++++
 7 files changed, 625 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 4e118f704699..d2f608ff8ca0 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -24276,6 +24276,8 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/serial/serial.yaml
 F:	drivers/tty/serdev/
 F:	include/linux/serdev.h
+F:	rust/helpers/serdev.c
+F:	rust/kernel/serdev.rs
 
 SERIAL IR RECEIVER
 M:	Sean Young <sean@mess.org>
diff --git a/drivers/tty/serdev/Kconfig b/drivers/tty/serdev/Kconfig
index 46ae732bfc68..e6dfe949ad01 100644
--- a/drivers/tty/serdev/Kconfig
+++ b/drivers/tty/serdev/Kconfig
@@ -9,6 +9,13 @@ menuconfig SERIAL_DEV_BUS
 
 	  Note that you typically also want to enable TTY port controller support.
 
+config RUST_SERIAL_DEV_BUS_ABSTRACTIONS
+	bool "Rust Serial device bus abstractions"
+	depends on RUST
+	select SERIAL_DEV_BUS
+	help
+	  This enables the Rust abstraction for the serial device bus API.
+
 if SERIAL_DEV_BUS
 
 config SERIAL_DEV_CTRL_TTYPORT
diff --git a/rust/bindings/bindings_helper.h b/rust/bindings/bindings_helper.h
index 446dbeaf0866..4e42635b8607 100644
--- a/rust/bindings/bindings_helper.h
+++ b/rust/bindings/bindings_helper.h
@@ -84,6 +84,7 @@
 #include <linux/regulator/consumer.h>
 #include <linux/sched.h>
 #include <linux/security.h>
+#include <linux/serdev.h>
 #include <linux/slab.h>
 #include <linux/sys_soc.h>
 #include <linux/task_work.h>
diff --git a/rust/helpers/helpers.c b/rust/helpers/helpers.c
index 38b34518eff1..2fb8506a748a 100644
--- a/rust/helpers/helpers.c
+++ b/rust/helpers/helpers.c
@@ -86,6 +86,7 @@
 #include "regulator.c"
 #include "scatterlist.c"
 #include "security.c"
+#include "serdev.c"
 #include "signal.c"
 #include "slab.c"
 #include "spinlock.c"
diff --git a/rust/helpers/serdev.c b/rust/helpers/serdev.c
new file mode 100644
index 000000000000..c52b78ca3fc7
--- /dev/null
+++ b/rust/helpers/serdev.c
@@ -0,0 +1,22 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include <linux/serdev.h>
+
+__rust_helper
+void rust_helper_serdev_device_driver_unregister(struct serdev_device_driver *sdrv)
+{
+	serdev_device_driver_unregister(sdrv);
+}
+
+__rust_helper
+void rust_helper_serdev_device_put(struct serdev_device *serdev)
+{
+	serdev_device_put(serdev);
+}
+
+__rust_helper
+void rust_helper_serdev_device_set_client_ops(struct serdev_device *serdev,
+					      const struct serdev_device_ops *ops)
+{
+	serdev_device_set_client_ops(serdev, ops);
+}
diff --git a/rust/kernel/lib.rs b/rust/kernel/lib.rs
index b72b2fbe046d..83bc2c312241 100644
--- a/rust/kernel/lib.rs
+++ b/rust/kernel/lib.rs
@@ -118,6 +118,8 @@
 pub mod scatterlist;
 pub mod security;
 pub mod seq_file;
+#[cfg(CONFIG_RUST_SERIAL_DEV_BUS_ABSTRACTIONS)]
+pub mod serdev;
 pub mod sizes;
 #[cfg(CONFIG_SOC_BUS)]
 pub mod soc;
diff --git a/rust/kernel/serdev.rs b/rust/kernel/serdev.rs
new file mode 100644
index 000000000000..c6a7f9683d06
--- /dev/null
+++ b/rust/kernel/serdev.rs
@@ -0,0 +1,590 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Abstractions for the serial device bus.
+//!
+//! C header: [`include/linux/serdev.h`](srctree/include/linux/serdev.h)
+
+use crate::{
+    acpi,
+    device,
+    driver,
+    error::{
+        from_result,
+        to_result,
+        VTABLE_DEFAULT_ERROR, //
+    },
+    new_mutex,
+    of,
+    prelude::*,
+    sync::{
+        aref::AlwaysRefCounted,
+        Mutex, //
+    },
+    time::{
+        msecs_to_jiffies,
+        Jiffies,
+        Msecs, //
+    },
+    types::{
+        Opaque,
+        ScopeGuard, //
+    }, //
+};
+
+use core::{
+    cell::UnsafeCell,
+    marker::PhantomData,
+    mem::{offset_of, MaybeUninit},
+    num::NonZero,
+    ptr::NonNull, //
+};
+
+/// Parity bit to use with a serial device.
+#[repr(u32)]
+pub enum Parity {
+    /// No parity bit.
+    None = bindings::serdev_parity_SERDEV_PARITY_NONE,
+    /// Even partiy.
+    Even = bindings::serdev_parity_SERDEV_PARITY_EVEN,
+    /// Odd parity.
+    Odd = bindings::serdev_parity_SERDEV_PARITY_ODD,
+}
+
+/// Timeout in Jiffies.
+pub enum Timeout {
+    /// Wait for a specific amount of [`Jiffies`].
+    Jiffies(NonZero<Jiffies>),
+    /// Wait for a specific amount of [`Msecs`].
+    Milliseconds(NonZero<Msecs>),
+    /// Wait as long as possible.
+    ///
+    /// This is equivalent to [`kernel::task::MAX_SCHEDULE_TIMEOUT`].
+    Max,
+}
+
+impl Timeout {
+    fn into_jiffies(self) -> isize {
+        match self {
+            Self::Jiffies(value) => value.get().try_into().unwrap_or_default(),
+            Self::Milliseconds(value) => {
+                msecs_to_jiffies(value.get()).try_into().unwrap_or_default()
+            }
+            Self::Max => 0,
+        }
+    }
+}
+
+/// An adapter for the registration of serial device bus device drivers.
+pub struct Adapter<T: Driver>(T);
+
+// SAFETY:
+// - `bindings::serdev_device_driver` is a C type declared as `repr(C)`.
+// - `PrivateData<'bound, T>` is the type of the driver's device private data.
+// - `struct serdev_device_driver` embeds a `struct device_driver`.
+// - `DEVICE_DRIVER_OFFSET` is the correct byte offset to the embedded `struct device_driver`.
+unsafe impl<T: Driver> driver::DriverLayout for Adapter<T> {
+    type DriverType = bindings::serdev_device_driver;
+    type DriverData<'bound> = PrivateData<'bound, T>;
+    const DEVICE_DRIVER_OFFSET: usize = core::mem::offset_of!(Self::DriverType, driver);
+}
+
+// SAFETY: A call to `unregister` for a given instance of `DriverType` is guaranteed to be valid if
+// a preceding call to `register` has been successful.
+unsafe impl<T: Driver> driver::RegistrationOps for Adapter<T> {
+    unsafe fn register(
+        sdrv: &Opaque<Self::DriverType>,
+        name: &'static CStr,
+        module: &'static ThisModule,
+    ) -> Result {
+        let of_table = match T::OF_ID_TABLE {
+            Some(table) => table.as_ptr(),
+            None => core::ptr::null(),
+        };
+
+        let acpi_table = match T::ACPI_ID_TABLE {
+            Some(table) => table.as_ptr(),
+            None => core::ptr::null(),
+        };
+
+        // SAFETY: It's safe to set the fields of `struct serdev_device_driver` on initialization.
+        unsafe {
+            (*sdrv.get()).driver.name = name.as_char_ptr();
+            (*sdrv.get()).probe = Some(Self::probe_callback);
+            (*sdrv.get()).remove = Some(Self::remove_callback);
+            (*sdrv.get()).driver.of_match_table = of_table;
+            (*sdrv.get()).driver.acpi_match_table = acpi_table;
+        }
+
+        // SAFETY: `sdrv` is guaranteed to be a valid `DriverType`.
+        to_result(unsafe { bindings::__serdev_device_driver_register(sdrv.get(), module.0) })
+    }
+
+    unsafe fn unregister(sdrv: &Opaque<Self::DriverType>) {
+        // SAFETY: `sdrv` is guaranteed to be a valid `DriverType`.
+        unsafe { bindings::serdev_device_driver_unregister(sdrv.get()) };
+    }
+}
+
+#[doc(hidden)]
+#[pin_data(PinnedDrop)]
+pub struct PrivateData<'bound, T: Driver> {
+    sdev: &'bound Device<device::Bound>,
+    #[pin]
+    driver: UnsafeCell<MaybeUninit<T::Data<'bound>>>,
+    open: UnsafeCell<bool>,
+    #[pin]
+    active: Mutex<bool>,
+}
+
+#[pinned_drop]
+impl<T: Driver> PinnedDrop for PrivateData<'_, T> {
+    fn drop(self: Pin<&mut Self>) {
+        let mut active = self.active.lock();
+        if *active {
+            // SAFETY:
+            // - We have exclusive access to `self.driver`.
+            // - `self.driver` is guaranteed to be initialized.
+            unsafe { (*self.driver.get()).assume_init_drop() };
+            *active = false;
+        }
+
+        // SAFETY: We have exclusive access to `self.open`.
+        if unsafe { *self.open.get() } {
+            // SAFETY: `self.sdev.as_raw()` is guaranteed to be a pointer to a valid
+            // `struct serdev_device`.
+            unsafe { bindings::serdev_device_close(self.sdev.as_raw()) };
+        }
+    }
+}
+
+impl<T: Driver> Adapter<T> {
+    const OPS: &'static bindings::serdev_device_ops = &bindings::serdev_device_ops {
+        receive_buf: if T::HAS_RECEIVE {
+            Some(Self::receive_buf_callback)
+        } else {
+            None
+        },
+        write_wakeup: Some(bindings::serdev_device_write_wakeup),
+    };
+
+    extern "C" fn probe_callback(sdev: *mut bindings::serdev_device) -> kernel::ffi::c_int {
+        // SAFETY: The serial device bus only ever calls the probe callback with a valid pointer to
+        // a `struct serdev_device`.
+        //
+        // INVARIANT: `sdev` is valid for the duration of `probe_callback()`.
+        let sdev = unsafe { &*sdev.cast::<Device<device::CoreInternal<'_>>>() };
+        let info = <Self as driver::Adapter>::id_info(sdev.as_ref());
+
+        from_result(|| {
+            sdev.as_ref().set_drvdata(try_pin_init!(PrivateData::<T> {
+                sdev: &**sdev,
+                driver: MaybeUninit::<T::Data<'_>>::zeroed().into(),
+                open: false.into(),
+                active <- new_mutex!(false),
+            }))?;
+            // SAFETY: We just set drvdata to `PrivateData<'_, T>`.
+            let private_data = unsafe { sdev.as_ref().drvdata_borrow::<PrivateData<'_, T>>() };
+            let private_data = ScopeGuard::new_with_data(private_data, |_| {
+                // SAFETY: We just set drvdata to `PrivateData<'_, T>`.
+                drop(unsafe { sdev.as_ref().drvdata_obtain::<PrivateData<'_, T>>() });
+            });
+            let mut active = private_data.active.lock();
+
+            // SAFETY: `sdev.as_raw()` is guaranteed to be a valid pointer to `serdev_device`.
+            unsafe { bindings::serdev_device_set_client_ops(sdev.as_raw(), Self::OPS) };
+
+            // SAFETY: The serial device bus only ever calls the probe callback with a valid pointer
+            // to a `serdev_device`.
+            to_result(unsafe { bindings::serdev_device_open(sdev.as_raw()) })?;
+
+            // SAFETY: We have exclusive access to `private_data.open`.
+            unsafe { *private_data.open.get() = true };
+
+            let data = T::probe(sdev, info);
+
+            // SAFETY: We have exclusive access to `private_data.driver`.
+            let driver = unsafe { &mut *private_data.driver.get() };
+            // SAFETY:
+            // - `driver.as_mut_ptr()` is a valid pointer to uninitialized data.
+            // - `private_data.driver` is pinned.
+            let result = unsafe { data.__pinned_init(driver.as_mut_ptr()) };
+
+            *active = result.is_ok();
+
+            drop(active);
+
+            result.map(|()| {
+                private_data.dismiss();
+                0
+            })
+        })
+    }
+
+    extern "C" fn remove_callback(sdev: *mut bindings::serdev_device) {
+        // SAFETY: The serial device bus only ever calls the remove callback with a valid pointer
+        // to a `struct serdev_device`.
+        //
+        // INVARIANT: `sdev` is valid for the duration of `remove_callback()`.
+        let sdev = unsafe { &*sdev.cast::<Device<device::CoreInternal<'_>>>() };
+
+        // SAFETY: `remove_callback` is only ever called after a successful call to
+        // `probe_callback`, hence it's guaranteed that `Device::set_drvdata()` has been called
+        // and stored a `Pin<KBox<PrivateData<'_, T>>>`.
+        let private_data = unsafe { sdev.as_ref().drvdata_borrow::<PrivateData<'_, T>>() };
+
+        // SAFETY: No one has exclusive access to `private_data.driver`.
+        let data = unsafe { &*private_data.driver.get() };
+        // SAFETY:
+        // - `private_data.driver` is pinned.
+        // - `remove_callback` is only ever called after a successful call to `probe_callback`,
+        //   hence it's guaranteed that `private_data.driver` was initialized.
+        let data_pinned = unsafe { Pin::new_unchecked(data.assume_init_ref()) };
+
+        T::unbind(sdev, data_pinned);
+    }
+
+    extern "C" fn receive_buf_callback(
+        sdev: *mut bindings::serdev_device,
+        buf: *const u8,
+        length: usize,
+    ) -> usize {
+        // SAFETY: The serial device bus only ever calls the receive buf callback with a valid
+        // pointer to a `struct serdev_device`.
+        //
+        // INVARIANT: `sdev` is valid for the duration of `receive_buf_callback()`.
+        let sdev = unsafe { &*sdev.cast::<Device<device::CoreInternal<'_>>>() };
+
+        // SAFETY: `receive_buf_callback` is only ever called after a successful call to
+        // `probe_callback`, hence it's guaranteed that `Device::set_drvdata()` has been called
+        // and stored a `Pin<KBox<PrivateData<'_, T>>>`.
+        let private_data = unsafe { sdev.as_ref().drvdata_borrow::<PrivateData<'_, T>>() };
+        let active = private_data.active.lock();
+
+        if !*active {
+            return length;
+        }
+
+        // SAFETY: No one has exclusive access to `private_data.driver`.
+        let data = unsafe { &*private_data.driver.get() };
+        // SAFETY:
+        // - `private_data.driver` is pinned.
+        // - `receive_buf_callback` is only ever called after a successful call to `probe_callback`,
+        //   hence it's guaranteed that `private_data.driver` was initialized.
+        let data_pinned = unsafe { Pin::new_unchecked(data.assume_init_ref()) };
+
+        // SAFETY: `buf` is guaranteed to be non-null and has the size of `length`.
+        let buf = unsafe { core::slice::from_raw_parts(buf, length) };
+
+        T::receive(sdev, data_pinned, buf)
+    }
+}
+
+impl<T: Driver> driver::Adapter for Adapter<T> {
+    type IdInfo = T::IdInfo;
+
+    fn of_id_table() -> Option<of::IdTable<Self::IdInfo>> {
+        T::OF_ID_TABLE
+    }
+
+    fn acpi_id_table() -> Option<acpi::IdTable<Self::IdInfo>> {
+        T::ACPI_ID_TABLE
+    }
+}
+
+/// Declares a kernel module that exposes a single serial device bus device driver.
+///
+/// # Examples
+///
+/// ```ignore
+/// kernel::module_serdev_device_driver! {
+///     type: MyDriver,
+///     name: "Module name",
+///     authors: ["Author name"],
+///     description: "Description",
+///     license: "GPL v2",
+/// }
+/// ```
+#[macro_export]
+macro_rules! module_serdev_device_driver {
+    ($($f:tt)*) => {
+        $crate::module_driver!(<T>, $crate::serdev::Adapter<T>, { $($f)* });
+    };
+}
+
+/// The serial device bus device driver trait.
+///
+/// Drivers must implement this trait in order to get a serial device bus device driver registered.
+///
+/// # Examples
+///
+///```
+/// # use kernel::{
+///     acpi,
+///     bindings,
+///     device::{
+///         Bound,
+///         Core, //
+///     },
+///     of,
+///     serdev, //
+/// };
+///
+/// struct MyDriver;
+///
+/// kernel::of_device_table!(
+///     OF_TABLE,
+///     MODULE_OF_TABLE,
+///     <MyDriver as serdev::Driver>::IdInfo,
+///     [
+///         (of::DeviceId::new(c"test,device"), ())
+///     ]
+/// );
+///
+/// kernel::acpi_device_table!(
+///     ACPI_TABLE,
+///     MODULE_ACPI_TABLE,
+///     <MyDriver as serdev::Driver>::IdInfo,
+///     [
+///         (acpi::DeviceId::new(c"LNUXBEEF"), ())
+///     ]
+/// );
+///
+/// #[vtable]
+/// impl serdev::Driver for MyDriver {
+///     type IdInfo = ();
+///     type Data<'bound> = Self;
+///     const OF_ID_TABLE: Option<of::IdTable<Self::IdInfo>> = Some(&OF_TABLE);
+///     const ACPI_ID_TABLE: Option<acpi::IdTable<Self::IdInfo>> = Some(&ACPI_TABLE);
+///
+///     fn probe<'bound>(
+///         sdev: &'bound serdev::Device<Core<'_>>,
+///         _id_info: Option<&'bound Self::IdInfo>,
+///     ) -> impl PinInit<Self::Data<'bound>, Error> + 'bound {
+///         sdev.set_baudrate(115200);
+///         sdev.write_all(b"Hello\n", serdev::Timeout::Max)?;
+///         Ok(MyDriver)
+///     }
+/// }
+///```
+#[vtable]
+pub trait Driver {
+    /// The type holding driver private data about each device id supported by the driver.
+    // TODO: Use associated_type_defaults once stabilized:
+    //
+    // ```
+    // type IdInfo: 'static = ();
+    // ```
+    type IdInfo: 'static;
+
+    /// The type of the driver's bus device private data.
+    type Data<'bound>: Send + 'bound;
+
+    /// The table of OF device ids supported by the driver.
+    const OF_ID_TABLE: Option<of::IdTable<Self::IdInfo>> = None;
+
+    /// The table of ACPI device ids supported by the driver.
+    const ACPI_ID_TABLE: Option<acpi::IdTable<Self::IdInfo>> = None;
+
+    /// Serial device bus device driver probe.
+    ///
+    /// Called when a new serial device bus device is added or discovered.
+    /// Implementers should attempt to initialize the device here.
+    fn probe<'bound>(
+        sdev: &'bound Device<device::Core<'_>>,
+        id_info: Option<&'bound Self::IdInfo>,
+    ) -> impl PinInit<Self::Data<'bound>, Error> + 'bound;
+
+    /// Serial device bus device driver unbind.
+    ///
+    /// Called when a [`Device`] is unbound from its bound [`Driver`]. Implementing this callback
+    /// is optional.
+    ///
+    /// This callback serves as a place for drivers to perform teardown operations that require a
+    /// `&Device<Core>` or `&Device<Bound>` reference. For instance.
+    ///
+    /// Otherwise, release operations for driver resources should be performed in `Drop`.
+    fn unbind<'bound>(sdev: &'bound Device<device::Core<'_>>, this: Pin<&Self::Data<'bound>>) {
+        let _ = (sdev, this);
+    }
+
+    /// Serial device bus device data receive callback.
+    ///
+    /// Called when data got received from device.
+    ///
+    /// Returns the number of bytes accepted.
+    fn receive<'bound>(
+        sdev: &'bound Device<device::Bound>,
+        this: Pin<&Self::Data<'bound>>,
+        data: &[u8],
+    ) -> usize {
+        let _ = (sdev, this, data);
+        build_error!(VTABLE_DEFAULT_ERROR)
+    }
+}
+
+/// The serial device bus device representation.
+///
+/// This structure represents the Rust abstraction for a C `struct serdev_device`. The
+/// implementation abstracts the usage of an already existing C `struct serdev_device` within Rust
+/// code that we get passed from the C side.
+///
+/// # Invariants
+///
+/// A [`Device`] instance represents a valid `struct serdev_device` created by the C portion of
+/// the kernel.
+#[repr(transparent)]
+pub struct Device<Ctx: device::DeviceContext = device::Normal>(
+    Opaque<bindings::serdev_device>,
+    PhantomData<Ctx>,
+);
+
+impl<Ctx: device::DeviceContext> Device<Ctx> {
+    fn as_raw(&self) -> *mut bindings::serdev_device {
+        self.0.get()
+    }
+}
+
+impl Device<device::Bound> {
+    /// Set the baudrate in bits per second.
+    ///
+    /// Common baudrates are 115200, 9600, 19200, 57600, 4800.
+    ///
+    /// Use [`Device::write_flush`] before calling this if you have written data prior to this call.
+    pub fn set_baudrate(&self, speed: u32) -> Result<(), u32> {
+        // SAFETY: `self.as_raw()` is guaranteed to be a pointer to a valid `serdev_device`.
+        let ret = unsafe { bindings::serdev_device_set_baudrate(self.as_raw(), speed) };
+        if ret == speed {
+            Ok(())
+        } else {
+            Err(ret)
+        }
+    }
+
+    /// Set if flow control should be enabled.
+    ///
+    /// Use [`Device::write_flush`] before calling this if you have written data prior to this call.
+    pub fn set_flow_control(&self, enable: bool) {
+        // SAFETY: `self.as_raw()` is guaranteed to be a pointer to a valid `serdev_device`.
+        unsafe { bindings::serdev_device_set_flow_control(self.as_raw(), enable) };
+    }
+
+    /// Set parity to use.
+    ///
+    /// Use [`Device::write_flush`] before calling this if you have written data prior to this call.
+    pub fn set_parity(&self, parity: Parity) -> Result {
+        // SAFETY: `self.as_raw()` is guaranteed to be a pointer to a valid `serdev_device`.
+        to_result(unsafe { bindings::serdev_device_set_parity(self.as_raw(), parity as u32) })
+    }
+
+    /// Write data to the serial device until the controller has accepted all the data or has
+    /// been interrupted by a timeout or signal.
+    ///
+    /// Note that any accepted data has only been buffered by the controller. Use
+    /// [`Device::wait_until_sent`] to make sure the controller write buffer has actually been
+    /// emptied.
+    ///
+    /// Returns the number of bytes written (less than `data.len()` if interrupted).
+    /// [`kernel::error::code::ETIMEDOUT`] or [`kernel::error::code::ERESTARTSYS`] if interrupted
+    /// before any bytes were written.
+    pub fn write_all(&self, data: &[u8], timeout: Timeout) -> Result<usize> {
+        // SAFETY:
+        // - `self.as_raw()` is guaranteed to be a pointer to a valid `serdev_device`.
+        // - `data.as_ptr()` is guaranteed to be a valid array pointer with the size of
+        //   `data.len()`.
+        let ret = unsafe {
+            bindings::serdev_device_write(
+                self.as_raw(),
+                data.as_ptr(),
+                data.len(),
+                timeout.into_jiffies(),
+            )
+        };
+        // CAST: negative return values are guaranteed to be between `-MAX_ERRNO` and `-1`,
+        // which always fit into a `i32`.
+        to_result(ret as i32).map(|()| ret.unsigned_abs())
+    }
+
+    /// Write data to the serial device.
+    ///
+    /// If you want to write until the controller has accepted all the data, use
+    /// [`Device::write_all`].
+    ///
+    /// Note that any accepted data has only been buffered by the controller. Use
+    /// [ Device::wait_until_sent`] to make sure the controller write buffer has actually been
+    /// emptied.
+    ///
+    /// Returns the number of bytes written (less than `data.len()` if not enough room in the
+    /// write buffer).
+    pub fn write(&self, data: &[u8]) -> Result<u32> {
+        // SAFETY:
+        // - `self.as_raw()` is guaranteed to be a pointer to a valid `serdev_device`.
+        // - `data.as_ptr()` is guaranteed to be a valid array pointer with the size of
+        //   `data.len()`.
+        let ret =
+            unsafe { bindings::serdev_device_write_buf(self.as_raw(), data.as_ptr(), data.len()) };
+
+        to_result(ret as i32).map(|()| ret.unsigned_abs())
+    }
+
+    /// Send data to the serial device immediately.
+    ///
+    /// Note that this doesn't guarantee that the data has been transmitted.
+    /// Use [`Device::wait_until_sent`] for this purpose.
+    pub fn write_flush(&self) {
+        // SAFETY: `self.as_raw()` is guaranteed to be a pointer to a valid `serdev_device`.
+        unsafe { bindings::serdev_device_write_flush(self.as_raw()) };
+    }
+
+    /// Wait for the data to be sent.
+    ///
+    /// After this function, the write buffer of the controller should be empty.
+    pub fn wait_until_sent(&self, timeout: Timeout) {
+        // SAFETY: `self.as_raw()` is guaranteed to be a pointer to a valid `serdev_device`.
+        unsafe { bindings::serdev_device_wait_until_sent(self.as_raw(), timeout.into_jiffies()) };
+    }
+}
+
+// SAFETY: `serdev::Device` is a transparent wrapper of `struct serdev_device`.
+// The offset is guaranteed to point to a valid device field inside `serdev::Device`.
+unsafe impl<Ctx: device::DeviceContext> device::AsBusDevice<Ctx> for Device<Ctx> {
+    const OFFSET: usize = offset_of!(bindings::serdev_device, dev);
+}
+
+// SAFETY: `Device` is a transparent wrapper of a type that doesn't depend on `Device`'s generic
+// argument.
+kernel::impl_device_context_deref!(unsafe { Device });
+kernel::impl_device_context_into_aref!(Device);
+
+// SAFETY: Instances of `Device` are always reference-counted.
+unsafe impl AlwaysRefCounted for Device {
+    fn inc_ref(&self) {
+        self.as_ref().inc_ref();
+    }
+
+    unsafe fn dec_ref(obj: NonNull<Self>) {
+        // SAFETY: The safety requirements guarantee that the refcount is non-zero.
+        unsafe { bindings::serdev_device_put(obj.cast().as_ptr()) }
+    }
+}
+
+impl<Ctx: device::DeviceContext> AsRef<device::Device<Ctx>> for Device<Ctx> {
+    fn as_ref(&self) -> &device::Device<Ctx> {
+        // SAFETY: By the type invariant of `Self`, `self.as_raw()` is a pointer to a valid
+        // `struct serdev_device`.
+        let dev = unsafe { &raw mut (*self.as_raw()).dev };
+
+        // SAFETY: `dev` points to a valid `struct device`.
+        unsafe { device::Device::from_raw(dev) }
+    }
+}
+
+// SAFETY: A `Device` is always reference-counted and can be released from any thread.
+unsafe impl Send for Device {}
+
+// SAFETY: `Device` can be shared among threads because all methods of `Device`
+// (i.e. `Device<Normal>) are thread safe.
+unsafe impl Sync for Device {}
+
+// SAFETY: Same as `Device<Normal>` -- the underlying `struct serdev_device` is the same;
+// `Bound` is a zero-sized type-state marker that does not affect thread safety.
+unsafe impl Sync for Device<device::Bound> {}

-- 
2.53.0

