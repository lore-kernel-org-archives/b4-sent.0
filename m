From: Kairui Song <kasong@tencent.com>
Date: Mon, 16 Feb 2026 22:58:04 +0800
Subject: [PATCH v4 3/3] mm, swap: merge common convention and simplify
 allocation helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260216-hibernate-perf-v4-3-1ba9f0bf1ec9@tencent.com>
References: <20260216-hibernate-perf-v4-0-1ba9f0bf1ec9@tencent.com>
In-Reply-To: <20260216-hibernate-perf-v4-0-1ba9f0bf1ec9@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 Carsten Grohmann <mail@carstengrohmann.de>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, linux-kernel@vger.kernel.org, 
 "open list:SUSPEND TO RAM" <linux-pm@vger.kernel.org>, 
 Carsten Grohmann <carstengrohmann@gmx.de>, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771253885; l=4406;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=XE85Cs7eMoW2MzbPsMRN8glTTJ2qQfea8kHvJhs9XRM=;
 b=XjOjKB6C9RKF289BaDOi2fed12TaT5b+w77m1kwzOZ5PBWUKf9cA9Lwh5/Vmc8idUkOkv49cW
 CGGS8aMFVcQCG2luwdfgnGmOyIk+xyV50eFl6DypcOEVr3JsMK69xGJ
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Almost all callers of the cluster scan helper require the: lock -> check
usefulness/emptiness check -> allocate -> unlock routine. So merge them
into the same helper to simplify the code.

While at it, add some kerneldoc too.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swapfile.c | 54 +++++++++++++++++++++++++++++++-----------------------
 1 file changed, 31 insertions(+), 23 deletions(-)

diff --git a/mm/swapfile.c b/mm/swapfile.c
index ea63885f344a..a6276c5ead8e 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -910,7 +910,21 @@ static bool cluster_alloc_range(struct swap_info_struct *si,
 	return true;
 }
 
-/* Try use a new cluster for current CPU and allocate from it. */
+/*
+ * alloc_swap_scan_cluster - Scan and allocate swap entries from one cluster.
+ * @si: the swap device of the cluster.
+ * @ci: the cluster, must be locked.
+ * @folio: the folio to allocate for, could be NULL.
+ * @offset: scan start offset, must be a swap device offset pointing inside @ci.
+ *
+ * Scan the swap slots inside @ci, starting from @offset, and allocate
+ * contiguous entries that point to these slots. If @folio is not NULL, folio
+ * size number of entries are allocated, and the starting entry is stored to
+ * folio->swap. If @folio is NULL, one entry will be allocated and passed to
+ * the caller as the return value. In both cases, the offset is returned.
+ *
+ * This helper also updates the percpu cached cluster.
+ */
 static unsigned int alloc_swap_scan_cluster(struct swap_info_struct *si,
 					    struct swap_cluster_info *ci,
 					    struct folio *folio, unsigned long offset)
@@ -923,11 +937,14 @@ static unsigned int alloc_swap_scan_cluster(struct swap_info_struct *si,
 	bool need_reclaim, ret, usable;
 
 	lockdep_assert_held(&ci->lock);
-	VM_WARN_ON(!cluster_is_usable(ci, order));
 
-	if (end < nr_pages || ci->count + nr_pages > SWAPFILE_CLUSTER)
+	if (!cluster_is_usable(ci, order) || end < nr_pages ||
+	    ci->count + nr_pages > SWAPFILE_CLUSTER)
 		goto out;
 
+	if (cluster_is_empty(ci))
+		offset = cluster_offset(si, ci);
+
 	for (end -= nr_pages; offset <= end; offset += nr_pages) {
 		need_reclaim = false;
 		if (!cluster_scan_range(si, ci, offset, nr_pages, &need_reclaim))
@@ -951,6 +968,14 @@ static unsigned int alloc_swap_scan_cluster(struct swap_info_struct *si,
 		break;
 	}
 out:
+	/*
+	 * Whether the allocation succeeded or failed, relocate the cluster
+	 * and update percpu offset cache. On success this is necessary to
+	 * mark the cluster as cached fast path. On failure, this invalidates
+	 * the percpu cache to indicate an allocation failure and next scan
+	 * should use a new cluster, and move the failed cluster to where it
+	 * should be.
+	 */
 	relocate_cluster(si, ci);
 	swap_cluster_unlock(ci);
 	if (si->flags & SWP_SOLIDSTATE) {
@@ -1060,14 +1085,7 @@ static unsigned long cluster_alloc_swap_entry(struct swap_info_struct *si,
 			goto new_cluster;
 
 		ci = swap_cluster_lock(si, offset);
-		/* Cluster could have been used by another order */
-		if (cluster_is_usable(ci, order)) {
-			if (cluster_is_empty(ci))
-				offset = cluster_offset(si, ci);
-			found = alloc_swap_scan_cluster(si, ci, folio, offset);
-		} else {
-			swap_cluster_unlock(ci);
-		}
+		found = alloc_swap_scan_cluster(si, ci, folio, offset);
 		if (found)
 			goto done;
 	}
@@ -1332,14 +1350,7 @@ static bool swap_alloc_fast(struct folio *folio)
 		return false;
 
 	ci = swap_cluster_lock(si, offset);
-	if (cluster_is_usable(ci, order)) {
-		if (cluster_is_empty(ci))
-			offset = cluster_offset(si, ci);
-		alloc_swap_scan_cluster(si, ci, folio, offset);
-	} else {
-		swap_cluster_unlock(ci);
-	}
-
+	alloc_swap_scan_cluster(si, ci, folio, offset);
 	put_swap_device(si);
 	return folio_test_swapcache(folio);
 }
@@ -1943,10 +1954,7 @@ swp_entry_t swap_alloc_hibernation_slot(int type)
 	pcp_offset = this_cpu_read(percpu_swap_cluster.offset[0]);
 	if (pcp_si == si && pcp_offset) {
 		ci = swap_cluster_lock(si, pcp_offset);
-		if (cluster_is_usable(ci, 0))
-			offset = alloc_swap_scan_cluster(si, ci, NULL, pcp_offset);
-		else
-			swap_cluster_unlock(ci);
+		offset = alloc_swap_scan_cluster(si, ci, NULL, pcp_offset);
 	}
 	if (offset == SWAP_ENTRY_INVALID)
 		offset = cluster_alloc_swap_entry(si, NULL);

-- 
2.52.0

