From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 06 May 2026 08:54:37 -0700
Subject: [PATCH v2 1/6] mm: hugetlb: Consolidate interpretation of gbl_chg
 within alloc_hugetlb_folio()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260506-hugetlb-open-up-v2-1-826a0c5f28fc@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778082886; l=2756;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=d07xjMz226JjEc/S2RGQulaBk1NX7KLyZoqjiwrAxHY=;
 b=+/SUHAmWoMFGdn/H4OjwEcyODzKvoeTyEnJ4IzRXpHEDn9Nb3OZ7OR2lii3cgkG937pidxwl/
 emDZjH9Y099DWpGjfBTGt96dGIVzbBczTi8J9uhVKuMPxthX4fi1lSL
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dequeue_hugetlb_folio_vma() function currently handles the gbl_chg
parameter to determine if a folio can be dequeued based on global page
availability. This leaks reservation-specific logic into the dequeueing
path.

Relocate this logic to alloc_hugetlb_folio() so that
dequeue_hugetlb_folio_vma() focuses solely on selecting and dequeuing a
folio. In alloc_hugetlb_folio(), only attempt to dequeue a folio if a
reservation exists (gbl_chg == 0) or if there are available huge pages in
the global pool.

No functional change intended.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Reviewed-by: James Houghton <jthoughton@google.com>
---
 mm/hugetlb.c | 24 +++++++++---------------
 1 file changed, 9 insertions(+), 15 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index f24bf49be047e..8be246b4e6134 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -1336,7 +1336,7 @@ static unsigned long available_huge_pages(struct hstate *h)
 
 static struct folio *dequeue_hugetlb_folio_vma(struct hstate *h,
 				struct vm_area_struct *vma,
-				unsigned long address, long gbl_chg)
+				unsigned long address)
 {
 	struct folio *folio = NULL;
 	struct mempolicy *mpol;
@@ -1344,13 +1344,6 @@ static struct folio *dequeue_hugetlb_folio_vma(struct hstate *h,
 	nodemask_t *nodemask;
 	int nid;
 
-	/*
-	 * gbl_chg==1 means the allocation requires a new page that was not
-	 * reserved before.  Making sure there's at least one free page.
-	 */
-	if (gbl_chg && !available_huge_pages(h))
-		goto err;
-
 	gfp_mask = htlb_alloc_mask(h);
 	nid = huge_node(vma, address, gfp_mask, &mpol, &nodemask);
 
@@ -1368,9 +1361,6 @@ static struct folio *dequeue_hugetlb_folio_vma(struct hstate *h,
 
 	mpol_cond_put(mpol);
 	return folio;
-
-err:
-	return NULL;
 }
 
 #if defined(CONFIG_ARCH_HAS_GIGANTIC_PAGE) && defined(CONFIG_CONTIG_ALLOC)
@@ -2939,12 +2929,16 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		goto out_uncharge_cgroup_reservation;
 
 	spin_lock_irq(&hugetlb_lock);
+
 	/*
-	 * glb_chg is passed to indicate whether or not a page must be taken
-	 * from the global free pool (global change).  gbl_chg == 0 indicates
-	 * a reservation exists for the allocation.
+	 * gbl_chg == 0 indicates a reservation exists for the allocation - so
+	 * try dequeuing a page. If there are available_huge_pages(), try using
+	 * them!
 	 */
-	folio = dequeue_hugetlb_folio_vma(h, vma, addr, gbl_chg);
+	folio = NULL;
+	if (!gbl_chg || available_huge_pages(h))
+		folio = dequeue_hugetlb_folio_vma(h, vma, addr);
+
 	if (!folio) {
 		spin_unlock_irq(&hugetlb_lock);
 		folio = alloc_buddy_hugetlb_folio_with_mpol(h, vma, addr);

-- 
2.54.0.545.g6539524ca2-goog

