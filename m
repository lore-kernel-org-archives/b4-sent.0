From: Bingfang Guo <bingfangguo@tencent.com>
Date: Thu, 13 Aug 2026 16:52:05 +0800
Subject: [PATCH RFC 4/5] memcg: add a helper to get online memcg from
 memcgid
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-memcgid-objcg-v1-4-83d21c685b77@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786611130; l=2588;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=9eOtm2zMK/wYtzZgGx4xX57blghdDku36wwXT3ij+M4=;
 b=WM11z9bUgck0UICbTCfnt20vuTyNOqdecwoNJvQu5KCqITzAtCi1u5O7CuPml+516VwM/0RIf
 vroA/tx5h04A0FUcWL3DZ/ltvYeJU8pD2+eJ3eqxKUBOjxHI2+PZ/95
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When swapping in, the folio is charged back to the memcg that swapped
it out, or to one of its ancestors if that memcg is gone.
mem_cgroup_swapin_charge_folio() currently does the id lookup and the
css_tryget_online() check by hand under the RCU read lock.

The objcg behind the id is reparented to an online memcg when its own
memcg is destroyed, so looking the id up and taking a reference
through the objcg is enough to guarantee an online memcg.  Add
mem_cgroup_from_private_id_online() for that purpose and use it in
mem_cgroup_swapin_charge_folio(), dropping the RCU read lock usage.

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
 include/linux/memcontrol.h |  1 +
 mm/memcontrol.c            | 22 ++++++++++++++++++----
 2 files changed, 19 insertions(+), 4 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index c33ec7efad50b..fef8a1c4191b1 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -827,6 +827,7 @@ static inline unsigned short mem_cgroup_private_id(struct mem_cgroup *memcg)
 	return memcg->id;
 }
 struct mem_cgroup *mem_cgroup_from_private_id(unsigned short id);
+struct mem_cgroup *mem_cgroup_from_private_id_online(unsigned short id);
 
 static inline u64 mem_cgroup_id(struct mem_cgroup *memcg)
 {
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 12545ca48194d..fdf2e0d1f17e5 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -4012,6 +4012,22 @@ struct mem_cgroup *mem_cgroup_from_private_id(unsigned short id)
 	return obj_cgroup_memcg(objcg);
 }
 
+/**
+ * mem_cgroup_from_private_id - look up an online memcg from a memcg id
+ *                              and get a reference.
+ * @id: the memcg id to look up
+ */
+struct mem_cgroup *mem_cgroup_from_private_id_online(unsigned short id)
+{
+	struct obj_cgroup *objcg;
+
+	objcg = xa_load(&mem_cgroup_private_ids, id);
+	if (!objcg)
+		return NULL;
+
+	return get_mem_cgroup_from_objcg(objcg);
+}
+
 static struct mem_cgroup *mem_cgroup_take_from_private_id(unsigned short id, unsigned int n)
 {
 	struct obj_cgroup *objcg;
@@ -5248,11 +5264,9 @@ int mem_cgroup_swapin_charge_folio(struct folio *folio, unsigned short id,
 	if (mem_cgroup_disabled())
 		return 0;
 
-	rcu_read_lock();
-	memcg = mem_cgroup_from_private_id(id);
-	if (!memcg || !css_tryget_online(&memcg->css))
+	memcg = mem_cgroup_from_private_id_online(id);
+	if (!memcg)
 		memcg = get_mem_cgroup_from_mm(mm);
-	rcu_read_unlock();
 
 	ret = charge_memcg(folio, memcg, gfp);
 

-- 
2.43.7

