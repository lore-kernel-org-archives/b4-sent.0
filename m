From: Kairui Song <kasong@tencent.com>
Date: Wed, 12 Aug 2026 20:22:39 +0800
Subject: [PATCH v2] mm/mglru: fix and remove redundant unevictable folio
 handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-mglru-mlock-fix-v2-1-a3fec5853c08@tencent.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ6CMBBEf4Xs2TXdQrTx5H8YDtAuUoXWtIVoC
 P9uwbPHN5l5s0DkYDnCpVgg8Gyj9S6DPBSg+8bdGa3JDFLIk1BEON6HMOE4eP3Ezr5RCqM6ZSp
 VnRvIq1fgHO/GW/3jOLUP1mnTbI3exuTDZ7+caev9t8+EhKqVpSQjmEx5Tew0u3TUfoR6Xdcvh
 zMrX8IAAAA=
X-Change-ID: 20260811-mglru-mlock-fix-20d8f8d4847a
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Michal Hocko <mhocko@kernel.org>, Qi Zheng <qi.zheng@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Lorenzo Stoakes <ljs@kernel.org>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Oleksandr Natalenko <oleksandr@natalenko.name>, 
 Suleiman Souhlal <suleiman@google.com>, 
 "Jan Alexander Steffens (heftig)" <heftig@archlinux.org>, 
 Yu Zhao <yuzhao@google.com>, Steven Barrett <steven@liquorix.net>, 
 Brian Geffon <bgeffon@google.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Kairui Song <ryncsn@gmail.com>, 
 linux-kernel@vger.kernel.org, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786537360; l=4125;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=U29orzKk9D7il/dD5NUP46H8cRaJscTJfBNkl8jXS24=;
 b=glwH4HIia2IpuIdS3x5BsJrnJb+xJ61O2JdxsyE/WYO1gAglTuMnQhrPr7sy7LM1selJb22QA
 PMDF4R6eoApDe9EvRBQIRyjTjJ52/SV8EO0iUoQSgJdMLIxLo6cHncu
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sort_folio() has a shortcut for moving folios that are no longer
evictable but are still sitting on a generation list.  However, this
shortcut is buggy.  It does not follow the PG_lru usage convention,
and it has a more serious issue.

Unevictable folios are not threaded on lists[LRU_UNEVICTABLE], so that
folio->lru can be reused to hold folio->mlock_count (see the comment in
lruvec_init()).  Hence lruvec_add_folio() skips the list_add() for them,
and every other place that turns a folio unevictable initialises
mlock_count explicitly: lru_add() sets it to 0, __mlock_folio() and
__mlock_new_folio() set it to !!folio_test_mlocked(folio).
sort_folio() sets nothing, and the lru_gen_del_folio() right above it
may have already poisoned folio->lru via list_del(), so mlock_count
ends up aliasing LIST_POISON2, which reads as 0x122, i.e. 290.  The
result is user visible.  On munlock, __munlock_folio() decrements that
bogus count, finds it still non-zero and bails out before clearing
PG_mlocked, so the folio remains unevictable and the Mlocked
accounting stays inflated until the folio is freed.

The shortcut also touches the LRU flags in the wrong order.  It calls
lru_gen_del_folio() while PG_lru is still set, so a concurrent
folio_test_clear_lru() (e.g. compaction, folio_isolate_lru()) can
succeed on a folio that has already been taken off the generation list,
which may lead to unexpected behavior.

So fix it by isolating them as common folios and letting the generic
shrink path cull them. This matches the classical LRU behavior, and
there should be no visible effect on the generic eviction or isolation
behavior.

There is no performance concern either, such a folio goes through this
once, and then it is off the generation lists for good.

Fixes: ac35a4902374 ("mm: multi-gen LRU: minimal implementation")
Signed-off-by: Kairui Song <kasong@tencent.com>
---
Changes in v2:
- Proactively bypass MGLRU pid protection and lazy promotion to avoid
  hot unevcitable folios staying on list for a long time.
- Link to v1: https://patch.msgid.link/20260811-mglru-mlock-fix-v1-1-8b2321d0e1d3@tencent.com
---
 mm/vmscan.c | 19 +++++--------------
 1 file changed, 5 insertions(+), 14 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 3194da7dcc79..ca2b926520ea 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4648,7 +4648,6 @@ void lru_gen_reparent_memcg(struct mem_cgroup *memcg, struct mem_cgroup *parent,
 static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_control *sc,
 		       int tier_idx)
 {
-	bool success;
 	int gen = folio_lru_gen(folio);
 	int type = folio_is_file_lru(folio);
 	int zone = folio_zonenum(folio);
@@ -4660,15 +4659,9 @@ static bool sort_folio(struct lruvec *lruvec, struct folio *folio, struct scan_c
 
 	VM_WARN_ON_ONCE_FOLIO(gen >= MAX_NR_GENS, folio);
 
-	/* unevictable */
-	if (!folio_evictable(folio)) {
-		success = lru_gen_del_folio(lruvec, folio, true);
-		VM_WARN_ON_ONCE_FOLIO(!success, folio);
-		folio_set_unevictable(folio);
-		lruvec_add_folio(lruvec, folio);
-		__count_vm_events(UNEVICTABLE_PGCULLED, delta);
-		return true;
-	}
+	/* unevictable: let it through and the generic path will cull it */
+	if (!folio_evictable(folio))
+		return false;
 
 	/* promoted */
 	if (gen != lru_gen_from_seq(lrugen->min_seq[type])) {
@@ -4921,11 +4914,9 @@ static int evict_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 	list_for_each_entry_safe_reverse(folio, next, &list, lru) {
 		DEFINE_MIN_SEQ(lruvec);
 
-		if (!folio_evictable(folio)) {
-			list_del(&folio->lru);
-			folio_putback_lru(folio);
+		/* move_folios_to_lru() culls unevictable folios via folio_putback_lru() */
+		if (!folio_evictable(folio))
 			continue;
-		}
 
 		/* retry folios that may have missed folio_rotate_reclaimable() */
 		if (!skip_retry && !folio_test_active(folio) && !folio_mapped(folio) &&

---
base-commit: 1029098ee3275ea5b78e329ce132262affa2f8cc
change-id: 20260811-mglru-mlock-fix-20d8f8d4847a

Best regards,
--  
Kairui Song <kasong@tencent.com>

