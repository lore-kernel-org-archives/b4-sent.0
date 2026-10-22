From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:28:20 -0700
Subject: [PATCH RFC v2 48/50] samples/kvm: Support dynamic revocation via
 kvm_gmem_revoke
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-48-5dd1dc6c660a@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=5235;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=osG+hTJkYFtiaTaA4QiAK1hu1UKqffxl7X7AaR/yTpk=;
 b=5mulF18xLe3alMuXjuYUoO2Dhxkx/Mzu3GEllOvbqE9jcwoVUn/Av90F9pyXp//3tVQ3oQysW
 Ncd5XybpfQfDgc3OQPRGAC/8Z879TUN3cCr/VVT0cyw05F9ete937EE
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support dynamic revocation in the sample memory provider module by
calling kvm_gmem_revoke() when pages are marked absent via
MPS_SET_PRESENT.

Note down the attaching gmem inode during .attach() and disallow double
attachment to the same provider file.

Clear the revoked pages after kvm_gmem_revoke() using mps_zero_range()
to ensure that stale data is wiped and cannot be observed when pages are
later marked present or reused.

Regarding locking and ordering:
- In mps_set_present(), mark the absent bitmap first before revoking so
  any concurrent page fault immediately sees the page as absent and
  rejects the lookup with -EFAULT.
- kvm_gmem_revoke() is called under info->lock to fully serialize
  MPS_SET_PRESENT operations against each other and prevent races
  between marking pages absent and present.
- The PFN passed to kvm_gmem_revoke() is derived from info->base_pfn +
  start. The mapping between page index and physical PFN is static and
  immutable for the lifetime of the provider file, ensuring that the
  pfn mapping remains completely stable across the revoke call.
- Passing pfn directly to kvm_gmem_revoke() allows guest_memfd to
  reclaim the physical range directly without calling back into the
  provider. This keeps the lock hierarchy strictly top-down (info->lock
  -> filemap_invalidate_lock -> mmu_lock) with no callbacks or deadlocks.

For now, nothing needs to be done when setting a page present, since users
should (re-)fault and (re-)obtain the PFN via .get_pfn(), to be added in a
later patch.

For users that don't support faulting, like the IOMMU, the counterpart to
kvm_gmem_revoke() will be made available for the first user to indicate
that the memory is now available. guest_memfd should then do the page table
mappings as necessary, based on the shared/private status.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/Kconfig                   |  2 +-
 samples/kvm/mem_provider_sample.c | 42 +++++++++++++++++++++++++++++++++------
 2 files changed, 37 insertions(+), 7 deletions(-)

diff --git a/samples/Kconfig b/samples/Kconfig
index 29a0efe49ac3a..1b227eec8bb6d 100644
--- a/samples/Kconfig
+++ b/samples/Kconfig
@@ -328,7 +328,7 @@ source "samples/damon/Kconfig"
 
 config SAMPLE_KVM_MEM_PROVIDER
 	tristate "Build sample memory provider -- loadable module only"
-	depends on CONTIG_ALLOC && X86_64 && m
+	depends on CONTIG_ALLOC && X86_64 && m && KVM_GUEST_MEMFD
 	help
 	  This builds a sample memory provider.
 	  Its files can back a guest_memfd and be mapped by iommufd.
diff --git a/samples/kvm/mem_provider_sample.c b/samples/kvm/mem_provider_sample.c
index dee15179959b2..3fa0d1a4335b5 100644
--- a/samples/kvm/mem_provider_sample.c
+++ b/samples/kvm/mem_provider_sample.c
@@ -39,13 +39,13 @@ struct mps_info {
 	struct page *cma_pages;		/* from alloc_contig_pages() */
 
 	unsigned long *absent;		/* taken away by MPS_SET_PRESENT */
+
+	struct inode *gmem_inode;
 };
 
-static void mps_gmem_put_pfn_range(void *provider, pgoff_t index,
-				   size_t nr_pages)
+static void mps_zero_range(struct mps_info *info, pgoff_t index,
+			    size_t nr_pages)
 {
-	struct file *resource_file = provider;
-	struct mps_info *info = resource_file->private_data;
 	size_t i;
 
 	if (index >= info->npages)
@@ -56,6 +56,14 @@ static void mps_gmem_put_pfn_range(void *provider, pgoff_t index,
 		clear_highpage(info->cma_pages + index + i);
 }
 
+static void mps_gmem_put_pfn_range(void *provider, pgoff_t index,
+				   size_t nr_pages)
+{
+	struct file *resource_file = provider;
+
+	mps_zero_range(resource_file->private_data, index, nr_pages);
+}
+
 /* Byte range [offset, offset + len) of @info as page indices. */
 static int mps_range(struct mps_info *info, u64 offset, u64 len,
 		     unsigned long *start, unsigned long *end)
@@ -73,10 +81,17 @@ static void mps_set_present(struct mps_info *info, unsigned long start,
 			    unsigned long end, bool present)
 {
 	mutex_lock(&info->lock);
-	if (present)
+	if (present) {
 		bitmap_clear(info->absent, start, end - start);
-	else
+	} else {
 		bitmap_set(info->absent, start, end - start);
+		if (info->gmem_inode) {
+			unsigned long pfn = info->base_pfn + start;
+
+			kvm_gmem_revoke(info->gmem_inode, start, end - start, &pfn);
+			mps_zero_range(info, start, end - start);
+		}
+	}
 	mutex_unlock(&info->lock);
 }
 
@@ -138,12 +153,27 @@ static long mps_file_ioctl(struct file *file, unsigned int cmd,
 static void *mps_gmem_attach(struct inode *gmem_inode,
 			     struct file *resource_file)
 {
+	struct mps_info *info = resource_file->private_data;
+
+	mutex_lock(&info->lock);
+	if (info->gmem_inode) {
+		mutex_unlock(&info->lock);
+		return ERR_PTR(-EBUSY);
+	}
+	info->gmem_inode = gmem_inode;
+	mutex_unlock(&info->lock);
+
 	return get_file(resource_file);
 }
 
 static void mps_gmem_release(void *provider)
 {
 	struct file *resource_file = provider;
+	struct mps_info *info = resource_file->private_data;
+
+	mutex_lock(&info->lock);
+	info->gmem_inode = NULL;
+	mutex_unlock(&info->lock);
 
 	fput(resource_file);
 }

-- 
2.56.0.257.gf7497c7d27-goog

