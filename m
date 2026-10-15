From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v4 00/17] mm/mglru: frequency guided promotion (MGLRU-FG)
 and flag cleanup
Date: Fri, 16 Oct 2026 02:15:49 +0800
Message-Id: <20261016-mglru-fg-v4-0-2106750c0bfa@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2XNywrCMBAF0F+RrI0kk0dbV/6HuMhjWiPaSlKLI
 v130xZ84Gbgwj13niRhDJjIdvUkEYeQQtfmINcr4o6mbZAGnzMBBpoVAPTSnOON1g0VBlypClm
 AsiTXrxHrcJ+n9oclp5s9oesnPzWOIfVdfMy/Bj71ltmSyc/swCmj0pfeeFHlo3c9tg7bfuO6C
 5mGB/jQivMvCpnWoFE5C9qb4p+KN+WMiS8qMnXWSyW1UdZXv3Qcxxfs3BfEKgEAAA==
X-Change-ID: 20260722-mglru-fg-3a2c8574725b
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792088152; l=24953;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=yV2JG+LqxbZD4fnOqyiS1rHF8jlluqoAzh5rMvaWVl0=;
 b=k2EyUaD/db6T7bKWyHh0itavpHhcTCuOza00fpJTNqDh2L93pA2vTIq0489KdC7bn4BbIaVc+
 bTBFssMXHGVC6hWzRREXhU4XojVseWcM/g29NbXmAvDXkZ4/uy45mrs
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all, this cover letter is going to be very long, as it includes a
systematic test and analysis. And moving this series out of RFC phase
as almost all readings are positive, tested on at least five different
platforms (desktop, large server, Android, x86_64 and arm64 boxes)
covering typical benchmarks, database, real applications, and has
good test reports from other individual testers. It's also pretty clear
about the next steps, and this blocks or breaks nothing AFAIK, which
should be a pure gain, improving the performance or reducing IO of many
workloads by ~10-40%.

Still following the idea proposed at LSF/MM/BPF [1], based on current
mm-new. Different workloads get a minor or dramatic improvement,
while reducing the page flags usage by 1 bit. The gain here is mostly
from a real improvement of LRU's ability to distinguish the hotter
workingset. Tested across multiple servers of different archs, desktops,
and Android.

It also fixes several long-standing issues including under-accounted PSI
and poor workingset tracking (especially for page cache).

Test results (CLRU means classical LRU):

Build kernel test:
==================
Running make -j48 in a 3G memcg, using ZRAM as swap (256G, lzo-rle) and
holding the kernel and build output on a NVMe drive, 3 runs of 5 swappiness
configurations (15 builds per kernel) [2]; the patched version is better
than mainline at every swappiness value, measuring the total on average:

         real     sys    pgpgin  pswpin  pswpout refault_file refault_anon
CLRU    1m39s  14m59s    21.47M   2.81M   11.47M        2.40M        2.87M
Before  1m32s   9m18s    12.57M   2.10M    9.05M         476k        2.07M
After   1m32s   9m01s     9.99M   1.62M    8.40M         369k        1.60M
delta   -0.4s -17s(-3%)  -20.5%  -22.4%    -7.1%       -22.4%       -22.6%

Same -j48 test, disk swap instead of ZRAM (SSD-backed; the kernel and build
output stay on NVMe). The regression reported for earlier revisions is gone:
it is now a small net win, with every I/O counter improved, at the cost of
~1% more system time spent on the extra promotion work:

        real        sys    pgpgin  pswpin  pswpout  refault_file  refault_anon
CLRU   4m22s     21m54s    36.80M   3.00M   10.56M         6.03M        3.05M
Before 2m51s     10m12s    10.04M   1.55M    5.02M          416k        1.02M
After  2m48s     10m18s     8.95M   1.41M    4.93M          341k         931k
delta  -4s(-2%)  +6s(+1%)  -10.9%   -8.8%    -1.8%        -18.1%        -9.0%

FIO cached read with zipf
=========================
Using an NVMe disk, in a 16G cgroup, total file size 40G, this measures
the LRU's theoretical ability to distinguish the hotter portion, 3 test
runs per config:

Using read()
------------
command: numactl --membind=0 --cpunodebind=0 \
fio --name=fg --numjobs=16 --nrfiles=1 \
    --filename_format="/var/lib/kmultibench/realdk.\$jobnum.img" \
    --size=2560M \
    --buffered=1 --ioengine=sync --rw=randread \
    --random_distribution=zipf:$ZIPF --bs=4k --time_based \
    --ramp_time=45s --runtime=600s --group_reporting

READING: Avg IOPS (higher is better)
 zipf:θ       CLRU | MGLRU before (vs CLRU) |       FG (vs CLRU) | Imprv. |
  0.8       397,572|      396,046 ( -0.4%)  |   449,714 (+13.1%) | +13.6% |
  0.9       605,862|      602,201 ( -0.6%)  |   692,524 (+14.3%) | +15.0% |
  1.1     2,092,280|    2,122,415 ( +1.4%)  | 2,457,564 (+17.5%) | +15.8% |
  1.2     4,444,665|    4,513,839 ( +1.6%)  | 5,066,901 (+14.0%) | +12.3% |

READING: refault/read (lower is better)
 zipf:θ      CLRU | MGLRU before (vs CLRU) |     FG (vs CLRU) | Imprv. |
  0.8     0.20108 |        0.20074 (-0.2%) | 0.17660 (-12.2%) | +12.0% |
  0.9     0.13356 |        0.13186 (-1.3%) | 0.11522 (-13.7%) | +12.6% |
  1.1     0.03641 |        0.03586 (-1.5%) | 0.03065 (-15.8%) | +14.5% |
  1.2     0.01479 |        0.01466 (-0.8%) | 0.01230 (-16.9%) | +16.1% |

For typical read() following zipf distributions, MGLRU was basically the
same as CLRU before or slightly worse in certain cases, now it's ~12-16%
better and leading. Worth noting we also observed in certain systems MGLRU
was worse than CLRU before in v2 - v3, which is now also optimized into a
gain.

Using mmap
----------
command: numactl --membind=0 --cpunodebind=0 \
fio --name=fg --numjobs=16 --nrfiles=1 \
    --filename_format="/var/lib/kmultibench/realdk.\$jobnum.img" \
    --size=2560M \
    --ioengine=mmap --rw=randread --fadvise_hint=0 \
    --random_distribution=zipf:$ZIPF --bs=4k --time_based \
    --ramp_time=45s --runtime=600s --group_reporting

READING: Avg IOPS (higher is better)
 zipf:θ       CLRU | MGLRU before (vs CLRU) |      FG (vs CLRU)   | Imprv. |
  0.8     1,521,315|    3,610,516 (+137.3%) | 3,980,874 (+161.7%) | +10.3% |
  0.9       926,158|    3,856,644 (+316.4%) | 4,423,859 (+377.7%) | +14.7% |
  1.1     2,303,035|    2,225,641 ( -3.4%)  | 2,715,460 (+17.9%)  | +22.0% |
  1.2     5,015,274|    4,811,580 ( -4.1%)  | 5,357,325 ( +6.8%)  | +11.3% |

READING: refault/read (lower is better)
 zipf:θ     CLRU | MGLRU before (vs CLRU) |    FG (vs CLRU)  | Imprv. |
  0.8     0.05403|      0.02009 (-62.8%)  | 0.01805 (-66.6%) | +10.2% |
  0.9     0.08937|      0.01899 (-78.8%)  | 0.01638 (-81.7%) | +13.8% |
  1.1     0.03549|      0.03644 ( +2.7%)  | 0.02925 (-17.6%) | +19.7% |
  1.2     0.01529|      0.01569 ( +2.6%)  | 0.01375 (-10.1%) | +12.4% |

For typical mmap read of file following zipf distributions, MGLRU was
behaving much better for theta < 1 and with a slight regression for
theta > 1. And FG greatly improved both cases, no more regression in any
case with an improvement ~10-20%.

Worth noting, without fadvise_hint=0, we will see a regression like this:
 zipf:θ      CLRU | MGLRU before (vs CLRU) |      FG (vs CLRU)  | Imprv. |
   1.1   1,873,230|    1,641,981 (-12.3%)  | 1,648,997 (-12.0%) |  +0.4% |

That's because MGLRU deliberately disables hotness tracking for MADV_RANDOM
areas and meanwhile for CLRU refault distance is still taking effect. I
don't think this is an issue or blocker as that's exactly what the
userspace asked and we also have plan to unify or improve shadow or
refault distance usage [9], [10].

Tighter cache
-------------
command: following the mmap test, adjusting cgroup limit and zipf theta, 2
tests per case:

READING: Avg IOPS (higher is better)

  memcg/θ       CLRU | MGLRU before (vs CLRU) |       FG (vs CLRU)  | Imprv. |
  16G/1.4  20,563,861|   20,408,851 ( -0.8%)  | 21,314,656 ( +3.7%) |  +4.4% |
   8G/1.4  14,606,000|   13,650,929 ( -6.5%)  | 14,603,348 (  0.0%) |  +7.0% |
   4G/1.4  10,102,227|    9,392,019 ( -7.0%)  |  9,992,258 ( -1.1%) |  +6.4% |
  12G/1.2   3,688,008|    3,502,117 ( -5.0%)  |  3,795,627 ( +2.9%) |  +8.4% |
   8G/1.2   2,726,922|    2,511,410 ( -7.9%)  |  2,735,389 ( +0.3%) |  +8.9% |
   4G/1.2   1,906,548|    1,672,370 (-12.3%)  |  1,785,545 ( -6.3%)*|  +6.8% |
  12G/1.1   1,618,437|    1,520,102 ( -6.1%)  |  1,641,287 ( +1.4%) |  +8.0% |
   8G/1.1   1,209,058|    1,100,118 ( -9.0%)  |  1,196,796 ( -1.0%) |  +8.8% |
   6G/1.1   1,024,652|      910,669 (-11.1%)  |  1,030,723 ( +0.6%) | +13.2% |

READING: refault per read (lower is better)

 memcg:θ     CLRU | MGLRU before (vs CLRU) |    FG (vs CLRU)  | Imprv. |
 16G/1.4  0.00205 |      0.00210 ( +2.4%)  | 0.00180 (-12.2%) | +14.3% |
  8G/1.4  0.00392 |      0.00430 ( +9.7%)  | 0.00379 ( -3.3%) | +11.9% |
  4G/1.4  0.00645 |      0.00722 (+11.9%)  | 0.00650 ( +0.8%) | +10.0% |
 12G/1.2  0.02169 |      0.02245 ( +3.5%)  | 0.02055 ( -5.3%) |  +8.5% |
  8G/1.2  0.02944 |      0.03209 ( +9.0%)  | 0.02875 ( -2.3%) | +10.4% |
  4G/1.2  0.04459 |      0.04897 ( +9.8%)  | 0.04388 ( -1.6%)*| +10.4% |
 12G/1.1  0.05159 |      0.05361 ( +3.9%)  | 0.04907 ( -4.9%) |  +8.5% |
  8G/1.1  0.06830 |      0.07387 ( +8.2%)  | 0.06708 ( -1.8%) |  +9.2% |
  6G/1.1  0.08064 |      0.08816 ( +9.3%)  | 0.08046 ( -0.2%) |  +8.7% |

It can be clearly seen that MGLRU was worse than CLRU before under tight
cache usage, and with FG all cases improved. And the missing rate measured
by refault per read shows FG is better than unpatched MGLRU and CLRU in
almost every configuration.

If we re-run the only obvious regression, the 4G/1.2 case (*), with perf,
the bottleneck is the lruvec lock, with the contention concentrated in
try_to_shrink_lruvec() where the lazy promotion work happens:

command:
  <same test command above, with 4G memcg and zipf:1.2, and below tracing>
  perf lock contention -ab -- sleep 355

READING (runtime=300s, 4G memcg, zipf:1.2):
  config:θ       IOPS | mean clat | sys% | lruvec lock total wait |
  CLRU          1,868k|    8195 ns| 6.01%|          ~10 s         |
  MGLRU before  1,677k|    9173 ns| 7.25%|          ~75 s         |
  MGLRU after   1,837k|    8488 ns| 7.33%|          ~78 s         |

The wait column is a per-run total. MGLRU now promotes more folios either
due to PID protection or FG promotion while holding the LRU lock. And
FG achieves comparable or even better performance by reducing actual IO
already, which is a net improvement compared to unpatched MGLRU. The
remaining gap over CLRU is inherited lock cost, which can be reduced
by batching and prefetching during scanning as demonstrated before [13]
(and interestingly, you can see the benchmark kind of matches the
improvement that I measured at that time).

MongoDB YCSB workloadb [3]
==========================
With recordcount:20000000 operationcount:6000000, threads:48,
in a 16G memcg, 3 runs:

CLRU:          97,856.45 ops/s
MGLRU Before:  85,702.39 ops/s (-12.4% vs CLRU)
MGLRU After:   98,569.77 ops/s ( +0.7% vs CLRU) +15.0% vs Before

MGLRU was doing worse than CLRU before, now it's doing better.

Chromium & Node.js test [4]
===========================
Using ZRAM as swap, on a 48c96t machine with 128G memory, 64 workers, run
for 1 hour:

                 Total requests:
CLRU:                     63822
MGLRU Before:            130650
MGLRU After:             228864 (+75.1%)

Worth noting there seems to be some reclaim balance jitter for this test
but MGLRU is far better already and now leading even more.

LevelDB Scan/Get
================
I also retested the LevelDB benchmark from the cache_ext paper [5].
Interestingly, mainline MGLRU already beats CLRU on this one after a
recent change in lru_gen_folio_seq that bumps new folios with refs == 1
to the second-oldest generation as discussed. That change accidentally
gave random reads a higher hotness level while making sequential reads
much colder as described before [14]. However it's unreliable and
incorrect because it depends on LRU drain timing, and hurts some workloads
as reported, or where the sequential part is actually hotter (any workload
involving hotter large file and many small cold files will be affected)
which is reproduced below.

This series improves it while covering ordinary workloads too and should
fix regressions:

LevelDB Scan / Get, Throughput Total:
CLRU:         4708.3 ops/s
MGLRU:        5026.9 ops/s (faster than CLRU, but hurts other workloads)
MGLRU After:  5179.2 ops/s (even better in all cases, and no regression)

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

Android (For reference)
=======================
Testing on Android is quite difficult: lack of mainline support, and it is
very noisy with real apps to get a stable result. I did an informal
backport of the latest MGLRU-FG patches onto the 6.1 GKI tree of a
Pixel 9 Pro (16 GB RAM, 8 GB ZRAM, Android 17), preserving the frozen
kABI layouts so the implementation is limited (see the code here [15]).
The "before" and "after" kernels share the same base and differ only by
the FG series: the "before" tree has MGLRU aligned to the current upstream
code, so that unrelated backport deltas cancel out. (And BTW that alignment
also improved the performance by a lot, which matches the report from
previous MGLRU reclaim optimization series [12]).

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
behaviour, and the 6.1 base lacks some of the upstream infrastructure. Even
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

"Before" is the aligned tree without the FG series, "After" adds FG. The
numbers are trimmed means over the 12 interleaved runs per kernel: for each
counter's avg, the highest and lowest run are dropped and the middle ten
averaged. Each counter is the vmstat delta of one full run. The 95% CI is
a bootstrap over the 12 rounds of the paired run-total ratio (After vs
Before).

The environment is noisy, but given the fact that every counter except
pgpgout is improved by ~10% on average and the 95% CI reading is also
looking good, and we have been seeing positive readings since v2 of this
series, I think we can safely say that this series reduced IO by about
10% for the same Android workload and has a very positive effect on it.

I also ran the Android Jank test from Zicheng [7] on this device (chrome
scroll, FrameTimeline), plus a 34-app keepalive run. No obvious difference
was observed: the run-mean chrome scroll fps of every kernel sits in a
100.6-103.6 band on a 120 Hz panel, and the jank ratios are all below 8%
per scroll round with no consistent ordering across kernels. The keepalive
test does not discriminate on this build: 31-32 of 34 apps stay alive
with every kernel. On the previous build a run kept slightly more apps
alive with FG (average 4.8 vs 4.5, peak 23 vs 20), that could be noise
or a slight improvement. Both kernels saturate all 8 cores with no obvious
CPU usage difference (99.8-99.9% utilization, ~518s busy per 65s window).

I also did a test on another Android phone with a 5.15 kernel (Xperia 1 V,
code here [16]), which has all apps in one global memcg (this Pixel 9 Pro
has each app in a separate memcg). The result looks much better there,
either due to the memcg layout or the non-reclaiming anon shadow (the 6.1
kernel reclaims anon shadow). But in either case, the performance is
a positive reading.

So in summary: with this revision we get lower file refaults, lower
pgpgin, and lower anon reclaim and swap traffic.

Redis / Valkey
==============
Valkey in a 1.5G ARM64 VM using 8G ZRAM as swap:

valkey-server --maxmemory 2560M
redis-benchmark -r 3000000 -n 3000000 -d 1024 -c 12 -P 32 -t get

        With BGSAVE running     Without BGSAVE running

Before: 308356.47 RPS          431468.44 TPS
After:  336300.34 RPS (+9.0%)  442151.81 TPS (+2.4%)

Looking good with some improvement, tested 3 times. Note on that VM we have
$ cat /sys/kernel/mm/lru_gen/enabled
0x0001

So page table walker is not available, but still working well.

Others
======

Additionally, PSI, smaps, and readahead should all benefit from better
accuracy since this series unifies the flag usage between classical
LRU and MGLRU.

Other tests such as MySQL are looking fine, with no regressions. There is
also community test report [8].

Refault distance is not included yet, so MGLRU may respond more slowly to
workingset shifts. That can be added later, as previously demonstrated
[9], [10].

Extra note about future development: this series is actually highly
compatible with ideas like workingset reporting [11]. The "gen climbing
folio" design may appear to conflict with workingset reporting's idea,
but it doesn't. The solution is simple and straightforward: once we can
extend the generation number to a larger value (e.g. 64 or 128), the
refs-driven promotion can stop at a lower gen (e.g. oldest_gen + 16),
leaving the remaining newer generations as perfectly time-gap-separated
bins.

The tier count is not fixed either; we'll need to find a way to tune it
if tiers go beyond 4 though, but that shouldn't be hard, not a blocker
either.

More details are in the individual commit messages. LLM is used to help
improve the comments and tests; all results are double checked.

Link: https://lore.kernel.org/linux-mm/CAMgjq7BoekNjg-Ra3C8M7=8=75su38w=HD782T5E_cxyeCeH_g@mail.gmail.com/ [1]
Link: https://lore.kernel.org/linux-mm/CAGsJ_4xre-x0e+qNVm=KLFnO1dbPkPX5RuecqwvTZu-vS+o8yQ@mail.gmail.com/ [2]
Link: https://github.com/brianfrankcooper/YCSB/blob/master/workloads/workloadb [3]
Link: https://lore.kernel.org/all/20221220214923.1229538-1-yuzhao@google.com/ [4]
Link: https://dl.acm.org/doi/10.1145/3731569.3764820 [5]
Link: https://github.com/ryncsn/emm-test-project/tree/master/sqlite-grep [6]
Link: https://github.com/purplewall1206/android-perf-bench [7]
Link: https://lore.kernel.org/linux-mm/92DCEFFD13221261+20260828102344.1537874-1-zhaozhengzhuo@uniontech.com/ [8]
Link: https://lwn.net/Articles/945266/ [9]
Link: https://lore.kernel.org/linux-mm/20260502-mglru-fg-v1-0-913619b014d9@tencent.com/ [10]
Link: https://lwn.net/Articles/976985/ [11]
Link: https://lore.kernel.org/linux-mm/20260417025123.2971253-1-wxy2009nrrr@163.com/ [12]
Link: https://lore.kernel.org/linux-mm/20240123184552.59758-1-ryncsn@gmail.com/ [13]
Link: https://lore.kernel.org/all/CAMgjq7Agqr1FLcG3HqT_M_1s8cHc21qQKTM-JS67-3gfQ6azPQ@mail.gmail.com/ [14]
Link: https://github.com/ryncsn/linux/tree/kasong/android/android14-6.1-mglru-fg-v4c-20261010 [15]
Link: https://github.com/ryncsn/linux/tree/silsrc/android/android13-5.15-yodo [16]

Assisted-by: LLM
Signed-off-by: Kairui Song <kasong@tencent.com>
Tested-by: zhaozhengzhuo <zhaozhengzhuo@uniontech.com>
---
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
Kairui Song (17):
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
      mm/mglru: reparent folios from all generations
      mm/mglru: make folio_inc_lru_refs lruvec lockless
      mm/mglru: make folio_test_workingset() work based on folio LRU refs
      Documentation/mm: multi-gen LRU: update for frequency guided promotion

 Documentation/admin-guide/mm/multigen_lru.rst |   4 +-
 Documentation/mm/multigen_lru.rst             |  57 +--
 fs/btrfs/compression.c                        |   1 +
 fs/erofs/zdata.c                              |   3 +-
 fs/proc/task_mmu.c                            |   6 +-
 include/linux/memcontrol.h                    |  39 ++
 include/linux/mm_inline.h                     | 354 ++++++++++++------
 include/linux/mmzone.h                        | 169 ++++++---
 include/linux/page-flags.h                    |   2 -
 kernel/bounds.c                               |   2 +-
 mm/damon/paddr.c                              |   3 +-
 mm/filemap.c                                  |   1 +
 mm/folio.c                                    |  85 +----
 mm/gup.c                                      |   6 +-
 mm/huge_memory.c                              |   8 +-
 mm/khugepaged.c                               |   4 +-
 mm/madvise.c                                  |  57 ++-
 mm/migrate.c                                  |   2 -
 mm/page_io.c                                  |   1 +
 mm/vmscan.c                                   | 520 +++++++++++++++++---------
 mm/workingset.c                               |  45 ++-
 21 files changed, 875 insertions(+), 494 deletions(-)
---
base-commit: 71a9b024444eba184335b67867897714e4da143c
change-id: 20260722-mglru-fg-3a2c8574725b

Best regards,
--  
Kairui Song <kasong@tencent.com>

