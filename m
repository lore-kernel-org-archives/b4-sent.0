From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 02 Jul 2026 09:21:49 -0700
Subject: [PATCH v4 5/6] mm: hugetlb: Move mem_cgroup_charge_hugetlb()
 earlier in allocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260702-hugetlb-open-up-v4-5-d53cefcccf34@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783009311; l=2464;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=YM0eoEwVRqN15NAQGhn2SLgSWfw138+SGW7+3TQlWbo=;
 b=F0Gzg9RzlR5MOiq9ompvYrScSReWJeOqgKYjCXThSWDFTc0gk7RyAq2vOnuPy5b9E46AKtr8U
 eM0sqLwP6l+AlfwMsVz9SUsbxBp563HNl6n7VndW6W6zk72Qk86xXe3
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move mem_cgroup_charge_hugetlb() earlier in the folio allocation
process. This change draws a cleaner line between memcg charging and the
subsequent hugetlb-specific reservation logic for VMAs and subpools.

While it would be ideal to make all accounting and reservations perfectly
symmetric, mem_cgroup_charge_hugetlb() is a complex operation that cannot
be performed under the hugetlb_lock. Moving the charge to this earlier
point ensures that memcg charging is handled before the code begins
manipulating subpool and VMA-specific state. These two types of accounting
will be separated in a future patch.

If mem_cgroup_charge_hugetlb() fails, the code now branches to
out_subpool_put to ensure the folio is freed and the subpool references are
handled correctly.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 mm/hugetlb.c | 31 ++++++++++++++++++-------------
 1 file changed, 18 insertions(+), 13 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 176b7e9130a38..08ac28111e694 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -2978,6 +2978,24 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 
 	spin_unlock_irq(&hugetlb_lock);
 
+	ret = mem_cgroup_charge_hugetlb(folio, gfp | __GFP_RETRY_MAYFAIL);
+	/*
+	 * Unconditionally increment NR_HUGETLB here. If it turns out that
+	 * mem_cgroup_charge_hugetlb failed, then immediately free the page and
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
+		goto out_subpool_put;
+	}
+
 	hugetlb_set_folio_subpool(folio, spool);
 
 	if (map_chg != MAP_CHG_ENFORCED) {
@@ -3005,19 +3023,6 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		}
 	}
 
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
-		return ERR_PTR(-ENOMEM);
-	}
-
 	return folio;
 
 out_uncharge_cgroup:

-- 
2.55.0.rc0.799.gd6f94ed593-goog

