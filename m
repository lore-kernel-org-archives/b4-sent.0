From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:03:52 +0800
Subject: [PATCH RFC 06/32] mm/mglru: frequency guided workingset promotion
 (MGLRU-FG)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-6-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=31159;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=nqgE3bRYpiEGBjHmyiK9hsIuBnvRLThtCXFVokE5+4U=;
 b=lgNk6FfuVePNIV8QzMKahhRT7F44WxnkFykS6orRUsI+oHbRHfv7ngt9czSFSGkHbKpPwVcQb
 271Dr919oI5DlImkyL5ftk5jqXHd7kS+M4R4aWDONQgTwKNxMffah1E
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For file folios, MGLRU mostly relies on tier protection to protect them
on eviction. This led to at least two problems:

- It has a long feedback loop: higher-tier folios won't be protected
  until enough re-faults have been triggered. And by the time protection
  happens, the folio is likely no longer a hot page.

- We have limited tiers, so if the access count of a set of folios goes
  beyond the tier limit, MGLRU is no longer able to tell which folio is
  hotter.

And tiering is not working efficiently for anon folios. Anon folios
rarely stay on any tiers except tier 0 and tier 3, the page access will
promote and change the folio tier aggressively for them.

So tweak the tiering mechanism a bit: for file folios, promote them more
adaptively. For folios that have an access count beyond the maximum
tiering count (LRU_REFS_MAX), reset its tier and promote it into the
next gen. This is just like protection, but happens at access time and
not eviction time. Compared to the previous protection mechanism, this
happens more proactively, and still won't over-protect file pages. The
promotion is very conservative, one gen at a time, and each promotion
resets the reference times count. Each promotion requires 8 accesses to
occur.

And now tiering is much more immune to the count overflow issue, as the
overflowed folio will be promoted and reset its count. And the lower
tier in newer gen have a higher protect priority (less likely to be
evicted) than the higher tier in lower gen, which seems reasonable as
always.

And for workingset tracking, we can simply consider all folios with a
referenced times count >= 2 (LRU_REFS_WORKINGSET) as a workingset. This
makes the workingset tracking similar to what active/inactive LRU had,
so in-kernel checks for workingset (e.g., PSI, readahead) will have a
more consistent behavior on MGLRU. Currently, MGLRU is causing a lower
PSI reading in some workloads.

Note that PG_workingset and PG_referenced are no longer used as
individual flags under MGLRU; they are now the low two bits of the LRU
reference count encoding. Adjusting the existing raw folio_test_*()
callers to the new semantics is left to a follow-up.

Behavior of active/inactive LRU is not changed.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm_inline.h |  58 +++++++++++++----------
 include/linux/mmzone.h    | 104 ++++++++++++++++++++++++++---------------
 kernel/bounds.c           |   2 +-
 mm/swap.c                 |  93 +++++++++++++++++++++++++++++--------
 mm/vmscan.c               | 115 ++++++++++++++++++++++------------------------
 mm/workingset.c           |  31 +++++++------
 6 files changed, 248 insertions(+), 155 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index 8a3fb357dc15..a9ed9a79364e 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -133,12 +133,12 @@ static inline int lru_hist_from_seq(unsigned long seq)
 	return seq % NR_HIST_GENS;
 }
 
-static inline int lru_tier_from_refs(int refs, bool workingset)
+static inline int lru_tier_from_refs(unsigned int refs)
 {
-	VM_WARN_ON_ONCE(refs > BIT(LRU_REFS_WIDTH));
-
-	/* see the comment on MAX_NR_TIERS */
-	return workingset ? MAX_NR_TIERS - 1 : order_base_2(refs);
+	VM_WARN_ON_ONCE(refs > LRU_REFS_MAX);
+	if (refs < LRU_REFS_WORKINGSET)
+		return 0;
+	return fls(refs - 1);
 }
 
 /**
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
@@ -196,9 +199,11 @@ static inline void lru_refs_set_flags(unsigned long *flags, unsigned int refs)
 	VM_WARN_ON_ONCE(refs > LRU_REFS_MAX);
 
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
@@ -280,23 +285,24 @@ static inline unsigned long lru_gen_folio_seq(const struct lruvec *lruvec,
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
+	 * +-------------------------------------------+------------------------------------------+
+	 * |     Accessed through page tables and      |     Accessed through file descriptors    |
+	 * |     promoted by folio_update_gen()        |     and protected by folio_inc_gen()     |
+	 * +------0------------------------------------+------------------------------------------+
+	 * |      PG_active (set while isolated)       |                                          |
+	 * +---------------------+---------------------+--------------------+---------------------+
+	 * |     LRU_REFS_MAX    | LRU_REFS_REFERENCED |    LRU_REFS_MAX    | LRU_REFS_REFERENCED |
+	 * +-------------------------------------------+------------------------------------------+
+	 * |<-------------- MIN_NR_GENS -------------->|                                          |
+	 * |<------------------------------------ MAX_NR_GENS ----------------------------------->|
 	 */
 	if (folio_test_active(folio))
-		gen = MIN_NR_GENS - folio_test_workingset(folio);
+		gen = MIN_NR_GENS - (refs >= LRU_REFS_WORKINGSET);
 	else if (reclaiming)
 		gen = MAX_NR_GENS;
 	else if ((!folio_is_file_lru(folio) && !folio_test_swapcache(folio)) ||
@@ -304,7 +310,7 @@ static inline unsigned long lru_gen_folio_seq(const struct lruvec *lruvec,
 		  (folio_test_dirty(folio) || folio_test_writeback(folio))))
 		gen = MIN_NR_GENS;
 	else
-		gen = MAX_NR_GENS - folio_test_workingset(folio);
+		gen = MAX_NR_GENS - (refs >= LRU_REFS_REFERENCED);
 
 	return max(READ_ONCE(lrugen->max_seq) - gen + 1, READ_ONCE(lrugen->min_seq[type]));
 }
@@ -396,6 +402,8 @@ static inline void folio_migrate_refs(struct folio *new, const struct folio *old
 {
 	if (folio_test_referenced(old))
 		folio_set_referenced(new);
+	if (folio_test_workingset(old))
+		folio_set_workingset(new);
 }
 #endif /* CONFIG_LRU_GEN */
 
diff --git a/include/linux/mmzone.h b/include/linux/mmzone.h
index 721d0db8b0f9..393bbea75838 100644
--- a/include/linux/mmzone.h
+++ b/include/linux/mmzone.h
@@ -470,55 +470,87 @@ enum lruvec_flags {
 
 /*
  * Each generation is divided into multiple tiers. A folio accessed N times
- * through file descriptors is in tier order_base_2(N). A folio in the first
- * tier (N=0,1) is marked by PG_referenced unless it was faulted in through page
- * tables or read ahead. A folio in the last tier (MAX_NR_TIERS-1) is marked by
- * PG_workingset. A folio in any other tier (1<N<5) between the first and last
- * is marked by additional bits of LRU_REFS_WIDTH in folio->flags.
+ * through file descriptors will be categorized as higher tier as shown below:
  *
- * In contrast to moving across generations which requires the LRU lock, moving
- * across tiers only involves atomic operations on folio->flags and therefore
- * has a negligible cost in the buffered access path. In the eviction path,
- * comparisons of refaulted/(evicted+protected) from the first tier and the rest
- * infer whether folios accessed multiple times through file descriptors are
- * statistically hot and thus worth protecting.
+ * MGLRU (Workingset Protection)
+ * Access   Tier   |
+ *    0      0     | - Should be mostly cold folio, or readahead & reclaiming. [1]
+ *    1      0     | - Folios that are used for at least once. [2]
+ * --WORKINGSET--<-\ - Considered workingset and future access may increase its gen. [3]
+ *    2      1     | - Reclaimable workingset. [4]
+ *    3      2     | - PID protected workingset. [5]
+ *    4*     2     | - Extended tiers [6]
+ *    5*     3     |
+ *    6*     3     |
+ *    7*     3     | - Promotion candidate workingset. [7]
+ * --PROMOTION--->-/
+ *
+ * 1. The tier is fls(N-1) for N > 1, 0 otherwise. Ideally each tier
+ * represents folios of similar access patterns, lower tiers are folios that
+ * are less important and should be evicted faster. Readahead (PG_readahead)
+ * or reclaiming (PG_reclaim) folios are force put in tier 0.
+ *
+ * 2. Folios accessed at least once are still on tier 0:
+ * (folio_lru_refs(folio) == LRU_REFS_REFERENCED == 1).
+ * One time usage doesn't make the folio qualified to be protected in anyway.
+ * If a workingset folio is accessed and in the oldest gen, it will be moved
+ * to second oldest gen. Gen moving is lazily done without involving
+ * LRU lock so it's cheap. It won't be promoted further if it's not on
+ * oldest gen to avoid over-promoting of caches.
+ *
+ * 3. Folios that are accessed more than once are considered workingset:
+ * (folio_lru_refs(folio) == LRU_REFS_WORKINGSET == 2).
+ *
+ * 4. A folio qualified as workingset is still on tier 1 unless it
+ * is accessed again. That makes the workingset still easily reclaimable, since
+ * the initial move in (1) and the promotion in (6) already protects recent
+ * workingset proactively, and we want to reclaim caches fast when under
+ * pressure: pinning a folio in high tier combined with the PID protect in
+ * (4) will cause the eviction of old caches delayed by a lot.
+ *
+ * 5. Starting from tier 1, PID protection will take effect. Lower tier
+ * will be sacrificed to protect higher tier when the higher tier have a
+ * higher refault rate (see PID protection part on vmscan.c).
+ *
+ * 6. Tier > 2 is only available when LRU_REFS_WIDTH >= 1. Ideally we will
+ * always have it but in some extreme configs, page flags is just not enough.
+ * This will be improved in the future. Without Tiers > 2, things still work,
+ * but we will promote file caches more aggressively, and maybe unexpectedly.
+ *
+ * 7. If the referenced count == LRU_REFS_MAX, a future access will increase
+ * the gen of the folio by one and reset its referenced count to
+ * LRU_REFS_PROTECTED. It still considered workingset but moved to a higher
+ * gen representing a higher hotness and reclaim bias.
+ *
+ * Tiering uses PG_workingset and PG_referenced and the lower two bits,
+ * LRU_REFS_MASK as the higher bits.
+ *
+ * A folio's referenced count never goes backwards except upon gen increase
+ * in (7) or a promotion. Passive protect by PID will reset a folio with higher
+ * referenced count to LRU_REFS_WORKINGSET. Refault of a reclaimed folio may
+ * restore its referenced count by lru_gen_refault.
+ *
+ * In the eviction path, comparisons of refaulted/(evicted+protected) from
+ * the first tier and the rest infer whether folios accessed multiple times
+ * through file descriptors are statistically hot and thus worth protecting.
  *
  * MAX_NR_TIERS is set to 4 so that the multi-gen LRU can support twice the
  * number of categories of the active/inactive LRU when keeping track of
- * accesses through file descriptors. This uses MAX_NR_TIERS-2 spare bits in
+ * accesses through file descriptors. This uses MAX_NR_TIERS-3 spare bits in
  * folio->flags, masked by LRU_REFS_MASK.
  */
 #define MAX_NR_TIERS		4U
+#define LRU_REFS_REFERENCED	0x1
+#define LRU_REFS_WORKINGSET	0x2
+#define LRU_REFS_PROTECTED	0x3
 
 #ifndef __GENERATING_BOUNDS_H
 
 #define LRU_GEN_MASK		((BIT(LRU_GEN_WIDTH) - 1) << LRU_GEN_PGOFF)
 #define LRU_GEN_MAX		(BIT(LRU_GEN_WIDTH - 1) - 1)
 #define LRU_REFS_MASK		((BIT(LRU_REFS_WIDTH) - 1) << LRU_REFS_PGOFF)
-#define LRU_REFS_MAX		(BIT(LRU_REFS_WIDTH) - 1)
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
diff --git a/mm/swap.c b/mm/swap.c
index 6204496d48f5..5fc8a9ffbedb 100644
--- a/mm/swap.c
+++ b/mm/swap.c
@@ -311,9 +311,9 @@ static void lru_activate(struct lruvec *lruvec, struct folio *folio)
 	if (folio_test_active(folio) || folio_test_unevictable(folio))
 		return;
 
-
 	lruvec_del_folio(lruvec, folio);
 	folio_set_active(folio);
+	folio_set_lru_refs(folio, LRU_REFS_WORKINGSET);
 	lruvec_add_folio(lruvec, folio);
 	trace_mm_lru_activate(folio);
 
@@ -390,30 +390,86 @@ static void __lru_cache_activate_folio(struct folio *folio)
 
 #ifdef CONFIG_LRU_GEN
 
-static void lru_gen_inc_refs(struct folio *folio)
+static void folio_inc_lru_refs(struct folio *folio)
 {
-	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
-	int refs;
+	int type, refs, gen, new_gen, max_gen, min_gen;
+	unsigned long new_flags, old_flags, max_seq;
+	struct lru_gen_folio *lrugen = NULL;
+	struct lruvec *lruvec = NULL;
+	bool isolated = false;
 
 	if (folio_test_unevictable(folio))
 		return;
 
-	if (!folio_lru_refs(folio)) {
-		folio_set_lru_refs(folio, 1);
-		return;
-	}
-
-	/* see the comment on LRU_REFS_FLAGS */
+	old_flags = READ_ONCE(*folio_flags(folio, 0));
 	do {
 		new_flags = old_flags;
-		refs = lru_refs_from_flags(old_flags);
-		if (refs == LRU_REFS_MAX) {
-			if (!folio_test_workingset(folio))
-				folio_set_workingset(folio);
-			return;
+		gen = lru_gen_from_flags(old_flags);
+		refs = lru_refs_from_flags(old_flags) + 1;
+		new_gen = gen;
+		if (gen < 0)
+			goto out;
+
+		/*
+		 * To promote frequently used folios, prevent isolation
+		 * first, it's a lazy promotion so no LRU lock needed.
+		 */
+		if (!isolated) {
+			if (!folio_test_clear_lru(folio))
+				goto out;
+			isolated = true;
+			old_flags &= ~BIT(PG_lru);
+			new_flags = old_flags;
+			rcu_read_lock();
+			lruvec = folio_lruvec(folio);
+			lrugen = &lruvec->lrugen;
 		}
-		lru_refs_set_flags(&new_flags, refs + 1);
+
+		max_seq = READ_ONCE(lrugen->max_seq);
+		max_gen = lru_gen_from_seq(max_seq);
+		if (gen == max_gen)
+			goto out;
+
+		/*
+		 * Always promote if we hit LRU_REFS_MAX, else, only promote
+		 * from oldest gen.
+		 */
+		if (refs <= LRU_REFS_MAX) {
+			type = folio_is_file_lru(folio);
+			min_gen = lru_gen_from_seq(READ_ONCE(lrugen->min_seq[type]));
+			if (gen != min_gen)
+				goto out;
+		} else {
+			refs = LRU_REFS_PROTECTED;
+		}
+
+		new_gen = (gen + 1UL) % MAX_NR_GENS;
+		lru_gen_set_flags(&new_flags, new_gen);
+out:
+		lru_refs_set_flags(&new_flags, min(refs, LRU_REFS_MAX));
+		if (isolated)
+			new_flags |= BIT(PG_lru);
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
+
+	if (isolated) {
+		bool reactive = false;
+
+		if (new_gen != gen) {
+			/*
+			 * It's possible that the folio is concurrently promoted to
+			 * latest gen, so the promotion above causes gen inversion.
+			 * The window is tiny but in such case, just activate the folio.
+			 */
+			if (max_seq != READ_ONCE(lrugen->max_seq))
+				reactive = true;
+			lru_gen_update_size(lruvec, folio, gen, new_gen);
+		}
+
+		rcu_read_unlock();
+
+		if (reactive)
+			folio_activate(folio);
+	}
 }
 
 static bool lru_gen_clear_refs(struct folio *folio)
@@ -426,7 +482,6 @@ static bool lru_gen_clear_refs(struct folio *folio)
 		return true;
 
 	folio_set_lru_refs(folio, 0);
-	folio_clear_workingset(folio);
 
 	rcu_read_lock();
 	seq = READ_ONCE(folio_lruvec(folio)->lrugen.min_seq[type]);
@@ -437,7 +492,7 @@ static bool lru_gen_clear_refs(struct folio *folio)
 
 #else /* !CONFIG_LRU_GEN */
 
-static void lru_gen_inc_refs(struct folio *folio)
+static void folio_inc_lru_refs(struct folio *folio)
 {
 }
 
@@ -466,7 +521,7 @@ void folio_mark_accessed(struct folio *folio)
 	if (folio_test_dropbehind(folio))
 		return;
 	if (lru_gen_enabled()) {
-		lru_gen_inc_refs(folio);
+		folio_inc_lru_refs(folio);
 		return;
 	}
 
diff --git a/mm/vmscan.c b/mm/vmscan.c
index a5b4750a5028..026b56828fdb 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -840,21 +840,30 @@ enum folio_references {
  * with PG_active set. In contrast, the aging (page table walk) path uses
  * folio_update_gen().
  */
-static bool lru_gen_set_refs(struct folio *folio)
+static bool folio_promote_lru_refs(struct folio *folio)
 {
-	/* see the comment on LRU_REFS_FLAGS */
-	if (!folio_lru_refs(folio) && !folio_test_workingset(folio)) {
-		folio_set_lru_refs(folio, 1);
-		return false;
-	}
+	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
+	int refs;
 
-	folio_set_lru_refs(folio, 0);
-	folio_set_workingset(folio);
+	do {
+		new_flags = old_flags;
+		refs = lru_refs_from_flags(old_flags);
+		/*
+		 * Bump refs by one up to LRU_REFS_MAX.  Once we are at
+		 * LRU_REFS_MAX, leave the flags alone: the caller treats a
+		 * return of true (refs >= LRU_REFS_WORKINGSET) as a cue to
+		 * activate the folio, which resets refs to
+		 * LRU_REFS_WORKINGSET in lru_activate().
+		 */
+		if (refs == LRU_REFS_MAX)
+			break;
+		lru_refs_set_flags(&new_flags, ++refs);
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
-	return true;
+	return refs >= LRU_REFS_WORKINGSET;
 }
 #else
-static bool lru_gen_set_refs(struct folio *folio)
+static bool folio_promote_lru_refs(struct folio *folio)
 {
 	return false;
 }
@@ -889,7 +898,7 @@ static enum folio_references folio_check_references(struct folio *folio,
 		if (!referenced_ptes)
 			return FOLIOREF_RECLAIM;
 
-		return lru_gen_set_refs(folio) ? FOLIOREF_ACTIVATE : FOLIOREF_KEEP;
+		return folio_promote_lru_refs(folio) ? FOLIOREF_ACTIVATE : FOLIOREF_KEEP;
 	}
 
 	referenced_folio = folio_test_clear_referenced(folio);
@@ -3196,39 +3205,39 @@ static bool positive_ctrl_err(struct ctrl_pos *sp, struct ctrl_pos *pv)
 static int folio_update_gen(struct folio *folio, int new_gen)
 {
 	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
-	int old_gen;
+	int refs, gen, ret;
 
 	/* see the comment on LRU_REFS_FLAGS */
-	if (!lru_refs_from_flags(old_flags) && !folio_test_workingset(folio)) {
-		folio_set_lru_refs(folio, 1);
-		return -1;
-	}
-
 	do {
-		old_gen = lru_gen_from_flags(old_flags);
+		gen = lru_gen_from_flags(old_flags);
+		refs = lru_refs_from_flags(old_flags);
 		new_flags = old_flags;
 
-		/* lru_gen_del_folio() has isolated this page? */
-		if (old_gen < 0)
-			break;
-
-		lru_gen_set_flags(&new_flags, new_gen);
-		lru_refs_set_flags(&new_flags, 0);
-		new_flags |= BIT(PG_workingset);
+		if (gen >= 0 && gen != new_gen && refs) {
+			ret = gen;
+			lru_gen_set_flags(&new_flags, new_gen);
+			lru_refs_set_flags(&new_flags, LRU_REFS_WORKINGSET);
+		} else {
+			ret = -1;
+			lru_refs_set_flags(&new_flags, min(++refs, LRU_REFS_MAX));
+		}
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
-	return old_gen;
+	return ret;
 }
 
 /* protect pages accessed multiple times through file descriptors */
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
 
@@ -3236,12 +3245,10 @@ static int folio_inc_gen(struct lruvec *lruvec, struct folio *folio)
 		if (old_gen >= 0 && old_gen != min_gen)
 			return old_gen;
 
-		new_flags = old_flags;
 		new_gen = (old_gen + 1) % MAX_NR_GENS;
-
-		new_flags = old_flags & ~(LRU_GEN_MASK | LRU_REFS_FLAGS);
-		new_flags |= (new_gen + 1UL) << LRU_GEN_PGOFF;
-	} while (!try_cmpxchg(&folio->flags.f, &old_flags, new_flags));
+		lru_gen_set_flags(&new_flags, new_gen);
+		lru_refs_set_flags(&new_flags, min(refs, LRU_REFS_WORKINGSET));
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
 	lru_gen_update_size(lruvec, folio, old_gen, new_gen);
 
@@ -3451,7 +3458,7 @@ static void walk_update_folio(struct lru_gen_mm_walk *walk, struct folio *folio,
 		old_gen = folio_update_gen(folio, new_gen);
 		if (old_gen >= 0 && old_gen != new_gen)
 			update_batch_size(walk, folio, old_gen, new_gen);
-	} else if (lru_gen_set_refs(folio)) {
+	} else if (folio_promote_lru_refs(folio)) {
 		old_gen = folio_lru_gen(folio);
 		if (old_gen >= 0 && old_gen != new_gen)
 			folio_activate(folio);
@@ -3846,7 +3853,8 @@ static bool inc_min_seq(struct lruvec *lruvec, int type, int swappiness)
 		while (!list_empty(head)) {
 			struct folio *folio = lru_to_folio(head);
 			int refs = folio_lru_refs(folio);
-			bool workingset = folio_test_workingset(folio);
+			int delta = folio_nr_pages(folio);
+			int tier = lru_tier_from_refs(refs);
 
 			VM_WARN_ON_ONCE_FOLIO(folio_test_unevictable(folio), folio);
 			VM_WARN_ON_ONCE_FOLIO(folio_test_active(folio), folio);
@@ -3856,14 +3864,8 @@ static bool inc_min_seq(struct lruvec *lruvec, int type, int swappiness)
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
@@ -4580,8 +4582,7 @@ static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_c
 	int zone = folio_zonenum(folio);
 	int delta = folio_nr_pages(folio);
 	int refs = folio_lru_refs(folio);
-	bool workingset = folio_test_workingset(folio);
-	int tier = lru_tier_from_refs(refs, workingset);
+	int tier = lru_tier_from_refs(refs);
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
 
 	VM_WARN_ON_ONCE_FOLIO(gen >= MAX_NR_GENS, folio);
@@ -4603,17 +4604,15 @@ static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_c
 	}
 
 	/* protected */
-	if (tier > tier_idx || refs + workingset == BIT(LRU_REFS_WIDTH) + 1) {
+	if (tier > tier_idx) {
+		int hist = lru_hist_from_seq(lrugen->min_seq[type]);
+
 		gen = folio_inc_gen(lruvec, folio);
-		list_move(&folio->lru, &lrugen->folios[gen][type][zone]);
+		list_move_tail(&folio->lru, &lrugen->folios[gen][type][zone]);
 
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
 
@@ -4641,10 +4640,6 @@ static bool isolate_folio(struct lruvec *lruvec, struct folio *folio, struct sca
 		return false;
 	}
 
-	/* see the comment on LRU_REFS_FLAGS */
-	if (!folio_test_referenced(folio))
-		folio_set_lru_refs(folio, 0);
-
 	success = lru_gen_del_folio(lruvec, folio, true);
 	VM_WARN_ON_ONCE_FOLIO(!success, folio);
 
@@ -4732,13 +4727,13 @@ static int get_tier_idx(struct lruvec *lruvec, int type)
 	struct ctrl_pos sp, pv = {};
 
 	/*
-	 * To leave a margin for fluctuations, use a larger gain factor (2:3).
+	 * To leave a margin for fluctuations, use a larger gain factor (1:2).
 	 * This value is chosen because any other tier would have at least twice
 	 * as many refaults as the first tier.
 	 */
-	read_ctrl_pos(lruvec, type, 0, 2, &sp);
+	read_ctrl_pos(lruvec, type, 0, 1, &sp);
 	for (tier = 1; tier < MAX_NR_TIERS; tier++) {
-		read_ctrl_pos(lruvec, type, tier, 3, &pv);
+		read_ctrl_pos(lruvec, type, tier, 2, &pv);
 		if (!positive_ctrl_err(&sp, &pv))
 			break;
 	}
@@ -4858,10 +4853,8 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
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
index 07e6836d0502..bdb8df6009af 100644
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
@@ -284,9 +290,9 @@ static bool lru_gen_test_recent(void *shadow, struct lruvec **lruvec,
 	*lruvec = mem_cgroup_lruvec(memcg, pgdat);
 
 	max_seq = READ_ONCE((*lruvec)->lrugen.max_seq);
-	max_seq &= (file ? EVICTION_MASK : EVICTION_MASK_ANON) >> LRU_REFS_WIDTH;
+	max_seq &= (file ? EVICTION_MASK : EVICTION_MASK_ANON) >> LRU_REFS_BITS;
 
-	return abs_diff(max_seq, *token >> LRU_REFS_WIDTH) < MAX_NR_GENS;
+	return abs_diff(max_seq, *token >> LRU_REFS_BITS) < MAX_NR_GENS;
 }
 
 static void lru_gen_refault(struct folio *folio, void *shadow)
@@ -314,8 +320,8 @@ static void lru_gen_refault(struct folio *folio, void *shadow)
 	lrugen = &lruvec->lrugen;
 
 	hist = lru_hist_from_seq(READ_ONCE(lrugen->min_seq[type]));
-	refs = (token & (BIT(LRU_REFS_WIDTH) - 1)) + 1;
-	tier = lru_tier_from_refs(refs, workingset);
+	refs = ((token & (BIT(LRU_REFS_BITS) - 1)) << 1) + workingset;
+	tier = lru_tier_from_refs(refs);
 
 	atomic_long_add(delta, &lrugen->refaulted[hist][type][tier]);
 
@@ -323,11 +329,10 @@ static void lru_gen_refault(struct folio *folio, void *shadow)
 	if (lru_gen_in_fault())
 		mod_lruvec_state(lruvec, WORKINGSET_ACTIVATE_BASE + type, delta);
 
-	if (workingset) {
-		folio_set_workingset(folio);
+	if (refs) {
+		folio_set_lru_refs(folio, refs);
 		mod_lruvec_state(lruvec, WORKINGSET_RESTORE_BASE + type, delta);
-	} else
-		set_mask_bits(&folio->flags.f, LRU_REFS_MASK, (refs - 1UL) << LRU_REFS_PGOFF);
+	}
 unlock:
 	rcu_read_unlock();
 }

-- 
2.54.0

