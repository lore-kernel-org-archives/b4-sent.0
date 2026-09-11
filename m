From: Kairui Song <kasong@tencent.com>
Date: Fri, 11 Sep 2026 19:45:16 +0800
Subject: [PATCH RFC v2 13/15] mm/mglru: make folio_inc_lru_refs lruvec
 lockless
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-mglru-fg-v2-13-f26e5cb26da7@tencent.com>
References: <20260911-mglru-fg-v2-0-f26e5cb26da7@tencent.com>
In-Reply-To: <20260911-mglru-fg-v2-0-f26e5cb26da7@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <qi.zheng@linux.dev>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Chris Li <chrisl@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, Zi Yan <ziy@nvidia.com>, 
 Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SeongJae Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Chen Ridong <chenridong@xiaomi.com>, 
 Tal Zussman <tz2294@columbia.edu>, Kairui Song <ryncsn@gmail.com>, 
 zhaozhengzhuo <zhaozhengzhuo@uniontech.com>, linux-kernel@vger.kernel.org, 
 cgroups@vger.kernel.org, Kairui Song <kasong@tencent.com>, 
 Nico Pache <nico.pache@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789127107; l=5413;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=qsSEp2ETBhYitLGlOVBAtq/PfXkJQgb2Hmat92vvGJg=;
 b=l8a+8v6n/1QzmI7ilkWtjQPVIgmIJTsD3dquNkK6HfeVXxZOTqeddMwskrazQKI3froEPK8Fo
 oMTMAJIVNsdAPPdbneLuKsC39Q+bijNPcrllJ2Ajiq3dP+S6HphaauW
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The lruvec spinlock in folio_inc_lru_refs was only taken to keep
concurrent aging from corrupting the size counters.  This is no
longer needed: the per-generation counters are atomic, and the
active/inactive ABI counters are updated per folio and linearized by
the CAS on the folio flags, so concurrent aging can no longer corrupt
them.  The same argument already allowed folio_reset_lru_refs() to
drop the lock.

Use folio_lruvec_live_get()/folio_lruvec_live_put() to hold the RCU
read lock around the lruvec lookup, and drop the spinlock entirely.

Also simplify the post-CAS accounting guards: gen is only assigned
non-negative values after the old_gen < 0 early exit, so gen != old_gen
implies gen >= 0, and lru_gen_update_size() needs no explicit guard.
The active/inactive ABI update keeps its gen >= 0 check because an
off-LRU folio has no lruvec to update.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm_inline.h | 10 +++++-----
 mm/vmscan.c               | 30 ++++++++++++++++--------------
 2 files changed, 21 insertions(+), 19 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index 686294fe81b8..bca00599dec6 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -293,10 +293,9 @@ static inline int folio_lru_gen(const struct folio *folio)
 	return lru_get_gen_flags(READ_ONCE(*const_folio_flags(folio, 0)));
 }
 
-static inline void lru_gen_update_size(struct lruvec *lruvec, struct folio *folio,
-				       int old_gen, int new_gen)
+static inline void lru_gen_update_size(struct lruvec *lruvec, int type,
+		struct folio *folio, int old_gen, int new_gen)
 {
-	int type = folio_is_file_lru(folio);
 	int zone = folio_zonenum(folio);
 	int delta = folio_nr_pages(folio);
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
@@ -371,7 +370,7 @@ static inline bool lru_gen_add_folio(struct lruvec *lruvec, struct folio *folio,
 	/* use the refs from the atomic snapshot to avoid raced update */
 	refs = lru_get_refs_flags(flags);
 
-	lru_gen_update_size(lruvec, folio, -1, gen);
+	lru_gen_update_size(lruvec, type, folio, -1, gen);
 	if (lru_refs_is_active(refs))
 		lru += LRU_ACTIVE;
 	__update_lru_size(lruvec, lru, zone, delta);
@@ -389,6 +388,7 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 {
 	unsigned long flags;
 	int gen, refs;
+	int type = folio_is_file_lru(folio);
 	int zone = folio_zonenum(folio);
 	int delta = folio_nr_pages(folio);
 	enum lru_list lru = folio_is_file_lru(folio) * LRU_INACTIVE_FILE;
@@ -411,7 +411,7 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 	if (!reclaiming && ((max_seq - gen) % MAX_NR_GENS) < MIN_NR_GENS)
 		folio_set_active(folio);
 
-	lru_gen_update_size(lruvec, folio, gen, -1);
+	lru_gen_update_size(lruvec, type, folio, gen, -1);
 	if (lru_refs_is_active(refs))
 		lru += LRU_ACTIVE;
 	__update_lru_size(lruvec, lru, zone, -delta);
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 240a8747490a..9deeb40fd5f3 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -960,16 +960,8 @@ void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
 		gen = old_gen;
 		if (old_gen < 0)
 			goto out;
-		/*
-		 * Lock the lruvec if the folio is on-list. We are already
-		 * doing lazy promotion so in theory we don't need this,
-		 * but for now, concurrent aging would still corrupt the
-		 * size counters.  This is a temporary limitation and
-		 * will be lifted very soon, so the lock here is not a
-		 * performance concern.
-		 */
 		if (!lruvec) {
-			lruvec = lruvec_live_lock_irq(folio_lruvec(folio));
+			lruvec = folio_lruvec_live_get(folio);
 			lrugen = &lruvec->lrugen;
 		}
 		max_seq = READ_ONCE(lrugen->max_seq);
@@ -1001,9 +993,19 @@ void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
 			lru_set_gen_flags(&new_flags, gen);
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
-	if (gen != old_gen)
-		lru_gen_update_size(lruvec, folio, old_gen, gen);
-	if (lru_refs_is_active(old_refs) != lru_refs_is_active(refs) && old_gen >= 0) {
+	if (gen != old_gen) {
+		lru_gen_update_size(lruvec, file, folio, old_gen, gen);
+		/*
+		 * Gen can only go forward while on list, so concurrent aging
+		 * is fine, except when multiple aging increase max_seq cross
+		 * the sliding window border causing hotness inversion. In that
+		 * very unlikely case, just activate the folio.
+		 */
+		if (unlikely(READ_ONCE(lrugen->max_seq) - max_seq > MIN_NR_GENS))
+			folio_activate(folio);
+	}
+
+	if (lru_refs_is_active(old_refs) != lru_refs_is_active(refs) && gen >= 0) {
 		enum lru_list lru = file * LRU_INACTIVE_FILE;
 
 		__update_lru_size(lruvec, lru + lru_refs_is_active(old_refs),
@@ -1012,7 +1014,7 @@ void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
 				  folio_zonenum(folio), nr_pages);
 	}
 	if (lruvec)
-		lruvec_unlock_irq(lruvec);
+		folio_lruvec_live_put(lruvec);
 }
 
 /**
@@ -3590,7 +3592,7 @@ static int folio_inc_gen(struct lruvec *lruvec, struct folio *folio)
 
 	new_gen = __folio_inc_gen(lruvec, folio, old_gen, &gen_increased);
 	if (gen_increased)
-		lru_gen_update_size(lruvec, folio, old_gen, new_gen);
+		lru_gen_update_size(lruvec, type, folio, old_gen, new_gen);
 
 	return new_gen;
 }

-- 
2.55.0

