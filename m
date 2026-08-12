From: Kairui Song <kasong@tencent.com>
Date: Thu, 13 Aug 2026 02:48:46 +0800
Subject: [PATCH v2 06/17] mm/huge_memory: consolidate irq and locking for
 folio split
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-swap-thp-cleanup-v2-6-d2ee48c6aa49@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786560550; l=4783;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=i75VWCkQ8jK7NZAq0hH8d0si3JwG/+ahq4sLsBZtBsY=;
 b=YuXMwQdPjrVH7JhAsFv1+GMWhTDNt4GrjxOpz/CbWpY988UPpf/8oMJOsueu/u2QCWRxC7cMz
 rt1jsToN6BEB5bcR3qmcv1GzRJD+8v4jTXXnCXoUwhlStZkGHo/vOgq
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Let each split helper handle its own locking instead of relying on
the caller, so both helpers manage their own irq and locking state.
This lets __folio_split() drop its local irq handling and fail label,
preparing for further cleanup.

The file path now uses xas_lock_irq() instead of local_irq_disable()
with xas_lock(). The two are equivalent on non-RT, and
TRANSPARENT_HUGEPAGE cannot be enabled on RT anyway. This conversion
also buys consistency: every other place in mm/ that freezes a folio
while it is still reachable through the page cache already takes the
lock this way. This was actually the last plain xas_lock() on
mapping->i_pages left in mm. If we are going to support RT, spinning
on frozen folio refs could be a problem, but it already exists in
many places and should be fixed generically.

The anon helper keeps a single local_irq_disable() as before, because
it has to cover several plain spinlocks at once.

The dropped xas_reset() was a no-op as the xa_state is not walked
before the xas_load() under the lock.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 52 ++++++++++++++++++++++++----------------------------
 1 file changed, 24 insertions(+), 28 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index dfecb93dd64f..2cd53afac63e 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3958,6 +3958,8 @@ static int __folio_freeze_split_unmapped_anon(struct folio *folio, unsigned int
 	bool dequeue_deferred;
 	int ret = 0;
 
+	local_irq_disable();
+
 	/*
 	 * If this folio can be on the deferred split queue, lock out
 	 * the shrinker before freezing the ref. If the shrinker sees
@@ -3980,6 +3982,7 @@ static int __folio_freeze_split_unmapped_anon(struct folio *folio, unsigned int
 			list_lru_unlock(lru);
 			rcu_read_unlock();
 		}
+		local_irq_enable();
 		return -EAGAIN;
 	}
 
@@ -4028,6 +4031,7 @@ static int __folio_freeze_split_unmapped_anon(struct folio *folio, unsigned int
 		lruvec_unlock(lruvec);
 	if (ci)
 		swap_cluster_unlock(ci);
+	local_irq_enable();
 
 	return ret;
 }
@@ -4043,8 +4047,21 @@ static int __folio_freeze_split_unmapped_file(struct folio *folio, unsigned int
 	struct lruvec *lruvec;
 	int ret;
 
-	if (!folio_ref_freeze(folio, folio_cache_ref_count(folio) + 1))
-		return -EAGAIN;
+	xas_lock_irq(xas);
+
+	/*
+	 * Check if the folio is present in page cache.
+	 * We assume all tail are present too, if folio is there.
+	 */
+	if (xas_load(xas) != folio) {
+		ret = -EAGAIN;
+		goto fail;
+	}
+
+	if (!folio_ref_freeze(folio, folio_cache_ref_count(folio) + 1)) {
+		ret = -EAGAIN;
+		goto fail;
+	}
 
 	if (folio_test_pmd_mappable(folio) &&
 	    new_order < HPAGE_PMD_ORDER) {
@@ -4112,6 +4129,8 @@ static int __folio_freeze_split_unmapped_file(struct folio *folio, unsigned int
 	if (do_lru)
 		lruvec_unlock(lruvec);
 
+fail:
+	xas_unlock_irq(xas);
 	return ret;
 }
 
@@ -4251,19 +4270,7 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 
 	unmap_folio(folio);
 
-	/* block interrupt reentry in xa_lock and spinlock */
-	local_irq_disable();
-	if (mapping) {
-		/*
-		 * Check if the folio is present in page cache.
-		 * We assume all tail are present too, if folio is there.
-		 */
-		xas_lock(&xas);
-		xas_reset(&xas);
-		if (xas_load(&xas) != folio) {
-			ret = -EAGAIN;
-			goto fail;
-		}
+	if (!is_anon) {
 		ret = __folio_freeze_split_unmapped_file(folio, new_order, split_at, &xas, mapping,
 							 true, list, split_type, end,
 							 &nr_shmem_dropped);
@@ -4272,12 +4279,6 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 							 list, split_type);
 	}
 
-fail:
-	if (mapping)
-		xas_unlock(&xas);
-
-	local_irq_enable();
-
 	if (nr_shmem_dropped)
 		shmem_uncharge(mapping->host, nr_shmem_dropped);
 
@@ -4360,8 +4361,6 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
  */
 int folio_split_unmapped(struct folio *folio, unsigned int new_order)
 {
-	int ret = 0;
-
 	VM_WARN_ON_ONCE_FOLIO(folio_mapped(folio), folio);
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_locked(folio), folio);
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_large(folio), folio);
@@ -4370,11 +4369,8 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
 	if (folio_expected_ref_count(folio) != folio_ref_count(folio) - 1)
 		return -EAGAIN;
 
-	local_irq_disable();
-	ret = __folio_freeze_split_unmapped_anon(folio, new_order, &folio->page,
-						 false, NULL, SPLIT_TYPE_UNIFORM);
-	local_irq_enable();
-	return ret;
+	return __folio_freeze_split_unmapped_anon(folio, new_order, &folio->page,
+						  false, NULL, SPLIT_TYPE_UNIFORM);
 }
 
 /*

-- 
2.55.0

