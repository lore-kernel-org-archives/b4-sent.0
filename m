From: linuszeng <linuszeng@tencent.com>
Date: Wed, 09 Sep 2026 17:44:19 +0800
Subject: [PATCH v2 1/3] mm: page_counter: add page_counter_protection
 struct and init API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-descriptive-name-v2-1-d7dd7c099049@tencent.com>
References: <20260909-descriptive-name-v2-0-d7dd7c099049@tencent.com>
In-Reply-To: <20260909-descriptive-name-v2-0-d7dd7c099049@tencent.com>
To: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Maarten Lankhorst <dev@lankhorst.se>, Maxime Ripard <mripard@kernel.org>, 
 Natalie Vock <nat@pixelcluster.dev>, Tejun Heo <tj@kernel.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Oscar Salvador <osalvador@suse.de>, 
 Jingxiang Zeng <jingxiangzeng.cas@gmail.com>
Cc: Michal Hocko <mhocko@suse.com>, cgroups@vger.kernel.org, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linuszeng <linuszeng@tencent.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788947061; l=8820;
 i=linuszeng@tencent.com; s=20260909; h=from:subject:message-id;
 bh=qRo7579G0THOdatUrKxYMO5fc5xqKHZM+hDjreNI4ZA=;
 b=sm9aZHKSL3UgtbwsCx3EepH0eABzrIRsPuV/OQa6YtjA4YYenyUMrOOwjC/BuCeTXIw+F2a4w
 E94ynhOvlhRA+SfoBNns+mQRxSsyDGgong2OQVembX7Fcbr5Hz7AA6T
X-Developer-Key: i=linuszeng@tencent.com; a=ed25519;
 pk=6K54xRzYIRWqatrAPy86M4E0MsI92BVJBhXwz5NdC74=
X-Endpoint-Received: by B4 Relay for linuszeng@tencent.com/20260909 with auth_id=1017
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit extracts the hierarchical protection state (memory.min and
memory.low) from struct page_counter into a new page_counter_protection
structure.  It introduces page_counter_init_protection() to attach this
context, saving space for counters that don't support protection.

The dmem pool allocator now points its counter at the embedded
protection context, and the pool fix-up path in get_cg_pool_locked()
links the new prot->parent the same way it links cnt.parent, so pools
created bottom-up do not lose hierarchical protection.

No functional change.
---
 include/linux/memcontrol.h   |  7 ++++++
 include/linux/page_counter.h | 59 +++++++++++++++++++++++++++++++++++++++-----
 kernel/cgroup/dmem.c         |  9 ++++---
 mm/hugetlb_cgroup.c          |  4 +--
 mm/memcontrol.c              | 21 ++++++++++------
 mm/page_counter.c            |  2 +-
 6 files changed, 82 insertions(+), 20 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index 058ebd73ff16..ed863f4ed233 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -195,6 +195,13 @@ struct mem_cgroup {
 	/* Accounted resources */
 	struct page_counter memory;		/* Both v1 & v2 */
 
+	/*
+	 * Hierarchical memory.min/memory.low protection tracking for the
+	 * memory page counter. swap/memsw, kmem and tcpmem counters do not
+	 * support protection and have no such context.
+	 */
+	struct page_counter_protection memory_prot;
+
 	union {
 		struct page_counter swap;	/* v2 only */
 		struct page_counter memsw;	/* v1 only */
diff --git a/include/linux/page_counter.h b/include/linux/page_counter.h
index 07b7cb12249c..b81f16702764 100644
--- a/include/linux/page_counter.h
+++ b/include/linux/page_counter.h
@@ -7,6 +7,32 @@
 #include <linux/limits.h>
 #include <asm/page.h>
 
+/*
+ * Hierarchical protection (memory.min / memory.low) tracking.
+ *
+ * Only the memory page counter (and dmem pools) participate in protection.
+ * swap/memsw, kmem and tcpmem page counters never do, so the protection
+ * fields are kept out of struct page_counter in this separate structure to
+ * save space in the common case. struct page_counter links to it via ->prot,
+ * which is NULL for counters without protection support.
+ */
+struct page_counter_protection {
+	struct page_counter_protection *parent;
+
+	/* effective memory.min and memory.min usage tracking */
+	unsigned long emin;
+	atomic_long_t min_usage;
+	atomic_long_t children_min_usage;
+
+	/* effective memory.low and memory.low usage tracking */
+	unsigned long elow;
+	atomic_long_t low_usage;
+	atomic_long_t children_low_usage;
+
+	unsigned long min;
+	unsigned long low;
+};
+
 struct page_counter {
 	/*
 	 * Make sure 'usage' does not share cacheline with any other field in
@@ -41,6 +67,12 @@ struct page_counter {
 	unsigned long high;
 	unsigned long max;
 	struct page_counter *parent;
+
+	/*
+	 * Hierarchical protection context, NULL for counters that do not
+	 * support memory.min/memory.low (swap, memsw, kmem, tcpmem, ...).
+	 */
+	struct page_counter_protection *prot;
 } ____cacheline_internodealigned_in_smp;
 
 #if BITS_PER_LONG == 32
@@ -49,18 +81,33 @@ struct page_counter {
 #define PAGE_COUNTER_MAX (LONG_MAX / PAGE_SIZE)
 #endif
 
-/*
- * Protection is supported only for the first counter (with id 0).
- */
 static inline void page_counter_init(struct page_counter *counter,
-				     struct page_counter *parent,
-				     bool protection_support)
+				     struct page_counter *parent)
 {
 	counter->usage = (atomic_long_t)ATOMIC_LONG_INIT(0);
 	counter->max = PAGE_COUNTER_MAX;
 	counter->parent = parent;
-	counter->protection_support = protection_support;
 	counter->track_failcnt = false;
+	counter->prot = NULL;
+}
+
+/*
+ * Enable hierarchical protection (memory.min/memory.low) on @counter.
+ * @prot and @parent are the protection contexts of @counter and its
+ * parent page counter respectively. Only the memory page counter (and
+ * dmem pools) call this.
+ *
+ * The remaining members of @prot (emin, elow and the usage counters) are
+ * expected to be zero already, so @prot must come from zeroed memory.
+ */
+static inline void page_counter_init_protection(struct page_counter *counter,
+						struct page_counter_protection *prot,
+						struct page_counter_protection *parent)
+{
+	counter->prot = prot;
+	prot->parent = parent;
+	prot->min = 0;
+	prot->low = 0;
 }
 
 static inline unsigned long page_counter_read(struct page_counter *counter)
diff --git a/kernel/cgroup/dmem.c b/kernel/cgroup/dmem.c
index 4683f3d68022..a4bac0d5ac3b 100644
--- a/kernel/cgroup/dmem.c
+++ b/kernel/cgroup/dmem.c
@@ -88,6 +88,7 @@ struct dmem_cgroup_pool_state {
 	struct rcu_head rcu;
 
 	struct page_counter cnt;
+	struct page_counter_protection prot;
 	struct dmem_cgroup_pool_state *parent;
 
 	refcount_t ref;
@@ -426,8 +427,9 @@ alloc_pool_single(struct dmemcg_state *dmemcs, struct dmem_cgroup_region *region
 	if (parent)
 		ppool = find_cg_pool_locked(parent, region);
 
-	page_counter_init(&pool->cnt,
-			  ppool ? &ppool->cnt : NULL, true);
+	page_counter_init(&pool->cnt, ppool ? &ppool->cnt : NULL);
+	page_counter_init_protection(&pool->cnt, &pool->prot,
+				     ppool ? &ppool->prot : NULL);
 	reset_all_resource_limits(pool);
 	refcount_set(&pool->ref, 1);
 	kref_get(&region->ref);
@@ -480,8 +482,9 @@ get_cg_pool_locked(struct dmemcg_state *dmemcs, struct dmem_cgroup_region *regio
 		/* ppool was created if it didn't exist by above loop. */
 		ppool = find_cg_pool_locked(pp, region);
 
-		/* Fix up parent links, mark as inited. */
+		/* Fix up parent links (counter and protection), mark as inited. */
 		pool->cnt.parent = &ppool->cnt;
+		pool->prot.parent = &ppool->prot;
 		if (ppool && !pool->parent) {
 			pool->parent = ppool;
 			dmemcg_pool_get(ppool);
diff --git a/mm/hugetlb_cgroup.c b/mm/hugetlb_cgroup.c
index ecb6e0b7819a..7fdae504cfc6 100644
--- a/mm/hugetlb_cgroup.c
+++ b/mm/hugetlb_cgroup.c
@@ -108,8 +108,8 @@ static void hugetlb_cgroup_init(struct hugetlb_cgroup *h_cgroup,
 		fault = hugetlb_cgroup_counter_from_cgroup(h_cgroup, idx);
 		rsvd = hugetlb_cgroup_counter_from_cgroup_rsvd(h_cgroup, idx);
 
-		page_counter_init(fault, fault_parent, false);
-		page_counter_init(rsvd, rsvd_parent, false);
+		page_counter_init(fault, fault_parent);
+		page_counter_init(rsvd, rsvd_parent);
 
 		if (!cgroup_subsys_on_dfl(hugetlb_cgrp_subsys)) {
 			fault->track_failcnt = true;
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 86ff580c7018..ffa1ced3baae 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -4267,25 +4267,30 @@ mem_cgroup_css_alloc(struct cgroup_subsys_state *parent_css)
 #endif
 	page_counter_set_high(&memcg->swap, PAGE_COUNTER_MAX);
 	if (parent) {
-		page_counter_init(&memcg->memory, &parent->memory, memcg_on_dfl);
-		page_counter_init(&memcg->swap, &parent->swap, false);
+		page_counter_init(&memcg->memory, &parent->memory);
+		if (memcg_on_dfl)
+			page_counter_init_protection(&memcg->memory, &memcg->memory_prot,
+						     &parent->memory_prot);
+		page_counter_init(&memcg->swap, &parent->swap);
 #ifdef CONFIG_MEMCG_V1
 		WRITE_ONCE(memcg->swappiness, mem_cgroup_swappiness(parent));
 		memcg->memory.track_failcnt = !memcg_on_dfl;
 		memcg->memsw.track_failcnt = !memcg_on_dfl;
 		WRITE_ONCE(memcg->oom_kill_disable, READ_ONCE(parent->oom_kill_disable));
-		page_counter_init(&memcg->kmem, &parent->kmem, false);
-		page_counter_init(&memcg->tcpmem, &parent->tcpmem, false);
+		page_counter_init(&memcg->kmem, &parent->kmem);
+		page_counter_init(&memcg->tcpmem, &parent->tcpmem);
 		memcg->tcpmem.track_failcnt = !memcg_on_dfl;
 #endif
 	} else {
 		init_memcg_stats();
 		init_memcg_events();
-		page_counter_init(&memcg->memory, NULL, true);
-		page_counter_init(&memcg->swap, NULL, false);
+		page_counter_init(&memcg->memory, NULL);
+		page_counter_init_protection(&memcg->memory, &memcg->memory_prot,
+					     NULL);
+		page_counter_init(&memcg->swap, NULL);
 #ifdef CONFIG_MEMCG_V1
-		page_counter_init(&memcg->kmem, NULL, false);
-		page_counter_init(&memcg->tcpmem, NULL, false);
+		page_counter_init(&memcg->kmem, NULL);
+		page_counter_init(&memcg->tcpmem, NULL);
 #endif
 		root_mem_cgroup = memcg;
 		return &memcg->css;
diff --git a/mm/page_counter.c b/mm/page_counter.c
index 450543f4b318..38cb99f5f50e 100644
--- a/mm/page_counter.c
+++ b/mm/page_counter.c
@@ -15,7 +15,7 @@
 
 static bool track_protection(struct page_counter *c)
 {
-	return c->protection_support;
+	return c->prot != NULL;
 }
 
 static void propagate_protected_usage(struct page_counter *c,

-- 
2.43.7

