From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:03:49 +0800
Subject: [PATCH RFC 03/32] mm/mglru: wrap all access to folio flags with
 accessor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-3-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=7063;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=08Uk+DXB3RZOMcAhxRkisbJ6KbJA8hUQR439Qy3O5lM=;
 b=KPwlw0vvTZCg+2YG2oAv4raYUSjN+YfzLdm0ytNJbQ93DQJD0LmoX3PWfR3ci+xShOYwcYaXv
 xNtRqOERu7hAaMtRSKQiNQNitjmcDDSeyoGL+avgAUWsFZklJdVxIzU
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of reading folio->flags.f, use the folio_flags helper which is
design exactly for this which more checks.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm_inline.h | 12 ++++++------
 mm/swap.c                 |  8 ++++----
 mm/vmscan.c               | 16 ++++++++--------
 3 files changed, 18 insertions(+), 18 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index 045f9ee3880a..9c8ad8af37de 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -143,7 +143,7 @@ static inline int lru_tier_from_refs(int refs, bool workingset)
 
 static inline int folio_lru_refs(const struct folio *folio)
 {
-	unsigned long flags = READ_ONCE(folio->flags.f);
+	unsigned long flags = READ_ONCE(*const_folio_flags(folio, 0));
 
 	if (!(flags & BIT(PG_referenced)))
 		return 0;
@@ -156,7 +156,7 @@ static inline int folio_lru_refs(const struct folio *folio)
 
 static inline int folio_lru_gen(const struct folio *folio)
 {
-	unsigned long flags = READ_ONCE(folio->flags.f);
+	unsigned long flags = READ_ONCE(*const_folio_flags(folio, 0));
 
 	return ((flags & LRU_GEN_MASK) >> LRU_GEN_PGOFF) - 1;
 }
@@ -269,7 +269,7 @@ static inline bool lru_gen_add_folio(struct lruvec *lruvec, struct folio *folio,
 	gen = lru_gen_from_seq(seq);
 	flags = (gen + 1UL) << LRU_GEN_PGOFF;
 	/* see the comment on MIN_NR_GENS about PG_active */
-	set_mask_bits(&folio->flags.f, LRU_GEN_MASK | BIT(PG_active), flags);
+	set_mask_bits(folio_flags(folio, 0), LRU_GEN_MASK | BIT(PG_active), flags);
 
 	lru_gen_update_size(lruvec, folio, -1, gen);
 	/* for folio_rotate_reclaimable() */
@@ -294,7 +294,7 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 
 	/* for folio_migrate_flags() */
 	flags = !reclaiming && lru_gen_is_active(lruvec, gen) ? BIT(PG_active) : 0;
-	flags = set_mask_bits(&folio->flags.f, LRU_GEN_MASK, flags);
+	flags = set_mask_bits(folio_flags(folio, 0), LRU_GEN_MASK, flags);
 	gen = ((flags & LRU_GEN_MASK) >> LRU_GEN_PGOFF) - 1;
 
 	lru_gen_update_size(lruvec, folio, gen, -1);
@@ -305,9 +305,9 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 
 static inline void folio_migrate_refs(struct folio *new, const struct folio *old)
 {
-	unsigned long refs = READ_ONCE(old->flags.f) & LRU_REFS_MASK;
+	unsigned long refs = READ_ONCE(*const_folio_flags(old, 0)) & LRU_REFS_MASK;
 
-	set_mask_bits(&new->flags.f, LRU_REFS_MASK, refs);
+	set_mask_bits(folio_flags(new, 0), LRU_REFS_MASK, refs);
 }
 #else /* !CONFIG_LRU_GEN */
 
diff --git a/mm/swap.c b/mm/swap.c
index e3cf703ccb89..e7037ea2c10f 100644
--- a/mm/swap.c
+++ b/mm/swap.c
@@ -392,14 +392,14 @@ static void __lru_cache_activate_folio(struct folio *folio)
 
 static void lru_gen_inc_refs(struct folio *folio)
 {
-	unsigned long new_flags, old_flags = READ_ONCE(folio->flags.f);
+	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
 
 	if (folio_test_unevictable(folio))
 		return;
 
 	/* see the comment on LRU_REFS_FLAGS */
 	if (!folio_test_referenced(folio)) {
-		set_mask_bits(&folio->flags.f, LRU_REFS_MASK, BIT(PG_referenced));
+		set_mask_bits(folio_flags(folio, 0), LRU_REFS_MASK, BIT(PG_referenced));
 		return;
 	}
 
@@ -411,7 +411,7 @@ static void lru_gen_inc_refs(struct folio *folio)
 		}
 
 		new_flags = old_flags + BIT(LRU_REFS_PGOFF);
-	} while (!try_cmpxchg(&folio->flags.f, &old_flags, new_flags));
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 }
 
 static bool lru_gen_clear_refs(struct folio *folio)
@@ -423,7 +423,7 @@ static bool lru_gen_clear_refs(struct folio *folio)
 	if (gen < 0)
 		return true;
 
-	set_mask_bits(&folio->flags.f, LRU_REFS_FLAGS | BIT(PG_workingset), 0);
+	set_mask_bits(folio_flags(folio, 0), LRU_REFS_FLAGS | BIT(PG_workingset), 0);
 
 	rcu_read_lock();
 	seq = READ_ONCE(folio_lruvec(folio)->lrugen.min_seq[type]);
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 53b43e3f5795..7a1f08147dee 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -844,11 +844,11 @@ static bool lru_gen_set_refs(struct folio *folio)
 {
 	/* see the comment on LRU_REFS_FLAGS */
 	if (!folio_test_referenced(folio) && !folio_test_workingset(folio)) {
-		set_mask_bits(&folio->flags.f, LRU_REFS_MASK, BIT(PG_referenced));
+		set_mask_bits(folio_flags(folio, 0), LRU_REFS_MASK, BIT(PG_referenced));
 		return false;
 	}
 
-	set_mask_bits(&folio->flags.f, LRU_REFS_FLAGS, BIT(PG_workingset));
+	set_mask_bits(folio_flags(folio, 0), LRU_REFS_FLAGS, BIT(PG_workingset));
 	return true;
 }
 #else
@@ -3193,13 +3193,13 @@ static bool positive_ctrl_err(struct ctrl_pos *sp, struct ctrl_pos *pv)
 /* promote pages accessed through page tables */
 static int folio_update_gen(struct folio *folio, int gen)
 {
-	unsigned long new_flags, old_flags = READ_ONCE(folio->flags.f);
+	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
 
 	VM_WARN_ON_ONCE(gen >= MAX_NR_GENS);
 
 	/* see the comment on LRU_REFS_FLAGS */
 	if (!folio_test_referenced(folio) && !folio_test_workingset(folio)) {
-		set_mask_bits(&folio->flags.f, LRU_REFS_MASK, BIT(PG_referenced));
+		set_mask_bits(folio_flags(folio, 0), LRU_REFS_MASK, BIT(PG_referenced));
 		return -1;
 	}
 
@@ -3210,7 +3210,7 @@ static int folio_update_gen(struct folio *folio, int gen)
 
 		new_flags = old_flags & ~(LRU_GEN_MASK | LRU_REFS_FLAGS);
 		new_flags |= ((gen + 1UL) << LRU_GEN_PGOFF) | BIT(PG_workingset);
-	} while (!try_cmpxchg(&folio->flags.f, &old_flags, new_flags));
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
 	return ((old_flags & LRU_GEN_MASK) >> LRU_GEN_PGOFF) - 1;
 }
@@ -3221,7 +3221,7 @@ static int folio_inc_gen(struct lruvec *lruvec, struct folio *folio)
 	int type = folio_is_file_lru(folio);
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 	int new_gen, old_gen = lru_gen_from_seq(lrugen->min_seq[type]);
-	unsigned long new_flags, old_flags = READ_ONCE(folio->flags.f);
+	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
 
 	VM_WARN_ON_ONCE_FOLIO(!(old_flags & LRU_GEN_MASK), folio);
 
@@ -4639,7 +4639,7 @@ static bool isolate_folio(struct lruvec *lruvec, struct folio *folio, struct sca
 
 	/* see the comment on LRU_REFS_FLAGS */
 	if (!folio_test_referenced(folio))
-		set_mask_bits(&folio->flags.f, LRU_REFS_MASK, 0);
+		set_mask_bits(folio_flags(folio, 0), LRU_REFS_MASK, 0);
 
 	success = lru_gen_del_folio(lruvec, folio, true);
 	VM_WARN_ON_ONCE_FOLIO(!success, folio);
@@ -4855,7 +4855,7 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 
 		/* don't add rejected folios to the oldest generation */
 		if (lru_gen_folio_seq(lruvec, folio, false) == min_seq[type])
-			set_mask_bits(&folio->flags.f, LRU_REFS_FLAGS, BIT(PG_active));
+			set_mask_bits(folio_flags(folio, 0), LRU_REFS_FLAGS, BIT(PG_active));
 	}
 
 	move_folios_to_lru(&list);

-- 
2.54.0

