From: Kairui Song <kasong@tencent.com>
Date: Fri, 16 Oct 2026 02:16:06 +0800
Subject: [PATCH v4 17/17] Documentation/mm: multi-gen LRU: update for
 frequency guided promotion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-mglru-fg-v4-17-2106750c0bfa@tencent.com>
References: <20261016-mglru-fg-v4-0-2106750c0bfa@tencent.com>
In-Reply-To: <20261016-mglru-fg-v4-0-2106750c0bfa@tencent.com>
To: linux-mm@kvack.org, "Liam R. Howlett" <liam@infradead.org>, 
 SJ Park <sj@kernel.org>
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <qi.zheng@linux.dev>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Chris Li <chrisl@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, Zi Yan <ziy@nvidia.com>, 
 Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 David Rientjes <rientjes@google.com>, Yu Zhao <yuzhao@google.com>, 
 Vernon Yang <vernon2gm@gmail.com>, Zicheng Wang <wangzicheng@honor.com>, 
 Chen Ridong <chenridong@xiaomi.com>, Tal Zussman <tz2294@columbia.edu>, 
 Kairui Song <ryncsn@gmail.com>, Xiang Liu <liuxiang.277@bytedance.com>, 
 Ehab Ababneh <ehab.ababneh@intel.com>, 
 zhaozhengzhuo <zhaozhengzhuo@uniontech.com>, 
 Lian Wang <lianux.mm@gmail.com>, Kunwu Chan <kunwu.chan@gmail.com>, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 damon@lists.linux.dev, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792088152; l=5953;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=H9ePyPxQfKEyJG8pjQryA22Bu9URRS7jnmN2RCV298Y=;
 b=Vb9KmjNNstGoNvaMOwNk7ofyjEq/gP8OVY3K9CwFsX4iWIUxqEgFFz0bvwWvH+Y2p0iByDKlP
 wZqWyoquQutCr8DLLctzG4RU7bhi8F6VKDcrlaEAi+LHGq3mAiOnAnb
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The design doc still describes the old tier and promotion model:

- Tiers are no longer order_base_2() of the file descriptor accesses.
  A folio's tier is derived from its referenced count, which counts
  accesses from both page tables and file descriptors.

- A young PTE no longer always promotes a folio to the newest
  generation.  The first access only moves a folio one generation
  forward if it is at the tail of its LRU, i.e., in one of the two
  oldest generations of its type, a second access promotes it, and
  executable file folios are promoted on their first access.

- The eviction no longer uses the first tier as the only baseline.
  The type is selected by comparing all tiers of each type, and a tier
  is protected by comparing it against the tiers below it.

Update the aging and eviction sections accordingly.

Assisted-by: LLM
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 Documentation/mm/multigen_lru.rst | 57 ++++++++++++++++++++++-----------------
 1 file changed, 33 insertions(+), 24 deletions(-)

diff --git a/Documentation/mm/multigen_lru.rst b/Documentation/mm/multigen_lru.rst
index 52ed5092022f..ec8744c1f42c 100644
--- a/Documentation/mm/multigen_lru.rst
+++ b/Documentation/mm/multigen_lru.rst
@@ -95,16 +95,19 @@ at most ``MAX_NR_GENS`` generations. The gen counter stores a value
 within ``[1, MAX_NR_GENS]`` while a page is on one of
 ``lrugen->folios[]``; otherwise it stores zero.
 
-Each generation is divided into multiple tiers. A page accessed ``N``
-times through file descriptors is in tier ``order_base_2(N)``. Unlike
-generations, tiers do not have dedicated ``lrugen->folios[]``. In
-contrast to moving across generations, which requires the LRU lock,
-moving across tiers only involves atomic operations on
-``folio->flags`` and therefore has a negligible cost. A feedback loop
-modeled after the PID controller monitors refaults over all the tiers
-from anon and file types and decides which tiers from which types to
-evict or protect. The desired effect is to balance refault percentages
-between anon and file types proportional to the swappiness level.
+Each generation is divided into multiple tiers. A page's tier is
+derived from its referenced count, which counts the accesses collected
+from both channels above and is capped at ``LRU_REFS_MAX``: pages
+accessed at most once are in the lowest tier, and the tiers above hold
+pages accessed at least twice. Unlike generations, tiers do not have
+dedicated ``lrugen->folios[]``. In contrast to moving across
+generations, which requires the LRU lock, updating the referenced
+count only involves atomic operations on ``folio->flags`` and
+therefore has a negligible cost. A feedback loop modeled after the PID
+controller monitors refaults over all the tiers from anon and file
+types and decides which tiers from which types to evict or protect.
+The desired effect is to balance refault percentages between anon and
+file types proportional to the swappiness level.
 
 There are two conceptually independent procedures: the aging and the
 eviction. They form a closed-loop system, i.e., the page reclaim.
@@ -122,25 +125,31 @@ and calls ``walk_page_range()`` with each ``mm_struct`` on this list
 to scan PTEs, and after each iteration, it increments ``max_seq``. For
 the latter, when the eviction walks the rmap and finds a young PTE,
 the aging scans the adjacent PTEs. For both, on finding a young PTE,
-the aging clears the accessed bit and updates the gen counter of the
-page mapped by this PTE to ``(max_seq%MAX_NR_GENS)+1``.
+the aging clears the accessed bit and bumps the referenced count of
+the page mapped by this PTE. A second access promotes the page by
+updating its gen counter to ``(max_seq%MAX_NR_GENS)+1``; the first
+access only moves a page one generation forward if it is at the tail
+of its LRU, i.e., in one of the two oldest generations of its type,
+so that the next time it becomes the oldest one, its accessed bit
+reflects whether it has been used again. Executable file pages are
+promoted on their first access, since reclaiming them causes typical
+I/O thrashing.
 
 Eviction
 --------
 The eviction consumes old generations. Given an ``lruvec``, it
 increments ``min_seq`` when ``lrugen->folios[]`` indexed by
-``min_seq%MAX_NR_GENS`` becomes empty. To select a type and a tier to
-evict from, it first compares ``min_seq[]`` to select the older type.
-If both types are equally old, it selects the one whose first tier has
-a lower refault percentage. The first tier contains single-use
-unmapped clean pages, which are the best bet. The eviction sorts a
-page according to its gen counter if the aging has found this page
-accessed through page tables and updated its gen counter. It also
-moves a page to the next generation, i.e., ``min_seq+1``, if this page
-was accessed multiple times through file descriptors and the feedback
-loop has detected outlying refaults from the tier this page is in. To
-this end, the feedback loop uses the first tier as the baseline, for
-the reason stated earlier.
+``min_seq%MAX_NR_GENS`` becomes empty. To select a type to evict from,
+it first compares ``min_seq[]`` to select the older type. If both
+types are equally old, it compares the refault percentages of all the
+tiers of each type proportional to the swappiness level. To select a
+tier to protect, it compares the refault percentage of each tier
+against that of the tiers below it. The lowest tier contains pages
+accessed at most once, which are the best bet. The eviction sorts a
+page according to its gen counter if the aging or an access has
+updated its gen counter. It also moves a page to the next generation,
+i.e., ``min_seq+1``, if the feedback loop has detected outlying
+refaults from the tier this page is in.
 
 Working set protection
 ----------------------

-- 
2.56.0

