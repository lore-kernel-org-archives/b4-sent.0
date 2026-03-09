From: Tim Kovalenko <tim.kovalenko@proton.me>
Date: Mon, 09 Mar 2026 12:34:20 -0400
Subject: [PATCH v4 3/4] rust: dma: use pointer projection infra for
 `dma_{read,write}` macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-drm-rust-next-v4-3-4ef485b19a4c@proton.me>
References: <20260309-drm-rust-next-v4-0-4ef485b19a4c@proton.me>
In-Reply-To: <20260309-drm-rust-next-v4-0-4ef485b19a4c@proton.me>
To: Alexandre Courbot <acourbot@nvidia.com>, 
 Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Miguel Ojeda <ojeda@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, Boqun Feng <boqun@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Abdiel Janulgue <abdiel.janulgue@gmail.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Robin Murphy <robin.murphy@arm.com>, Boqun Feng <boqun@kernel.org>
Cc: nouveau@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, driver-core@lists.linux.dev
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773074117; l=15716;
 i=tim.kovalenko@proton.me; s=20260212; h=from:subject:message-id;
 bh=Upnq6G3yp4f/mbP79I/+fne9vntggLcTIt7uIQ8neSk=;
 b=sqTDthGSfjKed8A4BAAZQvoZUy1p5qKwmQT0xo73JLs8JyW6Hd/J2qHL7Xtc3Rx6qUw2ZkrsA
 Sn+jSi1eNKNCpyLy+Pl9evdmfHN3bTKaEDhtCjOHp02MZ9X+3VqvF56
X-Developer-Key: i=tim.kovalenko@proton.me; a=ed25519;
 pk=/+OiulEpgeZifgP4mDE4e5YlV6nMeY+frze/lY/xiHI=
X-Endpoint-Received: by B4 Relay for tim.kovalenko@proton.me/20260212 with auth_id=635
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Gary Guo <gary@garyguo.net>

Current `dma_read!`, `dma_write!` macros also use a custom
`addr_of!()`-based implementation for projecting pointers, which has
soundness issue as it relies on absence of `Deref` implementation on types.
It also has a soundness issue where it does not protect against unaligned
fields (when `#[repr(packed)]` is used) so it can generate misaligned
accesses.

This commit migrates them to use the general pointer projection
infrastructure, which handles these cases correctly.

As part of migration, the macro is updated to have an improved surface
syntax. The current macro have

    dma_read!(a.b.c[d].e.f)

to mean `a.b.c` is a DMA coherent allocation and it should project into it
with `[d].e.f` and do a read, which is confusing as it makes the indexing
operator integral to the macro (so it will break if you have an array of
`CoherentAllocation`, for example).

This also is problematic as we would like to generalize
`CoherentAllocation` from just slices to arbitrary types.

Make the macro expects `dma_read!(path.to.dma, .path.inside.dma)` as the
canonical syntax. The index operator is no longer special and is just one
type of projection (in additional to field projection). Similarly, make
`dma_write!(path.to.dma, .path.inside.dma, value)` become the canonical
syntax for writing.

Another issue of the current macro is that it is always fallible. This
makes sense with existing design of `CoherentAllocation`, but once we
support fixed size arrays with `CoherentAllocation`, it is desirable to
have the ability to perform infallible indexing as well, e.g. doing a `[0]`
index of `[Foo; 2]` is okay and can be checked at build-time, so forcing
falliblity is non-ideal. To capture this, the macro is changed to use
`[idx]` as infallible projection and `[idx]?` as fallible index projection
(those syntax are part of the general projection infra). A benefit of this
is that while individual indexing operation may fail, the overall
read/write operation is not fallible.

Fixes: ad2907b4e308 ("rust: add dma coherent allocator abstraction")
Reviewed-by: Benno Lossin <lossin@kernel.org>
Signed-off-by: Gary Guo <gary@garyguo.net>
Acked-by: Miguel Ojeda <ojeda@kernel.org>
---
 drivers/gpu/nova-core/gsp.rs      |  14 ++---
 drivers/gpu/nova-core/gsp/boot.rs |   2 +-
 drivers/gpu/nova-core/gsp/cmdq.rs |  10 +++-
 rust/kernel/dma.rs                | 114 +++++++++++++++++---------------------
 samples/rust/rust_dma.rs          |  30 +++++-----
 5 files changed, 81 insertions(+), 89 deletions(-)

diff --git a/drivers/gpu/nova-core/gsp.rs b/drivers/gpu/nova-core/gsp.rs
index 174feaca0a6b9269cf35286dec3acc4d60918904..25cd48514c777cb405a2af0acf57196b2e2e7837 100644
--- a/drivers/gpu/nova-core/gsp.rs
+++ b/drivers/gpu/nova-core/gsp.rs
@@ -143,14 +143,14 @@ pub(crate) fn new(pdev: &pci::Device<device::Bound>) -> impl PinInit<Self, Error
                     // _kgspInitLibosLoggingStructures (allocates memory for buffers)
                     // kgspSetupLibosInitArgs_IMPL (creates pLibosInitArgs[] array)
                     dma_write!(
-                        libos[0] = LibosMemoryRegionInitArgument::new("LOGINIT", &loginit.0)
-                    )?;
+                        libos, [0]?, LibosMemoryRegionInitArgument::new("LOGINIT", &loginit.0)
+                    );
                     dma_write!(
-                        libos[1] = LibosMemoryRegionInitArgument::new("LOGINTR", &logintr.0)
-                    )?;
-                    dma_write!(libos[2] = LibosMemoryRegionInitArgument::new("LOGRM", &logrm.0))?;
-                    dma_write!(rmargs[0].inner = fw::GspArgumentsCached::new(cmdq))?;
-                    dma_write!(libos[3] = LibosMemoryRegionInitArgument::new("RMARGS", rmargs))?;
+                        libos, [1]?, LibosMemoryRegionInitArgument::new("LOGINTR", &logintr.0)
+                    );
+                    dma_write!(libos, [2]?, LibosMemoryRegionInitArgument::new("LOGRM", &logrm.0));
+                    dma_write!(rmargs, [0]?.inner, fw::GspArgumentsCached::new(cmdq));
+                    dma_write!(libos, [3]?, LibosMemoryRegionInitArgument::new("RMARGS", rmargs));
                 },
             }))
         })
diff --git a/drivers/gpu/nova-core/gsp/boot.rs b/drivers/gpu/nova-core/gsp/boot.rs
index 9a00ddb922ac9d37db67e0abfacfcaa39f9a163d..f033c489d69c9fd8dffe3df0433020da18ff2297 100644
--- a/drivers/gpu/nova-core/gsp/boot.rs
+++ b/drivers/gpu/nova-core/gsp/boot.rs
@@ -166,7 +166,7 @@ pub(crate) fn boot(
 
         let wpr_meta =
             CoherentAllocation::<GspFwWprMeta>::alloc_coherent(dev, 1, GFP_KERNEL | __GFP_ZERO)?;
-        dma_write!(wpr_meta[0] = GspFwWprMeta::new(&gsp_fw, &fb_layout))?;
+        dma_write!(wpr_meta, [0]?, GspFwWprMeta::new(&gsp_fw, &fb_layout));
 
         self.cmdq
             .send_command(bar, commands::SetSystemInfo::new(pdev))?;
diff --git a/drivers/gpu/nova-core/gsp/cmdq.rs b/drivers/gpu/nova-core/gsp/cmdq.rs
index 87dbbd6d1be9d86e7fb45a84f9647265bd63f84e..0056bfbf0a44cfbc5a0ca08d069f881b877e1edc 100644
--- a/drivers/gpu/nova-core/gsp/cmdq.rs
+++ b/drivers/gpu/nova-core/gsp/cmdq.rs
@@ -202,9 +202,13 @@ fn new(dev: &device::Device<device::Bound>) -> Result<Self> {
 
         let gsp_mem =
             CoherentAllocation::<GspMem>::alloc_coherent(dev, 1, GFP_KERNEL | __GFP_ZERO)?;
-        dma_write!(gsp_mem[0].ptes = PteArray::new(gsp_mem.dma_handle())?)?;
-        dma_write!(gsp_mem[0].cpuq.tx = MsgqTxHeader::new(MSGQ_SIZE, RX_HDR_OFF, MSGQ_NUM_PAGES))?;
-        dma_write!(gsp_mem[0].cpuq.rx = MsgqRxHeader::new())?;
+        dma_write!(gsp_mem, [0]?.ptes, PteArray::new(gsp_mem.dma_handle())?);
+        dma_write!(
+            gsp_mem,
+            [0]?.cpuq.tx,
+            MsgqTxHeader::new(MSGQ_SIZE, RX_HDR_OFF, MSGQ_NUM_PAGES)
+        );
+        dma_write!(gsp_mem, [0]?.cpuq.rx, MsgqRxHeader::new());
 
         Ok(Self(gsp_mem))
     }
diff --git a/rust/kernel/dma.rs b/rust/kernel/dma.rs
index 909d56fd5118ee1db3585a8c10a99fe1d091dd00..cd2957b5f260b04c89e0762edba0820f11b064a4 100644
--- a/rust/kernel/dma.rs
+++ b/rust/kernel/dma.rs
@@ -461,6 +461,19 @@ pub fn size(&self) -> usize {
         self.count * core::mem::size_of::<T>()
     }
 
+    /// Returns the raw pointer to the allocated region in the CPU's virtual address space.
+    #[inline]
+    pub fn as_ptr(&self) -> *const [T] {
+        core::ptr::slice_from_raw_parts(self.cpu_addr.as_ptr(), self.count)
+    }
+
+    /// Returns the raw pointer to the allocated region in the CPU's virtual address space as
+    /// a mutable pointer.
+    #[inline]
+    pub fn as_mut_ptr(&self) -> *mut [T] {
+        core::ptr::slice_from_raw_parts_mut(self.cpu_addr.as_ptr(), self.count)
+    }
+
     /// Returns the base address to the allocated region in the CPU's virtual address space.
     pub fn start_ptr(&self) -> *const T {
         self.cpu_addr.as_ptr()
@@ -581,23 +594,6 @@ pub unsafe fn write(&mut self, src: &[T], offset: usize) -> Result {
         Ok(())
     }
 
-    /// Returns a pointer to an element from the region with bounds checking. `offset` is in
-    /// units of `T`, not the number of bytes.
-    ///
-    /// Public but hidden since it should only be used from [`dma_read`] and [`dma_write`] macros.
-    #[doc(hidden)]
-    pub fn item_from_index(&self, offset: usize) -> Result<*mut T> {
-        if offset >= self.count {
-            return Err(EINVAL);
-        }
-        // SAFETY:
-        // - The pointer is valid due to type invariant on `CoherentAllocation`
-        // and we've just checked that the range and index is within bounds.
-        // - `offset` can't overflow since it is smaller than `self.count` and we've checked
-        // that `self.count` won't overflow early in the constructor.
-        Ok(unsafe { self.cpu_addr.as_ptr().add(offset) })
-    }
-
     /// Reads the value of `field` and ensures that its type is [`FromBytes`].
     ///
     /// # Safety
@@ -670,6 +666,9 @@ unsafe impl<T: AsBytes + FromBytes + Send> Send for CoherentAllocation<T> {}
 
 /// Reads a field of an item from an allocated region of structs.
 ///
+/// The syntax is of form `kernel::dma_read!(dma, proj)` where `dma` is an expression to an
+/// [`CoherentAllocation`] and `proj` is a [projection specification](kernel::ptr::project!).
+///
 /// # Examples
 ///
 /// ```
@@ -684,36 +683,29 @@ unsafe impl<T: AsBytes + FromBytes + Send> Send for CoherentAllocation<T> {}
 /// unsafe impl kernel::transmute::AsBytes for MyStruct{};
 ///
 /// # fn test(alloc: &kernel::dma::CoherentAllocation<MyStruct>) -> Result {
-/// let whole = kernel::dma_read!(alloc[2]);
-/// let field = kernel::dma_read!(alloc[1].field);
+/// let whole = kernel::dma_read!(alloc, [2]?);
+/// let field = kernel::dma_read!(alloc, [1]?.field);
 /// # Ok::<(), Error>(()) }
 /// ```
 #[macro_export]
 macro_rules! dma_read {
-    ($dma:expr, $idx: expr, $($field:tt)*) => {{
-        (|| -> ::core::result::Result<_, $crate::error::Error> {
-            let item = $crate::dma::CoherentAllocation::item_from_index(&$dma, $idx)?;
-            // SAFETY: `item_from_index` ensures that `item` is always a valid pointer and can be
-            // dereferenced. The compiler also further validates the expression on whether `field`
-            // is a member of `item` when expanded by the macro.
-            unsafe {
-                let ptr_field = ::core::ptr::addr_of!((*item) $($field)*);
-                ::core::result::Result::Ok(
-                    $crate::dma::CoherentAllocation::field_read(&$dma, ptr_field)
-                )
-            }
-        })()
+    ($dma:expr, $($proj:tt)*) => {{
+        let dma = &$dma;
+        let ptr = $crate::ptr::project!(
+            $crate::dma::CoherentAllocation::as_ptr(dma), $($proj)*
+        );
+        // SAFETY: pointer created by projection is within DMA region.
+        unsafe { $crate::dma::CoherentAllocation::field_read(dma, ptr) }
     }};
-    ($dma:ident [ $idx:expr ] $($field:tt)* ) => {
-        $crate::dma_read!($dma, $idx, $($field)*)
-    };
-    ($($dma:ident).* [ $idx:expr ] $($field:tt)* ) => {
-        $crate::dma_read!($($dma).*, $idx, $($field)*)
-    };
 }
 
 /// Writes to a field of an item from an allocated region of structs.
 ///
+/// The syntax is of form `kernel::dma_write!(dma, proj, val)` where `dma` is an expression to an
+/// [`CoherentAllocation`] and `proj` is a [projection specification](kernel::ptr::project!),
+/// and `val` is the value to be written to the projected location.
+///
+///
 /// # Examples
 ///
 /// ```
@@ -728,37 +720,31 @@ macro_rules! dma_read {
 /// unsafe impl kernel::transmute::AsBytes for MyStruct{};
 ///
 /// # fn test(alloc: &kernel::dma::CoherentAllocation<MyStruct>) -> Result {
-/// kernel::dma_write!(alloc[2].member = 0xf);
-/// kernel::dma_write!(alloc[1] = MyStruct { member: 0xf });
+/// kernel::dma_write!(alloc, [2]?.member, 0xf);
+/// kernel::dma_write!(alloc, [1]?, MyStruct { member: 0xf });
 /// # Ok::<(), Error>(()) }
 /// ```
 #[macro_export]
 macro_rules! dma_write {
-    ($dma:ident [ $idx:expr ] $($field:tt)*) => {{
-        $crate::dma_write!($dma, $idx, $($field)*)
-    }};
-    ($($dma:ident).* [ $idx:expr ] $($field:tt)* ) => {{
-        $crate::dma_write!($($dma).*, $idx, $($field)*)
+    (@parse [$dma:expr] [$($proj:tt)*] [, $val:expr]) => {{
+        let dma = &$dma;
+        let ptr = $crate::ptr::project!(
+            mut $crate::dma::CoherentAllocation::as_mut_ptr(dma), $($proj)*
+        );
+        let val = $val;
+        // SAFETY: pointer created by projection is within DMA region.
+        unsafe { $crate::dma::CoherentAllocation::field_write(dma, ptr, val) }
     }};
-    ($dma:expr, $idx: expr, = $val:expr) => {
-        (|| -> ::core::result::Result<_, $crate::error::Error> {
-            let item = $crate::dma::CoherentAllocation::item_from_index(&$dma, $idx)?;
-            // SAFETY: `item_from_index` ensures that `item` is always a valid item.
-            unsafe { $crate::dma::CoherentAllocation::field_write(&$dma, item, $val) }
-            ::core::result::Result::Ok(())
-        })()
+    (@parse [$dma:expr] [$($proj:tt)*] [.$field:tt $($rest:tt)*]) => {
+        $crate::dma_write!(@parse [$dma] [$($proj)* .$field] [$($rest)*])
+    };
+    (@parse [$dma:expr] [$($proj:tt)*] [[$index:expr]? $($rest:tt)*]) => {
+        $crate::dma_write!(@parse [$dma] [$($proj)* [$index]?] [$($rest)*])
+    };
+    (@parse [$dma:expr] [$($proj:tt)*] [[$index:expr] $($rest:tt)*]) => {
+        $crate::dma_write!(@parse [$dma] [$($proj)* [$index]] [$($rest)*])
     };
-    ($dma:expr, $idx: expr, $(.$field:ident)* = $val:expr) => {
-        (|| -> ::core::result::Result<_, $crate::error::Error> {
-            let item = $crate::dma::CoherentAllocation::item_from_index(&$dma, $idx)?;
-            // SAFETY: `item_from_index` ensures that `item` is always a valid pointer and can be
-            // dereferenced. The compiler also further validates the expression on whether `field`
-            // is a member of `item` when expanded by the macro.
-            unsafe {
-                let ptr_field = ::core::ptr::addr_of_mut!((*item) $(.$field)*);
-                $crate::dma::CoherentAllocation::field_write(&$dma, ptr_field, $val)
-            }
-            ::core::result::Result::Ok(())
-        })()
+    ($dma:expr, $($rest:tt)*) => {
+        $crate::dma_write!(@parse [$dma] [] [$($rest)*])
     };
 }
diff --git a/samples/rust/rust_dma.rs b/samples/rust/rust_dma.rs
index 9c45851c876ef33414eb0071c42a2fb4ac3f1e78..ce39b55450978e69f40b20bb2a0479973f2843ad 100644
--- a/samples/rust/rust_dma.rs
+++ b/samples/rust/rust_dma.rs
@@ -68,7 +68,7 @@ fn probe(pdev: &pci::Device<Core>, _info: &Self::IdInfo) -> impl PinInit<Self, E
                 CoherentAllocation::alloc_coherent(pdev.as_ref(), TEST_VALUES.len(), GFP_KERNEL)?;
 
             for (i, value) in TEST_VALUES.into_iter().enumerate() {
-                kernel::dma_write!(ca[i] = MyStruct::new(value.0, value.1))?;
+                kernel::dma_write!(ca, [i]?, MyStruct::new(value.0, value.1));
             }
 
             let size = 4 * page::PAGE_SIZE;
@@ -85,24 +85,26 @@ fn probe(pdev: &pci::Device<Core>, _info: &Self::IdInfo) -> impl PinInit<Self, E
     }
 }
 
+impl DmaSampleDriver {
+    fn check_dma(&self) -> Result {
+        for (i, value) in TEST_VALUES.into_iter().enumerate() {
+            let val0 = kernel::dma_read!(self.ca, [i]?.h);
+            let val1 = kernel::dma_read!(self.ca, [i]?.b);
+
+            assert_eq!(val0, value.0);
+            assert_eq!(val1, value.1);
+        }
+
+        Ok(())
+    }
+}
+
 #[pinned_drop]
 impl PinnedDrop for DmaSampleDriver {
     fn drop(self: Pin<&mut Self>) {
         dev_info!(self.pdev, "Unload DMA test driver.\n");
 
-        for (i, value) in TEST_VALUES.into_iter().enumerate() {
-            let val0 = kernel::dma_read!(self.ca[i].h);
-            let val1 = kernel::dma_read!(self.ca[i].b);
-            assert!(val0.is_ok());
-            assert!(val1.is_ok());
-
-            if let Ok(val0) = val0 {
-                assert_eq!(val0, value.0);
-            }
-            if let Ok(val1) = val1 {
-                assert_eq!(val1, value.1);
-            }
-        }
+        assert!(self.check_dma().is_ok());
 
         for (i, entry) in self.sgt.iter().enumerate() {
             dev_info!(

-- 
2.53.0

