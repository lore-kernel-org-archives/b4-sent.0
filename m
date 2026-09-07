From: Kairui Song <kasong@tencent.com>
Date: Tue, 08 Sep 2026 02:12:18 +0800
Subject: [PATCH v4 14/17] mm/huge_memory: drop the unused do_lru argument
 of the file split helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-swap-thp-cleanup-v4-14-b532a3f20e71@tencent.com>
References: <20260908-swap-thp-cleanup-v4-0-b532a3f20e71@tencent.com>
In-Reply-To: <20260908-swap-thp-cleanup-v4-0-b532a3f20e71@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788804732; l=2439;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=a/jf5N0ceVT9ic/8DVL2LfIrSgCiaeltQ7+TGC4eqog=;
 b=UUxTwZ1zaeh+CLxeq2MurhCTVbY3kFNfbJnrl2RetkKuvrSFYHsrIxGIEj+I4hCcBR+FgAiGf
 0Gh6OORkTjmDxX0ae4Ym/nKlUhGjPAytxiXOqn5vI+jhtP/yJcvAduz
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The only caller of __folio_freeze_split_file() always passes do_lru as
true, so the argument and the branches gated on it are dead code.
Drop it.

Reviewed-by: Zi Yan <ziy@nvidia.com>
Acked-by: David Hildenbrand (Arm) <david@kernel.org>
Reviewed-by: Yeoreum Yun <yeoreum.yun@arm.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 16 +++++-----------
 1 file changed, 5 insertions(+), 11 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index ccd48cd5f94b..6ce58a5d93d8 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4107,8 +4107,7 @@ static int __folio_freeze_split_anon(struct folio *folio,
 
 static int __folio_freeze_split_file(struct folio *folio,
 		unsigned int new_order, struct page *split_at,
-		bool do_lru, struct list_head *list,
-		enum split_type split_type)
+		struct list_head *list, enum split_type split_type)
 {
 	struct address_space *mapping = folio->mapping;
 	XA_STATE(xas, &mapping->i_pages, folio->index);
@@ -4202,9 +4201,7 @@ static int __folio_freeze_split_file(struct folio *folio,
 	}
 
 	/* lock lru list/PageCompound, ref frozen by page_ref_freeze */
-	if (do_lru)
-		lruvec = folio_lruvec_lock(folio);
-
+	lruvec = folio_lruvec_lock(folio);
 	ret = __split_frozen_folio(folio, new_order, split_at, &xas,
 				   mapping, split_type);
 
@@ -4226,8 +4223,7 @@ static int __folio_freeze_split_file(struct folio *folio,
 		folio_ref_unfreeze(new_folio,
 				   folio_cache_ref_count(new_folio) + 1);
 
-		if (do_lru)
-			lru_add_split_folio(folio, new_folio, lruvec, list);
+		lru_add_split_folio(folio, new_folio, lruvec, list);
 
 		/* Add the new folio to the page cache. */
 		if (new_folio->index < end) {
@@ -4253,9 +4249,7 @@ static int __folio_freeze_split_file(struct folio *folio,
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
@@ -4335,7 +4329,7 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 						true, list, split_type);
 	else
 		ret = __folio_freeze_split_file(folio, new_order, split_at,
-						true, list, split_type);
+						list, split_type);
 
 	/*
 	 * Unlock all after-split folios except the one containing

-- 
2.55.0

