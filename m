From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:45 -0500
Subject: [PATCH 54/60] mm/migrate: route explicit NUMA migration to private
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-54-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198154; l=4872;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=LdBmn7sW2WZfOe8jPXvczezaQql167iyE39pQOO8QgY=;
 b=sTml8+HqIUvMTacUxZiUfSUZimAOAY9MiHZ9lsqd24xS7lWLntm08ZOzq3xfS7DqVpEkNzuQu
 aE+pXSWkZHlDCm/IGuzhatOFii5433SjI7oHHeyyJr2YhuHNaROFriH
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

move_pages(2) and migrate_pages(2) allocate the destination folio by
node id with __GFP_THISNODE. A private node is not on its own
__GFP_THISNODE (ZONELIST_NOFALLBACK) zonelist, so the allocation never
lands on it.

When the destination is a private node in N_MEMORY_MEMPOLICY, select the
node's private zonelist and a single-node mask in the syscall path, and
pass them to alloc_migration_target() via migration_target_control.

move_pages(2) now accepts such a destination rather than only common
memory, and still refuses other private nodes with -ENODEV, so
do_move_pages_to_node() only needs to check N_MEMORY_PRIVATE.
migrate_pages(2) keeps such nodes in its destination mask, and drops
other private nodes as it drops nodes outside the caller's cpuset.

The other users of alloc_migration_target() are unchanged.

HugeTLB folios still cannot move to a private node, since private nodes
hold no HugeTLB pages.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 mm/internal.h  |  1 +
 mm/mempolicy.c | 19 +++++++++++++++----
 mm/migrate.c   | 13 ++++++++++++-
 3 files changed, 28 insertions(+), 5 deletions(-)

diff --git a/mm/internal.h b/mm/internal.h
index c83c100a5253..646efc2eacd1 100644
--- a/mm/internal.h
+++ b/mm/internal.h
@@ -1309,6 +1309,7 @@ struct migration_target_control {
 	int nid;		/* preferred node id */
 	nodemask_t *nmask;
 	gfp_t gfp_mask;
+	unsigned int alloc_flags;	/* ALLOC_ZONELIST_PRIVATE or 0 */
 	enum migrate_reason reason;
 };
 
diff --git a/mm/mempolicy.c b/mm/mempolicy.c
index cb5419cb7ee8..a7cbb05ac86c 100644
--- a/mm/mempolicy.c
+++ b/mm/mempolicy.c
@@ -1340,7 +1340,7 @@ static bool migrate_folio_add(struct folio *folio, struct list_head *foliolist,
 static long migrate_to_node(struct mm_struct *mm, int source, int dest,
 			    int flags)
 {
-	nodemask_t nmask;
+	nodemask_t nmask, dest_mask;
 	struct vm_area_struct *vma;
 	LIST_HEAD(pagelist);
 	long nr_failed;
@@ -1351,6 +1351,14 @@ static long migrate_to_node(struct mm_struct *mm, int source, int dest,
 		.reason = MR_SYSCALL,
 	};
 
+	/* Private placement is reachable only through the private zonelist. */
+	if (node_state(dest, N_MEMORY_MEMPOLICY) &&
+	    node_state(dest, N_MEMORY_PRIVATE)) {
+		init_nodemask_of_node(&dest_mask, dest);
+		mtc.nmask = &dest_mask;
+		mtc.alloc_flags = ALLOC_ZONELIST_PRIVATE;
+	}
+
 	nodes_clear(nmask);
 	node_set(source, nmask);
 
@@ -1951,7 +1959,7 @@ static int kernel_migrate_pages(pid_t pid, unsigned long maxnode,
 	struct mm_struct *mm = NULL;
 	struct task_struct *task;
 	nodemask_t task_nodes;
-	int err;
+	int err, nid;
 	nodemask_t *old;
 	nodemask_t *new;
 	NODEMASK_SCRATCH(scratch);
@@ -2001,8 +2009,11 @@ static int kernel_migrate_pages(pid_t pid, unsigned long maxnode,
 	}
 
 	task_nodes = cpuset_mems_allowed(current);
-	/* Private memory is not a migration destination. */
-	nodes_andnot(task_nodes, task_nodes, node_states[N_MEMORY_PRIVATE]);
+	/* Private nodes are destinations only if they permit userspace placement. */
+	for_each_node_state(nid, N_MEMORY_PRIVATE) {
+		if (!node_state(nid, N_MEMORY_MEMPOLICY))
+			node_clear(nid, task_nodes);
+	}
 	if (!nodes_and(*new, *new, task_nodes))
 		goto out_put;
 
diff --git a/mm/migrate.c b/mm/migrate.c
index 6791834f14fe..eda961d43df0 100644
--- a/mm/migrate.c
+++ b/mm/migrate.c
@@ -2250,6 +2250,9 @@ struct folio *alloc_migration_target(struct folio *src, unsigned long private)
 	if (is_highmem_idx(zidx) || zidx == ZONE_MOVABLE)
 		gfp_mask |= __GFP_HIGHMEM;
 
+	if (mtc->alloc_flags)
+		return __folio_alloc_flags(gfp_mask, order, nid, mtc->nmask,
+					   mtc->alloc_flags);
 	return __folio_alloc(gfp_mask, order, nid, mtc->nmask);
 }
 
@@ -2267,6 +2270,7 @@ static int store_status(int __user *status, int start, int value, int nr)
 
 static int do_move_pages_to_node(struct list_head *pagelist, int node)
 {
+	nodemask_t nmask;
 	int err;
 	struct migration_target_control mtc = {
 		.nid = node,
@@ -2274,6 +2278,13 @@ static int do_move_pages_to_node(struct list_head *pagelist, int node)
 		.reason = MR_SYSCALL,
 	};
 
+	/* A private node is reachable only through its private zonelist. */
+	if (node_state(node, N_MEMORY_PRIVATE)) {
+		init_nodemask_of_node(&nmask, node);
+		mtc.nmask = &nmask;
+		mtc.alloc_flags = ALLOC_ZONELIST_PRIVATE;
+	}
+
 	err = migrate_pages(pagelist, alloc_migration_target, NULL,
 		(unsigned long)&mtc, MIGRATE_SYNC, MR_SYSCALL, NULL);
 	if (err)
@@ -2411,7 +2422,7 @@ static int do_pages_move(struct mm_struct *mm, nodemask_t task_nodes,
 		err = -ENODEV;
 		if (node < 0 || node >= MAX_NUMNODES)
 			goto out_flush;
-		if (!node_state(node, N_MEMORY_COMMON))
+		if (!node_state(node, N_MEMORY_MEMPOLICY))
 			goto out_flush;
 
 		err = -EACCES;

-- 
2.56.1

