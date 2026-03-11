From: Leno Hou <lenohou@gmail.com>
Subject: [PATCH v2 0/2] mm/mglru: fix cgroup OOM during MGLRU state
 switching
Date: Wed, 11 Mar 2026 20:09:41 +0800
Message-Id: <20260311-b4-switch-mglru-v2-v2-0-080cb9321463@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIVbsWkC/0XMQQ6CMBBA0auQWTukHQhUV97DuCg40EkoJS2gC
 eHuNm5cvsX/BySOwgluxQGRd0kS5gy6FNA7O4+M8soGUtSoSmvsakxvWXuHfpzihjuh6a7UWFW
 Zuhogh0vkQT6/6eOZPcTgcXWR7X9FZHSjlTJlq1rUOPEcXNjuo7cylX3wcJ5ffswa350AAAA=
X-Change-ID: 20260311-b4-switch-mglru-v2-8b926a03843f
To: Andrew Morton <akpm@linux-foundation.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Jialing Wang <wjl.linux@gmail.com>, 
 Yafang Shao <laoar.shao@gmail.com>, Yu Zhao <yuzhao@google.com>, 
 Kairui Song <ryncsn@gmail.com>, Bingfang Guo <bfguo@icloud.com>, 
 Barry Song <baohua@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Leno Hou <lenohou@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773230982; l=4299;
 i=lenohou@gmail.com; s=20260311; h=from:subject:message-id;
 bh=i6se0oZRXKFtnBz68nKbLYLaOr8ZsBgTi4bTAsYKR+g=;
 b=ho3bW5vUlOrRO0GDbulfWdvRJRo9/EGG7KO4DMxo6UEspNVPpB+6jNaXyszijvKaJJhZZGCdD
 +ak1JLtjAe1CC8E4+oP2ZnFUU3HO5YqHJ4BG/onrLyCS80RLnItCeo4
X-Developer-Key: i=lenohou@gmail.com; a=ed25519;
 pk=8AVHXYurzu1kOGjk9rwvxovwSCynBkv2QAcOvSIe1rw=
X-Endpoint-Received: by B4 Relay for lenohou@gmail.com/20260311 with auth_id=674
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the Multi-Gen LRU (MGLRU) state is toggled dynamically, a race
condition exists between the state switching and the memory reclaim
path. This can lead to unexpected cgroup OOM kills, even when plenty of
reclaimable memory is available.

Problem Description
==================

The issue arises from a "reclaim vacuum" during the transition.

1. When disabling MGLRU, lru_gen_change_state() sets lrugen->enabled to
   false before the pages are drained from MGLRU lists back to
   traditional LRU lists.
2. Concurrent reclaimers in shrink_lruvec() see lrugen->enabled as false
   and skip the MGLRU path.
3. However, these pages might not have reached the traditional LRU lists
   yet, or the changes are not yet visible to all CPUs due to a lack of
   synchronization.
4. get_scan_count() subsequently finds traditional LRU lists empty,
   concludes there is no reclaimable memory, and triggers an OOM kill.

A similar race can occur during enablement, where the reclaimer sees
the new state but the MGLRU lists haven't been populated via
fill_evictable() yet.

Solution
========

Introduce a 'draining' state (`lru_drain_core`) to bridge the
transition. When transitioning, the system enters this intermediate state
where the reclaimer is forced to attempt both MGLRU and traditional reclaim
paths sequentially. This ensures that folios remain visible to at least
one reclaim mechanism until the transition is fully materialized across all
CPUs.

Changes
=======

v2:
- Repalce with a static branch `lru_drain_core` to track the transition state.
- Ensures all LRU helpers correctly identify page state by checking
  folio_lru_gen(folio) != -1 instead of relying solely on global flags.
- Maintain workingset refault context across MGLRU state transitions
- Fix build error when CONFIG_LRU_GEN is disabled.

v1:
- Use smp_store_release() and smp_load_acquire() to ensure the visibility
  of 'enabled' and 'draining' flags across CPUs.
- Modify shrink_lruvec() to allow a "joint reclaim" period. If an lruvec
  is in the 'draining' state, the reclaimer will attempt to scan MGLRU
  lists first, and then fall through to traditional LRU lists instead
  of returning early. This ensures that folios are visible to at least
  one reclaim path at any given time.

This effectively eliminates the race window that previously triggered OOMs
under high memory pressure.

Reproduction
===========

The issue was consistently reproduced on v6.1.157 and v6.18.3 using
a high-pressure memory cgroup (v1) environment.

Reproduction steps:
1. Create a 16GB memcg and populate it with 10GB file cache (5GB active)
   and 8GB active anonymous memory.
2. Toggle MGLRU state while performing new memory allocations to force
   direct reclaim.

Reproduction script
===================
```bash

MGLRU_FILE="/sys/kernel/mm/lru_gen/enabled"
CGROUP_PATH="/sys/fs/cgroup/memory/memcg_oom_test"

switch_mglru() {
    local orig_val=$(cat "$MGLRU_FILE")
    if [[ "$orig_val" != "0x0000" ]]; then
        echo n > "$MGLRU_FILE" &
    else
        echo y > "$MGLRU_FILE" &
    fi
}

mkdir -p "$CGROUP_PATH"
echo $((16 * 1024 * 1024 * 1024)) > "$CGROUP_PATH/memory.limit_in_bytes"
echo $$ > "$CGROUP_PATH/cgroup.procs"

dd if=/dev/urandom of=/tmp/test_file bs=1M count=10240
dd if=/tmp/test_file of=/dev/null bs=1M # Warm up cache

stress-ng --vm 1 --vm-bytes 8G --vm-keep -t 600 &
sleep 5

switch_mglru
stress-ng --vm 1 --vm-bytes 2G --vm-populate --timeout 5s || echo "OOM Triggered"

grep oom_kill "$CGROUP_PATH/memory.oom_control"
```

Signed-off-by: Leno Hou <lenohou@gmail.com>
---
Leno Hou (2):
      mm/mglru: fix cgroup OOM during MGLRU state switching
      mm/mglru: maintain workingset refault context across state transitions

 include/linux/mm_inline.h |  5 +++++
 mm/rmap.c                 |  2 +-
 mm/swap.c                 | 14 ++++++++------
 mm/vmscan.c               | 49 ++++++++++++++++++++++++++++++++++++++---------
 mm/workingset.c           | 19 ++++++++++++------
 5 files changed, 67 insertions(+), 22 deletions(-)
---
base-commit: 6de23f81a5e08be8fbf5e8d7e9febc72a5b5f27f
change-id: 20260311-b4-switch-mglru-v2-8b926a03843f

Best regards,
-- 
Leno Hou <lenohou@gmail.com>

