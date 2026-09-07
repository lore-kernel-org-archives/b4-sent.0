From: Kairui Song <kasong@tencent.com>
Date: Tue, 08 Sep 2026 02:12:16 +0800
Subject: [PATCH v4 12/17] mm/huge_memory: move anon_vma handling into the
 anon split helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-swap-thp-cleanup-v4-12-b532a3f20e71@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788804732; l=5440;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=X2P4cDrUHVxhy5NF0vdUxXcb6y1qZnECR0W8Rgpwvlc=;
 b=v8Z0yYqIgMrwAWzCPdCTt0cJposY5TVpHL4ti7vOOeL4283+2IhgBZV5PBP5qd6T/i0Ka0kMu
 OjJxe2nKqfyDOQk5+875jZzJVMipNoOkI8v1PlihNqtS3r3ng5Koyc9
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Only anon split needs the anon_vma, and it only needs it to unmap and
remap.  Move the folio_get_anon_vma()/anon_vma_lock_write() pair out of
__folio_split() into the anon helper next to the folio_mapped()
check that already gates unmap_folio().

This makes the anon_vma conditional on folio_mapped(), which is a
behaviour change but should be fine.  folio_get_anon_vma() returns
NULL whenever !folio_mapped(), so an anon folio with
folio_mapcount() == 0 used to get -EBUSY from split_huge_page() and is
now split instead.  The realistic case is a THP that has been fully
swapped out and is still in the swap cache: swap PTEs do not contribute
mapcount, so it is !folio_mapped() but still alive.

That should be safe and right to have because:

- folio_ref_freeze() below still rejects a folio that picked up any
  reference, a mapping or a GUP pin, in the meantime.

- A parallel split is excluded by the folio lock.  The anon_vma
  write lock was added to serialize split in commit 062f1af2170a
  ("mm: thp: acquire the anon_vma rwsem for write during split"), when
  split_huge_page() did not hold the folio lock throughout. commit
  e9b61f19858a ("thp: reintroduce split_huge_page()") later made the
  folio lock a caller requirement and added the folio_ref_freeze()
  scheme, so that has been covered ever since.

- Unmapped path is already exercised by folio_split_unmapped(),
  and the swap cache split already runs well for a partially
  swapped-out mapped THP.

- folio_get_anon_vma() and folio_lock_anon_vma_read() both bail out
  on !folio_mapped() before taking the anon_vma lock, so there is
  nothing to lock against.

For mapped folios the anon_vma write lock is now released before
__folio_split() unlocks the after-split sub-folios, where previously it
was held across that loop, that window is harmless as the sub-folios
stay folio-locked and ref pinned.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 51 ++++++++++++++++++++++++---------------------------
 1 file changed, 24 insertions(+), 27 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index c4910c0b6018..53614b875794 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4005,16 +4005,31 @@ static int __folio_freeze_split_anon(struct folio *folio,
 	struct swap_cluster_info *ci = NULL;
 	struct folio *new_folio, *next;
 	int old_order = folio_order(folio);
+	struct anon_vma *anon_vma = NULL;
 	enum ttu_flags ttu_flags = 0;
 	struct lruvec *lruvec;
-	bool need_remap = false;
 	int ret = 0;
 
+	/*
+	 * Unmap/remap needs the anon_vma. The caller does not necessarily
+	 * hold an mmap_lock that would prevent the anon_vma from
+	 * disappearing, so we first take a reference and lock it.
+	 *
+	 * An unmapped folio needs none of this: folio_get_anon_vma() and
+	 * folio_lock_anon_vma_read() both bail out on !folio_mapped()
+	 * before taking the lock, and folio_ref_freeze() below still
+	 * rejects a folio that picked up a reference meanwhile. Note
+	 * a swapped-out THP counts as unmapped here as swap PTEs do
+	 * not contribute mapcount, and they are splittable.
+	 */
 	if (folio_mapped(folio)) {
-		need_remap = true;
+		anon_vma = folio_get_anon_vma(folio);
+		if (!anon_vma)
+			return -EBUSY;
+		anon_vma_lock_write(anon_vma);
 		ret = unmap_folio(folio);
 		if (ret)
-			return ret;
+			goto out_unlock;
 	}
 
 	local_irq_disable();
@@ -4076,11 +4091,16 @@ static int __folio_freeze_split_anon(struct folio *folio,
 		swap_cluster_unlock(ci);
 out_no_split:
 	local_irq_enable();
-	if (need_remap) {
+	if (anon_vma) {
 		if (!ret && !folio_is_device_private(folio))
 			ttu_flags = TTU_USE_SHARED_ZEROPAGE;
 		remap_folio(folio, 1 << old_order, ttu_flags);
 	}
+out_unlock:
+	if (anon_vma) {
+		anon_vma_unlock_write(anon_vma);
+		put_anon_vma(anon_vma);
+	}
 
 	return ret;
 }
@@ -4275,7 +4295,6 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 	struct folio *end_folio = folio_next(folio);
 	bool is_anon = folio_test_anon(folio);
 	struct mem_cgroup *memcg, *old_memcg;
-	struct anon_vma *anon_vma = NULL;
 	int old_order = folio_order(folio);
 	struct folio *new_folio, *next;
 	int ret;
@@ -4306,23 +4325,6 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 	memcg = get_mem_cgroup_from_folio(folio);
 	old_memcg = set_active_memcg(memcg);
 
-	if (is_anon) {
-		/*
-		 * The caller does not necessarily hold an mmap_lock that would
-		 * prevent the anon_vma disappearing so we first we take a
-		 * reference to it and then lock the anon_vma for write. This
-		 * is similar to folio_lock_anon_vma_read except the write lock
-		 * is taken to serialise against parallel split or collapse
-		 * operations.
-		 */
-		anon_vma = folio_get_anon_vma(folio);
-		if (!anon_vma) {
-			ret = -EBUSY;
-			goto out;
-		}
-		anon_vma_lock_write(anon_vma);
-	}
-
 	if (is_anon)
 		ret = __folio_freeze_split_anon(folio, new_order, split_at,
 						true, list, split_type);
@@ -4349,11 +4351,6 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 		free_folio_and_swap_cache(new_folio);
 	}
 
-	if (anon_vma) {
-		anon_vma_unlock_write(anon_vma);
-		put_anon_vma(anon_vma);
-	}
-out:
 	/* restore to caller's old_memcg */
 	set_active_memcg(old_memcg);
 	mem_cgroup_put(memcg);

-- 
2.55.0

