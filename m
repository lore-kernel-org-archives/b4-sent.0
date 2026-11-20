From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:30 -0500
Subject: [PATCH 39/60] mm/page_alloc: add a private-node zonelist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-39-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198153; l=3134;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=OqpMdBUt5im1cMgZFE5X+fZAbGJWYU6WcOHKkFwuS9o=;
 b=o/dYXsRSD+kDIMnUJjWNiDdysIiPZ9AEs4oJxtAad9XJMPtLlNyz+nTDlkBw/SrIIzFQ8NEmg
 Q5LoNu0vSTqCQh8ZHl/nPuFBHXZVGMqF4GQxX08YQa6pADhhTLCJq4v
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A private node carries N_MEMORY without N_MEMORY_COMMON, so the FALLBACK
and NOFALLBACK zonelists already exclude it. That leaves no zonelist
that can reach it.

Add ZONELIST_PRIVATE, which holds a node's local zones only if the node
is private. Common nodes have an empty private zonelist.

Like the existing zonelists, it is sized for every zone of every node.
That adds a zoneref (16 bytes on 64-bit) per possible zone, MAX_NUMNODES
* MAX_NR_ZONES, to each pgdat. A smaller local-only zonelist type can be
a follow-up if this matters.

When the zonelist becomes selectable, __GFP_THISNODE will still suppress
OOM, while the page allocator selects the private zonelist instead of
NOFALLBACK.

If a user grows requiring fallback behavior to COMMON nodes when the
private node is out of memory, we can consider adding a fallback
variant - but for now private node allocations use a local-only
zonelist to limit complexity.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 include/linux/mmzone.h | 5 +++--
 mm/mm_init.c           | 5 +++--
 mm/page_alloc.c        | 2 ++
 3 files changed, 8 insertions(+), 4 deletions(-)

diff --git a/include/linux/mmzone.h b/include/linux/mmzone.h
index d6c1a43c0bc8..05f212b56c9d 100644
--- a/include/linux/mmzone.h
+++ b/include/linux/mmzone.h
@@ -1402,10 +1402,11 @@ enum {
 	ZONELIST_FALLBACK,	/* zonelist with fallback */
 #ifdef CONFIG_NUMA
 	/*
-	 * The NUMA zonelists are doubled because we need zonelists that
-	 * restrict the allocations to a single node for __GFP_THISNODE.
+	 * NUMA nodes also have local-only zonelists that restrict allocations
+	 * to a single node, for __GFP_THISNODE and for private-node access.
 	 */
 	ZONELIST_NOFALLBACK,	/* zonelist without fallback (__GFP_THISNODE) */
+	ZONELIST_PRIVATE,	/* local private-node access, no fallback */
 #endif
 	MAX_ZONELISTS
 };
diff --git a/mm/mm_init.c b/mm/mm_init.c
index 99a45fd04ac5..a6ff49043b5c 100644
--- a/mm/mm_init.c
+++ b/mm/mm_init.c
@@ -99,7 +99,8 @@ void __init mminit_verify_zonelist(void)
 
 			/* Print information about the zonelist */
 			printk(KERN_DEBUG "mminit::zonelist %s %d:%s = ",
-				listid > 0 ? "thisnode" : "general", nid,
+				listid == 0 ? "general" :
+				listid == 1 ? "thisnode" : "private", nid,
 				zone->name);
 
 			/* Iterate the zonelist */
@@ -2706,7 +2707,7 @@ void __init mm_core_init(void)
 	init_zero_page_pfn();
 
 	/* Initializations relying on SMP setup */
-	BUILD_BUG_ON(MAX_ZONELISTS > 2);
+	BUILD_BUG_ON(MAX_ZONELISTS > 3);
 	build_all_zonelists(NULL);
 	page_alloc_init_cpuhp();
 	alloc_tag_sec_init();
diff --git a/mm/page_alloc.c b/mm/page_alloc.c
index 08e57f809a03..0bd21916cea1 100644
--- a/mm/page_alloc.c
+++ b/mm/page_alloc.c
@@ -6010,6 +6010,8 @@ static void build_zonelists(pg_data_t *pgdat)
 			    ZONELIST_FALLBACK);
 	build_local_zonelist(pgdat, ZONELIST_NOFALLBACK,
 			     node_state(nid, N_MEMORY_COMMON));
+	build_local_zonelist(pgdat, ZONELIST_PRIVATE,
+			     node_state(nid, N_MEMORY_PRIVATE));
 }
 
 #ifdef CONFIG_HAVE_MEMORYLESS_NODES

-- 
2.56.1

