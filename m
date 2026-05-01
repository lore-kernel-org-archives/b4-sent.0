From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:08 +0800
Subject: [PATCH RFC 22/32] mm/workingset: simplify and use a more intuitive
 model
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-22-913619b014d9@tencent.com>
References: <20260502-mglru-fg-v1-0-913619b014d9@tencent.com>
In-Reply-To: <20260502-mglru-fg-v1-0-913619b014d9@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Youngjun Park <youngjun.park@lge.com>, 
 Zi Yan <ziy@nvidia.com>, Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Nico Pache <npache@redhat.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SeongJae Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, 
 Chen Ridong <chenridong@huaweicloud.com>, Tal Zussman <tz2294@columbia.edu>, 
 Kairui Song <ryncsn@gmail.com>, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=20953;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=1dTSECn4f3IJgXaVU1EBjh87x63FnKLXmOSYf0cJJvQ=;
 b=rv32xcR6Z5PlYssPrbZDyzFCu3sTTQOO6bRxH6wtLlCZqpLs8DRhxnGd2cUR/nRfzaUxgAgPQ
 0YzGKc+n1TzAnXOG3oTJn2GdOm5aLK2rymKj8EDupUCULkcF0SNz039
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove workingset activation hook, rework the refault distance comparison
accordingly. The non-resident age counter (NA) is now incremented only
on eviction.

This is also preparation for adapting refault-distance-based file page
protection to multi-gen LRU.

Refault-based re-activation on the active/inactive LRU helps identify
the working set. On refault, it estimates the page's access distance
and, if small enough, activates the page directly instead of letting
it re-age through the inactive list.

The existing estimation (see the original comment in mm/workingset.c)
is built on two assumptions:

1. Activating an inactive page left-shifts all LRU pages by one
   (treating the LRU head as the right).
2. Evicting an inactive page left-shifts all LRU pages by one.

Assumption 2 is exact. Assumption 1 is a bit subtle. The old model
counts events (activations and evictions), which is internally
consistent, but it means NA advances at the rate of the busiest
pages, not at the rate of actual eviction pressure. A workload with
an established active set whose pages cycle inactive -> active ->
inactive -> active produces many NA increments per eviction. This
is not an edge case: a folio activated even once contributes two
NA per eviction, which is the common case. Legitimate working-set
candidates then get aged out of the refault window faster than real
eviction pressure would justify.

MGLRU does not fit this model well either. Pages are aged in generations
and are promoted frequently between them, so tying NA to activations
is even less meaningful. Note this patch does not change the MGLRU path
yet, just a preparation.

New model
=========

Treat evicted pages as if they were still resident, each carrying an
eviction timestamp (NA at eviction time). These timestamps logically
form a read-only "Shadow LRU" extending to the left of the real LRU.
For a refaulting page, define:

  SP = NA@refault - NA@eviction

SP is the page's offset back in the shadow LRU: how far in eviction
history it sits. Since every evicted page was once at the head of the
INACTIVE list, its in-memory access distance would have needed to be
at least:

  SP + NR_INACTIVE

to avoid eviction. So an upper bound on when activating the page could
keep it resident is:

  SP + NR_INACTIVE <= NR_INACTIVE + NR_ACTIVE

which simplifies to:

  SP <= NR_ACTIVE

(NR_INACTIVE is read at refault time, not eviction time; the two can
differ but are assumed comparable for workloads stable enough that the
heuristic is meaningful at all.)

The derivation above is the upper bound on feasibility. The policy
applied here is stricter: compare SP against the average of NR_ACTIVE
and NR_INACTIVE rather than NR_ACTIVE alone:

  SP <= (NR_ACTIVE + NR_INACTIVE) / 2

The number 2 here is not a magic number. Two arguments motivate this
threshold. They stem from different reasoning but converge on the same
operating point.

1. Empirical self-balancing. Relative to the feasibility bound
   SP <= NR_ACTIVE:

   - When NR_ACTIVE is short, no working set has been established yet.
     Moving the threshold above NR_ACTIVE lets more refaulting pages
     activate, so a working set can form faster.
   - When NR_ACTIVE is long, a working set is already establishing.
     Moving the threshold below NR_ACTIVE keeps it stable, so
     one-time refaults do not easily displace established active
     pages.

   Because NR_ACTIVE + NR_INACTIVE is roughly M (total cache memory),
   the threshold is roughly M/2 regardless of how the A/I split
   moves. The policy self-stabilizes around half of memory.

   Also note for refauting, the re-activation is pure hypothesis based
   so the lowest bar 1:1 is used.

2. Bounded MRU-like protection against LRU thrashing. On a sequential
   cyclic scan over a set of size S on memory M, every refault in
   steady state has SP ~= S - M. With the threshold at M/2, activation
   happens exactly when S <= 1.5 * M.

   In that regime, the first refaults of the second pass land on the
   active list and stop being evicted. Roughly M/2 pages get frozen
   active; the remaining M/2 pages churn through the inactive list.
   Hit rate on the frozen half is near 100%, compared to pure LRU's
   classic ~0% on any cyclic scan with S > M. This is a large
   improvement in the "slightly too large to fit" regime, which is a
   common workload shape when memory is sized close to but under the
   working set (analytics passes, batch jobs, cold-start caches).

   Above 1.5 * M the heuristic disengages. Since we don't know if the
   work load is sequential or random with skew, partial protection of
   much-larger sets has diminishing returns, and indiscriminate activation
   of pages with very large SP would pollute the active list with pages
   unlikely to be re-accessed before eviction.

   For uniform random access with no structure, SP is widely spread
   around its mean of S - M; activation is essentially neutral
   because no page is more valuable than another. The policy neither
   helps nor hurts.

The two arguments are independent but give a similar conclusion, and easy
to calculation, which is a useful coincidence and gives some confidence
the constant is well-chosen.

A secondary effect: NA still over-counts pages that are refaulted
and then re-evicted, because such pages contribute to NA twice over
their lifetime. This inflates SP for older shadows under heavy
refault churn. The feasibility bound SP <= NR_ACTIVE would
over-activate in that regime; tightening to (A+I)/2 dampens this
without a separate correction.

Performance
===========

Removing the NA update from folio_mark_accessed() and from
move_folios_to_lru() avoids a memcg parent walk and an atomic add
on those hot paths, so the no-pressure case should cost slightly
less. Under pressure the behavior still seems good. Testing with several
benchmarks didn't show any regression, and the simplification of code
leads to a direct gain in many cases. Results can be seen in a previous
posted version of this patch [1].

Link: https://lwn.net/ml/linux-kernel/20230920190244.16839-2-ryncsn@gmail.com/ [1]
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/swap.h |   2 -
 mm/swap.c            |   1 -
 mm/vmscan.c          |   2 -
 mm/workingset.c      | 225 ++++++++++++++++++++++++---------------------------
 4 files changed, 107 insertions(+), 123 deletions(-)

diff --git a/include/linux/swap.h b/include/linux/swap.h
index 1930f81e6be4..04806dc8b2b1 100644
--- a/include/linux/swap.h
+++ b/include/linux/swap.h
@@ -297,10 +297,8 @@ static inline swp_entry_t page_swap_entry(struct page *page)
 /* linux/mm/workingset.c */
 bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 				bool flush);
-void workingset_age_nonresident(struct lruvec *lruvec, unsigned long nr_pages);
 void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg);
 void workingset_refault(struct folio *folio, void *shadow);
-void workingset_activation(struct folio *folio);
 
 /* linux/mm/page_alloc.c */
 extern unsigned long totalreserve_pages;
diff --git a/mm/swap.c b/mm/swap.c
index 043c4ec708d7..97c820b85db1 100644
--- a/mm/swap.c
+++ b/mm/swap.c
@@ -545,7 +545,6 @@ void folio_mark_accessed(struct folio *folio)
 		else
 			__lru_cache_activate_folio(folio);
 		folio_clear_referenced_by_bit(folio);
-		workingset_activation(folio);
 	}
 	if (folio_test_idle(folio))
 		folio_clear_idle(folio);
diff --git a/mm/vmscan.c b/mm/vmscan.c
index a3200020b9c2..e6631ad03caa 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -1923,8 +1923,6 @@ static unsigned int move_folios_to_lru(struct list_head *list)
 		lruvec_add_folio(lruvec, folio);
 		nr_pages = folio_nr_pages(folio);
 		nr_moved += nr_pages;
-		if (folio_test_active(folio))
-			workingset_age_nonresident(lruvec, nr_pages);
 	}
 
 	if (lruvec)
diff --git a/mm/workingset.c b/mm/workingset.c
index fa644948c80e..01f6e9a72cdb 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -66,74 +66,89 @@
  * thrashing on the inactive list, after which refaulting pages can be
  * activated optimistically to compete with the existing active pages.
  *
- * Approximating inactive page access frequency - Observations:
- *
- * 1. When a page is accessed for the first time, it is added to the
- *    head of the inactive list, slides every existing inactive page
- *    towards the tail by one slot, and pushes the current tail page
- *    out of memory.
- *
- * 2. When a page is accessed for the second time, it is promoted to
- *    the active list, shrinking the inactive list by one slot.  This
- *    also slides all inactive pages that were faulted into the cache
- *    more recently than the activated page towards the tail of the
- *    inactive list.
- *
- * Thus:
- *
- * 1. The sum of evictions and activations between any two points in
- *    time indicate the minimum number of inactive pages accessed in
- *    between.
- *
- * 2. Moving one inactive page N page slots towards the tail of the
- *    list requires at least N inactive page accesses.
- *
- * Combining these:
- *
- * 1. When a page is finally evicted from memory, the number of
- *    inactive pages accessed while the page was in cache is at least
- *    the number of page slots on the inactive list.
- *
- * 2. In addition, measuring the sum of evictions and activations (E)
- *    at the time of a page's eviction, and comparing it to another
- *    reading (R) at the time the page faults back into memory tells
- *    the minimum number of accesses while the page was not cached.
- *    This is called the refault distance.
- *
- * Because the first access of the page was the fault and the second
- * access the refault, we combine the in-cache distance with the
- * out-of-cache distance to get the complete minimum access distance
- * of this page:
- *
- *      NR_inactive + (R - E)
- *
- * And knowing the minimum access distance of a page, we can easily
- * tell if the page would be able to stay in cache assuming all page
- * slots in the cache were available:
- *
- *   NR_inactive + (R - E) <= NR_inactive + NR_active
- *
- * If we have swap we should consider about NR_inactive_anon and
- * NR_active_anon, so for page cache and anonymous respectively:
- *
- *   NR_inactive_file + (R - E) <= NR_inactive_file + NR_active_file
- *   + NR_inactive_anon + NR_active_anon
- *
- *   NR_inactive_anon + (R - E) <= NR_inactive_anon + NR_active_anon
- *   + NR_inactive_file + NR_active_file
- *
- * Which can be further simplified to:
- *
- *   (R - E) <= NR_active_file + NR_inactive_anon + NR_active_anon
- *
- *   (R - E) <= NR_active_anon + NR_inactive_file + NR_active_file
- *
- * Put into words, the refault distance (out-of-cache) can be seen as
- * a deficit in inactive list space (in-cache).  If the inactive list
- * had (R - E) more page slots, the page would not have been evicted
- * in between accesses, but activated instead.  And on a full system,
- * the only thing eating into inactive list space is active pages.
- *
+ * For such approximation, introduce a counter `nonresident_age` (NA)
+ * per lruvec. NA is incremented once for every evicted page, and each
+ * evicted page's shadow entry records the NA value at eviction time as
+ * a timestamp. So when an evicted page is faulted in again, we have:
+ *
+ *   Let SP = ((NA's reading @ current) - (NA's reading @ eviction))
+ *
+ *                            +-memory available to cache-+
+ *                            |                           |
+ *  +-------------------------+===============+===========+
+ *  |       shadows    *      |   INACTIVE    |   ACTIVE  |
+ *  +-+------------^----------+===============+===========+
+ *    |            |
+ *    +------------+
+ *    |     SP
+ *  oldest shadow       * -> The refaulting page's shadow in the
+ *                           imaginary "Shadow LRU"
+ *
+ * SP stands for how far back in eviction history the refaulting page
+ * is. Since every evicted page was once at the head of the INACTIVE
+ * list, the minimum in-memory access distance this page would have
+ * needed to avoid eviction is:
+ *
+ *   SP + NR_INACTIVE
+ *
+ * So the page is a plausible workingset candidate if:
+ *
+ *   SP + NR_INACTIVE <= NR_INACTIVE + NR_ACTIVE
+ *
+ * which simplifies to:
+ *
+ *   SP <= NR_ACTIVE
+ *
+ * Note NR_INACTIVE is read at refault time, not at eviction time; the
+ * two can differ, but the difference is assumed small for workloads
+ * stable enough that the refault-distance heuristic is meaningful at
+ * all.
+ *
+ * The derivation above gives the upper bound on when activation could
+ * keep the page resident. The actual policy used here is stricter:
+ * the refault distance is compared against the average of NR_ACTIVE
+ * and NR_INACTIVE rather than NR_ACTIVE alone:
+ *
+ *   SP <= (NR_ACTIVE + NR_INACTIVE) / 2
+ *
+ * Two arguments motivate this threshold and converge on the same
+ * operating point:
+ *
+ * 1. Self-balancing around the feasibility bound. Relative to
+ *    SP <= NR_ACTIVE:
+ *
+ *    - when NR_ACTIVE is short (no established workingset), the
+ *      threshold sits above NR_ACTIVE, allowing more activations so
+ *      a workingset can form faster;
+ *    - when NR_ACTIVE is long (established workingset), the threshold
+ *      sits below NR_ACTIVE, so one-time refaults do not easily
+ *      displace established active pages.
+ *
+ *    Because NR_ACTIVE + NR_INACTIVE is roughly M (total cache
+ *    memory), the threshold is roughly M/2 regardless of how the A/I
+ *    split moves.
+ *
+ * 2. Bounded MRU-like protection. For a sequential cyclic scan over
+ *    a set of size S on memory M, every refault has SP roughly equal
+ *    to S - M in steady state. With the threshold at M/2, activation
+ *    happens exactly when S <= 1.5 * M. In that regime the heuristic
+ *    freezes roughly M/2 pages onto the active list, yielding a large
+ *    hit-rate improvement over pure LRU (which has ~0% hits on any
+ *    cyclic scan with S > M). Above 1.5 * M the heuristic disengages:
+ *    partial protection has diminishing returns as S/M grows, and
+ *    indiscriminate activation would pollute the active list with
+ *    pages unlikely to be re-accessed before eviction. For random
+ *    access with skew, the SP-based threshold naturally selects
+ *    hotter pages (shorter inter-access times give smaller SP), so
+ *    the benefit extends across a broader range of S/M as a smooth
+ *    transition rather than a cliff.
+ *
+ * A secondary effect: NA over-counts pages that are refaulted and
+ * then re-evicted (they contribute to NA twice over their lifetime),
+ * which inflates SP for older shadows under heavy refault churn. The
+ * feasibility bound SP <= NR_ACTIVE would over-activate in that
+ * regime; tightening to (A+I)/2 dampens this without a separate
+ * correction.
  *
  *		Refaulting inactive pages
  *
@@ -142,19 +157,14 @@
  * time there is actually a good chance that pages on the active list
  * are no longer in active use.
  *
- * So when a refault distance of (R - E) is observed and there are at
- * least (R - E) pages in the userspace workingset, the refaulting page
- * is activated optimistically in the hope that (R - E) pages are actually
- * used less frequently than the refaulting page - or even not used at
- * all anymore.
- *
- * That means if inactive cache is refaulting with a suitable refault
- * distance, we assume the cache workingset is transitioning and put
- * pressure on the current workingset.
+ * So when a refault distance SP satisfies the rule above, the
+ * refaulting page is activated optimistically in the hope that roughly
+ * (NR_ACTIVE + NR_INACTIVE) / 2 pages on the active side are used less
+ * frequently than the refaulting page - or even not used at all anymore.
  *
  * If this is wrong and demotion kicks in, the pages which are truly
  * used more frequently will be reactivated while the less frequently
- * used once will be evicted from memory.
+ * used ones will be evicted from memory.
  *
  * But if this is right, the stale pages will be pushed out of memory
  * and the used pages get to stay in cache.
@@ -170,11 +180,11 @@
  *
  *		Implementation
  *
- * For each node's LRU lists, a counter for inactive evictions and
- * activations is maintained (node->nonresident_age).
+ * For each lruvec, a non-resident age counter (lruvec->nonresident_age)
+ * is maintained. It is incremented once per evicted page.
  *
  * On eviction, a snapshot of this counter (along with some bits to
- * identify the node) is stored in the now empty page cache
+ * identify the lruvec) is stored in the now empty page cache
  * slot of the evicted page.  This is called a shadow entry.
  *
  * On cache misses for which there are shadow entries, an eligible
@@ -366,7 +376,7 @@ static void lru_gen_refault(struct folio *folio, void *shadow)
  * to the in-memory dimensions. This function allows reclaim and LRU
  * operations to drive the non-resident aging along in parallel.
  */
-void workingset_age_nonresident(struct lruvec *lruvec, unsigned long nr_pages)
+static void workingset_age_nonresident(struct lruvec *lruvec, unsigned long nr_pages)
 {
 	/*
 	 * Reclaiming a cgroup means reclaiming all its children in a
@@ -433,14 +443,12 @@ void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
 bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 				bool flush)
 {
+	unsigned long refault, distance, active, inactive;
 	struct mem_cgroup *eviction_memcg;
 	struct lruvec *eviction_lruvec;
-	unsigned long refault_distance;
-	unsigned long workingset_size;
-	unsigned long refault;
-	int memcgid;
 	struct pglist_data *pgdat;
 	unsigned long eviction;
+	int memcgid;
 
 	if (lru_gen_enabled()) {
 		bool recent;
@@ -511,8 +519,8 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 	 * longest time, so the occasional inappropriate activation
 	 * leading to pressure on the active list is not a problem.
 	 */
-	refault_distance = ((refault - eviction) &
-			    (file ? EVICTION_MASK : EVICTION_MASK_ANON));
+	distance = ((refault - eviction) &
+		    (file ? EVICTION_MASK : EVICTION_MASK_ANON));
 
 	/*
 	 * Compare the distance to the existing workingset size. We
@@ -521,22 +529,21 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 	 * workingset competition needs to consider anon or not depends
 	 * on having free swap space.
 	 */
-	workingset_size = lruvec_page_state(eviction_lruvec, NR_ACTIVE_FILE);
-	if (!file) {
-		workingset_size += lruvec_page_state(eviction_lruvec,
-						     NR_INACTIVE_FILE);
-	}
+	active = lruvec_page_state(eviction_lruvec, NR_ACTIVE_FILE);
+	inactive = lruvec_page_state(eviction_lruvec, NR_INACTIVE_FILE);
+
 	if (mem_cgroup_get_nr_swap_pages(eviction_memcg) > 0) {
-		workingset_size += lruvec_page_state(eviction_lruvec,
-						     NR_ACTIVE_ANON);
-		if (file) {
-			workingset_size += lruvec_page_state(eviction_lruvec,
-						     NR_INACTIVE_ANON);
-		}
+		active += lruvec_page_state(eviction_lruvec, NR_ACTIVE_ANON);
+		inactive += lruvec_page_state(eviction_lruvec, NR_INACTIVE_ANON);
 	}
 
 	mem_cgroup_put(eviction_memcg);
-	return refault_distance <= workingset_size;
+
+	/*
+	 * Be cautious about challenging the existing active working set;
+	 * sacrificing the inactive part of the opposite type should be safe.
+	 */
+	return distance <= (active + inactive) / 2;
 }
 
 /**
@@ -581,7 +588,6 @@ void workingset_refault(struct folio *folio, void *shadow)
 		goto out;
 
 	folio_set_active(folio);
-	workingset_age_nonresident(lruvec, nr);
 	mod_lruvec_state(lruvec, WORKINGSET_ACTIVATE_BASE + file, nr);
 
 	/* Folio was active prior to eviction */
@@ -598,23 +604,6 @@ void workingset_refault(struct folio *folio, void *shadow)
 	mem_cgroup_put(memcg);
 }
 
-/**
- * workingset_activation - note a page activation
- * @folio: Folio that is being activated.
- */
-void workingset_activation(struct folio *folio)
-{
-	/*
-	 * Filter non-memcg pages here, e.g. unmap can call
-	 * mark_page_accessed() on VDSO pages.
-	 */
-	if (mem_cgroup_disabled() || folio_memcg_charged(folio)) {
-		rcu_read_lock();
-		workingset_age_nonresident(folio_lruvec(folio), folio_nr_pages(folio));
-		rcu_read_unlock();
-	}
-}
-
 /*
  * Shadow entries reflect the share of the working set that does not
  * fit into memory, so their number depends on the access pattern of

-- 
2.54.0

