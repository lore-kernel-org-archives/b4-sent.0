From: Kairui Song <kasong@tencent.com>
Date: Wed, 04 Nov 2026 00:25:47 +0800
Subject: [PATCH v4 3/3] mm, swap: drop the swap cache guard and reclaim in
 swap_free_hibernation_slot()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-swap-hibernation-slots-v4-3-0ba9393609e1@tencent.com>
References: <20261104-swap-hibernation-slots-v4-0-0ba9393609e1@tencent.com>
In-Reply-To: <20261104-swap-hibernation-slots-v4-0-0ba9393609e1@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <baoquan.he@linux.dev>, Barry Song <baohua@kernel.org>, 
 Jianyue Wu <wujianyue000@gmail.com>, Youngjun Park <youngjun.park@lge.com>, 
 "David Hildenbrand (Arm)" <david@kernel.org>, 
 Kairui Song <ryncsn@gmail.com>, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793723146; l=1453;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=HPBYUP9MF3eSuiR7PGXZbC8XEUoasVA5Ed/MrXu8OwY=;
 b=4uNVtu2qFnk2q3Ro3dEgv6Ysy2ZgK5QDFSXGgJ3BR5URLa/fqYZSm2gIUkczc6q/+EjLyM7Pp
 boIUOm6t6rxBLDX/bw1typJvrJs67/sZAvugRsZ71of0Po6iNzyXGyc
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Youngjun Park <youngjun.park@lge.com>

Both are there for a folio that readahead might have put on the slot.  A
hibernation entry is not a shadow and has no swap count, so the swap cache
turns it away and no such folio can exist.

Signed-off-by: Youngjun Park <youngjun.park@lge.com>
Acked-by: Kairui Song <kasong@tencent.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swapfile.c | 12 +-----------
 1 file changed, 1 insertion(+), 11 deletions(-)

diff --git a/mm/swapfile.c b/mm/swapfile.c
index c26243140bf2..8dd2ba825413 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -2227,18 +2227,8 @@ void swap_free_hibernation_slot(swp_entry_t entry)
 	pgoff_t offset = swp_offset(entry);
 
 	ci = swap_cluster_lock(si, offset);
-	/*
-	 * A slot with a folio in the swap cache is freed when the folio
-	 * leaves the cache, the same rule swap_put_entries_cluster() follows.
-	 * Readahead can put a folio here, and freeing the slot now would
-	 * leave that folio with no entry behind it.
-	 */
-	if (!swp_tb_is_folio(__swap_table_get(ci, offset % SWAPFILE_CLUSTER)))
-		__swap_cluster_free_entries(si, ci, offset % SWAPFILE_CLUSTER, 1);
+	__swap_cluster_free_entries(si, ci, offset % SWAPFILE_CLUSTER, 1);
 	swap_cluster_unlock(ci);
-
-	/* In theory readahead might add it to the swap cache by accident */
-	__try_to_reclaim_swap(si, offset, TTRS_ANYWAY);
 }
 
 static int __find_hibernation_swap_type(dev_t device, sector_t offset)

-- 
2.56.0

