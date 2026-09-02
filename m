From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 02 Sep 2026 01:22:56 -0700
Subject: [PATCH 1/2] mm: hugetlb: Return -ENOSPC on memcg charge failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-hugetlb-alloc-folio-memcg-charge-error-handling-v1-1-e3e8942c141b@google.com>
References: <20260902-hugetlb-alloc-folio-memcg-charge-error-handling-v1-0-e3e8942c141b@google.com>
In-Reply-To: <20260902-hugetlb-alloc-folio-memcg-charge-error-handling-v1-0-e3e8942c141b@google.com>
To: Alex Shi <alexs@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Dongliang Mu <dzm91@hust.edu.cn>, 
 Hongxiang Lou <louhongxiang@huawei.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Jonathan Corbet <corbet@lwn.net>, 
 Joshua Hahn <joshua.hahnjy@gmail.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Miaohe Lin <linmiaohe@huawei.com>, Michal Hocko <mhocko@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Muchun Song <muchun.song@linux.dev>, 
 Nhat Pham <nphamcs@gmail.com>, Oscar Salvador <osalvador@suse.de>, 
 Peter Xu <peterx@redhat.com>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, 
 Shuah Khan <skhan@linuxfoundation.org>, jthoughton@google.com, 
 fvdl@google.com, rientjes@google.com, vannapurve@google.com, 
 Suren Baghdasaryan <surenb@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Wupeng Ma <mawupeng1@huawei.com>, Yanteng Si <si.yanteng@linux.dev>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 Ackerley Tng <ackerleytng@google.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788337379; l=2356;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=/vykoq6S6jD//j5trcHGMPdPAWTe6fd8Rz8OBB/ktN8=;
 b=wfhCNMZJJPNgBW2NCuyx+S9kXKexZ/7agd6XgUhL9IqhUo4tUieNAIWP9hMWipNtrK3C44qW0
 13Wicfdb6QrCDmoerV5o/WOzDWglesoWpZgvyIRqJUraxYeITnwVTp2
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When mem_cgroup_charge_hugetlb() fails with -ENOMEM, alloc_hugetlb_folio()
currently propagates this error. This results in the page fault handler
returning VM_FAULT_OOM.

Because HugeTLB allocations are high-order and use __GFP_RETRY_MAYFAIL,
they bypass the OOM killer. Returning VM_FAULT_OOM to the #PF handler
without triggering the OOM killer (or having it make progress) leads to
an infinite loop of retrying the fault.

Avoid this loop by returning -ENOSPC when charging fails, which maps to
VM_FAULT_SIGBUS, terminating the process cleanly.

Make mem_cgroup_charge_hugetlb() fault handling use a common error handling
path, the same handling used for hugetlb_cgroup_uncharge_cgroup{,_rsvd}(),
which also don't trigger the OOM killer and hence opt to terminate the
process with a SIGBUS.

Fixes: 991135774c0e0 ("memcg/hugetlb: introduce mem_cgroup_charge_hugetlb")
Cc: stable@vger.kernel.org
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 mm/hugetlb.c | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 7857728457952..01b57f6d3b804 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -2823,7 +2823,6 @@ void wait_for_freed_hugetlb_folios(void)
  *
  * Return: A pointer to the allocated folio, or an ERR_PTR on failure.
  *         -ENOSPC if cgroup charging fails or no folio is available.
- *         -ENOMEM if mem cgroup charging fails.
  */
 struct folio *hugetlb_alloc_folio(struct hstate *h,
 		struct mempolicy_interpreted *mpoli, u8 alloc_flags)
@@ -2896,7 +2895,18 @@ struct folio *hugetlb_alloc_folio(struct hstate *h,
 		 * were committed to the folio and freeing the folio
 		 * would have cleared those up.
 		 */
-		return ERR_PTR(ret);
+		/*
+		 * Return -ENOSPC when this function fails to allocate
+		 * or charge a huge page. If a standard (PAGE_SIZE)
+		 * page allocation fails, the OOM killer is given a
+		 * chance to run, which may resolve the failure on
+		 * retry. However, for HugeTLB allocations, the OOM
+		 * killer is not triggered.  Returning -ENOMEM (or
+		 * anything resulting in VM_FAULT_OOM) would leak to
+		 * the #PF handler, causing it to loop indefinitely
+		 * retrying the fault.
+		 */
+		return ERR_PTR(-ENOSPC);
 	}
 
 	return folio;

-- 
2.55.0.970.g62bdec98f9-goog

