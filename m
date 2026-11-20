From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:42 -0500
Subject: [PATCH 51/60] mm: restrict explicit migration to
 N_MEMORY_MEMPOLICY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-51-74f5f9a115c2@gourry.net>
References: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
In-Reply-To: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
To: Yury Norov <yury.norov@gmail.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 David Hildenbrand <david@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Michal Hocko <mhocko@suse.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Oscar Salvador <osalvador@suse.de>, Johannes Weiner <hannes@cmpxchg.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Brendan Jackman <brendan.jackman@linux.dev>, Zi Yan <ziy@nvidia.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Rakie Kim <rakie.kim@sk.com>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Matthew Brost <matthew.brost@intel.com>, Byungchul Park <byungchul@sk.com>, 
 Alistair Popple <apopple@nvidia.com>, SJ Park <sj@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, Kees Cook <kees@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Barry Song <baohua@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Michal Hocko <mhocko@kernel.org>, David Rientjes <rientjes@google.com>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Nico Pache <nico.pache@linux.dev>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Xu Xin <xu.xin@linux.dev>, Chengming Zhou <chengming.zhou@linux.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, Pedro Falcato <pfalcato@suse.de>, 
 Jann Horn <jannh@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, Jan Kara <jack@suse.cz>, 
 Waiman Long <longman@redhat.com>, Ridong Chen <ridong.chen@linux.dev>, 
 Tejun Heo <tj@kernel.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Dan Williams <djbw@kernel.org>, Vishal Verma <vishal.l.verma@intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, 
 Alison Schofield <alison.schofield@intel.com>, 
 Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 linux-cxl@vger.kernel.org, linux-doc@vger.kernel.org, 
 driver-core@lists.linux.dev, damon@lists.linux.dev, 
 linux-pm@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 cgroups@vger.kernel.org, nvdimm@lists.linux.dev, 
 linux-kselftest@vger.kernel.org, "Gregory Price (Meta)" <gourry@gourry.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198154; l=3917;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=B6Y6UKzNoFCEvlaigonl7wIhC2pzL3ijUJbtxgXP4vI=;
 b=Cqgg+950T1Wa/QOdAAoJ89OU4n2XkUCd91Mhb4KvzETYBoxSmxxLKw/cTE1vnANvYIjt0Oank
 NZIwcdEbRo7DFudh5eeM7NJWPyrWJpnbINaDNlQsQ5xoIUroWylq7iS
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mbind(MPOL_MF_MOVE), migrate_pages() and move_pages() act only on folios
on common memory. N_MEMORY_MEMPOLICY nodes are the nodes memory policy
and explicit migration may target, so let explicit migration also act on
folios already on them.

Add folio_allows_mempolicy(), which requires the folio's node to permit
memory policy, and use it instead.

Memory on other private nodes is still left alone:
  - move_pages() refuses to migrate it.
  - mbind(MPOL_MF_MOVE) and migrate_pages() skip its folios.

Cpuset migration can now find pages on these nodes. Evacuate them only
from nodes the cpuset no longer allows. Private nodes are still never
destinations for this kind of migration.

Migration keeps its best-effort behavior and can affect shared backing
pages seen by other mappers.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 kernel/cgroup/cpuset.c | 8 +++++++-
 mm/internal.h          | 7 +++++++
 mm/mempolicy.c         | 4 ++--
 mm/migrate.c           | 2 +-
 4 files changed, 17 insertions(+), 4 deletions(-)

diff --git a/kernel/cgroup/cpuset.c b/kernel/cgroup/cpuset.c
index e20f9ccb8ab7..7d4b922a1914 100644
--- a/kernel/cgroup/cpuset.c
+++ b/kernel/cgroup/cpuset.c
@@ -2686,8 +2686,14 @@ static void cpuset_migrate_mm_workfn(struct work_struct *work)
 {
 	struct cpuset_migrate_mm_work *mwork =
 		container_of(work, struct cpuset_migrate_mm_work, work);
+	nodemask_t retained;
 
-	/* Private nodes are never migration destinations. */
+	/*
+	 * Private nodes are never migration destinations. Evacuate private
+	 * memory only from nodes the cpuset no longer allows.
+	 */
+	nodes_and(retained, mwork->to, node_states[N_MEMORY_PRIVATE]);
+	nodes_andnot(mwork->from, mwork->from, retained);
 	nodes_andnot(mwork->to, mwork->to, node_states[N_MEMORY_PRIVATE]);
 	/* on a wq worker, no need to worry about %current's mems_allowed */
 	do_migrate_pages(mwork->mm, &mwork->from, &mwork->to, MPOL_MF_MOVE_ALL);
diff --git a/mm/internal.h b/mm/internal.h
index fa1ae221564e..4bac570bb29f 100644
--- a/mm/internal.h
+++ b/mm/internal.h
@@ -87,6 +87,13 @@ static inline bool folio_allows_reclaim(struct folio *folio)
 	       node_state(folio_nid(folio), N_MEMORY_RECLAIM);
 }
 
+/* May userspace NUMA operations act on this folio's memory? */
+static inline bool folio_allows_mempolicy(struct folio *folio)
+{
+	return !folio_is_zone_device(folio) &&
+	       node_state(folio_nid(folio), N_MEMORY_MEMPOLICY);
+}
+
 /* mm/vmscan.c */
 unsigned long zone_reclaimable_pages(struct zone *zone);
 unsigned long try_to_free_pages(struct zonelist *zonelist, int order,
diff --git a/mm/mempolicy.c b/mm/mempolicy.c
index 2bfe8b2b6287..9d2e56017ebe 100644
--- a/mm/mempolicy.c
+++ b/mm/mempolicy.c
@@ -705,7 +705,7 @@ static void queue_folios_pmd(pmd_t *pmd, unsigned long addr,
 		return;
 	}
 	folio = vm_normal_folio_pmd(walk->vma, addr, pmdval);
-	if (!folio || !folio_is_common_memory(folio))
+	if (!folio || !folio_allows_mempolicy(folio))
 		return;
 	if (!queue_folio_required(folio, qp))
 		return;
@@ -763,7 +763,7 @@ static int queue_folios_pte_range(pmd_t *pmd, unsigned long addr,
 			continue;
 		}
 		folio = vm_normal_folio(vma, addr, ptent);
-		if (!folio || !folio_is_common_memory(folio))
+		if (!folio || !folio_allows_mempolicy(folio))
 			continue;
 		if (folio_test_large(folio) && max_nr != 1)
 			nr = folio_pte_batch(folio, pte, ptent, max_nr);
diff --git a/mm/migrate.c b/mm/migrate.c
index ac583afa1bc5..6791834f14fe 100644
--- a/mm/migrate.c
+++ b/mm/migrate.c
@@ -2287,7 +2287,7 @@ static int __add_folio_for_migration(struct folio *folio, int node,
 	if (is_zero_folio(folio) || is_huge_zero_folio(folio))
 		return -EFAULT;
 
-	if (!folio_is_common_memory(folio))
+	if (!folio_allows_mempolicy(folio))
 		return -ENOENT;
 
 	if (folio_nid(folio) == node)

-- 
2.56.1

