From: Jingxiang Zeng <linuszeng@tencent.com>
Date: Fri, 18 Sep 2026 16:53:41 +0800
Subject: [PATCH 1/6] mm: page_counter: add page_counter_protection struct
 and init API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-descriptive-name-v1-1-dfcfdd91b456@tencent.com>
References: <20260918-descriptive-name-v1-0-dfcfdd91b456@tencent.com>
In-Reply-To: <20260918-descriptive-name-v1-0-dfcfdd91b456@tencent.com>
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
 Oscar Salvador <osalvador@suse.de>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: Jingxiang Zeng <jingxiangzeng.cas@gmail.com>, cgroups@vger.kernel.org, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-doc@vger.kernel.org, 
 Jingxiang Zeng <linuszeng@tencent.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721651; l=10506;
 i=linuszeng@tencent.com; s=20260909; h=from:subject:message-id;
 bh=XbEGRKxxHK1Nrej2GHdMz4TmIbAR4XKSXg/71ifM2nY=;
 b=eXC22pAC/5CqXJJBYbY6x3pyJLlR37S08bG7Uza31/gbk0+xAbjfenzgW5Db3JdnXD7fDNQE/
 pwrNFCppoGjBfsJI3HuKBNVQEJpdQj4W3RDIpVbknjGs00cWt713CVZ
X-Developer-Key: i=linuszeng@tencent.com; a=ed25519;
 pk=6K54xRzYIRWqatrAPy86M4E0MsI92BVJBhXwz5NdC74=
X-Endpoint-Received: by B4 Relay for linuszeng@tencent.com/20260909 with auth_id=1017
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hierarchical protection (memory.min/memory.low) is only used by the
memory page counter and by dmem pools; swap/memsw, kmem, tcpmem and
hugetlb counters never participate in it, yet every struct page_counter
carries the full protection state.

Add struct page_counter_protection to hold that state and link it to
struct page_counter through a ->prot pointer, NULL when protection is
not supported.  page_counter_init() loses its protection_support
argument and the new page_counter_init_protection() attaches the
context; track_protection() tests ->prot instead of the flag.
Protection stays enabled only on the cgroup v2 hierarchy, matching the
previous page_counter_init(..., memcg_on_dfl) behaviour, and the root
memcg keeps it unconditionally.

Order the new structure by access frequency: parent, min, low and the
four usage counters are what propagate_protected_usage() touches on
every charge and uncharge, once per level, so they come first and share
a cache line - both embedders place the structure at a cache line
boundary, at offset 384 in struct mem_cgroup and 192 in the dmem pool
state.  emin and elow are only recomputed during reclaim and read by
the protection checks, so they go last.

struct page_counter still carries the old protection fields at this
point, so nothing shrinks yet: they are migrated onto the new structure
in the next commit and removed in the one after that.

The dmem pool allocator points its counter at the embedded protection
context, and the pool fix-up path in get_cg_pool_locked() links
prot->parent the same way it links cnt.parent, so pools created
bottom-up do not lose hierarchical protection.

No functional change.

Signed-off-by: Jingxiang Zeng <linuszeng@tencent.com>
---
 include/linux/memcontrol.h   |  7 +++++
 include/linux/page_counter.h | 72 ++++++++++++++++++++++++++++++++++++++++----
 kernel/cgroup/dmem.c         |  9 ++++--
 mm/hugetlb_cgroup.c          |  4 +--
 mm/memcontrol.c              | 21 ++++++++-----
 mm/page_counter.c            |  2 +-
 6 files changed, 95 insertions(+), 20 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index 46bf724cae7a..5936f497aea6 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -199,6 +199,13 @@ struct mem_cgroup {
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
index 07b7cb12249c..5020e62aacb4 100644
--- a/include/linux/page_counter.h
+++ b/include/linux/page_counter.h
@@ -7,6 +7,45 @@
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
+	/*
+	 * Fields up to and including children_low_usage are read and
+	 * updated by propagate_protected_usage() on every charge and
+	 * uncharge, once per level of the hierarchy.  Keep them together
+	 * so that they share a cache line: both embedders (struct
+	 * mem_cgroup and the dmem pool state) place this structure at a
+	 * cache line boundary.
+	 */
+	struct page_counter_protection *parent;
+
+	unsigned long min;
+	unsigned long low;
+
+	/* memory.min and memory.low usage tracking */
+	atomic_long_t min_usage;
+	atomic_long_t low_usage;
+	atomic_long_t children_min_usage;
+	atomic_long_t children_low_usage;
+
+	/*
+	 * Effective values, recomputed by
+	 * page_counter_calculate_protection() during reclaim and read by
+	 * the mem_cgroup and dmem protection checks.  Not touched by the
+	 * charge path.
+	 */
+	unsigned long emin;
+	unsigned long elow;
+};
+
 struct page_counter {
 	/*
 	 * Make sure 'usage' does not share cacheline with any other field in
@@ -41,6 +80,12 @@ struct page_counter {
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
@@ -49,18 +94,33 @@ struct page_counter {
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
index 791e536efaeb..94c538ea3cb5 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -4296,25 +4296,30 @@ mem_cgroup_css_alloc(struct cgroup_subsys_state *parent_css)
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
index 98322803941a..aa1f9a9a314f 100644
--- a/mm/page_counter.c
+++ b/mm/page_counter.c
@@ -16,7 +16,7 @@
 
 static bool track_protection(struct page_counter *c)
 {
-	return c->protection_support;
+	return c->prot != NULL;
 }
 
 static void propagate_protected_usage(struct page_counter *c,

-- 
2.43.7

