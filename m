From: Kairui Song <kasong@tencent.com>
Date: Fri, 20 Feb 2026 07:42:10 +0800
Subject: [PATCH RFC 09/15] mm, swap: support flexible batch freeing of
 slots in different memcg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-swap-table-p4-v1-9-104795d19815@tencent.com>
References: <20260220-swap-table-p4-v1-0-104795d19815@tencent.com>
In-Reply-To: <20260220-swap-table-p4-v1-0-104795d19815@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, Zi Yan <ziy@nvidia.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Barry Song <baohua@kernel.org>, 
 Hugh Dickins <hughd@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Yosry Ahmed <yosry.ahmed@linux.dev>, Youngjun Park <youngjun.park@lge.com>, 
 Chengming Zhou <chengming.zhou@linux.dev>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <zhengqi.arch@bytedance.com>, linux-kernel@vger.kernel.org, 
 cgroups@vger.kernel.org, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771544524; l=2190;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=Nr97MkylL+DHtVgOfh389lZsI/jvwd7cCWUvrCs+ZdE=;
 b=VNT+6pjfkVvYVkF9R+AU+XtVKlcJWeED6XPNHYULO17gQljRJAaYmkZ02T9dibmkLNBBvXLp7
 wp61I+XYYaoBXuYFFCdCriXsl76W8j1LTC2XS24nk5qzY39pQZFZfDh
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of let the caller ensures all slots are in the same memcg, the
make it be able to handle different memcg at once.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swapfile.c | 31 +++++++++++++++++++++++++------
 1 file changed, 25 insertions(+), 6 deletions(-)

diff --git a/mm/swapfile.c b/mm/swapfile.c
index 2cd3e260f1bf..cd2d3b2ca6f0 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -1883,10 +1883,13 @@ void __swap_cluster_free_entries(struct swap_info_struct *si,
 				 struct swap_cluster_info *ci,
 				 unsigned int ci_start, unsigned int nr_pages)
 {
+	void *shadow;
 	unsigned long old_tb;
-	unsigned short id;
+	unsigned int type = si->type;
+	unsigned int id = 0, id_iter, id_check;
 	unsigned int ci_off = ci_start, ci_end = ci_start + nr_pages;
-	unsigned long offset = cluster_offset(si, ci) + ci_start;
+	unsigned long offset = cluster_offset(si, ci);
+	unsigned int ci_batch = ci_off;
 
 	VM_WARN_ON(ci->count < nr_pages);
 
@@ -1896,13 +1899,29 @@ void __swap_cluster_free_entries(struct swap_info_struct *si,
 		/* Release the last ref, or after swap cache is dropped */
 		VM_WARN_ON(!swp_tb_is_shadow(old_tb) || __swp_tb_get_count(old_tb) > 1);
 		__swap_table_set(ci, ci_off, null_to_swp_tb());
+
+		shadow = swp_tb_to_shadow(old_tb);
+		id_iter = shadow_to_memcgid(shadow);
+		if (id != id_iter) {
+			if (id) {
+				id_check = swap_cgroup_clear(swp_entry(type, offset + ci_batch),
+							     ci_off - ci_batch);
+				WARN_ON(id != id_check);
+				mem_cgroup_uncharge_swap(id, ci_off - ci_batch);
+			}
+			id = id_iter;
+			ci_batch = ci_off;
+		}
 	} while (++ci_off < ci_end);
 
-	id = swap_cgroup_clear(swp_entry(si->type, offset), nr_pages);
-	if (id)
-		mem_cgroup_uncharge_swap(id, nr_pages);
+	if (id) {
+		id_check = swap_cgroup_clear(swp_entry(type, offset + ci_batch),
+					     ci_off - ci_batch);
+		WARN_ON(id != id_check);
+		mem_cgroup_uncharge_swap(id, ci_off - ci_batch);
+	}
 
-	swap_range_free(si, offset, nr_pages);
+	swap_range_free(si, offset + ci_start, nr_pages);
 	swap_cluster_assert_empty(ci, ci_start, nr_pages, false);
 
 	if (!ci->count)

-- 
2.53.0

