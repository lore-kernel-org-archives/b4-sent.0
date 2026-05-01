From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:12 +0800
Subject: [PATCH RFC 26/32] mm/workingset: properly define the format of a
 folio shadow
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-26-913619b014d9@tencent.com>
References: <20260502-mglru-fg-v1-0-913619b014d9@tencent.com>
In-Reply-To: <20260502-mglru-fg-v1-0-913619b014d9@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Youngjun Park <youngjun.park@lge.com>, 
 Zi Yan <ziy@nvidia.com>, Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Nico Pache <npache@redhat.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SeongJae Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, 
 Chen Ridong <chenridong@huaweicloud.com>, Tal Zussman <tz2294@columbia.edu>, 
 Kairui Song <ryncsn@gmail.com>, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=6409;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=BHsPRvLdIXuKL3/5pLqvcCuBLzJEpjMu3hI5uV7aekI=;
 b=AcTOgAnvvy963ARcizG0u5Uont1pyDQrOxeIwl5U9ZU8DRZnP0MT4tUKr19pgaGqHDFeirdzz
 XLtUak8Rg5sBgd6KvulitmR+E8YDSYWip1TC4e5UormFnuF5hLwTJ2u
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The shadow of an evicted folio can be roughly divided into two parts:

- The common and mandatory pack info: which contains the memcg info,
  workingset bit, and pgdat.
- LRU specific eviction info: which is a "timestamp" for Active/Inactive
  LRU, and generation sequence for MGLRU.

The common pack part is the same for both Active/Inactive and MGLRU, and
the data stored presents the exact information. Meanwhile, the eviction
info part could be truncated, which is OK since the eviction info is
just a hint for LRU to determine what to do with a refaulted folio, and
in the worst case, only has a limited effect on the system's
performance.

Add some comments on this, and consolidate the macros for these two
parts.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/workingset.c | 61 +++++++++++++++++++++++++++++++++++++--------------------
 1 file changed, 40 insertions(+), 21 deletions(-)

diff --git a/mm/workingset.c b/mm/workingset.c
index b472ac34943e..622e00ac28b6 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -184,13 +184,35 @@
  * refault distance will immediately activate the refaulting page.
  */
 
-#define WORKINGSET_SHIFT 1
-#define EVICTION_SHIFT	((BITS_PER_LONG - BITS_PER_XA_VALUE) +	\
-			 WORKINGSET_SHIFT + NODES_SHIFT + \
-			 MEM_CGROUP_ID_SHIFT)
-#define EVICTION_SHIFT_ANON	(EVICTION_SHIFT + SWAP_COUNT_SHIFT)
-#define EVICTION_MASK	(~0UL >> EVICTION_SHIFT)
-#define EVICTION_MASK_ANON	(~0UL >> EVICTION_SHIFT_ANON)
+/*
+ * Active/Inactive LRU, MGLRU have different info embedded in the shadow.
+ * Shadow format:
+ *                   /     LRU Eviction Info    \ / LRU Pack Info \
+ *                  +----------------------------+----------------+-+
+ * non-MGLRU:       |SC|   eviction timestamp    | NID | MCID | W |1|
+ * MGLRU:           |SC|     seq number   | refs | NID | MCID | W |1|
+ *                   ^                              ^      ^    ^  ^
+ *    Swap Count (anon only)  NUMA ID (NODES_SHIFT)-+      |    | XA_VALUE
+ *          Memory Cgroup ID (MEM_CGROUP_ID_SHIFT) --------+    | mark
+ *                    Workingset Bit (WORKINGSET_SHIFT) --------+
+ *
+ * Shadow is a XA_VALUE, 63 / 31 bits are usable.
+ *
+ * The LRU pack info part is used to identify which lruvec a folio was
+ * evicted from. This part is always accurate so we never lose the
+ * basic track of faults on each lruvec.
+ *
+ * Eviction info is either a snapshot of the `evictions` counter of an
+ * lruvec when the folio was evicted (lru timestamp, for active/inactive
+ * LRU), or the min_seq number when the folio was evicted (MGLRU). This
+ * part may have shrunk, so we may get inaccurate info, which is usually
+ * fine and could be tolerated.
+ */
+#define WORKINGSET_SHIFT	1
+#define LRU_PACK_BITS		(NODES_SHIFT + MEM_CGROUP_ID_SHIFT + \
+				 WORKINGSET_SHIFT)
+#define LRU_EVICT_BITS		(BITS_PER_XA_VALUE - LRU_PACK_BITS)
+#define LRU_EVICT_BITS_ANON	(LRU_EVICT_BITS - SWAP_COUNT_SHIFT)
 
 /*
  * LRU refs uses LRU_REFS_WIDTH + 2 bits, the 2 bits are PG_workingset and
@@ -212,7 +234,9 @@ static unsigned int bucket_order[ANON_AND_FILE] __read_mostly;
 static void *pack_shadow(int memcgid, pg_data_t *pgdat, unsigned long eviction,
 			 bool workingset, bool file)
 {
-	eviction &= file ? EVICTION_MASK : EVICTION_MASK_ANON;
+	BUILD_BUG_ON(LRU_EVICT_BITS_ANON <= SWAP_COUNT_SHIFT);
+
+	eviction &= BIT(file ? LRU_EVICT_BITS : LRU_EVICT_BITS_ANON) - 1;
 	eviction = (eviction << MEM_CGROUP_ID_SHIFT) | memcgid;
 	eviction = (eviction << NODES_SHIFT) | pgdat->node_id;
 	eviction = (eviction << WORKINGSET_SHIFT) | workingset;
@@ -257,8 +281,7 @@ static void *lru_gen_eviction(struct folio *folio)
 	struct pglist_data *pgdat = folio_pgdat(folio);
 	unsigned short memcg_id;
 
-	BUILD_BUG_ON(LRU_GEN_WIDTH + LRU_REFS_BITS >
-		     BITS_PER_LONG - max(EVICTION_SHIFT, EVICTION_SHIFT_ANON));
+	BUILD_BUG_ON(LRU_GEN_WIDTH + LRU_REFS_BITS > LRU_EVICT_BITS_ANON);
 
 	rcu_read_lock();
 	memcg = folio_memcg(folio);
@@ -284,7 +307,7 @@ static bool lru_gen_test_recent(struct lruvec *lruvec,
 	unsigned long max_seq;
 
 	max_seq = READ_ONCE((lruvec)->lrugen.max_seq);
-	max_seq &= (file ? EVICTION_MASK : EVICTION_MASK_ANON) >> LRU_REFS_BITS;
+	max_seq &= BIT((file ? LRU_EVICT_BITS : LRU_EVICT_BITS_ANON) - LRU_REFS_BITS) - 1;
 
 	return abs_diff(max_seq, token >> LRU_REFS_BITS) < MAX_NR_GENS;
 }
@@ -512,7 +535,7 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 	 */
 	eviction <<= bucket_order[file];
 	distance = ((refault - eviction) &
-		    (file ? EVICTION_MASK : EVICTION_MASK_ANON));
+		    (BIT(file ? LRU_EVICT_BITS : LRU_EVICT_BITS_ANON) - 1));
 
 	/*
 	 * Compare the distance to the existing workingset size. We
@@ -781,12 +804,10 @@ static struct lock_class_key shadow_nodes_key;
 
 static int __init workingset_init(void)
 {
-	unsigned int timestamp_bits, timestamp_bits_anon;
 	struct shrinker *workingset_shadow_shrinker;
 	unsigned int max_order;
 	int ret = -ENOMEM;
 
-	BUILD_BUG_ON(BITS_PER_LONG < EVICTION_SHIFT);
 	/*
 	 * Calculate the eviction bucket size to cover the longest
 	 * actionable refault distance, which is currently half of
@@ -794,15 +815,13 @@ static int __init workingset_init(void)
 	 * some more pages at runtime, so keep working with up to
 	 * double the initial memory by using totalram_pages as-is.
 	 */
-	timestamp_bits = BITS_PER_LONG - EVICTION_SHIFT;
-	timestamp_bits_anon = BITS_PER_LONG - EVICTION_SHIFT_ANON;
 	max_order = fls_long(totalram_pages() - 1);
-	if (max_order > (BITS_PER_LONG - EVICTION_SHIFT))
-		bucket_order[WORKINGSET_FILE] = max_order - timestamp_bits;
-	if (max_order > timestamp_bits_anon)
-		bucket_order[WORKINGSET_ANON] = max_order - timestamp_bits_anon;
+	if (max_order > LRU_EVICT_BITS)
+		bucket_order[WORKINGSET_FILE] = max_order - LRU_EVICT_BITS;
+	if (max_order > LRU_EVICT_BITS_ANON)
+		bucket_order[WORKINGSET_ANON] = max_order - LRU_EVICT_BITS_ANON;
 	pr_info("workingset: timestamp_bits=%d (anon: %d) max_order=%d bucket_order=%u (anon: %d)\n",
-		timestamp_bits, timestamp_bits_anon, max_order,
+		LRU_EVICT_BITS, LRU_EVICT_BITS_ANON, max_order,
 		bucket_order[WORKINGSET_FILE], bucket_order[WORKINGSET_ANON]);
 
 	workingset_shadow_shrinker = shrinker_alloc(SHRINKER_NUMA_AWARE |

-- 
2.54.0

