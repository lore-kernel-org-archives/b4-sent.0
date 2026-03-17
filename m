From: Kairui Song <kasong@tencent.com>
Subject: [PATCH 0/8] mm/mglru: improve reclaim loop and dirty folio
 handling
Date: Wed, 18 Mar 2026 03:08:56 +0800
Message-Id: <20260318-mglru-reclaim-v1-0-2c46f9eb0508@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDY0MT3dz0nKJS3aLU5JzEzFxdw2TLFBPTxGRT8zQzJaCegqLUtMwKsHn
 RsbW1AG6uAetfAAAA
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
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773774704; l=8290;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=eZeE1mwOeuM5/QjG3PuY0PEhuNcZEzv0BBmgZNb4+Rs=;
 b=jhx+mMde0iZszca8qAee8NTHEc6ojHlS8lIfUW/7+CJ90slmaadJUMyraGAtguVBxYhZ22XVp
 jG77v9Ix9CXAVejof5vdGyIGk29v2TxrZLy5Hwad9vtBlrYKh/KQ9wc
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series cleans up and slightly improves MGLRU's reclaim loop and
dirty flush logic. As a result, we can see an up to ~50% reduce of file
faults and 30% increase in MongoDB throughput with YCSB and no swap
involved, other common benchmarks have no regression, and LOC is
reduced, with less unexpected OOM in our production environment.

Some of the problems were found in our production environment, and
others are mostly exposed while stress testing the LFU-like design as
proposed in the LSM/MM/BPF topic this year [1]. This series has no
direct relationship to that topic, but it cleans up the code base and
fixes several strange behaviors that make the test result of the
LFU-like design not as good as expected.

MGLRU's reclaim loop is a bit complex, and hence these problems are
somehow related to each other. The aging, scan number calculation, and
reclaim loop are coupled together, and the dirty folio handling logic is
quite different, making the reclaim loop hard to follow and the dirty
flush ineffective too.

This series slightly cleans up and improves the reclaim loop using a
scan budget by calculating the number of folios to scan at the beginning
of the loop, and decouples aging from the reclaim calculation helpers
Then move the dirty flush logic inside the reclaim loop so it can kick
in more effectively. These issues are somehow related, and this series
handles them and improves MGLRU reclaim in many ways.

Test results: All tests are done on a 48c96t NUMA machine with 2 nodes
and 128G memory machine using NVME as storage.

MongoDB
=======
Running YCSB workloadb [2] (recordcount:20000000 operationcount:6000000,
threads:32), which does 95% read and 5% update to generate mixed read
and dirty writeback. MongoDB is set up in a 10G cgroup using Docker, and
the WiredTiger cache size is set to 4.5G, using NVME as storage.

Not using SWAP.

Median of 3 test run, results are stable.

Before:
Throughput(ops/sec): 61642.78008938203
AverageLatency(us):  507.11127774145166
pgpgin 158190589
pgpgout 5880616
workingset_refault 7262988

After:
Throughput(ops/sec): 80216.04855744806  (+30.1%, higher is better)
AverageLatency(us):  388.17633477268913 (-23.5%, lower is better)
pgpgin 101871227                        (-35.6%, lower is better)
pgpgout 5770028
workingset_refault 3418186              (-52.9%, lower is better)

We can see a significant performance improvement after this series for
file cache heavy workloads like this. The test is done on NVME and the
performance gap would be even larger for slow devices, we observed
>100% gain for some other workloads running on HDD devices.

Chrome & Node.js [3]
====================
Using Yu Zhao's test script [3], testing on a x86_64 NUMA machine with 2
nodes and 128G memory, using 256G ZRAM as swap and spawn 32 memcg 64
workers:

Before:
Total requests:            77920
Per-worker 95% CI (mean):  [1199.9, 1235.1]
Per-worker stdev:          70.5
Jain's fairness:           0.996706 (1.0 = perfectly fair)
Latency:
Bucket     Count      Pct    Cumul
[0,1)s     25649   32.92%   32.92%
[1,2)s      7759    9.96%   42.87%
[2,4)s      5156    6.62%   49.49%
[4,8)s     39356   50.51%  100.00%

After:
Total requests:            79564
Per-worker 95% CI (mean):  [1224.2, 1262.2]
Per-worker stdev:          76.1
Jain's fairness:           0.996328 (1.0 = perfectly fair)
Latency:
Bucket     Count      Pct    Cumul
[0,1)s     25485   32.03%   32.03%
[1,2)s      8661   10.89%   42.92%
[2,4)s      6268    7.88%   50.79%
[4,8)s     39150   49.21%  100.00%

Seems identical, reclaim is still fair and effective, total requests
number seems slightly better.

OOM issue [4]
=============
Testing with a specific reproducer [4] to simulate what we encounterd in
production environment. Still using the same test machine but one node
is used as pmem ramdisk following steps in the reproducer, no SWAP used.

This reproducer spawns multiple workers that keep reading the given file
using mmap, and pauses for 120ms after one file read batch. It also
spawns another set of workers that keep allocating and freeing a
given size of anonymous memory. The total memory size exceeds the
memory limit (eg. 44G anon + 8G file, which is 52G vs 48G memcg limit).
But by evicting the file cache, the workload should hold just fine,
especially given that the file worker pauses after every batch, allowing
other workers to catch up.

- MGLRU disabled:
  Finished 128 iterations.

- MGLRU enabled:
  Hung or OOM with following info after about ~10-20 iterations:

    [  357.332946] file_anon_mix_pressure invoked oom-killer: gfp_mask=0xcc0(GFP_KERNEL), order=0, oom_score_adj=0
    ... <snip> ...
    [  357.333827] memory: usage 50331648kB, limit 50331648kB, failcnt 90907
    [  357.347728] swap: usage 0kB, limit 9007199254740988kB, failcnt 0
    [  357.348192] Memory cgroup stats for /demo:
    [  357.348314] anon 46724382720
    [  357.348963] file 4160753664

  OOM occurs despite there is still evictable file folios.

- MGLRU enabled after this series:
  Finished 128 iterations.

With aging blocking reclaim, the OOM will be much more likely to occur.
This issue is mostly fixed by patch 6 and result is much better, but
this series is still only the first step to improve file folio reclaim
for MGLRU, as there are still cases where file folios can't be
effectively reclaimed.

MySQL:
======

Testing with innodb_buffer_pool_size=26106127360, in a 2G memcg, using
ZRAM as swap and test command:

sysbench /usr/share/sysbench/oltp_read_only.lua --mysql-db=sb \
  --tables=48 --table-size=2000000 --threads=96 --time=600 run

Before:         22343.701667 tps
After patch 4:  22327.325000 tps
After patch 5:  22373.224000 tps
After patch 6:  22321.174000 tps
After patch 7:  22625.961667 tps (+1.26%, higher is better)

MySQL is anon folios heavy but still looking good. Seems only noise level
changes, no regression.

FIO:
====
Testing with the following command, where /mnt is an EXT4 ramdisk, 6
test runs each in a 10G memcg:

fio -name=cached --numjobs=16 --filename=/mnt/test.img --buffered=1 \
  --ioengine=io_uring --iodepth=128 --iodepth_batch_submit=32 \
  --iodepth_batch_complete=32 --rw=randread \
  --random_distribution=zipf:1.2 --norandommap --time_based \
  --ramp_time=1m --runtime=10m --group_reporting

Before:        32039.56 MB/s
After patch 3: 32751.50 MB/s
After patch 4: 32703.03 MB/s
After patch 5: 33395.52 MB/s
After patch 6: 32031.51 MB/s
After patch 7: 32534.29 MB/s

Also seem only noise level changes and no regression.

Build kernel:
=============
Build kernel test using ZRAM as swap, on top of tmpfs, in a 3G memcg
using make -j96 and defconfig, measuring system time, 8 test run each.

Before:        2881.41s
After patch 3: 2894.09s
After patch 4: 2846.73s
After patch 5: 2847.91s
After patch 6: 2835.17s
After patch 7: 2842.90s

Also seem only noise level changes, no regression or very slightly better.

Link: https://lore.kernel.org/linux-mm/CAMgjq7BoekNjg-Ra3C8M7=8=75su38w=HD782T5E_cxyeCeH_g@mail.gmail.com/ [1]
Link: https://github.com/brianfrankcooper/YCSB/blob/master/workloads/workloadb [2]
Link: https://lore.kernel.org/all/20221220214923.1229538-1-yuzhao@google.com/ [3]
Link: https://github.com/ryncsn/emm-test-project/tree/master/file-anon-mix-pressure [4]

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Kairui Song (8):
      mm/mglru: consolidate common code for retrieving evitable size
      mm/mglru: relocate the LRU scan batch limit to callers
      mm/mglru: restructure the reclaim loop
      mm/mglru: scan and count the exact number of folios
      mm/mglru: use a smaller batch for reclaim
      mm/mglru: don't abort scan immediately right after aging
      mm/mglru: simplify and improve dirty writeback handling
      mm/vmscan: remove sc->file_taken

 mm/vmscan.c | 191 ++++++++++++++++++++++++++----------------------------------
 1 file changed, 81 insertions(+), 110 deletions(-)
---
base-commit: dffde584d8054e88e597e3f28de04c7f5d191a67
change-id: 20260314-mglru-reclaim-1c9d45ac57f6

Best regards,
-- 
Kairui Song <kasong@tencent.com>

