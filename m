From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 20 Jul 2026 17:25:10 -0700
Subject: [PATCH v3 07/13] WIP: fs: hugetlbfs: Refactor subpool getters and
 integrate with hugetlb_subpool API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hugetlb-alloc-failure-fixes-v3-7-7d2a169aa9ee@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784602387; l=5388;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=/bVMwhDzkKWXm/PUQ4Oz0DueIPwM1LmPE5uQODdNRt4=;
 b=e9KVJDUd1/O3E5VwDVW5E9FSn4k3+pT0IRfemqqYsyY5VfHIO+b7wVSj17bceSsnoRwaed+Zi
 i/0O5pqbxyBCVCbC2l3qDsBLYdKyysNubSNU1FyLXhC3GzBd6/ng4aw
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor the direct field accesses to `spool->max_hpages`, `spool->min_hpages`,
and calculate subpool properties using dedicated, encapsulated accessor getters inside
`mm/hugetlb_subpool.c`.

Introduces and exports the following harmonized subpool getters to `mm/hugetlb_subpool.h`:
- `hugepage_subpool_free_hpages()`
- `hugepage_subpool_max_size()`
- `hugepage_subpool_min_size()`
- `hugepage_subpool_max_hpages()`

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 fs/hugetlbfs/inode.c | 28 +++++++++-------------------
 mm/hugetlb_subpool.c | 45 ++++++++++++++++++++++++++++++++++++++++++++-
 mm/hugetlb_subpool.h |  4 ++++
 3 files changed, 57 insertions(+), 20 deletions(-)

diff --git a/fs/hugetlbfs/inode.c b/fs/hugetlbfs/inode.c
index 8c1caad74c409..8abe0574b1c7e 100644
--- a/fs/hugetlbfs/inode.c
+++ b/fs/hugetlbfs/inode.c
@@ -1060,7 +1060,6 @@ static int hugetlbfs_show_options(struct seq_file *m, struct dentry *root)
 	struct hugetlbfs_sb_info *sbinfo = HUGETLBFS_SB(root->d_sb);
 	struct hugepage_subpool *spool = sbinfo->spool;
 	unsigned long hpage_size = huge_page_size(sbinfo->hstate);
-	unsigned hpage_shift = huge_page_shift(sbinfo->hstate);
 	char mod;
 
 	if (!uid_eq(sbinfo->uid, GLOBAL_ROOT_UID))
@@ -1082,12 +1081,13 @@ static int hugetlbfs_show_options(struct seq_file *m, struct dentry *root)
 	}
 	seq_printf(m, ",pagesize=%lu%c", hpage_size, mod);
 	if (spool) {
-		if (spool->max_hpages != -1)
-			seq_printf(m, ",size=%llu",
-				   (unsigned long long)spool->max_hpages << hpage_shift);
-		if (spool->min_hpages != -1)
-			seq_printf(m, ",min_size=%llu",
-				   (unsigned long long)spool->min_hpages << hpage_shift);
+		unsigned long long max_size = hugepage_subpool_max_size(spool);
+		unsigned long long min_size = hugepage_subpool_min_size(spool);
+
+		if (max_size != -1ULL)
+			seq_printf(m, ",size=%llu", max_size);
+		if (min_size != -1ULL)
+			seq_printf(m, ",min_size=%llu", min_size);
 	}
 	return 0;
 }
@@ -1106,18 +1106,8 @@ static int hugetlbfs_statfs(struct dentry *dentry, struct kstatfs *buf)
 		/* If no limits set, just report 0 or -1 for max/free/used
 		 * blocks, like simple_statfs() */
 		if (sbinfo->spool) {
-			long free_pages;
-
-			spin_lock_irq(&sbinfo->spool->lock);
-			buf->f_blocks = sbinfo->spool->max_hpages;
-			if (sbinfo->spool->max_hpages == -1) {
-				free_pages = -1;
-			} else {
-				free_pages = sbinfo->spool->max_hpages -
-					     sbinfo->spool->used_hpages;
-			}
-			buf->f_bavail = buf->f_bfree = free_pages;
-			spin_unlock_irq(&sbinfo->spool->lock);
+			buf->f_blocks = hugepage_subpool_max_hpages(sbinfo->spool);
+			buf->f_bavail = buf->f_bfree = hugepage_subpool_free_hpages(sbinfo->spool);
 			buf->f_files = sbinfo->max_inodes;
 			buf->f_ffree = sbinfo->free_inodes;
 		}
diff --git a/mm/hugetlb_subpool.c b/mm/hugetlb_subpool.c
index b12c16aa7e4c5..99e7975911079 100644
--- a/mm/hugetlb_subpool.c
+++ b/mm/hugetlb_subpool.c
@@ -12,7 +12,6 @@
 #endif
 #include <linux/spinlock.h>
 #include <linux/bug.h>
-
 #include "hugetlb_subpool.h"
 
 static inline bool subpool_is_free(struct hugepage_subpool *spool)
@@ -41,6 +40,50 @@ static inline void unlock_or_release_subpool(struct hugepage_subpool *spool,
 	}
 }
 
+long hugepage_subpool_free_hpages(struct hugepage_subpool *spool)
+{
+	long free_pages;
+
+	spin_lock_irq(&spool->lock);
+	if (spool->max_hpages == -1)
+		free_pages = -1;
+	else
+		free_pages = spool->max_hpages - spool->used_hpages;
+	spin_unlock_irq(&spool->lock);
+
+	return free_pages;
+}
+
+static unsigned int hugepage_subpool_hpage_shift(struct hugepage_subpool *spool)
+{
+	return huge_page_shift(spool->hstate);
+}
+
+unsigned long long hugepage_subpool_max_size(struct hugepage_subpool *spool)
+{
+	if (spool->max_hpages == -1)
+		return -1ULL;
+	return (unsigned long long)spool->max_hpages << hugepage_subpool_hpage_shift(spool);
+}
+
+unsigned long long hugepage_subpool_min_size(struct hugepage_subpool *spool)
+{
+	if (spool->min_hpages == -1)
+		return -1ULL;
+	return (unsigned long long)spool->min_hpages << hugepage_subpool_hpage_shift(spool);
+}
+
+long hugepage_subpool_max_hpages(struct hugepage_subpool *spool)
+{
+	long max_hpages;
+
+	spin_lock_irq(&spool->lock);
+	max_hpages = spool->max_hpages;
+	spin_unlock_irq(&spool->lock);
+
+	return max_hpages;
+}
+
 struct hugepage_subpool *hugepage_new_subpool(struct hstate *h, long max_hpages,
 						long min_hpages)
 {
diff --git a/mm/hugetlb_subpool.h b/mm/hugetlb_subpool.h
index be1f1cf012c9c..41d22239f2c3e 100644
--- a/mm/hugetlb_subpool.h
+++ b/mm/hugetlb_subpool.h
@@ -13,5 +13,9 @@ struct hugepage_subpool *hugepage_new_subpool(struct hstate *h, long max_hpages,
 void hugepage_put_subpool(struct hugepage_subpool *spool);
 long hugepage_subpool_get_pages(struct hugepage_subpool *spool, long delta);
 long hugepage_subpool_put_pages(struct hugepage_subpool *spool, long delta);
+long hugepage_subpool_free_hpages(struct hugepage_subpool *spool);
+long hugepage_subpool_max_hpages(struct hugepage_subpool *spool);
+unsigned long long hugepage_subpool_max_size(struct hugepage_subpool *spool);
+unsigned long long hugepage_subpool_min_size(struct hugepage_subpool *spool);
 
 #endif /* _MM_HUGETLB_SUBPOOL_H */

-- 
2.55.0.229.g6434b31f56-goog

