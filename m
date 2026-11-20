From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:18 -0500
Subject: [PATCH 27/60] mm: add the private-memory node state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-27-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198153; l=5643;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=zId/m3UcEeKPlrHjDuBTph6SlMWMgHfNTv0FPlTy5jk=;
 b=UQPuu0+30xBC00mgn1hSzuDWDMkKDN3WxupMdh1ZgoT3kBVxhLL5UdV2Q7T1tbGBb8aBZhTom
 a2I0WisarbDDWUsD2+k6+bL9x+5sPTZQCfJRGG2SOn1nC/Y+GahAoYl
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

N_MEMORY_COMMON describes memory that ordinary allocations and MM
services may use. Some memory is online but is not part of that pool.

Add N_MEMORY_PRIVATE for nodes with such memory.

N_MEMORY_COMMON and N_MEMORY_PRIVATE partition N_MEMORY, so a caller can
drop private nodes from a mask without also dropping memoryless nodes.

Expose the state via `has_private_memory`.

Without CONFIG_NUMA, node 0 holds all memory and none of it is private.
We have to adjust the node_state check to return false for this node,
previously when CONFIG_NUMA was disabled it would always return true.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 Documentation/ABI/stable/sysfs-devices-node | 10 ++++++++++
 Documentation/mm/physical_memory.rst        |  3 +++
 drivers/base/node.c                         |  2 ++
 include/linux/nodemask.h                    | 12 ++++++++----
 mm/page_alloc.c                             |  1 +
 5 files changed, 24 insertions(+), 4 deletions(-)

diff --git a/Documentation/ABI/stable/sysfs-devices-node b/Documentation/ABI/stable/sysfs-devices-node
index 0a2cf3088233..70ab780c6ddf 100644
--- a/Documentation/ABI/stable/sysfs-devices-node
+++ b/Documentation/ABI/stable/sysfs-devices-node
@@ -46,6 +46,16 @@ Description:
 		requesting the node explicitly, and that kernel memory
 		management services manage.
 
+What:		/sys/devices/system/node/has_private_memory
+Date:		November 2026
+Contact:	Linux Memory Management list <linux-mm@kvack.org>
+Description:
+		Nodelist of the memory nodes absent from has_common_memory.
+		Together the two lists partition has_memory.
+
+		Ordinary allocations do not use memory on a node listed here.
+		See Documentation/mm/numa_private_nodes.rst.
+
 What:		/sys/devices/system/node/nodeX
 Date:		October 2002
 Contact:	Linux Memory Management list <linux-mm@kvack.org>
diff --git a/Documentation/mm/physical_memory.rst b/Documentation/mm/physical_memory.rst
index 86a7d6080535..ddba7c890418 100644
--- a/Documentation/mm/physical_memory.rst
+++ b/Documentation/mm/physical_memory.rst
@@ -174,6 +174,9 @@ nodes with particular properties as defined by ``enum node_states``:
 ``N_MEMORY_COMMON``
   Ordinary allocations and memory management services may use the node's
   memory.
+``N_MEMORY_PRIVATE``
+  The node has memory but is not on the fallback zonelists. Together with
+  ``N_MEMORY_COMMON`` it partitions ``N_MEMORY``.
 ``N_CPU``
   The node has one or more CPUs
 ``N_GENERIC_INITIATOR``
diff --git a/drivers/base/node.c b/drivers/base/node.c
index cc6696d1390f..56a1741a6a45 100644
--- a/drivers/base/node.c
+++ b/drivers/base/node.c
@@ -966,6 +966,7 @@ static struct node_attr node_state_attr[] = {
 #endif
 	[N_MEMORY] = _NODE_ATTR(has_memory, N_MEMORY),
 	[N_MEMORY_COMMON] = _NODE_ATTR(has_common_memory, N_MEMORY_COMMON),
+	[N_MEMORY_PRIVATE] = _NODE_ATTR(has_private_memory, N_MEMORY_PRIVATE),
 	[N_CPU] = _NODE_ATTR(has_cpu, N_CPU),
 	[N_GENERIC_INITIATOR] = _NODE_ATTR(has_generic_initiator,
 					   N_GENERIC_INITIATOR),
@@ -980,6 +981,7 @@ static struct attribute *node_state_attrs[] = {
 #endif
 	&node_state_attr[N_MEMORY].attr.attr,
 	&node_state_attr[N_MEMORY_COMMON].attr.attr,
+	&node_state_attr[N_MEMORY_PRIVATE].attr.attr,
 	&node_state_attr[N_CPU].attr.attr,
 	&node_state_attr[N_GENERIC_INITIATOR].attr.attr,
 	NULL
diff --git a/include/linux/nodemask.h b/include/linux/nodemask.h
index c3b984105bd1..5a9722d57701 100644
--- a/include/linux/nodemask.h
+++ b/include/linux/nodemask.h
@@ -403,9 +403,12 @@ enum node_states {
 	 * to manage per-node meta-data and topology decisions.
 	 * N_MEMORY_COMMON indicates whether the node can satisfy arbitrary
 	 * allocations and whether a service should manage that node's folios.
+	 * N_MEMORY_PRIVATE holds the other memory nodes: together the two
+	 * partition N_MEMORY.
 	 */
 	N_MEMORY,		/* the node has memory */
 	N_MEMORY_COMMON,	/* common pool (fallback zonelist) */
+	N_MEMORY_PRIVATE,	/* memory outside the common pool */
 	N_CPU,		/* The node has one or more cpus */
 	N_GENERIC_INITIATOR,	/* The node has one or more Generic Initiators */
 	NR_NODE_STATES
@@ -478,9 +481,10 @@ static __always_inline void node_set_offline(int nid)
 
 #else
 
+/* Node 0 holds all memory, and none of it is private. */
 static __always_inline int node_state(int node, enum node_states state)
 {
-	return node == 0;
+	return node == 0 && state != N_MEMORY_PRIVATE;
 }
 
 static __always_inline void node_set_state(int node, enum node_states state)
@@ -493,13 +497,13 @@ static __always_inline void node_clear_state(int node, enum node_states state)
 
 static __always_inline int num_node_state(enum node_states state)
 {
-	return 1;
+	return state != N_MEMORY_PRIVATE;
 }
 
 #define for_each_node_state(node, __state) \
-	for ( (node) = 0; (node) == 0; (node) = 1)
+	for ((node) = 0; (node) == 0 && (__state) != N_MEMORY_PRIVATE; (node) = 1)
 
-#define first_node_state(state)	0
+#define first_node_state(state)	((state) == N_MEMORY_PRIVATE ? MAX_NUMNODES : 0)
 static __always_inline unsigned int next_node_state(int nid, enum node_states state)
 {
 	return MAX_NUMNODES;
diff --git a/mm/page_alloc.c b/mm/page_alloc.c
index 1ec7d8000792..50336eb58edf 100644
--- a/mm/page_alloc.c
+++ b/mm/page_alloc.c
@@ -217,6 +217,7 @@ void __meminit node_set_memory_state(int nid)
 
 void __meminit node_clear_memory_state(int nid)
 {
+	node_clear_state(nid, N_MEMORY_PRIVATE);
 	node_clear_state(nid, N_MEMORY_COMMON);
 	node_clear_state(nid, N_MEMORY);
 }

-- 
2.56.1

