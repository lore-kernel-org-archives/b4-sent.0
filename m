From: Bingfang Guo <bingfangguo@tencent.com>
Date: Thu, 13 Aug 2026 16:52:03 +0800
Subject: [PATCH RFC 2/5] memcg: get stable memcg first before getting
 memcgid reference
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-memcgid-objcg-v1-2-83d21c685b77@tencent.com>
References: <20260813-memcgid-objcg-v1-0-83d21c685b77@tencent.com>
In-Reply-To: <20260813-memcgid-objcg-v1-0-83d21c685b77@tencent.com>
To: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Dave Chinner <david@fromorbit.com>, Qi Zheng <qi.zheng@linux.dev>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>
Cc: cgroups@vger.kernel.org, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, Bingfang Guo <bfguo@icloud.com>, 
 Bingfang Guo <bingfangguo@tencent.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786611130; l=4263;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=jO1EJ+YiSvB3LpF8HaBSpgO3Wgmvg81030gxkA7owJQ=;
 b=IuoSLuzL/85amN4CY0wJlbVtvGU0mcWEE5s5ZLz/r+pG0gu1bd9lArAGvkUhpLoBQdNeOaZQn
 /8mlXbtlBnPBY0MdmBu+DAQ0AO/qUgV3bOyPNMKrDjv8rLi+hCRWcs4
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Storing the memcg private ID in a swap entry used to take the ID
reference under the RCU read lock and rely on
mem_cgroup_private_id_get_online() to hand back a usable (possibly
parent) memcg.

Now that the ID refcount lives on the objcg and stays alive until
css_released(), holding a memcg reference is enough to pin the ID. Both
__memcg1_swapout() and __mem_cgroup_try_charge_swap() take a stable
memcg reference first via get_mem_cgroup_from_objcg() and pin the ID
afterwards, dropping the rcu_read_lock() usage and the get-error-put
handling, and recording exactly the memcg the folio belongs to in the
swap entry.

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
 mm/memcontrol-v1.c | 23 +++++++++--------------
 mm/memcontrol.c    |  9 ++++++---
 2 files changed, 15 insertions(+), 17 deletions(-)

diff --git a/mm/memcontrol-v1.c b/mm/memcontrol-v1.c
index 2dc599484d006..a913d32ad1e17 100644
--- a/mm/memcontrol-v1.c
+++ b/mm/memcontrol-v1.c
@@ -618,7 +618,7 @@ void memcg1_commit_charge(struct folio *folio, struct mem_cgroup *memcg)
  */
 void __memcg1_swapout(struct folio *folio, struct swap_cluster_info *ci)
 {
-	struct mem_cgroup *memcg, *swap_memcg;
+	struct mem_cgroup *memcg;
 	struct obj_cgroup *objcg;
 	unsigned int nr_entries;
 
@@ -638,19 +638,20 @@ void __memcg1_swapout(struct folio *folio, struct swap_cluster_info *ci)
 	if (!objcg)
 		return;
 
-	rcu_read_lock();
-	memcg = obj_cgroup_memcg(objcg);
 	/*
 	 * In case the memcg owning these pages has been offlined and doesn't
 	 * have an ID allocated to it anymore, charge the closest online
-	 * ancestor for the swap instead and transfer the memory+swap charge.
+	 * ancestor for the swap instead.
 	 */
+	memcg = get_mem_cgroup_from_objcg(objcg);
 	nr_entries = folio_nr_pages(folio);
-	swap_memcg = mem_cgroup_private_id_get_online(memcg, nr_entries);
-	mod_memcg_state(swap_memcg, MEMCG_SWAP, nr_entries);
+	mod_memcg_state(memcg, MEMCG_SWAP, nr_entries);
+
+	/* we have a reference to it, so we should get exact memcg itself */
+	mem_cgroup_private_id_get_online(memcg, nr_entries);
 
 	__swap_cgroup_set(ci, swp_cluster_offset(folio->swap), nr_entries,
-			  mem_cgroup_private_id(swap_memcg));
+			  mem_cgroup_private_id(memcg));
 
 	folio_unqueue_deferred_split(folio);
 	folio->memcg_data = 0;
@@ -658,12 +659,6 @@ void __memcg1_swapout(struct folio *folio, struct swap_cluster_info *ci)
 	if (!obj_cgroup_is_root(objcg))
 		page_counter_uncharge(&memcg->memory, nr_entries);
 
-	if (memcg != swap_memcg) {
-		if (!mem_cgroup_is_root(swap_memcg))
-			page_counter_charge(&swap_memcg->memsw, nr_entries);
-		page_counter_uncharge(&memcg->memsw, nr_entries);
-	}
-
 	/*
 	 * The caller must hold the swap cluster lock with IRQ off. It is
 	 * important here to have the interrupts disabled because it is the
@@ -675,7 +670,7 @@ void __memcg1_swapout(struct folio *folio, struct swap_cluster_info *ci)
 	preempt_enable_nested();
 	memcg1_check_events(memcg, folio_nid(folio));
 
-	rcu_read_unlock();
+	mem_cgroup_put(memcg);
 	obj_cgroup_put(objcg);
 }
 
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 5f30e76ee93d7..a210fe2501219 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -5660,24 +5660,27 @@ int __mem_cgroup_try_charge_swap(struct folio *folio)
 		return 0;
 	}
 
-	memcg = mem_cgroup_private_id_get_online(memcg, nr_pages);
-	/* memcg is pined by memcg ID. */
+	memcg = get_mem_cgroup_from_objcg(objcg);
 	rcu_read_unlock();
 
 	if (!mem_cgroup_is_root(memcg) &&
 	    !page_counter_try_charge(&memcg->swap, nr_pages, &counter)) {
 		memcg_memory_event(memcg, MEMCG_SWAP_MAX);
 		memcg_memory_event(memcg, MEMCG_SWAP_FAIL);
-		mem_cgroup_private_id_put(memcg, nr_pages);
+		mem_cgroup_put(memcg);
 		return -ENOMEM;
 	}
 	mod_memcg_state(memcg, MEMCG_SWAP, nr_pages);
 
+	/* we have a reference to it, so we should get exact memcg itself */
+	mem_cgroup_private_id_get_online(memcg, nr_pages);
+
 	ci = swap_cluster_get_and_lock(folio);
 	__swap_cgroup_set(ci, swp_cluster_offset(folio->swap), nr_pages,
 			  mem_cgroup_private_id(memcg));
 	swap_cluster_unlock(ci);
 
+	mem_cgroup_put(memcg);
 	return 0;
 }
 

-- 
2.43.7

