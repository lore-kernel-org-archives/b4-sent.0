From: Kairui Song <kasong@tencent.com>
Date: Thu, 19 Nov 2026 05:03:40 +0800
Subject: [PATCH v5 08/17] mm/mglru: move add/del LRU size accounting out of
 lru_gen_update_size()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-mglru-fg-v5-8-9eee2fe97a2d@tencent.com>
References: <20261119-mglru-fg-v5-0-9eee2fe97a2d@tencent.com>
In-Reply-To: <20261119-mglru-fg-v5-0-9eee2fe97a2d@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <qi.zheng@linux.dev>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Chris Li <chrisl@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Nhat Pham <nphamcs@gmail.com>, Youngjun Park <youngjun.park@lge.com>, 
 Zi Yan <ziy@nvidia.com>, Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SJ Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Chen Ridong <chenridong@xiaomi.com>, 
 Tal Zussman <tz2294@columbia.edu>, Kairui Song <ryncsn@gmail.com>, 
 Xiang Liu <liuxiang.277@bytedance.com>, 
 Ehab Ababneh <ehab.ababneh@intel.com>, 
 Zhao Zhenzhuo <zhaozhengzhuo@uniontech.com>, 
 Lian Wang <lianux.mm@gmail.com>, Joanne Koong <joannelkoong@gmail.com>, 
 Kunwu Chan <kunwu.chan@gmail.com>, Hui Zhu <hui.zhu@linux.dev>, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 damon@lists.linux.dev, linux-doc@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795035820; l=3201;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=IMx6xZ1UYdgH8/pT8EECvr4VEPMQIFmzT2ojfi7j6eM=;
 b=5efdLIptwvbgkU2KOfLszIx7r/dpPWPZvzbfRP4VYmt9+JKNeYASC6zRHEvWm4MXQ2GGkSK2H
 EP1AAwudZXQB3k7st+uKT1b9Nc6IWqzONeHGo92DEWSw1p97bWfZDUw
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pure code shuffle, no behavior change.  lru_gen_update_size() now only
updates the per-generation counters plus the promotion move; the
addition and deletion active/inactive accounting move to
lru_gen_add_folio() and lru_gen_del_folio(), which know the generation
and can apply the active-window test directly.

The unevictable case is untouched: unevictable folios never enter
lru_gen_add_folio() and keep being accounted by lruvec_add_folio() as
before.

Tested-by: Zhao Zhenzhuo <zhaozhengzhuo@uniontech.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm_inline.h | 28 ++++++++++++++--------------
 1 file changed, 14 insertions(+), 14 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index 180db43c3a85..b15c3618a1f2 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -322,21 +322,9 @@ static inline void lru_gen_update_size(struct lruvec *lruvec, struct folio *foli
 	if (new_gen >= 0)
 		atomic_long_add(delta, &lrugen->nr_pages[new_gen][type][zone]);
 
-	/* addition */
-	if (old_gen < 0) {
-		if (lru_gen_is_active(lruvec, new_gen))
-			lru += LRU_ACTIVE;
-		__update_lru_size(lruvec, lru, zone, delta);
+	/* return now if not a promotion */
+	if (old_gen < 0 || new_gen < 0)
 		return;
-	}
-
-	/* deletion */
-	if (new_gen < 0) {
-		if (lru_gen_is_active(lruvec, old_gen))
-			lru += LRU_ACTIVE;
-		__update_lru_size(lruvec, lru, zone, -delta);
-		return;
-	}
 
 	/* promotion */
 	if (!lru_gen_is_active(lruvec, old_gen) && lru_gen_is_active(lruvec, new_gen)) {
@@ -391,6 +379,8 @@ static inline bool __lru_gen_add_folio(struct lruvec *lruvec, struct folio *foli
 	int gen = folio_lru_gen(folio);
 	int type = folio_is_file_lru(folio);
 	int zone = folio_zonenum(folio);
+	int delta = folio_nr_pages(folio);
+	enum lru_list lru = type * LRU_INACTIVE_FILE;
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 
 	BUILD_BUG_ON(BIT(LRU_GEN_WIDTH - 1) != MAX_NR_GENS);
@@ -408,6 +398,10 @@ static inline bool __lru_gen_add_folio(struct lruvec *lruvec, struct folio *foli
 	set_mask_bits(folio_flags(folio, 0), LRU_GEN_MASK | BIT(PG_active), flags);
 
 	lru_gen_update_size(lruvec, folio, -1, gen);
+	if (lru_gen_is_active(lruvec, gen))
+		lru += LRU_ACTIVE;
+	__update_lru_size(lruvec, lru, zone, delta);
+
 	/* for folio_rotate_reclaimable() */
 	if (reclaiming)
 		list_add_tail(&folio->lru, &lrugen->folios[gen][type][zone]);
@@ -432,6 +426,9 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 {
 	unsigned long flags;
 	int gen = folio_lru_gen(folio);
+	int zone = folio_zonenum(folio);
+	int delta = folio_nr_pages(folio);
+	enum lru_list lru = folio_is_file_lru(folio) * LRU_INACTIVE_FILE;
 
 	if (gen < 0)
 		return false;
@@ -445,6 +442,9 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 	gen = ((flags & LRU_GEN_MASK) >> LRU_GEN_PGOFF) - 1;
 
 	lru_gen_update_size(lruvec, folio, gen, -1);
+	if (lru_gen_is_active(lruvec, gen))
+		lru += LRU_ACTIVE;
+	__update_lru_size(lruvec, lru, zone, -delta);
 	list_del(&folio->lru);
 
 	return true;

-- 
2.56.1

