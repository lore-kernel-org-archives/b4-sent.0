From: linuszeng <linuszeng@tencent.com>
Date: Wed, 09 Sep 2026 16:08:52 +0800
Subject: [PATCH 2/3] mm: page_counter: track protection state in
 page_counter_protection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-descriptive-name-v1-2-1828961cb01a@tencent.com>
References: <20260909-descriptive-name-v1-0-1828961cb01a@tencent.com>
In-Reply-To: <20260909-descriptive-name-v1-0-1828961cb01a@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788941332; l=9367;
 i=linuszeng@tencent.com; s=20260909; h=from:subject:message-id;
 bh=L8zRdv2XrrdgHYes+wWpC8EXvoideRhwYKHMhN5k1CM=;
 b=vgz6ipuXcOYU83yuK+PjTHSRO4u+SoyZAHEJ2Us+vTnvgE2KnBL+c7ZqAR6G+65GXta3Do+iu
 ngfFYEjMMCMApkQofBmPUxZgLO5jf8bivQFd6/u1jTegbkZVWNWnFFk
X-Developer-Key: i=linuszeng@tencent.com; a=ed25519;
 pk=6K54xRzYIRWqatrAPy86M4E0MsI92BVJBhXwz5NdC74=
X-Endpoint-Received: by B4 Relay for linuszeng@tencent.com/20260909 with auth_id=1017
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the read/write side of hierarchical protection from struct
page_counter to struct page_counter_protection: propagate_protected_usage()
updates the protection context of the parent, page_counter_set_min()/low()
and page_counter_calculate_protection() operate on it, and memcg and dmem
accessors (including dmem_cgroup_below_min()/below_low()) read
min/low/emin/elow and children_*_usage from it.

struct page_counter keeps its now-unused protection fields for now; they
are removed in a follow-up commit.

No functional change.
---
 include/linux/memcontrol.h |  8 +++----
 kernel/cgroup/dmem.c       | 12 +++++-----
 mm/memcontrol.c            |  8 +++----
 mm/page_counter.c          | 59 +++++++++++++++++++++++++++++-----------------
 4 files changed, 52 insertions(+), 35 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index ed863f4ed233..44065001a66a 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -591,8 +591,8 @@ static inline void mem_cgroup_protection(struct mem_cgroup *root,
 	if (root == memcg)
 		return;
 
-	*min = READ_ONCE(memcg->memory.emin);
-	*low = READ_ONCE(memcg->memory.elow);
+	*min = READ_ONCE(memcg->memory_prot.emin);
+	*low = READ_ONCE(memcg->memory_prot.elow);
 }
 
 void mem_cgroup_calculate_protection(struct mem_cgroup *root,
@@ -616,7 +616,7 @@ static inline bool mem_cgroup_below_low(struct mem_cgroup *target,
 	if (mem_cgroup_unprotected(target, memcg))
 		return false;
 
-	return READ_ONCE(memcg->memory.elow) >=
+	return READ_ONCE(memcg->memory_prot.elow) >=
 		page_counter_read(&memcg->memory);
 }
 
@@ -626,7 +626,7 @@ static inline bool mem_cgroup_below_min(struct mem_cgroup *target,
 	if (mem_cgroup_unprotected(target, memcg))
 		return false;
 
-	return READ_ONCE(memcg->memory.emin) >=
+	return READ_ONCE(memcg->memory_prot.emin) >=
 		page_counter_read(&memcg->memory);
 }
 
diff --git a/kernel/cgroup/dmem.c b/kernel/cgroup/dmem.c
index e33d807cdea8..10321f1f0330 100644
--- a/kernel/cgroup/dmem.c
+++ b/kernel/cgroup/dmem.c
@@ -212,12 +212,12 @@ set_resource_max(struct dmem_cgroup_pool_state *pool, u64 val, bool nonblock)
 
 static u64 get_resource_low(struct dmem_cgroup_pool_state *pool)
 {
-	return pool ? READ_ONCE(pool->cnt.low) : 0;
+	return pool ? READ_ONCE(pool->cnt.prot->low) : 0;
 }
 
 static u64 get_resource_min(struct dmem_cgroup_pool_state *pool)
 {
-	return pool ? READ_ONCE(pool->cnt.min) : 0;
+	return pool ? READ_ONCE(pool->cnt.prot->min) : 0;
 }
 
 static u64 get_resource_max(struct dmem_cgroup_pool_state *pool)
@@ -388,13 +388,13 @@ bool dmem_cgroup_state_evict_valuable(struct dmem_cgroup_pool_state *limit_pool,
 	dmem_cgroup_calculate_protection(limit_pool, test_pool);
 
 	used = page_counter_read(ctest);
-	min = READ_ONCE(ctest->emin);
+	min = READ_ONCE(ctest->prot->emin);
 
 	if (used <= min)
 		return false;
 
 	if (!ignore_low) {
-		low = READ_ONCE(ctest->elow);
+		low = READ_ONCE(ctest->prot->elow);
 		if (used > low)
 			return true;
 
@@ -786,7 +786,7 @@ bool dmem_cgroup_below_min(struct dmem_cgroup_pool_state *root,
 	 * here.
 	 */
 	dmem_cgroup_calculate_protection(root, test);
-	return page_counter_read(&test->cnt) <= READ_ONCE(test->cnt.emin);
+	return page_counter_read(&test->cnt) <= READ_ONCE(test->cnt.prot->emin);
 }
 EXPORT_SYMBOL_GPL(dmem_cgroup_below_min);
 
@@ -817,7 +817,7 @@ bool dmem_cgroup_below_low(struct dmem_cgroup_pool_state *root,
 	 * here.
 	 */
 	dmem_cgroup_calculate_protection(root, test);
-	return page_counter_read(&test->cnt) <= READ_ONCE(test->cnt.elow);
+	return page_counter_read(&test->cnt) <= READ_ONCE(test->cnt.prot->elow);
 }
 EXPORT_SYMBOL_GPL(dmem_cgroup_below_low);
 
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index ffa1ced3baae..b4c01a0dfd4f 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -4823,7 +4823,7 @@ static ssize_t memory_peak_write(struct kernfs_open_file *of, char *buf,
 static int memory_min_show(struct seq_file *m, void *v)
 {
 	return seq_puts_memcg_tunable(m,
-		READ_ONCE(mem_cgroup_from_seq(m)->memory.min));
+		READ_ONCE(mem_cgroup_from_seq(m)->memory_prot.min));
 }
 
 static ssize_t memory_min_write(struct kernfs_open_file *of,
@@ -4846,7 +4846,7 @@ static ssize_t memory_min_write(struct kernfs_open_file *of,
 static int memory_low_show(struct seq_file *m, void *v)
 {
 	return seq_puts_memcg_tunable(m,
-		READ_ONCE(mem_cgroup_from_seq(m)->memory.low));
+		READ_ONCE(mem_cgroup_from_seq(m)->memory_prot.low));
 }
 
 static ssize_t memory_low_write(struct kernfs_open_file *of,
@@ -6271,6 +6271,6 @@ void mem_cgroup_show_protected_memory(struct mem_cgroup *memcg)
 		memcg = root_mem_cgroup;
 
 	pr_warn("Memory cgroup min protection %lukB -- low protection %lukB",
-		K(atomic_long_read(&memcg->memory.children_min_usage)),
-		K(atomic_long_read(&memcg->memory.children_low_usage)));
+		K(atomic_long_read(&memcg->memory_prot.children_min_usage)),
+		K(atomic_long_read(&memcg->memory_prot.children_low_usage)));
 }
diff --git a/mm/page_counter.c b/mm/page_counter.c
index 38cb99f5f50e..401201c8e390 100644
--- a/mm/page_counter.c
+++ b/mm/page_counter.c
@@ -21,28 +21,29 @@ static bool track_protection(struct page_counter *c)
 static void propagate_protected_usage(struct page_counter *c,
 				      unsigned long usage)
 {
+	struct page_counter_protection *prot = c->prot;
 	unsigned long protected, old_protected;
 	long delta;
 
-	if (!c->parent)
+	if (!prot || !prot->parent)
 		return;
 
-	protected = min(usage, READ_ONCE(c->min));
-	old_protected = atomic_long_read(&c->min_usage);
+	protected = min(usage, READ_ONCE(prot->min));
+	old_protected = atomic_long_read(&prot->min_usage);
 	if (protected != old_protected) {
-		old_protected = atomic_long_xchg(&c->min_usage, protected);
+		old_protected = atomic_long_xchg(&prot->min_usage, protected);
 		delta = protected - old_protected;
 		if (delta)
-			atomic_long_add(delta, &c->parent->children_min_usage);
+			atomic_long_add(delta, &prot->parent->children_min_usage);
 	}
 
-	protected = min(usage, READ_ONCE(c->low));
-	old_protected = atomic_long_read(&c->low_usage);
+	protected = min(usage, READ_ONCE(prot->low));
+	old_protected = atomic_long_read(&prot->low_usage);
 	if (protected != old_protected) {
-		old_protected = atomic_long_xchg(&c->low_usage, protected);
+		old_protected = atomic_long_xchg(&prot->low_usage, protected);
 		delta = protected - old_protected;
 		if (delta)
-			atomic_long_add(delta, &c->parent->children_low_usage);
+			atomic_long_add(delta, &prot->parent->children_low_usage);
 	}
 }
 
@@ -257,7 +258,10 @@ void page_counter_set_min(struct page_counter *counter, unsigned long nr_pages)
 {
 	struct page_counter *c;
 
-	WRITE_ONCE(counter->min, nr_pages);
+	if (!counter->prot)
+		return;
+
+	WRITE_ONCE(counter->prot->min, nr_pages);
 
 	for (c = counter; c; c = c->parent)
 		propagate_protected_usage(c, atomic_long_read(&c->usage));
@@ -274,7 +278,10 @@ void page_counter_set_low(struct page_counter *counter, unsigned long nr_pages)
 {
 	struct page_counter *c;
 
-	WRITE_ONCE(counter->low, nr_pages);
+	if (!counter->prot)
+		return;
+
+	WRITE_ONCE(counter->prot->low, nr_pages);
 
 	for (c = counter; c; c = c->parent)
 		propagate_protected_usage(c, atomic_long_read(&c->usage));
@@ -445,9 +452,18 @@ void page_counter_calculate_protection(struct page_counter *root,
 				       struct page_counter *counter,
 				       bool recursive_protection)
 {
+	struct page_counter_protection *prot = counter->prot;
+	struct page_counter_protection *parent_prot;
 	unsigned long usage, parent_usage;
 	struct page_counter *parent = counter->parent;
 
+	/*
+	 * Only counters with protection support (memory, dmem pools) are
+	 * ever passed here, but guard anyway.
+	 */
+	if (!prot)
+		return;
+
 	/*
 	 * Effective values of the reclaim targets are ignored so they
 	 * can be stale. Have a look at mem_cgroup_protection for more
@@ -463,23 +479,24 @@ void page_counter_calculate_protection(struct page_counter *root,
 		return;
 
 	if (parent == root) {
-		counter->emin = READ_ONCE(counter->min);
-		counter->elow = READ_ONCE(counter->low);
+		prot->emin = READ_ONCE(prot->min);
+		prot->elow = READ_ONCE(prot->low);
 		return;
 	}
 
+	parent_prot = parent->prot;
 	parent_usage = page_counter_read(parent);
 
-	WRITE_ONCE(counter->emin, effective_protection(usage, parent_usage,
-			READ_ONCE(counter->min),
-			READ_ONCE(parent->emin),
-			atomic_long_read(&parent->children_min_usage),
+	WRITE_ONCE(prot->emin, effective_protection(usage, parent_usage,
+			READ_ONCE(prot->min),
+			READ_ONCE(parent_prot->emin),
+			atomic_long_read(&parent_prot->children_min_usage),
 			recursive_protection));
 
-	WRITE_ONCE(counter->elow, effective_protection(usage, parent_usage,
-			READ_ONCE(counter->low),
-			READ_ONCE(parent->elow),
-			atomic_long_read(&parent->children_low_usage),
+	WRITE_ONCE(prot->elow, effective_protection(usage, parent_usage,
+			READ_ONCE(prot->low),
+			READ_ONCE(parent_prot->elow),
+			atomic_long_read(&parent_prot->children_low_usage),
 			recursive_protection));
 }
 #endif /* CONFIG_MEMCG || CONFIG_CGROUP_DMEM */

-- 
2.43.7

