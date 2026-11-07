From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:22 -0800
Subject: [PATCH RFC v3 48/88] samples/kvm: Support dynamic revocation via
 kvm_gmem_revoke
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-48-8484dde66a7e@google.com>
References: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
In-Reply-To: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
To: Alexey Kardashevskiy <aik@amd.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Christian Brauner <brauner@kernel.org>, 
 David Hildenbrand <david@kernel.org>, David Woodhouse <dwmw2@infradead.org>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, Jianxiong Gao <jxgao@google.com>, 
 John Starks <John.Starks@microsoft.com>, 
 Michael Roth <michael.roth@amd.com>, Paolo Bonzini <pbonzini@redhat.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Vishal Annapurve <vannapurve@google.com>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=4516;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=GWH3fZv1Ui/TswUwJ0eqio5HJ+BvFDkQT9zu7ehqt4I=;
 b=AzFkXUuX7PNtNJifty2kmSEefU5ky/gpNA1rYMtkZbJqdZY+8jkZospKZCDvQPJBzQdF+Ml6U
 sLn4skqpPUYCfSurKhTcpsfj5F4tNftObwJOwhSniLRdBLcsP/8BjSF
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
 samples/Kconfig               |  2 +-
 samples/kvm/memory_provider.c | 33 ++++++++++++++++++++++-----------
 2 files changed, 23 insertions(+), 12 deletions(-)

diff --git a/samples/Kconfig b/samples/Kconfig
index d4e79e1a9286b..4ef9328a91778 100644
--- a/samples/Kconfig
+++ b/samples/Kconfig
@@ -328,7 +328,7 @@ source "samples/damon/Kconfig"
 
 config SAMPLE_KVM_MEMORY_PROVIDER
 	tristate "Build sample memory provider -- loadable module only"
-	depends on CONTIG_ALLOC && X86_64 && m
+	depends on CONTIG_ALLOC && X86_64 && m && KVM_GUEST_MEMFD
 	help
 	  This builds a sample memory provider.
 	  Its files can back a guest_memfd and be mapped by iommufd.
diff --git a/samples/kvm/memory_provider.c b/samples/kvm/memory_provider.c
index 0a03623492f4c..926f3cf68ed49 100644
--- a/samples/kvm/memory_provider.c
+++ b/samples/kvm/memory_provider.c
@@ -43,6 +43,19 @@ struct mp_info {
 	struct inode *gmem_inode;
 };
 
+static void mp_zero_range(struct mp_info *info, pgoff_t index,
+			   size_t nr_pages)
+{
+	size_t i;
+
+	if (index >= info->npages)
+		return;
+
+	nr_pages = min_t(size_t, nr_pages, info->npages - index);
+	for (i = 0; i < nr_pages; i++)
+		clear_highpage(info->cma_pages + index + i);
+}
+
 /* Byte range [offset, offset + len) of @info as page indices. */
 static int mp_range(struct mp_info *info, u64 offset, u64 len,
 		    unsigned long *start, unsigned long *end)
@@ -82,12 +95,17 @@ static void mp_set_present(struct mp_info *info, unsigned long start,
 			   unsigned long end, bool present)
 {
 	mutex_lock(&info->lock);
-
-	if (present)
+	if (present) {
 		bitmap_clear(info->absent, start, end - start);
-	else
+	} else {
 		bitmap_set(info->absent, start, end - start);
+		if (info->gmem_inode) {
+			unsigned long pfn = info->base_pfn + start;
 
+			kvm_gmem_revoke(info->gmem_inode, start, end - start, &pfn);
+			mp_zero_range(info, start, end - start);
+		}
+	}
 	mutex_unlock(&info->lock);
 }
 
@@ -203,15 +221,8 @@ static void mp_gmem_put_pfn_range(void *provider, pgoff_t index,
 				   size_t nr_pages)
 {
 	struct file *resource_file = provider;
-	struct mp_info *info = resource_file->private_data;
-	size_t i;
 
-	if (index >= info->npages)
-		return;
-
-	nr_pages = min_t(size_t, nr_pages, info->npages - index);
-	for (i = 0; i < nr_pages; i++)
-		clear_highpage(info->cma_pages + index + i);
+	mp_zero_range(resource_file->private_data, index, nr_pages);
 }
 
 static int mp_gmem_get_pfn(void *provider, pgoff_t index, unsigned long *pfn,

-- 
2.56.0.455.g6c5a503b38-goog

