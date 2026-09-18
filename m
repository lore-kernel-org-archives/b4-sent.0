From: Bingfang Guo <bingfangguo@tencent.com>
Date: Fri, 18 Sep 2026 17:18:40 +0800
Subject: [PATCH 1/4] memcg: keep swap charging under RCU protection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-bingfangguo-memcgid-rework-v1-1-5bbf3220d88f@tencent.com>
References: <20260918-bingfangguo-memcgid-rework-v1-0-5bbf3220d88f@tencent.com>
In-Reply-To: <20260918-bingfangguo-memcgid-rework-v1-0-5bbf3220d88f@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789723137; l=2119;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=aNz5CIHBA0S+5g/N6vd9VKb1cpBJlA1cYu/omCgqzbc=;
 b=85Mfwmjg8Hw0ij0tgq5WRMyNU987rySAkUozMzMbKjZ4EMuLJjIpx4j/3IQ2O6QO3UEKF4Ac2
 Bd4qZmnpAuUD0TVgkE277fCPMZ0RJDGGHP/A5uHi2CEtksfylrjwdne
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a preparatory work for unbinding memcgid from memcg. No
functional change.

The swap charging path currently drops its RCU read lock after acquiring
a private ID reference. This is safe because the ID reference pins the
memcg's CSS.

Moving private ID references to objcgs will remove that lifetime
guarantee. Keep the RCU read lock held while accessing the memcg for
counter charging, statistics and failure handling. (This matches what
__memcg1_swapout() already does.).

Save the private ID before dropping the RCU read lock, and use the saved
value when recording the swap entry. The swap cluster locking remains
outside the RCU read-side critical section.

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
 mm/memcontrol.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 791e536efaebe..72522ec827c9a 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -5954,6 +5954,7 @@ int __mem_cgroup_try_charge_swap(struct folio *folio)
 	struct page_counter *counter;
 	struct mem_cgroup *memcg;
 	struct obj_cgroup *objcg;
+	unsigned short private_id;
 
 	if (do_memsw_account())
 		return 0;
@@ -5973,20 +5974,21 @@ int __mem_cgroup_try_charge_swap(struct folio *folio)
 
 	memcg = mem_cgroup_private_id_get_online(memcg, nr_pages);
 	/* memcg is pined by memcg ID. */
-	rcu_read_unlock();
+	private_id = mem_cgroup_private_id(memcg);
 
 	if (!mem_cgroup_is_root(memcg) &&
 	    !page_counter_try_charge(&memcg->swap, nr_pages, &counter)) {
 		memcg_memory_event(memcg, MEMCG_SWAP_MAX);
 		memcg_memory_event(memcg, MEMCG_SWAP_FAIL);
 		mem_cgroup_private_id_put(memcg, nr_pages);
+		rcu_read_unlock();
 		return -ENOMEM;
 	}
 	mod_memcg_state(memcg, MEMCG_SWAP, nr_pages);
+	rcu_read_unlock();
 
 	ci = swap_cluster_get_and_lock(folio);
-	__swap_cgroup_set(ci, swp_cluster_offset(folio->swap), nr_pages,
-			  mem_cgroup_private_id(memcg));
+	__swap_cgroup_set(ci, swp_cluster_offset(folio->swap), nr_pages, private_id);
 	swap_cluster_unlock(ci);
 
 	return 0;

-- 
2.43.7

