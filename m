From: Igor Korotin <igor.korotin.linux@gmail.com>
Date: Sat, 31 Jan 2026 14:12:45 +0000
Subject: [PATCH 3/5] rust: i2c: Add I2C Adapter registration abstractions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260131-i2c-adapter-v1-3-5a436e34cd1a@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769868772; l=17907;
 i=igor.korotin.linux@gmail.com; s=20260125; h=from:subject:message-id;
 bh=O00AxujwITCbYlKLKHLjBJTRZG5L0086MO+yva6+Jr4=;
 b=LxB+rq1ASkCN+in6cH21y6M6VHepp11Uq292hpMHHaCkpy5Ly9cB5ZYm2tziGKZ6z/8F0CToL
 IEwMwh1V+a7ACCXsRDws/S+z/zU9cv5JOP+12oQBhNP+CodhGCieLMd
X-Developer-Key: i=igor.korotin.linux@gmail.com; a=ed25519;
 pk=SjZ//wxnynZgJJgTqANyU10A7hdQQdDXLvXIr+zWroE=
X-Endpoint-Received: by B4 Relay for igor.korotin.linux@gmail.com/20260125 with auth_id=615
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add safe Rust abstractions for I2C adapter registration and
management, wrapping the C functions `i2c_add_adapter` and
`i2c_del_adapter`.

This includes:
- Hide `struct i2c_algorithm` unions from bindgen to avoid unnecessary
  mangles.
- Safe wrappers upon `struct i2c_msg` and `struct i2c_smbus_data`
- I2C Algorithm wrapper around `struct i2c_algorithm`
- I2C Adapter Flags wrapper
- Registration/deregistration logic for I2C adapters

Signed-off-by: Igor Korotin <igor.korotin.linux@gmail.com>
---
 include/linux/i2c.h        |   6 +
 rust/kernel/i2c.rs         |   1 +
 rust/kernel/i2c/adapter.rs | 120 ++++++++++++++++++
 rust/kernel/i2c/algo.rs    | 300 +++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 427 insertions(+)

diff --git a/include/linux/i2c.h b/include/linux/i2c.h
index 20fd41b51d5c..c176243de254 100644
--- a/include/linux/i2c.h
+++ b/include/linux/i2c.h
@@ -548,18 +548,24 @@ struct i2c_algorithm {
 	 * smbus_xfer. If set to NULL, the SMBus protocol is simulated
 	 * using common I2C messages.
 	 */
+#ifndef __BINDGEN__
 	union {
+#endif
 		int (*xfer)(struct i2c_adapter *adap, struct i2c_msg *msgs,
 			    int num);
+#ifndef __BINDGEN__
 		int (*master_xfer)(struct i2c_adapter *adap, struct i2c_msg *msgs,
 				   int num);
 	};
 	union {
+#endif
 		int (*xfer_atomic)(struct i2c_adapter *adap,
 				   struct i2c_msg *msgs, int num);
+#ifndef __BINDGEN__
 		int (*master_xfer_atomic)(struct i2c_adapter *adap,
 					   struct i2c_msg *msgs, int num);
 	};
+#endif
 	int (*smbus_xfer)(struct i2c_adapter *adap, u16 addr,
 			  unsigned short flags, char read_write,
 			  u8 command, int size, union i2c_smbus_data *data);
diff --git a/rust/kernel/i2c.rs b/rust/kernel/i2c.rs
index 0bebfde3e495..af33a3be83c4 100644
--- a/rust/kernel/i2c.rs
+++ b/rust/kernel/i2c.rs
@@ -19,6 +19,7 @@
 };
 
 pub mod adapter;
+pub mod algo;
 pub mod client;
 
 /// An I2C device id table.
diff --git a/rust/kernel/i2c/adapter.rs b/rust/kernel/i2c/adapter.rs
index 4a0d2faaf98b..ec64c1327792 100644
--- a/rust/kernel/i2c/adapter.rs
+++ b/rust/kernel/i2c/adapter.rs
@@ -6,7 +6,9 @@
 use crate::{
     bindings,
     device,
+    devres::Devres,
     error::*,
+    i2c::algo::*,
     prelude::*,
     types::Opaque, //
 };
@@ -38,6 +40,15 @@ impl<Ctx: device::DeviceContext> I2cAdapter<Ctx> {
     pub(super) fn as_raw(&self) -> *mut bindings::i2c_adapter {
         self.0.get()
     }
+
+    /// Convert a raw C `struct i2c_adapter` pointer to a `&'a I2cAdapter`.
+    pub(super) fn from_raw<'a>(ptr: *mut bindings::i2c_adapter) -> &'a Self {
+        // SAFETY: Callers must ensure that `ptr` is valid, non-null, and has a non-zero reference
+        // count, i.e. it must be ensured that the reference count of the C `struct i2c_adapter`
+        // `ptr` points to can't drop to zero, for the duration of this function call and the entire
+        // duration when the returned reference exists.
+        unsafe { &*ptr.cast() }
+    }
 }
 
 impl I2cAdapter {
@@ -78,3 +89,112 @@ unsafe fn dec_ref(obj: NonNull<Self>) {
         unsafe { bindings::i2c_put_adapter(obj.as_ref().as_raw()) }
     }
 }
+
+impl<Ctx: device::DeviceContext> AsRef<device::Device<Ctx>> for I2cAdapter<Ctx> {
+    fn as_ref(&self) -> &device::Device<Ctx> {
+        let raw = self.as_raw();
+        // SAFETY: By the type invariant of `Self`, `self.as_raw()` is a pointer to a valid
+        // `struct i2c_adapter`.
+        let dev = unsafe { &raw mut (*raw).dev };
+
+        // SAFETY: `dev` points to a valid `struct device`.
+        unsafe { device::Device::from_raw(dev) }
+    }
+}
+
+/// Options for creating an I2C adapter device.
+pub struct I2cAdapterOptions {
+    /// The name of the I2C adapter device.
+    pub name: &'static CStr,
+}
+
+impl I2cAdapterOptions {
+    /// Create a raw `struct i2c_adapter` ready for registration.
+    pub const fn as_raw<T: I2cAlgorithm>(self) -> bindings::i2c_adapter {
+        let mut adapter: bindings::i2c_adapter = pin_init::zeroed();
+        // TODO: make it some other way... this looks like shit
+        let src = self.name.to_bytes_with_nul();
+        let mut i: usize = 0;
+        while i < src.len() {
+            adapter.name[i] = src[i];
+            i += 1;
+        }
+        adapter.algo = I2cAlgorithmVTable::<T>::build();
+
+        adapter
+    }
+}
+
+/// A registration of a I2C Adapter.
+///
+/// # Invariants
+///
+/// - `inner` contains a `struct i2c_adapter` that is registered using
+///   `i2c_add_adapter()`.
+/// - This registration remains valid for the entire lifetime of the
+///   [`i2c::adapter::Registration<T>`] instance.
+/// - Deregistration occurs exactly once in [`Drop`] via `i2c_del_adapter()`.
+/// - `inner` wraps a valid, pinned `i2c_adapter` created using
+///   [`I2cAdapterOptions::as_raw`].
+#[repr(transparent)]
+#[pin_data(PinnedDrop)]
+pub struct Registration<T> {
+    #[pin]
+    inner: Opaque<bindings::i2c_adapter>,
+    t_: PhantomData<T>,
+}
+
+impl<T: I2cAlgorithm> Registration<T> {
+    /// Register an I2C adapter.
+    pub fn register<'a>(
+        parent_dev: &'a device::Device<device::Bound>,
+        opts: I2cAdapterOptions,
+    ) -> impl PinInit<Devres<Self>, Error> + 'a
+    where
+        T: 'a,
+    {
+        Devres::new(parent_dev, Self::new(parent_dev, opts))
+    }
+
+    fn new<'a>(
+        parent_dev: &'a device::Device<device::Bound>,
+        opts: I2cAdapterOptions,
+    ) -> impl PinInit<Self, Error> + use<'a, T>
+    where
+        T: 'a,
+    {
+        try_pin_init! { Self {
+            inner <- Opaque::try_ffi_init(move |slot: *mut bindings::i2c_adapter| {
+                // SAFETY: The initializer can write to the provided `slot`.
+                unsafe {slot.write(opts.as_raw::<T>()) };
+
+                // SAFETY: `slot` is valid from the initializer; `parent_dev` outlives the adapter.
+                unsafe { (*slot).dev.parent = parent_dev.as_raw() };
+
+                // SAFETY: the `struct i2c_adapter` was just created in slot. The adapter will
+                // get unregistered before `slot` is deallocated because the memory is pinned and
+                // the destructor of this type deallocates the memory.
+                // INVARIANT: If this returns `Ok(())`, then the `slot` will contain a registered
+                // i2c adapter.
+                to_result(unsafe {bindings::i2c_add_adapter(slot)})
+            }),
+            t_: PhantomData,
+            }
+        }
+    }
+}
+
+#[pinned_drop]
+impl<T> PinnedDrop for Registration<T> {
+    fn drop(self: Pin<&mut Self>) {
+        // SAFETY: We know that the device is registered by the type invariants.
+        unsafe { bindings::i2c_del_adapter(self.inner.get()) };
+    }
+}
+
+// SAFETY: A `Registration` of a `struct i2c_client` can be released from any thread.
+unsafe impl<T> Send for Registration<T> {}
+
+// SAFETY: `Registration` offers no interior mutability (no mutation through &self
+// and no mutable access is exposed)
+unsafe impl<T> Sync for Registration<T> {}
diff --git a/rust/kernel/i2c/algo.rs b/rust/kernel/i2c/algo.rs
new file mode 100644
index 000000000000..ca9fcc385426
--- /dev/null
+++ b/rust/kernel/i2c/algo.rs
@@ -0,0 +1,300 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! I2C subsystem
+
+// I2C Algorithm abstractions.
+use crate::{
+    bindings::{
+        i2c_adapter,
+        i2c_msg,
+        i2c_smbus_data,
+        u16_,
+        u32_,
+        u8_, //
+    },
+    device::Normal,
+    error::VTABLE_DEFAULT_ERROR,
+    i2c::adapter::I2cAdapter,
+    prelude::*,
+    types::Opaque, //
+};
+
+use core::{
+    marker::PhantomData, //
+};
+
+/// The i2c msg representation.
+///
+/// This structure represents the Rust abstraction for a C `struct i2c_msg`. The
+/// implementation abstracts the usage of an existing C `struct i2c_msg` that
+/// gets passed from/to the C side
+///
+/// # Invariants
+///
+/// A [`I2cMsg`] instance represents a valid `struct i2c_msg` created by the C portion of
+/// the kernel.
+#[repr(transparent)]
+pub struct I2cMsg(Opaque<bindings::i2c_msg>);
+
+impl I2cMsg {
+    /// Convert a raw C `struct i2c_msg` pointers to `&'a mut [I2cMsg]`.
+    pub fn from_raw_parts_mut<'a>(msgs: *mut bindings::i2c_msg, len: usize) -> &'a mut [Self] {
+        // SAFETY: Callers must ensure that `msgs` is valid, non-null, for the duration of this
+        // function call and the entire duration when the returned slice exists.
+        unsafe { core::slice::from_raw_parts_mut(msgs.cast::<Self>(), len) }
+    }
+}
+
+/// The i2c smbus data representation.
+///
+/// This structure represents the Rust abstraction for a C `struct i2c_smbus_data`. The
+/// implementation abstracts the usage of an existing C `struct i2c_smbus_data` that
+/// gets passed from/to the C side
+///
+/// # Invariants
+///
+/// A [`I2cSmbusData`] instance represents a valid `struct i2c_smbus_data` created by the C
+/// portion of the kernel.
+#[repr(transparent)]
+pub struct I2cSmbusData(Opaque<bindings::i2c_smbus_data>);
+
+impl I2cSmbusData {
+    /// Convert a raw C `struct i2c_smbus_data` pointer to `&'a I2cSmbusData`.
+    fn from_raw<'a>(ptr: *const bindings::i2c_smbus_data) -> &'a Self {
+        // SAFETY: Callers must ensure that `ptr` is valid, non-null, for the duration of this
+        // function call and the entire duration when the returned reference exists.
+        unsafe { &*ptr.cast() }
+    }
+}
+
+kernel::define_flags!(
+    I2cFlags(u32),
+    I2C_FUNC_I2C = bindings::I2C_FUNC_I2C,
+    I2C_FUNC_10BIT_ADDR = bindings::I2C_FUNC_10BIT_ADDR,
+    I2C_FUNC_PROTOCOL_MANGLING = bindings::I2C_FUNC_PROTOCOL_MANGLING,
+    I2C_FUNC_SMBUS_PEC = bindings::I2C_FUNC_SMBUS_PEC,
+    I2C_FUNC_NOSTART = bindings::I2C_FUNC_NOSTART,
+    I2C_FUNC_SLAVE = bindings::I2C_FUNC_SLAVE,
+    I2C_FUNC_SMBUS_BLOCK_PROC_CALL = bindings::I2C_FUNC_SMBUS_BLOCK_PROC_CALL,
+    I2C_FUNC_SMBUS_QUICK = bindings::I2C_FUNC_SMBUS_QUICK,
+    I2C_FUNC_SMBUS_READ_BYTE = bindings::I2C_FUNC_SMBUS_READ_BYTE,
+    I2C_FUNC_SMBUS_WRITE_BYTE = bindings::I2C_FUNC_SMBUS_WRITE_BYTE,
+    I2C_FUNC_SMBUS_READ_BYTE_DATA = bindings::I2C_FUNC_SMBUS_READ_BYTE_DATA,
+    I2C_FUNC_SMBUS_WRITE_BYTE_DATA = bindings::I2C_FUNC_SMBUS_WRITE_BYTE_DATA,
+    I2C_FUNC_SMBUS_READ_WORD_DATA = bindings::I2C_FUNC_SMBUS_READ_WORD_DATA,
+    I2C_FUNC_SMBUS_WRITE_WORD_DATA = bindings::I2C_FUNC_SMBUS_WRITE_WORD_DATA,
+    I2C_FUNC_SMBUS_PROC_CALL = bindings::I2C_FUNC_SMBUS_PROC_CALL,
+    I2C_FUNC_SMBUS_READ_BLOCK_DATA = bindings::I2C_FUNC_SMBUS_READ_BLOCK_DATA,
+    I2C_FUNC_SMBUS_WRITE_BLOCK_DATA = bindings::I2C_FUNC_SMBUS_WRITE_BLOCK_DATA,
+    I2C_FUNC_SMBUS_READ_I2C_BLOCK = bindings::I2C_FUNC_SMBUS_READ_I2C_BLOCK,
+    I2C_FUNC_SMBUS_WRITE_I2C_BLOCK = bindings::I2C_FUNC_SMBUS_WRITE_I2C_BLOCK,
+    I2C_FUNC_SMBUS_HOST_NOTIFY = bindings::I2C_FUNC_SMBUS_HOST_NOTIFY,
+);
+
+/// Trait implemented by the private data of an i2c adapter.
+#[vtable]
+pub trait I2cAlgorithm {
+    /// Handler for transfer a given number of messages defined by the msgs array
+    /// via the specified adapter.
+    fn xfer(_adap: &I2cAdapter<Normal>, _msgs: &mut [I2cMsg]) -> Result {
+        build_error!(VTABLE_DEFAULT_ERROR)
+    }
+
+    /// Same as @xfer. Yet, only using atomic context so e.g. PMICs
+    /// can be accessed very late before shutdown. Optional.
+    fn xfer_atomic(_adap: &I2cAdapter<Normal>, _msgs: &mut [I2cMsg]) -> Result {
+        build_error!(VTABLE_DEFAULT_ERROR)
+    }
+
+    /// Issue SMBus transactions to the given I2C adapter. If this
+    /// is not present, then the bus layer will try and convert the SMBus calls
+    /// into I2C transfers instead.
+    fn smbus_xfer(
+        _adap: &I2cAdapter<Normal>,
+        _addr: u16,
+        _flags: u16,
+        _read_write: u8,
+        _command: u8,
+        _size: usize,
+        _data: &I2cSmbusData,
+    ) -> Result {
+        build_error!(VTABLE_DEFAULT_ERROR)
+    }
+
+    /// Same as @smbus_xfer. Yet, only using atomic context
+    /// so e.g. PMICs can be accessed very late before shutdown. Optional.
+    fn smbus_xfer_atomic(
+        _adap: &I2cAdapter<Normal>,
+        _addr: u16,
+        _flags: u16,
+        _read_write: u8,
+        _command: u8,
+        _size: usize,
+        _data: &I2cSmbusData,
+    ) -> Result {
+        build_error!(VTABLE_DEFAULT_ERROR)
+    }
+
+    /// Return the flags that this algorithm/adapter pair supports
+    /// from the ``I2C_FUNC_*`` flags.
+    fn functionality(_adap: &I2cAdapter<Normal>) -> I2cFlags {
+        build_error!(VTABLE_DEFAULT_ERROR)
+    }
+}
+
+/// A vtable for the I2C xfer operations of a Rust i2c adapter.
+pub struct I2cAlgorithmVTable<T: I2cAlgorithm>(PhantomData<T>);
+
+impl<T: I2cAlgorithm> I2cAlgorithmVTable<T> {
+    /// # Safety
+    ///
+    /// `adap` must be a valid pointer to `struct i2c_adapter` that is associated with a
+    /// `i2c::adapter::Registration<T>`.
+    /// `msgs` must be a valid pointer to `struct i2c_msg` for reading/writing.
+    unsafe extern "C" fn xfer(
+        adap: *mut i2c_adapter,
+        msgs: *mut i2c_msg,
+        num: ffi::c_int,
+    ) -> ffi::c_int {
+        let num = match usize::try_from(num) {
+            Ok(num) => num,
+            Err(_err) => return EINVAL.to_errno(),
+        };
+
+        let msg_slice = I2cMsg::from_raw_parts_mut(msgs, num);
+
+        match T::xfer(I2cAdapter::from_raw(adap), msg_slice) {
+            Ok(()) => 0,
+            Err(err) => err.to_errno(),
+        }
+    }
+
+    /// # Safety
+    ///
+    /// `adap` must be a valid pointer to `struct i2c_adapter` that is associated with a
+    /// `i2c::adapter::Registration<T>`.
+    /// `msgs` must be a valid pointer to `struct i2c_msg` for reading/writing.
+    unsafe extern "C" fn xfer_atomic(
+        adap: *mut i2c_adapter,
+        msgs: *mut i2c_msg,
+        num: ffi::c_int,
+    ) -> ffi::c_int {
+        let num = match usize::try_from(num) {
+            Ok(num) => num,
+            Err(_err) => return EINVAL.to_errno(),
+        };
+
+        let msg_slice = I2cMsg::from_raw_parts_mut(msgs, num);
+
+        match T::xfer_atomic(I2cAdapter::from_raw(adap), msg_slice) {
+            Ok(()) => 0,
+            Err(err) => err.to_errno(),
+        }
+    }
+
+    /// # Safety
+    ///
+    /// `adap` must be a valid pointer to `struct i2c_adapter` that is associated with a
+    /// `i2c::adapter::Registration<T>`.
+    /// `data` must be a valid pointer to `struct i2c_smbus_data` for reading/writing.
+    unsafe extern "C" fn smbus_xfer(
+        adap: *mut i2c_adapter,
+        addr: u16_,
+        flags: ffi::c_ushort,
+        read_write: ffi::c_char,
+        command: u8_,
+        size: ffi::c_int,
+        data: *mut i2c_smbus_data,
+    ) -> ffi::c_int {
+        let size = match usize::try_from(size) {
+            Ok(size) => size,
+            Err(_err) => return EINVAL.to_errno(),
+        };
+
+        let data = I2cSmbusData::from_raw(data);
+
+        match T::smbus_xfer(
+            I2cAdapter::from_raw(adap),
+            addr,
+            flags,
+            read_write,
+            command,
+            size,
+            data,
+        ) {
+            Ok(()) => 0,
+            Err(err) => err.to_errno(),
+        }
+    }
+
+    /// # Safety
+    ///
+    /// `adap` must be a valid pointer to `struct i2c_adapter` that is associated with a
+    /// `i2c::adapter::Registration<T>`.
+    /// `data` must be a valid pointer to `struct i2c_smbus_data` for reading/writing.
+    unsafe extern "C" fn smbus_xfer_atomic(
+        adap: *mut i2c_adapter,
+        addr: u16_,
+        flags: ffi::c_ushort,
+        read_write: ffi::c_char,
+        command: u8_,
+        size: ffi::c_int,
+        data: *mut i2c_smbus_data,
+    ) -> ffi::c_int {
+        let size = match usize::try_from(size) {
+            Ok(size) => size,
+            Err(_err) => return EINVAL.to_errno(),
+        };
+
+        let data = I2cSmbusData::from_raw(data);
+
+        match T::smbus_xfer_atomic(
+            I2cAdapter::from_raw(adap),
+            addr,
+            flags,
+            read_write,
+            command,
+            size,
+            data,
+        ) {
+            Ok(()) => 0,
+            Err(err) => err.to_errno(),
+        }
+    }
+
+    /// # Safety
+    ///
+    /// `adap` must be a valid pointer to `struct i2c_adapter` that is associated with a
+    /// `I2cAdapterRegistration<T>`.
+    unsafe extern "C" fn functionality(adap: *mut i2c_adapter) -> u32_ {
+        T::functionality(I2cAdapter::from_raw(adap)).as_raw()
+    }
+
+    const VTABLE: bindings::i2c_algorithm = bindings::i2c_algorithm {
+        xfer: if T::HAS_XFER { Some(Self::xfer) } else { None },
+        xfer_atomic: if T::HAS_XFER_ATOMIC {
+            Some(Self::xfer_atomic)
+        } else {
+            None
+        },
+        smbus_xfer: if T::HAS_SMBUS_XFER {
+            Some(Self::smbus_xfer)
+        } else {
+            None
+        },
+        smbus_xfer_atomic: if T::HAS_SMBUS_XFER_ATOMIC {
+            Some(Self::smbus_xfer_atomic)
+        } else {
+            None
+        },
+        functionality: if T::HAS_FUNCTIONALITY {
+            Some(Self::functionality)
+        } else {
+            None
+        },
+    };
+
+    pub(super) const fn build() -> &'static bindings::i2c_algorithm {
+        &Self::VTABLE
+    }
+}

-- 
2.43.0

