From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v3 00/12] mm, swap: swap table phase IV: unify allocation
 and reduce static metadata
Date: Tue, 21 Apr 2026 14:16:44 +0800
Message-Id: <20260421-swap-table-p4-v3-0-2f23759a76bc@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13MQQ6CMBCF4auQrq3pjMVSV97DuChlkCZaSEuqh
 nB3Cy6MLN9Lvn9ikYKjyE7FxAIlF13v8zjsCmY742/EXZM3Q4FHAQA8Ps3AR1PfiQ+S64pIY22
 MspJlMwRq3WvtXa55dy6OfXiv+QTL+y0hik0pARcchFS6bEBXUJ5H8pb8uLf9gy2thD8vQW09L
 l61WQsoJVb/fp7nDzBl7KzsAAAA
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
 Qi Zheng <zhengqi.arch@bytedance.com>, linux-kernel@vger.kernel.org, 
 cgroups@vger.kernel.org, Kairui Song <kasong@tencent.com>, 
 Yosry Ahmed <yosry@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Michal Hocko <mhocko@suse.com>, Michal Hocko <mhocko@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Axel Rasmussen <axelrasmussen@google.com>, Lorenzo Stoakes <ljs@kernel.org>, 
 Yosry Ahmed <yosry@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776752211; l=6664;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=Jq+2g/EuZYELu4Xod9IzqQhR1K4oK3YcKoIfx89cJqE=;
 b=FyXzgmWAt9uW4Er33MihGGiukxDaxaaory1YWdx32QGCDV4K61FifWvn5q/a+E8K3CgvWRXDe
 a11dpN5OL8BCSceugbN/s3X8w7x6o68iIfAxhVUVNCADC6aTjSGa+HE
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

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

Performance test is also looking good, testing Redis in a 1.5G VM using
5G ZRAM as swap:

valkey-server --maxmemory 2560M
redis-benchmark -r 3000000 -n 3000000 -d 1024 -c 12 -P 32 -t get

Before: 3289011.918750 RPS
After:  3312087.142241 RPS (0.99% better)

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

To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>
Cc: Chris Li <chrisl@kernel.org>
Cc: Kairui Song <kasong@tencent.com>
Cc: Kemeng Shi <shikemeng@huaweicloud.com>
Cc: Nhat Pham <nphamcs@gmail.com>
Cc: Baoquan He <bhe@redhat.com>
Cc: Barry Song <baohua@kernel.org>
Cc: Youngjun Park <youngjun.park@lge.com>
Cc: Johannes Weiner <hannes@cmpxchg.org>
Cc: Yosry Ahmed <yosry@kernel.org>
Cc: Chengming Zhou <chengming.zhou@linux.dev>
Cc: David Hildenbrand <david@kernel.org>
Cc: Lorenzo Stoakes <ljs@kernel.org>
Cc: Zi Yan <ziy@nvidia.com>
Cc: Baolin Wang <baolin.wang@linux.alibaba.com>
Cc: Dev Jain <dev.jain@arm.com>
Cc: Lance Yang <lance.yang@linux.dev>
Cc: Hugh Dickins <hughd@google.com>
Cc: Michal Hocko <mhocko@suse.com>
Cc: Michal Hocko <mhocko@kernel.org>
Cc: Roman Gushchin <roman.gushchin@linux.dev>
Cc: Shakeel Butt <shakeel.butt@linux.dev>
Cc: Muchun Song <muchun.song@linux.dev>
Cc: Suren Baghdasaryan <surenb@google.com>
Cc: Axel Rasmussen <axelrasmussen@google.com>
Cc: Qi Zheng <zhengqi.arch@bytedance.com>
Cc: linux-kernel@vger.kernel.org
Cc: cgroups@vger.kernel.org

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
 mm/memcontrol-v1.c          |  66 +++---
 mm/memcontrol.c             |  32 +--
 mm/memory.c                 |  88 ++------
 mm/page_io.c                |  58 ++++-
 mm/shmem.c                  | 122 +++--------
 mm/swap.h                   |  91 +++-----
 mm/swap_cgroup.c            | 172 ---------------
 mm/swap_state.c             | 516 +++++++++++++++++++++++++-------------------
 mm/swap_table.h             | 169 ++++++++++++---
 mm/swapfile.c               | 212 +++++++++---------
 mm/vmscan.c                 |   2 +-
 mm/zswap.c                  |  25 +--
 20 files changed, 783 insertions(+), 899 deletions(-)
---
base-commit: f1541b40cd422d7e22273be9b7e9edfc9ea4f0d7
change-id: 20260111-swap-table-p4-98ee92baa7c4

Best regards,
--  
Kairui Song <kasong@tencent.com>

