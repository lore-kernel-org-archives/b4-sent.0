From: Kairui Song <kasong@tencent.com>
Subject: [PATCH RFC 00/13] mm/swap: introduce priority queue to remove
 global cluster cache and plist
Date: Tue, 14 Jul 2026 01:25:38 +0800
Message-Id: <20260714-swap-pcp-priq-v1-0-de9b164ed419@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDUyNL3eLyxALdgmQgLsos1DWzSDFOsTQyNTW3SFYC6ikoSk3LrACbF60
 U5OasFAsRLC5NykpNLgGZpFRbCwBgA1S8dgAAAA==
X-Change-ID: 20260529-swap-pcp-priq-68d3d925578c
To: linux-mm@kvack.org
Cc: linux-kernel@vger.kernel.org, Andrew Morton <akpm@linux-foundation.org>, 
 Chris Li <chrisl@kernel.org>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <baoquan.he@linux.dev>, Barry Song <baohua@kernel.org>, 
 Youngjun Park <youngjun.park@lge.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Kairui Song <kasong@tencent.com>, 
 Baoquan He <baoquan.he@linux.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783963612; l=7745;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=Kx8G4hqmRXWTsJ6zc3SII4f1OYOrJ6E6dUx1yBEVJmE=;
 b=c+w0tFeESadMAszrv3sx20936HsyfVQ7Hc+brIbOgFuU2E+yGJRfqeo4EUJAmxiX9Tf7VKPif
 v3jUiio/AdmCNj+0/oNQb7yHSBR8vomFy26HHHvVztfvR0NyhQchvw1
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

This series introduces a new way to fairly distribute the IO to multiple
swap devices, completely gets rid of the mutable plist and global lock,
hence removes the global cluster cache and allows allocation and
rotation to happen more freely. This is especially helpful for swap
tiering or layered swap. Sending as RFC for review first as tiering
should land first, this can rebase and join later as an optimization,
and there are a few items that can still be improved based on this
series. I specifically kept the tiering and layered ideas in mind to
make the new design friendly for new ideas like these and tested a
few different appraoches locally.

As a dependency, this also cleanup and rework the locking pattern for swap
device management. All swap devices and the newly introduced percpu reader
priority queue are now guarded by a percpu rwsem for better scalability
and a more future-proof design.

Previously, each swap device had its own percpu cluster cache. To improve
performance, commit 1b7e90020eb7 ("mm, swap: use percpu cluster as
allocation fast path") moved the cluster cache to a global scope and let
every device share the same global cache, so we don't need to always
touch the plist. Fast swap allocation will just use each CPU's cluster
cache. Device rotation is still always handled by the plist when one
cluster is drained in the cluster cache, which bundled cluster allocation
with rotation. It works, but this whole design caused several
long-standing issues:

1) The global percpu cluster cache sitting above device selection
   fundamentally conflicts with concepts like swap tiering and layered
   swap allocation. We need to bypass certain swap devices, so we have
   to bypass the cache as well because the cache doesn't have stable
   ownership. That would result in very poor performance. And there
   are other problems like priority inversion and device rotation.
   These are described in more detail in the swap tier series [1].

2) The plist itself requires plist_requeue() to rotate devices for
   round-robin, which needs swap_avail_lock held. Allocators must
   cycle: lock -> pick -> unlock -> allocate -> lock -> rotate. All
   CPUs contend on the same global list head, and the design is
   neither flexible nor robust.

3) Rotation is considered the slow path. The fast / slow path design to
   avoid touching the plist has caused workarounds like commit
   9fb749cd15078 ("mm, swap: do not perform synchronous discard during
   allocation"), we can't stably grab an actual device before touching
   the plist, so the design is suboptimal and has many constraints.

4) We don't have a clear rule of how rotation works. The round-robin
   rotation is strongly bundled to the cluster allocation algorithm,
   and cluster drain is unpredictable. We will have a roughly 2M
   rotation block size but that varies from time to time.

This series gets rid of all these issues step by step:

Patches 1-4: Cleanups and infrastructure
Patches 5-7: Lock and accounting consolidation
Patch 8: Revert the global percpu cluster by YoungJun
Patch 9: This is the core change: percpu reader swap queue
Patch 10: Remove the old swap_avail_head plist (no longer needed)
Patch 11: Drop the global sync discard workaround
Patches 12-13: Drop plist entirely

The design is described in Patch 9. In general, devices of the same
priority are arranged in the same static ring. The ring itself is mostly
read only, but each CPU's reader of the ring rotates, with a counter
built into each reader. The counter is adjustable and controls the
rotation pace. The priority ring design should fit well with the current
tiering design.

The performance is looking on par with the old global cluster cache
design, while it enables more potential features like weighted
interleave or adjustable shard value for device rotation of same
priority (by simply adjusting the counter value, SWAP_ROUND_ROBIN_QUOTA).

Testing with 8 ZRAM devices, running a typical build linux kernel test,
with make -j96 in a 2G memcg (Using 8 ZRAM, might not be a very common
setup but there are such configs to avoid lock contention inside each
ZRAM device, and this also simulates having multiple high speed block
devices as SWAP), measure average system time for 12 testruns:

Before:          6633.09s
After patch  8: 12294.74s (Move the global cluster cache back to device scope)
After patch 13:  6551.27s (Introduce the percpu queue to avoid device contention)

And doing the workload in a 3G memcg, avg sys time of 12 testrun:

Before:          3312.63s
After patch  8:  6450.35s
After patch 13:  3311.38s

Using 12 brd, testing with: usemem --init-time -O -y -x -n 32 1536M
Before:         4347.58 MB/s
After patch  8: 2773.39 MB/s
After patch 13: 4345.04 MB/s

Patch 8 removed the global percpu cluster cache, so we are touching the
plist before accessing the cache, and it's very clear that the performance
is really bad. Then with the new percpu reader queue design, we got rid
of the plist, performance is on-par or better, while there is no more
slow / fast path design, and cache stays inside each device. We can
always select a device based on priority before accessing the cache.

And the shard size is adjustable through SWAP_ROUND_ROBIN_QUOTA which is
hardcoded for now to 2M, changing that effect the performance in
different ways too.

And the distributions are fair among devices during the test (similiar
with brd):

NAME       TYPE      SIZE   USED PRIO
/dev/zram0 partition   8G 692.4M   -1
/dev/zram1 partition   8G 693.2M   -1
/dev/zram2 partition   8G 694.9M   -1
/dev/zram3 partition   8G 694.1M   -1
/dev/zram4 partition   8G 695.5M   -1
/dev/zram5 partition   8G 695.1M   -1
/dev/zram6 partition   8G 694.3M   -1
/dev/zram7 partition   8G 693.6M   -1

This work was discussed several times on the mailing list [2] and
rebased and reworked to leave room for future tiering, optimization,
e.g. by assigning separate iterators per priority ring.

One patch from YoungJun is included as well [3].

Link: https://lore.kernel.org/linux-mm/20260713025644.170839-1-youngjun.park@lge.com/ [1]
Link: https://lore.kernel.org/linux-mm/CAMgjq7BhOn48xEyC=2j837R7qddfjeBVHMiRqdx8no4ZEBpBLg@mail.gmail.com/ [2]
Link: https://lore.kernel.org/linux-mm/20260126065242.1221862-5-youngjun.park@lge.com/ [3]

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Kairui Song (12):
      mm/swap: remove unused parameter for reading swap header
      mm/swap: slightly cleanup the code for hibernation error handling
      mm/swap: cleanup and document swap device availability flag usage
      mm/swap: introduce swap device iteration helper
      mm/swap: change the swapon lock into a percpu rwsem
      mm/swap: remove swapon mutex and update proc reader
      mm/swap: consolidate swap inuse accounting helpers
      mm/swap: add priority queue for swap device allocation
      mm/swap: remove available list
      mm/swap: perform sync discard on single device more proactively
      mm/swap: drop swap active plist
      lib/plist.c: remove requeue function

Youngjun Park (1):
      mm/swap: change back to use each swap device's percpu cluster

 include/linux/plist.h |    2 -
 include/linux/swap.h  |   42 +-
 lib/plist.c           |   64 ---
 mm/swap.h             |   12 +-
 mm/swapfile.c         | 1165 +++++++++++++++++++++++++++++--------------------
 5 files changed, 718 insertions(+), 567 deletions(-)
---
base-commit: bdc38bfc1262e3d1432afadd2aa2ffd83d139dbb
change-id: 20260529-swap-pcp-priq-68d3d925578c

Best regards,
--  
Kairui Song <kasong@tencent.com>

