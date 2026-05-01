From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:07 +0800
Subject: [PATCH RFC 21/32] mm/swap: convert to new bitwise identical helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-21-913619b014d9@tencent.com>
References: <20260502-mglru-fg-v1-0-913619b014d9@tencent.com>
In-Reply-To: <20260502-mglru-fg-v1-0-913619b014d9@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Youngjun Park <youngjun.park@lge.com>, 
 Zi Yan <ziy@nvidia.com>, Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Nico Pache <npache@redhat.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SeongJae Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, 
 Chen Ridong <chenridong@huaweicloud.com>, Tal Zussman <tz2294@columbia.edu>, 
 Kairui Song <ryncsn@gmail.com>, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=1323;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=eeiiyy+su7zYF2XxxCJkB0ii+3kNLayc6qTsNhWAGbI=;
 b=FyZO3KOY9qKBaiu/DIWFcROSEhhGKBxTqumQl6RrGU/2X5SJ5Pyl15i0sP1V8AB44wIWdPUMO
 AKnyGEbam5xBgtdf2RYhHf1fGBdJpGpa9Ss1FHDNVjXiSSeafhu8cev
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No feature change, just prepare for removal of PG_referenced.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swap.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/mm/swap.c b/mm/swap.c
index 2250d9db1395..043c4ec708d7 100644
--- a/mm/swap.c
+++ b/mm/swap.c
@@ -629,7 +629,7 @@ static void lru_deactivate_file(struct lruvec *lruvec, struct folio *folio)
 
 	lruvec_del_folio(lruvec, folio);
 	folio_clear_active(folio);
-	folio_clear_referenced(folio);
+	folio_clear_referenced_by_bit(folio);
 
 	if (folio_test_writeback(folio) || folio_test_dirty(folio)) {
 		/*
@@ -665,7 +665,7 @@ static void lru_deactivate(struct lruvec *lruvec, struct folio *folio)
 
 	lruvec_del_folio(lruvec, folio);
 	folio_clear_active(folio);
-	folio_clear_referenced(folio);
+	folio_clear_referenced_by_bit(folio);
 	lruvec_add_folio(lruvec, folio);
 
 	__count_vm_events(PGDEACTIVATE, nr_pages);
@@ -685,7 +685,7 @@ static void lru_lazyfree(struct lruvec *lruvec, struct folio *folio)
 	if (lru_gen_enabled())
 		lru_gen_clear_refs(folio);
 	else
-		folio_clear_referenced(folio);
+		folio_clear_referenced_by_bit(folio);
 	/*
 	 * Lazyfree folios are clean anonymous folios.  They have
 	 * the swapbacked flag cleared, to distinguish them from normal

-- 
2.54.0

