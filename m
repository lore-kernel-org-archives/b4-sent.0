From: Zhang Peng <zippermonkey@icloud.com>
Date: Mon, 09 Mar 2026 16:17:42 +0800
Subject: [PATCH 2/2] mm, vmscan: flush TLB for every 31 folios evictions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-batch-tlb-flush-v1-2-eb8fed7d1a9e@icloud.com>
References: <20260309-batch-tlb-flush-v1-0-eb8fed7d1a9e@icloud.com>
In-Reply-To: <20260309-batch-tlb-flush-v1-0-eb8fed7d1a9e@icloud.com>
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Qi Zheng <zhengqi.arch@bytedance.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Michal Hocko <mhocko@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>, Zhang Peng <bruzzhang@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773044270; l=4427;
 i=zippermonkey@icloud.com; s=20260309; h=from:subject:message-id;
 bh=VtbVoUdutucQYTv61lHy5DXkSCu6zJZpJudQ30ChVHA=;
 b=hb84Un+QVXegPOTad/271FdH2TnK0FCOWCwyQrjIcYqmfgBJ2uz0HVL0r8lRGfBXbWq4q5Q3B
 MJJHWQGILuwAzFjHJquHifaJ+c6i/rVn/faJo05uEQWnci0nAx0TqPg
X-Developer-Key: i=zippermonkey@icloud.com; a=ed25519;
 pk=tPCLpFnBfIyHsp0k7eaUTUREEa36bQNW/69X+NS8wBU=
X-Endpoint-Received: by B4 Relay for zippermonkey@icloud.com/20260309 with auth_id=671
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: bruzzhang <bruzzhang@tencent.com>

Currently we flush TLB for every dirty folio, which is a bottleneck for
systems with many cores as this causes heavy IPI usage.

So instead, batch the folios, and flush once for every 31 folios (one
folio_batch). These folios will be held in a folio_batch releasing their
lock, then when folio_batch is full, do following steps:

- For each folio: lock - check still evictable - unlock
  - If no longer evictable, return the folio to the caller.
- Flush TLB once for the batch
- Pageout the folios (refcount freeze happens in the pageout path)

Note we can't hold a frozen folio in folio_batch for long as it will
cause filemap/swapcache lookup to livelock. Fortunately pageout usually
won't take too long; sync IO is fast, and non-sync IO will be issued
with the folio marked writeback.

Suggested-by: Kairui Song <kasong@tencent.com>
Signed-off-by: bruzzhang <bruzzhang@tencent.com>
---
 mm/vmscan.c | 68 ++++++++++++++++++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 61 insertions(+), 7 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index a336f7fc7dae..69cdd3252ff8 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -1240,6 +1240,48 @@ static void pageout_one(struct folio *folio, struct list_head *ret_folios,
 	VM_BUG_ON_FOLIO(folio_test_lru(folio) ||
 			folio_test_unevictable(folio), folio);
 }
+
+static void pageout_batch(struct folio_batch *fbatch,
+			  struct list_head *ret_folios,
+			  struct folio_batch *free_folios,
+			  struct scan_control *sc, struct reclaim_stat *stat,
+			  struct swap_iocb **plug, struct list_head *folio_list)
+{
+	int i = 0, count = folio_batch_count(fbatch);
+	struct folio *folio;
+
+	folio_batch_reinit(fbatch);
+	do {
+		folio = fbatch->folios[i];
+		if (!folio_trylock(folio)) {
+			list_add(&folio->lru, ret_folios);
+			continue;
+		}
+
+		if (folio_test_writeback(folio) || folio_test_lru(folio) ||
+		    folio_mapped(folio))
+			goto next;
+		folio_batch_add(fbatch, folio);
+		continue;
+next:
+		folio_unlock(folio);
+		list_add(&folio->lru, ret_folios);
+	} while (++i != count);
+
+	i = 0;
+	count = folio_batch_count(fbatch);
+	if (!count)
+		return;
+	/* One TLB flush for the batch */
+	try_to_unmap_flush_dirty();
+	do {
+		folio = fbatch->folios[i];
+		pageout_one(folio, ret_folios, free_folios, sc, stat, plug,
+			    folio_list);
+	} while (++i != count);
+	folio_batch_reinit(fbatch);
+}
+
 /*
  * Reclaimed folios are counted in stat->nr_reclaimed.
  */
@@ -1249,6 +1291,8 @@ static void shrink_folio_list(struct list_head *folio_list,
 		struct mem_cgroup *memcg)
 {
 	struct folio_batch free_folios;
+	struct folio_batch flush_folios;
+
 	LIST_HEAD(ret_folios);
 	LIST_HEAD(demote_folios);
 	unsigned int nr_demoted = 0;
@@ -1257,6 +1301,8 @@ static void shrink_folio_list(struct list_head *folio_list,
 	struct swap_iocb *plug = NULL;
 
 	folio_batch_init(&free_folios);
+	folio_batch_init(&flush_folios);
+
 	memset(stat, 0, sizeof(*stat));
 	cond_resched();
 	do_demote_pass = can_demote(pgdat->node_id, sc, memcg);
@@ -1578,15 +1624,19 @@ static void shrink_folio_list(struct list_head *folio_list,
 				goto keep_locked;
 			if (!sc->may_writepage)
 				goto keep_locked;
-
 			/*
-			 * Folio is dirty. Flush the TLB if a writable entry
-			 * potentially exists to avoid CPU writes after I/O
-			 * starts and then write it out here.
+			 * For anon, we should only see swap cache (anon) and
+			 * the list pinning the page. For file page, the filemap
+			 * and the list pins it. Combined with the page_ref_freeze
+			 * in pageout_batch ensure nothing else touches the page
+			 * during lock unlocked.
 			 */
-			try_to_unmap_flush_dirty();
-			pageout_one(folio, &ret_folios, &free_folios, sc, stat,
-				&plug, folio_list);
+			folio_unlock(folio);
+			if (!folio_batch_add(&flush_folios, folio))
+				pageout_batch(&flush_folios,
+							&ret_folios, &free_folios,
+							sc, stat, &plug,
+							folio_list);
 			goto next;
 		}
 
@@ -1614,6 +1664,10 @@ static void shrink_folio_list(struct list_head *folio_list,
 next:
 		continue;
 	}
+	if (folio_batch_count(&flush_folios)) {
+		pageout_batch(&flush_folios, &ret_folios, &free_folios, sc,
+			      stat, &plug, folio_list);
+	}
 	/* 'folio_list' is always empty here */
 
 	/* Migrate folios selected for demotion */

-- 
2.43.7

