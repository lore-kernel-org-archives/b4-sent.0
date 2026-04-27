From: Kairui Song <kasong@tencent.com>
Date: Tue, 28 Apr 2026 02:06:57 +0800
Subject: [PATCH v7 06/15] mm/mglru: avoid reclaim type fall back when
 isolation makes no progress
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-mglru-reclaim-v7-6-02fabb92dc43@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777313217; l=1509;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=AV4QwhcpwdcCenfYKd1bClgIwnLcHYhA5p31fWGzsBc=;
 b=RPW2xoKjwCBGjBsqPc3JbY06T1rqff5twu3k3Hrf74NgrDi5y3NM+KsVtZEFYncyjGQRyHYN5
 LBoBHSYdPm5D6qX7Dp4Tr7taNsz+8t35dxHiq4sIzFQaSK4wDcmyNdq
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Barry Song (Xiaomi)" <baohua@kernel.org>

While isolation makes no progress in scan_folios(), we quickly fall back
to the other type in isolate_folios(). This is incorrect, as the current
type may still have sufficient folios. Falling back can undermine the
positive_ctrl_err() result from get_type_to_scan(), which is derived
from swappiness.

So just continue scanning this type for another round.

Worth noting if the cold generations are all reclaimed, scan will no
longer make any progress either, which may undermine the swappiness
again. This is not a new issue and hence better be fixed later [1].

Link: https://lore.kernel.org/linux-mm/CAGsJ_4zjdOYEtuO6gNjABm7NDxW0skzBFNRNee-k2D6VwsYEQA@mail.gmail.com/ [1]
Signed-off-by: Barry Song (Xiaomi) <baohua@kernel.org>
Reviewed-by: Kairui Song <kasong@tencent.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 2dbd39e29dfc..ac9d2d4f8e65 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4817,8 +4817,13 @@ static int isolate_folios(unsigned long nr_to_scan, struct lruvec *lruvec,
 			*isolate_scanned = scanned;
 			break;
 		}
-
-		type = !type;
+		/*
+		 * If scanned > 0 and isolated == 0, avoid falling back to the
+		 * other type, as this type remains sufficient. Falling back
+		 * too readily can disrupt the positive_ctrl_err() bias.
+		 */
+		if (!scanned)
+			type = !type;
 	}
 
 	return total_scanned;

-- 
2.54.0

