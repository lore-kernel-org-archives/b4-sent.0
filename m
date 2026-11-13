From: Kairui Song <kasong@tencent.com>
Date: Sat, 14 Nov 2026 05:26:21 +0800
Subject: [PATCH RFC 5/8] mm/huge_memory: publish split folios by walking
 backwards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-swap-thp-split-v1-5-dfa8d4fa448d@tencent.com>
References: <20261114-swap-thp-split-v1-0-dfa8d4fa448d@tencent.com>
In-Reply-To: <20261114-swap-thp-split-v1-0-dfa8d4fa448d@tencent.com>
To: linux-mm@kvack.org
Cc: David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Matthew Wilcox <willy@infradead.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Zi Yan <ziy@nvidia.com>, 
 Nico Pache <nico.pache@linux.dev>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794605194; l=3261;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=Sf46vfrRt4G+zN3kqE3m/RvfsaIDpCNGdcr6uA236Go=;
 b=oZpzJU5a8EodGaJbZWszLOQkq/lIyaXCT4mGPjnh7iWciUzCCPnau5+TY4vnCCA3ZEQ7q2saI
 QN63NVcxFDxAQpo/yZQxb1IZv7CrMRCkJKZphU1t2ITr1F+czqKW4HB
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__xa_store() builds a fresh XA_STATE per after-split folio, so a uniform
order-9 to order-0 split does 511 root walks, which is slow and on the
hot path for file folio splitting.

So instead, just use one XA_STATE iterator, and step back folio by folio
using the new xas_prev_canonical() helper: each iteration is much
cheaper, and publishing costs only one full descent walk.

Also simplify the code by unifying the post-processing of past EOF
folios.  We may store a few more folios than necessary, but the store is
much cheaper now, the truncate path is unlikely, and it makes the folio
removal convention in a mapping more consistent: the folio being removed
always matches the content in the mapping now.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 35 +++++++++++++++++++----------------
 1 file changed, 19 insertions(+), 16 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 3d3a82a03149..7270baa20d80 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4187,7 +4187,7 @@ static int __folio_freeze_split_file(struct folio *folio,
 	XA_STATE(xas, &mapping->i_pages, folio->index);
 	struct folio *end_folio = folio_next(folio);
 	struct mem_cgroup *memcg, *old_memcg;
-	struct folio *new_folio;
+	struct folio *new_folio, *old_folio;
 	int nr_shmem_dropped = 0;
 	unsigned int min_order;
 	struct lruvec *lruvec;
@@ -4282,28 +4282,31 @@ static int __folio_freeze_split_file(struct folio *folio,
 	 * before @folio, or at the end of @list, and the LRU is drained
 	 * from the tail, so the last one added goes first.
 	 */
+	xas_set_order(&xas, folio->index + old_nr_pages - 1, 0);
+	old_folio = xas_prev_canonical(&xas);
 	for (new_folio = folio_prev(end_folio); new_folio != folio;
 	     new_folio = folio_prev(new_folio)) {
 		unsigned long nr_pages = folio_nr_pages(new_folio);
 
 		folio_ref_unfreeze(new_folio, nr_pages + 1);
 		lru_add_split_folio(folio, new_folio, lruvec, list);
-
-		/* Add the new folio to the page cache. */
-		if (new_folio->index < end) {
-			__xa_store(&mapping->i_pages, new_folio->index,
-				   new_folio, 0);
-			continue;
+		/* Mapping is split, but content is still old folio */
+		WARN_ON_ONCE(xas_get_order(&xas) != folio_order(new_folio));
+		WARN_ON_ONCE(old_folio != folio);
+		/* order 0 store: siblings keep resolving to this slot */
+		xas_store(&xas, new_folio);
+		/* Step off now as the unlink below can free the xa_node */
+		old_folio = xas_prev_canonical(&xas);
+		if (new_folio->index >= end) {
+			/* Drop folio beyond EOF: ->index >= end */
+			if (shmem_mapping(mapping))
+				nr_shmem_dropped += nr_pages;
+			else if (folio_test_clear_dirty(new_folio))
+				folio_account_cleaned(new_folio,
+						      inode_to_wb(mapping->host));
+			__filemap_remove_folio(new_folio, NULL);
+			folio_put_refs(new_folio, nr_pages);
 		}
-
-		/* Drop folio beyond EOF: ->index >= end */
-		if (shmem_mapping(mapping))
-			nr_shmem_dropped += nr_pages;
-		else if (folio_test_clear_dirty(new_folio))
-			folio_account_cleaned(
-				new_folio, inode_to_wb(mapping->host));
-		__filemap_remove_folio(new_folio, NULL);
-		folio_put_refs(new_folio, nr_pages);
 	}
 
 	/*

-- 
2.56.1

