From: Bingfang Guo <bingfangguo@tencent.com>
Date: Tue, 01 Sep 2026 16:58:02 +0800
Subject: [PATCH RFC v2 3/6] mm/memcg: pass the id itself instead of memcg
 for putting ID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260901-bingfangguo-memcgid-rework-v2-3-8edd7f7a7251@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788253095; l=2276;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=Hme7alp92v7qswodLGOz+AEsobF9FQa4tLBqDCAkCtM=;
 b=c8nFHb4AUhwzs6oAknyCqJ0Pm1qLXpvYuxZxHbNmRGZsdbLVMb09sl90FHGF647pHZfMqOyHs
 cmyhPaHJmgHACPLgmtpGf/+GzZKmjR+RGTDIcB4wtk93DT2tIPbQDeH
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Swap uncharge knows the memcg only by its private id, and the id can
outlive the memcg it used to belong to after we rebind memcgid to
objcgs.  Make mem_cgroup_private_id_put() take the id and resolve the
memcg containing the refcount internally, and keep the underlying
__mem_cgroup_private_id_put() for the offline path that still holds a
memcg pointer.

In the uncharge path, the memcg pointer will have to be read from the
xarray twice, but we'll fix that later by returning the memcg from the
put path, so the uncharge path can obtain a reference in the same step.

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
 mm/memcontrol.c | 17 ++++++++++++++---
 1 file changed, 14 insertions(+), 3 deletions(-)

diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index ecb4fb07d7735..048c9bb0fad79 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -4038,7 +4038,7 @@ static void mem_cgroup_private_id_remove(struct mem_cgroup *memcg)
 	}
 }
 
-static inline void mem_cgroup_private_id_put(struct mem_cgroup *memcg, unsigned int n)
+static void __mem_cgroup_private_id_put(struct mem_cgroup *memcg, unsigned int n)
 {
 	if (refcount_sub_and_test(n, &memcg->id.ref)) {
 		mem_cgroup_private_id_remove(memcg);
@@ -4048,9 +4048,19 @@ static inline void mem_cgroup_private_id_put(struct mem_cgroup *memcg, unsigned
 	}
 }
 
+static void mem_cgroup_private_id_put(unsigned short id, unsigned int n)
+{
+	struct mem_cgroup *memcg;
+
+	rcu_read_lock();
+	memcg = mem_cgroup_from_private_id(id);
+	__mem_cgroup_private_id_put(memcg, n);
+	rcu_read_unlock();
+}
+
 static void mem_cgroup_private_id_kill(struct mem_cgroup *memcg)
 {
-	mem_cgroup_private_id_put(memcg, 1);
+	__mem_cgroup_private_id_put(memcg, 1);
 }
 
 struct mem_cgroup *mem_cgroup_private_id_get_online(struct mem_cgroup *memcg, unsigned int n)
@@ -5815,9 +5825,10 @@ void __mem_cgroup_uncharge_swap(unsigned short id, unsigned int nr_pages)
 				page_counter_uncharge(&memcg->swap, nr_pages);
 		}
 		mod_memcg_state(memcg, MEMCG_SWAP, -nr_pages);
-		mem_cgroup_private_id_put(memcg, nr_pages);
+		mem_cgroup_private_id_put(id, nr_pages);
 	}
 	rcu_read_unlock();
+
 }
 
 long mem_cgroup_get_nr_swap_pages(struct mem_cgroup *memcg)

-- 
2.43.7

