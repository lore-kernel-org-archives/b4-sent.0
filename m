From: Kairui Song <kasong@tencent.com>
Date: Sat, 14 Nov 2026 05:26:19 +0800
Subject: [PATCH RFC 3/8] mm/huge_memory: avoid an unnecessary folio size
 reading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-swap-thp-split-v1-3-dfa8d4fa448d@tencent.com>
References: <20261114-swap-thp-split-v1-0-dfa8d4fa448d@tencent.com>
In-Reply-To: <20261114-swap-thp-split-v1-0-dfa8d4fa448d@tencent.com>
To: linux-mm@kvack.org
Cc: David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Matthew Wilcox <willy@infradead.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Zi Yan <ziy@nvidia.com>, 
 Nico Pache <nico.pache@linux.dev>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794605194; l=764;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=LmZMW4ryeSabpn9A1T3iIoGeWriFohkqBblDlYZuq1I=;
 b=4fw0LMeSbz2l92yW9mvBPwE3Bk04f4enplJroZxhcwS0OJz+aB1OBrVwS0CwbCV0PFM4kLkng
 8P7TF3DT9z1AcN67GtLPSjSXQGar6Bv6odbdrAeZEpSgq81WlJQyTNb
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We already have that in the local variable, a trivial cleanup.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 0d589be136d2..b60fd73fe35c 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4287,9 +4287,7 @@ static int __folio_freeze_split_file(struct folio *folio,
 		/* compute next before the folio can be freed below */
 		next = folio_next(new_folio);
 
-		folio_ref_unfreeze(new_folio,
-				   folio_nr_pages(new_folio) + 1);
-
+		folio_ref_unfreeze(new_folio, nr_pages + 1);
 		lru_add_split_folio(folio, new_folio, lruvec, list);
 
 		/* Add the new folio to the page cache. */

-- 
2.56.1

