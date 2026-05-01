From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:03:54 +0800
Subject: [PATCH RFC 08/32] mm: make folio lru referenced times count a
 generic API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-8-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=9380;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=kFsnhem71+vNlAD+uETGIDzz3S2DgnshxmHavEobZls=;
 b=ZcQPWJu7KfLDxZjQPqZ8h8aF5A2CQesX2x+TUpUsKZ3cYMSL9TEgR2qq0n4FukOnjz+ugfmQ+
 t8XROTxV3wDBrzDHokgy4gl5yiQOj36pBlwUNU8gEDp1DYXLPS6eEdb
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To prepare for unifying the API for checking folio referenced status,
expose the referenced times counting as a generic API. For MGLRU this
helps to adapt other subsystem based on the referenced times counting,
for non-MGLRU this is still bitwise compatible and there won't be
major behavior change.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm_inline.h | 229 +++++++++++++++++++++++++++++++++-------------
 mm/migrate.c              |   2 -
 2 files changed, 167 insertions(+), 64 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index a9ed9a79364e..a108695424fb 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -94,6 +94,173 @@ static __always_inline enum lru_list folio_lru_list(const struct folio *folio)
 	return lru;
 }
 
+/**
+ * lru_refs_from_flags - Return LRU referenced / access count from folio flags.
+ * @flags: folio flags
+ */
+static inline int lru_refs_from_flags(unsigned long flags)
+{
+	int refs;
+
+	/*
+	 * Return the total number of accesses. Also see the comment on
+	 * LRU_REFS_FLAGS.
+	 */
+	refs = (flags & BIT(PG_referenced)) ? BIT(0) : 0;
+	refs += (flags & BIT(PG_workingset)) ? BIT(1) : 0;
+	refs += ((flags & LRU_REFS_MASK) >> LRU_REFS_PGOFF) << 2;
+	return refs;
+}
+
+/**
+ * lru_refs_set_flags - Set the LRU referenced / access count to specified folio flags.
+ * @flags: pointer to the folio flags
+ * @refs: referenced / access count number, between 0 and LRU_REFS_MAX, inclusive.
+ */
+static inline void lru_refs_set_flags(unsigned long *flags, unsigned int refs)
+{
+	VM_WARN_ON_ONCE(refs > LRU_REFS_MAX);
+
+	*flags &= ~LRU_REFS_FLAGS;
+	if (refs & BIT(0))
+		*flags |= BIT(PG_referenced);
+	if (refs & BIT(1))
+		*flags |= BIT(PG_workingset);
+	*flags |= (((unsigned long)refs) >> 2) << LRU_REFS_PGOFF;
+}
+
+static inline int folio_lru_refs(const struct folio *folio)
+{
+	return lru_refs_from_flags(READ_ONCE(*const_folio_flags(folio, 0)));
+}
+
+static inline void folio_set_lru_refs(struct folio *folio, unsigned int refs)
+{
+	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
+
+	do {
+		new_flags = old_flags;
+		lru_refs_set_flags(&new_flags, refs);
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
+}
+
+/**
+ * folio_is_referenced - Tell if a folio was accessed before.
+ * @folio: the folio.
+ *
+ * This helper currently only works as intended for MGLRU, as it checks
+ * all LRU_REFS_FLAGS. It might be fine for non-MGLRU to replace
+ * folio_test_referenced in some cases but the user should be careful.
+ *
+ * Returns: true if the folio's LRU referenced / accessd count > 0.
+ */
+static inline bool folio_is_referenced(const struct folio *folio)
+{
+	return folio_lru_refs(folio) >= LRU_REFS_REFERENCED;
+}
+
+/**
+ * folio_mark_referenced - Mark a folio as referenced.
+ * @folio: the folio.
+ *
+ * Ensures the folio's LRU referenced count is at least
+ * LRU_REFS_REFERENCED. Won't do anything if the count is already larger
+ * than that. This helper currently only works as intended for MGLRU.
+ * Not a drop-in replacement, but should be fine for non-MGLRU to replace
+ * folio_set_referenced with this after audit.
+ */
+static inline void folio_mark_referenced(struct folio *folio)
+{
+	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
+
+	do {
+		new_flags = old_flags;
+		if (lru_refs_from_flags(new_flags) >= LRU_REFS_REFERENCED)
+			return;
+		lru_refs_set_flags(&new_flags, LRU_REFS_REFERENCED);
+	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
+}
+
+/**
+ * __folio_init_referenced - Force init a folio as referenced non-atomicly.
+ * @folio: the folio.
+ *
+ * Force set a folio's LRU referenced count to LRU_REFS_REFERENCED non-atomicly.
+ * Can be used to replace __folio_set_referenced safely.
+ */
+static inline void __folio_init_referenced(struct folio *folio)
+{
+	lru_refs_set_flags(folio_flags(folio, 0), LRU_REFS_REFERENCED);
+}
+
+/**
+ * folio_mark_referenced_by_bit - Mark a folio as referenced by bit.
+ * @folio: the folio.
+ *
+ * non-MGLRU may want to make use the lowest LRU referenced count bit
+ * explicitely as a referenced mark.
+ */
+static inline void folio_mark_referenced_by_bit(struct folio *folio)
+{
+	set_mask_bits(folio_flags(folio, 0), BIT(PG_referenced), BIT(PG_referenced));
+}
+
+/**
+ * folio_clear_referenced_by_bit - Mark a folio as referenced exactly once.
+ * @folio: the folio.
+ */
+static inline void folio_clear_referenced_by_bit(struct folio *folio)
+{
+	set_mask_bits(folio_flags(folio, 0), BIT(PG_referenced), 0);
+}
+
+/**
+ * folio_test_clear_referenced_bit - Test and clear the referenced bit
+ * @folio: the folio.
+ */
+static inline bool folio_test_clear_referenced_bit(struct folio *folio)
+{
+	return test_and_clear_bit(PG_referenced, folio_flags(folio, 0));
+}
+
+/**
+ * folio_is_referenced_by_bit - Mark a folio as referenced at least once.
+ * @folio: the folio.
+ */
+static inline bool folio_is_referenced_by_bit(const struct folio *folio)
+{
+	return test_bit(PG_referenced, const_folio_flags(folio, 0));
+}
+
+/**
+ * folio_is_workingset - Tell if a folio is part of the workingset.
+ * @folio: the folio.
+ *
+ * Can be used to replace folio_test_workingset safely. For MGLRU the LRU
+ * referenced count tells if a folio is a workingset as intended. For non-MGLRU,
+ * the check below only holds true if the PG_workingset bit is set.
+ */
+static inline bool folio_is_workingset(const struct folio *folio)
+{
+	return folio_lru_refs(folio) >= LRU_REFS_WORKINGSET;
+}
+
+/**
+ * folio_mark_workingset_by_bit - Mark a folio as part of the workingset.
+ * @folio: the folio.
+ *
+ * Force set a folio's LRU referenced count to at least LRU_REFS_WORKINGSET.
+ */
+static inline void folio_mark_workingset_by_bit(struct folio *folio)
+{
+	set_mask_bits(folio_flags(folio, 0), BIT(PG_workingset), BIT(PG_workingset));
+}
+
+static inline void folio_migrate_refs(struct folio *new, const struct folio *old)
+{
+	folio_set_lru_refs(new, folio_lru_refs(old));
+}
+
 #ifdef CONFIG_LRU_GEN
 
 static inline bool lru_gen_switching(void)
@@ -171,56 +338,6 @@ static inline void lru_gen_set_flags(unsigned long *flags, int gen)
 	*flags |= (gen + 1UL) << LRU_GEN_PGOFF;
 }
 
-/**
- * lru_refs_from_flags - Return LRU referenced / access count from folio flags.
- * @flags: folio flags
- */
-static inline int lru_refs_from_flags(unsigned long flags)
-{
-	int refs;
-
-	/*
-	 * Return the total number of accesses. Also see the comment on
-	 * LRU_REFS_FLAGS.
-	 */
-	refs = (flags & BIT(PG_referenced)) ? BIT(0) : 0;
-	refs += (flags & BIT(PG_workingset)) ? BIT(1) : 0;
-	refs += ((flags & LRU_REFS_MASK) >> LRU_REFS_PGOFF) << 2;
-	return refs;
-}
-
-/**
- * lru_refs_set_flags - Set the LRU referenced / access count to specified folio flags.
- * @flags: pointer to the folio flags
- * @refs: referenced / access count number, between 0 and LRU_REFS_MAX, inclusive.
- */
-static inline void lru_refs_set_flags(unsigned long *flags, unsigned int refs)
-{
-	VM_WARN_ON_ONCE(refs > LRU_REFS_MAX);
-
-	*flags &= ~LRU_REFS_FLAGS;
-	if (refs & BIT(0))
-		*flags |= BIT(PG_referenced);
-	if (refs & BIT(1))
-		*flags |= BIT(PG_workingset);
-	*flags |= (((unsigned long)refs) >> 2) << LRU_REFS_PGOFF;
-}
-
-static inline int folio_lru_refs(const struct folio *folio)
-{
-	return lru_refs_from_flags(READ_ONCE(*const_folio_flags(folio, 0)));
-}
-
-static inline void folio_set_lru_refs(struct folio *folio, unsigned int refs)
-{
-	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
-
-	do {
-		new_flags = old_flags;
-		lru_refs_set_flags(&new_flags, refs);
-	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
-}
-
 static inline int folio_lru_gen(const struct folio *folio)
 {
 	return lru_gen_from_flags(READ_ONCE(*const_folio_flags(folio, 0)));
@@ -366,11 +483,6 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 
 	return true;
 }
-
-static inline void folio_migrate_refs(struct folio *new, const struct folio *old)
-{
-	folio_set_lru_refs(new, folio_lru_refs(old));
-}
 #else /* !CONFIG_LRU_GEN */
 
 static inline bool lru_gen_enabled(void)
@@ -398,13 +510,6 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 	return false;
 }
 
-static inline void folio_migrate_refs(struct folio *new, const struct folio *old)
-{
-	if (folio_test_referenced(old))
-		folio_set_referenced(new);
-	if (folio_test_workingset(old))
-		folio_set_workingset(new);
-}
 #endif /* CONFIG_LRU_GEN */
 
 static __always_inline
diff --git a/mm/migrate.c b/mm/migrate.c
index 23248484a165..bb52bb8565f4 100644
--- a/mm/migrate.c
+++ b/mm/migrate.c
@@ -770,8 +770,6 @@ void folio_migrate_flags(struct folio *newfolio, struct folio *folio)
 		folio_set_active(newfolio);
 	} else if (folio_test_clear_unevictable(folio))
 		folio_set_unevictable(newfolio);
-	if (folio_test_workingset(folio))
-		folio_set_workingset(newfolio);
 	if (folio_test_checked(folio))
 		folio_set_checked(newfolio);
 	/*

-- 
2.54.0

