From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:31 -0500
Subject: [PATCH 40/60] mm/page_alloc: let MM callers select the local
 private zonelist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-40-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198153; l=3868;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=npD7Fmno/ihvzONGk5Hl78WlKQtT973I2z2+au4TARw=;
 b=B+B4iyRjeprBqeAT8WfT6BHrv5fPRykSXQFs1sxCFnPlJtNmc6Rzehajvtbg2fl48qr5ckUeO
 TI31w3UdoXUBQoL6KmdQvmp7Vmy8aGnqUBf4brYww1HglkUBFrAUDZz
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ALLOC_ZONELIST_PRIVATE, which selects the local private zonelist
independently of __GFP_THISNODE.

__GFP_THISNODE still governs OOM behavior separately.

Allocations are otherwise still filtered by the task's cpuset, this
creates some quirks.

Reserve allocations normally drop the nodemask and the cpuset check.
A private request keeps both, since private memory has no reserves
to grant. A non-blocking __GFP_HIGH request still skips the cpuset
check, as it does for ordinary allocations.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 mm/page_alloc.c | 21 +++++++++++++++------
 mm/page_alloc.h | 15 +++++++++++++++
 2 files changed, 30 insertions(+), 6 deletions(-)

diff --git a/mm/page_alloc.c b/mm/page_alloc.c
index 0bd21916cea1..a219057931c3 100644
--- a/mm/page_alloc.c
+++ b/mm/page_alloc.c
@@ -4926,16 +4926,24 @@ __alloc_pages_slowpath(gfp_t gfp_mask, unsigned int order,
 		goto got_pg;
 
 	reserve_flags = __gfp_pfmemalloc_flags(gfp_mask);
-	if (reserve_flags)
+	if (reserve_flags) {
+		unsigned int keep = ALLOC_KSWAPD;
+
+		/* The cpuset still grants a private request's node. */
+		if (ac->alloc_flags & ALLOC_ZONELIST_PRIVATE)
+			keep |= ALLOC_CPUSET;
 		alloc_flags = alloc_flags_cma(gfp_mask) | reserve_flags |
-				ac->alloc_flags | (alloc_flags & ALLOC_KSWAPD);
+				ac->alloc_flags | (alloc_flags & keep);
+	}
 
 	/*
 	 * Reset the nodemask and zonelist iterators if memory policies can be
 	 * ignored. These allocations are high priority and system rather than
-	 * user oriented.
+	 * user oriented. A private request keeps its node: private memory has
+	 * no reserves to grant.
 	 */
-	if (!(alloc_flags & ALLOC_CPUSET) || reserve_flags) {
+	if ((!(alloc_flags & ALLOC_CPUSET) || reserve_flags) &&
+	    !(ac->alloc_flags & ALLOC_ZONELIST_PRIVATE)) {
 		ac->nodemask = NULL;
 		ac->preferred_zoneref = first_zones_zonelist(ac->zonelist,
 					ac->highest_zoneidx, ac->nodemask);
@@ -5164,7 +5172,7 @@ static inline bool prepare_alloc_pages(gfp_t gfp_mask, unsigned int order,
 		unsigned int *alloc_flags)
 {
 	ac->highest_zoneidx = gfp_zone(gfp_mask);
-	ac->zonelist = node_zonelist(preferred_nid, gfp_mask);
+	ac->zonelist = select_zonelist(preferred_nid, gfp_mask, *alloc_flags);
 	ac->nodemask = nodemask;
 	ac->migratetype = gfp_migratetype(gfp_mask);
 
@@ -5477,7 +5485,8 @@ struct page *__alloc_frozen_pages_noprof(gfp_t gfp, unsigned int order,
 	unsigned int zonelist_iter_cookie;
 
 	/* Other flags could be supported later if needed. */
-	if (WARN_ON(alloc_flags & ~(ALLOC_NOLOCK | ALLOC_NO_CODETAG)))
+	if (WARN_ON(alloc_flags & ~(ALLOC_NOLOCK | ALLOC_NO_CODETAG |
+				    ALLOC_ZONELIST_PRIVATE)))
 		return NULL;
 
 	if (!alloc_order_allowed(gfp, order, alloc_flags))
diff --git a/mm/page_alloc.h b/mm/page_alloc.h
index 917653ae14a3..c0a0e6abe4cd 100644
--- a/mm/page_alloc.h
+++ b/mm/page_alloc.h
@@ -56,6 +56,11 @@
  * alloc_tag_sub_check().
  */
 #define ALLOC_NO_CODETAG       0x1000
+#ifdef CONFIG_NUMA
+#define ALLOC_ZONELIST_PRIVATE 0x2000	/* use the local private zonelist */
+#else
+#define ALLOC_ZONELIST_PRIVATE 0x0
+#endif
 
 /* Flags that allow allocations below the min watermark. */
 #define ALLOC_RESERVES (ALLOC_MIN_RESERVE|ALLOC_HIGHATOMIC|ALLOC_OOM)
@@ -100,6 +105,16 @@ struct alloc_context {
 	unsigned int reclaim_compact_order;
 };
 
+static inline struct zonelist *
+select_zonelist(int nid, gfp_t gfp, unsigned int alloc_flags)
+{
+#ifdef CONFIG_NUMA
+	if (alloc_flags & ALLOC_ZONELIST_PRIVATE)
+		return &NODE_DATA(nid)->node_zonelists[ZONELIST_PRIVATE];
+#endif
+	return node_zonelist(nid, gfp);
+}
+
 /*
  * This function returns the order of a free page in the buddy system. In
  * general, page_zone(page)->lock must be held by the caller to prevent the

-- 
2.56.1

