From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 20 Jul 2026 17:25:11 -0700
Subject: [PATCH v3 08/13] WIP: mm: hugetlb: Make struct hugepage_subpool
 private to hugetlb_subpool.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hugetlb-alloc-failure-fixes-v3-8-7d2a169aa9ee@google.com>
References: <20260720-hugetlb-alloc-failure-fixes-v3-0-7d2a169aa9ee@google.com>
In-Reply-To: <20260720-hugetlb-alloc-failure-fixes-v3-0-7d2a169aa9ee@google.com>
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Nhat Pham <nphamcs@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Peter Xu <peterx@redhat.com>, 
 Wupeng Ma <mawupeng1@huawei.com>, fvdl@google.com, rientjes@google.com, 
 jthoughton@google.com, Mike Kravetz <mike.kravetz@oracle.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>
Cc: vannapurve@google.com, erdemaktas@google.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784602387; l=2362;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=M6CZbHlay9O7mPyDIiOB40w5xsbkP4SdrC/EYdyZfC0=;
 b=EKSNPcPFErEcErK9ZdAcLB9AUma7YsDD5mhlF9ptqMRDEPyM8LE51vREzhRtzj/WSlU3plrqD
 WQwh+ogZMhrC8TVS/THJDOBsQh9QXXvOAFq7sC5ey7BszOhs0v7FFYF
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that all filesystem and memory management subpool layout inspections across
`fs/hugetlbfs/inode.c` and `mm/` leverage the exported, harmonized APIs, transition
`struct hugepage_subpool` out of the public header `include/linux/hugetlb.h` and
encapsulate it privately inside `mm/hugetlb_subpool.c`.

Replace the header definition with a forward declaration, completely protecting the
underlying subpool allocation counters, reservations, and spinlock boundaries.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/hugetlb.h | 13 ++-----------
 mm/hugetlb_subpool.c    | 12 ++++++++++++
 2 files changed, 14 insertions(+), 11 deletions(-)

diff --git a/include/linux/hugetlb.h b/include/linux/hugetlb.h
index f36be371c6e88..074a45903973e 100644
--- a/include/linux/hugetlb.h
+++ b/include/linux/hugetlb.h
@@ -18,6 +18,7 @@
 
 struct mmu_gather;
 struct node;
+struct hstate;
 
 void free_huge_folio(struct folio *folio);
 
@@ -34,17 +35,7 @@ void free_huge_folio(struct folio *folio);
  */
 #define __NR_USED_SUBPAGE 3
 
-struct hugepage_subpool {
-	spinlock_t lock;
-	long count;
-	long max_hpages;	/* Maximum huge pages or -1 if no maximum. */
-	long used_hpages;	/* Used page count, includes both */
-				/* allocated and reserved pages. */
-	struct hstate *hstate;
-	long min_hpages;	/* Minimum huge pages or -1 if no minimum. */
-	long rsv_hpages;	/* Pages reserved against global pool to */
-				/* satisfy minimum size. */
-};
+struct hugepage_subpool;
 
 struct resv_map {
 	struct kref refs;
diff --git a/mm/hugetlb_subpool.c b/mm/hugetlb_subpool.c
index 99e7975911079..eb5472bdf2192 100644
--- a/mm/hugetlb_subpool.c
+++ b/mm/hugetlb_subpool.c
@@ -14,6 +14,18 @@
 #include <linux/bug.h>
 #include "hugetlb_subpool.h"
 
+struct hugepage_subpool {
+	spinlock_t lock;
+	long count;
+	long max_hpages;	/* Maximum huge pages or -1 if no maximum. */
+	long used_hpages;	/* Used page count, includes both */
+				/* allocated and reserved pages. */
+	struct hstate *hstate;
+	long min_hpages;	/* Minimum huge pages or -1 if no minimum. */
+	long rsv_hpages;	/* Pages reserved against global pool to */
+				/* satisfy minimum size. */
+};
+
 static inline bool subpool_is_free(struct hugepage_subpool *spool)
 {
 	if (spool->count)

-- 
2.55.0.229.g6434b31f56-goog

