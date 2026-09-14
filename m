From: Kairui Song <kasong@tencent.com>
Date: Tue, 15 Sep 2026 01:14:42 +0800
Subject: [PATCH v5 01/17] mm/swap: fix off-by-one in swap cache replace
 sanity check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-swap-thp-cleanup-v5-1-39878b37dfb0@tencent.com>
References: <20260915-swap-thp-cleanup-v5-0-39878b37dfb0@tencent.com>
In-Reply-To: <20260915-swap-thp-cleanup-v5-0-39878b37dfb0@tencent.com>
To: linux-mm@kvack.org
Cc: linux-kernel@vger.kernel.org, Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Zi Yan <ziy@nvidia.com>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Nico Pache <nico.pache@linux.dev>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Chris Li <chrisl@kernel.org>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <baoquan.he@linux.dev>, 
 Barry Song <baohua@kernel.org>, Youngjun Park <youngjun.park@lge.com>, 
 Yeoreum Yun <yeoreum.yun@arm.com>, 
 "Kiryl Shutsemau (Meta)" <kas@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>, Kairui Song <kasong@tencent.com>, 
 Kairui Song <ryncsn@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789406149; l=1650;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=810n4do4aOKMWihCxqnhsHXg2hcES1SAm+rRly1NOZc=;
 b=TD7AokuIIIO3qHuTryNrrJFaeotme90f+Sx8e3cBvBRNKxx+8aj6JZLK5qKRH21lcwrMz1ac5
 Z6Yn5pDcF3EAmvXXtvcBrZhV529Cqpzegiilz1N9cpCkU/1k+pvbA9g
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DEBUG_VM sanity check in __swap_cache_replace_folio() iterates
the old folio's range with "while (ci_off++ < ci_end)", so the loop
body runs on the already-incremented offset: the first entry is
skipped and one entry past the range is read.  For a folio split
that entry belongs to the first after-split folio and was just
repointed by the replacement loop above, so the check would warn
spuriously whenever sub-folio orders differ from the head folio's.

Currently we don't support non-uniform swapcache split, but this still
needs a fix to clean it up and prepare for non-uniform swap cache split.

Use the same do-while pattern as the replacement loop.

Fixes: 8578e0c00dcf ("mm, swap: use the swap table for the swap cache and switch API")
Acked-by: Zi Yan <ziy@nvidia.com>
Reviewed-by: Barry Song <baohua@kernel.org>
Acked-by: David Hildenbrand (Arm) <david@kernel.org>
Reviewed-by: Yeoreum Yun <yeoreum.yun@arm.com>
Acked-by: Kiryl Shutsemau (Meta) <kas@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swap_state.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/mm/swap_state.c b/mm/swap_state.c
index 625c185a1ca4..cef44aadee61 100644
--- a/mm/swap_state.c
+++ b/mm/swap_state.c
@@ -396,8 +396,9 @@ void __swap_cache_replace_folio(struct swap_cluster_info *ci,
 	    folio_order(old) != folio_order(new)) {
 		ci_off = swp_cluster_offset(old->swap);
 		ci_end = ci_off + folio_nr_pages(old);
-		while (ci_off++ < ci_end)
+		do {
 			WARN_ON_ONCE(swp_tb_to_folio(__swap_table_get(ci, ci_off)) != old);
+		} while (++ci_off < ci_end);
 	}
 }
 

-- 
2.55.0

