From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:27:59 -0700
Subject: [PATCH RFC v2 27/50] samples/kvm: Remove mem_provider_ops from
 sample provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-27-5dd1dc6c660a@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=8340;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=S5v5jXc6PnMRtZUZ0DKjcX62D7jtBt/5hL1gymz+OBQ=;
 b=6MeGzyOwEhN0CpX45Vc/yYXmowtUHXg5L6FY6U7eb8Xb34dSRrBcAnrw5ieYLOWztt9ggnpF5
 azh+Buf814NBfVhk0xg6LGh9LdYVZtt55/yKbXawF9c4lsIH0TneUkL
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Trim this memory provider down to just the memory provider parts first,
removing mem_provider_ops and related callbacks.

Leave the integration with guest_memfd alternative providers to future
patches.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/Kconfig                   |   4 +-
 samples/kvm/mem_provider_sample.c | 121 ++++----------------------------------
 samples/kvm/mem_provider_sample.h |   8 +--
 3 files changed, 18 insertions(+), 115 deletions(-)

diff --git a/samples/Kconfig b/samples/Kconfig
index a06eafb5d7ba4..29a0efe49ac3a 100644
--- a/samples/Kconfig
+++ b/samples/Kconfig
@@ -328,9 +328,9 @@ source "samples/damon/Kconfig"
 
 config SAMPLE_KVM_MEM_PROVIDER
 	tristate "Build sample memory provider -- loadable module only"
-	depends on MEM_PROVIDER && CONTIG_ALLOC && X86_64 && m
+	depends on CONTIG_ALLOC && X86_64 && m
 	help
-	  This builds a sample memory provider (include/linux/mem_provider.h).
+	  This builds a sample memory provider.
 	  Its files can back a guest_memfd and be mapped by iommufd.
 	  It allocates a contiguous region with alloc_contig_pages()
 	  and carves out child provider files on the fly.
diff --git a/samples/kvm/mem_provider_sample.c b/samples/kvm/mem_provider_sample.c
index 574c712a11389..294b2d65fc29d 100644
--- a/samples/kvm/mem_provider_sample.c
+++ b/samples/kvm/mem_provider_sample.c
@@ -2,13 +2,10 @@
 /*
  * mem_provider_sample - a sample memory provider.
  *
- * The module owns a region of physical memory and lends it through provider
- * files (include/linux/mem_provider.h).  A VMM passes the same file to
- * KVM_CREATE_GUEST_MEMFD, for the guest, and to IOMMU_IOAS_MAP_FILE, for the
- * guest's devices.  The module calls neither KVM nor iommufd: it answers
- * "what is page N" and revokes a range when the answer changes.
+ * The module owns a region of physical memory and lends it through child
+ * files.
  *
- * The control device /dev/mem_provider_sample creates provider files.
+ * The control device /dev/mem_provider_sample creates child files.
  * NEW_CHILD carves part of the region into a child file. A page can also
  * be taken away. See mem_provider_sample.h.
  *
@@ -21,7 +18,6 @@
 #include <linux/fs.h>
 #include <linux/gfp.h>
 #include <linux/io.h>
-#include <linux/mem_provider.h>
 #include <linux/miscdevice.h>
 #include <linux/mm.h>
 #include <linux/module.h>
@@ -31,14 +27,11 @@
 #include "mem_provider_sample.h"
 
 /*
- * One provider file.
+ * One child file.
  *
- * Lock order: mps_root.lock, then mps_info.lock, then the consumers' locks
- * (taken by their revoke callbacks).  get_page() takes no lock, so a
- * consumer can call it from its fault paths and its revoke callback.
+ * Lock order: mps_root.lock, then mps_info.lock.
  */
 struct mps_info {
-	struct mem_provider_file mpf;
 	struct mutex lock;		/* the bitmaps */
 
 	unsigned long base_pfn;
@@ -69,89 +62,7 @@ static struct mps_root {
 	struct list_head children;
 } mps_root;
 
-/* Does @info have page @index now?  Called with or without info->lock. */
-static bool mps_page_present(struct mps_info *info, unsigned long index)
-{
-	return !test_bit(index, info->absent);
-}
-
-/*
- * The length of the run from @index of pages with the same state as @index:
- * present.
- */
-static unsigned long mps_run(struct mps_info *info, unsigned long index)
-{
-	unsigned long end = info->npages;
-
-	end = min(end, find_next_bit(info->absent, info->npages, index + 1));
-	return end - index;
-}
-
-/* ---- Provider operations ------------------------------------------------ */
-
-static struct mem_provider_file *
-mps_mp_attach(struct file *file, loff_t size)
-{
-	struct mps_info *info = file->private_data;
-
-	if (size > (loff_t)info->npages << PAGE_SHIFT)
-		return ERR_PTR(-EINVAL);
-	return &info->mpf;
-}
-
-static void mps_mp_detach(struct mem_provider_file *mpf)
-{
-}
-
-/*
- * Reads the bitmaps without info->lock.  A change runs under the lock and
- * revokes the range afterwards, so an answer that a change makes out of date
- * is dropped by the consumer.
- */
-static int mps_mp_get_page(struct mem_provider_file *mpf, pgoff_t index,
-			   unsigned long *pfn, int *max_order, u32 *attrs)
-{
-	struct mps_info *info = container_of(mpf, struct mps_info, mpf);
-	unsigned long run;
-
-	if (index >= info->npages)
-		return -EINVAL;
-
-	if (!mps_page_present(info, index))
-		return -EFAULT;
-
-	/* The aligned block around @index must be one run. */
-	run = mps_run(info, index);
-	while (*max_order) {
-		unsigned long first = ALIGN_DOWN(index, 1UL << *max_order);
-
-		if (first + (1UL << *max_order) <= index + run &&
-		    (first == index || mps_page_present(info, first)) &&
-		    mps_run(info, first) >= 1UL << *max_order)
-			break;
-		(*max_order)--;
-	}
-
-	*pfn = info->base_pfn + index;
-	return 0;
-}
-
-static const struct mem_provider_ops mps_mp_ops = {
-	.attach		= mps_mp_attach,
-	.detach		= mps_mp_detach,
-	.get_page	= mps_mp_get_page,
-};
-
-/* Tell the consumers that pages [start, end) of @info changed. */
-static void mps_revoke(struct mps_info *info, unsigned long start,
-		       unsigned long end)
-{
-	if (end > start)
-		mem_provider_revoke(&info->mpf, (loff_t)start << PAGE_SHIFT,
-				    (loff_t)(end - start) << PAGE_SHIFT);
-}
-
-/* ---- Provider file ------------------------------------------------------ */
+/* ---- Child file --------------------------------------------------------- */
 
 /* Byte range [offset, offset + len) of @info as page indices. */
 static int mps_range(struct mps_info *info, u64 offset, u64 len,
@@ -174,7 +85,6 @@ static void mps_set_present(struct mps_info *info, unsigned long start,
 		bitmap_clear(info->absent, start, end - start);
 	else
 		bitmap_set(info->absent, start, end - start);
-	mps_revoke(info, start, end);
 	mutex_unlock(&info->lock);
 }
 
@@ -226,15 +136,11 @@ static int mps_file_release(struct inode *inode, struct file *file)
 	return 0;
 }
 
-static const struct mem_provider_fops mps_file_fops = {
-	.fops = {
-		.owner		= THIS_MODULE,
-		.fop_flags	= FOP_MEM_PROVIDER,
-		.release	= mps_file_release,
-		.unlocked_ioctl	= mps_file_ioctl,
-		.compat_ioctl	= compat_ptr_ioctl,
-	},
-	.ops = &mps_mp_ops,
+static const struct file_operations mps_file_fops = {
+	.owner		= THIS_MODULE,
+	.release	= mps_file_release,
+	.unlocked_ioctl	= mps_file_ioctl,
+	.compat_ioctl	= compat_ptr_ioctl,
 };
 
 /*
@@ -253,7 +159,6 @@ static int mps_new_file(unsigned long base_pfn, unsigned long npages,
 	info = kzalloc_obj(*info);
 	if (!info)
 		return -ENOMEM;
-	mem_provider_file_init(&info->mpf);
 	info->base_pfn = base_pfn;
 	info->npages = npages;
 	info->absent = bitmap_zalloc(npages, GFP_KERNEL);
@@ -269,7 +174,7 @@ static int mps_new_file(unsigned long base_pfn, unsigned long npages,
 		ret = fd;
 		goto err_free;
 	}
-	file = anon_inode_getfile("[mem-provider-sample]", &mps_file_fops.fops,
+	file = anon_inode_getfile("[mem-provider-sample]", &mps_file_fops,
 				  info, O_RDWR);
 	if (IS_ERR(file)) {
 		put_unused_fd(fd);
@@ -354,7 +259,7 @@ static struct file *mps_get_child(int fd, struct mps_info **infop)
 
 	if (!file)
 		return ERR_PTR(-EBADF);
-	if (file->f_op != &mps_file_fops.fops ||
+	if (file->f_op != &mps_file_fops ||
 	    !((struct mps_info *)file->private_data)->is_child) {
 		fput(file);
 		return ERR_PTR(-EINVAL);
diff --git a/samples/kvm/mem_provider_sample.h b/samples/kvm/mem_provider_sample.h
index 51eaf39acbad1..b520b49e56f60 100644
--- a/samples/kvm/mem_provider_sample.h
+++ b/samples/kvm/mem_provider_sample.h
@@ -6,12 +6,10 @@
 #include <linux/types.h>
 
 /*
- * A sample memory provider (include/linux/mem_provider.h).
+ * A sample memory provider.
  *
- * Every fd that this module returns is a provider file.  Pass it as
- * resource_fd to KVM_CREATE_GUEST_MEMFD with GUEST_MEMFD_FLAG_USE_RESOURCE,
- * and as fd to IOMMU_IOAS_MAP_FILE.  Both consumers follow every change that
- * the ioctls below make.
+ * Every fd that this module returns is a child file. Pass it to
+ * KVM_CREATE_GUEST_MEMFD.
  */
 
 #define MPS_IOCTL_BASE		'P'

-- 
2.56.0.257.gf7497c7d27-goog

