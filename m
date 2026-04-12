From: Kairui Song <kasong@tencent.com>
Date: Mon, 13 Apr 2026 00:48:26 +0800
Subject: [PATCH v5 12/14] mm/vmscan: remove sc->file_taken
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260413-mglru-reclaim-v5-12-8eaeacbddc44@tencent.com>
References: <20260413-mglru-reclaim-v5-0-8eaeacbddc44@tencent.com>
In-Reply-To: <20260413-mglru-reclaim-v5-0-8eaeacbddc44@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 David Hildenbrand <david@kernel.org>, Michal Hocko <mhocko@kernel.org>, 
 Qi Zheng <zhengqi.arch@bytedance.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Lorenzo Stoakes <ljs@kernel.org>, 
 Barry Song <baohua@kernel.org>, David Stevens <stevensd@google.com>, 
 Chen Ridong <chenridong@huaweicloud.com>, Leno Hou <lenohou@gmail.com>, 
 Yafang Shao <laoar.shao@gmail.com>, Yu Zhao <yuzhao@google.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Kalesh Singh <kaleshsingh@google.com>, 
 Suren Baghdasaryan <surenb@google.com>, Chris Li <chrisl@kernel.org>, 
 Vernon Yang <vernon2gm@gmail.com>, linux-kernel@vger.kernel.org, 
 Qi Zheng <qi.zheng@linux.dev>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776012497; l=963;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=o7IfWpYvb69FfM+6QHpHKLjSXJdMZ8mmLPd6WDSOdzk=;
 b=XwU6oycFtzzEXn83BtJbfuUKeK0+9X4XcCrwsedeyEG5UJ98PBWfmDNuZobUdvF3wfmMTDfSR
 j2rLk6jQdGACPZ3qZuO0VUVi5jXV2Zf7n3kLENeT1FB/oXzyRSnfY4y
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No one is using it now, just remove it.

Reviewed-by: Axel Rasmussen <axelrasmussen@google.com>
Reviewed-by: Baolin Wang <baolin.wang@linux.alibaba.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 3 ---
 1 file changed, 3 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 3f6ba34fcd24..b0b66c03d4dc 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -173,7 +173,6 @@ struct scan_control {
 		unsigned int congested;
 		unsigned int writeback;
 		unsigned int immediate;
-		unsigned int file_taken;
 		unsigned int taken;
 	} nr;
 
@@ -2040,8 +2039,6 @@ static unsigned long shrink_inactive_list(unsigned long nr_to_scan,
 	sc->nr.writeback += stat.nr_writeback;
 	sc->nr.immediate += stat.nr_immediate;
 	sc->nr.taken += nr_taken;
-	if (file)
-		sc->nr.file_taken += nr_taken;
 
 	trace_mm_vmscan_lru_shrink_inactive(pgdat->node_id,
 			nr_scanned, nr_reclaimed, &stat, sc->priority, file);

-- 
2.53.0

