From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 08 Jul 2026 15:12:53 -0700
Subject: [PATCH v2 5/5] mm: hugetlb: Move memcg charge earlier to prevent
 reservation leak
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-hugetlb-alloc-failure-fixes-v2-5-c7f27cbb462b@google.com>
References: <20260708-hugetlb-alloc-failure-fixes-v2-0-c7f27cbb462b@google.com>
In-Reply-To: <20260708-hugetlb-alloc-failure-fixes-v2-0-c7f27cbb462b@google.com>
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Nhat Pham <nphamcs@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Peter Xu <peterx@redhat.com>, 
 Wupeng Ma <mawupeng1@huawei.com>, fvdl@google.com, rientjes@google.com, 
 jthoughton@google.com
Cc: vannapurve@google.com, erdemaktas@google.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, Ackerley Tng <ackerleytng@google.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783548773; l=2730;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=aDc4LeCjf9Msx78DCPQ6R0pVUvWtCQbT0+pt5lURw5A=;
 b=C/Vy+QfzINHzFrWHsVd2Hc4hHJO95u4DUt+Y/R5xhEOPitzw3jg3OzKoQPYxnnBqtqUyIy91U
 VA+6kJWQ3QyDecXnoBFpg9D6y68TwiYF811Q3SspObCEMxjI1Nd5bFn
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When mem_cgroup_charge_hugetlb() fails, alloc_hugetlb_folio() clears the
charges and frees the folio. The reservation committed via
vma_commit_reservation() was not undone, leaving the reservation map in an
inconsistent state, causing resv_huge_pages to leak when the process
exited.

Fix this by moving the mem_cgroup_charge_hugetlb() call earlier in
alloc_hugetlb_folio(), before vma_commit_reservation() is called.

If the charge fails now, the reservation is not yet committed. Jump to
out_subpool_put, which will then call vma_end_reservation() to abort the
reservation and keep the reservation map and resv_huge_pages counter
consistent.

Fixes: 991135774c0e0 ("memcg/hugetlb: introduce mem_cgroup_charge_hugetlb")
Cc: stable@vger.kernel.org
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 mm/hugetlb.c | 34 ++++++++++++++++++++--------------
 1 file changed, 20 insertions(+), 14 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 3e1d99f03c70e..e000af6f28585 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -2954,6 +2954,25 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 
 	spin_unlock_irq(&hugetlb_lock);
 
+	ret = mem_cgroup_charge_hugetlb(folio, gfp);
+	/*
+	 * Unconditionally increment NR_HUGETLB here. If it turns out that
+	 * mem_cgroup_charge_hugetlb failed, then immediately free the page and
+	 * decrement NR_HUGETLB.
+	 */
+	lruvec_stat_mod_folio(folio, NR_HUGETLB, pages_per_huge_page(h));
+
+	if (ret == -ENOMEM) {
+		folio_put(folio);
+		/*
+		 * Charges to hugetlb_cgroup for usage and
+		 * reservations were already committed, so folio_put()
+		 * would have uncharged those. Go straight to undoing
+		 * subpool charges.
+		 */
+		goto out_subpool_put;
+	}
+
 	hugetlb_set_folio_subpool(folio, spool);
 
 	if (map_chg != MAP_CHG_ENFORCED) {
@@ -2981,19 +3000,6 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		}
 	}
 
-	ret = mem_cgroup_charge_hugetlb(folio, gfp);
-	/*
-	 * Unconditionally increment NR_HUGETLB here. If it turns out that
-	 * mem_cgroup_charge_hugetlb failed, then immediately free the page and
-	 * decrement NR_HUGETLB.
-	 */
-	lruvec_stat_mod_folio(folio, NR_HUGETLB, pages_per_huge_page(h));
-
-	if (ret == -ENOMEM) {
-		folio_put(folio);
-		goto err;
-	}
-
 	return folio;
 
 out_uncharge_cgroup:
@@ -3014,7 +3020,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 out_end_reservation:
 	if (map_chg != MAP_CHG_ENFORCED)
 		vma_end_reservation(h, vma, addr);
-err:
+
 	/*
 	 * Return -ENOSPC when this function fails to allocate or
 	 * charge a huge page. If a standard (PAGE_SIZE) page

-- 
2.55.0.795.g602f6c329a-goog

