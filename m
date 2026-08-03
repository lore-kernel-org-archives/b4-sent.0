From: Kairui Song <kasong@tencent.com>
Date: Tue, 04 Aug 2026 03:47:06 +0800
Subject: [PATCH RFC 10/15] mm/mglru: make folio lru referenced times count
 a generic API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-mglru-fg-v1-10-4d8dad39dad6@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785786439; l=9394;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=pavYdhuAU5OwgfCxwjbABkIxiu5hT6fbcrjm/x7ACsw=;
 b=d3wg6Yy52t36UmlNDlDQoCaeid1WRHhSSSH1k9fIA07ImY/PrYXUV4Ynfyh44gvYQPVityi4D
 GpazfrxHVV0APh8Tm1fpf0blBikgvUg/l5TmvuUwYEJSj4j9ENJVudp
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
 include/linux/mm_inline.h | 233 ++++++++++++++++++++++++++++++----------------
 mm/migrate.c              |   2 -
 2 files changed, 155 insertions(+), 80 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index 944baa91bf18..a13b7d3c033a 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -94,6 +94,161 @@ static __always_inline enum lru_list folio_lru_list(const struct folio *folio)
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
+	BUILD_BUG_ON((LRU_REFS_MAX >> 2) > (BIT(LRU_REFS_WIDTH) - 1));
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
+int folio_inc_lru_refs(struct folio *folio, bool is_fault, bool is_exec);
+
+/**
+ * folio_is_referenced - Tell if a folio was accessed before.
+ * @folio: the folio.
+ *
+ * This helper currently only works as intended for MGLRU, as it checks
+ * all LRU_REFS_FLAGS. It might be fine for non-MGLRU to replace
+ * folio_test_referenced in some cases but the user should be careful.
+ *
+ * Returns: true if the folio's LRU referenced / accessed count > 0.
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
+ * folio_mark_referenced_by_bit - Mark a folio as referenced by bit.
+ * @folio: the folio.
+ *
+ * non-MGLRU may want to make use of the lowest LRU referenced count bit
+ * explicitly as a referenced mark.
+ */
+static inline void folio_mark_referenced_by_bit(struct folio *folio)
+{
+	set_bit(PG_referenced, folio_flags(folio, 0));
+}
+
+/**
+ * folio_clear_referenced_by_bit - Clear the referenced bit of a folio.
+ * @folio: the folio.
+ */
+static inline void folio_clear_referenced_by_bit(struct folio *folio)
+{
+	clear_bit(PG_referenced, folio_flags(folio, 0));
+}
+
+/**
+ * folio_test_clear_referenced_by_bit - Test and clear the referenced bit
+ * @folio: the folio.
+ */
+static inline bool folio_test_clear_referenced_by_bit(struct folio *folio)
+{
+	return test_and_clear_bit(PG_referenced, folio_flags(folio, 0));
+}
+
+/**
+ * folio_is_referenced_by_bit - Test if the referenced bit of a folio is set.
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
+ * folio_mark_workingset_by_bit - Set the workingset bit of a folio.
+ * @folio: the folio.
+ */
+static inline void folio_mark_workingset_by_bit(struct folio *folio)
+{
+	set_bit(PG_workingset, folio_flags(folio, 0));
+}
+
+static inline void folio_migrate_refs(struct folio *new, const struct folio *old)
+{
+	folio_set_lru_refs(new, folio_lru_refs(old));
+}
+
 #ifdef CONFIG_LRU_GEN
 
 static inline bool lru_gen_switching(void)
@@ -171,58 +326,6 @@ static inline void lru_gen_set_flags(unsigned long *flags, int gen)
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
-	BUILD_BUG_ON((LRU_REFS_MAX >> 2) > (BIT(LRU_REFS_WIDTH) - 1));
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
-int folio_inc_lru_refs(struct folio *folio, bool is_fault, bool is_exec);
-
 static inline int folio_lru_gen(const struct folio *folio)
 {
 	return lru_gen_from_flags(READ_ONCE(*const_folio_flags(folio, 0)));
@@ -369,11 +472,6 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 	return true;
 }
 
-static inline void folio_migrate_refs(struct folio *new, const struct folio *old)
-{
-	folio_set_lru_refs(new, folio_lru_refs(old));
-}
-
 #else /* !CONFIG_LRU_GEN */
 
 static inline bool lru_gen_enabled(void)
@@ -401,27 +499,6 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 	return false;
 }
 
-static inline int folio_lru_refs(const struct folio *folio)
-{
-	return 0;
-}
-
-static inline void folio_set_lru_refs(struct folio *folio, unsigned int refs)
-{
-}
-
-static inline int folio_inc_lru_refs(struct folio *folio, bool promote, bool is_exec)
-{
-	return 0;
-}
-
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
index c737d0682fa4..806f1e913a38 100644
--- a/mm/migrate.c
+++ b/mm/migrate.c
@@ -786,8 +786,6 @@ void folio_migrate_flags(struct folio *newfolio, struct folio *folio)
 		folio_set_active(newfolio);
 	} else if (folio_test_clear_unevictable(folio))
 		folio_set_unevictable(newfolio);
-	if (folio_test_workingset(folio))
-		folio_set_workingset(newfolio);
 	if (folio_test_checked(folio))
 		folio_set_checked(newfolio);
 	/*

-- 
2.55.0

