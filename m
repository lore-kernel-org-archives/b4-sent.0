From: Kairui Song <kasong@tencent.com>
Date: Tue, 15 Sep 2026 01:14:51 +0800
Subject: [PATCH v5 10/17] mm/huge_memory: move the racy refcount check into
 unmap_folio()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-swap-thp-cleanup-v5-10-39878b37dfb0@tencent.com>
References: <20260915-swap-thp-cleanup-v5-0-39878b37dfb0@tencent.com>
In-Reply-To: <20260915-swap-thp-cleanup-v5-0-39878b37dfb0@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789406149; l=3481;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=6TD9CYMGDYoBQJQWdao35dtOQRgVegEwGFMbqhcYaO0=;
 b=lVGM00QcXpp6HveeRp+JBlSlB+2SK6QZpSYox3k/Ndb9lJ/6B6bASgXEZFd2PRyltk2PVjluZ
 Cv5U5EOzV+OB17/C84FB5+qsjW6nu9RlQipZ6PwX+sJzGCuJVmsoRVg
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The check only exists to avoid the expensive PMD-splitting unmap of a
folio that cannot be split anyway.  Move it from __folio_split() into
unmap_folio(), right before the PMD split, so both the anon and file
split helpers get the early check without repeating it.

unmap_folio() now returns -EAGAIN if the check fails and the split
helpers propagate the error.  folio_split_unmapped() drops its own
copy of the check: it works on already unmapped folios and the
definitive folio_ref_freeze() in __folio_freeze_split_anon() still
catches unexpected references.

Reviewed-by: Zi Yan <ziy@nvidia.com>
Reviewed-by: Kiryl Shutsemau (Meta) <kas@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 29 +++++++++++++----------------
 1 file changed, 13 insertions(+), 16 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 77bf68c9b9af..859aefda7356 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3539,13 +3539,17 @@ void vma_adjust_trans_huge(struct vm_area_struct *vma,
 		split_huge_pmd_if_needed(next, end);
 }
 
-static void unmap_folio(struct folio *folio)
+static int unmap_folio(struct folio *folio)
 {
 	enum ttu_flags ttu_flags = TTU_RMAP_LOCKED | TTU_SYNC |
 		TTU_BATCH_FLUSH;
 
 	VM_BUG_ON_FOLIO(!folio_test_large(folio), folio);
 
+	/* Racy check if we can split the page, before we split PMDs */
+	if (folio_expected_ref_count(folio) != folio_ref_count(folio) - 1)
+		return -EAGAIN;
+
 	if (folio_test_pmd_mappable(folio))
 		ttu_flags |= TTU_SPLIT_HUGE_PMD;
 
@@ -3560,6 +3564,8 @@ static void unmap_folio(struct folio *folio)
 		try_to_unmap(folio, ttu_flags | TTU_IGNORE_MLOCK);
 
 	try_to_unmap_flush();
+
+	return 0;
 }
 
 static bool __discard_anon_folio_pmd_locked(struct vm_area_struct *vma,
@@ -4030,7 +4036,9 @@ static int __folio_freeze_split_anon(struct folio *folio,
 
 	if (folio_mapped(folio)) {
 		need_remap = true;
-		unmap_folio(folio);
+		ret = unmap_folio(folio);
+		if (ret)
+			return ret;
 	}
 
 	local_irq_disable();
@@ -4124,7 +4132,9 @@ static int __folio_freeze_split_file(struct folio *folio,
 	if (shmem_mapping(mapping))
 		end = shmem_fallocend(mapping->host, end);
 
-	unmap_folio(folio);
+	ret = unmap_folio(folio);
+	if (ret)
+		return ret;
 
 	xas_lock_irq(xas);
 
@@ -4332,15 +4342,6 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		i_mmap_lock_read(mapping);
 	}
 
-	/*
-	 * Racy check if we can split the page, before unmap_folio() will
-	 * split PMDs
-	 */
-	if (folio_expected_ref_count(folio) != folio_ref_count(folio) - 1) {
-		ret = -EAGAIN;
-		goto out_unlock;
-	}
-
 	if (is_anon)
 		ret = __folio_freeze_split_anon(folio, new_order, split_at,
 						true, list, split_type);
@@ -4379,7 +4380,6 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		free_folio_and_swap_cache(new_folio);
 	}
 
-out_unlock:
 	if (anon_vma) {
 		anon_vma_unlock_write(anon_vma);
 		put_anon_vma(anon_vma);
@@ -4427,9 +4427,6 @@ int folio_split_unmapped(struct folio *folio, unsigned int new_order)
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_large(folio), folio);
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_anon(folio), folio);
 
-	if (folio_expected_ref_count(folio) != folio_ref_count(folio) - 1)
-		return -EAGAIN;
-
 	return __folio_freeze_split_anon(folio, new_order, &folio->page,
 					 false, NULL, SPLIT_TYPE_UNIFORM);
 }

-- 
2.55.0

