From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:27:57 -0700
Subject: [PATCH RFC v2 25/50] samples/kvm: Remove MMAP_CAPABLE flag from
 sample provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-25-5dd1dc6c660a@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=5272;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=NyLuSglYrgseNgo22Leven/EVJ6xVizHVjRReJCGP3c=;
 b=oOyJLSyR86edjat5g+/tkS/BgrVfnXSZMxDSUij8i8EsT8NCw5Hlv/4VKfZZ36+fvuL82lKzW
 YHjlPObEObuCk6Lf69FV0eMFWTxmVS2+taE4yXO2/NipSMiv4SSI0tI
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the MMAP_CAPABLE flag and associated write-back PAT mapping logic
from the sample memory provider.

This is removed to focus on the core concept of providing memory.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/kvm/mem_provider_sample.c | 66 +--------------------------------------
 samples/kvm/mem_provider_sample.h |  6 +---
 2 files changed, 2 insertions(+), 70 deletions(-)

diff --git a/samples/kvm/mem_provider_sample.c b/samples/kvm/mem_provider_sample.c
index abb8e35cd5357..f7ecb2ea1d75d 100644
--- a/samples/kvm/mem_provider_sample.c
+++ b/samples/kvm/mem_provider_sample.c
@@ -61,8 +61,6 @@ struct mps_info {
 	unsigned long base_pfn;
 	unsigned long npages;
 	struct page *cma_pages;		/* from alloc_contig_pages(), or NULL */
-	bool mmap_capable;
-	bool fixed_wb;			/* holds a ref on the fixed-region WB alias */
 
 	unsigned long *absent;		/* taken away by CTL_SET_PRESENT */
 
@@ -86,48 +84,8 @@ static struct mps_root {
 	struct page *cma_pages;
 	unsigned long *allocated;	/* pages allocated to a child */
 	struct list_head children;
-	/* Files over the fixed region that may be mapped into userspace. */
-	unsigned int fixed_wb_users;
 } mps_root;
 
-/*
- * A write-back mapping of the addr=/len= region, held while any file over it
- * may be mapped into userspace (counted by mps_root.fixed_wb_users).  Without
- * it, PAT makes the range uncached on x86, and the VMM's mapping would be
- * uncached while the guest's is write-back.  PAT may still give a weaker type
- * if the MTRRs do not mark the range write-back.
- */
-static void *mps_fixed_wb;
-
-/* A file over the fixed region whose pages the host may map. */
-static bool mps_over_fixed_mappable(struct mps_info *info)
-{
-	return addr && len && !info->cma_pages && info->mmap_capable;
-}
-
-/*
- * Hold a write-back mapping of the fixed region while any file over it may be
- * mapped into userspace.  Called under mps_root.lock.
- */
-static int mps_fixed_wb_get(void)
-{
-	if (mps_root.fixed_wb_users == 0) {
-		mps_fixed_wb = memremap(addr, len, MEMREMAP_WB);
-		if (!mps_fixed_wb)
-			return -ENOMEM;
-	}
-	mps_root.fixed_wb_users++;
-	return 0;
-}
-
-static void mps_fixed_wb_put(void)
-{
-	if (--mps_root.fixed_wb_users == 0) {
-		memunmap(mps_fixed_wb);
-		mps_fixed_wb = NULL;
-	}
-}
-
 /* Does @info have page @index now?  Called with or without info->lock. */
 static bool mps_page_present(struct mps_info *info, unsigned long index)
 {
@@ -192,9 +150,6 @@ static int mps_mp_get_page(struct mem_provider_file *mpf, pgoff_t index,
 	}
 
 	*pfn = info->base_pfn + index;
-	/* The creator of the file decides whether the host may map it. */
-	if (!info->mmap_capable)
-		*attrs |= MEM_PROVIDER_ATTR_NO_USER_MAP;
 	return 0;
 }
 
@@ -281,13 +236,6 @@ static int mps_file_release(struct inode *inode, struct file *file)
 		bitmap_clear(mps_root.allocated, info->root_index, info->npages);
 		mutex_unlock(&mps_root.lock);
 	}
-	if (addr && len && !info->cma_pages) {
-		mutex_lock(&mps_root.lock);
-		if (info->fixed_wb)
-			mps_fixed_wb_put();
-		mutex_unlock(&mps_root.lock);
-	}
-
 	if (info->cma_pages)
 		free_contig_range(info->base_pfn, info->npages);
 	bitmap_free(info->absent);
@@ -325,7 +273,6 @@ static int mps_new_file(unsigned long base_pfn, unsigned long npages,
 	mem_provider_file_init(&info->mpf);
 	info->base_pfn = base_pfn;
 	info->npages = npages;
-	info->mmap_capable = flags & MPS_FLAG_MMAP_CAPABLE;
 	info->absent = bitmap_zalloc(npages, GFP_KERNEL);
 	if (!info->absent) {
 		ret = -ENOMEM;
@@ -449,7 +396,7 @@ static long mps_ctl_new_child(void __user *uarg)
 
 	if (copy_from_user(&nc, uarg, sizeof(nc)))
 		return -EFAULT;
-	if ((nc.flags & ~MPS_FLAG_MMAP_CAPABLE) || nc.pad)
+	if (nc.flags || nc.pad)
 		return -EINVAL;
 
 	mutex_lock(&mps_root.lock);
@@ -471,15 +418,6 @@ static long mps_ctl_new_child(void __user *uarg)
 		ret = fd;
 		goto out_unlock;
 	}
-	if (mps_over_fixed_mappable(info)) {
-		if (mps_fixed_wb_get()) {
-			put_unused_fd(fd);
-			fput(file);
-			ret = -ENOMEM;
-			goto out_unlock;
-		}
-		info->fixed_wb = true;
-	}
 
 	bitmap_set(mps_root.allocated, first, last - first);
 	info->is_child = true;
@@ -571,8 +509,6 @@ static void __exit mps_exit(void)
 {
 	misc_deregister(&mps_dev);
 	mps_root_teardown();
-	if (mps_fixed_wb)
-		memunmap(mps_fixed_wb);
 }
 module_exit(mps_exit);
 
diff --git a/samples/kvm/mem_provider_sample.h b/samples/kvm/mem_provider_sample.h
index 3b0928b6478ca..51eaf39acbad1 100644
--- a/samples/kvm/mem_provider_sample.h
+++ b/samples/kvm/mem_provider_sample.h
@@ -14,10 +14,6 @@
  * the ioctls below make.
  */
 
-/* Flags for struct mps_new_child */
-/* The host may map the pages; otherwise they are NO_USER_MAP */
-#define MPS_FLAG_MMAP_CAPABLE	(1u << 0)
-
 #define MPS_IOCTL_BASE		'P'
 
 /*
@@ -36,7 +32,7 @@
  * root into a new child fd. Returns the child fd.
  */
 struct mps_new_child {
-	__u32 flags;	/* MPS_FLAG_* */
+	__u32 flags;	/* Reserved, must be 0 */
 	__u32 pad;
 	__u64 offset;	/* bytes into the root, page aligned */
 	__u64 len;	/* bytes, page aligned */

-- 
2.56.0.257.gf7497c7d27-goog

