From: Kairui Song <kasong@tencent.com>
Date: Fri, 03 Apr 2026 02:53:29 +0800
Subject: [PATCH v3 03/14] mm/mglru: relocate the LRU scan batch limit to
 callers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-mglru-reclaim-v3-3-a285efd6ff91@tencent.com>
References: <20260403-mglru-reclaim-v3-0-a285efd6ff91@tencent.com>
In-Reply-To: <20260403-mglru-reclaim-v3-0-a285efd6ff91@tencent.com>
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
 Qi Zheng <qi.zheng@linux.dev>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775156018; l=3260;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=t1HUAx5d1QFG9Hfnk5BrzG1D63onxNMjgtf1TQ7zmGc=;
 b=GOjNFgd9u+a6HEbec8EHvZzLzVytLP1RAikjRqZr9s0k06yP5i/tq4xusoK34nfAQQAD+B6LE
 PMP181WbUVHCL1WzYp0UrS49WfvMRLmOi3pDESCUEKVzbA5lYoqSf0m
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Same as active / inactive LRU, MGLRU isolates and scans folios in
batches.  The batch split is done hidden deep in the helper, which
makes the code harder to follow.  The helper's arguments are also
confusing since callers usually request more folios than the batch
size, so the helper almost never processes the full requested amount.

Move the batch splitting into the top loop to make it cleaner, there
should be no behavior change.

Reviewed-by: Axel Rasmussen <axelrasmussen@google.com>
Reviewed-by: Baolin Wang <baolin.wang@linux.alibaba.com>
Reviewed-by: Barry Song <baohua@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 16 +++++++++-------
 1 file changed, 9 insertions(+), 7 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index f336f89a2de6..963362523782 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4695,10 +4695,10 @@ static int scan_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 	int scanned = 0;
 	int isolated = 0;
 	int skipped = 0;
-	int scan_batch = min(nr_to_scan, MAX_LRU_BATCH);
-	int remaining = scan_batch;
+	unsigned long remaining = nr_to_scan;
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 
+	VM_WARN_ON_ONCE(nr_to_scan > MAX_LRU_BATCH);
 	VM_WARN_ON_ONCE(!list_empty(list));
 
 	if (get_nr_gens(lruvec, type) == MIN_NR_GENS)
@@ -4751,7 +4751,7 @@ static int scan_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 	mod_lruvec_state(lruvec, item, isolated);
 	mod_lruvec_state(lruvec, PGREFILL, sorted);
 	mod_lruvec_state(lruvec, PGSCAN_ANON + type, isolated);
-	trace_mm_vmscan_lru_isolate(sc->reclaim_idx, sc->order, scan_batch,
+	trace_mm_vmscan_lru_isolate(sc->reclaim_idx, sc->order, nr_to_scan,
 				scanned, skipped, isolated,
 				type ? LRU_INACTIVE_FILE : LRU_INACTIVE_ANON);
 	if (type == LRU_GEN_FILE)
@@ -4987,7 +4987,7 @@ static bool should_abort_scan(struct lruvec *lruvec, struct scan_control *sc)
 
 static bool try_to_shrink_lruvec(struct lruvec *lruvec, struct scan_control *sc)
 {
-	long nr_to_scan;
+	long nr_batch, nr_to_scan;
 	unsigned long scanned = 0;
 	int swappiness = get_swappiness(lruvec, sc);
 
@@ -4998,7 +4998,8 @@ static bool try_to_shrink_lruvec(struct lruvec *lruvec, struct scan_control *sc)
 		if (nr_to_scan <= 0)
 			break;
 
-		delta = evict_folios(nr_to_scan, lruvec, sc, swappiness);
+		nr_batch = min(nr_to_scan, MAX_LRU_BATCH);
+		delta = evict_folios(nr_batch, lruvec, sc, swappiness);
 		if (!delta)
 			break;
 
@@ -5623,6 +5624,7 @@ static int run_aging(struct lruvec *lruvec, unsigned long seq,
 static int run_eviction(struct lruvec *lruvec, unsigned long seq, struct scan_control *sc,
 			int swappiness, unsigned long nr_to_reclaim)
 {
+	int nr_batch;
 	DEFINE_MAX_SEQ(lruvec);
 
 	if (seq + MIN_NR_GENS > max_seq)
@@ -5639,8 +5641,8 @@ static int run_eviction(struct lruvec *lruvec, unsigned long seq, struct scan_co
 		if (sc->nr_reclaimed >= nr_to_reclaim)
 			return 0;
 
-		if (!evict_folios(nr_to_reclaim - sc->nr_reclaimed, lruvec, sc,
-				  swappiness))
+		nr_batch = min(nr_to_reclaim - sc->nr_reclaimed, MAX_LRU_BATCH);
+		if (!evict_folios(nr_batch, lruvec, sc, swappiness))
 			return 0;
 
 		cond_resched();

-- 
2.53.0

