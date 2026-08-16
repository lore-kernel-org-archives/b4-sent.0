From: Marina <dejamarina@proton.me>
Date: Sun, 16 Aug 2026 00:07:52 -0700
Subject: [PATCH] io_uring: keep memlock accounting while regions are mapped
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260816-io-uring-retained-mmap-accounting-v1-1-44e5eedd7ad3@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2NQQqDQAwAvyI5G3DV1tKviIe4G20OZiWrpSD+3
 bXHYWDmgMQmnOBdHGD8lSRRM7iyAP8hnRklZIa6qp/Vyz1QIu4mOqPxRqIccFloRfI+7rrdYpx
 G34XOubYhyJ3VeJLf/9EP53kBH1oyBXMAAAA=
X-Change-ID: 20260815-io-uring-retained-mmap-accounting-bfbc7d71143a
To: Jens Axboe <axboe@kernel.dk>
Cc: io-uring@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786864329; l=6570;
 i=dejamarina@proton.me; s=20260815; h=from:subject:message-id;
 bh=qLxBrYf50g+OuYx8yDSRrA0uFWQ9y5dYnjPSpqE9LhI=;
 b=2blRtHRgT88h3GXM3GwULtN5byYgsdYom2/LO8aAj5mV0dB1zwiWmIDofva2TfeJ13MY7qGi+
 If0tmApTLVGDhnPxvM4KJW5mU1OzaYhHmV6Wl33cp/t5ZA3ubuCrS5k
X-Developer-Key: i=dejamarina@proton.me; a=ed25519;
 pk=o6FEADjBmL41WCfiAGLN0AkjAW72humn8TYGV/+V8cw=
X-Endpoint-Received: by B4 Relay for dejamarina@proton.me/20260815 with auth_id=953
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

io_uring unaccounts kernel-allocated SQ/CQ and SQE regions when resize
replaces them, even if existing VMAs still retain their pages. Repeating
mmap and resize can therefore retain memory beyond RLIMIT_MEMLOCK.

Move each charge to a refcounted record owned by the active region and its
MMU or NOMMU mappings. Release it after both the region and final VMA are
gone. Keep direct accounting for user-provided regions, which cannot be
mapped through the io_uring file.

Accounting stays region-granular, so a partial mapping retains the complete
region charge.

Fixes: 79cfe9e59c2a ("io_uring/register: add IORING_REGISTER_RESIZE_RINGS")
Signed-off-by: Marina <dejamarina@proton.me>
---
 include/linux/io_uring_types.h |   3 ++
 io_uring/memmap.c              | 108 ++++++++++++++++++++++++++++++++++++++---
 2 files changed, 105 insertions(+), 6 deletions(-)

diff --git a/include/linux/io_uring_types.h b/include/linux/io_uring_types.h
index 87151a5b62c1..6feb7ee3440f 100644
--- a/include/linux/io_uring_types.h
+++ b/include/linux/io_uring_types.h
@@ -94,11 +94,14 @@ struct io_hash_table {
 	unsigned		hash_bits;
 };
 
+struct io_region_account;
+
 struct io_mapped_region {
 	struct page		**pages;
 	void			*ptr;
 	unsigned		nr_pages;
 	unsigned		flags;
+	struct io_region_account	*account;
 };
 
 /*
diff --git a/io_uring/memmap.c b/io_uring/memmap.c
index 23e8a85111bc..ca28a9429c16 100644
--- a/io_uring/memmap.c
+++ b/io_uring/memmap.c
@@ -4,6 +4,8 @@
 #include <linux/errno.h>
 #include <linux/mm.h>
 #include <linux/mman.h>
+#include <linux/refcount.h>
+#include <linux/sched/user.h>
 #include <linux/slab.h>
 #include <linux/vmalloc.h>
 #include <linux/io_uring.h>
@@ -88,6 +90,52 @@ enum {
 	IO_REGION_F_SINGLE_REF			= 4,
 };
 
+struct io_region_account {
+	refcount_t refs;
+	struct user_struct *user;
+	unsigned long nr_pages;
+};
+
+static struct io_region_account *
+io_region_account_alloc(struct user_struct *user, unsigned long nr_pages)
+{
+	struct io_region_account *account;
+	int ret;
+
+	if (!user)
+		return NULL;
+
+	account = kmalloc_obj(*account, GFP_KERNEL_ACCOUNT);
+	if (!account)
+		return ERR_PTR(-ENOMEM);
+
+	ret = __io_account_mem(user, nr_pages);
+	if (ret) {
+		kfree(account);
+		return ERR_PTR(ret);
+	}
+
+	refcount_set(&account->refs, 1);
+	account->user = get_uid(user);
+	account->nr_pages = nr_pages;
+	return account;
+}
+
+static void io_region_account_get(struct io_region_account *account)
+{
+	if (account)
+		refcount_inc(&account->refs);
+}
+
+static void io_region_account_put(struct io_region_account *account)
+{
+	if (account && refcount_dec_and_test(&account->refs)) {
+		__io_unaccount_mem(account->user, account->nr_pages);
+		free_uid(account->user);
+		kfree(account);
+	}
+}
+
 void io_free_region(struct user_struct *user, struct io_mapped_region *mr)
 {
 	if (mr->pages) {
@@ -105,8 +153,12 @@ void io_free_region(struct user_struct *user, struct io_mapped_region *mr)
 	}
 	if ((mr->flags & IO_REGION_F_VMAP) && mr->ptr)
 		vunmap(mr->ptr);
-	if (mr->nr_pages && user)
+	if (mr->account) {
+		WARN_ON_ONCE(mr->account->user != user);
+		io_region_account_put(mr->account);
+	} else if (mr->nr_pages && user) {
 		__io_unaccount_mem(user, mr->nr_pages);
+	}
 
 	memset(mr, 0, sizeof(*mr));
 }
@@ -188,7 +240,8 @@ int io_create_region(struct io_ring_ctx *ctx, struct io_mapped_region *mr,
 	int nr_pages, ret;
 	u64 end;
 
-	if (WARN_ON_ONCE(mr->pages || mr->ptr || mr->nr_pages))
+	if (WARN_ON_ONCE(mr->pages || mr->ptr || mr->nr_pages ||
+			 mr->account))
 		return -EFAULT;
 	if (memchr_inv(&reg->__resv, 0, sizeof(reg->__resv)))
 		return -EINVAL;
@@ -207,10 +260,23 @@ int io_create_region(struct io_ring_ctx *ctx, struct io_mapped_region *mr,
 		return -EOVERFLOW;
 
 	nr_pages = reg->size >> PAGE_SHIFT;
-	if (ctx->user) {
-		ret = __io_account_mem(ctx->user, nr_pages);
-		if (ret)
+	if (reg->flags & IORING_MEM_REGION_TYPE_USER) {
+		if (ctx->user) {
+			ret = __io_account_mem(ctx->user, nr_pages);
+			if (ret)
+				return ret;
+		}
+	} else {
+		/*
+		 * Kernel-allocated pages can outlive their active region through
+		 * userspace mappings.
+		 */
+		mr->account = io_region_account_alloc(ctx->user, nr_pages);
+		if (IS_ERR(mr->account)) {
+			ret = PTR_ERR(mr->account);
+			mr->account = NULL;
 			return ret;
+		}
 	}
 	mr->nr_pages = nr_pages;
 
@@ -281,15 +347,41 @@ static void *io_uring_validate_mmap_request(struct file *file, loff_t pgoff)
 
 #ifdef CONFIG_MMU
 
+static void io_region_vm_open(struct vm_area_struct *vma)
+{
+	io_region_account_get(vma->vm_private_data);
+}
+
+static void io_region_vm_close(struct vm_area_struct *vma)
+{
+	io_region_account_put(vma->vm_private_data);
+}
+
+static const struct vm_operations_struct io_region_vm_ops = {
+	.open = io_region_vm_open,
+	.close = io_region_vm_close,
+};
+
 static int io_region_mmap(struct io_ring_ctx *ctx,
 			  struct io_mapped_region *mr,
 			  struct vm_area_struct *vma,
 			  unsigned max_pages)
 {
 	unsigned long nr_pages = min(mr->nr_pages, max_pages);
+	int ret;
 
 	vm_flags_set(vma, VM_DONTEXPAND);
-	return vm_insert_pages(vma, vma->vm_start, mr->pages, &nr_pages);
+	ret = vm_insert_pages(vma, vma->vm_start, mr->pages, &nr_pages);
+	if (!ret && mr->account) {
+		/*
+		 * Accounting deliberately remains at region granularity when
+		 * this VMA maps only part of the region.
+		 */
+		vma->vm_private_data = mr->account;
+		vma->vm_ops = &io_region_vm_ops;
+		vma->vm_ops->open(vma);
+	}
+	return ret;
 }
 
 __cold int io_uring_mmap(struct file *file, struct vm_area_struct *vma)
@@ -379,6 +471,8 @@ static void io_uring_nommu_vm_close(struct vm_area_struct *vma)
 
 	for (index = vma->vm_start; index < vma->vm_end; index += PAGE_SIZE)
 		put_page(virt_to_page((void *) index));
+
+	io_region_account_put(vma->vm_private_data);
 }
 
 static const struct vm_operations_struct io_uring_nommu_vm_ops = {
@@ -411,6 +505,8 @@ int io_uring_mmap(struct file *file, struct vm_area_struct *vma)
 	for (i = 0; i < region->nr_pages; i++)
 		get_page(region->pages[i]);
 
+	vma->vm_private_data = region->account;
+	io_region_account_get(region->account);
 	vma->vm_ops = &io_uring_nommu_vm_ops;
 	return 0;
 }

---
base-commit: a5161661ae99f497affa83a5b8654e457cda6267
change-id: 20260815-io-uring-retained-mmap-accounting-bfbc7d71143a

Best regards,
-- 
Marina <dejamarina@proton.me>

