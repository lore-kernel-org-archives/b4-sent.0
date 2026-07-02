From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 02 Jul 2026 09:21:46 -0700
Subject: [PATCH v4 2/6] mm: hugetlb: Move mpol interpretation out of
 alloc_buddy_hugetlb_folio_with_mpol()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260702-hugetlb-open-up-v4-2-d53cefcccf34@google.com>
References: <20260702-hugetlb-open-up-v4-0-d53cefcccf34@google.com>
In-Reply-To: <20260702-hugetlb-open-up-v4-0-d53cefcccf34@google.com>
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>, fvdl@google.com, 
 jiaqiyan@google.com, joshua.hahnjy@gmail.com, jthoughton@google.com, 
 mhocko@kernel.org, michael.roth@amd.com, pasha.tatashin@soleen.com, 
 pbonzini@redhat.com, peterx@redhat.com, pratyush@kernel.org, 
 rick.p.edgecombe@intel.com, rientjes@google.com, roman.gushchin@linux.dev, 
 seanjc@google.com, shakeel.butt@linux.dev, shivankg@amd.com, 
 vannapurve@google.com, yan.y.zhao@intel.com, Zi Yan <ziy@nvidia.com>, 
 Matthew Brost <matthew.brost@intel.com>, Rakie Kim <rakie.kim@sk.com>, 
 Byungchul Park <byungchul@sk.com>, Gregory Price <gourry@gourry.net>, 
 Ying Huang <ying.huang@linux.alibaba.com>, 
 Alistair Popple <apopple@nvidia.com>, Dan Williams <djbw@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783009310; l=4766;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=2jWAF3HAwTBG0geXcDCSU9vc4ojuXyHXW0JiBSi/XNI=;
 b=ikqY98+QuylZk6PVjj0evvIs0PRsVQ5isGbwLy/WbQa9ooxTds1n3aeS/IGh/x8dhuICPCxDe
 ztrWZ7nkNfYARtYgAgx3fOVDwIJi9eqtv12jptkc2aXl4r7ixYiLdOo
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

Introduce struct mempolicy_interpreted to hold all the components of an
interpreted memory policy.

Rename alloc_buddy_hugetlb_folio_with_mpol() to alloc_buddy_hugetlb_folio()
since the function no longer interprets memory policy.

No functional change intended.

Reviewed-by: James Houghton <jthoughton@google.com>
Acked-by: Oscar Salvador <osalvador@suse.de>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/uapi/linux/mempolicy.h |  2 +-
 mm/hugetlb.c                   | 54 ++++++++++++++++++++++++++++--------------
 2 files changed, 37 insertions(+), 19 deletions(-)

diff --git a/include/uapi/linux/mempolicy.h b/include/uapi/linux/mempolicy.h
index 6c962d866e864..7f6fc9599693b 100644
--- a/include/uapi/linux/mempolicy.h
+++ b/include/uapi/linux/mempolicy.h
@@ -16,7 +16,7 @@
  */
 
 /* Policies */
-enum {
+enum mempolicy_mode {
 	MPOL_DEFAULT,
 	MPOL_PREFERRED,
 	MPOL_BIND,
diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 83ab9390db565..cdcfff521b6db 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -1317,6 +1317,12 @@ static unsigned long available_huge_pages(struct hstate *h)
 	return h->free_huge_pages - h->resv_huge_pages;
 }
 
+struct mempolicy_interpreted {
+	int nid;
+	nodemask_t *nodemask;
+	enum mempolicy_mode mode;
+};
+
 static struct folio *dequeue_hugetlb_folio_vma(struct hstate *h,
 				struct vm_area_struct *vma,
 				unsigned long address)
@@ -2138,32 +2144,28 @@ static struct folio *alloc_migrate_hugetlb_folio(struct hstate *h, gfp_t gfp_mas
 	return folio;
 }
 
-/*
- * Use the VMA's mpolicy to allocate a huge page from the buddy.
- */
 static
-struct folio *alloc_buddy_hugetlb_folio_with_mpol(struct hstate *h,
-		struct vm_area_struct *vma, unsigned long addr)
+struct folio *alloc_buddy_hugetlb_folio(struct hstate *h,
+		gfp_t gfp_mask, struct mempolicy_interpreted *mpoli)
 {
 	struct folio *folio = NULL;
-	struct mempolicy *mpol;
-	gfp_t gfp_mask = htlb_alloc_mask(h);
-	int nid;
-	nodemask_t *nodemask;
+	nodemask_t *nodemask = mpoli->nodemask;
 
-	nid = huge_node(vma, addr, gfp_mask, &mpol, &nodemask);
-	if (mpol_is_preferred_many(mpol)) {
+	if (mpoli->mode == MPOL_PREFERRED_MANY) {
 		gfp_t gfp = gfp_mask & ~(__GFP_DIRECT_RECLAIM | __GFP_NOFAIL);
 
-		folio = alloc_surplus_hugetlb_folio(h, gfp, nid, nodemask);
+		folio = alloc_surplus_hugetlb_folio(h, gfp, mpoli->nid,
+						    nodemask);
 
 		/* Fallback to all nodes if page==NULL */
 		nodemask = NULL;
 	}
 
-	if (!folio)
-		folio = alloc_surplus_hugetlb_folio(h, gfp_mask, nid, nodemask);
-	mpol_cond_put(mpol);
+	if (!folio) {
+		folio = alloc_surplus_hugetlb_folio(h, gfp_mask, mpoli->nid,
+						    nodemask);
+	}
+
 	return folio;
 }
 
@@ -2853,7 +2855,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	int ret, idx;
 	struct hugetlb_cgroup *h_cg = NULL;
 	struct hugetlb_cgroup *h_cg_rsvd = NULL;
-	gfp_t gfp = htlb_alloc_mask(h) | __GFP_RETRY_MAYFAIL;
+	gfp_t gfp = htlb_alloc_mask(h);
 
 	idx = hstate_index(h);
 
@@ -2925,8 +2927,24 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		folio = dequeue_hugetlb_folio_vma(h, vma, addr);
 
 	if (!folio) {
+		struct mempolicy_interpreted mpoli;
+		struct mempolicy *mpol;
+		nodemask_t *nodemask;
+		int nid;
+
 		spin_unlock_irq(&hugetlb_lock);
-		folio = alloc_buddy_hugetlb_folio_with_mpol(h, vma, addr);
+		nid = huge_node(vma, addr, gfp, &mpol, &nodemask);
+		mpoli = (struct mempolicy_interpreted){
+			.nid = nid,
+#ifdef CONFIG_NUMA
+			.mode = mpol ? mpol->mode : MPOL_DEFAULT,
+#else
+			.mode = MPOL_DEFAULT,
+#endif
+			.nodemask = nodemask,
+		};
+		folio = alloc_buddy_hugetlb_folio(h, gfp, &mpoli);
+		mpol_cond_put(mpol);
 		if (!folio)
 			goto out_uncharge_cgroup;
 		spin_lock_irq(&hugetlb_lock);
@@ -2982,7 +3000,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		}
 	}
 
-	ret = mem_cgroup_charge_hugetlb(folio, gfp);
+	ret = mem_cgroup_charge_hugetlb(folio, gfp | __GFP_RETRY_MAYFAIL);
 	/*
 	 * Unconditionally increment NR_HUGETLB here. If it turns out that
 	 * mem_cgroup_charge_hugetlb failed, then immediately free the page and

-- 
2.55.0.rc0.799.gd6f94ed593-goog

