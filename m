From: Zhang Peng <zippermonkey@icloud.com>
Subject: [PATCH 0/2] mm: batch TLB flushing for dirty folios in vmscan
Date: Mon, 09 Mar 2026 16:17:40 +0800
Message-Id: <20260309-batch-tlb-flush-v1-0-eb8fed7d1a9e@icloud.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACSCrmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDYwNL3aTEkuQM3ZKcJN20nNLiDF0LS+M0g1RTsyQTSzMloK6CotS0zAq
 widGxtbUADrHzlGEAAAA=
X-Change-ID: 20260309-batch-tlb-flush-893f0e56b496
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Qi Zheng <zhengqi.arch@bytedance.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Michal Hocko <mhocko@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>, Zhang Peng <bruzzhang@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773044270; l=3059;
 i=zippermonkey@icloud.com; s=20260309; h=from:subject:message-id;
 bh=Hxlyr94vhT6tceNWkfUX7FnAnLC5MO+FeAUWHj402F0=;
 b=sxFReAs8wK3VKflfARWnWgk7f6wn4fNFW99rIJrAv5x9OfnVaMTXYyL4a3bY+wRiQydi+yVgG
 mEgfk97EZfFAx4YusLrPnkMyYxiSThIU+eO6DqO9mz6vCP33ltXCVv6
X-Developer-Key: i=zippermonkey@icloud.com; a=ed25519;
 pk=tPCLpFnBfIyHsp0k7eaUTUREEa36bQNW/69X+NS8wBU=
X-Endpoint-Received: by B4 Relay for zippermonkey@icloud.com/20260309 with auth_id=671
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduces batch TLB flushing optimization for dirty folios
during memory reclaim, aiming to reduce IPI overhead on multi-core systems.

Background
----------
Currently, when performing pageout in memory reclaim, try_to_unmap_flush_dirty()
is called for each dirty folio individually. On multi-core systems, this causes
frequent IPIs which can significantly impact performance.

Approach
--------
This patch series accumulates dirty folios into batches and performs a single
TLB flush for the entire batch, rather than flushing for each individual folio.

Changes
-------
Patch 1: Refactor shrink_folio_list() to improve code readability and
         maintainability by extracting common logic into helper functions:
         - folio_active_bounce(): Handle folio activation logic
         - folio_free(): Handle folio freeing logic
         - pageout_one(): Handle single folio pageout logic

Patch 2: Implement batch TLB flushing logic. Dirty folios are accumulated
         in batches and a single TLB flush is performed for each batch
         before calling pageout.

Testing
-------
The benchmark script uses stress-ng to compare TLB shootdown behavior before and
after this patch. It constrains a stress-ng workload via memcg to force reclaim
through shrink_folio_list(), reporting TLB shootdowns and IPIs.

Core benchmark command: stress-ng --vm 16 --vm-bytes 2G --vm-keep --timeout 60

==========================================================================
                 batch_dirty_tlb_flush Benchmark Results
==========================================================================
  Kernel: 7.0.0-rc1+   CPUs: 16
  MemTotal: 31834M   SwapTotal: 8191M
  memcg limit: 512M   alloc: 2G   workers: 16   duration: 60s
--------------------------------------------------------------------------
Metric                 Before        After             Delta (abs / %)
--------------------------------------------------------------------------
bogo ops/s             28238.63      35833.97          +7595.34 (+26.9%)
TLB shootdowns         55428953      17621697          -37807256 (-68.2%)
Function call IPIs     34073695      14498768          -19574927 (-57.4%)
pgscan_anon (pages)    52856224      60252894          7396670 (+14.0%)
pgsteal_anon (pages)   29004962      34054753          5049791 (+17.4%)
--------------------------------------------------------------------------

Suggested-by: Kairui Song <kasong@tencent.com>
Signed-off-by: Zhang Peng <bruzzhang@tencent.com>
---
bruzzhang (2):
      mm/vmscan: refactor shrink_folio_list for readability and maintainability
      mm, vmscan: flush TLB for every 31 folios evictions

 include/linux/vmstat.h |   1 +
 mm/vmscan.c            | 387 +++++++++++++++++++++++++++++++------------------
 2 files changed, 245 insertions(+), 143 deletions(-)
---
base-commit: 49cb736d092aaa856283e33b78ec3afb3964d82f
change-id: 20260309-batch-tlb-flush-893f0e56b496

Best regards,
-- 
Zhang Peng <zippermonkey@icloud.com>

