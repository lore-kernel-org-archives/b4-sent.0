From: Bingfang Guo <bingfangguo@tencent.com>
Date: Tue, 01 Sep 2026 16:58:04 +0800
Subject: [PATCH RFC v2 5/6] mm/memcg: move memcg private ID refcount to
 objcg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260901-bingfangguo-memcgid-rework-v2-5-8edd7f7a7251@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788253095; l=8148;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=bz0oJJYOZ1ur7mPkUre9OVRRcvB/FU5h49DJMMfeoYg=;
 b=0fR3itNFCPfxBX75td2l9MmkZhoxtn6FEtoAv958EYYfiOFI/GM3Ob6dIYQn3aUesuVKevOCm
 JzYj0H0mdFHCs1WEyHffculcUenUNo/vW7C0cT3G8lYGUE7aY/gHx+b
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The memcg private ID is used by objects that can't afford storing a
whole pointer and can outlive memcgs to track the memcg (notably swap
entries). The current design holds a refcount to the css, preventing the
memcg from being freed.  This patch unbinds the lifetime of memcgid from
the memcg so it can be freed.

The idea is to move the refcount of memcgid to one of the memcg's objcg
and hold a pointer and a reference to the objcg in the global memcgid
xarray. No more css reference to the memcg so swapped out pages no
longer pin the dying memcg.

When retrieving the online memcg from the id, the objcg is taken out of
the xarray, and resolves to the online parent memcg naturally, which is
exactly what is expected in normal swapin folio charging path.  For swap
uncharging, the objcg is used for putting the id refcount and getting
the online ancestor in one go.

The exceptions are list_lru and workingset recent test, which require
exact the memcg the id points to. Those callers are fixed in the next
patch.

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
 include/linux/memcontrol.h | 15 +++++-----
 mm/memcontrol.c            | 71 +++++++++++++++++++++++++++++++---------------
 2 files changed, 55 insertions(+), 31 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index f227348a3f24a..eafc817ff244c 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -66,11 +66,6 @@ struct mem_cgroup_reclaim_cookie {
 
 #define MEM_CGROUP_ID_SHIFT	16
 
-struct mem_cgroup_private_id {
-	int id;
-	refcount_t ref;
-};
-
 struct memcg_vmstats_percpu;
 struct memcg1_events_percpu;
 struct memcg_vmstats;
@@ -173,6 +168,7 @@ struct obj_cgroup {
 	struct percpu_ref refcnt;
 	struct mem_cgroup *memcg;
 	atomic_t nr_charged_bytes;
+	refcount_t memcgid_ref;
 	union {
 		struct list_head list; /* protected by objcg_lock */
 		struct rcu_head rcu;
@@ -189,8 +185,8 @@ struct obj_cgroup {
 struct mem_cgroup {
 	struct cgroup_subsys_state css;
 
-	/* Private memcg ID. Used to ID objects that outlive the cgroup */
-	struct mem_cgroup_private_id id;
+	/* The objcg holding private memcg ID. */
+	struct obj_cgroup *id_objcg;
 
 	/* Accounted resources */
 	struct page_counter memory;		/* Both v1 & v2 */
@@ -255,6 +251,9 @@ struct mem_cgroup {
 #endif
 	int kmemcg_id;
 
+	/* Private memcg ID. Used to ID objects that outlive the cgroup */
+	int id;
+
 #ifdef CONFIG_CGROUP_WRITEBACK
 	struct list_head cgwb_list;
 #endif
@@ -810,7 +809,7 @@ static inline unsigned short mem_cgroup_private_id(struct mem_cgroup *memcg)
 	if (mem_cgroup_disabled())
 		return 0;
 
-	return memcg->id.id;
+	return memcg->id;
 }
 struct mem_cgroup *mem_cgroup_from_private_id(unsigned short id);
 
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index f0503a1e5492d..38d2b00657a7a 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -3773,7 +3773,7 @@ static void memcg_online_kmem(struct mem_cgroup *memcg)
 
 	static_branch_enable(&memcg_kmem_online_key);
 
-	memcg->kmemcg_id = memcg->id.id;
+	memcg->kmemcg_id = memcg->id;
 }
 
 static void memcg_offline_kmem(struct mem_cgroup *memcg)
@@ -4032,19 +4032,23 @@ static DEFINE_XARRAY_ALLOC1(mem_cgroup_private_ids);
 
 static void mem_cgroup_private_id_remove(struct mem_cgroup *memcg)
 {
-	if (memcg->id.id > 0) {
-		xa_erase(&mem_cgroup_private_ids, memcg->id.id);
-		memcg->id.id = 0;
+	if (memcg->id > 0) {
+		xa_erase(&mem_cgroup_private_ids, memcg->id);
+		memcg->id = 0;
 	}
 }
 
-static void __mem_cgroup_private_id_put(struct mem_cgroup *memcg, unsigned int n)
+static void __mem_cgroup_private_id_put(struct obj_cgroup *objcg,
+		unsigned short id, unsigned int n)
 {
-	if (refcount_sub_and_test(n, &memcg->id.ref)) {
-		mem_cgroup_private_id_remove(memcg);
+	struct obj_cgroup *objcg_free;
 
-		/* Memcg ID pins CSS */
-		css_put(&memcg->css);
+	if (refcount_sub_and_test(n, &objcg->memcgid_ref)) {
+		objcg_free = xa_erase(&mem_cgroup_private_ids, id);
+		VM_WARN_ON(objcg_free != objcg);
+
+		/* Memcg ID pins the objcg */
+		obj_cgroup_put(objcg);
 	}
 }
 
@@ -4055,18 +4059,20 @@ static void __mem_cgroup_private_id_put(struct mem_cgroup *memcg, unsigned int n
  */
 static struct mem_cgroup *mem_cgroup_private_id_put(unsigned short id, unsigned int n)
 {
-	struct mem_cgroup *memcg;
+	struct mem_cgroup *memcg = NULL;
+	struct obj_cgroup *objcg;
 
 	rcu_read_lock();
-	memcg = mem_cgroup_from_private_id(id);
-	if (!memcg)
+	objcg = xa_load(&mem_cgroup_private_ids, id);
+	if (unlikely(!objcg))
 		goto out;
 
-	__mem_cgroup_private_id_put(memcg, n);
-
+	memcg = obj_cgroup_memcg(objcg);
 	while (memcg_is_dying(memcg) || !mem_cgroup_tryget(memcg))
 		memcg = parent_mem_cgroup(memcg);
 
+	__mem_cgroup_private_id_put(objcg, id, n);
+
 out:
 	rcu_read_unlock();
 	return memcg;
@@ -4074,12 +4080,17 @@ static struct mem_cgroup *mem_cgroup_private_id_put(unsigned short id, unsigned
 
 static void mem_cgroup_private_id_kill(struct mem_cgroup *memcg)
 {
-	__mem_cgroup_private_id_put(memcg, 1);
+	__mem_cgroup_private_id_put(memcg->id_objcg, memcg->id, 1);
 }
 
 struct mem_cgroup *mem_cgroup_private_id_get_online(struct mem_cgroup *memcg, unsigned int n)
 {
-	while (!refcount_add_not_zero(n, &memcg->id.ref)) {
+	struct obj_cgroup *objcg;
+
+	rcu_read_lock();
+	objcg = memcg->id_objcg;
+
+	while (!refcount_add_not_zero(n, &objcg->memcgid_ref)) {
 		/*
 		 * The root cgroup cannot be destroyed, so it's refcount must
 		 * always be >= 1.
@@ -4089,7 +4100,10 @@ struct mem_cgroup *mem_cgroup_private_id_get_online(struct mem_cgroup *memcg, un
 			break;
 		}
 		memcg = parent_mem_cgroup(memcg);
+		objcg = memcg->id_objcg;
 	}
+
+	rcu_read_unlock();
 	return memcg;
 }
 
@@ -4101,8 +4115,14 @@ struct mem_cgroup *mem_cgroup_private_id_get_online(struct mem_cgroup *memcg, un
  */
 struct mem_cgroup *mem_cgroup_from_private_id(unsigned short id)
 {
+	struct obj_cgroup *objcg;
 	WARN_ON_ONCE(!rcu_read_lock_held());
-	return xa_load(&mem_cgroup_private_ids, id);
+
+	objcg = xa_load(&mem_cgroup_private_ids, id);
+	if (!objcg)
+		return NULL;
+
+	return obj_cgroup_memcg(objcg);
 }
 
 struct mem_cgroup *mem_cgroup_get_from_id(u64 id)
@@ -4203,7 +4223,7 @@ static struct mem_cgroup *mem_cgroup_alloc(struct mem_cgroup *parent)
 	if (!memcg)
 		return ERR_PTR(-ENOMEM);
 
-	error = xa_alloc(&mem_cgroup_private_ids, &memcg->id.id, NULL,
+	error = xa_alloc(&mem_cgroup_private_ids, &memcg->id, NULL,
 			 XA_LIMIT(1, MEM_CGROUP_ID_MAX), GFP_KERNEL);
 	if (error)
 		goto fail;
@@ -4348,9 +4368,10 @@ static int mem_cgroup_css_online(struct cgroup_subsys_state *css)
 				   FLUSH_TIME);
 	lru_gen_online_memcg(memcg);
 
-	/* Online state pins memcg ID, memcg ID pins CSS */
-	refcount_set(&memcg->id.ref, 1);
-	css_get(css);
+	/* CSS pins memcg ID, memcg ID pins obj cgroup */
+	memcg->id_objcg = objcg;
+	refcount_set(&memcg->id_objcg->memcgid_ref, 1);
+	obj_cgroup_get(memcg->id_objcg);
 
 	/*
 	 * Ensure mem_cgroup_from_private_id() works once we're fully online.
@@ -4362,7 +4383,7 @@ static int mem_cgroup_css_online(struct cgroup_subsys_state *css)
 	 * publish it here at the end of onlining. This matches the
 	 * regular ID destruction during offlining.
 	 */
-	xa_store(&mem_cgroup_private_ids, memcg->id.id, memcg, GFP_KERNEL);
+	xa_store(&mem_cgroup_private_ids, memcg->id, memcg->id_objcg, GFP_KERNEL);
 
 	return 0;
 free_objcg:
@@ -5832,7 +5853,11 @@ void __mem_cgroup_uncharge_swap(unsigned short id, unsigned int nr_pages)
 	rcu_read_lock();
 	memcg = mem_cgroup_private_id_put(id, nr_pages);
 	if (memcg) {
-		if (!mem_cgroup_is_root(memcg)) {
+		/*
+		 * If the memcg was offline and reparented to root, swap needs
+		 * uncharging as well. We check this by comparing the memcgid.
+		 */
+		if (!mem_cgroup_is_root(memcg) || id != mem_cgroup_private_id(memcg)) {
 			if (do_memsw_account())
 				page_counter_uncharge(&memcg->memsw, nr_pages);
 			else

-- 
2.43.7

