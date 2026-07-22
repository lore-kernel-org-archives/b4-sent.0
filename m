From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 22 Jul 2026 16:41:14 -0700
Subject: [PATCH v4 06/16] mm: hugetlb: Rename local variables for clarity
 in hugetlb_reserve_pages()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-hugetlb-alloc-failure-fixes-v4-6-88e8b81970dc@google.com>
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
 linux-doc@vger.kernel.org, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784763678; l=4405;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=YN6Ec4dryGn+lNCiGktVw2z+GkC+1qiWsI1wgmafaTw=;
 b=2bILnGfpQYBpRme36koKemun0e04kP1hxT7XZpV0o3yJRaZSrtupWWZeQRckJ1ePGfhGs4qPM
 8BCX7oBBkyyAdb4/2/vTHjmS0gJZT/YU/XnuJHwl3Zt1scXLcXt/uJ9
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In hugetlb_reserve_pages(), the return value of
hugepage_subpool_get_pages() was named gbl_resv, while the return value of
hugepage_subpool_put_pages() was named gbl_reserve. These variable names
were inconsistent with the naming conventions established in
alloc_hugetlb_folio().

Rename local variables in hugetlb_reserve_pages() to match naming in
alloc_hugetlb_folio().

+ Rename gbl_resv to gbl_resv_get, which is the number of global
  reservations required from the global pool (because neither reservation
  maps nor pre-existing subpool reservations could cover the request).

  If gbl_resv_get is 0, the reservation request is fully covered by
  pre-existing subpool reservations, so no additional global reservations
  are requested. If gbl_resv_get > 0, it represents the number of
  additional global reservations required, which are charged to global
  memory via hugetlb_acct_memory(h, gbl_resv_get).

  Note: gbl_resv_get in hugetlb_reserve_pages() is conceptually slightly
  different from gbl_resv_get in alloc_hugetlb_folio():

  + In hugetlb_reserve_pages(): additional _reservations_ required,
                                accounted using hugetlb_acct_memory()
  + In alloc_hugetlb_folio(): additional _pages_ required, no change to
                              h->resv_huge_pages if gbl_resv_get > 0

+ Rename gbl_reserve to gbl_resv_put, which is the number of pages the
  subpool could not absorb into its reservations during rollback (and are
  thus returned to the global pool).

In error rollback paths, hugetlb_acct_memory(h, gbl_resv_get -
gbl_resv_put) adjusts global reservations using the difference between
global pages requested (gbl_resv_get) and global pages returned
(gbl_resv_put).

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 mm/hugetlb.c | 19 ++++++++++---------
 1 file changed, 10 insertions(+), 9 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 879e4640dc50d..8431c00d48267 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -6562,12 +6562,13 @@ long hugetlb_reserve_pages(struct inode *inode,
 		struct vm_area_struct *vma,
 		vma_flags_t vma_flags)
 {
-	long chg = -1, add = -1, gbl_resv;
+	long chg = -1, add = -1;
 	struct hstate *h = hstate_inode(inode);
 	struct hugepage_subpool *spool = subpool_inode(inode);
 	struct resv_map *resv_map;
 	struct hugetlb_cgroup *h_cg = NULL;
-	long gbl_reserve, regions_needed = 0;
+	long gbl_resv_get, gbl_resv_put;
+	long regions_needed = 0;
 	int err;
 
 	/* This should never happen */
@@ -6642,9 +6643,9 @@ long hugetlb_reserve_pages(struct inode *inode,
 	 * the subpool has a minimum size, there may be some global
 	 * reservations already in place (gbl_reserve).
 	 */
-	gbl_resv = hugepage_subpool_get_pages(spool, chg);
-	if (gbl_resv < 0) {
-		err = gbl_resv;
+	gbl_resv_get = hugepage_subpool_get_pages(spool, chg);
+	if (gbl_resv_get < 0) {
+		err = gbl_resv_get;
 		goto out_uncharge_cgroup;
 	}
 
@@ -6652,7 +6653,7 @@ long hugetlb_reserve_pages(struct inode *inode,
 	 * Check enough hugepages are available for the reservation.
 	 * Hand the pages back to the subpool if there are not
 	 */
-	err = hugetlb_acct_memory(h, gbl_resv);
+	err = hugetlb_acct_memory(h, gbl_resv_get);
 	if (err < 0)
 		goto out_put_pages;
 
@@ -6671,7 +6672,7 @@ long hugetlb_reserve_pages(struct inode *inode,
 		add = region_add(resv_map, from, to, regions_needed, h, h_cg);
 
 		if (unlikely(add < 0)) {
-			hugetlb_acct_memory(h, -gbl_resv);
+			hugetlb_acct_memory(h, -gbl_resv_get);
 			err = add;
 			goto out_put_pages;
 		} else if (unlikely(chg > add)) {
@@ -6713,14 +6714,14 @@ long hugetlb_reserve_pages(struct inode *inode,
 	 * tell us the new number of reservations that need to be
 	 * returned to the global pool.
 	 */
-	gbl_reserve = hugepage_subpool_put_pages(spool, chg);
+	gbl_resv_put = hugepage_subpool_put_pages(spool, chg);
 	/*
 	 * There may be a difference between the number of
 	 * reservations to consume and the number to restore now if
 	 * there are multiple threads interacting with the subpool -
 	 * restore the difference.
 	 */
-	hugetlb_acct_memory(h, gbl_resv - gbl_reserve);
+	hugetlb_acct_memory(h, gbl_resv_get - gbl_resv_put);
 
 out_uncharge_cgroup:
 	hugetlb_cgroup_uncharge_cgroup_rsvd(hstate_index(h),

-- 
2.55.0.229.g6434b31f56-goog

