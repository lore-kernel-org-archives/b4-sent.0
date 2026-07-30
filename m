From: Alvin Sun <alvin.sun@linux.dev>
Date: Fri, 31 Jul 2026 01:05:43 +0800
Subject: [PATCH v2 5/9] rust: drm: add debugfs_init callback to Driver
 trait
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-tyr-debugfs-v2-v2-5-aea19eccb996@linux.dev>
References: <20260731-tyr-debugfs-v2-v2-0-aea19eccb996@linux.dev>
In-Reply-To: <20260731-tyr-debugfs-v2-v2-0-aea19eccb996@linux.dev>
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
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Matthew Brost <matthew.brost@intel.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 =?utf-8?q?Ma=C3=ADra_Canal?= <mcanal@igalia.com>, 
 Melissa Wen <mwen@igalia.com>, Wambui Karuga <wambui.karugax@gmail.com>, 
 Eric Anholt <eric@anholt.net>, Ben Gamari <bgamari@gmail.com>, 
 rust-for-linux@vger.kernel.org, driver-core@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785431148; l=4261;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=Mu/THEs4NT5nNw4z7NqjGMWVALSaA8dgypD02/JDRXs=;
 b=Vv+KfURg6kwiS2V3pkSEKb24JmkZRi0mkucL3WPHVnRo6orv2pNtzyrdWBlpd9MdSl2XLFoEQ
 faMxHsP+XSCCZhDPDUwU633m6r4bYMpHblmSoeScV4tqQqJjnmvF8px
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add debugfs_init method to the Driver trait, enabling Rust DRM
drivers to populate debugfs entries during device registration.
The C callback converts from raw C minor/dentry types to Rust Device
and ScopedDir references.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/bindings/bindings_helper.h |  1 +
 rust/kernel/drm/device.rs       | 36 ++++++++++++++++++++++++++++++++++--
 rust/kernel/drm/driver.rs       | 11 +++++++++++
 3 files changed, 46 insertions(+), 2 deletions(-)

diff --git a/rust/bindings/bindings_helper.h b/rust/bindings/bindings_helper.h
index 1124785e210b3..c3b2a86528934 100644
--- a/rust/bindings/bindings_helper.h
+++ b/rust/bindings/bindings_helper.h
@@ -30,6 +30,7 @@
 
 #include <linux/acpi.h>
 #include <linux/gpu_buddy.h>
+#include <drm/drm_debugfs.h>
 #include <drm/drm_device.h>
 #include <drm/drm_drv.h>
 #include <drm/drm_file.h>
diff --git a/rust/kernel/drm/device.rs b/rust/kernel/drm/device.rs
index 7a3a0e21e9557..c9aa5d2374444 100644
--- a/rust/kernel/drm/device.rs
+++ b/rust/kernel/drm/device.rs
@@ -7,6 +7,7 @@
 use crate::{
     alloc::allocator::Kmalloc,
     bindings,
+    debugfs::ScopedDir,
     device,
     drm::{
         self,
@@ -39,7 +40,7 @@
     ptr::{
         self,
         NonNull, //
-    },
+    }, //
 };
 
 #[cfg(CONFIG_DRM_LEGACY)]
@@ -170,7 +171,7 @@ const fn compute_features() -> u32 {
         release: Some(Device::<T>::release),
         master_set: None,
         master_drop: None,
-        debugfs_init: None,
+        debugfs_init: Some(Device::<T, Normal>::debugfs_init_callback),
 
         gem_create_object: T::Object::ALLOC_OPS.gem_create_object,
         prime_handle_to_fd: T::Object::ALLOC_OPS.prime_handle_to_fd,
@@ -353,6 +354,37 @@ extern "C" fn release(ptr: *mut bindings::drm_device) {
         unsafe { core::ptr::drop_in_place(this) };
     }
 
+    /// C callback for `drm_driver.debugfs_init`.
+    ///
+    /// # Safety
+    ///
+    /// The DRM core guarantees that `minor` is valid and non-null when calling
+    /// this callback, and that `minor->dev` is a valid `drm_device` embedded
+    /// in a `Device<T>`.
+    unsafe extern "C" fn debugfs_init_callback(minor: *mut bindings::drm_minor) {
+        // SAFETY: `minor` is valid and non-null per the function's safety
+        // precondition.
+        let dev_ptr = unsafe { (*minor).dev };
+        // SAFETY: `minor` is valid per the function's safety precondition.
+        let debugfs_root = unsafe { (*minor).debugfs_root };
+
+        // Debugfs may be disabled.
+        if debugfs_root.is_null() {
+            return;
+        }
+
+        // SAFETY: `dev_ptr` points to a valid `drm_device` embedded in
+        // `Device<T, Normal>`. `debugfs_init` runs during registration, so
+        // the `Normal` context is correct.
+        let device = unsafe { Device::<T, Normal>::from_raw(dev_ptr) };
+
+        // SAFETY: `debugfs_root` is a valid dentry that remains alive as long as the
+        // DRM device is registered, which outlives this `ScopedDir`.
+        let dir = unsafe { ScopedDir::from_dentry(debugfs_root) };
+
+        T::debugfs_init(device, &dir);
+    }
+
     /// Change the [`DeviceContext`] for a [`Device`].
     ///
     /// # Safety
diff --git a/rust/kernel/drm/driver.rs b/rust/kernel/drm/driver.rs
index 08b2a318cf02a..7f3a6eaeddc5e 100644
--- a/rust/kernel/drm/driver.rs
+++ b/rust/kernel/drm/driver.rs
@@ -6,6 +6,7 @@
 
 use crate::{
     bindings,
+    debugfs::ScopedDir,
     device,
     drm,
     error::to_result,
@@ -138,6 +139,16 @@ pub trait Driver {
     /// usable from the render node (i.e. marked DRM_RENDER_ALLOW), whereas
     /// userspace processes using the master node can invoke any ioctl.
     const FEAT_RENDER: bool = false;
+
+    /// Populates debugfs for this DRM device.
+    ///
+    /// Called by the DRM core during registration, once per minor (callback
+    /// runs after `dev->registered`).
+    fn debugfs_init<'a>(_dev: &'a drm::Device<Self, drm::Normal>, _dir: &ScopedDir<'a, 'static>)
+    where
+        Self: Sized,
+    {
+    }
 }
 
 /// The registration type of a `drm::Device`.

-- 
2.43.0

