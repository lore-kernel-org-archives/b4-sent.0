From: Kairui Song <kasong@tencent.com>
Date: Wed, 18 Feb 2026 04:06:29 +0800
Subject: [PATCH v3 04/12] mm, swap: consolidate bad slots setup and make it
 more robust
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260218-swap-table-p3-v3-4-f4e34be021a7@tencent.com>
References: <20260218-swap-table-p3-v3-0-f4e34be021a7@tencent.com>
In-Reply-To: <20260218-swap-table-p3-v3-0-f4e34be021a7@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 Youngjun Park <youngjun.park@lge.com>, linux-kernel@vger.kernel.org, 
 Chris Li <chrisl@kernel.org>, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771358806; l=4411;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=dTxwU7HNi4RjZm8BIg4m/tk9gYStmKjj5MiTeMIyv7o=;
 b=X0FBoaZxzsjFgaOx7GXTnkZmNCoBeOVc8rrBdBmxLga4IAkX6V3jxFmOmyvmmFpMTcvJKdXBw
 Yoz2wOXCe4kDldrwEgD0/8IdRNTGJgxl5dcBRLKsDyf9zXElv8040Od
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In preparation for using the swap table to track bad slots directly,
move the bad slot setup to one place, set up the swap_map mark, and
cluster counter update together.

While at it, provide more informative logs and a more robust fallback if
any bad slot info looks incorrect.

Fixes a potential issue that a malformed swap file may cause the cluster
to be unusable upon swapon, and provides a more verbose warning on a
malformed swap file

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swapfile.c | 68 +++++++++++++++++++++++++++++++++--------------------------
 1 file changed, 38 insertions(+), 30 deletions(-)

diff --git a/mm/swapfile.c b/mm/swapfile.c
index fb0d48681c48..91c1fa804185 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -743,13 +743,37 @@ static void relocate_cluster(struct swap_info_struct *si,
  * slot. The cluster will not be added to the free cluster list, and its
  * usage counter will be increased by 1. Only used for initialization.
  */
-static int swap_cluster_setup_bad_slot(struct swap_cluster_info *cluster_info,
-				       unsigned long offset)
+static int swap_cluster_setup_bad_slot(struct swap_info_struct *si,
+				       struct swap_cluster_info *cluster_info,
+				       unsigned int offset, bool mask)
 {
 	unsigned long idx = offset / SWAPFILE_CLUSTER;
 	struct swap_table *table;
 	struct swap_cluster_info *ci;
 
+	/* si->max may got shrunk by swap swap_activate() */
+	if (offset >= si->max && !mask) {
+		pr_debug("Ignoring bad slot %u (max: %u)\n", offset, si->max);
+		return 0;
+	}
+	/*
+	 * Account it, skip header slot: si->pages is initiated as
+	 * si->max - 1. Also skip the masking of last cluster,
+	 * si->pages doesn't include that part.
+	 */
+	if (offset && !mask)
+		si->pages -= 1;
+	if (!si->pages) {
+		pr_warn("Empty swap-file\n");
+		return -EINVAL;
+	}
+	/* Check for duplicated bad swap slots. */
+	if (si->swap_map[offset]) {
+		pr_warn("Duplicated bad slot offset %d\n", offset);
+		return -EINVAL;
+	}
+
+	si->swap_map[offset] = SWAP_MAP_BAD;
 	ci = cluster_info + idx;
 	if (!ci->table) {
 		table = swap_table_alloc(GFP_KERNEL);
@@ -3227,30 +3251,12 @@ static int setup_swap_map(struct swap_info_struct *si,
 			  union swap_header *swap_header,
 			  unsigned long maxpages)
 {
-	unsigned long i;
 	unsigned char *swap_map;
 
 	swap_map = vzalloc(maxpages);
 	si->swap_map = swap_map;
 	if (!swap_map)
 		return -ENOMEM;
-
-	swap_map[0] = SWAP_MAP_BAD; /* omit header page */
-	for (i = 0; i < swap_header->info.nr_badpages; i++) {
-		unsigned int page_nr = swap_header->info.badpages[i];
-		if (page_nr == 0 || page_nr > swap_header->info.last_page)
-			return -EINVAL;
-		if (page_nr < maxpages) {
-			swap_map[page_nr] = SWAP_MAP_BAD;
-			si->pages--;
-		}
-	}
-
-	if (!si->pages) {
-		pr_warn("Empty swap-file\n");
-		return -EINVAL;
-	}
-
 	return 0;
 }
 
@@ -3281,26 +3287,28 @@ static int setup_swap_clusters_info(struct swap_info_struct *si,
 	}
 
 	/*
-	 * Mark unusable pages as unavailable. The clusters aren't
-	 * marked free yet, so no list operations are involved yet.
-	 *
-	 * See setup_swap_map(): header page, bad pages,
-	 * and the EOF part of the last cluster.
+	 * Mark unusable pages (header page, bad pages, and the EOF part of
+	 * the last cluster) as unavailable. The clusters aren't marked free
+	 * yet, so no list operations are involved yet.
 	 */
-	err = swap_cluster_setup_bad_slot(cluster_info, 0);
+	err = swap_cluster_setup_bad_slot(si, cluster_info, 0, false);
 	if (err)
 		goto err;
 	for (i = 0; i < swap_header->info.nr_badpages; i++) {
 		unsigned int page_nr = swap_header->info.badpages[i];
 
-		if (page_nr >= maxpages)
-			continue;
-		err = swap_cluster_setup_bad_slot(cluster_info, page_nr);
+		if (!page_nr || page_nr > swap_header->info.last_page) {
+			pr_warn("Bad slot offset is out of border: %d (last_page: %d)\n",
+				page_nr, swap_header->info.last_page);
+			err = -EINVAL;
+			goto err;
+		}
+		err = swap_cluster_setup_bad_slot(si, cluster_info, page_nr, false);
 		if (err)
 			goto err;
 	}
 	for (i = maxpages; i < round_up(maxpages, SWAPFILE_CLUSTER); i++) {
-		err = swap_cluster_setup_bad_slot(cluster_info, i);
+		err = swap_cluster_setup_bad_slot(si, cluster_info, i, true);
 		if (err)
 			goto err;
 	}

-- 
2.52.0

