From: Kairui Song <kasong@tencent.com>
Date: Tue, 04 Aug 2026 03:47:07 +0800
Subject: [PATCH RFC 11/15] mm/mglru: replace folio workinset check and
 update with new helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-mglru-fg-v1-11-4d8dad39dad6@tencent.com>
References: <20260804-mglru-fg-v1-0-4d8dad39dad6@tencent.com>
In-Reply-To: <20260804-mglru-fg-v1-0-4d8dad39dad6@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <qi.zheng@linux.dev>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Chris Li <chrisl@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, Zi Yan <ziy@nvidia.com>, 
 Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SeongJae Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Chen Ridong <chenridong@xiaomi.com>, 
 Tal Zussman <tz2294@columbia.edu>, Kairui Song <ryncsn@gmail.com>, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785786439; l=7823;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=ps3GPccJmNKKFg75e7bKrntkjE3H1Gau9WECQyN6J8c=;
 b=SsYlfhIoI9qTSRrpCosoUsyZvOU0ul0m78d3Qr/DFKMMXzkq44g4dt3l0QbyqaioklkvikIIo
 XQr9zDOideJDFLJAUTIr+IvQonmZ1XL5DQ4gdvvRSPbhot5/9ELDycb
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With the new folio LRU refs tracking API, when MGLRU enabled, a folio
is considered a workingset folio if its referenced count > 1. This is
compatible with classical LRU and reasonable in many ways:

The PG_referenced and PG_workingset are used as the lower bits of the
LRU refs counter, and MGLRU will make use of extra bits as higher bits.

So when MGLRU is disabled, all higher bits are always 0, making the
check bit-wise equal to the old behavior. Active/inactive LRU sets
PG_workingset explicitly for folios moved from active list to inactive
list, and that makes the LRU refs tracking API (folio_is_workingset)
report a referenced number > 1. Clearing PG_workingset will always
return a value <= 1.

When MGLRU is enabled, a folio referenced twice is considered a
workingset folio, which is basically the same as how active/inactive LRU
used to promote a file page to the active list. Note for
active/inactive, the folio has to be marked inactive and PG_workingset
before eviction, but MGLRU doesn't have a demotion process, so this
simplified check ensures we have a stable definition and accurate
readings in PSI and readaheads just like before.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 fs/btrfs/compression.c | 3 ++-
 mm/filemap.c           | 8 ++++----
 mm/madvise.c           | 4 ++--
 mm/page_io.c           | 3 ++-
 mm/readahead.c         | 8 ++++----
 mm/vmscan.c            | 2 +-
 mm/workingset.c        | 4 ++--
 7 files changed, 17 insertions(+), 15 deletions(-)

diff --git a/fs/btrfs/compression.c b/fs/btrfs/compression.c
index ffb6b52863a7..e756403e8bd5 100644
--- a/fs/btrfs/compression.c
+++ b/fs/btrfs/compression.c
@@ -21,6 +21,7 @@
 #include <linux/sched/mm.h>
 #include <linux/log2.h>
 #include <linux/shrinker.h>
+#include <linux/mm_inline.h>
 #include "misc.h"
 #include "ctree.h"
 #include "fs.h"
@@ -448,7 +449,7 @@ static noinline int add_ra_bio_folios(struct inode *inode, u64 compressed_end,
 			continue;
 		}
 
-		if (!*memstall && folio_test_workingset(folio)) {
+		if (!*memstall && folio_is_workingset(folio)) {
 			psi_memstall_enter(pflags);
 			*memstall = 1;
 		}
diff --git a/mm/filemap.c b/mm/filemap.c
index 6afec636881f..a88a6140ed09 100644
--- a/mm/filemap.c
+++ b/mm/filemap.c
@@ -1259,7 +1259,7 @@ static inline int folio_wait_bit_common(struct folio *folio, int bit_nr,
 	bool in_thrashing;
 
 	if (bit_nr == PG_locked &&
-	    !folio_test_uptodate(folio) && folio_test_workingset(folio)) {
+	    !folio_test_uptodate(folio) && folio_is_workingset(folio)) {
 		delayacct_thrashing_start(&in_thrashing);
 		psi_memstall_enter(&pflags);
 		thrashing = true;
@@ -1414,7 +1414,7 @@ void softleaf_entry_wait_on_locked(softleaf_t entry, spinlock_t *ptl)
 	struct folio *folio = softleaf_to_folio(entry);
 
 	q = folio_waitqueue(folio);
-	if (!folio_test_uptodate(folio) && folio_test_workingset(folio)) {
+	if (!folio_test_uptodate(folio) && folio_is_workingset(folio)) {
 		delayacct_thrashing_start(&in_thrashing);
 		psi_memstall_enter(&pflags);
 		thrashing = true;
@@ -2510,7 +2510,7 @@ static void filemap_get_read_batch(struct address_space *mapping,
 static int filemap_read_folio(struct file *file, filler_t filler,
 		struct folio *folio)
 {
-	bool workingset = folio_test_workingset(folio);
+	bool workingset = folio_is_workingset(folio);
 	unsigned long pflags;
 	int error;
 
@@ -3981,7 +3981,7 @@ vm_fault_t filemap_map_pages(struct vm_fault *vmf,
 		 */
 		if ((map_ret & VM_FAULT_NOPAGE) &&
 		    !(vmf->flags & FAULT_FLAG_TRIED) &&
-		    !folio_test_workingset(folio) &&
+		    !folio_is_workingset(folio) &&
 		    !(vma->vm_flags & (VM_SEQ_READ | VM_EXEC))) {
 			unsigned short mmap_miss;
 
diff --git a/mm/madvise.c b/mm/madvise.c
index 07a21ca31bad..abb17760b8b5 100644
--- a/mm/madvise.c
+++ b/mm/madvise.c
@@ -427,7 +427,7 @@ static int madvise_cold_or_pageout_pte_range(pmd_t *pmd,
 		folio_clear_referenced(folio);
 		folio_test_clear_young(folio);
 		if (folio_test_active(folio))
-			folio_set_workingset(folio);
+			folio_mark_workingset_by_bit(folio);
 		if (pageout) {
 			if (folio_isolate_lru(folio)) {
 				if (folio_test_unevictable(folio))
@@ -542,7 +542,7 @@ static int madvise_cold_or_pageout_pte_range(pmd_t *pmd,
 		folio_clear_referenced(folio);
 		folio_test_clear_young(folio);
 		if (folio_test_active(folio))
-			folio_set_workingset(folio);
+			folio_mark_workingset_by_bit(folio);
 		if (pageout) {
 			if (folio_isolate_lru(folio)) {
 				if (folio_test_unevictable(folio))
diff --git a/mm/page_io.c b/mm/page_io.c
index e4fa7ffffe8b..e7efc5bff668 100644
--- a/mm/page_io.c
+++ b/mm/page_io.c
@@ -25,6 +25,7 @@
 #include <linux/sched/task.h>
 #include <linux/delayacct.h>
 #include <linux/zswap.h>
+#include <linux/mm_inline.h>
 #include "swap.h"
 #include "swap_table.h"
 
@@ -452,7 +453,7 @@ void swap_read_folio(struct swap_io_ctx *ctx, struct folio *folio)
 {
 	struct swap_info_struct *sis = __swap_entry_to_info(folio->swap);
 	bool synchronous = sis->flags & SWP_SYNCHRONOUS_IO;
-	bool workingset = folio_test_workingset(folio);
+	bool workingset = folio_is_workingset(folio);
 	unsigned long pflags;
 	bool in_thrashing;
 
diff --git a/mm/readahead.c b/mm/readahead.c
index 558c92957518..3ab796af6490 100644
--- a/mm/readahead.c
+++ b/mm/readahead.c
@@ -302,7 +302,7 @@ void page_cache_ra_unbounded(struct readahead_control *ractl,
 		}
 		if (i == mark)
 			folio_set_readahead(folio);
-		ractl->_workingset |= folio_test_workingset(folio);
+		ractl->_workingset |= folio_is_workingset(folio);
 		ractl->_nr_pages += min_nrpages;
 		i += min_nrpages;
 	}
@@ -474,7 +474,7 @@ static inline int ra_alloc_folio(struct readahead_control *ractl, pgoff_t index,
 	}
 
 	ractl->_nr_pages += 1UL << order;
-	ractl->_workingset |= folio_test_workingset(folio);
+	ractl->_workingset |= folio_is_workingset(folio);
 	return 0;
 }
 
@@ -817,7 +817,7 @@ void readahead_expand(struct readahead_control *ractl,
 			folio_put(folio);
 			return;
 		}
-		if (unlikely(folio_test_workingset(folio)) &&
+		if (unlikely(folio_is_workingset(folio)) &&
 				!ractl->_workingset) {
 			ractl->_workingset = true;
 			psi_memstall_enter(&ractl->_pflags);
@@ -846,7 +846,7 @@ void readahead_expand(struct readahead_control *ractl,
 			folio_put(folio);
 			return;
 		}
-		if (unlikely(folio_test_workingset(folio)) &&
+		if (unlikely(folio_is_workingset(folio)) &&
 				!ractl->_workingset) {
 			ractl->_workingset = true;
 			psi_memstall_enter(&ractl->_pflags);
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 9c8d9e3af375..913e69eae534 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -2268,7 +2268,7 @@ static void shrink_active_list(unsigned long nr_to_scan,
 		}
 
 		folio_clear_active(folio);	/* we are de-activating */
-		folio_set_workingset(folio);
+		folio_mark_workingset_by_bit(folio);
 		list_add(&folio->lru, &l_inactive);
 	}
 
diff --git a/mm/workingset.c b/mm/workingset.c
index 452fe8554990..568a3e44cd5e 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -438,7 +438,7 @@ void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
 	eviction >>= bucket_order[file];
 	workingset_age_nonresident(lruvec, folio_nr_pages(folio));
 	return pack_shadow(memcgid, pgdat, eviction,
-			   folio_test_workingset(folio), file);
+			   folio_is_workingset(folio), file);
 }
 
 /**
@@ -609,7 +609,7 @@ void workingset_refault(struct folio *folio, void *shadow)
 
 	/* Folio was active prior to eviction */
 	if (workingset) {
-		folio_set_workingset(folio);
+		folio_mark_workingset_by_bit(folio);
 		mod_lruvec_state(lruvec, WORKINGSET_RESTORE_BASE + file, nr);
 	}
 out:

-- 
2.55.0

