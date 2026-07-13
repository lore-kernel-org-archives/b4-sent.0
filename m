From: Kairui Song <kasong@tencent.com>
Date: Tue, 14 Jul 2026 01:25:50 +0800
Subject: [PATCH RFC 12/13] mm/swap: drop swap active plist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-swap-pcp-priq-v1-12-de9b164ed419@tencent.com>
References: <20260714-swap-pcp-priq-v1-0-de9b164ed419@tencent.com>
In-Reply-To: <20260714-swap-pcp-priq-v1-0-de9b164ed419@tencent.com>
To: linux-mm@kvack.org
Cc: linux-kernel@vger.kernel.org, Andrew Morton <akpm@linux-foundation.org>, 
 Chris Li <chrisl@kernel.org>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <baoquan.he@linux.dev>, Barry Song <baohua@kernel.org>, 
 Youngjun Park <youngjun.park@lge.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783963612; l=4414;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=G45gA89umSL+kNs6bHyiaF1kIcN9pJ1ls62NQeOiYC4=;
 b=u/9trm152FgryD98mxUIQo6uu+x7EW9bzV/9nIVIRIh+hgrKj7kmLlR7Hv9I6jJ7gNWDavUCJ
 duRagp71EcEAIb40QpjiSyJQ5sj8Hf12sDBBp+XT3wQO0N93DXKzAqv
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The swap_active_head plist tracked all writable swap devices, ordered
by priority.  Now that every consumer that needed priority ordering
has moved to the priority queue, the remaining users only need to
find any writable device.

Remove swap_active_head, the associated plist_node from
swap_info_struct, and migrate the remaining plist operations.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/swap.h |  1 -
 mm/swapfile.c        | 26 +++++---------------------
 2 files changed, 5 insertions(+), 22 deletions(-)

diff --git a/include/linux/swap.h b/include/linux/swap.h
index 189c9898641b..04767540972b 100644
--- a/include/linux/swap.h
+++ b/include/linux/swap.h
@@ -267,7 +267,6 @@ struct swap_info_struct {
 	struct percpu_ref users;	/* indicate and keep swap device valid. */
 	unsigned long	flags;		/* SWP_USED etc: see above */
 	signed short	prio;		/* swap priority of this type */
-	struct plist_node list;		/* entry in swap_active_head */
 	signed char	type;		/* strange name for an index */
 	unsigned int	max;		/* size of this swap device */
 	struct swap_cluster_info *cluster_info; /* cluster info. Only for SSD */
diff --git a/mm/swapfile.c b/mm/swapfile.c
index 74a50c39da60..f93863309a5a 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -41,7 +41,6 @@
 #include <linux/completion.h>
 #include <linux/suspend.h>
 #include <linux/zswap.h>
-#include <linux/plist.h>
 
 #include <asm/tlbflush.h>
 #include <linux/leafops.h>
@@ -90,12 +89,6 @@ bool swap_migration_ad_supported;
 static const char Bad_file[] = "Bad swap file entry ";
 static const char Bad_offset[] = "Bad swap offset entry ";
 
-/*
- * all active swap_info_structs
- * protected with swapon_rwsem, and ordered by priority.
- */
-static PLIST_HEAD(swap_active_head);
-
 static inline struct swap_info_struct *__swap_iter(int *i, unsigned long flag)
 {
 	lockdep_assert_held(&swapon_rwsem);
@@ -3212,7 +3205,6 @@ static void swap_device_enable(struct swap_info_struct *si)
 	spin_unlock(&swap_queue_update_lock);
 	atomic_long_add(si->pages, &nr_swap_pages);
 	total_swap_pages += si->pages;
-	plist_add(&si->list, &swap_active_head);
 	percpu_up_write(&swapon_rwsem);
 
 	add_to_avail_list(si);
@@ -3244,7 +3236,6 @@ static int swap_device_disable(struct swap_info_struct *si)
 	spin_lock(&swap_queue_update_lock);
 	si->flags &= ~SWP_WRITEOK;
 	spin_unlock(&swap_queue_update_lock);
-	plist_del(&si->list, &swap_active_head);
 	total_swap_pages -= si->pages;
 	atomic_long_sub(si->pages, &nr_swap_pages);
 	del_from_avail_list(si, true);
@@ -3306,9 +3297,8 @@ SYSCALL_DEFINE1(swapoff, const char __user *, specialfile)
 
 	mapping = victim->f_mapping;
 	percpu_down_read(&swapon_rwsem);
-	plist_for_each_entry(p, &swap_active_head, list) {
-		if (p->flags & SWP_WRITEOK &&
-		    p->swap_file->f_mapping == mapping) {
+	for_each_avail_swap(p) {
+		if (p->swap_file->f_mapping == mapping) {
 			found = 1;
 			break;
 		}
@@ -3579,7 +3569,6 @@ static struct swap_info_struct *alloc_swap_info(void)
 		 */
 	}
 	p->swap_extent_root = RB_ROOT;
-	plist_node_init(&p->list, 0);
 	p->flags = SWP_USED;
 	percpu_up_write(&swapon_rwsem);
 	if (defer) {
@@ -3981,12 +3970,7 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 	if (swap_flags & SWAP_FLAG_PREFER)
 		prio = swap_flags & SWAP_FLAG_PRIO_MASK;
 
-	/*
-	 * The plist prio is negated because plist ordering is
-	 * low-to-high, while swap ordering is high-to-low
-	 */
 	si->prio = prio;
-	si->list.prio = -si->prio;
 	si->swap_file = swap_file;
 
 	/* Sets SWP_WRITEOK, resurrect the percpu ref, expose the swap device */
@@ -4096,7 +4080,7 @@ int swap_dup_entry_direct(swp_entry_t entry)
 #if defined(CONFIG_MEMCG) && defined(CONFIG_BLK_CGROUP)
 static bool __has_usable_swap(void)
 {
-	return !plist_head_empty(&swap_active_head);
+	return READ_ONCE(total_swap_pages) > 0;
 }
 
 void __folio_throttle_swaprate(struct folio *folio, gfp_t gfp)
@@ -4120,8 +4104,8 @@ void __folio_throttle_swaprate(struct folio *folio, gfp_t gfp)
 		return;
 
 	percpu_down_read(&swapon_rwsem);
-	plist_for_each_entry(si, &swap_active_head, list) {
-		if ((si->flags & SWP_WRITEOK) && si->bdev) {
+	for_each_avail_swap(si) {
+		if (si->bdev) {
 			blkcg_schedule_throttle(si->bdev->bd_disk, true);
 			break;
 		}

-- 
2.55.0

