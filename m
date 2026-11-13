From: Kairui Song <kasong@tencent.com>
Date: Sat, 14 Nov 2026 05:26:24 +0800
Subject: [PATCH RFC 8/8] mm/huge_memory: walk the folios reversely for the
 release loop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-swap-thp-split-v1-8-dfa8d4fa448d@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794605194; l=1841;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=dZXSI3LM1sOQiwV6KeB6SU17Z87R/eSYehou1jdR5o4=;
 b=IzWZ890bKlfCzLTPrilcnJxROgDWfSBsVhqWNDPvxfGm52kTpVgfbT0g1oAWYBw9TmLkGlYET
 sEISPvezQAnDtnWjHKzRTfNJFLFL1pk8WFV+NU3RVhV8SiCnyBW6syP
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The release loop unlocks and puts every after-split folio except the one
holding @lock_at.  Walk it backwards with folio_prev() instead of
forwards with folio_next().

This also helps avoid a for loop pitfall mentioned by Zi Yan [1]:
folio_next() needs the folio it is given to stay alive until the
increment, folio_prev() does not.  So the cached next pointer can go, and
the folio that was just put is never read again.

Same folios visited, same work on each, only the direction changes.

Link: https://lore.kernel.org/r/DKJSFCLP967N.YBR4DNK1NM2N@nvidia.com [1]
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 2ff201a5e5f3..bb09465a3948 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4366,7 +4366,7 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 	const bool is_anon = folio_test_anon(folio);
 	const bool is_swapcache = folio_test_swapcache(folio);
 	int old_order = folio_order(folio);
-	struct folio *new_folio, *next;
+	struct folio *new_folio, *lock_folio;
 	int ret;
 
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_locked(folio), folio);
@@ -4399,9 +4399,10 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 	 * Unlock all after-split folios except the one containing
 	 * @lock_at page. If @folio is not split, it will be kept locked.
 	 */
-	for (new_folio = folio; new_folio != end_folio; new_folio = next) {
-		next = folio_next(new_folio);
-		if (new_folio == page_folio(lock_at))
+	lock_folio = page_folio(lock_at);
+	for (new_folio = folio_prev(end_folio); new_folio != folio;
+	     new_folio = folio_prev(new_folio)) {
+		if (new_folio == lock_folio)
 			continue;
 
 		/*

-- 
2.56.1

