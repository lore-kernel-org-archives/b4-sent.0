From: Kairui Song <kasong@tencent.com>
Date: Fri, 20 Feb 2026 07:42:11 +0800
Subject: [PATCH RFC 10/15] mm, swap: always retrieve memcg id from swap
 table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-swap-table-p4-v1-10-104795d19815@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771544524; l=4319;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=WsZXml04ASUgTsoFPs4VOCkE3+G9dotFosGt0KDSdnI=;
 b=8PUGQy+iLDj47T0eAJnEPkBbFEpbjpdotOGd9HFhFodXjiH7rSlOJhvBygk9dElK56junzS5k
 sewBlHU75avAo5d1frQoohXdWvj9c85coOf+rZoeyzNWabyjMYaOOeT
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Transition mem_cgroup_swapin_charge_folio() to receive the memcg id
from the caller via the swap table shadow entry, demoting the old
swap cgroup array lookup to a sanity check. Also removes the per-PTE
cgroup id batching break from swap_pte_batch() since now swap is able to
free slots across mem cgroups.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/memcontrol.h | 6 ++++--
 mm/internal.h              | 4 ----
 mm/memcontrol.c            | 9 ++++++---
 mm/swap_state.c            | 5 ++++-
 4 files changed, 14 insertions(+), 10 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index 0b37d4faf785..8fc794baf736 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -667,7 +667,8 @@ static inline int mem_cgroup_charge(struct folio *folio, struct mm_struct *mm,
 int mem_cgroup_charge_hugetlb(struct folio* folio, gfp_t gfp);
 
 int mem_cgroup_swapin_charge_folio(struct folio *folio, struct mm_struct *mm,
-				  gfp_t gfp, swp_entry_t entry);
+				   gfp_t gfp, swp_entry_t entry,
+				   unsigned short id);
 
 void __mem_cgroup_uncharge(struct folio *folio);
 
@@ -1145,7 +1146,8 @@ static inline int mem_cgroup_charge_hugetlb(struct folio* folio, gfp_t gfp)
 }
 
 static inline int mem_cgroup_swapin_charge_folio(struct folio *folio,
-			struct mm_struct *mm, gfp_t gfp, swp_entry_t entry)
+			struct mm_struct *mm, gfp_t gfp, swp_entry_t entry,
+			unsigned short id)
 {
 	return 0;
 }
diff --git a/mm/internal.h b/mm/internal.h
index 5bbe081c9048..416d3401aa17 100644
--- a/mm/internal.h
+++ b/mm/internal.h
@@ -452,12 +452,10 @@ static inline int swap_pte_batch(pte_t *start_ptep, int max_nr, pte_t pte)
 	const pte_t *end_ptep = start_ptep + max_nr;
 	const softleaf_t entry = softleaf_from_pte(pte);
 	pte_t *ptep = start_ptep + 1;
-	unsigned short cgroup_id;
 
 	VM_WARN_ON(max_nr < 1);
 	VM_WARN_ON(!softleaf_is_swap(entry));
 
-	cgroup_id = lookup_swap_cgroup_id(entry);
 	while (ptep < end_ptep) {
 		softleaf_t entry;
 
@@ -466,8 +464,6 @@ static inline int swap_pte_batch(pte_t *start_ptep, int max_nr, pte_t pte)
 		if (!pte_same(pte, expected_pte))
 			break;
 		entry = softleaf_from_pte(pte);
-		if (lookup_swap_cgroup_id(entry) != cgroup_id)
-			break;
 		expected_pte = pte_next_swp_offset(expected_pte);
 		ptep++;
 	}
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index d9ff44b77409..d0f50019d733 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -4794,6 +4794,7 @@ int mem_cgroup_charge_hugetlb(struct folio *folio, gfp_t gfp)
  * @mm: mm context of the victim
  * @gfp: reclaim mode
  * @entry: swap entry for which the folio is allocated
+ * @id: the mem cgroup id
  *
  * This function charges a folio allocated for swapin. Please call this before
  * adding the folio to the swapcache.
@@ -4801,19 +4802,21 @@ int mem_cgroup_charge_hugetlb(struct folio *folio, gfp_t gfp)
  * Returns 0 on success. Otherwise, an error code is returned.
  */
 int mem_cgroup_swapin_charge_folio(struct folio *folio, struct mm_struct *mm,
-				  gfp_t gfp, swp_entry_t entry)
+				   gfp_t gfp, swp_entry_t entry, unsigned short id)
 {
 	struct mem_cgroup *memcg, *swap_memcg;
+	unsigned short memcg_id;
 	unsigned int nr_pages;
-	unsigned short id;
 	int ret;
 
 	if (mem_cgroup_disabled())
 		return 0;
 
-	id = lookup_swap_cgroup_id(entry);
+	memcg_id = lookup_swap_cgroup_id(entry);
 	nr_pages = folio_nr_pages(folio);
 
+	WARN_ON_ONCE(id != memcg_id);
+
 	rcu_read_lock();
 	swap_memcg = mem_cgroup_from_private_id(id);
 	if (!swap_memcg) {
diff --git a/mm/swap_state.c b/mm/swap_state.c
index cc4bf40320ef..5ab3a41fe42c 100644
--- a/mm/swap_state.c
+++ b/mm/swap_state.c
@@ -251,8 +251,11 @@ static struct folio *__swap_cache_alloc(struct swap_cluster_info *ci,
 	__swap_cache_add_folio(ci, folio, entry);
 	spin_unlock(&ci->lock);
 
+	/* With swap table, we must have a shadow, for memcg tracking */
+	WARN_ON(!shadow);
+
 	if (mem_cgroup_swapin_charge_folio(folio, vmf ? vmf->vma->vm_mm : NULL,
-					   gfp, entry)) {
+					   gfp, entry, shadow_to_memcgid(shadow))) {
 		spin_lock(&ci->lock);
 		__swap_cache_del_folio(ci, folio, shadow, false, false);
 		spin_unlock(&ci->lock);

-- 
2.53.0

