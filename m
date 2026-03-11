From: Leno Hou <lenohou@gmail.com>
Date: Wed, 11 Mar 2026 20:09:43 +0800
Subject: [PATCH v2 2/2] mm/mglru: maintain workingset refault context
 across state transitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-b4-switch-mglru-v2-v2-2-080cb9321463@gmail.com>
References: <20260311-b4-switch-mglru-v2-v2-0-080cb9321463@gmail.com>
In-Reply-To: <20260311-b4-switch-mglru-v2-v2-0-080cb9321463@gmail.com>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Jialing Wang <wjl.linux@gmail.com>, 
 Yafang Shao <laoar.shao@gmail.com>, Yu Zhao <yuzhao@google.com>, 
 Kairui Song <ryncsn@gmail.com>, Bingfang Guo <bfguo@icloud.com>, 
 Barry Song <baohua@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Leno Hou <lenohou@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773230982; l=5011;
 i=lenohou@gmail.com; s=20260311; h=from:subject:message-id;
 bh=mpnWMW6S89qGDIwaKivQjNoGDsv2soTWaW1Gf6K14EE=;
 b=xcndljvTygCcwBzsgj8nOw/iRC7PBqzNOjNrqjCnt1Bogi0UldgGc+rLPInShme/2seEjuxVE
 5txGqDKNySACcCOr+H31oDye4fgESyq3o03RYnnnbcViC1fsrV+Y3ed
X-Developer-Key: i=lenohou@gmail.com; a=ed25519;
 pk=8AVHXYurzu1kOGjk9rwvxovwSCynBkv2QAcOvSIe1rw=
X-Endpoint-Received: by B4 Relay for lenohou@gmail.com/20260311 with auth_id=674
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When MGLRU state is toggled dynamically, existing shadow entries (eviction
tokens) lose their context. Traditional LRU and MGLRU handle workingset
refaults using different logic. Without context, shadow entries
re-activated by the "wrong" reclaim logic trigger excessive page
activations (pgactivate) and system thrashing, as the kernel cannot
correctly distinguish if a refaulted page was originally managed by
MGLRU or the traditional LRU.

This patch introduces shadow entry context tracking:

- Encode MGLRU origin: Introduce WORKINGSET_MGLRU_SHIFT into the shadow
  entry (eviction token) encoding. This adds an 'is_mglru' bit to shadow
  entries, allowing the kernel to correctly identify the originating
  reclaim logic for a page even after the global MGLRU state has been
  toggled.

- Refault logic dispatch: Use this 'is_mglru' bit in workingset_refault()
  and workingset_test_recent() to dispatch refault events to the correct
  handler (lru_gen_refault vs. traditional workingset refault).

This ensures that refaulted pages are handled by the appropriate reclaim
logic regardless of the current MGLRU enabled state, preventing
unnecessary thrashing and state-inconsistent refault activations during
state transitions.

To: Andrew Morton <akpm@linux-foundation.org>
To: Axel Rasmussen <axelrasmussen@google.com>
To: Yuanchu Xie <yuanchu@google.com>
To: Wei Xu <weixugc@google.com>
To: Barry Song <21cnbao@gmail.com>
To: Jialing Wang <wjl.linux@gmail.com>
To: Yafang Shao <laoar.shao@gmail.com>
To: Yu Zhao <yuzhao@google.com>
To: Kairui Song <ryncsn@gmail.com>
To: Bingfang Guo <bfguo@icloud.com>
Cc: linux-mm@kvack.org
Cc: linux-kernel@vger.kernel.org
Signed-off-by: Leno Hou <lenohou@gmail.com>
---
 mm/workingset.c | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/mm/workingset.c b/mm/workingset.c
index 13422d304715..baa766daac24 100644
--- a/mm/workingset.c
+++ b/mm/workingset.c
@@ -180,8 +180,10 @@
  * refault distance will immediately activate the refaulting page.
  */
 
+#define WORKINGSET_MGLRU_SHIFT  1
 #define WORKINGSET_SHIFT 1
 #define EVICTION_SHIFT	((BITS_PER_LONG - BITS_PER_XA_VALUE) +	\
+			 WORKINGSET_MGLRU_SHIFT + \
 			 WORKINGSET_SHIFT + NODES_SHIFT + \
 			 MEM_CGROUP_ID_SHIFT)
 #define EVICTION_MASK	(~0UL >> EVICTION_SHIFT)
@@ -197,12 +199,13 @@
 static unsigned int bucket_order __read_mostly;
 
 static void *pack_shadow(int memcgid, pg_data_t *pgdat, unsigned long eviction,
-			 bool workingset)
+			 bool workingset, bool is_mglru)
 {
 	eviction &= EVICTION_MASK;
 	eviction = (eviction << MEM_CGROUP_ID_SHIFT) | memcgid;
 	eviction = (eviction << NODES_SHIFT) | pgdat->node_id;
 	eviction = (eviction << WORKINGSET_SHIFT) | workingset;
+	eviction = (eviction << WORKINGSET_MGLRU_SHIFT) | is_mglru;
 
 	return xa_mk_value(eviction);
 }
@@ -214,6 +217,7 @@ static void unpack_shadow(void *shadow, int *memcgidp, pg_data_t **pgdat,
 	int memcgid, nid;
 	bool workingset;
 
+	entry >>= WORKINGSET_MGLRU_SHIFT;
 	workingset = entry & ((1UL << WORKINGSET_SHIFT) - 1);
 	entry >>= WORKINGSET_SHIFT;
 	nid = entry & ((1UL << NODES_SHIFT) - 1);
@@ -254,7 +258,7 @@ static void *lru_gen_eviction(struct folio *folio)
 	hist = lru_hist_from_seq(min_seq);
 	atomic_long_add(delta, &lrugen->evicted[hist][type][tier]);
 
-	return pack_shadow(mem_cgroup_private_id(memcg), pgdat, token, workingset);
+	return pack_shadow(mem_cgroup_private_id(memcg), pgdat, token, workingset, true);
 }
 
 /*
@@ -390,7 +394,7 @@ void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
 	VM_BUG_ON_FOLIO(folio_ref_count(folio), folio);
 	VM_BUG_ON_FOLIO(!folio_test_locked(folio), folio);
 
-	if (lru_gen_enabled())
+	if (folio_lru_gen(folio) != -1)
 		return lru_gen_eviction(folio);
 
 	lruvec = mem_cgroup_lruvec(target_memcg, pgdat);
@@ -400,7 +404,7 @@ void *workingset_eviction(struct folio *folio, struct mem_cgroup *target_memcg)
 	eviction >>= bucket_order;
 	workingset_age_nonresident(lruvec, folio_nr_pages(folio));
 	return pack_shadow(memcgid, pgdat, eviction,
-				folio_test_workingset(folio));
+				folio_test_workingset(folio), false);
 }
 
 /**
@@ -426,8 +430,10 @@ bool workingset_test_recent(void *shadow, bool file, bool *workingset,
 	int memcgid;
 	struct pglist_data *pgdat;
 	unsigned long eviction;
+	unsigned long entry = xa_to_value(shadow);
+	bool is_mglru = !!(entry & WORKINGSET_MGLRU_SHIFT);
 
-	if (lru_gen_enabled()) {
+	if (is_mglru) {
 		bool recent;
 
 		rcu_read_lock();
@@ -539,10 +545,11 @@ void workingset_refault(struct folio *folio, void *shadow)
 	struct lruvec *lruvec;
 	bool workingset;
 	long nr;
+	unsigned long entry = xa_to_value(shadow);
 
 	VM_BUG_ON_FOLIO(!folio_test_locked(folio), folio);
 
-	if (lru_gen_enabled()) {
+	if (entry & ((1UL << WORKINGSET_MGLRU_SHIFT) - 1)) {
 		lru_gen_refault(folio, shadow);
 		return;
 	}

-- 
2.52.0

