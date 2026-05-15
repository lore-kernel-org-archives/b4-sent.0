From: Kairui Song <kasong@tencent.com>
Date: Fri, 15 May 2026 17:44:14 +0800
Subject: [PATCH v2] mm, swap: avoid leaving unused extend table after alloc
 race
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-swap-extend-table-fix-v2-1-833d72ad53e5@tencent.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0Jm7RimiBBX3sOwKO0gNdqStiKGc
 HcLxqXLN3nz3wyBveEAp2wGz6MJxtkEYpeB6qW9MhqdGEQujnlJAsNLDshTZKsxyvbO2JkJWVe
 aukNZa6kg/Q6e03nbvTRfDs/2xiquY6vRmxCdf2/hkVbv1yj+NEZCQlmRZlmX1LXFOQmKbdwr9
 4BmWZYPC+rFss4AAAA=
X-Change-ID: 20260512-swap-extend-table-fix-ed7d1f458dac
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Breno Leitao <leitao@debian.org>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 Youngjun Park <youngjun.park@lge.com>, Kairui Song <ryncsn@gmail.com>, 
 linux-kernel@vger.kernel.org, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778838260; l=4942;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=mUn/F24LeFaL4ar295oTulNdGtYoq7Q5z5xlo3vUeq4=;
 b=CdQ3G7hU4bfxcF3FIPcmvuP87EoXrhYvS5xnJ7aSYPDNKeyw4SWXXKReRkKm6lI4/XXg/6aKX
 KdWSWu4CFY5AdqaB6JZkx6Uz4a63h2RJ2JjdtfV1/aPuUtGlPYB3gQO
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allocating an extend table requires dropping the ci lock first.
While the lock is dropped, a concurrent put can decrease the slot's
swap count to a value that is no longer maxed out, so the extend
table is no longer required. The current allocation path still
attach the new extend table to the cluster anyway, leaving it unused.

The next maxed out count on the same cluster may still reuse the
table, and frees it properly. But swapoff could leak it indeed.

To eliminate the waste, re-check under the ci lock that the extend
table is still needed before publishing it, and free the local allocation
otherwise.

Also close the check window by ensuring every count decrement that brings
a slot below SWP_TB_COUNT_MAX - 1 runs swap_extend_table_try_free(),
not just the MAX to MAX - 1 transition. With this, a freshly published
extend table that becomes redundant due to a racing put is freed on
the very next decrement, restoring the invariant that an empty cluster
never has a non-NULL ci->extend_table.

The added overhead is ignorable.

Fixes: 0d6af9bcf383 ("mm, swap: use the swap table to track the swap count")
Reported-by: Breno Leitao <leitao@debian.org>
Closes: https://lore.kernel.org/linux-mm/agG6Dp0umhs6O1SY@gmail.com/
Signed-off-by: Kairui Song <kasong@tencent.com>
---
Changes in v2:
- Fix another race found by sashiko:
  https://lore.kernel.org/linux-mm/CAMgjq7CQM+vzjQ-dgnAjvE8+czs1FmrK7Cv+EJ6jCGysa8OSqQ@mail.gmail.com/
- The change is minor, stress tests are looking good, so I kept the old tags.
- Update commit message, swapoff could indeed leak the extend table.
- Link to v1: https://patch.msgid.link/20260513-swap-extend-table-fix-v1-1-a71dea851fb3@tencent.com
---
 mm/swapfile.c | 42 ++++++++++++++++++++++++++++++++++--------
 1 file changed, 34 insertions(+), 8 deletions(-)

diff --git a/mm/swapfile.c b/mm/swapfile.c
index 08309c1dafa3..46caad0013b9 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -1443,8 +1443,10 @@ static bool swap_sync_discard(void)
 }
 
 static int swap_extend_table_alloc(struct swap_info_struct *si,
-				   struct swap_cluster_info *ci, gfp_t gfp)
+				   struct swap_cluster_info *ci,
+				   unsigned int ci_off, gfp_t gfp)
 {
+	int count;
 	void *table;
 
 	table = kzalloc(sizeof(ci->extend_table[0]) * SWAPFILE_CLUSTER, gfp);
@@ -1452,12 +1454,28 @@ static int swap_extend_table_alloc(struct swap_info_struct *si,
 		return -ENOMEM;
 
 	spin_lock(&ci->lock);
-	if (!ci->extend_table)
-		ci->extend_table = table;
-	else
-		kfree(table);
+	/*
+	 * Extend table allocation requires releasing ci lock first so it's
+	 * possible that the slot has been freed, no longer overflowed, or
+	 * a concurrent extend table allocation has already succeeded, so
+	 * the allocation is no longer needed.
+	 */
+	if (!cluster_table_is_alloced(ci))
+		goto out_free;
+	count = swp_tb_get_count(__swap_table_get(ci, ci_off));
+	if (count < (SWP_TB_COUNT_MAX - 1))
+		goto out_free;
+	if (ci->extend_table)
+		goto out_free;
+
+	ci->extend_table = table;
 	spin_unlock(&ci->lock);
 	return 0;
+
+out_free:
+	spin_unlock(&ci->lock);
+	kfree(table);
+	return 0;
 }
 
 int swap_retry_table_alloc(swp_entry_t entry, gfp_t gfp)
@@ -1472,7 +1490,7 @@ int swap_retry_table_alloc(swp_entry_t entry, gfp_t gfp)
 		return 0;
 
 	ci = __swap_offset_to_cluster(si, offset);
-	ret = swap_extend_table_alloc(si, ci, gfp);
+	ret = swap_extend_table_alloc(si, ci, swp_cluster_offset(entry), gfp);
 
 	put_swap_device(si);
 	return ret;
@@ -1519,13 +1537,21 @@ static void __swap_cluster_put_entry(struct swap_cluster_info *ci,
 		if (count == (SWP_TB_COUNT_MAX - 1)) {
 			ci->extend_table[ci_off] = 0;
 			__swap_table_set(ci, ci_off, __swp_tb_mk_count(swp_tb, count));
-			swap_extend_table_try_free(ci);
 		} else {
 			ci->extend_table[ci_off] = count;
 		}
 	} else {
 		__swap_table_set(ci, ci_off, __swp_tb_mk_count(swp_tb, --count));
 	}
+
+	/*
+	 * `SWP_TB_COUNT_MAX - 1` triggers extend table allocation. If the
+	 * count was above that, then the extend table is no longer needed,
+	 * so free it. And if we just put the count value from MAX - 1, it's
+	 * also possible that a pending dup just attached an extend table.
+	 */
+	if (unlikely(count == SWP_TB_COUNT_MAX - 2 || count == SWP_TB_COUNT_MAX - 1))
+		swap_extend_table_try_free(ci);
 }
 
 /**
@@ -1665,7 +1691,7 @@ static int swap_dup_entries_cluster(struct swap_info_struct *si,
 		if (unlikely(err)) {
 			if (err == -ENOMEM) {
 				spin_unlock(&ci->lock);
-				err = swap_extend_table_alloc(si, ci, GFP_ATOMIC);
+				err = swap_extend_table_alloc(si, ci, ci_off, GFP_ATOMIC);
 				spin_lock(&ci->lock);
 				if (!err)
 					goto restart;

---
base-commit: 444fc9435e57157fcf30fc99aee44997f3458641
change-id: 20260512-swap-extend-table-fix-ed7d1f458dac

Best regards,
--  
Kairui Song <kasong@tencent.com>

