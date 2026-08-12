From: Kairui Song <kasong@tencent.com>
Date: Thu, 13 Aug 2026 02:48:44 +0800
Subject: [PATCH v2 04/17] mm/huge_memory: split the routine for splitting
 anon and file folio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-swap-thp-cleanup-v2-4-d2ee48c6aa49@tencent.com>
References: <20260813-swap-thp-cleanup-v2-0-d2ee48c6aa49@tencent.com>
In-Reply-To: <20260813-swap-thp-cleanup-v2-0-d2ee48c6aa49@tencent.com>
To: linux-mm@kvack.org
Cc: linux-kernel@vger.kernel.org, Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Zi Yan <ziy@nvidia.com>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Nico Pache <nico.pache@linux.dev>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Chris Li <chrisl@kernel.org>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <baoquan.he@linux.dev>, 
 Barry Song <baohua@kernel.org>, Youngjun Park <youngjun.park@lge.com>, 
 Shivam Kalra <shivamkalra98@zohomail.in>, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786560550; l=8891;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=u/PY3rA59I05qsJFQoxSfswRpt4QGmWJXn/YBJ2ly+E=;
 b=UyS+Ybcre9RJQTyAqQjSqfHwqYAvv4gnR792SypgViHDof+y9eE9m3XOtx0gAXQS85+nRFqdL
 xVBFl+WEPXuBoejnyg+lqyZHq8VJeM3/Zg61bzwUwcxyMie4aQ36dAR
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No functional change intended. Before adding more logic, split
__folio_freeze_and_split_unmapped() into an anon and a file variant so
each path can evolve independently. The two paths shared little beyond
the folio freeze call, the LRU locking, and the unfreeze skeleton, but
differed in all other per-folio bookkeeping and routines.

While splitting, some cleanups become easy to apply, and helped drop a
few now-redundant checks. Also introduce a folio iteration helper to
avoid a common pitfall of iterating post-split sub-folios: a sub folio
might get freed mid-iteration as pointed out by Zi [1].

Link: https://lore.kernel.org/linux-mm/DKJSFCLP967N.YBR4DNK1NM2N@nvidia.com/ [1]
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 133 +++++++++++++++++++++++++++++++++++--------------------
 1 file changed, 85 insertions(+), 48 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 7fb603ac500f..7587eeb09e4a 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3634,6 +3634,18 @@ static bool page_range_has_hwpoisoned(struct page *page, long nr_pages)
 	return false;
 }
 
+/**
+ * for_each_folio_safe - iterate over contiguous folios safe against folio free
+ * @start: the first folio to iterate
+ * @end: sentinel, folio_next() of the last folio to iterate
+ * @sub_folio: struct folio * to use as the loop cursor
+ * @next: struct folio * used as temporary storage
+ */
+#define for_each_folio_safe(start, end, sub_folio, next) \
+	for (sub_folio = (start), next = folio_next(sub_folio); \
+	     sub_folio != (end); \
+	     sub_folio = next, next = folio_next(next))
+
 /*
  * It splits @folio into @new_order folios and copies the @folio metadata to
  * all the resulting folios.
@@ -3933,11 +3945,9 @@ static unsigned int folio_cache_ref_count(const struct folio *folio)
 	return folio_nr_pages(folio);
 }
 
-static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int new_order,
-					     struct page *split_at, struct xa_state *xas,
-					     struct address_space *mapping, bool do_lru,
-					     struct list_head *list, enum split_type split_type,
-					     pgoff_t end, int *nr_shmem_dropped)
+static int __folio_freeze_split_unmapped_anon(struct folio *folio, unsigned int new_order,
+					      struct page *split_at, bool do_lru,
+					      struct list_head *list, enum split_type split_type)
 {
 	struct folio *end_folio = folio_next(folio);
 	struct swap_cluster_info *ci = NULL;
@@ -3948,7 +3958,6 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 	bool dequeue_deferred;
 	int ret = 0;
 
-	VM_WARN_ON_ONCE(!mapping && end);
 	/*
 	 * If this folio can be on the deferred split queue, lock out
 	 * the shrinker before freezing the ref. If the shrinker sees
@@ -3956,7 +3965,7 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 	 * lock and must clean up the LRU state - the same dequeue we
 	 * will do below as part of the split.
 	 */
-	dequeue_deferred = folio_test_anon(folio) && old_order > 1;
+	dequeue_deferred = old_order > 1;
 	if (dequeue_deferred) {
 		struct mem_cgroup *memcg;
 
@@ -3986,24 +3995,70 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 		rcu_read_unlock();
 	}
 
-	if (mapping) {
+	if (folio_test_swapcache(folio))
+		ci = swap_cluster_get_and_lock(folio);
+
+	if (do_lru)
+		lruvec = folio_lruvec_lock(folio);
+
+	ret = __split_unmapped_folio(folio, new_order, split_at, NULL,
+				     NULL, split_type);
+
+	/*
+	 * Unfreeze the post-split folios and put them back to the right
+	 * place. Keep the head @folio frozen until the end: sub entries
+	 * in swap cache must be updated first, so a concurrent
+	 * swap_cache_get_folio() cannot return the head folio for a sub
+	 * entry (folio_try_get() will fail on the head @folio until unfreeze).
+	 */
+	for_each_folio_safe(folio_next(folio), end_folio, new_folio, next) {
+		zone_device_private_split_cb(folio, new_folio);
+		folio_ref_unfreeze(new_folio,
+				   folio_cache_ref_count(new_folio) + 1);
+		if (do_lru)
+			lru_add_split_folio(folio, new_folio, lruvec, list);
+		if (ci)
+			__swap_cache_replace_folio(ci, folio, new_folio);
+	}
+
+	zone_device_private_split_cb(folio, NULL);
+	folio_ref_unfreeze(folio, folio_cache_ref_count(folio) + 1);
+
+	if (do_lru)
+		lruvec_unlock(lruvec);
+	if (ci)
+		swap_cluster_unlock(ci);
+
+	return ret;
+}
+
+static int __folio_freeze_split_unmapped_file(struct folio *folio, unsigned int new_order,
+					      struct page *split_at, struct xa_state *xas,
+					      struct address_space *mapping, bool do_lru,
+					      struct list_head *list, enum split_type split_type,
+					      pgoff_t end, int *nr_shmem_dropped)
+{
+	struct folio *end_folio = folio_next(folio);
+	struct folio *new_folio, *next;
+	struct lruvec *lruvec;
+	int ret;
+
+	if (!folio_ref_freeze(folio, folio_cache_ref_count(folio) + 1))
+		return -EAGAIN;
+
+	if (folio_test_pmd_mappable(folio) &&
+	    new_order < HPAGE_PMD_ORDER) {
 		int nr = folio_nr_pages(folio);
 
-		if (folio_test_pmd_mappable(folio) &&
-		    new_order < HPAGE_PMD_ORDER) {
-			if (folio_test_swapbacked(folio)) {
-				lruvec_stat_mod_folio(folio,
-						      NR_SHMEM_THPS, -nr);
-			} else {
-				lruvec_stat_mod_folio(folio,
-						      NR_FILE_THPS, -nr);
-			}
+		if (folio_test_swapbacked(folio)) {
+			lruvec_stat_mod_folio(folio,
+					      NR_SHMEM_THPS, -nr);
+		} else {
+			lruvec_stat_mod_folio(folio,
+					      NR_FILE_THPS, -nr);
 		}
 	}
 
-	if (folio_test_swapcache(folio))
-		ci = swap_cluster_get_and_lock(folio);
-
 	/* lock lru list/PageCompound, ref frozen by page_ref_freeze */
 	if (do_lru)
 		lruvec = folio_lruvec_lock(folio);
@@ -4013,39 +4068,21 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 
 	/*
 	 * Unfreeze after-split folios and put them back to the right
-	 * list. @folio should be kept frozon until page cache
+	 * list. @folio should be kept frozen until page cache
 	 * entries are updated with all the other after-split folios
 	 * to prevent others seeing stale page cache entries.
 	 * As a result, new_folio starts from the next folio of
 	 * @folio.
 	 */
-	for (new_folio = folio_next(folio); new_folio != end_folio;
-	     new_folio = next) {
+	for_each_folio_safe(folio_next(folio), end_folio, new_folio, next) {
 		unsigned long nr_pages = folio_nr_pages(new_folio);
 
-		next = folio_next(new_folio);
-
-		zone_device_private_split_cb(folio, new_folio);
-
 		folio_ref_unfreeze(new_folio,
 				   folio_cache_ref_count(new_folio) + 1);
 
 		if (do_lru)
 			lru_add_split_folio(folio, new_folio, lruvec, list);
 
-		/*
-		 * Anonymous folio with swap cache.
-		 * NOTE: shmem in swap cache is not supported yet.
-		 */
-		if (ci) {
-			__swap_cache_replace_folio(ci, folio, new_folio);
-			continue;
-		}
-
-		/* Anonymous folio without swap cache */
-		if (!mapping)
-			continue;
-
 		/* Add the new folio to the page cache. */
 		if (new_folio->index < end) {
 			__xa_store(&mapping->i_pages, new_folio->index,
@@ -4064,7 +4101,6 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 		folio_put_refs(new_folio, nr_pages);
 	}
 
-	zone_device_private_split_cb(folio, NULL);
 	/*
 	 * Unfreeze @folio only after all page cache entries, which
 	 * used to point to it, have been updated with new folios.
@@ -4075,8 +4111,6 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 
 	if (do_lru)
 		lruvec_unlock(lruvec);
-	if (ci)
-		swap_cluster_unlock(ci);
 
 	return ret;
 }
@@ -4230,10 +4264,14 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 			ret = -EAGAIN;
 			goto fail;
 		}
+		ret = __folio_freeze_split_unmapped_file(folio, new_order, split_at, &xas, mapping,
+							 true, list, split_type, end,
+							 &nr_shmem_dropped);
+	} else {
+		ret = __folio_freeze_split_unmapped_anon(folio, new_order, split_at, true,
+							 list, split_type);
 	}
 
-	ret = __folio_freeze_and_split_unmapped(folio, new_order, split_at, &xas, mapping,
-						true, list, split_type, end, &nr_shmem_dropped);
 fail:
 	if (mapping)
 		xas_unlock(&xas);
@@ -4333,9 +4371,8 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
 		return -EAGAIN;
 
 	local_irq_disable();
-	ret = __folio_freeze_and_split_unmapped(folio, new_order, &folio->page, NULL,
-						NULL, false, NULL, SPLIT_TYPE_UNIFORM,
-						0, NULL);
+	ret = __folio_freeze_split_unmapped_anon(folio, new_order, &folio->page,
+						 false, NULL, SPLIT_TYPE_UNIFORM);
 	local_irq_enable();
 	return ret;
 }

-- 
2.55.0

