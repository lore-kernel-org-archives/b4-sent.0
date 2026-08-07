From: Kairui Song <kasong@tencent.com>
Date: Sat, 08 Aug 2026 05:17:03 +0800
Subject: [PATCH RFC 02/13] mm/huge_memory: fix rejection of swap cache
 folios with a mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-swap-thp-cleanup-v1-2-689939a7ccc3@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786137467; l=3532;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=CYIc1grENaJdW23IuxAR2mIbHqlN5p0Qzr5lTwIiQZc=;
 b=vj4vHBRaXAz7etIULkvV5Z9u1GthgAv8ww+CrE7FRqFWnH9VEyTBmFrzx4yZFf+ogRTl2aZwi
 kvK0TKpok5OCsScuovbsRcozYfPLcz2WQHypWq0BmnDk24bUVXuYs+I
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A folio in the swap cache cannot be split if it has a mapping (shmem).
The split code only checks for this in __folio_freeze_and_split_unmapped,
after the folio ref has been frozen and the NR_SHMEM_THPS/NR_FILE_THPS
counters have been decremented, and returns -EINVAL without unfreezing
the folio or restoring the counters. That error path is fragile: if it
is ever taken, the folio is left frozen and stuck, the counters are
skewed, and the VM_WARN_ON_ONCE_FOLIO would fire for a state that is
actually legitimate.

Check for this case up front in folio_check_splittable and return
-EINVAL before any state is modified. Under DEBUG_VM, the existing
"Tried to split an unsplittable folio" warning in __folio_split
reports the rejection.

Fixes: 00527733d0dc ("mm/huge_memory: add two new (not yet used) functions for folio_split()")
Fixes: 714b056c8321 ("mm/huge_memory: convert VM_BUG* to VM_WARN* in __folio_split")
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 26 ++++++++++++++++----------
 1 file changed, 16 insertions(+), 10 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index ced400f72d43..2fa72158e063 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3878,6 +3878,9 @@ static int __split_unmapped_folio(struct folio *folio, int new_order,
 int folio_check_splittable(struct folio *folio, unsigned int new_order,
 			   enum split_type split_type)
 {
+	bool is_anon = folio_test_anon(folio);
+	bool is_swapcache = folio_test_swapcache(folio);
+
 	VM_WARN_ON_FOLIO(!folio_test_locked(folio), folio);
 	/*
 	 * Folios that just got truncated cannot get split. Signal to the
@@ -3886,11 +3889,11 @@ int folio_check_splittable(struct folio *folio, unsigned int new_order,
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
@@ -3901,7 +3904,7 @@ int folio_check_splittable(struct folio *folio, unsigned int new_order,
 	 * swapcache folio split. Only uniform split to order-0 can be used
 	 * here.
 	 */
-	if ((split_type == SPLIT_TYPE_NON_UNIFORM || new_order) && folio_test_swapcache(folio)) {
+	if ((split_type == SPLIT_TYPE_NON_UNIFORM || new_order) && is_swapcache) {
 		return -EINVAL;
 	}
 
@@ -3911,6 +3914,15 @@ int folio_check_splittable(struct folio *folio, unsigned int new_order,
 	if (folio_test_writeback(folio))
 		return -EBUSY;
 
+	/*
+	 * A non-anon swapcache folio that still has a mapping should only
+	 * be a shmem folio under IO, there is little benefit in splitting
+	 * them hence not supported. Reject it here up front: the split
+	 * routine cannot back out cleanly once the folio ref is frozen.
+	 */
+	if (!is_anon && is_swapcache && folio->mapping)
+		return -EINVAL;
+
 	return 0;
 }
 
@@ -3983,14 +3995,8 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
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

