From: Kairui Song <kasong@tencent.com>
Date: Fri, 17 Apr 2026 02:34:32 +0800
Subject: [PATCH v2 02/11] mm, swap: move common swap cache operations into
 standalone helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260417-swap-table-p4-v2-2-17f5d1015428@tencent.com>
References: <20260417-swap-table-p4-v2-0-17f5d1015428@tencent.com>
In-Reply-To: <20260417-swap-table-p4-v2-0-17f5d1015428@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Zi Yan <ziy@nvidia.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Barry Song <baohua@kernel.org>, 
 Hugh Dickins <hughd@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Youngjun Park <youngjun.park@lge.com>, 
 Chengming Zhou <chengming.zhou@linux.dev>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <zhengqi.arch@bytedance.com>, linux-kernel@vger.kernel.org, 
 cgroups@vger.kernel.org, Kairui Song <kasong@tencent.com>, 
 Yosry Ahmed <yosry@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Michal Hocko <mhocko@suse.com>, Michal Hocko <mhocko@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Lorenzo Stoakes <ljs@kernel.org>, 
 Yosry Ahmed <yosry@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776364480; l=7606;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=HpVIdXRr1EUECVgWZuJLDmJFOLfQVogQc6+DzLywiyw=;
 b=SwEVpOX11TdO0kzHMxfkZdsPnOyUE63uNUTZLtlSzzfSMRc/+13I/N8uDLQE+PY4+IaquBzxq
 A/ajo4XISw9DmVY/efzeO7IAHtQVi7zP6CHNlbdFweICKGMwEibj/LO
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move a few swap cache checking, adding, and deletion operations
into standalone helpers to be used later. And while at it, add
proper kernel doc.

No feature or behavior change.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swap_state.c | 141 ++++++++++++++++++++++++++++++++++++++------------------
 1 file changed, 95 insertions(+), 46 deletions(-)

diff --git a/mm/swap_state.c b/mm/swap_state.c
index eb4304aa00b7..3ef86db8220a 100644
--- a/mm/swap_state.c
+++ b/mm/swap_state.c
@@ -137,8 +137,42 @@ void *swap_cache_get_shadow(swp_entry_t entry)
 	return NULL;
 }
 
-void __swap_cache_add_folio(struct swap_cluster_info *ci,
-			    struct folio *folio, swp_entry_t entry)
+/**
+ * __swap_cache_add_check - Check if a range is suitable for adding a folio.
+ * @ci: The locked swap cluster.
+ * @ci_off: Range start offset.
+ * @nr: Number of slots to check.
+ * @shadow: Returns the shadow value if one exists in the range.
+ *
+ * Check if all slots covered by given range have a swap count >= 1.
+ * Retrieves the shadow if there is one.
+ *
+ * Context: Caller must lock the cluster.
+ */
+static int __swap_cache_add_check(struct swap_cluster_info *ci,
+				  unsigned int ci_off, unsigned int nr,
+				  void **shadow)
+{
+	unsigned int ci_end = ci_off + nr;
+	unsigned long old_tb;
+
+	if (unlikely(!ci->table))
+		return -ENOENT;
+	do {
+		old_tb = __swap_table_get(ci, ci_off);
+		if (unlikely(swp_tb_is_folio(old_tb)))
+			return -EEXIST;
+		if (unlikely(!__swp_tb_get_count(old_tb)))
+			return -ENOENT;
+		if (swp_tb_is_shadow(old_tb))
+			*shadow = swp_tb_to_shadow(old_tb);
+	} while (++ci_off < ci_end);
+
+	return 0;
+}
+
+static void __swap_cache_do_add_folio(struct swap_cluster_info *ci,
+				      struct folio *folio, swp_entry_t entry)
 {
 	unsigned int ci_off = swp_cluster_offset(entry), ci_end;
 	unsigned long nr_pages = folio_nr_pages(folio);
@@ -159,7 +193,28 @@ void __swap_cache_add_folio(struct swap_cluster_info *ci,
 	folio_ref_add(folio, nr_pages);
 	folio_set_swapcache(folio);
 	folio->swap = entry;
+}
 
+/**
+ * __swap_cache_add_folio - Add a folio to the swap cache and update stats.
+ * @ci: The locked swap cluster.
+ * @folio: The folio to be added.
+ * @entry: The swap entry corresponding to the folio.
+ *
+ * Unconditionally add a folio to the swap cache. The caller must ensure
+ * all slots are usable and have no conflicts. This assigns entry to
+ * @folio->swap, increases folio refcount by the number of pages, and
+ * updates swap cache stats.
+ *
+ * Context: Caller must ensure the folio is locked and lock the cluster
+ * that holds the entries.
+ */
+void __swap_cache_add_folio(struct swap_cluster_info *ci,
+			    struct folio *folio, swp_entry_t entry)
+{
+	unsigned long nr_pages = folio_nr_pages(folio);
+
+	__swap_cache_do_add_folio(ci, folio, entry);
 	node_stat_mod_folio(folio, NR_FILE_PAGES, nr_pages);
 	lruvec_stat_mod_folio(folio, NR_SWAPCACHE, nr_pages);
 }
@@ -168,9 +223,11 @@ void __swap_cache_add_folio(struct swap_cluster_info *ci,
  * swap_cache_add_folio - Add a folio into the swap cache.
  * @folio: The folio to be added.
  * @entry: The swap entry corresponding to the folio.
- * @gfp: gfp_mask for XArray node allocation.
  * @shadowp: If a shadow is found, return the shadow.
  *
+ * Add a folio into the swap cache. Will return error if any slot is no
+ * longer a valid swapped out slot or already occupied by another folio.
+ *
  * Context: Caller must ensure @entry is valid and protect the swap device
  * with reference count or locks.
  */
@@ -179,60 +236,31 @@ static int swap_cache_add_folio(struct folio *folio, swp_entry_t entry,
 {
 	int err;
 	void *shadow = NULL;
-	unsigned long old_tb;
+	unsigned int ci_off;
 	struct swap_info_struct *si;
 	struct swap_cluster_info *ci;
-	unsigned int ci_start, ci_off, ci_end;
 	unsigned long nr_pages = folio_nr_pages(folio);
 
 	si = __swap_entry_to_info(entry);
-	ci_start = swp_cluster_offset(entry);
-	ci_end = ci_start + nr_pages;
-	ci_off = ci_start;
 	ci = swap_cluster_lock(si, swp_offset(entry));
-	if (unlikely(!ci->table)) {
-		err = -ENOENT;
-		goto failed;
+	ci_off = swp_cluster_offset(entry);
+	err = __swap_cache_add_check(ci, ci_off, nr_pages, &shadow);
+	if (err) {
+		swap_cluster_unlock(ci);
+		return err;
 	}
-	do {
-		old_tb = __swap_table_get(ci, ci_off);
-		if (unlikely(swp_tb_is_folio(old_tb))) {
-			err = -EEXIST;
-			goto failed;
-		}
-		if (unlikely(!__swp_tb_get_count(old_tb))) {
-			err = -ENOENT;
-			goto failed;
-		}
-		if (swp_tb_is_shadow(old_tb))
-			shadow = swp_tb_to_shadow(old_tb);
-	} while (++ci_off < ci_end);
+
 	__swap_cache_add_folio(ci, folio, entry);
 	swap_cluster_unlock(ci);
 	if (shadowp)
 		*shadowp = shadow;
-	return 0;
 
-failed:
-	swap_cluster_unlock(ci);
-	return err;
+	return 0;
 }
 
-/**
- * __swap_cache_del_folio - Removes a folio from the swap cache.
- * @ci: The locked swap cluster.
- * @folio: The folio.
- * @entry: The first swap entry that the folio corresponds to.
- * @shadow: shadow value to be filled in the swap cache.
- *
- * Removes a folio from the swap cache and fills a shadow in place.
- * This won't put the folio's refcount. The caller has to do that.
- *
- * Context: Caller must ensure the folio is locked and in the swap cache
- * using the index of @entry, and lock the cluster that holds the entries.
- */
-void __swap_cache_del_folio(struct swap_cluster_info *ci, struct folio *folio,
-			    swp_entry_t entry, void *shadow)
+static void __swap_cache_do_del_folio(struct swap_cluster_info *ci,
+				      struct folio *folio,
+				      swp_entry_t entry, void *shadow)
 {
 	int count;
 	unsigned long old_tb;
@@ -259,14 +287,12 @@ void __swap_cache_del_folio(struct swap_cluster_info *ci, struct folio *folio,
 			folio_swapped = true;
 		else
 			need_free = true;
-		/* If shadow is NULL, we sets an empty shadow. */
+		/* If shadow is NULL, we set an empty shadow. */
 		__swap_table_set(ci, ci_off, shadow_to_swp_tb(shadow, count));
 	} while (++ci_off < ci_end);
 
 	folio->swap.val = 0;
 	folio_clear_swapcache(folio);
-	node_stat_mod_folio(folio, NR_FILE_PAGES, -nr_pages);
-	lruvec_stat_mod_folio(folio, NR_SWAPCACHE, -nr_pages);
 
 	if (!folio_swapped) {
 		__swap_cluster_free_entries(si, ci, ci_start, nr_pages);
@@ -279,6 +305,29 @@ void __swap_cache_del_folio(struct swap_cluster_info *ci, struct folio *folio,
 	}
 }
 
+/**
+ * __swap_cache_del_folio - Removes a folio from the swap cache.
+ * @ci: The locked swap cluster.
+ * @folio: The folio.
+ * @entry: The first swap entry that the folio corresponds to.
+ * @shadow: shadow value to be filled in the swap cache.
+ *
+ * Removes a folio from the swap cache and fills a shadow in place.
+ * This won't put the folio's refcount. The caller has to do that.
+ *
+ * Context: Caller must ensure the folio is locked and in the swap cache
+ * using the index of @entry, and lock the cluster that holds the entries.
+ */
+void __swap_cache_del_folio(struct swap_cluster_info *ci, struct folio *folio,
+			    swp_entry_t entry, void *shadow)
+{
+	unsigned long nr_pages = folio_nr_pages(folio);
+
+	__swap_cache_do_del_folio(ci, folio, entry, shadow);
+	node_stat_mod_folio(folio, NR_FILE_PAGES, -nr_pages);
+	lruvec_stat_mod_folio(folio, NR_SWAPCACHE, -nr_pages);
+}
+
 /**
  * swap_cache_del_folio - Removes a folio from the swap cache.
  * @folio: The folio.

-- 
2.53.0

