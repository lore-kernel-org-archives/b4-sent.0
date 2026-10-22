From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:28:00 -0700
Subject: [PATCH RFC v2 28/50] samples/kvm: Make provider files independent
 of a root pool
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-28-5dd1dc6c660a@google.com>
References: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
In-Reply-To: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
To: Alex Williamson <alex@shazbot.org>, Alexander Graf <graf@amazon.de>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Alexey Kardashevskiy <aik@amd.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Ashish Kalra <ashish.kalra@amd.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Baolu Lu <baolu.lu@linux.intel.com>, Bill Wendling <morbo@google.com>, 
 Borislav Petkov <bp@alien8.de>, Catalin Marinas <catalin.marinas@arm.com>, 
 Christian Brauner <brauner@kernel.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Connor Williamson <connordw@amazon.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, David Hildenbrand <david@kernel.org>, 
 David Rientjes <rientjes@google.com>, David Woodhouse <dwmw2@infradead.org>, 
 Erdem Aktas <erdemaktas@google.com>, Frank van der Linden <fvdl@google.com>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, Fred Griffoul <griffoul@gmail.com>, 
 Gregory Price <gourry@gourry.net>, "H. Peter Anvin" <hpa@zytor.com>, 
 Hugh Dickins <hughd@google.com>, Ingo Molnar <mingo@redhat.com>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, 
 James Houghton <jthoughton@google.com>, Jan Kara <jack@suse.cz>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Jianxiong Gao <jxgao@google.com>, 
 Joerg Roedel <joro@8bytes.org>, Joey Gouly <joey.gouly@arm.com>, 
 John Starks <John.Starks@microsoft.com>, Jonathan Corbet <corbet@lwn.net>, 
 Justin Stitt <justinstitt@google.com>, Kevin Tian <kevin.tian@intel.com>, 
 Lorenzo Stoakes <ljs@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 Michael Roth <michael.roth@amd.com>, Mike Rapoport <rppt@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Nicolin Chen <nicolinc@nvidia.com>, Oliver Upton <oupton@kernel.org>, 
 Paolo Bonzini <pbonzini@redhat.com>, Pratyush Yadav <pratyush@kernel.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Robin Murphy <robin.murphy@arm.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, Shuah Khan <shuah@kernel.org>, 
 Steffen Eiden <seiden@linux.ibm.com>, Steven Price <steven.price@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Tom Lendacky <thomas.lendacky@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Vishal Annapurve <vannapurve@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Will Deacon <will@kernel.org>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Yan Zhao <yan.y.zhao@intel.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, x86@kernel.org, 
 Shuah Khan <skhan@linuxfoundation.org>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, llvm@lists.linux.dev, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=14373;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=XWrssdqecvYTeKbgOR3E/4j1UfbxSbeVXECooite7yU=;
 b=i/Iy61ZCwiUC4kTb/Nd2/YuidtxPfYUDIcAa7k0EK0jeHEpNScT/4csBpKeRZOHryQhI9hDAR
 ab5BeDMRwsoDUJytRerHVs77xeigY7Ns51BLKpnAXvyE0vyMYtf0rBu
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the root pool concept (mps_root) and allow each provider file to
directly allocate its own contiguous memory range from alloc_contig_pages.

Because children are effectively independent and no longer share or
transfer ownership of memory regions, managing a global root pool is
unnecessary and adds artificial restrictions.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/kvm/mem_provider_sample.c | 264 ++++++++++----------------------------
 samples/kvm/mem_provider_sample.h |  37 ++----
 2 files changed, 77 insertions(+), 224 deletions(-)

diff --git a/samples/kvm/mem_provider_sample.c b/samples/kvm/mem_provider_sample.c
index 294b2d65fc29d..a8d40f3c631ed 100644
--- a/samples/kvm/mem_provider_sample.c
+++ b/samples/kvm/mem_provider_sample.c
@@ -2,12 +2,12 @@
 /*
  * mem_provider_sample - a sample memory provider.
  *
- * The module owns a region of physical memory and lends it through child
- * files.
+ * The module provides physical memory through provider files.
  *
- * The control device /dev/mem_provider_sample creates child files.
- * NEW_CHILD carves part of the region into a child file. A page can also
- * be taken away. See mem_provider_sample.h.
+ * The control device /dev/mem_provider_sample creates provider files.
+ * Each file allocates its own contiguous memory from alloc_contig_pages().
+ * Pages can be dynamically marked present or absent.
+ * See mem_provider_sample.h.
  *
  * Confidential VMs are not supported.
  */
@@ -27,43 +27,18 @@
 #include "mem_provider_sample.h"
 
 /*
- * One child file.
- *
- * Lock order: mps_root.lock, then mps_info.lock.
+ * One provider file.
  */
 struct mps_info {
 	struct mutex lock;		/* the bitmaps */
 
 	unsigned long base_pfn;
 	unsigned long npages;
-	struct page *cma_pages;		/* from alloc_contig_pages(), or NULL */
+	struct page *cma_pages;		/* from alloc_contig_pages() */
 
 	unsigned long *absent;		/* taken away by CTL_SET_PRESENT */
-
-	/*
-	 * A child of the root: its first page in the root, and whether it
-	 * was carved out from the root (is_child).
-	 */
-	unsigned long root_index;
-	bool is_child;
-	struct list_head root_link;	/* mps_root.children, mps_root.lock */
 };
 
-/*
- * The root region, owned by the control device.  Changes of ownership run
- * under @lock, which is taken before any child's lock.
- */
-static struct mps_root {
-	struct mutex lock;		/* everything below */
-	unsigned long base_pfn;
-	unsigned long npages;
-	struct page *cma_pages;
-	unsigned long *allocated;	/* pages allocated to a child */
-	struct list_head children;
-} mps_root;
-
-/* ---- Child file --------------------------------------------------------- */
-
 /* Byte range [offset, offset + len) of @info as page indices. */
 static int mps_range(struct mps_info *info, u64 offset, u64 len,
 		     unsigned long *start, unsigned long *end)
@@ -93,8 +68,7 @@ static long mps_get_stats(struct mps_info *info, void __user *uarg)
 	struct mps_stats st = {};
 
 	mutex_lock(&info->lock);
-	st.region_offset = (u64)info->root_index << PAGE_SHIFT;
-	st.region_len = (u64)info->npages << PAGE_SHIFT;
+	st.size = (u64)info->npages << PAGE_SHIFT;
 	st.absent_pages = bitmap_weight(info->absent, info->npages);
 	mutex_unlock(&info->lock);
 
@@ -102,9 +76,8 @@ static long mps_get_stats(struct mps_info *info, void __user *uarg)
 }
 
 /*
- * A child fd is read-only to its holder: only GET_STATS.  The owner changes a
- * child's pages through the control device (MPS_CTL_SET_PRESENT), so a VMM
- * that holds a child cannot.
+ * A provider fd is read-only to its holder: only GET_STATS. The owner changes
+ * a file's pages through the control device (MPS_CTL_SET_PRESENT).
  */
 static long mps_file_ioctl(struct file *file, unsigned int cmd,
 			   unsigned long arg)
@@ -117,18 +90,10 @@ static long mps_file_ioctl(struct file *file, unsigned int cmd,
 	return -ENOTTY;
 }
 
-/* Every consumer has detached: each one holds a reference to the file. */
 static int mps_file_release(struct inode *inode, struct file *file)
 {
 	struct mps_info *info = file->private_data;
 
-	/* A child gives the pages it has back to the root. */
-	if (info->is_child) {
-		mutex_lock(&mps_root.lock);
-		list_del(&info->root_link);
-		bitmap_clear(mps_root.allocated, info->root_index, info->npages);
-		mutex_unlock(&mps_root.lock);
-	}
 	if (info->cma_pages)
 		free_contig_range(info->base_pfn, info->npages);
 	bitmap_free(info->absent);
@@ -143,124 +108,13 @@ static const struct file_operations mps_file_fops = {
 	.compat_ioctl	= compat_ptr_ioctl,
 };
 
-/*
- * Make a provider file over [base_pfn, base_pfn + npages).  The fd is
- * reserved but not installed, so that the caller can finish setting up
- * @info before another thread can reach it.
- */
-static int mps_new_file(unsigned long base_pfn, unsigned long npages,
-			u32 flags, struct mps_info **infop,
-			 struct file **filep)
-{
-	struct mps_info *info;
-	struct file *file;
-	int fd, ret;
-
-	info = kzalloc_obj(*info);
-	if (!info)
-		return -ENOMEM;
-	info->base_pfn = base_pfn;
-	info->npages = npages;
-	info->absent = bitmap_zalloc(npages, GFP_KERNEL);
-	if (!info->absent) {
-		ret = -ENOMEM;
-		goto err_free;
-	}
-	mutex_init(&info->lock);
-	INIT_LIST_HEAD(&info->root_link);
-
-	fd = get_unused_fd_flags(O_CLOEXEC);
-	if (fd < 0) {
-		ret = fd;
-		goto err_free;
-	}
-	file = anon_inode_getfile("[mem-provider-sample]", &mps_file_fops,
-				  info, O_RDWR);
-	if (IS_ERR(file)) {
-		put_unused_fd(fd);
-		ret = PTR_ERR(file);
-		goto err_free;
-	}
-	*infop = info;
-	*filep = file;
-	return fd;
-
-err_free:
-	bitmap_free(info->absent);
-	kfree(info);
-	return ret;
-}
-
-static struct page *mps_alloc_region(unsigned long npages)
-{
-	struct page *pages;
-
-	pages = alloc_contig_pages(npages, GFP_KERNEL | __GFP_ZERO,
-				   numa_node_id(), NULL);
-	return pages;
-}
-
-/* ---- Root and children -------------------------------------------------- */
-
-/* Create the root on the first NEW_CHILD of @size. */
-static int mps_root_ensure(u64 size)
-{
-	struct page *pages;
-	unsigned long npages;
-
-	lockdep_assert_held(&mps_root.lock);
-	if (mps_root.npages)
-		return 0;
-
-	if (!size || !PAGE_ALIGNED(size))
-		return -EINVAL;
-	npages = size >> PAGE_SHIFT;
-	pages = mps_alloc_region(npages);
-	if (!pages)
-		return -ENOMEM;
-	mps_root.base_pfn = page_to_pfn(pages);
-	mps_root.allocated = bitmap_zalloc(npages, GFP_KERNEL);
-	if (!mps_root.allocated) {
-		free_contig_range(page_to_pfn(pages), npages);
-		return -ENOMEM;
-	}
-	mps_root.cma_pages = pages;
-	mps_root.npages = npages;
-	return 0;
-}
-
-static void mps_root_teardown(void)
-{
-	if (!mps_root.npages)
-		return;
-	WARN_ON(!list_empty(&mps_root.children));
-	if (mps_root.cma_pages)
-		free_contig_range(mps_root.base_pfn, mps_root.npages);
-	bitmap_free(mps_root.allocated);
-}
-
-/* A page-aligned byte range of the root as page indices [first, last). */
-static int mps_root_range(u64 offset, u64 length, unsigned long *first,
-			  unsigned long *last)
-{
-	if (!length || !PAGE_ALIGNED(offset) || !PAGE_ALIGNED(length))
-		return -EINVAL;
-	*first = offset >> PAGE_SHIFT;
-	*last = *first + (length >> PAGE_SHIFT);
-	if (*last <= *first || *last > mps_root.npages)
-		return -EINVAL;
-	return 0;
-}
-
-/* Return a referenced child file made by NEW_CHILD. */
-static struct file *mps_get_child(int fd, struct mps_info **infop)
+static struct file *mps_get_file(int fd, struct mps_info **infop)
 {
 	struct file *file = fget(fd);
 
 	if (!file)
 		return ERR_PTR(-EBADF);
-	if (file->f_op != &mps_file_fops ||
-	    !((struct mps_info *)file->private_data)->is_child) {
+	if (file->f_op != &mps_file_fops) {
 		fput(file);
 		return ERR_PTR(-EINVAL);
 	}
@@ -268,55 +122,76 @@ static struct file *mps_get_child(int fd, struct mps_info **infop)
 	return file;
 }
 
-static long mps_ctl_new_child(void __user *uarg)
+static long mps_ctl_new_file(void __user *uarg)
 {
-	struct mps_new_child nc;
-	unsigned long first, last;
+	struct mps_new_file nf;
 	struct mps_info *info;
+	struct page *pages;
 	struct file *file;
+	unsigned long npages;
 	int fd, ret;
 
-	if (copy_from_user(&nc, uarg, sizeof(nc)))
+	if (copy_from_user(&nf, uarg, sizeof(nf)))
 		return -EFAULT;
-	if (nc.flags || nc.pad)
+	if (nf.flags || nf.pad)
+		return -EINVAL;
+	if (!nf.size || !PAGE_ALIGNED(nf.size))
+		return -EINVAL;
+
+	npages = nf.size >> PAGE_SHIFT;
+	if (npages > KMALLOC_MAX_SIZE * BITS_PER_BYTE)
 		return -EINVAL;
 
-	mutex_lock(&mps_root.lock);
-	ret = mps_root_ensure(nc.offset + nc.len);
-	if (ret)
-		goto out_unlock;
-	ret = mps_root_range(nc.offset, nc.len, &first, &last);
-	if (ret)
-		goto out_unlock;
-
-	if (find_next_bit(mps_root.allocated, last, first) < last) {
-		ret = -EBUSY;
-		goto out_unlock;
+	info = kzalloc_obj(*info);
+	if (!info)
+		return -ENOMEM;
+
+	info->absent = bitmap_zalloc(npages, GFP_KERNEL);
+	if (!info->absent) {
+		ret = -ENOMEM;
+		goto err_free_info;
 	}
 
-	fd = mps_new_file(mps_root.base_pfn + first, last - first, nc.flags,
-			  &info, &file);
+	pages = alloc_contig_pages(npages, GFP_KERNEL | __GFP_ZERO,
+				   numa_node_id(), NULL);
+	if (!pages) {
+		ret = -ENOMEM;
+		goto err_free_absent;
+	}
+
+	info->cma_pages = pages;
+	info->base_pfn = page_to_pfn(pages);
+	info->npages = npages;
+	mutex_init(&info->lock);
+
+	fd = get_unused_fd_flags(O_CLOEXEC);
 	if (fd < 0) {
 		ret = fd;
-		goto out_unlock;
+		goto err_free_pages;
+	}
+
+	file = anon_inode_getfile("[mem-provider-sample]", &mps_file_fops,
+				  info, O_RDWR);
+	if (IS_ERR(file)) {
+		put_unused_fd(fd);
+		ret = PTR_ERR(file);
+		goto err_free_pages;
 	}
 
-	bitmap_set(mps_root.allocated, first, last - first);
-	info->is_child = true;
-	info->root_index = first;
-	list_add(&info->root_link, &mps_root.children);
-	mutex_unlock(&mps_root.lock);
 	fd_install(fd, file);
 	return fd;
 
-out_unlock:
-	mutex_unlock(&mps_root.lock);
+err_free_pages:
+	free_contig_range(page_to_pfn(pages), npages);
+err_free_absent:
+	bitmap_free(info->absent);
+err_free_info:
+	kfree(info);
 	return ret;
 }
 
 /*
- * CTL_SET_PRESENT changes a child's pages, by the owner on the control device.
- * A VMM that holds the child fd cannot, so it cannot undo them.
+ * CTL_SET_PRESENT changes a file's pages, by the owner on the control device.
  */
 static long mps_ctl_set_present(void __user *uarg)
 {
@@ -330,7 +205,7 @@ static long mps_ctl_set_present(void __user *uarg)
 		return -EFAULT;
 	if (cr.value > 1)
 		return -EINVAL;
-	file = mps_get_child(cr.fd, &info);
+	file = mps_get_file(cr.fd, &info);
 	if (IS_ERR(file))
 		return PTR_ERR(file);
 	ret = mps_range(info, cr.offset, cr.len, &start, &end);
@@ -346,8 +221,8 @@ static long mps_ctl_ioctl(struct file *file, unsigned int cmd,
 	void __user *uarg = (void __user *)arg;
 
 	switch (cmd) {
-	case MPS_NEW_CHILD:
-		return mps_ctl_new_child(uarg);
+	case MPS_NEW_FILE:
+		return mps_ctl_new_file(uarg);
 	case MPS_CTL_SET_PRESENT:
 		return mps_ctl_set_present(uarg);
 	default:
@@ -369,22 +244,13 @@ static struct miscdevice mps_dev = {
 
 static int __init mps_init(void)
 {
-	int ret;
-
-	mutex_init(&mps_root.lock);
-	INIT_LIST_HEAD(&mps_root.children);
-
-	ret = misc_register(&mps_dev);
-	if (ret)
-		return ret;
-	return 0;
+	return misc_register(&mps_dev);
 }
 module_init(mps_init);
 
 static void __exit mps_exit(void)
 {
 	misc_deregister(&mps_dev);
-	mps_root_teardown();
 }
 module_exit(mps_exit);
 
diff --git a/samples/kvm/mem_provider_sample.h b/samples/kvm/mem_provider_sample.h
index b520b49e56f60..c4cb10b4aadeb 100644
--- a/samples/kvm/mem_provider_sample.h
+++ b/samples/kvm/mem_provider_sample.h
@@ -8,41 +8,28 @@
 /*
  * A sample memory provider.
  *
- * Every fd that this module returns is a child file. Pass it to
+ * Every fd that this module returns is a provider file. Pass it to
  * KVM_CREATE_GUEST_MEMFD.
  */
 
 #define MPS_IOCTL_BASE		'P'
 
 /*
- * ---- A tree of owners --------------------------------------------------
- *
- * The control device owns one region, the root.  NEW_CHILD carves part of
- * it into a new provider fd for one VM.
- *
- * The owner changes a child's pages through the control device
- * (CTL_SET_PRESENT).  A child fd is read-only to its holder: a VMM can
- * only GET_STATS, never change the memory.
- */
-
-/*
- * ioctl on /dev/mem_provider_sample: carve [@offset, @offset + @len) of the
- * root into a new child fd. Returns the child fd.
+ * ioctl on /dev/mem_provider_sample: create a new provider fd of @size.
+ * Returns the provider fd.
  */
-struct mps_new_child {
+struct mps_new_file {
 	__u32 flags;	/* Reserved, must be 0 */
 	__u32 pad;
-	__u64 offset;	/* bytes into the root, page aligned */
-	__u64 len;	/* bytes, page aligned */
+	__u64 size;	/* bytes, page aligned */
 };
 
-#define MPS_NEW_CHILD \
-	_IOW(MPS_IOCTL_BASE, 5, struct mps_new_child)
+#define MPS_NEW_FILE \
+	_IOW(MPS_IOCTL_BASE, 5, struct mps_new_file)
 
-/* ioctl on a child fd: read the child's state, for tests. */
+/* ioctl on a provider fd: read the file's state, for tests. */
 struct mps_stats {
-	__u64 region_offset;	/* the child's range in the root */
-	__u64 region_len;
+	__u64 size;
 	__u64 absent_pages;	/* pages taken away by CTL_SET_PRESENT */
 };
 
@@ -50,14 +37,14 @@ struct mps_stats {
 	_IOR(MPS_IOCTL_BASE, 10, struct mps_stats)
 
 /*
- * ioctl on /dev/mem_provider_sample: CTL_SET_PRESENT on child @fd, by the
+ * ioctl on /dev/mem_provider_sample: CTL_SET_PRESENT on file @fd, by the
  * owner. @value is the present value (1 = present, 0 = absent), and @offset
- * and @len are a byte range within the child, page aligned.
+ * and @len are a byte range within the file, page aligned.
  */
 struct mps_ctl_range {
 	__s32 fd;
 	__u32 value;
-	__u64 offset;	/* bytes into the child, page aligned */
+	__u64 offset;	/* bytes into the file, page aligned */
 	__u64 len;	/* bytes, page aligned */
 };
 

-- 
2.56.0.257.gf7497c7d27-goog

