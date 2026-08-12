From: Kairui Song <kasong@tencent.com>
Date: Thu, 13 Aug 2026 02:48:45 +0800
Subject: [PATCH v2 05/17] mm/huge_memory: rename __split_unmapped_folio()
 to __split_frozen_folio()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-swap-thp-cleanup-v2-5-d2ee48c6aa49@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786560550; l=3653;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=4JjolaupwqTSBLBL65mRa9wmeq9w6In5IrkOzFf5Yfo=;
 b=PHakkmQPHqY39DyzfM8bL3N0JcH49hAnhiemotbeD4OEWgIRduaoR19O8xiqfC1GegF8t58WA
 V373ObQRPxvC2AazrS50uoRBCj2zFpBrAYxFJeJRNzvTQ0Rm2jNeR7S
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The helper splits a folio whose refcount is frozen: the frozen refcount
is the state it relies on, while unmapping is arranged by the caller
beforehand. The old name caused confusion and people may try to call the
helper on non-frozen folios.

Suggested-by: Zi Yan <ziy@nvidia.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 7587eeb09e4a..dfecb93dd64f 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3767,8 +3767,8 @@ static void __split_folio_to_order(struct folio *folio, int old_order,
 }
 
 /**
- * __split_unmapped_folio() - splits an unmapped @folio to lower order folios in
- * two ways: uniform split or non-uniform split.
+ * __split_frozen_folio() - splits a frozen @folio to lower order folios
+ * in two ways: uniform split or non-uniform split.
  * @folio: the to-be-split folio
  * @new_order: the smallest order of the after split folios (since buddy
  *             allocator like split generates folios with orders from @folio's
@@ -3807,7 +3807,7 @@ static void __split_folio_to_order(struct folio *folio, int old_order,
  * Return: 0 - successful, <0 - failed (if -ENOMEM is returned, @folio might be
  * split but not to @new_order, the caller needs to check)
  */
-static int __split_unmapped_folio(struct folio *folio, int new_order,
+static int __split_frozen_folio(struct folio *folio, int new_order,
 		struct page *split_at, struct xa_state *xas,
 		struct address_space *mapping, enum split_type split_type)
 {
@@ -4001,8 +4001,8 @@ static int __folio_freeze_split_unmapped_anon(struct folio *folio, unsigned int
 	if (do_lru)
 		lruvec = folio_lruvec_lock(folio);
 
-	ret = __split_unmapped_folio(folio, new_order, split_at, NULL,
-				     NULL, split_type);
+	ret = __split_frozen_folio(folio, new_order, split_at, NULL,
+				   NULL, split_type);
 
 	/*
 	 * Unfreeze the post-split folios and put them back to the right
@@ -4063,8 +4063,8 @@ static int __folio_freeze_split_unmapped_file(struct folio *folio, unsigned int
 	if (do_lru)
 		lruvec = folio_lruvec_lock(folio);
 
-	ret = __split_unmapped_folio(folio, new_order, split_at, xas,
-				     mapping, split_type);
+	ret = __split_frozen_folio(folio, new_order, split_at, xas,
+				   mapping, split_type);
 
 	/*
 	 * Unfreeze after-split folios and put them back to the right
@@ -4124,9 +4124,9 @@ static int __folio_freeze_split_unmapped_file(struct folio *folio, unsigned int
  * @list: after-split folios will be put on it if non NULL
  * @split_type: perform uniform split or not (non-uniform split)
  *
- * It calls __split_unmapped_folio() to perform uniform and non-uniform split.
+ * It calls __split_frozen_folio() to perform uniform and non-uniform split.
  * It is in charge of checking whether the split is supported or not and
- * preparing @folio for __split_unmapped_folio().
+ * preparing @folio for __split_frozen_folio().
  *
  * After splitting, the after-split folio containing @lock_at remains locked
  * and others are unlocked:
@@ -4229,7 +4229,7 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		i_mmap_lock_read(mapping);
 
 		/*
-		 *__split_unmapped_folio() may need to trim off pages beyond
+		 * __split_frozen_folio() may need to trim off pages beyond
 		 * EOF: but on 32-bit, i_size_read() takes an irq-unsafe
 		 * seqlock, which cannot be nested inside the page tree lock.
 		 * So note end now: i_size itself may be changed at any moment,

-- 
2.55.0

