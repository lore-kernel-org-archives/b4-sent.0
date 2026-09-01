From: Bingfang Guo <bingfangguo@tencent.com>
Date: Tue, 01 Sep 2026 16:58:01 +0800
Subject: [PATCH RFC v2 2/6] mm/memcg: get memcgid reference only after swap
 charging success
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260901-bingfangguo-memcgid-rework-v2-2-8edd7f7a7251@tencent.com>
References: <20260901-bingfangguo-memcgid-rework-v2-0-8edd7f7a7251@tencent.com>
In-Reply-To: <20260901-bingfangguo-memcgid-rework-v2-0-8edd7f7a7251@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788253095; l=2079;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=ErkCRKG7+ifvfMdPwACVPkm46ElNXWlnuq1XQ4FUIi8=;
 b=DDtDUpfBr/Cr35KrVKoFXS5DDP6UzA+O0oBVcDic8cgdd5zeProvls7hwZXdQbkadI2cVWUcU
 lmlkGHHPgxyDvquRgY9UsYRryi10Q4EWn81coSXY+EukseXogsThSAF
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__mem_cgroup_try_charge_swap() pinned the memcg private id before the
swap counter was charged and had to undo the pin on the failure path.
Hold RCU lock for an extended period (which should be fine,
__memcg1_swapout() does this as well) so concurrent memcg release can
be avoided, and take the id reference to its online parent only after
charging has succeeded.

The failure path is now a plain return, and the id is only pinned for
entries that actually end up charged to swap.

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
 mm/memcontrol.c | 15 +++++++++------
 1 file changed, 9 insertions(+), 6 deletions(-)

diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 31cec9dde55f0..ecb4fb07d7735 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -5755,6 +5755,7 @@ int __mem_cgroup_try_charge_swap(struct folio *folio)
 	struct page_counter *counter;
 	struct mem_cgroup *memcg;
 	struct obj_cgroup *objcg;
+	unsigned short memcgid;
 
 	if (do_memsw_account())
 		return 0;
@@ -5772,22 +5773,24 @@ int __mem_cgroup_try_charge_swap(struct folio *folio)
 		return 0;
 	}
 
-	memcg = mem_cgroup_private_id_get_online(memcg, nr_pages);
-	/* memcg is pined by memcg ID. */
-	rcu_read_unlock();
+	while (memcg_is_dying(memcg))
+		memcg = parent_mem_cgroup(memcg);
 
 	if (!mem_cgroup_is_root(memcg) &&
 	    !page_counter_try_charge(&memcg->swap, nr_pages, &counter)) {
 		memcg_memory_event(memcg, MEMCG_SWAP_MAX);
 		memcg_memory_event(memcg, MEMCG_SWAP_FAIL);
-		mem_cgroup_private_id_put(memcg, nr_pages);
+		rcu_read_unlock();
 		return -ENOMEM;
 	}
 	mod_memcg_state(memcg, MEMCG_SWAP, nr_pages);
 
+	memcg = mem_cgroup_private_id_get_online(memcg, nr_pages);
+	memcgid = mem_cgroup_private_id(memcg);
+	rcu_read_unlock();
+
 	ci = swap_cluster_get_and_lock(folio);
-	__swap_cgroup_set(ci, swp_cluster_offset(folio->swap), nr_pages,
-			  mem_cgroup_private_id(memcg));
+	__swap_cgroup_set(ci, swp_cluster_offset(folio->swap), nr_pages, memcgid);
 	swap_cluster_unlock(ci);
 
 	return 0;

-- 
2.43.7

