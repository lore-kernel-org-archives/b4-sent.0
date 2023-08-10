From: Zachary Goldstein <zachary.goldstein@concurrent-rt.com>
Date: Thu, 10 Aug 2023 15:05:34 -0400
Subject: [PATCH RT] mm/memcg: Fix recursive locking on refill_stock() on
 PREEMPT_RT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230809-memcg-fix-recursive-lock-v1-1-0870815484c6@concurrent-rt.com>
X-B4-Tracking: v=1; b=H4sIAP001WQC/x2NQQ6CMBBFr0Jm7ZgCMYLHMO6Mi3b8QqMUMsWGh
 HB3i8uXl//+ShHqEelSrKRIPvoxZCgPBUlvQwf2z8xUmao2jWl5wCAdv/zCCvlq9An8GeXNEGl
 EHM5tXVOeOxvBTm2Qfg+k07E0rDMHLPPuJ0Wu/K/vdL3RY9t+pvjoHI4AAAA=
To: linux-mm@kvack.org, cgroups@vger.kernel.org
Cc: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Vladimir Davydov <vdavydov.dev@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Sebastian Andrzej Siewior <bigeasy@linutronix.de>, 
 Thomas Gleixner <tglx@linutronix.de>, Steven Rostedt <rostedt@goodmis.org>, 
 linux-kernel@vger.kernel.org, linux-rt-users@vger.kernel.org, 
 Zachary Goldstein <zachary.goldstein@concurrent-rt.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1691694539; l=3174;
 i=zachary.goldstein@concurrent-rt.com; s=20230809; h=from:subject:message-id;
 bh=iGCY5O8pU90PvwzpSq10zAF0Xf00Oq3bpeBOxq/cAek=;
 b=0aJq6ecGEBSIY9wfC7XKUKq9WBhQh5kGwH74a64bwReInzEPOAdFARO74YqaxHYeNuO34f2AC
 CjAntrJQVhPBUN9HNANwJ+l3vOvu1T13Y/zZGi+XgFi0NP+BRcVYOjS
X-Developer-Key: i=zachary.goldstein@concurrent-rt.com; a=ed25519;
 pk=GLF18lQ96tRolyWMpDtJzDQ9bi7+1+rMHript5TFdSg=
X-Endpoint-Received: by B4 Relay for zachary.goldstein@concurrent-rt.com/20230809 with auth_id=74
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

5.10 suffers from the same recursive locking issue that
commit a848d25434de4 ("mm/memcg: Opencode the inner part of
obj_cgroup_uncharge_pages() in drain_obj_stock()") fixes.

Modified description from the commit to reflect this patch changes:

Provide the inner part of refill_stock() as __refill_stock() without
disabling interrupts. This eases the integration of local_lock_t where
recursive locking must be avoided.
Open code __memcg_kmem_uncharge() in drain_obj_stock() and
obj_cgroup_release() and use __refill_stock(). The caller of
drain_obj_stock() and obj_cgroup_release() already disables interrupts.

Signed-off-by: Zachary Goldstein <zachary.goldstein@concurrent-rt.com>
---
 mm/memcontrol.c | 28 +++++++++++++++++++++-------
 1 file changed, 21 insertions(+), 7 deletions(-)

diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 5dd77e260c25..d61918cc44c1 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -260,6 +260,8 @@ struct cgroup_subsys_state *vmpressure_to_css(struct vmpressure *vmpr)
 #ifdef CONFIG_MEMCG_KMEM
 static DEFINE_SPINLOCK(objcg_lock);
 
+static void __refill_stock(struct mem_cgroup *memcg, unsigned int nr_pages);
+
 static void obj_cgroup_release(struct percpu_ref *ref)
 {
 	struct obj_cgroup *objcg = container_of(ref, struct obj_cgroup, refcnt);
@@ -294,8 +296,12 @@ static void obj_cgroup_release(struct percpu_ref *ref)
 
 	spin_lock_irqsave(&objcg_lock, flags);
 	memcg = obj_cgroup_memcg(objcg);
-	if (nr_pages)
-		__memcg_kmem_uncharge(memcg, nr_pages);
+	if (nr_pages) {
+		if (!cgroup_subsys_on_dfl(memory_cgrp_subsys))
+			page_counter_uncharge(&memcg->kmem, nr_pages);
+
+		__refill_stock(memcg, nr_pages);
+	}
 	list_del(&objcg->list);
 	mem_cgroup_put(memcg);
 	spin_unlock_irqrestore(&objcg_lock, flags);
@@ -2319,12 +2325,9 @@ static void drain_local_stock(struct work_struct *dummy)
  * Cache charges(val) to local per_cpu area.
  * This will be consumed by consume_stock() function, later.
  */
-static void refill_stock(struct mem_cgroup *memcg, unsigned int nr_pages)
+static void __refill_stock(struct mem_cgroup *memcg, unsigned int nr_pages)
 {
 	struct memcg_stock_pcp *stock;
-	unsigned long flags;
-
-	local_lock_irqsave(&memcg_stock.lock, flags);
 
 	stock = this_cpu_ptr(&memcg_stock);
 	if (stock->cached != memcg) { /* reset if necessary */
@@ -2336,7 +2339,14 @@ static void refill_stock(struct mem_cgroup *memcg, unsigned int nr_pages)
 
 	if (stock->nr_pages > MEMCG_CHARGE_BATCH)
 		drain_stock(stock);
+}
 
+static void refill_stock(struct mem_cgroup *memcg, unsigned int nr_pages)
+{
+	unsigned long flags;
+
+	local_lock_irqsave(&memcg_stock.lock, flags);
+	__refill_stock(memcg, nr_pages);
 	local_unlock_irqrestore(&memcg_stock.lock, flags);
 }
 
@@ -3179,7 +3189,11 @@ static void drain_obj_stock(struct memcg_stock_pcp *stock)
 				goto retry;
 			rcu_read_unlock();
 
-			__memcg_kmem_uncharge(memcg, nr_pages);
+			if (!cgroup_subsys_on_dfl(memory_cgrp_subsys))
+				page_counter_uncharge(&memcg->kmem, nr_pages);
+
+			__refill_stock(memcg, nr_pages);
+
 			css_put(&memcg->css);
 		}
 

--
2.39.2

