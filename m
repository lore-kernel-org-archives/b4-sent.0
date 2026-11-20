From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:44 -0500
Subject: [PATCH 53/60] mm/mempolicy: add MPOL_F_PRIVATE_NODES for private
 node bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-53-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198154; l=11909;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=qpDp9Uw5U7Holq6SO9FpvmrnHTCzndjaolkmwUv4n7U=;
 b=waLUxFwVjjK1r6z4uQauHS9EmVfZ5EzEf3NftvJiPHdtba1GeE5pQkOh+uFgsoD0FSgI7Qh0m
 90Gt5kKZDi0BUk8WRLzEx00KWBPydIAE+btm2kQOwM3mOTEjAL0xccQ
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Private bindings behave differently from ordinary ones: they are strict,
never rebound, and fail with SIGBUS instead of invoking the OOM killer
when their node is exhausted. Callers should know they are opting into
that behavior explicitly.

Add MPOL_F_PRIVATE_NODES, an mbind() mode flag that binds a mapping to
one private node in N_MEMORY_MEMPOLICY. Without the flag, private nodes
in a mask are ignored - the same as nodes outside the cpuset.

Older kernels reject the flag, so userspace can probe for it.

A private binding must name exactly one node. The private zonelist
covers only that node, and a memoryless node left in the mask would
widen the binding once it gains memory.

The flag selects a rebind mode like MPOL_F_STATIC_NODES and
MPOL_F_RELATIVE_NODES, so it excludes both: a private binding is never
rebound. policy_nodemask() already ignores a binding with no node in the
current cpuset, so revoking access suspends the binding to common
memory, and restoring access resumes it.

The flag also excludes MPOL_F_NUMA_BALANCING, since NUMA balancing does
not act on private memory.  This can be loosened in the future.

Reject private bindings on HugeTLB mappings. Pool reservations are made
at mmap() time against global counts, and pool growth and dequeue use
the common zonelists, so the binding could never be satisfied. This
can also be loosened in the future if a use case grows HugeTLB support.

set_mempolicy() rejects the flag, because a task policy also steers the
task's kernel allocations.

Policies other than MPOL_BIND only apply to common memory nodes.
This can also be loosened later if a use case appears, but no compelling
use case has been proposed in 2 years of discussions.  This minimizes
the overall complexity of the base HBM/GPU use case considerably.

Use policy_nodemask() for the existing cpuset and zone checks, then
select the local private zonelist only when the effective target is
eligible private memory.

set_mempolicy_home_node() rejects a home node other than the bound
private node, since there is no fallback behavior in either direction,
an unmatched home node is nonsensical.

numa_maps reports private bindings as "private".

Document the flag in the admin guide.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 .../admin-guide/mm/numa_memory_policy.rst          | 22 +++++++
 include/uapi/linux/mempolicy.h                     |  4 +-
 mm/mempolicy.c                                     | 76 +++++++++++++++++++---
 3 files changed, 92 insertions(+), 10 deletions(-)

diff --git a/Documentation/admin-guide/mm/numa_memory_policy.rst b/Documentation/admin-guide/mm/numa_memory_policy.rst
index 90ab26e805a9..f2dc59cd6acc 100644
--- a/Documentation/admin-guide/mm/numa_memory_policy.rst
+++ b/Documentation/admin-guide/mm/numa_memory_policy.rst
@@ -341,6 +341,28 @@ MPOL_F_RELATIVE_NODES
 	MPOL_PREFERRED policies that were created with an empty nodemask
 	(local allocation).
 
+MPOL_F_PRIVATE_NODES
+	This flag binds a VMA to a single private memory node (see
+	Documentation/mm/numa_private_nodes.rst).  Without it, private
+	nodes in a policy's nodemask are ignored, as nodes outside the
+	task's cpuset are.
+
+	Only mbind() with MPOL_BIND accepts the flag, and its nodemask
+	must name exactly one private node that permits userspace
+	placement.
+	A private binding is never rebound when the task's allowed nodes
+	change.  While its node is ineligible (outside the task's cpuset,
+	or no longer private memory that permits userspace placement),
+	the binding is suspended and allocations use common memory.  It
+	resumes when the node becomes eligible again.  If the node returns
+	as common memory, the binding acts as an ordinary binding to that
+	node.
+	get_mempolicy() reports the original nodemask.
+
+	MPOL_F_PRIVATE_NODES cannot be combined with
+	MPOL_F_STATIC_NODES, MPOL_F_RELATIVE_NODES or
+	MPOL_F_NUMA_BALANCING, and cannot be used on HugeTLB mappings.
+
 Memory Policy Reference Counting
 ================================
 
diff --git a/include/uapi/linux/mempolicy.h b/include/uapi/linux/mempolicy.h
index 7f6fc9599693..4dcdf8f68803 100644
--- a/include/uapi/linux/mempolicy.h
+++ b/include/uapi/linux/mempolicy.h
@@ -31,13 +31,15 @@ enum mempolicy_mode {
 #define MPOL_F_STATIC_NODES	(1 << 15)
 #define MPOL_F_RELATIVE_NODES	(1 << 14)
 #define MPOL_F_NUMA_BALANCING	(1 << 13) /* Optimize with NUMA balancing if possible */
+#define MPOL_F_PRIVATE_NODES	(1 << 12) /* mbind() to a private memory node */
 
 /*
  * MPOL_MODE_FLAGS is the union of all possible optional mode flags passed to
  * either set_mempolicy() or mbind().
  */
 #define MPOL_MODE_FLAGS							\
-	(MPOL_F_STATIC_NODES | MPOL_F_RELATIVE_NODES | MPOL_F_NUMA_BALANCING)
+	(MPOL_F_STATIC_NODES | MPOL_F_RELATIVE_NODES | MPOL_F_NUMA_BALANCING | \
+	 MPOL_F_PRIVATE_NODES)
 
 /* Whether the nodemask is specified by users */
 #define MPOL_USER_NODEMASK_FLAGS (MPOL_F_STATIC_NODES | MPOL_F_RELATIVE_NODES)
diff --git a/mm/mempolicy.c b/mm/mempolicy.c
index 9d2e56017ebe..cb5419cb7ee8 100644
--- a/mm/mempolicy.c
+++ b/mm/mempolicy.c
@@ -451,9 +451,13 @@ static int mpol_set_nodemask(struct mempolicy *pol,
 	if (!pol || pol->mode == MPOL_LOCAL)
 		return 0;
 
-	/* Check N_MEMORY_COMMON */
-	nodes_and(nsc->mask1,
-		  cpuset_current_mems_allowed, node_states[N_MEMORY_COMMON]);
+	/* Private bindings name a private node; others use common memory. */
+	if (pol->flags & MPOL_F_PRIVATE_NODES)
+		nodes_and(nsc->mask1, node_states[N_MEMORY_MEMPOLICY],
+			  node_states[N_MEMORY_PRIVATE]);
+	else
+		nsc->mask1 = node_states[N_MEMORY_COMMON];
+	nodes_and(nsc->mask1, nsc->mask1, cpuset_current_mems_allowed);
 
 	VM_BUG_ON(!nodes);
 
@@ -488,6 +492,13 @@ static struct mempolicy *mpol_new(unsigned short mode, unsigned short flags,
 	}
 	VM_BUG_ON(!nodes);
 
+	/*
+	 * The private zonelist covers a single node, so a private bind must name
+	 * exactly one node; a memoryless bit would later widen the binding.
+	 */
+	if ((flags & MPOL_F_PRIVATE_NODES) && nodes_weight(*nodes) != 1)
+		return ERR_PTR(-EINVAL);
+
 	/*
 	 * MPOL_PREFERRED cannot be used with MPOL_F_STATIC_NODES or
 	 * MPOL_F_RELATIVE_NODES if the nodemask is empty (local allocation).
@@ -580,6 +591,9 @@ static void mpol_rebind_policy(struct mempolicy *pol, const nodemask_t *newmask)
 
 	if (!pol || pol->mode == MPOL_LOCAL)
 		return;
+	/* Allocation checks a private binding against the current cpuset. */
+	if (pol->flags & MPOL_F_PRIVATE_NODES)
+		return;
 	mpol_rebindable_mems(&mems, newmask);
 	if (!mpol_store_user_nodemask(pol) &&
 	    nodes_equal(pol->w.cpuset_mems_allowed, mems))
@@ -1587,6 +1601,21 @@ static long do_mbind(unsigned long start, unsigned long len,
 	if (err)
 		goto mpol_out;
 
+	/* Private nodes cannot hold HugeTLB pages; this is unsupported. */
+	if (new && (new->flags & MPOL_F_PRIVATE_NODES)) {
+		vma_iter_init(&vmi, mm, start);
+		for_each_vma_range(vmi, vma, end) {
+			if (vma_is_hugetlb(vma)) {
+				err = -EINVAL;
+				break;
+			}
+		}
+		if (err) {
+			mmap_write_unlock(mm);
+			goto mpol_out;
+		}
+	}
+
 	/*
 	 * Lock the VMAs before scanning for pages to migrate,
 	 * to ensure we don't miss a concurrently inserted page.
@@ -1771,6 +1800,11 @@ static inline int sanitize_mpol_flags(int *mode, unsigned short *flags)
 		return -EINVAL;
 	if ((*flags & MPOL_F_STATIC_NODES) && (*flags & MPOL_F_RELATIVE_NODES))
 		return -EINVAL;
+	/* A private binding is never rebound or balanced. */
+	if ((*flags & MPOL_F_PRIVATE_NODES) &&
+	    (*mode != MPOL_BIND ||
+	     (*flags & (MPOL_USER_NODEMASK_FLAGS | MPOL_F_NUMA_BALANCING))))
+		return -EINVAL;
 	if (*flags & MPOL_F_NUMA_BALANCING) {
 		if (*mode == MPOL_BIND || *mode == MPOL_PREFERRED_MANY)
 			*flags |= (MPOL_F_MOF | MPOL_F_MORON);
@@ -1851,6 +1885,11 @@ SYSCALL_DEFINE4(set_mempolicy_home_node, unsigned long, start, unsigned long, le
 			err = -EOPNOTSUPP;
 			break;
 		}
+		if ((old->flags & MPOL_F_PRIVATE_NODES) &&
+		    !node_isset(home_node, old->nodes)) {
+			err = -EINVAL;
+			break;
+		}
 		new = mpol_dup(old);
 		if (IS_ERR(new)) {
 			err = PTR_ERR(new);
@@ -1888,6 +1927,10 @@ static long kernel_set_mempolicy(int mode, const unsigned long __user *nmask,
 	if (err)
 		return err;
 
+	/* A task policy also steers the task's kernel allocations. */
+	if (mode_flags & MPOL_F_PRIVATE_NODES)
+		return -EINVAL;
+
 	err = get_nodes(&nodes, nmask, maxnode);
 	if (err)
 		return err;
@@ -2124,7 +2167,8 @@ bool apply_policy_zone(struct mempolicy *policy, enum zone_type zone)
 	 * if policy->nodes has movable memory only,
 	 * we apply policy when gfp_zone(gfp) = ZONE_MOVABLE only.
 	 *
-	 * policy->nodes is intersect with node_states[N_MEMORY_COMMON].
+	 * policy->nodes is intersect with node_states[N_MEMORY_COMMON], or with
+	 * the private N_MEMORY_MEMPOLICY nodes for MPOL_F_PRIVATE_NODES.
 	 * so if the following test fails, it implies
 	 * policy->nodes has movable memory only.
 	 */
@@ -2495,10 +2539,20 @@ static struct page *alloc_pages_preferred_many(gfp_t gfp, unsigned int order,
 static struct page *alloc_pages_mpol(gfp_t gfp, unsigned int order,
 		struct mempolicy *pol, pgoff_t ilx, int nid)
 {
+	unsigned int alloc_flags = ALLOC_DEFAULT;
 	nodemask_t *nodemask;
 	struct page *page;
 
 	nodemask = policy_nodemask(gfp, pol, ilx, &nid);
+	if (nodemask && (pol->flags & MPOL_F_PRIVATE_NODES)) {
+		int private_nid = first_node(*nodemask);
+
+		if (node_state(private_nid, N_MEMORY_MEMPOLICY) &&
+		    node_state(private_nid, N_MEMORY_PRIVATE)) {
+			nid = private_nid;
+			alloc_flags = ALLOC_ZONELIST_PRIVATE;
+		}
+	}
 
 	if (pol->mode == MPOL_PREFERRED_MANY)
 		return alloc_pages_preferred_many(gfp, order, nid, nodemask);
@@ -2520,24 +2574,26 @@ static struct page *alloc_pages_mpol(gfp_t gfp, unsigned int order,
 		    pol->mode != MPOL_WEIGHTED_INTERLEAVE &&
 		    (!nodemask || node_isset(nid, *nodemask))) {
 			/*
-			 * First, try to allocate THP only on local node, but
+			 * First, try to allocate THP only on the selected node, but
 			 * don't reclaim unnecessarily, just compact.
 			 */
 			page = __alloc_frozen_pages_noprof(
 				gfp | __GFP_THISNODE | __GFP_NORETRY, order,
-				nid, NULL, ALLOC_DEFAULT);
+				nid, (alloc_flags & ALLOC_ZONELIST_PRIVATE) ?
+					 nodemask : NULL, alloc_flags);
 			if (page || !(gfp & __GFP_DIRECT_RECLAIM))
 				return page;
 			/*
 			 * If hugepage allocations are configured to always
 			 * synchronous compact or the vma has been madvised
 			 * to prefer hugepage backing, retry allowing remote
-			 * memory with both reclaim and compact as well.
+			 * memory with both reclaim and compact as well. A
+			 * private binding stays on its local zonelist.
 			 */
 		}
 	}
 
-	page = __alloc_frozen_pages_noprof(gfp, order, nid, nodemask, ALLOC_DEFAULT);
+	page = __alloc_frozen_pages_noprof(gfp, order, nid, nodemask, alloc_flags);
 
 	if (unlikely(pol->mode == MPOL_INTERLEAVE ||
 		     pol->mode == MPOL_WEIGHTED_INTERLEAVE) && page) {
@@ -3651,12 +3707,14 @@ void mpol_to_str(char *buffer, int maxlen, struct mempolicy *pol)
 		p += snprintf(p, buffer + maxlen - p, "=");
 
 		/*
-		 * Static and relative are mutually exclusive.
+		 * Static, relative and private are mutually exclusive.
 		 */
 		if (flags & MPOL_F_STATIC_NODES)
 			p += snprintf(p, buffer + maxlen - p, "static");
 		else if (flags & MPOL_F_RELATIVE_NODES)
 			p += snprintf(p, buffer + maxlen - p, "relative");
+		else if (flags & MPOL_F_PRIVATE_NODES)
+			p += snprintf(p, buffer + maxlen - p, "private");
 
 		if (flags & MPOL_F_NUMA_BALANCING) {
 			if (!is_power_of_2(flags & MPOL_MODE_FLAGS))

-- 
2.56.1

