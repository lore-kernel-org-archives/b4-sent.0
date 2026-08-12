From: Kairui Song <kasong@tencent.com>
Date: Thu, 13 Aug 2026 02:48:56 +0800
Subject: [PATCH v2 16/17] mm/huge_memory: clarify supported split orders in
 comment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-swap-thp-cleanup-v2-16-d2ee48c6aa49@tencent.com>
References: <20260813-swap-thp-cleanup-v2-0-d2ee48c6aa49@tencent.com>
In-Reply-To: <20260813-swap-thp-cleanup-v2-0-d2ee48c6aa49@tencent.com>
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
 Shivam Kalra <shivamkalra98@zohomail.in>, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786560551; l=1942;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=MHV5HzFK6Fi4cPV8SFNP30qZtKhPmUDpBG5x8ElzA/A=;
 b=ghP6fLeoLxLoroMH0xcm5w5WQj8k6/m3y+SZvLRMFwxVcxjdFYirWizt0zQPbmWw57lhiicW0
 5cVPzTHsKKrClDHF0+q3wVSo93k9BPwBjQ61TTQufmua/1apoI5yAB0
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The doc comment for __split_huge_page_to_list_to_order() needs an
update: only order 1 is rejected for anon and swapcache folios,
matching the new_order == 1 check in folio_check_splittable().

Also realign the continuation line of the function signature while at
it.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 11 +++++------
 1 file changed, 5 insertions(+), 6 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 317e5b63d44b..c8ec12f6f471 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4406,11 +4406,10 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
  *    GUP pins, will result in the folio not getting split; instead, the caller
  *    will receive an -EAGAIN.
  *
- * 4) @new_order > 1, usually. Order-1 is not supported for anon or swapcache
- *    folios: anon folios need subpage 2 for _deferred_list, which order-1
- *    folios lack, and a swapcache folio may become anon once faulted in.
- *    File-backed order-1 folios are supported, since they do not use
- *    _deferred_list.
+ * 4) @new_order != 1 for anon or swapcache. Anon folios need subpage 2 for
+ *    _deferred_list, which order-1 folios lack, and a swapcache folio may
+ *    become anon once faulted in. File-backed order-1 folios are supported,
+ *    since they do not use _deferred_list.
  *
  * After splitting, the caller's folio reference will be transferred to @page,
  * resulting in a raised refcount of @page after this call. The other pages may
@@ -4438,7 +4437,7 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
  * with the folio. Splitting to order 0 is compatible with all folios.
  */
 int __split_huge_page_to_list_to_order(struct page *page, struct list_head *list,
-				     unsigned int new_order)
+				       unsigned int new_order)
 {
 	struct folio *folio = page_folio(page);
 

-- 
2.55.0

