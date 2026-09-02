From: Kairui Song <kasong@tencent.com>
Date: Wed, 02 Sep 2026 17:50:54 +0800
Subject: [PATCH v5 1/6] mm/memcontrol: move the lru_zone_size sanity check
 to the reader side
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-mglru-flags-cleanup-v5-1-9db761d779ef@tencent.com>
References: <20260902-mglru-flags-cleanup-v5-0-9db761d779ef@tencent.com>
In-Reply-To: <20260902-mglru-flags-cleanup-v5-0-9db761d779ef@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Baoquan He <baoquan.he@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Muchun Song <muchun.song@linux.dev>, Chris Li <chrisl@kernel.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Ridong Chen <ridong.chen@linux.dev>, Lian Wang <lianux.mm@gmail.com>, 
 Yu Zhao <yuzhao@google.com>, Zi Yan <ziy@nvidia.com>, 
 Qi Zheng <qi.zheng@linux.dev>, cgroups@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kairui Song <ryncsn@gmail.com>, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788342657; l=4138;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=QI6bvhReGHb4fOvBljBjwiJV5Y8Bw1C5l29qeBm+tPA=;
 b=zq0mgu+IKjbAnDIaSkFgx6KtQr5EysUe2PZDWpe8eFGP89GdZJw9RhoxJ5PBrmbNBR5CRJC7N
 NNim/6E9hoaCYsBGaC7VgOuRQeEsD+geKaWaOzKjSEnNcKCREhoD5eE
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of using an unsigned long and checking the counter value at
the updater side, turn the counter into a signed long and check at the
reader side. This reduces overhead and simplifies the code.

commit ca707239e8a7 ("mm: update_lru_size warn and reset bad lru_size")
added a sanity check for memcg counter underflow: lru_zone_size is
unsigned, so an underflow wraps it around and returns an enormously
large number, then the memcg shrinker loops almost forever as the
calculated number of folios to shrink is huge. It also checked if a
zero value matches the empty LRU list, so the positive and negative
deltas had to be handled separately. However that emptiness check was
already removed by commit b4536f0c829c ("mm, memcg: fix the active list
aging for lowmem requests when memcg is enabled"), so handling the
deltas separately is no longer needed.

The remaining update-side check is costly and cannot really catch the
leak it is after anyway. It runs on every LRU folio, and if a folio was
removed without updating the counter while other folios remain on the
LRU, the WARN only triggers much later, from a likely innocent
callsite. While readers are much rarer than writers, only the reclaim
and reparenting paths read it, once per batch.

Checking at the reader side instead leaves the update path a plain
addition, and puts the warning where the value is actually consumed.

Note this changes the behavior on underflow: the correction is removed
and a negative value is kept. A massive leak of the LRU size counter
would indicate that something else has gone very wrong, and one should
fix that leaking site instead. Besides, the original behavior might
cause false positives, or make things worse if the accounting happens
after the actual insertion: the value is not leaked, just delayed, so
force-fixing it would cause a bigger problem. The warning now only kicks
in when a consumer actually uses it, in which case the reader gets zero.

Reviewed-by: Ridong Chen <ridong.chen@linux.dev>
Reviewed-by: Barry Song <baohua@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/memcontrol.h |  9 +++++++--
 mm/memcontrol.c            | 18 +-----------------
 2 files changed, 8 insertions(+), 19 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index 7d1c0ce189a8..86780ef65eaf 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -113,7 +113,7 @@ struct mem_cgroup_per_node {
 	/* Fields which get updated often at the end. */
 	struct lruvec		lruvec;
 	CACHELINE_PADDING(_pad2_);
-	unsigned long		lru_zone_size[MAX_NR_ZONES][NR_LRU_LISTS];
+	long			lru_zone_size[MAX_NR_ZONES][NR_LRU_LISTS];
 	struct mem_cgroup_reclaim_iter	iter;
 
 	/*
@@ -902,10 +902,15 @@ static inline
 unsigned long mem_cgroup_get_zone_lru_size(struct lruvec *lruvec,
 		enum lru_list lru, int zone_idx)
 {
+	long val;
 	struct mem_cgroup_per_node *mz;
 
 	mz = container_of(lruvec, struct mem_cgroup_per_node, lruvec);
-	return READ_ONCE(mz->lru_zone_size[zone_idx][lru]);
+	val = READ_ONCE(mz->lru_zone_size[zone_idx][lru]);
+	if (WARN_ON_ONCE(val < 0))
+		return 0;
+
+	return val;
 }
 
 void __mem_cgroup_handle_over_high(gfp_t gfp_mask);
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 856a7d07586c..0a65ab8df27a 100644
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
+	mz->lru_zone_size[zid][lru] += nr_pages;
 }
 
 /**

-- 
2.55.0

