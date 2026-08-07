From: Kairui Song <kasong@tencent.com>
Date: Sat, 08 Aug 2026 05:17:14 +0800
Subject: [PATCH RFC 13/13] mm/huge_memory: count only swap cache refs in
 anon folio split
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-swap-thp-cleanup-v1-13-689939a7ccc3@tencent.com>
References: <20260808-swap-thp-cleanup-v1-0-689939a7ccc3@tencent.com>
In-Reply-To: <20260808-swap-thp-cleanup-v1-0-689939a7ccc3@tencent.com>
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
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786137467; l=4434;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=6txV4z9147MCY3v3Y112JpwmGarss54hNdYDLN2lhpw=;
 b=XXdvVVkJnsuSqgAphHl1AuGTvhydbgaE1nQ6pBzl6XSvLM9/V7veYYRMKGOANAqlaGxgJnV1b
 LerXbuHpQtTB/9FMV3d50V87DM7K2D5+CgItBEfmSefWnMWMgXfF5CV
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Only __folio_freeze_split_unmap() sees anon folios and swap cache folios
now. The file split helper only handles page cache folios, which hold
exactly folio_nr_pages() references.

Rename folio_cache_ref_count() to folio_swapcache_ref_count() and drop
the anon check so the helper counts what its name says. The file split
helper now uses folio_nr_pages() directly.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 35 +++++++++++++++--------------------
 1 file changed, 15 insertions(+), 20 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index dba53fbb93a8..0d70ee3017c4 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3915,10 +3915,10 @@ int folio_check_splittable(struct folio *folio, unsigned int new_order,
 	return 0;
 }
 
-/* Number of folio references from the pagecache or the swapcache. */
-static unsigned int folio_cache_ref_count(const struct folio *folio)
+/* Number of folio references from the swapcache. */
+static unsigned int folio_swapcache_ref_count(const struct folio *folio)
 {
-	if (folio_test_anon(folio) && !folio_test_swapcache(folio))
+	if (!folio_test_swapcache(folio))
 		return 0;
 	return folio_nr_pages(folio);
 }
@@ -3984,7 +3984,7 @@ static int __folio_freeze_split_unmap(struct folio *folio, unsigned int new_orde
 				    folio_nid(folio), &memcg);
 	}
 
-	if (!folio_ref_freeze(folio, folio_cache_ref_count(folio) + 1)) {
+	if (!folio_ref_freeze(folio, folio_swapcache_ref_count(folio) + 1)) {
 		if (dequeue_deferred) {
 			list_lru_unlock(lru);
 			rcu_read_unlock();
@@ -4027,7 +4027,7 @@ static int __folio_freeze_split_unmap(struct folio *folio, unsigned int new_orde
 	     new_folio = folio_next(new_folio)) {
 		zone_device_private_split_cb(folio, new_folio);
 		folio_ref_unfreeze(new_folio,
-				   folio_cache_ref_count(new_folio) + 1);
+				   folio_swapcache_ref_count(new_folio) + 1);
 		if (do_lru)
 			lru_add_split_folio(folio, new_folio, lruvec, list);
 		if (ci)
@@ -4035,7 +4035,7 @@ static int __folio_freeze_split_unmap(struct folio *folio, unsigned int new_orde
 	}
 
 	zone_device_private_split_cb(folio, NULL);
-	folio_ref_unfreeze(folio, folio_cache_ref_count(folio) + 1);
+	folio_ref_unfreeze(folio, folio_swapcache_ref_count(folio) + 1);
 
 	if (do_lru)
 		lruvec_unlock(lruvec);
@@ -4064,6 +4064,7 @@ static int __folio_freeze_split_unmap_file(struct folio *folio, unsigned int new
 	struct address_space *mapping = folio->mapping;
 	XA_STATE(xas, &mapping->i_pages, folio->index);
 	struct folio *end_folio = folio_next(folio);
+	long old_nr_pages = folio_nr_pages(folio);
 	struct mem_cgroup *memcg, *old_memcg;
 	struct folio *new_folio, *next;
 	int nr_shmem_dropped = 0;
@@ -4135,22 +4136,16 @@ static int __folio_freeze_split_unmap_file(struct folio *folio, unsigned int new
 		goto fail;
 	}
 
-	if (!folio_ref_freeze(folio, folio_cache_ref_count(folio) + 1)) {
+	if (!folio_ref_freeze(folio, old_nr_pages + 1)) {
 		ret = -EAGAIN;
 		goto fail;
 	}
 
-	if (folio_test_pmd_mappable(folio) &&
-	    new_order < HPAGE_PMD_ORDER) {
-		int nr = folio_nr_pages(folio);
-
-		if (folio_test_swapbacked(folio)) {
-			lruvec_stat_mod_folio(folio,
-					      NR_SHMEM_THPS, -nr);
-		} else {
-			lruvec_stat_mod_folio(folio,
-					      NR_FILE_THPS, -nr);
-		}
+	if (folio_test_pmd_mappable(folio) && new_order < HPAGE_PMD_ORDER) {
+		if (folio_test_swapbacked(folio))
+			lruvec_stat_mod_folio(folio, NR_SHMEM_THPS, -old_nr_pages);
+		else
+			lruvec_stat_mod_folio(folio, NR_FILE_THPS, -old_nr_pages);
 	}
 
 	/* lock lru list/PageCompound, ref frozen by page_ref_freeze */
@@ -4175,7 +4170,7 @@ static int __folio_freeze_split_unmap_file(struct folio *folio, unsigned int new
 		next = folio_next(new_folio);
 
 		folio_ref_unfreeze(new_folio,
-				   folio_cache_ref_count(new_folio) + 1);
+				   folio_nr_pages(new_folio) + 1);
 
 		if (do_lru)
 			lru_add_split_folio(folio, new_folio, lruvec, list);
@@ -4203,7 +4198,7 @@ static int __folio_freeze_split_unmap_file(struct folio *folio, unsigned int new
 	 * Otherwise, a parallel folio_try_get() can grab @folio
 	 * and its caller can see stale page cache entries.
 	 */
-	folio_ref_unfreeze(folio, folio_cache_ref_count(folio) + 1);
+	folio_ref_unfreeze(folio, folio_nr_pages(folio) + 1);
 
 	if (do_lru)
 		lruvec_unlock(lruvec);

-- 
2.55.0

