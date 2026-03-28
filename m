From: Kairui Song <kasong@tencent.com>
Date: Sun, 29 Mar 2026 03:52:28 +0800
Subject: [PATCH v2 02/12] mm/mglru: rename variables related to aging and
 rotation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260329-mglru-reclaim-v2-2-b53a3678513c@tencent.com>
References: <20260329-mglru-reclaim-v2-0-b53a3678513c@tencent.com>
In-Reply-To: <20260329-mglru-reclaim-v2-0-b53a3678513c@tencent.com>
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
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774727549; l=2780;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=/S4DxXkZbkmPymDZ4txoaa0S870DUGxVp3pt8OKH86o=;
 b=pAXljMxVpl/JontxkdHTDUsp9N8qbT9jY4ejGTIS5od5hogsVJMNr2Ts2tYOn2yIXqguzcG76
 SJV0Ty4ZYC2AXCeVrwYGiT0H3sxlzJDkoGBIVKBtITYnqp2xFDzeTQY
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current variable name isn't helpful. Make the variable names more
meaningful.

Only naming change, no behavior change.

Suggested-by: Barry Song <baohua@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index adc07501a137..f336f89a2de6 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4934,7 +4934,7 @@ static bool should_run_aging(struct lruvec *lruvec, unsigned long max_seq,
  */
 static long get_nr_to_scan(struct lruvec *lruvec, struct scan_control *sc, int swappiness)
 {
-	bool success;
+	bool need_aging;
 	unsigned long nr_to_scan;
 	struct mem_cgroup *memcg = lruvec_memcg(lruvec);
 	DEFINE_MAX_SEQ(lruvec);
@@ -4942,7 +4942,7 @@ static long get_nr_to_scan(struct lruvec *lruvec, struct scan_control *sc, int s
 	if (mem_cgroup_below_min(sc->target_mem_cgroup, memcg))
 		return -1;
 
-	success = should_run_aging(lruvec, max_seq, swappiness, &nr_to_scan);
+	need_aging = should_run_aging(lruvec, max_seq, swappiness, &nr_to_scan);
 
 	/* try to scrape all its memory if this memcg was deleted */
 	if (nr_to_scan && !mem_cgroup_online(memcg))
@@ -4951,7 +4951,7 @@ static long get_nr_to_scan(struct lruvec *lruvec, struct scan_control *sc, int s
 	nr_to_scan = apply_proportional_protection(memcg, sc, nr_to_scan);
 
 	/* try to get away with not aging at the default priority */
-	if (!success || sc->priority == DEF_PRIORITY)
+	if (!need_aging || sc->priority == DEF_PRIORITY)
 		return nr_to_scan >> sc->priority;
 
 	/* stop scanning this lruvec as it's low on cold folios */
@@ -5040,7 +5040,7 @@ static bool try_to_shrink_lruvec(struct lruvec *lruvec, struct scan_control *sc)
 
 static int shrink_one(struct lruvec *lruvec, struct scan_control *sc)
 {
-	bool success;
+	bool need_rotate;
 	unsigned long scanned = sc->nr_scanned;
 	unsigned long reclaimed = sc->nr_reclaimed;
 	struct mem_cgroup *memcg = lruvec_memcg(lruvec);
@@ -5058,7 +5058,7 @@ static int shrink_one(struct lruvec *lruvec, struct scan_control *sc)
 		memcg_memory_event(memcg, MEMCG_LOW);
 	}
 
-	success = try_to_shrink_lruvec(lruvec, sc);
+	need_rotate = try_to_shrink_lruvec(lruvec, sc);
 
 	shrink_slab(sc->gfp_mask, pgdat->node_id, memcg, sc->priority);
 
@@ -5068,10 +5068,10 @@ static int shrink_one(struct lruvec *lruvec, struct scan_control *sc)
 
 	flush_reclaim_state(sc);
 
-	if (success && mem_cgroup_online(memcg))
+	if (need_rotate && mem_cgroup_online(memcg))
 		return MEMCG_LRU_YOUNG;
 
-	if (!success && lruvec_is_sizable(lruvec, sc))
+	if (!need_rotate && lruvec_is_sizable(lruvec, sc))
 		return 0;
 
 	/* one retry if offlined or too small */

-- 
2.53.0

