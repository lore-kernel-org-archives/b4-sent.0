From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:43 -0500
Subject: [PATCH 52/60] mm: count memory with userspace placement as general
 purpose
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-52-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198154; l=4692;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=6RX//QZ0SKZV5TxlzdYhe/tOzKC4XmRnHwcFufstJ18=;
 b=NCTptt6/uCAZdwhyVmM2rpriQlBmZN9AxKQqG79yZ5rxdXd8RGciTmhOiPZUUECoSDy16oEFb
 Kbu7zu/nGUdCEINR6uXZJsSM2Z1tPpxQx5CroIpLspzccWRfbqKkHRl
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Userspace places ordinary data on N_MEMORY_MEMPOLICY nodes, and neither
the commit charge nor a task's RSS can tell nodes apart. Treat their
memory as general purpose: totalram_pages() and MemFree count it, and so
do the limits sized from them (overcommit, OOM capacity).

Other defaults sized from totalram_pages(), such as the zswap pool and
tmpfs sizes, also see the larger total, as they already do for memory
the kernel cannot allocate from in ZONE_MOVABLE.

Free memory on these nodes serves only private bindings and migration,
so counting it in MemAvailable or the global dirtyable memory would
overstate both. Add common_free_pages() and use it there.

MemAvailable also assumes about half of the file LRU can be reclaimed.
Reclaiming file pages on these nodes frees only private memory, so
count only the file LRU on common nodes, via common_file_pages().

File pages that reach a private node through migration stay covered
by the dirty limits' file LRU term.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 mm/internal.h       | 26 ++++++++++++++++++++++++--
 mm/page-writeback.c |  7 ++++++-
 mm/show_mem.c       | 24 ++++++++++++++++++++----
 3 files changed, 50 insertions(+), 7 deletions(-)

diff --git a/mm/internal.h b/mm/internal.h
index 4bac570bb29f..c83c100a5253 100644
--- a/mm/internal.h
+++ b/mm/internal.h
@@ -793,11 +793,33 @@ void set_recommended_min_free_kbytes(void);
 
 extern char * const zone_names[MAX_NR_ZONES];
 
-/* true if the node is capable of servicing general system allocations */
+/*
+ * true if the node is capable of servicing general system allocations or
+ * userspace directed allocations (mempolicy, migration)
+ */
 static inline bool node_memory_is_general_purpose(int nid)
 {
 	return READ_ONCE(NODE_DATA(nid)->memory_features) &
-	       NODE_MEMORY_FEAT_COMMON;
+	       NODE_MEMORY_FEAT_MEMPOLICY;
+}
+
+unsigned long common_free_pages(void);
+
+/* File LRU pages on common nodes, whose reclaim frees common memory. */
+static inline unsigned long common_file_pages(void)
+{
+	unsigned long nr = global_node_page_state(NR_ACTIVE_FILE) +
+			   global_node_page_state(NR_INACTIVE_FILE);
+	int nid;
+
+	if (!IS_ENABLED(CONFIG_NUMA))
+		return nr;
+
+	for_each_node_state(nid, N_MEMORY_PRIVATE) {
+		nr -= min(nr, node_page_state(NODE_DATA(nid), NR_ACTIVE_FILE) +
+			      node_page_state(NODE_DATA(nid), NR_INACTIVE_FILE));
+	}
+	return nr;
 }
 
 extern int min_free_kbytes;
diff --git a/mm/page-writeback.c b/mm/page-writeback.c
index 00293a64fcea..6181266bf159 100644
--- a/mm/page-writeback.c
+++ b/mm/page-writeback.c
@@ -317,7 +317,12 @@ static unsigned long global_dirtyable_memory(void)
 {
 	unsigned long x;
 
-	x = nr_free_pages();
+	/*
+	 * Free private memory serves only private bindings and migration.
+	 * File pages that reach private memory are counted with the file
+	 * LRU below.
+	 */
+	x = common_free_pages();
 	/*
 	 * Pages reserved for the kernel should not be considered
 	 * dirtyable, to prevent a situation where reclaim has to
diff --git a/mm/show_mem.c b/mm/show_mem.c
index 24dd33ba783b..de4769e06a53 100644
--- a/mm/show_mem.c
+++ b/mm/show_mem.c
@@ -46,17 +46,18 @@ long si_mem_available(void)
 
 	/*
 	 * Estimate the amount of memory available for userspace allocations,
-	 * without causing swapping or OOM.
+	 * without causing swapping or OOM. Only free common memory serves
+	 * ordinary allocations.
 	 */
-	available = nr_free_pages() - totalreserve_pages;
+	available = common_free_pages() - totalreserve_pages;
 
 	/*
 	 * Not all the page cache can be freed, otherwise the system will
 	 * start swapping or thrashing. Assume at least half of the page
 	 * cache, or the low watermark worth of cache, needs to stay.
 	 */
-	pagecache = global_node_page_state(NR_ACTIVE_FILE) +
-		global_node_page_state(NR_INACTIVE_FILE);
+	/* Reclaiming file pages on private nodes frees only private memory. */
+	pagecache = common_file_pages();
 	pagecache -= min(pagecache / 2, wmark_low);
 	available += pagecache;
 
@@ -92,6 +93,21 @@ unsigned long nr_free_pages(void)
 	return nr;
 }
 
+/* Free pages on common nodes, the free memory ordinary allocations can use. */
+unsigned long common_free_pages(void)
+{
+	unsigned long nr = global_zone_page_state(NR_FREE_PAGES);
+	int nid;
+
+	if (!IS_ENABLED(CONFIG_NUMA))
+		return nr;
+
+	for_each_node_state(nid, N_MEMORY_PRIVATE) {
+		nr -= min(nr, sum_zone_node_page_state(nid, NR_FREE_PAGES));
+	}
+	return nr;
+}
+
 void si_meminfo(struct sysinfo *val)
 {
 	val->totalram = totalram_pages();

-- 
2.56.1

