From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 20 Jul 2026 17:25:06 -0700
Subject: [PATCH v3 03/13] mm: hugetlb: Use try-commit-cancel protocol for
 memcg charge of folios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hugetlb-alloc-failure-fixes-v3-3-7d2a169aa9ee@google.com>
References: <20260720-hugetlb-alloc-failure-fixes-v3-0-7d2a169aa9ee@google.com>
In-Reply-To: <20260720-hugetlb-alloc-failure-fixes-v3-0-7d2a169aa9ee@google.com>
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Nhat Pham <nphamcs@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Peter Xu <peterx@redhat.com>, 
 Wupeng Ma <mawupeng1@huawei.com>, fvdl@google.com, rientjes@google.com, 
 jthoughton@google.com, Mike Kravetz <mike.kravetz@oracle.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>
Cc: vannapurve@google.com, erdemaktas@google.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784602387; l=10920;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=0AcwGphc3uan0N2TDSOh02phq0/whAnaLvUQOgTHT0c=;
 b=aGV+5Brhx8SclDNTFhVEBxin3LumpPpe6D0wnVa8FJWlaXPeCRzhdP5E/EcKZ94gkjloJEvSq
 +0FxmYsdgGWAIUAnTVc66ZyJk2YZ20AF+uZgiwHsgN+7gBwG73a3B6v
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Using mem_cgroup_charge_hugetlb() to charge a HugeTLB folio during page
fault creates a reservation leak bug if the task hits its memory cgroup
limit.

When alloc_hugetlb_folio() commits the VMA reservation, the reserved
page is removed from the reserve map. If a subsequent call to
mem_cgroup_charge_hugetlb() returns -ENOMEM, the allocation is aborted
and the physical folio is disposed of via free_huge_page(). However,
because the VMA reservation was already consumed, the reservation count
in the reserve map is lost. This causes subsequent faults in the VMA
address range to fail with premature reservation exhaustion.

Additionally, dropping the use of free_huge_folio() on the failure path
fixes an issue where free_huge_folio() was incorrectly invoked on a
folio with a refcount of 1, triggering refcount mismatches and kernel
warnings.

To fix this, introduce a try-commit-cancel protocol for memory cgroup
charging of HugeTLB folios, matching the architecture used by the
hugetlb cgroup controller. Invoking mem_cgroup_hugetlb_try_charge()
before consuming the VMA reservation ensures that if the memory cgroup
limit is reached, the allocation is aborted cleanly without leaking
the reservation entry or having to dispose of a partially initialized
folio.

An alternative would be to retain the current usage of
mem_cgroup_charge_hugetlb() and free_huge_page(), but freeing the folio
performs reservation management for subpools and global hstate, which
complicates rollback in alloc_hugetlb_folio(). Using a try-commit-cancel
protocol is more consistent with the other charging performed in
alloc_hugetlb_folio() and easier to understand.

Fixes: 991135774c0e0 ("memcg/hugetlb: introduce mem_cgroup_charge_hugetlb")
Cc: stable@vger.kernel.org
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/memcontrol.h |  36 ++++++++++++--
 mm/hugetlb.c               |  30 ++++++------
 mm/memcontrol.c            | 114 +++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 162 insertions(+), 18 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index e1f46a0016fcf..c4e63d0e03526 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -641,7 +641,16 @@ static inline int mem_cgroup_charge(struct folio *folio, struct mm_struct *mm,
 	return __mem_cgroup_charge(folio, mm, gfp);
 }
 
-int mem_cgroup_charge_hugetlb(struct folio* folio, gfp_t gfp);
+int mem_cgroup_charge_hugetlb(struct folio *folio, gfp_t gfp);
+int mem_cgroup_hugetlb_try_charge(unsigned int nr_pages, gfp_t gfp,
+				  struct mem_cgroup **memcg_p,
+				  struct obj_cgroup **objcg_p);
+void mem_cgroup_hugetlb_commit_charge(struct folio *folio,
+				      struct mem_cgroup *memcg,
+				      struct obj_cgroup *objcg);
+void mem_cgroup_hugetlb_cancel_charge(unsigned int nr_pages,
+				      struct mem_cgroup *memcg,
+				      struct obj_cgroup *objcg);
 
 int mem_cgroup_swapin_charge_folio(struct folio *folio, unsigned short id,
 				   struct mm_struct *mm, gfp_t gfp);
@@ -1128,9 +1137,30 @@ static inline int mem_cgroup_charge(struct folio *folio,
 	return 0;
 }
 
-static inline int mem_cgroup_charge_hugetlb(struct folio* folio, gfp_t gfp)
+static inline int mem_cgroup_charge_hugetlb(struct folio *folio, gfp_t gfp)
+{
+	return 0;
+}
+
+static inline int mem_cgroup_hugetlb_try_charge(unsigned int nr_pages, gfp_t gfp,
+						struct mem_cgroup **memcg_p,
+						struct obj_cgroup **objcg_p)
+{
+	*memcg_p = NULL;
+	*objcg_p = NULL;
+	return 0;
+}
+
+static inline void mem_cgroup_hugetlb_commit_charge(struct folio *folio,
+						    struct mem_cgroup *memcg,
+						    struct obj_cgroup *objcg)
+{
+}
+
+static inline void mem_cgroup_hugetlb_cancel_charge(unsigned int nr_pages,
+						    struct mem_cgroup *memcg,
+						    struct obj_cgroup *objcg)
 {
-        return 0;
 }
 
 static inline int mem_cgroup_swapin_charge_folio(struct folio *folio,
diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index b32735b092a0a..061d7250c202d 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -38,6 +38,7 @@
 #include <linux/mm_inline.h>
 #include <linux/padata.h>
 #include <linux/pgalloc.h>
+#include <linux/memcontrol.h>
 
 #include <asm/page.h>
 #include <asm/tlb.h>
@@ -2863,6 +2864,8 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	int ret, idx;
 	struct hugetlb_cgroup *h_cg = NULL;
 	struct hugetlb_cgroup *h_cg_rsvd = NULL;
+	struct mem_cgroup *mem_cg = NULL;
+	struct obj_cgroup *obj_cg = NULL;
 	gfp_t gfp = htlb_alloc_mask(h) | __GFP_RETRY_MAYFAIL;
 
 	idx = hstate_index(h);
@@ -2922,6 +2925,11 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 	if (ret)
 		goto out_uncharge_cgroup_reservation;
 
+	ret = mem_cgroup_hugetlb_try_charge(pages_per_huge_page(h), gfp,
+					    &mem_cg, &obj_cg);
+	if (ret)
+		goto out_uncharge_cgroup;
+
 	spin_lock_irq(&hugetlb_lock);
 	/*
 	 * glb_chg is passed to indicate whether or not a page must be taken
@@ -2933,7 +2941,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		spin_unlock_irq(&hugetlb_lock);
 		folio = alloc_buddy_hugetlb_folio_with_mpol(h, vma, addr);
 		if (!folio)
-			goto out_uncharge_cgroup;
+			goto out_uncharge_cgroup_memcg;
 		spin_lock_irq(&hugetlb_lock);
 		list_add(&folio->lru, &h->hugepage_activelist);
 		folio_ref_unfreeze(folio, 1);
@@ -2960,6 +2968,9 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 
 	spin_unlock_irq(&hugetlb_lock);
 
+	mem_cgroup_hugetlb_commit_charge(folio, mem_cg, obj_cg);
+	lruvec_stat_mod_folio(folio, NR_HUGETLB, pages_per_huge_page(h));
+
 	hugetlb_set_folio_subpool(folio, spool);
 
 	if (map_chg != MAP_CHG_ENFORCED) {
@@ -2987,21 +2998,10 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 		}
 	}
 
-	ret = mem_cgroup_charge_hugetlb(folio, gfp);
-	/*
-	 * Unconditionally increment NR_HUGETLB here. If it turns out that
-	 * mem_cgroup_charge_hugetlb failed, then immediately free the page and
-	 * decrement NR_HUGETLB.
-	 */
-	lruvec_stat_mod_folio(folio, NR_HUGETLB, pages_per_huge_page(h));
-
-	if (ret == -ENOMEM) {
-		free_huge_folio(folio);
-		goto err;
-	}
-
 	return folio;
 
+out_uncharge_cgroup_memcg:
+	mem_cgroup_hugetlb_cancel_charge(pages_per_huge_page(h), mem_cg, obj_cg);
 out_uncharge_cgroup:
 	hugetlb_cgroup_uncharge_cgroup(idx, pages_per_huge_page(h), h_cg);
 out_uncharge_cgroup_reservation:
@@ -3022,7 +3022,7 @@ struct folio *alloc_hugetlb_folio(struct vm_area_struct *vma,
 out_end_reservation:
 	if (map_chg != MAP_CHG_ENFORCED)
 		vma_end_reservation(h, vma, addr);
-err:
+
 	/*
 	 * Return -ENOSPC when this function fails to allocate or
 	 * charge a huge page. If a standard (PAGE_SIZE) page
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 6dc4888a90f3f..0beee5c0ce93b 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -5180,6 +5180,120 @@ int mem_cgroup_charge_hugetlb(struct folio *folio, gfp_t gfp)
 	return ret;
 }
 
+/**
+ * mem_cgroup_hugetlb_try_charge - Try to charge the memcg for a hugetlb folio
+ * @nr_pages: number of base pages to charge
+ * @gfp: reclaim mode
+ * @memcg_p: Output pointer to the charged mem_cgroup (if successful and enabled)
+ * @objcg_p: Output pointer to the charged obj_cgroup (if successful and enabled)
+ *
+ * Prepares and tries to reserve the memory counter for the folio from the current
+ * task's memcg. If successful, both *memcg_p and *objcg_p are populated and their
+ * references are pinned until a subsequent call to mem_cgroup_hugetlb_commit_charge
+ * or mem_cgroup_hugetlb_cancel_charge.
+ *
+ * Returns ENOMEM if the memcg is already full.
+ * Returns 0 if either the charge was successful, or if we skip charging.
+ */
+int mem_cgroup_hugetlb_try_charge(unsigned int nr_pages, gfp_t gfp,
+				  struct mem_cgroup **memcg_p,
+				  struct obj_cgroup **objcg_p)
+{
+	struct mem_cgroup *memcg;
+	struct obj_cgroup *objcg;
+	int ret = 0;
+
+	*memcg_p = NULL;
+	*objcg_p = NULL;
+
+	if (mem_cgroup_disabled() || !memcg_accounts_hugetlb() ||
+	    !cgroup_subsys_on_dfl(memory_cgrp_subsys))
+		return 0;
+
+	memcg = get_mem_cgroup_from_current();
+	if (!memcg)
+		return 0;
+
+	objcg = get_obj_cgroup_from_memcg(memcg);
+	if (!objcg)
+		goto put_memcg;
+
+	if (!obj_cgroup_is_root(objcg)) {
+		ret = try_charge_memcg(memcg, gfp, nr_pages);
+		if (ret)
+			goto put_objcg;
+	}
+
+	*memcg_p = memcg;
+	*objcg_p = objcg;
+	return 0;
+
+put_objcg:
+	obj_cgroup_put(objcg);
+put_memcg:
+	mem_cgroup_put(memcg);
+	return ret;
+}
+
+/**
+ * mem_cgroup_hugetlb_commit_charge - Commit the memcg charge for a hugetlb folio
+ * @folio: folio being charged
+ * @memcg: Target mem_cgroup obtained from mem_cgroup_hugetlb_try_charge
+ * @objcg: Target obj_cgroup obtained from mem_cgroup_hugetlb_try_charge
+ *
+ * Finalizes the memory and statistics charging for the folio in the specified memcg.
+ * Transfers the pinned objcg reference to the folio structure (for automatic
+ * uncharging upon freeing via mem_cgroup_uncharge). Releases the try-commit reference
+ * on memcg.
+ */
+void mem_cgroup_hugetlb_commit_charge(struct folio *folio,
+				      struct mem_cgroup *memcg,
+				      struct obj_cgroup *objcg)
+{
+	if (!memcg || !objcg)
+		return;
+
+	commit_charge(folio, objcg);
+	memcg1_commit_charge(folio, memcg);
+
+	/*
+	 * Drop our try-commit-cancel protocol reference on memcg.
+	 * The objcg reference is TRANSFERRED to the folio by commit_charge,
+	 * so it will be put automatically by __mem_cgroup_uncharge() when
+	 * the folio is freed.
+	 */
+	mem_cgroup_put(memcg);
+}
+
+/**
+ * mem_cgroup_hugetlb_cancel_charge - Cancel and undo a hugetlb folio memcg charge
+ * @nr_pages: number of base pages to uncharge
+ * @memcg: Target mem_cgroup obtained from mem_cgroup_hugetlb_try_charge
+ * @objcg: Target obj_cgroup obtained from mem_cgroup_hugetlb_try_charge
+ *
+ * Cancels and safely rolls back the prepared memory charge for the folio in the
+ * specified memcg. Releases the try-commit pinned references on both memcg and objcg.
+ */
+void mem_cgroup_hugetlb_cancel_charge(unsigned int nr_pages,
+				      struct mem_cgroup *memcg,
+				      struct obj_cgroup *objcg)
+{
+	if (!memcg || !objcg)
+		return;
+
+	if (!obj_cgroup_is_root(objcg))
+		refill_stock(memcg, nr_pages);
+
+	/*
+	 * Drop our try-commit-cancel protocol references on both objcg
+	 * and memcg, since this mapping attempt was aborted and the folio
+	 * was never committed.
+	 */
+	obj_cgroup_put(objcg);
+	mem_cgroup_put(memcg);
+}
+
+
 /**
  * mem_cgroup_swapin_charge_folio - Charge a newly allocated folio for swapin.
  * @folio: the folio to charge

-- 
2.55.0.229.g6434b31f56-goog

