From: Kairui Song <kasong@tencent.com>
Date: Fri, 21 Aug 2026 02:55:28 +0800
Subject: [PATCH v3 15/18] mm/huge_memory: lift order-0 restriction for
 swapcache split
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-swap-thp-cleanup-v3-15-9b43f5163238@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787252124; l=4239;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=Ck/sQwhNsEW7aOrpnl5OtjvomBAG/W4r8DcOvIJa0P4=;
 b=KLUkvjpHuIejSkFjYK0HMSbyzjaxKoIAJ+uo9IzE7hImYJ+OOK35RtL0A1PuF+MuXjplnbn8O
 wCoG1pOHgkgBZikpmNMeb57klT4fItMH6zmloALB+tQjIjeQVp8zy+z
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The restriction that swapcache folios can only be uniformly split to
order 0 dates back to when the swap cache was managed via address_space
mapping (swap_address_space).  The old split loop only created order-0
sub-folios with a fixed stride, so non-uniform split and non-zero order
were rightfully blocked.

After the swap cache switched to swap table under a cluster lock,
__swap_cache_replace_folio already gained the ability to replace any
number of entries for any sub-folio size in one cluster, and the old
swap_address_space locking and limit was removed. The restriction
became obsolete but persisted through multiple refactorings.

Drop it now: swapcache folios can be split to any supported order with
either uniform or non-uniform split, except order-1 which is not
supported for anon folios. Mappingless swap cache folios could be either
anon or shmem, so for now we just simply forbid order-1 for all swapcache.

Acked-by: Zi Yan <ziy@nvidia.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 31 +++++++++++++------------------
 1 file changed, 13 insertions(+), 18 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 113a33cddace..06f353f937d1 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3797,6 +3797,7 @@ static int __split_frozen_folio(struct folio *folio, int new_order,
 		struct address_space *mapping, enum split_type split_type)
 {
 	const bool is_anon = folio_test_anon(folio);
+	const bool is_swapcache = folio_test_swapcache(folio);
 	int old_order = folio_order(folio);
 	int start_order = split_type == SPLIT_TYPE_UNIFORM ? new_order : old_order - 1;
 	struct folio *old_folio = folio;
@@ -3811,8 +3812,8 @@ static int __split_frozen_folio(struct folio *folio, int new_order,
 	     split_order--) {
 		int nr_new_folios = 1UL << (old_order - split_order);
 
-		/* order-1 anonymous folio is not supported */
-		if (is_anon && split_order == 1)
+		/* order-1 anonymous or swapcache folio is not supported */
+		if ((is_anon || is_swapcache) && split_order == 1)
 			continue;
 
 		if (mapping) {
@@ -3887,19 +3888,13 @@ int folio_check_splittable(struct folio *folio, unsigned int new_order,
 	if (!folio->mapping && !is_swapcache)
 		return -EBUSY;
 
-	/* order-1 is not supported for anonymous THP. */
-	if (is_anon && new_order == 1)
-		return -EINVAL;
-
 	/*
-	 * swapcache folio could only be split to order 0
-	 *
-	 * non-uniform split creates after-split folios with orders from
-	 * folio_order(folio) - 1 to new_order, making it not suitable for any
-	 * swapcache folio split. Only uniform split to order-0 can be used
-	 * here.
+	 * Order-1 is unsupported: anon folios need subpage 2 for the
+	 * deferred split list, hybrid shmem & swap cache folios are not
+	 * splittable, and a splittable mappingless swap cache folio could
+	 * be either anon or shmem, which we cannot tell apart.
 	 */
-	if ((split_type == SPLIT_TYPE_NON_UNIFORM || new_order) && is_swapcache)
+	if ((is_anon || is_swapcache) && new_order == 1)
 		return -EINVAL;
 
 	if (is_huge_zero_folio(folio))
@@ -4405,11 +4400,11 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
  *    GUP pins, will result in the folio not getting split; instead, the caller
  *    will receive an -EAGAIN.
  *
- * 4) @new_order > 1, usually. Splitting to order-1 anonymous folios is not
- *    supported for non-file-backed folios, because folio->_deferred_list, which
- *    is used by partially mapped folios, is stored in subpage 2, but an order-1
- *    folio only has subpages 0 and 1. File-backed order-1 folios are supported,
- *    since they do not use _deferred_list.
+ * 4) @new_order > 1, usually. Order-1 is not supported for anon or swapcache
+ *    folios: anon folios need subpage 2 for _deferred_list, which order-1
+ *    folios lack, and a swapcache folio may become anon once faulted in.
+ *    File-backed order-1 folios are supported, since they do not use
+ *    _deferred_list.
  *
  * After splitting, the caller's folio reference will be transferred to @page,
  * resulting in a raised refcount of @page after this call. The other pages may

-- 
2.55.0

