From: Bingfang Guo <bingfangguo@tencent.com>
Date: Tue, 27 Oct 2026 10:21:08 +0800
Subject: [PATCH] mm/mglru: skip oom killing for high order allocs in kswapd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-fix-mglru-kswapd-age-v1-1-b1ffdec4ae52@tencent.com>
X-B4-Tracking: v=1; b=H4sIAJMK4GoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDINZNy6zQzU3PKSrVzS4uTyxI0U0EqrG0MLY0MDM0STY3MVMCai0oSgW
 qAxsbHQvhF5cmZaUml4DMUqqtBQCBaHKzeAAAAA==
X-Change-ID: 20261026-fix-mglru-kswapd-age-98390614c746
To: Andrew Morton <akpm@linux-foundation.org>, 
 Kairui Song <kasong@tencent.com>, Qi Zheng <qi.zheng@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Michal Hocko <mhocko@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Yu Zhao <yuzhao@google.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Bingfang Guo <bingfangguo@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793067668; l=2033;
 i=bingfangguo@tencent.com; s=20260812; h=from:subject:message-id;
 bh=+NHgwZPSL4lsn3SUUTmSyqpRl3Ciw1JrL46ewddx38Q=;
 b=jnw8LXfvvz+KGsE6wZisVj9vHnHVOxP2bE4RM+sv7KPH4LTBMws81Qrt3RYHmK//t2koHb3eQ
 jSlAa4Q+v6VAc8lBCHD+G0R009PadeosKyjVND3NfHj0BEYipQa1Otw
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=q7u9S7d5e7VijWrYF9O+vv9/XvqWduVGtwGtuCObAHE=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260812 with auth_id=942
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We observed that when MGLRU min_ttl is set and the system is highly
fragmented, high order allocations (e.g. order == 9) will fail and wake
up kswapd. It can not make any progress, while pushing generations of
memcgs so that they all end up younger than min_ttl_ms, repeatedly
triggering the OOM killer in lru_gen_age_node(). Then the whole process
repeats until all processes are killed and the kernel panics.

Fix this by skipping OOM killer invocations in lru_gen_age_node() for
sc->order > PAGE_ALLOC_COSTLY_ORDER, which is also what the normal
allocation path will do, to fail high order allocations without OOM
killing.

==== Testing ====

Tested on a VM with 6 cores and 6GiB of memory, HZ=1000, MGLRU enabled,
min_ttl_ms set to 1000, and a workload that fragments the memory then
allocates 2M pages.

Without the patch, kswapd kills all processes and panics the system even
with plenty of memory available. With the patch, allocations fail but
the system remains stable.

Fixes: 30d77b7eef019 ("mm/mglru: fix ineffective protection calculation")
Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
 mm/vmscan.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 9959ca158ce83..b32777468ead8 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4407,6 +4407,12 @@ static void lru_gen_age_node(struct pglist_data *pgdat, struct scan_control *sc)
 			reclaimable = lruvec_is_reclaimable(lruvec, sc, min_ttl);
 	} while ((memcg = mem_cgroup_iter(NULL, memcg, NULL)));
 
+	/*
+	 * OOM killing won't help high order allocations. Skip and let them fail.
+	 */
+	if (sc->order > PAGE_ALLOC_COSTLY_ORDER)
+		return;
+
 	/*
 	 * The main goal is to OOM kill if every generation from all memcgs is
 	 * younger than min_ttl. However, another possibility is all memcgs are

---
base-commit: 39274b454e9993cea319f4ac342a8082a9ee1730
change-id: 20261026-fix-mglru-kswapd-age-98390614c746

Best regards,
--  
Bingfang Guo <bingfangguo@tencent.com>

