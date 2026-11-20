From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:08:54 -0500
Subject: [PATCH 03/60] mm: introduce the common-memory node state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-3-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198152; l=6041;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=ajsO63VrYOt1/B86M9EiwRSYqxX+EUlgXltSDFFhAuY=;
 b=i8EdEJBLCK7kYw+nGD0pd446Jpk01TMj3DEPiN/iEyXX9xSSPwHuWtf9EvwHBIGp7fpgk2j1g
 eGSAKGYzz0zCca0iN2pUlbb/I/wPDtOPtDeqTdJbPbkWAfpWma+9Zqh
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

N_MEMORY is overloaded with two meanings:
  1) a node has memory.
  2) a node's memory is reachable via ordinary allocation or
     an arbitrary MM service may use that memory.

Allow N_MEMORY to mean #1, and introduce N_MEMORY_COMMON to mean #2.

N_MEMORY_COMMON nodes contain "common memory" capable of being managed
arbitrarily by the kernel MM based solely on zone membership. Following
commits convert relevant N_MEMORY users to N_MEMORY_COMMON.

Expose the state via `has_common_memory` so userspace can identify
the memory available to ordinary allocations and common MM services.

Add has_memory to the docs while we're here.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 Documentation/ABI/stable/sysfs-devices-node | 17 +++++++++++++++++
 Documentation/mm/physical_memory.rst        |  8 +++++++-
 drivers/base/node.c                         |  2 ++
 include/linux/nodemask.h                    |  9 ++++++++-
 mm/page_alloc.c                             |  3 +++
 5 files changed, 37 insertions(+), 2 deletions(-)

diff --git a/Documentation/ABI/stable/sysfs-devices-node b/Documentation/ABI/stable/sysfs-devices-node
index 2d0e023f22a7..0a2cf3088233 100644
--- a/Documentation/ABI/stable/sysfs-devices-node
+++ b/Documentation/ABI/stable/sysfs-devices-node
@@ -10,6 +10,15 @@ Contact:	Linux Memory Management list <linux-mm@kvack.org>
 Description:
 		Nodes that are online.
 
+What:		/sys/devices/system/node/has_memory
+Date:		December 2012
+Contact:	Linux Memory Management list <linux-mm@kvack.org>
+Description:
+		Nodes that have memory.
+
+		This memory may or may not be reachable via standard
+		allocations, see has_common_memory for details.
+
 What:		/sys/devices/system/node/has_normal_memory
 Date:		October 2002
 Contact:	Linux Memory Management list <linux-mm@kvack.org>
@@ -29,6 +38,14 @@ Description:
 		Nodes that have regular or high memory.
 		Depends on CONFIG_HIGHMEM.
 
+What:		/sys/devices/system/node/has_common_memory
+Date:		November 2026
+Contact:	Linux Memory Management list <linux-mm@kvack.org>
+Description:
+		Nodes whose memory ordinary allocations may use without
+		requesting the node explicitly, and that kernel memory
+		management services manage.
+
 What:		/sys/devices/system/node/nodeX
 Date:		October 2002
 Contact:	Linux Memory Management list <linux-mm@kvack.org>
diff --git a/Documentation/mm/physical_memory.rst b/Documentation/mm/physical_memory.rst
index 2e67e8b23a99..86a7d6080535 100644
--- a/Documentation/mm/physical_memory.rst
+++ b/Documentation/mm/physical_memory.rst
@@ -168,7 +168,12 @@ nodes with particular properties as defined by ``enum node_states``:
   The node has regular or high memory. When ``CONFIG_HIGHMEM`` is disabled
   aliased to ``N_NORMAL_MEMORY``.
 ``N_MEMORY``
-  The node has memory(regular, high, movable)
+  The node has online memory (regular, high, movable).  This is a topology and
+  accounting state. Presence in this mask does not mean ordinary allocations
+  can use the node's memory. See ``N_MEMORY_COMMON``.
+``N_MEMORY_COMMON``
+  Ordinary allocations and memory management services may use the node's
+  memory.
 ``N_CPU``
   The node has one or more CPUs
 ``N_GENERIC_INITIATOR``
@@ -184,6 +189,7 @@ For example, for node 2 with normal memory and CPUs, bit 2 will be set in ::
   node_states[N_NORMAL_MEMORY]
   node_states[N_HIGH_MEMORY]
   node_states[N_MEMORY]
+  node_states[N_MEMORY_COMMON]
   node_states[N_CPU]
 
 For various operations possible with nodemasks please refer to
diff --git a/drivers/base/node.c b/drivers/base/node.c
index dcdc8626627a..cc6696d1390f 100644
--- a/drivers/base/node.c
+++ b/drivers/base/node.c
@@ -965,6 +965,7 @@ static struct node_attr node_state_attr[] = {
 	[N_HIGH_MEMORY] = _NODE_ATTR(has_high_memory, N_HIGH_MEMORY),
 #endif
 	[N_MEMORY] = _NODE_ATTR(has_memory, N_MEMORY),
+	[N_MEMORY_COMMON] = _NODE_ATTR(has_common_memory, N_MEMORY_COMMON),
 	[N_CPU] = _NODE_ATTR(has_cpu, N_CPU),
 	[N_GENERIC_INITIATOR] = _NODE_ATTR(has_generic_initiator,
 					   N_GENERIC_INITIATOR),
@@ -978,6 +979,7 @@ static struct attribute *node_state_attrs[] = {
 	&node_state_attr[N_HIGH_MEMORY].attr.attr,
 #endif
 	&node_state_attr[N_MEMORY].attr.attr,
+	&node_state_attr[N_MEMORY_COMMON].attr.attr,
 	&node_state_attr[N_CPU].attr.attr,
 	&node_state_attr[N_GENERIC_INITIATOR].attr.attr,
 	NULL
diff --git a/include/linux/nodemask.h b/include/linux/nodemask.h
index 90bdcffa42ea..c3b984105bd1 100644
--- a/include/linux/nodemask.h
+++ b/include/linux/nodemask.h
@@ -398,7 +398,14 @@ enum node_states {
 #else
 	N_HIGH_MEMORY = N_NORMAL_MEMORY,
 #endif
-	N_MEMORY,		/* The node has memory(regular, high, movable) */
+	/*
+	 * N_MEMORY indicates online memory exists on the node - it is used
+	 * to manage per-node meta-data and topology decisions.
+	 * N_MEMORY_COMMON indicates whether the node can satisfy arbitrary
+	 * allocations and whether a service should manage that node's folios.
+	 */
+	N_MEMORY,		/* the node has memory */
+	N_MEMORY_COMMON,	/* common pool (fallback zonelist) */
 	N_CPU,		/* The node has one or more cpus */
 	N_GENERIC_INITIATOR,	/* The node has one or more Generic Initiators */
 	NR_NODE_STATES
diff --git a/mm/page_alloc.c b/mm/page_alloc.c
index 88d507f93b1a..ddb04b72a160 100644
--- a/mm/page_alloc.c
+++ b/mm/page_alloc.c
@@ -203,6 +203,7 @@ nodemask_t node_states[NR_NODE_STATES] __read_mostly = {
 	[N_HIGH_MEMORY] = { { [0] = 1UL } },
 #endif
 	[N_MEMORY] = { { [0] = 1UL } },
+	[N_MEMORY_COMMON] = { { [0] = 1UL } },
 	[N_CPU] = { { [0] = 1UL } },
 #endif	/* NUMA */
 };
@@ -211,10 +212,12 @@ EXPORT_SYMBOL(node_states);
 void __meminit node_set_memory_state(int nid)
 {
 	node_set_state(nid, N_MEMORY);
+	node_set_state(nid, N_MEMORY_COMMON);
 }
 
 void __meminit node_clear_memory_state(int nid)
 {
+	node_clear_state(nid, N_MEMORY_COMMON);
 	node_clear_state(nid, N_MEMORY);
 }
 

-- 
2.56.1

