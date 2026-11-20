From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:20 -0500
Subject: [PATCH 29/60] mm: keep private memory out of the system memory
 totals
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-29-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198153; l=7541;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=8jD4gdJ7f9IthJ+W65OhuvHMjSc7pf2CPG7wZM7sxhA=;
 b=WALF1SEszBgHGduONGSRsLszrM9vdU14F2BXkDNGsxMux4GtiPUn1jCBsOIJG94Sncocj518V
 +J8LFEBQrN1AkkVDHSuBdmtjq0kHaikaGd0FRxFUM7hg22oUR9ppnh1
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

totalram_pages() (MemTotal) counts every managed page, and MemFree
counts every free page, including private memory.

Many limits and defaults are sized from totalram_pages():
  - the overcommit limit
  - OOM capacity
  - tmpfs
  - zswap defaults
  - others

Private memory is not usable by ordinary allocations, so it should
not inflate these counts.

Count only general purpose memory in totalram_pages() and
nr_free_pages(). For now general purpose memory is common memory.

The two must agree because some callers (files_maxfiles_init()) use
their difference as used memory. A node's features cannot change while
it has memory, so counting each node by its features keeps the total
exact.

Several readers use NR_FREE_PAGES directly with the intent of getting
the general purpose memory count:
 - overcommit reserve defaults
 - DAMON's free-memory metrics
 - dirty limits
 - MemAvailable

Switch them to nr_free_pages() as well.

The vmstat counters and per-node meminfo still count private memory.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 include/linux/swap.h |  4 ++--
 mm/damon/core.c      |  5 +++--
 mm/internal.h        |  7 +++++++
 mm/mmap.c            |  6 +++---
 mm/nommu.c           |  4 ++--
 mm/page-writeback.c  |  2 +-
 mm/page_alloc.c      |  3 ++-
 mm/show_mem.c        | 20 ++++++++++++++++++--
 8 files changed, 38 insertions(+), 13 deletions(-)

diff --git a/include/linux/swap.h b/include/linux/swap.h
index 4f686709d71f..fe7eb13385a0 100644
--- a/include/linux/swap.h
+++ b/include/linux/swap.h
@@ -308,8 +308,8 @@ static inline swp_entry_t folio_page_swap_entry(const struct folio *folio,
 /* linux/mm/page_alloc.c */
 extern unsigned long totalreserve_pages;
 
-/* Definition of global_zone_page_state not available yet */
-#define nr_free_pages() global_zone_page_state(NR_FREE_PAGES)
+/* linux/mm/show_mem.c */
+unsigned long nr_free_pages(void);
 
 /* linux/mm/folio.c */
 void folio_add_lru(struct folio *folio);
diff --git a/mm/damon/core.c b/mm/damon/core.c
index 986404b547eb..3eec5a17b5e4 100644
--- a/mm/damon/core.c
+++ b/mm/damon/core.c
@@ -10,6 +10,7 @@
 #include <linux/kthread.h>
 #include <linux/memcontrol.h>
 #include <linux/mm.h>
+#include <linux/swap.h>
 #include <linux/pid.h>
 #include <linux/psi.h>
 #include <linux/sched.h>
@@ -3229,7 +3230,7 @@ static unsigned int damos_hugepage_mem_bp(void)
 	unsigned long thp, total_pages, free_pages;
 
 	total_pages = totalram_pages();
-	free_pages = global_zone_page_state(NR_FREE_PAGES);
+	free_pages = nr_free_pages();
 
 	if (total_pages <= free_pages)
 		return 10000;
@@ -3867,7 +3868,7 @@ static int damos_get_wmark_metric_value(enum damos_wmark_metric metric,
 {
 	switch (metric) {
 	case DAMOS_WMARK_FREE_MEM_RATE:
-		*metric_value = global_zone_page_state(NR_FREE_PAGES) * 1000 /
+		*metric_value = nr_free_pages() * 1000 /
 		       totalram_pages();
 		return 0;
 	default:
diff --git a/mm/internal.h b/mm/internal.h
index e89dd1153662..9c162ded5305 100644
--- a/mm/internal.h
+++ b/mm/internal.h
@@ -779,6 +779,13 @@ void set_recommended_min_free_kbytes(void);
 
 extern char * const zone_names[MAX_NR_ZONES];
 
+/* true if the node is capable of servicing general system allocations */
+static inline bool node_memory_is_general_purpose(int nid)
+{
+	return READ_ONCE(NODE_DATA(nid)->memory_features) &
+	       NODE_MEMORY_FEAT_COMMON;
+}
+
 extern int min_free_kbytes;
 extern int defrag_mode;
 
diff --git a/mm/mmap.c b/mm/mmap.c
index 7618e72766a5..091d67f82221 100644
--- a/mm/mmap.c
+++ b/mm/mmap.c
@@ -1567,7 +1567,7 @@ static int init_user_reserve(void)
 {
 	unsigned long free_kbytes;
 
-	free_kbytes = K(global_zone_page_state(NR_FREE_PAGES));
+	free_kbytes = K(nr_free_pages());
 
 	sysctl_user_reserve_kbytes = min(free_kbytes / 32, SZ_128K);
 	return 0;
@@ -1588,7 +1588,7 @@ static int init_admin_reserve(void)
 {
 	unsigned long free_kbytes;
 
-	free_kbytes = K(global_zone_page_state(NR_FREE_PAGES));
+	free_kbytes = K(nr_free_pages());
 
 	sysctl_admin_reserve_kbytes = min(free_kbytes / 32, SZ_8K);
 	return 0;
@@ -1632,7 +1632,7 @@ static int reserve_mem_notifier(struct notifier_block *nb,
 
 		break;
 	case MEM_OFFLINE:
-		free_kbytes = K(global_zone_page_state(NR_FREE_PAGES));
+		free_kbytes = K(nr_free_pages());
 
 		if (sysctl_user_reserve_kbytes > free_kbytes) {
 			init_user_reserve();
diff --git a/mm/nommu.c b/mm/nommu.c
index df99495c8902..a6f70c5d9ec8 100644
--- a/mm/nommu.c
+++ b/mm/nommu.c
@@ -1858,7 +1858,7 @@ static int __meminit init_user_reserve(void)
 {
 	unsigned long free_kbytes;
 
-	free_kbytes = K(global_zone_page_state(NR_FREE_PAGES));
+	free_kbytes = K(nr_free_pages());
 
 	sysctl_user_reserve_kbytes = min(free_kbytes / 32, 1UL << 17);
 	return 0;
@@ -1879,7 +1879,7 @@ static int __meminit init_admin_reserve(void)
 {
 	unsigned long free_kbytes;
 
-	free_kbytes = K(global_zone_page_state(NR_FREE_PAGES));
+	free_kbytes = K(nr_free_pages());
 
 	sysctl_admin_reserve_kbytes = min(free_kbytes / 32, 1UL << 13);
 	return 0;
diff --git a/mm/page-writeback.c b/mm/page-writeback.c
index 5939f781fc54..00293a64fcea 100644
--- a/mm/page-writeback.c
+++ b/mm/page-writeback.c
@@ -317,7 +317,7 @@ static unsigned long global_dirtyable_memory(void)
 {
 	unsigned long x;
 
-	x = global_zone_page_state(NR_FREE_PAGES);
+	x = nr_free_pages();
 	/*
 	 * Pages reserved for the kernel should not be considered
 	 * dirtyable, to prevent a situation where reclaim has to
diff --git a/mm/page_alloc.c b/mm/page_alloc.c
index 3a7c12fec906..0a5176a6e9db 100644
--- a/mm/page_alloc.c
+++ b/mm/page_alloc.c
@@ -6513,7 +6513,8 @@ static void setup_per_zone_lowmem_reserve(void);
 void adjust_managed_page_count(struct page *page, long count)
 {
 	atomic_long_add(count, &page_zone(page)->managed_pages);
-	totalram_pages_add(count);
+	if (node_memory_is_general_purpose(page_to_nid(page)))
+		totalram_pages_add(count);
 	setup_per_zone_lowmem_reserve();
 }
 EXPORT_SYMBOL(adjust_managed_page_count);
diff --git a/mm/show_mem.c b/mm/show_mem.c
index b938cbcd774a..b90fb5a0016b 100644
--- a/mm/show_mem.c
+++ b/mm/show_mem.c
@@ -45,7 +45,7 @@ long si_mem_available(void)
 	 * Estimate the amount of memory available for userspace allocations,
 	 * without causing swapping or OOM.
 	 */
-	available = global_zone_page_state(NR_FREE_PAGES) - totalreserve_pages;
+	available = nr_free_pages() - totalreserve_pages;
 
 	/*
 	 * Not all the page cache can be freed, otherwise the system will
@@ -73,11 +73,27 @@ long si_mem_available(void)
 }
 EXPORT_SYMBOL_GPL(si_mem_available);
 
+/* Free pages of general-purpose memory, the memory totalram_pages() counts. */
+unsigned long nr_free_pages(void)
+{
+	unsigned long nr = global_zone_page_state(NR_FREE_PAGES);
+	int nid;
+
+	if (!IS_ENABLED(CONFIG_NUMA))
+		return nr;
+
+	for_each_node_state(nid, N_MEMORY_PRIVATE) {
+		if (!node_memory_is_general_purpose(nid))
+			nr -= min(nr, sum_zone_node_page_state(nid, NR_FREE_PAGES));
+	}
+	return nr;
+}
+
 void si_meminfo(struct sysinfo *val)
 {
 	val->totalram = totalram_pages();
 	val->sharedram = global_node_page_state(NR_SHMEM);
-	val->freeram = global_zone_page_state(NR_FREE_PAGES);
+	val->freeram = nr_free_pages();
 	val->bufferram = nr_blockdev_pages();
 	val->totalhigh = totalhigh_pages();
 	val->freehigh = nr_free_highpages();

-- 
2.56.1

