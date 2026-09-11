From: Kairui Song <kasong@tencent.com>
Date: Fri, 11 Sep 2026 19:45:15 +0800
Subject: [PATCH RFC v2 12/15] mm/mglru: folio LRU refs based
 active/inactive number accounting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-mglru-fg-v2-12-f26e5cb26da7@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789127106; l=31379;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=U/KM9IdrUrBsaDw7NNuWTkSVrVEBNHBlUXka2G/UUoc=;
 b=xe8979B2H1DqlIKhMSKu+LRZ3uxYuyXi4+rAfHvVwFKh+FsKp1sBXOmOEd9rbaChqqm7z2bmE
 f7+CZhgaOinDuMojbvKKGtrTM0FS6w+g+MBoOWv/NuTq812iQt2b2B/
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the active/inactive LRU sizes exported through /proc/vmstat
and memory.stat are derived from the generation window: folios in the
two newest generations are accounted as active, the rest as inactive.
This has always caused many problems:

- Unmapped file folios stick to the oldest gens, so active files are
  always under-reported, unlike classical LRU.

- The reading is jumpy: on aging, the second-newest gen, previously
  active, becomes inactive all at once, causing a huge drop of active
  folios for no reason from time to time.

- The reading is reversed on swapless machines, and the active anon
  number is an oscillating random number. When swappiness is 0 (no
  swap or swap is full), MGLRU ages anon by moving the gens directly
  without walk or touching any folio, to reduce the overhead. So all
  inactive anon folios will suddenly count as active, or vice versa,
  which breaks many metric reading components, and the reading itself
  doesn't make any sense in any way.

With frequency guided promotion, hotness is already tracked per folio by
its referenced count, so we can do folio level accounting instead: a
folio is active once its refs reach LRU_REFS_ACTIVATED (currently
LRU_REFS_PROTECTED).

On access, folios are accounted to the active part. On forced aging or
PID protecting, folios are reset to LRU_REFS_WORKINGSET, dropping them
to the inactive part. The reading is now smooth and consistent, and
much closer to classical LRU. Note that on swapless machines anon refs
are never reset by aging (the shortcut skips the per-folio walk), so
active anon grows monotonically, but the reading is stable and still
much more meaningful than the previous oscillating random number.

The accounting is now per folio and lruvec independent, so no size
adjustment is needed when reparenting a dying memcg: the hierarchical
stats keep the counts in the parent automatically.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 fs/proc/task_mmu.c        |   2 +-
 include/linux/mm_inline.h |  79 ++++++++++--------
 include/linux/mmzone.h    |  23 ++++--
 mm/damon/paddr.c          |   2 +-
 mm/folio.c                |  35 +-------
 mm/vmscan.c               | 205 +++++++++++++++++++++++++++++-----------------
 mm/workingset.c           |   2 +-
 7 files changed, 195 insertions(+), 153 deletions(-)

diff --git a/fs/proc/task_mmu.c b/fs/proc/task_mmu.c
index 9cc47efbaa51..a490170f2a3a 100644
--- a/fs/proc/task_mmu.c
+++ b/fs/proc/task_mmu.c
@@ -891,7 +891,7 @@ static bool smap_check_folio_referenced(struct folio *folio)
 static void smap_clear_folio_referenced(struct folio *folio)
 {
 	if (lru_gen_enabled())
-		folio_set_lru_refs(folio, 0);
+		folio_reset_lru_refs(folio);
 	else
 		folio_clear_referenced(folio);
 }
diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index 23ddd5d78571..686294fe81b8 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -183,24 +183,39 @@ static inline int folio_lru_refs(const struct folio *folio)
 	return lru_get_refs_flags(READ_ONCE(*const_folio_flags(folio, 0)));
 }
 
-static inline void folio_set_lru_refs(struct folio *folio, unsigned int refs)
+/**
+ * __folio_set_lru_refs - Set a folio's LRU refs.
+ * @folio: the folio
+ * @refs: the new referenced count (0 .. LRU_REFS_MAX)
+ *
+ * Set the folio's LRU refs.  The folio must be off the LRU list (e.g.,
+ * isolated), or use folio_inc_lru_refs or folio_reset_lru_refs instead.
+ */
+static inline void __folio_set_lru_refs(struct folio *folio, unsigned int refs)
 {
 	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
 
 	do {
 		new_flags = old_flags;
+		VM_WARN_ON_ONCE(lru_get_gen_flags(old_flags) != -1);
 		lru_set_refs_flags(&new_flags, refs);
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 }
 
 #ifdef CONFIG_LRU_GEN
 void folio_inc_lru_refs(struct folio *folio, unsigned int flags);
+bool folio_reset_lru_refs(struct folio *folio);
 #else
 static inline void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
 {
 	/* Should not be called with !CONFIG_LRU_GEN */
 	WARN_ON_ONCE(1);
 }
+
+static inline bool folio_reset_lru_refs(struct folio *folio)
+{
+	return false;
+}
 #endif
 
 /**
@@ -214,7 +229,9 @@ static inline void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
  */
 static inline void folio_migrate_lru_refs(struct folio *new, const struct folio *old)
 {
-	folio_set_lru_refs(new, folio_lru_refs(old));
+	VM_WARN_ON_ONCE_FOLIO(folio_test_lru(old), old);
+	VM_WARN_ON_ONCE_FOLIO(folio_test_lru(new), new);
+	__folio_set_lru_refs(new, folio_lru_refs(old));
 }
 
 #ifdef CONFIG_LRU_GEN
@@ -265,19 +282,15 @@ static inline int lru_tier_from_refs(unsigned int refs)
 	return fls(refs - 1);
 }
 
-static inline int folio_lru_gen(const struct folio *folio)
+static inline bool lru_refs_is_active(unsigned int refs)
 {
-	return lru_get_gen_flags(READ_ONCE(*const_folio_flags(folio, 0)));
+	VM_WARN_ON_ONCE(refs > LRU_REFS_MAX);
+	return refs >= LRU_REFS_ACTIVATED;
 }
 
-static inline bool lru_gen_is_active(const struct lruvec *lruvec, int gen)
+static inline int folio_lru_gen(const struct folio *folio)
 {
-	unsigned long max_seq = READ_ONCE(lruvec->lrugen.max_seq);
-
-	VM_WARN_ON_ONCE(gen >= MAX_NR_GENS);
-
-	/* see the comment on MIN_NR_GENS */
-	return gen == lru_gen_from_seq(max_seq) || gen == lru_gen_from_seq(max_seq - 1);
+	return lru_get_gen_flags(READ_ONCE(*const_folio_flags(folio, 0)));
 }
 
 static inline void lru_gen_update_size(struct lruvec *lruvec, struct folio *folio,
@@ -286,7 +299,6 @@ static inline void lru_gen_update_size(struct lruvec *lruvec, struct folio *foli
 	int type = folio_is_file_lru(folio);
 	int zone = folio_zonenum(folio);
 	int delta = folio_nr_pages(folio);
-	enum lru_list lru = type * LRU_INACTIVE_FILE;
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 
 	VM_WARN_ON_ONCE(old_gen != -1 && old_gen >= MAX_NR_GENS);
@@ -297,19 +309,6 @@ static inline void lru_gen_update_size(struct lruvec *lruvec, struct folio *foli
 		atomic_long_sub(delta, &lrugen->nr_pages[old_gen][type][zone]);
 	if (new_gen >= 0)
 		atomic_long_add(delta, &lrugen->nr_pages[new_gen][type][zone]);
-
-	/* return now if not a promotion */
-	if (old_gen < 0 || new_gen < 0)
-		return;
-
-	/* promotion */
-	if (!lru_gen_is_active(lruvec, old_gen) && lru_gen_is_active(lruvec, new_gen)) {
-		__update_lru_size(lruvec, lru, zone, -delta);
-		__update_lru_size(lruvec, lru + LRU_ACTIVE, zone, delta);
-	}
-
-	/* demotion requires isolation, e.g., lru_deactivate_fn() */
-	VM_WARN_ON_ONCE(lru_gen_is_active(lruvec, old_gen) && !lru_gen_is_active(lruvec, new_gen));
 }
 
 static inline unsigned long lru_gen_folio_seq(const struct lruvec *lruvec,
@@ -351,7 +350,7 @@ static inline bool lru_gen_add_folio(struct lruvec *lruvec, struct folio *folio,
 {
 	unsigned long seq;
 	unsigned long flags;
-	int gen = folio_lru_gen(folio);
+	int gen, refs;
 	int type = folio_is_file_lru(folio);
 	int zone = folio_zonenum(folio);
 	int delta = folio_nr_pages(folio);
@@ -359,7 +358,7 @@ static inline bool lru_gen_add_folio(struct lruvec *lruvec, struct folio *folio,
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 
 	BUILD_BUG_ON(BIT(LRU_GEN_WIDTH - 1) != MAX_NR_GENS);
-	VM_WARN_ON_ONCE_FOLIO(gen != -1, folio);
+	VM_WARN_ON_ONCE_FOLIO(folio_lru_gen(folio) != -1, folio);
 
 	if (folio_test_unevictable(folio) || !lrugen->enabled)
 		return false;
@@ -368,10 +367,12 @@ static inline bool lru_gen_add_folio(struct lruvec *lruvec, struct folio *folio,
 	gen = lru_gen_from_seq(seq);
 	flags = (gen + 1UL) << LRU_GEN_PGOFF;
 	/* see the comment on MIN_NR_GENS about PG_active */
-	set_mask_bits(folio_flags(folio, 0), LRU_GEN_MASK | BIT(PG_active), flags);
+	flags = set_mask_bits(folio_flags(folio, 0), LRU_GEN_MASK | BIT(PG_active), flags);
+	/* use the refs from the atomic snapshot to avoid raced update */
+	refs = lru_get_refs_flags(flags);
 
 	lru_gen_update_size(lruvec, folio, -1, gen);
-	if (lru_gen_is_active(lruvec, gen))
+	if (lru_refs_is_active(refs))
 		lru += LRU_ACTIVE;
 	__update_lru_size(lruvec, lru, zone, delta);
 
@@ -387,24 +388,31 @@ static inline bool lru_gen_add_folio(struct lruvec *lruvec, struct folio *folio,
 static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio, bool reclaiming)
 {
 	unsigned long flags;
-	int gen = folio_lru_gen(folio);
+	int gen, refs;
 	int zone = folio_zonenum(folio);
 	int delta = folio_nr_pages(folio);
 	enum lru_list lru = folio_is_file_lru(folio) * LRU_INACTIVE_FILE;
+	unsigned long max_seq = READ_ONCE(lruvec->lrugen.max_seq);
 
+	flags = set_mask_bits(folio_flags(folio, 0), LRU_GEN_MASK, 0);
+	gen = lru_get_gen_flags(flags);
+	refs = lru_get_refs_flags(flags);
 	if (gen < 0)
 		return false;
 
 	VM_WARN_ON_ONCE_FOLIO(folio_test_active(folio), folio);
 	VM_WARN_ON_ONCE_FOLIO(folio_test_unevictable(folio), folio);
 
-	/* for folio_migrate_flags() */
-	flags = !reclaiming && lru_gen_is_active(lruvec, gen) ? BIT(PG_active) : 0;
-	flags = set_mask_bits(folio_flags(folio, 0), LRU_GEN_MASK, flags);
-	gen = ((flags & LRU_GEN_MASK) >> LRU_GEN_PGOFF) - 1;
+	/*
+	 * See the comment in lru_gen_folio_seq.  For migration, compaction,
+	 * or any other isolation of a hot folio, try best to retain its gen
+	 * info. Ideally we would keep the full gen info.
+	 */
+	if (!reclaiming && ((max_seq - gen) % MAX_NR_GENS) < MIN_NR_GENS)
+		folio_set_active(folio);
 
 	lru_gen_update_size(lruvec, folio, gen, -1);
-	if (lru_gen_is_active(lruvec, gen))
+	if (lru_refs_is_active(refs))
 		lru += LRU_ACTIVE;
 	__update_lru_size(lruvec, lru, zone, -delta);
 	list_del(&folio->lru);
@@ -455,6 +463,7 @@ static __always_inline void folio_inc_lru_refs_fast(struct folio *folio)
 		return;
 	}
 
+	BUILD_BUG_ON(LRU_REFS_REFERENCED >= LRU_REFS_ACTIVATED);
 	old_flags = READ_ONCE(*folio_flags(folio, 0));
 	do {
 		if (lru_get_refs_flags(old_flags))
diff --git a/include/linux/mmzone.h b/include/linux/mmzone.h
index 523783186c57..da950f848bb9 100644
--- a/include/linux/mmzone.h
+++ b/include/linux/mmzone.h
@@ -456,15 +456,15 @@ enum lruvec_flags {
  * least twice before handing this folio over to the eviction. The first check
  * clears the accessed bit from the initial fault; the second check makes sure
  * this folio hasn't been used since then. This process, AKA second chance,
- * requires a minimum of two generations, hence MIN_NR_GENS. And to maintain ABI
- * compatibility with the active/inactive LRU, e.g., /proc/vmstat, these two
- * generations are considered active; the rest of generations, if they exist,
- * are considered inactive. See lru_gen_is_active().
+ * requires a minimum of two generations, hence MIN_NR_GENS.
+ *
+ * Active/inactive is per-folio based on the referenced count;
+ * see the comment above MAX_NR_TIERS.
  *
  * PG_active is always cleared while a folio is on one of lrugen->folios[] so
- * that the sliding window needs not to worry about it. And it's set again when
- * a folio considered active is isolated for non-reclaiming purposes, e.g.,
- * migration. See lru_gen_add_folio() and lru_gen_del_folio().
+ * that the sliding window needs not to worry about it.  It is set on a
+ * fault-driven refault (see lru_gen_refault), or isolation (see
+ * lru_gen_del_folio).
  *
  * MAX_NR_GENS is set to 4 so that the multi-gen LRU can support twice the
  * number of categories of the active/inactive LRU when keeping track of
@@ -564,11 +564,15 @@ enum lruvec_flags {
  *
  * A folio's referenced count never goes backwards except upon gen
  * increase as described above, or when explicitly reset by
- * lru_gen_clear_refs().  Refault of a reclaimed folio restores
+ * folio_reset_lru_refs().  Refault of a reclaimed folio restores
  * its referenced count, capped at LRU_REFS_PROTECTED, which aligns with
  * promotion.  Page table refaults of previous workingset folios send
  * them to the latest gen, driving aging faster.
  *
+ * For the active/inactive LRU ABI (/proc/vmstat), a folio is active
+ * if its referenced count reaches LRU_REFS_ACTIVATED.  The threshold
+ * currently set to LRU_REFS_PROTECTED, which is tier 2.
+ *
  * MAX_NR_TIERS is set to 4 so that the multi-gen LRU can support twice
  * the number of categories of the active/inactive LRU.
  */
@@ -583,6 +587,7 @@ enum lruvec_flags {
 #define LRU_REFS_REFERENCED	0x1
 #define LRU_REFS_WORKINGSET	0x2
 #define LRU_REFS_PROTECTED	0x3
+#define LRU_REFS_ACTIVATED	LRU_REFS_PROTECTED
 
 #ifndef __GENERATING_BOUNDS_H
 
@@ -691,6 +696,8 @@ struct lru_gen_mm_walk {
 	unsigned long seq;
 	/* the next address within an mm to scan */
 	unsigned long next_addr;
+	/* to batch activated pages */
+	int nr_activated[ANON_AND_FILE][MAX_NR_ZONES];
 	/* to batch promoted pages */
 	int nr_pages[MAX_NR_GENS][ANON_AND_FILE][MAX_NR_ZONES];
 	/* to batch the mm stats */
diff --git a/mm/damon/paddr.c b/mm/damon/paddr.c
index 38d3ff7019e3..c5539b6f7695 100644
--- a/mm/damon/paddr.c
+++ b/mm/damon/paddr.c
@@ -285,7 +285,7 @@ static unsigned long damon_pa_pageout(struct damon_region *r,
 		 * so the hotness can be, and better be dropped.
 		 */
 		if (lru_gen_enabled())
-			folio_set_lru_refs(folio, 0);
+			folio_reset_lru_refs(folio);
 		else
 			folio_clear_referenced(folio);
 		folio_test_clear_young(folio);
diff --git a/mm/folio.c b/mm/folio.c
index 55cb37366487..cd9a49c1df68 100644
--- a/mm/folio.c
+++ b/mm/folio.c
@@ -349,35 +349,6 @@ static void __lru_cache_activate_folio(struct folio *folio)
 	local_unlock(&cpu_fbatches.lock);
 }
 
-#ifdef CONFIG_LRU_GEN
-
-static bool lru_gen_clear_refs(struct folio *folio)
-{
-	int gen = folio_lru_gen(folio);
-	int type = folio_is_file_lru(folio);
-	unsigned long seq;
-
-	if (gen < 0)
-		return true;
-
-	folio_set_lru_refs(folio, 0);
-
-	rcu_read_lock();
-	seq = READ_ONCE(folio_lruvec(folio)->lrugen.min_seq[type]);
-	rcu_read_unlock();
-	/* whether can do without shuffling under the LRU lock */
-	return gen == lru_gen_from_seq(seq);
-}
-
-#else /* !CONFIG_LRU_GEN */
-
-static bool lru_gen_clear_refs(struct folio *folio)
-{
-	return false;
-}
-
-#endif /* CONFIG_LRU_GEN */
-
 /**
  * folio_mark_accessed - Mark a folio as having seen activity.
  * @folio: The folio to mark.
@@ -554,7 +525,7 @@ static void lru_lazyfree(struct lruvec *lruvec, struct folio *folio)
 	lruvec_del_folio(lruvec, folio);
 	folio_clear_active(folio);
 	if (lru_gen_enabled())
-		lru_gen_clear_refs(folio);
+		__folio_set_lru_refs(folio, 0);
 	else
 		folio_clear_referenced(folio);
 	/*
@@ -627,7 +598,7 @@ void deactivate_file_folio(struct folio *folio)
 	if (folio_test_unevictable(folio) || !folio_test_lru(folio))
 		return;
 
-	if (lru_gen_enabled() && lru_gen_clear_refs(folio))
+	if (lru_gen_enabled() && !folio_reset_lru_refs(folio))
 		return;
 
 	folio_batch_add_and_move(folio, lru_deactivate_file);
@@ -646,7 +617,7 @@ void folio_deactivate(struct folio *folio)
 	if (folio_test_unevictable(folio) || !folio_test_lru(folio))
 		return;
 
-	if (lru_gen_enabled() ? lru_gen_clear_refs(folio) : !folio_test_active(folio))
+	if (lru_gen_enabled() ? !folio_reset_lru_refs(folio) : !folio_test_active(folio))
 		return;
 
 	folio_batch_add_and_move(folio, lru_deactivate);
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 9be0cd20dc54..240a8747490a 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -944,17 +944,19 @@ enum folio_references {
 void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
 {
 	int max_gen, min_gen;
-	int type, refs, old_gen, gen;
+	int file, old_refs, refs, old_gen, gen;
 	unsigned long new_flags, old_flags, max_seq;
+	long nr_pages = folio_nr_pages(folio);
 	struct lru_gen_folio *lrugen;
 	struct lruvec *lruvec = NULL;
 
-	type = folio_is_file_lru(folio);
 	old_flags = READ_ONCE(*folio_flags(folio, 0));
 	do {
 		new_flags = old_flags;
 		old_gen = lru_get_gen_flags(old_flags);
-		refs = lru_get_refs_flags(old_flags) + 1;
+		old_refs = lru_get_refs_flags(old_flags);
+		file = folio_flags_is_file_lru(&old_flags);
+		refs = old_refs + 1;
 		gen = old_gen;
 		if (old_gen < 0)
 			goto out;
@@ -972,7 +974,7 @@ void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
 		}
 		max_seq = READ_ONCE(lrugen->max_seq);
 		max_gen = lru_gen_from_seq(max_seq);
-		min_gen = lru_gen_from_seq(READ_ONCE(lrugen->min_seq[type]));
+		min_gen = lru_gen_from_seq(READ_ONCE(lrugen->min_seq[file]));
 		if (old_gen == max_gen)
 			goto out;
 
@@ -1001,50 +1003,102 @@ void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
 
 	if (gen != old_gen)
 		lru_gen_update_size(lruvec, folio, old_gen, gen);
+	if (lru_refs_is_active(old_refs) != lru_refs_is_active(refs) && old_gen >= 0) {
+		enum lru_list lru = file * LRU_INACTIVE_FILE;
+
+		__update_lru_size(lruvec, lru + lru_refs_is_active(old_refs),
+				  folio_zonenum(folio), -nr_pages);
+		__update_lru_size(lruvec, lru + lru_refs_is_active(refs),
+				  folio_zonenum(folio), nr_pages);
+	}
 	if (lruvec)
 		lruvec_unlock_irq(lruvec);
 }
 
+/**
+ * Reset the folio's lru refs indicator. The caller doesn't need to hold
+ * the folio lock, isolate the folio, or hold the lruvec lock.
+ */
+bool folio_reset_lru_refs(struct folio *folio)
+{
+	int type, gen, refs;
+	unsigned long seq, new_flags, old_flags;
+	long nr_pages = folio_nr_pages(folio);
+	struct lruvec *lruvec;
+	bool reset = false;
+
+	old_flags = READ_ONCE(*folio_flags(folio, 0));
+	do {
+		new_flags = old_flags;
+		refs = lru_get_refs_flags(old_flags);
+		type = folio_flags_is_file_lru(&old_flags);
+		gen = lru_get_gen_flags(old_flags);
+		if (!refs)
+			break;
+		lru_set_refs_flags(&new_flags, 0);
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
+
+	if (gen >= 0) {
+		lruvec = folio_lruvec_live_get(folio);
+
+		/* If the folio is on list, caller might also want to demote it */
+		seq = READ_ONCE(lruvec->lrugen.min_seq[type]);
+		reset = (gen != lru_gen_from_seq(seq));
+		if (lru_refs_is_active(refs)) {
+			__update_lru_size(lruvec, type * LRU_FILE + LRU_ACTIVE,
+					  folio_zonenum(folio), -nr_pages);
+			__update_lru_size(lruvec, type * LRU_FILE,
+					  folio_zonenum(folio), nr_pages);
+		}
+
+		folio_lruvec_live_put(lruvec);
+	}
+
+	return reset;
+}
+
 /*
  * Update the folio's lru refs indicator during a page table walk.
  * max_seq is stable since this runs inside the aging process.
  *
- * Returns the old generation and stores the new generation in @new_gen when
- * the folio is promoted (to max_gen) or advanced by one generation.
- * Returns -1 if no gen change occurred.
+ * Returns the old generation, or -1 if the folio is off the LRU list.
+ * Old LRU refs, and updated gen and LRU refs info by the successful
+ * cmpxchg are all stored by returning arguments.
  */
 static int folio_inc_lru_refs_walk(struct folio *folio, struct lruvec *lruvec,
-				   const vma_flags_t *vma_flags,
-				   int *new_gen, int *type)
+				   const vma_flags_t *vma_flags, int *new_gen,
+				   int *old_refs, int *new_refs, int *type)
 {
 	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
 	unsigned long max_seq = READ_ONCE(lruvec->lrugen.max_seq);
-	int refs, gen, max_gen, ret;
+	int refs, old_gen, max_gen;
 
 	max_gen = lru_gen_from_seq(max_seq);
-
 	do {
-		gen = lru_get_gen_flags(old_flags);
+		old_gen = lru_get_gen_flags(old_flags);
 		refs = lru_get_refs_flags(old_flags) + 1;
 		new_flags = old_flags;
 
-		if (gen >= 0 && gen != max_gen) {
-			ret = gen;
+		if (old_gen >= 0 && old_gen != max_gen) {
+			*new_refs = min(refs, LRU_REFS_PROTECTED);
 			/* Promote second page table access or executable */
 			if (refs > LRU_REFS_REFERENCED || is_exec_file_folio(folio, vma_flags))
 				*new_gen = max_gen;
 			else
-				*new_gen = (gen + 1) % MAX_NR_GENS;
+				*new_gen = (old_gen + 1) % MAX_NR_GENS;
 			lru_set_gen_flags(&new_flags, *new_gen);
-			lru_set_refs_flags(&new_flags, min(refs, LRU_REFS_PROTECTED));
+			lru_set_refs_flags(&new_flags, *new_refs);
 		} else {
-			ret = -1;
-			lru_set_refs_flags(&new_flags, min(refs, LRU_REFS_MAX));
+			*new_gen = old_gen;
+			*new_refs = min(refs, LRU_REFS_MAX);
+			lru_set_refs_flags(&new_flags, *new_refs);
 		}
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
 	*type = folio_flags_is_file_lru(&old_flags);
-	return ret;
+	*old_refs = lru_get_refs_flags(old_flags);
+
+	return old_gen;
 }
 
 /*
@@ -3482,10 +3536,11 @@ static bool positive_ctrl_err(struct ctrl_pos *sp, struct ctrl_pos *pv)
  *                          the aging
  ******************************************************************************/
 
-static int __folio_inc_gen(struct folio *folio, int old_gen, bool *increased)
+static int __folio_inc_gen(struct lruvec *lruvec, struct folio *folio,
+		int old_gen, bool *increased)
 {
 	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
-	int refs, new_gen;
+	int file, refs, old_refs, new_gen;
 
 	do {
 		new_gen = lru_get_gen_flags(old_flags);
@@ -3499,11 +3554,24 @@ static int __folio_inc_gen(struct folio *folio, int old_gen, bool *increased)
 
 		new_flags = old_flags;
 		new_gen = (old_gen + 1) % MAX_NR_GENS;
-		refs = lru_get_refs_flags(old_flags);
+		old_refs = lru_get_refs_flags(old_flags);
+		file = folio_flags_is_file_lru(&old_flags);
+		refs = min(old_refs, LRU_REFS_WORKINGSET);
 		lru_set_gen_flags(&new_flags, new_gen);
-		lru_set_refs_flags(&new_flags, min(refs, LRU_REFS_WORKINGSET));
+		lru_set_refs_flags(&new_flags, refs);
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
+	/* Refs capped below PROTECTED: demote if previously active. */
+	if (lru_refs_is_active(old_refs) != lru_refs_is_active(refs)) {
+		enum lru_list lru = file * LRU_INACTIVE_FILE;
+		int nr_pages = folio_nr_pages(folio);
+
+		__update_lru_size(lruvec, lru + lru_refs_is_active(old_refs),
+				 folio_zonenum(folio), -nr_pages);
+		__update_lru_size(lruvec, lru + lru_refs_is_active(refs),
+				 folio_zonenum(folio), nr_pages);
+	}
+
 	if (increased)
 		*increased = true;
 	return new_gen;
@@ -3520,7 +3588,7 @@ static int folio_inc_gen(struct lruvec *lruvec, struct folio *folio)
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 	int new_gen, old_gen = lru_gen_from_seq(lrugen->min_seq[type]);
 
-	new_gen = __folio_inc_gen(folio, old_gen, &gen_increased);
+	new_gen = __folio_inc_gen(lruvec, folio, old_gen, &gen_increased);
 	if (gen_increased)
 		lru_gen_update_size(lruvec, folio, old_gen, new_gen);
 
@@ -3528,18 +3596,26 @@ static int folio_inc_gen(struct lruvec *lruvec, struct folio *folio)
 }
 
 static void update_batch_size(struct lru_gen_mm_walk *walk, struct folio *folio,
-			      int old_gen, int new_gen, int type)
+			      int old_gen, int new_gen, int old_refs, int new_refs, int type)
 {
 	int zone = folio_zonenum(folio);
 	int delta = folio_nr_pages(folio);
 
-	VM_WARN_ON_ONCE(old_gen >= MAX_NR_GENS);
-	VM_WARN_ON_ONCE(new_gen >= MAX_NR_GENS);
-
-	walk->batched++;
+	/* gen counter update */
+	if (old_gen != new_gen) {
+		VM_WARN_ON_ONCE(old_gen >= MAX_NR_GENS);
+		VM_WARN_ON_ONCE(new_gen >= MAX_NR_GENS);
+		walk->batched++;
+		walk->nr_pages[old_gen][type][zone] -= delta;
+		walk->nr_pages[new_gen][type][zone] += delta;
+	}
 
-	walk->nr_pages[old_gen][type][zone] -= delta;
-	walk->nr_pages[new_gen][type][zone] += delta;
+	/* active/inactive counter update */
+	if (lru_refs_is_active(old_refs) != lru_refs_is_active(new_refs)) {
+		walk->nr_activated[type][zone] +=
+			lru_refs_is_active(new_refs) ? delta : -delta;
+		walk->batched++;
+	}
 }
 
 static void reset_batch_size(struct lru_gen_mm_walk *walk)
@@ -3551,7 +3627,6 @@ static void reset_batch_size(struct lru_gen_mm_walk *walk)
 	walk->batched = 0;
 
 	for_each_gen_type_zone(gen, type, zone) {
-		enum lru_list lru = type * LRU_INACTIVE_FILE;
 		int delta = walk->nr_pages[gen][type][zone];
 
 		if (!delta)
@@ -3559,10 +3634,21 @@ static void reset_batch_size(struct lru_gen_mm_walk *walk)
 
 		walk->nr_pages[gen][type][zone] = 0;
 		atomic_long_add(delta, &lrugen->nr_pages[gen][type][zone]);
+	}
 
-		if (lru_gen_is_active(lruvec, gen))
-			lru += LRU_ACTIVE;
-		__update_lru_size(lruvec, lru, zone, delta);
+	/* apply batched active/inactive updates */
+	for (type = 0; type < ANON_AND_FILE; type++) {
+		for (zone = 0; zone < MAX_NR_ZONES; zone++) {
+			enum lru_list lru = type * LRU_INACTIVE_FILE;
+			int delta = walk->nr_activated[type][zone];
+
+			if (delta) {
+				__update_lru_size(lruvec, lru + LRU_ACTIVE,
+						  zone, delta);
+				__update_lru_size(lruvec, lru, zone, -delta);
+				walk->nr_activated[type][zone] = 0;
+			}
+		}
 	}
 
 	lruvec_unlock_irq(lruvec);
@@ -3717,7 +3803,7 @@ static bool suitable_to_scan(int total, int young)
 static void walk_update_folio(struct lru_gen_mm_walk *walk, struct vm_area_struct *vma,
 		struct lruvec *lruvec, struct folio *folio, bool dirty)
 {
-	int new_gen, old_gen, type;
+	int new_gen, old_gen, old_refs, new_refs, type;
 	unsigned int flags = LRU_REF_MAPPED;
 
 	if (!folio)
@@ -3730,9 +3816,10 @@ static void walk_update_folio(struct lru_gen_mm_walk *walk, struct vm_area_struc
 
 	if (walk) {
 		old_gen = folio_inc_lru_refs_walk(folio, lruvec, &vma->flags,
-						  &new_gen, &type);
+						  &new_gen, &old_refs, &new_refs, &type);
 		if (old_gen >= 0)
-			update_batch_size(walk, folio, old_gen, new_gen, type);
+			update_batch_size(walk, folio, old_gen, new_gen,
+					  old_refs, new_refs, type);
 	} else {
 		if (is_exec_file_folio(folio, &vma->flags))
 			flags |= LRU_REF_EXEC;
@@ -4091,6 +4178,7 @@ static void clear_mm_walk(void)
 
 	VM_WARN_ON_ONCE(walk && memchr_inv(walk->nr_pages, 0, sizeof(walk->nr_pages)));
 	VM_WARN_ON_ONCE(walk && memchr_inv(walk->mm_stats, 0, sizeof(walk->mm_stats)));
+	VM_WARN_ON_ONCE(walk && memchr_inv(walk->nr_activated, 0, sizeof(walk->nr_activated)));
 
 	current->reclaim_state->mm_walk = NULL;
 
@@ -4129,8 +4217,6 @@ static bool inc_min_seq(struct lruvec *lruvec, int type, int swappiness)
 		goto done;
 
 	VM_WARN_ON_ONCE(get_nr_gens(lruvec, type) != MAX_NR_GENS);
-	VM_WARN_ON_ONCE(lru_gen_is_active(lruvec, old_gen) !=
-			lru_gen_is_active(lruvec, target_gen));
 	/* prevent cold/hot inversion if the type is evictable */
 	for (zone = 0; zone < MAX_NR_ZONES; zone++) {
 		struct list_head *target_list = &lrugen->folios[target_gen][type][zone];
@@ -4153,7 +4239,7 @@ static bool inc_min_seq(struct lruvec *lruvec, int type, int swappiness)
 
 			prefetchw_next_lru_folio(folio, head);
 			pos = pos->next;
-			new_gen = __folio_inc_gen(folio, old_gen, &gen_increased);
+			new_gen = __folio_inc_gen(lruvec, folio, old_gen, &gen_increased);
 			/*
 			 * If gen_increased is false, this is a promotion. Put folios
 			 * at the head of the promoted gen. Otherwise, put them at
@@ -4240,8 +4326,7 @@ static void try_to_inc_min_seq(struct lruvec *lruvec, int swappiness)
 static bool inc_max_seq(struct lruvec *lruvec, unsigned long seq, int swappiness)
 {
 	bool success;
-	int prev, next;
-	int type, zone;
+	int type, next;
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 restart:
 	if (seq < READ_ONCE(lrugen->max_seq))
@@ -4267,32 +4352,10 @@ static bool inc_max_seq(struct lruvec *lruvec, unsigned long seq, int swappiness
 		goto restart;
 	}
 
-	/*
-	 * Update the active/inactive LRU sizes for compatibility. Both sides of
-	 * the current max_seq need to be covered, since max_seq+1 can overlap
-	 * with min_seq[LRU_GEN_ANON] if swapping is constrained. And if they do
-	 * overlap, cold/hot inversion happens.
-	 */
-	prev = lru_gen_from_seq(lrugen->max_seq - 1);
-	next = lru_gen_from_seq(lrugen->max_seq + 1);
-
-	for (type = 0; type < ANON_AND_FILE; type++) {
-		for (zone = 0; zone < MAX_NR_ZONES; zone++) {
-			enum lru_list lru = type * LRU_INACTIVE_FILE;
-			long delta = atomic_long_read(&lrugen->nr_pages[prev][type][zone]) -
-				     atomic_long_read(&lrugen->nr_pages[next][type][zone]);
-
-			if (!delta)
-				continue;
-
-			__update_lru_size(lruvec, lru, zone, delta);
-			__update_lru_size(lruvec, lru + LRU_ACTIVE, zone, -delta);
-		}
-	}
-
 	for (type = 0; type < ANON_AND_FILE; type++)
 		reset_ctrl_pos(lruvec, type, false);
 
+	next = lru_gen_from_seq(lrugen->max_seq + 1);
 	WRITE_ONCE(lrugen->timestamps[next], jiffies);
 	/* make sure preceding modifications appear */
 	smp_store_release(&lrugen->max_seq, lrugen->max_seq + 1);
@@ -4811,7 +4874,6 @@ static void __lru_gen_reparent_memcg(struct lruvec *child_lruvec, struct lruvec
 				     int zone, int type)
 {
 	struct lru_gen_folio *child_lrugen, *parent_lrugen;
-	enum lru_list lru = type * LRU_INACTIVE_FILE;
 	int i;
 
 	child_lrugen = &child_lruvec->lrugen;
@@ -4820,8 +4882,6 @@ static void __lru_gen_reparent_memcg(struct lruvec *child_lruvec, struct lruvec
 	for (i = 0; i < get_nr_gens(child_lruvec, type); i++) {
 		int gen = lru_gen_from_seq(child_lrugen->max_seq - i);
 		long nr_pages = atomic_long_read(&child_lrugen->nr_pages[gen][type][zone]);
-		int child_lru_active = lru_gen_is_active(child_lruvec, gen) ? LRU_ACTIVE : 0;
-		int parent_lru_active = lru_gen_is_active(parent_lruvec, gen) ? LRU_ACTIVE : 0;
 
 		/* Assuming that child pages are colder than parent pages */
 		list_splice_tail_init(&child_lrugen->folios[gen][type][zone],
@@ -4829,11 +4889,6 @@ static void __lru_gen_reparent_memcg(struct lruvec *child_lruvec, struct lruvec
 
 		atomic_long_set(&child_lrugen->nr_pages[gen][type][zone], 0);
 		atomic_long_add(nr_pages, &parent_lrugen->nr_pages[gen][type][zone]);
-
-		if (lru_gen_is_active(child_lruvec, gen) != lru_gen_is_active(parent_lruvec, gen)) {
-			__update_lru_size(child_lruvec, lru + child_lru_active, zone, -nr_pages);
-			__update_lru_size(parent_lruvec, lru + parent_lru_active, zone, nr_pages);
-		}
 	}
 }
 
@@ -5164,7 +5219,7 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 		}
 
 		/* Reset folio's refs before return */
-		folio_set_lru_refs(folio, min(folio_lru_refs(folio), LRU_REFS_WORKINGSET));
+		__folio_set_lru_refs(folio, min(folio_lru_refs(folio), LRU_REFS_WORKINGSET));
 		if (lru_gen_folio_seq(lruvec, folio, false) == min_seq[type])
 			folio_set_active(folio);
 	}
diff --git a/mm/workingset.c b/mm/workingset.c
index 44be539b93d2..a04d495139c4 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -334,7 +334,7 @@ static void lru_gen_refault(struct folio *folio, void *shadow)
 			mod_lruvec_state(lruvec, WORKINGSET_ACTIVATE_BASE + type, delta);
 		}
 		/* Refault is also promotion, cap the refs like folio_inc_lru_refs */
-		folio_set_lru_refs(folio, min(refs, LRU_REFS_PROTECTED));
+		__folio_set_lru_refs(folio, min(refs, LRU_REFS_PROTECTED));
 	}
 
 	if (refs >= LRU_REFS_WORKINGSET)

-- 
2.55.0

