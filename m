From: Bingfang Guo <bingfangguo@tencent.com>
Date: Thu, 13 Aug 2026 16:52:06 +0800
Subject: [PATCH RFC 5/5] memcg: filter out reparented memcgs got using
 memcgid
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-memcgid-objcg-v1-5-83d21c685b77@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786611130; l=2805;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=zY1JXeipRRE4x+8HShYlKEllHTJG9Rn8M3UwjRUwSJk=;
 b=CusELUTT7HqgDWh2KGQvd8fGGqtxEXggEBLMydLTG5KzIJxwbuc5HVMPhaTVT/r1MjFsRGMGg
 Wp/8xlAWmeCC0QRq+pJq/R8DkaLIDm1Gd2BHzegRT2mnbwkdEmg/i4o
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mem_cgroup_from_private_id() looks up the objcg that owns the id and
returns the objcg's current memcg.  After reparenting, that memcg can
differ from the one the id originally belonged to.

Callers such as the list lru and workingset refault code expect to get
back exactly the memcg referred to by the memcgid, so check that the
returned memcg still owns the id and return NULL otherwise, letting
the callers skip the entry.

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
 mm/list_lru.c   | 2 +-
 mm/memcontrol.c | 9 ++++++++-
 mm/workingset.c | 6 +++++-
 3 files changed, 14 insertions(+), 3 deletions(-)

diff --git a/mm/list_lru.c b/mm/list_lru.c
index 36662d02ff963..bc956267f6835 100644
--- a/mm/list_lru.c
+++ b/mm/list_lru.c
@@ -428,7 +428,7 @@ unsigned long list_lru_walk_node(struct list_lru *lru, int nid,
 		xa_for_each(&lru->xa, index, mlru) {
 			rcu_read_lock();
 			memcg = mem_cgroup_from_private_id(index);
-			if (!mem_cgroup_tryget(memcg)) {
+			if (!memcg || !mem_cgroup_tryget(memcg)) {
 				rcu_read_unlock();
 				continue;
 			}
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index fdf2e0d1f17e5..e7555eca77019 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -3999,17 +3999,24 @@ void mem_cgroup_private_id_get(struct mem_cgroup *memcg, unsigned int n)
  * @id: the memcg id to look up
  *
  * Caller must hold rcu_read_lock().
+ *
+ * @return: the memcg, or NULL if the memcg is already reparented.
  */
 struct mem_cgroup *mem_cgroup_from_private_id(unsigned short id)
 {
 	struct obj_cgroup *objcg;
+	struct mem_cgroup *memcg;
 	WARN_ON_ONCE(!rcu_read_lock_held());
 
 	objcg = xa_load(&mem_cgroup_private_ids, id);
 	if (!objcg)
 		return NULL;
 
-	return obj_cgroup_memcg(objcg);
+	memcg = obj_cgroup_memcg(objcg);
+	if (mem_cgroup_private_id(memcg) != id)
+		return NULL;
+
+	return memcg;
 }
 
 /**
diff --git a/mm/workingset.c b/mm/workingset.c
index f351798e723ac..b6e22536a5240 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -283,6 +283,10 @@ static bool lru_gen_test_recent(void *shadow, struct lruvec **lruvec,
 	memcg = mem_cgroup_from_private_id(memcg_id);
 	*lruvec = mem_cgroup_lruvec(memcg, pgdat);
 
+	/* reparented memcg loses its max_seq */
+	if (!memcg)
+		return false;
+
 	max_seq = READ_ONCE((*lruvec)->lrugen.max_seq);
 	max_seq &= (file ? EVICTION_MASK : EVICTION_MASK_ANON) >> LRU_REFS_WIDTH;
 
@@ -470,7 +474,7 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 	 * configurations instead.
 	 */
 	eviction_memcg = mem_cgroup_from_private_id(memcgid);
-	if (!mem_cgroup_tryget(eviction_memcg))
+	if (!eviction_memcg || !mem_cgroup_tryget(eviction_memcg))
 		eviction_memcg = NULL;
 	rcu_read_unlock();
 

-- 
2.43.7

