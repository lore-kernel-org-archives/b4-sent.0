From: Kairui Song <kasong@tencent.com>
Date: Thu, 13 Aug 2026 02:48:48 +0800
Subject: [PATCH v2 08/17] mm/huge_memory: move unmap and remap into the
 split helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-swap-thp-cleanup-v2-8-d2ee48c6aa49@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786560550; l=5602;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=JtWm25Dng3Mhqkcbs3f3Xwf56RRf8KwYB3EpO59ZokM=;
 b=INsZYrdAKljYMMdiEFr1eEUKBxnFmja12VRs97CQi/tVlEjpCg2GFaxG0LDMQC+l32JNFp5Tt
 GQVahCVb+KaAYlEBqvcMDK1kOB45i/Jiz2dtSIGig14Y92NW0hvM+zr
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To prepare for further cleanup, move the unmap/remap handling from
__folio_split() into the split helpers.  Only anon folios need to
be remapped, so remap_page() is now only called for anon splits and
the anon check in remap_page() is redundant and can be removed.

Reviewed-by: Zi Yan <ziy@nvidia.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 58 ++++++++++++++++++++++++++++++--------------------------
 1 file changed, 31 insertions(+), 27 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 43093b9a5bca..aa10a13bc255 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3589,9 +3589,6 @@ static void remap_page(struct folio *folio, unsigned long nr, int flags)
 {
 	int i = 0;
 
-	/* If unmap_folio() uses try_to_migrate() on file, remove this check */
-	if (!folio_test_anon(folio))
-		return;
 	for (;;) {
 		remove_migration_ptes(folio, folio, TTU_RMAP_LOCKED | flags);
 		i += folio_nr_pages(folio);
@@ -3945,19 +3942,23 @@ static unsigned int folio_cache_ref_count(const struct folio *folio)
 	return folio_nr_pages(folio);
 }
 
-static int __folio_freeze_split_unmapped_anon(struct folio *folio, unsigned int new_order,
-					      struct page *split_at, bool do_lru,
-					      struct list_head *list, enum split_type split_type)
+static int __folio_split_unmap_and_freeze_anon(struct folio *folio, unsigned int new_order,
+					       struct page *split_at, bool do_lru, bool unmap,
+					       struct list_head *list, enum split_type split_type)
 {
 	struct folio *end_folio = folio_next(folio);
 	struct swap_cluster_info *ci = NULL;
 	struct folio *new_folio, *next;
 	int old_order = folio_order(folio);
+	enum ttu_flags ttu_flags = 0;
 	struct list_lru_one *lru;
 	struct lruvec *lruvec;
 	bool dequeue_deferred;
 	int ret = 0;
 
+	if (unmap)
+		unmap_folio(folio);
+
 	local_irq_disable();
 
 	/*
@@ -3982,8 +3983,8 @@ static int __folio_freeze_split_unmapped_anon(struct folio *folio, unsigned int
 			list_lru_unlock(lru);
 			rcu_read_unlock();
 		}
-		local_irq_enable();
-		return -EAGAIN;
+		ret = -EAGAIN;
+		goto out_no_split;
 	}
 
 	if (dequeue_deferred) {
@@ -4031,15 +4032,21 @@ static int __folio_freeze_split_unmapped_anon(struct folio *folio, unsigned int
 		lruvec_unlock(lruvec);
 	if (ci)
 		swap_cluster_unlock(ci);
+out_no_split:
 	local_irq_enable();
+	if (unmap) {
+		if (!ret && !folio_is_device_private(folio))
+			ttu_flags = TTU_USE_SHARED_ZEROPAGE;
+		remap_page(folio, 1 << old_order, ttu_flags);
+	}
 
 	return ret;
 }
 
-static int __folio_freeze_split_unmapped_file(struct folio *folio, unsigned int new_order,
-					      struct page *split_at, struct xa_state *xas,
-					      struct address_space *mapping, bool do_lru,
-					      struct list_head *list, enum split_type split_type)
+static int __folio_split_unmap_and_freeze_file(struct folio *folio, unsigned int new_order,
+					       struct page *split_at, struct xa_state *xas,
+					       struct address_space *mapping, bool do_lru,
+					       struct list_head *list, enum split_type split_type)
 {
 	struct folio *end_folio = folio_next(folio);
 	struct folio *new_folio, *next;
@@ -4059,6 +4066,8 @@ static int __folio_freeze_split_unmapped_file(struct folio *folio, unsigned int
 	if (shmem_mapping(mapping))
 		end = shmem_fallocend(mapping->host, end);
 
+	unmap_folio(folio);
+
 	xas_lock_irq(xas);
 
 	/*
@@ -4139,8 +4148,11 @@ static int __folio_freeze_split_unmapped_file(struct folio *folio, unsigned int
 
 	if (do_lru)
 		lruvec_unlock(lruvec);
-
 fail:
+	/*
+	 * If we want to use try_to_migrate() on file in unmap_folio,
+	 * remember to add remap_page() and adapt it.
+	 */
 	xas_unlock_irq(xas);
 	if (nr_shmem_dropped)
 		shmem_uncharge(mapping->host, nr_shmem_dropped);
@@ -4180,7 +4192,6 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 	struct anon_vma *anon_vma = NULL;
 	int old_order = folio_order(folio);
 	struct folio *new_folio, *next;
-	enum ttu_flags ttu_flags = 0;
 	int ret;
 
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_locked(folio), folio);
@@ -4268,21 +4279,14 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		goto out_unlock;
 	}
 
-	unmap_folio(folio);
-
 	if (!is_anon) {
-		ret = __folio_freeze_split_unmapped_file(folio, new_order, split_at, &xas, mapping,
-							 true, list, split_type);
+		ret = __folio_split_unmap_and_freeze_file(folio, new_order, split_at, &xas, mapping,
+							  true, list, split_type);
 	} else {
-		ret = __folio_freeze_split_unmapped_anon(folio, new_order, split_at, true,
-							 list, split_type);
+		ret = __folio_split_unmap_and_freeze_anon(folio, new_order, split_at, true,
+							  true, list, split_type);
 	}
 
-	if (!ret && is_anon && !folio_is_device_private(folio))
-		ttu_flags = TTU_USE_SHARED_ZEROPAGE;
-
-	remap_page(folio, 1 << old_order, ttu_flags);
-
 	/*
 	 * Drop the mapping while the inode is still pinned. @folio stays
 	 * locked and present in the page cache until the loop below, so
@@ -4365,8 +4369,8 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
 	if (folio_expected_ref_count(folio) != folio_ref_count(folio) - 1)
 		return -EAGAIN;
 
-	return __folio_freeze_split_unmapped_anon(folio, new_order, &folio->page,
-						  false, NULL, SPLIT_TYPE_UNIFORM);
+	return __folio_split_unmap_and_freeze_anon(folio, new_order, &folio->page, false,
+						   false, NULL, SPLIT_TYPE_UNIFORM);
 }
 
 /*

-- 
2.55.0

