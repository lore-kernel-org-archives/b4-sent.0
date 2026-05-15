From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v4 00/12] mm, swap: swap table phase IV: unify allocation
 and reduce static metadata
Date: Fri, 15 May 2026 17:54:13 +0800
Message-Id: <20260515-swap-table-p4-v4-0-f1b49e845a8d@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2XPQQ6CMBCF4auQrq3pDIVSV97DuChlkCYKhJKqI
 dzdggsVl2+S709mYp4GR54dkokNFJx3XRuH3CXMNqa9EHdV3AwF5gIAuL+bno+mvBLvJdcFkcb
 SGGUli6YfqHaPtXc6x904P3bDc80HWK7vEqLYlAJwwUFIpbMKdAHZcaTWUjvubXdjSyvgx0tQW
 4+LV3XUAjKJxb9PvzxuPwlp9FhjqjJtVF7aXz/P8wuoTi2wLAEAAA==
X-Change-ID: 20260111-swap-table-p4-98ee92baa7c4
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Zi Yan <ziy@nvidia.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Barry Song <baohua@kernel.org>, 
 Hugh Dickins <hughd@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Youngjun Park <youngjun.park@lge.com>, 
 Chengming Zhou <chengming.zhou@linux.dev>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>, Lorenzo Stoakes <ljs@kernel.org>, 
 Yosry Ahmed <yosry@kernel.org>, Qi Zheng <qi.zheng@linux.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778838859; l=6356;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=BzTfwZUHtgNuqb5kM5h8jWNl9TZuFWWrTO/8ZiO5hi8=;
 b=/z+CporQVOPlwE8qWqtM/px6qF000ZygbqyZO29u6WegtlV8G0t7mj9M34l1uTmVuBiLbS8cv
 SyWBheMxXesCx00/nOjBdY1LPrLy7/Y0+h3eFO4VeJI4Qo/K2brv0tk
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kairui Song <kasong@tencent.com>

This series unifies the allocation and charging of anon and shmem swap
in folios, provides better synchronization, consolidates the metadata
management, hence dropping the static array and map, and improves the
performance. The static metadata overhead is now close to zero, and
workload performance is slightly improved.

For example, mounting a 1TB swap device saves about 512MB of memory:

Before:
free -m
          total   used      free   shared   buff/cache   available
Mem:       1464    805       346        1          382         658
Swap:   1048575      0   1048575

After:
free -m
          total   used      free   shared   buff/cache   available
Mem:       1464    277       899         1         356        1187
Swap:   1048575      0   1048575

Memory usage is ~512M lower, and we now have a close to 0 static
overhead. It was about 2 bytes per slot before, now roughly 0.09375
bytes per slot (48 bytes ci info per cluster, which is 512 slots).

Performance test is also looking good, testing Redis in a 2G VM using
6G ZRAM as swap:

valkey-server --maxmemory 2560M
redis-benchmark -r 3000000 -n 3000000 -d 1024 -c 12 -P 32 -t get

Before: 3385017.283654 RPS
After:  3433309.307292 RPS (1.42% better)

Testing with build kernel under global pressure on a 48c96t system,
limiting the total memory to 8G, using 12G ZRAM, 24 test runs,
enabling THP:

make -j96, using defconfig

Before: user time 2904.59s system time 4773.99s
After:  user time 2909.38s system time 4641.55s (2.77% better)

Testing with usemem on a 32c machine using 48G brd ramdisk and 16G
RAM, 12 test run:

usemem --init-time -O -y -x -n 48 1G

Before: Throughput (Sum): 6482.58 MB/s Free Latency: 371371.67us
After:  Throughput (Sum): 6539.28 MB/s Free Latency: 363059.88us

Seems similar, or slightly better.

This series also reduces memory thrashing, I no longer see any:
"Huh VM_FAULT_OOM leaked out to the #PF handler. Retrying PF", it was
shown several times during stress testing before this series when under
great pressure:

Before: grep -Ri VM_FAULT_OOM <test logs> | wc -l => 18
After:  grep -Ri VM_FAULT_OOM <test logs> | wc -l => 0

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Changes in v4:
- Rebased on latest mm-unstable and re-test, benchmark results are
  basically the same so mostly kept unchanged. Changes in v4 are code
  style and very minor behavior change.
- Improve a few commit messages, rename a few variables as suggested by
  [ Chris Li ].
- Rename thp_limit_gfp_mask to thp_shmem_limit_gfp_mask as suggested by
  [ Zi Yan ].
- Cleanup a few allocation and code style issue [ YoungJun Park ]
- Remove the forced fallback in swap_cache_alloc_folio, the caller will
  pass in the exact orders to be used. [ Baolin Wang ]
- Rename swapin_entry to swapin_sync, it's only used by synchronization
  devices at this moment and describes what it does better
  [ David Hildenbrand ]
- Link to v3: https://patch.msgid.link/20260421-swap-table-p4-v3-0-2f23759a76bc@tencent.com

Changes in v3:
- This is based on mm-unstable, also applies to mm-new, and has no
  conflict with YoungJun's tier series, and only trivial conflict with
  Baoquan's swapops due to filename change.
- Fix zero map build issue on 32 bit archs [ YoungJun Park ]
- Cleanup memcg table allocation helpers [ YoungJun Park ]
- Fix WARN for non NUMA build:
  https://lore.kernel.org/linux-mm/CAMgjq7ANih7u7SJB8uWcQHS8XRJySNRc3ti9V-SVey0nGE3gLQ@mail.gmail.com/
- Improve of commit messages.
- Re-test several tests, the conclusion is the same as v2.
- Link to v2: https://patch.msgid.link/20260417-swap-table-p4-v2-0-17f5d1015428@tencent.com

Changes in v2:
- Drop the RFC prefix and also the RFC part.
- Now there is zero change to cgroup or refault tracking, RFC v1 changed
  some cgroup behavior. To archive that v2 use a standalone memcg_table
  for each cluster. It can be dropped or better optimized later if we
  have a better solution. The performance gain is partly cancelled
  compared to RFC v1 since we now need an extra allocation for free cluster
  isolation and peak memory usage is 2 bytes higher. But still looking
  good. That table size is accetable (1024 bytes), no RCU needed, and
  fits for kmalloc. Even if we keep it as it is in the future,
  it's still accetable.
- Link to v1: https://lore.kernel.org/r/20260220-swap-table-p4-v1-0-104795d19815@tencent.com

---
Kairui Song (12):
      mm, swap: simplify swap cache allocation helper
      mm, swap: move common swap cache operations into standalone helpers
      mm/huge_memory: move THP gfp limit helper into header
      mm, swap: add support for stable large allocation in swap cache directly
      mm, swap: unify large folio allocation
      mm/memcg, swap: tidy up cgroup v1 memsw swap helpers
      mm, swap: support flexible batch freeing of slots in different memcgs
      mm, swap: delay and unify memcg lookup and charging for swapin
      mm, swap: consolidate cluster allocation helpers
      mm/memcg, swap: store cgroup id in cluster table directly
      mm/memcg: remove no longer used swap cgroup array
      mm, swap: merge zeromap into swap table

 MAINTAINERS                 |   1 -
 include/linux/huge_mm.h     |  30 +++
 include/linux/memcontrol.h  |  16 +-
 include/linux/swap.h        |  19 +-
 include/linux/swap_cgroup.h |  47 ----
 mm/Makefile                 |   3 -
 mm/huge_memory.c            |   2 +-
 mm/internal.h               |  11 +-
 mm/memcontrol-v1.c          |  66 ++++--
 mm/memcontrol.c             |  31 ++-
 mm/memory.c                 |  88 ++------
 mm/page_io.c                |  61 +++++-
 mm/shmem.c                  | 123 +++--------
 mm/swap.h                   |  91 +++-----
 mm/swap_cgroup.c            | 174 ---------------
 mm/swap_state.c             | 519 +++++++++++++++++++++++++-------------------
 mm/swap_table.h             | 179 ++++++++++++---
 mm/swapfile.c               | 215 +++++++++---------
 mm/vmscan.c                 |   2 +-
 mm/zswap.c                  |  25 +--
 20 files changed, 800 insertions(+), 903 deletions(-)
---
base-commit: 444fc9435e57157fcf30fc99aee44997f3458641
change-id: 20260111-swap-table-p4-98ee92baa7c4

Best regards,
--  
Kairui Song <kasong@tencent.com>

