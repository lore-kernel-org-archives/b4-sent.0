From: Kairui Song <kasong@tencent.com>
Date: Wed, 18 Feb 2026 04:06:37 +0800
Subject: [PATCH v3 12/12] mm, swap: no need to clear the shadow explicitly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260218-swap-table-p3-v3-12-f4e34be021a7@tencent.com>
References: <20260218-swap-table-p3-v3-0-f4e34be021a7@tencent.com>
In-Reply-To: <20260218-swap-table-p3-v3-0-f4e34be021a7@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 Youngjun Park <youngjun.park@lge.com>, linux-kernel@vger.kernel.org, 
 Chris Li <chrisl@kernel.org>, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771358806; l=3144;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=Q0lBjSShyhdY2RwLncpL2hL+mRqIuErD7BuuaEl7Tog=;
 b=8HJd87buS9O2RDjBJVI/JPFWqAGjZ/tZ8SHZCwdUyevLQFXEz7hNeBSGpP8VDEko1e2W88Cbr
 f75J32I17ctAjc73AYgXB2x0BXnap1ldmE0AEALFXDI6Mv1JtT/gaRx
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since we no longer bypass the swap cache, every swap-in will clear the
swap shadow by inserting the folio into the swap table. The only place
we may seem to need to free the swap shadow is when the swap slots are
freed directly without a folio (swap_put_entries_direct). But with the
swap table, that is not needed either. Freeing a slot in the swap table
will set the table entry to NULL, which erases the shadow just fine.

So just delete all explicit shadow clearing, it's no longer needed.
Also, rearrange the freeing.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swap.h       |  1 -
 mm/swap_state.c | 21 ---------------------
 mm/swapfile.c   |  2 --
 3 files changed, 24 deletions(-)

diff --git a/mm/swap.h b/mm/swap.h
index 9728e6a944b2..a77016f2423b 100644
--- a/mm/swap.h
+++ b/mm/swap.h
@@ -290,7 +290,6 @@ void __swap_cache_del_folio(struct swap_cluster_info *ci,
 			    struct folio *folio, swp_entry_t entry, void *shadow);
 void __swap_cache_replace_folio(struct swap_cluster_info *ci,
 				struct folio *old, struct folio *new);
-void __swap_cache_clear_shadow(swp_entry_t entry, int nr_ents);
 
 void show_swap_cache_info(void);
 void swapcache_clear(struct swap_info_struct *si, swp_entry_t entry, int nr);
diff --git a/mm/swap_state.c b/mm/swap_state.c
index e7618ffe6d70..32d9d877bda8 100644
--- a/mm/swap_state.c
+++ b/mm/swap_state.c
@@ -350,27 +350,6 @@ void __swap_cache_replace_folio(struct swap_cluster_info *ci,
 	}
 }
 
-/**
- * __swap_cache_clear_shadow - Clears a set of shadows in the swap cache.
- * @entry: The starting index entry.
- * @nr_ents: How many slots need to be cleared.
- *
- * Context: Caller must ensure the range is valid, all in one single cluster,
- * not occupied by any folio, and lock the cluster.
- */
-void __swap_cache_clear_shadow(swp_entry_t entry, int nr_ents)
-{
-	struct swap_cluster_info *ci = __swap_entry_to_cluster(entry);
-	unsigned int ci_off = swp_cluster_offset(entry), ci_end;
-	unsigned long old;
-
-	ci_end = ci_off + nr_ents;
-	do {
-		old = __swap_table_xchg(ci, ci_off, null_to_swp_tb());
-		WARN_ON_ONCE(swp_tb_is_folio(old) || swp_tb_get_count(old));
-	} while (++ci_off < ci_end);
-}
-
 /*
  * If we are the only user, then try to free up the swap cache.
  *
diff --git a/mm/swapfile.c b/mm/swapfile.c
index dab5e726855b..802efa37b33f 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -1287,7 +1287,6 @@ static void swap_range_alloc(struct swap_info_struct *si,
 static void swap_range_free(struct swap_info_struct *si, unsigned long offset,
 			    unsigned int nr_entries)
 {
-	unsigned long begin = offset;
 	unsigned long end = offset + nr_entries - 1;
 	void (*swap_slot_free_notify)(struct block_device *, unsigned long);
 	unsigned int i;
@@ -1312,7 +1311,6 @@ static void swap_range_free(struct swap_info_struct *si, unsigned long offset,
 			swap_slot_free_notify(si->bdev, offset);
 		offset++;
 	}
-	__swap_cache_clear_shadow(swp_entry(si->type, begin), nr_entries);
 
 	/*
 	 * Make sure that try_to_unuse() observes si->inuse_pages reaching 0

-- 
2.52.0

