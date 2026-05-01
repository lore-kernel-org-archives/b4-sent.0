From: Kairui Song <kasong@tencent.com>
Date: Sat, 02 May 2026 05:04:10 +0800
Subject: [PATCH RFC 24/32] mm/workingset: use a single atomic operation for
 read and age
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-mglru-fg-v1-24-913619b014d9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=2020;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=wgOBUng+uTQYm5twq6Yy1hA/jkGiMMQo7dEmYz74ui0=;
 b=ir6e0a5kqtAwGqvbIavgrfnZJL15MwneqaCVg2lgFlnO9FBbjWzjQcm7j0Nc4ykvHkerskNIx
 VRDLrU4BOj7CxHp3RBUP3d15PVMDXtxI4aCutuGdbgjQxeqMnPjkN6q
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

One single atomic operation should be faster than two for most archs,
and be more accurate.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/workingset.c | 12 +++++++-----
 1 file changed, 7 insertions(+), 5 deletions(-)

diff --git a/mm/workingset.c b/mm/workingset.c
index aac68cecdfbf..a77a6c0c3e15 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -369,8 +369,10 @@ static void lru_gen_refault(struct folio *folio, void *shadow)
  * to the in-memory dimensions. This function allows reclaim and LRU
  * operations to drive the non-resident aging along in parallel.
  */
-static void workingset_age_nonresident(struct lruvec *lruvec, unsigned long nr_pages)
+static long workingset_age_nonresident(struct lruvec *lruvec, unsigned long nr_pages)
 {
+	unsigned long eviction;
+
 	/*
 	 * Reclaiming a cgroup means reclaiming all its children in a
 	 * round-robin fashion. That means that each cgroup has an LRU
@@ -382,9 +384,10 @@ static void workingset_age_nonresident(struct lruvec *lruvec, unsigned long nr_p
 	 * the virtual inactive lists of all its parents, including
 	 * the root cgroup's, age as well.
 	 */
-	do {
+	eviction = atomic_long_fetch_add_relaxed(nr_pages, &lruvec->evictions);
+	while ((lruvec = parent_lruvec(lruvec)))
 		atomic_long_add(nr_pages, &lruvec->evictions);
-	} while ((lruvec = parent_lruvec(lruvec)));
+	return eviction;
 }
 
 /**
@@ -414,9 +417,8 @@ void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
 	lruvec = mem_cgroup_lruvec(target_memcg, pgdat);
 	/* XXX: target_memcg can be NULL, go through lruvec */
 	memcgid = mem_cgroup_private_id(lruvec_memcg(lruvec));
-	eviction = atomic_long_read(&lruvec->evictions);
+	eviction = workingset_age_nonresident(lruvec, folio_nr_pages(folio));
 	eviction >>= bucket_order[file];
-	workingset_age_nonresident(lruvec, folio_nr_pages(folio));
 	return pack_shadow(memcgid, pgdat, eviction,
 			   folio_is_workingset(folio), file);
 }

-- 
2.54.0

