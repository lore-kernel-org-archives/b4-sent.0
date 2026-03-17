From: Kairui Song <kasong@tencent.com>
Date: Wed, 18 Mar 2026 03:09:00 +0800
Subject: [PATCH 4/8] mm/mglru: scan and count the exact number of folios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-mglru-reclaim-v1-4-2c46f9eb0508@tencent.com>
References: <20260318-mglru-reclaim-v1-0-2c46f9eb0508@tencent.com>
In-Reply-To: <20260318-mglru-reclaim-v1-0-2c46f9eb0508@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 David Hildenbrand <david@kernel.org>, Michal Hocko <mhocko@kernel.org>, 
 Qi Zheng <zhengqi.arch@bytedance.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Lorenzo Stoakes <ljs@kernel.org>, 
 Barry Song <baohua@kernel.org>, David Stevens <stevensd@google.com>, 
 Chen Ridong <chenridong@huaweicloud.com>, Leno Hou <lenohou@gmail.com>, 
 Yafang Shao <laoar.shao@gmail.com>, Yu Zhao <yuzhao@google.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Kalesh Singh <kaleshsingh@google.com>, 
 Suren Baghdasaryan <surenb@google.com>, Chris Li <chrisl@kernel.org>, 
 Vernon Yang <vernon2gm@gmail.com>, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773774704; l=3146;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=ky1RNKZLvXcrdMH1kH0GOekvj38YuXZMcHy4rmbDVXw=;
 b=553cnEXzCmztoDDKU1GnFdlSR+/vyXytKxAb9StLKpS6UvhbV0dykEwBCqNffnCFJo5+JaTEK
 2Ihc40Wy2N/BFNiKqlIvvQgFHbhIaFzs+7QgAGC09dLP7kT7vmNdIM1
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make the scan helpers return the exact number of folios being scanned
or isolated. This should make the scan more accurate and easier to
follow.

Now there is no more need for special handling when there is no
progress made. The old livelock prevention `(return isolated ||
!remaining ? scanned : 0)` is replaced by the natural scan budget
exhaustion in try_to_shrink_lruvec, and sort_folio moves ineligible
folios to newer generations.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 27 +++++++++++----------------
 1 file changed, 11 insertions(+), 16 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index ed5b5f8dd3c7..4f4548ff3a17 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4680,7 +4680,7 @@ static bool isolate_folio(struct lruvec *lruvec, struct folio *folio, struct sca
 
 static int scan_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 		       struct scan_control *sc, int type, int tier,
-		       struct list_head *list)
+		       struct list_head *list, int *isolatedp)
 {
 	int i;
 	int gen;
@@ -4750,11 +4750,9 @@ static int scan_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 				type ? LRU_INACTIVE_FILE : LRU_INACTIVE_ANON);
 	if (type == LRU_GEN_FILE)
 		sc->nr.file_taken += isolated;
-	/*
-	 * There might not be eligible folios due to reclaim_idx. Check the
-	 * remaining to prevent livelock if it's not making progress.
-	 */
-	return isolated || !remaining ? scanned : 0;
+
+	*isolatedp = isolated;
+	return scanned;
 }
 
 static int get_tier_idx(struct lruvec *lruvec, int type)
@@ -4819,23 +4817,24 @@ static int isolate_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 			  int *type_scanned, struct list_head *list)
 {
 	int i;
+	int scanned = 0;
+	int isolated = 0;
 	int type = get_type_to_scan(lruvec, swappiness);
 
 	for_each_evictable_type(i, swappiness) {
-		int scanned;
 		int tier = get_tier_idx(lruvec, type);
 
 		*type_scanned = type;
 
-		scanned = scan_folios(nr_to_scan, lruvec, sc,
-				      type, tier, list);
-		if (scanned)
+		scanned += scan_folios(nr_to_scan, lruvec, sc,
+				      type, tier, list, &isolated);
+		if (isolated)
 			return scanned;
 
 		type = !type;
 	}
 
-	return 0;
+	return scanned;
 }
 
 static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
@@ -4852,7 +4851,6 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 	struct reclaim_stat stat;
 	struct lru_gen_mm_walk *walk;
 	bool skip_retry = false;
-	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 	struct mem_cgroup *memcg = lruvec_memcg(lruvec);
 	struct pglist_data *pgdat = lruvec_pgdat(lruvec);
 
@@ -4860,10 +4858,7 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 
 	scanned = isolate_folios(nr_to_scan, lruvec, sc, swappiness, &type, &list);
 
-	scanned += try_to_inc_min_seq(lruvec, swappiness);
-
-	if (evictable_min_seq(lrugen->min_seq, swappiness) + MIN_NR_GENS > lrugen->max_seq)
-		scanned = 0;
+	try_to_inc_min_seq(lruvec, swappiness);
 
 	lruvec_unlock_irq(lruvec);
 

-- 
2.53.0

