From: Kairui Song <kasong@tencent.com>
Date: Wed, 18 Mar 2026 03:08:57 +0800
Subject: [PATCH 1/8] mm/mglru: consolidate common code for retrieving
 evitable size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-mglru-reclaim-v1-1-2c46f9eb0508@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773774704; l=4083;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=oBDA7DoT+1LgZqzpmvPbT4X1VuiGCgQ8ao2nlrP+Kj0=;
 b=iHaahECT5wFn/8x3pOujy095P54IV+9WnkgMAUT2I1Czxg3d8ClJY6ZPN97ihTWBUn0bJjLoI
 zQT8vb5jG0fDeEZsBGFTXBGIzPWtlMUzmxDquBHFrTjaMGSvEq7rNk7
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Merge commonly used code for counting evictable folios in a lruvec.

No behavior change.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 42 +++++++++++++++++-------------------------
 1 file changed, 17 insertions(+), 25 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 33287ba4a500..d7fc7f1fe06d 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4078,27 +4078,33 @@ static void set_initial_priority(struct pglist_data *pgdat, struct scan_control
 	sc->priority = clamp(priority, DEF_PRIORITY / 2, DEF_PRIORITY);
 }
 
-static bool lruvec_is_sizable(struct lruvec *lruvec, struct scan_control *sc)
+static long lruvec_evictable_size(struct lruvec *lruvec, int swappiness)
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
@@ -4921,9 +4927,6 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 static bool should_run_aging(struct lruvec *lruvec, unsigned long max_seq,
 			     int swappiness, unsigned long *nr_to_scan)
 {
-	int gen, type, zone;
-	unsigned long size = 0;
-	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 	DEFINE_MIN_SEQ(lruvec);
 
 	*nr_to_scan = 0;
@@ -4931,18 +4934,7 @@ static bool should_run_aging(struct lruvec *lruvec, unsigned long max_seq,
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
@@ -4954,7 +4946,7 @@ static bool should_run_aging(struct lruvec *lruvec, unsigned long max_seq,
  */
 static long get_nr_to_scan(struct lruvec *lruvec, struct scan_control *sc, int swappiness)
 {
-	bool success;
+	bool need_aging;
 	unsigned long nr_to_scan;
 	struct mem_cgroup *memcg = lruvec_memcg(lruvec);
 	DEFINE_MAX_SEQ(lruvec);
@@ -4962,7 +4954,7 @@ static long get_nr_to_scan(struct lruvec *lruvec, struct scan_control *sc, int s
 	if (mem_cgroup_below_min(sc->target_mem_cgroup, memcg))
 		return -1;
 
-	success = should_run_aging(lruvec, max_seq, swappiness, &nr_to_scan);
+	need_aging = should_run_aging(lruvec, max_seq, swappiness, &nr_to_scan);
 
 	/* try to scrape all its memory if this memcg was deleted */
 	if (nr_to_scan && !mem_cgroup_online(memcg))
@@ -4971,7 +4963,7 @@ static long get_nr_to_scan(struct lruvec *lruvec, struct scan_control *sc, int s
 	nr_to_scan = apply_proportional_protection(memcg, sc, nr_to_scan);
 
 	/* try to get away with not aging at the default priority */
-	if (!success || sc->priority == DEF_PRIORITY)
+	if (!need_aging || sc->priority == DEF_PRIORITY)
 		return nr_to_scan >> sc->priority;
 
 	/* stop scanning this lruvec as it's low on cold folios */

-- 
2.53.0

