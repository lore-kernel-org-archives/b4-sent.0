From: Kairui Song <kasong@tencent.com>
Date: Sat, 14 Nov 2026 05:26:20 +0800
Subject: [PATCH RFC 4/8] mm/huge_memory: walk the after-split file folios
 in reverse order
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-swap-thp-split-v1-4-dfa8d4fa448d@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794605194; l=4209;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=5RcEb+SDUe2Odh3xMkEh76RLv2cvnpFfdB3Sf/OMRkM=;
 b=SpVjGzS1NGVb8J1ELrgC77295ZiYjOgl2efqf5zi8EtFc672KCE7Kk65kpazdOgAQfDUTkuo+
 P6SDBWUz2HcBQrZZvr6HWVIPvnE27x83Wsb5L3gxtYagCMSe9e5cFsA
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the new folio_prev() to walk the after-split range backwards. The
@folio is still unfrozen after the loop, so it remains the last folio to
be unfrozen and stays frozen until every page cache entry that used
to point at it has been repointed to an after-split folio.

This improves the code in two ways: A local variable is saved, and this
is also the order the LRU wants.  lru_add_split_folio() inserts each
sub-folio with list_add_tail(), just before @folio on the LRU, or at
the tail of @list. The LRU is drained from the tail, so with the
reverse walk, @folio goes first, then next to it is the
first sub folio, and the pieces are reclaimed in ascending order, where
the forward walk left them descending which is not the correct order.

And even if the folio is isolated, almost all split callers drain the
list from the tail (lru_to_folio() is head->prev). With s1
.. s4 the four sub-folios in ascending address order and @folio
holding the first pages of the range, we have:

  For a folio on the LRU (list == NULL), reading head to tail:

  Before (forward): [ .. s1 s2 s3 s4 folio ]  reclaimed: folio s4 s3 s2 s1
  After  (reverse): [ .. s4 s3 s2 s1 folio ]  reclaimed: folio s1 s2 s3 s4

  For a folio the caller isolated off the LRU, reading head to tail:

  Before (forward): [ .. s1 s2 s3 s4 ]        consumed: s4 s3 s2 s1
  After  (reverse): [ .. s4 s3 s2 s1 ]        consumed: s1 s2 s3 s4

Migration is the one @list user that walks its list from the head; that
list is only a work queue and the order carries no meaning there. We may
unify that part too if needed.

The effect is not very measurable in real workloads but we can get it
right while reducing stack usage, so let's do that.

This also helps avoid a for loop pitfall mentioned by Zi Yan [1]:
folio_next() needs the folio it is given to stay alive until the
increment, folio_prev() does not.  So the cached next pointer and its
comment can go.

The anon helper still walks forward, and will be converted separately.

Link: https://lore.kernel.org/r/DKJSFCLP967N.YBR4DNK1NM2N@nvidia.com [1]
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 23 +++++++++++------------
 1 file changed, 11 insertions(+), 12 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index b60fd73fe35c..3d3a82a03149 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4187,7 +4187,7 @@ static int __folio_freeze_split_file(struct folio *folio,
 	XA_STATE(xas, &mapping->i_pages, folio->index);
 	struct folio *end_folio = folio_next(folio);
 	struct mem_cgroup *memcg, *old_memcg;
-	struct folio *new_folio, *next;
+	struct folio *new_folio;
 	int nr_shmem_dropped = 0;
 	unsigned int min_order;
 	struct lruvec *lruvec;
@@ -4273,20 +4273,19 @@ static int __folio_freeze_split_file(struct folio *folio,
 	ret = __split_frozen_folio(folio, new_order, split_at, &xas, split_type);
 
 	/*
-	 * Unfreeze after-split folios and put them back to the right
-	 * list. @folio should be kept frozen until page cache
-	 * entries are updated with all the other after-split folios
-	 * to prevent others seeing stale page cache entries.
-	 * As a result, new_folio starts from the next folio of
-	 * @folio.
+	 * Unfreeze the after-split folios and put them back on the right
+	 * list, walking the range in reverse so @folio is unfrozen last.
+	 * It stays frozen until then, so a parallel lookup cannot
+	 * folio_try_get() @folio and see a stale page cache entry.
+	 *
+	 * Reverse is also the reclaim order: sub-folios are inserted right
+	 * before @folio, or at the end of @list, and the LRU is drained
+	 * from the tail, so the last one added goes first.
 	 */
-	for (new_folio = folio_next(folio); new_folio != end_folio;
-	     new_folio = next) {
+	for (new_folio = folio_prev(end_folio); new_folio != folio;
+	     new_folio = folio_prev(new_folio)) {
 		unsigned long nr_pages = folio_nr_pages(new_folio);
 
-		/* compute next before the folio can be freed below */
-		next = folio_next(new_folio);
-
 		folio_ref_unfreeze(new_folio, nr_pages + 1);
 		lru_add_split_folio(folio, new_folio, lruvec, list);
 

-- 
2.56.1

