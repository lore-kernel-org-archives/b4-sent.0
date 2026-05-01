From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:04 +0800
Subject: [PATCH RFC 18/32] mm/vmscan: convert to new bitwise identical
 helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-18-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=1005;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=g0CjYTRIe9ngM5FeeFowlBKRaYV4naFyb1v+5e6oewY=;
 b=1O08Fjuv7dDsUSN65/Nh/EKQX5Zn+CfMlt8A8CHIlb4oXMYvuDZNoL/N8ajhstsKC7eU8DLsw
 Xvzd7PgG+K0BufVemZT87auAAygwRgKn3y6d7OMjSqe/ca16Fjp1BzM
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No feature change, just prepare for removal of PG_referenced.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 2fd62d02a83a..a3200020b9c2 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -901,7 +901,7 @@ static enum folio_references folio_check_references(struct folio *folio,
 		return folio_promote_lru_refs(folio) ? FOLIOREF_ACTIVATE : FOLIOREF_KEEP;
 	}
 
-	referenced_folio = folio_test_clear_referenced(folio);
+	referenced_folio = folio_test_clear_referenced_bit(folio);
 
 	if (referenced_ptes) {
 		/*
@@ -918,7 +918,7 @@ static enum folio_references folio_check_references(struct folio *folio,
 		 * so that recently deactivated but used folios are
 		 * quickly recovered.
 		 */
-		folio_set_referenced(folio);
+		folio_mark_referenced_by_bit(folio);
 
 		if (referenced_folio || referenced_ptes > 1)
 			return FOLIOREF_ACTIVATE;

-- 
2.54.0

