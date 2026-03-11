From: Leno Hou <lenohou@gmail.com>
Date: Wed, 11 Mar 2026 20:09:42 +0800
Subject: [PATCH v2 1/2] mm/mglru: fix cgroup OOM during MGLRU state
 switching
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-b4-switch-mglru-v2-v2-1-080cb9321463@gmail.com>
References: <20260311-b4-switch-mglru-v2-v2-0-080cb9321463@gmail.com>
In-Reply-To: <20260311-b4-switch-mglru-v2-v2-0-080cb9321463@gmail.com>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Jialing Wang <wjl.linux@gmail.com>, 
 Yafang Shao <laoar.shao@gmail.com>, Yu Zhao <yuzhao@google.com>, 
 Kairui Song <ryncsn@gmail.com>, Bingfang Guo <bfguo@icloud.com>, 
 Barry Song <baohua@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Leno Hou <lenohou@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773230982; l=9504;
 i=lenohou@gmail.com; s=20260311; h=from:subject:message-id;
 bh=tFWHXkGhpgsi30y22v+vy7TlYveQq5dfwpqWnM8x6p4=;
 b=Rgna2s5Of0mtAYeppCOfpRVCYSTggsfNLOAXPDZBgmHH5PiJH3V8UnWaEwe5CKCAfj3rzSTs4
 EJfPo9cDfmIBUxe4S8jTETCrtXs1iUMzqFPFBc4DlQpBzKol71Q3XLB
X-Developer-Key: i=lenohou@gmail.com; a=ed25519;
 pk=8AVHXYurzu1kOGjk9rwvxovwSCynBkv2QAcOvSIe1rw=
X-Endpoint-Received: by B4 Relay for lenohou@gmail.com/20260311 with auth_id=674
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the Multi-Gen LRU (MGLRU) state is toggled dynamically, a race
condition exists between the state switching and the memory reclaim
path. This can lead to unexpected cgroup OOM kills, even when plenty of
reclaimable memory is available.

Problem Description
==================

The issue arises from a "reclaim vacuum" during the transition.

1. When disabling MGLRU, lru_gen_change_state() sets lrugen->enabled to
   false before the pages are drained from MGLRU lists back to
   traditional LRU lists.
2. Concurrent reclaimers in shrink_lruvec() see lrugen->enabled as false
   and skip the MGLRU path.
3. However, these pages might not have reached the traditional LRU lists
   yet, or the changes are not yet visible to all CPUs due to a lack of
   synchronization.
4. get_scan_count() subsequently finds traditional LRU lists empty,
   concludes there is no reclaimable memory, and triggers an OOM kill.

A similar race can occur during enablement, where the reclaimer sees
the new state but the MGLRU lists haven't been populated via
fill_evictable() yet.


Solution
=======

Introduce a 'draining' state (`lru_drain_core`) to bridge the
transition. When transitioning, the system enters this intermediate state
where the reclaimer is forced to attempt both MGLRU and traditional reclaim
paths sequentially. This ensures that folios remain visible to at least
one reclaim mechanism until the transition is fully materialized across all
CPUs.

Changes
=======

- Adds a static branch `lru_drain_core` to track the transition state.
- Updates shrink_lruvec(), shrink_node(), and kswapd_age_node() to allow
  a "joint reclaim" period during the transition.
- Ensures all LRU helpers correctly identify page state by checking
  folio_lru_gen(folio) != -1 instead of relying solely on global flags.

This effectively eliminates the race window that previously triggered OOMs
under high memory pressure.

The issue was consistently reproduced on v6.1.157 and v6.18.3 using
a high-pressure memory cgroup (v1) environment.

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
 include/linux/mm_inline.h |  5 +++++
 mm/rmap.c                 |  2 +-
 mm/swap.c                 | 14 ++++++++------
 mm/vmscan.c               | 49 ++++++++++++++++++++++++++++++++++++++---------
 4 files changed, 54 insertions(+), 16 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index fa2d6ba811b5..e6443e22bf67 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -321,6 +321,11 @@ static inline bool lru_gen_in_fault(void)
 	return false;
 }
 
+static inline int folio_lru_gen(const struct folio *folio)
+{
+	return -1;
+}
+
 static inline bool lru_gen_add_folio(struct lruvec *lruvec, struct folio *folio, bool reclaiming)
 {
 	return false;
diff --git a/mm/rmap.c b/mm/rmap.c
index 0f00570d1b9e..488bcdca65ed 100644
--- a/mm/rmap.c
+++ b/mm/rmap.c
@@ -958,7 +958,7 @@ static bool folio_referenced_one(struct folio *folio,
 			return false;
 		}
 
-		if (lru_gen_enabled() && pvmw.pte) {
+		if ((folio_lru_gen(folio) != -1) && pvmw.pte) {
 			if (lru_gen_look_around(&pvmw))
 				referenced++;
 		} else if (pvmw.pte) {
diff --git a/mm/swap.c b/mm/swap.c
index bb19ccbece46..a2397b44710a 100644
--- a/mm/swap.c
+++ b/mm/swap.c
@@ -456,7 +456,7 @@ void folio_mark_accessed(struct folio *folio)
 {
 	if (folio_test_dropbehind(folio))
 		return;
-	if (lru_gen_enabled()) {
+	if (folio_lru_gen(folio) != -1) {
 		lru_gen_inc_refs(folio);
 		return;
 	}
@@ -553,7 +553,7 @@ void folio_add_lru_vma(struct folio *folio, struct vm_area_struct *vma)
  */
 static void lru_deactivate_file(struct lruvec *lruvec, struct folio *folio)
 {
-	bool active = folio_test_active(folio) || lru_gen_enabled();
+	bool active = folio_test_active(folio) || (folio_lru_gen(folio) != -1);
 	long nr_pages = folio_nr_pages(folio);
 
 	if (folio_test_unevictable(folio))
@@ -596,7 +596,9 @@ static void lru_deactivate(struct lruvec *lruvec, struct folio *folio)
 {
 	long nr_pages = folio_nr_pages(folio);
 
-	if (folio_test_unevictable(folio) || !(folio_test_active(folio) || lru_gen_enabled()))
+	if (folio_test_unevictable(folio) ||
+		!(folio_test_active(folio) ||
+		(folio_lru_gen(folio) != -1)))
 		return;
 
 	lruvec_del_folio(lruvec, folio);
@@ -618,7 +620,7 @@ static void lru_lazyfree(struct lruvec *lruvec, struct folio *folio)
 
 	lruvec_del_folio(lruvec, folio);
 	folio_clear_active(folio);
-	if (lru_gen_enabled())
+	if (folio_lru_gen(folio) != -1)
 		lru_gen_clear_refs(folio);
 	else
 		folio_clear_referenced(folio);
@@ -689,7 +691,7 @@ void deactivate_file_folio(struct folio *folio)
 	if (folio_test_unevictable(folio) || !folio_test_lru(folio))
 		return;
 
-	if (lru_gen_enabled() && lru_gen_clear_refs(folio))
+	if ((folio_lru_gen(folio) != -1) && lru_gen_clear_refs(folio))
 		return;
 
 	folio_batch_add_and_move(folio, lru_deactivate_file);
@@ -708,7 +710,7 @@ void folio_deactivate(struct folio *folio)
 	if (folio_test_unevictable(folio) || !folio_test_lru(folio))
 		return;
 
-	if (lru_gen_enabled() ? lru_gen_clear_refs(folio) : !folio_test_active(folio))
+	if ((folio_lru_gen(folio) != -1) ? lru_gen_clear_refs(folio) : !folio_test_active(folio))
 		return;
 
 	folio_batch_add_and_move(folio, lru_deactivate);
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 0fc9373e8251..38d38edda471 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -873,11 +873,23 @@ static bool lru_gen_set_refs(struct folio *folio)
 	set_mask_bits(&folio->flags.f, LRU_REFS_FLAGS, BIT(PG_workingset));
 	return true;
 }
+
+DEFINE_STATIC_KEY_FALSE(lru_drain_core);
+static inline bool lru_gen_draining(void)
+{
+	return static_branch_unlikely(&lru_drain_core);
+}
+
 #else
 static bool lru_gen_set_refs(struct folio *folio)
 {
 	return false;
 }
+static inline bool lru_gen_draining(void)
+{
+	return false;
+}
+
 #endif /* CONFIG_LRU_GEN */
 
 static enum folio_references folio_check_references(struct folio *folio,
@@ -905,7 +917,7 @@ static enum folio_references folio_check_references(struct folio *folio,
 	if (referenced_ptes == -1)
 		return FOLIOREF_KEEP;
 
-	if (lru_gen_enabled()) {
+	if (folio_lru_gen(folio) != -1) {
 		if (!referenced_ptes)
 			return FOLIOREF_RECLAIM;
 
@@ -2319,7 +2331,7 @@ static void prepare_scan_control(pg_data_t *pgdat, struct scan_control *sc)
 	unsigned long file;
 	struct lruvec *target_lruvec;
 
-	if (lru_gen_enabled())
+	if (lru_gen_enabled() && !lru_gen_draining())
 		return;
 
 	target_lruvec = mem_cgroup_lruvec(sc->target_mem_cgroup, pgdat);
@@ -5178,6 +5190,8 @@ static void lru_gen_change_state(bool enabled)
 	if (enabled == lru_gen_enabled())
 		goto unlock;
 
+	static_branch_enable_cpuslocked(&lru_drain_core);
+
 	if (enabled)
 		static_branch_enable_cpuslocked(&lru_gen_caps[LRU_GEN_CORE]);
 	else
@@ -5208,6 +5222,9 @@ static void lru_gen_change_state(bool enabled)
 
 		cond_resched();
 	} while ((memcg = mem_cgroup_iter(NULL, memcg, NULL)));
+
+	static_branch_disable_cpuslocked(&lru_drain_core);
+
 unlock:
 	mutex_unlock(&state_mutex);
 	put_online_mems();
@@ -5780,9 +5797,12 @@ static void shrink_lruvec(struct lruvec *lruvec, struct scan_control *sc)
 	bool proportional_reclaim;
 	struct blk_plug plug;
 
-	if (lru_gen_enabled() && !root_reclaim(sc)) {
+	if ((lru_gen_enabled() || lru_gen_draining()) && !root_reclaim(sc)) {
 		lru_gen_shrink_lruvec(lruvec, sc);
-		return;
+
+		if (!lru_gen_draining())
+			return;
+
 	}
 
 	get_scan_count(lruvec, sc, nr);
@@ -6041,11 +6061,17 @@ static void shrink_node(pg_data_t *pgdat, struct scan_control *sc)
 	unsigned long nr_reclaimed, nr_scanned, nr_node_reclaimed;
 	struct lruvec *target_lruvec;
 	bool reclaimable = false;
+	s8 priority = sc->priority;
 
-	if (lru_gen_enabled() && root_reclaim(sc)) {
+	if ((lru_gen_enabled() || lru_gen_draining()) && root_reclaim(sc)) {
 		memset(&sc->nr, 0, sizeof(sc->nr));
 		lru_gen_shrink_node(pgdat, sc);
-		return;
+
+		if (!lru_gen_draining())
+			return;
+
+		sc->priority = priority;
+
 	}
 
 	target_lruvec = mem_cgroup_lruvec(sc->target_mem_cgroup, pgdat);
@@ -6315,7 +6341,7 @@ static void snapshot_refaults(struct mem_cgroup *target_memcg, pg_data_t *pgdat)
 	struct lruvec *target_lruvec;
 	unsigned long refaults;
 
-	if (lru_gen_enabled())
+	if (lru_gen_enabled() && !lru_gen_draining())
 		return;
 
 	target_lruvec = mem_cgroup_lruvec(target_memcg, pgdat);
@@ -6703,10 +6729,15 @@ static void kswapd_age_node(struct pglist_data *pgdat, struct scan_control *sc)
 {
 	struct mem_cgroup *memcg;
 	struct lruvec *lruvec;
+	s8 priority = sc->priority;
 
-	if (lru_gen_enabled()) {
+	if (lru_gen_enabled() || lru_gen_draining()) {
 		lru_gen_age_node(pgdat, sc);
-		return;
+
+		if (!lru_gen_draining())
+			return;
+
+		sc->priority = priority;
 	}
 
 	lruvec = mem_cgroup_lruvec(NULL, pgdat);

-- 
2.52.0

