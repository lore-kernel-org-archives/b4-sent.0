From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:03 -0500
Subject: [PATCH 12/60] mm/vmscan: restrict reclaim to common memory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-12-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198152; l=2825;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=FtLUhP0wFF5GfqO7k4obSm/pRyOe/gBL2Z3quyWtR6I=;
 b=zwlm1U/LcEdr9egylwJhEu7nOZaUODHcksIlsiJlCATY4Fbl78/BXLfyNjSKWv3UDT+qsBfSZ
 piPbYWcP1rrCCLgsKDDw4afKb7rTwG3CyQeRdlVm7Foh4LeK1/sZgiM
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reclaim serves the ordinary allocation domain.

Restrict it to N_MEMORY_COMMON:
  - start kswapd only on common nodes, at boot or hotplug.
  - walk common nodes when MGLRU's debugfs interface iterates or
    validates nodes, using first_node_state() and next_node_state() in
    place of first_memory_node and next_memory_node.

Direct reclaim serves an allocation from its own zonelist, so it is left
alone.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 mm/memory_hotplug.c |  3 ++-
 mm/vmscan.c         | 12 ++++++------
 2 files changed, 8 insertions(+), 7 deletions(-)

diff --git a/mm/memory_hotplug.c b/mm/memory_hotplug.c
index 1d3d1792074c..a599fcad65d3 100644
--- a/mm/memory_hotplug.c
+++ b/mm/memory_hotplug.c
@@ -1222,7 +1222,8 @@ int online_pages(unsigned long pfn, unsigned long nr_pages,
 	/* reinitialise watermarks and update pcp limits */
 	init_per_zone_wmark_min();
 
-	kswapd_run(nid);
+	if (node_state(nid, N_MEMORY_COMMON))
+		kswapd_run(nid);
 	kcompactd_run(nid);
 
 	if (node_arg.nid >= 0)
diff --git a/mm/vmscan.c b/mm/vmscan.c
index bc7579d47f9b..5b53e0391d80 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -5729,7 +5729,7 @@ static void *lru_gen_seq_start(struct seq_file *m, loff_t *pos)
 	do {
 		int nid;
 
-		for_each_node_state(nid, N_MEMORY) {
+		for_each_node_state(nid, N_MEMORY_COMMON) {
 			if (!nr_to_skip--)
 				return mem_cgroup_lruvec(memcg, NODE_DATA(nid));
 		}
@@ -5754,13 +5754,13 @@ static void *lru_gen_seq_next(struct seq_file *m, void *v, loff_t *pos)
 
 	++*pos;
 
-	nid = next_memory_node(nid);
+	nid = next_node_state(nid, N_MEMORY_COMMON);
 	if (nid == MAX_NUMNODES) {
 		memcg = mem_cgroup_iter(NULL, memcg, NULL);
 		if (!memcg)
 			return NULL;
 
-		nid = first_memory_node;
+		nid = first_node_state(N_MEMORY_COMMON);
 	}
 
 	return mem_cgroup_lruvec(memcg, NODE_DATA(nid));
@@ -5832,7 +5832,7 @@ static int lru_gen_seq_show(struct seq_file *m, void *v)
 	DEFINE_MAX_SEQ(lruvec);
 	DEFINE_MIN_SEQ(lruvec);
 
-	if (nid == first_memory_node) {
+	if (nid == first_node_state(N_MEMORY_COMMON)) {
 		const char *path = memcg ? m->private : "";
 
 #ifdef CONFIG_MEMCG
@@ -5935,7 +5935,7 @@ static int run_cmd(char cmd, u64 memcg_id, int nid, unsigned long seq,
 	int err = -EINVAL;
 	struct mem_cgroup *memcg = NULL;
 
-	if (nid < 0 || nid >= MAX_NUMNODES || !node_state(nid, N_MEMORY))
+	if (nid < 0 || nid >= MAX_NUMNODES || !node_state(nid, N_MEMORY_COMMON))
 		return -EINVAL;
 
 	if (!mem_cgroup_disabled()) {
@@ -7907,7 +7907,7 @@ static int __init kswapd_init(void)
 {
 	int nid;
 
-	for_each_node_state(nid, N_MEMORY)
+	for_each_node_state(nid, N_MEMORY_COMMON)
  		kswapd_run(nid);
 	register_sysctl_init("vm", vmscan_sysctl_table);
 	return 0;

-- 
2.56.1

