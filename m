From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 20 Jul 2026 17:25:07 -0700
Subject: [PATCH v3 04/13] mm: hugetlb: Remove unused
 mem_cgroup_charge_hugetlb function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hugetlb-alloc-failure-fixes-v3-4-7d2a169aa9ee@google.com>
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
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784602387; l=2906;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=YxYG1OGXEwJP8y6Z/IuFu/IygfIhB7TL//GqeViUvNo=;
 b=ODtz7IxzrmEVm8ITYNPhXWX2tkSFDb0Wo55iHcQRNwKOI1rX9vcyL7wqj2XEfXYcaIBA0galC
 iwpBY5zcPvkCL3uWuHWuJCKXlOZCeXKd8EuisExKDwVIE1ZR8hjkV60
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that the alloc_hugetlb_folio path has been successfully migrated to
the new try-commit-cancel memcg charging protocol, the old
mem_cgroup_charge_hugetlb function and its associated header and
static inline declarations are completely unused. Remove them to clean
up the memory controller's codebase.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/memcontrol.h |  6 ------
 mm/memcontrol.c            | 34 ----------------------------------
 2 files changed, 40 deletions(-)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index c4e63d0e03526..23fbbbc8e11f2 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -641,7 +641,6 @@ static inline int mem_cgroup_charge(struct folio *folio, struct mm_struct *mm,
 	return __mem_cgroup_charge(folio, mm, gfp);
 }
 
-int mem_cgroup_charge_hugetlb(struct folio *folio, gfp_t gfp);
 int mem_cgroup_hugetlb_try_charge(unsigned int nr_pages, gfp_t gfp,
 				  struct mem_cgroup **memcg_p,
 				  struct obj_cgroup **objcg_p);
@@ -1137,11 +1136,6 @@ static inline int mem_cgroup_charge(struct folio *folio,
 	return 0;
 }
 
-static inline int mem_cgroup_charge_hugetlb(struct folio *folio, gfp_t gfp)
-{
-	return 0;
-}
-
 static inline int mem_cgroup_hugetlb_try_charge(unsigned int nr_pages, gfp_t gfp,
 						struct mem_cgroup **memcg_p,
 						struct obj_cgroup **objcg_p)
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 0beee5c0ce93b..6764ff041c196 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -5146,40 +5146,6 @@ int __mem_cgroup_charge(struct folio *folio, struct mm_struct *mm, gfp_t gfp)
 	return ret;
 }
 
-/**
- * mem_cgroup_charge_hugetlb - charge the memcg for a hugetlb folio
- * @folio: folio being charged
- * @gfp: reclaim mode
- *
- * This function is called when allocating a huge page folio, after the page has
- * already been obtained and charged to the appropriate hugetlb cgroup
- * controller (if it is enabled).
- *
- * Returns ENOMEM if the memcg is already full.
- * Returns 0 if either the charge was successful, or if we skip the charging.
- */
-int mem_cgroup_charge_hugetlb(struct folio *folio, gfp_t gfp)
-{
-	struct mem_cgroup *memcg = get_mem_cgroup_from_current();
-	int ret = 0;
-
-	/*
-	 * Even memcg does not account for hugetlb, we still want to update
-	 * system-level stats via lruvec_stat_mod_folio. Return 0, and skip
-	 * charging the memcg.
-	 */
-	if (mem_cgroup_disabled() || !memcg_accounts_hugetlb() ||
-		!memcg || !cgroup_subsys_on_dfl(memory_cgrp_subsys))
-		goto out;
-
-	if (charge_memcg(folio, memcg, gfp))
-		ret = -ENOMEM;
-
-out:
-	mem_cgroup_put(memcg);
-	return ret;
-}
-
 /**
  * mem_cgroup_hugetlb_try_charge - Try to charge the memcg for a hugetlb folio
  * @nr_pages: number of base pages to charge

-- 
2.55.0.229.g6434b31f56-goog

