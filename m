From: Bingfang Guo <bingfangguo@tencent.com>
Date: Wed, 25 Nov 2026 04:32:19 +0000
Subject: [PATCH v2] mm/mglru: skip oom killing for order != 0 allocs in
 kswapd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-fix-mglru-kswapd-age-v2-1-4cc37437af9b@tencent.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ6CMBBFr0Jm7RhaEcSV9zAsShmgKi1pC2pI7
 27BuHMxi5e8+W8BR1aRg3OygKVZOWV0BL5LQPZCd4SqiQw85TmLh6164dA97IR39xRjgyI65el
 QpjnLZJHlEF9HS9HbZq/Vl91U30j6dWs1euW8se+tO7PV+yWK/4mZIcOatW1DMhN05BdPWpL2e
 2kGqEIIH9I7E4fMAAAA
X-Change-ID: 20261026-fix-mglru-kswapd-age-98390614c746
To: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Michal Hocko <mhocko@kernel.org>, Qi Zheng <qi.zheng@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Lorenzo Stoakes <ljs@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Yu Zhao <yuzhao@google.com>, 
 Bingfang Guo <bfguo@icloud.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Bingfang Guo <bingfangguo@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795581142; l=2716;
 i=bingfangguo@tencent.com; s=20260905; h=from:subject:message-id;
 bh=qV2l1gYt5Q96N5XOUnCBfwyMyXQq9VOKcjW+/oh4RQU=;
 b=S50EhNmVKqI1zc8Itdg9ig9CLE0dcM5ia7nxqwpj/tzGTLAG6/LlpCYTP4xUP/YJbJAfurPnW
 JIZfOZMkqW5BSmD9w/7MpCOjXskbmcPqC3VT2QBmY65mCiJkaw3fCeU
X-Developer-Key: i=bingfangguo@tencent.com; a=ed25519;
 pk=7YoBtD5pTW/XZHfmJ9x+FaHVq1TstMOvF31LTY3F+0w=
X-Endpoint-Received: by B4 Relay for bingfangguo@tencent.com/20260905 with auth_id=1006
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We observed that when MGLRU min_ttl is set and the system is highly
fragmented, high order allocations (e.g. order == 9) will fail and wake
up kswapd. It can not make any progress, while pushing generations of
memcgs so that they all end up younger than min_ttl_ms, repeatedly
triggering the OOM killer in lru_gen_age_node(). Then the whole process
repeats until all processes are killed and the kernel panics.

The purpose of the min_ttl is to prevent thrashing when all memcgs are
too young to reclaim instead of preventing fragmentation. So fix this by
restoring the behavior in commit 30d77b7eef019 ("mm/mglru: fix
ineffective protection calculation"), which skips OOM killer invocations
in lru_gen_age_node() for sc->order != 0.

Fixes: 30d77b7eef019 ("mm/mglru: fix ineffective protection calculation")
Signed-off-by: Bingfang Guo <bingfangguo@tencent.com>
---
==== Testing ====

Tested on a VM with 6 cores and 6GiB of memory, HZ=1000, MGLRU enabled,
min_ttl_ms set to 1000, and a workload that fragments the memory then
allocates 2M pages.

Without the patch, kswapd kills all processes and panics the system even
with plenty of memory available. With the patch, allocations fail but
the system remains stable.

--
Changes in v2:
- Reword the comments to explain the purpose clearly. (Kairui)
- Relax the skip condition to sc->order != 0 for soundness. (sashiko)
- Rebase to mm-unstable.
- Cc stable.
- Link to v1: https://lore.kernel.org/all/20261027-fix-mglru-kswapd-age-v1-1-b1ffdec4ae52@tencent.com/
---
 mm/vmscan.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 836f50814ffa..9fadc6f9da49 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4351,7 +4351,7 @@ static void lru_gen_age_node(struct pglist_data *pgdat, struct scan_control *sc)
 {
 	struct mem_cgroup *memcg;
 	unsigned long min_ttl = READ_ONCE(lru_gen_min_ttl);
-	bool reclaimable = !min_ttl;
+	bool reclaimable = !min_ttl || sc->order;
 
 	VM_WARN_ON_ONCE(!current_is_kswapd());
 
@@ -4371,6 +4371,9 @@ static void lru_gen_age_node(struct pglist_data *pgdat, struct scan_control *sc)
 	 * The main goal is to OOM kill if every generation from all memcgs is
 	 * younger than min_ttl. However, another possibility is all memcgs are
 	 * either too small or below min.
+	 *
+	 * OOM killing for fragmentation is not desired. So skip this when
+	 * sc->order != 0.
 	 */
 	if (!reclaimable && mutex_trylock(&oom_lock)) {
 		struct oom_control oc = {

---
base-commit: a3d0117e02bfa1c3bb6c50e7afe42bbecdbb3459
change-id: 20261026-fix-mglru-kswapd-age-98390614c746

Best regards,
-- 
Bingfang Guo <bingfangguo@tencent.com>

