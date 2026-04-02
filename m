From: Kairui Song <kasong@tencent.com>
Date: Fri, 03 Apr 2026 02:53:33 +0800
Subject: [PATCH v3 07/14] mm/mglru: don't abort scan immediately right
 after aging
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-mglru-reclaim-v3-7-a285efd6ff91@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775156018; l=3449;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=bSy2f/NXeY/jTEGjpMc5skrp7OityVUKdYtvXUwM9i8=;
 b=QnCc+Y5vPX1EtMTnDjPqM98CZyYXa7TzJ9o1gvPr99U5A7mK5FSBlop3VqXGnX99Bxl5JRVJd
 4OapmGaqoHAA3OGBA0cf2x/09kPXxW6LXW+v/C+H3lSS/MVsGNiepHl
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Right now, if eviction triggers aging, the reclaimer will abort. This is
not the optimal strategy for several reasons.

Aborting the reclaim early wastes a reclaim cycle when under pressure,
and for concurrent reclaim, if the LRU is under aging, all concurrent
reclaimers might fail. And if the age has just finished, new cold folios
exposed by the aging are not reclaimed until the next reclaim iteration.

What's more, the current aging trigger is quite lenient, having 3 gens
with a reclaim priority lower than default will trigger aging, and
blocks reclaiming from one memcg. This wastes reclaim retry cycles
easily. And in the worst case, if the reclaim is making slower progress
and all following attempts fail due to being blocked by aging, it
triggers unexpected early OOM.

And if a lruvec requires aging, it doesn't mean it's hot. Instead, the
lruvec could be idle for quite a while, and hence it might contain lots
of cold folios to be reclaimed.

While it's helpful to rotate memcg LRU after aging for global reclaim,
as global reclaim fairness is coupled with the rotation in shrink_many,
memcg fairness is instead handled by cgroup iteration in
shrink_node_memcgs. So, for memcg level pressure, this abort is not the
key part for keeping the fairness. And in most cases, there is no need
to age, and fairness must be achieved by upper-level reclaim control.

So instead, just keep the scanning going unless one whole batch of
folios failed to be isolated or enough folios have been scanned, which
is triggered by evict_folios returning 0. And only abort for global
reclaim after one batch, so when there are fewer memcgs, progress is
still made, and the fairness mechanism described above still works fine.

And in most cases, the one more batch attempt for global reclaim might
just be enough to satisfy what the reclaimer needs, hence improving
global reclaim performance by reducing reclaim retry cycles.

Rotation is still there after the reclaim is done, which still follows
the comment in mmzone.h. And fairness still looking good.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 9c28afb0219c..b3371877762a 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4987,7 +4987,7 @@ static bool should_abort_scan(struct lruvec *lruvec, struct scan_control *sc)
  */
 static bool try_to_shrink_lruvec(struct lruvec *lruvec, struct scan_control *sc)
 {
-	bool need_rotate = false;
+	bool need_rotate = false, should_age = false;
 	long nr_batch, nr_to_scan;
 	int swappiness = get_swappiness(lruvec, sc);
 	struct mem_cgroup *memcg = lruvec_memcg(lruvec);
@@ -5005,7 +5005,7 @@ static bool try_to_shrink_lruvec(struct lruvec *lruvec, struct scan_control *sc)
 		if (should_run_aging(lruvec, max_seq, sc, swappiness)) {
 			if (try_to_inc_max_seq(lruvec, max_seq, swappiness, false))
 				need_rotate = true;
-			break;
+			should_age = true;
 		}
 
 		nr_batch = min(nr_to_scan, MIN_LRU_BATCH);
@@ -5016,6 +5016,10 @@ static bool try_to_shrink_lruvec(struct lruvec *lruvec, struct scan_control *sc)
 		if (should_abort_scan(lruvec, sc))
 			break;
 
+		/* For cgroup reclaim, fairness is handled by iterator, not rotation */
+		if (root_reclaim(sc) && should_age)
+			break;
+
 		nr_to_scan -= delta;
 		cond_resched();
 	}

-- 
2.53.0

