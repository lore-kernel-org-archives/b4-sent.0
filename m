From: Dave Airlie <airlied@redhat.com>
Date: Mon, 26 Oct 2026 14:24:13 +1000
Subject: [PATCH] gpu: nova-core: make pramin/buddy optional
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-nova-pramin-option-v1-1-d073b3f047fc@redhat.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDINbNyy9L1C0oSszNzNPNLygBKtc1NUhOSTMEyhpZGCoBNRYUpaZlVoA
 NjY6trQUAwL1fyGQAAAA=
X-Change-ID: 20261026-nova-pramin-option-50cdf1102281
To: Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=10660; i=airlied@redhat.com;
 h=from:subject:message-id; bh=y1Ee85SjLYBHnt+Mbfoy0aEr1Y5JSRZKiYENRoxCwXc=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq3tXu5PO9wEwJbKjSgA6vlZqeSRtnKJGH52VFy
 OZNLXHXrIaJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCat7V7gAKCRAMdPNZecSG
 vqsZD/sHdnK0GEJDTG12tR0y7WTGHNhd+8RW0DgG+a+Qjcy04ylv+pY/6HIatDuqhKGjxlg601B
 R70K2d9YmJ/0F7sFPz8kMmTADmCPlUB7I6krEcYp9vj4uQcQna/1bh75+H+xfmPMAtC7HKgxDwO
 FYO8673KTQ6T8SXlQDKBzatCV6lpX/hRoJT/pLipBHsC+9lbDLuwJUL3VIPlkN4zwZ7T8Qn1mdl
 Z/cJ3aV2TELq17KjqIxdfvPryT6jKEGhoron0cTHjM8W14p3KG3jvDk9RZYa9Em4ENHfUeA+CCx
 F5m1n+eDDTSiLmEqZNsoz4JhU0au17+FfMOYZmcF36zhf0E2PLBh3KTsZPwV+8q88l3lRO6Mf9J
 yWA70E0ciRWZWuDYyNdberhU/qDcMbEm5pi3hdXPgEif6mNHM0pVFbzjw5YY7Coq8H6/g8lyMQb
 wJgFUrSMrf+vOIVMsJetepH79rQ+P4kPECd9Oa28wXOijcxxsue9u7CWapfYMeORJWQAYicALkB
 3B2mH2SpO2iUWdK+DhR7YoIz+S6I4oocBMnycEupcIHyNmHbh+RMnwTSVto8l9H5a4eI3arGgww
 P0LMVQotg4CMQFbe59vyNc3Y+TgeGqEuuhpfPvxwNA3xUpfXxVEnUPGDjpqsBkGv+aog4+OTviJ
 BZh+t/bHe5gaaZg==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These aren't used on systems with no framebuffer memory.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/nova-core/gpu.rs               | 15 +++++++------
 drivers/gpu/nova-core/mm.rs                | 34 +++++++++++++++---------------
 drivers/gpu/nova-core/mm/bar_user.rs       | 14 ++++++------
 drivers/gpu/nova-core/mm/pagetable/map.rs  | 10 ++++-----
 drivers/gpu/nova-core/mm/pagetable/walk.rs |  2 +-
 5 files changed, 38 insertions(+), 37 deletions(-)

diff --git a/drivers/gpu/nova-core/gpu.rs b/drivers/gpu/nova-core/gpu.rs
index 4e59072cab50..5d53fde2cdc1 100644
--- a/drivers/gpu/nova-core/gpu.rs
+++ b/drivers/gpu/nova-core/gpu.rs
@@ -564,18 +564,19 @@ pub(crate) fn new<'a>(
 
             // Create GPU memory manager owning memory management resources.
             mm: {
-                let usable_vram = gsp_static_info.usable_fb_regions.first().ok_or(ENODEV)?;
-                let buddy_params = GpuBuddyParams {
-                    base_offset: usable_vram.start,
-                    size: usable_vram.end - usable_vram.start,
-                    chunk_size: Alignment::new::<SZ_4K>(),
-                };
+                let buddy_params = gsp_static_info.usable_fb_regions.first().map(|usable_vram| {
+                    GpuBuddyParams {
+                        base_offset: usable_vram.start,
+                        size: usable_vram.end - usable_vram.start,
+                        chunk_size: Alignment::new::<SZ_4K>(),
+                    }
+                });
 
                 GpuMm::new(
                     bar,
                     gsp_resources.spec.chipset,
                     buddy_params,
-                    VramAddress::from_raw(gsp_static_info.total_fb_end),
+                    Some(VramAddress::from_raw(gsp_static_info.total_fb_end)),
                 )?
             },
 
diff --git a/drivers/gpu/nova-core/mm.rs b/drivers/gpu/nova-core/mm.rs
index 8a934c55169f..9a2c73c978be 100644
--- a/drivers/gpu/nova-core/mm.rs
+++ b/drivers/gpu/nova-core/mm.rs
@@ -71,12 +71,12 @@ macro_rules! impl_pfn_bounded {
 /// GPU Memory Manager - owns all core MM components.
 ///
 /// Provides centralized ownership of memory management resources:
-/// - [`GpuBuddy`] allocator for VRAM page table allocation.
-/// - [`pramin::Pramin`] for direct VRAM access.
+/// - Optional [`GpuBuddy`] allocator for VRAM page table allocation.
+/// - Optional [`pramin::Pramin`] for direct VRAM access.
 /// - [`Tlb`] manager for translation buffer flush operations.
 pub(crate) struct GpuMm<'gpu> {
-    buddy: GpuBuddy,
-    pramin: pramin::Pramin<'gpu>,
+    buddy: Option<GpuBuddy>,
+    pramin: Option<pramin::Pramin<'gpu>>,
     tlb: Pin<KBox<Tlb<'gpu>>>,
 }
 
@@ -85,28 +85,28 @@ impl<'gpu> GpuMm<'gpu> {
     pub(crate) fn new(
         bar: Bar0<'gpu>,
         chipset: Chipset,
-        buddy_params: GpuBuddyParams,
-        total_fb_end: VramAddress,
+        buddy_params: Option<GpuBuddyParams>,
+        total_fb_end: Option<VramAddress>,
     ) -> Result<Self> {
-        // PRAMIN covers all physical VRAM (including GSP-reserved areas
-        // above the usable region, e.g. the BAR1 page directory).
-        let vram_region = VramAddress::ZERO..total_fb_end;
-
         Ok(Self {
-            buddy: GpuBuddy::new(buddy_params)?,
-            pramin: pramin::Pramin::new(bar, chipset, vram_region)?,
+            buddy: buddy_params.map(GpuBuddy::new).transpose()?,
+            // PRAMIN covers all physical VRAM, including GSP-reserved areas above
+            // the usable region, such as the BAR1 page directory.
+            pramin: total_fb_end
+                .map(|end| pramin::Pramin::new(bar, chipset, VramAddress::ZERO..end))
+                .transpose()?,
             tlb: KBox::pin_init(Tlb::new(bar), GFP_KERNEL)?,
         })
     }
 
     /// Access the [`GpuBuddy`] allocator.
-    pub(crate) fn buddy(&self) -> &GpuBuddy {
-        &self.buddy
+    pub(crate) fn buddy(&self) -> Result<&GpuBuddy> {
+        self.buddy.as_ref().ok_or(ENODEV)
     }
 
     /// Access the [`pramin::Pramin`].
-    fn pramin_mut(&mut self) -> &mut pramin::Pramin<'gpu> {
-        &mut self.pramin
+    fn pramin_mut(&mut self) -> Result<&mut pramin::Pramin<'gpu>> {
+        self.pramin.as_mut().ok_or(ENODEV)
     }
 
     /// Access the [`Tlb`] manager.
@@ -329,7 +329,7 @@ pub(crate) fn run(
             return Ok(());
         };
 
-        pramin::selftest::run(dev, mm.pramin_mut(), VramAddress::from_raw(base))?;
+        pramin::selftest::run(dev, mm.pramin_mut()?, VramAddress::from_raw(base))?;
         bar_user::run_self_test(dev, mm, bar_user, bar1_pdb, chipset)
     }
 }
diff --git a/drivers/gpu/nova-core/mm/bar_user.rs b/drivers/gpu/nova-core/mm/bar_user.rs
index 6e9384f06f43..baf9450b93a6 100644
--- a/drivers/gpu/nova-core/mm/bar_user.rs
+++ b/drivers/gpu/nova-core/mm/bar_user.rs
@@ -212,14 +212,14 @@ pub(crate) fn run_self_test(
     let pdb_addr = VramAddress::from_raw(bar1_pdb);
 
     // Check if initial page tables are in VRAM.
-    if crate::mm::pagetable::check_pdb_valid(mm.pramin_mut(), pdb_addr, chipset).is_err() {
+    if crate::mm::pagetable::check_pdb_valid(mm.pramin_mut()?, pdb_addr, chipset).is_err() {
         dev_info!(dev, "MM: Self-test SKIPPED - no valid VRAM page tables\n");
         return Ok(());
     }
 
     // Set up a test page from the buddy allocator.
     let test_page_blocks = KBox::pin_init(
-        mm.buddy().alloc_blocks(
+        mm.buddy()?.alloc_blocks(
             GpuBuddyAllocMode::Simple,
             SZ_4K.into_safe_cast(),
             Alignment::new::<SZ_4K>(),
@@ -245,7 +245,7 @@ pub(crate) fn run_self_test(
     let vram_read_addr = test_vram + 0x100;
 
     // Test 1: Write via PRAMIN, read via BAR1.
-    mm.pramin_mut()
+    mm.pramin_mut()?
         .window_at::<u32>(vram_read_addr)?
         .view()
         .write_val(PATTERN_PRAMIN);
@@ -296,7 +296,7 @@ pub(crate) fn run_self_test(
 
     // Punch a 4K hole at base+16K so the subsequent 32K allocation must split.
     let _hole = KBox::pin_init(
-        mm.buddy().alloc_blocks(
+        mm.buddy()?.alloc_blocks(
             GpuBuddyAllocMode::Range(range_base + sz_16k..range_base + sz_16k + sz_4k),
             SZ_4K.into_safe_cast(),
             Alignment::new::<SZ_4K>(),
@@ -308,7 +308,7 @@ pub(crate) fn run_self_test(
     // Allocate 32K within [base, base+36K). The hole forces the allocator to return
     // split blocks whose sizes are determined by buddy alignment.
     let blocks = KBox::pin_init(
-        mm.buddy().alloc_blocks(
+        mm.buddy()?.alloc_blocks(
             GpuBuddyAllocMode::Range(range_base..range_base + sz_32k_4k),
             SZ_32K.into_safe_cast(),
             Alignment::new::<SZ_4K>(),
@@ -353,7 +353,7 @@ pub(crate) fn run_self_test(
             bar1.try_write32(PATTERN_BAR1, page_bar1_off)?;
 
             let pramin_val = mm
-                .pramin_mut()
+                .pramin_mut()?
                 .window_at::<u32>(VramAddress::from_raw(page_phys))?
                 .view()
                 .read_val();
@@ -391,7 +391,7 @@ pub(crate) fn run_self_test(
     let access = bar_user.map(mm, &[test_pfn], true)?;
 
     // Write pattern via PRAMIN, read via BarUserAccess.
-    mm.pramin_mut()
+    mm.pramin_mut()?
         .window_at::<u32>(test_vram)?
         .view()
         .write_val(PATTERN_BAR1);
diff --git a/drivers/gpu/nova-core/mm/pagetable/map.rs b/drivers/gpu/nova-core/mm/pagetable/map.rs
index 77431c509a89..fd404b0734bb 100644
--- a/drivers/gpu/nova-core/mm/pagetable/map.rs
+++ b/drivers/gpu/nova-core/mm/pagetable/map.rs
@@ -81,7 +81,7 @@ pub(super) fn new(pdb_addr: VramAddress) -> Self {
     /// Allocate and zero a physical page table page.
     fn alloc_and_zero_page(mm: &mut GpuMm<'_>, level: PageTableLevel) -> Result<PreparedPtPage> {
         let blocks = KBox::pin_init(
-            mm.buddy().alloc_blocks(
+            mm.buddy()?.alloc_blocks(
                 GpuBuddyAllocMode::Simple,
                 SZ_4K.into_safe_cast(),
                 Alignment::new::<SZ_4K>(),
@@ -94,7 +94,7 @@ fn alloc_and_zero_page(mm: &mut GpuMm<'_>, level: PageTableLevel) -> Result<Prep
 
         // Zero via PRAMIN.
         let window = mm
-            .pramin_mut()
+            .pramin_mut()?
             .window_at::<[u64; PAGE_SIZE / 8]>(page_vram)?;
         for i in 0..PAGE_SIZE / 8 {
             io_write!(window.view(), [build: i], 0);
@@ -120,7 +120,7 @@ fn ensure_single_pte_path(
         for _ in 0..max_iter {
             let result = self
                 .walker
-                .walk_pde_levels(mm.pramin_mut(), vfn, |install_addr| {
+                .walk_pde_levels(mm.pramin_mut()?, vfn, |install_addr| {
                     pt_pages.get(&install_addr).and_then(|p| {
                         p.alloc
                             .iter()
@@ -197,7 +197,7 @@ pub(super) fn install_mappings(
         writable: bool,
     ) -> Result {
         {
-            let pramin = mm.pramin_mut();
+            let pramin = mm.pramin_mut()?;
 
             // Drain prepared PT pages, install all pending PDEs.
             let mut cursor = pt_pages.cursor_front_mut();
@@ -255,7 +255,7 @@ pub(super) fn invalidate_ptes(
         let invalid_pte = M::Pte::invalid();
 
         {
-            let pramin = mm.pramin_mut();
+            let pramin = mm.pramin_mut()?;
             for i in 0..num_pages {
                 let i_u64: u64 = i.into_safe_cast();
                 let vfn = Vfn::new(vfn_start.raw() + i_u64);
diff --git a/drivers/gpu/nova-core/mm/pagetable/walk.rs b/drivers/gpu/nova-core/mm/pagetable/walk.rs
index 76c1729971f5..19aae75c2c76 100644
--- a/drivers/gpu/nova-core/mm/pagetable/walk.rs
+++ b/drivers/gpu/nova-core/mm/pagetable/walk.rs
@@ -172,7 +172,7 @@ pub(super) fn walk_pde_levels(
     ///
     /// Returns [`WalkResult::PageTableMissing`] if intermediate tables don't exist.
     pub(super) fn walk_to_pte_lookup(&self, mm: &mut GpuMm<'_>, vfn: Vfn) -> Result<WalkResult> {
-        self.walk_to_pte_lookup_with_window(mm.pramin_mut(), vfn)
+        self.walk_to_pte_lookup_with_window(mm.pramin_mut()?, vfn)
     }
 
     /// Walk to PTE using a caller-provided PRAMIN manager (lookup only).

---
base-commit: 3497a403264b094ebd61b8b755165d56e7d9dc37
change-id: 20261026-nova-pramin-option-50cdf1102281

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

