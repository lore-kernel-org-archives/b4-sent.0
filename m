From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 06 May 2026 08:54:40 -0700
Subject: [PATCH v2 4/6] mm: hugetlb: Use error variable in
 alloc_hugetlb_folio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260506-hugetlb-open-up-v2-4-826a0c5f28fc@google.com>
References: <20260506-hugetlb-open-up-v2-0-826a0c5f28fc@google.com>
In-Reply-To: <20260506-hugetlb-open-up-v2-0-826a0c5f28fc@google.com>
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>, fvdl@google.com, 
 jiaqiyan@google.com, joshua.hahnjy@gmail.com, jthoughton@google.com, 
 mhocko@kernel.org, michael.roth@amd.com, pasha.tatashin@soleen.com, 
 pbonzini@redhat.com, peterx@redhat.com, pratyush@kernel.org, 
 rick.p.edgecombe@intel.com, rientjes@google.com, roman.gushchin@linux.dev, 
 seanjc@google.com, shakeel.butt@linux.dev, shivankg@amd.com, 
 vannapurve@google.com, yan.y.zhao@intel.com, Dan Williams <djbw@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778082886; l=2128;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=eGP3URO25a2yJfXjXfljDSZfxvkXYHSvdYeyD7MI+ek=;
 b=7RdhDIfpu2hRHtT21qfwETAVWbSePUPaxz9JrwOIiwwAWtPE6ipWXGpk2G8+NkmVEBhRnCSRm
 dv6BvSt6FHdDvL8xQXod9qkE63QOT2QnsHlTzCbxf64nENwkYBB79re
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor alloc_hugetlb_folio to use a local variable for returning error
codes. Instead of returning ERR_PTR(-ENOSPC) at the end of the error
path, assign -ENOSPC to a return variable at each failure point and
return that variable at the end.

This allows the cleanup goto targets to be used with other errors in a
later patch.

No functional change intended.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 mm/hugetlb.c | 15 +++++++++++----
 1 file changed, 11 insertions(+), 4 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 3395de4d0999a..68c21305fc86a 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -2894,8 +2894,10 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	 */
 	if (map_chg) {
 		gbl_chg = hugepage_subpool_get_pages(spool, 1);
-		if (gbl_chg < 0)
+		if (gbl_chg < 0) {
+			ret = -ENOSPC;
 			goto out_end_reservation;
+		}
 	} else {
 		/*
 		 * If we have the vma reservation ready, no need for extra
@@ -2911,13 +2913,17 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	if (map_chg) {
 		ret = hugetlb_cgroup_charge_cgroup_rsvd(
 			idx, pages_per_huge_page(h), &h_cg);
-		if (ret)
+		if (ret) {
+			ret = -ENOSPC;
 			goto out_subpool_put;
+		}
 	}
 
 	ret = hugetlb_cgroup_charge_cgroup(idx, pages_per_huge_page(h), &h_cg);
-	if (ret)
+	if (ret) {
+		ret = -ENOSPC;
 		goto out_uncharge_cgroup_reservation;
+	}
 
 	spin_lock_irq(&hugetlb_lock);
 
@@ -2938,6 +2944,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		folio = alloc_buddy_hugetlb_folio_with_mpol(h, mpol, nid, nodemask);
 		if (!folio) {
 			mpol_cond_put(mpol);
+			ret = -ENOSPC;
 			goto out_uncharge_cgroup;
 		}
 		spin_lock_irq(&hugetlb_lock);
@@ -3030,7 +3037,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 out_end_reservation:
 	if (map_chg != MAP_CHG_ENFORCED)
 		vma_end_reservation(h, vma, addr);
-	return ERR_PTR(-ENOSPC);
+	return ERR_PTR(ret);
 }
 
 static __init void *alloc_bootmem(struct hstate *h, int nid, bool node_exact)

-- 
2.54.0.545.g6539524ca2-goog

