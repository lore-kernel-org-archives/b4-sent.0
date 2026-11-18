From: Kairui Song <kasong@tencent.com>
Date: Thu, 19 Nov 2026 05:03:37 +0800
Subject: [PATCH v5 05/17] mm/mglru: skip the flags cmpxchg when nothing
 changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-mglru-fg-v5-5-9eee2fe97a2d@tencent.com>
References: <20261119-mglru-fg-v5-0-9eee2fe97a2d@tencent.com>
In-Reply-To: <20261119-mglru-fg-v5-0-9eee2fe97a2d@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <qi.zheng@linux.dev>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Chris Li <chrisl@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Nhat Pham <nphamcs@gmail.com>, Youngjun Park <youngjun.park@lge.com>, 
 Zi Yan <ziy@nvidia.com>, Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SJ Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Chen Ridong <chenridong@xiaomi.com>, 
 Tal Zussman <tz2294@columbia.edu>, Kairui Song <ryncsn@gmail.com>, 
 Xiang Liu <liuxiang.277@bytedance.com>, 
 Ehab Ababneh <ehab.ababneh@intel.com>, 
 Zhao Zhenzhuo <zhaozhengzhuo@uniontech.com>, 
 Lian Wang <lianux.mm@gmail.com>, Joanne Koong <joannelkoong@gmail.com>, 
 Kunwu Chan <kunwu.chan@gmail.com>, Hui Zhu <hui.zhu@linux.dev>, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 damon@lists.linux.dev, linux-doc@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795035819; l=3975;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=rKjtT9cTVQE3kB+eFzFZdlThrfxXKVi5B+1GEDGHtjw=;
 b=eXy1GT3doCWx4eA2MrHyusXF+V13z0BHWbZolJceGwJbmMtsa+zI9QRCGuCTBY1Rom264jpeW
 FKGD+ZvzktJA6h8Yvwm38iMU9RTQym7XK1PfXQXh4ylDSTy6KSdhsZ9
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Ridong Chen <chenridong@xiaomi.com>

folio_update_gen() and folio_set_lru_refs() always end with a
try_cmpxchg() on folio->flags, even when the new value equals the old
one. The locked instruction still takes the struct page cacheline in
exclusive state.

That is common in practice: a folio mapped by many processes is visited
once per mm during a page table walk, and after the first visit it is
already in the youngest generation with refs cleared and PG_workingset
set. isolate_folio() and the eviction paths also call
folio_set_lru_refs(folio, 0) on folios whose refs are already zero.

Break out of the loop when the flags would not change. The update is
complete at the point of that read: the flags already hold the target
value, and a concurrent change to them is ordered after it. When the
cmpxchg would have succeeded, the value written is the same, so no new
state becomes reachable.

What the patch drops is the retry. A retry re-reads the flags and
recomputes new_flags from the newer value, so it overwrites a concurrent
update with what this CPU wanted. For folio_update_gen(), a walker that
read an older max_seq can lose the cmpxchg against a promotion done by
another CPU, and then write its older generation back on the retry.
folio_set_lru_refs() can likewise clear a refs increment that raced with
it. Breaking out keeps the newer state.

No caller relies on the full barrier that the locked instruction
implied on the skipped path: the eviction and isolation callers run
under the LRU lock, and the others (page table walks,
folio_mark_accessed(), lru_gen_clear_refs()) only care about the
resulting flags value, which is already in place. Note that
lru_gen_inc_refs() already returns without any atomic when refs is at
LRU_REFS_MAX and the folio is in the workingset.

Tested on an i7-13700HX with turbo disabled and the performance
governor. N processes map the same 2GiB tmpfs file (huge=never) and
read every page, then one aging pass is triggered on their memcg
through /sys/kernel/debug/lru_gen ("+ <memcg_id> 0 <max_seq> 200 1").
Time per aging pass in ms, median of 5 runs of 10 passes each, averaged
over 2 boots of each kernel:

  processes    base   patched
          1    32.9      31.7   -3.5%
          8   195.1     160.2  -17.9%
         32   755.8     592.2  -21.7%
         64  1597.2    1260.6  -21.1%

With one process, every visit changes the generation, so there is
nothing to skip. Before the patch, perf annotate attributes 53-58% of
the walk_update_folio() samples to the lock cmpxchg in the inlined
folio_update_gen() in this test.

[kasong: folio_update_gen() is replaced by folio_inc_lru_refs_walk()
later in the series, which keeps the same early exit.]
Reviewed-by: Kairui Song <kasong@tencent.com>
Signed-off-by: Ridong Chen <chenridong@xiaomi.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm_inline.h | 2 ++
 mm/vmscan.c               | 2 ++
 2 files changed, 4 insertions(+)

diff --git a/include/linux/mm_inline.h b/include/linux/mm_inline.h
index 46beded51c7d..2571b3f01226 100644
--- a/include/linux/mm_inline.h
+++ b/include/linux/mm_inline.h
@@ -233,6 +233,8 @@ static inline void folio_set_lru_refs(struct folio *folio, unsigned int refs)
 	do {
 		new_flags = old_flags;
 		lru_set_refs_flags(&new_flags, refs);
+		if (new_flags == old_flags)
+			break;
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 }
 
diff --git a/mm/vmscan.c b/mm/vmscan.c
index 8d14831cdf83..0f24b6ebc1eb 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -3274,6 +3274,8 @@ static int folio_update_gen(struct folio *folio, int new_gen, int *type,
 		lru_set_gen_flags(&new_flags, new_gen);
 		lru_set_refs_flags(&new_flags, 0);
 		new_flags |= BIT(PG_workingset);
+		if (new_flags == old_flags)
+			break;
 	} while (!try_cmpxchg(folio_flags(folio, 0), &old_flags, new_flags));
 
 	*type = folio_flags_is_file_lru(&old_flags);

-- 
2.56.1

