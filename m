From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v2 0/6] mm/mglru: clean up folio counters and flag usage
Date: Mon, 24 Aug 2026 23:26:27 +0800
Message-Id: <20260824-mglru-flags-cleanup-v2-0-0104132114ae@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0Jm7ZjSIKmuvAdhUaZTqIFC2kI0h
 LsLuHf5kvffXyFycBzhka0QeHHRjX4HecmAOu1bRmd2BilkKVSucGj7MKPtdRuRetZ+npCouJP
 VprwVFvblFNi691mt6h/HuXkxpSN1GJ2LaQyf83bJD+//w5KjQGWaxmgSRip6JvbEPl1pHKDet
 u0LpB498coAAAA=
X-Change-ID: 20260818-mglru-flags-cleanup-cc49cfad654f
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Baoquan He <baoquan.he@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Muchun Song <muchun.song@linux.dev>, Chris Li <chrisl@kernel.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Ridong Chen <ridong.chen@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Yu Zhao <yuzhao@google.com>, 
 Zi Yan <ziy@nvidia.com>, Qi Zheng <qi.zheng@linux.dev>, 
 cgroups@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Kairui Song <ryncsn@gmail.com>, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787585189; l=2302;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=h/haknnj8pSvM1JoVwSzP1DECAsXwqNBvWxA9kRJxV0=;
 b=a4Y23NvntoKAxWeXth0PVBJK9aQsc8tTuri17H2veCuuj+DP1oDuHP9/uIBmNoeGrNBypDJji
 9B/iyN22v/2Bs99/hfZzTq/PeAxTqFSLKyQcHl0lLzR88jeEEb7aKST
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a cleanup series separated out from the MGLRU-FG series [1]. As
that series is getting too long in following updates, seperate out the
clean up part for easier review and merge.

No feature change is intended, except one bugfix. It mostly replaces
the open-coded bit operations scattered throughout the MGLRU code with
new helpers, with proper kdocs, sanity debug checks, and hardens a few
MGLRU functions.

A subtle generation counter leak is also found during the refactoring
and the fix is included.

Also collected review feedbacks on the cleanup part from the posted
series.

Link: https://lore.kernel.org/linux-mm/20260804-mglru-fg-v1-0-4d8dad39dad6@tencent.com/ [1]
Signed-off-by: Kairui Song <kasong@tencent.com>
---
Changes in v2:
- Dropped the redundant LRU_GEN_MAX macro.
- Renamed folio_migrate_refs() to folio_migrate_lru_refs() and reworded
  its commit message to describe the referenced state being transferred.
- Rewrote patch 6's commit message with a detailed analysis of the
  anon/file accounting race.
- Dropped patch 7, it doesn't really fix anything, and might be in
  conflict with other updating series.
- Collected Reviewed-by tags.
- Link to v1: https://patch.msgid.link/20260818-mglru-flags-cleanup-v1-0-8dbbdac0d28c@tencent.com

---
Kairui Song (6):
      mm/memcontrol: make lru_zone_size atomic and simplify sanity check
      mm/mglru: introduce helpers for manipulating gen and refs flags
      mm/migrate: copy all referenced state via folio_migrate_lru_refs
      mm/mglru: move max_seq read into walk_update_folio
      mm/mglru: use explicit tier range in read_ctrl_pos()
      mm/mglru: fix potential generation folio number leak

 include/linux/memcontrol.h |   9 +++-
 include/linux/mm_inline.h  | 103 +++++++++++++++++++++++++++++++++------
 include/linux/mmzone.h     |   3 ++
 mm/folio.c                 |  19 ++++----
 mm/memcontrol.c            |  18 +------
 mm/migrate.c               |   6 +--
 mm/vmscan.c                | 117 +++++++++++++++++++++++----------------------
 7 files changed, 175 insertions(+), 100 deletions(-)
---
base-commit: efecab401cb15fd3bb9bc05990609acb6b267ff2
change-id: 20260818-mglru-flags-cleanup-cc49cfad654f

Best regards,
--  
Kairui Song <kasong@tencent.com>

