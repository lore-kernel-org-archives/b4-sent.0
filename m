From: Kairui Song <kasong@tencent.com>
Date: Mon, 13 Apr 2026 00:48:23 +0800
Subject: [PATCH v5 09/14] mm/mglru: use the common routine for
 dirty/writeback reactivation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260413-mglru-reclaim-v5-9-8eaeacbddc44@tencent.com>
References: <20260413-mglru-reclaim-v5-0-8eaeacbddc44@tencent.com>
In-Reply-To: <20260413-mglru-reclaim-v5-0-8eaeacbddc44@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776012497; l=3145;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=/X4tLveOy+BYFW/Zy6+R0vMXPcNqV+3IgOLhWgyGVaY=;
 b=O73Zv+vYMZOn0sSZ+5JRY/iW+5z8qjEomyZSYRa7iYd8d7HTuSFm3QlJFJHOQUPFzgVCGADc0
 z3J0NZSLEgLA93OaJZwauHtgqcKd97qysgKlk/iHPlY2ttyQqx8TKZE
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently MGLRU will move the dirty writeback folios to the second
oldest gen instead of reactivate them like the classical LRU. This
might help to reduce the LRU contention as it skipped the isolation.
But as a result we will see these folios at the LRU tail more frequently
leading to inefficient reclaim.

Besides, the dirty / writeback check after isolation in
shrink_folio_list is more accurate and covers more cases. So instead,
just drop the special handling for dirty writeback, use the common
routine and re-activate it like the classical LRU.

This should in theory improve the scan efficiency. These folios will be
rotated back to LRU tail once writeback is done so there is no risk of
hotness inversion. And now each reclaim loop will have a higher
success rate. This also prepares for unifying the writeback and
throttling mechanism with classical LRU, we keep these folios far from
tail so detecting the tail batch will have a similar pattern with
classical LRU.

The micro optimization that avoids LRU contention by skipping the
isolation is gone, which should be fine. Compared to IO and writeback
cost, the isolation overhead is trivial.

And using the common routine also keeps the folio's referenced bits
(tier bits), which could improve metrics in the long term. Also no
more need to clean reclaim bit as the common routine will make use
of it.

Note the common routine updates a few throttling and writeback counters,
which are not used, and never have been for the MGLRU case. We will
start making use of these in later commits.

Reviewed-by: Axel Rasmussen <axelrasmussen@google.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 19 -------------------
 1 file changed, 19 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 965d8905a4fe..d63ac03a7266 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4578,7 +4578,6 @@ static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_c
 		       int tier_idx)
 {
 	bool success;
-	bool dirty, writeback;
 	int gen = folio_lru_gen(folio);
 	int type = folio_is_file_lru(folio);
 	int zone = folio_zonenum(folio);
@@ -4628,21 +4627,6 @@ static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_c
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
 
@@ -4664,9 +4648,6 @@ static bool isolate_folio(struct lruvec *lruvec, struct folio *folio, struct sca
 	if (!folio_test_referenced(folio))
 		set_mask_bits(&folio->flags.f, LRU_REFS_MASK, 0);
 
-	/* for shrink_folio_list() */
-	folio_clear_reclaim(folio);
-
 	success = lru_gen_del_folio(lruvec, folio, true);
 	VM_WARN_ON_ONCE_FOLIO(!success, folio);
 

-- 
2.53.0

