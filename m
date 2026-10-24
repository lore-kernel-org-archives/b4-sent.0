From: Leno Hou <lenohou@gmail.com>
Subject: [PATCH 6.1 v2 0/2] mm: vmscan: fix dirty folios throttling on
 cgroup v1 for MGLRU
Date: Sat, 24 Oct 2026 13:38:43 +0800
Message-Id: <20261024-linux-6-1-y-v2-0-92958fc61228@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNuw6CQBREf4Xc2kv2oStYaWwsLewMBay7cA0Ps
 wsEQvh3ASvLycyZM4E3joyHUzCBMz15auoliF0Aukjr3CC9lgyCCcViHmNJdTegQo4jZkpoe1Q
 qSqWEhfg4Y2nY3p5wvzyut0CFHJJf5bvsbXS7vq3jgnzbuHEz93xDVglnYv8n6Tky1FZGXKqDl
 Sw751VKZaibCpJ5nr9U+kh1wwAAAA==
X-Change-ID: 20260919-linux-6-1-y-b62cf7668a33
To: stable@vger.kernel.org
Cc: Leno Hou <lenohou@gmail.com>, Wei Xu <weixugc@google.com>, 
 Zeng Jingxiang <linuszeng@tencent.com>, Kairui Song <kasong@tencent.com>, 
 Chris Li <chrisl@kernel.org>, "T.J. Mercier" <tjmercier@google.com>, 
 Yu Zhao <yuzhao@google.com>, Andrew Morton <akpm@linux-foundation.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Barry Song <baohua@kernel.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Axel Rasmussen <axelrasmussen@google.com>, 
 David Hildenbrand <david@kernel.org>, 
 "Lorenzo Stoakes (Oracle)" <ljs@kernel.org>, 
 Michal Hocko <mhocko@kernel.org>, Qi Zheng <zhengqi.arch@bytedance.com>, 
 Yuanchu Xie <yuanchu@google.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792820328; l=1839;
 i=lenohou@gmail.com; s=20260311; h=from:subject:message-id;
 bh=7ZVbrrON3k4kx5LrBKVyBNgPO30Z2rlp/eRf3qHKhU0=;
 b=03h52asE15rJ3tWDBxJCnq0JqADUwRrZjN1Y/t3pYh9tv2ifjz7Qu1KOZWpRh2nqc8JxFdXOf
 VFT2E7KeCfwB0aw0729dJCQBhio62ZSmnw6UgeeEkA1JLDojl6cjXzp
X-Developer-Key: i=lenohou@gmail.com; a=ed25519;
 pk=8AVHXYurzu1kOGjk9rwvxovwSCynBkv2QAcOvSIe1rw=
X-Endpoint-Received: by B4 Relay for lenohou@gmail.com/20260311 with auth_id=674
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The series backports the following upstream commits:

  1. 1bc542c6a0d1 ("mm/vmscan: wake up flushers conditionally to avoid cgroup OOM")
  2. 13b6b6209104 ("mm: vmscan: fix dirty folios throttling on cgroup v1 for MGLRU")

Patch 1 wakes up flushers conditionally when a memcg is about to OOM due
to dirty caches.  It restores the flusher wakeup that was removed by
14aa8b2d5c2e ("mm/mglru: don't sync disk for each aging cycle").

Patch 2 handles cgroup v1, where balance_dirty_pages() does not throttle
dirty folios.  See 9badce000e2c ("cgroup, writeback: don't enable cgroup
writeback on traditional hierarchies").  After 6b0dfabb3555 ("fs: Remove
aops->writepage"), reclaim no longer writes back filesystem folios
directly.  On large memory systems, the flusher may not be able to write
back quickly enough, leaving many folios already under writeback.  Since
MGLRU cannot reclaim these dirty folios, the system may run out of memory
and trigger the OOM killer.  Patch 2 throttles reclaim after waking up
the flusher for cgroup v1, similar to 81a70c21d917
("mm/cgroup/reclaim: fix dirty pages throttling on cgroup v1").

Signed-off-by: Leno Hou <lenohou@gmail.com>
---
Changes in v2:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://patch.msgid.link/20261024-linux-6-1-y-v1-0-cf381365f30b@gmail.com

---
Leno Hou (2):
      mm/vmscan: wake up flushers conditionally to avoid cgroup OOM
      mm: vmscan: fix dirty folios throttling on cgroup v1 for MGLRU

 mm/vmscan.c | 37 +++++++++++++++++++++++++++++++++++--
 1 file changed, 35 insertions(+), 2 deletions(-)
---
base-commit: 79807e970724c1f90cee1316361d61b80db4eef6
change-id: 20260919-linux-6-1-y-b62cf7668a33

Best regards,
--  
Leno Hou <lenohou@gmail.com>

