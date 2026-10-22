From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:27:58 -0700
Subject: [PATCH RFC v2 26/50] samples/kvm: Remove fixed address and length
 module parameters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-26-5dd1dc6c660a@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=4776;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=ZvgRlCQoX8aAOrmBNmY778ViCyt2HTQ8fDZpwcewiX8=;
 b=hMQxwei6fo+VWEPARf94RDMkjPiXa+ZvJwZ4AhdrwKCCaWXn8vnLqltUKdpAyZOGn4NdnyfGr
 LnjlZ8YhxflCPm+xo9J+Bmw3RSJruFNHUioJ+FO3GfZblRoOKJxiBWk
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the addr and len module parameters from the sample memory
provider.

The prototype doesn't require pre-carved out memory ranges, since
MPS_NEW_CHILD already allows carving out memory on the fly. Being able to
carve out memory on the fly makes testing easier.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/Kconfig                   | 12 +++------
 samples/kvm/mem_provider_sample.c | 53 +++++++++------------------------------
 2 files changed, 15 insertions(+), 50 deletions(-)

diff --git a/samples/Kconfig b/samples/Kconfig
index 3c870bca076af..a06eafb5d7ba4 100644
--- a/samples/Kconfig
+++ b/samples/Kconfig
@@ -331,15 +331,9 @@ config SAMPLE_KVM_MEM_PROVIDER
 	depends on MEM_PROVIDER && CONTIG_ALLOC && X86_64 && m
 	help
 	  This builds a sample memory provider (include/linux/mem_provider.h).
-	  Its files can back a guest_memfd and be mapped by iommufd.  Loaded
-	  with addr= and len=, it lends a fixed physical range that has no
-	  struct page, for example memory hidden with memmap= on the command
-	  line.  Without them, it allocates a contiguous region with
-	  alloc_contig_pages().
-
-	  It shows how a memory owner moves pages between VMs, takes them
-	  back or makes them read only, and how guest_memfd and iommufd
-	  follow each change.
+	  Its files can back a guest_memfd and be mapped by iommufd.
+	  It allocates a contiguous region with alloc_contig_pages()
+	  and carves out child provider files on the fly.
 
 	  If unsure, say N.
 
diff --git a/samples/kvm/mem_provider_sample.c b/samples/kvm/mem_provider_sample.c
index f7ecb2ea1d75d..574c712a11389 100644
--- a/samples/kvm/mem_provider_sample.c
+++ b/samples/kvm/mem_provider_sample.c
@@ -8,17 +8,9 @@
  * guest's devices.  The module calls neither KVM nor iommufd: it answers
  * "what is page N" and revokes a range when the answer changes.
  *
- * The region is either:
- *
- *  - a fixed range given with addr= and len=, which has no struct page, for
- *    example memory hidden from the kernel with memmap= on the command line;
- *  - or, without those parameters, a range from alloc_contig_pages().
- *
  * The control device /dev/mem_provider_sample creates provider files.
- * SETUP makes one file over the whole region.  NEW_CHILD carves part of the
- * region into a child file, and MOVE, DONATE and RECLAIM change which child
- * has which page.  A page can also be taken away or made read only.  See
- * mem_provider_sample.h.
+ * NEW_CHILD carves part of the region into a child file. A page can also
+ * be taken away. See mem_provider_sample.h.
  *
  * Confidential VMs are not supported.
  */
@@ -38,15 +30,6 @@
 
 #include "mem_provider_sample.h"
 
-static unsigned long long addr;
-module_param(addr, ullong, 0444);
-MODULE_PARM_DESC(addr,
-		 "Physical base of a region with no struct page (optional)");
-
-static unsigned long long len;
-module_param(len, ullong, 0444);
-MODULE_PARM_DESC(len, "Size in bytes of that region (optional)");
-
 /*
  * One provider file.
  *
@@ -314,32 +297,26 @@ static struct page *mps_alloc_region(unsigned long npages)
 
 /* ---- Root and children -------------------------------------------------- */
 
-/* Create the root on the first NEW_CHILD, from addr=/len= or of @size. */
+/* Create the root on the first NEW_CHILD of @size. */
 static int mps_root_ensure(u64 size)
 {
-	struct page *pages = NULL;
+	struct page *pages;
 	unsigned long npages;
 
 	lockdep_assert_held(&mps_root.lock);
 	if (mps_root.npages)
 		return 0;
 
-	if (addr && len) {
-		mps_root.base_pfn = addr >> PAGE_SHIFT;
-		npages = len >> PAGE_SHIFT;
-	} else {
-		if (!size || !PAGE_ALIGNED(size))
-			return -EINVAL;
-		npages = size >> PAGE_SHIFT;
-		pages = mps_alloc_region(npages);
-		if (!pages)
-			return -ENOMEM;
-		mps_root.base_pfn = page_to_pfn(pages);
-	}
+	if (!size || !PAGE_ALIGNED(size))
+		return -EINVAL;
+	npages = size >> PAGE_SHIFT;
+	pages = mps_alloc_region(npages);
+	if (!pages)
+		return -ENOMEM;
+	mps_root.base_pfn = page_to_pfn(pages);
 	mps_root.allocated = bitmap_zalloc(npages, GFP_KERNEL);
 	if (!mps_root.allocated) {
-		if (pages)
-			free_contig_range(page_to_pfn(pages), npages);
+		free_contig_range(page_to_pfn(pages), npages);
 		return -ENOMEM;
 	}
 	mps_root.cma_pages = pages;
@@ -489,12 +466,6 @@ static int __init mps_init(void)
 {
 	int ret;
 
-	if ((addr || len) &&
-	    (!addr || !len || !PAGE_ALIGNED(addr) || !PAGE_ALIGNED(len))) {
-		pr_err("mem_provider_sample: addr= and len= must both be set and page aligned\n");
-		return -EINVAL;
-	}
-
 	mutex_init(&mps_root.lock);
 	INIT_LIST_HEAD(&mps_root.children);
 

-- 
2.56.0.257.gf7497c7d27-goog

