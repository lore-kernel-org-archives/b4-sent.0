From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:01 +0800
Subject: [PATCH RFC 15/32] mm/gup: use new helpers for marking folios as
 referenced
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-15-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=1672;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=zzj2htF5O3Boz+i6Si7xd6bJD7nkf/a9RkvvaueQ9so=;
 b=sZi3qcG1zBUsLAgNczKqAvDXvOrUzPJS593cEkUbvLcZSL+TA/nS/UnQHUw8/BbKhSltO+z1A
 MbjywAvxq4tDfpfGluN3y7BIjR9yZGpQIA1+BNH1U2QKP35eubRjqAL
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Marking the folio as referenced in gup fast was first introduced by commit
8ee53820edfd ("thp: mmu_notifier_test_young"). Then later refractored
but still basically the samething in commit e93480537fd7 ("mm/gup: Mark all
pages PageReferenced in generic get_user_pages_fast()"). Some implementation
may changed over days by the goal is the same: provide hotness info for better
memory management.

We have made all users that cares about a folio's hotness info to the
new helper, so convert this updater too.

NOTE: it would be better to convert to folio_mark_referenced later.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/gup.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/mm/gup.c b/mm/gup.c
index 21ea90baefb1..78ffa364ff18 100644
--- a/mm/gup.c
+++ b/mm/gup.c
@@ -2898,7 +2898,7 @@ static int gup_fast_pte_range(pmd_t pmd, pmd_t *pmdp, unsigned long addr,
 			gup_put_folio(folio, 1, flags);
 			goto pte_unmap;
 		}
-		folio_set_referenced(folio);
+		folio_mark_referenced_by_bit(folio);
 		pages[*nr] = page;
 		(*nr)++;
 	} while (ptep++, addr += PAGE_SIZE, addr != end);
@@ -2967,7 +2967,7 @@ static int gup_fast_pmd_leaf(pmd_t orig, pmd_t *pmdp, unsigned long addr,
 	*nr += refs;
 	for (; refs; refs--)
 		*(pages++) = page++;
-	folio_set_referenced(folio);
+	folio_mark_referenced_by_bit(folio);
 	return 1;
 }
 
@@ -3011,7 +3011,7 @@ static int gup_fast_pud_leaf(pud_t orig, pud_t *pudp, unsigned long addr,
 	*nr += refs;
 	for (; refs; refs--)
 		*(pages++) = page++;
-	folio_set_referenced(folio);
+	folio_mark_referenced_by_bit(folio);
 	return 1;
 }
 

-- 
2.54.0

