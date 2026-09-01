From: Bingfang Guo <bingfangguo@tencent.com>
Date: Tue, 01 Sep 2026 16:58:03 +0800
Subject: [PATCH RFC v2 4/6] mm/memcg: return the memcg when putting memcgid
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260901-bingfangguo-memcgid-rework-v2-4-8edd7f7a7251@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788253095; l=2395;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=A1qQqLP5yDMt8FsMtFOg0bivZFdxXUGUKPpa8uP9vSI=;
 b=SDxnNZGTvufnF2pzh/K+4XYnYFWQcDEg+BL0G/Mxc0c0jXuvvOso6qj3wfuU3pFeXELjN/juH
 /qvaZjgC7g3BEC0Brs8fdvQp+grYKljsPUo0sOADm4168oeOHGOopSQ
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__mem_cgroup_uncharge_swap() needs both the memcg and the id refcount
drop.  Right now it looks the memcg up by id, uncharges it, then looks
it up again inside mem_cgroup_private_id_put() to drop the reference.

Make mem_cgroup_private_id_put() resolve the id once, drop the
reference, and return the nearest online memcg with a reference held for
the caller.  __mem_cgroup_uncharge_swap() then uses that memcg directly
and drops the reference after uncharging, avoiding the second xarray
lookup.

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
 mm/memcontrol.c | 20 +++++++++++++++++---
 1 file changed, 17 insertions(+), 3 deletions(-)

diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 048c9bb0fad79..f0503a1e5492d 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -4048,14 +4048,28 @@ static void __mem_cgroup_private_id_put(struct mem_cgroup *memcg, unsigned int n
 	}
 }
 
-static void mem_cgroup_private_id_put(unsigned short id, unsigned int n)
+/**
+ * mem_cgroup_private_id_put - put memcgid and get the nearest online memcg
+ * @id: the memcg private id got from mem_cgroup_id_get_online
+ * @n: count of references to put
+ */
+static struct mem_cgroup *mem_cgroup_private_id_put(unsigned short id, unsigned int n)
 {
 	struct mem_cgroup *memcg;
 
 	rcu_read_lock();
 	memcg = mem_cgroup_from_private_id(id);
+	if (!memcg)
+		goto out;
+
 	__mem_cgroup_private_id_put(memcg, n);
+
+	while (memcg_is_dying(memcg) || !mem_cgroup_tryget(memcg))
+		memcg = parent_mem_cgroup(memcg);
+
+out:
 	rcu_read_unlock();
+	return memcg;
 }
 
 static void mem_cgroup_private_id_kill(struct mem_cgroup *memcg)
@@ -5816,7 +5830,7 @@ void __mem_cgroup_uncharge_swap(unsigned short id, unsigned int nr_pages)
 	struct mem_cgroup *memcg;
 
 	rcu_read_lock();
-	memcg = mem_cgroup_from_private_id(id);
+	memcg = mem_cgroup_private_id_put(id, nr_pages);
 	if (memcg) {
 		if (!mem_cgroup_is_root(memcg)) {
 			if (do_memsw_account())
@@ -5825,10 +5839,10 @@ void __mem_cgroup_uncharge_swap(unsigned short id, unsigned int nr_pages)
 				page_counter_uncharge(&memcg->swap, nr_pages);
 		}
 		mod_memcg_state(memcg, MEMCG_SWAP, -nr_pages);
-		mem_cgroup_private_id_put(id, nr_pages);
 	}
 	rcu_read_unlock();
 
+	mem_cgroup_put(memcg);
 }
 
 long mem_cgroup_get_nr_swap_pages(struct mem_cgroup *memcg)

-- 
2.43.7

