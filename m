From: Kairui Song <kasong@tencent.com>
Date: Wed, 04 Nov 2026 00:18:14 +0800
Subject: [PATCH v2 1/4] mm/zswap: drop the stale zswap entry of a zero
 folio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-swap-fixes-v2-1-204be064be5b@tencent.com>
References: <20261104-swap-fixes-v2-0-204be064be5b@tencent.com>
In-Reply-To: <20261104-swap-fixes-v2-0-204be064be5b@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <baoquan.he@linux.dev>, 
 Barry Song <baohua@kernel.org>, Youngjun Park <youngjun.park@lge.com>, 
 Usama Arif <usamaarif642@gmail.com>, 
 Chengming Zhou <chengming.zhou@linux.dev>, Yosry Ahmed <yosry@kernel.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Chuanhua Han <hanchuanhua@oppo.com>, Mani Tofigh <mt4022@columbia.edu>, 
 NeilBrown <neil@brown.name>, Christoph Hellwig <hch@lst.de>, 
 linux-kernel@vger.kernel.org, Josef Bacik <josef@toxicpanda.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793722701; l=2902;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=5JIfvqgJZSkDLS+9X8sNXJzSR9p+F+l9mzgjMoyRQf0=;
 b=nnIkmk/QGTpjHCzmkNn8ZZTzaxluVqlOIuUU6+PAEz3ckDifiSnny/fyr9FzDbFlimey9SHP+
 EbB2jPyII0rACVUq8xQ3eS4VRNg/1DDZ3CFhSZzZONMVtqLoOMRKBgI
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Josef Bacik <josef@toxicpanda.com>

A folio can stay in the swap cache after zswap_store() has stored it,
when a swapin fault gets a reference on it before reclaim can remove it.
do_swap_page() maps an exclusive folio writable and, for a read fault,
keeps it in the swap cache, so it can be modified and swapped out again
to the same slot. zswap_store() handles this, it replaces the old entry,
or drops it if the store fails or zswap got disabled, "otherwise,
writeback could overwrite the new data in the swapfile".

swap_writeout() does not get as far as zswap_store() if the folio is
zero-filled now. It only sets the zero flag of the slot, and the zswap
entry with the previous contents stays in the tree and on the LRU:

  reclaim            fault              zswap shrinker
  zswap_store(D1)
                     swap cache hit,
                     map, write zeroes
  swap_writeout()
    zero flag set
  folio reclaimed
                                        zswap_writeback_entry()
                                          swap_cache_alloc_folio()
                                          decompress D1, uptodate
                     swap cache hit:
                     maps D1

Swapin looks at the zero flag first, but only when it has to read the
folio. The folio that zswap writeback leaves in the swap cache is up to
date as far as anybody can tell, so the process gets its old data back
instead of the zeroes it has written, until that folio is reclaimed.

Invalidate the zswap entries in the zero-filled case as well. The folio
is locked and in the swap cache, which keeps zswap writeback away.

Fixes: 0ca0c24e3211 ("mm: store zero pages to be swapped out in a bitmap")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Josef Bacik <josef@toxicpanda.com>
Signed-off-by: David Hildenbrand (Arm) <david@kernel.org>
[kasong@tencent.com: fix zswap_invalidate() arguments]
Reviewed-by: Johannes Weiner <hannes@cmpxchg.org>
Reviewed-by: Nhat Pham <nphamcs@gmail.com>
Reviewed-by: Yosry Ahmed <yosry@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/page_io.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/mm/page_io.c b/mm/page_io.c
index c6824fcd483e..65681eed9c80 100644
--- a/mm/page_io.c
+++ b/mm/page_io.c
@@ -224,7 +224,17 @@ int swap_writeout(struct swap_io_ctx *ctx, struct folio *folio)
 	 * acquired internally by swap_zeromap_folio_set/clear.
 	 */
 	if (is_folio_zero_filled(folio)) {
+		swp_entry_t entry = folio->swap;
+
 		swap_zeromap_folio_set(folio);
+
+		/*
+		 * The folio may have been stored in zswap before and dirtied
+		 * again while it stayed in the swap cache. Drop the old copy,
+		 * or zswap writeback would bring it back into the swap cache.
+		 */
+		zswap_invalidate(swp_type(entry), swp_offset(entry),
+				 folio_nr_pages(folio));
 		goto out_unlock;
 	}
 

-- 
2.56.0

