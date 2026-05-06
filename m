From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 06 May 2026 08:54:39 -0700
Subject: [PATCH v2 3/6] mm: hugetlb: Move mpol interpretation out of
 dequeue_hugetlb_folio_vma()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260506-hugetlb-open-up-v2-3-826a0c5f28fc@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778082886; l=3663;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=zIDAPwSnRf8adh9I7F/T1NlbtOUHnAoWsG2BkZYAmpE=;
 b=e6zxTOz1Z5Z7o18qfH+LW7SX9rmjkxEwXMwf606rlXQdoT9U30y3BMbzYKZvyIorkfFoOtRCm
 J8flqEynR5oAbgxmGpozVQHraboIoYB2OmWYo5LFk4l23gaMyzZ0nSY
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
 mm/hugetlb.c | 34 +++++++++++++++-------------------
 1 file changed, 15 insertions(+), 19 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index ea3bc405b3162..3395de4d0999a 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -1334,18 +1334,11 @@ static unsigned long available_huge_pages(struct hstate *h)
 	return h->free_huge_pages - h->resv_huge_pages;
 }
 
-static struct folio *dequeue_hugetlb_folio_vma(struct hstate *h,
-				struct vm_area_struct *vma,
-				unsigned long address)
+static struct folio *dequeue_hugetlb_folio_with_mpol(struct hstate *h,
+		struct mempolicy *mpol, int nid, nodemask_t *nodemask)
 {
 	struct folio *folio = NULL;
-	struct mempolicy *mpol;
-	gfp_t gfp_mask;
-	nodemask_t *nodemask;
-	int nid;
-
-	gfp_mask = htlb_alloc_mask(h);
-	nid = huge_node(vma, address, gfp_mask, &mpol, &nodemask);
+	gfp_t gfp_mask = htlb_alloc_mask(h);
 
 	if (mpol_is_preferred_many(mpol)) {
 		folio = dequeue_hugetlb_folio_nodemask(h, gfp_mask,
@@ -1359,7 +1352,6 @@ static struct folio *dequeue_hugetlb_folio_vma(struct hstate *h,
 		folio = dequeue_hugetlb_folio_nodemask(h, gfp_mask,
 							nid, nodemask);
 
-	mpol_cond_put(mpol);
 	return folio;
 }
 
@@ -2866,6 +2858,9 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	int ret, idx;
 	struct hugetlb_cgroup *h_cg = NULL;
 	gfp_t gfp = htlb_alloc_mask(h);
+	struct mempolicy *mpol;
+	nodemask_t *nodemask;
+	int nid;
 
 	idx = hstate_index(h);
 
@@ -2926,6 +2921,9 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 
 	spin_lock_irq(&hugetlb_lock);
 
+	/* Takes reference on mpol. */
+	nid = huge_node(vma, addr, gfp, &mpol, &nodemask);
+
 	/*
 	 * gbl_chg == 0 indicates a reservation exists for the allocation - so
 	 * try dequeuing a page. If there are available_huge_pages(), try using
@@ -2933,25 +2931,23 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	 */
 	folio = NULL;
 	if (!gbl_chg || available_huge_pages(h))
-		folio = dequeue_hugetlb_folio_vma(h, vma, addr);
+		folio = dequeue_hugetlb_folio_with_mpol(h, mpol, nid, nodemask);
 
 	if (!folio) {
-		struct mempolicy *mpol;
-		nodemask_t *nodemask;
-		int nid;
-
 		spin_unlock_irq(&hugetlb_lock);
-		nid = huge_node(vma, addr, gfp, &mpol, &nodemask);
 		folio = alloc_buddy_hugetlb_folio_with_mpol(h, mpol, nid, nodemask);
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
2.54.0.545.g6539524ca2-goog

