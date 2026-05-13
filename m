From: Kairui Song <kasong@tencent.com>
Date: Wed, 13 May 2026 17:21:11 +0800
Subject: [PATCH] mm, swap: avoid leaving unused extend table after alloc
 race
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260513-swap-extend-table-fix-v1-1-a71dea851fb3@tencent.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMUQrCMBCE4auUfXahCVbFq4gPaXaqKxJLNmqh9
 O5N9fEbmH8mQ1YYnZuZMj5q+koVbtdQvId0A6tUk2/9oe2cZ/uGkTEVJOES+id40IkhR3HDvjt
 JiFS/Y0adf93L9W979w/EssVoWVZl+BbseQAAAA==
X-Change-ID: 20260512-swap-extend-table-fix-ed7d1f458dac
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Breno Leitao <leitao@debian.org>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 Youngjun Park <youngjun.park@lge.com>, Kairui Song <ryncsn@gmail.com>, 
 linux-kernel@vger.kernel.org, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778664071; l=3322;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=olohF3NDSrfjvRRAsUpHGpzDKysDHKS6sIdmBbNETbA=;
 b=zpAlWCyt1bbDtA2xwMhWBQt1LZ0rOwusVROrVS8ULCEYK8RVrCy3ZRG6YzoMUZBUdCPTLeScB
 RQqXHkwetdFDO1d9a3eVQdPMExYZKu5VPmr8f27kKEH4r5U5nd/pjzM
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allocating an extend table requires dropping the ci lock first.
While the lock is dropped, a concurrent put can decrease the slot's
swap count to a value that is no longer maxed out, so the extend
table is no longer required. The current allocation path still
attach the new extend table to the cluster anyway, leaving it unused.

It's not really leaked, the next maxed out count on the same cluster
reuses the table, and frees it properly. Swapoff will also clean it up.

The worst case is one unused page pinned per cluster until the next
maxed-out allocation or swapoff. To eliminate the waste, re-check
under the ci lock that the extend table is still needed before
publishing it, and free the local allocation otherwise. The added
overhead is ignorable.

Fixes: 0d6af9bcf383 ("mm, swap: use the swap table to track the swap count")
Reported-by: Breno Leitao <leitao@debian.org>
Closes: https://lore.kernel.org/linux-mm/agG6Dp0umhs6O1SY@gmail.com/
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swapfile.c | 32 +++++++++++++++++++++++++-------
 1 file changed, 25 insertions(+), 7 deletions(-)

diff --git a/mm/swapfile.c b/mm/swapfile.c
index 4840fd40f36f..451d20bb9f47 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -1442,8 +1442,10 @@ static bool swap_sync_discard(void)
 }
 
 static int swap_extend_table_alloc(struct swap_info_struct *si,
-				   struct swap_cluster_info *ci, gfp_t gfp)
+				   struct swap_cluster_info *ci,
+				   unsigned int ci_off, gfp_t gfp)
 {
+	int count;
 	void *table;
 
 	table = kzalloc(sizeof(ci->extend_table[0]) * SWAPFILE_CLUSTER, gfp);
@@ -1451,11 +1453,27 @@ static int swap_extend_table_alloc(struct swap_info_struct *si,
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
+	spin_unlock(&ci->lock);
+	return 0;
+
+out_free:
 	spin_unlock(&ci->lock);
+	kfree(table);
 	return 0;
 }
 
@@ -1471,7 +1489,7 @@ int swap_retry_table_alloc(swp_entry_t entry, gfp_t gfp)
 		return 0;
 
 	ci = __swap_offset_to_cluster(si, offset);
-	ret = swap_extend_table_alloc(si, ci, gfp);
+	ret = swap_extend_table_alloc(si, ci, swp_cluster_offset(entry), gfp);
 
 	put_swap_device(si);
 	return ret;
@@ -1664,7 +1682,7 @@ static int swap_dup_entries_cluster(struct swap_info_struct *si,
 		if (unlikely(err)) {
 			if (err == -ENOMEM) {
 				spin_unlock(&ci->lock);
-				err = swap_extend_table_alloc(si, ci, GFP_ATOMIC);
+				err = swap_extend_table_alloc(si, ci, ci_off, GFP_ATOMIC);
 				spin_lock(&ci->lock);
 				if (!err)
 					goto restart;

---
base-commit: 972c53e0ec3abfc6f5fe2cb503640710fb23cf95
change-id: 20260512-swap-extend-table-fix-ed7d1f458dac

Best regards,
--  
Kairui Song <kasong@tencent.com>

