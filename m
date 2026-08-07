From: Kairui Song <kasong@tencent.com>
Date: Sat, 08 Aug 2026 05:17:11 +0800
Subject: [PATCH RFC 10/13] mm/huge_memory: allow splitting mappingless swap
 cache folios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-swap-thp-cleanup-v1-10-689939a7ccc3@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786137467; l=5534;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=RlM8mpHFdOY4ZKngaHLh0+gwh65R/G4errquU7C7PiU=;
 b=MDqPUHQlHc8YqRsgbFOiw/gs+clVxgCEnHoReVoVTyTkxhaAB4NXX3KxsTtkkEa6Yz3qns2nk
 DzI/Sd7a3E6DfST1h2ASXmwqXdemTCpnhxl4nCsz0a3lS1sJqa06qma
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
index ab2bb29748d3..b80d0db63225 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3881,12 +3881,10 @@ int folio_check_splittable(struct folio *folio, unsigned int new_order,
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
@@ -3931,11 +3929,12 @@ static unsigned int folio_cache_ref_count(const struct folio *folio)
 	return folio_nr_pages(folio);
 }
 
-static int __folio_freeze_split_unmap_anon(struct folio *folio, unsigned int new_order,
-					   struct page *split_at, bool do_lru, bool unmap,
-					   struct list_head *list, enum split_type split_type)
+static int __folio_freeze_split_unmap(struct folio *folio, unsigned int new_order,
+				      struct page *split_at, bool do_lru, bool anon_unmap,
+				      struct list_head *list, enum split_type split_type)
 {
 	struct folio *end_folio = folio_next(folio);
+	bool is_anon = folio_test_anon(folio);
 	struct swap_cluster_info *ci = NULL;
 	struct folio *new_folio;
 	int old_order = folio_order(folio);
@@ -3953,7 +3952,7 @@ static int __folio_freeze_split_unmap_anon(struct folio *folio, unsigned int new
 	 * similar to folio_lock_anon_vma_read() except the write lock is
 	 * taken to serialize against parallel split or collapse.
 	 */
-	if (unmap) {
+	if (anon_unmap) {
 		anon_vma = folio_get_anon_vma(folio);
 		if (!anon_vma)
 			return -EBUSY;
@@ -3966,7 +3965,7 @@ static int __folio_freeze_split_unmap_anon(struct folio *folio, unsigned int new
 		goto out_unlock;
 	}
 
-	if (unmap)
+	if (anon_unmap)
 		unmap_folio(folio);
 
 	local_irq_disable();
@@ -3977,8 +3976,11 @@ static int __folio_freeze_split_unmap_anon(struct folio *folio, unsigned int new
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
 
@@ -4047,13 +4049,13 @@ static int __folio_freeze_split_unmap_anon(struct folio *folio, unsigned int new
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
@@ -4257,6 +4259,7 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		struct page *split_at, struct page *lock_at,
 		struct list_head *list, enum split_type split_type)
 {
+	bool is_swapcache = folio_test_swapcache(folio);
 	struct folio *end_folio = folio_next(folio);
 	bool is_anon = folio_test_anon(folio);
 	int old_order = folio_order(folio);
@@ -4283,8 +4286,11 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 	}
 
 	if (is_anon)
-		ret = __folio_freeze_split_unmap_anon(folio, new_order, split_at, true,
-						      true, list, split_type);
+		ret = __folio_freeze_split_unmap(folio, new_order, split_at, true,
+						 true, list, split_type);
+	else if (is_swapcache)
+		ret = __folio_freeze_split_unmap(folio, new_order, split_at, true,
+						 false, list, split_type);
 	else
 		ret = __folio_freeze_split_unmap_file(folio, new_order, split_at,
 						      true, list, split_type);
@@ -4344,8 +4350,8 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_large(folio), folio);
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_anon(folio), folio);
 
-	return __folio_freeze_split_unmap_anon(folio, new_order, &folio->page, false,
-					       false, NULL, SPLIT_TYPE_UNIFORM);
+	return __folio_freeze_split_unmap(folio, new_order, &folio->page, false,
+					  false, NULL, SPLIT_TYPE_UNIFORM);
 }
 
 /*

-- 
2.55.0

