From: Kairui Song <kasong@tencent.com>
Date: Sat, 14 Nov 2026 05:26:18 +0800
Subject: [PATCH RFC 2/8] xarray: add xas_prev_canonical()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-swap-thp-split-v1-2-dfa8d4fa448d@tencent.com>
References: <20261114-swap-thp-split-v1-0-dfa8d4fa448d@tencent.com>
In-Reply-To: <20261114-swap-thp-split-v1-0-dfa8d4fa448d@tencent.com>
To: linux-mm@kvack.org
Cc: David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Matthew Wilcox <willy@infradead.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Zi Yan <ziy@nvidia.com>, 
 Nico Pache <nico.pache@linux.dev>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794605194; l=8119;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=F1Xh8X4E0iUXFanXwmpaX6dnEVbj5dOQIdvLxxlmNoQ=;
 b=l5BlWayWK/H3mc/6q/UJE4gWzCpMxj2+G0VExlA1+S1X0md5aFyGgy37Sayjtiec9Kjgx0f8C
 etPS5lgKfU/BWase7XmBFH+du30T8Fs+gRYkvZo1+UtwN/H3Wep4hfG
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xas_prev() moves one index at a time, so stepping backwards into a
multi-index entry can stop on a sibling slot. The new xas_prev_canonical()
steps back over an entry as a whole: it leaves the state on the slot
holding the entry and on the first index that entry covers, so
xas_get_order() also reports its order.

A cursor already inside an entry reports it instead of stepping off.

Cover it in the test suite too.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/xarray.h | 49 +++++++++++++++++++++++++
 lib/test_xarray.c      | 97 ++++++++++++++++++++++++++++++++++++++++++++++++++
 lib/xarray.c           |  8 -----
 3 files changed, 146 insertions(+), 8 deletions(-)

diff --git a/include/linux/xarray.h b/include/linux/xarray.h
index be850174e802..b76d24e7a46b 100644
--- a/include/linux/xarray.h
+++ b/include/linux/xarray.h
@@ -1502,6 +1502,15 @@ static inline bool xas_top(struct xa_node *node)
 	return node <= XAS_RESTART;
 }
 
+/* Move the index either forwards (find) or backwards (sibling slot) */
+static inline void xas_move_index(struct xa_state *xas, unsigned long offset)
+{
+	unsigned int shift = xas->xa_node->shift;
+
+	xas->xa_index &= ~XA_CHUNK_MASK << shift;
+	xas->xa_index += offset << shift;
+}
+
 /**
  * xas_reset() - Reset an XArray operation state.
  * @xas: XArray operation state.
@@ -1883,6 +1892,46 @@ static inline void *xas_prev(struct xa_state *xas)
 	return xa_entry(xas->xa, node, xas->xa_offset);
 }
 
+/**
+ * xas_prev_canonical() - Move iterator to the previous entry, onto the slot
+ * which stores it.
+ * @xas: XArray operation state.
+ *
+ * Same as xas_prev(), but it steps back over a multi-index entry as a
+ * whole: the state is left on the slot which stores the entry and on its
+ * first index, so xas_get_order() reports its order.  A cursor already
+ * inside an entry reports that entry instead of stepping off it.
+ *
+ * Context: Any context.  Hold the xa_lock or the RCU lock across the
+ * whole walk; xas_pause() is forward-only.
+ * Return: The entry at the new position, or %NULL (empty slot, error
+ * state, or the end of the walk).  The result may be an internal entry,
+ * which needs xas_retry().
+ */
+static inline void *xas_prev_canonical(struct xa_state *xas)
+{
+	void *entry = NULL;
+
+	/* step back unless @xas is already inside an entry */
+	if (!xas_is_node(xas) ||
+	    xas->xa_offset >= XA_CHUNK_SIZE ||
+	    xas->xa_offset == ((xas->xa_index >> xas->xa_node->shift) &
+			       XA_CHUNK_MASK))
+		entry = xas_prev(xas);
+	if (!xas_is_node(xas))
+		return entry;
+	if (xa_is_sibling(entry))
+		xas->xa_offset = xa_to_sibling(entry);
+
+	entry = xa_entry(xas->xa, xas->xa_node, xas->xa_offset);
+	/* a concurrent store or split can leave a sibling or a node here */
+	if (xa_is_sibling(entry) ||
+	    (xas->xa_node->shift && xa_is_node(entry)))
+		return XA_RETRY_ENTRY;
+	xas_move_index(xas, xas->xa_offset);
+	return entry;
+}
+
 /**
  * xas_next() - Move state to next index.
  * @xas: XArray operation state.
diff --git a/lib/test_xarray.c b/lib/test_xarray.c
index 615f7730a5bd..ad4507982b5b 100644
--- a/lib/test_xarray.c
+++ b/lib/test_xarray.c
@@ -2011,6 +2011,101 @@ static noinline void check_split(struct xarray *xa)
 static void check_split(struct xarray *xa) { }
 #endif
 
+/* Only the head holds an entry, and there is no node to walk */
+static noinline void check_prev_canonical_no_walk(struct xarray *xa)
+{
+	XA_STATE(xas, xa, 0);
+
+	xa_store(xa, 0, xa_mk_value(0x123), GFP_KERNEL);
+	xas_lock(&xas);
+	XA_BUG_ON(xa, xas_prev_canonical(&xas) != xa_mk_value(0x123));
+	XA_BUG_ON(xa, xas.xa_index != 0);
+	xas_unlock(&xas);
+	xa_destroy(xa);
+}
+
+static noinline void check_prev_canonical(struct xarray *xa)
+{
+	XA_STATE(xas, xa, 0);
+	void *entry;
+	unsigned long index;
+
+	/* Order 0 entries at [XA_CHUNK_SIZE / 2, XA_CHUNK_SIZE * 3 / 2 - 1] */
+	for (index = XA_CHUNK_SIZE / 2; index < XA_CHUNK_SIZE * 3 / 2; index++)
+		xa_store(xa, index, xa_mk_value(index), GFP_KERNEL);
+	/* A single order 0 entry at the very end */
+	xa_store(xa, XA_CHUNK_SIZE * 17 / 4, xa_mk_value(0xef), GFP_KERNEL);
+
+#ifdef CONFIG_XARRAY_MULTI
+	/* Entry A at [XA_CHUNK_SIZE * 3 / 2, XA_CHUNK_SIZE * 2 - 1] */
+	xa_store_order(xa, XA_CHUNK_SIZE * 3 / 2, XA_CHUNK_SHIFT - 1,
+		       xa_mk_value(0x123), GFP_KERNEL);
+	/* Entry B at [XA_CHUNK_SIZE * 2, XA_CHUNK_SIZE * 4 - 1] */
+	xa_store_order(xa, 2 * XA_CHUNK_SIZE, XA_CHUNK_SHIFT + 1,
+		       xa_mk_value(0x456), GFP_KERNEL);
+	/* Entry C at [XA_CHUNK_SIZE * 4, XA_CHUNK_SIZE * 17 / 4 - 1] */
+	xa_store_order(xa, 4 * XA_CHUNK_SIZE, XA_CHUNK_SHIFT - 2,
+		       xa_mk_value(0x789), GFP_KERNEL);
+#endif
+
+	xas_lock(&xas);
+#ifdef CONFIG_XARRAY_MULTI
+	/* A cursor inside the entry A reports it */
+	xas_set_order(&xas, 2 * XA_CHUNK_SIZE - 1, 0);
+	xas_load(&xas);
+	XA_BUG_ON(xa, xas_prev_canonical(&xas) != xa_mk_value(0x123));
+	XA_BUG_ON(xa, xas.xa_index != XA_CHUNK_SIZE * 3 / 2);
+	XA_BUG_ON(xa, xas_get_order(&xas) != XA_CHUNK_SHIFT - 1);
+	/* Replacing it to 0xABC: an order 0 store keeps its siblings */
+	XA_BUG_ON(xa, xas_store(&xas, xa_mk_value(0xABC)) !=
+		       xa_mk_value(0x123));
+#endif
+
+	/* A bounded walk over the last leaf ends past its last slot */
+	xas_set(&xas, 4 * XA_CHUNK_SIZE);
+	xas_for_each(&xas, entry, 5 * XA_CHUNK_SIZE - 1) { }
+	XA_BUG_ON(xa, xas.xa_offset != XA_CHUNK_SIZE);
+	XA_BUG_ON(xa, xas_prev_canonical(&xas) != NULL);
+	XA_BUG_ON(xa, xas.xa_index != 5 * XA_CHUNK_SIZE - 1);
+
+	/* Walk, and every step lands one entry back */
+	xas_set_order(&xas, XA_CHUNK_SIZE * 17 / 4, 0);
+
+	/* Read back the ending order 0 entry */
+	XA_BUG_ON(xa, xas_prev_canonical(&xas) != xa_mk_value(0xef));
+	XA_BUG_ON(xa, xas.xa_index != XA_CHUNK_SIZE * 17 / 4);
+	XA_BUG_ON(xa, xas_get_order(&xas) != 0);
+
+#ifdef CONFIG_XARRAY_MULTI
+	/* Read entry C */
+	XA_BUG_ON(xa, xas_prev_canonical(&xas) != xa_mk_value(0x789));
+	XA_BUG_ON(xa, xas.xa_index != 4 * XA_CHUNK_SIZE);
+	XA_BUG_ON(xa, xas_get_order(&xas) != XA_CHUNK_SHIFT - 2);
+	/* Read entry B */
+	XA_BUG_ON(xa, xas_prev_canonical(&xas) != xa_mk_value(0x456));
+	XA_BUG_ON(xa, xas.xa_index != 2 * XA_CHUNK_SIZE);
+	XA_BUG_ON(xa, xas_get_order(&xas) != XA_CHUNK_SHIFT + 1);
+	/* Read entry A, holding the value stored above */
+	XA_BUG_ON(xa, xas_prev_canonical(&xas) != xa_mk_value(0xABC));
+	XA_BUG_ON(xa, xas.xa_index != XA_CHUNK_SIZE * 3 / 2);
+	XA_BUG_ON(xa, xas_get_order(&xas) != XA_CHUNK_SHIFT - 1);
+#endif
+
+	/* The order 0 entries, in the leaf below entry A */
+	xas_set_order(&xas, XA_CHUNK_SIZE * 3 / 2 - 1, 0);
+	for (index = XA_CHUNK_SIZE * 3 / 2; index > XA_CHUNK_SIZE / 2; index--) {
+		XA_BUG_ON(xa, xas_prev_canonical(&xas) !=
+			       xa_mk_value(index - 1));
+		XA_BUG_ON(xa, xas_store(&xas, xa_mk_value(2)) !=
+			       xa_mk_value(index - 1));
+	}
+
+	/* The hole ends the walk */
+	XA_BUG_ON(xa, xas_prev_canonical(&xas) != NULL);
+	xas_unlock(&xas);
+	xa_destroy(xa);
+}
+
 static void check_align_1(struct xarray *xa, char *name)
 {
 	int i;
@@ -2328,6 +2423,8 @@ static int xarray_checks(void)
 	check_store_iter(&array);
 	check_align(&xa0);
 	check_split(&array);
+	check_prev_canonical_no_walk(&array);
+	check_prev_canonical(&array);
 
 	check_workingset(&array, 0);
 	check_workingset(&array, 64);
diff --git a/lib/xarray.c b/lib/xarray.c
index 48f440d114e1..1c295b9404dc 100644
--- a/lib/xarray.c
+++ b/lib/xarray.c
@@ -152,14 +152,6 @@ static void xas_set_offset(struct xa_state *xas)
 	xas->xa_offset = get_offset(xas->xa_index, xas->xa_node);
 }
 
-/* move the index either forwards (find) or backwards (sibling slot) */
-static void xas_move_index(struct xa_state *xas, unsigned long offset)
-{
-	unsigned int shift = xas->xa_node->shift;
-	xas->xa_index &= ~XA_CHUNK_MASK << shift;
-	xas->xa_index += offset << shift;
-}
-
 static void xas_next_offset(struct xa_state *xas)
 {
 	xas->xa_offset++;

-- 
2.56.1

