From: Kairui Song <kasong@tencent.com>
Date: Sat, 08 Aug 2026 05:17:05 +0800
Subject: [PATCH RFC 04/13] mm/huge_memory: split the routine for splitting
 anon and file folio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-swap-thp-cleanup-v1-4-689939a7ccc3@tencent.com>
References: <20260808-swap-thp-cleanup-v1-0-689939a7ccc3@tencent.com>
In-Reply-To: <20260808-swap-thp-cleanup-v1-0-689939a7ccc3@tencent.com>
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
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786137467; l=7993;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=lE4agxpn3+FjF8GNafybHiUXu6DuwUcHCxx6OFIyyko=;
 b=jXXfNFzNWB6VtTyyD5fFqI1uatlfOQTIT/j+NeGk17u1RduV+pdazf0ClMyT0jhyVcRUiflDM
 AjI2pnjs8n2Cu+5vYJxZ9KJ6O8TjLytin2u13dIH9nuR48TVn8DzPu7
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No functional change intended. Before adding more logic, split
__folio_freeze_and_split_unmapped() into an anon and a file variant so
each path can evolve independently. The two paths shared little beyond
the folio freeze call, the LRU locking, and the unfreeze skeleton, but
differed in all other per-folio bookkeeping and routines.

While splitting, some cleanups become easy to apply, and helped dropping
a few now redundant checks.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 121 ++++++++++++++++++++++++++++++++++---------------------
 1 file changed, 76 insertions(+), 45 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index cf8f90b94e42..56a356c30f30 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3934,22 +3934,19 @@ static unsigned int folio_cache_ref_count(const struct folio *folio)
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
-	struct folio *new_folio, *next;
+	struct folio *new_folio;
 	int old_order = folio_order(folio);
 	struct list_lru_one *lru;
 	struct lruvec *lruvec;
 	bool dequeue_deferred;
 	int ret = 0;
 
-	VM_WARN_ON_ONCE(!mapping && end);
 	/*
 	 * If this folio can be on the deferred split queue, lock out
 	 * the shrinker before freezing the ref. If the shrinker sees
@@ -3957,7 +3954,7 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 	 * lock and must clean up the LRU state - the same dequeue we
 	 * will do below as part of the split.
 	 */
-	dequeue_deferred = folio_test_anon(folio) && old_order > 1;
+	dequeue_deferred = old_order > 1;
 	if (dequeue_deferred) {
 		struct mem_cgroup *memcg;
 
@@ -3987,24 +3984,73 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
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
+	 * Unfreeze the after-split folios and put them back to the right
+	 * place, keeping the head @folio frozen until the end. While the
+	 * folio is in the swap cache, the sub entries must be updated with
+	 * their after-split folios before the head is unfrozen, so a
+	 * concurrent swap_cache_get_folio() cannot return the head folio
+	 * for a sub entry. Keeping the head frozen throughout also stops a
+	 * parallel folio_try_get() from observing a partially split folio.
+	 */
+	for (new_folio = folio_next(folio); new_folio != end_folio;
+	     new_folio = folio_next(new_folio)) {
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
@@ -4014,7 +4060,7 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 
 	/*
 	 * Unfreeze after-split folios and put them back to the right
-	 * list. @folio should be kept frozon until page cache
+	 * list. @folio should be kept frozen until page cache
 	 * entries are updated with all the other after-split folios
 	 * to prevent others seeing stale page cache entries.
 	 * As a result, new_folio starts from the next folio of
@@ -4026,27 +4072,12 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 
 		next = folio_next(new_folio);
 
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
@@ -4065,7 +4096,6 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 		folio_put_refs(new_folio, nr_pages);
 	}
 
-	zone_device_private_split_cb(folio, NULL);
 	/*
 	 * Unfreeze @folio only after all page cache entries, which
 	 * used to point to it, have been updated with new folios.
@@ -4076,8 +4106,6 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 
 	if (do_lru)
 		lruvec_unlock(lruvec);
-	if (ci)
-		swap_cluster_unlock(ci);
 
 	return ret;
 }
@@ -4231,10 +4259,14 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
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
@@ -4334,9 +4366,8 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
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

