From: Alireza Asgari <alireza@asgari.net>
Date: Sun, 15 Nov 2026 22:34:44 +0000
Subject: [PATCH RFC nf-next 4/9] memcg: add an owner-bound capacity
 reservation interface
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-b4-nfqueue-memory-accounting-v1-4-b9cc30819997@asgari.net>
References: <20261115-b4-nfqueue-memory-accounting-v1-0-b9cc30819997@asgari.net>
In-Reply-To: <20261115-b4-nfqueue-memory-accounting-v1-0-b9cc30819997@asgari.net>
To: netfilter-devel@vger.kernel.org, linux-mm@kvack.org
Cc: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, 
 Pablo Neira Ayuso <pablo@netfilter.org>, Florian Westphal <fw@strlen.de>, 
 Phil Sutter <phil@nwl.cc>, Shuah Khan <shuah@kernel.org>, 
 Tejun Heo <tj@kernel.org>, Vladimir Davydov <vdavydov.dev@gmail.com>, 
 Chris Down <chris@chrisdown.name>, 
 Zhang Jiao <zhangjiao2@cmss.chinamobile.com>, Song Hu <husong@kylinos.cn>, 
 cgroups@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Alireza Asgari <alireza@asgari.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794782082; l=8813;
 i=alireza@asgari.net; s=alireza-kernel; h=from:subject:message-id;
 bh=OjXsitYCWUxf4IwkzECeKMGMptD9gN0LJJoCyFoRNDQ=;
 b=r5MEYESz730o0FSe8B903OqNKPvShnAbK/J8l27OnJ9FgvqTtZJiUPTAdv1q73mK5aj/nuPYF
 eKEMrgniRjxB7w7fHMNW3L9WLb2htm2L730Uzmr7XCjL+aUnSCKjT/Q
X-Developer-Key: i=alireza@asgari.net; a=ed25519;
 pk=wuQ0/M69FqoVnrCMUJ13EQCwrCwVjCrtz75k15vW8tw=
X-Endpoint-Received: by B4 Relay for alireza@asgari.net/alireza-kernel with auth_id=1055
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

NFQUEUE capacity accounting needs to charge budget in configuration
context while preserving the owner selected when the queue was bound.
Add a proposed bulk page-reservation interface backed by a referenced
objcg. This reserves accounting budget; it does not allocate physical
pages or replace the charges for real allocations.

Track logical reserved pages separately from pages actually charged.
The distinction permits uncharged growth after reparenting to root while
still refunding inherited charges. Apply actual recorded refunds to the
page counters even when the current owner is root.

Use bounded GFP_NOWAIT charge batches. Failed growth rolls back its new
charges and leaves the old reservation intact. Reject PF_MEMALLOC growth
rather than allowing forced charges. Callers serialize operations in
sleepable context; ordinary memory.high handling can remain deferred.
On this base, deferred handling can target the current task's cgroup
instead of a saved owner after task migration.

Positive growth with a captured owner requires a 64-bit kernel. Virtual
reservations can otherwise bring shared 32-bit page counters near their
signed range without allocating matching physical memory. No-owner
reservations, shrinking, and destruction remain supported on 32-bit.

The API, use of ordinary memcg usage for empty capacity, and architecture
restriction are RFC policy choices requiring MM review.

Signed-off-by: Alireza Asgari <alireza@asgari.net>
---
 include/linux/memcontrol.h |  35 ++++++++++
 mm/memcontrol.c            | 163 +++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 198 insertions(+)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index 69e1bcc67c58..d25ff10976ec 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -32,6 +32,41 @@ struct mm_struct;
 struct kmem_cache;
 struct swap_cluster_info;
 
+/* Capacity accounting without allocating the reserved pages. */
+struct mem_cgroup_reservation {
+	struct obj_cgroup *objcg;
+	u64 pages;
+	u64 charged_pages; /* excludes growth after reparenting to root */
+};
+
+#ifdef CONFIG_MEMCG
+void mem_cgroup_reservation_init(struct mem_cgroup_reservation *res);
+int mem_cgroup_reservation_resize(struct mem_cgroup_reservation *res,
+				  u64 pages);
+void mem_cgroup_reservation_destroy(struct mem_cgroup_reservation *res);
+#else
+static inline void
+mem_cgroup_reservation_init(struct mem_cgroup_reservation *res)
+{
+	res->objcg = NULL;
+	res->pages = 0;
+	res->charged_pages = 0;
+}
+
+static inline int
+mem_cgroup_reservation_resize(struct mem_cgroup_reservation *res, u64 pages)
+{
+	res->pages = pages;
+	return 0;
+}
+
+static inline void
+mem_cgroup_reservation_destroy(struct mem_cgroup_reservation *res)
+{
+	mem_cgroup_reservation_init(res);
+}
+#endif
+
 /* Cgroup-specific page state, on top of universal node page state */
 enum memcg_stat_item {
 	MEMCG_SWAP = NR_VM_NODE_STAT_ITEMS,
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 446b60ca6aef..0227d9b411f5 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -3255,6 +3255,169 @@ static int obj_cgroup_charge_pages(struct obj_cgroup *objcg, gfp_t gfp,
 	return ret;
 }
 
+/* Keep both the page count and the signed kmem statistics deltas in range. */
+#define MEMCG_RESERVATION_BATCH (SZ_1G >> PAGE_SHIFT)
+
+static int mem_cgroup_reservation_charge(struct obj_cgroup *objcg,
+					 unsigned int pages, bool *charged)
+{
+	struct mem_cgroup *memcg;
+	int ret = 0;
+
+	memcg = get_mem_cgroup_from_objcg(objcg);
+	*charged = false;
+	/* Reparenting to root removes the limit, not previously held charges. */
+	if (!mem_cgroup_is_root(memcg)) {
+		/* Do not reclaim repeatedly while the caller serializes configuration. */
+		ret = try_charge(memcg, GFP_NOWAIT, pages);
+		if (!ret) {
+			account_kmem_nmi_safe(memcg, pages);
+			memcg1_account_kmem(memcg, pages);
+			*charged = true;
+		}
+	}
+	css_put(&memcg->css);
+	return ret;
+}
+
+static void mem_cgroup_reservation_uncharge_batch(struct mem_cgroup *memcg,
+						  unsigned int pages)
+{
+	account_kmem_nmi_safe(memcg, -pages);
+	memcg1_account_kmem(memcg, -pages);
+	/* These pages were charged, even if their owner is now root. */
+	memcg_uncharge(memcg, pages);
+}
+
+static void mem_cgroup_reservation_uncharge(struct obj_cgroup *objcg, u64 pages)
+{
+	while (pages) {
+		unsigned int batch = min_t(u64, pages, MEMCG_RESERVATION_BATCH);
+		struct mem_cgroup *memcg;
+
+		memcg = get_mem_cgroup_from_objcg(objcg);
+		mem_cgroup_reservation_uncharge_batch(memcg, batch);
+		css_put(&memcg->css);
+		pages -= batch;
+		cond_resched();
+	}
+}
+
+/**
+ * mem_cgroup_reservation_init - capture the current kernel memory owner
+ * @res: uninitialized reservation
+ *
+ * The owner is referenced until destruction and follows objcg reparenting.
+ * Root ownership or disabled kmem accounting leaves an uncharged reservation.
+ * The caller must serialize operations and use sleepable task context.
+ */
+void mem_cgroup_reservation_init(struct mem_cgroup_reservation *res)
+{
+	*res = (struct mem_cgroup_reservation){};
+	if (!mem_cgroup_disabled() && !mem_cgroup_kmem_disabled()) {
+		res->objcg = get_obj_cgroup_from_current();
+		if (res->objcg && obj_cgroup_is_root(res->objcg)) {
+			obj_cgroup_put(res->objcg);
+			res->objcg = NULL;
+		}
+	}
+}
+EXPORT_SYMBOL_GPL(mem_cgroup_reservation_init);
+
+/**
+ * mem_cgroup_reservation_resize - change a capacity charge in pages
+ * @res: initialized, externally serialized reservation
+ * @pages: new total reservation, in pages
+ *
+ * Growth does not reclaim, invoke the memcg OOM killer, or force-charge a
+ * failing reservation. It may therefore fail despite reclaimable memory.
+ * A failed growth leaves the old charge intact. This reserves budget, not
+ * physical pages, and does not replace charges for actual allocations.
+ * Growth with a captured owner requires a 64-bit kernel: virtual reservations
+ * must not bring 32-bit page counters close to their signed arithmetic limit.
+ * Unsupported growth returns -EOPNOTSUPP without changing the reservation.
+ * Reservations initialized without an owner, shrinking, and destruction
+ * remain supported.
+ *
+ * Successful growth may schedule deferred memory.high handling for current.
+ * That handler uses current's mm owner, which can differ from the reservation
+ * owner after task migration or cgroup reparenting. It does not guarantee
+ * reclaim or throttling for the charged owner. memory.max checks still use
+ * the reservation owner and its ancestors.
+ *
+ * Return: zero on success, or a negative error code.
+ */
+int mem_cgroup_reservation_resize(struct mem_cgroup_reservation *res, u64 pages)
+{
+	u64 charged = 0, remaining;
+	int ret;
+
+	BUILD_BUG_ON(!MEMCG_RESERVATION_BATCH);
+	BUILD_BUG_ON(MEMCG_RESERVATION_BATCH > INT_MAX);
+
+	if (!res->objcg)
+		goto commit;
+	if (pages > PAGE_COUNTER_MAX)
+		return -E2BIG;
+	if (pages <= res->pages) {
+		u64 retained = min(pages, res->charged_pages);
+
+		mem_cgroup_reservation_uncharge(res->objcg,
+						res->charged_pages - retained);
+		res->charged_pages = retained;
+		goto commit;
+	}
+	if (!IS_ENABLED(CONFIG_64BIT))
+		return -EOPNOTSUPP;
+	/* try_charge_memcg() otherwise allows reclaim contexts to overcharge. */
+	if (current->flags & PF_MEMALLOC)
+		return -ENOMEM;
+
+	remaining = pages - res->pages;
+	while (remaining) {
+		unsigned int batch =
+			min_t(u64, remaining, MEMCG_RESERVATION_BATCH);
+		bool accounted;
+
+		if (fatal_signal_pending(current)) {
+			ret = -EINTR;
+			goto rollback;
+		}
+		ret = mem_cgroup_reservation_charge(res->objcg, batch,
+						    &accounted);
+		if (ret)
+			goto rollback;
+		if (accounted)
+			charged += batch;
+		remaining -= batch;
+		cond_resched();
+	}
+	res->charged_pages += charged;
+commit:
+	res->pages = pages;
+	return 0;
+rollback:
+	mem_cgroup_reservation_uncharge(res->objcg, charged);
+	return ret;
+}
+EXPORT_SYMBOL_GPL(mem_cgroup_reservation_resize);
+
+/**
+ * mem_cgroup_reservation_destroy - release capacity and its owner reference
+ * @res: reservation with no remaining concurrent users
+ */
+void mem_cgroup_reservation_destroy(struct mem_cgroup_reservation *res)
+{
+	if (res->objcg) {
+		mem_cgroup_reservation_uncharge(res->objcg, res->charged_pages);
+		obj_cgroup_put(res->objcg);
+	}
+	res->objcg = NULL;
+	res->pages = 0;
+	res->charged_pages = 0;
+}
+EXPORT_SYMBOL_GPL(mem_cgroup_reservation_destroy);
+
 static struct obj_cgroup *page_objcg(const struct page *page)
 {
 	unsigned long memcg_data = page->memcg_data;

-- 
2.34.1

