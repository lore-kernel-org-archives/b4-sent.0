From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:15 +0800
Subject: [PATCH RFC 29/32] mm/mglru: convert avg_total and avg_refaulted to
 atomic
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-29-913619b014d9@tencent.com>
References: <20260502-mglru-fg-v1-0-913619b014d9@tencent.com>
In-Reply-To: <20260502-mglru-fg-v1-0-913619b014d9@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Youngjun Park <youngjun.park@lge.com>, 
 Zi Yan <ziy@nvidia.com>, Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Nico Pache <npache@redhat.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SeongJae Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, 
 Chen Ridong <chenridong@huaweicloud.com>, Tal Zussman <tz2294@columbia.edu>, 
 Kairui Song <ryncsn@gmail.com>, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=3247;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=hmT6vqop0NqUJUmZIf0OMLsTgQI+2TaaPPU/LnVzSzc=;
 b=g+0w/grZtdu1EfjPTqryehzK0cTREjDFDKafsOtlliKbG3uXxYucXFymfVL6KoJwofcPFE2cs
 gfKrnc8/qUECWpRaVLAaJ6HpGiIuc964Lmc3JDsXDYQuw5ArvJXTStI
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No feature change, make it possible to update these value parallelly.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mmzone.h |  4 ++--
 mm/vmscan.c            | 16 ++++++++--------
 2 files changed, 10 insertions(+), 10 deletions(-)

diff --git a/include/linux/mmzone.h b/include/linux/mmzone.h
index 6747e1c6079c..aa27627b0406 100644
--- a/include/linux/mmzone.h
+++ b/include/linux/mmzone.h
@@ -603,9 +603,9 @@ struct lru_gen_folio {
 	/* the multi-gen LRU sizes, eventually consistent */
 	atomic_long_t nr_pages[MAX_NR_GENS][ANON_AND_FILE][MAX_NR_ZONES];
 	/* the exponential moving average of refaulted */
-	unsigned long avg_refaulted[ANON_AND_FILE][MAX_NR_TIERS];
+	atomic_long_t avg_refaulted[ANON_AND_FILE][MAX_NR_TIERS];
 	/* the exponential moving average of evicted+protected */
-	unsigned long avg_total[ANON_AND_FILE][MAX_NR_TIERS];
+	atomic_long_t avg_total[ANON_AND_FILE][MAX_NR_TIERS];
 	/* can only be modified under the LRU lock */
 	unsigned long protected[NR_HIST_GENS][ANON_AND_FILE][MAX_NR_TIERS];
 	/* can be modified without holding the LRU lock */
diff --git a/mm/vmscan.c b/mm/vmscan.c
index e6631ad03caa..22e77450c1b4 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -3140,9 +3140,9 @@ static void read_ctrl_pos(struct lruvec *lruvec, int type, int tier, int gain,
 	pos->refaulted = pos->total = 0;
 
 	for (i = tier % MAX_NR_TIERS; i <= min(tier, MAX_NR_TIERS - 1); i++) {
-		pos->refaulted += lrugen->avg_refaulted[type][i] +
+		pos->refaulted += atomic_long_read(&lrugen->avg_refaulted[type][i]) +
 				  atomic_long_read(&lrugen->refaulted[hist][type][i]);
-		pos->total += lrugen->avg_total[type][i] +
+		pos->total += atomic_long_read(&lrugen->avg_total[type][i]) +
 			      lrugen->protected[hist][type][i] +
 			      atomic_long_read(&lrugen->evicted[hist][type][i]);
 	}
@@ -3166,14 +3166,14 @@ static void reset_ctrl_pos(struct lruvec *lruvec, int type, bool carryover)
 		if (carryover) {
 			unsigned long sum;
 
-			sum = lrugen->avg_refaulted[type][tier] +
+			sum = atomic_long_read(&lrugen->avg_refaulted[type][tier]) +
 			      atomic_long_read(&lrugen->refaulted[hist][type][tier]);
-			WRITE_ONCE(lrugen->avg_refaulted[type][tier], sum / 2);
+			atomic_long_set(&lrugen->avg_refaulted[type][tier], sum / 2);
 
-			sum = lrugen->avg_total[type][tier] +
+			sum = atomic_long_read(&lrugen->avg_total[type][tier]) +
 			      lrugen->protected[hist][type][tier] +
 			      atomic_long_read(&lrugen->evicted[hist][type][tier]);
-			WRITE_ONCE(lrugen->avg_total[type][tier], sum / 2);
+			atomic_long_set(&lrugen->avg_total[type][tier], sum / 2);
 		}
 
 		if (clear) {
@@ -5466,8 +5466,8 @@ static void lru_gen_seq_show_full(struct seq_file *m, struct lruvec *lruvec,
 
 			if (seq == max_seq) {
 				s = "RTx";
-				n[0] = READ_ONCE(lrugen->avg_refaulted[type][tier]);
-				n[1] = READ_ONCE(lrugen->avg_total[type][tier]);
+				n[0] = atomic_long_read(&lrugen->avg_refaulted[type][tier]);
+				n[1] = atomic_long_read(&lrugen->avg_total[type][tier]);
 			} else if (seq == min_seq[type] || NR_HIST_GENS > 1) {
 				s = "rep";
 				n[0] = atomic_long_read(&lrugen->refaulted[hist][type][tier]);

-- 
2.54.0

