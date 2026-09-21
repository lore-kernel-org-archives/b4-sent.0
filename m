From: Bingfang Guo <bingfangguo@tencent.com>
Subject: [PATCH v2 0/4] memcg: move memcgid refcount to objcg to unpin
 dying memcgs
Date: Mon, 21 Sep 2026 14:16:23 +0800
Message-Id: <20260921-bingfangguo-memcgid-rework-v2-0-6c0637dc0edb@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALfLsGoC/33OwYrCMBAG4FcpORtJptSMnhYEH8CreGiSSYxLE
 0lrd0X67kaFxQXx+M/A9/9X1lMO1LNVdWWZxtCHFEuAWcXMoY2eeLAlMxCwEAiK6xC9Kw9/Try
 jzvhgeaaflL/5skaChkyrW2AFOGVy4feB7/YlH0I/pHx5dI3yfn2yS4mf2FFywRutXQ0gLKL7G
 igaisPcpI7d4e1mXY3wAgr5EYQCIlmrnGoVNPI9+LIQZf2HJH00/jkKawvSLLDRSv03pmm6AWn
 jPadbAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789971391; l=4662;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=6MJxPjqbgb7Y/VEHgxJibzuGMSiGTlHjpPp7ebXihAI=;
 b=5Q7x040B0vUoB3GYgoqElocEo3xrwnGVk/iMGoohpF+TahdOPrG0amEOKcw9ubP44iLWxwITD
 E7hGSZoG2lGBt81pbdcPmQLrg8Az/uTwnuMmf9i08Y9/zUEWeKSZz+H
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Changes in v2:
- Remove the NULL test and use the root in lru_gen_test_recent() to fix
  the uninitialized lruvec pointer. (Shakeel)
- Wrap rcu section in the swap charging path with scoped_guard.
  (Shakeel)
- Replace rcu lock with lockdep assertion in mem_cgroup_private_id_put().
  (Shakeel)
- Keep memcg->private_id datatype unchanged and send it separately later
  for simplicity of this series. (Muchun)
- Add blank lines between variable definitions and assertions. (Muchun)
- Remove redundant comments. (Muchun & Shakeel)
- Collect Acked-by tags.
- Link to v1: https://lore.kernel.org/r/20260918-bingfangguo-memcgid-rework-v1-0-5bbf3220d88f@tencent.com

Although the dying memcg problem caused by LRU pages is fixed, I can
still see many dying memcgs on some workloads that use shmem and those
pages are swapped out. For example, programs populating logs to tmpfs or
containers sharing data using shmem.  This series binds the memcgid
refcount to objcgs so dying memcgs can be freed normally in this case.

The memcg private ID identifies memcgs for objects that can outlive the
cgroup itself: swap entries and workingset shadows.  Today the ID's
refcount is embedded in the css, and every outstanding ID reference
(mostly swap entries) pins the css, keeping the entire memcg alive.
This causes a problem: A swapped-out page holds a memcgid reference that
pins the css, so the memcg cannot be freed until the page is swapped
back in and charged back to its online parent.

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
     instead.  (Patch 1)

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
     the nearest live ancestor.  (Patch 4)

The series is now four patches. The first three are preparation that
keeps today's semantics while the ID is still bound to the css. Only the
last patch changes behavior.

** Testing **

RFC v1 contains some scripts and codes for reproducing the problem and
testing the fix [1].

[1] https://lore.kernel.org/r/20260813-memcgid-objcg-v1-0-83d21c685b77@tencent.com

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
Bingfang Guo (4):
      memcg: keep swap charging under RCU protection
      memcg: base swap charge accounting on memcgid root status
      memcg: manipulate memcg private ID references by ID
      memcg: move memcg private ID refcount to objcg

 include/linux/memcontrol.h |   7 +--
 mm/list_lru.c              |   2 +-
 mm/memcontrol-v1.c         |  21 ++++----
 mm/memcontrol-v1.h         |   8 ++-
 mm/memcontrol.c            | 125 +++++++++++++++++++++++++++++++--------------
 mm/workingset.c            |   2 +-
 6 files changed, 109 insertions(+), 56 deletions(-)
---
base-commit: 8d61431ed2607386b427752505379536eb634ce8
change-id: 20260827-bingfangguo-memcgid-rework-938e25ecaba2

Best regards,
-- 
Bingfang Guo <bingfangguo@tencent.com>

