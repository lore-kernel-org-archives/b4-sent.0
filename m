From: Bingfang Guo <bingfangguo@tencent.com>
Date: Mon, 21 Sep 2026 14:16:24 +0800
Subject: [PATCH v2 1/4] memcg: keep swap charging under RCU protection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-bingfangguo-memcgid-rework-v2-1-6c0637dc0edb@tencent.com>
References: <20260921-bingfangguo-memcgid-rework-v2-0-6c0637dc0edb@tencent.com>
In-Reply-To: <20260921-bingfangguo-memcgid-rework-v2-0-6c0637dc0edb@tencent.com>
To: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Dave Chinner <david@fromorbit.com>, Qi Zheng <qi.zheng@linux.dev>, 
 Kairui Song <kasong@tencent.com>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Bingfang Guo <bfguo@icloud.com>
Cc: cgroups@vger.kernel.org, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, Bingfang Guo <bingfangguo@tencent.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789971391; l=2959;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=sE3zMklqkcFz3uR1w6qomhpryX2R8nExKsjfG+k30bI=;
 b=jYqZPOQzuqXt3gG9v8XXM4BalCcLyDqai9BvgC5xpefOPP5WMa23il4SGzRfiEbjc9+PIIj0H
 GvQ5nU6AAg/DDtdj1U5G90CxDuQBHe6GOo2QGChpb/L3eR4heGMLTma
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a preparatory work for unbinding memcgid from memcg. No
functional change.

The swap charging path currently drops its RCU read lock after acquiring
a private ID reference. This is safe because the ID reference pins the
memcg's CSS.  After ID references are moved to pin objcgs, that lifetime
guarantee will no longer hold.

Keep the RCU read lock held while accessing the memcg for counter
charging, statistics and failure handling. (This matches what
__memcg1_swapout() already does).  Save the private ID for swap memcg
recording before dropping the RCU read lock. So the swap cluster locking
remains outside the RCU read-side critical section.

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
Acked-by: Muchun Song <muchun.song@linux.dev>
---
 mm/memcontrol.c | 38 +++++++++++++++++++-------------------
 1 file changed, 19 insertions(+), 19 deletions(-)

diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 791e536efaebe..981a231a76129 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -5954,6 +5954,7 @@ int __mem_cgroup_try_charge_swap(struct folio *folio)
 	struct page_counter *counter;
 	struct mem_cgroup *memcg;
 	struct obj_cgroup *objcg;
+	unsigned short private_id;
 
 	if (do_memsw_account())
 		return 0;
@@ -5963,30 +5964,29 @@ int __mem_cgroup_try_charge_swap(struct folio *folio)
 	if (!objcg)
 		return 0;
 
-	rcu_read_lock();
-	memcg = obj_cgroup_memcg(objcg);
-	if (!folio_test_swapcache(folio)) {
-		memcg_memory_event(memcg, MEMCG_SWAP_FAIL);
-		rcu_read_unlock();
-		return 0;
-	}
+	scoped_guard(rcu) {
+		memcg = obj_cgroup_memcg(objcg);
+		if (!folio_test_swapcache(folio)) {
+			memcg_memory_event(memcg, MEMCG_SWAP_FAIL);
+			return 0;
+		}
 
-	memcg = mem_cgroup_private_id_get_online(memcg, nr_pages);
-	/* memcg is pined by memcg ID. */
-	rcu_read_unlock();
+		memcg = mem_cgroup_private_id_get_online(memcg, nr_pages);
+		/* memcg is pined by memcg ID. */
+		private_id = mem_cgroup_private_id(memcg);
 
-	if (!mem_cgroup_is_root(memcg) &&
-	    !page_counter_try_charge(&memcg->swap, nr_pages, &counter)) {
-		memcg_memory_event(memcg, MEMCG_SWAP_MAX);
-		memcg_memory_event(memcg, MEMCG_SWAP_FAIL);
-		mem_cgroup_private_id_put(memcg, nr_pages);
-		return -ENOMEM;
+		if (!mem_cgroup_is_root(memcg) &&
+		    !page_counter_try_charge(&memcg->swap, nr_pages, &counter)) {
+			memcg_memory_event(memcg, MEMCG_SWAP_MAX);
+			memcg_memory_event(memcg, MEMCG_SWAP_FAIL);
+			mem_cgroup_private_id_put(memcg, nr_pages);
+			return -ENOMEM;
+		}
+		mod_memcg_state(memcg, MEMCG_SWAP, nr_pages);
 	}
-	mod_memcg_state(memcg, MEMCG_SWAP, nr_pages);
 
 	ci = swap_cluster_get_and_lock(folio);
-	__swap_cgroup_set(ci, swp_cluster_offset(folio->swap), nr_pages,
-			  mem_cgroup_private_id(memcg));
+	__swap_cgroup_set(ci, swp_cluster_offset(folio->swap), nr_pages, private_id);
 	swap_cluster_unlock(ci);
 
 	return 0;

-- 
2.43.7

