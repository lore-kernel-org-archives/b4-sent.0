From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 16 Sep 2026 16:39:04 -0700
Subject: [PATCH v3 4/4] mm: hugetlb: Avoid re-allocating global
 reservations on region add failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-hugetlb-subpool-always-track-used-v3-4-38aae9b5ccdd@google.com>
References: <20260916-hugetlb-subpool-always-track-used-v3-0-38aae9b5ccdd@google.com>
In-Reply-To: <20260916-hugetlb-subpool-always-track-used-v3-0-38aae9b5ccdd@google.com>
To: Alex Shi <alexs@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Dongliang Mu <dzm91@hust.edu.cn>, 
 Hongxiang Lou <louhongxiang@huawei.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Jonathan Corbet <corbet@lwn.net>, 
 Joshua Hahn <joshua.hahnjy@gmail.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Miaohe Lin <linmiaohe@huawei.com>, Michal Hocko <mhocko@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Muchun Song <muchun.song@linux.dev>, 
 Nhat Pham <nphamcs@gmail.com>, Oscar Salvador <osalvador@suse.de>, 
 Peter Xu <peterx@redhat.com>, Randy Dunlap <rdunlap@infradead.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Suren Baghdasaryan <surenb@google.com>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Wupeng Ma <mawupeng1@huawei.com>, 
 Yanteng Si <si.yanteng@linux.dev>, 
 Naoya Horiguchi <nao.horiguchi@gmail.com>, fvdl@google.com, 
 jthoughton@google.com, rientjes@google.com, vannapurve@google.com
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, Ackerley Tng <ackerleytng@google.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789601945; l=3236;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=9bkEGkyOV+QSeVMa/iDk/E1YpKwvqaT90NhqaQIG64M=;
 b=1XGNWUGnRvXVj0bMgtwgkbvJCSRj9qFIRHBreCl+e2AgqRTZkDsOM2OSA2gB1BLKbsz15xSmP
 MfrGwkkqi1VAaqqDTOsiY3A1fVam18S8s0W1iW3z5Y1JgHhB6P7b5hR
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When reserving huge pages for a shared mapping, reservations are first
requested from the subpool, and any remainder is accounted in global
reservations. When adding the file region entries fails later in the
process, the reservation attempt must be rolled back.

Previously, this error path explicitly dropped the global reservations
that were just acquired before jumping to the cleanup label. The cleanup
label then returned the pages to the subpool. If concurrent activity in
the subpool allowed the subpool to absorb more reservations upon return
than it supplied initially, the cleanup label calculated a positive
difference and attempted to allocate new global reservations from scratch.

This premature release was completely unnecessary because all requested
pages were already backed globally: partly by the mount guarantee and
partly by the global reservations just acquired. Prematurely dissolving
those reservations forced the cleanup path to attempt fresh buddy
allocations that could fail under memory pressure.

Instead, track the number of global reservations actually accounted so
far. In the cleanup label, subtract the already-accounted amount from the
difference between requested and returned reservations. This ensures
that when global reservations were already acquired, the adjustment is
purely non-positive, dropping excess reservations without ever attempting
fresh allocations.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Cc: stable@vger.kernel.org
---
 mm/hugetlb.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 6589b188cf657..ee1ba9ded0ec7 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -6678,6 +6678,7 @@ long hugetlb_reserve_pages(struct inode *inode,
 	struct hugepage_subpool *spool = subpool_inode(inode);
 	struct resv_map *resv_map;
 	struct hugetlb_cgroup *h_cg = NULL;
+	long gbl_resv_accounted = 0;
 	long regions_needed = 0;
 	long gbl_resv_get;
 	long gbl_resv_put;
@@ -6768,6 +6769,7 @@ long hugetlb_reserve_pages(struct inode *inode,
 	err = hugetlb_acct_memory(h, gbl_resv_get);
 	if (err < 0)
 		goto out_put_pages;
+	gbl_resv_accounted = gbl_resv_get;
 
 	/*
 	 * Account for the reservations made. Shared mappings record regions
@@ -6784,7 +6786,6 @@ long hugetlb_reserve_pages(struct inode *inode,
 		add = region_add(resv_map, from, to, regions_needed, h, h_cg);
 
 		if (unlikely(add < 0)) {
-			hugetlb_acct_memory(h, -gbl_resv_get);
 			err = add;
 			goto out_put_pages;
 		} else if (unlikely(chg > add)) {
@@ -6826,9 +6827,10 @@ long hugetlb_reserve_pages(struct inode *inode,
 	 * There may be a difference between the number of
 	 * reservations to consume and the number to restore now if
 	 * there are multiple threads interacting with the subpool -
-	 * restore the difference.
+	 * restore the difference, taking into account any global
+	 * reservations already acquired.
 	 */
-	hugetlb_acct_memory(h, gbl_resv_get - gbl_resv_put);
+	hugetlb_acct_memory(h, gbl_resv_get - gbl_resv_put - gbl_resv_accounted);
 
 out_uncharge_cgroup:
 	hugetlb_cgroup_uncharge_cgroup_rsvd(hstate_index(h),

-- 
2.55.0.1082.g2b9226bbc0-goog

