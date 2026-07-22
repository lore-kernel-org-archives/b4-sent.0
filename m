From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 22 Jul 2026 16:41:09 -0700
Subject: [PATCH v4 01/16] mm: hugetlb: Track used_hpages when
 getting/putting pages from subpool
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260722-hugetlb-alloc-failure-fixes-v4-1-88e8b81970dc@google.com>
References: <20260722-hugetlb-alloc-failure-fixes-v4-0-88e8b81970dc@google.com>
In-Reply-To: <20260722-hugetlb-alloc-failure-fixes-v4-0-88e8b81970dc@google.com>
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Nhat Pham <nphamcs@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Peter Xu <peterx@redhat.com>, 
 Wupeng Ma <mawupeng1@huawei.com>, fvdl@google.com, rientjes@google.com, 
 jthoughton@google.com, Mike Kravetz <mike.kravetz@oracle.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Alex Shi <alexs@kernel.org>, 
 Yanteng Si <si.yanteng@linux.dev>, Dongliang Mu <dzm91@hust.edu.cn>, 
 Hongxiang Lou <louhongxiang@huawei.com>, Miaohe Lin <linmiaohe@huawei.com>
Cc: vannapurve@google.com, erdemaktas@google.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 linux-doc@vger.kernel.org, Ackerley Tng <ackerleytng@google.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784763678; l=15585;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=LjOzgnGx28MPv1Yhb1uCUnMcPrMOx9BKzeq+bcSee/E=;
 b=hd6+xuUmlxAzNJra6Q4jn1V7MPjPDpyeeckJSVaSuGFNE9zNfsKAY595pUL3NHsqR1cTzF+9x
 eo25kJ5PB+TCw5zBRMO2mJxkQy2yf2JlZADQOwOU9DhmaLFpCU6fN4N
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hugepage_subpool_put_pages() currently has two distinct responsibilities
that conflict:

1. When size is specified for the mount, max_hpages != -1: Keep track of
   total active pages (allocated + reserved) and decrement this count
   (used_hpages) when a page is freed or allocation fails.
2. When min_size is specified for the mount, min_hpages != -1: Ensure we
   don't drop below the guaranteed minimum, and restore a reservation
   (rsv_hpages) if we do.

This causes trouble because when allocation fails (refer to
alloc_hugetlb_folio()) if gbl_chg = 1 (i.e. no subpool reservation was
taken):

+ To keep used_hpages consistent, HugeTLB needs to call
  hugepage_subpool_put_pages() to restore undo used_hpages being
  incremented
+ But can't call hugepage_subpool_put_pages() if no reservation was
  consumed.

One option would be to conditionally do subpool tracking updates outside of
the hugepage_subpool_put_pages() function, but that would spread logic all
over.

Instead, always track used_hpages, regardless of whether a max_size was
requested for the mount, so that the subpool always knows how many pages
were allocated through it. Every page allocated through the subpool
increments used_hpages, regardless of whether a reservation was taken from
it.

Conceptually, now, every allocation involving a subpool uses a page from
the subpool, which must be returned to the subpool. Every page taken from
the subpool tries to use a subpool reservation. Restoring a page to the
subpool reservations only if the page was taken from subpool
reservations. (If used_hpages >= min_hpages, the page must have not have
been taken from the reservations.)

Always tracking used_hpages provides the subpool with information of both
used and reserved counts to make the correct decision for both max_size and
min_size correctly.

With used_hpages always tracked,

+ subpool_is_free() can be simplified, such that the subpool can be
  declared free if there are no more pages in use.
+ open-coding in hugetlb_reserve_pages() can be removed.

Also update the

+ Documentation for used_hpages in the subpool struct, since it no longer
  matters whether the used pages count against the maximum.
+ Docstring for hugepage_subpool_{get,put}_pages
+ Documentation to use active voice, and remove some details in favor of
  having details documented in the docstring

Also update statfs reporting. Previously, if max_hpages is negative,
used_hpages is static at 0, so returning max_hpages - used_hpages returns
-1 and is always correct. Now, if the subpool doesn't have a maximum
requested size, indicate no limit for free pages (-1). If it does have a
maximum size, report the difference between the requested size and the
number of used pages. This difference is always positive, because if the
mount does have a maximum size, hugepage_subpool_get_pages() ensures that
the subpool usage never exceeds the maximum.

This fixes a bug in hugetlb_unreserve_pages(), where pages are returned to
the subpool regardless of whether it consumed a reservation. The
corresponding bug in the failure handling path of alloc_hugetlb_folio() was
fixed in a833a693a490e.

Fixes: 1c5ecae3a93fa ("hugetlbfs: add minimum size accounting to subpools")
Cc: stable@vger.kernel.org
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/mm/hugetlbfs_reserv.rst              |  17 +--
 .../translations/zh_CN/mm/hugetlbfs_reserv.rst     |  11 +-
 fs/hugetlbfs/inode.c                               |   8 +-
 include/linux/hugetlb.h                            |   4 +-
 mm/hugetlb.c                                       | 118 +++++++++++----------
 5 files changed, 75 insertions(+), 83 deletions(-)

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
index 216e1a0dd0b23..26c0187340636 100644
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
index 2abaf99321e90..34b9a3e1be0fa 100644
--- a/include/linux/hugetlb.h
+++ b/include/linux/hugetlb.h
@@ -38,8 +38,8 @@ struct hugepage_subpool {
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
index 571212b80835e..36fa3fb3945d8 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -129,12 +129,8 @@ static inline bool subpool_is_free(struct hugepage_subpool *spool)
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
@@ -187,13 +183,18 @@ void hugepage_put_subpool(struct hugepage_subpool *spool)
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
@@ -205,15 +206,14 @@ static long hugepage_subpool_get_pages(struct hugepage_subpool *spool,
 
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
@@ -234,11 +234,19 @@ static long hugepage_subpool_get_pages(struct hugepage_subpool *spool,
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
@@ -251,19 +259,24 @@ static long hugepage_subpool_put_pages(struct hugepage_subpool *spool,
 
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
@@ -6542,7 +6555,7 @@ long hugetlb_reserve_pages(struct inode *inode,
 		struct vm_area_struct *vma,
 		vma_flags_t vma_flags)
 {
-	long chg = -1, add = -1, spool_resv, gbl_resv;
+	long chg = -1, add = -1, gbl_resv;
 	struct hstate *h = hstate_inode(inode);
 	struct hugepage_subpool *spool = subpool_inode(inode);
 	struct resv_map *resv_map;
@@ -6622,9 +6635,9 @@ long hugetlb_reserve_pages(struct inode *inode,
 	 * the subpool has a minimum size, there may be some global
 	 * reservations already in place (gbl_reserve).
 	 */
-	gbl_reserve = hugepage_subpool_get_pages(spool, chg);
-	if (gbl_reserve < 0) {
-		err = gbl_reserve;
+	gbl_resv = hugepage_subpool_get_pages(spool, chg);
+	if (gbl_resv < 0) {
+		err = gbl_resv;
 		goto out_uncharge_cgroup;
 	}
 
@@ -6632,7 +6645,7 @@ long hugetlb_reserve_pages(struct inode *inode,
 	 * Check enough hugepages are available for the reservation.
 	 * Hand the pages back to the subpool if there are not
 	 */
-	err = hugetlb_acct_memory(h, gbl_reserve);
+	err = hugetlb_acct_memory(h, gbl_resv);
 	if (err < 0)
 		goto out_put_pages;
 
@@ -6651,7 +6664,7 @@ long hugetlb_reserve_pages(struct inode *inode,
 		add = region_add(resv_map, from, to, regions_needed, h, h_cg);
 
 		if (unlikely(add < 0)) {
-			hugetlb_acct_memory(h, -gbl_reserve);
+			hugetlb_acct_memory(h, -gbl_resv);
 			err = add;
 			goto out_put_pages;
 		} else if (unlikely(chg > add)) {
@@ -6687,26 +6700,21 @@ long hugetlb_reserve_pages(struct inode *inode,
 	}
 	return chg;
 
-out_put_pages:
-	spool_resv = chg - gbl_reserve;
-	if (spool_resv) {
-		/* put sub pool's reservation back, chg - gbl_reserve */
-		gbl_resv = hugepage_subpool_put_pages(spool, spool_resv);
-		/*
-		 * subpool's reserved pages can not be put back due to race,
-		 * return to hstate.
-		 */
-		hugetlb_acct_memory(h, -gbl_resv);
-	}
-	/* Restore used_hpages for pages that failed global reservation */
-	if (gbl_reserve && spool) {
-		unsigned long flags;
+ out_put_pages:
+	/*
+	 * Return all that was requested from the subpool, let subpool
+	 * tell us the new number of reservations that need to be
+	 * returned to the global pool.
+	 */
+	gbl_reserve = hugepage_subpool_put_pages(spool, chg);
+	/*
+	 * There may be a difference between the number of
+	 * reservations to consume and the number to restore now if
+	 * there are multiple threads interacting with the subpool -
+	 * restore the difference.
+	 */
+	hugetlb_acct_memory(h, gbl_resv - gbl_reserve);
 
-		spin_lock_irqsave(&spool->lock, flags);
-		if (spool->max_hpages != -1)
-			spool->used_hpages -= gbl_reserve;
-		unlock_or_release_subpool(spool, flags);
-	}
 out_uncharge_cgroup:
 	hugetlb_cgroup_uncharge_cgroup_rsvd(hstate_index(h),
 					    chg * pages_per_huge_page(h), h_cg);

-- 
2.55.0.229.g6434b31f56-goog

