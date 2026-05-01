From: Kairui Song <kasong@tencent.com>
Subject: [PATCH RFC 00/32] mm/mglru: MGLRU-FG and refault distance support
Date: Sat, 02 May 2026 05:03:46 +0800
Message-Id: <20260502-mglru-fg-v1-0-913619b014d9@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDEyMT3dz0nKJS3bR0XYukJAtTo9Q0CyODNCWg8oKi1LTMCrBR0UpBbs5
 KsRDB4tKkrNTkEpAhSrW1AJ2j1E5xAAAA
X-Change-ID: 20260424-mglru-fg-8bb852ef820f
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Youngjun Park <youngjun.park@lge.com>, 
 Zi Yan <ziy@nvidia.com>, Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Nico Pache <npache@redhat.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SeongJae Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, 
 Chen Ridong <chenridong@huaweicloud.com>, Tal Zussman <tz2294@columbia.edu>, 
 Kairui Song <ryncsn@gmail.com>, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777669448; l=7590;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=DBOpIru7jqacweorBAeXDkuyacrHQhA4NDUgZl7zFQ0=;
 b=1KI9TPY28o+QlUdOb0aHnPYcmh5Khm9aqozsCx0JrNb1IBSBovc+nlEFzVo52Jle+W0+f5u8E
 V29tnRKWiYCCgFwOUtd2uQJvr2ZwYxL0wUy1u9+4JQFwQkKJznMKnat
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is an RFC following the idea proposed as LSFMMBPF topic [1] this
year for demonstrating the design and improvements, sending it out so it
can be discussed better before or after the event. It's stable and
performing well, but obviously, it's too long for review, so I plan to
send these out step by step if we are OK with the basic ideas here.
Worth noting that the design is still not finalized yet, the tier and
refault calculation can still be better adjusted, and with more
benchmarking and testing. This is rebased on top of the current
mm-unstable as it is supposed to work on top of another series which is
currently there [4].

With this series, I'm seeing an obviously performance gain for tests
like GET/SCAN with LevelDB (which is borrowed from Tal's paper [2])
and MongoDB with TPCC [3] or YCSB [4]:

GET/SCAN LevelDB [2]:
Classical LRU: throughput_avg: 993.64 Ops/s
MGLRU before:  throughput_avg: 951.12 Ops/s
MGLRU after:   throughput_avg: 1344.72 Ops/s (+41% faster)

MongoDB YCSB workloadb (MGLRU):
Before: 82127.65 ops/sec
After:  95933.99 ops/sec (+16.8%)

Build kernel test (MGLRU):
Before: refault_file: 259681   refault_anon: 3006202  real: 1m49.005s
After:  refault_file: 201472   refault_anon: 3048107  reaL: 1m49.050s

FIO with zipf:
Before: 73557.72 MB/s
After:  74553.44 MB/s

Also, mechanisms like PSI, smap, readahead, will all have better
accuracy since this series unified the flag usage between classical
LRU and MGLRU.

This also reduces MGLRU's max flag usage by one, and hopefully provides
a generic API for other components like DAMON to contribute to MGLRU's
hotness tracking.

Other tests like the MySQL are looking fine, no regression. Filesearch
test in [2] also shows some improvement, not comparable to cache_ext, since
this still need to rely on things like the refault distance to establish a
pattern before it takes any effect, but more generic.

This series basically composed of three parts:

1) Make the MGLRU be frequency guided and rework MGLRU's flag format
   to shrink the bit usage. The format rework and MGLRU-FG design is
   strongly bound togther with 2) below.

   The main patch implementing MGLRU-FG is:
   mm/mglru: frequency guided workingset promotion (MGLRU-FG)

2) Convert all workingset / referenced flag user to use the new generic
   LRU refs API introduced by above.

3) Refault distance support for MGLRU.

   Refault distance refactor and support starts with:
   mm/workingset: simplify and use a more intuitive model

Step 1) and 2) are working well. But the overhead from 3) is still having
slightly higher than expected overhead (dozens of more atomic operations
upon refault, and an extra rstat flush, which is just like classical LRU),
and not a fully optimized work, so I'm still looking into it.

More detailes are in the commit message.

It's recommaneded to test it seperately for these three parts. Sending as
a long whole series to avoid conflict and provide a complete view of the
ongoing project.

NOTE for an RFC quality series: several helpers like folio_mark_referenced
might need further improvement, currently the implementation may lead to
inaccurate hotness info, only in theory and doesn't seems a new issue, but
could be improved easily later.

And the page flag removal can be decoupled from the workingset series easily.

Link: https://lore.kernel.org/linux-mm/CAMgjq7BoekNjg-Ra3C8M7=8=75su38w=HD782T5E_cxyeCeH_g@mail.gmail.com/ [1]
Link: https://dl.acm.org/doi/10.1145/3731569.3764820 [2]
Link: https://lwn.net/Articles/945266/ [3]
Link: https://lore.kernel.org/linux-mm/20260428-mglru-reclaim-v7-0-02fabb92dc43@tencent.com/ [4]

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Kairui Song (32):
      mm/memcontrol: make lru_zone_size atomic and simplify sanity check
      mm/memcontrol: allow update of LRU statistic without holding LRU lock
      mm/mglru: wrap all access to folio flags with accessor
      mm/mglru: introduce and use helpers for updating lru_gen refs and gen
      mm/mglru: make generation page counters atomic
      mm/mglru: frequency guided workingset promotion (MGLRU-FG)
      mm/mglru: don't reset folios LRU refs count on protection by default
      mm: make folio lru referenced times count a generic API
      mm: replace folio_set_workingset with folio_mark_workingset
      mm: replace folio_test_workingset with folio_is_workingset
      mm/smap: report workingset folios as referenced
      mm/huge_memory: mark file folio as accessed more accurately on split
      mm/khugepaged: consider workingset folios as referenced
      mm: convert rest folio LRU referenced usages to new helpers
      mm/gup: use new helpers for marking folios as referenced
      mm: convert folio referenced flag usages to new bitwise identical helpers
      mm/shmem: mark folio as referenced use new helper
      mm/vmscan: convert to new bitwise identical helper
      mm/madvise: convert to new lru refs API and better support for MGLRU
      mm/damon: don't clear the lruref for MGLRU
      mm/swap: convert to new bitwise identical helper
      mm/workingset: simplify and use a more intuitive model
      mm/workingset: rename the nonresistence age counter
      mm/workingset: use a single atomic operation for read and age
      mm/workingset, lru_gen: simplify lru_gen recent
      mm/workingset: properly define the format of a folio shadow
      mm/workingset: move refault distance checking into a helper
      mm/workingset: split lruvec retrieving and flush into a helper
      mm/mglru: convert avg_total and avg_refaulted to atomic
      mm/mglru, workingset: apply refault-distance based re-activation
      mm: remove PG_workingset
      mm: remove PG_referenced

 fs/btrfs/compression.c                 |   3 +-
 fs/erofs/zdata.c                       |   3 +-
 fs/fuse/dev.c                          |   2 -
 fs/proc/page.c                         |   1 -
 fs/proc/task_mmu.c                     |  22 +-
 include/linux/memcontrol.h             |   9 +-
 include/linux/mm.h                     |   2 +-
 include/linux/mm_inline.h              | 257 ++++++++++---
 include/linux/mmzone.h                 | 113 ++++--
 include/linux/page-flags.h             |  13 +-
 include/linux/swap.h                   |   2 -
 include/trace/events/mmflags.h         |   2 -
 include/uapi/linux/kernel-page-flags.h |   1 -
 kernel/bounds.c                        |   2 +-
 mm/damon/paddr.c                       |   3 +-
 mm/filemap.c                           |  12 +-
 mm/gup.c                               |   6 +-
 mm/huge_memory.c                       |  12 +-
 mm/khugepaged.c                        |   6 +-
 mm/madvise.c                           |  37 +-
 mm/memcontrol.c                        |  22 +-
 mm/migrate.c                           |   4 -
 mm/page_io.c                           |   3 +-
 mm/readahead.c                         |   8 +-
 mm/shmem.c                             |   2 +-
 mm/slub.c                              |   2 +-
 mm/swap.c                              | 109 ++++--
 mm/vmscan.c                            | 189 +++++-----
 mm/workingset.c                        | 666 ++++++++++++++++++---------------
 tools/mm/page-types.c                  |   1 -
 30 files changed, 916 insertions(+), 598 deletions(-)
---
base-commit: 2ed06bf65cef2e7b763ce59a9fc2e4a42ecfa1ce
change-id: 20260424-mglru-fg-8bb852ef820f

Best regards,
--  
Kairui Song <kasong@tencent.com>

