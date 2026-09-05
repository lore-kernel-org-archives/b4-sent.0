From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v6 0/6] mm/mglru: clean up folio counters and flag usage
Date: Sun, 06 Sep 2026 00:51:05 +0800
Message-Id: <20260906-mglru-flags-cleanup-v6-0-9aacbd77d4ca@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33PTU7EMAwF4KuMsiYoTpP+sOIeiEVqO52gTjpq2
 go06t1JhwVFU7F8kv09+yYSj4GTeDndxMhLSGGIOZRPJ4FnFzuWgXIWWulS1VDLS9ePs/S965L
 Enl2crxLRNOgdldZ4kTevI/vweVff3n9ymtsPxmmjtolzSNMwft1rF9jm/m9YQCpZU9uSQ0W6x
 teJI3KcnnG4iK1j0TtFm2NFZ0WBMlBoAOP4USn2SnmsFFmhxgNW1ubH60fF7JQCjhWTFU1giVh
 RxQe32F+lUfpYsVlpqK1KoKpq2P9V1nX9BtZJkdHiAQAA
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
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Ridong Chen <ridong.chen@linux.dev>, Lian Wang <lianux.mm@gmail.com>, 
 Yu Zhao <yuzhao@google.com>, Zi Yan <ziy@nvidia.com>, 
 Qi Zheng <qi.zheng@linux.dev>, cgroups@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kairui Song <ryncsn@gmail.com>, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788627071; l=3580;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=dskzQeDGxBtirZ5ohMl5zEVdQosEdst7khpwTL27U/U=;
 b=c12Fl395Bz9yonkrDDvw0bsBMU4J4OnfMbYdVzc+uUwH1FEGqU5ysTHxGqgnSRDcgtknxkfzX
 YAvjHxzMlViCZNwTdVvDMg/KXp8x21JoepotrEeSoxF5dZeuTCH5m0k
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
Changes in v6:
- Rebase on top of mm-unstable, also mergable on mm-new.
- Collect tags.
- Link to v5: https://patch.msgid.link/20260902-mglru-flags-cleanup-v5-0-9db761d779ef@tencent.com

Changes in v5:
- Change atomic long to plain long in patch 1, and adjust commit message.
- Rename is_file to type, and avoid touching folio_is_file_lru in patch 7/7.
- Link to v4: https://patch.msgid.link/20260831-mglru-flags-cleanup-v4-0-2d15dde0d7ee@tencent.com

Changes in v4:
- Rename lru_gen_set_flags/lru_gen_from_flags to
  lru_set_gen_flags/lru_get_gen_flags, similiar with lru refs helpers,
  as suggested by [ Barry Song ].
- Added some comments to cover concerned raised by [ Barry Song ] and [
  Baolin Wang ].
- A little code shuffling and better sanity check for concerns raised by 
  [ Ridong Chen ].
- Collect tags.
- Link to v3: https://patch.msgid.link/20260826-mglru-flags-cleanup-v3-0-d9f1c75549c8@tencent.com

Changes in v3:
- Set PG_workingset before setting LRU refs bit to avoid any potential
  under report of folio tier.
- Migrate folio's referenced status before PG_update so lockless readers
  won't set stale referenced status.
- Link to v2: https://patch.msgid.link/20260824-mglru-flags-cleanup-v2-0-0104132114ae@tencent.com

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
      mm/memcontrol: move the lru_zone_size sanity check to the reader side
      mm/mglru: introduce helpers for manipulating gen and refs flags
      mm/migrate: copy all referenced state via folio_migrate_lru_refs
      mm/mglru: move max_seq read into walk_update_folio
      mm/mglru: use explicit tier range in read_ctrl_pos()
      mm/mglru: fix potential generation folio number leak

 include/linux/memcontrol.h |   9 +++-
 include/linux/mm_inline.h  | 115 +++++++++++++++++++++++++++++++++++++++-----
 include/linux/mmzone.h     |   3 ++
 mm/folio.c                 |  19 ++++----
 mm/memcontrol.c            |  18 +------
 mm/migrate.c               |   6 +--
 mm/vmscan.c                | 116 ++++++++++++++++++++++++---------------------
 7 files changed, 188 insertions(+), 98 deletions(-)
---
base-commit: b5529903123d9535bcf74386c1f4e185e8632dd9
change-id: 20260818-mglru-flags-cleanup-cc49cfad654f

Best regards,
--  
Kairui Song <kasong@tencent.com>

