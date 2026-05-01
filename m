From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:13 +0800
Subject: [PATCH RFC 27/32] mm/workingset: move refault distance checking
 into a helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-27-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=7913;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=bwYzIJmY3Hqa83k+2m4zOivhjtGZdKIukV17N5RFO4g=;
 b=406q4TDrkyFVDQ5IMpGCHCP44WNYxwuZQGPzaniAOeZA2dwckbGSgUqvgkWv/KqqeqF9PROsP
 Cb4l7vx1BkkC9r/wmxg3Sx2QxppoNWXmWgFDYcIRETQ5+fcG45eU5gT
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There isn't any feature change, just move the refault distance checking
logic into a standalone helper so it can be reused later.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/workingset.c | 136 ++++++++++++++++++++++++++++++++------------------------
 1 file changed, 78 insertions(+), 58 deletions(-)

diff --git a/mm/workingset.c b/mm/workingset.c
index 622e00ac28b6..e756b0cc14b5 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -234,9 +234,6 @@ static unsigned int bucket_order[ANON_AND_FILE] __read_mostly;
 static void *pack_shadow(int memcgid, pg_data_t *pgdat, unsigned long eviction,
 			 bool workingset, bool file)
 {
-	BUILD_BUG_ON(LRU_EVICT_BITS_ANON <= SWAP_COUNT_SHIFT);
-
-	eviction &= BIT(file ? LRU_EVICT_BITS : LRU_EVICT_BITS_ANON) - 1;
 	eviction = (eviction << MEM_CGROUP_ID_SHIFT) | memcgid;
 	eviction = (eviction << NODES_SHIFT) | pgdat->node_id;
 	eviction = (eviction << WORKINGSET_SHIFT) | workingset;
@@ -264,6 +261,77 @@ static void unpack_shadow(void *shadow, int *memcgidp, pg_data_t **pgdat,
 	*workingsetp = workingset;
 }
 
+/**
+ * lru_eviction - notifies eviction of an folio on an lruvec
+ * @lruvec: the lruvec the folio belongs to
+ * @nr_pages: size of the folio
+ *
+ * As in-memory folio is evicted, increase the eviction counter on
+ * the LRU and return its current reading.
+ */
+static inline unsigned long lru_eviction(struct lruvec *lruvec, int nr_pages,
+					 int bits, int bucket_order)
+{
+	unsigned long eviction;
+
+	/*
+	 * Reclaiming a cgroup means reclaiming all its children in a
+	 * round-robin fashion. That means that each cgroup has an LRU
+	 * order that is composed of the LRU orders of its child
+	 * cgroups; and every page has an LRU position not just in the
+	 * cgroup that owns it, but in all of that group's ancestors.
+	 *
+	 * So when the physical inactive list of a leaf cgroup ages,
+	 * the virtual inactive lists of all its parents, including
+	 * the root cgroup's, age as well.
+	 */
+	BUILD_BUG_ON(LRU_EVICT_BITS_ANON <= SWAP_COUNT_SHIFT);
+	eviction = atomic_long_fetch_add_relaxed(nr_pages, &lruvec->evictions);
+	while ((lruvec = parent_lruvec(lruvec)))
+		atomic_long_add(nr_pages, &lruvec->evictions);
+
+	/* Truncate the timestamp to fit in limited bits */
+	eviction >>= bucket_order;
+	eviction &= (BIT(bits) - 1);
+	return eviction;
+}
+
+/**
+ * lru_distance - calculate the refault distance of a refaulted folio
+ * @lruvec: the lruvec the folio belongs to before eviction
+ * @eviction: eviction timestamp recorded in the shadow
+ * @bits: number of bits used to encode the timestamp
+ * @bucket_order: bucket order used to truncate the timestamp
+ *
+ * Read the lruvec's current eviction counter and return the refault
+ * distance.
+ */
+static inline unsigned long lru_distance(struct lruvec *lruvec,
+					 unsigned long eviction,
+					 int bits, int bucket_order)
+{
+	unsigned long refault;
+
+	eviction <<= bucket_order;
+	refault = atomic_long_read(&lruvec->evictions);
+
+	/*
+	 * The unsigned subtraction here gives an accurate distance
+	 * across evictions overflows in most cases. There is a
+	 * special case: usually, shadow entries have a short lifetime
+	 * and are either refaulted or reclaimed along with the inode
+	 * before they get too old.  But it is not impossible for the
+	 * evictions to lap a shadow entry in the field, which
+	 * can then result in a false small refault distance, leading
+	 * to a false activation should this old entry actually
+	 * refault again.  However, earlier kernels used to deactivate
+	 * unconditionally with *every* reclaim invocation for the
+	 * longest time, so the occasional inappropriate activation
+	 * leading to pressure on the active list is not a problem.
+	 */
+	return (refault - eviction) & (BIT(bits) - 1);
+}
+
 #ifdef CONFIG_LRU_GEN
 
 static void *lru_gen_eviction(struct folio *folio)
@@ -379,37 +447,6 @@ static void lru_gen_refault(struct folio *folio, void *shadow)
 
 #endif /* CONFIG_LRU_GEN */
 
-/**
- * workingset_age_nonresident - age non-resident entries as LRU ages
- * @lruvec: the lruvec that was aged
- * @nr_pages: the number of pages to count
- *
- * As in-memory pages are aged, non-resident pages need to be aged as
- * well, in order for the refault distances later on to be comparable
- * to the in-memory dimensions. This function allows reclaim and LRU
- * operations to drive the non-resident aging along in parallel.
- */
-static long workingset_age_nonresident(struct lruvec *lruvec, unsigned long nr_pages)
-{
-	unsigned long eviction;
-
-	/*
-	 * Reclaiming a cgroup means reclaiming all its children in a
-	 * round-robin fashion. That means that each cgroup has an LRU
-	 * order that is composed of the LRU orders of its child
-	 * cgroups; and every page has an LRU position not just in the
-	 * cgroup that owns it, but in all of that group's ancestors.
-	 *
-	 * So when the physical inactive list of a leaf cgroup ages,
-	 * the virtual inactive lists of all its parents, including
-	 * the root cgroup's, age as well.
-	 */
-	eviction = atomic_long_fetch_add_relaxed(nr_pages, &lruvec->evictions);
-	while ((lruvec = parent_lruvec(lruvec)))
-		atomic_long_add(nr_pages, &lruvec->evictions);
-	return eviction;
-}
-
 /**
  * workingset_eviction - note the eviction of a folio from memory
  * @target_memcg: the cgroup that is causing the reclaim
@@ -437,8 +474,9 @@ void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
 	lruvec = mem_cgroup_lruvec(target_memcg, pgdat);
 	/* XXX: target_memcg can be NULL, go through lruvec */
 	memcgid = mem_cgroup_private_id(lruvec_memcg(lruvec));
-	eviction = workingset_age_nonresident(lruvec, folio_nr_pages(folio));
-	eviction >>= bucket_order[file];
+	eviction = lru_eviction(lruvec, folio_nr_pages(folio),
+				file ? LRU_EVICT_BITS : LRU_EVICT_BITS_ANON,
+				bucket_order[file]);
 	return pack_shadow(memcgid, pgdat, eviction,
 			   folio_is_workingset(folio), file);
 }
@@ -458,7 +496,7 @@ void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
 bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 				bool flush)
 {
-	unsigned long refault, distance, active, inactive;
+	unsigned long distance, active, inactive;
 	struct mem_cgroup *eviction_memcg;
 	struct lruvec *eviction_lruvec;
 	struct pglist_data *pgdat;
@@ -515,27 +553,9 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 	if (flush)
 		mem_cgroup_flush_stats_ratelimited(eviction_memcg);
 
-	refault = atomic_long_read(&eviction_lruvec->evictions);
-
-	/*
-	 * Calculate the refault distance
-	 *
-	 * The unsigned subtraction here gives an accurate distance
-	 * across evictions overflows in most cases. There is a
-	 * special case: usually, shadow entries have a short lifetime
-	 * and are either refaulted or reclaimed along with the inode
-	 * before they get too old.  But it is not impossible for the
-	 * evictions to lap a shadow entry in the field, which
-	 * can then result in a false small refault distance, leading
-	 * to a false activation should this old entry actually
-	 * refault again.  However, earlier kernels used to deactivate
-	 * unconditionally with *every* reclaim invocation for the
-	 * longest time, so the occasional inappropriate activation
-	 * leading to pressure on the active list is not a problem.
-	 */
-	eviction <<= bucket_order[file];
-	distance = ((refault - eviction) &
-		    (BIT(file ? LRU_EVICT_BITS : LRU_EVICT_BITS_ANON) - 1));
+	distance = lru_distance(eviction_lruvec, eviction,
+				file ? LRU_EVICT_BITS : LRU_EVICT_BITS_ANON,
+				bucket_order[file]);
 
 	/*
 	 * Compare the distance to the existing workingset size. We

-- 
2.54.0

