From: Kairui Song <kasong@tencent.com>
Date: Mon, 16 Feb 2026 22:58:03 +0800
Subject: [PATCH v4 2/3] mm, swap: reduce indention for hibernate allocation
 helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260216-hibernate-perf-v4-2-1ba9f0bf1ec9@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771253885; l=2613;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=NAvqyk1BCM82J8HW6Gnh4CX79o/hdmbrD/B6Y3rHXiw=;
 b=k/nFxKLOf037gv1sMhovQ1z7Lzzq5b7SFtNWk9LCk4plm6mzv2JlgbNEHqsWpL6ecmjVkQy7s
 lmvDhThxszvBx4B7SxU8s36kT/fNDml41igu0SWj6EFXOnsA1XxehU2
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It doesn't have to check the device flag, as the allocator will also
check the device flag and refuse to allocate if the device is not
writable. This might cause a trivial waste of CPU cycles of hibernate
allocation raced with swapoff, but that is very unlikely to happen.
Removing the check on the common path should be more helpful.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swapfile.c | 51 +++++++++++++++++++++++----------------------------
 1 file changed, 23 insertions(+), 28 deletions(-)

diff --git a/mm/swapfile.c b/mm/swapfile.c
index 32e0e7545ab8..ea63885f344a 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -1931,35 +1931,30 @@ swp_entry_t swap_alloc_hibernation_slot(int type)
 	struct swap_cluster_info *ci;
 	swp_entry_t entry = {0};
 
-	if (!si)
-		goto fail;
-
-	/* This is called for allocating swap entry, not cache */
-	if (get_swap_device_info(si)) {
-		if (si->flags & SWP_WRITEOK) {
-			/*
-			 * Try the local cluster first if it matches the device. If
-			 * not, try grab a new cluster and override local cluster.
-			 */
-			local_lock(&percpu_swap_cluster.lock);
-			pcp_si = this_cpu_read(percpu_swap_cluster.si[0]);
-			pcp_offset = this_cpu_read(percpu_swap_cluster.offset[0]);
-			if (pcp_si == si && pcp_offset) {
-				ci = swap_cluster_lock(si, pcp_offset);
-				if (cluster_is_usable(ci, 0))
-					offset = alloc_swap_scan_cluster(si, ci, NULL, pcp_offset);
-				else
-					swap_cluster_unlock(ci);
-			}
-			if (!offset)
-				offset = cluster_alloc_swap_entry(si, NULL);
-			local_unlock(&percpu_swap_cluster.lock);
-			if (offset)
-				entry = swp_entry(si->type, offset);
-		}
-		put_swap_device(si);
+	/* Return empty entry if device is not usable (swapoff or full) */
+	if (!si || !get_swap_device_info(si))
+		return entry;
+	/*
+	 * Try the local cluster first if it matches the device. If
+	 * not, try grab a new cluster and override local cluster.
+	 */
+	local_lock(&percpu_swap_cluster.lock);
+	pcp_si = this_cpu_read(percpu_swap_cluster.si[0]);
+	pcp_offset = this_cpu_read(percpu_swap_cluster.offset[0]);
+	if (pcp_si == si && pcp_offset) {
+		ci = swap_cluster_lock(si, pcp_offset);
+		if (cluster_is_usable(ci, 0))
+			offset = alloc_swap_scan_cluster(si, ci, NULL, pcp_offset);
+		else
+			swap_cluster_unlock(ci);
 	}
-fail:
+	if (offset == SWAP_ENTRY_INVALID)
+		offset = cluster_alloc_swap_entry(si, NULL);
+	local_unlock(&percpu_swap_cluster.lock);
+	if (offset)
+		entry = swp_entry(si->type, offset);
+	put_swap_device(si);
+
 	return entry;
 }
 

-- 
2.52.0

