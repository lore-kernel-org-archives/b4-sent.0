From: Kairui Song <kasong@tencent.com>
Date: Wed, 23 Sep 2026 23:32:46 +0200
Subject: [PATCH v6 15/17] mm/huge_memory: clean up after-split folio
 freeing in __folio_split
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-swap-thp-cleanup-v6-15-ba1b4ba72c6f@tencent.com>
References: <20260923-swap-thp-cleanup-v6-0-ba1b4ba72c6f@tencent.com>
In-Reply-To: <20260923-swap-thp-cleanup-v6-0-ba1b4ba72c6f@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790199160; l=2665;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=AQb8VGHmCtACgG3BJvB2LYY1R1HEBncd5BHWOwnHe8M=;
 b=F06ZdTYwgfJVEsPAfkgvPL/eTORiKnaXRd6FY2R/9M89Xtg7PMRDlyTl2fjhQ/0e97jYMuLBm
 bmbM7a7dTJTAjsXllyw2lbB1vjd82/tlqbPT3RSz4CIb88a6/Wu0Bzu
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace free_folio_and_swap_cache() with an explicit folio_free_swap()
and folio_put() in the after-split loop.  free_folio_and_swap_cache()
must trylock it again and re-check folio_mapped() before freeing the
swap cache entries. If the trylock loses a race, the entries are left
behind even though the folio reference is dropped.

The sub folios are still locked here, so just directly call
folio_free_swap() under the lock if it's unmapped, then unlock and
drop the reference.  This makes the swap cache freeing deterministic
and the reference drop explicit.

Reviewed-by: Zi Yan <ziy@nvidia.com>
Reviewed-by: Yeoreum Yun <yeoreum.yun@arm.com>
Reviewed-by: Kiryl Shutsemau (Meta) <kas@kernel.org>
Acked-by: David Hildenbrand (Arm) <david@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 13 ++++++++-----
 1 file changed, 8 insertions(+), 5 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 86583bf1b148..a98f447ae78a 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4325,7 +4325,8 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		struct list_head *list, enum split_type split_type)
 {
 	struct folio *end_folio = folio_next(folio);
-	bool is_anon = folio_test_anon(folio);
+	const bool is_anon = folio_test_anon(folio);
+	const bool is_swapcache = folio_test_swapcache(folio);
 	int old_order = folio_order(folio);
 	struct folio *new_folio, *next;
 	int ret;
@@ -4365,14 +4366,16 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		if (new_folio == page_folio(lock_at))
 			continue;
 
-		folio_unlock(new_folio);
 		/*
 		 * Subpages whose mapping has been zapped may be freed
 		 * earlier, but freeing them requires taking the
-		 * lru_lock, so we defer put_page() on tail pages until
+		 * lru_lock, so we defer folio_put() on tail pages until
 		 * after the split completes.
 		 */
-		free_folio_and_swap_cache(new_folio);
+		if (is_swapcache && !folio_mapped(new_folio))
+			folio_free_swap(new_folio);
+		folio_unlock(new_folio);
+		folio_put(new_folio);
 	}
 
 out:
@@ -4399,7 +4402,7 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
  * isolated from LRU (if applicable)
  *
  * Upon return, the folio is not remapped, split folios are not added to LRU,
- * free_folio_and_swap_cache() is not called, and new folios remain locked.
+ * folio_free_swap() is not called, and new folios remain locked.
  *
  * Return: 0 on success, -EAGAIN if the folio cannot be split (e.g., due to
  *         insufficient reference count or extra pins).

-- 
2.55.0

