From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:11 +0800
Subject: [PATCH RFC 25/32] mm/workingset, lru_gen: simplify lru_gen recent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-25-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=4396;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=KbFTzFXmhJEXcTUabj/0KGmAdVaMVZsImEKHZnTCyNA=;
 b=RZb8GTAX1xI9h34O7aHTxF8zmM5P2cs1w7khJykb58iQUXdSl8fVGbsw1OfZz9Bg07EHTDjJK
 Yd9ndllnZ4bBx8uRFgZBRXfjzVFN8DheBQywHs+6Y1ygX8I9k5cFIlo
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the commont part in the common caller. Also let it return early if
the memcg doesn't match.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/workingset.c | 55 ++++++++++++++++++++++++++-----------------------------
 1 file changed, 26 insertions(+), 29 deletions(-)

diff --git a/mm/workingset.c b/mm/workingset.c
index a77a6c0c3e15..b472ac34943e 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -277,44 +277,41 @@ static void *lru_gen_eviction(struct folio *folio)
 
 /*
  * Tests if the shadow entry is for a folio that was recently evicted.
- * Fills in @lruvec, @token, @workingset with the values unpacked from shadow.
  */
-static bool lru_gen_test_recent(void *shadow, struct lruvec **lruvec,
-				unsigned long *token, bool *workingset, bool file)
+static bool lru_gen_test_recent(struct lruvec *lruvec,
+				unsigned long token, bool file)
 {
-	int memcg_id;
 	unsigned long max_seq;
-	struct mem_cgroup *memcg;
-	struct pglist_data *pgdat;
-
-	unpack_shadow(shadow, &memcg_id, &pgdat, token, workingset);
 
-	memcg = mem_cgroup_from_private_id(memcg_id);
-	*lruvec = mem_cgroup_lruvec(memcg, pgdat);
-
-	max_seq = READ_ONCE((*lruvec)->lrugen.max_seq);
+	max_seq = READ_ONCE((lruvec)->lrugen.max_seq);
 	max_seq &= (file ? EVICTION_MASK : EVICTION_MASK_ANON) >> LRU_REFS_BITS;
 
-	return abs_diff(max_seq, *token >> LRU_REFS_BITS) < MAX_NR_GENS;
+	return abs_diff(max_seq, token >> LRU_REFS_BITS) < MAX_NR_GENS;
 }
 
 static void lru_gen_refault(struct folio *folio, void *shadow)
 {
 	bool recent;
+	int memcg_id;
 	int hist, tier, refs;
 	bool workingset;
 	unsigned long token;
 	struct lruvec *lruvec;
+	struct mem_cgroup *memcg;
+	struct pglist_data *pgdat;
 	struct lru_gen_folio *lrugen;
 	int type = folio_is_file_lru(folio);
 	int delta = folio_nr_pages(folio);
 
-	rcu_read_lock();
+	unpack_shadow(shadow, &memcg_id, &pgdat, &token, &workingset);
 
-	recent = lru_gen_test_recent(shadow, &lruvec, &token, &workingset, type);
+	rcu_read_lock();
+	memcg = mem_cgroup_from_private_id(memcg_id);
+	lruvec = mem_cgroup_lruvec(memcg, pgdat);
 	if (lruvec != folio_lruvec(folio))
 		goto unlock;
 
+	recent = lru_gen_test_recent(lruvec, token, type);
 	mod_lruvec_state(lruvec, WORKINGSET_REFAULT_BASE + type, delta);
 
 	if (!recent)
@@ -347,8 +344,8 @@ static void *lru_gen_eviction(struct folio *folio)
 	return NULL;
 }
 
-static bool lru_gen_test_recent(void *shadow, struct lruvec **lruvec,
-				unsigned long *token, bool *workingset, bool file)
+static bool lru_gen_test_recent(struct lruvec *lruvec,
+				unsigned long token, bool file)
 {
 	return false;
 }
@@ -445,19 +442,8 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 	unsigned long eviction;
 	int memcgid;
 
-	if (lru_gen_enabled()) {
-		bool recent;
-
-		rcu_read_lock();
-		recent = lru_gen_test_recent(shadow, &eviction_lruvec, &eviction,
-					     workingset, file);
-		rcu_read_unlock();
-		return recent;
-	}
-
 	rcu_read_lock();
 	unpack_shadow(shadow, &memcgid, &pgdat, &eviction, workingset);
-	eviction <<= bucket_order[file];
 
 	/*
 	 * Look up the memcg associated with the stored ID. It might
@@ -482,6 +468,17 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 
 	if (!mem_cgroup_disabled() && !eviction_memcg)
 		return false;
+
+	eviction_lruvec = mem_cgroup_lruvec(eviction_memcg, pgdat);
+
+	if (lru_gen_enabled()) {
+		bool recent;
+
+		recent = lru_gen_test_recent(eviction_lruvec, eviction, file);
+		mem_cgroup_put(eviction_memcg);
+		return recent;
+	}
+
 	/*
 	 * Flush stats (and potentially sleep) outside the RCU read section.
 	 *
@@ -495,7 +492,6 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 	if (flush)
 		mem_cgroup_flush_stats_ratelimited(eviction_memcg);
 
-	eviction_lruvec = mem_cgroup_lruvec(eviction_memcg, pgdat);
 	refault = atomic_long_read(&eviction_lruvec->evictions);
 
 	/*
@@ -514,6 +510,7 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 	 * longest time, so the occasional inappropriate activation
 	 * leading to pressure on the active list is not a problem.
 	 */
+	eviction <<= bucket_order[file];
 	distance = ((refault - eviction) &
 		    (file ? EVICTION_MASK : EVICTION_MASK_ANON));
 

-- 
2.54.0

