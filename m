From: Leno Hou <lenohou@gmail.com>
Date: Mon, 16 Mar 2026 02:18:28 +0800
Subject: [PATCH v3 1/2] mm/mglru: fix cgroup OOM during MGLRU state
 switching
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260316-b4-switch-mglru-v2-v3-1-c846ce9a2321@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773598759; l=11348;
 i=lenohou@gmail.com; s=20260311; h=from:subject:message-id;
 bh=kyuspqsl57CQHhG9arU0ApaAlBWfHd4kjkO+N+OYlnQ=;
 b=lJZQoqkROXtQJhx/pEQq7aliD0NS8u0fPJ1wpQyQwBo9/YPQsBfBhdCAFEeVPzqdPIsBP/NDB
 5JrJ1B8hIlTAtZBmWasqTgSBzV0uMKjPPFp7/YxZuRrvgduiYgtTHf7
X-Developer-Key: i=lenohou@gmail.com; a=ed25519;
 pk=8AVHXYurzu1kOGjk9rwvxovwSCynBkv2QAcOvSIe1rw=
X-Endpoint-Received: by B4 Relay for lenohou@gmail.com/20260311 with auth_id=674
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the Multi-Gen LRU (MGLRU) state is toggled dynamically, a race
condition exists between the state switching and the memory reclaim path.
This can lead to unexpected cgroup OOM kills, even when plenty of
reclaimable memory is available.

Problem Description
==================

The issue arises from a "reclaim vacuum" during the transition.

1. When disabling MGLRU, lru_gen_change_state() sets lrugen->enabled to
   false before the pages are drained from MGLRU lists back to traditional
   LRU lists.
2. Concurrent reclaimers in shrink_lruvec() see lrugen->enabled as false
   and skip the MGLRU path.
3. However, these pages might not have reached the traditional LRU lists
   yet, or the changes are not yet visible to all CPUs due to a lack
   of synchronization.
4. get_scan_count() subsequently finds traditional LRU lists empty,
   concludes there is no reclaimable memory, and triggers an OOM kill.

A similar race can occur during enablement, where the reclaimer sees the
new state but the MGLRU lists haven't been populated via fill_evictable()
yet.

Solution
========

Introduce a 'draining' state (`lru_drain_core`) to bridge the transition.
When transitioning, the system enters this intermediate state where
the reclaimer is forced to attempt both MGLRU and traditional reclaim
paths sequentially. This ensures that folios remain visible to at least
one reclaim mechanism until the transition is fully materialized across
all CPUs.

Changes
=======

v3:
 - Rebase onto mm-new branch for queue testing
 - Don't look around while draining
 - Fix Barry Song's comment

v2:
- Repalce with a static branch `lru_drain_core` to track the transition
  state.
- Ensures all LRU helpers correctly identify page state by checking
  folio_lru_gen(folio) != -1 instead of relying solely on global flags.
- Maintain workingset refault context across MGLRU state transitions
- Fix build error when CONFIG_LRU_GEN is disabled.

v1:
- Use smp_store_release() and smp_load_acquire() to ensure the visibility
  of 'enabled' and 'draining' flags across CPUs.
- Modify shrink_lruvec() to allow a "joint reclaim" period. If an lruvec
  is in the 'draining' state, the reclaimer will attempt to scan MGLRU
  lists first, and then fall through to traditional LRU lists instead
  of returning early. This ensures that folios are visible to at least
  one reclaim path at any given time.

Race & Mitigation
================

A race window exists between checking the 'draining' state and performing
the actual list operations. For instance, a reclaimer might observe the
draining state as false just before it changes, leading to a suboptimal
reclaim path decision.

However, this impact is effectively mitigated by the kernel's reclaim
retry mechanism (e.g., in do_try_to_free_pages). If a reclaimer pass fails
to find eligible folios due to a state transition race, subsequent retries
in the loop will observe the updated state and correctly direct the scan
to the appropriate LRU lists. This ensures the transient inconsistency
does not escalate into a terminal OOM kill.

This effectively reduce the race window that previously triggered OOMs
under high memory pressure.

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
 include/linux/mm_inline.h | 16 ++++++++++++++++
 mm/rmap.c                 |  2 +-
 mm/swap.c                 | 15 +++++++++------
 mm/vmscan.c               | 38 +++++++++++++++++++++++++++++---------
 4 files changed, 55 insertions(+), 16 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index ad50688d89db..16ac700dac9c 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -102,6 +102,12 @@ static __always_inline enum lru_list folio_lru_list(const struct folio *folio)
 
 #ifdef CONFIG_LRU_GEN
 
+static inline bool lru_gen_draining(void)
+{
+	DECLARE_STATIC_KEY_FALSE(lru_drain_core);
+
+	return static_branch_unlikely(&lru_drain_core);
+}
 #ifdef CONFIG_LRU_GEN_ENABLED
 static inline bool lru_gen_enabled(void)
 {
@@ -316,11 +322,21 @@ static inline bool lru_gen_enabled(void)
 	return false;
 }
 
+static inline bool lru_gen_draining(void)
+{
+	return false;
+}
+
 static inline bool lru_gen_in_fault(void)
 {
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
index 6398d7eef393..0b5f663f3062 100644
--- a/mm/rmap.c
+++ b/mm/rmap.c
@@ -966,7 +966,7 @@ static bool folio_referenced_one(struct folio *folio,
 			nr = folio_pte_batch(folio, pvmw.pte, pteval, max_nr);
 		}
 
-		if (lru_gen_enabled() && pvmw.pte) {
+		if (lru_gen_enabled() && !lru_gen_draining() && pvmw.pte) {
 			if (lru_gen_look_around(&pvmw, nr))
 				referenced++;
 		} else if (pvmw.pte) {
diff --git a/mm/swap.c b/mm/swap.c
index 5cc44f0de987..ecb192c02d2e 100644
--- a/mm/swap.c
+++ b/mm/swap.c
@@ -462,7 +462,7 @@ void folio_mark_accessed(struct folio *folio)
 {
 	if (folio_test_dropbehind(folio))
 		return;
-	if (lru_gen_enabled()) {
+	if (folio_lru_gen(folio) != -1) {
 		lru_gen_inc_refs(folio);
 		return;
 	}
@@ -559,7 +559,7 @@ void folio_add_lru_vma(struct folio *folio, struct vm_area_struct *vma)
  */
 static void lru_deactivate_file(struct lruvec *lruvec, struct folio *folio)
 {
-	bool active = folio_test_active(folio) || lru_gen_enabled();
+	bool active = folio_test_active(folio) || (folio_lru_gen(folio) != -1);
 	long nr_pages = folio_nr_pages(folio);
 
 	if (folio_test_unevictable(folio))
@@ -602,7 +602,9 @@ static void lru_deactivate(struct lruvec *lruvec, struct folio *folio)
 {
 	long nr_pages = folio_nr_pages(folio);
 
-	if (folio_test_unevictable(folio) || !(folio_test_active(folio) || lru_gen_enabled()))
+	if (folio_test_unevictable(folio) ||
+		!(folio_test_active(folio) ||
+		(folio_lru_gen(folio) != -1)))
 		return;
 
 	lruvec_del_folio(lruvec, folio);
@@ -617,6 +619,7 @@ static void lru_deactivate(struct lruvec *lruvec, struct folio *folio)
 static void lru_lazyfree(struct lruvec *lruvec, struct folio *folio)
 {
 	long nr_pages = folio_nr_pages(folio);
+	int gen = folio_lru_gen(folio);
 
 	if (!folio_test_anon(folio) || !folio_test_swapbacked(folio) ||
 	    folio_test_swapcache(folio) || folio_test_unevictable(folio))
@@ -624,7 +627,7 @@ static void lru_lazyfree(struct lruvec *lruvec, struct folio *folio)
 
 	lruvec_del_folio(lruvec, folio);
 	folio_clear_active(folio);
-	if (lru_gen_enabled())
+	if (gen != -1)
 		lru_gen_clear_refs(folio);
 	else
 		folio_clear_referenced(folio);
@@ -695,7 +698,7 @@ void deactivate_file_folio(struct folio *folio)
 	if (folio_test_unevictable(folio) || !folio_test_lru(folio))
 		return;
 
-	if (lru_gen_enabled() && lru_gen_clear_refs(folio))
+	if ((folio_lru_gen(folio) != -1) && lru_gen_clear_refs(folio))
 		return;
 
 	folio_batch_add_and_move(folio, lru_deactivate_file);
@@ -714,7 +717,7 @@ void folio_deactivate(struct folio *folio)
 	if (folio_test_unevictable(folio) || !folio_test_lru(folio))
 		return;
 
-	if (lru_gen_enabled() ? lru_gen_clear_refs(folio) : !folio_test_active(folio))
+	if ((folio_lru_gen(folio) != -1) ? lru_gen_clear_refs(folio) : !folio_test_active(folio))
 		return;
 
 	folio_batch_add_and_move(folio, lru_deactivate);
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 33287ba4a500..bcefd8db9c03 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -886,7 +886,7 @@ static enum folio_references folio_check_references(struct folio *folio,
 	if (referenced_ptes == -1)
 		return FOLIOREF_KEEP;
 
-	if (lru_gen_enabled()) {
+	if (lru_gen_enabled() && !lru_gen_draining()) {
 		if (!referenced_ptes)
 			return FOLIOREF_RECLAIM;
 
@@ -2286,7 +2286,7 @@ static void prepare_scan_control(pg_data_t *pgdat, struct scan_control *sc)
 	unsigned long file;
 	struct lruvec *target_lruvec;
 
-	if (lru_gen_enabled())
+	if (lru_gen_enabled() && !lru_gen_draining())
 		return;
 
 	target_lruvec = mem_cgroup_lruvec(sc->target_mem_cgroup, pgdat);
@@ -2625,6 +2625,7 @@ static bool can_age_anon_pages(struct lruvec *lruvec,
 
 #ifdef CONFIG_LRU_GEN
 
+DEFINE_STATIC_KEY_FALSE(lru_drain_core);
 #ifdef CONFIG_LRU_GEN_ENABLED
 DEFINE_STATIC_KEY_ARRAY_TRUE(lru_gen_caps, NR_LRU_GEN_CAPS);
 #define get_cap(cap)	static_branch_likely(&lru_gen_caps[cap])
@@ -5318,6 +5319,8 @@ static void lru_gen_change_state(bool enabled)
 	if (enabled == lru_gen_enabled())
 		goto unlock;
 
+	static_branch_enable_cpuslocked(&lru_drain_core);
+
 	if (enabled)
 		static_branch_enable_cpuslocked(&lru_gen_caps[LRU_GEN_CORE]);
 	else
@@ -5348,6 +5351,9 @@ static void lru_gen_change_state(bool enabled)
 
 		cond_resched();
 	} while ((memcg = mem_cgroup_iter(NULL, memcg, NULL)));
+
+	static_branch_disable_cpuslocked(&lru_drain_core);
+
 unlock:
 	mutex_unlock(&state_mutex);
 	put_online_mems();
@@ -5920,9 +5926,12 @@ static void shrink_lruvec(struct lruvec *lruvec, struct scan_control *sc)
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
@@ -6181,11 +6190,17 @@ static void shrink_node(pg_data_t *pgdat, struct scan_control *sc)
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
@@ -6455,7 +6470,7 @@ static void snapshot_refaults(struct mem_cgroup *target_memcg, pg_data_t *pgdat)
 	struct lruvec *target_lruvec;
 	unsigned long refaults;
 
-	if (lru_gen_enabled())
+	if (lru_gen_enabled() && !lru_gen_draining())
 		return;
 
 	target_lruvec = mem_cgroup_lruvec(target_memcg, pgdat);
@@ -6844,10 +6859,15 @@ static void kswapd_age_node(struct pglist_data *pgdat, struct scan_control *sc)
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

