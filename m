From: Leno Hou <lenohou@gmail.com>
Subject: [PATCH 6.12 0/2] mm: vmscan: fix dirty folios throttling on cgroup
 v1 for MGLRU
Date: Sat, 24 Oct 2026 13:35:02 +0800
Message-Id: <20261024-fix-mglru-v6-6-v2-v1-0-8c9b40f9fc24@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyMT3bTMCt3c9JyiUt0yM10z3TIj3RSLpGTLFBNDC+NkcyWgvoKiVKA
 isJnRSgGOIc4eCmZ6hkZKsRC54tKkrNTkEpChSrW1ALVCrAeBAAAA
X-Change-ID: 20261024-fix-mglru-v6-6-v2-d8bc9d4183c7
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792820120; l=1731;
 i=lenohou@gmail.com; s=20260311; h=from:subject:message-id;
 bh=StomykYfb3/sFZOdoTuIrIamn2Q34stb+/OsW4JO9BM=;
 b=8dvX07Tv7g/PTETOsReRAxCMP4HRJ1TsVn4CcloyMCIkQF1r0FLI09JMOl90IuscEc37Gi2G+
 1rvXY9RHt0TB6/7Rj/wOUZWilXfl1dnbDiNKAt2CoQtv2Rhbg1ApS+p
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
- Link to v1: https://patch.msgid.link/20261024-linux-6-1-y-v1-0-cf381365f30b@gmail.com

---
Leno Hou (2):
      mm/vmscan: wake up flushers conditionally to avoid cgroup OOM
      mm: vmscan: fix dirty folios throttling on cgroup v1 for MGLRU

 mm/vmscan.c | 36 ++++++++++++++++++++++++++++++++++--
 1 file changed, 34 insertions(+), 2 deletions(-)
---
base-commit: 0aebf2870d53a8d97e02a99e2103ea0b38950c1b
change-id: 20261024-fix-mglru-v6-6-v2-d8bc9d4183c7

Best regards,
--  
Leno Hou <lenohou@gmail.com>

