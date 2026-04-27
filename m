From: Kairui Song <kasong@tencent.com>
Date: Tue, 28 Apr 2026 02:07:00 +0800
Subject: [PATCH v7 09/15] mm/mglru: remove redundant swap constrained check
 upon isolation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-mglru-reclaim-v7-9-02fabb92dc43@tencent.com>
References: <20260428-mglru-reclaim-v7-0-02fabb92dc43@tencent.com>
In-Reply-To: <20260428-mglru-reclaim-v7-0-02fabb92dc43@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Kairui Song <kasong@tencent.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Michal Hocko <mhocko@kernel.org>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 David Stevens <stevensd@google.com>, 
 Chen Ridong <chenridong@huaweicloud.com>, Leno Hou <lenohou@gmail.com>, 
 Yafang Shao <laoar.shao@gmail.com>, Yu Zhao <yuzhao@google.com>, 
 Zicheng Wang <wangzicheng@honor.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Kalesh Singh <kaleshsingh@google.com>, 
 Suren Baghdasaryan <surenb@google.com>, Chris Li <chrisl@kernel.org>, 
 Vernon Yang <vernon2gm@gmail.com>, linux-kernel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kairui Song <ryncsn@gmail.com>, 
 Qi Zheng <qi.zheng@linux.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777313217; l=1862;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=3kVEaa+69q2QQdWMI3d9+Nc1UFdcO1MQkSA+3AlCcvY=;
 b=G0qlbP8TdGe9GvyLqb1tlEmx425wLBr5K4r5niqGUlo9Pwy5K0n28djEMUxQFw2UmH4bI6Tn4
 IONoSmPMaMfDBaJ3v78FFlusOvvvbq0AlGOER8YZb3XgTRX1ViCR3xB
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the swap-constrained early reject check upon isolation.  This check
is a micro optimization when swap IO is not allowed, so folios are
rejected early.  But it is redundant and overly broad since
shrink_folio_list() already handles all these cases with proper
granularity.

Notably, this check wrongly rejected lazyfree folios, and it doesn't cover
all rejection cases.  shrink_folio_list() uses may_enter_fs(), which
distinguishes non-SWP_FS_OPS devices from filesystem-backed swap and does
all the checks after folio is locked, so flags like swap cache are stable.

This check also covers dirty file folios, which are not a problem now
since sort_folio() already bumps dirty file folios to the next generation,
but causes trouble for unifying dirty folio writeback handling.

And there should be no performance impact from removing it.  We may have
lost a micro optimization, but unblocked lazyfree reclaim for NOIO
contexts, which is not a common case in the first place.

Reviewed-by: Axel Rasmussen <axelrasmussen@google.com>
Reviewed-by: Baolin Wang <baolin.wang@linux.alibaba.com>
Reviewed-by: Chen Ridong <chenridong@huaweicloud.com>
Reviewed-by: Barry Song <baohua@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 6 ------
 1 file changed, 6 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 42ccc6eb0748..ea86297b604c 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4650,12 +4650,6 @@ static bool isolate_folio(struct lruvec *lruvec, struct folio *folio, struct sca
 {
 	bool success;
 
-	/* swap constrained */
-	if (!(sc->gfp_mask & __GFP_IO) &&
-	    (folio_test_dirty(folio) ||
-	     (folio_test_anon(folio) && !folio_test_swapcache(folio))))
-		return false;
-
 	/* raced with release_pages() */
 	if (!folio_try_get(folio))
 		return false;

-- 
2.54.0

