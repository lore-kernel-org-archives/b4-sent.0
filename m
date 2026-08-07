From: Kairui Song <kasong@tencent.com>
Date: Sat, 08 Aug 2026 05:17:09 +0800
Subject: [PATCH RFC 08/13] mm/huge_memory: move anon_vma and filemap
 management into split helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-swap-thp-cleanup-v1-8-689939a7ccc3@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786137467; l=9016;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=Tdpu3yM2jJD/dLTIquK8QVzk8LI0pYKr2L3DEgrEOZY=;
 b=vE5S16rk8H6tQL7nMbKAIEEiUR03ZTW7o4PEm5gfVq7qO35uzHPGQa0PaRtrA3KeCbh9yKL8e
 qEexL8JeNZ1CjPd10TUfXx4AfXATeKc3jN/GArLUOjRiAlTTylK34wK
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Only anon split needs vma info, and only file split needs the filemap
handling. Move the related code into separate helpers so they are
genuinely more self-contained.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 177 +++++++++++++++++++++++++------------------------------
 1 file changed, 79 insertions(+), 98 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index c0115841d1a0..f0ea6e5f53f7 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3939,12 +3939,33 @@ static int __folio_freeze_split_unmap_anon(struct folio *folio, unsigned int new
 	struct swap_cluster_info *ci = NULL;
 	struct folio *new_folio;
 	int old_order = folio_order(folio);
+	struct anon_vma *anon_vma = NULL;
 	enum ttu_flags ttu_flags = 0;
 	struct list_lru_one *lru;
 	struct lruvec *lruvec;
 	bool dequeue_deferred;
 	int ret = 0;
 
+	/*
+	 * Unmap/remap needs the anon_vma. The caller does not necessarily
+	 * hold an mmap_lock that would prevent the anon_vma from
+	 * disappearing, so we first take a reference and lock it. This is
+	 * similar to folio_lock_anon_vma_read() except the write lock is
+	 * taken to serialize against parallel split or collapse.
+	 */
+	if (unmap) {
+		anon_vma = folio_get_anon_vma(folio);
+		if (!anon_vma)
+			return -EBUSY;
+		anon_vma_lock_write(anon_vma);
+	}
+
+	/* Racy check if we can split the page, before the optional unmap. */
+	if (folio_expected_ref_count(folio) != folio_ref_count(folio) - 1) {
+		ret = -EAGAIN;
+		goto out_unlock;
+	}
+
 	if (unmap)
 		unmap_folio(folio);
 
@@ -4031,21 +4052,58 @@ static int __folio_freeze_split_unmap_anon(struct folio *folio, unsigned int new
 			ttu_flags = TTU_USE_SHARED_ZEROPAGE;
 		remap_page(folio, 1 << old_order, ttu_flags);
 	}
+out_unlock:
+	if (anon_vma) {
+		anon_vma_unlock_write(anon_vma);
+		put_anon_vma(anon_vma);
+	}
 
 	return ret;
 }
 
 static int __folio_freeze_split_unmap_file(struct folio *folio, unsigned int new_order,
-					   struct page *split_at, struct xa_state *xas,
-					   struct address_space *mapping, bool do_lru,
+					   struct page *split_at, bool do_lru,
 					   struct list_head *list, enum split_type split_type)
 {
+	struct address_space *mapping = folio->mapping;
+	XA_STATE(xas, &mapping->i_pages, folio->index);
 	struct folio *end_folio = folio_next(folio);
 	struct folio *new_folio, *next;
 	int nr_shmem_dropped = 0;
+	unsigned int min_order;
 	struct lruvec *lruvec;
 	pgoff_t end = 0;
-	int ret;
+	gfp_t gfp;
+	int ret = 0;
+
+	min_order = mapping_min_folio_order(mapping);
+	if (new_order < min_order)
+		return -EINVAL;
+
+	gfp = current_gfp_context(mapping_gfp_mask(mapping) & GFP_RECLAIM_MASK);
+	if (!filemap_release_folio(folio, gfp))
+		return -EBUSY;
+
+	mapping_set_update(&xas, mapping);
+
+	if (split_type == SPLIT_TYPE_UNIFORM) {
+		int old_order = folio_order(folio);
+
+		xas_set_order(&xas, folio->index, new_order);
+		xas_split_alloc(&xas, folio, old_order, gfp);
+		if (xas_error(&xas)) {
+			ret = xas_error(&xas);
+			goto fail_free;
+		}
+	}
+
+	i_mmap_lock_read(mapping);
+
+	/* Racy check if we can split the page, before unmap_folio() */
+	if (folio_expected_ref_count(folio) != folio_ref_count(folio) - 1) {
+		ret = -EAGAIN;
+		goto fail_mmap_unlock;
+	}
 
 	/*
 	 *__split_unmapped_folio() may need to trim off pages beyond
@@ -4060,13 +4118,13 @@ static int __folio_freeze_split_unmap_file(struct folio *folio, unsigned int new
 
 	unmap_folio(folio);
 
-	xas_lock_irq(xas);
+	xas_lock_irq(&xas);
 
 	/*
 	 * Check if the folio is present in page cache.
 	 * We assume all tail are present too, if folio is there.
 	 */
-	if (xas_load(xas) != folio) {
+	if (xas_load(&xas) != folio) {
 		ret = -EAGAIN;
 		goto fail;
 	}
@@ -4093,7 +4151,7 @@ static int __folio_freeze_split_unmap_file(struct folio *folio, unsigned int new
 	if (do_lru)
 		lruvec = folio_lruvec_lock(folio);
 
-	ret = __split_unmapped_folio(folio, new_order, split_at, xas,
+	ret = __split_unmapped_folio(folio, new_order, split_at, &xas,
 				     mapping, split_type);
 
 	/*
@@ -4145,9 +4203,19 @@ static int __folio_freeze_split_unmap_file(struct folio *folio, unsigned int new
 		lruvec_unlock(lruvec);
 
 fail:
-	xas_unlock_irq(xas);
+	xas_unlock_irq(&xas);
+fail_mmap_unlock:
 	if (nr_shmem_dropped)
 		shmem_uncharge(mapping->host, nr_shmem_dropped);
+	/*
+	 * Drop the mapping while the inode is still pinned. @folio stays
+	 * locked and present in the page cache, so eviction cannot free
+	 * the inode yet, nothing past this point may touch the inode or
+	 * the mapping.
+	 */
+	i_mmap_unlock_read(mapping);
+fail_free:
+	xas_destroy(&xas);
 	return ret;
 }
 
@@ -4176,12 +4244,9 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		struct page *split_at, struct page *lock_at,
 		struct list_head *list, enum split_type split_type)
 {
-	XA_STATE(xas, &folio->mapping->i_pages, folio->index);
 	struct folio *end_folio = folio_next(folio);
 	bool is_anon = folio_test_anon(folio);
 	struct mem_cgroup *memcg, *old_memcg;
-	struct address_space *mapping = NULL;
-	struct anon_vma *anon_vma = NULL;
 	int old_order = folio_order(folio);
 	struct folio *new_folio, *next;
 	int ret;
@@ -4212,84 +4277,12 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 	memcg = get_mem_cgroup_from_folio(folio);
 	old_memcg = set_active_memcg(memcg);
 
-	if (is_anon) {
-		/*
-		 * The caller does not necessarily hold an mmap_lock that would
-		 * prevent the anon_vma disappearing so we first we take a
-		 * reference to it and then lock the anon_vma for write. This
-		 * is similar to folio_lock_anon_vma_read except the write lock
-		 * is taken to serialise against parallel split or collapse
-		 * operations.
-		 */
-		anon_vma = folio_get_anon_vma(folio);
-		if (!anon_vma) {
-			ret = -EBUSY;
-			goto out;
-		}
-		anon_vma_lock_write(anon_vma);
-		mapping = NULL;
-	} else {
-		unsigned int min_order;
-		gfp_t gfp;
-
-		mapping = folio->mapping;
-		min_order = mapping_min_folio_order(mapping);
-		if (new_order < min_order) {
-			ret = -EINVAL;
-			goto out;
-		}
-
-		gfp = current_gfp_context(mapping_gfp_mask(mapping) &
-							GFP_RECLAIM_MASK);
-
-		if (!filemap_release_folio(folio, gfp)) {
-			ret = -EBUSY;
-			goto out;
-		}
-
-		mapping_set_update(&xas, mapping);
-
-		if (split_type == SPLIT_TYPE_UNIFORM) {
-			xas_set_order(&xas, folio->index, new_order);
-			xas_split_alloc(&xas, folio, old_order, gfp);
-			if (xas_error(&xas)) {
-				ret = xas_error(&xas);
-				goto out;
-			}
-		}
-
-		anon_vma = NULL;
-		i_mmap_lock_read(mapping);
-	}
-
-	/*
-	 * Racy check if we can split the page, before unmap_folio() will
-	 * split PMDs
-	 */
-	if (folio_expected_ref_count(folio) != folio_ref_count(folio) - 1) {
-		ret = -EAGAIN;
-		goto out_unlock;
-	}
-
-	if (!is_anon) {
-		ret = __folio_freeze_split_unmap_file(folio, new_order, split_at, &xas, mapping,
-							 true, list, split_type);
-	} else {
+	if (is_anon)
 		ret = __folio_freeze_split_unmap_anon(folio, new_order, split_at, true,
 						      true, list, split_type);
-	}
-
-	/*
-	 * Drop the mapping while the inode is still pinned. @folio stays
-	 * locked and present in the page cache until the loop below, so
-	 * eviction cannot free the inode yet; @lock_at is not enough, it may
-	 * be a tail beyond EOF that the split already dropped from the page
-	 * cache. Nothing past this point may touch the inode or the mapping.
-	 */
-	if (mapping) {
-		i_mmap_unlock_read(mapping);
-		mapping = NULL;
-	}
+	else
+		ret = __folio_freeze_split_unmap_file(folio, new_order, split_at,
+						      true, list, split_type);
 
 	/*
 	 * Unlock all after-split folios except the one containing
@@ -4310,19 +4303,10 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		free_folio_and_swap_cache(new_folio);
 	}
 
-out_unlock:
-	if (anon_vma) {
-		anon_vma_unlock_write(anon_vma);
-		put_anon_vma(anon_vma);
-	}
-	if (mapping)
-		i_mmap_unlock_read(mapping);
-out:
 	/* restore to caller's old_memcg */
 	set_active_memcg(old_memcg);
 	mem_cgroup_put(memcg);
 out_no_memcg:
-	xas_destroy(&xas);
 	if (is_pmd_order(old_order))
 		count_vm_event(!ret ? THP_SPLIT_PAGE : THP_SPLIT_PAGE_FAILED);
 	count_mthp_stat(old_order, !ret ? MTHP_STAT_SPLIT : MTHP_STAT_SPLIT_FAILED);
@@ -4358,9 +4342,6 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_large(folio), folio);
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_anon(folio), folio);
 
-	if (folio_expected_ref_count(folio) != folio_ref_count(folio) - 1)
-		return -EAGAIN;
-
 	return __folio_freeze_split_unmap_anon(folio, new_order, &folio->page, false,
 					       false, NULL, SPLIT_TYPE_UNIFORM);
 }

-- 
2.55.0

