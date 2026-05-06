From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 06 May 2026 08:54:38 -0700
Subject: [PATCH v2 2/6] mm: hugetlb: Move mpol interpretation out of
 alloc_buddy_hugetlb_folio_with_mpol()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260506-hugetlb-open-up-v2-2-826a0c5f28fc@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778082886; l=2961;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=ngW2MpP6uF73PbJ5TvqQViScClcx1raOJSqESPZNT2g=;
 b=60OulaMrVIeL0AUDLw/Oj4vJ4TXPrn+qA6Ksx0VcV+YxxEG7QSPdreEFwdfYdmXpaEq60mkKZ
 NM7+wE2n83lBiKpobQJz9oQFqYCtE8npaDcWzeD6ssL5cTOLYqSVXQ1
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move memory policy interpretation out of
alloc_buddy_hugetlb_folio_with_mpol() and into alloc_hugetlb_folio() to
separate reading and interpretation of memory policy from actual
allocation.

This will later allow memory policy to be interpreted outside of the
process of allocating a hugetlb folio entirely. This opens doors for other
callers of the HugeTLB folio allocation function, such as guest_memfd,
where memory may not always be mapped and hence may not have an associated
vma.

No functional change intended.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Reviewed-by: James Houghton <jthoughton@google.com>
---
 mm/hugetlb.c | 20 +++++++++++---------
 1 file changed, 11 insertions(+), 9 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 8be246b4e6134..ea3bc405b3162 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -2160,15 +2160,11 @@ static struct folio *alloc_migrate_hugetlb_folio(struct hstate *h, gfp_t gfp_mas
  */
 static
 struct folio *alloc_buddy_hugetlb_folio_with_mpol(struct hstate *h,
-		struct vm_area_struct *vma, unsigned long addr)
+		struct mempolicy *mpol, int nid, nodemask_t *nodemask)
 {
 	struct folio *folio = NULL;
-	struct mempolicy *mpol;
 	gfp_t gfp_mask = htlb_alloc_mask(h);
-	int nid;
-	nodemask_t *nodemask;
 
-	nid = huge_node(vma, addr, gfp_mask, &mpol, &nodemask);
 	if (mpol_is_preferred_many(mpol)) {
 		gfp_t gfp = gfp_mask & ~(__GFP_DIRECT_RECLAIM | __GFP_NOFAIL);
 
@@ -2180,7 +2176,7 @@ struct folio *alloc_buddy_hugetlb_folio_with_mpol(struct hstate *h,
 
 	if (!folio)
 		folio = alloc_surplus_hugetlb_folio(h, gfp_mask, nid, nodemask);
-	mpol_cond_put(mpol);
+
 	return folio;
 }
 
@@ -2869,7 +2865,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	map_chg_state map_chg;
 	int ret, idx;
 	struct hugetlb_cgroup *h_cg = NULL;
-	gfp_t gfp = htlb_alloc_mask(h) | __GFP_RETRY_MAYFAIL;
+	gfp_t gfp = htlb_alloc_mask(h);
 
 	idx = hstate_index(h);
 
@@ -2940,8 +2936,14 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		folio = dequeue_hugetlb_folio_vma(h, vma, addr);
 
 	if (!folio) {
+		struct mempolicy *mpol;
+		nodemask_t *nodemask;
+		int nid;
+
 		spin_unlock_irq(&hugetlb_lock);
-		folio = alloc_buddy_hugetlb_folio_with_mpol(h, vma, addr);
+		nid = huge_node(vma, addr, gfp, &mpol, &nodemask);
+		folio = alloc_buddy_hugetlb_folio_with_mpol(h, mpol, nid, nodemask);
+		mpol_cond_put(mpol);
 		if (!folio)
 			goto out_uncharge_cgroup;
 		spin_lock_irq(&hugetlb_lock);
@@ -2997,7 +2999,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		}
 	}
 
-	ret = mem_cgroup_charge_hugetlb(folio, gfp);
+	ret = mem_cgroup_charge_hugetlb(folio, gfp | __GFP_RETRY_MAYFAIL);
 	/*
 	 * Unconditionally increment NR_HUGETLB here. If it turns out that
 	 * mem_cgroup_charge_hugetlb failed, then immediately free the page and

-- 
2.54.0.545.g6539524ca2-goog

