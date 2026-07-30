From: Alvin Sun <alvin.sun@linux.dev>
Date: Fri, 31 Jul 2026 01:05:40 +0800
Subject: [PATCH v2 2/9] rust: debugfs: add SeqShow trait and seq_file file
 operations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-tyr-debugfs-v2-v2-2-aea19eccb996@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785431148; l=8068;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=SGD5eo0FIbmV4lmWi2duA/OCEdF+gG3Y3sHkHFC6+qY=;
 b=ZbN8jfSO8mO1NUyNg4kgvyxZuKB9v982mSoav+JY9M42DkDPL3/MwAzOth958SFZc08oGbjHa
 kiiiHyssAURA0wD6C+M+KVO74JouoVzZCGSKA2zOpRj7SxVBnC5rAoj
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SeqShow trait for seq_file-backed debugfs files with optional
open/release lifecycle hooks. Needed by DRM and other subsystems to
expose readable debugfs state via seq_file.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/debugfs.rs          | 16 ++++++-
 rust/kernel/debugfs/file_ops.rs | 97 +++++++++++++++++++++++++++++++++++++++++
 rust/kernel/debugfs/traits.rs   | 30 ++++++++++++-
 3 files changed, 141 insertions(+), 2 deletions(-)

diff --git a/rust/kernel/debugfs.rs b/rust/kernel/debugfs.rs
index d7b8014a64746..dea0e2c953039 100644
--- a/rust/kernel/debugfs.rs
+++ b/rust/kernel/debugfs.rs
@@ -24,7 +24,7 @@
         PhantomData,
         PhantomPinned, //
     },
-    ops::Deref,
+    ops::Deref, //
 };
 
 mod traits;
@@ -33,6 +33,7 @@
     BinaryReaderMut,
     BinaryWriter,
     Reader,
+    SeqShow,
     Writer, //
 };
 
@@ -51,6 +52,7 @@
     FileOps,
     ReadFile,
     ReadWriteFile,
+    SeqReadFile,
     WriteFile, //
 };
 
@@ -588,6 +590,18 @@ pub fn read_callback_file<T, F>(&self, name: &CStr, data: &'data T, _f: &'static
         self.create_file(name, data, vtable)
     }
 
+    /// Creates a seq_file debugfs file in this directory.
+    ///
+    /// The file's contents are produced by invoking [`SeqShow::show`] with
+    /// `data` on each read.
+    ///
+    /// This function does not produce an owning handle to the file. The created
+    /// file is removed when the [`Scope`] that this directory belongs to is
+    /// dropped.
+    pub fn seq_file<S: SeqShow<U>, U: Sync + 'static>(&self, name: &CStr, data: &'data U) {
+        self.create_file(name, data, &<S as SeqReadFile<U>>::FILE_OPS)
+    }
+
     /// Creates a read-write file in this directory.
     ///
     /// Reading the file uses the [`Writer`] implementation on `data`. Writing to the file uses
diff --git a/rust/kernel/debugfs/file_ops.rs b/rust/kernel/debugfs/file_ops.rs
index f15908f71c4a2..20a4362785a44 100644
--- a/rust/kernel/debugfs/file_ops.rs
+++ b/rust/kernel/debugfs/file_ops.rs
@@ -5,11 +5,13 @@
     BinaryReader,
     BinaryWriter,
     Reader,
+    SeqShow,
     Writer, //
 };
 
 use crate::{
     debugfs::callback_adapters::Adapter,
+    error::from_result,
     fmt,
     fs::file,
     prelude::*,
@@ -19,6 +21,7 @@
 };
 
 use core::marker::PhantomData;
+use core::ptr::NonNull;
 
 #[cfg(CONFIG_DEBUG_FS)]
 use core::ops::Deref;
@@ -123,6 +126,100 @@ fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
     0
 }
 
+/// Show callback for `SeqShow` types.
+///
+/// # Safety
+///
+/// The seq_file core guarantees that `seq` points to a live `seq_file` and that
+/// `seq->private` is a valid pointer to a `T` with no outstanding mutable
+/// references.
+unsafe extern "C" fn seq_file_show<S: SeqShow<T>, T: Sync>(
+    seq: *mut bindings::seq_file,
+    _: *mut crate::ffi::c_void,
+) -> crate::ffi::c_int {
+    // SAFETY: `seq->private` is a valid `T` pointer with no outstanding
+    // mutable references.
+    let data = unsafe { &*((*seq).private.cast::<T>()) };
+    // SAFETY: `seq` points to a live `seq_file`.
+    let m = unsafe { SeqFile::from_raw(seq) };
+    from_result(|| S::show(data, m).map(|()| 0))
+}
+
+/// Open callback for `SeqShow` types.
+///
+/// # Safety
+///
+/// The VFS guarantees that `inode` is valid with `i_private` pointing to a
+/// valid `T` that remains valid for the duration of the call, and that `file`
+/// points to a live, uninitialized file object.
+unsafe extern "C" fn seq_file_open<S: SeqShow<T>, T: Sync>(
+    inode: *mut bindings::inode,
+    file: *mut bindings::file,
+) -> crate::ffi::c_int {
+    // SAFETY: `inode` is valid per VFS. `i_private` points to a valid `T`
+    // (guaranteed by the `FileOps<T>` invariants).
+    let data = unsafe { (*inode).i_private.cast::<T>() };
+    // SAFETY: `data` is a valid `T` pointer from `i_private` per the `FileOps` invariants.
+    let data_ref = unsafe { &*data };
+
+    if let Err(e) = S::open(data_ref) {
+        return e.to_errno();
+    }
+
+    // SAFETY: `file` is valid per VFS; `data` matches `seq_file_show`'s contract.
+    let ret = unsafe { bindings::single_open(file, Some(seq_file_show::<S, T>), data.cast()) };
+    if ret != 0 {
+        // SAFETY: Since `S::open` has already succeeded, `data` is valid. `data` came from
+        // `i_private` (a `&T` reference), so it is non-null.
+        unsafe { S::release(NonNull::new_unchecked(data)) };
+    }
+    ret
+}
+
+/// Release callback for `SeqShow` types.
+///
+/// # Safety
+///
+/// The VFS guarantees that `file` is valid, and that `private_data` points to
+/// a live `seq_file` whose `private` field is a valid pointer to `T`.
+unsafe extern "C" fn seq_file_release<S: SeqShow<T>, T: Sync>(
+    inode: *mut bindings::inode,
+    file: *mut bindings::file,
+) -> crate::ffi::c_int {
+    // SAFETY: `file->private_data` is the seq_file from `single_open`.
+    let seq = unsafe { (*file).private_data.cast::<bindings::seq_file>() };
+
+    // SAFETY: `seq->private` was set by `single_open` to the `i_private` value.
+    let data = unsafe { (*seq).private };
+
+    // SAFETY: `data` came from `i_private` (a `&T` reference), so it is
+    // non-null.
+    unsafe { S::release(NonNull::new_unchecked(data.cast::<T>())) };
+
+    // SAFETY: `inode` and `file` are valid per VFS.
+    unsafe { bindings::single_release(inode, file) }
+}
+
+pub(crate) trait SeqReadFile<T> {
+    const FILE_OPS: FileOps<T>;
+}
+
+impl<S: SeqShow<T>, T: Sync + 'static> SeqReadFile<T> for S {
+    const FILE_OPS: FileOps<T> = {
+        let operations = bindings::file_operations {
+            read: Some(bindings::seq_read),
+            llseek: Some(bindings::seq_lseek),
+            release: Some(seq_file_release::<Self, T>),
+            open: Some(seq_file_open::<Self, T>),
+            ..pin_init::zeroed()
+        };
+        // SAFETY: `read` and `llseek` are stock `seq_file` implementations.
+        // `seq_file_open` and `seq_file_release` treat `inode->i_private` as a
+        // valid `&T` reference, satisfying the `FileOps::new` contract.
+        unsafe { FileOps::new(operations, 0o400) }
+    };
+}
+
 // Work around lack of generic const items.
 pub(crate) trait ReadFile<T> {
     const FILE_OPS: FileOps<T>;
diff --git a/rust/kernel/debugfs/traits.rs b/rust/kernel/debugfs/traits.rs
index 8c39524b6a990..4cbdfdf511a88 100644
--- a/rust/kernel/debugfs/traits.rs
+++ b/rust/kernel/debugfs/traits.rs
@@ -8,6 +8,7 @@
     fmt,
     fs::file,
     prelude::*,
+    seq_file::SeqFile,
     sync::{
         atomic::{
             Atomic,
@@ -33,7 +34,8 @@
         Deref,
         DerefMut, //
     },
-    str::FromStr,
+    ptr::NonNull,
+    str::FromStr, //
 };
 
 /// A trait for types that can be written into a string.
@@ -338,3 +340,29 @@ fn read_from_slice(
         self.deref().read_from_slice(reader, offset)
     }
 }
+
+/// Renders `data` into a seq_file.
+///
+/// `data` is the value stashed as the debugfs file's `i_private` at creation
+/// time. `show` is invoked on each read to produce the file's contents.
+///
+/// `open` and `release` are optional lifecycle hooks called during file open
+/// and release. They can be used to manage the lifetime of `data` (e.g.,
+/// reference counting). Default implementations are no-ops.
+pub trait SeqShow<T> {
+    /// Writes debugfs output for the file.
+    fn show(data: &T, m: &SeqFile) -> Result;
+
+    /// Called during file open, before `single_open`.
+    fn open(_data: &T) -> Result {
+        Ok(())
+    }
+
+    /// Called during file release, before `single_release`.
+    ///
+    /// # Safety
+    ///
+    /// `data` must point to valid memory, kept alive by actions taken in
+    /// [`Self::open`] (e.g., incrementing a reference count).
+    unsafe fn release(_data: NonNull<T>) {}
+}

-- 
2.43.0

