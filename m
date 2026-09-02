From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 02 Sep 2026 16:30:49 -0700
Subject: [PATCH 3/3] mm: hugetlb: Fix subpool usage leak on allocation
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-hugetlb-subpool-always-track-used-v1-3-de1cd14bd713@google.com>
References: <20260902-hugetlb-subpool-always-track-used-v1-0-de1cd14bd713@google.com>
In-Reply-To: <20260902-hugetlb-subpool-always-track-used-v1-0-de1cd14bd713@google.com>
To: Alex Shi <alexs@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Dongliang Mu <dzm91@hust.edu.cn>, 
 Hongxiang Lou <louhongxiang@huawei.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Jonathan Corbet <corbet@lwn.net>, 
 Joshua Hahn <joshua.hahnjy@gmail.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Miaohe Lin <linmiaohe@huawei.com>, Michal Hocko <mhocko@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Muchun Song <muchun.song@linux.dev>, 
 Nhat Pham <nphamcs@gmail.com>, Oscar Salvador <osalvador@suse.de>, 
 Peter Xu <peterx@redhat.com>, Randy Dunlap <rdunlap@infradead.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Suren Baghdasaryan <surenb@google.com>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Wupeng Ma <mawupeng1@huawei.com>, 
 Yanteng Si <si.yanteng@linux.dev>, fvdl@google.com, jthoughton@google.com, 
 rientjes@google.com, vannapurve@google.com
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, Ackerley Tng <ackerleytng@google.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788391851; l=3568;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=tOiKIJk4lCf4MxbAJGBewXo+Umkms5osEmNl/iOM9Fg=;
 b=k/ppmJwUIxnr7mkxBDZiMKZAiR+XSgPaNyo312BYQpvGcs049LcEqLMitF0MLO+p5YCizSbZh
 W0d7UofDCOSAEq9m0a7EZnsZBaNFaQkP35qjQzRIgkV5WdzV7I9j3Ol
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When folio allocation fails early (e.g. buddy allocation failure or
cgroup charging failure) and a reservation was not used (meaning an
unreserved global page was needed), the subpool page acquired during the
allocation attempt must still be returned.

Currently, the subpool cleanup error path only returns the page to the
subpool if a reservation was used. If no reservation was used, it skips
releasing the page back to the subpool, permanently leaking the subpool's
used pages counter.

With subpools now always tracking used pages, always release the page
back to the subpool whenever a subpool page was acquired.

Opportunistically rename the local variables tracking global reservations
needed and global reservations returned. This clarifies the accounting:
a value of zero for needed global reservations indicates an existing
reservation satisfies the allocation, while a non-zero value indicates
new global pages are required.

Adjust global reservations using the difference between reservations
needed and reservations returned to properly handle races where concurrent
threads interact with the same subpool.

Fixes: a833a693a490 ("mm: hugetlb: fix incorrect fallback for subpool")
Cc: stable@vger.kernel.org
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 mm/hugetlb.c | 23 ++++++++++-------------
 1 file changed, 10 insertions(+), 13 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index d84ef044d1346..e24f856c949c3 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -2955,7 +2955,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	struct hugepage_subpool *spool = subpool_vma(vma);
 	struct hstate *h = hstate_vma(vma);
 	struct folio *folio;
-	long retval, gbl_chg, gbl_reserve;
+	long retval, gbl_resv_get;
 	map_chg_state map_chg;
 	struct mempolicy_interpreted mpoli;
 	gfp_t gfp = htlb_alloc_mask(h);
@@ -2994,8 +2994,8 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	 * Or if it can get one from the pool reservation directly.
 	 */
 	if (map_chg) {
-		gbl_chg = hugepage_subpool_get_pages(spool, 1);
-		if (gbl_chg < 0) {
+		gbl_resv_get = hugepage_subpool_get_pages(spool, 1);
+		if (gbl_resv_get < 0) {
 			ret = -ENOSPC;
 			goto out_end_reservation;
 		}
@@ -3004,7 +3004,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		 * If we have the vma reservation ready, no need for extra
 		 * global reservation.
 		 */
-		gbl_chg = 0;
+		gbl_resv_get = 0;
 	}
 
 	/*
@@ -3015,10 +3015,10 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		alloc_flags |= HUGETLB_ALLOC_CHARG_CGROUP_RSVD;
 
 	/*
-	 * gbl_chg == 0 indicates a reservation exists for this
+	 * gbl_resv_get == 0 indicates a reservation exists for this
 	 * allocation, so try to use it.
 	 */
-	if (gbl_chg == 0)
+	if (gbl_resv_get == 0)
 		alloc_flags |= HUGETLB_ALLOC_USE_GLOBAL_RESERVATIONS;
 
 	/* Takes reference on mpol. */
@@ -3072,13 +3072,10 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	return folio;
 
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
 
 out_end_reservation:

-- 
2.55.0.970.g62bdec98f9-goog

