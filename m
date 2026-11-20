From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:34 -0500
Subject: [PATCH 43/60] mm/page_alloc: fall back when a bind policy's nodes
 become private
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-43-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198153; l=3943;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=MvCOuLTJrjpaTAmpn2Zbq/KX8f7RvrtAs1ipWbBROxM=;
 b=DVYzRbCZncJFfd8wmeRLbtBkyfuqBe2ViahLjuovjyvk17+NJApfRjBY2nJ50Ht7MFj0Mt9Nc
 RvcANV2Hfw5CWYGgF52KPf58f0DIBcx5qSTyz3t9oWeSeLKVo/t70CN
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Memory hotplug can make a node private after a bind policy naming it
was created. A static bind policy, a shared memory policy, or any bind
policy without cpusets is not rebound when the node's memory is
removed, so it still names the node when the node returns as private
memory.

The common zonelists hold no private node, so a policy naming only such
nodes leaves the allocation no zone to use. The nodemask still
intersects the cpuset, so check_retry_cpuset() keeps it, and a fault
through the policy is retried forever.

Let relax_private_alloc() treat a nodemask that names a private node
like a private request: once no node in the zonelist is in the nodemask
and allowed by the cpuset, drop the nodemask and allocate from common
memory. Only a request on the private zonelist keeps __GFP_THISNODE
strict.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 mm/page_alloc.c | 31 +++++++++++++++++++------------
 1 file changed, 19 insertions(+), 12 deletions(-)

diff --git a/mm/page_alloc.c b/mm/page_alloc.c
index ea48991ef589..b7339bc634d5 100644
--- a/mm/page_alloc.c
+++ b/mm/page_alloc.c
@@ -4078,16 +4078,20 @@ __alloc_pages_cpuset_fallback(gfp_t gfp_mask, unsigned int order,
 	return page;
 }
 
-/* A request on the private zonelist. */
+/* A private request, or a nodemask that names a private node. */
 static bool alloc_is_private(const struct alloc_context *ac)
 {
-	return ac->alloc_flags & ALLOC_ZONELIST_PRIVATE;
+	if (ac->alloc_flags & ALLOC_ZONELIST_PRIVATE)
+		return true;
+	return ac->nodemask &&
+	       nodes_intersects(*ac->nodemask, node_states[N_MEMORY_PRIVATE]);
 }
 
 /*
- * Whether a private request can still allocate: some node in its zonelist is
- * in its nodemask and allowed by the cpuset. Any zone type counts, so neither a
- * GFP zone restriction nor an exhausted node makes the request unsatisfiable.
+ * Whether a request that names private memory can still allocate: some node in
+ * its zonelist is in its nodemask and allowed by the cpuset. Any zone type
+ * counts, so neither a GFP zone restriction nor an exhausted node makes the
+ * request unsatisfiable.
  */
 static bool alloc_private_reachable(gfp_t gfp, const struct alloc_context *ac)
 {
@@ -4095,7 +4099,7 @@ static bool alloc_private_reachable(gfp_t gfp, const struct alloc_context *ac)
 	struct zone *zone;
 
 	/* A strict local private request keeps its allocation domain. */
-	if (gfp & __GFP_THISNODE)
+	if ((gfp & __GFP_THISNODE) && (ac->alloc_flags & ALLOC_ZONELIST_PRIVATE))
 		return true;
 
 	for_each_zone_zonelist_nodemask(zone, z, ac->zonelist, MAX_NR_ZONES - 1,
@@ -4819,10 +4823,11 @@ check_retry_cpuset(int cpuset_mems_cookie, struct alloc_context *ac)
 }
 
 /*
- * Relax a private request that can no longer allocate, because the cpuset
- * revoked its node or memory hotplug removed it. Drop the nodemask and allocate
- * from the common zonelist of the preferred node. Called after
- * check_retry_cpuset() and check_retry_zonelist() found no concurrent update.
+ * Relax a request that names private memory but can no longer allocate,
+ * because the cpuset revoked its node or memory hotplug removed it or made it
+ * private. Drop the nodemask and allocate from the common zonelist of the
+ * preferred node. Called after check_retry_cpuset() and check_retry_zonelist()
+ * found no concurrent update.
  */
 static bool relax_private_alloc(gfp_t gfp, struct alloc_context *ac)
 {
@@ -4830,8 +4835,10 @@ static bool relax_private_alloc(gfp_t gfp, struct alloc_context *ac)
 		return false;
 
 	ac->nodemask = NULL;
-	ac->alloc_flags &= ~ALLOC_ZONELIST_PRIVATE;
-	ac->zonelist = node_zonelist(ac->preferred_nid, gfp);
+	if (ac->alloc_flags & ALLOC_ZONELIST_PRIVATE) {
+		ac->alloc_flags &= ~ALLOC_ZONELIST_PRIVATE;
+		ac->zonelist = node_zonelist(ac->preferred_nid, gfp);
+	}
 	return true;
 }
 

-- 
2.56.1

