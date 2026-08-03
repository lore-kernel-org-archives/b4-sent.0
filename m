From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 03 Aug 2026 06:38:00 -0700
Subject: [PATCH v5 3/3] mm: hugetlb: Move mpol interpretation out of
 dequeue_hugetlb_folio_vma()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-hugetlb-mpol-interpretation-v5-3-af2b7089f8a9@google.com>
References: <20260803-hugetlb-mpol-interpretation-v5-0-af2b7089f8a9@google.com>
In-Reply-To: <20260803-hugetlb-mpol-interpretation-v5-0-af2b7089f8a9@google.com>
To: Alistair Popple <apopple@nvidia.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Byungchul Park <byungchul@sk.com>, David Hildenbrand <david@kernel.org>, 
 Gregory Price <gourry@gourry.net>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Matthew Brost <matthew.brost@intel.com>, 
 Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 Rakie Kim <rakie.kim@sk.com>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Zi Yan <ziy@nvidia.com>, erdemaktas@google.com, fvdl@google.com, 
 jiaqiyan@google.com, jthoughton@google.com, mhocko@kernel.org, 
 michael.roth@amd.com, pasha.tatashin@soleen.com, pbonzini@redhat.com, 
 peterx@redhat.com, pratyush@kernel.org, rick.p.edgecombe@intel.com, 
 rientjes@google.com, roman.gushchin@linux.dev, seanjc@google.com, 
 shakeel.butt@linux.dev, shivankg@amd.com, vannapurve@google.com, 
 yan.y.zhao@intel.com, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785764284; l=4241;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=mxYJ9ZfIJDNqqNET+i798zl+eMXnvPpSjYi2l1OPxHE=;
 b=QivN7sN8I31WwiKn12XzM7zIcnCzCJFKMeumY1BlC2xQSYMVmWvVkTmcw5squW1hr8iXtI4B0
 wOnsLFdhs81A9khAN94v1qQa86hSPfKdAOJ4qgacYrp7gCr0+NrP8kz
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move memory policy interpretation out of dequeue_hugetlb_folio_vma() and
into alloc_hugetlb_folio() to separate reading and interpretation of memory
policy from actual allocation.

Also rename dequeue_hugetlb_folio_vma() to
dequeue_hugetlb_folio_with_mpol() to remove association with vma and to
align with alloc_buddy_hugetlb_folio_with_mpol().

This will later allow memory policy to be interpreted outside of the
process of allocating a hugetlb folio entirely. This opens doors for other
callers of the HugeTLB folio allocation function, such as guest_memfd,
where memory may not always be mapped and hence may not have an associated
vma.

No functional change intended.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Reviewed-by: James Houghton <jthoughton@google.com>
---
 mm/hugetlb.c | 66 +++++++++++++++++++++++++++++-------------------------------
 1 file changed, 32 insertions(+), 34 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 3a159de08a0b6..a11cb919e00fe 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -1323,32 +1323,26 @@ struct mempolicy_interpreted {
 	enum mempolicy_mode mode;
 };
 
-static struct folio *dequeue_hugetlb_folio_vma(struct hstate *h,
-				struct vm_area_struct *vma,
-				unsigned long address)
+static struct folio *dequeue_hugetlb_folio(struct hstate *h, gfp_t gfp_mask,
+					   struct mempolicy_interpreted *mpoli)
 {
+	nodemask_t *nodemask = mpoli->nodemask;
 	struct folio *folio = NULL;
-	struct mempolicy *mpol;
-	gfp_t gfp_mask;
-	nodemask_t *nodemask;
-	int nid;
-
-	gfp_mask = htlb_alloc_mask(h);
-	nid = huge_node(vma, address, gfp_mask, &mpol, &nodemask);
 
-	if (mpol_is_preferred_many(mpol)) {
+	if (mpoli->mode == MPOL_PREFERRED_MANY) {
 		folio = dequeue_hugetlb_folio_nodemask(h, gfp_mask,
-							nid, nodemask);
+						       mpoli->nid,
+						       nodemask);
 
 		/* Fallback to all nodes if page==NULL */
 		nodemask = NULL;
 	}
 
-	if (!folio)
+	if (!folio) {
 		folio = dequeue_hugetlb_folio_nodemask(h, gfp_mask,
-							nid, nodemask);
-
-	mpol_cond_put(mpol);
+						       mpoli->nid,
+						       nodemask);
+	}
 	return folio;
 }
 
@@ -2855,7 +2849,11 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	int ret, idx;
 	struct hugetlb_cgroup *h_cg = NULL;
 	struct hugetlb_cgroup *h_cg_rsvd = NULL;
+	struct mempolicy_interpreted mpoli;
 	gfp_t gfp = htlb_alloc_mask(h);
+	struct mempolicy *mpol;
+	nodemask_t *nodemask;
+	int nid;
 
 	idx = hstate_index(h);
 
@@ -2914,6 +2912,18 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	if (ret)
 		goto out_uncharge_cgroup_reservation;
 
+	/* Takes reference on mpol. */
+	nid = huge_node(vma, addr, gfp, &mpol, &nodemask);
+	mpoli = (struct mempolicy_interpreted){
+		.nid = nid,
+#ifdef CONFIG_NUMA
+		.mode = mpol ? mpol->mode : MPOL_DEFAULT,
+#else
+		.mode = MPOL_DEFAULT,
+#endif
+		.nodemask = nodemask,
+	};
+
 	spin_lock_irq(&hugetlb_lock);
 
 	/*
@@ -2925,35 +2935,23 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	 */
 	folio = NULL;
 	if (!gbl_chg || available_huge_pages(h))
-		folio = dequeue_hugetlb_folio_vma(h, vma, addr);
+		folio = dequeue_hugetlb_folio(h, gfp, &mpoli);
 
 	if (!folio) {
-		struct mempolicy_interpreted mpoli;
-		struct mempolicy *mpol;
-		nodemask_t *nodemask;
-		int nid;
-
 		spin_unlock_irq(&hugetlb_lock);
-		nid = huge_node(vma, addr, gfp, &mpol, &nodemask);
-		mpoli = (struct mempolicy_interpreted){
-			.nid = nid,
-#ifdef CONFIG_NUMA
-			.mode = mpol ? mpol->mode : MPOL_DEFAULT,
-#else
-			.mode = MPOL_DEFAULT,
-#endif
-			.nodemask = nodemask,
-		};
 		folio = alloc_buddy_hugetlb_folio(h, gfp, &mpoli);
-		mpol_cond_put(mpol);
-		if (!folio)
+		if (!folio) {
+			mpol_cond_put(mpol);
 			goto out_uncharge_cgroup;
+		}
 		spin_lock_irq(&hugetlb_lock);
 		list_add(&folio->lru, &h->hugepage_activelist);
 		folio_ref_unfreeze(folio, 1);
 		/* Fall through */
 	}
 
+	mpol_cond_put(mpol);
+
 	/*
 	 * Either dequeued or buddy-allocated folio needs to add special
 	 * mark to the folio when it consumes a global reservation.

-- 
2.55.0.508.g3f0d502094-goog

