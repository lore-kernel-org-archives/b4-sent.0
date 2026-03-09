From: Zhang Peng <zippermonkey@icloud.com>
Date: Mon, 09 Mar 2026 16:17:41 +0800
Subject: [PATCH 1/2] mm/vmscan: refactor shrink_folio_list for readability
 and maintainability
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-batch-tlb-flush-v1-1-eb8fed7d1a9e@icloud.com>
References: <20260309-batch-tlb-flush-v1-0-eb8fed7d1a9e@icloud.com>
In-Reply-To: <20260309-batch-tlb-flush-v1-0-eb8fed7d1a9e@icloud.com>
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Qi Zheng <zhengqi.arch@bytedance.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Michal Hocko <mhocko@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>, Zhang Peng <bruzzhang@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773044270; l=15615;
 i=zippermonkey@icloud.com; s=20260309; h=from:subject:message-id;
 bh=hrfPhSLZZ+Rs47sneAPE3A+aMP6Jn54Z4Elam2hH+qQ=;
 b=fUmw9fFg8kt3KWtm2+E4vru0K1g6gu3U9xmpxMOL/reogAbxVlV3fpbzzCERza86X04XKFhtC
 VEZIwe1KMrjCfyLtZNomyGBfvdZ/yLy9FI8h+mzUEkEHPYh1tkSv0+I
X-Developer-Key: i=zippermonkey@icloud.com; a=ed25519;
 pk=tPCLpFnBfIyHsp0k7eaUTUREEa36bQNW/69X+NS8wBU=
X-Endpoint-Received: by B4 Relay for zippermonkey@icloud.com/20260309 with auth_id=671
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: bruzzhang <bruzzhang@tencent.com>

Refactor shrink_folio_list() by extracting three helper functions to
improve code organization and readability:

- folio_active_bounce(): Handle folio activation logic when pages need to
  be bounced back to the head of the LRU list
- folio_free(): Handle folio freeing logic, including buffer release,
  mapping removal, and batch management
- pageout_one(): Handle single folio pageout logic with proper state
  transition handling

Change shrink_folio_list() return type from unsigned int to void and track
reclaimed pages through stat->nr_reclaimed instead of a local variable.
Add nr_reclaimed field to struct reclaim_stat to support this change.

This refactoring maintains the same functionality while making the code
more modular and easier to understand. The extracted functions encapsulate
specific logical operations, making the main function flow clearer and
reducing code duplication.

No functional change.

Suggested-by: Kairui Song <kasong@tencent.com>
Signed-off-by: bruzzhang <bruzzhang@tencent.com>
---
 include/linux/vmstat.h |   1 +
 mm/vmscan.c            | 323 ++++++++++++++++++++++++++++---------------------
 2 files changed, 186 insertions(+), 138 deletions(-)

diff --git a/include/linux/vmstat.h b/include/linux/vmstat.h
index 3c9c266cf782..f088c5641d99 100644
--- a/include/linux/vmstat.h
+++ b/include/linux/vmstat.h
@@ -26,6 +26,7 @@ struct reclaim_stat {
 	unsigned nr_unmap_fail;
 	unsigned nr_lazyfree_fail;
 	unsigned nr_demoted;
+	unsigned nr_reclaimed;
 };
 
 /* Stat data for system wide items */
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 3f64a09f415c..a336f7fc7dae 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -1076,10 +1076,174 @@ static bool may_enter_fs(struct folio *folio, gfp_t gfp_mask)
 	return !data_race(folio_swap_flags(folio) & SWP_FS_OPS);
 }
 
+/* Mark folio as active and prepare to bounce back to head of LRU */
+static void folio_active_bounce(struct folio *folio, struct reclaim_stat *stat,
+		unsigned int nr_pages)
+{
+	/* Not a candidate for swapping, so reclaim swap space. */
+	if (folio_test_swapcache(folio) &&
+		(mem_cgroup_swap_full(folio) || folio_test_mlocked(folio)))
+		folio_free_swap(folio);
+	VM_BUG_ON_FOLIO(folio_test_active(folio), folio);
+	if (!folio_test_mlocked(folio)) {
+		int type = folio_is_file_lru(folio);
+
+		folio_set_active(folio);
+		stat->nr_activate[type] += nr_pages;
+		count_memcg_folio_events(folio, PGACTIVATE, nr_pages);
+	}
+}
+
+static bool folio_free(struct folio *folio, struct folio_batch *free_folios,
+		struct scan_control *sc, struct reclaim_stat *stat)
+{
+	unsigned int nr_pages = folio_nr_pages(folio);
+	struct address_space *mapping = folio_mapping(folio);
+
+	/*
+	 * If the folio has buffers, try to free the buffer
+	 * mappings associated with this folio. If we succeed
+	 * we try to free the folio as well.
+	 *
+	 * We do this even if the folio is dirty.
+	 * filemap_release_folio() does not perform I/O, but it
+	 * is possible for a folio to have the dirty flag set,
+	 * but it is actually clean (all its buffers are clean).
+	 * This happens if the buffers were written out directly,
+	 * with submit_bh(). ext3 will do this, as well as
+	 * the blockdev mapping.  filemap_release_folio() will
+	 * discover that cleanness and will drop the buffers
+	 * and mark the folio clean - it can be freed.
+	 *
+	 * Rarely, folios can have buffers and no ->mapping.
+	 * These are the folios which were not successfully
+	 * invalidated in truncate_cleanup_folio().  We try to
+	 * drop those buffers here and if that worked, and the
+	 * folio is no longer mapped into process address space
+	 * (refcount == 1) it can be freed.  Otherwise, leave
+	 * the folio on the LRU so it is swappable.
+	 */
+	if (folio_needs_release(folio)) {
+		if (!filemap_release_folio(folio, sc->gfp_mask)) {
+			folio_active_bounce(folio, stat, nr_pages);
+			return false;
+		}
+
+		if (!mapping && folio_ref_count(folio) == 1) {
+			folio_unlock(folio);
+			if (folio_put_testzero(folio))
+				goto free_it;
+			else {
+				/*
+				 * rare race with speculative reference.
+				 * the speculative reference will free
+				 * this folio shortly, so we may
+				 * increment nr_reclaimed here (and
+				 * leave it off the LRU).
+				 */
+				stat->nr_reclaimed += nr_pages;
+				return true;
+			}
+		}
+	}
+
+	if (folio_test_lazyfree(folio)) {
+		/* follow __remove_mapping for reference */
+		if (!folio_ref_freeze(folio, 1))
+			return false;
+		/*
+		 * The folio has only one reference left, which is
+		 * from the isolation. After the caller puts the
+		 * folio back on the lru and drops the reference, the
+		 * folio will be freed anyway. It doesn't matter
+		 * which lru it goes on. So we don't bother checking
+		 * the dirty flag here.
+		 */
+		count_vm_events(PGLAZYFREED, nr_pages);
+		count_memcg_folio_events(folio, PGLAZYFREED, nr_pages);
+	} else if (!mapping || !__remove_mapping(mapping, folio, true,
+							sc->target_mem_cgroup))
+		return false;
+
+	folio_unlock(folio);
+free_it:
+	/*
+	 * Folio may get swapped out as a whole, need to account
+	 * all pages in it.
+	 */
+	stat->nr_reclaimed += nr_pages;
+
+	folio_unqueue_deferred_split(folio);
+	if (folio_batch_add(free_folios, folio) == 0) {
+		mem_cgroup_uncharge_folios(free_folios);
+		try_to_unmap_flush();
+		free_unref_folios(free_folios);
+	}
+	return true;
+}
+
+static void pageout_one(struct folio *folio, struct list_head *ret_folios,
+			struct folio_batch *free_folios,
+			struct scan_control *sc, struct reclaim_stat *stat,
+			struct swap_iocb **plug, struct list_head *folio_list)
+{
+	struct address_space *mapping = folio_mapping(folio);
+	unsigned int nr_pages = folio_nr_pages(folio);
+
+	switch (pageout(folio, mapping, plug, folio_list)) {
+	case PAGE_ACTIVATE:
+		/*
+		 * If shmem folio is split when writeback to swap,
+		 * the tail pages will make their own pass through
+		 * this function and be accounted then.
+		 */
+		if (nr_pages > 1 && !folio_test_large(folio)) {
+			sc->nr_scanned -= (nr_pages - 1);
+			nr_pages = 1;
+		}
+		folio_active_bounce(folio, stat, nr_pages);
+		fallthrough;
+	case PAGE_KEEP:
+		goto locked_keepit;
+	case PAGE_SUCCESS:
+		if (nr_pages > 1 && !folio_test_large(folio)) {
+			sc->nr_scanned -= (nr_pages - 1);
+			nr_pages = 1;
+		}
+		stat->nr_pageout += nr_pages;
+
+		if (folio_test_writeback(folio))
+			goto keepit;
+		if (folio_test_dirty(folio))
+			goto keepit;
+
+		/*
+		 * A synchronous write - probably a ramdisk.  Go
+		 * ahead and try to reclaim the folio.
+		 */
+		if (!folio_trylock(folio))
+			goto keepit;
+		if (folio_test_dirty(folio) ||
+			folio_test_writeback(folio))
+			goto locked_keepit;
+		mapping = folio_mapping(folio);
+		fallthrough;
+	case PAGE_CLEAN:
+		; /* try to free the folio below */
+	}
+	if (folio_free(folio, free_folios, sc, stat))
+		return;
+locked_keepit:
+	folio_unlock(folio);
+keepit:
+	list_add(&folio->lru, ret_folios);
+	VM_BUG_ON_FOLIO(folio_test_lru(folio) ||
+			folio_test_unevictable(folio), folio);
+}
 /*
- * shrink_folio_list() returns the number of reclaimed pages
+ * Reclaimed folios are counted in stat->nr_reclaimed.
  */
-static unsigned int shrink_folio_list(struct list_head *folio_list,
+static void shrink_folio_list(struct list_head *folio_list,
 		struct pglist_data *pgdat, struct scan_control *sc,
 		struct reclaim_stat *stat, bool ignore_references,
 		struct mem_cgroup *memcg)
@@ -1087,7 +1251,7 @@ static unsigned int shrink_folio_list(struct list_head *folio_list,
 	struct folio_batch free_folios;
 	LIST_HEAD(ret_folios);
 	LIST_HEAD(demote_folios);
-	unsigned int nr_reclaimed = 0, nr_demoted = 0;
+	unsigned int nr_demoted = 0;
 	unsigned int pgactivate = 0;
 	bool do_demote_pass;
 	struct swap_iocb *plug = NULL;
@@ -1421,126 +1585,15 @@ static unsigned int shrink_folio_list(struct list_head *folio_list,
 			 * starts and then write it out here.
 			 */
 			try_to_unmap_flush_dirty();
-			switch (pageout(folio, mapping, &plug, folio_list)) {
-			case PAGE_KEEP:
-				goto keep_locked;
-			case PAGE_ACTIVATE:
-				/*
-				 * If shmem folio is split when writeback to swap,
-				 * the tail pages will make their own pass through
-				 * this function and be accounted then.
-				 */
-				if (nr_pages > 1 && !folio_test_large(folio)) {
-					sc->nr_scanned -= (nr_pages - 1);
-					nr_pages = 1;
-				}
-				goto activate_locked;
-			case PAGE_SUCCESS:
-				if (nr_pages > 1 && !folio_test_large(folio)) {
-					sc->nr_scanned -= (nr_pages - 1);
-					nr_pages = 1;
-				}
-				stat->nr_pageout += nr_pages;
-
-				if (folio_test_writeback(folio))
-					goto keep;
-				if (folio_test_dirty(folio))
-					goto keep;
-
-				/*
-				 * A synchronous write - probably a ramdisk.  Go
-				 * ahead and try to reclaim the folio.
-				 */
-				if (!folio_trylock(folio))
-					goto keep;
-				if (folio_test_dirty(folio) ||
-				    folio_test_writeback(folio))
-					goto keep_locked;
-				mapping = folio_mapping(folio);
-				fallthrough;
-			case PAGE_CLEAN:
-				; /* try to free the folio below */
-			}
-		}
-
-		/*
-		 * If the folio has buffers, try to free the buffer
-		 * mappings associated with this folio. If we succeed
-		 * we try to free the folio as well.
-		 *
-		 * We do this even if the folio is dirty.
-		 * filemap_release_folio() does not perform I/O, but it
-		 * is possible for a folio to have the dirty flag set,
-		 * but it is actually clean (all its buffers are clean).
-		 * This happens if the buffers were written out directly,
-		 * with submit_bh(). ext3 will do this, as well as
-		 * the blockdev mapping.  filemap_release_folio() will
-		 * discover that cleanness and will drop the buffers
-		 * and mark the folio clean - it can be freed.
-		 *
-		 * Rarely, folios can have buffers and no ->mapping.
-		 * These are the folios which were not successfully
-		 * invalidated in truncate_cleanup_folio().  We try to
-		 * drop those buffers here and if that worked, and the
-		 * folio is no longer mapped into process address space
-		 * (refcount == 1) it can be freed.  Otherwise, leave
-		 * the folio on the LRU so it is swappable.
-		 */
-		if (folio_needs_release(folio)) {
-			if (!filemap_release_folio(folio, sc->gfp_mask))
-				goto activate_locked;
-			if (!mapping && folio_ref_count(folio) == 1) {
-				folio_unlock(folio);
-				if (folio_put_testzero(folio))
-					goto free_it;
-				else {
-					/*
-					 * rare race with speculative reference.
-					 * the speculative reference will free
-					 * this folio shortly, so we may
-					 * increment nr_reclaimed here (and
-					 * leave it off the LRU).
-					 */
-					nr_reclaimed += nr_pages;
-					continue;
-				}
-			}
+			pageout_one(folio, &ret_folios, &free_folios, sc, stat,
+				&plug, folio_list);
+			goto next;
 		}
 
-		if (folio_test_lazyfree(folio)) {
-			/* follow __remove_mapping for reference */
-			if (!folio_ref_freeze(folio, 1))
-				goto keep_locked;
-			/*
-			 * The folio has only one reference left, which is
-			 * from the isolation. After the caller puts the
-			 * folio back on the lru and drops the reference, the
-			 * folio will be freed anyway. It doesn't matter
-			 * which lru it goes on. So we don't bother checking
-			 * the dirty flag here.
-			 */
-			count_vm_events(PGLAZYFREED, nr_pages);
-			count_memcg_folio_events(folio, PGLAZYFREED, nr_pages);
-		} else if (!mapping || !__remove_mapping(mapping, folio, true,
-							 sc->target_mem_cgroup))
+		if (!folio_free(folio, &free_folios, sc, stat))
 			goto keep_locked;
-
-		folio_unlock(folio);
-free_it:
-		/*
-		 * Folio may get swapped out as a whole, need to account
-		 * all pages in it.
-		 */
-		nr_reclaimed += nr_pages;
-
-		folio_unqueue_deferred_split(folio);
-		if (folio_batch_add(&free_folios, folio) == 0) {
-			mem_cgroup_uncharge_folios(&free_folios);
-			try_to_unmap_flush();
-			free_unref_folios(&free_folios);
-		}
-		continue;
-
+		else
+			continue;
 activate_locked_split:
 		/*
 		 * The tail pages that are failed to add into swap cache
@@ -1551,29 +1604,21 @@ static unsigned int shrink_folio_list(struct list_head *folio_list,
 			nr_pages = 1;
 		}
 activate_locked:
-		/* Not a candidate for swapping, so reclaim swap space. */
-		if (folio_test_swapcache(folio) &&
-		    (mem_cgroup_swap_full(folio) || folio_test_mlocked(folio)))
-			folio_free_swap(folio);
-		VM_BUG_ON_FOLIO(folio_test_active(folio), folio);
-		if (!folio_test_mlocked(folio)) {
-			int type = folio_is_file_lru(folio);
-			folio_set_active(folio);
-			stat->nr_activate[type] += nr_pages;
-			count_memcg_folio_events(folio, PGACTIVATE, nr_pages);
-		}
+		folio_active_bounce(folio, stat, nr_pages);
 keep_locked:
 		folio_unlock(folio);
 keep:
 		list_add(&folio->lru, &ret_folios);
 		VM_BUG_ON_FOLIO(folio_test_lru(folio) ||
 				folio_test_unevictable(folio), folio);
+next:
+		continue;
 	}
 	/* 'folio_list' is always empty here */
 
 	/* Migrate folios selected for demotion */
 	nr_demoted = demote_folio_list(&demote_folios, pgdat, memcg);
-	nr_reclaimed += nr_demoted;
+	stat->nr_reclaimed += nr_demoted;
 	stat->nr_demoted += nr_demoted;
 	/* Folios that could not be demoted are still in @demote_folios */
 	if (!list_empty(&demote_folios)) {
@@ -1613,7 +1658,6 @@ static unsigned int shrink_folio_list(struct list_head *folio_list,
 
 	if (plug)
 		swap_write_unplug(plug);
-	return nr_reclaimed;
 }
 
 unsigned int reclaim_clean_pages_from_list(struct zone *zone,
@@ -1647,8 +1691,9 @@ unsigned int reclaim_clean_pages_from_list(struct zone *zone,
 	 * change in the future.
 	 */
 	noreclaim_flag = memalloc_noreclaim_save();
-	nr_reclaimed = shrink_folio_list(&clean_folios, zone->zone_pgdat, &sc,
+	shrink_folio_list(&clean_folios, zone->zone_pgdat, &sc,
 					&stat, true, NULL);
+	nr_reclaimed = stat.nr_reclaimed;
 	memalloc_noreclaim_restore(noreclaim_flag);
 
 	list_splice(&clean_folios, folio_list);
@@ -2017,8 +2062,8 @@ static unsigned long shrink_inactive_list(unsigned long nr_to_scan,
 	if (nr_taken == 0)
 		return 0;
 
-	nr_reclaimed = shrink_folio_list(&folio_list, pgdat, sc, &stat, false,
-					 lruvec_memcg(lruvec));
+	shrink_folio_list(&folio_list, pgdat, sc, &stat, false, lruvec_memcg(lruvec));
+	nr_reclaimed = stat.nr_reclaimed;
 
 	spin_lock_irq(&lruvec->lru_lock);
 	move_folios_to_lru(lruvec, &folio_list);
@@ -2195,7 +2240,8 @@ static unsigned int reclaim_folio_list(struct list_head *folio_list,
 		.no_demotion = 1,
 	};
 
-	nr_reclaimed = shrink_folio_list(folio_list, pgdat, &sc, &stat, true, NULL);
+	shrink_folio_list(folio_list, pgdat, &sc, &stat, true, NULL);
+	nr_reclaimed = stat.nr_reclaimed;
 	while (!list_empty(folio_list)) {
 		folio = lru_to_folio(folio_list);
 		list_del(&folio->lru);
@@ -4703,7 +4749,8 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 	if (list_empty(&list))
 		return scanned;
 retry:
-	reclaimed = shrink_folio_list(&list, pgdat, sc, &stat, false, memcg);
+	shrink_folio_list(&list, pgdat, sc, &stat, false, memcg);
+	reclaimed = stat.nr_reclaimed;
 	sc->nr.unqueued_dirty += stat.nr_unqueued_dirty;
 	sc->nr_reclaimed += reclaimed;
 	trace_mm_vmscan_lru_shrink_inactive(pgdat->node_id,

-- 
2.43.7

