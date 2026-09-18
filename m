From: Jingxiang Zeng <linuszeng@tencent.com>
Date: Fri, 18 Sep 2026 16:53:44 +0800
Subject: [PATCH 4/6] mm: memcontrol: give swap and memsw their own page
 counters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-descriptive-name-v1-4-dfcfdd91b456@tencent.com>
References: <20260918-descriptive-name-v1-0-dfcfdd91b456@tencent.com>
In-Reply-To: <20260918-descriptive-name-v1-0-dfcfdd91b456@tencent.com>
To: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Maarten Lankhorst <dev@lankhorst.se>, Maxime Ripard <mripard@kernel.org>, 
 Natalie Vock <nat@pixelcluster.dev>, Tejun Heo <tj@kernel.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Oscar Salvador <osalvador@suse.de>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: Jingxiang Zeng <jingxiangzeng.cas@gmail.com>, cgroups@vger.kernel.org, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-doc@vger.kernel.org, 
 Jingxiang Zeng <linuszeng@tencent.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721651; l=9416;
 i=linuszeng@tencent.com; s=20260909; h=from:subject:message-id;
 bh=3nVozcwT8fvm9kkRHSGOBpv9SiIXCVqsk3cpyNYsL4o=;
 b=T9k2eZse7y/gatzeWXlUZwF/Fn5ZipNDfa7RtRVfizOuLg1R8eN3NEGBgvBiVe98EnIzGGiAj
 jat5Iz4MsxAC2WhrcbCOztMx5JyvInRK1PmzVCHvdfkE+w45u0TfypR
X-Developer-Key: i=linuszeng@tencent.com; a=ed25519;
 pk=6K54xRzYIRWqatrAPy86M4E0MsI92BVJBhXwz5NdC74=
X-Endpoint-Received: by B4 Relay for linuszeng@tencent.com/20260909 with auth_id=1017
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

struct mem_cgroup keeps the swap and memsw page counters in a union: v1
only ever charges memsw, the combined memory+swap counter, and v2 only
ever charges swap, the standalone swap limit, so the two could share
storage.

Split them into separate counters and maintain memsw on both
hierarchies.  do_memsw_account() no longer gates the combined charge in
try_charge_memcg(), memcg_uncharge(), the force-charge path,
mem_cgroup_replace_folio() and mem_cgroup_margin(); v2 also hands the
combined charge over to the swap slot in __mem_cgroup_try_charge_swap()
and drops it again in __mem_cgroup_uncharge_swap().  The counter is
initialised for both hierarchies in mem_cgroup_css_alloc() and reset in
mem_cgroup_css_reset().

memsw.max defaults to PAGE_COUNTER_MAX and v2 has no interface to
change it yet, so the combined charge cannot fail there and behaviour
on the default hierarchy is unchanged.  The default hierarchy does pay
for one extra page_counter operation per charge and uncharge, and
struct mem_cgroup grows by one page counter (128 bytes on x86_64).

Note that v2 briefly counts a page twice against the combined counter
while it is being swapped out: the folio keeps its memsw charge until
it leaves memory, and the swap slot takes one as soon as it is
allocated.  v1 avoids this by clearing folio->memcg_data under the swap
cluster lock, which the v2 swapout path does not do.  The skew only
ever makes the combined limit stricter, never looser.

No functional change on either hierarchy.

Signed-off-by: Jingxiang Zeng <linuszeng@tencent.com>
---
 include/linux/memcontrol.h | 12 ++++---
 mm/memcontrol.c            | 78 ++++++++++++++++++++++++++++++----------------
 2 files changed, 59 insertions(+), 31 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index ff69a390a809..bd69caee282c 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -206,10 +206,14 @@ struct mem_cgroup {
 	 */
 	struct page_counter_protection memory_prot;
 
-	union {
-		struct page_counter swap;	/* v2 only */
-		struct page_counter memsw;	/* v1 only */
-	};
+	/*
+	 * Swap accounting.  These used to share storage because v1 only ever
+	 * used memsw (the combined memory+swap limit) and v2 only ever used
+	 * swap (a standalone swap limit).  They are separate now so that the
+	 * combined counter can be maintained on both hierarchies.
+	 */
+	struct page_counter swap;	/* Standalone swap limit, v2 only */
+	struct page_counter memsw;	/* Combined memory+swap, v1 & v2 */
 
 	/* Written on the charge, reclaim and socket paths. */
 	__cacheline_group_begin_aligned(memcg_write_hot);
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index aaf23e849408..1daa55f2e99d 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -1591,14 +1591,17 @@ static unsigned long mem_cgroup_margin(struct mem_cgroup *memcg)
 	if (count < limit)
 		margin = limit - count;
 
-	if (do_memsw_account()) {
-		count = page_counter_read(&memcg->memsw);
-		limit = READ_ONCE(memcg->memsw.max);
-		if (count < limit)
-			margin = min(margin, limit - count);
-		else
-			margin = 0;
-	}
+	/*
+	 * The combined memory+swap limit applies on both hierarchies and
+	 * caps what can still be charged.  It defaults to "max", so this
+	 * only narrows the margin once a combined limit is configured.
+	 */
+	count = page_counter_read(&memcg->memsw);
+	limit = READ_ONCE(memcg->memsw.max);
+	if (count < limit)
+		margin = min(margin, limit - count);
+	else
+		margin = 0;
 
 	return margin;
 }
@@ -2188,8 +2191,7 @@ static bool consume_stock(struct mem_cgroup *memcg, unsigned int nr_pages)
 static void memcg_uncharge(struct mem_cgroup *memcg, unsigned int nr_pages)
 {
 	page_counter_uncharge(&memcg->memory, nr_pages);
-	if (do_memsw_account())
-		page_counter_uncharge(&memcg->memsw, nr_pages);
+	page_counter_uncharge(&memcg->memsw, nr_pages);
 }
 
 /*
@@ -2721,12 +2723,19 @@ static int try_charge_memcg(struct mem_cgroup *memcg, gfp_t gfp_mask,
 		batch = nr_pages;
 
 	reclaim_options = MEMCG_RECLAIM_MAY_SWAP;
-	if (!do_memsw_account() ||
-	    page_counter_try_charge(&memcg->memsw, batch, &counter)) {
+	/*
+	 * The combined memory+swap counter is charged on both hierarchies.
+	 * Its limit is only configurable through v1's memsw.limit_in_bytes
+	 * for now and defaults to "max", so unless the user configures a
+	 * combined limit this never fails.
+	 *
+	 * Swapping does not reduce the combined charge, so when the combined
+	 * limit is what we hit, reclaim must not count on swap.
+	 */
+	if (page_counter_try_charge(&memcg->memsw, batch, &counter)) {
 		if (page_counter_try_charge(&memcg->memory, batch, &counter))
 			goto done_restock;
-		if (do_memsw_account())
-			page_counter_uncharge(&memcg->memsw, batch);
+		page_counter_uncharge(&memcg->memsw, batch);
 		mem_over_limit = mem_cgroup_from_counter(counter, memory);
 	} else {
 		mem_over_limit = mem_cgroup_from_counter(counter, memsw);
@@ -2836,8 +2845,7 @@ static int try_charge_memcg(struct mem_cgroup *memcg, gfp_t gfp_mask,
 	 * temporarily by force charging it.
 	 */
 	page_counter_charge(&memcg->memory, nr_pages);
-	if (do_memsw_account())
-		page_counter_charge(&memcg->memsw, nr_pages);
+	page_counter_charge(&memcg->memsw, nr_pages);
 
 out:
 	/*
@@ -4295,12 +4303,14 @@ mem_cgroup_css_alloc(struct cgroup_subsys_state *parent_css)
 	WRITE_ONCE(memcg->zswap_writeback, true);
 #endif
 	page_counter_set_high(&memcg->swap, PAGE_COUNTER_MAX);
+	page_counter_set_high(&memcg->memsw, PAGE_COUNTER_MAX);
 	if (parent) {
 		page_counter_init(&memcg->memory, &parent->memory);
 		if (memcg_on_dfl)
 			page_counter_init_protection(&memcg->memory, &memcg->memory_prot,
 						     &parent->memory_prot);
 		page_counter_init(&memcg->swap, &parent->swap);
+		page_counter_init(&memcg->memsw, &parent->memsw);
 #ifdef CONFIG_MEMCG_V1
 		WRITE_ONCE(memcg->swappiness, mem_cgroup_swappiness(parent));
 		memcg->memory.track_failcnt = !memcg_on_dfl;
@@ -4317,6 +4327,7 @@ mem_cgroup_css_alloc(struct cgroup_subsys_state *parent_css)
 		page_counter_init_protection(&memcg->memory, &memcg->memory_prot,
 					     NULL);
 		page_counter_init(&memcg->swap, NULL);
+		page_counter_init(&memcg->memsw, NULL);
 #ifdef CONFIG_MEMCG_V1
 		page_counter_init(&memcg->kmem, NULL);
 		page_counter_init(&memcg->tcpmem, NULL);
@@ -4490,6 +4501,7 @@ static void mem_cgroup_css_reset(struct cgroup_subsys_state *css)
 
 	page_counter_set_max(&memcg->memory, PAGE_COUNTER_MAX);
 	page_counter_set_max(&memcg->swap, PAGE_COUNTER_MAX);
+	page_counter_set_max(&memcg->memsw, PAGE_COUNTER_MAX);
 	WRITE_ONCE(memcg->oom_group, false);
 #ifdef CONFIG_ZSWAP
 	WRITE_ONCE(memcg->zswap_max, PAGE_COUNTER_MAX);
@@ -4503,6 +4515,7 @@ static void mem_cgroup_css_reset(struct cgroup_subsys_state *css)
 	page_counter_set_low(&memcg->memory, 0);
 	page_counter_set_high(&memcg->memory, PAGE_COUNTER_MAX);
 	page_counter_set_high(&memcg->swap, PAGE_COUNTER_MAX);
+	page_counter_set_high(&memcg->memsw, PAGE_COUNTER_MAX);
 	memcg_wb_domain_size_changed(memcg);
 }
 
@@ -5608,8 +5621,7 @@ void mem_cgroup_replace_folio(struct folio *old, struct folio *new)
 	 */
 	if (!obj_cgroup_is_root(objcg)) {
 		page_counter_charge(&memcg->memory, nr_pages);
-		if (do_memsw_account())
-			page_counter_charge(&memcg->memsw, nr_pages);
+		page_counter_charge(&memcg->memsw, nr_pages);
 	}
 
 	commit_charge(new, objcg);
@@ -5980,12 +5992,24 @@ int __mem_cgroup_try_charge_swap(struct folio *folio)
 	/* memcg is pined by memcg ID. */
 	rcu_read_unlock();
 
-	if (!mem_cgroup_is_root(memcg) &&
-	    !page_counter_try_charge(&memcg->swap, nr_pages, &counter)) {
-		memcg_memory_event(memcg, MEMCG_SWAP_MAX);
-		memcg_memory_event(memcg, MEMCG_SWAP_FAIL);
-		mem_cgroup_private_id_put(memcg, nr_pages);
-		return -ENOMEM;
+	if (!mem_cgroup_is_root(memcg)) {
+		if (!page_counter_try_charge(&memcg->swap, nr_pages, &counter)) {
+			memcg_memory_event(memcg, MEMCG_SWAP_MAX);
+			memcg_memory_event(memcg, MEMCG_SWAP_FAIL);
+			mem_cgroup_private_id_put(memcg, nr_pages);
+			return -ENOMEM;
+		}
+		/*
+		 * Hand the combined memory+swap charge over to the swap slot.
+		 * The folio still holds a memsw charge and drops it when it
+		 * leaves memory, so the combined charge stays constant across
+		 * the swapout; it is briefly counted twice in between, which
+		 * only ever makes the combined limit stricter.
+		 *
+		 * Force-charge here: this is a transfer of an existing charge,
+		 * not a new allocation, so it must not fail.
+		 */
+		page_counter_charge(&memcg->memsw, nr_pages);
 	}
 	mod_memcg_state(memcg, MEMCG_SWAP, nr_pages);
 
@@ -6010,10 +6034,10 @@ void __mem_cgroup_uncharge_swap(unsigned short id, unsigned int nr_pages)
 	memcg = mem_cgroup_from_private_id(id);
 	if (memcg) {
 		if (!mem_cgroup_is_root(memcg)) {
-			if (do_memsw_account())
-				page_counter_uncharge(&memcg->memsw, nr_pages);
-			else
+			/* v1 tracks swap only through the combined counter */
+			if (!do_memsw_account())
 				page_counter_uncharge(&memcg->swap, nr_pages);
+			page_counter_uncharge(&memcg->memsw, nr_pages);
 		}
 		mod_memcg_state(memcg, MEMCG_SWAP, -nr_pages);
 		mem_cgroup_private_id_put(memcg, nr_pages);

-- 
2.43.7

