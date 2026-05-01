From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:00 +0800
Subject: [PATCH RFC 14/32] mm: convert rest folio LRU referenced usages to
 new helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-14-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=1270;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=s9IM5saCZOi1yMrQ9wd37CGnZKAxDY3IwusY5KAp2fM=;
 b=AjjRfwfd76/c82mEMrSgQlxsNUhdUausxOPl6q2Enso4MgBpO0AY3ccxZG3B8/BDqvylfIBb0
 ERx+uZevY/aDpfqVoUhUizG7Af7iJlG4HWFUFRPpixkNa46KQ/KyKiL
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No feature change, everything is bitwisely same with before, just
preparing to drop the page flag.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/filemap.c | 2 +-
 mm/swap.c    | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/mm/filemap.c b/mm/filemap.c
index 50897ca1d74e..91a1d1c03475 100644
--- a/mm/filemap.c
+++ b/mm/filemap.c
@@ -2015,7 +2015,7 @@ struct folio *__filemap_get_folio_mpol(struct address_space *mapping,
 
 			/* Init accessed so avoid atomic mark_page_accessed later */
 			if (fgp_flags & FGP_ACCESSED)
-				__folio_set_referenced(folio);
+				__folio_init_referenced(folio);
 			if (fgp_flags & FGP_DONTCACHE)
 				__folio_set_dropbehind(folio);
 
diff --git a/mm/swap.c b/mm/swap.c
index 5fc8a9ffbedb..6e0397ff881d 100644
--- a/mm/swap.c
+++ b/mm/swap.c
@@ -514,7 +514,7 @@ static bool lru_gen_clear_refs(struct folio *folio)
  * * active,unreferenced	->	active,referenced
  *
  * When a newly allocated folio is not yet visible, so safe for non-atomic ops,
- * __folio_set_referenced() may be substituted for folio_mark_accessed().
+ * __folio_init_referenced() may be substituted for folio_mark_accessed().
  */
 void folio_mark_accessed(struct folio *folio)
 {

-- 
2.54.0

