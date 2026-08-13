From: Bingfang Guo <bingfangguo@tencent.com>
Date: Thu, 13 Aug 2026 16:52:04 +0800
Subject: [PATCH RFC 3/5] memcg: remove retry logic in
 mem_cgroup_private_id_get_online
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-memcgid-objcg-v1-3-83d21c685b77@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786611130; l=3214;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=5i2b3adAqDemDU/NAVoq8sK/uF2LIbB9NIx+Y5tqrZ8=;
 b=R9G5tW/eOsF1fEjMg6cHo6RdBDAD5yzOljC1iwmE4ddG37Cg5xTgcu5n+bSnG4To3/L8nTiny
 eDLxTl9DEDGAgfNU01C5tFnLzDpgWesTl3zgcaES2tabu+sgDAb5DeH
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With the ID released only in css_released() (patch 1) and every caller
holding a stable reference obtained from get_mem_cgroup_from_objcg()
(patch 2), the id refcount is guaranteed to be non-zero whenever the ID
is taken, so the retry loop that walked up the parent chain can never
trigger.

Remove the retry logic, rename the function to
mem_cgroup_private_id_get() and turn the fallible return value into a
VM_WARN_ON() that documents the invariant.

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
 mm/memcontrol-v1.c |  2 +-
 mm/memcontrol-v1.h |  3 +--
 mm/memcontrol.c    | 20 +++++---------------
 3 files changed, 7 insertions(+), 18 deletions(-)

diff --git a/mm/memcontrol-v1.c b/mm/memcontrol-v1.c
index a913d32ad1e17..e5161e061bd11 100644
--- a/mm/memcontrol-v1.c
+++ b/mm/memcontrol-v1.c
@@ -648,7 +648,7 @@ void __memcg1_swapout(struct folio *folio, struct swap_cluster_info *ci)
 	mod_memcg_state(memcg, MEMCG_SWAP, nr_entries);
 
 	/* we have a reference to it, so we should get exact memcg itself */
-	mem_cgroup_private_id_get_online(memcg, nr_entries);
+	mem_cgroup_private_id_get(memcg, nr_entries);
 
 	__swap_cgroup_set(ci, swp_cluster_offset(folio->swap), nr_entries,
 			  mem_cgroup_private_id(memcg));
diff --git a/mm/memcontrol-v1.h b/mm/memcontrol-v1.h
index 0f703f239c80f..9c74400aa7ddb 100644
--- a/mm/memcontrol-v1.h
+++ b/mm/memcontrol-v1.h
@@ -21,8 +21,7 @@ void drain_all_stock(struct mem_cgroup *root_memcg);
 
 int memory_stat_show(struct seq_file *m, void *v);
 
-struct mem_cgroup *mem_cgroup_private_id_get_online(struct mem_cgroup *memcg,
-						    unsigned int n);
+void mem_cgroup_private_id_get(struct mem_cgroup *memcg, unsigned int n);
 
 /* Cgroup v1-specific declarations */
 #ifdef CONFIG_MEMCG_V1
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index a210fe2501219..12545ca48194d 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -3985,23 +3985,13 @@ static inline void mem_cgroup_private_id_put(struct mem_cgroup *memcg, unsigned
 	__mem_cgroup_private_id_put(memcg->id_objcg, memcg->id, n);
 }
 
-struct mem_cgroup *mem_cgroup_private_id_get_online(struct mem_cgroup *memcg, unsigned int n)
+void mem_cgroup_private_id_get(struct mem_cgroup *memcg, unsigned int n)
 {
+	bool success;
 	struct obj_cgroup *objcg = memcg->id_objcg;
 
-	while (!refcount_add_not_zero(n, &objcg->id_ref)) {
-		/*
-		 * The root cgroup cannot be destroyed, so it's refcount must
-		 * always be >= 1.
-		 */
-		if (WARN_ON_ONCE(mem_cgroup_is_root(memcg))) {
-			VM_BUG_ON(1);
-			break;
-		}
-		memcg = parent_mem_cgroup(memcg);
-		objcg = memcg->id_objcg;
-	}
-	return memcg;
+	success = refcount_add_not_zero(n, &objcg->id_ref);
+	VM_WARN_ON(!success);
 }
 
 /**
@@ -5673,7 +5663,7 @@ int __mem_cgroup_try_charge_swap(struct folio *folio)
 	mod_memcg_state(memcg, MEMCG_SWAP, nr_pages);
 
 	/* we have a reference to it, so we should get exact memcg itself */
-	mem_cgroup_private_id_get_online(memcg, nr_pages);
+	mem_cgroup_private_id_get(memcg, nr_pages);
 
 	ci = swap_cluster_get_and_lock(folio);
 	__swap_cgroup_set(ci, swp_cluster_offset(folio->swap), nr_pages,

-- 
2.43.7

