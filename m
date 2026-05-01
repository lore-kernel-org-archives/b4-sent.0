From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:03:55 +0800
Subject: [PATCH RFC 09/32] mm: replace folio_set_workingset with
 folio_mark_workingset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-9-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=1960;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=R9UYu0s/pryes2odZArBSEeX7+UjdOfURrA6S5mawmM=;
 b=oHo47lWbXKavCucKWmMfLLUs3lCZ0hcCiiwYPQV6fBHKDp5kb11/cGdfRYKUhtz89xvWpZvna
 Pa8zYdBQ5fTCdPmmbqpdrq8R5vX0i4CocHaRDxIN0oGIoBXjqpah5tm
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No feature change, new help is bit-wise identical, just to prepare for
removal of PG_workingset.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/madvise.c    | 4 ++--
 mm/vmscan.c     | 2 +-
 mm/workingset.c | 2 +-
 3 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/mm/madvise.c b/mm/madvise.c
index 69708e953cf5..930939c55cd5 100644
--- a/mm/madvise.c
+++ b/mm/madvise.c
@@ -428,7 +428,7 @@ static int madvise_cold_or_pageout_pte_range(pmd_t *pmd,
 		folio_clear_referenced(folio);
 		folio_test_clear_young(folio);
 		if (folio_test_active(folio))
-			folio_set_workingset(folio);
+			folio_mark_workingset_by_bit(folio);
 		if (pageout) {
 			if (folio_isolate_lru(folio)) {
 				if (folio_test_unevictable(folio))
@@ -543,7 +543,7 @@ static int madvise_cold_or_pageout_pte_range(pmd_t *pmd,
 		folio_clear_referenced(folio);
 		folio_test_clear_young(folio);
 		if (folio_test_active(folio))
-			folio_set_workingset(folio);
+			folio_mark_workingset_by_bit(folio);
 		if (pageout) {
 			if (folio_isolate_lru(folio)) {
 				if (folio_test_unevictable(folio))
diff --git a/mm/vmscan.c b/mm/vmscan.c
index c6857a933ebf..2fd62d02a83a 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -2141,7 +2141,7 @@ static void shrink_active_list(unsigned long nr_to_scan,
 		}
 
 		folio_clear_active(folio);	/* we are de-activating */
-		folio_set_workingset(folio);
+		folio_mark_workingset_by_bit(folio);
 		list_add(&folio->lru, &l_inactive);
 	}
 
diff --git a/mm/workingset.c b/mm/workingset.c
index bdb8df6009af..bdee91f54e61 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -586,7 +586,7 @@ void workingset_refault(struct folio *folio, void *shadow)
 
 	/* Folio was active prior to eviction */
 	if (workingset) {
-		folio_set_workingset(folio);
+		folio_mark_workingset_by_bit(folio);
 		/*
 		 * XXX: Move to folio_add_lru() when it supports new vs
 		 * putback

-- 
2.54.0

