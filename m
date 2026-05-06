From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 06 May 2026 08:54:42 -0700
Subject: [PATCH v2 6/6] mm: hugetlb: Refactor out hugetlb_alloc_folio()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260506-hugetlb-open-up-v2-6-826a0c5f28fc@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778082886; l=9112;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=zPlFgYkmuWlbZ0fv93XRQ9dNZUEoV1wVV83bZAcmM2o=;
 b=HPPWp6DtX5ckKKL2Y2JyaJF+iyeM5p2mthrOWGId5tZ2kGaFEKAjjUeJk0x1ijjrxS2mgxyZD
 757hPSkEcAiA6KNYC/D+jwmDVhIhVulPQxc2ibS0qLSwfEUrGctzgr5
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor out hugetlb_alloc_folio() from alloc_hugetlb_folio(), which
handles allocation of a folio and memory and HugeTLB charging to cgroups.

This refactoring decouples the HugeTLB page allocation from VMAs,
specifically:

1. Reservations (as in resv_map) are stored in the vma
2. mpol is stored at vma->vm_policy
3. A vma must be used for allocation even if the pages are not meant to be
   used by host process.

Without this coupling, VMAs are no longer a requirement for
allocation. This opens up the allocation routine for usage without VMAs,
which will allow guest_memfd to use HugeTLB as a more generic allocator of
huge pages, since guest_memfd memory may not have any associated VMAs by
design. In addition, direct allocations from HugeTLB could possibly be
refactored to avoid the use of a pseudo-VMA.

Also, this decouples HugeTLB page allocation from HugeTLBfs, where the
subpool is stored at the fs mount. This is also a requirement for
guest_memfd, where the plan is to have a subpool created per-fd and stored
on the inode.

No functional change intended.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/hugetlb.h |   3 +
 mm/hugetlb.c            | 179 ++++++++++++++++++++++++++----------------------
 2 files changed, 100 insertions(+), 82 deletions(-)

diff --git a/include/linux/hugetlb.h b/include/linux/hugetlb.h
index 93418625d3c5f..ec205d8580885 100644
--- a/include/linux/hugetlb.h
+++ b/include/linux/hugetlb.h
@@ -705,6 +705,9 @@ bool hugetlb_bootmem_page_zones_valid(int nid, struct huge_bootmem_page *m);
 int isolate_or_dissolve_huge_folio(struct folio *folio, struct list_head *list);
 int replace_free_hugepage_folios(unsigned long start_pfn, unsigned long end_pfn);
 void wait_for_freed_hugetlb_folios(void);
+struct folio *hugetlb_alloc_folio(struct hstate *h, struct hugepage_subpool *spool,
+		struct mempolicy *mpol, int nid, nodemask_t *nodemask,
+		bool charge_hugetlb_cgroup_rsvd, bool use_global_reservation);
 struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 				unsigned long addr, bool cow_from_owner);
 struct folio *alloc_hugetlb_folio_nodemask(struct hstate *h, int preferred_nid,
diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 4159b3565a9be..a1c5b94e52e0a 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -2821,6 +2821,88 @@ void wait_for_freed_hugetlb_folios(void)
 	flush_work(&free_hpage_work);
 }
 
+struct folio *hugetlb_alloc_folio(struct hstate *h, struct hugepage_subpool *spool,
+		struct mempolicy *mpol, int nid, nodemask_t *nodemask,
+		bool charge_hugetlb_cgroup_rsvd, bool use_global_reservation)
+{
+	size_t nr_pages = pages_per_huge_page(h);
+	struct hugetlb_cgroup *h_cg = NULL;
+	gfp_t gfp = htlb_alloc_mask(h);
+	int idx = hstate_index(h);
+	struct folio *folio;
+	int ret;
+
+	if (charge_hugetlb_cgroup_rsvd &&
+	    hugetlb_cgroup_charge_cgroup_rsvd(idx, nr_pages, &h_cg))
+		return ERR_PTR(-ENOSPC);
+
+	if (hugetlb_cgroup_charge_cgroup(idx, nr_pages, &h_cg)) {
+		ret = -ENOSPC;
+		goto err_uncharge_hugetlb_cgroup_rsvd;
+	}
+
+	spin_lock_irq(&hugetlb_lock);
+
+	folio = NULL;
+	if (use_global_reservation || available_huge_pages(h))
+		folio = dequeue_hugetlb_folio_with_mpol(h, mpol, nid, nodemask);
+
+	if (!folio) {
+		spin_unlock_irq(&hugetlb_lock);
+		folio = alloc_buddy_hugetlb_folio_with_mpol(h, mpol, nid, nodemask);
+		if (!folio) {
+			ret = -ENOSPC;
+			goto err_uncharge_hugetlb_cgroup;
+		}
+		spin_lock_irq(&hugetlb_lock);
+		list_add(&folio->lru, &h->hugepage_activelist);
+		folio_ref_unfreeze(folio, 1);
+		/* Fall through */
+	}
+
+	if (use_global_reservation) {
+		folio_set_hugetlb_restore_reserve(folio);
+		h->resv_huge_pages--;
+	}
+
+	hugetlb_cgroup_commit_charge(idx, pages_per_huge_page(h), h_cg, folio);
+
+	if (charge_hugetlb_cgroup_rsvd) {
+		hugetlb_cgroup_commit_charge_rsvd(idx, pages_per_huge_page(h),
+						  h_cg, folio);
+	}
+
+	spin_unlock_irq(&hugetlb_lock);
+
+	ret = mem_cgroup_charge_hugetlb(folio, gfp | __GFP_RETRY_MAYFAIL);
+	/*
+	 * Unconditionally increment NR_HUGETLB here because if
+	 * mem_cgroup_charge_hugetlb failed, freeing the page will
+	 * decrement NR_HUGETLB.
+	 */
+	lruvec_stat_mod_folio(folio, NR_HUGETLB, pages_per_huge_page(h));
+
+	if (ret == -ENOMEM) {
+		free_huge_folio(folio);
+		/*
+		 * Skip uncharging hugetlb_cgroup since the charges
+		 * were committed to the folio and freeing the folio
+		 * would have cleared those up.
+		 */
+		return ERR_PTR(ret);
+	}
+
+	return folio;
+
+ err_uncharge_hugetlb_cgroup:
+	hugetlb_cgroup_uncharge_cgroup(idx, nr_pages, h_cg);
+ err_uncharge_hugetlb_cgroup_rsvd:
+	if (charge_hugetlb_cgroup_rsvd)
+		hugetlb_cgroup_uncharge_cgroup_rsvd(idx, nr_pages, h_cg);
+
+	return ERR_PTR(ret);
+}
+
 typedef enum {
 	/*
 	 * For either 0/1: we checked the per-vma resv map, and one resv
@@ -2856,11 +2938,12 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	long retval, gbl_chg, gbl_reserve;
 	map_chg_state map_chg;
 	int ret, idx;
-	struct hugetlb_cgroup *h_cg = NULL;
 	gfp_t gfp = htlb_alloc_mask(h);
 	struct mempolicy *mpol;
 	nodemask_t *nodemask;
 	int nid;
+	bool charge_hugetlb_cgroup_rsvd;
+	bool global_reservation_exists;
 
 	idx = hstate_index(h);
 
@@ -2907,89 +2990,28 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	}
 
 	/*
-	 * If this allocation is not consuming a per-vma reservation,
-	 * charge the hugetlb cgroup now.
+	 * If allocation doesn't reuse a reservation in the resv_map,
+	 * charge for the reservation.
 	 */
-	if (map_chg) {
-		ret = hugetlb_cgroup_charge_cgroup_rsvd(
-			idx, pages_per_huge_page(h), &h_cg);
-		if (ret) {
-			ret = -ENOSPC;
-			goto out_subpool_put;
-		}
-	}
+	charge_hugetlb_cgroup_rsvd = map_chg != MAP_CHG_REUSE;
 
-	ret = hugetlb_cgroup_charge_cgroup(idx, pages_per_huge_page(h), &h_cg);
-	if (ret) {
-		ret = -ENOSPC;
-		goto out_uncharge_cgroup_reservation;
-	}
-
-	spin_lock_irq(&hugetlb_lock);
+	/*
+	 * gbl_chg == 0 indicates a reservation exists for this
+	 * allocation, so try to use it.
+	 */
+	global_reservation_exists = gbl_chg == 0;
 
 	/* Takes reference on mpol. */
 	nid = huge_node(vma, addr, gfp, &mpol, &nodemask);
 
-	/*
-	 * gbl_chg == 0 indicates a reservation exists for the allocation - so
-	 * try dequeuing a page. If there are available_huge_pages(), try using
-	 * them!
-	 */
-	folio = NULL;
-	if (!gbl_chg || available_huge_pages(h))
-		folio = dequeue_hugetlb_folio_with_mpol(h, mpol, nid, nodemask);
-
-	if (!folio) {
-		spin_unlock_irq(&hugetlb_lock);
-		folio = alloc_buddy_hugetlb_folio_with_mpol(h, mpol, nid, nodemask);
-		if (!folio) {
-			mpol_cond_put(mpol);
-			ret = -ENOSPC;
-			goto out_uncharge_cgroup;
-		}
-		spin_lock_irq(&hugetlb_lock);
-		list_add(&folio->lru, &h->hugepage_activelist);
-		folio_ref_unfreeze(folio, 1);
-		/* Fall through */
-	}
+	folio = hugetlb_alloc_folio(h, spool, mpol, nid, nodemask,
+				    charge_hugetlb_cgroup_rsvd,
+				    global_reservation_exists);
 
 	mpol_cond_put(mpol);
 
-	/*
-	 * Either dequeued or buddy-allocated folio needs to add special
-	 * mark to the folio when it consumes a global reservation.
-	 */
-	if (!gbl_chg) {
-		folio_set_hugetlb_restore_reserve(folio);
-		h->resv_huge_pages--;
-	}
-
-	hugetlb_cgroup_commit_charge(idx, pages_per_huge_page(h), h_cg, folio);
-	/* If allocation is not consuming a reservation, also store the
-	 * hugetlb_cgroup pointer on the page.
-	 */
-	if (map_chg) {
-		hugetlb_cgroup_commit_charge_rsvd(idx, pages_per_huge_page(h),
-						  h_cg, folio);
-	}
-
-	spin_unlock_irq(&hugetlb_lock);
-
-	ret = mem_cgroup_charge_hugetlb(folio, gfp | __GFP_RETRY_MAYFAIL);
-	/*
-	 * Unconditionally increment NR_HUGETLB here. If it turns out that
-	 * mem_cgroup_charge_hugetlb failed, then immediately free the page and
-	 * decrement NR_HUGETLB.
-	 */
-	lruvec_stat_mod_folio(folio, NR_HUGETLB, pages_per_huge_page(h));
-
-	if (ret == -ENOMEM) {
-		free_huge_folio(folio);
-		/*
-		 * Skip uncharging hugetlb_cgroup since the charges
-		 * were committed to the folio and freeing the folio
-		 * would have cleared those up.
-		 */
+	if (IS_ERR(folio)) {
+		ret = PTR_ERR(folio);
 		goto out_subpool_put;
 	}
 
@@ -3022,12 +3044,6 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 
 	return folio;
 
-out_uncharge_cgroup:
-	hugetlb_cgroup_uncharge_cgroup(idx, pages_per_huge_page(h), h_cg);
-out_uncharge_cgroup_reservation:
-	if (map_chg)
-		hugetlb_cgroup_uncharge_cgroup_rsvd(idx, pages_per_huge_page(h),
-						    h_cg);
 out_subpool_put:
 	/*
 	 * put page to subpool iff the quota of subpool's rsv_hpages is used
@@ -3038,7 +3054,6 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		hugetlb_acct_memory(h, -gbl_reserve);
 	}
 
-
 out_end_reservation:
 	if (map_chg != MAP_CHG_ENFORCED)
 		vma_end_reservation(h, vma, addr);

-- 
2.54.0.545.g6539524ca2-goog

