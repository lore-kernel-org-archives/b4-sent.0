From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:25 -0500
Subject: [PATCH 34/60] mm/mempolicy: don't rebind policies onto private
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-34-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198153; l=3916;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=O4sFHAoLYcMEsR+pbprmEIIYrOpT4VdUvGorp6JE4oo=;
 b=++1ya54kNulohMUVhkDNAIgSodP5iBDwFFCmWjVnOGU1NsRveo/lx1Jce0OpvaUnLUmZ7pT/r
 w52A5nrqjOZA3Cb2wKDaNK6almrCmCp5wMfSWBDh7BzHHpTEwgkoGoQ
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A cpuset can allow private nodes, and rebinding a policy to a new cpuset
mask can move its nodes onto them:
  - a static policy reapplies the raw user mask.
  - relative and remapped policies follow node positions in the cpuset
    mask.

Ordinary policies cannot use private nodes.

Rebind policies over the cpuset's nodes other than private ones, and
record the remap base the same way, so adding or removing a private node
moves no policy.

Cpusets keep common memory in every effective mask, so a mask with no
node left is a bug. Warn, and keep the whole mask rather than leave the
policy empty.

On systems without a private node, rebinding is unchanged.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 mm/mempolicy.c | 42 ++++++++++++++++++++++++++++++------------
 1 file changed, 30 insertions(+), 12 deletions(-)

diff --git a/mm/mempolicy.c b/mm/mempolicy.c
index e208018499d6..81ccc481cea1 100644
--- a/mm/mempolicy.c
+++ b/mm/mempolicy.c
@@ -418,6 +418,18 @@ static int mpol_new_preferred(struct mempolicy *pol, const nodemask_t *nodes)
 	return 0;
 }
 
+/*
+ * Policies are rebound over the cpuset's nodes other than private ones. A node
+ * removed since the remap base was recorded keeps its position.
+ */
+static void mpol_rebindable_mems(nodemask_t *dst, const nodemask_t *nodes)
+{
+	nodes_andnot(*dst, *nodes, node_states[N_MEMORY_PRIVATE]);
+	/* Cpusets keep common memory in every effective mask. */
+	if (WARN_ON_ONCE(nodes_empty(*dst)))
+		*dst = *nodes;
+}
+
 /*
  * mpol_set_nodemask is called after mpol_new() to set up the nodemask, if
  * any, for the new policy.  mpol_new() has already validated the nodes
@@ -453,7 +465,8 @@ static int mpol_set_nodemask(struct mempolicy *pol,
 	if (mpol_store_user_nodemask(pol))
 		pol->w.user_nodemask = *nodes;
 	else
-		pol->w.cpuset_mems_allowed = cpuset_current_mems_allowed;
+		mpol_rebindable_mems(&pol->w.cpuset_mems_allowed,
+				     &cpuset_current_mems_allowed);
 
 	ret = mpol_ops[pol->mode].create(pol, &nsc->mask2);
 	return ret;
@@ -528,20 +541,22 @@ static void mpol_rebind_default(struct mempolicy *pol, const nodemask_t *nodes)
 
 static void mpol_rebind_nodemask(struct mempolicy *pol, const nodemask_t *nodes)
 {
-	nodemask_t tmp;
+	nodemask_t tmp, allowed;
+
+	mpol_rebindable_mems(&allowed, nodes);
 
-	if (pol->flags & MPOL_F_STATIC_NODES)
-		nodes_and(tmp, pol->w.user_nodemask, *nodes);
-	else if (pol->flags & MPOL_F_RELATIVE_NODES)
-		mpol_relative_nodemask(&tmp, &pol->w.user_nodemask, nodes);
-	else {
+	if (pol->flags & MPOL_F_STATIC_NODES) {
+		nodes_and(tmp, pol->w.user_nodemask, allowed);
+	} else if (pol->flags & MPOL_F_RELATIVE_NODES) {
+		mpol_relative_nodemask(&tmp, &pol->w.user_nodemask, &allowed);
+	} else {
 		nodes_remap(tmp, pol->nodes, pol->w.cpuset_mems_allowed,
-								*nodes);
-		pol->w.cpuset_mems_allowed = *nodes;
+			    allowed);
+		pol->w.cpuset_mems_allowed = allowed;
 	}
 
 	if (nodes_empty(tmp))
-		tmp = *nodes;
+		tmp = allowed;
 
 	pol->nodes = tmp;
 }
@@ -549,7 +564,7 @@ static void mpol_rebind_nodemask(struct mempolicy *pol, const nodemask_t *nodes)
 static void mpol_rebind_preferred(struct mempolicy *pol,
 						const nodemask_t *nodes)
 {
-	pol->w.cpuset_mems_allowed = *nodes;
+	mpol_rebindable_mems(&pol->w.cpuset_mems_allowed, nodes);
 }
 
 /*
@@ -561,10 +576,13 @@ static void mpol_rebind_preferred(struct mempolicy *pol,
  */
 static void mpol_rebind_policy(struct mempolicy *pol, const nodemask_t *newmask)
 {
+	nodemask_t mems;
+
 	if (!pol || pol->mode == MPOL_LOCAL)
 		return;
+	mpol_rebindable_mems(&mems, newmask);
 	if (!mpol_store_user_nodemask(pol) &&
-	    nodes_equal(pol->w.cpuset_mems_allowed, *newmask))
+	    nodes_equal(pol->w.cpuset_mems_allowed, mems))
 		return;
 
 	mpol_ops[pol->mode].rebind(pol, newmask);

-- 
2.56.1

