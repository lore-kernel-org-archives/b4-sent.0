From: Bingfang Guo <bingfangguo@tencent.com>
Subject: [PATCH 0/4] memcg: move memcgid refcount to objcg to unpin dying
 memcgs
Date: Fri, 18 Sep 2026 17:18:39 +0800
Message-Id: <20260918-bingfangguo-memcgid-rework-v1-0-5bbf3220d88f@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO8BrWoC/33NQQ6CMBCF4auQrh1TxmDBlfcwLEo7lImhJS2ih
 nB3K+5d/m+Sb1aRKDIlcSlWEWnhxMHnKA+FMIP2joBtboESz7JGBR171+eDewQYaTSOLUR6hni
 H5lQTVmR0p1FkYIrU82vHb23ugdMc4nv/teB3/bGNLP+xC4KEmqxVvdIKq/I6kzfk56MJo2i3b
 fsAZMijKsYAAAA=
To: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Dave Chinner <david@fromorbit.com>, Qi Zheng <qi.zheng@linux.dev>, 
 Kairui Song <kasong@tencent.com>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Bingfang Guo <bfguo@icloud.com>
Cc: cgroups@vger.kernel.org, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, Bingfang Guo <bingfangguo@tencent.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789723137; l=5707;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=HumpYWRvgw+zE8iW9fnW9BLZuICOHn1xarDSuFOUwNk=;
 b=JK6vnLeJDS4DDri2IkSmkhJ4WAGjPV2qPJrDt2KG5O4yzojD3NmCiPh0b/br6WT6IGGXuFHXr
 vhRvhXx1dA5D6lho+ASHD0US+LtbkZn0YKux6e5dH4o2HtiNHfitw88
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Changes since RFC:
- Make the ID API symmetric: mem_cgroup_private_id_get() returns the ID
  and mem_cgroup_private_id_put() takes the ID. (Muchun Song)
- Drop the "take the ID only after the charge succeeded" and the
  dying-memcg walk-up in the swap charge path. (Muchun Song)
- Fold the list_lru / workingset / MGLRU NULL handling into the patch
  that moves the refcount, so the broken intermediate state is never
  introduced. (Muchun Song)
- Add obj_cgroup_from_private_id() and use it in the swap uncharge path,
  so the final put reuses the objcg that was already looked up instead
  of having the put helper return a memcg. (Muchun Song)
- Rename mem_cgroup->id_objcg to private_id_objcg, and make
  mem_cgroup->private_id an unsigned short. (Muchun Song)
- Require the caller to hold the RCU read lock in the ID helpers instead
  of taking it inside them. (Muchun Song)
- Add mem_cgroup_private_id_is_root() and decide whether a swap entry
  carries a counter charge from the ID's root status instead of the
  resolved memcg's, which keeps charge and uncharge symmetric after
  reparenting.
- Reorder and merge commits; the series is now four patches.
- Link to RFC v2: https://lore.kernel.org/r/20260901-bingfangguo-memcgid-rework-v2-0-8edd7f7a7251@tencent.com

Although the dying memcg problem caused by LRU pages is fixed, I can
still see many dying memcgs on some workloads that use shmem and those
pages are swapped out. For example, programs populating logs to tmpfs or
containers sharing data using shmem.  This series binds the memcgid
refcount to objcgs so dying memcgs can be freed normally in this case.

The memcg private ID identifies memcgs for objects that can outlive the
cgroup itself: swap entries and workingset shadows.  Today the ID's
refcount is embedded in the css, and every outstanding ID reference
(mostly swap entries) pins the css, keeping the entire memcg alive,
which brings a problem: A swapped-out page holds a memcgid reference
that pins the css, so the memcg cannot be freed until the page is
swapped back in and charged back to its online parent.

The work done by Muchun Song and Qi Zheng already charges folios to the
objcg, which is reparented to its parent when the memcg offlines.  This
series applies similar idea to the memcg private ID: the ID's refcount
moves from the css into the objcg, and the memcgid xarray holds a
reference to an objcg instead of pinning the css.  When the memcg
offlines, the objcg is reparented and any remaining memcgid references
resolve to the ancestor, so swapped-out pages no longer pin the dying
memcg and get the online parent naturally on swapin.

Unbinding the ID from the memcg has three consequences the series has to
deal with:

  1. The ID stops pinning the memcg, so the paths that relied on the ID
     reference to keep the memcg alive have to hold the RCU read lock
     instead.  (Patch 1.)

  2. Charge and uncharge no longer necessarily happen on the same memcg:
     swapout charges the folio's memcg, while the slot free resolves the
     nearest live ancestor.  The counters are hierarchical, and the
     MEMCG_SWAP stat is either reparented at offline (v1) or not visible
     (v2), so nothing leaks.  But "does this entry carry a counter
     charge at all" can no longer be answered from the resolved memcg:
     root is skipped only because root's swap is not accounted, and a
     non-root ID whose memcg was reparented into root still carries a
     charge that must be released.  Patch 2 adds
     mem_cgroup_private_id_is_root() and makes all three swap paths
     decide on the ID's root status.

  3. An ID can now outlive the memcg it was allocated to, so the memcg
     resolved from an ID is not necessarily the memcg the ID was handed
     out for.  Callers that need exactly that memcg (list_lru, the
     workingset and MGLRU shadow tests) now get NULL and skip the entry,
     while the swap paths, which only need something to account to, get
     the nearest live ancestor.  (Patch 4.)

The series is now four patches:

  memcg: keep swap charging under RCU protection
  memcg: base swap charge accounting on memcgid root status
  memcg: manipulate memcg private ID references by ID
  memcg: move memcg private ID refcount to objcg

Only the last patch changes behavior.  The first three are preparation
that keeps today's semantics while the ID is still bound to the css.

RFC v1 contains some scripts and codes for reproducing the problem and
testing the fix.

** Changelogs **

Changes in RFC v2:
- Rework the logic to try to keep changes small.
- Change order of the commits to make it cleaner.
- Fix problems reported by sashiko.
- Reparent to mm-unstable.
- Link to RFC v1: https://lore.kernel.org/r/20260813-memcgid-objcg-v1-0-83d21c685b77@tencent.com

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
Bingfang Guo (4):
      memcg: keep swap charging under RCU protection
      memcg: base swap charge accounting on memcgid root status
      memcg: manipulate memcg private ID references by ID
      memcg: move memcg private ID refcount to objcg

 include/linux/memcontrol.h |   9 ++--
 mm/list_lru.c              |   2 +-
 mm/memcontrol-v1.c         |  21 ++++-----
 mm/memcontrol-v1.h         |   8 +++-
 mm/memcontrol.c            | 111 ++++++++++++++++++++++++++++++++++-----------
 mm/workingset.c            |   5 +-
 6 files changed, 110 insertions(+), 46 deletions(-)
---
base-commit: 27e4e1835109ef599d72abe6c09711e0b1916033
change-id: 20260827-bingfangguo-memcgid-rework-938e25ecaba2

Best regards,
-- 
Bingfang Guo <bingfangguo@tencent.com>

