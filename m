From: Tim Kovalenko <tim.kovalenko@proton.me>
Date: Mon, 09 Mar 2026 12:34:21 -0400
Subject: [PATCH v4 4/4] gpu: nova-core: fix stack overflow in GSP memory
 allocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-drm-rust-next-v4-4-4ef485b19a4c@proton.me>
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
 linux-kbuild@vger.kernel.org, driver-core@lists.linux.dev, 
 Tim Kovalenko <tim.kovalenko@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773074117; l=3986;
 i=tim.kovalenko@proton.me; s=20260212; h=from:subject:message-id;
 bh=02lIiBKVUWPZgiHflont6ppBx+2QAZbO4PzXiivsIkE=;
 b=pE0ZKAo+0q+3X2PamEznSFPbbQiSdIw7Xy/EgQG+Zfy/iiwn0Rb6Om2UKZsCeEXyeudQjTtkF
 +jL/j8+uX6ICxdDQJsEfm++qZt+CwLBc7cGDTtVkdNtnXo/EFKH2KKd
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
 drivers/gpu/nova-core/gsp.rs      | 34 +++++++++++++++++++---------------
 drivers/gpu/nova-core/gsp/cmdq.rs | 15 ++++++++++++++-
 2 files changed, 33 insertions(+), 16 deletions(-)

diff --git a/drivers/gpu/nova-core/gsp.rs b/drivers/gpu/nova-core/gsp.rs
index 25cd48514c777cb405a2af0acf57196b2e2e7837..20170e483e04c476efce8997b3916b0ad829ed38 100644
--- a/drivers/gpu/nova-core/gsp.rs
+++ b/drivers/gpu/nova-core/gsp.rs
@@ -47,16 +47,11 @@
 unsafe impl<const NUM_ENTRIES: usize> AsBytes for PteArray<NUM_ENTRIES> {}
 
 impl<const NUM_PAGES: usize> PteArray<NUM_PAGES> {
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
+    /// Returns the page table entry for `index`, for a mapping starting at `start` DmaAddress.
+    fn entry(start: DmaAddress, index: usize) -> Result<u64> {
+        start
+            .checked_add(num::usize_as_u64(index) << GSP_PAGE_SHIFT)
+            .ok_or(EOVERFLOW)
     }
 }
 
@@ -86,16 +81,25 @@ fn new(dev: &device::Device<device::Bound>) -> Result<Self> {
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
 
+        // This is a  one by one GSP Page write to the memory
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
index 0056bfbf0a44cfbc5a0ca08d069f881b877e1edc..c8327d3098f73f9b880eee99038ad10a16e1e32d 100644
--- a/drivers/gpu/nova-core/gsp/cmdq.rs
+++ b/drivers/gpu/nova-core/gsp/cmdq.rs
@@ -202,7 +202,20 @@ fn new(dev: &device::Device<device::Bound>) -> Result<Self> {
 
         let gsp_mem =
             CoherentAllocation::<GspMem>::alloc_coherent(dev, 1, GFP_KERNEL | __GFP_ZERO)?;
-        dma_write!(gsp_mem, [0]?.ptes, PteArray::new(gsp_mem.dma_handle())?);
+
+        const NUM_PTES: usize = GSP_PAGE_SIZE / size_of::<u64>();
+
+        let start = gsp_mem.dma_handle();
+        // One by one GSP Page write to the memory to avoid stack overflow when allocating
+        // the whole array at once.
+        for i in 0..NUM_PTES {
+            dma_write!(
+                gsp_mem,
+                [0]?.ptes.0[i],
+                PteArray::<NUM_PTES>::entry(start, i)?
+            );
+        }
+
         dma_write!(
             gsp_mem,
             [0]?.cpuq.tx,

-- 
2.53.0

