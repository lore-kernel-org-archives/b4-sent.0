From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:41 -0500
Subject: [PATCH 50/60] mm: add N_MEMORY_MEMPOLICY node state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-50-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198153; l=4477;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=POrrod7a8qe5/RJcpG1x1W6f1yuN7ZdnOW2+WhH0FXE=;
 b=aTDMy5aQgR/eu/TnyoctRRRg14g5CIETIw3u4dDaQdYVGncbixZ+T0SNCnrlFn6DFrsn4+Zg1
 q8XW52q1jYMDuHrNhBZsCfARwTf3Qz3aNp9IhHdIxv9ybHyAJ3U5en6
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add N_MEMORY_MEMPOLICY as an internal state for the nodes that memory
policy interfaces and explicit migration may target, and
NODE_MEMORY_FEAT_MEMPOLICY for memory providers to select it.

Userspace placement lets ordinary processes use the node like any other
memory. That assumes the node is reclaimed and compacted, so the feature
requires both.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 Documentation/mm/physical_memory.rst |  3 +++
 include/linux/nodemask.h             | 11 +++++++++--
 mm/page_alloc.c                      |  4 ++++
 3 files changed, 16 insertions(+), 2 deletions(-)

diff --git a/Documentation/mm/physical_memory.rst b/Documentation/mm/physical_memory.rst
index 1bafe8c085a3..75752c3a5694 100644
--- a/Documentation/mm/physical_memory.rst
+++ b/Documentation/mm/physical_memory.rst
@@ -190,6 +190,8 @@ The following states are internal and not exported through sysfs:
 ``N_MEMORY_RECLAIM``
   The kernel reclaims the node on its own initiative (kswapd, memcg and
   explicit reclaim).
+``N_MEMORY_MEMPOLICY``
+  Memory-policy interfaces and explicit migration may target the node.
 
 For each node that has a property described above, the bit corresponding to the
 node ID in the ``node_states[<property>]`` bitmask is set.
@@ -205,6 +207,7 @@ For example, for node 2 with normal memory and CPUs, bit 2 will be set in ::
   node_states[N_CPU]
   node_states[N_MEMORY_COMPACTION]
   node_states[N_MEMORY_RECLAIM]
+  node_states[N_MEMORY_MEMPOLICY]
 
 For various operations possible with nodemasks please refer to
 ``include/linux/nodemask.h``.
diff --git a/include/linux/nodemask.h b/include/linux/nodemask.h
index be5edbee2b22..c7a1800d9171 100644
--- a/include/linux/nodemask.h
+++ b/include/linux/nodemask.h
@@ -414,6 +414,7 @@ enum node_states {
 	/* Internal states, not exported through sysfs */
 	N_MEMORY_COMPACTION,	/* mm compaction may operate on the node */
 	N_MEMORY_RECLAIM,	/* mm reclaim may operate on the node */
+	N_MEMORY_MEMPOLICY,	/* memory policy may target the node */
 	NR_NODE_STATES
 };
 
@@ -552,14 +553,17 @@ static __always_inline int node_random(const nodemask_t *maskp)
 #define NODE_MEMORY_FEAT_COMMON		BIT(0) /* add to fallback zonelist */
 #define NODE_MEMORY_FEAT_COMPACTION	BIT(1) /* mm compaction */
 #define NODE_MEMORY_FEAT_RECLAIM	BIT(2) /* mm reclaim */
+#define NODE_MEMORY_FEAT_MEMPOLICY	BIT(3) /* userspace NUMA controls */
 #define NODE_MEMORY_FEAT_ALL		(NODE_MEMORY_FEAT_COMMON | \
 					 NODE_MEMORY_FEAT_COMPACTION | \
-					 NODE_MEMORY_FEAT_RECLAIM)
+					 NODE_MEMORY_FEAT_RECLAIM | \
+					 NODE_MEMORY_FEAT_MEMPOLICY)
 
 /*
  * Common memory carries every feature. Private memory needs NUMA: node 0
  * holds all memory without it. Reclaim leaves high-order requests to
- * compaction, so it requires compaction.
+ * compaction, so it requires compaction. Userspace placement assumes the
+ * node is reclaimed and compacted like any other memory.
  */
 static inline bool node_memory_features_valid(unsigned long features)
 {
@@ -570,6 +574,9 @@ static inline bool node_memory_features_valid(unsigned long features)
 	if ((features & NODE_MEMORY_FEAT_RECLAIM) &&
 	    !(features & NODE_MEMORY_FEAT_COMPACTION))
 		return false;
+	if ((features & NODE_MEMORY_FEAT_MEMPOLICY) &&
+	    !(features & NODE_MEMORY_FEAT_RECLAIM))
+		return false;
 	return IS_ENABLED(CONFIG_NUMA);
 }
 
diff --git a/mm/page_alloc.c b/mm/page_alloc.c
index cc70e1b45322..eff9c3d8251f 100644
--- a/mm/page_alloc.c
+++ b/mm/page_alloc.c
@@ -206,6 +206,7 @@ nodemask_t node_states[NR_NODE_STATES] __read_mostly = {
 	[N_MEMORY_COMMON] = { { [0] = 1UL } },
 	[N_MEMORY_COMPACTION] = { { [0] = 1UL } },
 	[N_MEMORY_RECLAIM] = { { [0] = 1UL } },
+	[N_MEMORY_MEMPOLICY] = { { [0] = 1UL } },
 	[N_CPU] = { { [0] = 1UL } },
 #endif	/* NUMA */
 };
@@ -224,10 +225,13 @@ void __meminit node_set_memory_state(int nid, unsigned long features)
 		node_set_state(nid, N_MEMORY_COMPACTION);
 	if (features & NODE_MEMORY_FEAT_RECLAIM)
 		node_set_state(nid, N_MEMORY_RECLAIM);
+	if (features & NODE_MEMORY_FEAT_MEMPOLICY)
+		node_set_state(nid, N_MEMORY_MEMPOLICY);
 }
 
 void __meminit node_clear_memory_state(int nid)
 {
+	node_clear_state(nid, N_MEMORY_MEMPOLICY);
 	node_clear_state(nid, N_MEMORY_RECLAIM);
 	node_clear_state(nid, N_MEMORY_COMPACTION);
 	node_clear_state(nid, N_MEMORY_PRIVATE);

-- 
2.56.1

