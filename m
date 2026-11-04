From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 04 Nov 2026 18:59:09 +0900
Subject: [PATCH 2/2] mm/page_owner: also check PageTail before reading
 memcg_data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-kpagecgroup-split-v1-2-f70e947fec85@samsung.com>
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
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793786347; l=1494;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=Tqm3nbQI1nWClGneJZ4Vn7FgKvDR6MGrjq0L2fxkJJg=;
 b=jF1VyraheDQeftMsTSeeShKLufOP/x6ZE8gVhGZ9J5wjIN48n1F2UD5mWKXUqYitdOutXoi71
 O73YaVFvaRmDVw6oCDkIzhWabi9SfSmF0DAaIx8yLkW/5QSQ3GX9K2Z
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

print_page_owner_memcg() loads memcg_data before it tests PageTail().
In the first tail page, memcg_data holds the folio's _nr_pages. A split
can make the page a folio between the two loads. The stale _nr_pages
then passes the PageTail() test and is used as an objcg pointer.

__split_folio_to_order() stores memcg_data before the smp_wmb() that
precedes clear_compound_head(). Also test PageTail() before the load,
with a paired smp_rmb(). Keep the test after the load for a page that
becomes a tail in between.

Fixes: 4996fc547f5b ("mm: let _folio_nr_pages overlay memcg_data in first tail page")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Needs patch 1 for the store order. Found by reading the code, not
reproduced. The page_owner oops seen with a delay after
clear_compound_head() is the window patch 1 closes.
---
 mm/page_owner.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/mm/page_owner.c b/mm/page_owner.c
index cfc31c92d7..058d4dec84 100644
--- a/mm/page_owner.c
+++ b/mm/page_owner.c
@@ -564,6 +564,13 @@ static inline int print_page_owner_memcg(char *kbuf, size_t count, int ret,
 	char name[80];
 
 	rcu_read_lock();
+	if (PageTail(page))
+		goto out_unlock;
+	/*
+	 * Order the memcg_data load after the PageTail() load. Pairs with
+	 * smp_wmb() in __split_folio_to_order().
+	 */
+	smp_rmb();
 	memcg_data = READ_ONCE(page->memcg_data);
 	if (!memcg_data || PageTail(page))
 		goto out_unlock;

-- 
2.43.0

