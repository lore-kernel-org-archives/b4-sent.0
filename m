From: Kairui Song <kasong@tencent.com>
Date: Fri, 11 Sep 2026 19:45:07 +0800
Subject: [PATCH RFC v2 04/15] mm/mglru: frequency guided workingset
 promotion (MGLRU-FG)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-mglru-fg-v2-4-f26e5cb26da7@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789127106; l=45668;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=7yxmFC+L/U+wgIKzzIXJZiypw334NbUyB6yONVQ2ssU=;
 b=9Doe+PTNqHKMYfZgBefzMwEo1gEZK5jSIL5VCqG3VpD5RiZxBapK2gzhficuAuSFE0UvHO6RP
 fwfS8z90W6JDfeRLlGT39HqHhHUe/uqTpo+U9DEN3GYAkKFljlyzUy3
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Complement MGLRU's eviction-time tier-PID protection with access-time
frequency-guided promotion.  Introduce a unified set of helpers built based
on referenced (access) count of a folio.

Each access increments a folio's referenced count stored in folio flags
(refs), refs still maps to a logarithmic tier just like before, but with
more formal bit definitions, a few special thresholds are introduced:
LRU_REFS_REFERENCED (1), LRU_REFS_WORKINGSET (2), LRU_REFS_PROTECTED (3),
and LRU_REFS_MAX (7). When refs reaches a certain threshold, the folio is
promoted proactively instead of waiting for the PID controller to kick in.

Also simplify MGLRU's usage of PG_workingset and PG_referenced: they
become the low two bits of the refs count, with the higher bits
provided by LRU_REFS_MASK.  This reduces MGLRU's original refs count
bit usage by one, since only one extra bit is now needed to record a
max referenced count of 7, and makes MGLRU's refs accounting more
accurate.

This doesn't affect classical LRU in any way, and it addresses several
shortcomings of MGLRU's old tier-only cache protection model:

- Long feedback loop: protection only activated after enough re-faults,
  by which time the hot folios are already evicted, or no longer hot.

- Limited tier resolution: once referenced count exceeded the bits
  limit (8 previously), MGLRU could no longer distinguish hotter folios as
  they are capped by the tier.  And what's worse, PG_workingset forces
  a folio to stay on tier 3.

- Eviction hotness reversion: because PID protection activates upon
  eviction and always targets the LRU tail, it tends to protect cold tail
  folios at the expense of hotter head folios.  Once the tail folios
  consume the PID protection budget, head folios lose their protection.

- Additionally, the PID cannot distinguish the access time of folios
  that share the same reference count, and there are only 4 tiers.

To achieve a frequency-guided framework, this commit introduces and reworks
the LRU_REFS related helpers and definitions; most of the work is done by
the helpers below, and their inline comments describe the details.

- folio_inc_lru_refs(): Called on any cache access (folio_mark_accessed)
  or page table access.  This is the main helper: it promotes folios
  according to their access frequency.

  Promotion is lazy: the gen bits and size counters are updated eagerly,
  while the list move is deferred to the next isolation.  NOTE: For now,
  the lruvec lock is unconditionally taken on every on-list access to
  block concurrent aging; a lockless fast path will be implemented very
  soon in a following commit.

- folio_inc_lru_refs_walk(): Used by the PTE walk path during aging,
  where generations are stable, and promotes folios a bit more
  aggressively since PTE accesses have a higher promotion bias; this
  also performs lazy promotion.

- folio_inc_lru_refs_isolated(): Used by the rmap check before
  eviction.  The folio is isolated and hence this doesn't perform
  promotion by itself; the folio will be added back to the right gen
  upon return according to the access frequency.  This path also has a
  higher promotion bias.

The eviction-time folio_inc_gen() still handles PID protection, but the
protection ratio is softer than before since proactive promotion is
mostly good enough already.  The PID gain factors are relaxed from
(2:3) to (1:2) and the setpoint now spans the cumulative mass of the
tiers below the candidate instead of tier 0 alone.  folio_inc_gen()
caps refs at WORKINGSET so the folio retains enough history to stay
above the cold tier.  Tier 1 is the fallback tier for PID, and tier 2
is the fallback tier for frequency-guided promotion.  The forced
protection for full-refs folios is removed, obsoleted by the proactive
promotion.

Refaults are now activated purely according to access frequency:
the old fault bias applied in folio_add_lru() is simplified, since a
folio's access history is a more consistent signal than the context of
the faulting task.  Page table access is still considered a slightly
stronger signal.

This also redefines PG_workingset and PG_referenced as the low two
bits of the refs count, eliminating the old restriction where
LRU_REFS_MASK was only valid when PG_referenced was set, and allows
all paths to use the same encoding consistently.  Following this idea,
a workingset folio is now defined as refs >= LRU_REFS_WORKINGSET (2),
matching the active/inactive LRU's definition and giving in-kernel
consumers (PSI, readahead) consistent behavior on MGLRU, fixing the
longstanding issue that these users don't work well with MGLRU.

PG_workingset and PG_referenced are no longer independent flags under
MGLRU.  Adjusting existing raw folio_test_*() callers to the new
semantics is left as follow-ups.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm_inline.h |  83 +++++++------
 include/linux/mmzone.h    | 144 ++++++++++++++++------
 kernel/bounds.c           |   2 +-
 mm/folio.c                |  50 +-------
 mm/vmscan.c               | 304 ++++++++++++++++++++++++++++++----------------
 mm/workingset.c           |  45 ++++---
 6 files changed, 380 insertions(+), 248 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index f52f02e8e5be..7c8288661edd 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -144,12 +144,13 @@ static inline int lru_hist_from_seq(unsigned long seq)
 	return seq % NR_HIST_GENS;
 }
 
-static inline int lru_tier_from_refs(int refs, bool workingset)
+static inline int lru_tier_from_refs(unsigned int refs)
 {
-	VM_WARN_ON_ONCE(refs > BIT(LRU_REFS_WIDTH));
-
-	/* see the comment on MAX_NR_TIERS */
-	return workingset ? MAX_NR_TIERS - 1 : order_base_2(refs);
+	BUILD_BUG_ON(fls(LRU_REFS_MAX - 1) > MAX_NR_TIERS - 1);
+	VM_WARN_ON_ONCE(refs > LRU_REFS_MAX);
+	if (refs < LRU_REFS_WORKINGSET)
+		return 0;
+	return fls(refs - 1);
 }
 
 /**
@@ -187,21 +188,24 @@ static inline int lru_get_gen_flags(unsigned long flags)
  * @flags: pointer to the folio flags
  * @refs: referenced / access count number, between 0 and LRU_REFS_MAX, inclusive.
  *
- * For MGLRU, PG_referenced holds the first ref, and the extra bits hold the
- * remaining refs. For classical LRU the extra bits are not used, so it can
- * also be seen as the refs count never exceeds 1. In both cases, refs == 1
- * means PG_referenced is set and the extra bits are zero, and refs == 0 means
- * PG_referenced and the extra bits are all unset.
+ * For MGLRU, PG_referenced, PG_workingset are used as the lower two bits of
+ * refs counter, and extra bits hold the remaining higher bits. For classical
+ * LRU the extra bits are not used, and the two flags has no direct
+ * relationship with each other, but this helper can still be used to sync
+ * them. For both cases, refs == 0 means these two flags and the extra bits
+ * are all unset. And refs == 1 / 2 / 3 means PG_referenced and PG_workingset
+ * are set in an bit order way, which is more meaningful for MGLRU though.
  */
 static inline void lru_set_refs_flags(unsigned long *flags, unsigned int refs)
 {
 	VM_WARN_ON_ONCE(refs > LRU_REFS_MAX);
-	BUILD_BUG_ON(LRU_REFS_MAX != (LRU_REFS_MASK >> LRU_REFS_PGOFF) + 1);
-
+	BUILD_BUG_ON(LRU_REFS_MASK & (BIT(PG_referenced) | BIT(PG_workingset)));
 	*flags &= ~LRU_REFS_FLAGS;
-	if (!refs)
-		return;
-	*flags |= (BIT(PG_referenced) | ((refs - 1UL) << LRU_REFS_PGOFF));
+	if (refs & BIT(0))
+		*flags |= BIT(PG_referenced);
+	if (refs & BIT(1))
+		*flags |= BIT(PG_workingset);
+	*flags |= ((unsigned long)refs >> 2) << LRU_REFS_PGOFF;
 }
 
 /**
@@ -212,13 +216,13 @@ static inline void lru_set_refs_flags(unsigned long *flags, unsigned int refs)
  */
 static inline int lru_get_refs_flags(unsigned long flags)
 {
-	if (!(flags & BIT(PG_referenced)))
-		return 0;
-	/*
-	 * Return the total number of accesses including PG_referenced. Also see
-	 * the comment on LRU_REFS_FLAGS.
-	 */
-	return ((flags & LRU_REFS_MASK) >> LRU_REFS_PGOFF) + 1;
+	int refs;
+
+	/* Return the total number of accesses. See the comment on LRU_REFS_FLAGS. */
+	refs = (flags & BIT(PG_referenced)) ? BIT(0) : 0;
+	refs += (flags & BIT(PG_workingset)) ? BIT(1) : 0;
+	refs += ((flags & LRU_REFS_MASK) >> LRU_REFS_PGOFF) << 2;
+	return refs;
 }
 
 static inline int folio_lru_refs(const struct folio *folio)
@@ -236,6 +240,8 @@ static inline void folio_set_lru_refs(struct folio *folio, unsigned int refs)
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 }
 
+void folio_inc_lru_refs(struct folio *folio, unsigned int flags);
+
 static inline int folio_lru_gen(const struct folio *folio)
 {
 	return lru_get_gen_flags(READ_ONCE(*const_folio_flags(folio, 0)));
@@ -243,7 +249,7 @@ static inline int folio_lru_gen(const struct folio *folio)
 
 static inline bool lru_gen_is_active(const struct lruvec *lruvec, int gen)
 {
-	unsigned long max_seq = lruvec->lrugen.max_seq;
+	unsigned long max_seq = READ_ONCE(lruvec->lrugen.max_seq);
 
 	VM_WARN_ON_ONCE(gen >= MAX_NR_GENS);
 
@@ -300,23 +306,24 @@ static inline unsigned long lru_gen_folio_seq(const struct lruvec *lruvec,
 					      bool reclaiming)
 {
 	int gen;
+	int refs = folio_lru_refs(folio);
 	int type = folio_is_file_lru(folio);
 	const struct lru_gen_folio *lrugen = &lruvec->lrugen;
 
 	/*
-	 * +-----------------------------------+-----------------------------------+
-	 * | Accessed through page tables and  | Accessed through file descriptors |
-	 * | promoted by folio_update_gen()    | and protected by folio_inc_gen()  |
-	 * +-----------------------------------+-----------------------------------+
-	 * | PG_active (set while isolated)    |                                   |
-	 * +-----------------+-----------------+-----------------+-----------------+
-	 * |  PG_workingset  |  PG_referenced  |  PG_workingset  |  LRU_REFS_FLAGS |
-	 * +-----------------------------------+-----------------------------------+
-	 * |<---------- MIN_NR_GENS ---------->|                                   |
-	 * |<---------------------------- MAX_NR_GENS ---------------------------->|
+	 * +------------------------------------------+------------------------------------------+
+	 * |     Accessed through page tables and     |     Accessed through file descriptors    |
+	 * | promoted by folio_inc_lru_refs_walk()    | protected by folio_inc_lru_refs/inc_gen  |
+	 * +------------------------------------------+------------------------------------------+
+	 * | PG_active (set at isolation or refault)  |                                          |
+	 * +--------------------+---------------------+--------------------+---------------------+
+	 * |     LRU_REFS_MAX   | LRU_REFS_WORKINGSET |    LRU_REFS_MAX    | LRU_REFS_WORKINGSET |
+	 * +------------------------------------------+------------------------------------------+
+	 * |<-------------- MIN_NR_GENS ------------->|                                          |
+	 * |<----------------------------------- MAX_NR_GENS ----------------------------------->|
 	 */
 	if (folio_test_active(folio))
-		gen = MIN_NR_GENS - folio_test_workingset(folio);
+		gen = MIN_NR_GENS - (refs >= LRU_REFS_WORKINGSET);
 	else if (reclaiming)
 		gen = MAX_NR_GENS;
 	else if ((!folio_is_file_lru(folio) && !folio_test_swapcache(folio)) ||
@@ -324,7 +331,7 @@ static inline unsigned long lru_gen_folio_seq(const struct lruvec *lruvec,
 		  (folio_test_dirty(folio) || folio_test_writeback(folio))))
 		gen = MIN_NR_GENS;
 	else
-		gen = MAX_NR_GENS - (folio_test_workingset(folio) || folio_test_referenced(folio));
+		gen = MAX_NR_GENS - (refs >= LRU_REFS_WORKINGSET);
 
 	return max(READ_ONCE(lrugen->max_seq) - gen + 1, READ_ONCE(lrugen->min_seq[type]));
 }
@@ -338,6 +345,7 @@ static inline bool lru_gen_add_folio(struct lruvec *lruvec, struct folio *folio,
 	int zone = folio_zonenum(folio);
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 
+	BUILD_BUG_ON(BIT(LRU_GEN_WIDTH - 1) != MAX_NR_GENS);
 	VM_WARN_ON_ONCE_FOLIO(gen != -1, folio);
 
 	if (folio_test_unevictable(folio) || !lrugen->enabled)
@@ -392,7 +400,6 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
  */
 static inline void folio_migrate_lru_refs(struct folio *new, const struct folio *old)
 {
-	BUILD_BUG_ON(LRU_REFS_MASK & BIT(PG_referenced));
 	folio_set_lru_refs(new, folio_lru_refs(old));
 }
 #else /* !CONFIG_LRU_GEN */
@@ -422,6 +429,10 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 	return false;
 }
 
+static inline void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
+{
+}
+
 static inline void folio_migrate_lru_refs(struct folio *new, const struct folio *old)
 {
 	if (folio_test_referenced(old))
diff --git a/include/linux/mmzone.h b/include/linux/mmzone.h
index de7d3f8059a5..523783186c57 100644
--- a/include/linux/mmzone.h
+++ b/include/linux/mmzone.h
@@ -475,57 +475,121 @@ enum lruvec_flags {
 #define MAX_NR_GENS		4U
 
 /*
- * Each generation is divided into multiple tiers. A folio accessed N times
- * through file descriptors is in tier order_base_2(N). A folio in the first
- * tier (N=0,1) is marked by PG_referenced unless it was faulted in through page
- * tables or read ahead. A folio in the last tier (MAX_NR_TIERS-1) is marked by
- * PG_workingset. A folio in any other tier (1<N<5) between the first and last
- * is marked by additional bits of LRU_REFS_WIDTH in folio->flags.
+ * Each generation is divided into multiple tiers. A folio's referenced
+ * count maps to a tier as shown below:
  *
- * In contrast to moving across generations which requires the LRU lock, moving
- * across tiers only involves atomic operations on folio->flags and therefore
- * has a negligible cost in the buffered access path. In the eviction path,
- * comparisons of refaulted/(evicted+protected) from the first tier and the rest
- * infer whether folios accessed multiple times through file descriptors are
- * statistically hot and thus worth protecting.
+ * MGLRU (frequency guidance)
+ *  Refs  Tier  |- Refs: how many times (at least) a folio has been referenced.
+ *   0      0   |- Mostly cold pages, readahead, etc. [1]
+ *   1      0   |= LRU_REFS_REFERENCED: Used at least once. [2]
+ * -WORKINGSET-+|- Pages beyond are workingset and never fall below this floor. [3]
+ *   2      1<-+|= LRU_REFS_WORKINGSET: Classical workingset, accessed twice, protected. [4]
+ *   3      2   |- LRU_REFS_PROTECTED: Protected workingset, promoted pages capped at here. [5]
+ *   4      2   |
+ *   5      3   |- The tier here is MAX_NR_TIERS - 1
+ *   6      3   |
+ *   7      3   |= LRU_REFS_MAX: Promotion candidate. [6]
+ * -PROMOTION->-/
  *
- * MAX_NR_TIERS is set to 4 so that the multi-gen LRU can support twice the
- * number of categories of the active/inactive LRU when keeping track of
- * accesses through file descriptors. This uses MAX_NR_TIERS-2 spare bits in
- * folio->flags, masked by LRU_REFS_MASK.
+ * Ideally each tier holds folios of similar access patterns: lower tiers
+ * are less important and evicted faster.  A page's reference count and
+ * tier are capped when it changes generation, preventing it from
+ * dominating the new generation based on old-generation access history.
+ * Generation ordering already ensures a newer-gen page is hotter than an
+ * older-gen one regardless of tier.
+ *
+ * Refs tracks accesses from two sources: page table (lazily collected by
+ * the page table aging walk or rmap eviction lookup) and file descriptors
+ * (by folio_mark_accessed).  Page table accesses are weighted heavier
+ * because the accessed bit is sticky (undercounts repeated accesses),
+ * passively collected, and page faults are generally more important as
+ * userspace does not expect a memory access to block on reclaim.  Both
+ * access types increment refs by one; the result is capped at
+ * LRU_REFS_PROTECTED on promotion or deferral, or LRU_REFS_MAX otherwise.
+ *
+ * 1. Tier is fls(N-1) for N > 1, 0 otherwise.  Folios with zero
+ *    accesses (refs == 0) are generally cold, e.g. readahead folios.
+ *
+ *    Page table access advances a folio by one generation even at the
+ *    lowest refs or tier.  Freshly allocated folios start with refs == 0;
+ *    faulted and mapped folios have their page table access bit set, so
+ *    the first page table access check always sets LRU_REFS_REFERENCED and
+ *    moves them one generation forward, driving aging and workingset shift.
+ *
+ * 2. Folios accessed once stay on tier 0: one-time usage does not
+ *    qualify for protection.  A second access advances the folio,
+ *    aligning with classical LRU's use-twice threshold.  A second page
+ *    table access promotes to the latest gen; file access only defers
+ *    eviction from the oldest gen.
+ *
+ * 3. Folios accessed at least twice are considered workingset.  This
+ *    mostly aligns with classical LRU: at least one I/O is saved by
+ *    keeping them in memory.  Folios at or above this level never fall
+ *    below tier 1 (the workingset floor), so tier 0 stays a clean tier
+ *    for cold cache while tier 1 serves as the fallback line for
+ *    actually reused or historically hot folios.
+ *
+ *    Folios refaulted through a page fault at refs 1 will enter the second
+ *    newest gen, so faulting will be protected better.
+ *
+ * 4. Starting from tier 1, PID protection sacrifices lower tiers to
+ *    protect higher tiers by comparing refault rates for long-term
+ *    accuracy, and caps higher refs to this value.  Since PID protection
+ *    bypasses page table lookup and clearing, when a further eviction
+ *    attempt occurs after PID loosens, the folio's page table access is
+ *    rechecked and the folio is sent back to LRU_REFS_PROTECTED.  This
+ *    also gives folios a fair opportunity to be promoted by file access
+ *    again.
+ *
+ *    Folios refaulted through a page fault at tier 1 or above are activated
+ *    and enter the newest gen. Non fault page will enter second oldest gen,
+ *    driving aging and workingset shifting.
+ *
+ * 5. Pages beyond the ordinary workingset tier form new tiers for the
+ *    PID controller to protect differently.  Folios at or above this
+ *    level are capped at LRU_REFS_PROTECTED on promotion or deferral,
+ *    and at LRU_REFS_WORKINGSET under PID protection in the oldest
+ *    generation, where they represent a historical workingset.
+ *
+ * 6. Folios that reach LRU_REFS_MAX are advanced to the next generation
+ *    on further access, with refs capped to LRU_REFS_PROTECTED.  This
+ *    gives them a fair start for advancement to an even newer generation
+ *    while keeping hot folios distinguishable.
+ *
+ * Tiering uses PG_referenced and PG_workingset as the lower two bits,
+ * and the bits masked by LRU_REFS_MASK as the higher bits, so the refs
+ * count ranges from 0 to LRU_REFS_MAX.  A folio is on the workingset
+ * tier once accessed at least twice, which is more consistent with the
+ * classical LRU.
+ *
+ * A folio's referenced count never goes backwards except upon gen
+ * increase as described above, or when explicitly reset by
+ * lru_gen_clear_refs().  Refault of a reclaimed folio restores
+ * its referenced count, capped at LRU_REFS_PROTECTED, which aligns with
+ * promotion.  Page table refaults of previous workingset folios send
+ * them to the latest gen, driving aging faster.
+ *
+ * MAX_NR_TIERS is set to 4 so that the multi-gen LRU can support twice
+ * the number of categories of the active/inactive LRU.
  */
 #define MAX_NR_TIERS		4U
 #define LRU_TIER_MIN		0U
 #define LRU_TIER_MAX		(MAX_NR_TIERS - 1)
 
+/* Access source flags for folio_inc_lru_refs() */
+#define LRU_REF_MAPPED		0x1U
+#define LRU_REF_EXEC		0x2U
+
+#define LRU_REFS_REFERENCED	0x1
+#define LRU_REFS_WORKINGSET	0x2
+#define LRU_REFS_PROTECTED	0x3
+
 #ifndef __GENERATING_BOUNDS_H
 
 #define LRU_GEN_MASK		((BIT(LRU_GEN_WIDTH) - 1) << LRU_GEN_PGOFF)
 #define LRU_REFS_MASK		((BIT(LRU_REFS_WIDTH) - 1) << LRU_REFS_PGOFF)
-#define LRU_REFS_MAX		BIT(LRU_REFS_WIDTH)
-
-/*
- * For folios accessed multiple times through file descriptors,
- * lru_gen_inc_refs() sets additional bits of LRU_REFS_WIDTH in folio->flags
- * after PG_referenced, then PG_workingset after LRU_REFS_WIDTH. After all its
- * bits are set, i.e., LRU_REFS_FLAGS|BIT(PG_workingset), a folio is lazily
- * promoted into the second oldest generation in the eviction path. And when
- * folio_inc_gen() does that, it clears LRU_REFS_FLAGS so that
- * lru_gen_inc_refs() can start over. Note that for this case, LRU_REFS_MASK is
- * only valid when PG_referenced is set.
- *
- * For folios accessed multiple times through page tables, folio_update_gen()
- * from a page table walk or lru_gen_set_refs() from a rmap walk sets
- * PG_referenced after the accessed bit is cleared for the first time.
- * Thereafter, those two paths set PG_workingset and promote folios to the
- * youngest generation. Like folio_inc_gen(), folio_update_gen() also clears
- * PG_referenced. Note that for this case, LRU_REFS_MASK is not used.
- *
- * For both cases above, after PG_workingset is set on a folio, it remains until
- * this folio is either reclaimed, or "deactivated" by lru_gen_clear_refs(). It
- * can be set again if lru_gen_test_recent() returns true upon a refault.
- */
-#define LRU_REFS_FLAGS		(LRU_REFS_MASK | BIT(PG_referenced))
+#define LRU_REFS_FLAGS		(LRU_REFS_MASK | BIT(PG_referenced) | BIT(PG_workingset))
+#define LRU_REFS_MAX		(BIT(LRU_REFS_WIDTH + 2) - 1)
 
 struct lruvec;
 struct page_vma_mapped_walk;
diff --git a/kernel/bounds.c b/kernel/bounds.c
index 02b619eb6106..06a034713b5d 100644
--- a/kernel/bounds.c
+++ b/kernel/bounds.c
@@ -25,7 +25,7 @@ int main(void)
 	DEFINE(SPINLOCK_SIZE, sizeof(spinlock_t));
 #ifdef CONFIG_LRU_GEN
 	DEFINE(LRU_GEN_WIDTH, order_base_2(MAX_NR_GENS + 1));
-	DEFINE(__LRU_REFS_WIDTH, MAX_NR_TIERS - 2);
+	DEFINE(__LRU_REFS_WIDTH, MAX_NR_TIERS - 3);
 #else
 	DEFINE(LRU_GEN_WIDTH, 0);
 	DEFINE(__LRU_REFS_WIDTH, 0);
diff --git a/mm/folio.c b/mm/folio.c
index 47a437e0f7fd..55cb37366487 100644
--- a/mm/folio.c
+++ b/mm/folio.c
@@ -273,7 +273,6 @@ static void lru_activate(struct lruvec *lruvec, struct folio *folio)
 	if (folio_test_active(folio) || folio_test_unevictable(folio))
 		return;
 
-
 	lruvec_del_folio(lruvec, folio);
 	folio_set_active(folio);
 	lruvec_add_folio(lruvec, folio);
@@ -352,32 +351,6 @@ static void __lru_cache_activate_folio(struct folio *folio)
 
 #ifdef CONFIG_LRU_GEN
 
-static void lru_gen_inc_refs(struct folio *folio)
-{
-	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
-	int refs;
-
-	if (folio_test_unevictable(folio))
-		return;
-
-	/* see the comment on LRU_REFS_FLAGS */
-	if (!folio_lru_refs(folio)) {
-		folio_set_lru_refs(folio, 1);
-		return;
-	}
-
-	do {
-		new_flags = old_flags;
-		refs = lru_get_refs_flags(old_flags);
-		if (refs == LRU_REFS_MAX) {
-			if (!folio_test_workingset(folio))
-				folio_set_workingset(folio);
-			return;
-		}
-		lru_set_refs_flags(&new_flags, refs + 1);
-	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
-}
-
 static bool lru_gen_clear_refs(struct folio *folio)
 {
 	int gen = folio_lru_gen(folio);
@@ -388,7 +361,6 @@ static bool lru_gen_clear_refs(struct folio *folio)
 		return true;
 
 	folio_set_lru_refs(folio, 0);
-	folio_clear_workingset(folio);
 
 	rcu_read_lock();
 	seq = READ_ONCE(folio_lruvec(folio)->lrugen.min_seq[type]);
@@ -399,10 +371,6 @@ static bool lru_gen_clear_refs(struct folio *folio)
 
 #else /* !CONFIG_LRU_GEN */
 
-static void lru_gen_inc_refs(struct folio *folio)
-{
-}
-
 static bool lru_gen_clear_refs(struct folio *folio)
 {
 	return false;
@@ -428,7 +396,8 @@ void folio_mark_accessed(struct folio *folio)
 	if (folio_test_dropbehind(folio))
 		return;
 	if (lru_gen_enabled()) {
-		lru_gen_inc_refs(folio);
+		if (!folio_test_unevictable(folio))
+			folio_inc_lru_refs(folio, 0);
 		return;
 	}
 
@@ -474,21 +443,6 @@ void folio_add_lru(struct folio *folio)
 			folio_test_unevictable(folio), folio);
 	VM_BUG_ON_FOLIO(folio_test_lru(folio), folio);
 
-	/*
-	 * For refaulted workingset folios, set PG_active so they
-	 * can be added to active generations.
-	 * For prefaulted file folios, folio_mark_accessed() sets
-	 * PG_referenced so lru_gen_folio_seq() places them into
-	 * the second oldest generation.
-	 */
-	if (lru_gen_enabled() && !folio_test_unevictable(folio) &&
-	    lru_gen_in_fault() && !(current->flags & PF_MEMALLOC)) {
-		if (folio_test_workingset(folio))
-			folio_set_active(folio);
-		else if (!folio_test_referenced(folio))
-			folio_mark_accessed(folio);
-	}
-
 	folio_batch_add_and_move(folio, lru_add);
 }
 EXPORT_SYMBOL(folio_add_lru);
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 32890e628240..9be0cd20dc54 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -902,38 +902,175 @@ enum folio_references {
 };
 
 #ifdef CONFIG_LRU_GEN
+/******************************************************************************
+ *                     Referenced count feedback
+ ******************************************************************************/
+
 /*
- * Only used on a mapped folio in the eviction (rmap walk) path, where promotion
- * needs to be done by taking the folio off the LRU list and then adding it back
- * with PG_active set. In contrast, the aging (page table walk) path uses
- * folio_update_gen().
+ * The folio_inc_lru_refs{_*} helpers below collect the referenced info
+ * (hotness) from other parts, including the page table walker, the rmap walk
+ * upon eviction, the rmap lookaround, and file descriptors
+ * (folio_mark_accessed).
+ *
+ * Page table accesses escalate a folio in two steps.  The first access
+ * advances it one generation; a second access sends it to the newest
+ * generation.  Executable file folios skip the first step and are promoted
+ * immediately, as reclaiming them causes IO thrashing.
+ *
+ * File descriptor accesses do not promote.  They only defer eviction from
+ * the oldest generation, and only once the folio is a workingset folio
+ * (LRU_REFS_WORKINGSET), leaving the rest to PID protection.  Page table
+ * accesses are treated more generously because the accessed bit is sticky
+ * (it under-counts repeated accesses) and because a page fault is more
+ * costly than file descriptor I/O.
+ *
+ * PID protection operates on tier > 0 folios.  The one proactive promotion
+ * outside of it and the page table path is the overflow case where the
+ * referenced count exceeds LRU_REFS_MAX, which means the folio is hotter
+ * than everything else in its generation.
+ *
+ * Whenever a folio changes generation here its referenced count is capped at
+ * LRU_REFS_PROTECTED, so it starts at or below the protected tier regardless
+ * of its old-generation access history.  PID protection (folio_inc_gen) caps
+ * at LRU_REFS_WORKINGSET independently.
  */
-static bool lru_gen_set_refs(struct folio *folio, const vma_flags_t *vma_flags)
-{
-	/* see the comment on LRU_REFS_FLAGS */
-	if (!folio_test_referenced(folio) && !folio_test_workingset(folio)) {
-		/* Activate file-backed executable folios after first usage. */
-		if (is_exec_file_folio(folio, vma_flags)) {
-			folio_set_workingset(folio);
-			folio_set_lru_refs(folio, 0);
-			return true;
+
+/*
+ * Update the folio's lru refs indicator. The caller doesn't need to hold
+ * the folio lock, isolate the folio, or hold the lruvec lock. Used by both
+ * cache access (flags == 0) and page table access (LRU_REF_MAPPED,
+ * optionally with LRU_REF_EXEC).
+ */
+void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
+{
+	int max_gen, min_gen;
+	int type, refs, old_gen, gen;
+	unsigned long new_flags, old_flags, max_seq;
+	struct lru_gen_folio *lrugen;
+	struct lruvec *lruvec = NULL;
+
+	type = folio_is_file_lru(folio);
+	old_flags = READ_ONCE(*folio_flags(folio, 0));
+	do {
+		new_flags = old_flags;
+		old_gen = lru_get_gen_flags(old_flags);
+		refs = lru_get_refs_flags(old_flags) + 1;
+		gen = old_gen;
+		if (old_gen < 0)
+			goto out;
+		/*
+		 * Lock the lruvec if the folio is on-list. We are already
+		 * doing lazy promotion so in theory we don't need this,
+		 * but for now, concurrent aging would still corrupt the
+		 * size counters.  This is a temporary limitation and
+		 * will be lifted very soon, so the lock here is not a
+		 * performance concern.
+		 */
+		if (!lruvec) {
+			lruvec = lruvec_live_lock_irq(folio_lruvec(folio));
+			lrugen = &lruvec->lrugen;
 		}
+		max_seq = READ_ONCE(lrugen->max_seq);
+		max_gen = lru_gen_from_seq(max_seq);
+		min_gen = lru_gen_from_seq(READ_ONCE(lrugen->min_seq[type]));
+		if (old_gen == max_gen)
+			goto out;
 
-		folio_set_lru_refs(folio, 1);
-		return false;
-	}
+		if (flags & (LRU_REF_MAPPED | LRU_REF_EXEC)) {
+			/* Promote second page table access or executable */
+			if (refs > LRU_REFS_REFERENCED || flags & LRU_REF_EXEC)
+				gen = max_gen;
+			else
+				gen = (old_gen + 1) % MAX_NR_GENS;
+			refs = min(refs, LRU_REFS_PROTECTED);
+		} else if (refs > LRU_REFS_MAX) {
+			/* LRU refs counting overflow, bump the gen */
+			gen = (old_gen + 1) % MAX_NR_GENS;
+			refs = LRU_REFS_PROTECTED;
+		} else if (old_gen == min_gen && refs >= LRU_REFS_WORKINGSET) {
+			/* Defer eviction of just accessed workingset */
+			gen = (old_gen + 1) % MAX_NR_GENS;
+			refs = min(refs, LRU_REFS_PROTECTED);
+		}
+out:
+		refs = min(refs, LRU_REFS_MAX);
+		lru_set_refs_flags(&new_flags, refs);
+		if (gen != old_gen)
+			lru_set_gen_flags(&new_flags, gen);
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
-	/* Promote on second access */
-	if (folio_lru_refs(folio) > 1) {
-		folio_set_workingset(folio);
-		folio_set_lru_refs(folio, 0);
-	} else {
-		folio_mark_accessed(folio);
-	}
-	return true;
+	if (gen != old_gen)
+		lru_gen_update_size(lruvec, folio, old_gen, gen);
+	if (lruvec)
+		lruvec_unlock_irq(lruvec);
+}
+
+/*
+ * Update the folio's lru refs indicator during a page table walk.
+ * max_seq is stable since this runs inside the aging process.
+ *
+ * Returns the old generation and stores the new generation in @new_gen when
+ * the folio is promoted (to max_gen) or advanced by one generation.
+ * Returns -1 if no gen change occurred.
+ */
+static int folio_inc_lru_refs_walk(struct folio *folio, struct lruvec *lruvec,
+				   const vma_flags_t *vma_flags,
+				   int *new_gen, int *type)
+{
+	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
+	unsigned long max_seq = READ_ONCE(lruvec->lrugen.max_seq);
+	int refs, gen, max_gen, ret;
+
+	max_gen = lru_gen_from_seq(max_seq);
+
+	do {
+		gen = lru_get_gen_flags(old_flags);
+		refs = lru_get_refs_flags(old_flags) + 1;
+		new_flags = old_flags;
+
+		if (gen >= 0 && gen != max_gen) {
+			ret = gen;
+			/* Promote second page table access or executable */
+			if (refs > LRU_REFS_REFERENCED || is_exec_file_folio(folio, vma_flags))
+				*new_gen = max_gen;
+			else
+				*new_gen = (gen + 1) % MAX_NR_GENS;
+			lru_set_gen_flags(&new_flags, *new_gen);
+			lru_set_refs_flags(&new_flags, min(refs, LRU_REFS_PROTECTED));
+		} else {
+			ret = -1;
+			lru_set_refs_flags(&new_flags, min(refs, LRU_REFS_MAX));
+		}
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
+
+	*type = folio_flags_is_file_lru(&old_flags);
+	return ret;
+}
+
+/*
+ * Update the lru refs indicator of an isolated folio, only used on
+ * mapped folios upon the final eviction.
+ *
+ * Increments the refs count (capped at LRU_REFS_PROTECTED).  Returns true
+ * if the caller should activate the folio (second access or
+ * executable), false to keep it in the eviction list.
+ */
+static bool folio_inc_lru_refs_isolated(struct folio *folio, const vma_flags_t *vma_flags)
+{
+	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
+	int refs;
+
+	do {
+		new_flags = old_flags;
+		refs = lru_get_refs_flags(old_flags) + 1;
+		lru_set_refs_flags(&new_flags, min(refs, LRU_REFS_PROTECTED));
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
+
+	/* Promote second page table access or executable */
+	return refs > LRU_REFS_REFERENCED || is_exec_file_folio(folio, vma_flags);
 }
 #else
-static bool lru_gen_set_refs(struct folio *folio, const vma_flags_t *vma_flags)
+static bool folio_inc_lru_refs_isolated(struct folio *folio, const vma_flags_t *vma_flags)
 {
 	return false;
 }
@@ -968,7 +1105,8 @@ static enum folio_references folio_check_references(struct folio *folio,
 		if (!referenced_ptes)
 			return FOLIOREF_RECLAIM;
 
-		return lru_gen_set_refs(folio, &vma_flags) ? FOLIOREF_ACTIVATE : FOLIOREF_KEEP;
+		return folio_inc_lru_refs_isolated(folio, &vma_flags) ?
+		       FOLIOREF_ACTIVATE : FOLIOREF_KEEP;
 	}
 
 	referenced_folio = folio_test_clear_referenced(folio);
@@ -3344,50 +3482,15 @@ static bool positive_ctrl_err(struct ctrl_pos *sp, struct ctrl_pos *pv)
  *                          the aging
  ******************************************************************************/
 
-/* promote pages accessed through page tables */
-static int folio_update_gen(struct folio *folio, int new_gen, int *type,
-			    const vma_flags_t *vma_flags)
-{
-	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
-	int old_gen;
-
-	/*
-	 * See the comment on LRU_REFS_FLAGS, and activate file-backed
-	 * executable folios after first usage to avoid typical IO
-	 * thrashing from reclaiming.
-	 */
-	if (!folio_test_referenced(folio) && !folio_test_workingset(folio) &&
-	    !is_exec_file_folio(folio, vma_flags)) {
-		folio_set_lru_refs(folio, 1);
-		return -1;
-	}
-
-	do {
-		old_gen = lru_get_gen_flags(old_flags);
-		new_flags = old_flags;
-
-		/* lru_gen_del_folio() has isolated this page? */
-		if (old_gen < 0)
-			break;
-
-		lru_set_gen_flags(&new_flags, new_gen);
-		lru_set_refs_flags(&new_flags, 0);
-		new_flags |= BIT(PG_workingset);
-	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
-
-	*type = folio_flags_is_file_lru(&old_flags);
-	return old_gen;
-}
-
 static int __folio_inc_gen(struct folio *folio, int old_gen, bool *increased)
 {
 	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
-	int new_gen;
+	int refs, new_gen;
 
 	do {
 		new_gen = lru_get_gen_flags(old_flags);
 
-		/* folio_update_gen() has promoted this page? */
+		/* folio_inc_lru_refs() has promoted this page? */
 		if (new_gen >= 0 && new_gen != old_gen) {
 			if (increased)
 				*increased = false;
@@ -3396,9 +3499,9 @@ static int __folio_inc_gen(struct folio *folio, int old_gen, bool *increased)
 
 		new_flags = old_flags;
 		new_gen = (old_gen + 1) % MAX_NR_GENS;
-
+		refs = lru_get_refs_flags(old_flags);
 		lru_set_gen_flags(&new_flags, new_gen);
-		lru_set_refs_flags(&new_flags, 0);
+		lru_set_refs_flags(&new_flags, min(refs, LRU_REFS_WORKINGSET));
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
 	if (increased)
@@ -3406,17 +3509,21 @@ static int __folio_inc_gen(struct folio *folio, int old_gen, bool *increased)
 	return new_gen;
 }
 
-/* protect pages accessed multiple times through file descriptors */
+/*
+ * Force bump a folio's generation. Used for PID protection or to defer
+ * eviction of a temporarily unevictable folio.
+ */
 static int folio_inc_gen(struct lruvec *lruvec, struct folio *folio)
 {
+	bool gen_increased;
 	int type = folio_is_file_lru(folio);
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 	int new_gen, old_gen = lru_gen_from_seq(lrugen->min_seq[type]);
-	bool gen_increased;
 
 	new_gen = __folio_inc_gen(folio, old_gen, &gen_increased);
 	if (gen_increased)
 		lru_gen_update_size(lruvec, folio, old_gen, new_gen);
+
 	return new_gen;
 }
 
@@ -3611,25 +3718,25 @@ static void walk_update_folio(struct lru_gen_mm_walk *walk, struct vm_area_struc
 		struct lruvec *lruvec, struct folio *folio, bool dirty)
 {
 	int new_gen, old_gen, type;
+	unsigned int flags = LRU_REF_MAPPED;
 
 	if (!folio)
 		return;
 
-	new_gen = lru_gen_from_seq(READ_ONCE(lruvec->lrugen.max_seq));
-
 	if (dirty && !folio_test_dirty(folio) &&
 	    !(folio_test_anon(folio) && folio_test_swapbacked(folio) &&
 	      !folio_test_swapcache(folio)))
 		folio_mark_dirty(folio);
 
 	if (walk) {
-		old_gen = folio_update_gen(folio, new_gen, &type, &vma->flags);
-		if (old_gen >= 0 && old_gen != new_gen)
+		old_gen = folio_inc_lru_refs_walk(folio, lruvec, &vma->flags,
+						  &new_gen, &type);
+		if (old_gen >= 0)
 			update_batch_size(walk, folio, old_gen, new_gen, type);
-	} else if (lru_gen_set_refs(folio, &vma->flags)) {
-		old_gen = folio_lru_gen(folio);
-		if (old_gen >= 0 && old_gen != new_gen)
-			folio_activate(folio);
+	} else {
+		if (is_exec_file_folio(folio, &vma->flags))
+			flags |= LRU_REF_EXEC;
+		folio_inc_lru_refs(folio, flags);
 	}
 }
 
@@ -4036,7 +4143,7 @@ static bool inc_min_seq(struct lruvec *lruvec, int type, int swappiness)
 			struct folio *folio = list_entry(pos, struct folio, lru);
 			long nr_pages = folio_nr_pages(folio);
 			int refs = folio_lru_refs(folio);
-			bool workingset = folio_test_workingset(folio);
+			int tier = lru_tier_from_refs(refs);
 			bool gen_increased;
 
 			VM_WARN_ON_ONCE_FOLIO(folio_test_unevictable(folio), folio);
@@ -4056,13 +4163,8 @@ static bool inc_min_seq(struct lruvec *lruvec, int type, int swappiness)
 				delta += nr_pages;
 				batch_end = &folio->lru;
 
-				/* don't count the workingset being lazily promoted */
-				if (refs + workingset != BIT(LRU_REFS_WIDTH) + 1) {
-					int tier = lru_tier_from_refs(refs, workingset);
-
-					WRITE_ONCE(lrugen->protected[hist][type][tier],
-						   lrugen->protected[hist][type][tier] + nr_pages);
-				}
+				WRITE_ONCE(lrugen->protected[hist][type][tier],
+					   lrugen->protected[hist][type][tier] + nr_pages);
 			} else {
 				flush_lru_batch(head, &batch_end, target_list);
 				list_move(&folio->lru, &lrugen->folios[new_gen][type][zone]);
@@ -4777,8 +4879,7 @@ static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_c
 	int zone = folio_zonenum(folio);
 	int delta = folio_nr_pages(folio);
 	int refs = folio_lru_refs(folio);
-	bool workingset = folio_test_workingset(folio);
-	int tier = lru_tier_from_refs(refs, workingset);
+	int tier = lru_tier_from_refs(refs);
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 
 	VM_WARN_ON_ONCE_FOLIO(gen >= MAX_NR_GENS, folio);
@@ -4794,17 +4895,15 @@ static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_c
 	}
 
 	/* protected */
-	if (tier > tier_idx || refs + workingset == BIT(LRU_REFS_WIDTH) + 1) {
+	if (tier > tier_idx) {
+		int hist = lru_hist_from_seq(lrugen->min_seq[type]);
+
 		gen = folio_inc_gen(lruvec, folio);
 		list_move(&folio->lru, &lrugen->folios[gen][type][zone]);
 
-		/* don't count the workingset being lazily promoted */
-		if (refs + workingset != BIT(LRU_REFS_WIDTH) + 1) {
-			int hist = lru_hist_from_seq(lrugen->min_seq[type]);
+		WRITE_ONCE(lrugen->protected[hist][type][tier],
+			   lrugen->protected[hist][type][tier] + delta);
 
-			WRITE_ONCE(lrugen->protected[hist][type][tier],
-				   lrugen->protected[hist][type][tier] + delta);
-		}
 		return true;
 	}
 
@@ -4832,10 +4931,6 @@ static bool isolate_folio(struct lruvec *lruvec, struct folio *folio, struct sca
 		return false;
 	}
 
-	/* see the comment on LRU_REFS_FLAGS */
-	if (!folio_test_referenced(folio))
-		folio_set_lru_refs(folio, 0);
-
 	success = lru_gen_del_folio(lruvec, folio, true);
 	VM_WARN_ON_ONCE_FOLIO(!success, folio);
 
@@ -4923,13 +5018,14 @@ static int get_tier_idx(struct lruvec *lruvec, int type)
 	struct ctrl_pos sp, pv = {};
 
 	/*
-	 * To leave a margin for fluctuations, use a larger gain factor (2:3).
-	 * This value is chosen because any other tier would have at least twice
-	 * as many refaults as the first tier.
+	 * To leave a margin for fluctuations, use a larger gain factor (1:2).
+	 * Stop at the first tier whose refault rate is clearly worse than
+	 * that of the cumulative mass of the tiers below it; the PID
+	 * protects the tiers above it.
 	 */
-	read_ctrl_pos(lruvec, type, LRU_TIER_MIN, LRU_TIER_MIN, 2, &sp);
 	for (tier = LRU_TIER_MIN + 1; tier <= LRU_TIER_MAX; tier++) {
-		read_ctrl_pos(lruvec, type, tier, tier, 3, &pv);
+		read_ctrl_pos(lruvec, type, LRU_TIER_MIN, tier - 1, 1, &sp);
+		read_ctrl_pos(lruvec, type, tier, tier, 2, &pv);
 		if (!positive_ctrl_err(&sp, &pv))
 			break;
 	}
@@ -5067,10 +5163,8 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 			continue;
 		}
 
-		/* See the comments on LRU_REFS_FLAGS */
-		folio_set_lru_refs(folio, 0);
-
-		/* don't add rejected folios to the oldest generation */
+		/* Reset folio's refs before return */
+		folio_set_lru_refs(folio, min(folio_lru_refs(folio), LRU_REFS_WORKINGSET));
 		if (lru_gen_folio_seq(lruvec, folio, false) == min_seq[type])
 			folio_set_active(folio);
 	}
diff --git a/mm/workingset.c b/mm/workingset.c
index 8412f4840ae3..44be539b93d2 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -188,6 +188,12 @@
 #define EVICTION_SHIFT_ANON	(EVICTION_SHIFT + SWAP_COUNT_SHIFT)
 #define EVICTION_MASK	(~0UL >> EVICTION_SHIFT)
 #define EVICTION_MASK_ANON	(~0UL >> EVICTION_SHIFT_ANON)
+/*
+ * LRU refs uses LRU_REFS_WIDTH + 2 bits, the 2 bits being PG_workingset
+ * and PG_referenced.  The lowest bit is recorded in the workingset field
+ * of the shadow entry (to reuse pack_shadow()).
+ */
+#define LRU_REFS_BITS ((LRU_REFS_WIDTH + 2) - 1)
 
 /*
  * Eviction timestamps need to be able to cover the full range of
@@ -242,13 +248,12 @@ static void *lru_gen_eviction(struct folio *folio)
 	int type = folio_is_file_lru(folio);
 	int delta = folio_nr_pages(folio);
 	int refs = folio_lru_refs(folio);
-	bool workingset = folio_test_workingset(folio);
-	int tier = lru_tier_from_refs(refs, workingset);
+	int tier = lru_tier_from_refs(refs);
 	struct mem_cgroup *memcg;
 	struct pglist_data *pgdat = folio_pgdat(folio);
 	unsigned short memcg_id;
 
-	BUILD_BUG_ON(LRU_GEN_WIDTH + LRU_REFS_WIDTH >
+	BUILD_BUG_ON(LRU_GEN_WIDTH + LRU_REFS_BITS >
 		     BITS_PER_LONG - max(EVICTION_SHIFT, EVICTION_SHIFT_ANON));
 
 	rcu_read_lock();
@@ -256,14 +261,14 @@ static void *lru_gen_eviction(struct folio *folio)
 	lruvec = mem_cgroup_lruvec(memcg, pgdat);
 	lrugen = &lruvec->lrugen;
 	min_seq = READ_ONCE(lrugen->min_seq[type]);
-	token = (min_seq << LRU_REFS_WIDTH) | max(refs - 1, 0);
+	token = (min_seq << LRU_REFS_BITS) | refs >> 1;
 
 	hist = lru_hist_from_seq(min_seq);
 	atomic_long_add(delta, &lrugen->evicted[hist][type][tier]);
 	memcg_id = mem_cgroup_private_id(memcg);
 	rcu_read_unlock();
 
-	return pack_shadow(memcg_id, pgdat, token, workingset, type);
+	return pack_shadow(memcg_id, pgdat, token, refs & 1, type);
 }
 
 /*
@@ -284,9 +289,9 @@ static bool lru_gen_test_recent(void *shadow, struct lruvec **lruvec,
 	*lruvec = mem_cgroup_lruvec(memcg, pgdat);
 
 	max_seq = READ_ONCE((*lruvec)->lrugen.max_seq);
-	max_seq &= (file ? EVICTION_MASK : EVICTION_MASK_ANON) >> LRU_REFS_WIDTH;
+	max_seq &= (file ? EVICTION_MASK : EVICTION_MASK_ANON) >> LRU_REFS_BITS;
 
-	return abs_diff(max_seq, *token >> LRU_REFS_WIDTH) < MAX_NR_GENS;
+	return abs_diff(max_seq, *token >> LRU_REFS_BITS) < MAX_NR_GENS;
 }
 
 static void lru_gen_refault(struct folio *folio, void *shadow)
@@ -314,22 +319,26 @@ static void lru_gen_refault(struct folio *folio, void *shadow)
 	lrugen = &lruvec->lrugen;
 
 	hist = lru_hist_from_seq(READ_ONCE(lrugen->min_seq[type]));
-	refs = (token & (BIT(LRU_REFS_WIDTH) - 1)) + 1;
-	tier = lru_tier_from_refs(refs, workingset);
+	refs = ((token & (BIT(LRU_REFS_BITS) - 1)) << 1) + workingset;
+	tier = lru_tier_from_refs(refs);
 
 	atomic_long_add(delta, &lrugen->refaulted[hist][type][tier]);
 
-	if (workingset) {
-		/*
-		 * see folio_add_lru(), where folio_set_active() is
-		 * called for workingset folios
-		 */
-		if (lru_gen_in_fault())
+	/*
+	 * Activate a fault-driven refault folio, which would have been
+	 * promoted had it stayed in memory.
+	 */
+	if (refs >= LRU_REFS_REFERENCED) {
+		if (lru_gen_in_fault()) {
+			folio_set_active(folio);
 			mod_lruvec_state(lruvec, WORKINGSET_ACTIVATE_BASE + type, delta);
-		folio_set_workingset(folio);
+		}
+		/* Refault is also promotion, cap the refs like folio_inc_lru_refs */
+		folio_set_lru_refs(folio, min(refs, LRU_REFS_PROTECTED));
+	}
+
+	if (refs >= LRU_REFS_WORKINGSET)
 		mod_lruvec_state(lruvec, WORKINGSET_RESTORE_BASE + type, delta);
-	} else
-		set_mask_bits(&folio->flags.f, LRU_REFS_MASK, (refs - 1UL) << LRU_REFS_PGOFF);
 unlock:
 	rcu_read_unlock();
 }

-- 
2.55.0

