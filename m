From: Kairui Song <kasong@tencent.com>
Date: Tue, 04 Aug 2026 03:47:04 +0800
Subject: [PATCH RFC 08/15] mm/memcg: add folio-based lruvec live helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-mglru-fg-v1-8-4d8dad39dad6@tencent.com>
References: <20260804-mglru-fg-v1-0-4d8dad39dad6@tencent.com>
In-Reply-To: <20260804-mglru-fg-v1-0-4d8dad39dad6@tencent.com>
To: linux-mm@kvack.org
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
 SeongJae Park <sj@kernel.org>, David Rientjes <rientjes@google.com>, 
 Yu Zhao <yuzhao@google.com>, Vernon Yang <vernon2gm@gmail.com>, 
 Zicheng Wang <wangzicheng@honor.com>, Chen Ridong <chenridong@xiaomi.com>, 
 Tal Zussman <tz2294@columbia.edu>, Kairui Song <ryncsn@gmail.com>, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>, Baoquan He <baoquan.he@linux.dev>, 
 Nico Pache <nico.pache@linux.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785786439; l=1942;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=CYaQx+ZxB9rM3tJj/qRBO+O5Fxa1QWpmGb5iZwXshX8=;
 b=++Am5L1YzqiSnxDr9o1VMbCVEwEukS5UN1/zmmuMnpfuljIk/qOzAXVOhUiwyoRYhYQDYt45R
 xgE/vtt5N5wAukyhcBnL6BpQE79+Z9dNxi2hwZQC227lqiolRkVLMAv
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a helper that resolves a stable lruvec for a folio under RCU
without taking the lruvec lock.  It takes a folio directly so the
lruvec lookup happens inside the RCU read-side critical section,
which a lruvec-based interface cannot guarantee.

The lock-taking variant now inlines the ancestor walk instead of
calling a separate helper.

No functional change.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/memcontrol.h | 38 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/include/linux/memcontrol.h b/include/linux/memcontrol.h
index 68f363000d7f..ea0111392b9b 100644
--- a/include/linux/memcontrol.h
+++ b/include/linux/memcontrol.h
@@ -1506,6 +1506,44 @@ static inline void lruvec_lock_irq(struct lruvec *lruvec)
 	spin_lock_irq(&lruvec->lru_lock);
 }
 
+/**
+ * folio_lruvec_live_get - get a live lruvec for a folio under RCU
+ * @folio: the folio
+ *
+ * Computes @folio's lruvec and walks up to the nearest live ancestor
+ * if the folio's memcg is dying.  Must be paired with
+ * folio_lruvec_live_put().
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
2.55.0

