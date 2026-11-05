From: Mani Tofigh <mt4022@columbia.edu>
Date: Thu, 05 Nov 2026 15:50:42 -0500
Subject: [PATCH v2] mm/memory_hotplug: don't offline a hwpoisoned page
 still in the page cache
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-memhp-hwpoison-pagecache-v2-1-029d35634d42@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBBFf4V0bU1bnrryPwyLoYx0jLRNC6gh/
 Ls81i5Pcu85M4sYCCO7JjMLOFEkZ1dQp4RpA7ZDTu3KTAlVSKEuvMfeeG7e3lF0lnvoUIM2yKH
 AFHKVQVoKtt59wAd9dvW9PjiOzRP1sPm2haE4uPDd25PcdkdGCvk/M0kuObZVWeUasgybm3avs
 W8IztiOrF6W5QcbMN/m1QAAAA==
X-Change-ID: 20261029-memhp-hwpoison-pagecache-a6e3a524a370
To: David Hildenbrand <david@kernel.org>, 
 Oscar Salvador <osalvador@suse.de>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: Miaohe Lin <linmiaohe@huawei.com>, 
 Naoya Horiguchi <nao.horiguchi@gmail.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Gregory Price <gourry@gourry.net>, 
 linux-mm@kvack.org, linux-cxl@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793911842; l=6645;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=LcESJSofCaj5hhsA+wo/1wUjY9ar4+NtuF2td4wtlmY=;
 b=L6SShOaykmI6dCci4Iy1FG7sziKGM25QC0E0mxJNfwPNCYkScmr7PKCl2ukaPWDTZ8RA8L9fU
 czAA+IwmvnrB3pXpqIFkAfhsj5sEa///R1+XfVVYQNXRgEsXOnfQb96
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Memory offline skips hwpoisoned pages, assuming nobody uses them
anymore.  memory_failure() however sets PG_hwpoison before it takes the
page, and taking it waits on pcp_batch_high_lock, which offline_pages()
holds for the whole offline.  A memory error during the offline thus
marks the page and then waits while the offline skips it:

  Task A (offline_pages)               Task B (memory_failure)
  zone_pcp_disable()
                                       TestSetPageHWPoison(P)
                                       get_hwpoison_page()
                                         /* waits for Task A */
  do_migrate_range()
    /* P is poisoned (not migrated) */
  test_pages_isolated()
    /* P is poisoned (accepted) */
  zone_pcp_enable()
                                       /* P is off the LRU (Ignored) */

The block goes offline while the file still points to P, and the next
walk of the file's pages (here drop_caches on ext4) crashes on a struct
page of offlined memory:

  [   11.710348] Memory failure: 0x24224: unhandlable page.
  [   11.710372] Memory failure: 0x24224: recovery action for get hwpoison page: Ignored
  [   11.765371] page:000000008c304eee is uninitialized and poisoned
  [   11.765389] page dumped because: VM_BUG_ON_PAGE(page_ref_count(page) == 0)
  [   11.765440] kernel BUG at include/linux/mm.h:1990!
  [   11.765458] Oops: invalid opcode: 0000 [#1] SMP KASAN NOPTI
  [   11.772284] CPU: 3 UID: 0 PID: 85 Comm: mfoffline Tainted: G        W            7.3.0-17087-gd865f2677c44 #1 PREEMPT
  [   11.777970] RIP: 0010:find_lock_entries+0x8ee/0xad0
  [   11.798761] Call Trace:
  [   11.799297]  <TASK>
  [   11.803284]  mapping_try_invalidate+0xfd/0x2c0
  [   11.810571]  drop_pagecache_sb+0x111/0x330
  [   11.811572]  __iterate_supers+0x2e2/0x370
  [   11.815863]  drop_caches_sysctl_handler+0x74/0xb0
  [   11.816994]  proc_sys_call_handler+0x2ec/0x440
  [   11.821360]  vfs_write+0x545/0x1250
  [   11.825220]  ksys_write+0xfa/0x200
  [   11.830202]  do_syscall_64+0xfb/0x590
  [   11.832084]  entry_SYSCALL_64_after_hwframe+0x77/0x7f
  [   11.848423]  </TASK>

Once the memory is also removed it's a use-after-free of the memory map.
tmpfs and the swap cache can end up the same way without the race.
Since commit a76054266661 ("mm: shmem: don't truncate page if memory
failure happens"), memory_failure() leaves a poisoned tmpfs folio in the
page cache on purpose, and it does the same for a dirty folio in the
swap cache.

Treat a hwpoisoned page whose folio is still in a page cache or swap
cache as busy in scan_movable_pages() and
__test_page_isolated_in_pageblock() so that the offline fails and a
waiting memory_failure() can go on.  Also have do_migrate_range() leave
such a folio alone instead of taking it off the LRU, so that
memory_failure() can still remove it from the cache.  A later offline
succeeds once the page is out of the cache.  With the fix, the offline
fails with -EBUSY and the file doesn't point to offlined memory anymore.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 10s.

Fixes: b023f46813cd ("memory-hotplug: skip HWPoisoned page when offlining pages")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Changes in v2:
- Leave a hwpoisoned folio that is still in a page cache or swap cache
  alone in do_migrate_range(), so that a waiting memory_failure() can
  still remove it from the cache (Sashiko)
- Rebase onto current mm-new
- Link to v1: https://lore.kernel.org/all/20261101-memhp-hwpoison-pagecache-v1-1-ed8785ca44eb@columbia.edu/

A pinned hwpoisoned page still isn't covered.  I'll send the refcount
check David suggested as a follow-up.

Taking get_online_mems() in memory_failure(), as in Gregory's series
[1], would close only the race and not the tmpfs or swap cache case.

[1] https://lore.kernel.org/all/20261027042204.3741307-4-gourry@gourry.net/

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/mfoffline.c
---
 mm/internal.h       | 9 +++++++++
 mm/memory_hotplug.c | 5 +++++
 mm/page_isolation.c | 2 +-
 3 files changed, 15 insertions(+), 1 deletion(-)

diff --git a/mm/internal.h b/mm/internal.h
index 78a7f17b9934..35c6d30537f0 100644
--- a/mm/internal.h
+++ b/mm/internal.h
@@ -1168,6 +1168,15 @@ static inline bool node_reclaim_enabled(void)
 	return node_reclaim_mode & (RECLAIM_ZONE|RECLAIM_WRITE|RECLAIM_UNMAP);
 }
 
+/*
+ * A hwpoisoned page can be skipped by memory offline only once no page
+ * cache or swap cache can find it anymore.
+ */
+static inline bool hwpoison_page_offlineable(const struct page *page)
+{
+	return !folio_mapping(page_folio(page));
+}
+
 extern unsigned long  __must_check vm_mmap_pgoff(struct file *, unsigned long,
         unsigned long, unsigned long,
         unsigned long, unsigned long);
diff --git a/mm/memory_hotplug.c b/mm/memory_hotplug.c
index 1bfd1f4daeb2..c5cfaa24b41b 100644
--- a/mm/memory_hotplug.c
+++ b/mm/memory_hotplug.c
@@ -1821,6 +1821,8 @@ static int scan_movable_pages(unsigned long start, unsigned long end,
 		struct folio *folio;
 
 		page = pfn_to_page(pfn);
+		if (PageHWPoison(page) && !hwpoison_page_offlineable(page))
+			return -EBUSY;
 		if (PageLRU(page) || page_has_movable_ops(page))
 			goto found;
 
@@ -1887,6 +1889,9 @@ static void do_migrate_range(unsigned long start_pfn, unsigned long end_pfn)
 			 */
 			if (folio_test_large(folio) && !folio_test_hugetlb(folio))
 				goto put_folio;
+			/* The offline fails on it anyway, leave it to memory_failure() */
+			if (!hwpoison_page_offlineable(page))
+				goto put_folio;
 			if (folio_test_lru(folio) && !folio_isolate_lru(folio))
 				goto put_folio;
 			if (folio_mapped(folio)) {
diff --git a/mm/page_isolation.c b/mm/page_isolation.c
index 5aaad037384e..beb09ef345ee 100644
--- a/mm/page_isolation.c
+++ b/mm/page_isolation.c
@@ -593,7 +593,7 @@ __test_page_isolated_in_pageblock(unsigned long pfn, unsigned long end_pfn,
 			 */
 			pfn += 1 << buddy_order(page);
 		else if ((mode == PB_ISOLATE_MODE_MEM_OFFLINE) &&
-			 PageHWPoison(page))
+			 PageHWPoison(page) && hwpoison_page_offlineable(page))
 			/* A HWPoisoned page cannot be also PageBuddy */
 			pfn++;
 		else if ((mode == PB_ISOLATE_MODE_MEM_OFFLINE) &&

---
base-commit: dba8aba0a9a00ff781c03d82ae534fc6f8c2e263
change-id: 20261029-memhp-hwpoison-pagecache-a6e3a524a370

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

