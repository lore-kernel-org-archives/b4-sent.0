From: Kairui Song <kasong@tencent.com>
Date: Sat, 14 Nov 2026 05:26:22 +0800
Subject: [PATCH RFC 6/8] mm/huge_memory: rearrange split routine handling
 for better optimization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-swap-thp-split-v1-6-dfa8d4fa448d@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794605194; l=2082;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=Ywh5u6CH0UvNagiKhU1WNU9qFNY87IWayR40Afi6yCI=;
 b=5BjTzAVdQpgSdWyC+wp+tXTzTaCfmBLbicy3sBWh0+gsjfSSveiCBn0OAOViPC/pMoDHBKNFM
 dILf8SHbE2BB1NmVgVtErkw8dzv+fl3VR5SvpYPPSoY5MiKaULg5b9m
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Anonymous folios never use a mapping or an xarray, so combine the is_anon
and xas conditions into a single if/else-if chain.  The compiler cannot do
this on its own because the xarray split calls sit between the two
conditions and the anon mTHP stat update comes after the split helpers.

./scripts/bloat-o-meter on mm/huge_memory.o (x86-64 KVM test config) shows
__split_frozen_folio() shrinking from 1077 to 996 bytes.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 7270baa20d80..e16b93318613 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3929,13 +3929,17 @@ static int __split_frozen_folio(struct folio *folio, int new_order,
 	for (split_order = start_order;
 	     split_order >= new_order;
 	     split_order--) {
-		int nr_new_folios = 1UL << (old_order - split_order);
+		if (is_anon) {
+			int nr_new_folios = 1UL << (old_order - split_order);
 
-		/* order-1 anonymous folio is not supported */
-		if (is_anon && split_order == 1)
-			continue;
+			/* order-1 anonymous folio is not supported */
+			if (split_order == 1)
+				continue;
 
-		if (xas) {
+			/* Split can't fail at this point, update counters now */
+			mod_mthp_stat(old_order, MTHP_STAT_NR_ANON, -1);
+			mod_mthp_stat(split_order, MTHP_STAT_NR_ANON, nr_new_folios);
+		} else if (xas) {
 			/*
 			 * uniform split has xas_split_alloc() called before
 			 * irq is disabled to allocate enough memory, whereas
@@ -3960,10 +3964,6 @@ static int __split_frozen_folio(struct folio *folio, int new_order,
 		pgalloc_tag_split(folio, old_order, split_order);
 		__split_folio_to_order(folio, old_order, split_order);
 
-		if (is_anon) {
-			mod_mthp_stat(old_order, MTHP_STAT_NR_ANON, -1);
-			mod_mthp_stat(split_order, MTHP_STAT_NR_ANON, nr_new_folios);
-		}
 		/*
 		 * If uniform split, the process is complete.
 		 * If non-uniform, continue splitting the folio at @split_at

-- 
2.56.1

