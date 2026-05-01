From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:09 +0800
Subject: [PATCH RFC 23/32] mm/workingset: rename the nonresistence age
 counter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-23-913619b014d9@tencent.com>
References: <20260502-mglru-fg-v1-0-913619b014d9@tencent.com>
In-Reply-To: <20260502-mglru-fg-v1-0-913619b014d9@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Youngjun Park <youngjun.park@lge.com>, 
 Zi Yan <ziy@nvidia.com>, Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Nico Pache <npache@redhat.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SeongJae Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, 
 Chen Ridong <chenridong@huaweicloud.com>, Tal Zussman <tz2294@columbia.edu>, 
 Kairui Song <ryncsn@gmail.com>, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=4861;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=RZ75CFKx9NHBtI4cGuTrtP6eqoZNh7E9CBvqbHcahSE=;
 b=6CUaoS9oIH44bJ2AntcJ9Npik2Ryxt5O6dYw7eQBmQWbjWLTWtWLbYQjxusIpbsC+fbHre9/X
 LYWbK2P1T1OCsWFUfQfEBXJKiNAl+i7YwNq4D52rScVPa3Jkg1GqBLa
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Clearly, now nonresistence_age just means how many pages has been evicted
from this lruvec. Rename it.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mmzone.h |  4 ++--
 mm/workingset.c        | 27 ++++++++++-----------------
 2 files changed, 12 insertions(+), 19 deletions(-)

diff --git a/include/linux/mmzone.h b/include/linux/mmzone.h
index 393bbea75838..6747e1c6079c 100644
--- a/include/linux/mmzone.h
+++ b/include/linux/mmzone.h
@@ -799,8 +799,8 @@ struct lruvec {
 	 */
 	unsigned long			anon_cost;
 	unsigned long			file_cost;
-	/* Non-resident age, driven by LRU movement */
-	atomic_long_t			nonresident_age;
+	/* How many evictions has happened */
+	atomic_long_t			evictions;
 	/* Refaults at the time of last reclaim cycle */
 	unsigned long			refaults[ANON_AND_FILE];
 	/* Various lruvec state flags (enum lruvec_flags) */
diff --git a/mm/workingset.c b/mm/workingset.c
index 01f6e9a72cdb..aac68cecdfbf 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -66,12 +66,12 @@
  * thrashing on the inactive list, after which refaulting pages can be
  * activated optimistically to compete with the existing active pages.
  *
- * For such approximation, introduce a counter `nonresident_age` (NA)
- * per lruvec. NA is incremented once for every evicted page, and each
- * evicted page's shadow entry records the NA value at eviction time as
+ * For such approximation, introduce a counter `evictions` (E)
+ * per lruvec. E is incremented once for every evicted page, and each
+ * evicted page's shadow entry records the E value at eviction time as
  * a timestamp. So when an evicted page is faulted in again, we have:
  *
- *   Let SP = ((NA's reading @ current) - (NA's reading @ eviction))
+ *   Let SP = ((E's reading @ current) - (E's reading @ eviction))
  *
  *                            +-memory available to cache-+
  *                            |                           |
@@ -143,13 +143,6 @@
  *    the benefit extends across a broader range of S/M as a smooth
  *    transition rather than a cliff.
  *
- * A secondary effect: NA over-counts pages that are refaulted and
- * then re-evicted (they contribute to NA twice over their lifetime),
- * which inflates SP for older shadows under heavy refault churn. The
- * feasibility bound SP <= NR_ACTIVE would over-activate in that
- * regime; tightening to (A+I)/2 dampens this without a separate
- * correction.
- *
  *		Refaulting inactive pages
  *
  * All that is known about the active list is that the pages have been
@@ -180,7 +173,7 @@
  *
  *		Implementation
  *
- * For each lruvec, a non-resident age counter (lruvec->nonresident_age)
+ * For each lruvec, a non-resident age counter (lruvec->evictions)
  * is maintained. It is incremented once per evicted page.
  *
  * On eviction, a snapshot of this counter (along with some bits to
@@ -390,7 +383,7 @@ static void workingset_age_nonresident(struct lruvec *lruvec, unsigned long nr_p
 	 * the root cgroup's, age as well.
 	 */
 	do {
-		atomic_long_add(nr_pages, &lruvec->nonresident_age);
+		atomic_long_add(nr_pages, &lruvec->evictions);
 	} while ((lruvec = parent_lruvec(lruvec)));
 }
 
@@ -421,7 +414,7 @@ void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
 	lruvec = mem_cgroup_lruvec(target_memcg, pgdat);
 	/* XXX: target_memcg can be NULL, go through lruvec */
 	memcgid = mem_cgroup_private_id(lruvec_memcg(lruvec));
-	eviction = atomic_long_read(&lruvec->nonresident_age);
+	eviction = atomic_long_read(&lruvec->evictions);
 	eviction >>= bucket_order[file];
 	workingset_age_nonresident(lruvec, folio_nr_pages(folio));
 	return pack_shadow(memcgid, pgdat, eviction,
@@ -501,17 +494,17 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 		mem_cgroup_flush_stats_ratelimited(eviction_memcg);
 
 	eviction_lruvec = mem_cgroup_lruvec(eviction_memcg, pgdat);
-	refault = atomic_long_read(&eviction_lruvec->nonresident_age);
+	refault = atomic_long_read(&eviction_lruvec->evictions);
 
 	/*
 	 * Calculate the refault distance
 	 *
 	 * The unsigned subtraction here gives an accurate distance
-	 * across nonresident_age overflows in most cases. There is a
+	 * across evictions overflows in most cases. There is a
 	 * special case: usually, shadow entries have a short lifetime
 	 * and are either refaulted or reclaimed along with the inode
 	 * before they get too old.  But it is not impossible for the
-	 * nonresident_age to lap a shadow entry in the field, which
+	 * evictions to lap a shadow entry in the field, which
 	 * can then result in a false small refault distance, leading
 	 * to a false activation should this old entry actually
 	 * refault again.  However, earlier kernels used to deactivate

-- 
2.54.0

