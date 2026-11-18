From: Kairui Song <kasong@tencent.com>
Date: Thu, 19 Nov 2026 05:03:36 +0800
Subject: [PATCH v5 04/17] mm/memcg: add folio-based lruvec live helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-mglru-fg-v5-4-9eee2fe97a2d@tencent.com>
References: <20261119-mglru-fg-v5-0-9eee2fe97a2d@tencent.com>
In-Reply-To: <20261119-mglru-fg-v5-0-9eee2fe97a2d@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <qi.zheng@linux.dev>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Chris Li <chrisl@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Nhat Pham <nphamcs@gmail.com>, Youngjun Park <youngjun.park@lge.com>, 
 Zi Yan <ziy@nvidia.com>, Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SJ Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Chen Ridong <chenridong@xiaomi.com>, 
 Tal Zussman <tz2294@columbia.edu>, Kairui Song <ryncsn@gmail.com>, 
 Xiang Liu <liuxiang.277@bytedance.com>, 
 Ehab Ababneh <ehab.ababneh@intel.com>, 
 Zhao Zhenzhuo <zhaozhengzhuo@uniontech.com>, 
 Lian Wang <lianux.mm@gmail.com>, Joanne Koong <joannelkoong@gmail.com>, 
 Kunwu Chan <kunwu.chan@gmail.com>, Hui Zhu <hui.zhu@linux.dev>, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 damon@lists.linux.dev, linux-doc@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795035819; l=5345;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=UPy3pGE6319hHgjCcjHs3BYbIQXEmhnHCnBETYV6U1U=;
 b=AqfXtl+0yCpQiqyIhsARAmmg2Fsm9mLz1qO5V+JmtA+2ZDtZgTGXqyJCmNSR+dvfy8goUaZ48
 3vrkNo74McRCI5QhGsRrjoUyRufQBCMaywpKJnzlOrA+BydE3iJC3FC
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a helper that resolves a live lruvec for a folio under RCU
without taking the lruvec lock.  It takes a folio directly so the
lruvec lookup happens inside the RCU read-side critical section,
which a lruvec-based interface cannot guarantee.  The first user is
the lockless folio_inc_lru_refs() path later in the series.

Factor the ancestor walk out of lruvec_live_lock_irq() into
__lruvec_get_live(), so that both entry points share it, and spell
out why the walk is enough while only the RCU read lock is held:
reparenting of a memcg that starts dying waits for a grace period,
so it cannot race with the caller until the lock is released.

Move memcg_is_dying() up in memcontrol.h, next to the other memcg state
predicates, and use it for the walk rather than repeating the open coded
css_is_dying() test a few definitions away from where it is explained.

No functional change for existing callers.

Tested-by: Zhao Zhenzhuo <zhaozhengzhuo@uniontech.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/memcontrol.h | 71 ++++++++++++++++++++++++++++++++++++----------
 1 file changed, 56 insertions(+), 15 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index 980358bc6f49..441a5d57e723 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -571,6 +571,11 @@ static inline bool mem_cgroup_disabled(void)
 	return !cgroup_subsys_enabled(memory_cgrp_subsys);
 }
 
+static inline bool memcg_is_dying(struct mem_cgroup *memcg)
+{
+	return memcg ? css_is_dying(&memcg->css) : false;
+}
+
 static inline void mem_cgroup_protection(const struct mem_cgroup *root,
 					 const struct mem_cgroup *memcg,
 					 unsigned long *min,
@@ -1349,6 +1354,11 @@ static inline bool mem_cgroup_online(struct mem_cgroup *memcg)
 	return true;
 }
 
+static inline bool memcg_is_dying(struct mem_cgroup *memcg)
+{
+	return false;
+}
+
 static inline
 unsigned long mem_cgroup_get_zone_lru_size(const struct lruvec *lruvec,
 		enum lru_list lru, int zone_idx)
@@ -1510,28 +1520,41 @@ static inline void lruvec_lock_irq(struct lruvec *lruvec)
 	spin_lock_irq(&lruvec->lru_lock);
 }
 
-static inline struct lruvec *lruvec_live_lock_irq(struct lruvec *lruvec)
+/*
+ * Reparenting moves a dying memcg's LRU state to its parent at any time,
+ * so anything added to that LRU afterwards would be lost.  This helper
+ * walks up to the nearest live ancestor while the caller must hold the
+ * RCU read lock: reparenting of a memcg that starts dying waits for a
+ * grace period, so it cannot race with the caller until the lock is
+ * released.
+ */
+static inline struct lruvec *__lruvec_get_live(struct lruvec *lruvec)
 {
 #ifdef CONFIG_MEMCG
 	struct pglist_data *pgdat = lruvec_pgdat(lruvec);
 	struct mem_cgroup *memcg = lruvec_memcg(lruvec);
 
-	rcu_read_lock();
-
 	/*
 	 * The memcg can be NULL when the memory controller is disabled.
 	 * Otherwise, the caller keeps the memcg owning @lruvec alive.
 	 */
-	while (unlikely(memcg && css_is_dying(&memcg->css))) {
+	while (unlikely(memcg_is_dying(memcg))) {
 		memcg = parent_mem_cgroup(memcg);
 		lruvec = mem_cgroup_lruvec(memcg, pgdat);
 	}
+#endif
+	return lruvec;
+}
 
+static inline struct lruvec *lruvec_live_lock_irq(struct lruvec *lruvec)
+{
+#ifdef CONFIG_MEMCG
+	rcu_read_lock();
+	lruvec = __lruvec_get_live(lruvec);
 	spin_lock_irq(&lruvec->lru_lock);
 #else
 	lruvec_lock_irq(lruvec);
 #endif
-
 	return lruvec;
 }
 
@@ -1561,6 +1584,34 @@ static inline bool folio_matches_lruvec(const struct folio *folio,
 	       lruvec_memcg(lruvec) == folio_memcg(folio);
 }
 
+/**
+ * folio_lruvec_live_get - get a live lruvec for a folio under RCU
+ * @folio: the folio
+ *
+ * Same as folio_lruvec(), except that a folio whose memcg is dying is
+ * accounted to the nearest live ancestor, which is where reparenting
+ * would put it anyway.
+ *
+ * Return: the live lruvec, with rcu_read_lock() held.  Pair it with
+ * folio_lruvec_live_put().
+ */
+static inline struct lruvec *folio_lruvec_live_get(struct folio *folio)
+{
+#ifdef CONFIG_MEMCG
+	rcu_read_lock();
+	return __lruvec_get_live(folio_lruvec(folio));
+#else
+	return folio_lruvec(folio);
+#endif
+}
+
+static inline void folio_lruvec_live_put(struct lruvec *lruvec)
+{
+#ifdef CONFIG_MEMCG
+	rcu_read_unlock();
+#endif
+}
+
 /* Don't lock again iff page's lruvec locked */
 static inline struct lruvec *folio_lruvec_relock_irq(const struct folio *folio,
 		struct lruvec *locked_lruvec)
@@ -1826,11 +1877,6 @@ void mem_cgroup_node_filter_allowed(struct mem_cgroup *memcg, nodemask_t *mask);
 
 void mem_cgroup_show_protected_memory(struct mem_cgroup *memcg);
 
-static inline bool memcg_is_dying(struct mem_cgroup *memcg)
-{
-	return memcg ? css_is_dying(&memcg->css) : false;
-}
-
 #else
 static inline bool mem_cgroup_kmem_disabled(void)
 {
@@ -1901,11 +1947,6 @@ static inline void mem_cgroup_node_filter_allowed(struct mem_cgroup *memcg,
 static inline void mem_cgroup_show_protected_memory(struct mem_cgroup *memcg)
 {
 }
-
-static inline bool memcg_is_dying(struct mem_cgroup *memcg)
-{
-	return false;
-}
 #endif /* CONFIG_MEMCG */
 
 #if defined(CONFIG_MEMCG) && defined(CONFIG_LRU_GEN)

-- 
2.56.1

