From: Kairui Song <kasong@tencent.com>
Subject: [PATCH RFC 00/15] mm/mglru: frequency guided promotion (MGLRU-FG)
 and flag cleanup
Date: Tue, 04 Aug 2026 03:46:56 +0800
Message-Id: <20260804-mglru-fg-v1-0-4d8dad39dad6@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyMj3dz0nKJS3bR0XeNEo2QLU3MTcyPTJCWg8oKi1LTMCrBR0UpBbs5
 KsRDB4tKkrNTkEpAhSrW1AGpFfCRxAAAA
X-Change-ID: 20260722-mglru-fg-3a2c8574725b
To: linux-mm@kvack.org
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
 SeongJae Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Chen Ridong <chenridong@xiaomi.com>, 
 Tal Zussman <tz2294@columbia.edu>, Kairui Song <ryncsn@gmail.com>, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785786439; l=8628;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=Sdrv3XemOx1Vo85/fr08UdLOt06D3fX3iVkJqHAzPqk=;
 b=Kyl0bfXZNTA7MNrQdLsqI9g7PxvrQNUUQ7t9uTfxl8vivX1Fo7HBfZ03Nf7DkDWHJKCbEVVo0
 DciY22taQ1XDsHYkl8uyRcG5NFk3V028B9MMHSM6oISljClHa740cGc
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the updated RFC following the idea proposed at LSF/MM/BPF [1] this
year. It's very usable, stable, and performing well, but I'll keep it RFC
for V1 as some tests are still ongoing and results can be more accurate
with further auditing.

With this series, I'm seeing an obvious performance gain across all kinds
of tests, and it reduces MGLRU's flag usage by one. It also fixes several
long-standing issues including under-accounted PSI and poor workingset
tracking (especially for page cache).

Some test results (CLRU means classical LRU):

Build kernel test, running make -j48 in a 3G memcg, using disk swap and
holding the kernel and build output on the same NVMe drive, 16 runs using
different swappiness configurations [2]; the patched version is better than
mainline at almost every swappiness value, measuring the total average:

        real     sys  pgpgin  pswpin  pswpout  refault_file  refault_anon
CLRU   6m06s  31m01s   50.3M   3.20M    13.8M         10.3M         3.35M
Before 2m56s  11m06s   10.6M   1.59M    5.40M          414k         1.03M
After  2m49s  10m39s    9.0M   1.36M    4.82M          280k          861k
delta    -7s    -27s    -15%    -14%     -11%          -32%          -16%

MongoDB YCSB workloadb (recordcount:20000000 operationcount:6000000,
threads:48, in a 16G memcg), 3 runs [3]:
CLRU:          98389.94 ops/s
MGLRU Before:  86421.44 ops/s
MGLRU After:   95378.50 ops/s (+10.3%)

Chromium & Node.js test, using ZRAM as swap, on a 48c96t machine with
128G memory, 64 workers, run for 1 hour [4]:
                 Total requests:
CLRU:                     63822
MGLRU Before:            153029
MGLRU After:             225664 (+47.4%)

(NOTE: It seems some recent change broken MGLRU's fainress guarteen and
also made this test dramatically faster than a few months ago, which isn't
related to this series and reading are even better now, but I'll take a
deeper look later.)

FIO, zipf 0.9 distribution on an NVMe disk, in a 16G cgroup, total file
size 40G; this measures the LRU's theoretical ability to distinguish the
hotter portion:

fio --name=fg --numjobs=16 --nrfiles=1 \
    --filename_format="$testdir/rnvmedk.\$jobnum.img" \
    --size=${FILE_MIB}M \
    --buffered=1 --ioengine=sync --rw=randread \
    --random_distribution=zipf:$ZIPF --bs=$BS --time_based \
    --ramp_time=45s --runtime=600s \
    --group_reporting

CLRU:   Avg: 2454.37 MB/s
Before: Avg: 2350.40 MB/s
After:  Avg: 2611.37 MB/s (+11.1%)

I also retested the LevelDB benchmark from the cache_ext paper [5].
Interestingly, mainline MGLRU already beats CLRU on this one after a
recent change in lru_gen_folio_seq that bumps new folios with refs == 1
to the second-oldest generation. That change accidentally gave random
reads a higher hotness level while making sequential reads much colder:
sequential reads involve many readahead hits, and readahead folios start
with refs == 0, so they're already in the oldest generation, and
folio_mark_accessed() on a readahead hit has almost no effect on generations
in mainline MGLRU. Meanwhile, all direct-hit (random read) folios start
with refs == 1 in the second-oldest generation. As a result, the scan-get
test natively protects the "get" part and sacrifices the "scan" part.
That's not the best solution though. It's unreliable because it depends
on LRU drain timing, and it hurts workloads where the sequential part is
actually hotter (any workload involving a hotter large file and many
small cold files will be affected).

This series improves on that base: it covers ordinary workloads without
hurting the scan-get workload and without relying on that initial bump.

LevelDB Scan / Get, Throughput Total:
CLRU:         4668.8 ops/s
MGLRU:        5026.9 ops/s (faster than CLRU, but hurts other workloads)
MGLRU After:  5029.7 ops/s (fastest in all cases, and no regression)

The hot-sequential and cold-random workload can be easily reproduced with
SQLite and grep. SQLite continuously scans and looks up a small hot
portion of a DB file, while grep iterates over a set of small files much
larger than RAM [6]:

         SQLite scan & lookup time:       Grep iterate time:
CLRU:                       14.51ms               13281.37ms
MGLRU mainline:            567.05ms               13694.47ms
MGLRU After this series:    10.58ms               12930.43ms

The grep cold portion is larger than RAM and accessed only once per
iteration, so there's no promotion of any of it. CLRU handles
this reasonably; mainline MGLRU has a clear regression; MGLRU-FG now
not only recovers but is able to catch some hot parts from the cold grep
workload. This test is somewhat subjective, but the signal is clear.

Additionally, PSI, smaps, and readahead all benefit from better accuracy
since this series unifies the flag usage between classical LRU and MGLRU.

Other tests such as MySQL are looking fine, with no regressions.

Refault distance is not included yet, so MGLRU may respond more slowly to
workingset shifts. That can be added later, as previously demonstrated
[7], [8].

Extra note about future development: this series is highly compatible with
ideas like workingset reporting [9]. The "gen climbing folio" design may
appear to conflict with workingset reporting's idea of using generations
as access-gap identifiers, but it doesn't — the solution is
straightforward: once we can extend the generation number to a larger
value (e.g. 64 or 128), the refs-driven promotion can stop at a lower
gen (e.g. oldest_gen + 16), leaving the remaining newer generations as
perfectly time-gap-separated bins.

The tier count is not fixed either; we'll need to find a way to tune it
if tiers go beyond 4, but that shouldn't be hard.

More details are in the individual commit messages.

Link: https://lore.kernel.org/linux-mm/CAMgjq7BoekNjg-Ra3C8M7=8=75su38w=HD782T5E_cxyeCeH_g@mail.gmail.com/ [1]
Link: https://lore.kernel.org/linux-mm/CAGsJ_4xre-x0e+qNVm=KLFnO1dbPkPX5RuecqwvTZu-vS+o8yQ@mail.gmail.com/ [2]
Link: https://github.com/brianfrankcooper/YCSB/blob/master/workloads/workloadb [3]
Link: https://lore.kernel.org/all/20221220214923.1229538-1-yuzhao@google.com/ [4]
Link: https://dl.acm.org/doi/10.1145/3731569.3764820 [5]
Link: https://github.com/ryncsn/emm-test-project/tree/master/sqlite-grep [6]
Link: https://lwn.net/Articles/945266/ [7]
Link: https://lore.kernel.org/linux-mm/20260502-mglru-fg-v1-0-913619b014d9@tencent.com/ [8]
Link: https://lwn.net/Articles/976985/ [9]

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Kairui Song (15):
      mm/memcontrol: make lru_zone_size atomic and simplify sanity check
      mm/memcontrol: allow update of LRU statistic without holding LRU lock
      mm/mglru: introduce and always use helpers for manipulating page flags
      mm/mglru: make generation page counters atomic
      mm/mglru: move max_seq read into walk_update_folio
      mm/mglru: use explicit tier range in read_ctrl_pos()
      mm/mglru: move refault workingset activation into lru_gen_refault
      mm/memcg: add folio-based lruvec live helper
      mm/mglru: frequency guided workingset promotion (MGLRU-FG)
      mm/mglru: make folio lru referenced times count a generic API
      mm/mglru: replace folio workinset check and update with new helper
      mm/smap: report workingset folios as referenced
      mm/huge_memory: mark file folio as accessed more accurately on split
      mm/khugepaged: consider workingset folios as referenced
      mm/madvise: convert to new lru refs API and better support for MGLRU

 fs/btrfs/compression.c     |   3 +-
 fs/proc/task_mmu.c         |  22 ++-
 include/linux/memcontrol.h |  47 +++++-
 include/linux/mm_inline.h  | 256 ++++++++++++++++++++++++++------
 include/linux/mmzone.h     | 137 ++++++++++++-----
 kernel/bounds.c            |   2 +-
 mm/filemap.c               |   8 +-
 mm/folio.c                 |  49 +-----
 mm/huge_memory.c           |   8 +-
 mm/khugepaged.c            |   6 +-
 mm/madvise.c               |  37 +++--
 mm/memcontrol.c            |  22 +--
 mm/migrate.c               |   4 -
 mm/page_io.c               |   3 +-
 mm/readahead.c             |   8 +-
 mm/vmscan.c                | 360 ++++++++++++++++++++++++++++-----------------
 mm/workingset.c            |  66 ++++++---
 17 files changed, 689 insertions(+), 349 deletions(-)
---
base-commit: 94f9b3980dd446b56acf1dfed649e9b32a9f3813
change-id: 20260722-mglru-fg-3a2c8574725b

Best regards,
--  
Kairui Song <kasong@tencent.com>

