From: Kairui Song <kasong@tencent.com>
Date: Thu, 13 Aug 2026 02:48:53 +0800
Subject: [PATCH v2 13/17] mm/huge_memory: drop the unused do_lru argument
 of the file split helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-swap-thp-cleanup-v2-13-d2ee48c6aa49@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786560551; l=3118;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=flVoHm9M5zKLwjUGNriGa0pMoxT0o6QzUJyZyEIqxUE=;
 b=7DHyK/rZjLlMvKwFURyay/2aB1cvnHprN4cS2TRJ0VbuKTx3rnETMs6xNKZNVSwG7/cUwtAo+
 nFEEiTDxTajDsVPW9H95QIQFjwo4VnWNJEkdNJQRdrnRAMEo+g1QN38
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The only caller of __folio_split_unmap_and_freeze_file() always passes
do_lru as true, so the argument and the branches gated on it are dead
code.  Drop it.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 19 ++++++-------------
 1 file changed, 6 insertions(+), 13 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index ce02608b37f4..72e7d24139e6 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4097,8 +4097,6 @@ static int __folio_split_unmap_and_freeze(struct folio *folio, unsigned int new_
  *             smallest order of the after-split folios (non-uniform split)
  * @split_at: in non-uniform split, the folio containing @split_at is split
  *            until its order becomes @new_order
- * @do_lru: if true, add after-split folios to @list if non NULL, otherwise to
- *          the LRU list
  * @list: after-split folios will be put on it if non NULL
  * @split_type: perform uniform split or not (non-uniform split)
  *
@@ -4110,8 +4108,8 @@ static int __folio_split_unmap_and_freeze(struct folio *folio, unsigned int new_
  * is returned, @folio might be split but not to @new_order)
  */
 static int __folio_split_unmap_and_freeze_file(struct folio *folio, unsigned int new_order,
-					       struct page *split_at, bool do_lru,
-					       struct list_head *list, enum split_type split_type)
+					       struct page *split_at, struct list_head *list,
+					       enum split_type split_type)
 {
 	struct address_space *mapping = folio->mapping;
 	XA_STATE(xas, &mapping->i_pages, folio->index);
@@ -4206,9 +4204,7 @@ static int __folio_split_unmap_and_freeze_file(struct folio *folio, unsigned int
 	}
 
 	/* lock lru list/PageCompound, ref frozen by page_ref_freeze */
-	if (do_lru)
-		lruvec = folio_lruvec_lock(folio);
-
+	lruvec = folio_lruvec_lock(folio);
 	ret = __split_frozen_folio(folio, new_order, split_at, &xas,
 				   mapping, split_type);
 
@@ -4226,8 +4222,7 @@ static int __folio_split_unmap_and_freeze_file(struct folio *folio, unsigned int
 		folio_ref_unfreeze(new_folio,
 				   folio_cache_ref_count(new_folio) + 1);
 
-		if (do_lru)
-			lru_add_split_folio(folio, new_folio, lruvec, list);
+		lru_add_split_folio(folio, new_folio, lruvec, list);
 
 		/* Add the new folio to the page cache. */
 		if (new_folio->index < end) {
@@ -4253,9 +4248,7 @@ static int __folio_split_unmap_and_freeze_file(struct folio *folio, unsigned int
 	 * and its caller can see stale page cache entries.
 	 */
 	folio_ref_unfreeze(folio, folio_cache_ref_count(folio) + 1);
-
-	if (do_lru)
-		lruvec_unlock(lruvec);
+	lruvec_unlock(lruvec);
 fail:
 	/*
 	 * If we want to use try_to_migrate() on file in unmap_folio,
@@ -4339,7 +4332,7 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 						     false, list, split_type);
 	else
 		ret = __folio_split_unmap_and_freeze_file(folio, new_order, split_at,
-							  true, list, split_type);
+							  list, split_type);
 
 	/*
 	 * Unlock all after-split folios except the one containing

-- 
2.55.0

