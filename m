From: Jingxiang Zeng <linuszeng@tencent.com>
Date: Fri, 18 Sep 2026 16:53:45 +0800
Subject: [PATCH 5/6] mm: memcontrol: add memory.memsw.max to the default
 hierarchy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-descriptive-name-v1-5-dfcfdd91b456@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721651; l=10079;
 i=linuszeng@tencent.com; s=20260909; h=from:subject:message-id;
 bh=O+UnCNXqeUosINeQRBcbUosVOEHXAvFyYevVXrvwqHw=;
 b=wUwcrPfS0kgUjJfvEvXnh4fH+Tr+1i59G8Jg1hull13COHjMDKJn7HeYYxUhyMXf1WQoEz9fR
 z/qv+9mCczGCHIU586g8PMfoaf7XvzzSJxKGLImoiM7gV4CY5M8a0FH
X-Developer-Key: i=linuszeng@tencent.com; a=ed25519;
 pk=6K54xRzYIRWqatrAPy86M4E0MsI92BVJBhXwz5NdC74=
X-Endpoint-Received: by B4 Relay for linuszeng@tencent.com/20260909 with auth_id=1017
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cgroup v1 can cap the sum of memory and swap through
memsw.limit_in_bytes.  v2 only offers separate memory.max and
memory.swap.max, so a workload that must be capped on the total of the
two has no equivalent knob: memory.max alone can be met by swapping,
and capping both separately reserves swap that the workload may never
use.

Now that the combined counter is maintained on both hierarchies, expose
it on the default hierarchy:

  memory.memsw.current  combined memory+swap usage
  memory.memsw.max      combined memory+swap hard limit, default "max"

A charge counted here is held for as long as the memory occupies either
RAM or a swap slot, so reclaim cannot bring a cgroup back under the
limit by swapping; try_to_free_mem_cgroup_pages() is called without
MEMCG_RECLAIM_MAY_SWAP when the limit is written, and the cgroup OOM
killer is the last resort, mirroring memory.max.

Both writers enforce memory.max <= memory.memsw.max and return -EINVAL
otherwise, so the two limits cannot be configured into a state reclaim
could never satisfy.  This matches the invariant v1 keeps in
mem_cgroup_resize_max(), including the serialization: the test and the
store are done under a mutex, as two concurrent writers could otherwise
both pass the check and leave memory.max above the combined limit.  The
mutex is not held across reclaim.

Since memory.max defaults to "max", a combined limit can only be
installed once memory.max has been lowered, and updating both limits has
to start with memory.memsw.max when raising them and with memory.max
when lowering them.  Document that ordering next to the invariant.

Print the combined counter in the OOM dump on the default hierarchy too,
so a kill caused by this limit can be told apart from one caused by
memory.max.  No failcnt is printed there: it is only tracked on v1, and
a breach is already counted as MEMCG_MAX.

The files follow the default-hierarchy naming convention
(current/max) rather than v1's limit_in_bytes, and live in swap_files[]
since a combined limit is only meaningful with swap configured.

Signed-off-by: Jingxiang Zeng <linuszeng@tencent.com>
---
 Documentation/admin-guide/cgroup-v2.rst |  32 ++++++++
 mm/memcontrol.c                         | 136 ++++++++++++++++++++++++++++++--
 2 files changed, 163 insertions(+), 5 deletions(-)

diff --git a/Documentation/admin-guide/cgroup-v2.rst b/Documentation/admin-guide/cgroup-v2.rst
index 8d2603751c51..dd0cf28d39d9 100644
--- a/Documentation/admin-guide/cgroup-v2.rst
+++ b/Documentation/admin-guide/cgroup-v2.rst
@@ -1881,6 +1881,38 @@ The following nested keys are defined.
 	Swap usage hard limit.  If a cgroup's swap usage reaches this
 	limit, anonymous memory of the cgroup will not be swapped out.
 
+  memory.memsw.current
+	A read-only single value file which exists on non-root cgroups.
+
+	The total amount of memory and swap space currently charged to
+	the cgroup and its descendants.
+
+  memory.memsw.max
+	A read-write single value file which exists on non-root
+	cgroups.  The default is "max".
+
+	Combined memory and swap usage hard limit.  Unlike memory.max,
+	which can be met by swapping anonymous memory out, a charge
+	counted here is kept for as long as the memory occupies either
+	RAM or a swap slot.  Reclaim therefore cannot bring a cgroup
+	back under this limit by swapping; only dropping pages, or
+	freeing swap slots, does.
+
+	This is the default-hierarchy counterpart of cgroup v1's
+	memory.memsw.limit_in_bytes and is useful for workloads that
+	must be capped on the sum of the two resources rather than on
+	each of them separately.
+
+	The limit must not be lower than memory.max: writes that would
+	violate memory.max <= memory.memsw.max are rejected with
+	EINVAL, in either file.  Since memory.max defaults to "max", a
+	combined limit can only be installed after memory.max has been
+	lowered.  To raise both limits, write memory.memsw.max first;
+	to lower both, write memory.max first.
+
+	If the limit is exceeded and reclaim cannot bring usage back
+	down, the cgroup OOM killer is invoked.
+
   memory.swap.events
 	A read-only flat-keyed file which exists on non-root cgroups.
 	The following entries are defined.  Unless specified
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 1daa55f2e99d..9e8a176e7afb 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -1873,11 +1873,15 @@ void mem_cgroup_print_oom_meminfo(struct mem_cgroup *memcg)
 	pr_info("memory: usage %llukB, limit %llukB, failcnt %lu\n",
 		K((u64)page_counter_read(&memcg->memory)),
 		K((u64)READ_ONCE(memcg->memory.max)), memory_failcnt);
-	if (cgroup_subsys_on_dfl(memory_cgrp_subsys))
+	if (cgroup_subsys_on_dfl(memory_cgrp_subsys)) {
 		pr_info("swap: usage %llukB, limit %llukB, failcnt %lu\n",
 			K((u64)page_counter_read(&memcg->swap)),
 			K((u64)READ_ONCE(memcg->swap.max)),
 			atomic_long_read(&memcg->memory_events[MEMCG_SWAP_MAX]));
+		pr_info("memory+swap: usage %llukB, limit %llukB\n",
+			K((u64)page_counter_read(&memcg->memsw)),
+			K((u64)READ_ONCE(memcg->memsw.max)));
+	}
 #ifdef CONFIG_MEMCG_V1
 	else {
 		pr_info("memory+swap: usage %llukB, limit %llukB, failcnt %lu\n",
@@ -2724,10 +2728,10 @@ static int try_charge_memcg(struct mem_cgroup *memcg, gfp_t gfp_mask,
 
 	reclaim_options = MEMCG_RECLAIM_MAY_SWAP;
 	/*
-	 * The combined memory+swap counter is charged on both hierarchies.
-	 * Its limit is only configurable through v1's memsw.limit_in_bytes
-	 * for now and defaults to "max", so unless the user configures a
-	 * combined limit this never fails.
+	 * The combined memory+swap counter is charged on both hierarchies:
+	 * v1 exposes it as memsw.limit_in_bytes, v2 as memory.memsw.max.
+	 * It defaults to "max", so unless the user configures a combined
+	 * limit this never fails.
 	 *
 	 * Swapping does not reduce the combined charge, so when the combined
 	 * limit is what we hit, reclaim must not count on swap.
@@ -4981,6 +4985,14 @@ static int memory_max_show(struct seq_file *m, void *v)
 		READ_ONCE(mem_cgroup_from_seq(m)->memory.max));
 }
 
+/*
+ * Serializes memory.max against memory.memsw.max so that the two cannot be
+ * tested and installed concurrently, which would let a pair of writers land
+ * in a state where memory.max exceeds the combined limit.  Only held across
+ * the check and the store, never across reclaim.
+ */
+static DEFINE_MUTEX(dfl_max_mutex);
+
 static ssize_t memory_max_write(struct kernfs_open_file *of,
 				char *buf, size_t nbytes, loff_t off)
 {
@@ -4995,7 +5007,20 @@ static ssize_t memory_max_write(struct kernfs_open_file *of,
 	if (err)
 		return err;
 
+	/*
+	 * Keep the basic invariant memory.max <= memory.memsw.max, so a
+	 * combined memory+swap limit cannot be exceeded through the memory
+	 * limit.  memory.memsw.max defaults to "max", so this only rejects
+	 * writes once a combined limit has been configured.
+	 */
+	mutex_lock(&dfl_max_mutex);
+	if (max > READ_ONCE(memcg->memsw.max)) {
+		mutex_unlock(&dfl_max_mutex);
+		return -EINVAL;
+	}
+
 	xchg(&memcg->memory.max, max);
+	mutex_unlock(&dfl_max_mutex);
 
 	if (of->file->f_flags & O_NONBLOCK)
 		goto out;
@@ -6204,7 +6229,108 @@ static int swap_events_show(struct seq_file *m, void *v)
 	return 0;
 }
 
+static u64 memsw_current_read(struct cgroup_subsys_state *css,
+			      struct cftype *cft)
+{
+	struct mem_cgroup *memcg = mem_cgroup_from_css(css);
+
+	return (u64)page_counter_read(&memcg->memsw) * PAGE_SIZE;
+}
+
+static int memsw_max_show(struct seq_file *m, void *v)
+{
+	return seq_puts_memcg_tunable(m,
+		READ_ONCE(mem_cgroup_from_seq(m)->memsw.max));
+}
+
+/*
+ * The combined memory+swap limit.  Swapping a page out does not release a
+ * combined charge, so reclaim cannot use swap to get back under this limit;
+ * only dropping pages, or freeing swap slots, helps.
+ */
+static ssize_t memsw_max_write(struct kernfs_open_file *of,
+			       char *buf, size_t nbytes, loff_t off)
+{
+	struct mem_cgroup *memcg = mem_cgroup_from_css(of_css(of));
+	unsigned int nr_reclaims = MAX_RECLAIM_RETRIES;
+	bool drained = false;
+	unsigned long max;
+	int err;
+
+	buf = strstrip(buf);
+	err = page_counter_memparse(buf, "max", &max);
+	if (err)
+		return err;
+
+	/*
+	 * Keep the basic invariant memory.max <= memory.memsw.max: a combined
+	 * limit below the memory limit could never be met by reclaim.  Lower
+	 * memory.max first to install a combined limit on a fresh cgroup,
+	 * where memory.max still defaults to "max".
+	 */
+	mutex_lock(&dfl_max_mutex);
+	if (max < READ_ONCE(memcg->memory.max)) {
+		mutex_unlock(&dfl_max_mutex);
+		return -EINVAL;
+	}
+
+	xchg(&memcg->memsw.max, max);
+	mutex_unlock(&dfl_max_mutex);
+
+	if (of->file->f_flags & O_NONBLOCK)
+		goto out;
+
+	for (;;) {
+		unsigned long nr_pages = page_counter_read(&memcg->memsw);
+
+		if (max != READ_ONCE(memcg->memsw.max))
+			break;
+
+		if (nr_pages <= max)
+			break;
+
+		if (signal_pending(current))
+			break;
+
+		/* cgroup_rmdir() waits for us with cgroup_mutex held. */
+		if (memcg_is_dying(memcg))
+			break;
+
+		if (!drained) {
+			drain_all_stock(memcg);
+			drained = true;
+			continue;
+		}
+
+		if (nr_reclaims) {
+			if (!try_to_free_mem_cgroup_pages(memcg, nr_pages - max,
+					GFP_KERNEL, 0, NULL))
+				nr_reclaims--;
+			continue;
+		}
+
+		memcg_memory_event(memcg, MEMCG_OOM);
+		if (!mem_cgroup_out_of_memory(memcg, GFP_KERNEL, 0))
+			break;
+		cond_resched();
+	}
+out:
+	memcg_wb_domain_size_changed(memcg);
+	return nbytes;
+}
+
 static struct cftype swap_files[] = {
+	{
+		.name = "memsw.current",
+		.flags = CFTYPE_NOT_ON_ROOT,
+		.read_u64 = memsw_current_read,
+	},
+	{
+		.name = "memsw.max",
+		.flags = CFTYPE_NOT_ON_ROOT,
+		.seq_show = memsw_max_show,
+		.write = memsw_max_write,
+	},
 	{
 		.name = "swap.current",
 		.flags = CFTYPE_NOT_ON_ROOT,

-- 
2.43.7

