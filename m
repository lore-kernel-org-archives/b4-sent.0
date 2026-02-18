From: Tim Kovalenko <tim.kovalenko@proton.me>
Date: Tue, 17 Feb 2026 23:01:29 -0500
Subject: [PATCH v3] gpu: nova-core: fix stack overflow in GSP memory
 allocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260217-drm-rust-next-v3-1-9e7e95c597dc@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XMQQ6CMBCF4auQrq1pBwTqynsYF8UO0gUtmdYGQ
 7i7hRUxcfle8v0LC0gWA7sWCyNMNljv8ihPBXsO2r2QW5M3AwG1AAnc0MjpHSJ3OEfeYadAIyr
 TXFg2E2Fv5713f+Q92BA9ffZ8ktv7r5Qkl7wSqlRtJwFreZvIR+/OI7KtlOCoy18NWWstVNU3b
 QNSH/W6rl/aVHVF6AAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771387293; l=6122;
 i=tim.kovalenko@proton.me; s=20260212; h=from:subject:message-id;
 bh=9d2Vc62rvOiPpAv0Hkn6Wiy01xq2m2s0v3zXT6ns3tQ=;
 b=XCWTBdsFpHQ/x01zkYW8tXHp3uoZqiNipbkmGPP5tl3V3birQttmkhUkU/SzQj6SQtRxxKDIJ
 UQItC1vjmCxAcX/TmTwm0CmI+0dMv+HZGHQ3UqAmaB+PmF5qyM+XeVJ
X-Developer-Key: i=tim.kovalenko@proton.me; a=ed25519;
 pk=/+OiulEpgeZifgP4mDE4e5YlV6nMeY+frze/lY/xiHI=
X-Endpoint-Received: by B4 Relay for tim.kovalenko@proton.me/20260212 with auth_id=635
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The `Cmdq::new` function was allocating a `PteArray` struct on the stack
and was causing a stack overflow with 8216 bytes.

Modify the `PteArray` to calculate and write the Page Table Entries
directly into the coherent DMA buffer one-by-one. This reduces the stack
usage quite a lot.

Signed-off-by: Tim Kovalenko <tim.kovalenko@proton.me>
---
Changes in v3:
- Addressed the comments and re-instated the PteArray type.
- PteArray now uses `init` instead of `new` where it writes to `self`
  page by page.
- PteArray just needs a pte pointer obtained from the `gsp_mem.as_slice_mut`.

I hope I understood everything in the V2 email chain and implemented it correctly :)

- Link to v2: https://lore.kernel.org/r/20260213-drm-rust-next-v2-1-aa094f78721a@proton.me

Changes in v2:
- Missed a code formatting issue.
- Link to v1: https://lore.kernel.org/r/20260212-drm-rust-next-v1-1-409398b12e61@proton.me
---
 drivers/gpu/nova-core/gsp.rs      | 34 +++++++++++++++++++++++-----------
 drivers/gpu/nova-core/gsp/cmdq.rs | 20 +++++++++++++++-----
 2 files changed, 38 insertions(+), 16 deletions(-)

diff --git a/drivers/gpu/nova-core/gsp.rs b/drivers/gpu/nova-core/gsp.rs
index 174feaca0a6b9269cf35286dec3acc4d60918904..7dc67fd55ce6ce19cbb750961dcfb4e373a20b4c 100644
--- a/drivers/gpu/nova-core/gsp.rs
+++ b/drivers/gpu/nova-core/gsp.rs
@@ -2,6 +2,8 @@
 
 mod boot;
 
+use core::iter::Iterator;
+
 use kernel::{
     device,
     dma::{
@@ -30,7 +32,7 @@
         GspArgumentsPadded,
         LibosMemoryRegionInitArgument, //
     },
-    num,
+    num, //
 };
 
 pub(crate) const GSP_PAGE_SHIFT: usize = 12;
@@ -47,16 +49,17 @@
 unsafe impl<const NUM_ENTRIES: usize> AsBytes for PteArray<NUM_ENTRIES> {}
 
 impl<const NUM_PAGES: usize> PteArray<NUM_PAGES> {
-    /// Creates a new page table array mapping `NUM_PAGES` GSP pages starting at address `start`.
-    fn new(start: DmaAddress) -> Result<Self> {
-        let mut ptes = [0u64; NUM_PAGES];
-        for (i, pte) in ptes.iter_mut().enumerate() {
+    /// Initializes the page table array mapping `NUM_PAGES` GSP pages starting at address `start`.
+    /// This is done "in-memory" without using the stack to avoid overflow, by writing one page at
+    /// a time to the memory region
+    fn init(&mut self, start: DmaAddress) -> Result {
+        for (i, pte) in self.0.iter_mut().enumerate() {
             *pte = start
                 .checked_add(num::usize_as_u64(i) << GSP_PAGE_SHIFT)
                 .ok_or(EOVERFLOW)?;
         }
 
-        Ok(Self(ptes))
+        Ok(())
     }
 }
 
@@ -86,16 +89,25 @@ fn new(dev: &device::Device<device::Bound>) -> Result<Self> {
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
 
+        // As in [`PteArray::init`], this is a  one by one GSP Page write to the memory
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
index 46819a82a51adc58423502d9d45730923b843656..132342a1a6d843e999e2d0e4fbcc76bde2bd8652 100644
--- a/drivers/gpu/nova-core/gsp/cmdq.rs
+++ b/drivers/gpu/nova-core/gsp/cmdq.rs
@@ -23,7 +23,7 @@
     transmute::{
         AsBytes,
         FromBytes, //
-    },
+    }, //
 };
 
 use crate::{
@@ -34,10 +34,10 @@
             MsgFunction,
             MsgqRxHeader,
             MsgqTxHeader, //
-        },
+        }, //
         PteArray,
         GSP_PAGE_SHIFT,
-        GSP_PAGE_SIZE, //
+        GSP_PAGE_SIZE,
     },
     num,
     regs,
@@ -159,6 +159,7 @@ struct Msgq {
 #[repr(C)]
 struct GspMem {
     /// Self-mapping page table entries.
+    // ptes: [u64; GSP_PAGE_SIZE / size_of::<u64>()],
     ptes: PteArray<{ GSP_PAGE_SIZE / size_of::<u64>() }>,
     /// CPU queue: the driver writes commands here, and the GSP reads them. It also contains the
     /// write and read pointers that the CPU updates.
@@ -199,9 +200,18 @@ fn new(dev: &device::Device<device::Bound>) -> Result<Self> {
         const MSGQ_SIZE: u32 = num::usize_into_u32::<{ size_of::<Msgq>() }>();
         const RX_HDR_OFF: u32 = num::usize_into_u32::<{ mem::offset_of!(Msgq, rx) }>();
 
-        let gsp_mem =
+        let mut gsp_mem =
             CoherentAllocation::<GspMem>::alloc_coherent(dev, 1, GFP_KERNEL | __GFP_ZERO)?;
-        dma_write!(gsp_mem[0].ptes = PteArray::new(gsp_mem.dma_handle())?)?;
+
+        let start_address = gsp_mem.dma_handle();
+
+        // SAFETY: `gsp_mem` has just been created and we are its sole user.
+        let mem: &mut [GspMem] = unsafe { gsp_mem.as_slice_mut(0, 1)? };
+
+        // Borrowing the array from gsp_mem and writing directly to that in the init method of
+        // PteArray
+        mem[0].ptes.init(start_address)?;
+
         dma_write!(gsp_mem[0].cpuq.tx = MsgqTxHeader::new(MSGQ_SIZE, RX_HDR_OFF, MSGQ_NUM_PAGES))?;
         dma_write!(gsp_mem[0].cpuq.rx = MsgqRxHeader::new())?;
 

---
base-commit: cea7b66a80412e2a5b74627b89ae25f1d0110a4b
change-id: 20260212-drm-rust-next-beb92aee9d75

Best regards,
-- 
Tim Kovalenko <tim.kovalenko@proton.me>

