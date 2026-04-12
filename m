From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v5 00/14] mm/mglru: improve reclaim loop and dirty folio
 handling
Date: Mon, 13 Apr 2026 00:48:14 +0800
Message-Id: <20260413-mglru-reclaim-v5-0-8eaeacbddc44@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2XMSwrCMBSF4a2UjI3k3cSR+xAH8fZGA7aVtBZFu
 nfTgljr8Bz4/hfpMEXsyK54kYRD7GLb5KE3BYGLb85IY5U3EUwYJrmi9fma7jQhXH2sKQdXKe1
 Bl8GQbG4JQ3zMvcMx70vs+jY95/zAp/dTsqvSwCmjApQJDk9MM7vvsQFs+i20NZlag1h44dZeZ
 H/S0ktTWs0l/Hv59YrJtZfZe2E1hsqE4Pi/V0tfrr3K3lkIsgLjNHe/fhzHNxFlI1hsAQAA
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
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776012497; l=11303;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=YzUoGyFaUO/PlsOFT5dYcmhxeyksZAyrB05HjT7sTTU=;
 b=YEw6pzSZaevYNfVw1Fvx8bPX/G6R5UrH3L1tIaaZq6bbagBlWvAdu+QhiMwtZ2y8RlFh3o7SH
 wsxTA9ab2QvCmLyOK9YRdg/mrPskfF6jqBbLZr/UQhXZrVzRMA6jzQF
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series is based on mm-unstable, also applies to mm-new.

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

Before:
Throughput(ops/sec): 62485.02962831822
AverageLatency(us): 500.9746963330107
pgpgin 159347462
pgpgout 5413332
workingset_refault_anon 0
workingset_refault_file 34522071

After:
Throughput(ops/sec): 79760.71784646061 (+27.6%, higher is better)
AverageLatency(us): 391.25169970043726 (-21.9%, lower is better)
pgpgin 111093923                       (-30.3%, lower is better)
pgpgout 5437456
workingset_refault_anon 0
workingset_refault_file 19566366       (-43.3%, lower is better)

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
Total requests:            79915
Per-worker 95% CI (mean):  [1233.9, 1263.5]
Per-worker stdev:          59.2
Jain's fairness:           0.997795 (1.0 = perfectly fair)
Latency:
Bucket     Count      Pct    Cumul
[0,1)s     26859   33.61%   33.61%
[1,2)s      7818    9.78%   43.39%
[2,4)s      5532    6.92%   50.31%
[4,8)s     39706   49.69%  100.00%

After:
Total requests:            81382
Per-worker 95% CI (mean):  [1241.9, 1301.3]
Per-worker stdev:          118.8
Jain's fairness:           0.991480 (1.0 = perfectly fair)
Latency:
Bucket     Count      Pct    Cumul
[0,1)s     26696   32.80%   32.80%
[1,2)s      8745   10.75%   43.55%
[2,4)s      6865    8.44%   51.98%
[4,8)s     39076   48.02%  100.00%

Reclaim is still fair and effective, total requests number seems
slightly better.

OOM issue with aging and throttling
===================================
For the throttling OOM issue, it can be easily reproduced using dd and
cgroup limit as demonstrated in patch 14, and fixed by this series.

The aging OOM is a bit tricky, a specific reproducer can be used to
simulate what we encountered in production environment [4]:
Spawns multiple workers that keep reading the given file using mmap,
and pauses for 120ms after one file read batch. It also spawns another
set of workers that keep allocating and freeing a given size of
anonymous memory. The total memory size exceeds the memory limit
(eg. 14G anon + 8G file, which is 22G vs a 16G memcg limit).

- MGLRU disabled:
  Finished 128 iterations.

- MGLRU enabled:
  OOM with following info after about ~10-20 iterations:
    [   62.624130] file_anon_mix_p invoked oom-killer: gfp_mask=0xcc0(GFP_KERNEL), order=0, oom_score_adj=0
    [   62.624999] memory: usage 16777216kB, limit 16777216kB, failcnt 24460
    [   62.640200] swap: usage 0kB, limit 9007199254740988kB, failcnt 0
    [   62.640823] Memory cgroup stats for /demo:
    [   62.641017] anon 10604879872
    [   62.641941] file 6574858240

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

Before:            17260.781429 tps
After this series: 17266.842857 tps

MySQL is anon folios heavy, involves writeback and file and still
looking good. Seems only noise level changes, no regression.

FIO:
====
Testing with the following command, where /mnt/ramdisk is a
64G EXT4 ramdisk, each test file is 3G, in a 10G memcg,
6 test run each:

fio --directory=/mnt/ramdisk --filename_format='test.$jobnum.img' \
  --name=cached --numjobs=16 --size=3072M --buffered=1 --ioengine=mmap \
  --rw=randread --norandommap --time_based \
  --ramp_time=1m --runtime=5m --group_reporting

Before:            9196.481429 MB/s
After this series: 9256.105000 MB/s

Also seem only noise level changes and no regression or slightly better.

Build kernel:
=============
Build kernel test using ZRAM as swap, on top of tmpfs, in a 3G memcg
using make -j96 and defconfig, measuring system time, 12 test run each.

Before:            2589.63s
After this series: 2543.58s

Also seem only noise level changes, no regression or very slightly better.

Link: https://lore.kernel.org/linux-mm/CAMgjq7BoekNjg-Ra3C8M7=8=75su38w=HD782T5E_cxyeCeH_g@mail.gmail.com/ [1]
Link: https://github.com/brianfrankcooper/YCSB/blob/master/workloads/workloadb [2]
Link: https://lore.kernel.org/all/20221220214923.1229538-1-yuzhao@google.com/ [3]
Link: https://github.com/ryncsn/emm-test-project/tree/master/file-anon-mix-pressure [4]
Link: https://lore.kernel.org/linux-mm/acgNCzRDVmSbXrOE@KASONG-MC4/ [5]

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Changes in v5:
- Add back a more moderate minimal batch limit for each reclaim loop:
  https://lore.kernel.org/linux-mm/adYP81AhpNf0znp3@KASONG-MC4/
- Collect review-by.
- Link to v4: https://patch.msgid.link/20260407-mglru-reclaim-v4-0-98cf3dc69519@tencent.com

Changes in v4:
- Remove the minimal scan batch limit, and add rotate for
  unevictable memcg as reported by sashiko:
  https://lore.kernel.org/linux-mm/ac8xVN82LBLDZpIO@KASONG-MC4/
- Slightly imporove a few commit messages.
- Reran the test and seems identical with before so data are unchanged.
- Collect review-by.
- Link to v3: https://patch.msgid.link/20260403-mglru-reclaim-v3-0-a285efd6ff91@tencent.com

Changes in v3:
- Don't force scan at least SWAP_CLUSTER_MAX pages for each reclaim
  loop. If the LRU is too small, adjust it accordingly. Now the
  multi-cgroup scan balance looked even better for tiny cgroups:
  https://lore.kernel.org/linux-mm/aciejkdIHyXPNS9Y@KASONG-MC4/
- Add one patch to remove the swap constraint check in isolate_folio. In
  theory, it's fine, and both stress test and performance test didn't
  show any issue:
  https://lore.kernel.org/linux-mm/CAMgjq7C8TCsK99p85i3QzGCwgkXscTfFB6XCUTWQOcuqwHQa2Q@mail.gmail.com/
- I reran most tests, all seem identical, so most data is kept.
  Intermediate test results are dropped. I ran tests on most patches
  individually, and there is no problem, but the series is getting too
  long, and posting them makes it harder to read and unnecessary.
- Split previously patch 8 into two patches as suggested [ Shakeel Butt ],
  also some test result is collected to support the design:
  https://lore.kernel.org/linux-mm/ac44BVOvOm8lhVvj@KASONG-MC4/#t
  I kept Axel's review-by since the code is identical.
- Call try_to_inc_min_seq twice to avoid stale empty gen and drop
  its return argument [ Baolin Wang ]
- Move a few lines of code between patches to where they fits better,
  the final result is identical [ Baolin Wang ].
- Collect tested by and update test setup [ Leno Hou ]
- Collect review by.
- Update a few commit message [ Shakeel Butt ].
- Link to v2: https://patch.msgid.link/20260329-mglru-reclaim-v2-0-b53a3678513c@tencent.com

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
Kairui Song (14):
      mm/mglru: consolidate common code for retrieving evictable size
      mm/mglru: rename variables related to aging and rotation
      mm/mglru: relocate the LRU scan batch limit to callers
      mm/mglru: restructure the reclaim loop
      mm/mglru: scan and count the exact number of folios
      mm/mglru: use a smaller batch for reclaim
      mm/mglru: don't abort scan immediately right after aging
      mm/mglru: remove redundant swap constrained check upon isolation
      mm/mglru: use the common routine for dirty/writeback reactivation
      mm/mglru: simplify and improve dirty writeback handling
      mm/mglru: remove no longer used reclaim argument for folio protection
      mm/vmscan: remove sc->file_taken
      mm/vmscan: remove sc->unqueued_dirty
      mm/vmscan: unify writeback reclaim statistic and throttling

 mm/vmscan.c | 330 ++++++++++++++++++++++++++----------------------------------
 1 file changed, 142 insertions(+), 188 deletions(-)
---
base-commit: 196ab4af58d724f24335fed3da62920c3cea945f
change-id: 20260314-mglru-reclaim-1c9d45ac57f6

Best regards,
--  
Kairui Song <kasong@tencent.com>

