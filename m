From: Kairui Song <kasong@tencent.com>
Date: Thu, 13 Aug 2026 02:48:51 +0800
Subject: [PATCH v2 11/17] mm/huge_memory: allow splitting mappingless swap
 cache folios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-swap-thp-cleanup-v2-11-d2ee48c6aa49@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786560551; l=5578;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=axzIDmGBd7lK34RIiiCkCmxGB/OY8kzRuNR2iFyLEgA=;
 b=VVfsDpjhS3AuyTbgJ0R3IWwvcbxW474xxgRHBGP/ufz+aIPrjhmq1f0/CY7W8J4qxugU0Nlt8
 iPMsmlMN09zDy48pXfrnTWeWKR9e3BjuYT3OB0USmlvBZznCJwl0hmc
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Lift the restriction that kept swap cache folios without a mapping
from being split.  All the underlying infrastructure is sound against
that with a few more tweaks, no reason to block it anymore.

Also rename the split helper, which now handles mappingless swap
cache folios that are yet to be anon, or may actually belong to
shmem.  In either case there is not much difference in how they would
be split.

A non-anon swap cache folio that still has a mapping (e.g. a shmem
swap cache folio) remains rejected up front: it would need both its
page cache and swap cache entries updated on split, which the split
helpers do not do, and there would be little benefit in doing so.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 40 +++++++++++++++++++++++-----------------
 1 file changed, 23 insertions(+), 17 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 29b46f039d1e..67401c58794e 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3893,12 +3893,10 @@ int folio_check_splittable(struct folio *folio, unsigned int new_order,
 	VM_WARN_ON_FOLIO(!folio_test_locked(folio), folio);
 	/*
 	 * Folios that just got truncated cannot get split. Signal to the
-	 * caller that there was a race.
-	 *
-	 * TODO: this will also currently refuse folios without a mapping in the
-	 * swapcache (shmem or to-be-anon folios).
+	 * caller that there was a race. A mappingless swap cache folio
+	 * has no page cache entries to update, so it is fine to split.
 	 */
-	if (!folio->mapping && !is_anon)
+	if (!folio->mapping && !is_swapcache)
 		return -EBUSY;
 
 	/* order-1 is not supported for anonymous THP. */
@@ -3942,11 +3940,12 @@ static unsigned int folio_cache_ref_count(const struct folio *folio)
 	return folio_nr_pages(folio);
 }
 
-static int __folio_split_unmap_and_freeze_anon(struct folio *folio, unsigned int new_order,
-					       struct page *split_at, bool do_lru, bool unmap,
-					       struct list_head *list, enum split_type split_type)
+static int __folio_split_unmap_and_freeze(struct folio *folio, unsigned int new_order,
+					  struct page *split_at, bool do_lru, bool anon_unmap,
+					  struct list_head *list, enum split_type split_type)
 {
 	struct folio *end_folio = folio_next(folio);
+	bool is_anon = folio_test_anon(folio);
 	struct swap_cluster_info *ci = NULL;
 	struct folio *new_folio, *next;
 	int old_order = folio_order(folio);
@@ -3964,7 +3963,7 @@ static int __folio_split_unmap_and_freeze_anon(struct folio *folio, unsigned int
 	 * similar to folio_lock_anon_vma_read() except the write lock is
 	 * taken to serialize against parallel split or collapse.
 	 */
-	if (unmap) {
+	if (anon_unmap) {
 		anon_vma = folio_get_anon_vma(folio);
 		if (!anon_vma)
 			return -EBUSY;
@@ -3977,7 +3976,7 @@ static int __folio_split_unmap_and_freeze_anon(struct folio *folio, unsigned int
 		goto out_unlock;
 	}
 
-	if (unmap)
+	if (anon_unmap)
 		unmap_folio(folio);
 
 	local_irq_disable();
@@ -3988,8 +3987,11 @@ static int __folio_split_unmap_and_freeze_anon(struct folio *folio, unsigned int
 	 * a 0-ref folio, it assumes it beat folio_put() to the list
 	 * lock and must clean up the LRU state - the same dequeue we
 	 * will do below as part of the split.
+	 *
+	 * Only anon folios are ever queued on the deferred split list,
+	 * so non-anon folios (mappingless swapcache) never need dequeuing.
 	 */
-	dequeue_deferred = old_order > 1;
+	dequeue_deferred = old_order > 1 && is_anon;
 	if (dequeue_deferred) {
 		struct mem_cgroup *memcg;
 
@@ -4055,13 +4057,13 @@ static int __folio_split_unmap_and_freeze_anon(struct folio *folio, unsigned int
 		swap_cluster_unlock(ci);
 out_no_split:
 	local_irq_enable();
-	if (unmap) {
+	if (anon_unmap) {
 		if (!ret && !folio_is_device_private(folio))
 			ttu_flags = TTU_USE_SHARED_ZEROPAGE;
 		remap_page(folio, 1 << old_order, ttu_flags);
 	}
 out_unlock:
-	if (anon_vma) {
+	if (anon_unmap) {
 		anon_vma_unlock_write(anon_vma);
 		put_anon_vma(anon_vma);
 	}
@@ -4265,6 +4267,7 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		struct page *split_at, struct page *lock_at,
 		struct list_head *list, enum split_type split_type)
 {
+	bool is_swapcache = folio_test_swapcache(folio);
 	struct folio *end_folio = folio_next(folio);
 	bool is_anon = folio_test_anon(folio);
 	int old_order = folio_order(folio);
@@ -4291,8 +4294,11 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 	}
 
 	if (is_anon)
-		ret = __folio_split_unmap_and_freeze_anon(folio, new_order, split_at, true,
-							  true, list, split_type);
+		ret = __folio_split_unmap_and_freeze(folio, new_order, split_at, true,
+						     true, list, split_type);
+	else if (is_swapcache)
+		ret = __folio_split_unmap_and_freeze(folio, new_order, split_at, true,
+						     false, list, split_type);
 	else
 		ret = __folio_split_unmap_and_freeze_file(folio, new_order, split_at,
 							  true, list, split_type);
@@ -4352,8 +4358,8 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_large(folio), folio);
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_anon(folio), folio);
 
-	return __folio_split_unmap_and_freeze_anon(folio, new_order, &folio->page, false,
-						   false, NULL, SPLIT_TYPE_UNIFORM);
+	return __folio_split_unmap_and_freeze(folio, new_order, &folio->page, false,
+					      false, NULL, SPLIT_TYPE_UNIFORM);
 }
 
 /*

-- 
2.55.0

