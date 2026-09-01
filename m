From: Bingfang Guo <bingfangguo@tencent.com>
Subject: [PATCH RFC v2 0/6] mm/memcg: move memcgid refcount to objcg to
 unpin dying memcgs
Date: Tue, 01 Sep 2026 16:57:59 +0800
Message-Id: <20260901-bingfangguo-memcgid-rework-v2-0-8edd7f7a7251@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJeTlmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzMDCyNz3aTMvPQ0oER6ab5ubmpucnpmim5Ranl+UbaupbFFqpFpanJiUqK
 REtCAgqLUtMwKsOHRSkFuzkqxtbUA5Vvo4HEAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788253095; l=3096;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=2rsNpbbKndbyocdYHBqGvoSTRhCZGAVV39aajeiQvbw=;
 b=niyCOO6I31iqWLWbba9BN/RcyJmA4XUdfG73eXvhi2yvhf4G3il5zEqKw7xURsTT+nbknaOgH
 SEQtesn+OCHCSrV8AwoIdhtMQMgrZm5lhO4im7A0OvH0B6Hj8Ev/k12
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Although the dying memcg problem caused by LRU pages is fixed, I can
still see the issue on some workloads that use shmem after those pages
are swapped out.  This series binds the memcgid refcount to objcgs so
dying memcgs can be freed normally in this case.

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

Patches 1-4 are self-contained preparatory cleanups:
  - add a helper to drop the online-state reference on offlining
  - take the memcgid reference only after swap charging succeeds
  - make mem_cgroup_private_id_put() take the ID instead of the memcg
  - return the memcg from mem_cgroup_private_id_put() for uncharging

Patch 5 actually moves the refcount to objcgs, and patch 6 makes the
remaining callers (list_lru, workingset) to filter out memcgs that have
already been reparented.

Changes in v2:
- Rework the logic to try to keep changes small.
- Change order of the commits to make it cleaner.
- Fix problems reported by sashiko.
- Reparent to mm-unstable.

RFC v1 contains some scripts and codes for reproducing the problem and
testing the fix:

https://lore.kernel.org/linux-mm/20260813-memcgid-objcg-v1-0-83d21c685b77@tencent.com/T/#m0e8ce07568e16239ba113c803f27caf308b299e7

Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
Bingfang Guo (6):
      mm/memcg: add a helper to kill the memcgid on offlining
      mm/memcg: get memcgid reference only after swap charging success
      mm/memcg: pass the id itself instead of memcg for putting ID
      mm/memcg: return the memcg when putting memcgid
      mm/memcg: move memcg private ID refcount to objcg
      mm/memcg: filter out reparented memcgs got from memcgid

 include/linux/memcontrol.h |  15 +++---
 mm/list_lru.c              |   2 +-
 mm/memcontrol.c            | 117 +++++++++++++++++++++++++++++++++++----------
 mm/workingset.c            |   2 +-
 4 files changed, 100 insertions(+), 36 deletions(-)
---
base-commit: 88297631d4d42f6004cb39c0ba3da7d2d10a616f
change-id: 20260827-bingfangguo-memcgid-rework-938e25ecaba2

Best regards,
-- 
Bingfang Guo <bingfangguo@tencent.com>

