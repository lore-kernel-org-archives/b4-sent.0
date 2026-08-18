From: Kairui Song <kasong@tencent.com>
Date: Tue, 18 Aug 2026 13:38:09 +0800
Subject: [PATCH 7/7] mm/mglru: improve code readability and harden
 folio_inc_gen
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-mglru-flags-cleanup-v1-7-8dbbdac0d28c@tencent.com>
References: <20260818-mglru-flags-cleanup-v1-0-8dbbdac0d28c@tencent.com>
In-Reply-To: <20260818-mglru-flags-cleanup-v1-0-8dbbdac0d28c@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Baoquan He <baoquan.he@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Muchun Song <muchun.song@linux.dev>, Chris Li <chrisl@kernel.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Yu Zhao <yuzhao@google.com>, Zi Yan <ziy@nvidia.com>, 
 Qi Zheng <qi.zheng@linux.dev>, cgroups@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kairui Song <ryncsn@gmail.com>, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787031501; l=1891;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=VAAQ2yiZ5J1ZoI2nmEdgdm+eoSsfABEBNy6fHJoC/Ao=;
 b=vfv8/0vJNXjl4xfANa0zvplr3gsB8l5c6I3ZE3bYCfgQRy1JPhuV/RfkOve+UzP3ZSo3ThysQ
 4bzJd3exJcxDOzcNw7VQ6D4JMMsKi6+5BvFKSfMgZ+wrxOLJtBX/l/a
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The helper should never be called for an off-list folio, and it always
expects the folio to be in the oldest generation before doing any
cmpxchg. Add a sanity check for the off-list case: if it is ever
violated, bail out and keep the folio flags untouched to minimize the
damage, instead of silently treating the folio as if it were in the
oldest generation and promoting it updating the flags to an unexpected
status.

Also rename the variables to clearly distinguish the folio's current
gen from the oldest gen.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 14 +++++++++-----
 1 file changed, 9 insertions(+), 5 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 7169cac60869..7e3ae0c6cba3 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -3308,18 +3308,22 @@ static int folio_inc_gen(struct lruvec *lruvec, struct folio *folio)
 {
 	int type = folio_is_file_lru(folio);
 	struct lru_gen_folio *lrugen = &lruvec->lrugen;
-	int new_gen, old_gen = lru_gen_from_seq(lrugen->min_seq[type]);
+	int new_gen, old_gen, min_gen = lru_gen_from_seq(lrugen->min_seq[type]);
 	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
 
 	do {
-		new_gen = lru_gen_from_flags(old_flags);
+		old_gen = lru_gen_from_flags(old_flags);
+		/* This helper should never be called for off-list folios */
+		VM_WARN_ON_ONCE(old_gen < 0);
+		if (old_gen < 0)
+			return min_gen;
 
 		/* folio_update_gen() has promoted this page? */
-		if (new_gen >= 0 && new_gen != old_gen)
-			return new_gen;
+		if (old_gen != min_gen)
+			return old_gen;
 
 		new_flags = old_flags;
-		new_gen = (old_gen + 1) % MAX_NR_GENS;
+		new_gen = (min_gen + 1) % MAX_NR_GENS;
 		lru_gen_set_flags(&new_flags, new_gen);
 		lru_refs_set_flags(&new_flags, 0);
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));

-- 
2.55.0

