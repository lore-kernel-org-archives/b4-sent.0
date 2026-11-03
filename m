From: Kairui Song <kasong@tencent.com>
Date: Wed, 04 Nov 2026 00:25:45 +0800
Subject: [PATCH v4 1/3] mm, swap: only allow swapped-out slots into the
 swap cache
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-swap-hibernation-slots-v4-1-0ba9393609e1@tencent.com>
References: <20261104-swap-hibernation-slots-v4-0-0ba9393609e1@tencent.com>
In-Reply-To: <20261104-swap-hibernation-slots-v4-0-0ba9393609e1@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <baoquan.he@linux.dev>, Barry Song <baohua@kernel.org>, 
 Jianyue Wu <wujianyue000@gmail.com>, Youngjun Park <youngjun.park@lge.com>, 
 "David Hildenbrand (Arm)" <david@kernel.org>, 
 Kairui Song <ryncsn@gmail.com>, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793723146; l=3324;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=DSg4zPkZqnOQvGhK9sG11r29/KrXHPQLe9s8Rr3DHeY=;
 b=11vQE85hIvbe97NqWxRwvbKHZLTqYj7++y3AJG7mDwZH12EvUhPH1qnjISuktefyl8en6VaMR
 jh9fyvGQjrxBGIJUcby06JaCEM3YOc/F9b/KUBNKe9Fh1hR/a8I/AfT
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Youngjun Park <youngjun.park@lge.com>

__swap_cache_add_check() turns away folio entries and slots with no count
and lets everything else in.  That is safe only when the caller owns the
slot.  Cluster readahead owns nothing, it walks a raw page_cluster sized
window of offsets around the faulting entry, so it can land on any slot.

A bad slot gets in.  The check reads the count with __swp_tb_get_count(),
which shifts the count bits out without looking at the type, and
SWP_TB_BAD has all of them set, so the slot reads as SWP_TB_COUNT_MAX.
Readahead then allocates a folio and reads the offset off the device for a
slot nothing will ever swap in, and the folio entry that replaces it drops
the bad marker.

Readahead used to be guarded by swap_entry_swapped(), which goes through
swp_tb_get_count() and gets -EINVAL for a bad slot.  That call went away
when the swap cache checks moved into __swap_cache_add_check(), and the
raw accessor there does not do the same type test.

Require a shadow entry instead.  A slot dropped from the swap cache always
gets one, empty if there is no workingset value.  The type test runs first,
so the count is only read off a countable entry, and the check as a whole
runs before the folio allocation in __swap_cache_alloc().

The large folio walk in the same function does the same raw reads.  A bad
slot cannot be in its range, but the range is not pinned, so a slot freed
and then taken by hibernation still trips the countable assertion there.
Give the walk the same shadow test, the folio check folds into it.

Reproduced with a badpages list written into the swap header by hand.
Readahead took over four bad slots before this patch and none after.  It
needs a crafted header, so a normal setup will not hit it.

Fixes: e1e6750df3b4 ("mm, swap: add support for stable large allocation in swap cache directly")
Acked-by: Kairui Song <kasong@tencent.com>
Signed-off-by: Youngjun Park <youngjun.park@lge.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swap_state.c | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/mm/swap_state.c b/mm/swap_state.c
index d9e36c505398..da65d75ceead 100644
--- a/mm/swap_state.c
+++ b/mm/swap_state.c
@@ -191,9 +191,14 @@ static int __swap_cache_add_check(struct swap_cluster_info *ci,
 	old_tb = __swap_table_get(ci, ci_off);
 	if (swp_tb_is_folio(old_tb))
 		return -EEXIST;
-	if (!__swp_tb_get_count(old_tb))
+	/*
+	 * Only a swapped-out slot may be brought into the swap cache.
+	 * Cluster readahead walks raw offset ranges, so it can land on
+	 * slots that are free, bad, or owned by hibernation.
+	 */
+	if (!swp_tb_is_shadow(old_tb) || !__swp_tb_get_count(old_tb))
 		return -ENOENT;
-	if (shadowp && swp_tb_is_shadow(old_tb))
+	if (shadowp)
 		*shadowp = swp_tb_to_shadow(old_tb);
 	if (memcg_id)
 		*memcg_id = __swap_cgroup_get(ci, ci_off);
@@ -206,7 +211,7 @@ static int __swap_cache_add_check(struct swap_cluster_info *ci,
 	ci_end = ci_off + nr;
 	do {
 		old_tb = __swap_table_get(ci, ci_off);
-		if (unlikely(swp_tb_is_folio(old_tb) ||
+		if (unlikely(!swp_tb_is_shadow(old_tb) ||
 			     !__swp_tb_get_count(old_tb) ||
 			     is_zero != __swap_table_test_zero(ci, ci_off) ||
 			     (memcg_id && *memcg_id != __swap_cgroup_get(ci, ci_off))))

-- 
2.56.0

