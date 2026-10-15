From: Kairui Song <kasong@tencent.com>
Date: Fri, 16 Oct 2026 02:15:52 +0800
Subject: [PATCH v4 03/17] mm/memcg: add folio-based lruvec live helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-mglru-fg-v4-3-2106750c0bfa@tencent.com>
References: <20261016-mglru-fg-v4-0-2106750c0bfa@tencent.com>
In-Reply-To: <20261016-mglru-fg-v4-0-2106750c0bfa@tencent.com>
To: linux-mm@kvack.org, "Liam R. Howlett" <liam@infradead.org>, 
 SJ Park <sj@kernel.org>
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <qi.zheng@linux.dev>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Chris Li <chrisl@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Vlastimil Babka <vbabka@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, Zi Yan <ziy@nvidia.com>, 
 Gregory Price <gourry@gourry.net>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Hugh Dickins <hughd@google.com>, 
 David Rientjes <rientjes@google.com>, Yu Zhao <yuzhao@google.com>, 
 Vernon Yang <vernon2gm@gmail.com>, Zicheng Wang <wangzicheng@honor.com>, 
 Chen Ridong <chenridong@xiaomi.com>, Tal Zussman <tz2294@columbia.edu>, 
 Kairui Song <ryncsn@gmail.com>, Xiang Liu <liuxiang.277@bytedance.com>, 
 Ehab Ababneh <ehab.ababneh@intel.com>, 
 zhaozhengzhuo <zhaozhengzhuo@uniontech.com>, 
 Lian Wang <lianux.mm@gmail.com>, Kunwu Chan <kunwu.chan@gmail.com>, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 damon@lists.linux.dev, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792088152; l=2034;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=bqSj6GEUFE1ch4tTEQEPZOkssBWYsWV/WhQc/GCJ0Bs=;
 b=ade8dgVk/QLtMdvzfHEj3EebA82ilil4wqag8aQYk8TBs2jVnr7PYCpkRECMbBvrjTfV5YSLN
 PEO3hnbVTjMAeyNrCoshcrvmZa1ho7dU4F2NiVCiQv+mbLQ0DEfSQ5d
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a helper that resolves a stable lruvec for a folio under RCU
without taking the lruvec lock.  It takes a folio directly so the
lruvec lookup happens inside the RCU read-side critical section,
which a lruvec-based interface cannot guarantee.

No functional change.

Tested-by: zhaozhengzhuo <zhaozhengzhuo@uniontech.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/memcontrol.h | 39 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index 74110a324f9e..829ab776ab44 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -1535,6 +1535,45 @@ static inline void lruvec_lock_irq(struct lruvec *lruvec)
 	spin_lock_irq(&lruvec->lru_lock);
 }
 
+/**
+ * folio_lruvec_live_get - get a live lruvec for a folio under RCU
+ * @folio: the folio
+ *
+ * Computes @folio's lruvec and walks up to the nearest live ancestor
+ * if the folio's memcg is dying.  Paired with folio_lruvec_live_put().
+ * The result may be stale: RCU keeps it alive but does not pin @folio
+ * to it.  That is fine as the counters are fixed up on reparenting.
+ *
+ * Return: the live lruvec, with rcu_read_lock held.
+ */
+static inline struct lruvec *folio_lruvec_live_get(struct folio *folio)
+{
+#ifdef CONFIG_MEMCG
+	struct lruvec *lruvec;
+	struct pglist_data *pgdat;
+	struct mem_cgroup *memcg;
+
+	rcu_read_lock();
+	lruvec = folio_lruvec(folio);
+	pgdat = lruvec_pgdat(lruvec);
+	memcg = lruvec_memcg(lruvec);
+	while (unlikely(memcg && css_is_dying(&memcg->css))) {
+		memcg = parent_mem_cgroup(memcg);
+		lruvec = mem_cgroup_lruvec(memcg, pgdat);
+	}
+	return lruvec;
+#else
+	return folio_lruvec(folio);
+#endif
+}
+
+static inline void folio_lruvec_live_put(struct lruvec *lruvec)
+{
+#ifdef CONFIG_MEMCG
+	rcu_read_unlock();
+#endif
+}
+
 static inline struct lruvec *lruvec_live_lock_irq(struct lruvec *lruvec)
 {
 #ifdef CONFIG_MEMCG

-- 
2.56.0

