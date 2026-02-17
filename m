From: Kairui Song <kasong@tencent.com>
Date: Wed, 18 Feb 2026 04:06:26 +0800
Subject: [PATCH v3 01/12] mm, swap: protect si->swap_file properly and use
 as a mount indicator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260218-swap-table-p3-v3-1-f4e34be021a7@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771358806; l=5423;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=OErUm6YzDXG8MUnIOgrfhhtTdULgZJzpg5xc2rcjJG4=;
 b=KefXHGVHQAdLFCFWu9nqJfG3nJH7rws2nW9hIB7xb9Nm1CovW7LHFC1ilWbZagYgRGOgXBJ9F
 i0WZsakiuEACJSPGsYv8bIL3j90aQTgfDsJQPU/voTO/wk/Fe3jfE8U
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

/proc/swaps uses si->swap_map as the indicator to check if the swap
device is mounted. swap_map will be removed soon, so change it to use
si->swap_file instead because:

- si->swap_file is exactly the only dynamic content that /proc/swaps is
  interested in. Previously, it was checking si->swap_map just to ensure
  si->swap_file is available. si->swap_map is set under mutex
  protection, and after si->swap_file is set, so having si->swap_map set
  guarantees si->swap_file is set.

- Checking si->flags doesn't work here. SWP_WRITEOK is cleared during
  swapoff, but /proc/swaps is supposed to show the device under swapoff
  too to report the swapoff progress. And SWP_USED is set even if the
  device hasn't been properly set up.

We can have another flag, but the easier way is to just check
si->swap_file directly. So protect si->swap_file setting with mutext,
and set si->swap_file only when the swap device is truly enabled.

/proc/swaps only interested in si->swap_file and a few static data
reading. Only si->swap_file needs protection. Reading other static
fields is always fine.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swapfile.c | 25 +++++++++++++------------
 1 file changed, 13 insertions(+), 12 deletions(-)

diff --git a/mm/swapfile.c b/mm/swapfile.c
index 32e0e7545ab8..25dfe992538d 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -110,6 +110,7 @@ struct swap_info_struct *swap_info[MAX_SWAPFILES];
 
 static struct kmem_cache *swap_table_cachep;
 
+/* Protects si->swap_file for /proc/swaps usage */
 static DEFINE_MUTEX(swapon_mutex);
 
 static DECLARE_WAIT_QUEUE_HEAD(proc_poll_wait);
@@ -2532,7 +2533,8 @@ static void drain_mmlist(void)
 /*
  * Free all of a swapdev's extent information
  */
-static void destroy_swap_extents(struct swap_info_struct *sis)
+static void destroy_swap_extents(struct swap_info_struct *sis,
+				 struct file *swap_file)
 {
 	while (!RB_EMPTY_ROOT(&sis->swap_extent_root)) {
 		struct rb_node *rb = sis->swap_extent_root.rb_node;
@@ -2543,7 +2545,6 @@ static void destroy_swap_extents(struct swap_info_struct *sis)
 	}
 
 	if (sis->flags & SWP_ACTIVATED) {
-		struct file *swap_file = sis->swap_file;
 		struct address_space *mapping = swap_file->f_mapping;
 
 		sis->flags &= ~SWP_ACTIVATED;
@@ -2626,9 +2627,9 @@ EXPORT_SYMBOL_GPL(add_swap_extent);
  * Typically it is in the 1-4 megabyte range.  So we can have hundreds of
  * extents in the rbtree. - akpm.
  */
-static int setup_swap_extents(struct swap_info_struct *sis, sector_t *span)
+static int setup_swap_extents(struct swap_info_struct *sis,
+			      struct file *swap_file, sector_t *span)
 {
-	struct file *swap_file = sis->swap_file;
 	struct address_space *mapping = swap_file->f_mapping;
 	struct inode *inode = mapping->host;
 	int ret;
@@ -2646,7 +2647,7 @@ static int setup_swap_extents(struct swap_info_struct *sis, sector_t *span)
 		sis->flags |= SWP_ACTIVATED;
 		if ((sis->flags & SWP_FS_OPS) &&
 		    sio_pool_init() != 0) {
-			destroy_swap_extents(sis);
+			destroy_swap_extents(sis, swap_file);
 			return -ENOMEM;
 		}
 		return ret;
@@ -2862,7 +2863,7 @@ SYSCALL_DEFINE1(swapoff, const char __user *, specialfile)
 	flush_work(&p->reclaim_work);
 	flush_percpu_swap_cluster(p);
 
-	destroy_swap_extents(p);
+	destroy_swap_extents(p, p->swap_file);
 	if (p->flags & SWP_CONTINUED)
 		free_swap_count_continuations(p);
 
@@ -2952,7 +2953,7 @@ static void *swap_start(struct seq_file *swap, loff_t *pos)
 		return SEQ_START_TOKEN;
 
 	for (type = 0; (si = swap_type_to_info(type)); type++) {
-		if (!(si->flags & SWP_USED) || !si->swap_map)
+		if (!(si->swap_file))
 			continue;
 		if (!--l)
 			return si;
@@ -2973,7 +2974,7 @@ static void *swap_next(struct seq_file *swap, void *v, loff_t *pos)
 
 	++(*pos);
 	for (; (si = swap_type_to_info(type)); type++) {
-		if (!(si->flags & SWP_USED) || !si->swap_map)
+		if (!(si->swap_file))
 			continue;
 		return si;
 	}
@@ -3390,7 +3391,6 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 		goto bad_swap;
 	}
 
-	si->swap_file = swap_file;
 	mapping = swap_file->f_mapping;
 	dentry = swap_file->f_path.dentry;
 	inode = mapping->host;
@@ -3440,7 +3440,7 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 
 	si->max = maxpages;
 	si->pages = maxpages - 1;
-	nr_extents = setup_swap_extents(si, &span);
+	nr_extents = setup_swap_extents(si, swap_file, &span);
 	if (nr_extents < 0) {
 		error = nr_extents;
 		goto bad_swap_unlock_inode;
@@ -3549,6 +3549,8 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 	prio = DEF_SWAP_PRIO;
 	if (swap_flags & SWAP_FLAG_PREFER)
 		prio = swap_flags & SWAP_FLAG_PRIO_MASK;
+
+	si->swap_file = swap_file;
 	enable_swap_info(si, prio, swap_map, cluster_info, zeromap);
 
 	pr_info("Adding %uk swap on %s.  Priority:%d extents:%d across:%lluk %s%s%s%s\n",
@@ -3573,10 +3575,9 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 	kfree(si->global_cluster);
 	si->global_cluster = NULL;
 	inode = NULL;
-	destroy_swap_extents(si);
+	destroy_swap_extents(si, swap_file);
 	swap_cgroup_swapoff(si->type);
 	spin_lock(&swap_lock);
-	si->swap_file = NULL;
 	si->flags = 0;
 	spin_unlock(&swap_lock);
 	vfree(swap_map);

-- 
2.52.0

