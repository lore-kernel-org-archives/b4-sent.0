From: Kairui Song <kasong@tencent.com>
Date: Sun, 17 May 2026 23:39:46 +0800
Subject: [PATCH v5 07/12] mm, swap: support flexible batch freeing of slots
 in different memcgs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260517-swap-table-p4-v5-7-88ae43e064c7@tencent.com>
References: <20260517-swap-table-p4-v5-0-88ae43e064c7@tencent.com>
In-Reply-To: <20260517-swap-table-p4-v5-0-88ae43e064c7@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Zi Yan <ziy@nvidia.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Barry Song <baohua@kernel.org>, 
 Hugh Dickins <hughd@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Youngjun Park <youngjun.park@lge.com>, 
 Chengming Zhou <chengming.zhou@linux.dev>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, linux-kernel@vger.kernel.org, 
 cgroups@vger.kernel.org, Kairui Song <kasong@tencent.com>, 
 Lorenzo Stoakes <ljs@kernel.org>, Yosry Ahmed <yosry@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779032386; l=2512;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=ZD2081+ctfRfaBeb4mp+5wkRHhM7k1bXJ2YEQVy37aA=;
 b=/gV2rB59+sfFgcX/Dv/Tg5we0Z1EcHk9+EDjavgbQFtp9YpTqfm8oJ7yHIq0BedOQfVQ6HnSG
 GNhYM36cxJHBEEoKcNtjUh75tuEkjOcoLjMNFHzWMJEEtS6uiMtjPPG
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of requiring the caller to ensure all slots are in the same
memcg, make the function handle different memcgs at once.

This is both a micro optimization and required for removing the memcg
lookup in the page table layer, so it can be unified at the swap layer.

We are not removing the memcg lookup in the page table in this commit.
It has to be done after the memcg lookup is deferred to the swap layer.

Acked-by: Chris Li <chrisl@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swapfile.c | 33 +++++++++++++++++++++++++++++----
 1 file changed, 29 insertions(+), 4 deletions(-)

diff --git a/mm/swapfile.c b/mm/swapfile.c
index 5c8bb15719bf..c9c80ba9252b 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -1873,21 +1873,46 @@ void __swap_cluster_free_entries(struct swap_info_struct *si,
 				 unsigned int ci_start, unsigned int nr_pages)
 {
 	unsigned long old_tb;
+	unsigned int type = si->type;
+	unsigned short batch_id = 0, id_cur;
 	unsigned int ci_off = ci_start, ci_end = ci_start + nr_pages;
-	unsigned long offset = cluster_offset(si, ci) + ci_start;
+	unsigned long ci_head = cluster_offset(si, ci);
+	unsigned int batch_off = ci_off;
+	swp_entry_t entry;
 
 	VM_WARN_ON(ci->count < nr_pages);
 
 	ci->count -= nr_pages;
 	do {
 		old_tb = __swap_table_get(ci, ci_off);
-		/* Release the last ref, or after swap cache is dropped */
+		/*
+		 * Freeing is done after release of the last swap count
+		 * ref, or after swap cache is dropped
+		 */
 		VM_WARN_ON(!swp_tb_is_shadow(old_tb) || __swp_tb_get_count(old_tb) > 1);
 		__swap_table_set(ci, ci_off, null_to_swp_tb());
+
+		/*
+		 * Uncharge swap slots by memcg in batches. Consecutive
+		 * slots with the same cgroup id are uncharged together.
+		 */
+		entry = swp_entry(type, ci_head + ci_off);
+		id_cur = lookup_swap_cgroup_id(entry);
+		if (batch_id != id_cur) {
+			if (batch_id)
+				mem_cgroup_uncharge_swap(swp_entry(type, ci_head + batch_off),
+							 ci_off - batch_off);
+			batch_id = id_cur;
+			batch_off = ci_off;
+		}
 	} while (++ci_off < ci_end);
 
-	mem_cgroup_uncharge_swap(swp_entry(si->type, offset), nr_pages);
-	swap_range_free(si, offset, nr_pages);
+	if (batch_id) {
+		mem_cgroup_uncharge_swap(swp_entry(type, ci_head + batch_off),
+					 ci_off - batch_off);
+	}
+
+	swap_range_free(si, ci_head + ci_start, nr_pages);
 	swap_cluster_assert_empty(ci, ci_start, nr_pages, false);
 
 	if (!ci->count)

-- 
2.54.0

