From: Kairui Song <kasong@tencent.com>
Date: Fri, 16 Oct 2026 02:15:59 +0800
Subject: [PATCH v4 10/17] mm/khugepaged: convert to LRU refs based
 operations for MGLRU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-mglru-fg-v4-10-2106750c0bfa@tencent.com>
References: <20261016-mglru-fg-v4-0-2106750c0bfa@tencent.com>
In-Reply-To: <20261016-mglru-fg-v4-0-2106750c0bfa@tencent.com>
To: linux-mm@kvack.org, "Liam R. Howlett" <liam@infradead.org>, 
 SJ Park <sj@kernel.org>
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <qi.zheng@linux.dev>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Chris Li <chrisl@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, Zi Yan <ziy@nvidia.com>, 
 Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 David Rientjes <rientjes@google.com>, Yu Zhao <yuzhao@google.com>, 
 Vernon Yang <vernon2gm@gmail.com>, Zicheng Wang <wangzicheng@honor.com>, 
 Chen Ridong <chenridong@xiaomi.com>, Tal Zussman <tz2294@columbia.edu>, 
 Kairui Song <ryncsn@gmail.com>, Xiang Liu <liuxiang.277@bytedance.com>, 
 Ehab Ababneh <ehab.ababneh@intel.com>, 
 zhaozhengzhuo <zhaozhengzhuo@uniontech.com>, 
 Lian Wang <lianux.mm@gmail.com>, Kunwu Chan <kunwu.chan@gmail.com>, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 damon@lists.linux.dev, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792088152; l=1305;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=+Tb0hPQRVBeGNFQursundpLJPnEU7iUig7NZAg5dyxU=;
 b=CyGgF3KwdKpDK/OPe5JsFLV9+9m3zkFUvTK3nxJVeinp1EKn/EhM9YluR8cGMSowDmMM9MQFe
 v00Gu8A/iiFBT95X30QnZS7uBlb25LDBy7tmWh/fvzwrgOY4vWuOcKC
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For MGLRU, PG_referenced is only the lowest bit of the folio LRU refs
count, so folios with a higher refs count no longer have the bit set.
folio_pte_referenced() testing the raw bit misses hot folios at
refs >= 2, under-counting the referenced folios of a candidate range
and aborting otherwise good collapses with SCAN_LACK_REFERENCED_PAGE.

Test the refs count directly when MGLRU is enabled, mirroring the
smaps conversion.  The classical LRU keeps the plain bit test.

Tested-by: zhaozhengzhuo <zhaozhengzhuo@uniontech.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/khugepaged.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/mm/khugepaged.c b/mm/khugepaged.c
index ef5cd6fda34f..5332b4c51fec 100644
--- a/mm/khugepaged.c
+++ b/mm/khugepaged.c
@@ -579,7 +579,9 @@ static bool folio_pte_referenced(struct folio *folio,
 		struct vm_area_struct *vma, unsigned long addr, pte_t pteval)
 {
 	/* The folio was referenced previously ... */
-	if (folio_test_young(folio) || folio_test_referenced(folio))
+	if (folio_test_young(folio))
+		return true;
+	if (folio_check_lru_refs(folio))
 		return true;
 	/* ... or the PTE mapping was recently used */
 	return pte_young(pteval) || mmu_notifier_test_young(vma->vm_mm, addr);

-- 
2.56.0

