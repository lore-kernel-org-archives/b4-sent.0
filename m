From: Kairui Song <kasong@tencent.com>
Date: Fri, 21 Aug 2026 02:55:31 +0800
Subject: [PATCH v3 18/18] mm/huge_memory: drop the redundant mapping
 argument of __split_frozen_folio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-swap-thp-cleanup-v3-18-9b43f5163238@tencent.com>
References: <20260821-swap-thp-cleanup-v3-0-9b43f5163238@tencent.com>
In-Reply-To: <20260821-swap-thp-cleanup-v3-0-9b43f5163238@tencent.com>
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
 Shivam Kalra <shivamkalra98@zohomail.in>, Kairui Song <kasong@tencent.com>, 
 Kairui Song <ryncsn@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787252124; l=2730;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=C/KWMIc1TIGmzytCo1JZzeZN1wb37i566yMOyV+S0h4=;
 b=pofJaSAoZPdagM0AwrC0JaDfa+6zRFpa+ZSDQm5WY/uffAKQWRp+Grd+4i7g3llomauI/M5sO
 ei0FFMii7viDibexOhjJv3emPk+9DlA90cruEMHWMOU4KNGEX7o7opn
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mapping parameter only served as a non-NULL check to detect
whether page cache entries need updating.  The xa_state pointer
conveys exactly the same information: the anon split helper passes
NULL and the file split helper passes &xas, which is non-NULL iff
the folio is in the page cache.

Use the xas pointer instead and drop the parameter, along with its
kerneldoc entry.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 11 ++++-------
 1 file changed, 4 insertions(+), 7 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 3e4c0fac7ba6..cc9f7e0d4194 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3761,7 +3761,6 @@ static void __split_folio_to_order(struct folio *folio, int old_order,
  * @split_at: in buddy allocator like split, the folio containing @split_at
  *            will be split until its order becomes @new_order.
  * @xas: xa_state pointing to folio->mapping->i_pages and locked by caller
- * @mapping: @folio->mapping
  * @split_type: if the split is uniform or not (buddy allocator like split)
  *
  *
@@ -3794,7 +3793,7 @@ static void __split_folio_to_order(struct folio *folio, int old_order,
  */
 static int __split_frozen_folio(struct folio *folio, int new_order,
 		struct page *split_at, struct xa_state *xas,
-		struct address_space *mapping, enum split_type split_type)
+		enum split_type split_type)
 {
 	const bool is_anon = folio_test_anon(folio);
 	const bool is_swapcache = folio_test_swapcache(folio);
@@ -3816,7 +3815,7 @@ static int __split_frozen_folio(struct folio *folio, int new_order,
 		if ((is_anon || is_swapcache) && split_order == 1)
 			continue;
 
-		if (mapping) {
+		if (xas) {
 			/*
 			 * uniform split has xas_split_alloc() called before
 			 * irq is disabled to allocate enough memory, whereas
@@ -4030,8 +4029,7 @@ static int __folio_split_unmap_and_freeze(struct folio *folio, unsigned int new_
 	if (do_lru)
 		lruvec = folio_lruvec_lock(folio);
 
-	ret = __split_frozen_folio(folio, new_order, split_at, NULL,
-				   NULL, split_type);
+	ret = __split_frozen_folio(folio, new_order, split_at, NULL, split_type);
 
 	/*
 	 * Unfreeze the post-split folios and put them back to the right
@@ -4185,8 +4183,7 @@ static int __folio_split_unmap_and_freeze_file(struct folio *folio, unsigned int
 
 	/* lock lru list/PageCompound, ref frozen by page_ref_freeze */
 	lruvec = folio_lruvec_lock(folio);
-	ret = __split_frozen_folio(folio, new_order, split_at, &xas,
-				   mapping, split_type);
+	ret = __split_frozen_folio(folio, new_order, split_at, &xas, split_type);
 
 	/*
 	 * Unfreeze after-split folios and put them back to the right

-- 
2.55.0

