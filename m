From: Kairui Song <kasong@tencent.com>
Date: Wed, 18 Mar 2026 03:09:01 +0800
Subject: [PATCH 5/8] mm/mglru: use a smaller batch for reclaim
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-mglru-reclaim-v1-5-2c46f9eb0508@tencent.com>
References: <20260318-mglru-reclaim-v1-0-2c46f9eb0508@tencent.com>
In-Reply-To: <20260318-mglru-reclaim-v1-0-2c46f9eb0508@tencent.com>
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
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773774704; l=825;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=WP4y9XHEWiYUb4a2CJWiS80eKSpma8CkjsOc7bozYm0=;
 b=g31dIkTIDAoe+MBcN4ZK5LGx2nUUlTr1S9ZIEF3qT1RdprPhYqv5TpzL2bTnSn2S22d/15tG8
 vcDdYbsDHYuD00RXl3abh+rRm7IHz5euwoqKW53MVDa4YC3BLrm/HqQ
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With a fixed number to reclaim calculated at the beginning, making each
following step smaller should reduce the lock contention and avoid
over-aggressive reclaim of folios, as it will abort earlier when the
number of folios to be reclaimed is reached.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/vmscan.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 4f4548ff3a17..2ff1609ff4de 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -5007,7 +5007,7 @@ static bool try_to_shrink_lruvec(struct lruvec *lruvec, struct scan_control *sc)
 			break;
 		}
 
-		nr_batch = min(nr_to_scan, MAX_LRU_BATCH);
+		nr_batch = min(nr_to_scan, MIN_LRU_BATCH);
 		delta = evict_folios(nr_batch, lruvec, sc, swappiness);
 		if (!delta)
 			break;

-- 
2.53.0

