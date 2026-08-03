From: Kairui Song <kasong@tencent.com>
Date: Tue, 04 Aug 2026 03:46:57 +0800
Subject: [PATCH RFC 01/15] mm/memcontrol: make lru_zone_size atomic and
 simplify sanity check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-mglru-fg-v1-1-4d8dad39dad6@tencent.com>
References: <20260804-mglru-fg-v1-0-4d8dad39dad6@tencent.com>
In-Reply-To: <20260804-mglru-fg-v1-0-4d8dad39dad6@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <qi.zheng@linux.dev>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Chris Li <chrisl@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, Zi Yan <ziy@nvidia.com>, 
 Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SeongJae Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Chen Ridong <chenridong@xiaomi.com>, 
 Tal Zussman <tz2294@columbia.edu>, Kairui Song <ryncsn@gmail.com>, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785786439; l=4666;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=VmGMj3oQ5WlKjZNi9BvygZeEmYIa6a/WBZg5ksVdh2w=;
 b=a0JTNWuPi48o3Fm1tmk0HF76NfE1tnogbipupV7MsafExoMnGyTXKGtgtIoml53Gk31D5uRJs
 EGfJ/FlOQdeCuvTUuafmuiYvO38wQEj4NOhVPlp6aOqx5ZKeCI4/sef
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

commit ca707239e8a7 ("mm: update_lru_size warn and reset bad lru_size")
introduced a sanity check to catch memcg counter underflow, which is
more like a workaround for another bug: lru_zone_size is unsigned, so
underflow will wrap it around and return an enormously large number,
then the memcg shrinker will loop almost forever as the calculated
number of folios to shrink is huge. That commit also checks if a zero
value matches the empty LRU list, so we have to hold the LRU lock, and
do the counter adding differently depending on whether the nr_pages is
negative.

But later commit b4536f0c829c ("mm, memcg: fix the active list aging for
lowmem requests when memcg is enabled") already removed the LRU
emptiness check, doing the adding differently is meaningless now. And if
we just turn it into an atomic long, underflow isn't a big issue either,
and can be checked at the reader side. The reader size is much less
frequently called than the updater.

So let's turn the counter into an atomic long and check at the
reader side instead, which has a smaller overhead. Use atomic to avoid
potential locking issue. The underflow correction is removed, which
should be fine as if there is a mass leaking of the LRU size counter,
something else may also have gone very wrong, and one should fix that
leaking site instead. Besides, doing the sanity check in updater is
unlikely to catch the leaking site, e.g. a folio was removed minutes ago
without updating the counter, while there are still other folios on the
LRU, the WARN won't be triggered until other folios are removed from a
likely correct callsite.

For now still keep the LRU lock context, in theory that can be removed
too since the update is atomic, if we can tolerate a temporary
inaccurate reading, but currently there is no benefit doing so yet.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/memcontrol.h |  9 +++++++--
 mm/memcontrol.c            | 18 +-----------------
 mm/vmscan.c                |  5 -----
 3 files changed, 8 insertions(+), 24 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index e78bc98ab229..b13e3f056319 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -113,7 +113,7 @@ struct mem_cgroup_per_node {
 	/* Fields which get updated often at the end. */
 	struct lruvec		lruvec;
 	CACHELINE_PADDING(_pad2_);
-	unsigned long		lru_zone_size[MAX_NR_ZONES][NR_LRU_LISTS];
+	atomic_long_t		lru_zone_size[MAX_NR_ZONES][NR_LRU_LISTS];
 	struct mem_cgroup_reclaim_iter	iter;
 
 	/*
@@ -897,10 +897,15 @@ static inline
 unsigned long mem_cgroup_get_zone_lru_size(struct lruvec *lruvec,
 		enum lru_list lru, int zone_idx)
 {
+	long val;
 	struct mem_cgroup_per_node *mz;
 
 	mz = container_of(lruvec, struct mem_cgroup_per_node, lruvec);
-	return READ_ONCE(mz->lru_zone_size[zone_idx][lru]);
+	val = atomic_long_read(&mz->lru_zone_size[zone_idx][lru]);
+	if (WARN_ON_ONCE(val < 0))
+		return 0;
+
+	return val;
 }
 
 void __mem_cgroup_handle_over_high(gfp_t gfp_mask);
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 1bde9d5af88a..7511773b3491 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -1529,28 +1529,12 @@ void mem_cgroup_update_lru_size(struct lruvec *lruvec, enum lru_list lru,
 				int zid, long nr_pages)
 {
 	struct mem_cgroup_per_node *mz;
-	unsigned long *lru_size;
-	long size;
 
 	if (mem_cgroup_disabled())
 		return;
 
 	mz = container_of(lruvec, struct mem_cgroup_per_node, lruvec);
-	lru_size = &mz->lru_zone_size[zid][lru];
-
-	if (nr_pages < 0)
-		*lru_size += nr_pages;
-
-	size = *lru_size;
-	if (WARN_ONCE(size < 0,
-		"%s(%p, %d, %ld): lru_size %ld\n",
-		__func__, lruvec, lru, nr_pages, size)) {
-		VM_BUG_ON(1);
-		*lru_size = 0;
-	}
-
-	if (nr_pages > 0)
-		*lru_size += nr_pages;
+	atomic_long_add(nr_pages, &mz->lru_zone_size[zid][lru]);
 }
 
 /**
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 17d2b793cbfc..fe7cf5d42e0c 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -1636,10 +1636,6 @@ unsigned int reclaim_clean_pages_from_list(struct zone *zone,
 	return nr_reclaimed;
 }
 
-/*
- * Update LRU sizes after isolating pages. The LRU size updates must
- * be complete before mem_cgroup_update_lru_size due to a sanity check.
- */
 static __always_inline void update_lru_sizes(struct lruvec *lruvec,
 			enum lru_list lru, unsigned long *nr_zone_taken)
 {
@@ -1651,7 +1647,6 @@ static __always_inline void update_lru_sizes(struct lruvec *lruvec,
 
 		update_lru_size(lruvec, lru, zid, -nr_zone_taken[zid]);
 	}
-
 }
 
 /*

-- 
2.55.0

