From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v5 00/17] mm/mglru: frequency guided promotion (MGLRU-FG)
 and flag cleanup
Date: Thu, 19 Nov 2026 05:03:32 +0800
Message-Id: <20261119-mglru-fg-v5-0-9eee2fe97a2d@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/2XNy2rDMBAF0F8JWldhNHrZXeU/Qhd6jB2Vxi6SY
 1qC/71yAolLNgMX7rlzZYVyosLed1eWaU4ljUMN+m3HwskNPfEUa2YIaMAi8nP/lS+867l0GBp
 tlUXtWa1/Z+rSz23q+HHP5eI/KUyrXxunVKYx/95+zWLt3WcbUM/ZWXDgKjbRRdnWYw4TDYGGa
 R/GM1uHZ3zSVogNxUo7NKSDRxOdfaXyQQWA3FBZafBRaWWc9rF9pWpDhdlQVSkKMFZDAN+5/3R
 Zlj8lWTwhZQEAAA==
X-Change-ID: 20260722-mglru-fg-3a2c8574725b
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795035819; l=29574;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=OdUNWJ+EyxgFhT6LdW4BfSMJUPo7Z/PtZeK9lwwbJKU=;
 b=VKDwqJBBqSWuA8QM+tVFg8dWTJCf02mwhDpVDqol3njakzbDHBSKCo/Ya+0jV86QRwTi0CXlg
 Nda5BlRjRegDqLLp/aeGoPndbmTM3+hAHzAgNbAI/8B0HL8NMNLd2s0
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series implements MGLRU-FG following the idea proposed at LSF/MM/BPF
this year [1], based on current mm-new. Depending on the workload, it
improves the performance or reduces IO by roughly 10% to over 50%,
fixes multiple long-standing issues with MGLRU metrics, and drops one
page flag.

The series has been tested on multiple platforms (desktop, large server,
Android phone, x86_64 and arm64 VM boxes) covering many typical benchmarks,
databases and real applications, so far everything looks nice, with good
test reports from other individual testers too.

Different workloads may get a flat, minor or dramatic improvement, the
gain here is mostly from real improvement of LRU's ability to distinguish
the hotter workingset.

It also redefines the Active workingset metric for MGLRU, which fixes
under-accounted PSI and poor active workingset readings. Cloud
platforms like Kubernetes derive pods' working set from it and use
it to make eviction decisions, MGLRU gave an unstable one there, and
users ended up disabling MGLRU to work around it [20]. That is also
a major blocker for us to deploy MGLRU widely.

The new MGLRU-FG's design is kind of a mixture with LFU, it uses unified
access frequency to distinguish hotter folios, but it still reclaims by
generation. The generation and bounded refs together form a
"logical refs count".

Accesses increase refs. When a folio's refs reach a threshold, the folio
is promoted to the next newer gen, and promotion caps the refs at a lower
threshold. A folio with lower physical refs in a newer gen is
logically hotter than a folio in an older gen with higher physical refs.
Hence gen aging lowers all logical refs without updating every folio,
avoiding hot cache pollution at no added overhead, while greatly
extending the ref counting and hotness distinguishing ability. It also
balances page table access counting against file descriptor (FD)
access with a defined rule.

The work here is mostly just a re-explanation of MGLRU's existing
mechanisms, everything is already there, we just connect them together
in a different way.

This version is rebased and retested on top of mm-new, which includes
Barry's swappiness rework [16], and this series combines very well and
became more important after that. High swappiness now drives file reclaim
much more aggressively, making the existing PID protection very
inefficient. Meanwhile FG can promote reused file folios much more
proactively, and the build kernel test shows a significant improvement
for that case. I also observed FG performing better in generic cases
after that series, as the more proactive aging populates more gens,
which lets FG distribute folios among them more evenly [19].

Test results (CLRU means classical LRU):

Build kernel test:
==================
This test is reworked: with the recent swappiness changes, behavior
differs dramatically between setups, so it is now split into two groups,
mild swappiness under mild pressure, and extreme swappiness.

For the mild swappiness range (60/100/150), with ZRAM as swap (256G,
lzo-rle) and a clean make -j48 defconfig build from an existing source
tree on an NVMe drive in a 3G/2G memcg, the average of 2 rounds across the
three swappiness levels:

Reading with 3G memcg (lower is better):
         real       sys    pgpgin   pgpgout pgmajfault refault_file refault_anon
CLRU     1m33s   10m08s     9.76M    38.05M      1.85M         466k        1.85M
Before   1m32s    9m27s    12.56M    40.49M      2.35M         345k        2.31M
After    1m32s    9m15s    10.44M    35.74M      1.80M         347k        1.76M
delta    -0.2%    -2.1%    -16.9%    -11.7%     -23.4%        +0.4%       -23.8%

Reading with 2G memcg (lower is better):
         real       sys    pgpgin   pgpgout pgmajfault refault_file refault_anon
CLRU     1m54s   25m47s    66.35M   158.02M     15.51M        1.57M       15.52M
Before   1m54s   25m15s    75.47M   183.48M     17.33M         973k       17.17M
After    1m52s   24m00s    69.67M   171.01M     15.51M        1.19M       15.36M
delta    -2.0%    -4.9%     -7.7%     -6.8%     -10.5%       +21.8%       -10.5%

We can see the performance is better with lower sys time and total pgpgin
with the mild setup. The slight drift of the file/anon counters is mostly
swappiness balance policy differences, which looks OK to me as the total
refault and IO dropped together with the build time.

Swappiness is still respected. The extreme points below show a major
improvement with disk as swap:

Using the same setup, first with ZRAM as swap, then with an NVMe device
as disk swap:
ZRAM as swap:
        sw   real  pgpgin  pg{steal/scan}_anon  pg{steal/scan}_file {anon/file}_refault
CLRU     1  2m06s  68.70M       9.86M / 50.91M     15.14M / 25.67M  2.08M / 14.97M
       100  1m32s   8.88M       9.15M / 49.65M     562.0k / 667.9k  1.69M / 409.9k
       200  1m36s  22.35M      19.53M / 79.35M     151.1k / 227.7k  5.52M /  84.2k
Before   1  1m42s  36.95M       8.45M / 15.43M      7.02M / 15.49M  2.19M /  3.58M
       100  1m32s  11.80M       9.83M / 20.29M     780.5k / 830.1k  2.16M / 321.8k
       200  1m41s  46.04M      29.87M / 68.96M          0 /      0 11.68M /      0
After    1  1m46s  42.75M       8.84M / 15.80M      8.72M / 20.35M  1.96M /  4.54M
       100  1m32s  11.08M       9.69M / 19.64M     804.0k / 856.6k  1.95M / 364.1k
       200  1m41s  32.89M      27.00M / 57.04M       1148 /   1152  8.13M /    480

Disk as swap:
        sw   real  pgpgin  pg{steal/scan}_anon  pg{steal/scan}_file {anon/file}_refault
CLRU     1  4m23s 153.56M      10.90M / 61.31M     36.00M / 55.81M   2.43M / 35.83M
       100  3m16s   9.95M       8.22M / 52.72M     588.5k / 652.4k   1.93M / 435.3k
       200  6m19s  25.36M      20.21M / 98.19M      94.6k /  94.7k   6.30M /   9365
Before   1  3m07s  27.18M       6.41M / 11.55M      4.83M /  8.80M   1.38M /  2.53M
       100  2m56s   9.52M       6.31M / 13.75M     609.1k / 628.3k   1.26M / 251.7k
       200 10m30s  71.66M      38.59M / 92.30M          0 /      0  13.87M /      0
After    1  3m18s  33.86M       7.60M / 14.89M      7.74M / 16.41M   1.37M /  4.14M
       100  2m46s   8.94M       5.69M / 13.86M     704.1k / 741.3k   1.09M / 268.8k
       200  6m03s  30.04M      19.72M / 49.85M        194 /    194   5.00M /    142

For sw=1, pgpgin looks higher, but that is because files are reclaimed
even harder, as swappiness asks for, while the performance is still OK and
better than CLRU.

For sw=100, the reading suggests the performance is better with a better
reclaim balance: pgpgin and total refault are down with both swap
devices, and building is ~10s faster on disk swap.

At sw=200 the disk swap build goes from 10m30s to 6m03s, almost halved.
The recent swappiness fix also exposes the weakness of the PID controller,
which almost stalls the build when reclaim is aimed at file folios, while
FG promotes file folios much more proactively. This is consistent with
the pgrefill counter below (Before -> After: the PID protects
almost nothing at sw=200):

pgrefill         sw=1              sw=100            sw=200
DISK       3.78M -> 10.23M   16.02M -> 24.17M    8.17k -> 34.28M
ZRAM       6.28M -> 11.09M   22.21M -> 30.94M   5.20M -> 42.85M

Note, this may read as if reclaim efficiency dropped slightly, which is
quite the opposite: FG softens the ineffective PID factor, and the lazy
promotion filters the workingset out proactively, so the scan count
may look bigger. We are just lacking an activation counter for MGLRU to
separate the two. Unfortunately that does not fit directly as there is no
activation for MGLRU; we may discuss and improve MGLRU's statistic
counters as a follow up.

In summary: MGLRU with FG respects swappiness well and improves the
performance by a lot, with lower pgpgin and almost half the build time at
the high swappiness values. The cases where MGLRU used to fall behind CLRU
now lead as well.

FIO cached read with zipf
=========================
(This is a simplified version, fuller coverage can be seen in [17])

Using an NVMe device, in a 16G cgroup, total file size 40G, this
measures the LRU's theoretical ability to distinguish the hotter
portion, 2 interleaved runs per config (only n=2, but it reproduces
the picture of the matrix in [17] just fine), THP off, swap off:

Using read()
------------
numactl --membind=0 --cpunodebind=0 \
fio --name=fg --numjobs=16 --nrfiles=1 \
    --filename_format="/var/lib/kmultibench/realdk.\$jobnum.img" \
    --size=2560M \
    --buffered=1 --ioengine=sync --rw=randread \
    --random_distribution=zipf:$ZIPF --bs=4k --time_based \
    --ramp_time=120s --runtime=600s --group_reporting

Avg IOPS (higher is better)
 zipf:θ       CLRU | MGLRU before (vs CLRU) |        FG (vs CLRU) |  Imprv.
  0.8       396,247|      403,014 ( +1.7%)  |    468,872 (+18.3%) |  +16.3%
  0.9       601,304|      616,291 ( +2.5%)  |    713,928 (+18.7%) |  +15.8%
  1.1     2,077,516|    2,158,626 ( +3.9%)  |  2,462,189 (+18.5%) |  +14.1%
  1.2     4,439,193|    4,546,680 ( +2.4%)  |  5,204,998 (+17.3%) |  +14.5%
  1.4    14,318,444|   14,122,531 ( -1.4%)  | 14,620,584 ( +2.1%) |   +3.5%

refault/read (lower is better, defined as workingset_refault_file / reads)
 zipf:θ      CLRU | MGLRU before (vs CLRU) |     FG (vs CLRU) |  Imprv.
  0.8     0.21707 |       0.21288 ( -1.9%) | 0.18887 (-13.0%) |  +11.3%
  0.9     0.14359 |       0.13994 ( -2.5%) | 0.12292 (-14.4%) |  +12.2%
  1.1     0.03919 |       0.03785 ( -3.4%) | 0.03267 (-16.6%) |  +13.7%
  1.2     0.01609 |       0.01551 ( -3.6%) | 0.01323 (-17.8%) |  +14.7%
  1.4     0.00167 |       0.00182 ( +9.0%) | 0.00133 (-20.4%) |  +26.9%

For typical read() following zipf distributions, FG improves every case,
mean +12.9% IOPS and -15.7% refault rate.  FG protects the hotter part
of the workingset better when under pressure, the only case where MGLRU
is behind CLRU is also ahead now.

Using mmap
----------
command: numactl --membind=0 --cpunodebind=0 \
fio --name=fg --numjobs=16 --nrfiles=1 \
    --filename_format="/var/lib/kmultibench/realdk.\$jobnum.img" \
    --size=2560M \
    --ioengine=mmap --rw=randread --fadvise_hint=0 \
    --random_distribution=zipf:$ZIPF --bs=4k --time_based \
    --ramp_time=120s --runtime=600s --group_reporting

Avg IOPS (higher is better)
 zipf:θ       CLRU | MGLRU before (vs CLRU) |        FG (vs CLRU) | Imprv.
  0.8     1,062,221|    3,591,468 (+238.1%) | 4,066,055 (+282.8%) | +13.2%
  0.9       658,512|    3,785,168 (+474.8%) | 4,475,720 (+579.7%) | +18.2%
  1.1     2,183,796|     2,166,070 ( -0.8%) |  2,451,181 (+12.2%) | +13.2%
  1.2     4,785,117|     4,710,772 ( -1.6%) |  5,199,245 ( +8.7%) | +10.4%
  1.4    20,654,851|    20,685,287 ( +0.1%) | 21,598,890 ( +4.6%) |  +4.4%

refault/read (lower is better, defined as workingset_refault_file / reads)
 zipf:θ     CLRU | MGLRU before (vs CLRU) |    FG (vs CLRU)  | Imprv. |
  0.8     0.12460|    0.02124 (-83.0%)  | 0.01898 (-84.8%) |  +10.6% |
  0.9     0.13972|    0.02010 (-85.6%)  | 0.01717 (-87.7%) |  +14.6% |
  1.1     0.04036|    0.03955 ( -2.0%)  | 0.03446 (-14.6%) |  +12.9% |
  1.2     0.01689|    0.01673 ( -0.9%)  | 0.01507 (-10.8%) |   +9.9% |
  1.4     0.00209|    0.00206 ( -1.4%)  | 0.00184 (-12.0%) |  +10.7% |

For typical mmap read of file following zipf distributions, FG also
improves every case here: mean +11.9% IOPS and -11.7% refault rate.
MGLRU remains far ahead of CLRU at theta < 1.

Worth noting, without fadvise_hint=0, we will see a regression like this:
 zipf:θ      CLRU | MGLRU before (vs CLRU) |       FG (vs CLRU) | Imprv.
  1.1    1,949,856|     1,667,041 (-14.5%) | 1,708,521 (-12.4%) |  +2.5%

That's because MGLRU deliberately disables hotness tracking for
MADV_RANDOM areas while CLRU still has refault distance. I don't think
this is a blocker: that is exactly what userspace asked for, and we do
plan to unify refault distance and improve shadow usage [8], [9], which
should also help with workingset shift [18]. FG is the baseline and we
will revisit that later.

Worth mentioning: a previous version test showed FG slightly lower on IOPS
for one config while its refault rate was actually lower. It is mostly
due to locking contention:

The earlier perf lock contention analysis shows the lazy promotion could
make MGLRU's isolation a bit slower than before:

command:
<same test command above, with 4G memcg, zipf:1.2 and a 300s runtime, and below tracing>
perf lock contention -ab -- sleep 355

Result (runtime=300s, 4G memcg, zipf:1.2):
  config:θ       IOPS | mean clat | sys% | lruvec lock total wait |
  CLRU          1,868k|    8195 ns| 6.01%|          ~10 s         |
  MGLRU before  1,677k|    9173 ns| 7.25%|          ~75 s         |
  MGLRU after   1,837k|    8488 ns| 7.33%|          ~78 s         |

MGLRU now promotes more folios due to FG lazy promotion while holding
the LRU lock, which is a good thing for most cases since it protects the
workingset better. The lazy promotion cost can be reduced later by
batching and prefetching during scanning as demonstrated before [12].

MongoDB YCSB [2]
================
With recordcount:18000000 operationcount:27000000, threads:16,
100% zipfian reads, workloads a/b/c, in a 12G memcg, n=2, with a
5000 IOPS cap on the block device, and a 0.25G WiredTiger cache to
simulate a slower device and stress the LRU more:

Throughput (ops/sec, higher is better):
CLRU:         13,474.85 ops/s
MGLRU Before: 14,101.40 ops/s (+4.6% vs CLRU)
MGLRU After:  16,577.92 ops/s (+23.0% vs CLRU) +17.6% vs Before

READ p99 latency (us, lower is better):
CLRU:         69,028.33 us
MGLRU Before: 65,065.67 us (-5.7% vs CLRU)
MGLRU After:  6,977.67 us (-89.9% vs CLRU) -89.3% vs Before

READ p50 latency is essentially unchanged. The setup differs from
previous posted ones as I'm trying to enlarge the test matrix, but
still we are seeing very nice results.

Chromium & Node.js test [3]
===========================
Using ZRAM as swap, 64 workers (32 memcgs x 2 NUMA nodes), 256G
zram, 1h testing:

                 Total requests:
MGLRU Before:            146,229
MGLRU After:             242,644 (+65.9%)

Worth noting there seems to be some reclaim balance jitter for this
test, while the balancing in upstream is not doing very well at this
point too, so this is worth more investigation later.

LevelDB Scan/Get
================
I also retested the LevelDB benchmark from the cache_ext paper [4].
Interestingly, mainline MGLRU already beats CLRU on this one after a
recent change in lru_gen_folio_seq that bumps new folios with refs == 1
to the second-oldest generation as discussed. That change accidentally
gave random reads a higher hotness level while making sequential reads
much colder as described before [13]. However it's unreliable and
incorrect because it depends on LRU drain timing, and hurts some workloads
as reported, or where the sequential part is actually hotter (any workload
involving hotter large file and many small cold files will be affected)
which is reproduced below.

This series improves it while covering ordinary workloads too and fixing
more regressions:

LevelDB Scan / Get, Throughput Total:
CLRU:         4708.3 ops/s
MGLRU:        5026.9 ops/s (faster than CLRU, but hurts other workloads)
MGLRU After:  5179.2 ops/s (even better in all cases, and no regression)

The hot-sequential and cold-random workload can be easily reproduced with
SQLite and grep. SQLite continuously scans and looks up a small hot
portion of a DB file, while grep iterates over a set of small files much
larger than RAM [5]:

         SQLite scan & lookup time:       Grep iterate time:
CLRU:                       14.51ms               13281.37ms
MGLRU mainline:            567.05ms               13694.47ms
MGLRU After this series:    10.58ms               12930.43ms

The grep cold portion is larger than RAM and accessed only once per
iteration, so there's no promotion of any of it. CLRU handles
this reasonably. Mainline MGLRU has a clear regression; MGLRU-FG not
only recovers but is able to catch some hot parts from the cold grep
workload. This test is somewhat subjective, but the signal is clear.

An alternative fix was discussed previously too and I tested it as well
[17]. FG is still better, and its gain holds on top of it.

Android (For reference)
=======================
Testing on Android is quite difficult: lack of mainline support, and it
is very noisy, but I did an informal backport on top of the 6.1 GKI tree,
testing with a Pixel 9 Pro (16 GB RAM, 8 GB ZRAM, Android 17), preserving
the frozen kABI layouts so the implementation is limited [14].

The "before" and "after" kernels share the same base and differ only by
the FG series: the "before" tree has MGLRU aligned to the current upstream
code. (And BTW that alignment also improved the performance by a lot,
which matches the report from previous MGLRU reclaim optimization
series [11]).

The workload is a churn loop driven over adb: 34 common apps and 20 Chrome
tabs are launched and cycled, with a brief scroll per app during the cold
build of each iteration, 16 iterations per run, about one hour per run. The
loop exhausts memory in every iteration (zram peaks at 6.9-7.8 GB of 8 GB,
MemFree down to 130-335 MB in every run). The two kernels are run in an
interleaved rotation and compared both on matched per-iteration samples
(same period, same iteration index) and on paired run totals, which
cancels most of the run-to-run drift. I've repeated the test for several
days and times getting similar results.

The memory-management stack in Android is built around the non-FG MGLRU
behavior, and the 6.1 base lacks some of the upstream infrastructure. Even
so, FG holds its own, it lowers reclaim traffic on both the file and the anon
side:

                          Before     After   Delta 95% CI   Avg Improv.
-----------------------------------------------------------------------
workingset_refault_anon    1.43M     1.25M   [-23%, -3%]          +12%
workingset_refault_file    1.54M     1.39M   [-17%, +2%]          +10%
pgscan_anon                4.04M     3.56M   [-20%, -5%]          +12%
pgsteal_anon               1.64M     1.45M   [-23%, -1%]          +12%
pgscan_file                7.49M     6.52M   [-17%, -5%]          +13%
pgsteal_file               6.55M     5.63M   [-18%, -7%]          +14%
pswpout                    1.82M     1.62M   [-22%, -1%]          +11%
pgpgin                    23.56M    20.33M   [-18%, -7%]          +14%
pgmajfault                 1.61M     1.42M   [-21%, -4%]          +12%
pgpgout                    3.39M     3.48M   [ +0%, +5%]           -3%

Numbers are trimmed means over the 12 interleaved runs per kernel: the
highest and lowest run are dropped and the middle ten averaged. It's
the vmstat delta of one full run. The 95% CI is a bootstrap over the
12 rounds of the paired run-total ratio (After vs Before).

Despite being noisy, every counter except pgpgout and
workingset_refault_file is improved by ~10% on average, with a 95% CI
that stays clear of zero. We have been seeing
positive readings since v2 of this series, and v5 still holds the same
pattern with a few days of testing. I think we can safely say that this
series is beneficial for generic Android workloads.

I also ran the Android Jank test from Zicheng [6] for previous versions,
and did a test on another Android phone with a 5.15 kernel on Xperia 1 V,
[15], the results are all looking good or basically flat.

Redis / Valkey
==============
Valkey in a 2G ARM64 VM, 2.4G dataset, using 8G ZRAM as swap and THP never.
Note, PT walk is missing there due to lack of hardware capability:

$ cat /sys/kernel/mm/lru_gen/enabled
0x0001

valkey-server --maxmemory 2560M
valkey-benchmark -r 3000000 -n 3000000 -d 1024 -c 12 -P 32 -t get

For every sample, 20 rounds each:

                            Before         After
plain GET              679,151 rps   707,938 rps  +4.2%
plain GET + BGSAVE     481,886 rps   494,153 rps  +2.5%

Small wins: the dataset does not fit in the guest, so this case runs
mostly under swap pressure. Nothing regresses, and GET throughput still
improves by ~4%.

Others
======

Additionally, PSI, smaps, and readahead should all benefit from better
accuracy since this series unifies the flag usage between classical
LRU and MGLRU.

Other tests such as MySQL are looking fine, with no regressions. There is
also community test report [7].

Refault distance is not included yet, so MGLRU may respond more slowly to
workingset shifts. That can be added later, as previously demonstrated
[8], [9].

Extra note about future development: this series is actually highly
compatible with ideas like workingset reporting [10]. The "gen climbing
folio" design may appear to conflict with workingset reporting's idea,
but it doesn't. The solution is simple and straightforward: once we can
extend the generation number to a larger value (e.g. 64 or 128), the
refs-driven promotion can stop at a lower gen (e.g. oldest_gen + 16),
leaving the remaining newer generations as perfectly time-gap-separated
bins. These older gens can be considered as expiring gen.

The tier count is not fixed either, we'll need to find a way to tune it
if tiers go beyond 4 though, but that shouldn't be hard, not a blocker
either.

More details are in the individual commit messages. LLM is used to help
improve the comments and tests, all results are double checked.

Link: https://lore.kernel.org/linux-mm/CAMgjq7BoekNjg-Ra3C8M7=8=75su38w=HD782T5E_cxyeCeH_g@mail.gmail.com/ [1]
Link: https://github.com/brianfrankcooper/YCSB/tree/master/workloads [2]
Link: https://lore.kernel.org/all/20221220214923.1229538-1-yuzhao@google.com/ [3]
Link: https://dl.acm.org/doi/10.1145/3731569.3764820 [4]
Link: https://github.com/ryncsn/emm-test-project/tree/master/sqlite-grep [5]
Link: https://github.com/purplewall1206/android-perf-bench [6]
Link: https://lore.kernel.org/linux-mm/92DCEFFD13221261+20260828102344.1537874-1-zhaozhengzhuo@uniontech.com/ [7]
Link: https://lwn.net/Articles/945266/ [8]
Link: https://lore.kernel.org/linux-mm/20260502-mglru-fg-v1-0-913619b014d9@tencent.com/ [9]
Link: https://lwn.net/Articles/976985/ [10]
Link: https://lore.kernel.org/linux-mm/20260417025123.2971253-1-wxy2009nrrr@163.com/ [11]
Link: https://lore.kernel.org/linux-mm/20240123184552.59758-1-ryncsn@gmail.com/ [12]
Link: https://lore.kernel.org/all/CAMgjq7Agqr1FLcG3HqT_M_1s8cHc21qQKTM-JS67-3gfQ6azPQ@mail.gmail.com/ [13]
Link: https://github.com/ryncsn/linux/tree/kasong/android/android14-6.1-mglru-fg-v4c-20261010 [14]
Link: https://github.com/ryncsn/linux/tree/silsrc/android/android13-5.15-yodo [15]
Link: https://lore.kernel.org/all/20261114200803.23129-1-baohua@kernel.org/ [16]
Link: https://lore.kernel.org/linux-mm/avd5bI-b9y1nKWw5@KASONG-MC4 [17]
Link: https://lore.kernel.org/linux-mm/CAMgjq7AEf_cJsLw4fxs7m5ntYPW9mjCOC_-w5j6ihk8F=xLRWA@mail.gmail.com/ [18]
Link: https://lore.kernel.org/all/CAMgjq7C1A2axrGiQzo2_9d6N9MQNP6Lg+ZqcHsac+qGvt8OL4A@mail.gmail.com/ [19]
Link: https://github.com/kubernetes/kubernetes/issues/127844 [20]

Signed-off-by: Kairui Song <kasong@tencent.com>
Tested-by: Zhao Zhenzhuo <zhaozhengzhuo@uniontech.com>
---
Changes in v5:
- Rebased onto current mm-new.
- Code and design are basically the same, mostly rebase and adaption and
  comment updates.
- Drop "mm: mglru: reparent folios from all generations": the fix it
  carried is upstream now.
- Pick up two patches from Ridong Chen to avoid conflicts.
- Fix a build warning with CONFIG_LRU_GEN=n.
- Share the ancestor walk between lruvec_live_lock_irq() and the new
  folio_lruvec_live_get()
- Note in __lru_gen_reparent_memcg() why the read/set/add of the child's
  counter cannot lose a lockless update.
- Say in the gup fast helper changelog what the fast path gains from it.
- Re-measure almost all tests as the recent swappiness rework changes a
  lot of things, and it turns out most result are still same or even better.
- Comment and kdoc updated, documentations needs more systematic update later.
- Link to v4: https://patch.msgid.link/20261016-mglru-fg-v4-0-2106750c0bfa@tencent.com

Changes in v4:
- Defer folios at the tail of their LRU instead of min_seq only:
  https://lore.kernel.org/linux-mm/CAMgjq7AOhDkuZZnWrGDguMvNtarZ7s0Ouzs1xYi2O4AkPEPbTQ@mail.gmail.com/
- Re-read max_seq inside the folio_inc_lru_refs_walk() cmpxchg loop, and
  apply the reparent fix before the lockless change.
- Tidy up a few code shuffles.
- Use generic refs-based helper for smaps, DAMON, khugepaged
  and madvise with better kdocs.
- Add community Tested-by tags for unchanged parts.
- Link to v3: https://patch.msgid.link/20261003-mglru-fg-v3-0-cbd4546a5bd9@tencent.com

Changes in v3:
- Micro-optimization for page flags operations: if the flags are
  unchanged after calculation, skip the cmpxchg.
- Avoid touching folio_activate even in the cold path. I tried multiple
  ways for that lockless promotion, PG_lru in the earlier RFC, and
  previous folio_activate, the new speculative barrier + retry seem the
  best solution.
- Apply tier cap for MADV_PAGEOUT.
- Only promote folio during page table walk or rmap if the folio
  is in the min gen. May be worth trying to enlarge the range to
  (max_seq - MIN_NR_GENS) in the next version.
- Fix a potential folio leak caused by reparenting.
- Retest shows great results especially for the Android case.
- Link to v2: https://patch.msgid.link/20260911-mglru-fg-v2-0-f26e5cb26da7@tencent.com

Changes in v2:
- Rebased; dropped v1 03/05/06 (already upstream), folded v1 01 and 07
  into patches 01 and 04; new patches 06, 07, 10, 12, 13.
- Make folio_test_workingset() itself arbitrate, dropping the parallel
  folio_is_* helpers; convert the last raw PageWorkingset() user
  (erofs). (Johannes)
- Use LRU_REF_MAPPED/LRU_REF_EXEC flags instead of is_fault/is_exec
  booleans. (Barry)
- Fix syzbot "WARNING in folio_inc_lru_refs" on off-LRU folios.
- Account active/inactive per folio from refs, not the gen window:
  /proc/vmstat and memory.stat no longer jump on aging or reverse on
  swapless machines.
- Make folio_inc_lru_refs() lockless; add folio_inc_lru_refs_fast()
  for the gup fast paths.
- Convert DAMON and khugepaged to the refs-based operations.
- Drop the lru_size WARN_ON_ONCE() and lockdep_assert_held(): the
  counter is lockless now, so transient negatives are expected.
- Link to v1: https://patch.msgid.link/20260804-mglru-fg-v1-0-4d8dad39dad6@tencent.com

---
Kairui Song (15):
      mm/memcontrol: allow update of LRU statistic without holding LRU lock
      mm/mglru: make generation page counters atomic
      mm/memcg: add folio-based lruvec live helper
      mm/mglru: frequency guided workingset promotion (MGLRU-FG)
      mm/mglru: make folio lru referenced times count a generic API
      mm/mglru: move add/del LRU size accounting out of lru_gen_update_size()
      mm/mglru, gup: mark folios referenced via a fast helper
      mm/mglru, smaps: convert to LRU refs based operations for MGLRU
      mm/damon: convert to LRU refs based operations for MGLRU
      mm/khugepaged: convert to LRU refs based operations for MGLRU
      mm/madvise: adapt for LRU refs based operations for MGLRU
      mm/huge_memory: mark folio as accessed more accurately on split
      mm/mglru: folio LRU refs based active/inactive number accounting
      mm/mglru: make folio_inc_lru_refs lruvec lockless
      mm/mglru: make folio_test_workingset() work based on folio LRU refs

Ridong Chen (2):
      mm/mglru: rename the generation offset in lru_gen_folio_seq()
      mm/mglru: skip the flags cmpxchg when nothing changes

 Documentation/admin-guide/mm/multigen_lru.rst |   4 +-
 fs/btrfs/compression.c                        |   1 +
 fs/erofs/zdata.c                              |   3 +-
 fs/proc/task_mmu.c                            |   6 +-
 include/linux/memcontrol.h                    |  71 +++-
 include/linux/mm_inline.h                     | 380 ++++++++++++------
 include/linux/mmzone.h                        | 150 ++++---
 include/linux/page-flags.h                    |   2 -
 kernel/bounds.c                               |   2 +-
 mm/damon/paddr.c                              |   3 +-
 mm/filemap.c                                  |   1 +
 mm/folio.c                                    |  88 +----
 mm/gup.c                                      |   6 +-
 mm/huge_memory.c                              |   8 +-
 mm/khugepaged.c                               |   4 +-
 mm/madvise.c                                  |  54 ++-
 mm/migrate.c                                  |   2 -
 mm/page_io.c                                  |   1 +
 mm/vmscan.c                                   | 538 ++++++++++++++++++--------
 mm/vmscan.h                                   |   2 +-
 mm/workingset.c                               |  47 ++-
 21 files changed, 879 insertions(+), 494 deletions(-)
---
base-commit: 25fee5b1762b8799dd8b72c2f6d666eb01680cc7
change-id: 20260722-mglru-fg-3a2c8574725b

Best regards,
--  
Kairui Song <kasong@tencent.com>

