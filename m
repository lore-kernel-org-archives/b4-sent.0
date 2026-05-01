From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:16 +0800
Subject: [PATCH RFC 30/32] mm/mglru, workingset: apply refault-distance
 based re-activation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-30-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=9815;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=3SDg1UIwE2lOt/3QEIDXKbHVzTms1xk8wQaCfFECvFg=;
 b=IVyQkXaCapdKIeTGy01jKs/3iCm+Yy/0+bi99dDFnHITieJXGhW1YYpbViK7xMYWbGx8vZTm7
 ri+vMaIdqD0Ceelh1IhYMLmwcQ1jYrRjxSGiLndWjW7SCZTFXvN1zJV
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I noticed MGLRU not working very well on certain workflows, which is
observed on some heavily stressed databases. That is when the file
page workingset size exceeds total memory, and the access distance
of file pages also larger than total memory. All file pages could stuck
on the oldest generation and getting read-in then evicted permutably.
Despite anon pages being idle, they never get aged. PID controller
didn't kickin until there are some minor access pattern changes.
And file pages are not promoted or reused.

Even though the memory can't cover the whole workingset, the
refault-distance based re-activation can help hold part of the
workingset in-memory to help reduce the IO workload significantly.

So apply it for MGLRU as well. The updated refault-distance model
fits well for MGLRU in most cases, if we just consider the last two
generation as the inactive LRU and the first two generations as
active LRU.

Some adjustment is done to fit the logic better, also make the
refault-distance contributed to page tiering and PID refault detection
of MGLRU.

NOTE: This also changed the meaning of workingset_* fields in
/proc/vmstat.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/workingset.c | 116 +++++++++++++++++++++++++++++++++++++++-----------------
 1 file changed, 81 insertions(+), 35 deletions(-)

diff --git a/mm/workingset.c b/mm/workingset.c
index 5c52dd835a92..25a8eda233ef 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -190,7 +190,7 @@
  *                   /     LRU Eviction Info    \ / LRU Pack Info \
  *                  +----------------------------+----------------+-+
  * non-MGLRU:       |SC|   eviction timestamp    | NID | MCID | W |1|
- * MGLRU:           |SC|     seq number   | refs | NID | MCID | W |1|
+ * MGLRU:           |SC| refs|eviction timestamp | NID | MCID | W |1|
  *                   ^                              ^      ^    ^  ^
  *    Swap Count (anon only)  NUMA ID (NODES_SHIFT)-+      |    | XA_VALUE
  *          Memory Cgroup ID (MEM_CGROUP_ID_SHIFT) --------+    | mark
@@ -219,7 +219,9 @@
  * PG_referenced. But here we record PG_workingset separately (to reuse
  * pack_shadow).
  */
-#define LRU_REFS_BITS ((LRU_REFS_WIDTH + 2) - 1)
+#define LRU_REFS_BITS		((LRU_REFS_WIDTH + 2) - 1)
+#define LRU_GEN_EVICT_BITS	(LRU_EVICT_BITS - LRU_REFS_BITS)
+#define LRU_GEN_EVICT_BITS_ANON	(LRU_EVICT_BITS_ANON - LRU_REFS_BITS)
 
 /*
  * Eviction timestamps need to be able to cover the full range of
@@ -230,6 +232,7 @@
  * evictions into coarser buckets by shaving off lower timestamp bits.
  */
 static unsigned int bucket_order[ANON_AND_FILE] __read_mostly;
+static unsigned int lru_gen_bucket_order[ANON_AND_FILE] __read_mostly;
 
 static void *pack_shadow(int memcgid, pg_data_t *pgdat, unsigned long eviction,
 			 bool workingset, bool file)
@@ -392,7 +395,6 @@ static void *lru_gen_eviction(struct folio *folio)
 {
 	int hist;
 	unsigned long token;
-	unsigned long min_seq;
 	struct lruvec *lruvec;
 	struct lru_gen_folio *lrugen;
 	int type = folio_is_file_lru(folio);
@@ -403,16 +405,19 @@ static void *lru_gen_eviction(struct folio *folio)
 	struct pglist_data *pgdat = folio_pgdat(folio);
 	unsigned short memcg_id;
 
-	BUILD_BUG_ON(LRU_GEN_WIDTH + LRU_REFS_BITS > LRU_EVICT_BITS_ANON);
+	BUILD_BUG_ON(LRU_GEN_WIDTH + LRU_REFS_BITS > LRU_GEN_EVICT_BITS_ANON);
 
 	rcu_read_lock();
 	memcg = folio_memcg(folio);
 	lruvec = mem_cgroup_lruvec(memcg, pgdat);
 	lrugen = &lruvec->lrugen;
-	min_seq = READ_ONCE(lrugen->min_seq[type]);
-	token = (min_seq << LRU_REFS_BITS) | refs >> 1;
+	hist = lru_hist_from_seq(READ_ONCE(lrugen->min_seq[type]));
 
-	hist = lru_hist_from_seq(min_seq);
+	token = refs >> 1;
+	token <<= type ? LRU_GEN_EVICT_BITS : LRU_GEN_EVICT_BITS_ANON;
+	token |= lru_eviction(lruvec, delta,
+			      type ? LRU_GEN_EVICT_BITS : LRU_GEN_EVICT_BITS_ANON,
+			      lru_gen_bucket_order[type]);
 	atomic_long_add(delta, &lrugen->evicted[hist][type][tier]);
 	memcg_id = mem_cgroup_private_id(memcg);
 	rcu_read_unlock();
@@ -423,56 +428,87 @@ static void *lru_gen_eviction(struct folio *folio)
 /*
  * Tests if the shadow entry is for a folio that was recently evicted.
  */
-static bool lru_gen_test_recent(struct lruvec *lruvec,
-				unsigned long token, bool file)
+static bool lru_gen_test_recent(struct lruvec *lruvec, bool file,
+				unsigned long distance)
 {
-	unsigned long max_seq;
+	struct lru_gen_folio *lrugen;
+	unsigned long recent = 0;
+	int hist, tier;
 
-	max_seq = READ_ONCE((lruvec)->lrugen.max_seq);
-	max_seq &= BIT((file ? LRU_EVICT_BITS : LRU_EVICT_BITS_ANON) - LRU_REFS_BITS) - 1;
+	lrugen = &lruvec->lrugen;
+	hist = lru_hist_from_seq(READ_ONCE(lrugen->min_seq[file]));
+	for (tier = 0; tier < MAX_NR_TIERS; tier++)
+		recent += atomic_long_read(&lrugen->evicted[hist][file][tier]);
 
-	return abs_diff(max_seq, token >> LRU_REFS_BITS) < MAX_NR_GENS;
+	return distance <= recent;
 }
 
 static void lru_gen_refault(struct folio *folio, void *shadow)
 {
 	bool recent;
-	int hist, tier, refs;
 	bool workingset;
-	unsigned long token;
+	int hist, tier, refs;
 	struct lruvec *lruvec;
 	struct lru_gen_folio *lrugen;
 	int type = folio_is_file_lru(folio);
 	int delta = folio_nr_pages(folio);
+	unsigned long token, distance, total;
 
-	lruvec = try_unpack_get_lruvec(shadow, &token, &workingset, false);
+	lruvec = try_unpack_get_lruvec(shadow, &token, &workingset, true);
 	if (!lruvec)
 		return;
 	if (lruvec != folio_lruvec(folio))
 		goto out_put;
 
-	recent = lru_gen_test_recent(lruvec, token, type);
 	mod_lruvec_state(lruvec, WORKINGSET_REFAULT_BASE + type, delta);
 
-	if (!recent)
-		goto out_put;
-
 	lrugen = &lruvec->lrugen;
-
 	hist = lru_hist_from_seq(READ_ONCE(lrugen->min_seq[type]));
-	refs = ((token & (BIT(LRU_REFS_BITS) - 1)) << 1) + workingset;
-	tier = lru_tier_from_refs(refs);
 
-	atomic_long_add(delta, &lrugen->refaulted[hist][type][tier]);
+	distance = lru_distance(lruvec, token,
+				type ? LRU_GEN_EVICT_BITS : LRU_GEN_EVICT_BITS_ANON,
+				lru_gen_bucket_order[type]);
+	recent = lru_gen_test_recent(lruvec, type, distance);
+
+	total = lruvec_page_state(lruvec, NR_ACTIVE_FILE) +
+		lruvec_page_state(lruvec, NR_INACTIVE_FILE);
+	if (!type || mem_cgroup_get_nr_swap_pages(lruvec_memcg(lruvec))) {
+		total += lruvec_page_state(lruvec, NR_ACTIVE_ANON) +
+			lruvec_page_state(lruvec, NR_INACTIVE_ANON);
+	}
+
+	/* Return if it's neither recently evicted nor fits workingset. */
+	if (!recent && distance > total)
+		goto out_put;
 
-	/* see folio_add_lru() where folio_set_active() will be called */
-	if (lru_gen_in_fault())
+	token >>= type ? LRU_GEN_EVICT_BITS : LRU_GEN_EVICT_BITS_ANON;
+	token &= (BIT(LRU_REFS_BITS) - 1);
+	refs = (token << 1) + workingset;
+	tier = lru_tier_from_refs(refs);
+
+	/* Set refault as active. */
+	if (distance < total / 2) {
+		folio_set_active(folio);
 		mod_lruvec_state(lruvec, WORKINGSET_ACTIVATE_BASE + type, delta);
+	}
 
+	/* Restore reference count. */
 	if (refs) {
 		folio_set_lru_refs(folio, refs);
 		mod_lruvec_state(lruvec, WORKINGSET_RESTORE_BASE + type, delta);
 	}
+
+	/*
+	 * If it's recently evicted, update the recent gen's counter. Else,
+	 * update the global counter, increase total too to avoid having
+	 * a refault rate > 1.
+	 */
+	if (recent) {
+		atomic_long_add(delta, &lrugen->refaulted[hist][type][tier]);
+	} else {
+		atomic_long_add(delta, &lrugen->avg_total[type][tier]);
+		atomic_long_add(delta, &lrugen->avg_refaulted[type][tier]);
+	}
 out_put:
 	put_lruvec(lruvec);
 }
@@ -484,8 +520,8 @@ static void *lru_gen_eviction(struct folio *folio)
 	return NULL;
 }
 
-static bool lru_gen_test_recent(struct lruvec *lruvec,
-				unsigned long token, bool file)
+static bool lru_gen_test_recent(struct lruvec *lruvec, bool file,
+				unsigned long distance)
 {
 	return false;
 }
@@ -551,15 +587,16 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 	unsigned long distance;
 	bool recent;
 
+	lruvec = try_unpack_get_lruvec(shadow, &eviction, workingset, flush);
+	if (!lruvec)
+		return false;
+
 	if (lru_gen_enabled()) {
-		lruvec = try_unpack_get_lruvec(shadow, &eviction, workingset, false);
-		if (!lruvec)
-			return false;
-		recent = lru_gen_test_recent(lruvec, eviction, file);
+		distance = lru_distance(lruvec, eviction,
+					file ? LRU_GEN_EVICT_BITS : LRU_GEN_EVICT_BITS_ANON,
+					lru_gen_bucket_order[file]);
+		recent = lru_gen_test_recent(lruvec, file, distance);
 	} else {
-		lruvec = try_unpack_get_lruvec(shadow, &eviction, workingset, flush);
-		if (!lruvec)
-			return false;
 		distance = lru_distance(lruvec, eviction,
 					file ? LRU_EVICT_BITS : LRU_EVICT_BITS_ANON,
 					bucket_order[file]);
@@ -850,6 +887,15 @@ static int __init workingset_init(void)
 	pr_info("workingset: timestamp_bits=%d (anon: %d) max_order=%d bucket_order=%u (anon: %d)\n",
 		LRU_EVICT_BITS, LRU_EVICT_BITS_ANON, max_order,
 		bucket_order[WORKINGSET_FILE], bucket_order[WORKINGSET_ANON]);
+#ifdef CONFIG_LRU_GEN
+	if (max_order > LRU_GEN_EVICT_BITS)
+		lru_gen_bucket_order[WORKINGSET_FILE] = max_order - LRU_GEN_EVICT_BITS;
+	if (max_order > LRU_GEN_EVICT_BITS_ANON)
+		lru_gen_bucket_order[WORKINGSET_ANON] = max_order - LRU_GEN_EVICT_BITS_ANON;
+	pr_info("workingset: lru_gen_timestamp_bits=%d (anon: %d) lru_gen_bucket_order=%u (anon %d)\n",
+		LRU_GEN_EVICT_BITS, LRU_GEN_EVICT_BITS_ANON,
+		lru_gen_bucket_order[WORKINGSET_FILE], lru_gen_bucket_order[WORKINGSET_ANON]);
+#endif
 
 	workingset_shadow_shrinker = shrinker_alloc(SHRINKER_NUMA_AWARE |
 						    SHRINKER_MEMCG_AWARE,

-- 
2.54.0

