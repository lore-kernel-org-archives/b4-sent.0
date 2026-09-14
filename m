From: Kairui Song <kasong@tencent.com>
Date: Tue, 15 Sep 2026 01:14:43 +0800
Subject: [PATCH v5 02/17] mm/huge_memory: fix rejection of swap cache
 folios with a mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-swap-thp-cleanup-v5-2-39878b37dfb0@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789406149; l=3844;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=os8GAwRhiIAeYozzDiYE5/qpjgUr240Y6fX1iEFFm7o=;
 b=x/Xr68PDIC2GidVJPvhZOkF4fMPuURDvqo9AMcQPkTXq+N/nZXOj+Qides9OL/uE6BsYnEoi0
 yp8AJJq1p7ZCESo/T6+fI8f/sEtTrNCP8wjue0YaiDEN6vRXpRmwBni
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A folio in the swap cache cannot be split if it has a mapping (shmem).
The split code does a defensive check for this in
__folio_freeze_and_split_unmapped, after the folio ref has been frozen
and the NR_SHMEM_THPS/NR_FILE_THPS counters have been decremented. It
rejects the split and returns -EINVAL without unfreezing the folio or
restoring the counters.

That error path is buggy, if it is ever taken. It leaves the folio
frozen and stuck, skews the counters, and fires the
VM_WARN_ON_ONCE_FOLIO for a state that is actually legitimate.

Check for this case up front in folio_check_splittable and return
-EBUSY before any state is modified, so the split routine always backs
out cleanly.

Also fix a bracket style issue that checkpatch.pl keeps complaining
about.

Fixes: 00527733d0dc ("mm/huge_memory: add two new (not yet used) functions for folio_split()")
Fixes: 714b056c8321 ("mm/huge_memory: convert VM_BUG* to VM_WARN* in __folio_split")
Reviewed-by: Zi Yan <ziy@nvidia.com>
Reviewed-by: Barry Song <baohua@kernel.org>
Acked-by: David Hildenbrand (Arm) <david@kernel.org>
Reviewed-by: Yeoreum Yun <yeoreum.yun@arm.com>
Reviewed-by: Kiryl Shutsemau (Meta) <kas@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 26 ++++++++++++++++----------
 1 file changed, 16 insertions(+), 10 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 7140a1031fb2..351e8893808b 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3934,6 +3934,9 @@ static int __split_unmapped_folio(struct folio *folio, int new_order,
 int folio_check_splittable(struct folio *folio, unsigned int new_order,
 			   enum split_type split_type)
 {
+	const bool is_anon = folio_test_anon(folio);
+	const bool is_swapcache = folio_test_swapcache(folio);
+
 	VM_WARN_ON_FOLIO(!folio_test_locked(folio), folio);
 	/*
 	 * Folios that just got truncated cannot get split. Signal to the
@@ -3942,11 +3945,11 @@ int folio_check_splittable(struct folio *folio, unsigned int new_order,
 	 * TODO: this will also currently refuse folios without a mapping in the
 	 * swapcache (shmem or to-be-anon folios).
 	 */
-	if (!folio->mapping && !folio_test_anon(folio))
+	if (!folio->mapping && !is_anon)
 		return -EBUSY;
 
 	/* order-1 is not supported for anonymous THP. */
-	if (folio_test_anon(folio) && new_order == 1)
+	if (is_anon && new_order == 1)
 		return -EINVAL;
 
 	/*
@@ -3957,7 +3960,7 @@ int folio_check_splittable(struct folio *folio, unsigned int new_order,
 	 * swapcache folio split. Only uniform split to order-0 can be used
 	 * here.
 	 */
-	if ((split_type == SPLIT_TYPE_NON_UNIFORM || new_order) && folio_test_swapcache(folio))
+	if ((split_type == SPLIT_TYPE_NON_UNIFORM || new_order) && is_swapcache)
 		return -EINVAL;
 
 	if (is_huge_zero_folio(folio))
@@ -3966,6 +3969,15 @@ int folio_check_splittable(struct folio *folio, unsigned int new_order,
 	if (folio_test_writeback(folio))
 		return -EBUSY;
 
+	/*
+	 * A non-anon swapcache folio that still has a mapping can only be a
+	 * shmem folio under SWAP IO, it's removed from either swap cache or
+	 * shmem mapping afterward. There is little benefit in splitting them
+	 * hence reject it here up front before touching anything.
+	 */
+	if (!is_anon && is_swapcache && folio->mapping)
+		return -EBUSY;
+
 	return 0;
 }
 
@@ -4038,14 +4050,8 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 			}
 		}
 
-		if (folio_test_swapcache(folio)) {
-			if (mapping) {
-				VM_WARN_ON_ONCE_FOLIO(mapping, folio);
-				return -EINVAL;
-			}
-
+		if (folio_test_swapcache(folio))
 			ci = swap_cluster_get_and_lock(folio);
-		}
 
 		/* lock lru list/PageCompound, ref frozen by page_ref_freeze */
 		if (do_lru)

-- 
2.55.0

