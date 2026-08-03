From: Kairui Song <kasong@tencent.com>
Date: Tue, 04 Aug 2026 03:47:05 +0800
Subject: [PATCH RFC 09/15] mm/mglru: frequency guided workingset promotion
 (MGLRU-FG)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-mglru-fg-v1-9-4d8dad39dad6@tencent.com>
References: <20260804-mglru-fg-v1-0-4d8dad39dad6@tencent.com>
In-Reply-To: <20260804-mglru-fg-v1-0-4d8dad39dad6@tencent.com>
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
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785786439; l=43085;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=PZVvdYTo29B+se/YGXvix1IVIJ4PBPQU7sKD9u9WNsE=;
 b=eOyEQ66pEutii2irfmeNMyZIjccwM8pMYrHNSfCqJ1S6VhxQd0nrq/COXHmYPXRLnXFB46nAU
 M30N7LZ64ZIBKNQ7Gm3WRRjwzWJSxFZHSVhCfy4vsDWiKs1Ns+DaRSf
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Complement MGLRU's eviction-time tier-PID protection with access-time
frequency-guided promotion.  Introduce a unified set of helpers built based
on referenced (access) count of a folio.

Each access increments a folio's referenced count stored in folio flags
(refs), refs still mappes to a logarithmic tier just like before, but with
more formal bit definitions, a few special thresholds are introduced:
LRU_REFS_REFERENCED (1), LRU_REFS_WORKINGSET (2), LRU_REFS_PROTECTED (3),
and LRU_REFS_MAX(7). When it reaches certain threshold, the folio is
promoted proactively instead of wait for the PID controller to kick in.

Also simplify MGLRU's usage of PG_workingset and PG_referenced, now
these 2 flags are purely used as the lower 2 bit of refs for MGLRU. This
doesn't effect classical LRU in any way. This will actually simplify and
make MGLRU's certain metric reading more accurate, and reduced MGLRU's
original tier / referenced count bit by one since only one extra bit is
now needed to record a max referenced count of 7 (previously 2 extra bits
are needed). This changes make sense because MGLRU doesn't have demotion
so these 2 flags are never separately useful for MGLRU.

This addresses several shortcomings of the old model:

- Long feedback loop: protection only activated after enough
  re-faults, by which time the folio is often no longer hot.

- Limited tier resolution: once referenced count exceeded the bits
  limit (8 previously), MGLRU could no longer distinguish hotter folios as
  they are capped by the tier.  And what's worse, PG_workingset
  forces a folio to stay on tier 3.

- Eviction-time bias: because PID protection activates upon eviction
  and always targets the LRU tail, it tends to protect cold tail
  folios at the expense of hotter head folios.  Once the tail folios
  consume the PID protection budget, head folios lose their
  protection.  Additionally, the PID cannot distinguish the access
  time of folios that share the same reference count.

Besides reworking the LRU_REFS related helpers and definitions, most of
the work is done by the helpers below; the implementation details are
described in their inline comments.

- folio_inc_lru_refs(): Used by both cache access (folio_mark_accessed)
  and page table access.  The folio could be off-list (isolated),
  unlocked, or unmapped.  This helper uses PG_lru to stabilize the
  folio and performs a speculative and lazy promotion.

- folio_inc_lru_refs_walk(): Used by the PTE walk path during aging,
  where generations are stable; performs lazy promotion.

- folio_inc_lru_refs_isolated(): Used by the rmap check before
  eviction.  The folio is isolated and hence this doesn't perform
  promotion by itself; the folio will be added back to the right gen
  upon return.

The eviction-time folio_inc_gen() still handles PID protection, but the
protection ratio is softer than before, and it caps refs at WORKINGSET
so the folio retains enough history to stay above the cold tier.

The PID controller gain factors in get_tier_idx() are also relaxed from
(2:3) to (1:2).  Since the new folio gen bump paths already proactively
protect hot folios, PID protection can afford to be more permissive
without increasing the refault rate.

PG_workingset and PG_referenced are repurposed as the low two bits
of the unified LRU reference count.  LRU_REFS_MASK provides the
higher bits.  This eliminates the old restriction where LRU_REFS_MASK
was only valid when PG_referenced was set, and allows all paths to use
the same encoding consistently.

Hence, a workingset folio is now defined as refs >= LRU_REFS_WORKINGSET
(2), matching the active/inactive LRU's definition and giving in-kernel
consumers (PSI, readahead) consistent behavior on MGLRU, which will be
done in later commits.

Note that PG_workingset and PG_referenced are no longer independent
flags under MGLRU.  Adjusting existing raw folio_test_*() callers
to the new semantics is left as follow-ups.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm_inline.h |  83 ++++++++-----
 include/linux/mmzone.h    | 135 ++++++++++++++-------
 kernel/bounds.c           |   2 +-
 mm/folio.c                |  46 +-------
 mm/vmscan.c               | 290 ++++++++++++++++++++++++++++++----------------
 mm/workingset.c           |  55 ++++++---
 6 files changed, 385 insertions(+), 226 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index 018a2f54a5c9..944baa91bf18 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -133,12 +133,13 @@ static inline int lru_hist_from_seq(unsigned long seq)
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
@@ -164,9 +165,8 @@ static inline int lru_gen_from_flags(unsigned long flags)
  */
 static inline void lru_gen_set_flags(unsigned long *flags, int gen)
 {
-	VM_WARN_ON_ONCE(gen > LRU_GEN_MAX || gen < 0);
 	BUILD_BUG_ON((LRU_GEN_MAX + 1) != MAX_NR_GENS);
-
+	VM_WARN_ON_ONCE(gen > LRU_GEN_MAX || gen < 0);
 	*flags &= ~LRU_GEN_MASK;
 	*flags |= (gen + 1UL) << LRU_GEN_PGOFF;
 }
@@ -177,13 +177,16 @@ static inline void lru_gen_set_flags(unsigned long *flags, int gen)
  */
 static inline int lru_refs_from_flags(unsigned long flags)
 {
-	if (!(flags & BIT(PG_referenced)))
-		return 0;
+	int refs;
+
 	/*
-	 * Return the total number of accesses including PG_referenced. Also see
-	 * the comment on LRU_REFS_FLAGS.
+	 * Return the total number of accesses. Also see the comment on
+	 * LRU_REFS_FLAGS.
 	 */
-	return ((flags & LRU_REFS_MASK) >> LRU_REFS_PGOFF) + 1;
+	refs = (flags & BIT(PG_referenced)) ? BIT(0) : 0;
+	refs += (flags & BIT(PG_workingset)) ? BIT(1) : 0;
+	refs += ((flags & LRU_REFS_MASK) >> LRU_REFS_PGOFF) << 2;
+	return refs;
 }
 
 /**
@@ -194,11 +197,13 @@ static inline int lru_refs_from_flags(unsigned long flags)
 static inline void lru_refs_set_flags(unsigned long *flags, unsigned int refs)
 {
 	VM_WARN_ON_ONCE(refs > LRU_REFS_MAX);
-
+	BUILD_BUG_ON((LRU_REFS_MAX >> 2) > (BIT(LRU_REFS_WIDTH) - 1));
 	*flags &= ~LRU_REFS_FLAGS;
-	if (!refs)
-		return;
-	*flags |= (BIT(PG_referenced) | ((refs - 1UL) << LRU_REFS_PGOFF));
+	if (refs & BIT(0))
+		*flags |= BIT(PG_referenced);
+	if (refs & BIT(1))
+		*flags |= BIT(PG_workingset);
+	*flags |= (((unsigned long)refs) >> 2) << LRU_REFS_PGOFF;
 }
 
 static inline int folio_lru_refs(const struct folio *folio)
@@ -216,6 +221,8 @@ static inline void folio_set_lru_refs(struct folio *folio, unsigned int refs)
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 }
 
+int folio_inc_lru_refs(struct folio *folio, bool is_fault, bool is_exec);
+
 static inline int folio_lru_gen(const struct folio *folio)
 {
 	return lru_gen_from_flags(READ_ONCE(*const_folio_flags(folio, 0)));
@@ -223,7 +230,7 @@ static inline int folio_lru_gen(const struct folio *folio)
 
 static inline bool lru_gen_is_active(const struct lruvec *lruvec, int gen)
 {
-	unsigned long max_seq = lruvec->lrugen.max_seq;
+	unsigned long max_seq = READ_ONCE(lruvec->lrugen.max_seq);
 
 	VM_WARN_ON_ONCE(gen > LRU_GEN_MAX);
 
@@ -280,23 +287,24 @@ static inline unsigned long lru_gen_folio_seq(const struct lruvec *lruvec,
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
@@ -304,7 +312,7 @@ static inline unsigned long lru_gen_folio_seq(const struct lruvec *lruvec,
 		  (folio_test_dirty(folio) || folio_test_writeback(folio))))
 		gen = MIN_NR_GENS;
 	else
-		gen = MAX_NR_GENS - (folio_test_workingset(folio) || folio_test_referenced(folio));
+		gen = MAX_NR_GENS - (refs >= LRU_REFS_WORKINGSET);
 
 	return max(READ_ONCE(lrugen->max_seq) - gen + 1, READ_ONCE(lrugen->min_seq[type]));
 }
@@ -365,6 +373,7 @@ static inline void folio_migrate_refs(struct folio *new, const struct folio *old
 {
 	folio_set_lru_refs(new, folio_lru_refs(old));
 }
+
 #else /* !CONFIG_LRU_GEN */
 
 static inline bool lru_gen_enabled(void)
@@ -392,10 +401,26 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 	return false;
 }
 
+static inline int folio_lru_refs(const struct folio *folio)
+{
+	return 0;
+}
+
+static inline void folio_set_lru_refs(struct folio *folio, unsigned int refs)
+{
+}
+
+static inline int folio_inc_lru_refs(struct folio *folio, bool promote, bool is_exec)
+{
+	return 0;
+}
+
 static inline void folio_migrate_refs(struct folio *new, const struct folio *old)
 {
 	if (folio_test_referenced(old))
 		folio_set_referenced(new);
+	if (folio_test_workingset(old))
+		folio_set_workingset(new);
 }
 #endif /* CONFIG_LRU_GEN */
 
diff --git a/include/linux/mmzone.h b/include/linux/mmzone.h
index 4225dab760ba..e4f7efc02e50 100644
--- a/include/linux/mmzone.h
+++ b/include/linux/mmzone.h
@@ -472,56 +472,111 @@ enum lruvec_flags {
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
+ *   4*     2   |
+ *   5*     3   |- The tier here is MAX_NR_TIERS - 1
+ *   6*     3   |
+ *   7*     3   |= LRU_REFS_MAX: Promotion candidate. [6]
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
+ * and the bits masked by LRU_REFS_MASK as the higher bits.
+ *
+ * A folio's referenced count never goes backwards except upon gen
+ * increase as described above.  Refault of a reclaimed folio restores
+ * its referenced count, capped at LRU_REFS_PROTECTED, which aligns with
+ * promotion.  Page table refaults of previous workingset folios send
+ * them to the latest gen, driving aging faster.
+ *
+ * MAX_NR_TIERS is set to 4 so that the multi-gen LRU can support twice
+ * the number of categories of the active/inactive LRU.
  */
 #define MAX_NR_TIERS		4U
+#define LRU_REFS_REFERENCED	0x1
+#define LRU_REFS_WORKINGSET	0x2
+#define LRU_REFS_PROTECTED	0x3
 
 #ifndef __GENERATING_BOUNDS_H
 
 #define LRU_GEN_MASK		((BIT(LRU_GEN_WIDTH) - 1) << LRU_GEN_PGOFF)
 #define LRU_GEN_MAX		(BIT(LRU_GEN_WIDTH - 1) - 1)
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
index fab00cb02970..a326602a59fe 100644
--- a/mm/folio.c
+++ b/mm/folio.c
@@ -272,7 +272,6 @@ static void lru_activate(struct lruvec *lruvec, struct folio *folio)
 	if (folio_test_active(folio) || folio_test_unevictable(folio))
 		return;
 
-
 	lruvec_del_folio(lruvec, folio);
 	folio_set_active(folio);
 	lruvec_add_folio(lruvec, folio);
@@ -351,32 +350,6 @@ static void __lru_cache_activate_folio(struct folio *folio)
 
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
-		refs = lru_refs_from_flags(old_flags);
-		if (refs == LRU_REFS_MAX) {
-			if (!folio_test_workingset(folio))
-				folio_set_workingset(folio);
-			return;
-		}
-		lru_refs_set_flags(&new_flags, refs + 1);
-	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
-}
-
 static bool lru_gen_clear_refs(struct folio *folio)
 {
 	int gen = folio_lru_gen(folio);
@@ -387,7 +360,6 @@ static bool lru_gen_clear_refs(struct folio *folio)
 		return true;
 
 	folio_set_lru_refs(folio, 0);
-	folio_clear_workingset(folio);
 
 	rcu_read_lock();
 	seq = READ_ONCE(folio_lruvec(folio)->lrugen.min_seq[type]);
@@ -398,10 +370,6 @@ static bool lru_gen_clear_refs(struct folio *folio)
 
 #else /* !CONFIG_LRU_GEN */
 
-static void lru_gen_inc_refs(struct folio *folio)
-{
-}
-
 static bool lru_gen_clear_refs(struct folio *folio)
 {
 	return false;
@@ -427,7 +395,8 @@ void folio_mark_accessed(struct folio *folio)
 	if (folio_test_dropbehind(folio))
 		return;
 	if (lru_gen_enabled()) {
-		lru_gen_inc_refs(folio);
+		if (!folio_test_unevictable(folio))
+			folio_inc_lru_refs(folio, false, false);
 		return;
 	}
 
@@ -473,17 +442,6 @@ void folio_add_lru(struct folio *folio)
 			folio_test_unevictable(folio), folio);
 	VM_BUG_ON_FOLIO(folio_test_lru(folio), folio);
 
-	/*
-	 * For prefaulted file folios, folio_mark_accessed() sets
-	 * PG_referenced so lru_gen_folio_seq() places them into
-	 * the second oldest generation.
-	 */
-	if (lru_gen_enabled() && !folio_test_unevictable(folio) &&
-	    lru_gen_in_fault() && !(current->flags & PF_MEMALLOC)) {
-		if (!folio_test_referenced(folio) && !folio_test_workingset(folio))
-			folio_mark_accessed(folio);
-	}
-
 	folio_batch_add_and_move(folio, lru_add);
 }
 EXPORT_SYMBOL(folio_add_lru);
diff --git a/mm/vmscan.c b/mm/vmscan.c
index a359d5a1ff41..9c8d9e3af375 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -830,38 +830,177 @@ enum folio_references {
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
-			folio_set_lru_refs(folio, 0);
-			folio_set_workingset(folio);
-			return true;
+
+/*
+ * Update the folio's lru refs indicator without taking the folio lock,
+ * isolation, or lruvec lock. Used by both page table access (@is_fault=true)
+ * and by file access (@is_fault=false).
+ */
+int folio_inc_lru_refs(struct folio *folio, bool is_fault, bool is_exec)
+{
+	int max_gen, min_gen;
+	int type, refs, gen, new_gen;
+	unsigned long new_flags, old_flags, max_seq;
+	struct lru_gen_folio *lrugen;
+	struct lruvec *lruvec;
+
+	type = folio_is_file_lru(folio);
+	lruvec = folio_lruvec_live_get(folio);
+	lrugen = &lruvec->lrugen;
+
+	old_flags = READ_ONCE(*folio_flags(folio, 0));
+	do {
+		new_flags = old_flags;
+		gen = lru_gen_from_flags(old_flags);
+		refs = lru_refs_from_flags(old_flags) + 1;
+		new_gen = gen;
+		if (!(old_flags & BIT(PG_lru)) || gen < 0)
+			goto out;
+
+		max_seq = READ_ONCE(lrugen->max_seq);
+		max_gen = lru_gen_from_seq(max_seq);
+		min_gen = lru_gen_from_seq(READ_ONCE(lrugen->min_seq[type]));
+		if (gen == max_gen)
+			goto out;
+
+		if (is_fault || is_exec) {
+			/* Promote second page table access or executable */
+			if (refs > LRU_REFS_REFERENCED || is_exec)
+				new_gen = max_gen;
+			else
+				new_gen = (gen + 1UL) % MAX_NR_GENS;
+			refs = min(refs, LRU_REFS_PROTECTED);
+		} else if (refs > LRU_REFS_MAX) {
+			/* LRU refs counting overflow, bump the gen */
+			new_gen = (gen + 1UL) % MAX_NR_GENS;
+			refs = LRU_REFS_PROTECTED;
+		} else if (gen == min_gen && refs >= LRU_REFS_WORKINGSET) {
+			/* Defer eviction of just accessed workingset */
+			new_gen = (gen + 1UL) % MAX_NR_GENS;
+			refs = min(refs, LRU_REFS_PROTECTED);
 		}
+out:
+		refs = min(refs, LRU_REFS_MAX);
+		lru_refs_set_flags(&new_flags, refs);
+		if (new_gen >= 0)
+			lru_gen_set_flags(&new_flags, new_gen);
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
-		folio_set_lru_refs(folio, 1);
-		return false;
+	if (new_gen != gen) {
+		/*
+		 * Gen can only go forward, so concurrent aging is
+		 * usually fine, except when multiple aging increase
+		 * max_seq multiple times, new_gen may have go beyond
+		 * the new max_seq's current gen border and causes
+		 * hotness inversion. In that very unlikely case,
+		 * just activate the folio.
+		 */
+		lru_gen_update_size(lruvec, folio, gen, new_gen);
+		if (unlikely(READ_ONCE(lrugen->max_seq) - max_seq > MIN_NR_GENS))
+			folio_activate(folio);
 	}
 
-	/* Promote on second access */
-	if (folio_lru_refs(folio) > 1) {
-		folio_set_lru_refs(folio, 0);
-		folio_set_workingset(folio);
-	} else {
-		folio_mark_accessed(folio);
-	}
-	return true;
+	folio_lruvec_live_put(lruvec);
+	return refs;
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
+				   const vma_flags_t *vma_flags, int *new_gen)
+{
+	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
+	unsigned long max_seq = READ_ONCE(lruvec->lrugen.max_seq);
+	int refs, gen, max_gen, ret;
+
+	max_gen = lru_gen_from_seq(max_seq);
+
+	do {
+		gen = lru_gen_from_flags(old_flags);
+		refs = lru_refs_from_flags(old_flags) + 1;
+		new_flags = old_flags;
+
+		if (gen >= 0 && gen != max_gen) {
+			ret = gen;
+			/* Promote second page table access or executable */
+			if (refs > LRU_REFS_REFERENCED || is_exec_file_folio(folio, vma_flags))
+				*new_gen = max_gen;
+			else
+				*new_gen = (gen + 1) % MAX_NR_GENS;
+			lru_gen_set_flags(&new_flags, *new_gen);
+			lru_refs_set_flags(&new_flags, min(refs, LRU_REFS_PROTECTED));
+		} else {
+			ret = -1;
+			lru_refs_set_flags(&new_flags, min(refs, LRU_REFS_MAX));
+		}
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
+
+	return ret;
+}
+
+/*
+ * Update the folio's lru refs indicator while the folio is isolated.
+ * Only used on mapped folios upon the final eviction, when the folio is
+ * off the LRU list (isolated).
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
+		refs = lru_refs_from_flags(old_flags) + 1;
+		lru_refs_set_flags(&new_flags, min(refs, LRU_REFS_PROTECTED));
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
@@ -896,7 +1035,8 @@ static enum folio_references folio_check_references(struct folio *folio,
 		if (!referenced_ptes)
 			return FOLIOREF_RECLAIM;
 
-		return lru_gen_set_refs(folio, &vma_flags) ? FOLIOREF_ACTIVATE : FOLIOREF_KEEP;
+		return folio_inc_lru_refs_isolated(folio, &vma_flags) ?
+		       FOLIOREF_ACTIVATE : FOLIOREF_KEEP;
 	}
 
 	referenced_folio = folio_test_clear_referenced(folio);
@@ -3262,59 +3402,31 @@ static bool positive_ctrl_err(struct ctrl_pos *sp, struct ctrl_pos *pv)
  *                          the aging
  ******************************************************************************/
 
-/* promote pages accessed through page tables */
-static int folio_update_gen(struct folio *folio, int new_gen, const vma_flags_t *vma_flags)
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
-		old_gen = lru_gen_from_flags(old_flags);
-		new_flags = old_flags;
-
-		/* lru_gen_del_folio() has isolated this page? */
-		if (old_gen < 0)
-			break;
-
-		lru_gen_set_flags(&new_flags, new_gen);
-		lru_refs_set_flags(&new_flags, 0);
-		new_flags |= BIT(PG_workingset);
-	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
-
-	return old_gen;
-}
-
-/* protect pages accessed multiple times through file descriptors */
+/*
+ * Force bump a folio's generation. Used for PID protection or defer the
+ * eviction of temporarily unevictable folio.
+ */
 static int folio_inc_gen(struct lruvec *lruvec, struct folio *folio)
 {
+	int refs;
 	int type = folio_is_file_lru(folio);
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 	int old_gen, new_gen, min_gen = lru_gen_from_seq(lrugen->min_seq[type]);
 	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
 
 	do {
+		new_flags = old_flags;
+		refs = lru_refs_from_flags(old_flags);
 		old_gen = lru_gen_from_flags(old_flags);
 		VM_WARN_ON_ONCE_FOLIO(old_gen < 0, folio);
 
-		/* folio_update_gen() has promoted this page? */
+		/* folio has been promoted? */
 		if (old_gen >= 0 && old_gen != min_gen)
 			return old_gen;
 
-		new_flags = old_flags;
 		new_gen = (old_gen + 1) % MAX_NR_GENS;
 		lru_gen_set_flags(&new_flags, new_gen);
-		lru_refs_set_flags(&new_flags, 0);
+		lru_refs_set_flags(&new_flags, min(refs, LRU_REFS_WORKINGSET));
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
 	lru_gen_update_size(lruvec, folio, old_gen, new_gen);
@@ -3518,21 +3630,17 @@ static void walk_update_folio(struct lru_gen_mm_walk *walk, struct vm_area_struc
 	if (!folio)
 		return;
 
-	new_gen = lru_gen_from_seq(READ_ONCE(lruvec->lrugen.max_seq));
-
 	if (dirty && !folio_test_dirty(folio) &&
 	    !(folio_test_anon(folio) && folio_test_swapbacked(folio) &&
 	      !folio_test_swapcache(folio)))
 		folio_mark_dirty(folio);
 
 	if (walk) {
-		old_gen = folio_update_gen(folio, new_gen, &vma->flags);
-		if (old_gen >= 0 && old_gen != new_gen)
+		old_gen = folio_inc_lru_refs_walk(folio, lruvec, &vma->flags, &new_gen);
+		if (old_gen >= 0)
 			update_batch_size(walk, folio, old_gen, new_gen);
-	} else if (lru_gen_set_refs(folio, &vma->flags)) {
-		old_gen = folio_lru_gen(folio);
-		if (old_gen >= 0 && old_gen != new_gen)
-			folio_activate(folio);
+	} else {
+		folio_inc_lru_refs(folio, true, is_exec_file_folio(folio, &vma->flags));
 	}
 }
 
@@ -3917,7 +4025,8 @@ static bool inc_min_seq(struct lruvec *lruvec, int type, int swappiness)
 		while (!list_empty(head)) {
 			struct folio *folio = lru_to_folio(head);
 			int refs = folio_lru_refs(folio);
-			bool workingset = folio_test_workingset(folio);
+			int delta = folio_nr_pages(folio);
+			int tier = lru_tier_from_refs(refs);
 
 			VM_WARN_ON_ONCE_FOLIO(folio_test_unevictable(folio), folio);
 			VM_WARN_ON_ONCE_FOLIO(folio_test_active(folio), folio);
@@ -3927,14 +4036,8 @@ static bool inc_min_seq(struct lruvec *lruvec, int type, int swappiness)
 			new_gen = folio_inc_gen(lruvec, folio);
 			list_move_tail(&folio->lru, &lrugen->folios[new_gen][type][zone]);
 
-			/* don't count the workingset being lazily promoted */
-			if (refs + workingset != BIT(LRU_REFS_WIDTH) + 1) {
-				int tier = lru_tier_from_refs(refs, workingset);
-				int delta = folio_nr_pages(folio);
-
-				WRITE_ONCE(lrugen->protected[hist][type][tier],
-					   lrugen->protected[hist][type][tier] + delta);
-			}
+			WRITE_ONCE(lrugen->protected[hist][type][tier],
+				   lrugen->protected[hist][type][tier] + delta);
 
 			if (!--remaining)
 				return false;
@@ -4649,8 +4752,7 @@ static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_c
 	int zone = folio_zonenum(folio);
 	int delta = folio_nr_pages(folio);
 	int refs = folio_lru_refs(folio);
-	bool workingset = folio_test_workingset(folio);
-	int tier = lru_tier_from_refs(refs, workingset);
+	int tier = lru_tier_from_refs(refs);
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 
 	VM_WARN_ON_ONCE_FOLIO(gen >= MAX_NR_GENS, folio);
@@ -4672,17 +4774,15 @@ static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_c
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
 
@@ -4710,10 +4810,6 @@ static bool isolate_folio(struct lruvec *lruvec, struct folio *folio, struct sca
 		return false;
 	}
 
-	/* see the comment on LRU_REFS_FLAGS */
-	if (!folio_test_referenced(folio))
-		folio_set_lru_refs(folio, 0);
-
 	success = lru_gen_del_folio(lruvec, folio, true);
 	VM_WARN_ON_ONCE_FOLIO(!success, folio);
 
@@ -4801,13 +4897,13 @@ static int get_tier_idx(struct lruvec *lruvec, int type)
 	struct ctrl_pos sp, pv = {};
 
 	/*
-	 * To leave a margin for fluctuations, use a larger gain factor (2:3).
+	 * To leave a margin for fluctuations, use a larger gain factor (1:2).
 	 * This value is chosen because any other tier would have at least twice
 	 * as many refaults as the first tier.
 	 */
-	read_ctrl_pos(lruvec, type, 0, 1, 2, &sp);
 	for (tier = 1; tier < MAX_NR_TIERS; tier++) {
-		read_ctrl_pos(lruvec, type, tier, tier + 1, 3, &pv);
+		read_ctrl_pos(lruvec, type, 0, tier, 1, &sp);
+		read_ctrl_pos(lruvec, type, tier, tier + 1, 2, &pv);
 		if (!positive_ctrl_err(&sp, &pv))
 			break;
 	}
@@ -4930,10 +5026,8 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 		}
 
 		/* don't add rejected folios to the oldest generation */
-		if (lru_gen_folio_seq(lruvec, folio, false) == min_seq[type]) {
-			folio_set_lru_refs(folio, 0);
+		if (lru_gen_folio_seq(lruvec, folio, false) == min_seq[type])
 			folio_set_active(folio);
-		}
 	}
 
 	move_folios_to_lru(&list);
diff --git a/mm/workingset.c b/mm/workingset.c
index 5438e9390011..452fe8554990 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -189,6 +189,13 @@
 #define EVICTION_MASK	(~0UL >> EVICTION_SHIFT)
 #define EVICTION_MASK_ANON	(~0UL >> EVICTION_SHIFT_ANON)
 
+/*
+ * LRU refs uses LRU_REFS_WIDTH + 2 bits, the 2 bits are PG_workingset and
+ * PG_referenced. But here we record PG_workingset separately (to reuse
+ * pack_shadow).
+ */
+#define LRU_REFS_BITS ((LRU_REFS_WIDTH + 2) - 1)
+
 /*
  * Eviction timestamps need to be able to cover the full range of
  * actionable refaults. However, bits are tight in the xarray
@@ -242,13 +249,12 @@ static void *lru_gen_eviction(struct folio *folio)
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
@@ -256,14 +262,14 @@ static void *lru_gen_eviction(struct folio *folio)
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
@@ -284,11 +290,24 @@ static bool lru_gen_test_recent(void *shadow, struct lruvec **lruvec,
 	*lruvec = mem_cgroup_lruvec(memcg, pgdat);
 
 	max_seq = READ_ONCE((*lruvec)->lrugen.max_seq);
-	max_seq &= (file ? EVICTION_MASK : EVICTION_MASK_ANON) >> LRU_REFS_WIDTH;
+	max_seq &= (file ? EVICTION_MASK : EVICTION_MASK_ANON) >> LRU_REFS_BITS;
 
-	return abs_diff(max_seq, *token >> LRU_REFS_WIDTH) < MAX_NR_GENS;
+	return abs_diff(max_seq, *token >> LRU_REFS_BITS) < MAX_NR_GENS;
 }
 
+/*
+ * Restore the refs of a refaulted folio from its shadow entry.
+ *
+ * Any folio that was accessed at least once before eviction (refs >=
+ * LRU_REFS_REFERENCED) is activated on a fault-driven refault, giving it a
+ * strong gen placement. Non-fault refaults (e.g. readahead) are not
+ * activated regardless of refs.
+ *
+ * The restored refs is capped at LRU_REFS_PROTECTED to prevent stale
+ * high-tier history from carrying over across eviction cycles. The
+ * WORKINGSET_RESTORE stat is bumped only for refs >= LRU_REFS_WORKINGSET
+ * to track genuine workingset restoration.
+ */
 static void lru_gen_refault(struct folio *folio, void *shadow)
 {
 	bool recent;
@@ -314,21 +333,29 @@ static void lru_gen_refault(struct folio *folio, void *shadow)
 	lrugen = &lruvec->lrugen;
 
 	hist = lru_hist_from_seq(READ_ONCE(lrugen->min_seq[type]));
-	refs = (token & (BIT(LRU_REFS_WIDTH) - 1)) + 1;
-	tier = lru_tier_from_refs(refs, workingset);
+	refs = ((token & (BIT(LRU_REFS_BITS) - 1)) << 1) + workingset;
+	tier = lru_tier_from_refs(refs);
 
 	atomic_long_add(delta, &lrugen->refaulted[hist][type][tier]);
 
-	if (workingset) {
-		/* Send refaulted workingset folios to active generations. */
+	/*
+	 * Activate a fault-driven refault: the folio was accessed at
+	 * least once before eviction and would have been promoted had
+	 * it stayed in memory.
+	 */
+	if (refs >= LRU_REFS_REFERENCED) {
 		if (lru_gen_in_fault()) {
 			folio_set_active(folio);
 			mod_lruvec_state(lruvec, WORKINGSET_ACTIVATE_BASE + type, delta);
 		}
-		folio_set_workingset(folio);
+		/* Cap restored refs to prevent stale high-tier carry-over */
+		folio_set_lru_refs(folio, min(refs, LRU_REFS_PROTECTED));
+	}
+
+	/* WORKINGSET_RESTORE tracks genuine workingset-level refaults */
+	if (refs >= LRU_REFS_WORKINGSET)
 		mod_lruvec_state(lruvec, WORKINGSET_RESTORE_BASE + type, delta);
-	} else
-		set_mask_bits(&folio->flags.f, LRU_REFS_MASK, (refs - 1UL) << LRU_REFS_PGOFF);
+
 unlock:
 	rcu_read_unlock();
 }

-- 
2.55.0

