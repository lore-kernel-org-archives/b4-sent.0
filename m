From: Kairui Song <kasong@tencent.com>
Date: Wed, 18 Feb 2026 04:06:35 +0800
Subject: [PATCH v3 10/12] mm, swap: no need to truncate the scan border
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260218-swap-table-p3-v3-10-f4e34be021a7@tencent.com>
References: <20260218-swap-table-p3-v3-0-f4e34be021a7@tencent.com>
In-Reply-To: <20260218-swap-table-p3-v3-0-f4e34be021a7@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 Youngjun Park <youngjun.park@lge.com>, linux-kernel@vger.kernel.org, 
 Chris Li <chrisl@kernel.org>, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771358806; l=1640;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=2+MOtDCYClcDw9TcgcSvHJeMem5KxDman/aSTNPnNu0=;
 b=JiApyFqhVexB0R2dK8YJdP7PMRcUBDYnG3jDQt7pwNUkIz80Oj0pUtxXTadmSQ1fbZjU9Abnv
 mDDgUzSRT8SCBo98cAzB0tTSBiD8cJzIXZ2lZ/iV5LkjyBVp6V5TlwY
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

swap_map had a static flexible size, so the last cluster won't be fully
covered, hence the allocator needs to check the scan border to avoid
OOB. But the swap table has a fixed-sized swap table for each cluster,
and the slots beyond the device size are marked as bad slots. The
allocator can simply scan all slots as usual, and any bad slots will be
skipped.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swap.h     | 2 +-
 mm/swapfile.c | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/mm/swap.h b/mm/swap.h
index 0a91e21e92b1..cc410b94e91a 100644
--- a/mm/swap.h
+++ b/mm/swap.h
@@ -85,7 +85,7 @@ static inline struct swap_cluster_info *__swap_offset_to_cluster(
 		struct swap_info_struct *si, pgoff_t offset)
 {
 	VM_WARN_ON_ONCE(percpu_ref_is_zero(&si->users)); /* race with swapoff */
-	VM_WARN_ON_ONCE(offset >= si->max);
+	VM_WARN_ON_ONCE(offset >= roundup(si->max, SWAPFILE_CLUSTER));
 	return &si->cluster_info[offset / SWAPFILE_CLUSTER];
 }
 
diff --git a/mm/swapfile.c b/mm/swapfile.c
index 801d8092be51..df2b88c6c67b 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -945,8 +945,8 @@ static unsigned int alloc_swap_scan_cluster(struct swap_info_struct *si,
 {
 	unsigned int next = SWAP_ENTRY_INVALID, found = SWAP_ENTRY_INVALID;
 	unsigned long start = ALIGN_DOWN(offset, SWAPFILE_CLUSTER);
-	unsigned long end = min(start + SWAPFILE_CLUSTER, si->max);
 	unsigned int order = likely(folio) ? folio_order(folio) : 0;
+	unsigned long end = start + SWAPFILE_CLUSTER;
 	unsigned int nr_pages = 1 << order;
 	bool need_reclaim, ret, usable;
 

-- 
2.52.0

