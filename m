From: Tim Kovalenko <tim.kovalenko@proton.me>
Date: Thu, 12 Feb 2026 22:49:13 -0500
Subject: [PATCH] gpu: nova-core: fix stack overflow in GSP memory
 allocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260212-drm-rust-next-v1-1-409398b12e61@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MwQpAUBBG4VfRrE0xhXgVWeD+mIVLc5GSd3ez/
 BbnPBRgikBN8pDh0qCbj8jThMal9zNYXTRJJmUmubCzle0MB3vcBw8YaumB2lUFxWY3THr/v7Z
 73w9rhI7IXwAAAA==
X-Change-ID: 20260212-drm-rust-next-beb92aee9d75
To: Alexandre Courbot <acourbot@nvidia.com>, 
 Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>
Cc: nouveau@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Tim Kovalenko <tim.kovalenko@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770954563; l=6047;
 i=tim.kovalenko@proton.me; s=20260212; h=from:subject:message-id;
 bh=zAyFM1Gds/9GkecAEWLm2RUuiSkvinRA/rr0HZejhKw=;
 b=W+viKVGiSV2fpc2PJZQBP4AL/bo8ESOw7mFgK3OvX6xoEvuVJ/GSYvGDmMzY2TXs99oKTp0Cj
 NVxFchszV9qATlli8IFa+bPzn6HliAUQwfaFwAvGygjUBGtMNwCVPCP
X-Developer-Key: i=tim.kovalenko@proton.me; a=ed25519;
 pk=/+OiulEpgeZifgP4mDE4e5YlV6nMeY+frze/lY/xiHI=
X-Endpoint-Received: by B4 Relay for tim.kovalenko@proton.me/20260212 with auth_id=635
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The `Cmdq::new` function was allocating a `PteArray` struct on the stack
and was causing a stack overflow with 8216 bytes.

Remove the `PteArray` and instead calculate and write the Page Table
Entries directly into the coherent DMA buffer one-by-one. This reduces
the stack usage quite a lot.

Signed-off-by: Tim Kovalenko <tim.kovalenko@proton.me>
---
 drivers/gpu/nova-core/gsp.rs      | 50 ++++++++++++++-------------------------
 drivers/gpu/nova-core/gsp/cmdq.rs | 27 ++++++++++++++++++---
 2 files changed, 42 insertions(+), 35 deletions(-)

diff --git a/drivers/gpu/nova-core/gsp.rs b/drivers/gpu/nova-core/gsp.rs
index 174feaca0a6b9269cf35286dec3acc4d60918904..316eeaf87ec5ae67422a34426eefa747c9b6502b 100644
--- a/drivers/gpu/nova-core/gsp.rs
+++ b/drivers/gpu/nova-core/gsp.rs
@@ -2,16 +2,14 @@
 
 mod boot;
 
+use core::iter::Iterator;
+
 use kernel::{
     device,
-    dma::{
-        CoherentAllocation,
-        DmaAddress, //
-    },
+    dma::CoherentAllocation,
     dma_write,
     pci,
-    prelude::*,
-    transmute::AsBytes, //
+    prelude::*, //
 };
 
 pub(crate) mod cmdq;
@@ -39,27 +37,6 @@
 /// Number of GSP pages to use in a RM log buffer.
 const RM_LOG_BUFFER_NUM_PAGES: usize = 0x10;
 
-/// Array of page table entries, as understood by the GSP bootloader.
-#[repr(C)]
-struct PteArray<const NUM_ENTRIES: usize>([u64; NUM_ENTRIES]);
-
-/// SAFETY: arrays of `u64` implement `AsBytes` and we are but a wrapper around one.
-unsafe impl<const NUM_ENTRIES: usize> AsBytes for PteArray<NUM_ENTRIES> {}
-
-impl<const NUM_PAGES: usize> PteArray<NUM_PAGES> {
-    /// Creates a new page table array mapping `NUM_PAGES` GSP pages starting at address `start`.
-    fn new(start: DmaAddress) -> Result<Self> {
-        let mut ptes = [0u64; NUM_PAGES];
-        for (i, pte) in ptes.iter_mut().enumerate() {
-            *pte = start
-                .checked_add(num::usize_as_u64(i) << GSP_PAGE_SHIFT)
-                .ok_or(EOVERFLOW)?;
-        }
-
-        Ok(Self(ptes))
-    }
-}
-
 /// The logging buffers are byte queues that contain encoded printf-like
 /// messages from GSP-RM.  They need to be decoded by a special application
 /// that can parse the buffers.
@@ -86,16 +63,25 @@ fn new(dev: &device::Device<device::Bound>) -> Result<Self> {
             NUM_PAGES * GSP_PAGE_SIZE,
             GFP_KERNEL | __GFP_ZERO,
         )?);
-        let ptes = PteArray::<NUM_PAGES>::new(obj.0.dma_handle())?;
+
+        let start_addr = obj.0.dma_handle();
 
         // SAFETY: `obj` has just been created and we are its sole user.
-        unsafe {
-            // Copy the self-mapping PTE at the expected location.
+        let pte_region = unsafe {
             obj.0
-                .as_slice_mut(size_of::<u64>(), size_of_val(&ptes))?
-                .copy_from_slice(ptes.as_bytes())
+                .as_slice_mut(size_of::<u64>(), NUM_PAGES * size_of::<u64>())?
         };
 
+        // As in [`DmaGspMem`], this is a  one by one GSP Page write to the memory
+        // to avoid stack overflow when allocating the whole array at once.
+        for (i, chunk) in pte_region.chunks_exact_mut(size_of::<u64>()).enumerate() {
+            let pte_value = start_addr
+                .checked_add(num::usize_as_u64(i) << GSP_PAGE_SHIFT)
+                .ok_or(EOVERFLOW)?;
+
+            chunk.copy_from_slice(&pte_value.to_ne_bytes());
+        }
+
         Ok(obj)
     }
 }
diff --git a/drivers/gpu/nova-core/gsp/cmdq.rs b/drivers/gpu/nova-core/gsp/cmdq.rs
index 46819a82a51adc58423502d9d45730923b843656..13a82d505c123e733850a00f627ddfe0c218940c 100644
--- a/drivers/gpu/nova-core/gsp/cmdq.rs
+++ b/drivers/gpu/nova-core/gsp/cmdq.rs
@@ -35,7 +35,6 @@
             MsgqRxHeader,
             MsgqTxHeader, //
         },
-        PteArray,
         GSP_PAGE_SHIFT,
         GSP_PAGE_SIZE, //
     },
@@ -159,7 +158,7 @@ struct Msgq {
 #[repr(C)]
 struct GspMem {
     /// Self-mapping page table entries.
-    ptes: PteArray<{ GSP_PAGE_SIZE / size_of::<u64>() }>,
+    ptes: [u64; GSP_PAGE_SIZE / size_of::<u64>()],
     /// CPU queue: the driver writes commands here, and the GSP reads them. It also contains the
     /// write and read pointers that the CPU updates.
     ///
@@ -201,7 +200,29 @@ fn new(dev: &device::Device<device::Bound>) -> Result<Self> {
 
         let gsp_mem =
             CoherentAllocation::<GspMem>::alloc_coherent(dev, 1, GFP_KERNEL | __GFP_ZERO)?;
-        dma_write!(gsp_mem[0].ptes = PteArray::new(gsp_mem.dma_handle())?)?;
+        const NUM_PAGES: usize = GSP_PAGE_SIZE / size_of::<u64>();
+
+        // One by one GSP Page write to the memory to avoid stack overflow when allocating
+        // the whole array at once.
+        let item = gsp_mem.item_from_index(0)?;
+        for i in 0..NUM_PAGES {
+            let pte_value = gsp_mem
+                    .dma_handle()
+                    .checked_add(num::usize_as_u64(i) << GSP_PAGE_SHIFT)
+                    .ok_or(EOVERFLOW)?;
+
+            // SAFETY: `item_from_index` ensures that `item` is always a valid pointer and can be
+            // dereferenced. The compiler also further validates the expression on whether `field`
+            // is a member of `item` when expanded by the macro.
+            //
+            // Further, this is dma_write! macro expanded and modified to allow for individual
+            // page write.
+            unsafe {
+                let ptr_field = core::ptr::addr_of_mut!((*item).ptes[i]);
+                gsp_mem.field_write(ptr_field, pte_value);
+            }
+        }
+
         dma_write!(gsp_mem[0].cpuq.tx = MsgqTxHeader::new(MSGQ_SIZE, RX_HDR_OFF, MSGQ_NUM_PAGES))?;
         dma_write!(gsp_mem[0].cpuq.rx = MsgqRxHeader::new())?;
 

---
base-commit: cea7b66a80412e2a5b74627b89ae25f1d0110a4b
change-id: 20260212-drm-rust-next-beb92aee9d75

Best regards,
-- 
Tim Kovalenko <tim.kovalenko@proton.me>

