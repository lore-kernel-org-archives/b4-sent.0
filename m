From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v3 00/18] mm/huge_memory: clean up folio split and lift
 swapcache split limits
Date: Fri, 21 Aug 2026 02:55:13 +0800
Message-Id: <20260821-swap-thp-cleanup-v3-0-9b43f5163238@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23NQQ7CIBQE0KsY1mIoNAiuvIdxQX9/LUYpKbRqm
 t5dqDHR6HKSmTcTCdhbDGS3mkiPow22cymI9YpAa9wJqa1TJpxxyRQrabgZT2PrKVzQuMFTCcg
 rlNCISpE08z029r6Qh+Mrh6E6I8Ts5EZrQ+z6x/I5Frn35tUvPxaUUam0FtpsAUDsIzpAFzfQX
 Uk+GPkHUYg/BE9EzRFLBdKYUn8T8zw/AVZVQ/UHAQAA
X-Change-ID: 20260804-swap-thp-cleanup-6ce2be6cf3b8
To: linux-mm@kvack.org
Cc: linux-kernel@vger.kernel.org, Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Zi Yan <ziy@nvidia.com>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Nico Pache <nico.pache@linux.dev>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Chris Li <chrisl@kernel.org>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <baoquan.he@linux.dev>, 
 Barry Song <baohua@kernel.org>, Youngjun Park <youngjun.park@lge.com>, 
 Shivam Kalra <shivamkalra98@zohomail.in>, Kairui Song <kasong@tencent.com>, 
 Kairui Song <ryncsn@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787252124; l=4769;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=Nh1z2UMuz3wh/KOtpGfftf3doRz64lPxSzA8cbjdwuA=;
 b=yuRxAZ3eMnSIl1AX9oYRxwJpXwdFu7d8viw+AtghVUYmcdBh3bpPBdg5oGD5KajA4RSoWK8/4
 QZsZbaj+4ynAqZ27x9MHKAmey8lmqfJ/PlVipt0/y1gzrEIBwiRLahO
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series clean up the split code, add better swap cache split support
for mappingless, large order, uniform and non-uniform split.  Generic
performance is on par or slightly better, and stack usage is reduced.

The swap cache infrastructure can handle non-uniform or high order folio
replace, so there is no reason for either restriction from the THP side.
What stands in the way is the mixed anon/file folio split routine,
which makes lifting the restrictions hard to follow, and it already
carries some buggy or redundant checks.

So this series cleans up the split path and separates anon and file
splitting into two helpers.  The file split path never sees a swap
cache folio, and that is now enforced up front: a folio that is both
in the page cache and the swap cache can only be a shmem folio, which
remains unsupported and is rejected early.  That helps to rule out swap
cache handling in that part completely.  Only the anon split path
handles swap cache folios, with an anon mapping or mappingless:
either way the splitting is similar, and non-uniform split is
supported as well.

Order-1 is still forbidden for swap cache splitting.  In theory it is
doable for shmem swap cache folios, but a mappingless swap cache
folio cannot currently be told apart from a shmem one, so forbid it
for all swap cache folios for now.

Testing:

The in-tree split_huge_page_test selftest (uniform, non-uniform and
in-folio-offset splits of anon and pagecache folios) passes 62/62 on
the patched kernel.

ftrace function_graph tracing filtered on __folio_split() was used to
compare per-call durations between the base and the patched kernel on
the same x86-64 box (interleaved runs across alternating reboots;
135 split calls per run, 50 test run):

Before: 67.9 us, stddev: 1.59
After:  66.4 us, stddev: 1.19

The patched kernel is slightly faster. The stack usage is also reduced
by about ~10%, with a very slight growth of huge_memory.o.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Changes in v3:
- Get rid of for_each_folio_safe and open code it.
- Check if the folio is mapped before freeing it swap cache to avoid
  potential performance lose.
- Initial test and binary analyze showed everything is very similiar to
  previously series.
- Drop the redundant mapping argument of __split_frozen_folio
- Link to v2: https://patch.msgid.link/20260813-swap-thp-cleanup-v2-0-d2ee48c6aa49@tencent.com

Changes in v2:
- Return -EBUSY instead of -EINVAL for swap cache & shmem folio split
  attempt.
- Introduce a for_each_folio_safe macro to dedupliate the code and
  hightlight the reason we need to keep the iterate safe from folio
  freeing. [ Zi Yan ]
- Rename __split_unmapped_folio() to __split_frozen_folio [ Zi Yan ]
- Rename __folio_freeze_split_unmap_anon. [ Zi Yan ]
- Several comment improments [ Zi Yan ]
- Drop an unused do_lru argument.
- Previouse test results are basically unchanged, stack usage reduced,
  object very slightly larger.
- Link to v1: https://patch.msgid.link/20260808-swap-thp-cleanup-v1-0-689939a7ccc3@tencent.com

---
Kairui Song (18):
      mm/swap: fix off-by-one in swap cache replace sanity check
      mm/huge_memory: fix rejection of swap cache folios with a mapping
      mm/huge_memory: invert folio_ref_freeze() check to reduce indentation
      mm/huge_memory: split the routine for splitting anon and file folio
      mm/huge_memory: rename __split_unmapped_folio() to __split_frozen_folio()
      mm/huge_memory: consolidate irq and locking for folio split
      mm/huge_memory: move EOF trimming into the file split helper
      mm/huge_memory: move unmap and remap into the split helpers
      mm/huge_memory: move anon_vma and filemap management into split helpers
      mm/huge_memory: move memcg switch into the file split helper
      mm/huge_memory: allow splitting mappingless swap cache folios
      mm/huge_memory: add kerneldoc for the split helpers
      mm/huge_memory: drop the unused do_lru argument of the file split helper
      mm/huge_memory: clean up after-split folio freeing in __folio_split
      mm/huge_memory: lift order-0 restriction for swapcache split
      mm/huge_memory: clarify supported split orders in comment
      mm/huge_memory: count only swap cache refs in anon folio split
      mm/huge_memory: drop the redundant mapping argument of __split_frozen_folio

 mm/huge_memory.c | 633 +++++++++++++++++++++++++++++--------------------------
 mm/swap_state.c  |   3 +-
 2 files changed, 338 insertions(+), 298 deletions(-)
---
base-commit: 4b2ae13f3393ef4b4bce0021e8762790354f369f
change-id: 20260804-swap-thp-cleanup-6ce2be6cf3b8

Best regards,
--  
Kairui Song <kasong@tencent.com>

