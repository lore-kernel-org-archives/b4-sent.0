From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 16 Sep 2026 16:39:01 -0700
Subject: [PATCH v3 1/4] mm: hugetlb: Track used_hpages when getting/putting
 pages from subpool
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260916-hugetlb-subpool-always-track-used-v3-1-38aae9b5ccdd@google.com>
References: <20260916-hugetlb-subpool-always-track-used-v3-0-38aae9b5ccdd@google.com>
In-Reply-To: <20260916-hugetlb-subpool-always-track-used-v3-0-38aae9b5ccdd@google.com>
To: Alex Shi <alexs@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Dongliang Mu <dzm91@hust.edu.cn>, 
 Hongxiang Lou <louhongxiang@huawei.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Jonathan Corbet <corbet@lwn.net>, 
 Joshua Hahn <joshua.hahnjy@gmail.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Miaohe Lin <linmiaohe@huawei.com>, Michal Hocko <mhocko@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Muchun Song <muchun.song@linux.dev>, 
 Nhat Pham <nphamcs@gmail.com>, Oscar Salvador <osalvador@suse.de>, 
 Peter Xu <peterx@redhat.com>, Randy Dunlap <rdunlap@infradead.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Suren Baghdasaryan <surenb@google.com>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Wupeng Ma <mawupeng1@huawei.com>, 
 Yanteng Si <si.yanteng@linux.dev>, 
 Naoya Horiguchi <nao.horiguchi@gmail.com>, fvdl@google.com, 
 jthoughton@google.com, rientjes@google.com, vannapurve@google.com
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, Ackerley Tng <ackerleytng@google.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789601945; l=14450;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=1rJLxc1vQs+7R3iQxLs6DJhbnCNS1veJoZJ6u64m6UE=;
 b=p+Y+YmKHxOPhydDivUi3pXAIbjicZ4mIXrvwEKxw0Fz1syw4o01FWso8Z2ePGDeUQ0DBDIsjE
 0lOb3CkL9W7BuoI2stEDqkMEkocf5UjhQU7MGeTr89mBx7yICqXut+/
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HugeTLB subpools currently only track used pages (used_hpages) when a
maximum size limit (max_hpages) is configured.

This breaks minimum size (min_hpages) guarantees. The subpool guarantee
requires that the sum of used pages and remaining subpool reserves
satisfies the configured minimum:

  used_hpages + rsv_hpages >= min_hpages

where used_hpages includes both allocated folios and active reservations.
Therefore, when pages or reservations are released, the maximum number
of reservations the subpool can absorb is:

  limit = max(0, min_hpages - used_hpages)

When used_hpages is untracked and remains zero,
hugepage_subpool_put_pages() assumes limit == min_hpages. It falsely
restores reservations to the subpool even when existing allocations
already satisfy the guarantee.

This false restoration leads to:
1. Leaked global reservations: resv_huge_pages is not decremented,
   reducing the huge pages available for use across the host.
2. Premature freeing: the subpool considers itself unreferenced on
   unmount (rsv_hpages == min_hpages), freeing the subpool while folios
   are still active in page cache and leading to a use-after-free.

Fix this by unconditionally tracking used_hpages in the subpool, and
capping the reservations the subpool can absorb to
(min_hpages - used_hpages).

With used_hpages always tracked:
- subpool_is_free() is simplified to check whether used_hpages is zero.
- hugetlbfs_statfs() is updated to explicitly check for max_hpages == -1;
  previously it relied on (-1 - 0) evaluating to -1, which would now
  underflow and report negative free block counts.

Trace of a false restoration:

1. Mount time:
    + spool->min_hpages = 1 (user requested min_size=2M)
    + spool->max_hpages = -1 (no maximum size specified)
    + spool->rsv_hpages = 1 (reserve min_hpages)
    + spool->used_hpages = 0 (untracked when max_hpages == -1)
    + h->resv_huge_pages = 1 (reserved by hugetlb_acct_memory(h, 1))

2. Shared mapping of 4MB (2 pages) created (mmap with MAP_SHARED):
    + In hugetlb_reserve_pages(), region_chg() finds chg = 2 (pages 0
      and 1 need reservations)
    + hugepage_subpool_get_pages(spool, 2):
        + spool->rsv_hpages = 0 (consumed the 1 subpool reservation)
        + Returns 1 (since this subpool only had 1 reservation)
    + hugetlb_acct_memory(h, 1):
        + h->resv_huge_pages = 2 (incremented from 1 to 2 for the
          global reservation)
        + region_add() records reservations for pages 0 and 1 in
          resv_map

3. Process touches and populates Page 0:
    + hugetlb_no_page() calls alloc_hugetlb_folio()
    + Page 0 reuses the existing reservation (vma_needs_reservation()
      returns 0 => map_chg = MAP_CHG_REUSE = 0)
    + hugepage_subpool_get_pages() is not called (map_chg == 0)
    + dequeue_hugetlb_folio_nodemask() consumes 1 reservation:
      h->resv_huge_pages = 1 (decremented from 2 to 1)

4. Process closes the file and exits:
    + For MAP_SHARED mappings, reservations persist in inode resv_map
    + Page 1 reservation remains active
    + h->resv_huge_pages = 1 (retained for Page 1)

5. File is truncated to 2MB (truncate -s 2M):
    + Truncation invokes remove_inode_hugepages() for range [1, LONG_MAX)
    + Page 1 was never faulted into page cache => freed = 0
    + Calls hugetlb_unreserve_pages(inode, 1, LONG_MAX, freed = 0)
    + region_del() removes Page 1 from resv_map => chg = 1

6. Inside hugetlb_unreserve_pages(): hugepage_subpool_put_pages(1):
    + delta = chg - freed = 1 - 0 = 1
    + Because spool->max_hpages == -1, spool->used_hpages always = 0
    + spool->used_hpages < spool->min_hpages (0 < 1 => true)
      <<== subpool assumes 0 pages are in use, ignoring allocated Page 0
    + spool->rsv_hpages + delta <= spool->min_hpages (0 + 1 <= 1 => true)
    + spool->rsv_hpages += 1 => spool->rsv_hpages = 1
      <<== false reservation restored to subpool
    + Returns 0 (subpool absorbed the reservation)

7. Back in hugetlb_unreserve_pages(): hugetlb_acct_memory():
    + hugetlb_acct_memory(h, -0) does nothing
    + h->resv_huge_pages remains stuck at 1 even though both reservations
      have ended (Page 0 allocated, Page 1 truncated)

8. Later during unmounting:
    + subpool_is_free() checks spool->rsv_hpages == spool->min_hpages
      (1 == 1 => true)
    + The subpool is erroneously considered completely free
    + hugetlb_acct_memory(spool->hstate, -spool->min_hpages) decrements
      h->resv_huge_pages by 1 (1 - 1 = 0), masking the leak on unmount

9. If the folio outlives the inode:
    + When Page 0 is freed, free_huge_folio() attempts to access the
      freed subpool pointer, leading to a use-after-free and double-free.

Fixes: 09a95e29cb30 ("mm/hugetlb: optimize minimum size (min_size) accounting")
Fixes: 1c5ecae3a93fa ("hugetlbfs: add minimum size accounting to subpools")
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Reviewed-by: Joshua Hahn <joshua.hahnjy@gmail.com>
Cc: stable@vger.kernel.org
---
 Documentation/mm/hugetlbfs_reserv.rst              | 17 +----
 .../translations/zh_CN/mm/hugetlbfs_reserv.rst     | 11 +---
 fs/hugetlbfs/inode.c                               |  8 ++-
 include/linux/hugetlb.h                            |  4 +-
 mm/hugetlb.c                                       | 73 +++++++++++++---------
 5 files changed, 55 insertions(+), 58 deletions(-)

diff --git a/Documentation/mm/hugetlbfs_reserv.rst b/Documentation/mm/hugetlbfs_reserv.rst
index a49115db18c76..d244583fdcbc3 100644
--- a/Documentation/mm/hugetlbfs_reserv.rst
+++ b/Documentation/mm/hugetlbfs_reserv.rst
@@ -314,21 +314,8 @@ huge pages.  If they can not be reserved, the mount fails.
 The routines hugepage_subpool_get/put_pages() are called when pages are
 obtained from or released back to a subpool.  They perform all subpool
 accounting, and track any reservations associated with the subpool.
-hugepage_subpool_get/put_pages are passed the number of huge pages by which
-to adjust the subpool 'used page' count (down for get, up for put).  Normally,
-they return the same value that was passed or an error if not enough pages
-exist in the subpool.
-
-However, if reserves are associated with the subpool a return value less
-than the passed value may be returned.  This return value indicates the
-number of additional global pool adjustments which must be made.  For example,
-suppose a subpool contains 3 reserved huge pages and someone asks for 5.
-The 3 reserved pages associated with the subpool can be used to satisfy part
-of the request.  But, 2 pages must be obtained from the global pools.  To
-relay this information to the caller, the value 2 is returned.  The caller
-is then responsible for attempting to obtain the additional two pages from
-the global pools.
-
+hugepage_subpool_get/put_pages() use the number of huge pages passed to adjust
+the subpool 'used page' count.
 
 COW and Reservations
 ====================
diff --git a/Documentation/translations/zh_CN/mm/hugetlbfs_reserv.rst b/Documentation/translations/zh_CN/mm/hugetlbfs_reserv.rst
index 20947f8bd0654..ae1f1f31477fc 100644
--- a/Documentation/translations/zh_CN/mm/hugetlbfs_reserv.rst
+++ b/Documentation/translations/zh_CN/mm/hugetlbfs_reserv.rst
@@ -246,15 +246,8 @@ hugepage_subpool的min_hpages字段中被跟踪。在挂载时，hugetlb_acct_me
 被调用以预留指定数量的巨页。如果它们不能被预留，挂载就会失败。
 
 当从子池中获取或释放页面时，会调用hugepage_subpool_get/put_pages()函数。
-hugepage_subpool_get/put_pages被传递给巨页数量，以此来调整子池的 “已用页面” 计数
-（get为下降，put为上升）。通常情况下，如果子池中没有足够的页面，它们会返回与传递的相同的值或
-一个错误。
-
-然而，如果预留与子池相关联，可能会返回一个小于传递值的返回值。这个返回值表示必须进行的额外全局
-池调整的数量。例如，假设一个子池包含3个预留的巨页，有人要求5个。与子池相关的3个预留页可以用来
-满足部分请求。但是，必须从全局池中获得2个页面。为了向调用者转达这一信息，将返回值2。然后，调用
-者要负责从全局池中获取另外两个页面。
-
+它们负责所有子池的统计核算，并跟踪与子池相关联的预留。
+hugepage_subpool_get/put_pages()函数使用传入的巨页数量来调整子池的“已用页面”计数。
 
 COW和预留
 ==========
diff --git a/fs/hugetlbfs/inode.c b/fs/hugetlbfs/inode.c
index 7611a8470ea26..5113f743f6fc7 100644
--- a/fs/hugetlbfs/inode.c
+++ b/fs/hugetlbfs/inode.c
@@ -1109,8 +1109,12 @@ static int hugetlbfs_statfs(struct dentry *dentry, struct kstatfs *buf)
 
 			spin_lock_irq(&sbinfo->spool->lock);
 			buf->f_blocks = sbinfo->spool->max_hpages;
-			free_pages = sbinfo->spool->max_hpages
-				- sbinfo->spool->used_hpages;
+			if (sbinfo->spool->max_hpages == -1) {
+				free_pages = -1;
+			} else {
+				free_pages = sbinfo->spool->max_hpages -
+					     sbinfo->spool->used_hpages;
+			}
 			buf->f_bavail = buf->f_bfree = free_pages;
 			spin_unlock_irq(&sbinfo->spool->lock);
 			buf->f_files = sbinfo->max_inodes;
diff --git a/include/linux/hugetlb.h b/include/linux/hugetlb.h
index 16c4c4caa126c..4551ff3023640 100644
--- a/include/linux/hugetlb.h
+++ b/include/linux/hugetlb.h
@@ -39,8 +39,8 @@ struct hugepage_subpool {
 	spinlock_t lock;
 	long count;
 	long max_hpages;	/* Maximum huge pages or -1 if no maximum. */
-	long used_hpages;	/* Used count against maximum, includes */
-				/* both allocated and reserved pages. */
+	long used_hpages;	/* Used page count, includes both */
+				/* allocated and reserved pages. */
 	struct hstate *hstate;
 	long min_hpages;	/* Minimum huge pages or -1 if no minimum. */
 	long rsv_hpages;	/* Pages reserved against global pool to */
diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 4f6f58bf3db6c..e72e22f887478 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -130,12 +130,8 @@ static inline bool subpool_is_free(struct hugepage_subpool *spool)
 {
 	if (spool->count)
 		return false;
-	if (spool->max_hpages != -1)
-		return spool->used_hpages == 0;
-	if (spool->min_hpages != -1)
-		return spool->rsv_hpages == spool->min_hpages;
 
-	return true;
+	return spool->used_hpages == 0;
 }
 
 static inline void unlock_or_release_subpool(struct hugepage_subpool *spool,
@@ -193,13 +189,18 @@ void hugepage_put_subpool(struct hugepage_subpool *spool)
 	unlock_or_release_subpool(spool, flags);
 }
 
-/*
- * Subpool accounting for allocating and reserving pages.
- * Return -ENOMEM if there are not enough resources to satisfy the
- * request.  Otherwise, return the number of pages by which the
- * global pools must be adjusted (upward).  The returned value may
- * only be different than the passed value (delta) in the case where
- * a subpool minimum size must be maintained.
+/**
+ * hugepage_subpool_get_pages - Get pages from a subpool
+ * @spool: pointer to subpool structure (may be NULL)
+ * @delta: number of pages to allocate or reserve
+ *
+ * Check and update subpool page usage counts when allocating or
+ * reserving @delta hugepages.
+ *
+ * Context: Takes spool->lock using spin_lock_irq().
+ * Return: Non-negative number of reservations that cannot be
+ *         satisfied by the subpool, or -ENOMEM if the subpool maximum
+ *         limit would be exceeded.
  */
 static long hugepage_subpool_get_pages(struct hugepage_subpool *spool,
 				      long delta)
@@ -211,15 +212,14 @@ static long hugepage_subpool_get_pages(struct hugepage_subpool *spool,
 
 	spin_lock_irq(&spool->lock);
 
-	if (spool->max_hpages != -1) {		/* maximum size accounting */
-		if ((spool->used_hpages + delta) <= spool->max_hpages)
-			spool->used_hpages += delta;
-		else {
-			ret = -ENOMEM;
-			goto unlock_ret;
-		}
+	if (spool->max_hpages != -1 &&
+	    spool->used_hpages + delta > spool->max_hpages) {
+		ret = -ENOMEM;
+		goto unlock_ret;
 	}
 
+	spool->used_hpages += delta;
+
 	/* minimum size accounting */
 	if (spool->min_hpages != -1 && spool->rsv_hpages) {
 		if (delta > spool->rsv_hpages) {
@@ -240,11 +240,19 @@ static long hugepage_subpool_get_pages(struct hugepage_subpool *spool,
 	return ret;
 }
 
-/*
- * Subpool accounting for freeing and unreserving pages.
- * Return the number of global page reservations that must be dropped.
- * The return value may only be different than the passed value (delta)
- * in the case where a subpool minimum size must be maintained.
+/**
+ * hugepage_subpool_put_pages - Release pages back to a subpool
+ * @spool: pointer to subpool structure (may be NULL)
+ * @delta: number of pages to free or unreserve
+ *
+ * Check and update subpool page usage counts when freeing or
+ * unreserving @delta hugepages.
+ *
+ * Context: Takes spool->lock using spin_lock_irqsave(). May release
+ *          and free @spool if its usage count and references reach
+ *          zero.
+ * Return: Non-negative number of reservations that the subpool cannot
+ *         absorb.
  */
 static long hugepage_subpool_put_pages(struct hugepage_subpool *spool,
 				       long delta)
@@ -257,19 +265,24 @@ static long hugepage_subpool_put_pages(struct hugepage_subpool *spool,
 
 	spin_lock_irqsave(&spool->lock, flags);
 
-	if (spool->max_hpages != -1)		/* maximum size accounting */
-		spool->used_hpages -= delta;
+	spool->used_hpages -= delta;
 
 	 /* minimum size accounting */
 	if (spool->min_hpages != -1 && spool->used_hpages < spool->min_hpages) {
-		if (spool->rsv_hpages + delta <= spool->min_hpages)
+		/*
+		 * limit is the maximum number of reservations that
+		 * can be restored to this subpool.
+		 */
+		long limit = spool->min_hpages - spool->used_hpages;
+
+		if (spool->rsv_hpages + delta <= limit)
 			ret = 0;
 		else
-			ret = spool->rsv_hpages + delta - spool->min_hpages;
+			ret = spool->rsv_hpages + delta - limit;
 
 		spool->rsv_hpages += delta;
-		if (spool->rsv_hpages > spool->min_hpages)
-			spool->rsv_hpages = spool->min_hpages;
+		if (spool->rsv_hpages > limit)
+			spool->rsv_hpages = limit;
 	}
 
 	/*

-- 
2.55.0.1082.g2b9226bbc0-goog

