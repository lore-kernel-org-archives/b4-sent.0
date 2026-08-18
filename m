From: Kairui Song <kasong@tencent.com>
Date: Tue, 18 Aug 2026 13:38:08 +0800
Subject: [PATCH 6/7] mm/mglru: fix potential generation folio number leak
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-mglru-flags-cleanup-v1-6-8dbbdac0d28c@tencent.com>
References: <20260818-mglru-flags-cleanup-v1-0-8dbbdac0d28c@tencent.com>
In-Reply-To: <20260818-mglru-flags-cleanup-v1-0-8dbbdac0d28c@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Baoquan He <baoquan.he@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Muchun Song <muchun.song@linux.dev>, Chris Li <chrisl@kernel.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Yu Zhao <yuzhao@google.com>, Zi Yan <ziy@nvidia.com>, 
 Qi Zheng <qi.zheng@linux.dev>, cgroups@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kairui Song <ryncsn@gmail.com>, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787031500; l=4447;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=RQ+/yXu5Ad8B7H0/N8WrVK9khx+u3YPD4VofNalxc64=;
 b=cfXZesEt3HAFlRTwsJTeSktOmQNsfJsb5vwfLGKcBYj5CBIRCSV1MsCNF4o1W99XR2XRVNn9C
 Ys4Vr2qcYhqDmbxB9rHcNo3vZlGDHEOJ4R6A9Gbmih2jVq/1NJ5Cd5y
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each generation of MGLRU accounts anon and file folio numbers
separately. The page table walker's update_batch_size() derives the
anon / file type of a folio from its current flags, but the page table
walk holds neither the lruvec lock nor the folio lock, so the type can
change during that period.

MADV_FREE's lazyfree path clears PG_swapbacked under the lruvec lock,
so the folio is no longer considered on the anon LRU list. Lazyfreed
folios can also be changed back to the anon list again. If the flip
lands between folio_update_gen()'s cmpxchg and the type read in
update_batch_size(), the batched delta pair is applied to the wrong
type. The anon and file generation counters then carry phantom deltas
that nothing reconciles, permanently skewing lrugen->nr_pages and the
reclaim budgets derived from it.

Fix it by capturing the type from the flags snapshot the cmpxchg
linearized against: folio_update_gen() returns the type of the state
it transitioned from, and update_batch_size() accounts with it instead
of re-reading the live flags. The batched deltas then always match the
type of the state the cmpxchg transitioned from.

Fixes: 018ee47f1489 ("mm: multi-gen LRU: exploit locality in rmap")
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm_inline.h |  7 ++++++-
 mm/vmscan.c               | 13 +++++++------
 2 files changed, 13 insertions(+), 7 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index df62daaa2ee7..4bb390d9516e 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -10,6 +10,11 @@
 #include <linux/userfaultfd_k.h>
 #include <linux/leafops.h>
 
+static inline int folio_flags_is_file_lru(const unsigned long *flags)
+{
+	return !test_bit(PG_swapbacked, flags);
+}
+
 /**
  * folio_is_file_lru - Should the folio be on a file LRU or anon LRU?
  * @folio: The folio to test.
@@ -27,7 +32,7 @@
  */
 static inline int folio_is_file_lru(const struct folio *folio)
 {
-	return !folio_test_swapbacked(folio);
+	return folio_flags_is_file_lru(const_folio_flags(folio, 0));
 }
 
 static __always_inline void __update_lru_size(struct lruvec *lruvec,
diff --git a/mm/vmscan.c b/mm/vmscan.c
index a613bb8d7271..7169cac60869 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -3269,7 +3269,8 @@ static bool positive_ctrl_err(struct ctrl_pos *sp, struct ctrl_pos *pv)
  ******************************************************************************/
 
 /* promote pages accessed through page tables */
-static int folio_update_gen(struct folio *folio, int new_gen, const vma_flags_t *vma_flags)
+static int folio_update_gen(struct folio *folio, int new_gen, int *is_file,
+			    const vma_flags_t *vma_flags)
 {
 	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
 	int old_gen;
@@ -3298,6 +3299,7 @@ static int folio_update_gen(struct folio *folio, int new_gen, const vma_flags_t
 		new_flags |= BIT(PG_workingset);
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
+	*is_file = folio_flags_is_file_lru(&old_flags);
 	return old_gen;
 }
 
@@ -3328,9 +3330,8 @@ static int folio_inc_gen(struct lruvec *lruvec, struct folio *folio)
 }
 
 static void update_batch_size(struct lru_gen_mm_walk *walk, struct folio *folio,
-			      int old_gen, int new_gen)
+			      int old_gen, int new_gen, int type)
 {
-	int type = folio_is_file_lru(folio);
 	int zone = folio_zonenum(folio);
 	int delta = folio_nr_pages(folio);
 
@@ -3519,7 +3520,7 @@ static bool suitable_to_scan(int total, int young)
 static void walk_update_folio(struct lru_gen_mm_walk *walk, struct vm_area_struct *vma,
 			      struct lruvec *lruvec, struct folio *folio, bool dirty)
 {
-	int new_gen, old_gen;
+	int new_gen, old_gen, file;
 
 	if (!folio)
 		return;
@@ -3532,9 +3533,9 @@ static void walk_update_folio(struct lru_gen_mm_walk *walk, struct vm_area_struc
 		folio_mark_dirty(folio);
 
 	if (walk) {
-		old_gen = folio_update_gen(folio, new_gen, &vma->flags);
+		old_gen = folio_update_gen(folio, new_gen, &file, &vma->flags);
 		if (old_gen >= 0 && old_gen != new_gen)
-			update_batch_size(walk, folio, old_gen, new_gen);
+			update_batch_size(walk, folio, old_gen, new_gen, file);
 	} else if (lru_gen_set_refs(folio, &vma->flags)) {
 		old_gen = folio_lru_gen(folio);
 		if (old_gen >= 0 && old_gen != new_gen)

-- 
2.55.0

