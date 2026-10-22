From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:27:56 -0700
Subject: [PATCH RFC v2 24/50] samples/kvm: Remove MPS_SETUP support from
 sample provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-24-5dd1dc6c660a@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=6500;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=kd/hDDXV3WNRGwpxli/N8UyduIITpgFXaaGre5ydRTg=;
 b=jWVnD6aMNALyW68Ag9Zv6gBXyLPiCk1SiGVbKrBoHWUSRZxnN+CWHddR98l5/8R+inewYyeVU
 tdNch/zzH+eD4XauEf7pBaqVQ8X8LbSWNeFYWqvoN0U1h4fg1M736Js
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MPS_SETUP is a subset of the functionality provided by MPS_NEW_CHILD.
A single file covering the entire region can be created by carving out
the full range with MPS_NEW_CHILD.

Retain MPS_NEW_CHILD as it enables testing alternative provider
functionality when there are separate sub-pools of memory carved out
from the root.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/kvm/mem_provider_sample.c | 72 ---------------------------------------
 samples/kvm/mem_provider_sample.h | 29 ++--------------
 2 files changed, 3 insertions(+), 98 deletions(-)

diff --git a/samples/kvm/mem_provider_sample.c b/samples/kvm/mem_provider_sample.c
index 4e8f306ba1154..abb8e35cd5357 100644
--- a/samples/kvm/mem_provider_sample.c
+++ b/samples/kvm/mem_provider_sample.c
@@ -61,7 +61,6 @@ struct mps_info {
 	unsigned long base_pfn;
 	unsigned long npages;
 	struct page *cma_pages;		/* from alloc_contig_pages(), or NULL */
-	bool fixed;			/* a SETUP file over addr=/len= */
 	bool mmap_capable;
 	bool fixed_wb;			/* holds a ref on the fixed-region WB alias */
 
@@ -87,11 +86,6 @@ static struct mps_root {
 	struct page *cma_pages;
 	unsigned long *allocated;	/* pages allocated to a child */
 	struct list_head children;
-	/*
-	 * The addr=/len= region is used either by one SETUP file or by the
-	 * root, never by both, so that its frames have one owner.
-	 */
-	bool fixed_setup;
 	/* Files over the fixed region that may be mapped into userspace. */
 	unsigned int fixed_wb_users;
 } mps_root;
@@ -289,8 +283,6 @@ static int mps_file_release(struct inode *inode, struct file *file)
 	}
 	if (addr && len && !info->cma_pages) {
 		mutex_lock(&mps_root.lock);
-		if (info->fixed)
-			mps_root.fixed_setup = false;
 		if (info->fixed_wb)
 			mps_fixed_wb_put();
 		mutex_unlock(&mps_root.lock);
@@ -373,66 +365,6 @@ static struct page *mps_alloc_region(unsigned long npages)
 	return pages;
 }
 
-static long mps_ctl_setup(void __user *uarg)
-{
-	struct mps_setup setup;
-	unsigned long base_pfn, npages;
-	struct page *pages = NULL;
-	struct mps_info *info;
-	struct file *file;
-	int fd;
-
-	if (copy_from_user(&setup, uarg, sizeof(setup)))
-		return -EFAULT;
-	if ((setup.flags & ~MPS_FLAG_MMAP_CAPABLE) || setup.pad)
-		return -EINVAL;
-
-	if (addr && len) {
-		/* The fixed region has one owner: this file or the root. */
-		mutex_lock(&mps_root.lock);
-		if (mps_root.fixed_setup || mps_root.npages) {
-			mutex_unlock(&mps_root.lock);
-			return -EBUSY;
-		}
-		fd = mps_new_file(addr >> PAGE_SHIFT, len >> PAGE_SHIFT,
-				  setup.flags, &info, &file);
-		if (fd >= 0 && mps_over_fixed_mappable(info)) {
-			if (mps_fixed_wb_get()) {
-				put_unused_fd(fd);
-				fput(file);
-				fd = -ENOMEM;
-			} else {
-				info->fixed_wb = true;
-			}
-		}
-		if (fd >= 0) {
-			info->fixed = true;
-			mps_root.fixed_setup = true;
-		}
-		mutex_unlock(&mps_root.lock);
-		if (fd >= 0)
-			fd_install(fd, file);
-		return fd;
-	}
-
-	if (!setup.size || !PAGE_ALIGNED(setup.size))
-		return -EINVAL;
-	npages = setup.size >> PAGE_SHIFT;
-	pages = mps_alloc_region(npages);
-	if (!pages)
-		return -ENOMEM;
-	base_pfn = page_to_pfn(pages);
-
-	fd = mps_new_file(base_pfn, npages, setup.flags, &info, &file);
-	if (fd < 0) {
-		free_contig_range(base_pfn, npages);
-		return fd;
-	}
-	info->cma_pages = pages;
-	fd_install(fd, file);
-	return fd;
-}
-
 /* ---- Root and children -------------------------------------------------- */
 
 /* Create the root on the first NEW_CHILD, from addr=/len= or of @size. */
@@ -446,8 +378,6 @@ static int mps_root_ensure(u64 size)
 		return 0;
 
 	if (addr && len) {
-		if (mps_root.fixed_setup)
-			return -EBUSY;
 		mps_root.base_pfn = addr >> PAGE_SHIFT;
 		npages = len >> PAGE_SHIFT;
 	} else {
@@ -596,8 +526,6 @@ static long mps_ctl_ioctl(struct file *file, unsigned int cmd,
 	void __user *uarg = (void __user *)arg;
 
 	switch (cmd) {
-	case MPS_SETUP:
-		return mps_ctl_setup(uarg);
 	case MPS_NEW_CHILD:
 		return mps_ctl_new_child(uarg);
 	case MPS_CTL_SET_PRESENT:
diff --git a/samples/kvm/mem_provider_sample.h b/samples/kvm/mem_provider_sample.h
index 1afea136328f5..3b0928b6478ca 100644
--- a/samples/kvm/mem_provider_sample.h
+++ b/samples/kvm/mem_provider_sample.h
@@ -14,38 +14,17 @@
  * the ioctls below make.
  */
 
-/* Flags for struct mps_setup and struct mps_new_child */
+/* Flags for struct mps_new_child */
 /* The host may map the pages; otherwise they are NO_USER_MAP */
 #define MPS_FLAG_MMAP_CAPABLE	(1u << 0)
 
-/*
- * ioctl on /dev/mem_provider_sample: create a provider fd.
- *
- * If the module was loaded with addr= and len=, the fd covers that fixed
- * range, which has no struct page, and @size is ignored.  The fixed range
- * then has one owner.  SETUP fails with -EBUSY while a SETUP file uses it,
- * or once the first MPS_NEW_CHILD has made it the root of the children, which
- * lasts until the module is unloaded.  MPS_NEW_CHILD fails with -EBUSY while
- * a SETUP file uses it.  Otherwise the fd covers @size bytes from
- * alloc_contig_pages().
- */
-struct mps_setup {
-	__u32 flags;	/* MPS_FLAG_* */
-	__u32 pad;
-	__u64 size;	/* bytes, page aligned */
-};
-
 #define MPS_IOCTL_BASE		'P'
-#define MPS_SETUP \
-	_IOW(MPS_IOCTL_BASE, 1, struct mps_setup)
 
 /*
  * ---- A tree of owners --------------------------------------------------
  *
  * The control device owns one region, the root.  NEW_CHILD carves part of
- * it into a new provider fd for one VM.  The owner can MOVE pages between
- * children, DONATE pages to the root, so that no child has them, and
- * RECLAIM them.  Each change revokes the range, so KVM and iommufd follow.
+ * it into a new provider fd for one VM.
  *
  * The owner changes a child's pages through the control device
  * (CTL_SET_PRESENT).  A child fd is read-only to its holder: a VMM can
@@ -54,9 +33,7 @@ struct mps_setup {
 
 /*
  * ioctl on /dev/mem_provider_sample: carve [@offset, @offset + @len) of the
- * root into a new child fd.  The child gets every page of the range that no
- * other child has and that is not donated.  Ranges of children may overlap,
- * which is how a page can MOVE between them.  Returns the child fd.
+ * root into a new child fd. Returns the child fd.
  */
 struct mps_new_child {
 	__u32 flags;	/* MPS_FLAG_* */

-- 
2.56.0.257.gf7497c7d27-goog

