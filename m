From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:22 -0500
Subject: [PATCH 31/60] cgroup/cpuset: inherit common memory when a nodemask
 is private only
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-31-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198153; l=8729;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=lhAjAk7Sm6BaAakto+KbG1/rEMIjEBUTFNJJhHnsEgg=;
 b=0w6zXkqUQAxwMZHNpdjCJwh22P2ZJENxucUISEDMrEBkWvfPDRkY99+RSVag9NWwOq11MJQRH
 IcyhSRPQT3UDQwfXY7yDZh+nJ2+FXeoiiQ9r1UMnmnYyaJVB/NX9klN
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cpuset.mems governs every N_MEMORY node, but ordinary allocations
can use only N_MEMORY_COMMON memory.

An effective mask without N_MEMORY_COMMON nodes creates an unsatisfiable
condition for ordinary system allocations, such as page tables. This
can cause an unsatisfiable OOM or an infinite fault retry loop.

Treat a cpuset.mems mask without a common memory node as a condition
to inherit the parent's common memory nodes.

The inheritance behavior differs subtly between v1 and v2:

operation                             v1              v2
 write {}, no tasks                 remain empty    inherit all
 write {}, populated                -ENOSPC         inherit all
 write {private}                    -ENOSPC         inherit common
 write {outside parent}             -EACCES         inherit common
 write {common, private}             normal intersection in both modes
 task attach w/ {private}           -ENOSPC         use effective mask
 {common, private}, unplug common   clear & move    keep & add common

In the v2 {private} case, the cpuset inherits only the parent's common
nodes and gains no access to unrelated private nodes. A request naming
no node the parent allows does the same. Systems without private nodes
are entirely unchanged by this commit.

An actual empty request still inherits the parent's full effective mask.

Example: (C=common, P=private)
  parent.cpuset.mems = {C0, C1, P2, P3}
  child.cpuset.mems  = {C0, P2}

  /* User sets private-only mask */
  echo {P2} > child.cpuset.mems
  child.cpuset.mems  = P2
  child.cpuset.effective_mems = {C0, C1, P2}

      or

  /* Hot-unplug removes C0 */
  hotunplug {C0}
  child.cpuset.mems  = {C0, P2}
  child.cpuset.effective_mems = {C1, P2}

      or

  /* User clears the nodemask entirely */
  echo {} > child.cpuset.mems
  child.cpuset.effective_mems => {C0, C1, P2, P3}

Private nodes are thus non-inheritable unless the nodemask is empty.

Rejecting a private-only nodemask in v2 would be confusing (-EINVAL
on a valid node) and inconsistent with hotplug, which can still leave
a cpuset with only private memory. Resolve every case the same way:
effective_mems inherits only the common nodes.

For v1, a write rejects a mask without common memory with -ENOSPC,
even with no tasks attached: v1 has no effective mask to add common
nodes to, so tasks attached later would have no common memory. Memory
hotplug that leaves a mask with only private memory moves its tasks to
an ancestor.

Automatic memory migration uses only common-memory destinations.

A task's mems_allowed comes from guarantee_online_mems(), which walks
up the hierarchy while a cpuset has no memory. Walk up while it has no
common memory instead, so a task never gets a private-only mask in the
window between memory going offline and the hotplug update of the
effective masks.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 kernel/cgroup/cpuset.c | 58 +++++++++++++++++++++++++++++++++++++++-----------
 1 file changed, 46 insertions(+), 12 deletions(-)

diff --git a/kernel/cgroup/cpuset.c b/kernel/cgroup/cpuset.c
index db32d330cfbc..6802ca13c46b 100644
--- a/kernel/cgroup/cpuset.c
+++ b/kernel/cgroup/cpuset.c
@@ -534,22 +534,24 @@ static void guarantee_active_cpus(struct task_struct *tsk,
 
 /*
  * Return in *pmask the portion of a cpusets's mems_allowed that
- * are online, with memory.  If none are online with memory, walk
- * up the cpuset hierarchy until we find one that does have some
- * online mems.  The top cpuset always has some mems online. With v2,
+ * are online, with memory.  If none of them is common memory, walk
+ * up the cpuset hierarchy until we find one that does have some.
+ * The top cpuset always has some common memory online. With v2,
  * effective_mems should always contain online memory nodes except
  * during the transition period where a memory node hotunplug operation
  * is in progress.
  *
- * One way or another, we guarantee to return some non-empty subset
- * of node_states[N_MEMORY].
+ * One way or another, we guarantee to return some subset of
+ * node_states[N_MEMORY] that includes common memory.
  *
  * Call with callback_lock or cpuset_mutex held.
  */
 static void guarantee_online_mems(struct cpuset *cs, nodemask_t *pmask)
 {
-	while (!nodes_and(*pmask, cs->effective_mems, node_states[N_MEMORY]))
+	while (!nodes_intersects(cs->effective_mems,
+				 node_states[N_MEMORY_COMMON]))
 		cs = parent_cs(cs);
+	nodes_and(*pmask, cs->effective_mems, node_states[N_MEMORY]);
 }
 
 /**
@@ -1684,22 +1686,40 @@ static void compute_effective_cpumask(struct cpumask *new_cpus,
 		cpumask_copy(new_cpus, parent->effective_cpus);
 }
 
+/* @mems names private memory nodes but no common memory node. */
+static bool mems_private_only(const nodemask_t *mems)
+{
+	return nodes_intersects(*mems, node_states[N_MEMORY_PRIVATE]) &&
+	       !nodes_intersects(*mems, node_states[N_MEMORY_COMMON]);
+}
+
 /**
  * compute_effective_nodemask - Compute the effective nodemask of the cpuset
  * @new_mems: the temp variable for the new effective_mems mask
  * @cs: the cpuset the need to recompute the new effective_mems mask
  * @parent: the parent cpuset
  *
- * For v2, the parent's effective_mems is inherited if nodemask is empty.
+ * A nodemask whose memory is all private cannot serve an ordinary allocation.
+ * In v2, a non-empty request retains the requested nodes granted by the parent
+ * and inherits the parent's nodes other than private ones.
+ * In v1, cpuset_hotplug_update_tasks() empties such a mask, so the tasks move
+ * to an ancestor.
  */
 static void compute_effective_nodemask(nodemask_t *new_mems,
 				       struct cpuset *cs, struct cpuset *parent)
 {
-	bool has_mems;
+	nodemask_t inherited;
 
-	has_mems = nodes_and(*new_mems, cs->mems_allowed, parent->effective_mems);
-	if (!has_mems && is_in_v2_mode())
+	nodes_and(*new_mems, cs->mems_allowed, parent->effective_mems);
+	if (!is_in_v2_mode())
+		return;
+	if (nodes_empty(cs->mems_allowed)) {
 		nodes_copy(*new_mems, parent->effective_mems);
+	} else if (nodes_empty(*new_mems) || mems_private_only(new_mems)) {
+		nodes_andnot(inherited, parent->effective_mems,
+			     node_states[N_MEMORY_PRIVATE]);
+		nodes_or(*new_mems, *new_mems, inherited);
+	}
 }
 
 /*
@@ -2667,6 +2687,8 @@ static void cpuset_migrate_mm_workfn(struct work_struct *work)
 	struct cpuset_migrate_mm_work *mwork =
 		container_of(work, struct cpuset_migrate_mm_work, work);
 
+	/* Private nodes are never migration destinations. */
+	nodes_andnot(mwork->to, mwork->to, node_states[N_MEMORY_PRIVATE]);
 	/* on a wq worker, no need to worry about %current's mems_allowed */
 	do_migrate_pages(mwork->mm, &mwork->from, &mwork->to, MPOL_MF_MOVE_ALL);
 	mmput(mwork->mm);
@@ -2900,6 +2922,14 @@ static int update_nodemask(struct cpuset *cs, struct cpuset *trialcs,
 			  top_cpuset.mems_allowed))
 		return -EINVAL;
 
+	/*
+	 * In v1, if a mask has no common memory nodes, it's treated as empty
+	 * because there is no effective-mems inherited fallback. As a result,
+	 * we treat this state the same as-if there was no memory at all.
+	 */
+	if (!is_in_v2_mode() && mems_private_only(&trialcs->mems_allowed))
+		return -ENOSPC;
+
 	/* No change? nothing to do */
 	if (nodes_equal(cs->mems_allowed, trialcs->mems_allowed))
 		return 0;
@@ -3090,7 +3120,7 @@ static int update_prstate(struct cpuset *cs, int new_prs)
 
 /*
  * Check to see if a cpuset can accept a new task
- * For v1, cpus_allowed and mems_allowed can't be empty.
+ * For v1, cpus_allowed can't be empty and mems_allowed must have common memory.
  * For v2, effective_cpus can't be empty.
  * Note that in v1, effective_cpus = cpus_allowed.
  *
@@ -3103,7 +3133,8 @@ static int cpuset_can_attach_check(struct cpuset *cs, struct cpuset *oldcs,
 	bool cpus_updated, mems_updated;
 
 	if (cpumask_empty(cs->effective_cpus) ||
-	   (!is_in_v2_mode() && nodes_empty(cs->mems_allowed)))
+	   (!is_in_v2_mode() && (nodes_empty(cs->mems_allowed) ||
+				 mems_private_only(&cs->mems_allowed))))
 		return -ENOSPC;
 
 	if (!oldcs)
@@ -3988,6 +4019,9 @@ static void cpuset_hotplug_update_tasks(struct cpuset *cs, struct tmpmasks *tmp)
 	parent = parent_cs(cs);
 	compute_effective_cpumask(&new_cpus, cs, parent);
 	compute_effective_nodemask(&new_mems, cs, parent);
+	/* A legacy cpuset left with only private memory moves its tasks. */
+	if (!is_in_v2_mode() && mems_private_only(&new_mems))
+		nodes_clear(new_mems);
 
 	if (!tmp || !cs->partition_root_state)
 		goto update_tasks;

-- 
2.56.1

