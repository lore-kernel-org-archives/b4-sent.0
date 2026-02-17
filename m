From: Kairui Song <kasong@tencent.com>
Date: Wed, 18 Feb 2026 04:06:28 +0800
Subject: [PATCH v3 03/12] mm, swap: remove redundant arguments and locking
 for enabling a device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260218-swap-table-p3-v3-3-f4e34be021a7@tencent.com>
References: <20260218-swap-table-p3-v3-0-f4e34be021a7@tencent.com>
In-Reply-To: <20260218-swap-table-p3-v3-0-f4e34be021a7@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 Youngjun Park <youngjun.park@lge.com>, linux-kernel@vger.kernel.org, 
 Chris Li <chrisl@kernel.org>, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771358806; l=4474;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=7v/yOoUm+JKrDy/cUABunBQ64SLCuHCZ71QcM/9ivnk=;
 b=pe7JYHGn/ycRyxgjvXfgwIlVdmMo/7yYX6nZc5R0wASNkiT41lF4CipymFe7E/R78JWzygbk2
 rfrQGO4XYH1CvtT5mQhICq1K9z8VGrFEWknTZcO7tflKC4tAPK7m94m
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is no need to repeatedly pass zero map and priority values.
zeromap is similar to cluster info and swap_map, which are only used
once the swap device is exposed. And the prio values are currently
read only once set, and only used for the list insertion upon expose
or swap info display.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swapfile.c | 48 ++++++++++++++++++------------------------------
 1 file changed, 18 insertions(+), 30 deletions(-)

diff --git a/mm/swapfile.c b/mm/swapfile.c
index 8fc35b316ade..fb0d48681c48 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -2663,19 +2663,6 @@ static int setup_swap_extents(struct swap_info_struct *sis,
 	return generic_swapfile_activate(sis, swap_file, span);
 }
 
-static void setup_swap_info(struct swap_info_struct *si, int prio,
-			    unsigned long *zeromap)
-{
-	si->prio = prio;
-	/*
-	 * the plist prio is negated because plist ordering is
-	 * low-to-high, while swap ordering is high-to-low
-	 */
-	si->list.prio = -si->prio;
-	si->avail_list.prio = -si->prio;
-	si->zeromap = zeromap;
-}
-
 static void _enable_swap_info(struct swap_info_struct *si)
 {
 	atomic_long_add(si->pages, &nr_swap_pages);
@@ -2689,17 +2676,12 @@ static void _enable_swap_info(struct swap_info_struct *si)
 	add_to_avail_list(si, true);
 }
 
-static void enable_swap_info(struct swap_info_struct *si, int prio,
-			     unsigned long *zeromap)
+/*
+ * Called after the swap device is ready, resurrect its percpu ref, it's now
+ * safe to reference it. Add it to the list to expose it to the allocator.
+ */
+static void enable_swap_info(struct swap_info_struct *si)
 {
-	spin_lock(&swap_lock);
-	spin_lock(&si->lock);
-	setup_swap_info(si, prio, zeromap);
-	spin_unlock(&si->lock);
-	spin_unlock(&swap_lock);
-	/*
-	 * Finished initializing swap device, now it's safe to reference it.
-	 */
 	percpu_ref_resurrect(&si->users);
 	spin_lock(&swap_lock);
 	spin_lock(&si->lock);
@@ -2712,7 +2694,6 @@ static void reinsert_swap_info(struct swap_info_struct *si)
 {
 	spin_lock(&swap_lock);
 	spin_lock(&si->lock);
-	setup_swap_info(si, si->prio, si->zeromap);
 	_enable_swap_info(si);
 	spin_unlock(&si->lock);
 	spin_unlock(&swap_lock);
@@ -3365,7 +3346,6 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 	int nr_extents;
 	sector_t span;
 	unsigned long maxpages;
-	unsigned long *zeromap = NULL;
 	struct folio *folio = NULL;
 	struct inode *inode = NULL;
 	bool inced_nr_rotate_swap = false;
@@ -3481,9 +3461,9 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 	 * Use kvmalloc_array instead of bitmap_zalloc as the allocation order might
 	 * be above MAX_PAGE_ORDER incase of a large swap file.
 	 */
-	zeromap = kvmalloc_array(BITS_TO_LONGS(maxpages), sizeof(long),
-				    GFP_KERNEL | __GFP_ZERO);
-	if (!zeromap) {
+	si->zeromap = kvmalloc_array(BITS_TO_LONGS(maxpages), sizeof(long),
+				     GFP_KERNEL | __GFP_ZERO);
+	if (!si->zeromap) {
 		error = -ENOMEM;
 		goto bad_swap_unlock_inode;
 	}
@@ -3552,10 +3532,17 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 	if (swap_flags & SWAP_FLAG_PREFER)
 		prio = swap_flags & SWAP_FLAG_PRIO_MASK;
 
+	/*
+	 * The plist prio is negated because plist ordering is
+	 * low-to-high, while swap ordering is high-to-low
+	 */
+	si->prio = prio;
+	si->list.prio = -si->prio;
+	si->avail_list.prio = -si->prio;
 	si->swap_file = swap_file;
 
 	/* Sets SWP_WRITEOK, resurrect the percpu ref, expose the swap device */
-	enable_swap_info(si, prio, zeromap);
+	enable_swap_info(si);
 
 	pr_info("Adding %uk swap on %s.  Priority:%d extents:%d across:%lluk %s%s%s%s\n",
 		K(si->pages), name->name, si->prio, nr_extents,
@@ -3585,6 +3572,8 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 	si->swap_map = NULL;
 	free_swap_cluster_info(si->cluster_info, si->max);
 	si->cluster_info = NULL;
+	kvfree(si->zeromap);
+	si->zeromap = NULL;
 	/*
 	 * Clear the SWP_USED flag after all resources are freed so
 	 * alloc_swap_info can reuse this si safely.
@@ -3592,7 +3581,6 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 	spin_lock(&swap_lock);
 	si->flags = 0;
 	spin_unlock(&swap_lock);
-	kvfree(zeromap);
 	if (inced_nr_rotate_swap)
 		atomic_dec(&nr_rotate_swap);
 	if (swap_file)

-- 
2.52.0

