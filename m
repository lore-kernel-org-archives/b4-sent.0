From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:02 +0800
Subject: [PATCH RFC 16/32] mm: convert folio referenced flag usages to new
 bitwise identical helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-16-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=999;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=+5qun8U2KQYDmQH0ZIm/6ejG1bASGFZfAJQuD/re23Y=;
 b=lSMsnUvxGGUaYG0E/v+f1nxrr3TYC9U+s6XCF5kTjEYfQM7zbRpIjFFhSJ4RiZ/Cp9u0YGRqE
 oaQcIqhCOdFBSP97uzGceWG0hU5snTAOcZ2U8TXEw2Y4nZ5E9KEBA6c
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To prepare for removal of this page flag, use the new introduced
standalone helper.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swap.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/mm/swap.c b/mm/swap.c
index 6e0397ff881d..2250d9db1395 100644
--- a/mm/swap.c
+++ b/mm/swap.c
@@ -525,8 +525,8 @@ void folio_mark_accessed(struct folio *folio)
 		return;
 	}
 
-	if (!folio_test_referenced(folio)) {
-		folio_set_referenced(folio);
+	if (!folio_is_referenced_by_bit(folio)) {
+		folio_mark_referenced_by_bit(folio);
 	} else if (folio_test_unevictable(folio)) {
 		/*
 		 * Unevictable pages are on the "LRU_UNEVICTABLE" list. But,
@@ -544,7 +544,7 @@ void folio_mark_accessed(struct folio *folio)
 			folio_activate(folio);
 		else
 			__lru_cache_activate_folio(folio);
-		folio_clear_referenced(folio);
+		folio_clear_referenced_by_bit(folio);
 		workingset_activation(folio);
 	}
 	if (folio_test_idle(folio))

-- 
2.54.0

