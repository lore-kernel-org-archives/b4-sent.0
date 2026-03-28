From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v2 00/12] mm/mglru: improve reclaim loop and dirty folio
 handling
Date: Sun, 29 Mar 2026 03:52:26 +0800
Message-Id: <20260329-mglru-reclaim-v2-0-b53a3678513c@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13MQQ6CMBCF4auQWVvT1raCK+9hWOAwwCRQTFuJh
 nB3K4kbl/9L3rdCpMAU4VKsEGjhyLPPoQ8F4ND4ngS3uUFL7eRJGTH1Y3iKQDg2PAmFVWtsg/b
 cOcifR6COX7t3q3MPHNMc3ju/qO/6k8o/aVFCCo3GdRXdpZXlNZFH8umI8wT1tm0fPCJ17awAA
 AA=
X-Change-ID: 20260314-mglru-reclaim-1c9d45ac57f6
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 David Hildenbrand <david@kernel.org>, Michal Hocko <mhocko@kernel.org>, 
 Qi Zheng <zhengqi.arch@bytedance.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Lorenzo Stoakes <ljs@kernel.org>, 
 Barry Song <baohua@kernel.org>, David Stevens <stevensd@google.com>, 
 Chen Ridong <chenridong@huaweicloud.com>, Leno Hou <lenohou@gmail.com>, 
 Yafang Shao <laoar.shao@gmail.com>, Yu Zhao <yuzhao@google.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Kalesh Singh <kaleshsingh@google.com>, 
 Suren Baghdasaryan <surenb@google.com>, Chris Li <chrisl@kernel.org>, 
 Vernon Yang <vernon2gm@gmail.com>, linux-kernel@vger.kernel.org, 
 Qi Zheng <qi.zheng@linux.dev>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774727549; l=9146;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=35yLS4uOo5XTtIbJNZAJxiJKNivR5w1dba4z/A6nZec=;
 b=ialMt7ZZ2TGQLCQ8GGwjo9DV92CJSOOYZoTQi8QqoZ700iVBS10BwZOedF0p5UKd5L6d5X37v
 DtsZ28J1rF6Ayj+ljF53LFHRL+GMLuAqTNcPiXyo93njuer316o8sXx
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series is based on mm-new to avoid conflict with Baolin's Cgroup V1
MGLRU fix.

This series cleans up and slightly improves MGLRU's reclaim loop and
dirty writeback handling. As a result, we can see an up to ~30% increase
in some workloads like MongoDB with YCSB and a huge decrease in file
refault, no swap involved. Other common benchmarks have no regression,
and LOC is reduced, with less unexpected OOM, too.

Some of the problems were found in our production environment, and
others were mostly exposed while stress testing during the development
of the LSM/MM/BPF topic on improving MGLRU [1]. This series cleans up
the code base and fixes several performance issues, preparing for
further work.

MGLRU's reclaim loop is a bit complex, and hence these problems are
somehow related to each other. The aging, scan number calculation, and
reclaim loop are coupled together, and the dirty folio handling logic is
quite different, making the reclaim loop hard to follow and the dirty
flush ineffective.

This series slightly cleans up and improves these issues using a scan
budget by calculating the number of folios to scan at the beginning of
the loop, and decouples aging from the reclaim calculation helpers.
Then, move the dirty flush logic inside the reclaim loop so it can kick
in more effectively. These issues are somehow related, and this series
handles them and improves MGLRU reclaim in many ways.

Test results: All tests are done on a 48c96t NUMA machine with 2 nodes
and a 128G memory machine using NVME as storage.

MongoDB
=======
Running YCSB workloadb [2] (recordcount:20000000 operationcount:6000000,
threads:32), which does 95% read and 5% update to generate mixed read
and dirty writeback. MongoDB is set up in a 10G cgroup using Docker, and
the WiredTiger cache size is set to 4.5G, using NVME as storage.

Not using SWAP.

Median of 3 test run, results are stable.

Before:
Throughput(ops/sec): 63050.37725142389
AverageLatency(us): 497.0088950307069
pgpgin 164636727
pgpgout 5551216
workingset_refault_anon 0
workingset_refault_file 34365441

After:
Throughput(ops/sec): 79937.11613530689 (+26.7%, higher is better)
AverageLatency(us): 390.1616943501661  (-21.5%, lower is better)
pgpgin 108820685                       (-33.9%, lower is better)
pgpgout 5406292
workingset_refault_anon 0
workingset_refault_file 18934364       (-44.9%, lower is better)

We can see a significant performance improvement after this series.
The test is done on NVME and the performance gap would be even larger
for slow devices, such as HDD or network storage. We observed over
100% gain for some workloads with slow IO.

Chrome & Node.js [3]
====================
Using Yu Zhao's test script [3], testing on a x86_64 NUMA machine with 2
nodes and 128G memory, using 256G ZRAM as swap and spawn 32 memcg 64
workers:

Before:
Total requests:            81832
Per-worker 95% CI (mean):  [1248.8, 1308.4]
Per-worker stdev:          119.1
Jain's fairness:           0.991530 (1.0 = perfectly fair)
Latency:
[0,1)s     27951   34.16%   34.16%
[1,2)s      7495    9.16%   43.32%
[2,4)s      8140    9.95%   53.26%
[4,8)s     38246   46.74%  100.00%

After:
Total requests:            82413
Per-worker 95% CI (mean):  [1241.4, 1334.0]
Per-worker stdev:          185.3
Jain's fairness:           0.980016 (1.0 = perfectly fair)
Latency:
[0,1)s     27940   33.90%   33.90%
[1,2)s      8772   10.64%   44.55%
[2,4)s      6827    8.28%   52.83%
[4,8)s     38874   47.17%  100.00%

Seems identical, reclaim is still fair and effective, total requests
number seems slightly better.

OOM issue with aging and throttling
===================================
For the throttling OOM issue, it can be easily reproduced using dd and
cgroup limit as demonstrated in patch 12, and fixed by this series.

The aging OOM is a bit tricky, a specific reproducer can be used to
simulate what we encountered in production environment [4]: Spawns
multiple workers that keep reading the given file using mmap, and pauses
for 120ms after one file read batch. It also spawns another set of
workers that keep allocating and freeing a given size of anonymous memory.
The total memory size exceeds the memory limit (eg. 44G anon + 8G file,
which is 52G vs 48G memcg limit).

- MGLRU disabled:
  Finished 128 iterations.

- MGLRU enabled:
  OOM with following info after about ~10-20 iterations:
    [  154.365634] file_anon_mix_p invoked oom-killer: gfp_mask=0xcc0(GFP_KERNEL), order=0, oom_score_adj=0
    [  154.366456] memory: usage 50331648kB, limit 50331648kB, failcnt 354207
    [  154.378941] swap: usage 0kB, limit 9007199254740988kB, failcnt 0
    [  154.379408] Memory cgroup stats for /demo:
    [  154.379544] anon 44352327680
    [  154.380079] file 7187271680

  OOM occurs despite there being still evictable file folios.

- MGLRU enabled after this series:
  Finished 128 iterations.

Worth noting there is another OOM related issue reported in V1 of
this series, which is tested and looking OK now [5].

MySQL:
======

Testing with innodb_buffer_pool_size=26106127360, in a 2G memcg, using
ZRAM as swap and test command:

sysbench /usr/share/sysbench/oltp_read_only.lua --mysql-db=sb \
  --tables=48 --table-size=2000000 --threads=48 --time=600 run

Before:            17237.570000 tps
After patch 5:     17259.975714 tps
After patch 6:     17230.475714 tps
After patch 7:     17250.316667 tps
After patch 8:     17278.933333 tps
After this series: 17265.361667 tps (+0.2%, higher is better)

MySQL is anon folios heavy, involves writeback and file and still
looking good. Seems only noise level changes, no regression in
any step.

FIO:
====
Testing with the following command, where /mnt/ramdisk is a
64G EXT4 ramdisk, each test file is 3G, 6 test runs each in a
12G memcg:

fio --directory=/mnt/ramdisk --filename_format='test.$jobnum.img' \
       --name=cached --numjobs=16 --buffered=1 --ioengine=mmap \
       --rw=randread --random_distribution=zipf:1.2 --norandommap \
       --time_based --ramp_time=1m --runtime=5m --group_reporting

Before:            75912.75 MB/s
After this series: 75907.46 MB/s

Also seem only noise level changes and no regression.

Build kernel:
=============
Build kernel test using ZRAM as swap, on top of tmpfs, in a 3G memcg
using make -j96 and defconfig, measuring system time, 12 test run each.

Before:            2604.29s
After this series: 2538.90s

Also seem only noise level changes, no regression or very slightly better.

Link: https://lore.kernel.org/linux-mm/CAMgjq7BoekNjg-Ra3C8M7=8=75su38w=HD782T5E_cxyeCeH_g@mail.gmail.com/ [1]
Link: https://github.com/brianfrankcooper/YCSB/blob/master/workloads/workloadb [2]
Link: https://lore.kernel.org/all/20221220214923.1229538-1-yuzhao@google.com/ [3]
Link: https://github.com/ryncsn/emm-test-project/tree/master/file-anon-mix-pressure [4]
Link: https://lore.kernel.org/linux-mm/acgNCzRDVmSbXrOE@KASONG-MC4/ [5]

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Changes in v2:
- Rebase on top of mm-new which includes Cgroup V1 fix from
  [ Baolin Wang ].
- Added dirty throttling OOM fix as patch 12, as [ Chen Ridong ]'s
  review suggested that we shouldn't leave the counter and reclaim
  feedback in shrink_folio_list untracked in this series.
- Add a minimal scan number of SWAP_CLUSTER_MAX limit in patch
  "restructure the reclaim loop", the change is trivial but might
  help avoid livelock for tiny cgroups.
- Redo the tests, most test are basically identical to before, but just
  in case, since the patch also solves the throttling issue now, and
  discussed with reports from CachyOS.
- Add a separate patch for variable renaming as suggested by [ Barry
  Song ]. No feature change.
- Improve several comment and code issue [ Axel Rasmussen ].
- Remove no longer needed variable [ Axel Rasmussen ].
- Collect review by.
- Link to v1: https://lore.kernel.org/r/20260318-mglru-reclaim-v1-0-2c46f9eb0508@tencent.com

---
Kairui Song (12):
      mm/mglru: consolidate common code for retrieving evitable size
      mm/mglru: rename variables related to aging and rotation
      mm/mglru: relocate the LRU scan batch limit to callers
      mm/mglru: restructure the reclaim loop
      mm/mglru: scan and count the exact number of folios
      mm/mglru: use a smaller batch for reclaim
      mm/mglru: don't abort scan immediately right after aging
      mm/mglru: simplify and improve dirty writeback handling
      mm/mglru: remove no longer used reclaim argument for folio protection
      mm/vmscan: remove sc->file_taken
      mm/vmscan: remove sc->unqueued_dirty
      mm/vmscan: unify writeback reclaim statistic and throttling

 mm/vmscan.c | 308 ++++++++++++++++++++++++++----------------------------------
 1 file changed, 132 insertions(+), 176 deletions(-)
---
base-commit: e4b3c4494ae831396aded19f30132826a0d63031
change-id: 20260314-mglru-reclaim-1c9d45ac57f6

Best regards,
--  
Kairui Song <kasong@tencent.com>

