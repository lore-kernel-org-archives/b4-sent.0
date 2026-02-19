From: Kairui Song <kasong@tencent.com>
Date: Fri, 20 Feb 2026 07:42:15 +0800
Subject: [PATCH RFC 14/15] mm, swap: add a special device for ghost swap
 setup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-swap-table-p4-v1-14-104795d19815@tencent.com>
References: <20260220-swap-table-p4-v1-0-104795d19815@tencent.com>
In-Reply-To: <20260220-swap-table-p4-v1-0-104795d19815@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, Zi Yan <ziy@nvidia.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Barry Song <baohua@kernel.org>, 
 Hugh Dickins <hughd@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Yosry Ahmed <yosry.ahmed@linux.dev>, Youngjun Park <youngjun.park@lge.com>, 
 Chengming Zhou <chengming.zhou@linux.dev>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Qi Zheng <zhengqi.arch@bytedance.com>, linux-kernel@vger.kernel.org, 
 cgroups@vger.kernel.org, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771544524; l=5352;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=O3BFoOFHolD8K6jdQ6r7SaL/46khBUmErm+aeFqPkUg=;
 b=eSqTz2oJlmVuUdj4GCRJ+RA8upcoyTgpzycyxnyD0Gvm4OVZAjVNFL2ffi01TJr2LW/3Zm4hW
 BR62/OWEVH2B9/MuTlXAxlzz7upTFjH/F4IHkz8+Sd28aGdViLoTF/3
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use /dev/ghostswap as a special device so userspace can setup ghost
swap easily without any extra tools.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 drivers/char/mem.c   | 39 +++++++++++++++++++++++++++++++++++++++
 include/linux/swap.h |  2 ++
 mm/swapfile.c        | 22 +++++++++++++++++++---
 3 files changed, 60 insertions(+), 3 deletions(-)

diff --git a/drivers/char/mem.c b/drivers/char/mem.c
index cca4529431f8..8d0eb3f7d191 100644
--- a/drivers/char/mem.c
+++ b/drivers/char/mem.c
@@ -30,6 +30,7 @@
 #include <linux/uio.h>
 #include <linux/uaccess.h>
 #include <linux/security.h>
+#include <linux/swap.h>
 
 #define DEVMEM_MINOR	1
 #define DEVPORT_MINOR	4
@@ -667,6 +668,41 @@ static const struct file_operations null_fops = {
 	.uring_cmd	= uring_cmd_null,
 };
 
+#ifdef CONFIG_SWAP
+static ssize_t read_ghostswap(struct file *file, char __user *buf,
+			      size_t count, loff_t *ppos)
+{
+	union swap_header *hdr;
+	size_t to_copy;
+
+	if (*ppos >= PAGE_SIZE)
+		return 0;
+
+	hdr = kzalloc(PAGE_SIZE, GFP_KERNEL);
+	if (!hdr)
+		return -ENOMEM;
+
+	hdr->info.version = 1;
+	hdr->info.last_page = totalram_pages() - 1;
+	memcpy(hdr->magic.magic, "SWAPSPACE2", 10);
+	to_copy = min_t(size_t, count, PAGE_SIZE - *ppos);
+	if (copy_to_user(buf, (char *)hdr + *ppos, to_copy)) {
+		kfree(hdr);
+		return -EFAULT;
+	}
+
+	kfree(hdr);
+	*ppos += to_copy;
+	return to_copy;
+}
+
+static const struct file_operations ghostswap_fops = {
+	.llseek		= null_lseek,
+	.read		= read_ghostswap,
+	.write		= write_null,
+};
+#endif
+
 #ifdef CONFIG_DEVPORT
 static const struct file_operations port_fops = {
 	.llseek		= memory_lseek,
@@ -718,6 +754,9 @@ static const struct memdev {
 #ifdef CONFIG_PRINTK
 	[11] = { "kmsg", &kmsg_fops, 0, 0644 },
 #endif
+#ifdef CONFIG_SWAP
+	[DEVGHOST_MINOR] = { "ghostswap", &ghostswap_fops, 0, 0660 },
+#endif
 };
 
 static int memory_open(struct inode *inode, struct file *filp)
diff --git a/include/linux/swap.h b/include/linux/swap.h
index 3b2efd319f44..b57a4a40f4fe 100644
--- a/include/linux/swap.h
+++ b/include/linux/swap.h
@@ -421,6 +421,8 @@ void free_pages_and_swap_cache(struct encoded_page **, int);
 /* linux/mm/swapfile.c */
 extern atomic_long_t nr_swap_pages;
 extern atomic_t nr_real_swapfiles;
+
+#define DEVGHOST_MINOR	13	/* /dev/ghostswap char device minor */
 extern long total_swap_pages;
 extern atomic_t nr_rotate_swap;
 
diff --git a/mm/swapfile.c b/mm/swapfile.c
index 65666c43cbd5..d054f40ec75f 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -42,6 +42,7 @@
 #include <linux/suspend.h>
 #include <linux/zswap.h>
 #include <linux/plist.h>
+#include <linux/major.h>
 
 #include <asm/tlbflush.h>
 #include <linux/leafops.h>
@@ -1703,6 +1704,7 @@ int folio_alloc_swap(struct folio *folio)
 	unsigned int size = 1 << order;
 	struct swap_cluster_info *ci;
 
+	VM_WARN_ON_FOLIO(folio_test_swapcache(folio), folio);
 	VM_BUG_ON_FOLIO(!folio_test_locked(folio), folio);
 	VM_BUG_ON_FOLIO(!folio_test_uptodate(folio), folio);
 
@@ -3421,6 +3423,10 @@ static int setup_swap_clusters_info(struct swap_info_struct *si,
 	err = swap_cluster_setup_bad_slot(si, cluster_info, 0, false);
 	if (err)
 		goto err;
+
+	if (!swap_header)
+		goto setup_cluster_info;
+
 	for (i = 0; i < swap_header->info.nr_badpages; i++) {
 		unsigned int page_nr = swap_header->info.badpages[i];
 
@@ -3440,6 +3446,7 @@ static int setup_swap_clusters_info(struct swap_info_struct *si,
 			goto err;
 	}
 
+setup_cluster_info:
 	INIT_LIST_HEAD(&si->free_clusters);
 	INIT_LIST_HEAD(&si->full_clusters);
 	INIT_LIST_HEAD(&si->discard_clusters);
@@ -3476,7 +3483,7 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 	struct dentry *dentry;
 	int prio;
 	int error;
-	union swap_header *swap_header;
+	union swap_header *swap_header = NULL;
 	int nr_extents;
 	sector_t span;
 	unsigned long maxpages;
@@ -3528,6 +3535,15 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 		goto bad_swap_unlock_inode;
 	}
 
+	/* /dev/ghostswap: synthesize a ghost swap device. */
+	if (S_ISCHR(inode->i_mode) &&
+	    imajor(inode) == MEM_MAJOR && iminor(inode) == DEVGHOST_MINOR) {
+		maxpages = round_up(totalram_pages(), SWAPFILE_CLUSTER);
+		si->flags |= SWP_GHOST | SWP_SOLIDSTATE;
+		si->bdev = NULL;
+		goto setup;
+	}
+
 	/*
 	 * The swap subsystem needs a major overhaul to support this.
 	 * It doesn't work yet so just disable it for now.
@@ -3550,13 +3566,13 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 		goto bad_swap_unlock_inode;
 	}
 	swap_header = kmap_local_folio(folio, 0);
-
 	maxpages = read_swap_header(si, swap_header, inode);
 	if (unlikely(!maxpages)) {
 		error = -EINVAL;
 		goto bad_swap_unlock_inode;
 	}
 
+setup:
 	si->max = maxpages;
 	si->pages = maxpages - 1;
 	nr_extents = setup_swap_extents(si, swap_file, &span);
@@ -3585,7 +3601,7 @@ SYSCALL_DEFINE2(swapon, const char __user *, specialfile, int, swap_flags)
 
 	if (si->bdev && bdev_nonrot(si->bdev)) {
 		si->flags |= SWP_SOLIDSTATE;
-	} else {
+	} else if (!(si->flags & SWP_SOLIDSTATE)) {
 		atomic_inc(&nr_rotate_swap);
 		inced_nr_rotate_swap = true;
 	}

-- 
2.53.0

