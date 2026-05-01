From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:14 +0800
Subject: [PATCH RFC 28/32] mm/workingset: split lruvec retrieving and flush
 into a helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-28-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=8304;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=CannGTZuhdb+chYR/x/lEwpMQkSHEkSpZfE0GVG1Xvg=;
 b=oXBiImfpMiql1tAMBZqHjNGBH+90Hveu3ZZG7nw1NvBuBrivKpGFuLylAq0UHD0SBKaV/+h7T
 khWYi0AglAVD1r4EUq/bDzIigkek7M7F7l5+pz4g9OXg6Qjj0Zb0PwG
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Soon MGLRU will share the common routine for refault distance checking,
so make a few helpers for that. No feature change.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/workingset.c | 189 +++++++++++++++++++++++++++++---------------------------
 1 file changed, 98 insertions(+), 91 deletions(-)

diff --git a/mm/workingset.c b/mm/workingset.c
index e756b0cc14b5..5c52dd835a92 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -261,6 +261,60 @@ static void unpack_shadow(void *shadow, int *memcgidp, pg_data_t **pgdat,
 	*workingsetp = workingset;
 }
 
+static struct lruvec *try_unpack_get_lruvec(void *shadow,
+					    unsigned long *eviction,
+					    bool *workingset, bool flush)
+{
+	int memcgid;
+	struct mem_cgroup *memcg;
+	struct pglist_data *pgdat;
+
+	unpack_shadow(shadow, &memcgid, &pgdat, eviction, workingset);
+
+	/*
+	 * Look up the memcg associated with the stored ID. It might
+	 * have been deleted since the folio's eviction.
+	 *
+	 * Note that in rare events the ID could have been recycled
+	 * for a new cgroup that refaults a shared folio. This is
+	 * impossible to tell from the available data. However, this
+	 * should be a rare and limited disturbance, and activations
+	 * are always speculative anyway. Ultimately, it's the aging
+	 * algorithm's job to shake out the minimum access frequency
+	 * for the active cache.
+	 *
+	 * XXX: On !CONFIG_MEMCG, this will always return NULL; it
+	 * would be better if the root_mem_cgroup existed in all
+	 * configurations instead.
+	 */
+	rcu_read_lock();
+	memcg = mem_cgroup_from_private_id(memcgid);
+	if (!mem_cgroup_tryget(memcg))
+		memcg = NULL;
+	rcu_read_unlock();
+
+	if (!mem_cgroup_disabled() && !memcg)
+		return NULL;
+
+	/*
+	 * Flush stats (and potentially sleep) outside the RCU read section.
+	 * XXX: With per-memcg flushing and thresholding, is ratelimiting
+	 * still needed here?
+	 */
+	if (memcg && flush)
+		mem_cgroup_flush_stats_ratelimited(memcg);
+
+	return mem_cgroup_lruvec(memcg, pgdat);
+}
+
+static void put_lruvec(struct lruvec *lruvec)
+{
+	if (mem_cgroup_disabled())
+		return;
+
+	mem_cgroup_put(lruvec_memcg(lruvec));
+}
+
 /**
  * lru_eviction - notifies eviction of an folio on an lruvec
  * @lruvec: the lruvec the folio belongs to
@@ -383,30 +437,25 @@ static bool lru_gen_test_recent(struct lruvec *lruvec,
 static void lru_gen_refault(struct folio *folio, void *shadow)
 {
 	bool recent;
-	int memcg_id;
 	int hist, tier, refs;
 	bool workingset;
 	unsigned long token;
 	struct lruvec *lruvec;
-	struct mem_cgroup *memcg;
-	struct pglist_data *pgdat;
 	struct lru_gen_folio *lrugen;
 	int type = folio_is_file_lru(folio);
 	int delta = folio_nr_pages(folio);
 
-	unpack_shadow(shadow, &memcg_id, &pgdat, &token, &workingset);
-
-	rcu_read_lock();
-	memcg = mem_cgroup_from_private_id(memcg_id);
-	lruvec = mem_cgroup_lruvec(memcg, pgdat);
+	lruvec = try_unpack_get_lruvec(shadow, &token, &workingset, false);
+	if (!lruvec)
+		return;
 	if (lruvec != folio_lruvec(folio))
-		goto unlock;
+		goto out_put;
 
 	recent = lru_gen_test_recent(lruvec, token, type);
 	mod_lruvec_state(lruvec, WORKINGSET_REFAULT_BASE + type, delta);
 
 	if (!recent)
-		goto unlock;
+		goto out_put;
 
 	lrugen = &lruvec->lrugen;
 
@@ -424,8 +473,8 @@ static void lru_gen_refault(struct folio *folio, void *shadow)
 		folio_set_lru_refs(folio, refs);
 		mod_lruvec_state(lruvec, WORKINGSET_RESTORE_BASE + type, delta);
 	}
-unlock:
-	rcu_read_unlock();
+out_put:
+	put_lruvec(lruvec);
 }
 
 #else /* !CONFIG_LRU_GEN */
@@ -494,91 +543,49 @@ void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
  * Return: true if the shadow is for a recently evicted folio; false otherwise.
  */
 bool workingset_test_recent(void *shadow, bool file, bool *workingset,
-				bool flush)
+			    bool flush)
 {
-	unsigned long distance, active, inactive;
-	struct mem_cgroup *eviction_memcg;
-	struct lruvec *eviction_lruvec;
-	struct pglist_data *pgdat;
+	struct lruvec *lruvec;
 	unsigned long eviction;
-	int memcgid;
-
-	rcu_read_lock();
-	unpack_shadow(shadow, &memcgid, &pgdat, &eviction, workingset);
-
-	/*
-	 * Look up the memcg associated with the stored ID. It might
-	 * have been deleted since the folio's eviction.
-	 *
-	 * Note that in rare events the ID could have been recycled
-	 * for a new cgroup that refaults a shared folio. This is
-	 * impossible to tell from the available data. However, this
-	 * should be a rare and limited disturbance, and activations
-	 * are always speculative anyway. Ultimately, it's the aging
-	 * algorithm's job to shake out the minimum access frequency
-	 * for the active cache.
-	 *
-	 * XXX: On !CONFIG_MEMCG, this will always return NULL; it
-	 * would be better if the root_mem_cgroup existed in all
-	 * configurations instead.
-	 */
-	eviction_memcg = mem_cgroup_from_private_id(memcgid);
-	if (!mem_cgroup_tryget(eviction_memcg))
-		eviction_memcg = NULL;
-	rcu_read_unlock();
-
-	if (!mem_cgroup_disabled() && !eviction_memcg)
-		return false;
-
-	eviction_lruvec = mem_cgroup_lruvec(eviction_memcg, pgdat);
+	unsigned long active, inactive;
+	unsigned long distance;
+	bool recent;
 
 	if (lru_gen_enabled()) {
-		bool recent;
-
-		recent = lru_gen_test_recent(eviction_lruvec, eviction, file);
-		mem_cgroup_put(eviction_memcg);
-		return recent;
-	}
-
-	/*
-	 * Flush stats (and potentially sleep) outside the RCU read section.
-	 *
-	 * Note that workingset_test_recent() itself might be called in RCU read
-	 * section (for e.g, in cachestat) - these callers need to skip flushing
-	 * stats (via the flush argument).
-	 *
-	 * XXX: With per-memcg flushing and thresholding, is ratelimiting
-	 * still needed here?
-	 */
-	if (flush)
-		mem_cgroup_flush_stats_ratelimited(eviction_memcg);
-
-	distance = lru_distance(eviction_lruvec, eviction,
-				file ? LRU_EVICT_BITS : LRU_EVICT_BITS_ANON,
-				bucket_order[file]);
-
-	/*
-	 * Compare the distance to the existing workingset size. We
-	 * don't activate pages that couldn't stay resident even if
-	 * all the memory was available to the workingset. Whether
-	 * workingset competition needs to consider anon or not depends
-	 * on having free swap space.
-	 */
-	active = lruvec_page_state(eviction_lruvec, NR_ACTIVE_FILE);
-	inactive = lruvec_page_state(eviction_lruvec, NR_INACTIVE_FILE);
-
-	if (mem_cgroup_get_nr_swap_pages(eviction_memcg) > 0) {
-		active += lruvec_page_state(eviction_lruvec, NR_ACTIVE_ANON);
-		inactive += lruvec_page_state(eviction_lruvec, NR_INACTIVE_ANON);
+		lruvec = try_unpack_get_lruvec(shadow, &eviction, workingset, false);
+		if (!lruvec)
+			return false;
+		recent = lru_gen_test_recent(lruvec, eviction, file);
+	} else {
+		lruvec = try_unpack_get_lruvec(shadow, &eviction, workingset, flush);
+		if (!lruvec)
+			return false;
+		distance = lru_distance(lruvec, eviction,
+					file ? LRU_EVICT_BITS : LRU_EVICT_BITS_ANON,
+					bucket_order[file]);
+		/*
+		 * Compare the distance to the existing workingset size. We
+		 * don't activate pages that couldn't stay resident even if
+		 * all the memory was available to the workingset. Whether
+		 * workingset competition needs to consider anon or not depends
+		 * on having free swap space.
+		 */
+		active = lruvec_page_state(lruvec, NR_ACTIVE_FILE);
+		inactive = lruvec_page_state(lruvec, NR_INACTIVE_FILE);
+		if (mem_cgroup_get_nr_swap_pages(lruvec_memcg(lruvec)) > 0) {
+			active += lruvec_page_state(lruvec, NR_ACTIVE_ANON);
+			inactive += lruvec_page_state(lruvec, NR_INACTIVE_ANON);
+		}
+		/*
+		 * Be cautious about challenging the existing active working
+		 * set; sacrificing the inactive part of the opposite type
+		 * should be safe.
+		 */
+		recent = distance <= (active + inactive) / 2;
 	}
 
-	mem_cgroup_put(eviction_memcg);
-
-	/*
-	 * Be cautious about challenging the existing active working set;
-	 * sacrificing the inactive part of the opposite type should be safe.
-	 */
-	return distance <= (active + inactive) / 2;
+	put_lruvec(lruvec);
+	return recent;
 }
 
 /**

-- 
2.54.0

