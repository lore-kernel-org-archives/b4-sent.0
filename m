From: Kairui Song <kasong@tencent.com>
Date: Sat, 14 Nov 2026 05:26:23 +0800
Subject: [PATCH RFC 7/8] mm/huge_memory: walk the after-split anon folios
 in reverse order
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-swap-thp-split-v1-7-dfa8d4fa448d@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794605194; l=2204;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=b73U95HEn/sFMHZHf5dLhjLZSLi/GMxez+2xE4t43Nc=;
 b=70EsV5Uha41PjuPYxhWxWFvxuyMQ0o4A1mtGI917jUBg/etMrn8S6YMm7q+tJXy9XsBoKFNy5
 KgC9YTrm+YIDDLdn2hg/4O0StaQTY/e7i5dpk8foYPEWf6bNteg3Zi7
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Just like the file folio, walk the after-split range with folio_prev()
so the pieces are queued in ascending reclaim order where the forward
walk left them descending, and the cached "next" goes away. All of its
users either expects an ascending or do not care.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index e16b93318613..2ff201a5e5f3 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4076,7 +4076,7 @@ static int __folio_freeze_split_anon(struct folio *folio,
 	struct folio *end_folio = folio_next(folio);
 	struct swap_cluster_info *ci = NULL;
 	const int old_order = folio_order(folio);
-	struct folio *new_folio, *next;
+	struct folio *new_folio;
 	struct anon_vma *anon_vma = NULL;
 	enum ttu_flags ttu_flags = 0;
 	struct lruvec *lruvec;
@@ -4137,15 +4137,15 @@ static int __folio_freeze_split_anon(struct folio *folio,
 	ret = __split_frozen_folio(folio, new_order, split_at, NULL, split_type);
 
 	/*
-	 * Unfreeze the after-split folios and put them back to the right
-	 * place. Keep the head @folio frozen until the end: sub entries
-	 * in swap cache must be updated first, so a concurrent
-	 * swap_cache_get_folio() cannot return the head folio for a sub
-	 * entry (folio_try_get() will fail on the head @folio until unfreeze).
+	 * Unfreeze the after-split folios and put them back, keeping @folio
+	 * frozen until every sub entry in the swap cache is repointed, so
+	 * that a racing swap_cache_get_folio() cannot folio_try_get() the
+	 * head.  Backward is also the reclaim order: the pieces queue just
+	 * before @folio on the LRU, or at the tail of @list, both drained
+	 * from the tail.
 	 */
-	for (new_folio = folio_next(folio); new_folio != end_folio;
-	     new_folio = next) {
-		next = folio_next(new_folio);
+	for (new_folio = folio_prev(end_folio); new_folio != folio;
+	     new_folio = folio_prev(new_folio)) {
 		zone_device_private_split_cb(folio, new_folio);
 		folio_ref_unfreeze(new_folio,
 				   folio_swapcache_ref_count(new_folio) + 1);

-- 
2.56.1

