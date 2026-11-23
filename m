From: Kairui Song <kasong@tencent.com>
Date: Tue, 24 Nov 2026 02:52:55 +0800
Subject: [PATCH v6 03/18] mm/memcontrol: avoid potential counter leak when
 reparenting local stats
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-mglru-fg-v6-3-8ffea39934a6@tencent.com>
References: <20261124-mglru-fg-v6-0-8ffea39934a6@tencent.com>
In-Reply-To: <20261124-mglru-fg-v6-0-8ffea39934a6@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <qi.zheng@linux.dev>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Chris Li <chrisl@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Nhat Pham <nphamcs@gmail.com>, Youngjun Park <youngjun.park@lge.com>, 
 Zi Yan <ziy@nvidia.com>, Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 SJ Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Tal Zussman <tz2294@columbia.edu>, 
 Kairui Song <ryncsn@gmail.com>, Xiang Liu <liuxiang.277@bytedance.com>, 
 Ehab Ababneh <ehab.ababneh@intel.com>, 
 Zhao Zhenzhuo <zhaozhengzhuo@uniontech.com>, 
 Lian Wang <lianux.mm@gmail.com>, Joanne Koong <joannelkoong@gmail.com>, 
 Kunwu Chan <kunwu.chan@gmail.com>, Hui Zhu <hui.zhu@linux.dev>, 
 Maxim Muzafarov <maxmuzaf@gmail.com>, linux-kernel@vger.kernel.org, 
 cgroups@vger.kernel.org, damon@lists.linux.dev, linux-doc@vger.kernel.org, 
 Tianyi Chen <hi@tychen.cc>, Kairui Song <kasong@tencent.com>, 
 Ridong Chen <ridong.chen@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459977; l=3407;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=DITLxusEF3jFekXchW/A6iHzf//ot6gPbXly+2fd+cQ=;
 b=oQEvwa9i+84qyXpmUPi7pXNiCe/5dSBG7wL+wB1oC2sXK73KSejhjUMAwogTXAJ3+Pcs3FOdO
 fyAevJbJU6HADPweDl0ahO3Xr133F1H4Ez41aJ+ynn60czLlmD8SsmG
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

lruvec_page_state_local() clamps negative values to zero on SMP.  That
is right for readers reporting page counts, but can be wrong for
reparenting once MGLRU updates the counters without the lruvec lock.

Reparenting runs after the forced stats flush, so a negative is a real
balance that has to move to the parent, not be discarded. We will
introduce lockless MGLRU promotion which may cause following problem:

 1. A refs CAS on a folio on the child's lruvec moves it from
    inactive to active, and its active/inactive counter update follows
    as a separate step.

 2. A concurrent isolation of the folio reads the folio as active,
    debits the child's NR_ACTIVE_* by delta before CSS_DYING is visible
    to it.

 3. The child is killed, and the two __update_lru_size() calls from
    step 1 land on the parent: NR_INACTIVE_* -delta, then NR_ACTIVE_*
    +delta.

The child is left with NR_ACTIVE_* -delta while the parent holds the
matching +delta, and reparenting the child's raw value is what cancels
the parent's credit.  However, if the child happens to hold few enough
folios for that counter to be negative, lruvec_page_state_local() clamps
the child's negative to zero, which drops the debit instead, so the
parent keeps NR_ACTIVE_* overcounted by delta, and its active + inactive
total overcounted as well, permanently: the child's local counters are
gone once reparenting is done.

So use a raw signed helper and reparent with that.  Ordinary readers
still keep the clamp.

Reported-by: Kunwu Chan <kunwu.chan@gmail.com>
Closes: https://lore.kernel.org/linux-mm/CAN_Opa-+nb0vxQ+HsENCG2fEEMZoxG9Sy_DBC4CLkWjNLzDWKw@mail.gmail.com/
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/memcontrol.c | 15 +++++++++++----
 1 file changed, 11 insertions(+), 4 deletions(-)

diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 091401cecf39..3f551e2e3206 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -562,11 +562,10 @@ unsigned long lruvec_page_state_monotonic(const struct lruvec *lruvec,
 	return (unsigned long)READ_ONCE(pn->lruvec_stats->state[i]);
 }
 
-unsigned long lruvec_page_state_local(const struct lruvec *lruvec,
+static long __lruvec_page_state_local(const struct lruvec *lruvec,
 				      enum node_stat_item idx)
 {
 	const struct mem_cgroup_per_node *pn;
-	long x;
 	int i;
 
 	if (mem_cgroup_disabled())
@@ -577,7 +576,14 @@ unsigned long lruvec_page_state_local(const struct lruvec *lruvec,
 		return 0;
 
 	pn = container_of_const(lruvec, struct mem_cgroup_per_node, lruvec);
-	x = READ_ONCE(pn->lruvec_stats->state_local[i]);
+	return READ_ONCE(pn->lruvec_stats->state_local[i]);
+}
+
+unsigned long lruvec_page_state_local(const struct lruvec *lruvec,
+				      enum node_stat_item idx)
+{
+	long x = __lruvec_page_state_local(lruvec, idx);
+
 #ifdef CONFIG_SMP
 	if (x < 0)
 		x = 0;
@@ -595,7 +601,8 @@ void reparent_memcg_lruvec_state_local(struct mem_cgroup *memcg,
 
 	for_each_node(nid) {
 		struct lruvec *lruvec = mem_cgroup_lruvec(memcg, NODE_DATA(nid));
-		unsigned long value = lruvec_page_state_local(lruvec, idx);
+		/* Reparent the raw value: the clamp drops the child's debit. */
+		long value = __lruvec_page_state_local(lruvec, idx);
 
 		__mod_memcg_lruvec_state(memcg, nid, idx, -value);
 		__mod_memcg_lruvec_state(parent, nid, idx, value);

-- 
2.56.1

