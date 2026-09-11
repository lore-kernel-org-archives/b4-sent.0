From: Kairui Song <kasong@tencent.com>
Date: Fri, 11 Sep 2026 19:45:08 +0800
Subject: [PATCH RFC v2 05/15] mm/mglru: make folio lru referenced times
 count a generic API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-mglru-fg-v2-5-f26e5cb26da7@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789127106; l=6566;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=sl9oGI385dpNBKTnFrEsaoQodEeUL5C6uVYMyQKT218=;
 b=WnnrsfQJcZ207GAQreMw8xwJIEDcbjputonZZn9uY0Xj4u54Z2w1nZD7H+WibPnYVffHJ8JUV
 O/jQuRtOoevAWuq0845ed2pYiVoEs2AX+SEsXwsKaVDZxc0kOZ71PXx
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pure code shuffle, no behavior change.  Make the folio LRU refs helpers
available regardless of CONFIG_LRU_GEN; without MGLRU the refs bits are
never set, so they are inert.  Move the lru_gen_* helpers into the
CONFIG_LRU_GEN section unchanged.  This prepares for unifying the API
for checking folio referenced and workingset status.

folio_migrate_lru_refs() now migrates the complete refs count,
including PG_workingset (bit 1 of the encoding), bitwise identical to
the direct copy dropped from folio_migrate_flags().  It also gains
off-LRU VM_WARN_ON_ONCE checks, compiled out unless CONFIG_DEBUG_VM.

lru_set_refs_flags() skips the nonexistent mask bits when
LRU_REFS_WIDTH collapses to 0, keeping the generic helpers inert for
!CONFIG_LRU_GEN builds.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm_inline.h | 145 +++++++++++++++++++++++-----------------------
 mm/migrate.c              |   2 -
 2 files changed, 72 insertions(+), 75 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index 7c8288661edd..5a62b83b4168 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -105,54 +105,6 @@ static __always_inline enum lru_list folio_lru_list(const struct folio *folio)
 	return lru;
 }
 
-#ifdef CONFIG_LRU_GEN
-
-static inline bool lru_gen_switching(void)
-{
-	DECLARE_STATIC_KEY_FALSE(lru_switch);
-
-	return static_branch_unlikely(&lru_switch);
-}
-#ifdef CONFIG_LRU_GEN_ENABLED
-static inline bool lru_gen_enabled(void)
-{
-	DECLARE_STATIC_KEY_TRUE(lru_gen_caps[NR_LRU_GEN_CAPS]);
-
-	return static_branch_likely(&lru_gen_caps[LRU_GEN_CORE]);
-}
-#else
-static inline bool lru_gen_enabled(void)
-{
-	DECLARE_STATIC_KEY_FALSE(lru_gen_caps[NR_LRU_GEN_CAPS]);
-
-	return static_branch_unlikely(&lru_gen_caps[LRU_GEN_CORE]);
-}
-#endif
-
-static inline bool lru_gen_in_fault(void)
-{
-	return current->in_lru_fault;
-}
-
-static inline int lru_gen_from_seq(unsigned long seq)
-{
-	return seq % MAX_NR_GENS;
-}
-
-static inline int lru_hist_from_seq(unsigned long seq)
-{
-	return seq % NR_HIST_GENS;
-}
-
-static inline int lru_tier_from_refs(unsigned int refs)
-{
-	BUILD_BUG_ON(fls(LRU_REFS_MAX - 1) > MAX_NR_TIERS - 1);
-	VM_WARN_ON_ONCE(refs > LRU_REFS_MAX);
-	if (refs < LRU_REFS_WORKINGSET)
-		return 0;
-	return fls(refs - 1);
-}
-
 /**
  * lru_set_gen_flags - Set the LRU generation number to specified folio flags.
  * @flags: pointer to the folio flags
@@ -205,7 +157,8 @@ static inline void lru_set_refs_flags(unsigned long *flags, unsigned int refs)
 		*flags |= BIT(PG_referenced);
 	if (refs & BIT(1))
 		*flags |= BIT(PG_workingset);
-	*flags |= ((unsigned long)refs >> 2) << LRU_REFS_PGOFF;
+	if (LRU_REFS_WIDTH)
+		*flags |= ((unsigned long)refs >> 2) << LRU_REFS_PGOFF;
 }
 
 /**
@@ -240,7 +193,77 @@ static inline void folio_set_lru_refs(struct folio *folio, unsigned int refs)
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 }
 
+#ifdef CONFIG_LRU_GEN
 void folio_inc_lru_refs(struct folio *folio, unsigned int flags);
+#else
+static inline void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
+{
+	/* Should not be called with !CONFIG_LRU_GEN */
+	WARN_ON_ONCE(1);
+}
+#endif
+
+/**
+ * folio_migrate_lru_refs - copy the reference state to a new folio
+ * @new: the destination folio
+ * @old: the source folio
+ *
+ * Transfer the reference state to @new during migration: the MGLRU
+ * refs count, or PG_referenced and PG_workingset (bits 0-1 of the
+ * encoding) for the active/inactive LRU.
+ */
+static inline void folio_migrate_lru_refs(struct folio *new, const struct folio *old)
+{
+	folio_set_lru_refs(new, folio_lru_refs(old));
+}
+
+#ifdef CONFIG_LRU_GEN
+
+static inline bool lru_gen_switching(void)
+{
+	DECLARE_STATIC_KEY_FALSE(lru_switch);
+
+	return static_branch_unlikely(&lru_switch);
+}
+#ifdef CONFIG_LRU_GEN_ENABLED
+static inline bool lru_gen_enabled(void)
+{
+	DECLARE_STATIC_KEY_TRUE(lru_gen_caps[NR_LRU_GEN_CAPS]);
+
+	return static_branch_likely(&lru_gen_caps[LRU_GEN_CORE]);
+}
+#else
+static inline bool lru_gen_enabled(void)
+{
+	DECLARE_STATIC_KEY_FALSE(lru_gen_caps[NR_LRU_GEN_CAPS]);
+
+	return static_branch_unlikely(&lru_gen_caps[LRU_GEN_CORE]);
+}
+#endif
+
+static inline bool lru_gen_in_fault(void)
+{
+	return current->in_lru_fault;
+}
+
+static inline int lru_gen_from_seq(unsigned long seq)
+{
+	return seq % MAX_NR_GENS;
+}
+
+static inline int lru_hist_from_seq(unsigned long seq)
+{
+	return seq % NR_HIST_GENS;
+}
+
+static inline int lru_tier_from_refs(unsigned int refs)
+{
+	BUILD_BUG_ON(fls(LRU_REFS_MAX - 1) > MAX_NR_TIERS - 1);
+	VM_WARN_ON_ONCE(refs > LRU_REFS_MAX);
+	if (refs < LRU_REFS_WORKINGSET)
+		return 0;
+	return fls(refs - 1);
+}
 
 static inline int folio_lru_gen(const struct folio *folio)
 {
@@ -388,20 +411,6 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 
 	return true;
 }
-
-/**
- * folio_migrate_lru_refs - copy the reference state to a new folio
- * @new: the destination folio
- * @old: the source folio
- *
- * Transfer the reference state to @new during migration: the MGLRU
- * refs count, including PG_referenced, or just PG_referenced for the
- * active/inactive LRU.
- */
-static inline void folio_migrate_lru_refs(struct folio *new, const struct folio *old)
-{
-	folio_set_lru_refs(new, folio_lru_refs(old));
-}
 #else /* !CONFIG_LRU_GEN */
 
 static inline bool lru_gen_enabled(void)
@@ -428,16 +437,6 @@ static inline bool lru_gen_del_folio(struct lruvec *lruvec, struct folio *folio,
 {
 	return false;
 }
-
-static inline void folio_inc_lru_refs(struct folio *folio, unsigned int flags)
-{
-}
-
-static inline void folio_migrate_lru_refs(struct folio *new, const struct folio *old)
-{
-	if (folio_test_referenced(old))
-		folio_set_referenced(new);
-}
 #endif /* CONFIG_LRU_GEN */
 
 static __always_inline
diff --git a/mm/migrate.c b/mm/migrate.c
index a369d0c95c38..b1ccffc4e7cd 100644
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

