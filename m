From: Kairui Song <kasong@tencent.com>
Date: Tue, 15 Sep 2026 01:14:47 +0800
Subject: [PATCH v5 06/17] mm/huge_memory: consolidate irq and locking for
 folio split
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-swap-thp-cleanup-v5-6-39878b37dfb0@tencent.com>
References: <20260915-swap-thp-cleanup-v5-0-39878b37dfb0@tencent.com>
In-Reply-To: <20260915-swap-thp-cleanup-v5-0-39878b37dfb0@tencent.com>
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
 Yeoreum Yun <yeoreum.yun@arm.com>, 
 "Kiryl Shutsemau (Meta)" <kas@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>, Kairui Song <kasong@tencent.com>, 
 Kairui Song <ryncsn@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789406149; l=4898;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=9nADEDAf7Q9o9bXChgiHRbBnW7jE6WqRyVFeq9s3Ky0=;
 b=03mBbAMWRAHMpV7mScz8iM+udOGiUuGVdjnxWdWseAaIHfdPl7Iv3bMw/akl6nNTGxkjw4FWx
 TwBHbqINGedCi2EC3lsm3zWPq7OC7McZmGyyaBUcB4nwGRvpu8c9i3p
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

Reviewed-by: Zi Yan <ziy@nvidia.com>
Reviewed-by: Kiryl Shutsemau (Meta) <kas@kernel.org>
Reviewed-by: Yeoreum Yun <yeoreum.yun@arm.com>
Acked-by: David Hildenbrand (Arm) <david@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 58 ++++++++++++++++++++++++++------------------------------
 1 file changed, 27 insertions(+), 31 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 35c48eaf038f..d0e2f1801d6f 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4021,8 +4021,12 @@ static int __folio_freeze_split_anon(struct folio *folio,
 	struct lruvec *lruvec;
 	int ret = 0;
 
-	if (!folio_ref_freeze(folio, folio_cache_ref_count(folio) + 1))
+	local_irq_disable();
+
+	if (!folio_ref_freeze(folio, folio_cache_ref_count(folio) + 1)) {
+		local_irq_enable();
 		return -EAGAIN;
+	}
 
 	/* Take off the deferred split queue while frozen and memcg set */
 	folio_unqueue_deferred_split(folio);
@@ -4070,6 +4074,7 @@ static int __folio_freeze_split_anon(struct folio *folio,
 		lruvec_unlock(lruvec);
 	if (ci)
 		swap_cluster_unlock(ci);
+	local_irq_enable();
 
 	return ret;
 }
@@ -4088,8 +4093,21 @@ static int __folio_freeze_split_file(struct folio *folio,
 	/* Currently device private folios can only back anonymous memory. */
 	VM_WARN_ON_ONCE_FOLIO(folio_is_device_private(folio), folio);
 
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
@@ -4161,6 +4179,8 @@ static int __folio_freeze_split_file(struct folio *folio,
 	if (do_lru)
 		lruvec_unlock(lruvec);
 
+fail:
+	xas_unlock_irq(xas);
 	return ret;
 }
 
@@ -4300,32 +4320,13 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 
 	unmap_folio(folio);
 
-	/* block interrupt reentry in xa_lock and spinlock */
-	local_irq_disable();
-	if (is_anon) {
+	if (is_anon)
 		ret = __folio_freeze_split_anon(folio, new_order, split_at,
 						true, list, split_type);
-	} else {
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
+	else
 		ret = __folio_freeze_split_file(folio, new_order, split_at, &xas, mapping,
 						true, list, split_type, end,
 						&nr_shmem_dropped);
-	}
-
-fail:
-	if (mapping)
-		xas_unlock(&xas);
-
-	local_irq_enable();
 
 	if (nr_shmem_dropped)
 		shmem_uncharge(mapping->host, nr_shmem_dropped);
@@ -4409,8 +4410,6 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
  */
 int folio_split_unmapped(struct folio *folio, unsigned int new_order)
 {
-	int ret = 0;
-
 	VM_WARN_ON_ONCE_FOLIO(folio_mapped(folio), folio);
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_locked(folio), folio);
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_large(folio), folio);
@@ -4419,11 +4418,8 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
 	if (folio_expected_ref_count(folio) != folio_ref_count(folio) - 1)
 		return -EAGAIN;
 
-	local_irq_disable();
-	ret = __folio_freeze_split_anon(folio, new_order, &folio->page,
-					false, NULL, SPLIT_TYPE_UNIFORM);
-	local_irq_enable();
-	return ret;
+	return __folio_freeze_split_anon(folio, new_order, &folio->page,
+					 false, NULL, SPLIT_TYPE_UNIFORM);
 }
 
 /*

-- 
2.55.0

