From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Wed, 05 Aug 2026 16:48:24 +0530
Subject: [PATCH 1/3] mm/huge_memory: allow splitting mappingless swapcache
 folios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-b4-mappingless-swapcache-v1-1-b1d78ba257ca@zohomail.in>
References: <20260805-b4-mappingless-swapcache-v1-0-b1d78ba257ca@zohomail.in>
In-Reply-To: <20260805-b4-mappingless-swapcache-v1-0-b1d78ba257ca@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Zi Yan <ziy@nvidia.com>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Barry Song <baohua@kernel.org>, 
 Lance Yang <lance.yang@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Shuah Khan <shuah@kernel.org>, Nico Pache <nico.pache@linux.dev>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785928706; l=2824;
 i=shivamkalra98@zohomail.in; s=20260402; h=from:subject:message-id;
 bh=8FMzJVK2ktfmBA3br5AL94P4EAWSWFZ1bi19CraqMDc=;
 b=vFVVaOmpFpx2FC4WlxGKq8HT1cGRL2x/naOSV50p6GJ3D5FhoW2agZET2hqyQ2/wsIkR5HfUk
 holeEC7s6tKAc9aKP5Ewd/xKNVTkdHwvi2HoPABOU3FeEYcq5KCwa8d
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=U8kQSxcte8P8iZ6zB7phIj+Yl+i/5ntifBGuclgypx8=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260402 with auth_id=716
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A shmem folio is removed from its page cache when it is written to swap.
While it remains in the swap cache, it has no address_space mapping, so
folio_check_splittable() mistakes it for a truncated folio and rejects the
split with -EBUSY.

Allow a mappingless folio when it is in the swap cache. Initialize the
XArray state without an address-space mapping, then assign the XArray only
for mapped file folios. The split path already replaces each split folio
in the swap cache while holding the swap-cluster lock.

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/huge_memory.c | 18 +++++++-----------
 1 file changed, 7 insertions(+), 11 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 804b8f6aa557..ecfe40b1400b 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3882,12 +3882,10 @@ int folio_check_splittable(struct folio *folio, unsigned int new_order,
 	VM_WARN_ON_FOLIO(!folio_test_locked(folio), folio);
 	/*
 	 * Folios that just got truncated cannot get split. Signal to the
-	 * caller that there was a race.
-	 *
-	 * TODO: this will also currently refuse folios without a mapping in the
-	 * swapcache (shmem or to-be-anon folios).
+	 * caller that there was a race. A mappingless swapcache folio can be
+	 * either shmem or not yet associated with an anon_vma, and is valid.
 	 */
-	if (!folio->mapping && !folio_test_anon(folio))
+	if (!folio->mapping && !folio_test_swapcache(folio))
 		return -EBUSY;
 
 	/* order-1 is not supported for anonymous THP. */
@@ -4022,10 +4020,7 @@ static int __folio_freeze_and_split_unmapped(struct folio *folio, unsigned int n
 			if (do_lru)
 				lru_add_split_folio(folio, new_folio, lruvec, list);
 
-			/*
-			 * Anonymous folio with swap cache.
-			 * NOTE: shmem in swap cache is not supported yet.
-			 */
+			/* Folio in the swap cache. */
 			if (ci) {
 				__swap_cache_replace_folio(ci, folio, new_folio);
 				continue;
@@ -4103,7 +4098,7 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		struct page *split_at, struct page *lock_at,
 		struct list_head *list, enum split_type split_type)
 {
-	XA_STATE(xas, &folio->mapping->i_pages, folio->index);
+	XA_STATE(xas, NULL, folio->index);
 	struct folio *end_folio = folio_next(folio);
 	bool is_anon = folio_test_anon(folio);
 	struct mem_cgroup *memcg, *old_memcg;
@@ -4158,11 +4153,12 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		}
 		anon_vma_lock_write(anon_vma);
 		mapping = NULL;
-	} else {
+	} else if (folio->mapping) {
 		unsigned int min_order;
 		gfp_t gfp;
 
 		mapping = folio->mapping;
+		xas.xa = &mapping->i_pages;
 		min_order = mapping_min_folio_order(mapping);
 		if (new_order < min_order) {
 			ret = -EINVAL;

-- 
2.43.0

