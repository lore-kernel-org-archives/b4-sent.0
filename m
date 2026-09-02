From: Kairui Song <kasong@tencent.com>
Date: Wed, 02 Sep 2026 17:50:59 +0800
Subject: [PATCH v5 6/6] mm/mglru: fix potential generation folio number
 leak
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-mglru-flags-cleanup-v5-6-9db761d779ef@tencent.com>
References: <20260902-mglru-flags-cleanup-v5-0-9db761d779ef@tencent.com>
In-Reply-To: <20260902-mglru-flags-cleanup-v5-0-9db761d779ef@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Baoquan He <baoquan.he@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Muchun Song <muchun.song@linux.dev>, Chris Li <chrisl@kernel.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Ridong Chen <ridong.chen@linux.dev>, Lian Wang <lianux.mm@gmail.com>, 
 Yu Zhao <yuzhao@google.com>, Zi Yan <ziy@nvidia.com>, 
 Qi Zheng <qi.zheng@linux.dev>, cgroups@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kairui Song <ryncsn@gmail.com>, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788342657; l=5300;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=BeFRtTv2DUVCnBDdSk2xGGeIVNwza5FMggB+YkSlaTk=;
 b=WKortzZwxgU1YkMCpiMgIJayfIQsa7teb+grctu7+vTppe/6UAmFcu5HnWG/tveeH6BpxNbyq
 4h3I9AloIQiAPCNj/AL/+unCXwYy8KCX1/IJJTmhLHESJl3BqpwQucE
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each generation of MGLRU accounts anon and file folio numbers
separately, and the page table walker updates each generation's
counters in batch once the walk is done. The walker promotes a
folio's generation with a cmpxchg on folio->flags, and
update_batch_size() then reads the live flags again to pick the
anon/file column to charge. The walk holds neither the lruvec lock nor
the folio lock, so the type can flip between the cmpxchg and that
read: the lazyfree path clears PG_swapbacked, and reclaim sets it back
on a dirty lazyfree folio. The batched delta pair is then recorded in
the wrong type column. Nothing reconciles it afterwards, permanently
skewing lrugen->nr_pages and the reclaim budgets derived from it.

Fix it by capturing the type from the flags snapshot the cmpxchg
linearized against: folio_update_gen() returns the type of the state
it transitioned from, and update_batch_size() accounts with that.

A folio's type only changes while it is off the LRU list, inside a
del/add pair under the lruvec lock, with the gen bits cleared in
between. The generation and PG_swapbacked sit in the same
folio->flags word, so the cmpxchg snapshot captures them together.
Let G be the generation that snapshot captured (old_gen) and G' the
one it wrote (new_gen); the CAS can land in only three places:

  - before the del: the folio is anon at G; the batch records anon
    G -> G', and the del later removes the folio from the anon
    counters;
  - between del and add: gen == -1, so folio_update_gen() returns -1
    without touching the flags and no batch is recorded; the del/add
    pair accounts for the move alone;
  - after the add: the folio is file at the fresh generation the add
    charged; the batch records file, that gen -> G', matching that
    charge.

Unlike the drift of lazy promotions, which sort_folio() repairs under
the lruvec lock, the phantom deltas from before this fix land in a
column the folio never occupies again, so nothing ever repairs them.

Fixes: bd74fdaea146 ("mm: multi-gen LRU: support page table walks")
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm_inline.h | 11 +++++++++++
 mm/vmscan.c               | 13 +++++++------
 2 files changed, 18 insertions(+), 6 deletions(-)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index 047295ae6e8a..ab69b9930893 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -30,6 +30,17 @@ static inline int folio_is_file_lru(const struct folio *folio)
 	return !folio_test_swapbacked(folio);
 }
 
+/**
+ * folio_flags_is_file_lru - Should the folio be on a file LRU or anon LRU?
+ * @flags: The folio's flags.
+ *
+ * Just like folio_is_file_lru but take the folio flags directly instead.
+ */
+static inline int folio_flags_is_file_lru(const unsigned long *flags)
+{
+	return !test_bit(PG_swapbacked, flags);
+}
+
 static __always_inline void __update_lru_size(struct lruvec *lruvec,
 				enum lru_list lru, enum zone_type zid,
 				long nr_pages)
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 714a3f273f49..e7d379c6e703 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -3269,7 +3269,8 @@ static bool positive_ctrl_err(struct ctrl_pos *sp, struct ctrl_pos *pv)
  ******************************************************************************/
 
 /* promote pages accessed through page tables */
-static int folio_update_gen(struct folio *folio, int new_gen, const vma_flags_t *vma_flags)
+static int folio_update_gen(struct folio *folio, int new_gen, int *type,
+			    const vma_flags_t *vma_flags)
 {
 	unsigned long new_flags, old_flags = READ_ONCE(*folio_flags(folio, 0));
 	int old_gen;
@@ -3298,6 +3299,7 @@ static int folio_update_gen(struct folio *folio, int new_gen, const vma_flags_t
 		new_flags |= BIT(PG_workingset);
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
+	*type = folio_flags_is_file_lru(&old_flags);
 	return old_gen;
 }
 
@@ -3328,9 +3330,8 @@ static int folio_inc_gen(struct lruvec *lruvec, struct folio *folio)
 }
 
 static void update_batch_size(struct lru_gen_mm_walk *walk, struct folio *folio,
-			      int old_gen, int new_gen)
+			      int old_gen, int new_gen, int type)
 {
-	int type = folio_is_file_lru(folio);
 	int zone = folio_zonenum(folio);
 	int delta = folio_nr_pages(folio);
 
@@ -3519,7 +3520,7 @@ static bool suitable_to_scan(int total, int young)
 static void walk_update_folio(struct lru_gen_mm_walk *walk, struct vm_area_struct *vma,
 		struct lruvec *lruvec, struct folio *folio, bool dirty)
 {
-	int new_gen, old_gen;
+	int new_gen, old_gen, type;
 
 	if (!folio)
 		return;
@@ -3532,9 +3533,9 @@ static void walk_update_folio(struct lru_gen_mm_walk *walk, struct vm_area_struc
 		folio_mark_dirty(folio);
 
 	if (walk) {
-		old_gen = folio_update_gen(folio, new_gen, &vma->flags);
+		old_gen = folio_update_gen(folio, new_gen, &type, &vma->flags);
 		if (old_gen >= 0 && old_gen != new_gen)
-			update_batch_size(walk, folio, old_gen, new_gen);
+			update_batch_size(walk, folio, old_gen, new_gen, type);
 	} else if (lru_gen_set_refs(folio, &vma->flags)) {
 		old_gen = folio_lru_gen(folio);
 		if (old_gen >= 0 && old_gen != new_gen)

-- 
2.55.0

