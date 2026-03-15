From: Leno Hou <lenohou@gmail.com>
Date: Mon, 16 Mar 2026 02:18:29 +0800
Subject: [PATCH v3 2/2] mm/mglru: maintain workingset refault context
 across state transitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260316-b4-switch-mglru-v2-v3-2-c846ce9a2321@gmail.com>
References: <20260316-b4-switch-mglru-v2-v3-0-c846ce9a2321@gmail.com>
In-Reply-To: <20260316-b4-switch-mglru-v2-v3-0-c846ce9a2321@gmail.com>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Jialing Wang <wjl.linux@gmail.com>, 
 Yafang Shao <laoar.shao@gmail.com>, Yu Zhao <yuzhao@google.com>, 
 Kairui Song <ryncsn@gmail.com>, Bingfang Guo <bfguo@icloud.com>, 
 Barry Song <baohua@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Leno Hou <lenohou@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773598759; l=9959;
 i=lenohou@gmail.com; s=20260311; h=from:subject:message-id;
 bh=BzLymly7UqWV2k0JhEp7lvZpm6LCjjIAK/A6bt/7X98=;
 b=grGmb05RZk/p4O8A1anhDQfMEpjTfSb0d2+QR/k5NgLHzs5Ev198xlQlLCliJgPkPW8wfRcKq
 Az/W/3QAmaVCldO0npLWohcLNzylGLvSBOWmC8MsSvDJz6JQb4wZEzu
X-Developer-Key: i=lenohou@gmail.com; a=ed25519;
 pk=8AVHXYurzu1kOGjk9rwvxovwSCynBkv2QAcOvSIe1rw=
X-Endpoint-Received: by B4 Relay for lenohou@gmail.com/20260311 with auth_id=674
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When MGLRU state is toggled dynamically, existing shadow entries (eviction
tokens) lose their context. Traditional LRU and MGLRU handle workingset
refaults using different logic. Without context, shadow entries
re-activated by the "wrong" reclaim logic trigger excessive page
activations (pgactivate) and system thrashing, as the kernel cannot
correctly distinguish if a refaulted page was originally managed by
MGLRU or the traditional LRU.

This patch introduces shadow entry context tracking:

- Encode MGLRU origin: Introduce WORKINGSET_MGLRU_SHIFT into the shadow
  entry (eviction token) encoding. This adds an 'is_mglru' bit to shadow
  entries, allowing the kernel to correctly identify the originating
  reclaim logic for a page even after the global MGLRU state has been
  toggled.

- Refault logic dispatch: Use this 'is_mglru' bit in workingset_refault()
  and workingset_test_recent() to dispatch refault events to the correct
  handler (lru_gen_refault vs. traditional workingset refault).

This ensures that refaulted pages are handled by the appropriate reclaim
logic regardless of the current MGLRU enabled state, preventing
unnecessary thrashing and state-inconsistent refault activations during
state transitions.

To: Andrew Morton <akpm@linux-foundation.org>
To: Axel Rasmussen <axelrasmussen@google.com>
To: Yuanchu Xie <yuanchu@google.com>
To: Wei Xu <weixugc@google.com>
To: Barry Song <21cnbao@gmail.com>
To: Jialing Wang <wjl.linux@gmail.com>
To: Yafang Shao <laoar.shao@gmail.com>
To: Yu Zhao <yuzhao@google.com>
To: Kairui Song <ryncsn@gmail.com>
To: Bingfang Guo <bfguo@icloud.com>
Cc: linux-mm@kvack.org
Cc: linux-kernel@vger.kernel.org
Signed-off-by: Leno Hou <lenohou@gmail.com>
---
 include/linux/swap.h |  2 +-
 mm/vmscan.c          | 17 ++++++++++++-----
 mm/workingset.c      | 22 +++++++++++++++-------
 3 files changed, 28 insertions(+), 13 deletions(-)

diff --git a/include/linux/swap.h b/include/linux/swap.h
index 7a09df6977a5..5f7d3f08d840 100644
--- a/include/linux/swap.h
+++ b/include/linux/swap.h
@@ -297,7 +297,7 @@ static inline swp_entry_t page_swap_entry(struct page *page)
 bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 				bool flush);
 void workingset_age_nonresident(struct lruvec *lruvec, unsigned long nr_pages);
-void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg);
+void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg, bool lru_gen);
 void workingset_refault(struct folio *folio, void *shadow);
 void workingset_activation(struct folio *folio);
 
diff --git a/mm/vmscan.c b/mm/vmscan.c
index bcefd8db9c03..de21343b5cd2 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -180,6 +180,9 @@ struct scan_control {
 
 	/* for recording the reclaimed slab by now */
 	struct reclaim_state reclaim_state;
+
+	/* whether in lru gen scan context */
+	unsigned int lru_gen:1;
 };
 
 #ifdef ARCH_HAS_PREFETCHW
@@ -685,7 +688,7 @@ static pageout_t pageout(struct folio *folio, struct address_space *mapping,
  * gets returned with a refcount of 0.
  */
 static int __remove_mapping(struct address_space *mapping, struct folio *folio,
-			    bool reclaimed, struct mem_cgroup *target_memcg)
+	bool reclaimed, struct mem_cgroup *target_memcg, struct scan_control *sc)
 {
 	int refcount;
 	void *shadow = NULL;
@@ -739,7 +742,7 @@ static int __remove_mapping(struct address_space *mapping, struct folio *folio,
 		swp_entry_t swap = folio->swap;
 
 		if (reclaimed && !mapping_exiting(mapping))
-			shadow = workingset_eviction(folio, target_memcg);
+			shadow = workingset_eviction(folio, target_memcg, sc->lru_gen);
 		memcg1_swapout(folio, swap);
 		__swap_cache_del_folio(ci, folio, swap, shadow);
 		swap_cluster_unlock_irq(ci);
@@ -765,7 +768,7 @@ static int __remove_mapping(struct address_space *mapping, struct folio *folio,
 		 */
 		if (reclaimed && folio_is_file_lru(folio) &&
 		    !mapping_exiting(mapping) && !dax_mapping(mapping))
-			shadow = workingset_eviction(folio, target_memcg);
+			shadow = workingset_eviction(folio, target_memcg, sc->lru_gen);
 		__filemap_remove_folio(folio, shadow);
 		xa_unlock_irq(&mapping->i_pages);
 		if (mapping_shrinkable(mapping))
@@ -802,7 +805,7 @@ static int __remove_mapping(struct address_space *mapping, struct folio *folio,
  */
 long remove_mapping(struct address_space *mapping, struct folio *folio)
 {
-	if (__remove_mapping(mapping, folio, false, NULL)) {
+	if (__remove_mapping(mapping, folio, false, NULL, NULL)) {
 		/*
 		 * Unfreezing the refcount with 1 effectively
 		 * drops the pagecache ref for us without requiring another
@@ -1499,7 +1502,7 @@ static unsigned int shrink_folio_list(struct list_head *folio_list,
 			count_vm_events(PGLAZYFREED, nr_pages);
 			count_memcg_folio_events(folio, PGLAZYFREED, nr_pages);
 		} else if (!mapping || !__remove_mapping(mapping, folio, true,
-							 sc->target_mem_cgroup))
+							 sc->target_mem_cgroup, sc))
 			goto keep_locked;
 
 		folio_unlock(folio);
@@ -1599,6 +1602,7 @@ unsigned int reclaim_clean_pages_from_list(struct zone *zone,
 	struct scan_control sc = {
 		.gfp_mask = GFP_KERNEL,
 		.may_unmap = 1,
+		.lru_gen = lru_gen_enabled(),
 	};
 	struct reclaim_stat stat;
 	unsigned int nr_reclaimed;
@@ -1993,6 +1997,7 @@ static unsigned long shrink_inactive_list(unsigned long nr_to_scan,
 	if (nr_taken == 0)
 		return 0;
 
+	sc->lru_gen = 0;
 	nr_reclaimed = shrink_folio_list(&folio_list, pgdat, sc, &stat, false,
 					 lruvec_memcg(lruvec));
 
@@ -2167,6 +2172,7 @@ static unsigned int reclaim_folio_list(struct list_head *folio_list,
 		.may_unmap = 1,
 		.may_swap = 1,
 		.no_demotion = 1,
+		.lru_gen = lru_gen_enabled(),
 	};
 
 	nr_reclaimed = shrink_folio_list(folio_list, pgdat, &sc, &stat, true, NULL);
@@ -4864,6 +4870,7 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 	if (list_empty(&list))
 		return scanned;
 retry:
+	sc->lru_gen = 1;
 	reclaimed = shrink_folio_list(&list, pgdat, sc, &stat, false, memcg);
 	sc->nr.unqueued_dirty += stat.nr_unqueued_dirty;
 	sc->nr_reclaimed += reclaimed;
diff --git a/mm/workingset.c b/mm/workingset.c
index 07e6836d0502..3764a4a68c2c 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -181,8 +181,10 @@
  * refault distance will immediately activate the refaulting page.
  */
 
+#define WORKINGSET_MGLRU_SHIFT  1
 #define WORKINGSET_SHIFT 1
 #define EVICTION_SHIFT	((BITS_PER_LONG - BITS_PER_XA_VALUE) +	\
+			 WORKINGSET_MGLRU_SHIFT + \
 			 WORKINGSET_SHIFT + NODES_SHIFT + \
 			 MEM_CGROUP_ID_SHIFT)
 #define EVICTION_SHIFT_ANON	(EVICTION_SHIFT + SWAP_COUNT_SHIFT)
@@ -200,12 +202,13 @@
 static unsigned int bucket_order[ANON_AND_FILE] __read_mostly;
 
 static void *pack_shadow(int memcgid, pg_data_t *pgdat, unsigned long eviction,
-			 bool workingset, bool file)
+			 bool workingset, bool file, bool is_mglru)
 {
 	eviction &= file ? EVICTION_MASK : EVICTION_MASK_ANON;
 	eviction = (eviction << MEM_CGROUP_ID_SHIFT) | memcgid;
 	eviction = (eviction << NODES_SHIFT) | pgdat->node_id;
 	eviction = (eviction << WORKINGSET_SHIFT) | workingset;
+	eviction = (eviction << WORKINGSET_MGLRU_SHIFT) | is_mglru;
 
 	return xa_mk_value(eviction);
 }
@@ -217,6 +220,7 @@ static void unpack_shadow(void *shadow, int *memcgidp, pg_data_t **pgdat,
 	int memcgid, nid;
 	bool workingset;
 
+	entry >>= WORKINGSET_MGLRU_SHIFT;
 	workingset = entry & ((1UL << WORKINGSET_SHIFT) - 1);
 	entry >>= WORKINGSET_SHIFT;
 	nid = entry & ((1UL << NODES_SHIFT) - 1);
@@ -263,7 +267,7 @@ static void *lru_gen_eviction(struct folio *folio)
 	memcg_id = mem_cgroup_private_id(memcg);
 	rcu_read_unlock();
 
-	return pack_shadow(memcg_id, pgdat, token, workingset, type);
+	return pack_shadow(memcg_id, pgdat, token, workingset, type, true);
 }
 
 /*
@@ -387,7 +391,8 @@ void workingset_age_nonresident(struct lruvec *lruvec, unsigned long nr_pages)
  * Return: a shadow entry to be stored in @folio->mapping->i_pages in place
  * of the evicted @folio so that a later refault can be detected.
  */
-void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
+void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg,
+							 bool lru_gen)
 {
 	struct pglist_data *pgdat = folio_pgdat(folio);
 	int file = folio_is_file_lru(folio);
@@ -400,7 +405,7 @@ void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
 	VM_BUG_ON_FOLIO(folio_ref_count(folio), folio);
 	VM_BUG_ON_FOLIO(!folio_test_locked(folio), folio);
 
-	if (lru_gen_enabled())
+	if (lru_gen)
 		return lru_gen_eviction(folio);
 
 	lruvec = mem_cgroup_lruvec(target_memcg, pgdat);
@@ -410,7 +415,7 @@ void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
 	eviction >>= bucket_order[file];
 	workingset_age_nonresident(lruvec, folio_nr_pages(folio));
 	return pack_shadow(memcgid, pgdat, eviction,
-			   folio_test_workingset(folio), file);
+			   folio_test_workingset(folio), file, false);
 }
 
 /**
@@ -436,8 +441,10 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 	int memcgid;
 	struct pglist_data *pgdat;
 	unsigned long eviction;
+	unsigned long entry = xa_to_value(shadow);
+	bool is_mglru = !!(entry & WORKINGSET_MGLRU_SHIFT);
 
-	if (lru_gen_enabled()) {
+	if (is_mglru) {
 		bool recent;
 
 		rcu_read_lock();
@@ -550,10 +557,11 @@ void workingset_refault(struct folio *folio, void *shadow)
 	struct lruvec *lruvec;
 	bool workingset;
 	long nr;
+	unsigned long entry = xa_to_value(shadow);
 
 	VM_BUG_ON_FOLIO(!folio_test_locked(folio), folio);
 
-	if (lru_gen_enabled()) {
+	if (entry & ((1UL << WORKINGSET_MGLRU_SHIFT) - 1)) {
 		lru_gen_refault(folio, shadow);
 		return;
 	}

-- 
2.52.0

