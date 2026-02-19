From: Kairui Song <kasong@tencent.com>
Date: Fri, 20 Feb 2026 07:42:07 +0800
Subject: [PATCH RFC 06/15] memcg, swap: reparent the swap entry on swapin
 if swapout cgroup is dead
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-swap-table-p4-v1-6-104795d19815@tencent.com>
References: <20260220-swap-table-p4-v1-0-104795d19815@tencent.com>
In-Reply-To: <20260220-swap-table-p4-v1-0-104795d19815@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, Zi Yan <ziy@nvidia.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Barry Song <baohua@kernel.org>, 
 Hugh Dickins <hughd@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Yosry Ahmed <yosry.ahmed@linux.dev>, Youngjun Park <youngjun.park@lge.com>, 
 Chengming Zhou <chengming.zhou@linux.dev>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <zhengqi.arch@bytedance.com>, linux-kernel@vger.kernel.org, 
 cgroups@vger.kernel.org, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771544524; l=5359;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=9vO+dDP6+je7+jClnWWZNq1Qut+lGRZYCcUUD2nWDoQ=;
 b=IJcUr2SA72vqNqyIF134yy4jJ7YYtmhGsNrcSmy0Q9+wfm8Xie+xv3UHp/3cAaYgf2KVDPluh
 fEz1zi/4rLRAHAdpMH0ccI3u2DKM8Z0eLSBfg87HH3CD83K36kEjcv1
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As a result this will always charge the swapin folio into the dead
cgroup's parent cgroup, and ensure folio->swap belongs to folio_memcg.
This only affects some uncommon behavior if we move the process between
memcg.

When a process that previously swapped some memory is moved to another
cgroup, and the cgroup where the swap occurred is dead, folios for
swap in of old swap entries will be charged into the new cgroup.
Combined with the lazy freeing of swap cache, this leads to a strange
situation where the folio->swap entry belongs to a cgroup that is not
folio->memcg.

Swapin from dead zombie memcg might be rare in practise, cgroups are
offlined only after the workload in it is gone, which requires zapping
the page table first, and releases all swap entries. Shmem is
a bit different, but shmem always has swap count == 1, and force
releases the swap cache. So, for shmem charging into the new memcg and
release entry does look more sensible.

However, to make things easier to understand for an RFC, let's just
always charge to the parent cgroup if the leaf cgroup is dead. This may
not be the best design, but it makes the following work much easier to
demonstrate.

For a better solution, we can later:

- Dynamically allocate a swap cluster trampoline cgroup table
  (ci->memcg_table) and use that for zombie swapin only. Which is
  actually OK and may not cause a mess in the code level, since the
  incoming swap table compaction will require table expansion on swap-in
  as well.

- Just tolerate a 2-byte per slot overhead all the time, which is also
  acceptable.

- Limit the charge to parent behavior to only one situation: when the
  swap count > 2 and the process is migrated to another cgroup after
  swapout, these entries. This is even more rare to see in practice, I
  think.

For reference, the memory ownership model of cgroup v2:

"""
A memory area is charged to the cgroup which instantiated it and stays
charged to the cgroup until the area is released.  Migrating a process
to a different cgroup doesn't move the memory usages that it
instantiated while in the previous cgroup to the new cgroup.

A memory area may be used by processes belonging to different cgroups.
To which cgroup the area will be charged is in-deterministic; however,
over time, the memory area is likely to end up in a cgroup which has
enough memory allowance to avoid high reclaim pressure.

If a cgroup sweeps a considerable amount of memory which is expected
to be accessed repeatedly by other cgroups, it may make sense to use
POSIX_FADV_DONTNEED to relinquish the ownership of memory areas
belonging to the affected files to ensure correct memory ownership.
"""

So I think all of the solutions mentioned above, including this commit,
are not wrong.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/memcontrol.c | 53 +++++++++++++++++++++++++++++++++++++++++++++++++----
 1 file changed, 49 insertions(+), 4 deletions(-)

diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 73f622f7a72b..b2898719e935 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -4803,22 +4803,67 @@ int mem_cgroup_charge_hugetlb(struct folio *folio, gfp_t gfp)
 int mem_cgroup_swapin_charge_folio(struct folio *folio, struct mm_struct *mm,
 				  gfp_t gfp, swp_entry_t entry)
 {
-	struct mem_cgroup *memcg;
-	unsigned short id;
+	struct mem_cgroup *memcg, *swap_memcg;
+	unsigned short id, parent_id;
+	unsigned int nr_pages;
 	int ret;
 
 	if (mem_cgroup_disabled())
 		return 0;
 
 	id = lookup_swap_cgroup_id(entry);
+	nr_pages = folio_nr_pages(folio);
+
 	rcu_read_lock();
-	memcg = mem_cgroup_from_private_id(id);
-	if (!memcg || !css_tryget_online(&memcg->css))
+	swap_memcg = mem_cgroup_from_private_id(id);
+	if (!swap_memcg) {
+		WARN_ON_ONCE(id);
 		memcg = get_mem_cgroup_from_mm(mm);
+	} else {
+		memcg = swap_memcg;
+		/* Find the nearest online ancestor if dead, for reparent */
+		while (!css_tryget_online(&memcg->css))
+			memcg = parent_mem_cgroup(memcg);
+	}
 	rcu_read_unlock();
 
 	ret = charge_memcg(folio, memcg, gfp);
+	if (ret)
+		goto out;
+
+	/*
+	 * If the swap entry's memcg is dead, reparent the swap charge
+	 * from swap_memcg to memcg.
+	 *
+	 * If memcg is also being offlined, the charge will be moved to
+	 * its parent again.
+	 */
+	if (swap_memcg && memcg != swap_memcg) {
+		struct mem_cgroup *parent_memcg;
 
+		parent_memcg = mem_cgroup_private_id_get_online(memcg, nr_pages);
+		parent_id = mem_cgroup_private_id(parent_memcg);
+
+		WARN_ON(id != swap_cgroup_clear(entry, nr_pages));
+		swap_cgroup_record(folio, parent_id, entry);
+
+		if (do_memsw_account()) {
+			if (!mem_cgroup_is_root(parent_memcg))
+				page_counter_charge(&parent_memcg->memsw, nr_pages);
+			page_counter_uncharge(&swap_memcg->memsw, nr_pages);
+		} else {
+			if (!mem_cgroup_is_root(parent_memcg))
+				page_counter_charge(&parent_memcg->swap, nr_pages);
+			page_counter_uncharge(&swap_memcg->swap, nr_pages);
+		}
+
+		mod_memcg_state(parent_memcg, MEMCG_SWAP, nr_pages);
+		mod_memcg_state(swap_memcg, MEMCG_SWAP, -nr_pages);
+
+		/* Release the dead cgroup after reparent */
+		mem_cgroup_private_id_put(swap_memcg, nr_pages);
+	}
+out:
 	css_put(&memcg->css);
 	return ret;
 }

-- 
2.53.0

