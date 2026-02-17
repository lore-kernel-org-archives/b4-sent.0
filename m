From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v3 00/12] mm, swap: swap table phase III: remove swap_map
Date: Wed, 18 Feb 2026 04:06:25 +0800
Message-Id: <20260218-swap-table-p3-v3-0-f4e34be021a7@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13MQQ7CIBCF4asY1o5hqJTqynsYF9AOlkRpAwQ1T
 e8u7Uq7fC/5v4lFCo4iO+8mFii76AZfRrXfsbbX/k7gurKZ4EKiwBriS4+QtHkQjBU0HanKEik
 jLSvNGMi69+pdb2X3LqYhfFY+4/IuUs1RbKWMwEGrI0pptTkZfknkW/Lp0A5PtlhZ/PbNthelt
 8RNrchygfK/n+f5C7daBY/sAAAA
X-Change-ID: 20251216-swap-table-p3-8de73fee7b5f
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 Youngjun Park <youngjun.park@lge.com>, linux-kernel@vger.kernel.org, 
 Chris Li <chrisl@kernel.org>, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771358806; l=4924;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=A8tvZuNzeX3ptMHESXmOnZxAJZVESqug9w+R4jhew4U=;
 b=6LubyR8vhfIJ8XyfWmJmr1o9thCKYkaLYPhPaaB4hjujPpuoT5Kb49nlu46jQ0Np1lW8TVv2X
 6gHVEvKTG3gD/wJB54fi3mRipC6OpWfiDCTojPyznsWK0us+w4ugu+m
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series is based on phase II which is still in mm-unstable.

This series removes the static swap_map and uses the swap table for the
swap count directly. This saves about ~30% memory usage for the static
swap metadata. For example, this saves 256MB of memory when mounting a
1TB swap device. Performance is slightly better too, since the double
update of the swap table and swap_map is now gone.

Test results:

Mounting a swap device:
=======================
Mount a 1TB brd device as SWAP, just to verify the memory save:

`free -m` before:
               total        used        free      shared  buff/cache   available
Mem:            1465        1051         417           1          61         413
Swap:        1054435           0     1054435

`free -m` after:
               total        used        free      shared  buff/cache   available
Mem:            1465         795         672           1          62         670
Swap:        1054435           0     1054435

Idle memory usage is reduced by ~256MB just as expected. And following
this design we should be able to save another ~512MB in a next phase.

Build kernel test:
==================
Test using ZSWAP with NVME SWAP, make -j48, defconfig, in a x86_64 VM
with 5G RAM, under global pressure, avg of 32 test run:

                Before            After:
System time:    1038.97s          1013.75s (-2.4%)

Test using ZRAM as SWAP, make -j12, tinyconfig, in a ARM64 VM with 1.5G
RAM, under global pressure, avg of 32 test run:

                Before            After:
System time:    67.75s            66.65s (-1.6%)

The result is slightly better.

Redis / Valkey benchmark:
=========================
Test using ZRAM as SWAP, in a ARM64 VM with 1.5G RAM, under global pressure,
avg of 64 test run:

Server: valkey-server --maxmemory 2560M
Client: redis-benchmark -r 3000000 -n 3000000 -d 1024 -c 12 -P 32 -t get

        no persistence              with BGSAVE
Before: 472705.71 RPS               369451.68 RPS
After:  481197.93 RPS (+1.8%)       374922.32 RPS (+1.5%)

In conclusion, performance is better in all cases, and memory usage is
much lower.

The swap cgroup array will also be merged into the swap table in a later
phase, saving the other ~60% part of the static swap metadata and making
all the swap metadata dynamic. The improved API for swap operations also
reduces the lock contention and makes more batching operations possible.

Suggested-by: Chris Li <chrisl@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
Changes in v3:
- Use unsigned int instead of unsigned long for extended map as
  suggested by [Youngjun Park].
- Update a few stalled comments, and add back alloc failure warn.
- Link to v2: https://lore.kernel.org/r/20260128-swap-table-p3-v2-0-fe0b67ef0215@tencent.com

Changes in v2:
- Fix build error for ARC with 40 bits of PAE address, adjust macros to
  shrink SWP_TB_COUNT_BITS if needed, and trigger build error if that
  field is too small. There should be no code change for 64 bit builds.
- Fix build warning of unused variables.
- SWP_TB_COUNT_MAX should be ((1 << SWP_TB_COUNT_BITS) - 1), not ((1 <<
  SWP_TB_COUNT_BITS) - 2). No behavior change, just don't waste usable
  bits and reduce the chance of a slower extended table path.
- Add a missing NULL check in swap_extend_table_try_free.
- Fix a typecast error in the swapoff path to silence some static analyzer.
- Stress tested setups with SWP_TB_COUNT_BITS == 2, looks fine.
- Link to v1:
  https://lore.kernel.org/r/20260126-swap-table-p3-v1-0-a74155fab9b0@tencent.com

---
Kairui Song (12):
      mm, swap: protect si->swap_file properly and use as a mount indicator
      mm, swap: clean up swapon process and locking
      mm, swap: remove redundant arguments and locking for enabling a device
      mm, swap: consolidate bad slots setup and make it more robust
      mm/workingset: leave highest bits empty for anon shadow
      mm, swap: implement helpers for reserving data in the swap table
      mm, swap: mark bad slots in swap table directly
      mm, swap: simplify swap table sanity range check
      mm, swap: use the swap table to track the swap count
      mm, swap: no need to truncate the scan border
      mm, swap: simplify checking if a folio is swapped
      mm, swap: no need to clear the shadow explicitly

 include/linux/swap.h |   28 +-
 mm/memory.c          |    2 +-
 mm/swap.h            |   22 +-
 mm/swap_state.c      |   72 ++--
 mm/swap_table.h      |  138 ++++++-
 mm/swapfile.c        | 1121 +++++++++++++++++++++-----------------------------
 mm/workingset.c      |   49 ++-
 7 files changed, 667 insertions(+), 765 deletions(-)
---
base-commit: d9982f38eb6e9a0cb6bdd1116cc87f75a1084aad
change-id: 20251216-swap-table-p3-8de73fee7b5f

Best regards,
-- 
Kairui Song <kasong@tencent.com>

