From: Kairui Song <kasong@tencent.com>
Date: Wed, 18 Mar 2026 03:09:03 +0800
Subject: [PATCH 7/8] mm/mglru: simplify and improve dirty writeback
 handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-mglru-reclaim-v1-7-2c46f9eb0508@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773774704; l=6525;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=4v8IMSBCol6NW26BtD5Q/L1ClDP1BcPSL9T6s99BSk4=;
 b=ogWGF6m9Kn1C0l8kcePmuURjvWxNqfs0Nq5qylyh8k5Lu9lBZj1aLlqafYXwCtj1m+qUBfcfX
 GlyrobjCyxTBuGGdl87zTSoMBm9jDi7IXnMMfQTqP+yFeDoz9Q+gqi6
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current handling of dirty writeback folios is not working well for
file page heavy workloads: Dirty folios are protected and move to next
gen upon isolation of getting throttled or reactivated upon pageout
(shrink_folio_list).

This might help to reduce the LRU lock contention slightly, but as a
result, the ping-pong effect of folios between head and tail of last two
gens is serious as the shrinker will run into protected dirty writeback
folios more frequently compared to activation. The dirty flush wakeup
condition is also much more passive compared to active/inactive LRU.
Active / inactve LRU wakes the flusher if one batch of folios passed to
shrink_folio_list is unevictable due to under writeback, but MGLRU
instead has to check this after the whole reclaim loop is done, and then
count the isolation protection number compared to the total reclaim
number.

And we previously saw OOM problems with it, too, which were fixed but
still not perfect [1].

So instead, just drop the special handling for dirty writeback, just
re-activate it like active / inactive LRU. And also move the dirty flush
wake up check right after shrink_folio_list. This should improve both
throttling and performance.

Test with YCSB workloadb showed a major performance improvement:

Before this series:
Throughput(ops/sec): 61642.78008938203
AverageLatency(us):  507.11127774145166
pgpgin 158190589
pgpgout 5880616
workingset_refault 7262988

After this commit:
Throughput(ops/sec): 80216.04855744806  (+30.1%, higher is better)
AverageLatency(us):  388.17633477268913 (-23.5%, lower is better)
pgpgin 101871227                        (-35.6%, lower is better)
pgpgout 5770028
workingset_refault 3418186              (-52.9%, lower is better)

The refault rate is 50% lower, and throughput is 30% higher, which is a
huge gain. We also observed significant performance gain for other
real-world workloads.

We were concerned that the dirty flush could cause more wear for SSD:
that should not be the problem here, since the wakeup condition is when
the dirty folios have been pushed to the tail of LRU, which indicates
that memory pressure is so high that writeback is blocking the workload
already.

Signed-off-by: Kairui Song <kasong@tencent.com>
Link: https://lore.kernel.org/linux-mm/20241026115714.1437435-1-jingxiangzeng.cas@gmail.com/ [1]
---
 mm/vmscan.c | 44 +++++++++++++-------------------------------
 1 file changed, 13 insertions(+), 31 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index b26959d90850..e11d0f1a8b68 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4577,7 +4577,6 @@ static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_c
 		       int tier_idx)
 {
 	bool success;
-	bool dirty, writeback;
 	int gen = folio_lru_gen(folio);
 	int type = folio_is_file_lru(folio);
 	int zone = folio_zonenum(folio);
@@ -4627,21 +4626,6 @@ static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_c
 		return true;
 	}
 
-	dirty = folio_test_dirty(folio);
-	writeback = folio_test_writeback(folio);
-	if (type == LRU_GEN_FILE && dirty) {
-		sc->nr.file_taken += delta;
-		if (!writeback)
-			sc->nr.unqueued_dirty += delta;
-	}
-
-	/* waiting for writeback */
-	if (writeback || (type == LRU_GEN_FILE && dirty)) {
-		gen = folio_inc_gen(lruvec, folio, true);
-		list_move(&folio->lru, &lrugen->folios[gen][type][zone]);
-		return true;
-	}
-
 	return false;
 }
 
@@ -4748,8 +4732,6 @@ static int scan_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 	trace_mm_vmscan_lru_isolate(sc->reclaim_idx, sc->order, nr_to_scan,
 				scanned, skipped, isolated,
 				type ? LRU_INACTIVE_FILE : LRU_INACTIVE_ANON);
-	if (type == LRU_GEN_FILE)
-		sc->nr.file_taken += isolated;
 
 	*isolatedp = isolated;
 	return scanned;
@@ -4814,11 +4796,11 @@ static int get_type_to_scan(struct lruvec *lruvec, int swappiness)
 
 static int isolate_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 			  struct scan_control *sc, int swappiness,
-			  int *type_scanned, struct list_head *list)
+			  int *type_scanned,
+			  struct list_head *list, int *isolated)
 {
 	int i;
 	int scanned = 0;
-	int isolated = 0;
 	int type = get_type_to_scan(lruvec, swappiness);
 
 	for_each_evictable_type(i, swappiness) {
@@ -4827,8 +4809,8 @@ static int isolate_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 		*type_scanned = type;
 
 		scanned += scan_folios(nr_to_scan, lruvec, sc,
-				      type, tier, list, &isolated);
-		if (isolated)
+				      type, tier, list, isolated);
+		if (*isolated)
 			return scanned;
 
 		type = !type;
@@ -4843,6 +4825,7 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 	int type;
 	int scanned;
 	int reclaimed;
+	int isolated = 0;
 	LIST_HEAD(list);
 	LIST_HEAD(clean);
 	struct folio *folio;
@@ -4856,7 +4839,7 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 
 	lruvec_lock_irq(lruvec);
 
-	scanned = isolate_folios(nr_to_scan, lruvec, sc, swappiness, &type, &list);
+	scanned = isolate_folios(nr_to_scan, lruvec, sc, swappiness, &type, &list, &isolated);
 
 	try_to_inc_min_seq(lruvec, swappiness);
 
@@ -4866,12 +4849,18 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 		return scanned;
 retry:
 	reclaimed = shrink_folio_list(&list, pgdat, sc, &stat, false, memcg);
-	sc->nr.unqueued_dirty += stat.nr_unqueued_dirty;
 	sc->nr_reclaimed += reclaimed;
 	trace_mm_vmscan_lru_shrink_inactive(pgdat->node_id,
 			scanned, reclaimed, &stat, sc->priority,
 			type ? LRU_INACTIVE_FILE : LRU_INACTIVE_ANON);
 
+	/*
+	 * If too many file cache in the coldest generation can't be evicted
+	 * due to being dirty, wake up the flusher.
+	 */
+	if (stat.nr_unqueued_dirty == isolated)
+		wakeup_flusher_threads(WB_REASON_VMSCAN);
+
 	list_for_each_entry_safe_reverse(folio, next, &list, lru) {
 		DEFINE_MIN_SEQ(lruvec);
 
@@ -5023,13 +5012,6 @@ static bool try_to_shrink_lruvec(struct lruvec *lruvec, struct scan_control *sc)
 		cond_resched();
 	}
 
-	/*
-	 * If too many file cache in the coldest generation can't be evicted
-	 * due to being dirty, wake up the flusher.
-	 */
-	if (sc->nr.unqueued_dirty && sc->nr.unqueued_dirty == sc->nr.file_taken)
-		wakeup_flusher_threads(WB_REASON_VMSCAN);
-
 	/* whether this lruvec should be rotated */
 	return need_rotate;
 }

-- 
2.53.0

