From: SeungJong Ha <engineer.jjhama@gmail.com>
Date: Mon, 26 Jan 2026 12:22:09 +0000
Subject: [PATCH RFC 2/3] rust: tty: add TTY subsystem abstractions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-rust-tty-printk-driver-v1-2-28604e7e100e@gmail.com>
References: <20260126-rust-tty-printk-driver-v1-0-28604e7e100e@gmail.com>
In-Reply-To: <20260126-rust-tty-printk-driver-v1-0-28604e7e100e@gmail.com>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 SeungJong Ha <engineer.jjhama@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769430128; l=29559;
 i=engineer.jjhama@gmail.com; s=20260103; h=from:subject:message-id;
 bh=WQBEey82OuLBMZTWuHtXe1H87r381Rc30GoZYWPYHT0=;
 b=JAaR80nRGC3B2UkmEmL8m6kO/S3Qh1j8J6CZvDQUtD8gdSOkL3Ui8rNWyyKyuJdmCupOzS3sO
 tSiNWMpJz85A0R2g/fn6kCS1Vjwt5riyWoMfsV6ZMRszFY+kCp2ynpK
X-Developer-Key: i=engineer.jjhama@gmail.com; a=ed25519;
 pk=G5nmjm+RTiWBpyCvc5xjR1b3li/2zipLSMyz+T4fj5E=
X-Endpoint-Received: by B4 Relay for engineer.jjhama@gmail.com/20260103 with auth_id=590
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Rust abstractions for the TTY subsystem, providing safe wrappers for
tty_struct, tty_driver, and tty_port.

The abstractions are organized as follows:

- tty.rs: Core Tty<DriverData, DriverState> wrapper providing type-safe
  access to tty_struct with generic parameters for driver-specific data.

- tty/driver.rs: TtyDriverBuilder and TtyDriver for creating and
  registering TTY drivers. Includes:
  - Operations trait for implementing TTY callbacks (open, close, write,
    write_room, hangup)
  - Driver flags, termios output flags, and driver type constants

- tty/port.rs: DriverPort<Ops> combining tty_port with driver-specific
  data following the C pattern of embedding tty_port as the first field.
  Includes Operations trait for port callbacks (shutdown).

Key design decisions:
- Generic DriverData and DriverState types allow drivers to specify
  their own data types (typically Arc<T>) for per-tty and driver-wide
  state respectively.
- Pin-initialization is used throughout for safe handling of
  self-referential structures.
- The #[repr(C)] DriverPort layout enables container_of operations.

This provides the foundation for implementing TTY drivers in Rust.

Signed-off-by: SeungJong Ha <engineer.jjhama@gmail.com>
---
 rust/kernel/lib.rs        |   2 +
 rust/kernel/tty.rs        | 173 +++++++++++++++++
 rust/kernel/tty/driver.rs | 478 ++++++++++++++++++++++++++++++++++++++++++++++
 rust/kernel/tty/port.rs   | 148 ++++++++++++++
 4 files changed, 801 insertions(+)

diff --git a/rust/kernel/lib.rs b/rust/kernel/lib.rs
index f812cf120042..0160bfb54547 100644
--- a/rust/kernel/lib.rs
+++ b/rust/kernel/lib.rs
@@ -147,6 +147,8 @@
 pub mod time;
 pub mod tracepoint;
 pub mod transmute;
+#[cfg(CONFIG_TTY)]
+pub mod tty;
 pub mod types;
 pub mod uaccess;
 #[cfg(CONFIG_USB = "y")]
diff --git a/rust/kernel/tty.rs b/rust/kernel/tty.rs
new file mode 100644
index 000000000000..b2decd7e0b27
--- /dev/null
+++ b/rust/kernel/tty.rs
@@ -0,0 +1,173 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! TTY subsystem support.
+//!
+//! C headers: [`include/linux/tty.h`](srctree/include/linux/tty.h),
+//!            [`include/linux/tty_driver.h`](srctree/include/linux/tty_driver.h),
+//!            [`include/linux/tty_port.h`](srctree/include/linux/tty_port.h)
+//!
+//! This module provides TTY bindings for Rust TTY drivers.
+
+mod driver;
+pub mod port;
+
+use core::marker::PhantomData;
+
+pub use driver::{
+    flags,
+    oflag,
+    DriverType,
+    Operations,
+    Options,
+    TtyDriver,
+    TtyDriverBuilder,
+    TTYAUX_MAJOR,
+};
+pub use port::{
+    DriverPort,
+    Operations as PortOperations,
+};
+
+use crate::{
+    bindings,
+    sync::Arc,
+};
+
+/// TTY struct wrapper, generic over driver data and driver state types.
+///
+/// - `DriverData`: Per-tty instance data stored in `tty_struct->driver_data`.
+///   Use `Arc<T>` for shared data across multiple opens.
+/// - `DriverState`: Driver-level data stored in `tty_driver->driver_state` (shared by all ttys).
+///   Use `Arc<T>` for shared state.
+#[repr(transparent)]
+pub struct Tty<DriverData = (), DriverState = ()>(
+    *mut bindings::tty_struct,
+    PhantomData<(DriverData, DriverState)>,
+);
+
+impl<DriverData, DriverState> Tty<DriverData, DriverState> {
+    /// Creates a TTY wrapper from a raw pointer.
+    ///
+    /// # Safety
+    ///
+    /// - `ptr` must be a valid pointer to a `tty_struct`.
+    pub unsafe fn from_raw(ptr: *mut bindings::tty_struct) -> Self {
+        Self(ptr, PhantomData)
+    }
+
+    /// Returns the raw pointer.
+    pub fn as_raw(&self) -> *mut bindings::tty_struct {
+        self.0
+    }
+}
+
+impl<T: Send + Sync, DriverState> Tty<Arc<T>, DriverState> {
+    /// Sets driver-specific data in the `driver_data` field, taking ownership of the Arc.
+    ///
+    /// Returns the previously set data, if any.
+    pub fn set_driver_data(&self, data: Arc<T>) -> Option<Arc<T>> {
+        let old = self.take_driver_data();
+        // SAFETY: self.0 is valid.
+        unsafe {
+            (*self.0).driver_data = Arc::into_raw(data) as *mut _;
+        }
+        old
+    }
+
+    /// Takes the driver-specific data from the `driver_data` field, returning ownership.
+    ///
+    /// Returns `None` if no data was set.
+    pub fn take_driver_data(&self) -> Option<Arc<T>> {
+        // SAFETY: self.0 is valid.
+        let ptr = unsafe { (*self.0).driver_data };
+        if ptr.is_null() {
+            return None;
+        }
+        // SAFETY: self.0 is valid.
+        unsafe {
+            (*self.0).driver_data = core::ptr::null_mut();
+        }
+        // SAFETY: ptr was set via set_driver_data from an Arc<T>.
+        Some(unsafe { Arc::from_raw(ptr.cast()) })
+    }
+
+    /// Returns a reference to the driver-specific data in the `driver_data` field.
+    ///
+    /// Returns `None` if no data was set.
+    pub fn driver_data(&self) -> Option<&T> {
+        // SAFETY: self.0 is valid.
+        let ptr = unsafe { (*self.0).driver_data };
+        if ptr.is_null() {
+            return None;
+        }
+        // SAFETY: ptr was set via set_driver_data from an Arc<T>.
+        Some(unsafe { &*ptr.cast::<T>() })
+    }
+}
+
+impl<DriverData, T: Send + Sync> Tty<DriverData, Arc<T>> {
+    /// Returns a clone of the Arc holding the driver-level state.
+    ///
+    /// This is set by [`TtyDriverBuilder::set_driver_state`] and provides access to
+    /// driver-level data from within TTY operation callbacks. Returns a cloned Arc,
+    /// incrementing the reference count.
+    pub fn driver_state(&self) -> Option<Arc<T>> {
+        // SAFETY: self.0 is valid.
+        let driver = unsafe { (*self.0).driver };
+        if driver.is_null() {
+            return None;
+        }
+        // SAFETY: driver is valid.
+        let state = unsafe { (*driver).driver_state };
+        if state.is_null() {
+            return None;
+        }
+        // SAFETY: state was set via set_driver_state from an Arc<T>.
+        // We reconstruct the Arc, clone it, then forget the original to avoid
+        // decrementing the stored refcount.
+        let arc = unsafe { Arc::from_raw(state.cast::<T>()) };
+        let cloned = arc.clone();
+        core::mem::forget(arc);
+        Some(cloned)
+    }
+
+    /// Takes the driver-level state from `tty_driver->driver_state`, returning ownership.
+    ///
+    /// Returns `None` if no state was set.
+    pub fn take_driver_state(&self) -> Option<Arc<T>> {
+        // SAFETY: self.0 is valid.
+        let driver = unsafe { (*self.0).driver };
+        if driver.is_null() {
+            return None;
+        }
+        // SAFETY: driver is valid.
+        let ptr = unsafe { (*driver).driver_state };
+        if ptr.is_null() {
+            return None;
+        }
+        // SAFETY: driver is valid.
+        unsafe {
+            (*driver).driver_state = core::ptr::null_mut();
+        }
+        // SAFETY: ptr was set via set_driver_state from an Arc<T>.
+        Some(unsafe { Arc::from_raw(ptr.cast()) })
+    }
+
+    /// Sets the driver-level state in `tty_driver->driver_state`, taking ownership.
+    ///
+    /// Returns the previously set state, if any.
+    pub fn set_driver_state(&self, state: Arc<T>) -> Option<Arc<T>> {
+        // SAFETY: self.0 is valid.
+        let driver = unsafe { (*self.0).driver };
+        if driver.is_null() {
+            return None;
+        }
+        // Take old state first.
+        let old = self.take_driver_state();
+        // SAFETY: driver is valid.
+        unsafe {
+            (*driver).driver_state = Arc::into_raw(state) as *mut _;
+        }
+        old
+    }
+}
diff --git a/rust/kernel/tty/driver.rs b/rust/kernel/tty/driver.rs
new file mode 100644
index 000000000000..22a2210c3ef5
--- /dev/null
+++ b/rust/kernel/tty/driver.rs
@@ -0,0 +1,478 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! TTY driver support.
+//!
+//! Provides [`TtyDriverBuilder`] and [`TtyDriver`] for registering TTY drivers.
+
+use core::marker::PhantomData;
+
+use super::{
+    DriverPort,
+    PortOperations,
+    Tty,
+};
+use crate::{
+    bindings,
+    error::{
+        Error,
+        Result,
+        VTABLE_DEFAULT_ERROR,
+    },
+    prelude::*,
+    sync::Arc,
+    types::Opaque,
+};
+
+/// TTY driver flags.
+pub mod flags {
+    use crate::bindings;
+
+    /// Reset termios when the last process closes the device.
+    pub const RESET_TERMIOS: usize = bindings::tty_driver_flag_TTY_DRIVER_RESET_TERMIOS as usize;
+    /// Driver will guarantee not to set any special character handling flags.
+    pub const REAL_RAW: usize = bindings::tty_driver_flag_TTY_DRIVER_REAL_RAW as usize;
+    /// Do not create numbered /dev nodes (e.g., /dev/ttyprintk instead of /dev/ttyprintk0).
+    pub const UNNUMBERED_NODE: usize =
+        bindings::tty_driver_flag_TTY_DRIVER_UNNUMBERED_NODE as usize;
+}
+
+/// Termios output flags.
+pub mod oflag {
+    use crate::bindings;
+
+    /// Post-process output.
+    pub const OPOST: u32 = bindings::OPOST;
+    /// Map CR to NL on output.
+    pub const OCRNL: u32 = bindings::OCRNL;
+    /// No CR output at column 0.
+    pub const ONOCR: u32 = bindings::ONOCR;
+    /// NL performs CR function.
+    pub const ONLRET: u32 = bindings::ONLRET;
+}
+
+/// Major device number for TTY aux devices.
+pub const TTYAUX_MAJOR: i32 = bindings::TTYAUX_MAJOR as i32;
+
+/// TTY driver types.
+#[repr(u32)]
+#[derive(Copy, Clone, Debug)]
+pub enum DriverType {
+    /// System TTY.
+    System = bindings::tty_driver_type_TTY_DRIVER_TYPE_SYSTEM,
+    /// Console TTY.
+    Console = bindings::tty_driver_type_TTY_DRIVER_TYPE_CONSOLE,
+    /// Serial TTY.
+    Serial = bindings::tty_driver_type_TTY_DRIVER_TYPE_SERIAL,
+    /// PTY.
+    Pty = bindings::tty_driver_type_TTY_DRIVER_TYPE_PTY,
+}
+
+/// Options for creating a TTY driver.
+#[derive(Copy, Clone)]
+pub struct Options {
+    /// Driver name (shown in /proc/tty/drivers).
+    pub driver_name: &'static CStr,
+    /// Device name (used for /dev node).
+    pub name: &'static CStr,
+    /// Major device number.
+    pub major: i32,
+    /// Starting minor device number.
+    pub minor_start: i32,
+    /// Driver type.
+    pub driver_type: DriverType,
+    /// Driver flags (see [`flags`] module).
+    pub flags: usize,
+}
+
+/// Trait implemented by TTY device drivers.
+#[vtable]
+pub trait Operations: Sized + Send + Sync {
+    /// Driver-specific data type stored in `tty_struct->driver_data`.
+    ///
+    /// Use `Arc<T>` for shared data across multiple opens, or `()` if not needed.
+    /// Access via [`Tty::driver_data`] (returns `Option` since it may not be set until `open`).
+    type DriverData: Send + Sync;
+
+    /// Driver-level state type stored in `tty_driver->driver_state`.
+    ///
+    /// Use `Arc<T>` for shared state across all ttys, or `()` if not needed.
+    /// Access via [`Tty::driver_state`].
+    type DriverState: Send + Sync;
+
+    /// Port operations type. Must implement [`PortOperations`].
+    type PortOps: PortOperations + 'static;
+
+    /// Called when the TTY device is opened.
+    fn open(
+        tty: &Tty<Self::DriverData, Self::DriverState>,
+        file: *mut bindings::file,
+    ) -> Result<()>;
+
+    /// Called when the TTY device is closed.
+    fn close(tty: &Tty<Self::DriverData, Self::DriverState>, file: *mut bindings::file);
+
+    /// Called to write data to the device.
+    fn write(tty: &Tty<Self::DriverData, Self::DriverState>, buf: &[u8]) -> Result<usize>;
+
+    /// Returns the number of bytes that can be written.
+    fn write_room(_tty: &Tty<Self::DriverData, Self::DriverState>) -> u32 {
+        build_error!(VTABLE_DEFAULT_ERROR)
+    }
+
+    /// Called on hangup.
+    fn hangup(_tty: &Tty<Self::DriverData, Self::DriverState>) {
+        build_error!(VTABLE_DEFAULT_ERROR)
+    }
+}
+
+/// A vtable for the TTY operations.
+struct OperationsVTable<T: Operations>(PhantomData<T>);
+
+/// Type alias for the TTY type used in operations callbacks.
+type OpsTty<T> = Tty<<T as Operations>::DriverData, <T as Operations>::DriverState>;
+
+impl<T: Operations> OperationsVTable<T> {
+    /// # Safety
+    ///
+    /// `tty` and `filp` must be valid pointers.
+    unsafe extern "C" fn open(
+        tty: *mut bindings::tty_struct,
+        filp: *mut bindings::file,
+    ) -> core::ffi::c_int {
+        // SAFETY: tty is valid, driver_data starts as null.
+        let tty_ref = unsafe { OpsTty::<T>::from_raw(tty) };
+
+        match T::open(&tty_ref, filp) {
+            Ok(()) => 0,
+            Err(e) => e.to_errno(),
+        }
+    }
+
+    /// # Safety
+    ///
+    /// `tty` and `filp` must be valid pointers.
+    unsafe extern "C" fn close(tty: *mut bindings::tty_struct, filp: *mut bindings::file) {
+        // SAFETY: tty is valid, driver_data was set by driver in open.
+        let tty_ref = unsafe { OpsTty::<T>::from_raw(tty) };
+        T::close(&tty_ref, filp);
+    }
+
+    /// # Safety
+    ///
+    /// `tty` must be valid, `buf` must be valid for `count` bytes.
+    unsafe extern "C" fn write(
+        tty: *mut bindings::tty_struct,
+        buf: *const u8,
+        count: usize,
+    ) -> isize {
+        if buf.is_null() || count == 0 {
+            return 0;
+        }
+
+        // SAFETY: Kernel guarantees buf is valid for count bytes.
+        let slice = unsafe { core::slice::from_raw_parts(buf, count) };
+
+        // SAFETY: tty is valid, driver_data was set by driver in open.
+        let tty_ref = unsafe { OpsTty::<T>::from_raw(tty) };
+
+        match T::write(&tty_ref, slice) {
+            Ok(n) => n as isize,
+            Err(e) => e.to_errno() as isize,
+        }
+    }
+
+    /// # Safety
+    ///
+    /// `tty` must be a valid pointer.
+    unsafe extern "C" fn write_room(tty: *mut bindings::tty_struct) -> core::ffi::c_uint {
+        // SAFETY: tty is valid, driver_data was set by driver in open.
+        let tty_ref = unsafe { OpsTty::<T>::from_raw(tty) };
+        T::write_room(&tty_ref)
+    }
+
+    /// # Safety
+    ///
+    /// `tty` must be a valid pointer.
+    unsafe extern "C" fn hangup(tty: *mut bindings::tty_struct) {
+        // SAFETY: tty is valid, driver_data was set by driver in open.
+        let tty_ref = unsafe { OpsTty::<T>::from_raw(tty) };
+        T::hangup(&tty_ref);
+    }
+
+    const VTABLE: bindings::tty_operations = bindings::tty_operations {
+        open: Some(Self::open),
+        close: Some(Self::close),
+        write: Some(Self::write),
+        write_room: if T::HAS_WRITE_ROOM {
+            Some(Self::write_room)
+        } else {
+            None
+        },
+        hangup: if T::HAS_HANGUP {
+            Some(Self::hangup)
+        } else {
+            None
+        },
+        // All other operations are NULL.
+        lookup: None,
+        install: None,
+        remove: None,
+        shutdown: None,
+        cleanup: None,
+        put_char: None,
+        flush_chars: None,
+        chars_in_buffer: None,
+        ioctl: None,
+        compat_ioctl: None,
+        set_termios: None,
+        throttle: None,
+        unthrottle: None,
+        stop: None,
+        start: None,
+        break_ctl: None,
+        flush_buffer: None,
+        ldisc_ok: None,
+        set_ldisc: None,
+        wait_until_sent: None,
+        send_xchar: None,
+        tiocmget: None,
+        tiocmset: None,
+        resize: None,
+        get_icount: None,
+        get_serial: None,
+        set_serial: None,
+        show_fdinfo: None,
+        #[cfg(CONFIG_CONSOLE_POLL)]
+        poll_init: None,
+        #[cfg(CONFIG_CONSOLE_POLL)]
+        poll_get_char: None,
+        #[cfg(CONFIG_CONSOLE_POLL)]
+        poll_put_char: None,
+        proc_show: None,
+    };
+
+    const fn build() -> &'static bindings::tty_operations {
+        &Self::VTABLE
+    }
+}
+
+/// Builder for creating and configuring a TTY driver before registration.
+///
+/// Use [`TtyDriverBuilder::new`] to create a builder, optionally link ports
+/// with [`link_port`](Self::link_port), then call [`build`](Self::build) to
+/// register and obtain a [`TtyDriver`].
+///
+/// # Example
+///
+/// ```ignore
+/// let driver = KBox::pin_init(
+///     TtyDriverBuilder::<MyOps>::new(opts, module)?
+///         .link_port(&port, 0)
+///         .build(),
+///     GFP_KERNEL,
+/// )?;
+/// ```
+pub struct TtyDriverBuilder<T: Operations> {
+    driver_ptr: *mut bindings::tty_driver,
+    _t: PhantomData<T>,
+}
+
+impl<T: Operations> TtyDriverBuilder<T> {
+    /// Creates a new TTY driver builder.
+    pub fn new(opts: Options, module: &'static crate::ThisModule) -> Result<Self> {
+        // SAFETY: FFI call with valid arguments.
+        let driver_ptr = unsafe { bindings::__tty_alloc_driver(1, module.as_ptr(), opts.flags) };
+
+        if driver_ptr.is_null() || (driver_ptr as isize) < 0 && (driver_ptr as isize) > -4096 {
+            if driver_ptr.is_null() {
+                return Err(ENOMEM);
+            }
+            return Err(Error::from_errno(driver_ptr as i32));
+        }
+
+        // Configure the driver.
+        // SAFETY: driver_ptr is valid.
+        unsafe {
+            (*driver_ptr).driver_name = opts.driver_name.as_char_ptr();
+            (*driver_ptr).name = opts.name.as_char_ptr();
+            (*driver_ptr).major = opts.major;
+            (*driver_ptr).minor_start = opts.minor_start;
+            (*driver_ptr).type_ = opts.driver_type as u32;
+
+            // Set termios.
+            let mut termios = bindings::tty_std_termios;
+            termios.c_oflag = oflag::OPOST | oflag::OCRNL | oflag::ONOCR | oflag::ONLRET;
+            (*driver_ptr).init_termios = termios;
+
+            // Set operations vtable.
+            (*driver_ptr).ops = OperationsVTable::<T>::build();
+        }
+
+        Ok(Self {
+            driver_ptr,
+            _t: PhantomData,
+        })
+    }
+
+    /// Links a port to this driver at the specified line index.
+    ///
+    /// For fixed-device drivers (e.g., ttyprintk), call this before [`build`](Self::build).
+    pub fn link_port(self, port: &DriverPort<T::PortOps>, line: u32) -> Self {
+        // SAFETY: Both port and driver are valid.
+        unsafe {
+            bindings::tty_port_link_device(port.as_raw(), self.driver_ptr, line);
+        }
+        self
+    }
+
+    /// Registers the driver and returns a pin-initializer for [`TtyDriver`].
+    ///
+    /// The actual registration happens during pin-initialization.
+    pub fn build(self) -> impl PinInit<TtyDriver<T>, Error> {
+        let driver_ptr = self.driver_ptr;
+        // Prevent Drop from freeing the driver_ptr; TtyDriver takes ownership.
+        core::mem::forget(self);
+
+        try_pin_init!(TtyDriver::<T> {
+            inner <- Opaque::try_ffi_init(move |slot: *mut *mut bindings::tty_driver| {
+                // SAFETY: driver_ptr is valid.
+                let ret = unsafe { bindings::tty_register_driver(driver_ptr) };
+                if ret != 0 {
+                    // SAFETY: driver_ptr is valid, registration failed.
+                    unsafe { bindings::tty_driver_kref_put(driver_ptr) };
+                    return Err(Error::from_errno(ret));
+                }
+                // SAFETY: slot is valid for write.
+                unsafe { slot.write(driver_ptr) };
+                Ok(())
+            }),
+            _t: PhantomData,
+        }? Error)
+    }
+}
+
+impl<T: Operations> Drop for TtyDriverBuilder<T> {
+    fn drop(&mut self) {
+        // SAFETY: driver_ptr is valid, not yet registered.
+        unsafe { bindings::tty_driver_kref_put(self.driver_ptr) };
+    }
+}
+
+impl<T, S> TtyDriverBuilder<T>
+where
+    T: Operations<DriverState = Arc<S>>,
+    S: Send + Sync,
+{
+    /// Sets the driver-level state, taking ownership of the Arc.
+    ///
+    /// The state can be accessed via [`Tty::driver_state`] in TTY operation callbacks.
+    ///
+    /// # Note
+    ///
+    /// The caller must call [`TtyDriver::take_driver_state`] before the driver is
+    /// dropped to reclaim the state's memory. Failure to do so will result in a
+    /// memory leak.
+    pub fn set_driver_state(self, state: Arc<S>) -> Self {
+        // SAFETY: driver_ptr is valid.
+        unsafe {
+            (*self.driver_ptr).driver_state = Arc::into_raw(state) as *mut _;
+        }
+        self
+    }
+}
+
+/// A registered TTY driver.
+///
+/// Created via [`TtyDriverBuilder::build`]. The driver is automatically
+/// unregistered when dropped.
+///
+/// For probe-based drivers, ports can be linked after creation using
+/// [`link_port`](Self::link_port).
+///
+/// # Invariants
+///
+/// - `inner` contains a valid pointer to a registered `tty_driver`.
+/// - Deregistration occurs exactly once in [`Drop`].
+#[pin_data(PinnedDrop)]
+pub struct TtyDriver<T: Operations> {
+    #[pin]
+    inner: Opaque<*mut bindings::tty_driver>,
+    _t: PhantomData<T>,
+}
+
+// SAFETY: It is allowed to call `tty_unregister_driver` on a different thread.
+unsafe impl<T: Operations> Send for TtyDriver<T> {}
+// SAFETY: All `&self` methods are safe to call in parallel.
+unsafe impl<T: Operations> Sync for TtyDriver<T> {}
+
+impl<T: Operations> TtyDriver<T> {
+    /// Returns the driver pointer.
+    fn driver_ptr(&self) -> *mut bindings::tty_driver {
+        // SAFETY: inner is initialized.
+        unsafe { *self.inner.get() }
+    }
+
+    /// Links a port to this driver at the specified line index.
+    ///
+    /// For probe-based drivers (e.g., serial), call this at device probe time.
+    pub fn link_port<O: PortOperations + 'static>(&self, port: &DriverPort<O>, line: u32) {
+        // SAFETY: Both port and driver are valid.
+        unsafe {
+            bindings::tty_port_link_device(port.as_raw(), self.driver_ptr(), line);
+        }
+    }
+
+    /// Returns a raw pointer to the TTY driver.
+    pub fn as_raw(&self) -> *mut bindings::tty_driver {
+        self.driver_ptr()
+    }
+}
+
+impl<T, S> TtyDriver<T>
+where
+    T: Operations<DriverState = Arc<S>>,
+    S: Send + Sync,
+{
+    /// Takes the driver state, returning ownership of the Arc.
+    ///
+    /// Returns `None` if no state was set. This should be called before the driver
+    /// is dropped to reclaim the state's memory.
+    pub fn take_driver_state(&self) -> Option<Arc<S>> {
+        // SAFETY: driver_ptr is valid.
+        let ptr = unsafe { (*self.driver_ptr()).driver_state };
+        if ptr.is_null() {
+            return None;
+        }
+        // SAFETY: driver_ptr is valid.
+        unsafe {
+            (*self.driver_ptr()).driver_state = core::ptr::null_mut();
+        }
+        // SAFETY: ptr was set via set_driver_state from an Arc<S>.
+        Some(unsafe { Arc::from_raw(ptr.cast()) })
+    }
+
+    /// Returns a reference to the driver state.
+    ///
+    /// Returns `None` if no state was set.
+    pub fn driver_state(&self) -> Option<&S> {
+        // SAFETY: driver_ptr is valid.
+        let ptr = unsafe { (*self.driver_ptr()).driver_state };
+        if ptr.is_null() {
+            return None;
+        }
+        // SAFETY: ptr was set via set_driver_state from an Arc<S>.
+        Some(unsafe { &*ptr.cast::<S>() })
+    }
+}
+
+#[pinned_drop]
+impl<T: Operations> PinnedDrop for TtyDriver<T> {
+    fn drop(self: Pin<&mut Self>) {
+        // SAFETY: inner contains a valid registered driver.
+        unsafe {
+            let ptr = *self.inner.get();
+            bindings::tty_unregister_driver(ptr);
+            bindings::tty_driver_kref_put(ptr);
+        }
+    }
+}
diff --git a/rust/kernel/tty/port.rs b/rust/kernel/tty/port.rs
new file mode 100644
index 000000000000..576e884ed3bc
--- /dev/null
+++ b/rust/kernel/tty/port.rs
@@ -0,0 +1,148 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! TTY port support.
+//!
+//! Provides [`DriverPort`] which combines a TTY port with driver-specific data,
+//! following the C pattern of embedding `tty_port` as the first struct field.
+
+use core::marker::PhantomData;
+
+use pin_init::PinInit;
+
+use crate::{
+    bindings,
+    error::VTABLE_DEFAULT_ERROR,
+    prelude::*,
+    types::Opaque,
+};
+
+/// A combined TTY port and driver data structure.
+///
+/// Follows the C pattern of embedding `tty_port` as the first field.
+/// The `#[repr(C)]` layout enables safe `container_of` operations.
+#[repr(C)]
+#[pin_data]
+pub struct DriverPort<Ops: Operations> {
+    #[pin]
+    port: TtyPort<Ops>,
+    #[pin]
+    data: Ops::PortData,
+}
+
+impl<Ops: Operations> DriverPort<Ops> {
+    /// Creates a pin-initializer for a new driver port.
+    pub fn new(
+        data_init: impl PinInit<Ops::PortData, core::convert::Infallible>,
+    ) -> impl PinInit<Self, Error> {
+        try_pin_init!(Self {
+            port <- TtyPort::<Ops>::new(),
+            data <- data_init,
+        }? Error)
+    }
+
+    /// Returns a reference to the port-specific data.
+    pub fn data(&self) -> &Ops::PortData {
+        &self.data
+    }
+
+    /// Returns a raw pointer to the underlying `tty_port`.
+    pub(super) fn as_raw(&self) -> *mut bindings::tty_port {
+        self.port.as_raw()
+    }
+
+    /// Converts a raw `tty_port` pointer back to `&DriverPort` (container_of).
+    ///
+    /// # Safety
+    /// `ptr` must point to a `tty_port` within a valid `DriverPort<Ops>`.
+    unsafe fn from_raw<'a>(ptr: *mut bindings::tty_port) -> &'a Self {
+        // SAFETY: DriverPort is #[repr(C)] with TtyPort as first field.
+        unsafe { &*(ptr as *const Self) }
+    }
+}
+
+// SAFETY: DriverPort is Send/Sync if Ops::PortData is, since TtyPort is both.
+unsafe impl<Ops: Operations> Send for DriverPort<Ops> where Ops::PortData: Send {}
+// SAFETY: DriverPort is Send/Sync if Ops::PortData is, since TtyPort is both.
+unsafe impl<Ops: Operations> Sync for DriverPort<Ops> where Ops::PortData: Sync {}
+
+/// Wrapper for `struct tty_port`. Typically used via [`DriverPort`].
+///
+/// # Invariants
+/// Initialized via `tty_port_init()`, destroyed via `tty_port_destroy()` on drop.
+#[repr(transparent)]
+struct TtyPort<Ops: Operations>(Opaque<bindings::tty_port>, PhantomData<Ops>);
+
+impl<Ops: Operations> TtyPort<Ops> {
+    /// Creates a pin-initializer that calls `tty_port_init()` and sets the ops vtable.
+    fn new() -> impl PinInit<Self, Error> {
+        // SAFETY: tty_port_init initializes the port, vtable is static.
+        unsafe {
+            pin_init::pin_init_from_closure(|slot: *mut Self| {
+                let port_ptr = slot.cast::<bindings::tty_port>();
+                bindings::tty_port_init(port_ptr);
+                (*port_ptr).ops = OperationsVTable::<Ops>::build();
+                Ok(())
+            })
+        }
+    }
+
+    fn as_raw(&self) -> *mut bindings::tty_port {
+        self.0.get()
+    }
+}
+
+// SAFETY: TtyPort operations are internally synchronized by the kernel.
+unsafe impl<Ops: Operations> Send for TtyPort<Ops> {}
+// SAFETY: TtyPort operations are internally synchronized by the kernel.
+unsafe impl<Ops: Operations> Sync for TtyPort<Ops> {}
+
+impl<Ops: Operations> Drop for TtyPort<Ops> {
+    fn drop(&mut self) {
+        // SAFETY: Port was initialized in new(), must be destroyed.
+        unsafe { bindings::tty_port_destroy(self.0.get()) };
+    }
+}
+
+/// TTY port operations trait.
+///
+/// Implement to define callbacks for port events. The `PortData` type specifies
+/// data stored alongside the port in [`DriverPort`].
+#[vtable]
+pub trait Operations: Sized {
+    /// Port-specific data type stored in [`DriverPort`].
+    type PortData: Sync;
+
+    /// Called when the port is shut down (last user closes the device).
+    fn shutdown(_port: &DriverPort<Self>) {
+        build_error!(VTABLE_DEFAULT_ERROR)
+    }
+}
+
+/// Vtable adapter for port operations.
+struct OperationsVTable<Ops: Operations>(PhantomData<Ops>);
+
+impl<Ops: Operations> OperationsVTable<Ops> {
+    /// # Safety
+    /// `port` must be a valid `tty_port` within a `DriverPort<Ops>`.
+    unsafe extern "C" fn shutdown(port: *mut bindings::tty_port) {
+        // SAFETY: Port was registered with this vtable.
+        let driver_port = unsafe { DriverPort::<Ops>::from_raw(port) };
+        Ops::shutdown(driver_port);
+    }
+
+    const VTABLE: bindings::tty_port_operations = bindings::tty_port_operations {
+        shutdown: if Ops::HAS_SHUTDOWN {
+            Some(Self::shutdown)
+        } else {
+            None
+        },
+        carrier_raised: None,
+        dtr_rts: None,
+        activate: None,
+        destruct: None,
+    };
+
+    const fn build() -> &'static bindings::tty_port_operations {
+        &Self::VTABLE
+    }
+}

-- 
2.43.0

