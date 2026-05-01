From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:03:59 +0800
Subject: [PATCH RFC 13/32] mm/khugepaged: consider workingset folios as
 referenced
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-13-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=1950;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=UByiLYjFt2+kqAxm04OpzowbaWLuDjdJ8bJGsAYOXBE=;
 b=rN+ZBnZrzZD6vSDJMUHL0q+E5ZYHa/RaFdPJvCTAyQgAUBzFuz+g/IdZd5U6SrCWwaRFYnHSv
 Iys2yTORjLYCkFTarebaM66SXYa0dlv8YaJMk+cjtcUCldB69BmOlrO
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The folio_test_referenced check here is clearly trying to test if the
folio was ever referenced. It was first introduced by commit
8ee53820edfd ("thp: mmu_notifier_test_young") as an supplement of the
young bit check.

Folios are marked as PG_referenced on first access, but following access
will clear their PG_referenced on second access. So checking only the referenced
flag is not accurate enough.

Switch to use the new helper, so we can cover the secondary and following
access from MGLRU side. For non-MGLRU, this will make it return positve
for workingset folios too, which should be OK.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/khugepaged.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/mm/khugepaged.c b/mm/khugepaged.c
index 7d48d4fbd5f3..af9217e19eac 100644
--- a/mm/khugepaged.c
+++ b/mm/khugepaged.c
@@ -815,7 +815,7 @@ static enum scan_result __collapse_huge_page_isolate(struct vm_area_struct *vma,
 		 */
 		if (cc->is_khugepaged &&
 		    (pte_young(pteval) || folio_test_young(folio) ||
-		     folio_test_referenced(folio) ||
+		     folio_is_referenced(folio) ||
 		     mmu_notifier_test_young(vma->vm_mm, addr)))
 			referenced++;
 	}
@@ -1743,7 +1743,7 @@ static enum scan_result collapse_scan_pmd(struct mm_struct *mm,
 		 */
 		if (cc->is_khugepaged &&
 		    (pte_young(pteval) || folio_test_young(folio) ||
-		     folio_test_referenced(folio) ||
+		     folio_is_referenced(folio) ||
 		     mmu_notifier_test_young(vma->vm_mm, addr)))
 			referenced++;
 	}
@@ -2729,7 +2729,7 @@ static enum scan_result collapse_scan_file(struct mm_struct *mm,
 		/*
 		 * We probably should check if the folio is referenced
 		 * here, but nobody would transfer pte_young() to
-		 * folio_test_referenced() for us.  And rmap walk here
+		 * folio_is_referenced() for us.  And rmap walk here
 		 * is just too costly...
 		 */
 

-- 
2.54.0

