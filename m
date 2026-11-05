From: Mani Tofigh <mt4022@columbia.edu>
Date: Thu, 05 Nov 2026 12:19:27 -0500
Subject: [PATCH v3] mm/swapfile: drop a large unmapped swap-in folio in
 unuse_pte()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-swapin-large-unmapped-v3-1-d5906e4cf18d@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XNTQ6CMBAF4KuYrq1pCxRw5T2Mi1IGGcNP00LVE
 O5uiwsTE+PyZd58byEOLIIjx91CLHh0OA4hJPsd0a0arkCxDpkIJiRnCaPurgwOtFM23OahV8Z
 ATaUuGgmy5IVMSfg1Fhp8bO758s5urm6gp4jFRotuGu1zG/Y89v5teE45TTmkCpK8AKlPeuzmv
 kJ1gHomccaLDxSkX5AIUJHrnEFW5iJjX9C6ri/CfztfGAEAAA==
X-Change-ID: 20261030-swapin-large-unmapped-6c8f6e691864
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Chris Li <chrisl@kernel.org>, 
 Kairui Song <kasong@tencent.com>
Cc: Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <baoquan.he@linux.dev>, Barry Song <baohua@kernel.org>, 
 Youngjun Park <youngjun.park@lge.com>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793899166; l=6342;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=8JpSwuWf9NP1iQYvz5Gpx6uSt1GJJVSQ0Pxbzq2T8RE=;
 b=xkIsHYjRBs2rIxzOFBF2QCdJqdG9ZWe2Zb7y5agSBS+3a8FYWIRsZN0iJGCkY1GbGI1UR/EXx
 4pSs4ibZEoJD8kISLzMiOBs1eP+1JiOnI0ge0A7V9/F0eLEa4DVx+Rg
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit f1879e8a0c60 ("mm, swap: never bypass the swap cache even
for SWP_SYNCHRONOUS_IO"), a fault can read a swapped-out mTHP range into
one large folio in the swap cache.  The folio only becomes anon once
do_swap_page() maps all of it, so if the faulting PTE changes in the
meantime the folio stays in the swap cache while not being mapped or
anon:

  Task A (fault)                       Task B
  do_swap_page()
    /* swaps in large folio F */
                                       madvise(MADV_DONTNEED)
                                         /* zaps the faulting PTE */
    /* PTE changed (F not mapped) */

swapoff then maps it, which marks all of its pages as mapped and
exclusive, and the next fault on one of the other PTEs crashes in
do_swap_page():

  [    6.424485] kernel BUG at mm/memory.c:5195!
  [    6.424503] Oops: invalid opcode: 0000 [#1] SMP KASAN NOPTI
  [    6.427654] CPU: 0 UID: 0 PID: 67 Comm: swapmthp Tainted: G        W            7.3.0-17087-gd865f2677c44 #1 PREEMPT
  [    6.432665] RIP: 0010:do_swap_page+0x24eb/0x2fa0
  [    6.451035] Call Trace:
  [    6.451567]  <TASK>
  [    6.453841]  __handle_mm_fault+0x13b5/0x3b40
  [    6.458525]  handle_mm_fault+0x16f/0x480
  [    6.461143]  do_user_addr_fault+0x312/0xa30
  [    6.462044]  exc_page_fault+0x66/0xc0
  [    6.462846]  asm_exc_page_fault+0x26/0x30
  [    6.476708]  </TASK>

do_swap_page() already drops such a folio from the swap cache when it
can't map all of it.  We move that check into a helper and use it in
unuse_pte() too, so swapoff drops the folio and swaps the entries in
again as small folios.  With the fix, the next fault doesn't crash
anymore.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 1s.

Fixes: f1879e8a0c60 ("mm, swap: never bypass the swap cache even for SWP_SYNCHRONOUS_IO")
Cc: stable@vger.kernel.org
Reviewed-by: Nhat Pham <nphamcs@gmail.com>
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Changes in v3:
- Don't handle a dirty folio, the helper already warns on debug kernels
  (David)
- Keep the comment above the check in do_swap_page() and say "some folio
  pages" instead of "sub pages" (David)
- Drop the note that the check goes away once folio allocation is unified
  in the swap cache layer, mention it here instead (David)
- Add Nhat's Reviewed-by
- Link to v2: https://lore.kernel.org/all/20261103-swapin-large-unmapped-v2-1-87c70e597250@columbia.edu/

Changes in v2:
- Move the check in do_swap_page() into a helper and use it in
  unuse_pte() too (David)
- Use VM_WARN_ON_ONCE() for a dirty folio (David, Kairui)
- Keep a dirty folio and return -EBUSY from unuse_pte() instead of
  dropping it, since dropping it would lose data (Kairui)
- Rebase on mm/core.git for-next-fixes
- Link to v1: https://lore.kernel.org/r/20261030-swapin-large-unmapped-v1-1-41e4ae378e6c@columbia.edu

This is based on mm/core.git for-next-fixes, on top of David's 7f2c000ffb10
("mm/ksm: check large swap-cache folios before mapping them").  On mm-new
it only differs in context and applies with a 3-way merge.

The check can go away once folio allocation is unified in the swap cache
layer, where allocating a folio stabilizes the swap entries.

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/swapmthp.c
---
 mm/memory.c   | 13 ++++---------
 mm/swap.h     | 10 ++++++++++
 mm/swapfile.c |  9 +++++++++
 3 files changed, 23 insertions(+), 9 deletions(-)

diff --git a/mm/memory.c b/mm/memory.c
index 91836d217d25..10016f7984fd 100644
--- a/mm/memory.c
+++ b/mm/memory.c
@@ -5170,18 +5170,13 @@ vm_fault_t do_swap_page(struct vm_fault *vmf)
 	 * If a large folio already belongs to anon mapping, then we
 	 * can just go on and map it partially.
 	 * If not, with the large swapin check above failing, the page table
-	 * have changed, so sub pages might got charged to the wrong cgroup,
-	 * or even should be shmem. So we have to free it and fallback.
+	 * have changed, so some folio pages might be charged to the wrong
+	 * cgroup, or even should be shmem. So we have to free it and fallback.
 	 * Nothing should have touched it, both anon and shmem checks if a
 	 * large folio is fully applicable before use.
-	 *
-	 * This will be removed once we unify folio allocation in the swap cache
-	 * layer, where allocation of a folio stabilizes the swap entries.
 	 */
-	if (!folio_test_anon(folio) && folio_test_large(folio) &&
-	    nr_pages != folio_nr_pages(folio)) {
-		if (!WARN_ON_ONCE(folio_test_dirty(folio)))
-			swap_cache_del_folio(folio);
+	if (!swap_cache_folio_mappable(folio, nr_pages)) {
+		swap_cache_del_folio(folio);
 		goto out_nomap;
 	}
 
diff --git a/mm/swap.h b/mm/swap.h
index d5bf21f517dc..7779ccff5a0d 100644
--- a/mm/swap.h
+++ b/mm/swap.h
@@ -464,6 +464,16 @@ static inline void __swap_cache_replace_folio(struct swap_cluster_info *ci,
 }
 #endif /* CONFIG_SWAP */
 
+static inline bool swap_cache_folio_mappable(struct folio *folio,
+		unsigned int nr_pages)
+{
+	if (folio_test_anon(folio) || !folio_test_large(folio) ||
+	    nr_pages == folio_nr_pages(folio))
+		return true;
+	VM_WARN_ON_ONCE_FOLIO(folio_test_dirty(folio), folio);
+	return false;
+}
+
 extern const struct swap_ops swap_bdev_ops;
 
 int shmem_writeout(struct swap_io_ctx *ctx, struct folio *folio,
diff --git a/mm/swapfile.c b/mm/swapfile.c
index 71ef9e2efb3a..5d915951639e 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -2513,6 +2513,15 @@ static int unuse_pte(struct vm_area_struct *vma, pmd_t *pmd,
 	if (!folio_matches_swap_entry(folio, entry))
 		return 0;
 
+	/*
+	 * A large folio that a fault didn't map can't be mapped one PTE at a
+	 * time here, so drop it and swap in small folios instead.
+	 */
+	if (unlikely(!swap_cache_folio_mappable(folio, 1))) {
+		swap_cache_del_folio(folio);
+		return 0;
+	}
+
 	swapcache = folio;
 	folio = ksm_might_need_to_copy(folio,
 				       folio_file_page(folio, swp_offset(entry)), vma, addr);

---
base-commit: 71555ae8c7572fd99158013ca2e29187c5d2508d
change-id: 20261030-swapin-large-unmapped-6c8f6e691864

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

