From: Igor Korotin <igor.korotin.linux@gmail.com>
Date: Sat, 31 Jan 2026 14:12:43 +0000
Subject: [PATCH 1/5] rust: i2c: split client and adapter code into separate
 files
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260131-i2c-adapter-v1-1-5a436e34cd1a@gmail.com>
References: <20260131-i2c-adapter-v1-0-5a436e34cd1a@gmail.com>
In-Reply-To: <20260131-i2c-adapter-v1-0-5a436e34cd1a@gmail.com>
To: Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Wolfram Sang <wsa+renesas@sang-engineering.com>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-i2c@vger.kernel.org, markus.probst@posteo.de, 
 Igor Korotin <igor.korotin.linux@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769868772; l=24758;
 i=igor.korotin.linux@gmail.com; s=20260125; h=from:subject:message-id;
 bh=CWpKvsEF4lsRAwSev7dxPtlbm4RTfe9OSNpltobCOxc=;
 b=RAoYsPaqJqAJUfYs3yZPm2bn1sQD/qcMOMPVPMEggGu6R7b3HHKSjSWaBdFUZ/WG3541Msos3
 yskRH0nCWzSD9CffxfWb9jOEUXQS8pZYixVwhXUUGFBmKT2nod2BskI
X-Developer-Key: i=igor.korotin.linux@gmail.com; a=ed25519;
 pk=SjZ//wxnynZgJJgTqANyU10A7hdQQdDXLvXIr+zWroE=
X-Endpoint-Received: by B4 Relay for igor.korotin.linux@gmail.com/20260125 with auth_id=615
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reorganize the I2C module by splitting client-related and
adapter-related code into separate files for better maintainability.

- Move client traits and implementations to i2c/client.rs
- Move adapter traits and implementations to i2c/adapter.rs

Signed-off-by: Igor Korotin <igor.korotin.linux@gmail.com>
---
 MAINTAINERS                     |   1 +
 rust/kernel/i2c.rs              | 253 ++--------------------------------------
 rust/kernel/i2c/adapter.rs      |  80 +++++++++++++
 rust/kernel/i2c/client.rs       | 192 ++++++++++++++++++++++++++++++
 samples/rust/rust_driver_i2c.rs |  10 +-
 samples/rust/rust_i2c_client.rs |  15 ++-
 6 files changed, 293 insertions(+), 258 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index f6bc65de83c7..60662984176d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -11886,6 +11886,7 @@ R:	Danilo Krummrich <dakr@kernel.org>
 R:	Daniel Almeida <daniel.almeida@collabora.com>
 L:	rust-for-linux@vger.kernel.org
 S:	Maintained
+F:	rust/i2c/*
 F:	rust/kernel/i2c.rs
 F:	samples/rust/rust_driver_i2c.rs
 F:	samples/rust/rust_i2c_client.rs
diff --git a/rust/kernel/i2c.rs b/rust/kernel/i2c.rs
index 792a71b15463..0bebfde3e495 100644
--- a/rust/kernel/i2c.rs
+++ b/rust/kernel/i2c.rs
@@ -1,37 +1,25 @@
 // SPDX-License-Identifier: GPL-2.0
 
-//! I2C Driver subsystem
+//! I2C subsystem
 
 // I2C Driver abstractions.
 use crate::{
     acpi,
-    container_of,
     device,
     device_id::{
         RawDeviceId,
         RawDeviceIdIndex, //
     },
-    devres::Devres,
     driver,
     error::*,
+    i2c::client::I2cClient,
     of,
     prelude::*,
-    types::{
-        AlwaysRefCounted,
-        Opaque, //
-    }, //
+    types::Opaque, //
 };
 
-use core::{
-    marker::PhantomData,
-    mem::offset_of,
-    ptr::{
-        from_ref,
-        NonNull, //
-    }, //
-};
-
-use kernel::types::ARef;
+pub mod adapter;
+pub mod client;
 
 /// An I2C device id table.
 #[repr(transparent)]
@@ -291,13 +279,13 @@ macro_rules! module_i2c_driver {
 ///     const ACPI_ID_TABLE: Option<acpi::IdTable<Self::IdInfo>> = Some(&ACPI_TABLE);
 ///
 ///     fn probe(
-///         _idev: &i2c::I2cClient<Core>,
+///         _idev: &i2c::client::I2cClient<Core>,
 ///         _id_info: Option<&Self::IdInfo>,
 ///     ) -> impl PinInit<Self, Error> {
 ///         Err(ENODEV)
 ///     }
 ///
-///     fn shutdown(_idev: &i2c::I2cClient<Core>, this: Pin<&Self>) {
+///     fn shutdown(_idev: &i2c::client::I2cClient<Core>, this: Pin<&Self>) {
 ///     }
 /// }
 ///```
@@ -357,230 +345,3 @@ fn unbind(dev: &I2cClient<device::Core>, this: Pin<&Self>) {
         let _ = (dev, this);
     }
 }
-
-/// The i2c adapter representation.
-///
-/// This structure represents the Rust abstraction for a C `struct i2c_adapter`. The
-/// implementation abstracts the usage of an existing C `struct i2c_adapter` that
-/// gets passed from the C side
-///
-/// # Invariants
-///
-/// A [`I2cAdapter`] instance represents a valid `struct i2c_adapter` created by the C portion of
-/// the kernel.
-#[repr(transparent)]
-pub struct I2cAdapter<Ctx: device::DeviceContext = device::Normal>(
-    Opaque<bindings::i2c_adapter>,
-    PhantomData<Ctx>,
-);
-
-impl<Ctx: device::DeviceContext> I2cAdapter<Ctx> {
-    fn as_raw(&self) -> *mut bindings::i2c_adapter {
-        self.0.get()
-    }
-}
-
-impl I2cAdapter {
-    /// Returns the I2C Adapter index.
-    #[inline]
-    pub fn index(&self) -> i32 {
-        // SAFETY: `self.as_raw` is a valid pointer to a `struct i2c_adapter`.
-        unsafe { (*self.as_raw()).nr }
-    }
-
-    /// Gets pointer to an `i2c_adapter` by index.
-    pub fn get(index: i32) -> Result<ARef<Self>> {
-        // SAFETY: `index` must refer to a valid I2C adapter; the kernel
-        // guarantees that `i2c_get_adapter(index)` returns either a valid
-        // pointer or NULL. `NonNull::new` guarantees the correct check.
-        let adapter = NonNull::new(unsafe { bindings::i2c_get_adapter(index) }).ok_or(ENODEV)?;
-
-        // SAFETY: `adapter` is non-null and points to a live `i2c_adapter`.
-        // `I2cAdapter` is #[repr(transparent)], so this cast is valid.
-        Ok(unsafe { (&*adapter.as_ptr().cast::<I2cAdapter<device::Normal>>()).into() })
-    }
-}
-
-// SAFETY: `I2cAdapter` is a transparent wrapper of a type that doesn't depend on
-// `I2cAdapter`'s generic argument.
-kernel::impl_device_context_deref!(unsafe { I2cAdapter });
-kernel::impl_device_context_into_aref!(I2cAdapter);
-
-// SAFETY: Instances of `I2cAdapter` are always reference-counted.
-unsafe impl crate::types::AlwaysRefCounted for I2cAdapter {
-    fn inc_ref(&self) {
-        // SAFETY: The existence of a shared reference guarantees that the refcount is non-zero.
-        unsafe { bindings::i2c_get_adapter(self.index()) };
-    }
-
-    unsafe fn dec_ref(obj: NonNull<Self>) {
-        // SAFETY: The safety requirements guarantee that the refcount is non-zero.
-        unsafe { bindings::i2c_put_adapter(obj.as_ref().as_raw()) }
-    }
-}
-
-/// The i2c board info representation
-///
-/// This structure represents the Rust abstraction for a C `struct i2c_board_info` structure,
-/// which is used for manual I2C client creation.
-#[repr(transparent)]
-pub struct I2cBoardInfo(bindings::i2c_board_info);
-
-impl I2cBoardInfo {
-    const I2C_TYPE_SIZE: usize = 20;
-    /// Create a new [`I2cBoardInfo`] for a kernel driver.
-    #[inline(always)]
-    pub const fn new(type_: &'static CStr, addr: u16) -> Self {
-        let src = type_.to_bytes_with_nul();
-        build_assert!(src.len() <= Self::I2C_TYPE_SIZE, "Type exceeds 20 bytes");
-        let mut i2c_board_info: bindings::i2c_board_info = pin_init::zeroed();
-        let mut i: usize = 0;
-        while i < src.len() {
-            i2c_board_info.type_[i] = src[i];
-            i += 1;
-        }
-
-        i2c_board_info.addr = addr;
-        Self(i2c_board_info)
-    }
-
-    fn as_raw(&self) -> *const bindings::i2c_board_info {
-        from_ref(&self.0)
-    }
-}
-
-/// The i2c client representation.
-///
-/// This structure represents the Rust abstraction for a C `struct i2c_client`. The
-/// implementation abstracts the usage of an existing C `struct i2c_client` that
-/// gets passed from the C side
-///
-/// # Invariants
-///
-/// A [`I2cClient`] instance represents a valid `struct i2c_client` created by the C portion of
-/// the kernel.
-#[repr(transparent)]
-pub struct I2cClient<Ctx: device::DeviceContext = device::Normal>(
-    Opaque<bindings::i2c_client>,
-    PhantomData<Ctx>,
-);
-
-impl<Ctx: device::DeviceContext> I2cClient<Ctx> {
-    fn as_raw(&self) -> *mut bindings::i2c_client {
-        self.0.get()
-    }
-}
-
-// SAFETY: `I2cClient` is a transparent wrapper of `struct i2c_client`.
-// The offset is guaranteed to point to a valid device field inside `I2cClient`.
-unsafe impl<Ctx: device::DeviceContext> device::AsBusDevice<Ctx> for I2cClient<Ctx> {
-    const OFFSET: usize = offset_of!(bindings::i2c_client, dev);
-}
-
-// SAFETY: `I2cClient` is a transparent wrapper of a type that doesn't depend on
-// `I2cClient`'s generic argument.
-kernel::impl_device_context_deref!(unsafe { I2cClient });
-kernel::impl_device_context_into_aref!(I2cClient);
-
-// SAFETY: Instances of `I2cClient` are always reference-counted.
-unsafe impl AlwaysRefCounted for I2cClient {
-    fn inc_ref(&self) {
-        // SAFETY: The existence of a shared reference guarantees that the refcount is non-zero.
-        unsafe { bindings::get_device(self.as_ref().as_raw()) };
-    }
-
-    unsafe fn dec_ref(obj: NonNull<Self>) {
-        // SAFETY: The safety requirements guarantee that the refcount is non-zero.
-        unsafe { bindings::put_device(&raw mut (*obj.as_ref().as_raw()).dev) }
-    }
-}
-
-impl<Ctx: device::DeviceContext> AsRef<device::Device<Ctx>> for I2cClient<Ctx> {
-    fn as_ref(&self) -> &device::Device<Ctx> {
-        let raw = self.as_raw();
-        // SAFETY: By the type invariant of `Self`, `self.as_raw()` is a pointer to a valid
-        // `struct i2c_client`.
-        let dev = unsafe { &raw mut (*raw).dev };
-
-        // SAFETY: `dev` points to a valid `struct device`.
-        unsafe { device::Device::from_raw(dev) }
-    }
-}
-
-impl<Ctx: device::DeviceContext> TryFrom<&device::Device<Ctx>> for &I2cClient<Ctx> {
-    type Error = kernel::error::Error;
-
-    fn try_from(dev: &device::Device<Ctx>) -> Result<Self, Self::Error> {
-        // SAFETY: By the type invariant of `Device`, `dev.as_raw()` is a valid pointer to a
-        // `struct device`.
-        if unsafe { bindings::i2c_verify_client(dev.as_raw()).is_null() } {
-            return Err(EINVAL);
-        }
-
-        // SAFETY: We've just verified that the type of `dev` equals to
-        // `bindings::i2c_client_type`, hence `dev` must be embedded in a valid
-        // `struct i2c_client` as guaranteed by the corresponding C code.
-        let idev = unsafe { container_of!(dev.as_raw(), bindings::i2c_client, dev) };
-
-        // SAFETY: `idev` is a valid pointer to a `struct i2c_client`.
-        Ok(unsafe { &*idev.cast() })
-    }
-}
-
-// SAFETY: A `I2cClient` is always reference-counted and can be released from any thread.
-unsafe impl Send for I2cClient {}
-
-// SAFETY: `I2cClient` can be shared among threads because all methods of `I2cClient`
-// (i.e. `I2cClient<Normal>) are thread safe.
-unsafe impl Sync for I2cClient {}
-
-/// The registration of an i2c client device.
-///
-/// This type represents the registration of a [`struct i2c_client`]. When an instance of this
-/// type is dropped, its respective i2c client device will be unregistered from the system.
-///
-/// # Invariants
-///
-/// `self.0` always holds a valid pointer to an initialized and registered
-/// [`struct i2c_client`].
-#[repr(transparent)]
-pub struct Registration(NonNull<bindings::i2c_client>);
-
-impl Registration {
-    /// The C `i2c_new_client_device` function wrapper for manual I2C client creation.
-    pub fn new<'a>(
-        i2c_adapter: &I2cAdapter,
-        i2c_board_info: &I2cBoardInfo,
-        parent_dev: &'a device::Device<device::Bound>,
-    ) -> impl PinInit<Devres<Self>, Error> + 'a {
-        Devres::new(parent_dev, Self::try_new(i2c_adapter, i2c_board_info))
-    }
-
-    fn try_new(i2c_adapter: &I2cAdapter, i2c_board_info: &I2cBoardInfo) -> Result<Self> {
-        // SAFETY: the kernel guarantees that `i2c_new_client_device()` returns either a valid
-        // pointer or NULL. `from_err_ptr` separates errors. Following `NonNull::new`
-        // checks for NULL.
-        let raw_dev = from_err_ptr(unsafe {
-            bindings::i2c_new_client_device(i2c_adapter.as_raw(), i2c_board_info.as_raw())
-        })?;
-
-        let dev_ptr = NonNull::new(raw_dev).ok_or(ENODEV)?;
-
-        Ok(Self(dev_ptr))
-    }
-}
-
-impl Drop for Registration {
-    fn drop(&mut self) {
-        // SAFETY: `Drop` is only called for a valid `Registration`, which by invariant
-        // always contains a non-null pointer to an `i2c_client`.
-        unsafe { bindings::i2c_unregister_device(self.0.as_ptr()) }
-    }
-}
-
-// SAFETY: A `Registration` of a `struct i2c_client` can be released from any thread.
-unsafe impl Send for Registration {}
-
-// SAFETY: `Registration` offers no interior mutability (no mutation through &self
-// and no mutable access is exposed)
-unsafe impl Sync for Registration {}
diff --git a/rust/kernel/i2c/adapter.rs b/rust/kernel/i2c/adapter.rs
new file mode 100644
index 000000000000..4a0d2faaf98b
--- /dev/null
+++ b/rust/kernel/i2c/adapter.rs
@@ -0,0 +1,80 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! I2C subsystem
+
+// I2C Adapter abstractions.
+use crate::{
+    bindings,
+    device,
+    error::*,
+    prelude::*,
+    types::Opaque, //
+};
+
+use core::{
+    marker::PhantomData,
+    ptr::NonNull, //
+};
+
+use kernel::types::ARef;
+
+/// The i2c adapter representation.
+///
+/// This structure represents the Rust abstraction for a C `struct i2c_adapter`. The
+/// implementation abstracts the usage of an existing C `struct i2c_adapter` that
+/// gets passed from the C side
+///
+/// # Invariants
+///
+/// A [`I2cAdapter`] instance represents a valid `struct i2c_adapter` created by the C portion of
+/// the kernel.
+#[repr(transparent)]
+pub struct I2cAdapter<Ctx: device::DeviceContext = device::Normal>(
+    Opaque<bindings::i2c_adapter>,
+    PhantomData<Ctx>,
+);
+
+impl<Ctx: device::DeviceContext> I2cAdapter<Ctx> {
+    pub(super) fn as_raw(&self) -> *mut bindings::i2c_adapter {
+        self.0.get()
+    }
+}
+
+impl I2cAdapter {
+    /// Returns the I2C Adapter index.
+    #[inline]
+    pub fn index(&self) -> i32 {
+        // SAFETY: `self.as_raw` is a valid pointer to a `struct i2c_adapter`.
+        unsafe { (*self.as_raw()).nr }
+    }
+
+    /// Gets pointer to an `i2c_adapter` by index.
+    pub fn get(index: i32) -> Result<ARef<Self>> {
+        // SAFETY: `index` must refer to a valid I2C adapter; the kernel
+        // guarantees that `i2c_get_adapter(index)` returns either a valid
+        // pointer or NULL. `NonNull::new` guarantees the correct check.
+        let adapter = NonNull::new(unsafe { bindings::i2c_get_adapter(index) }).ok_or(ENODEV)?;
+
+        // SAFETY: `adapter` is non-null and points to a live `i2c_adapter`.
+        // `I2cAdapter` is #[repr(transparent)], so this cast is valid.
+        Ok(unsafe { (&*adapter.as_ptr().cast::<I2cAdapter<device::Normal>>()).into() })
+    }
+}
+
+// SAFETY: `I2cAdapter` is a transparent wrapper of a type that doesn't depend on
+// `I2cAdapter`'s generic argument.
+kernel::impl_device_context_deref!(unsafe { I2cAdapter });
+kernel::impl_device_context_into_aref!(I2cAdapter);
+
+// SAFETY: Instances of `I2cAdapter` are always reference-counted.
+unsafe impl crate::types::AlwaysRefCounted for I2cAdapter {
+    fn inc_ref(&self) {
+        // SAFETY: The existence of a shared reference guarantees that the refcount is non-zero.
+        unsafe { bindings::i2c_get_adapter(self.index()) };
+    }
+
+    unsafe fn dec_ref(obj: NonNull<Self>) {
+        // SAFETY: The safety requirements guarantee that the refcount is non-zero.
+        unsafe { bindings::i2c_put_adapter(obj.as_ref().as_raw()) }
+    }
+}
diff --git a/rust/kernel/i2c/client.rs b/rust/kernel/i2c/client.rs
new file mode 100644
index 000000000000..a597793ff038
--- /dev/null
+++ b/rust/kernel/i2c/client.rs
@@ -0,0 +1,192 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! I2C subsystem
+
+// I2C Client abstractions.
+use crate::{
+    container_of,
+    device,
+    devres::Devres,
+    error::*,
+    i2c::adapter::I2cAdapter,
+    prelude::*,
+    types::{
+        AlwaysRefCounted,
+        Opaque, //
+    }, //
+};
+
+use core::{
+    marker::PhantomData,
+    mem::offset_of,
+    ptr::{
+        from_ref,
+        NonNull, //
+    }, //
+};
+
+/// The i2c board info representation
+///
+/// This structure represents the Rust abstraction for a C `struct i2c_board_info` structure,
+/// which is used for manual I2C client creation.
+#[repr(transparent)]
+pub struct I2cBoardInfo(bindings::i2c_board_info);
+
+impl I2cBoardInfo {
+    const I2C_TYPE_SIZE: usize = 20;
+    /// Create a new [`I2cBoardInfo`] for a kernel driver.
+    #[inline(always)]
+    pub const fn new(type_: &'static CStr, addr: u16) -> Self {
+        let src = type_.to_bytes_with_nul();
+        build_assert!(src.len() <= Self::I2C_TYPE_SIZE, "Type exceeds 20 bytes");
+        let mut i2c_board_info: bindings::i2c_board_info = pin_init::zeroed();
+        let mut i: usize = 0;
+        while i < src.len() {
+            i2c_board_info.type_[i] = src[i];
+            i += 1;
+        }
+
+        i2c_board_info.addr = addr;
+        Self(i2c_board_info)
+    }
+
+    fn as_raw(&self) -> *const bindings::i2c_board_info {
+        from_ref(&self.0)
+    }
+}
+
+/// The i2c client representation.
+///
+/// This structure represents the Rust abstraction for a C `struct i2c_client`. The
+/// implementation abstracts the usage of an existing C `struct i2c_client` that
+/// gets passed from the C side
+///
+/// # Invariants
+///
+/// A [`I2cClient`] instance represents a valid `struct i2c_client` created by the C portion of
+/// the kernel.
+#[repr(transparent)]
+pub struct I2cClient<Ctx: device::DeviceContext = device::Normal>(
+    Opaque<bindings::i2c_client>,
+    PhantomData<Ctx>,
+);
+
+impl<Ctx: device::DeviceContext> I2cClient<Ctx> {
+    pub(super) fn as_raw(&self) -> *mut bindings::i2c_client {
+        self.0.get()
+    }
+}
+
+// SAFETY: `I2cClient` is a transparent wrapper of `struct i2c_client`.
+// The offset is guaranteed to point to a valid device field inside `I2cClient`.
+unsafe impl<Ctx: device::DeviceContext> device::AsBusDevice<Ctx> for I2cClient<Ctx> {
+    const OFFSET: usize = offset_of!(bindings::i2c_client, dev);
+}
+
+// SAFETY: `I2cClient` is a transparent wrapper of a type that doesn't depend on
+// `I2cClient`'s generic argument.
+kernel::impl_device_context_deref!(unsafe { I2cClient });
+kernel::impl_device_context_into_aref!(I2cClient);
+
+// SAFETY: Instances of `I2cClient` are always reference-counted.
+unsafe impl AlwaysRefCounted for I2cClient {
+    fn inc_ref(&self) {
+        // SAFETY: The existence of a shared reference guarantees that the refcount is non-zero.
+        unsafe { bindings::get_device(self.as_ref().as_raw()) };
+    }
+
+    unsafe fn dec_ref(obj: NonNull<Self>) {
+        // SAFETY: The safety requirements guarantee that the refcount is non-zero.
+        unsafe { bindings::put_device(&raw mut (*obj.as_ref().as_raw()).dev) }
+    }
+}
+
+impl<Ctx: device::DeviceContext> AsRef<device::Device<Ctx>> for I2cClient<Ctx> {
+    fn as_ref(&self) -> &device::Device<Ctx> {
+        let raw = self.as_raw();
+        // SAFETY: By the type invariant of `Self`, `self.as_raw()` is a pointer to a valid
+        // `struct i2c_client`.
+        let dev = unsafe { &raw mut (*raw).dev };
+
+        // SAFETY: `dev` points to a valid `struct device`.
+        unsafe { device::Device::from_raw(dev) }
+    }
+}
+
+impl<Ctx: device::DeviceContext> TryFrom<&device::Device<Ctx>> for &I2cClient<Ctx> {
+    type Error = kernel::error::Error;
+
+    fn try_from(dev: &device::Device<Ctx>) -> Result<Self, Self::Error> {
+        // SAFETY: By the type invariant of `Device`, `dev.as_raw()` is a valid pointer to a
+        // `struct device`.
+        if unsafe { bindings::i2c_verify_client(dev.as_raw()).is_null() } {
+            return Err(EINVAL);
+        }
+
+        // SAFETY: We've just verified that the type of `dev` equals to
+        // `bindings::i2c_client_type`, hence `dev` must be embedded in a valid
+        // `struct i2c_client` as guaranteed by the corresponding C code.
+        let idev = unsafe { container_of!(dev.as_raw(), bindings::i2c_client, dev) };
+
+        // SAFETY: `idev` is a valid pointer to a `struct i2c_client`.
+        Ok(unsafe { &*idev.cast() })
+    }
+}
+
+// SAFETY: A `I2cClient` is always reference-counted and can be released from any thread.
+unsafe impl Send for I2cClient {}
+
+// SAFETY: `I2cClient` can be shared among threads because all methods of `I2cClient`
+// (i.e. `I2cClient<Normal>) are thread safe.
+unsafe impl Sync for I2cClient {}
+
+/// The registration of an i2c client device.
+///
+/// This type represents the registration of a [`struct i2c_client`]. When an instance of this
+/// type is dropped, its respective i2c client device will be unregistered from the system.
+///
+/// # Invariants
+///
+/// `self.0` always holds a valid pointer to an initialized and registered
+/// [`struct i2c_client`].
+#[repr(transparent)]
+pub struct Registration(NonNull<bindings::i2c_client>);
+
+impl Registration {
+    /// The C `i2c_new_client_device` function wrapper for manual I2C client creation.
+    pub fn new<'a>(
+        i2c_adapter: &I2cAdapter,
+        i2c_board_info: &I2cBoardInfo,
+        parent_dev: &'a device::Device<device::Bound>,
+    ) -> impl PinInit<Devres<Self>, Error> + 'a {
+        Devres::new(parent_dev, Self::try_new(i2c_adapter, i2c_board_info))
+    }
+
+    fn try_new(i2c_adapter: &I2cAdapter, i2c_board_info: &I2cBoardInfo) -> Result<Self> {
+        // SAFETY: the kernel guarantees that `i2c_new_client_device()` returns either a valid
+        // pointer or NULL. `from_err_ptr` separates errors. Following `NonNull::new`
+        // checks for NULL.
+        let raw_dev = from_err_ptr(unsafe {
+            bindings::i2c_new_client_device(i2c_adapter.as_raw(), i2c_board_info.as_raw())
+        })?;
+
+        let dev_ptr = NonNull::new(raw_dev).ok_or(ENODEV)?;
+
+        Ok(Self(dev_ptr))
+    }
+}
+
+impl Drop for Registration {
+    fn drop(&mut self) {
+        // SAFETY: `Drop` is only called for a valid `Registration`, which by invariant
+        // always contains a non-null pointer to an `i2c_client`.
+        unsafe { bindings::i2c_unregister_device(self.0.as_ptr()) }
+    }
+}
+
+// SAFETY: A `Registration` of a `struct i2c_client` can be released from any thread.
+unsafe impl Send for Registration {}
+
+// SAFETY: `Registration` offers no interior mutability (no mutation through &self
+// and no mutable access is exposed)
+unsafe impl Sync for Registration {}
diff --git a/samples/rust/rust_driver_i2c.rs b/samples/rust/rust_driver_i2c.rs
index 6be79f9e9fb5..af5e9aae4f06 100644
--- a/samples/rust/rust_driver_i2c.rs
+++ b/samples/rust/rust_driver_i2c.rs
@@ -6,6 +6,7 @@
     acpi,
     device::Core,
     i2c,
+    i2c::client::I2cClient,
     of,
     prelude::*, //
 };
@@ -40,10 +41,7 @@ impl i2c::Driver for SampleDriver {
     const I2C_ID_TABLE: Option<i2c::IdTable<Self::IdInfo>> = Some(&I2C_TABLE);
     const OF_ID_TABLE: Option<of::IdTable<Self::IdInfo>> = Some(&OF_TABLE);
 
-    fn probe(
-        idev: &i2c::I2cClient<Core>,
-        info: Option<&Self::IdInfo>,
-    ) -> impl PinInit<Self, Error> {
+    fn probe(idev: &I2cClient<Core>, info: Option<&Self::IdInfo>) -> impl PinInit<Self, Error> {
         let dev = idev.as_ref();
 
         dev_info!(dev, "Probe Rust I2C driver sample.\n");
@@ -55,11 +53,11 @@ fn probe(
         Ok(Self)
     }
 
-    fn shutdown(idev: &i2c::I2cClient<Core>, _this: Pin<&Self>) {
+    fn shutdown(idev: &I2cClient<Core>, _this: Pin<&Self>) {
         dev_info!(idev.as_ref(), "Shutdown Rust I2C driver sample.\n");
     }
 
-    fn unbind(idev: &i2c::I2cClient<Core>, _this: Pin<&Self>) {
+    fn unbind(idev: &I2cClient<Core>, _this: Pin<&Self>) {
         dev_info!(idev.as_ref(), "Unbind Rust I2C driver sample.\n");
     }
 }
diff --git a/samples/rust/rust_i2c_client.rs b/samples/rust/rust_i2c_client.rs
index 8d2c12e535b0..4b3dcf21230c 100644
--- a/samples/rust/rust_i2c_client.rs
+++ b/samples/rust/rust_i2c_client.rs
@@ -71,7 +71,11 @@
     acpi,
     device,
     devres::Devres,
-    i2c,
+    i2c::{
+        adapter::I2cAdapter,
+        client::I2cBoardInfo,
+        client::Registration, //
+    }, //
     of,
     platform,
     prelude::*,
@@ -82,7 +86,7 @@
 struct SampleDriver {
     parent_dev: ARef<platform::Device>,
     #[pin]
-    _reg: Devres<i2c::Registration>,
+    _reg: Devres<Registration>,
 }
 
 kernel::of_device_table!(
@@ -101,8 +105,7 @@ struct SampleDriver {
 
 const SAMPLE_I2C_CLIENT_ADDR: u16 = 0x30;
 const SAMPLE_I2C_ADAPTER_INDEX: i32 = 0;
-const BOARD_INFO: i2c::I2cBoardInfo =
-    i2c::I2cBoardInfo::new(c"rust_driver_i2c", SAMPLE_I2C_CLIENT_ADDR);
+const BOARD_INFO: I2cBoardInfo = I2cBoardInfo::new(c"rust_driver_i2c", SAMPLE_I2C_CLIENT_ADDR);
 
 impl platform::Driver for SampleDriver {
     type IdInfo = ();
@@ -122,9 +125,9 @@ fn probe(
             parent_dev: pdev.into(),
 
             _reg <- {
-                let adapter = i2c::I2cAdapter::get(SAMPLE_I2C_ADAPTER_INDEX)?;
+                let adapter = I2cAdapter::get(SAMPLE_I2C_ADAPTER_INDEX)?;
 
-                i2c::Registration::new(&adapter, &BOARD_INFO, pdev.as_ref())
+                Registration::new(&adapter, &BOARD_INFO, pdev.as_ref())
             }
         })
     }

-- 
2.43.0

