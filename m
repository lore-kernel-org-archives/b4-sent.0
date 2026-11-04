From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 04 Nov 2026 18:59:08 +0900
Subject: [PATCH 1/2] mm/huge_memory: set memcg_data before a split page
 leaves the folio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-kpagecgroup-split-v1-1-f70e947fec85@samsung.com>
References: <20261104-kpagecgroup-split-v1-0-f70e947fec85@samsung.com>
In-Reply-To: <20261104-kpagecgroup-split-v1-0-f70e947fec85@samsung.com>
To: Andrew Morton <akpm@linux-foundation.org>
Cc: Tao Yi <escape@deepseek.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 David Hildenbrand <david@kernel.org>, Zi Yan <ziy@nvidia.com>, 
 Matthew Wilcox <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Nico Pache <nico.pache@linux.dev>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Barry Song <baohua@kernel.org>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Brendan Jackman <brendan.jackman@linux.dev>, linux-mm@kvack.org, 
 cgroups@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793786347; l=3540;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=cwh5/ANoMn3q9VykAu3ZRo+0WnStzvXM2AIm27t94Zo=;
 b=LfLHZKKD4ZZoASkLp/QUsGDpPgsHyik7sI6TFEG8bIwDQ7hcqjurrCS9tT9tVzD2uMffIdinU
 W/ilRC7e8NWCpqe/mTE/+m/FmR8U19gtyf7Q6smPjJhulLiU663ynWV
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__split_folio_to_order() copies memcg_data to a new folio after
clear_compound_head(). Until then, memcg_data of the first tail page
holds the folio's _nr_pages. page_cgroup_ino() can see that page as a
folio in the window and take _nr_pages for an objcg pointer. Reading
/proc/kpagecgroup as root then oopses while folios are split to
order 0.

Copy memcg_data before the smp_wmb(), as before commit fa23a338de93
("mm: separate folio_split_memcg_refs() from split_page_memcg()"). Add
the paired smp_rmb() to page_cgroup_ino().

Fixes: fa23a338de93 ("mm: separate folio_split_memcg_refs() from split_page_memcg()")
Reported-by: Tao Yi <escape@deepseek.com>
Closes: https://lore.kernel.org/all/20260907124001.1544655-1-escape@deepseek.com/
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested on x86_64 with KASAN (7.3-rc7 and mm-hotfixes-unstable) in an
8-vCPU QEMU guest: six threads read /proc/kpagecgroup for page 1 of 64
THPs that debugfs split_huge_pages splits to order 0. Base oopsed in 6
of 6 runs, 4 of them within 1.5 s. With patch 1, 8 runs of 300 s had
no oops.

Before 7.4, page_cgroup_ino() and folio_memcg_check() take non-const
pointers, so a stable backport needs "struct folio *folio" there. The
hunk applies to those trees without a conflict, and the build then
fails with CONFIG_WERROR=y (-Wdiscarded-qualifiers).
---
 mm/huge_memory.c | 17 +++++++++++++----
 mm/memcontrol.c  |  9 ++++++++-
 2 files changed, 21 insertions(+), 5 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 14599d0fff..adc5a47ee7 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3768,7 +3768,19 @@ static void __split_folio_to_order(struct folio *folio, int old_order,
 		if (folio_test_swapcache(folio))
 			new_folio->swap.val = folio->swap.val + i;
 
-		/* Page flags must be visible before we make the page non-compound. */
+#ifdef CONFIG_MEMCG
+		/*
+		 * In the first tail page, memcg_data still holds
+		 * folio->_nr_pages. Lockless PFN walkers (page_cgroup_ino(),
+		 * page_owner) read memcg_data once the page is not a tail.
+		 */
+		new_folio->memcg_data = folio->memcg_data;
+#endif
+
+		/*
+		 * Page flags and memcg_data must be visible before we make the
+		 * page non-compound.
+		 */
 		smp_wmb();
 
 		/*
@@ -3803,9 +3815,6 @@ static void __split_folio_to_order(struct folio *folio, int old_order,
 			folio_set_young(new_folio);
 		if (folio_test_idle(folio))
 			folio_set_idle(new_folio);
-#ifdef CONFIG_MEMCG
-		new_folio->memcg_data = folio->memcg_data;
-#endif
 
 		folio_xchg_last_cpupid(new_folio, folio_last_cpupid(folio));
 	}
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 84f4a8fd4d..c244d56446 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -375,12 +375,19 @@ struct cgroup_subsys_state *get_mem_cgroup_css_from_folio(const struct folio *fo
  */
 ino_t page_cgroup_ino(const struct page *page)
 {
+	const struct folio *folio;
 	struct mem_cgroup *memcg;
 	unsigned long ino = 0;
 
 	rcu_read_lock();
 	/* page_folio() is racy here, but the entire function is racy anyway */
-	memcg = folio_memcg_check(page_folio(page));
+	folio = page_folio(page);
+	/*
+	 * Order the memcg_data load after the compound_info load in
+	 * page_folio(). Pairs with smp_wmb() in __split_folio_to_order().
+	 */
+	smp_rmb();
+	memcg = folio_memcg_check(folio);
 
 	while (memcg && !css_is_online(&memcg->css))
 		memcg = parent_mem_cgroup(memcg);

-- 
2.43.0

