From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:38 -0500
Subject: [PATCH 47/60] mm/vmscan: restrict reclaim to N_MEMORY_RECLAIM
 instead of N_MEMORY_COMMON
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-47-74f5f9a115c2@gourry.net>
References: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
In-Reply-To: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
To: Yury Norov <yury.norov@gmail.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 David Hildenbrand <david@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Michal Hocko <mhocko@suse.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Oscar Salvador <osalvador@suse.de>, Johannes Weiner <hannes@cmpxchg.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Brendan Jackman <brendan.jackman@linux.dev>, Zi Yan <ziy@nvidia.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Rakie Kim <rakie.kim@sk.com>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Matthew Brost <matthew.brost@intel.com>, Byungchul Park <byungchul@sk.com>, 
 Alistair Popple <apopple@nvidia.com>, SJ Park <sj@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, Kees Cook <kees@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Barry Song <baohua@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Michal Hocko <mhocko@kernel.org>, David Rientjes <rientjes@google.com>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Nico Pache <nico.pache@linux.dev>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Xu Xin <xu.xin@linux.dev>, Chengming Zhou <chengming.zhou@linux.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, Pedro Falcato <pfalcato@suse.de>, 
 Jann Horn <jannh@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, Jan Kara <jack@suse.cz>, 
 Waiman Long <longman@redhat.com>, Ridong Chen <ridong.chen@linux.dev>, 
 Tejun Heo <tj@kernel.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Dan Williams <djbw@kernel.org>, Vishal Verma <vishal.l.verma@intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, 
 Alison Schofield <alison.schofield@intel.com>, 
 Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 linux-cxl@vger.kernel.org, linux-doc@vger.kernel.org, 
 driver-core@lists.linux.dev, damon@lists.linux.dev, 
 linux-pm@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 cgroups@vger.kernel.org, nvdimm@lists.linux.dev, 
 linux-kselftest@vger.kernel.org, "Gregory Price (Meta)" <gourry@gourry.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198153; l=6325;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=c7DgarKbPTh+6IzFAHFl6eKVTW2BJrYv3RKLDMceLJE=;
 b=pJ9yiRLLHXGH+ah/OM4I5sNBVlA9ZiE7FmUiyed58jvCYoAInkb3gL9qE4qbzozo6/HQ/UBhm
 +p2J5pp71F8BQDYiKB23kBhQW4ibDlwjd0+2F6Ea2rd3w38dcgQckEc
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kswapd and the reclaim interfaces currently serve only common memory. A
private node that opts into reclaim should get them too.

Restrict reclaim to N_MEMORY_RECLAIM:
  - start kswapd only on N_MEMORY_RECLAIM nodes.
  - walk N_MEMORY_RECLAIM nodes in MGLRU's debugfs interface.
  - reject nodeN/reclaim for nodes without N_MEMORY_RECLAIM.

Direct reclaim is unchanged: an allocation reclaims the zones on its
zonelist, and a private node's zones are only on its private zonelist.

Private nodes that permit reclaim get watermarks again (the capped
minimum that highmem and movable zones get) and are boosted, since
their kswapd restores both.

Private nodes without the state keep zero watermarks.

The hopeless-kswapd recovery on page free exists because allocations
that fall back to another node skip the direct reclaim that would clear
the state. Only common memory offers that fallback, so apply the
recovery only to common nodes now that private nodes run kswapd.

Leave private zones out of si_mem_available()'s low watermark sum,
which bounds the common page cache and slab that must stay.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 mm/memory_hotplug.c |  2 +-
 mm/page_alloc.c     | 11 +++++++----
 mm/show_mem.c       |  7 +++++--
 mm/vmscan.c         | 14 +++++++-------
 4 files changed, 20 insertions(+), 14 deletions(-)

diff --git a/mm/memory_hotplug.c b/mm/memory_hotplug.c
index 1cb10c88954e..8146f77919d5 100644
--- a/mm/memory_hotplug.c
+++ b/mm/memory_hotplug.c
@@ -1230,7 +1230,7 @@ int online_pages(unsigned long pfn, unsigned long nr_pages,
 	/* reinitialise watermarks and update pcp limits */
 	init_per_zone_wmark_min();
 
-	if (node_state(nid, N_MEMORY_COMMON))
+	if (node_state(nid, N_MEMORY_RECLAIM))
 		kswapd_run(nid);
 	if (node_state(nid, N_MEMORY_COMPACTION))
 		kcompactd_run(nid);
diff --git a/mm/page_alloc.c b/mm/page_alloc.c
index 864da908a59b..cc70e1b45322 100644
--- a/mm/page_alloc.c
+++ b/mm/page_alloc.c
@@ -2972,6 +2972,7 @@ static bool free_frozen_page_commit(struct zone *zone,
 		 * kswapd work again by resetting kswapd_failures.
 		 */
 		if (kswapd_test_hopeless(pgdat) &&
+		    node_state(pgdat->node_id, N_MEMORY_COMMON) &&
 		    num_node_state(N_MEMORY_COMMON) > 1)
 			kswapd_clear_hopeless(pgdat, KSWAPD_CLEAR_HOPELESS_PCP);
 	}
@@ -6814,8 +6815,8 @@ static void __setup_per_zone_wmarks(void)
 		u64 tmp;
 
 		spin_lock_irqsave(&zone->lock, flags);
-		/* No kswapd runs for a private node to restore watermarks. */
-		if (node_state(zone_to_nid(zone), N_MEMORY_PRIVATE)) {
+		/* Nodes that reclaim does not serve carry no watermarks. */
+		if (!node_state(zone_to_nid(zone), N_MEMORY_RECLAIM)) {
 			zone->_watermark[WMARK_MIN] = 0;
 			zone->_watermark[WMARK_LOW] = 0;
 			zone->_watermark[WMARK_HIGH] = 0;
@@ -6826,11 +6827,13 @@ static void __setup_per_zone_wmarks(void)
 		}
 		tmp = (u64)pages_min * zone_managed_pages(zone);
 		tmp = div64_ul(tmp, lowmem_pages);
-		if (is_highmem(zone) || zone_idx(zone) == ZONE_MOVABLE) {
+		if (is_highmem(zone) || zone_idx(zone) == ZONE_MOVABLE ||
+		    node_state(zone_to_nid(zone), N_MEMORY_PRIVATE)) {
 			/*
 			 * __GFP_HIGH and PF_MEMALLOC allocations usually don't
 			 * need highmem and movable zones pages, so cap pages_min
-			 * to a small  value here.
+			 * to a small  value here. Private memory holds no system
+			 * reserve, only this small minimum.
 			 *
 			 * The WMARK_HIGH-WMARK_LOW and (WMARK_LOW-WMARK_MIN)
 			 * deltas control async page reclaim, and so should
diff --git a/mm/show_mem.c b/mm/show_mem.c
index b90fb5a0016b..24dd33ba783b 100644
--- a/mm/show_mem.c
+++ b/mm/show_mem.c
@@ -38,8 +38,11 @@ long si_mem_available(void)
 	unsigned long reclaimable;
 	struct zone *zone;
 
-	for_each_zone(zone)
-		wmark_low += low_wmark_pages(zone);
+	/* Only common zones bound the page cache and slab that must stay. */
+	for_each_zone(zone) {
+		if (!node_state(zone_to_nid(zone), N_MEMORY_PRIVATE))
+			wmark_low += low_wmark_pages(zone);
+	}
 
 	/*
 	 * Estimate the amount of memory available for userspace allocations,
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 3e934135e805..03d0919d11be 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -5729,7 +5729,7 @@ static void *lru_gen_seq_start(struct seq_file *m, loff_t *pos)
 	do {
 		int nid;
 
-		for_each_node_state(nid, N_MEMORY_COMMON) {
+		for_each_node_state(nid, N_MEMORY_RECLAIM) {
 			if (!nr_to_skip--)
 				return mem_cgroup_lruvec(memcg, NODE_DATA(nid));
 		}
@@ -5754,13 +5754,13 @@ static void *lru_gen_seq_next(struct seq_file *m, void *v, loff_t *pos)
 
 	++*pos;
 
-	nid = next_node_state(nid, N_MEMORY_COMMON);
+	nid = next_node_state(nid, N_MEMORY_RECLAIM);
 	if (nid == MAX_NUMNODES) {
 		memcg = mem_cgroup_iter(NULL, memcg, NULL);
 		if (!memcg)
 			return NULL;
 
-		nid = first_node_state(N_MEMORY_COMMON);
+		nid = first_node_state(N_MEMORY_RECLAIM);
 	}
 
 	return mem_cgroup_lruvec(memcg, NODE_DATA(nid));
@@ -5832,7 +5832,7 @@ static int lru_gen_seq_show(struct seq_file *m, void *v)
 	DEFINE_MAX_SEQ(lruvec);
 	DEFINE_MIN_SEQ(lruvec);
 
-	if (nid == first_node_state(N_MEMORY_COMMON)) {
+	if (nid == first_node_state(N_MEMORY_RECLAIM)) {
 		const char *path = memcg ? m->private : "";
 
 #ifdef CONFIG_MEMCG
@@ -5935,7 +5935,7 @@ static int run_cmd(char cmd, u64 memcg_id, int nid, unsigned long seq,
 	int err = -EINVAL;
 	struct mem_cgroup *memcg = NULL;
 
-	if (nid < 0 || nid >= MAX_NUMNODES || !node_state(nid, N_MEMORY_COMMON))
+	if (nid < 0 || nid >= MAX_NUMNODES || !node_state(nid, N_MEMORY_RECLAIM))
 		return -EINVAL;
 
 	if (!mem_cgroup_disabled()) {
@@ -7907,7 +7907,7 @@ static int __init kswapd_init(void)
 {
 	int nid;
 
-	for_each_node_state(nid, N_MEMORY_COMMON)
+	for_each_node_state(nid, N_MEMORY_RECLAIM)
  		kswapd_run(nid);
 	register_sysctl_init("vm", vmscan_sysctl_table);
 	return 0;
@@ -8268,7 +8268,7 @@ static ssize_t reclaim_store(struct device *dev,
 {
 	int ret, nid = dev->id;
 
-	if (node_state(nid, N_MEMORY_PRIVATE))
+	if (node_state(nid, N_MEMORY) && !node_state(nid, N_MEMORY_RECLAIM))
 		return -EOPNOTSUPP;
 
 	ret = user_proactive_reclaim((char *)buf, NULL, NODE_DATA(nid));

-- 
2.56.1

