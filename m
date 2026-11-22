From: Nick Dowsett <nick42d@gmail.com>
Date: Sun, 22 Nov 2026 12:28:15 +0800
Subject: [PATCH 2/4] rust: wmi: add DeviceId and wmi_device_table! macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-rust-wmi-v1-2-63111d9e824c@gmail.com>
References: <20261122-rust-wmi-v1-0-63111d9e824c@gmail.com>
In-Reply-To: <20261122-rust-wmi-v1-0-63111d9e824c@gmail.com>
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
Cc: =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 platform-driver-x86@vger.kernel.org, Nick Dowsett <nick42d@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795321700; l=2770;
 i=nick42d@gmail.com; h=from:subject:message-id;
 bh=rN5WOMkzuWsdFdqCtGFto3bveJqWkdJKdIJZrv+wpJA=;
 b=HjDeKiCcpD/X/W5TCtr79VRGMnJDNbpXoWRXrRCf1L/3uC1jmyZT66TotA9kdT+Y4Q4lS2YK1
 pLLqOiKX/DJB3ubFEcXPob2nyCVBHqrTSi3ciLVWbGaK+k4EgqRlpDo
X-Developer-Key: i=nick42d@gmail.com; a=ed25519;
 pk=1uIkNexEofzEXNN3Y3QW5z8IrgjWaP0yH6Es51jxWOg=
X-Endpoint-Received: by B4 Relay for nick42d@gmail.com/default with auth_id=1596
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Add `wmi::DeviceId` wrapping `struct wmi_device_id`.

- Implements `wmi::IdTable` and the `wmi_device_table!` macro.

Signed-off-by: Nick Dowsett <nick42d@gmail.com>
---
 rust/kernel/wmi.rs | 57 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 57 insertions(+)

diff --git a/rust/kernel/wmi.rs b/rust/kernel/wmi.rs
index 5f1d8c9803d6..494797fdbf68 100644
--- a/rust/kernel/wmi.rs
+++ b/rust/kernel/wmi.rs
@@ -7,6 +7,8 @@
 use crate::{
     bindings,
     device,
+    device_id::RawDeviceId,
+    prelude::*,
     sync::aref::AlwaysRefCounted,
     types::Opaque, //
 };
@@ -15,6 +17,61 @@
     ptr::NonNull, //
 };
 
+/// IdTable type for WMI drivers.
+pub type IdTable = &'static dyn crate::device_id::IdTable<DeviceId, ()>;
+
+/// A WMI device ID wrapping [`struct wmi_device_id`].
+///
+/// [`struct wmi_device_id`]: srctree/include/linux/device-id/wmi.h
+///
+/// # Invariants
+/// `self.0.guid_string` is a valid, null-terminated string of length [`bindings::UUID_STRING_LEN`].
+#[repr(transparent)]
+#[derive(Clone, Copy)]
+pub struct DeviceId(bindings::wmi_device_id);
+// SAFETY: `DeviceId` is a `#[repr(transparent)]` wrapper of `wmi_device_id`.
+// `wmi_device_id` does not have any invariants, so it's safe to transmute to it.
+unsafe impl RawDeviceId for DeviceId {
+    type RawType = bindings::wmi_device_id;
+}
+impl DeviceId {
+    const WMI_UUID_LEN: usize = crate::num::casts::u32_as_usize(bindings::UUID_STRING_LEN);
+    /// Creates a new [`DeviceId`].
+    ///
+    /// Fails at compile time if `guid.len()` is not [`bindings::UUID_STRING_LEN`].
+    #[inline(always)]
+    pub const fn new(guid: &'static CStr) -> Self {
+        let src = guid.to_bytes_with_nul();
+        // NOTE: Function is marked `#[inline(always)]` to help compiler optimise the error path.
+        build_assert!(
+            src.len() == Self::WMI_UUID_LEN + 1,
+            "WMI DeviceId length incorrect"
+        );
+        let mut id: bindings::wmi_device_id = pin_init::zeroed();
+        // TODO: Upgrade to core::slice::copy_from_slice(src) once rustc>=1.87
+        let mut i = 0;
+        while i < src.len() {
+            id.guid_string[i] = src[i];
+            i += 1;
+        }
+        Self(id)
+    }
+}
+
+/// Create a WMI [`IdTable`] with an "alias" for modpost.
+#[macro_export]
+macro_rules! wmi_device_table {
+    ($table_name:ident, [$($id:expr),* $(,)?]) => {
+        $crate::module_device_table!(
+            "wmi",
+            $crate::wmi::DeviceId,
+            $table_name,
+            @none,
+            [$($id),*]
+        );
+    };
+}
+
 /// A WMI bus device ([`struct wmi_device`]).
 ///
 /// # Invariants

-- 
2.56.1

