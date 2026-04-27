From: Kairui Song <kasong@tencent.com>
Date: Tue, 28 Apr 2026 02:06:52 +0800
Subject: [PATCH v7 01/15] mm/mglru: consolidate common code for retrieving
 evictable size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-mglru-reclaim-v7-1-02fabb92dc43@tencent.com>
References: <20260428-mglru-reclaim-v7-0-02fabb92dc43@tencent.com>
In-Reply-To: <20260428-mglru-reclaim-v7-0-02fabb92dc43@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Kairui Song <kasong@tencent.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Michal Hocko <mhocko@kernel.org>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 David Stevens <stevensd@google.com>, 
 Chen Ridong <chenridong@huaweicloud.com>, Leno Hou <lenohou@gmail.com>, 
 Yafang Shao <laoar.shao@gmail.com>, Yu Zhao <yuzhao@google.com>, 
 Zicheng Wang <wangzicheng@honor.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Kalesh Singh <kaleshsingh@google.com>, 
 Suren Baghdasaryan <surenb@google.com>, Chris Li <chrisl@kernel.org>, 
 Vernon Yang <vernon2gm@gmail.com>, linux-kernel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kairui Song <ryncsn@gmail.com>, 
 Qi Zheng <qi.zheng@linux.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777313217; l=3107;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=Y3kkkb3C3sOmTNRwB81JWRKI8V4j68zDrNpkhlE+boo=;
 b=0CL/lEP4LfHtocAYd24RRpXvBtZg+qnGZk3sapZjnVvC/jbObXoa8fpMb8U4ycnX0017WnoJl
 8+JVaUBlFe4DX35z+D/F4kUuqs3ratkMEnO/emJ6E4lGATKi+qpT3GL
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Merge commonly used code for counting evictable folios in a lruvec.

No behavior change.

Acked-by: Yuanchu Xie <yuanchu@google.com>
Reviewed-by: Barry Song <baohua@kernel.org>
Reviewed-by: Chen Ridong <chenridong@huaweicloud.com>
Reviewed-by: Axel Rasmussen <axelrasmussen@google.com>
Reviewed-by: Baolin Wang <baolin.wang@linux.alibaba.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 36 ++++++++++++++----------------------
 1 file changed, 14 insertions(+), 22 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index b2d89ed69d22..b80fbc4fc285 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4084,27 +4084,33 @@ static void set_initial_priority(struct pglist_data *pgdat, struct scan_control
 	sc->priority = clamp(priority, DEF_PRIORITY / 2, DEF_PRIORITY);
 }
 
-static bool lruvec_is_sizable(struct lruvec *lruvec, struct scan_control *sc)
+static unsigned long lruvec_evictable_size(struct lruvec *lruvec, int swappiness)
 {
 	int gen, type, zone;
-	unsigned long total = 0;
-	int swappiness = get_swappiness(lruvec, sc);
+	unsigned long seq, total = 0;
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
-	struct mem_cgroup *memcg = lruvec_memcg(lruvec);
 	DEFINE_MAX_SEQ(lruvec);
 	DEFINE_MIN_SEQ(lruvec);
 
 	for_each_evictable_type(type, swappiness) {
-		unsigned long seq;
-
 		for (seq = min_seq[type]; seq <= max_seq; seq++) {
 			gen = lru_gen_from_seq(seq);
-
 			for (zone = 0; zone < MAX_NR_ZONES; zone++)
 				total += max(READ_ONCE(lrugen->nr_pages[gen][type][zone]), 0L);
 		}
 	}
 
+	return total;
+}
+
+static bool lruvec_is_sizable(struct lruvec *lruvec, struct scan_control *sc)
+{
+	unsigned long total;
+	int swappiness = get_swappiness(lruvec, sc);
+	struct mem_cgroup *memcg = lruvec_memcg(lruvec);
+
+	total = lruvec_evictable_size(lruvec, swappiness);
+
 	/* whether the size is big enough to be helpful */
 	return mem_cgroup_online(memcg) ? (total >> sc->priority) : total;
 }
@@ -4909,9 +4915,6 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 static bool should_run_aging(struct lruvec *lruvec, unsigned long max_seq,
 			     int swappiness, unsigned long *nr_to_scan)
 {
-	int gen, type, zone;
-	unsigned long size = 0;
-	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 	DEFINE_MIN_SEQ(lruvec);
 
 	*nr_to_scan = 0;
@@ -4919,18 +4922,7 @@ static bool should_run_aging(struct lruvec *lruvec, unsigned long max_seq,
 	if (evictable_min_seq(min_seq, swappiness) + MIN_NR_GENS > max_seq)
 		return true;
 
-	for_each_evictable_type(type, swappiness) {
-		unsigned long seq;
-
-		for (seq = min_seq[type]; seq <= max_seq; seq++) {
-			gen = lru_gen_from_seq(seq);
-
-			for (zone = 0; zone < MAX_NR_ZONES; zone++)
-				size += max(READ_ONCE(lrugen->nr_pages[gen][type][zone]), 0L);
-		}
-	}
-
-	*nr_to_scan = size;
+	*nr_to_scan = lruvec_evictable_size(lruvec, swappiness);
 	/* better to run aging even though eviction is still possible */
 	return evictable_min_seq(min_seq, swappiness) + MIN_NR_GENS == max_seq;
 }

-- 
2.54.0

