From: Kairui Song <kasong@tencent.com>
Date: Fri, 17 Apr 2026 02:34:40 +0800
Subject: [PATCH v2 10/11] mm/memcg: remove no longer used swap cgroup array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260417-swap-table-p4-v2-10-17f5d1015428@tencent.com>
References: <20260417-swap-table-p4-v2-0-17f5d1015428@tencent.com>
In-Reply-To: <20260417-swap-table-p4-v2-0-17f5d1015428@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Zi Yan <ziy@nvidia.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Barry Song <baohua@kernel.org>, 
 Hugh Dickins <hughd@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Youngjun Park <youngjun.park@lge.com>, 
 Chengming Zhou <chengming.zhou@linux.dev>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <zhengqi.arch@bytedance.com>, linux-kernel@vger.kernel.org, 
 cgroups@vger.kernel.org, Kairui Song <kasong@tencent.com>, 
 Yosry Ahmed <yosry@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Michal Hocko <mhocko@suse.com>, Michal Hocko <mhocko@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Lorenzo Stoakes <ljs@kernel.org>, 
 Yosry Ahmed <yosry@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776364480; l=10121;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=dDVYF4bq+qhEs2L8GOWU8vBbhrkUU3PY225ZFin1M1c=;
 b=EUmwNjHEsXpJCEbE8aaQRvBAZBor6OiWMkmhz90hz1lSdXbIqLRZCFzTHagZFmLWdYR0g7YXs
 z4UQ3E6iILJD3DsfImW3Csf0LHOnoonuk1cpjdW6zfx5z0UIFPjbiJX
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now all swap cgroup records are stored in the swap cluster directly,
no more need for a static array for that.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 MAINTAINERS                 |   1 -
 include/linux/swap_cgroup.h |  47 ------------
 mm/Makefile                 |   3 -
 mm/internal.h               |   1 -
 mm/memcontrol-v1.c          |   1 -
 mm/memcontrol.c             |   1 -
 mm/swap_cgroup.c            | 172 --------------------------------------------
 mm/swapfile.c               |   8 ---
 8 files changed, 234 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index ab54a9c77603..b34f39cbe3ec 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -6567,7 +6567,6 @@ F:	mm/memcontrol.c
 F:	mm/memcontrol-v1.c
 F:	mm/memcontrol-v1.h
 F:	mm/page_counter.c
-F:	mm/swap_cgroup.c
 F:	samples/cgroup/*
 F:	tools/testing/selftests/cgroup/memcg_protection.m
 F:	tools/testing/selftests/cgroup/test_hugetlb_memcg.c
diff --git a/include/linux/swap_cgroup.h b/include/linux/swap_cgroup.h
deleted file mode 100644
index 91cdf12190a0..000000000000
--- a/include/linux/swap_cgroup.h
+++ /dev/null
@@ -1,47 +0,0 @@
-/* SPDX-License-Identifier: GPL-2.0 */
-#ifndef __LINUX_SWAP_CGROUP_H
-#define __LINUX_SWAP_CGROUP_H
-
-#include <linux/swap.h>
-
-#if defined(CONFIG_MEMCG) && defined(CONFIG_SWAP)
-
-extern void swap_cgroup_record(struct folio *folio, unsigned short id, swp_entry_t ent);
-extern unsigned short swap_cgroup_clear(swp_entry_t ent, unsigned int nr_ents);
-extern unsigned short lookup_swap_cgroup_id(swp_entry_t ent);
-extern int swap_cgroup_swapon(int type, unsigned long max_pages);
-extern void swap_cgroup_swapoff(int type);
-
-#else
-
-static inline
-void swap_cgroup_record(struct folio *folio, unsigned short id, swp_entry_t ent)
-{
-}
-
-static inline
-unsigned short swap_cgroup_clear(swp_entry_t ent, unsigned int nr_ents)
-{
-	return 0;
-}
-
-static inline
-unsigned short lookup_swap_cgroup_id(swp_entry_t ent)
-{
-	return 0;
-}
-
-static inline int
-swap_cgroup_swapon(int type, unsigned long max_pages)
-{
-	return 0;
-}
-
-static inline void swap_cgroup_swapoff(int type)
-{
-	return;
-}
-
-#endif
-
-#endif /* __LINUX_SWAP_CGROUP_H */
diff --git a/mm/Makefile b/mm/Makefile
index 8ad2ab08244e..eff9f9e7e061 100644
--- a/mm/Makefile
+++ b/mm/Makefile
@@ -103,9 +103,6 @@ obj-$(CONFIG_PAGE_COUNTER) += page_counter.o
 obj-$(CONFIG_LIVEUPDATE_MEMFD) += memfd_luo.o
 obj-$(CONFIG_MEMCG_V1) += memcontrol-v1.o
 obj-$(CONFIG_MEMCG) += memcontrol.o vmpressure.o
-ifdef CONFIG_SWAP
-obj-$(CONFIG_MEMCG) += swap_cgroup.o
-endif
 ifdef CONFIG_BPF_SYSCALL
 obj-$(CONFIG_MEMCG) += bpf_memcontrol.o
 endif
diff --git a/mm/internal.h b/mm/internal.h
index 32de9f3a9fa0..164c7f0a6a98 100644
--- a/mm/internal.h
+++ b/mm/internal.h
@@ -17,7 +17,6 @@
 #include <linux/rmap.h>
 #include <linux/swap.h>
 #include <linux/leafops.h>
-#include <linux/swap_cgroup.h>
 #include <linux/tracepoint-defs.h>
 
 /* Internal core VMA manipulation functions. */
diff --git a/mm/memcontrol-v1.c b/mm/memcontrol-v1.c
index ff49337a61a3..c2a39ae1fd69 100644
--- a/mm/memcontrol-v1.c
+++ b/mm/memcontrol-v1.c
@@ -5,7 +5,6 @@
 #include <linux/mm_inline.h>
 #include <linux/pagewalk.h>
 #include <linux/backing-dev.h>
-#include <linux/swap_cgroup.h>
 #include <linux/eventfd.h>
 #include <linux/poll.h>
 #include <linux/sort.h>
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 43a7b25da37e..493aff40df0c 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -54,7 +54,6 @@
 #include <linux/vmpressure.h>
 #include <linux/memremap.h>
 #include <linux/mm_inline.h>
-#include <linux/swap_cgroup.h>
 #include <linux/cpu.h>
 #include <linux/oom.h>
 #include <linux/lockdep.h>
diff --git a/mm/swap_cgroup.c b/mm/swap_cgroup.c
deleted file mode 100644
index de779fed8c21..000000000000
--- a/mm/swap_cgroup.c
+++ /dev/null
@@ -1,172 +0,0 @@
-// SPDX-License-Identifier: GPL-2.0
-#include <linux/swap_cgroup.h>
-#include <linux/vmalloc.h>
-#include <linux/mm.h>
-
-#include <linux/swapops.h> /* depends on mm.h include */
-
-static DEFINE_MUTEX(swap_cgroup_mutex);
-
-/* Pack two cgroup id (short) of two entries in one swap_cgroup (atomic_t) */
-#define ID_PER_SC (sizeof(struct swap_cgroup) / sizeof(unsigned short))
-#define ID_SHIFT (BITS_PER_TYPE(unsigned short))
-#define ID_MASK (BIT(ID_SHIFT) - 1)
-struct swap_cgroup {
-	atomic_t ids;
-};
-
-struct swap_cgroup_ctrl {
-	struct swap_cgroup *map;
-};
-
-static struct swap_cgroup_ctrl swap_cgroup_ctrl[MAX_SWAPFILES];
-
-static unsigned short __swap_cgroup_id_lookup(struct swap_cgroup *map,
-					      pgoff_t offset)
-{
-	unsigned int shift = (offset % ID_PER_SC) * ID_SHIFT;
-	unsigned int old_ids = atomic_read(&map[offset / ID_PER_SC].ids);
-
-	BUILD_BUG_ON(!is_power_of_2(ID_PER_SC));
-	BUILD_BUG_ON(sizeof(struct swap_cgroup) != sizeof(atomic_t));
-
-	return (old_ids >> shift) & ID_MASK;
-}
-
-static unsigned short __swap_cgroup_id_xchg(struct swap_cgroup *map,
-					    pgoff_t offset,
-					    unsigned short new_id)
-{
-	unsigned short old_id;
-	struct swap_cgroup *sc = &map[offset / ID_PER_SC];
-	unsigned int shift = (offset % ID_PER_SC) * ID_SHIFT;
-	unsigned int new_ids, old_ids = atomic_read(&sc->ids);
-
-	do {
-		old_id = (old_ids >> shift) & ID_MASK;
-		new_ids = (old_ids & ~(ID_MASK << shift));
-		new_ids |= ((unsigned int)new_id) << shift;
-	} while (!atomic_try_cmpxchg(&sc->ids, &old_ids, new_ids));
-
-	return old_id;
-}
-
-/**
- * swap_cgroup_record - record mem_cgroup for a set of swap entries.
- * These entries must belong to one single folio, and that folio
- * must be being charged for swap space (swap out), and these
- * entries must not have been charged
- *
- * @folio: the folio that the swap entry belongs to
- * @id: mem_cgroup ID to be recorded
- * @ent: the first swap entry to be recorded
- */
-void swap_cgroup_record(struct folio *folio, unsigned short id,
-			swp_entry_t ent)
-{
-	unsigned int nr_ents = folio_nr_pages(folio);
-	struct swap_cgroup *map;
-	pgoff_t offset, end;
-	unsigned short old;
-
-	offset = swp_offset(ent);
-	end = offset + nr_ents;
-	map = swap_cgroup_ctrl[swp_type(ent)].map;
-
-	do {
-		old = __swap_cgroup_id_xchg(map, offset, id);
-		VM_BUG_ON(old);
-	} while (++offset != end);
-}
-
-/**
- * swap_cgroup_clear - clear mem_cgroup for a set of swap entries.
- * These entries must be being uncharged from swap. They either
- * belongs to one single folio in the swap cache (swap in for
- * cgroup v1), or no longer have any users (slot freeing).
- *
- * @ent: the first swap entry to be recorded into
- * @nr_ents: number of swap entries to be recorded
- *
- * Returns the existing old value.
- */
-unsigned short swap_cgroup_clear(swp_entry_t ent, unsigned int nr_ents)
-{
-	pgoff_t offset, end;
-	struct swap_cgroup *map;
-	unsigned short old, iter = 0;
-
-	offset = swp_offset(ent);
-	end = offset + nr_ents;
-	map = swap_cgroup_ctrl[swp_type(ent)].map;
-
-	do {
-		old = __swap_cgroup_id_xchg(map, offset, 0);
-		if (!iter)
-			iter = old;
-		VM_BUG_ON(iter != old);
-	} while (++offset != end);
-
-	return old;
-}
-
-/**
- * lookup_swap_cgroup_id - lookup mem_cgroup id tied to swap entry
- * @ent: swap entry to be looked up.
- *
- * Returns ID of mem_cgroup at success. 0 at failure. (0 is invalid ID)
- */
-unsigned short lookup_swap_cgroup_id(swp_entry_t ent)
-{
-	struct swap_cgroup_ctrl *ctrl;
-
-	if (mem_cgroup_disabled())
-		return 0;
-
-	ctrl = &swap_cgroup_ctrl[swp_type(ent)];
-	return __swap_cgroup_id_lookup(ctrl->map, swp_offset(ent));
-}
-
-int swap_cgroup_swapon(int type, unsigned long max_pages)
-{
-	struct swap_cgroup *map;
-	struct swap_cgroup_ctrl *ctrl;
-
-	if (mem_cgroup_disabled())
-		return 0;
-
-	BUILD_BUG_ON(sizeof(unsigned short) * ID_PER_SC !=
-		     sizeof(struct swap_cgroup));
-	map = vzalloc(DIV_ROUND_UP(max_pages, ID_PER_SC) *
-		      sizeof(struct swap_cgroup));
-	if (!map)
-		goto nomem;
-
-	ctrl = &swap_cgroup_ctrl[type];
-	mutex_lock(&swap_cgroup_mutex);
-	ctrl->map = map;
-	mutex_unlock(&swap_cgroup_mutex);
-
-	return 0;
-nomem:
-	pr_info("couldn't allocate enough memory for swap_cgroup\n");
-	pr_info("swap_cgroup can be disabled by swapaccount=0 boot option\n");
-	return -ENOMEM;
-}
-
-void swap_cgroup_swapoff(int type)
-{
-	struct swap_cgroup *map;
-	struct swap_cgroup_ctrl *ctrl;
-
-	if (mem_cgroup_disabled())
-		return;
-
-	mutex_lock(&swap_cgroup_mutex);
-	ctrl = &swap_cgroup_ctrl[type];
-	map = ctrl->map;
-	ctrl->map = NULL;
-	mutex_unlock(&swap_cgroup_mutex);
-
-	vfree(map);
-}
diff --git a/mm/swapfile.c b/mm/swapfile.c
index 5511cdbd2ccf..0753a62ebc25 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -45,7 +45,6 @@
 
 #include <asm/tlbflush.h>
 #include <linux/leafops.h>
-#include <linux/swap_cgroup.h>
 #include "swap_table.h"
 #include "internal.h"
 #include "swap.h"
@@ -3173,8 +3172,6 @@ SYSCALL_DEFINE1(swapoff, const char __user *, specialfile)
 	p->global_cluster = NULL;
 	kvfree(zeromap);
 	free_swap_cluster_info(cluster_info, maxpages);
-	/* Destroy swap account information */
-	swap_cgroup_swapoff(p->type);
 
 	inode = mapping->host;
 
@@ -3705,10 +3702,6 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 	if (error)
 		goto bad_swap_unlock_inode;
 
-	error = swap_cgroup_swapon(si->type, maxpages);
-	if (error)
-		goto bad_swap_unlock_inode;
-
 	/*
 	 * Use kvmalloc_array instead of bitmap_zalloc as the allocation order might
 	 * be above MAX_PAGE_ORDER incase of a large swap file.
@@ -3819,7 +3812,6 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 	si->global_cluster = NULL;
 	inode = NULL;
 	destroy_swap_extents(si, swap_file);
-	swap_cgroup_swapoff(si->type);
 	free_swap_cluster_info(si->cluster_info, si->max);
 	si->cluster_info = NULL;
 	kvfree(si->zeromap);

-- 
2.53.0

