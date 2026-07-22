From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 22 Jul 2026 16:41:13 -0700
Subject: [PATCH v4 05/16] mm: hugetlb: Fix subpool usage leak on allocation
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-hugetlb-alloc-failure-fixes-v4-5-88e8b81970dc@google.com>
References: <20260722-hugetlb-alloc-failure-fixes-v4-0-88e8b81970dc@google.com>
In-Reply-To: <20260722-hugetlb-alloc-failure-fixes-v4-0-88e8b81970dc@google.com>
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Nhat Pham <nphamcs@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Peter Xu <peterx@redhat.com>, 
 Wupeng Ma <mawupeng1@huawei.com>, fvdl@google.com, rientjes@google.com, 
 jthoughton@google.com, Mike Kravetz <mike.kravetz@oracle.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Alex Shi <alexs@kernel.org>, 
 Yanteng Si <si.yanteng@linux.dev>, Dongliang Mu <dzm91@hust.edu.cn>, 
 Hongxiang Lou <louhongxiang@huawei.com>, Miaohe Lin <linmiaohe@huawei.com>
Cc: vannapurve@google.com, erdemaktas@google.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 linux-doc@vger.kernel.org, Ackerley Tng <ackerleytng@google.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784763678; l=4429;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=aioziCwNl1YhUSW9QJsopoiM0FNET1b5J61jDqmRBgE=;
 b=EgFMKfYcEA2o7aDdaYSsd6UI7TTvR5GAm70ONUg9KMMDn45zAWhKmQCqMLfU8tl73gxpDjjB4
 l7LDr/Y+kTGDj3eEZeDlBJW0M2vKZYYopIAGmS2bhziu7J6FHpt5CR0
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When alloc_hugetlb_folio() fails early (e.g. buddy allocation failure or
hugetlb cgroup charging failure) and gbl_chg == 1 (meaning a reservation
was not used, but a global page was allocated instead), the subpool page
acquired via hugepage_subpool_get_pages() must still be returned.

Currently, the error path out_subpool_put: only calls
hugepage_subpool_put_pages() if !gbl_chg is true. If gbl_chg is 1, it
skips it, permanently leaking the subpool's used_hpages counter.

With the earlier patch to always track used_hpages in the subpool, always
call hugepage_subpool_put_pages() if map_chg is true to consistently
restore the page to the subpool. Condition on map_chg because map_chg also
gates hugepage_subpool_get_pages().

Opportunistically rename gbl_chg to gbl_resv_get, which is the number of
global pages needed (because neither resv_map nor subpool reservations
could be used).

If the number of global pages needed is 0, this allocation uses a
reservation somewhere, hence proceed to consume a reservation by
decrementing h->resv_huge_pages. If the number of global pages needed is 1,
reservations are neither created nor consumed.

Also rename gbl_reserve to gbl_resv_put, which is the number of
pages the subpool could not absorb into its reservations.

Adjust global reservations using hugetlb_acct_memory() with the difference
between gbl_resv_get and gbl_resv_put to take care of possible races where
another thread might have performed get or put with the same subpool, hence
perhaps requiring updates to global reservation counts. (If gbl_resv_get ==
0 because a resv_map reservation was used, map_chg == 0 so the entire
subpool returning is skipped - still correct.)

Fixes: a833a693a490e ("mm: hugetlb: fix incorrect fallback for subpool")
Cc: stable@vger.kernel.org
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 mm/hugetlb.c | 23 ++++++++++-------------
 1 file changed, 10 insertions(+), 13 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 5ee1bc5c00bfe..879e4640dc50d 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -2872,7 +2872,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	struct hugepage_subpool *spool = subpool_vma(vma);
 	struct hstate *h = hstate_vma(vma);
 	struct folio *folio;
-	long retval, gbl_chg, gbl_reserve;
+	long retval, gbl_resv_get;
 	map_chg_state map_chg;
 	int ret, idx;
 	struct hugetlb_cgroup *h_cg = NULL;
@@ -2912,15 +2912,15 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	 * Or if it can get one from the pool reservation directly.
 	 */
 	if (map_chg) {
-		gbl_chg = hugepage_subpool_get_pages(spool, 1);
-		if (gbl_chg < 0)
+		gbl_resv_get = hugepage_subpool_get_pages(spool, 1);
+		if (gbl_resv_get < 0)
 			goto out_end_reservation;
 	} else {
 		/*
 		 * If we have the vma reservation ready, no need for extra
 		 * global reservation.
 		 */
-		gbl_chg = 0;
+		gbl_resv_get = 0;
 	}
 
 	/*
@@ -2949,7 +2949,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	 * from the global free pool (global change).  gbl_chg == 0 indicates
 	 * a reservation exists for the allocation.
 	 */
-	folio = dequeue_hugetlb_folio_vma(h, vma, addr, gbl_chg);
+	folio = dequeue_hugetlb_folio_vma(h, vma, addr, gbl_resv_get);
 	if (!folio) {
 		spin_unlock_irq(&hugetlb_lock);
 		folio = alloc_buddy_hugetlb_folio_with_mpol(h, vma, addr);
@@ -2965,7 +2965,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	 * Either dequeued or buddy-allocated folio needs to add special
 	 * mark to the folio when it consumes a global reservation.
 	 */
-	if (!gbl_chg) {
+	if (!gbl_resv_get) {
 		folio_set_hugetlb_restore_reserve(folio);
 		h->resv_huge_pages--;
 	}
@@ -3022,13 +3022,10 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		hugetlb_cgroup_uncharge_cgroup_rsvd(idx, pages_per_huge_page(h),
 						    h_cg_rsvd);
 out_subpool_put:
-	/*
-	 * put page to subpool iff the quota of subpool's rsv_hpages is used
-	 * during hugepage_subpool_get_pages.
-	 */
-	if (map_chg && !gbl_chg) {
-		gbl_reserve = hugepage_subpool_put_pages(spool, 1);
-		hugetlb_acct_memory(h, -gbl_reserve);
+	if (map_chg) {
+		long gbl_resv_put = hugepage_subpool_put_pages(spool, 1);
+
+		hugetlb_acct_memory(h, gbl_resv_get - gbl_resv_put);
 	}
 
 

-- 
2.55.0.229.g6434b31f56-goog

