From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:38:01 -0800
Subject: [PATCH RFC v3 87/88] QUESTION: KVM: guest_memfd: Disallow private
 mappings of shared-only PFNs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-87-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=14128;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=YboiAAXrsRpRc5OH/Rd6uFPv93m0ToCdIqIrHIwRJIg=;
 b=ajkHJ0uXvnLtyBLv2CwiADg6fka9TnKfqMME3i9rQ1b1fhDLrSXOMh6jeDKixXX8x+DGU5KPG
 OJ3ARdykJrxBkxFnYyWqbLtizhyXr6KmUhskiqTbqOaIdbedecBHtz+
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Host kernel drivers directly write to the PCI MSI-X vector table to
program and mask interrupts. On confidential computing platforms, allowing
hardware protection tables (such as RMP, Secure-EPT, or GPT) to mark MSI-X
pages private causes subsequent host kernel interrupt updates to trigger
fatal hardware protection faults.

I see 2 options here:

1. Prevent it at conversion time, and require INIT_SHARED
2. Let guest_memfd track all conversions to private as per normal, but
   block setting the MSI-X range as private at the platform level by
   blocking platform config for SNP, ARM CCA at fault time, and by blocking
   faults for TDX.

Implement (2) partially by introducing a PFN attribute bit indicating that
a physical frame cannot be mapped or populated as private, reporting that
attribute from VFIO PCI whenever a BAR page overlaps the MSI-X vector
table.

When a PFN carries this attribute, reject private stage-2 fault resolution,
private memory population, and SNP RMP fault / VMSA reload paths before any
platform private transition occurs, while still allowing shared mappings.

The missing half is that for ARM CCA, which (for now?) doesn't use the
.gmem_make_private() hook, will have to enforce in its GPT configuration
path to block to-private config for MSI-X ranges.

With (2), the attribute-conversion check callback is not longer required.

Pros of preventing platform updates via PFN attributes:
- Enforces the invariant at the single boundary where physical frames
  enter hardware confidential state, covering both initial private files
  and later conversions uniformly. (Though for Confidential IO, the
  guest_memfd would have started off as INIT_SHARED anyway, so we could
  require INIT_SHARED in the VFIO .attach() handler)
- Allows virtual machine monitors to initialize or convert an entire BAR
  at once without carving out the MSI-X range when a memslot hole already
  traps guest MSI-X accesses.

Cons of preventing platform updates via PFN attributes:
- Defers error reporting from ioctl conversion or creation time to fault
  or populate time if userspace maps a shared-only page into a memslot and
  accesses it as private, whereas rejecting conversions and requiring
  shared initialization fails eagerly and keeps software attributes
  aligned with hardware capability.
- Special architecture make-private paths (CCA only?, since SNP's
  make-private is handled from within kvm_gmem_get_pfn) need to block this

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 arch/x86/kvm/svm/sev.c           |  9 +++++++-
 drivers/vfio/pci/vfio_pci.c      |  1 -
 drivers/vfio/pci/vfio_pci_core.c | 49 ++++++++++++----------------------------
 drivers/vfio/vfio_main.c         | 16 -------------
 include/linux/guest_memfd.h      | 14 ++----------
 include/linux/vfio.h             |  3 ---
 include/linux/vfio_pci_core.h    |  3 ---
 virt/kvm/guest_memfd.c           | 26 +++++----------------
 8 files changed, 30 insertions(+), 91 deletions(-)

diff --git a/arch/x86/kvm/svm/sev.c b/arch/x86/kvm/svm/sev.c
index 526f2a457cfe0..4d19ce862c27d 100644
--- a/arch/x86/kvm/svm/sev.c
+++ b/arch/x86/kvm/svm/sev.c
@@ -4100,7 +4100,8 @@ static void __sev_snp_reload_vmsa(struct kvm_vcpu *vcpu, gpa_t gpa)
 	if (kvm_gmem_get_pfn(vcpu->kvm, slot, gfn, &pfn, NULL, &pfn_attrs))
 		return;
 
-	if ((pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY) ||
+	if ((pfn_attrs & (GUEST_MEMFD_PFN_ATTRS_READONLY |
+			  GUEST_MEMFD_PFN_ATTRS_NO_PRIVATE)) ||
 	    !kvm_gmem_pfn_is_cacheable(pfn_attrs))
 		return;
 
@@ -5111,6 +5112,12 @@ void sev_handle_rmp_fault(struct kvm_vcpu *vcpu, gpa_t gpa, u64 error_code)
 		return;
 	}
 
+	if (pfn_attrs & GUEST_MEMFD_PFN_ATTRS_NO_PRIVATE) {
+		pr_warn_ratelimited("SEV: Unexpected RMP fault, shared-only backing page for GPA 0x%llx\n",
+				    gpa);
+		return;
+	}
+
 	if (!kvm_gmem_pfn_is_cacheable(pfn_attrs)) {
 		pr_warn_ratelimited("SEV: Unexpected RMP fault, non-cacheable backing page for GPA 0x%llx\n",
 				    gpa);
diff --git a/drivers/vfio/pci/vfio_pci.c b/drivers/vfio/pci/vfio_pci.c
index e5e2dbca152ec..6b137e009982c 100644
--- a/drivers/vfio/pci/vfio_pci.c
+++ b/drivers/vfio/pci/vfio_pci.c
@@ -173,7 +173,6 @@ static const struct vfio_device_ops vfio_pci_ops = {
 	.gmem_release		= vfio_pci_core_gmem_release,
 	.gmem_get_pfn		= vfio_pci_core_gmem_get_pfn,
 	.gmem_lookup_pfn_range	= vfio_pci_core_gmem_lookup_pfn_range,
-	.gmem_check_set_attributes = vfio_pci_core_gmem_check_set_attributes,
 	.gmem_read		= vfio_pci_core_gmem_read,
 	.gmem_write		= vfio_pci_core_gmem_write,
 #endif
diff --git a/drivers/vfio/pci/vfio_pci_core.c b/drivers/vfio/pci/vfio_pci_core.c
index c976574782663..ccaa24620112a 100644
--- a/drivers/vfio/pci/vfio_pci_core.c
+++ b/drivers/vfio/pci/vfio_pci_core.c
@@ -16,7 +16,6 @@
 #include <linux/eventfd.h>
 #include <linux/file.h>
 #include <linux/guest_memfd.h>
-#include <linux/kvm_host.h>
 #include <linux/interrupt.h>
 #include <linux/iommu.h>
 #include <linux/module.h>
@@ -2790,45 +2789,25 @@ int vfio_pci_core_gmem_get_pfn(struct vfio_device *core_vdev, pgoff_t index,
 	if (max_order)
 		*max_order = 0;
 
-	if (pfn_attrs)
+	if (pfn_attrs) {
 		*pfn_attrs = GUEST_MEMFD_PFN_ATTRS_CACHE_UC_ALLOW_WC;
 
-	return 0;
-}
-EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_get_pfn);
-
-int vfio_pci_core_gmem_check_set_attributes(struct vfio_device *core_vdev,
-					    pgoff_t index, size_t nr_pages,
-					    u64 attributes)
-{
-	struct vfio_pci_core_device *vdev =
-		container_of(core_vdev, struct vfio_pci_core_device, vdev);
-	pgoff_t bar_pgoff;
-	size_t size;
-	loff_t pos;
-	int bar;
-
-	if (!(attributes & KVM_MEMORY_ATTRIBUTE_PRIVATE))
-		return 0;
-
-	/*
-	 * Prevent private conversion of pages containing the MSI-X vector
-	 * table. The host kernel directly programs MSI-X table entries to
-	 * configure and mask interrupts; converting these pages to private
-	 * would cause host kernel writes to trigger fatal hardware protection
-	 * faults (e.g. RMP or GPT violations) on confidential compute platforms.
-	 */
-	bar = index >> (VFIO_PCI_OFFSET_SHIFT - PAGE_SHIFT);
-	bar_pgoff = index & ((1ULL << (VFIO_PCI_OFFSET_SHIFT - PAGE_SHIFT)) - 1);
-	pos = (loff_t)bar_pgoff << PAGE_SHIFT;
-	size = nr_pages << PAGE_SHIFT;
-
-	if (vfio_pci_range_overlaps_msix(vdev, bar, pos, size))
-		return -EINVAL;
+		/*
+		 * Disallow private mappings of pages overlapping the MSI-X
+		 * vector table. The host kernel directly programs MSI-X table
+		 * entries to configure and mask interrupts; marking these pages
+		 * private in hardware protection tables (e.g. RMP or GPT) would
+		 * cause host kernel writes to trigger fatal faults.
+		 */
+		if (vfio_pci_range_overlaps_msix(vdev, bar,
+						 (loff_t)pgoff << PAGE_SHIFT,
+						 PAGE_SIZE))
+			*pfn_attrs |= GUEST_MEMFD_PFN_ATTRS_NO_PRIVATE;
+	}
 
 	return 0;
 }
-EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_check_set_attributes);
+EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_get_pfn);
 
 int vfio_pci_core_gmem_lookup_pfn_range(struct vfio_device *core_vdev,
 					pgoff_t index, unsigned long *pfn,
diff --git a/drivers/vfio/vfio_main.c b/drivers/vfio/vfio_main.c
index 96a768b5ec71b..770ae8ef7926f 100644
--- a/drivers/vfio/vfio_main.c
+++ b/drivers/vfio/vfio_main.c
@@ -1621,21 +1621,6 @@ static int vfio_device_gmem_mmap(void *provider, struct vm_area_struct *vma)
 	return vfio_device_mmap(df->device, vma);
 }
 
-static int vfio_device_gmem_check_set_attributes(void *provider, pgoff_t index,
-						 size_t nr_pages,
-						 u64 attributes)
-{
-	struct file *file = provider;
-	struct vfio_device_file *df = file->private_data;
-	struct vfio_device *device = df->device;
-
-	if (!device->ops->gmem_check_set_attributes)
-		return 0;
-
-	return device->ops->gmem_check_set_attributes(device, index, nr_pages,
-						      attributes);
-}
-
 static int vfio_device_gmem_lookup_pfn_range(void *provider, pgoff_t index,
 					     unsigned long *pfn,
 					     size_t *nr_pages)
@@ -1692,7 +1677,6 @@ static const struct guest_memfd_provider_operations vfio_device_gmem_provider_op
 	.read                 = vfio_device_gmem_read,
 	.write                = vfio_device_gmem_write,
 	.mmap                 = vfio_device_gmem_mmap,
-	.check_set_attributes = vfio_device_gmem_check_set_attributes,
 };
 
 int vfio_device_gmem_revoke(struct vfio_device *device, pgoff_t start,
diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
index c85594b58112a..f839ae936ebed 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -32,6 +32,8 @@ struct mempolicy;
 #define GUEST_MEMFD_PFN_ATTRS_CACHE_UC_ALLOW_WC	(2ULL << 1)
 #define GUEST_MEMFD_PFN_ATTRS_CACHE_WC		(3ULL << 1)
 
+#define GUEST_MEMFD_PFN_ATTRS_NO_PRIVATE	BIT_ULL(3)
+
 static inline bool kvm_gmem_pfn_is_cacheable(u64 pfn_attrs)
 {
 	return (pfn_attrs & GUEST_MEMFD_PFN_ATTRS_CACHE_MASK) ==
@@ -88,16 +90,6 @@ static inline bool kvm_gmem_pfn_is_cacheable(u64 pfn_attrs)
  * @mmap: Optional callback to set up user mappings. Called when userspace calls
  *        mmap() on guest_memfd. The provider can customize VMA flags, or reject
  *        the mapping.
- * @check_set_attributes: Optional callback to validate attribute changes on a
- *                        range of indices before they are committed. Called
- *                        with the exclusive filemap invalidate lock held. The
- *                        provider can inspect the requested attributes and
- *                        offset range and return 0 to allow the transition or
- *                        a negative error code (e.g. -EINVAL or -EPERM) to
- *                        reject it. Once @check_set_attributes succeeds, the
- *                        provider must ensure this result stays valid and
- *                        constant until guest_memfd stops using the range. Do
- *                        not take locks held across kvm_gmem_revoke().
  *
  * Used by filesystems and device drivers that provide memory for guest_memfd.
  */
@@ -117,8 +109,6 @@ struct guest_memfd_provider_operations {
 			loff_t *ppos);
 	ssize_t (*write)(void *provider, const void *buf, size_t count,
 			 loff_t *ppos);
-	int (*check_set_attributes)(void *provider, pgoff_t index,
-				    size_t nr_pages, u64 attributes);
 };
 
 #ifdef CONFIG_KVM_GUEST_MEMFD
diff --git a/include/linux/vfio.h b/include/linux/vfio.h
index 012a233a375ab..c38bbc5568fee 100644
--- a/include/linux/vfio.h
+++ b/include/linux/vfio.h
@@ -125,9 +125,6 @@ struct vfio_device_ops {
 	int (*gmem_get_pfn)(struct vfio_device *device, pgoff_t index,
 			    unsigned long *pfn, int *max_order,
 			    u64 *pfn_attrs);
-	int (*gmem_check_set_attributes)(struct vfio_device *device,
-					 pgoff_t index, size_t nr_pages,
-					 u64 attributes);
 	int (*gmem_lookup_pfn_range)(struct vfio_device *device, pgoff_t index,
 				     unsigned long *pfn, size_t *nr_pages);
 	ssize_t (*gmem_read)(struct vfio_device *device, void *buf,
diff --git a/include/linux/vfio_pci_core.h b/include/linux/vfio_pci_core.h
index 03cb0b41855dd..5bab69cb83c25 100644
--- a/include/linux/vfio_pci_core.h
+++ b/include/linux/vfio_pci_core.h
@@ -175,9 +175,6 @@ void vfio_pci_core_gmem_release(struct vfio_device *core_vdev);
 int vfio_pci_core_gmem_get_pfn(struct vfio_device *core_vdev, pgoff_t index,
 			       unsigned long *pfn, int *max_order,
 			       u64 *pfn_attrs);
-int vfio_pci_core_gmem_check_set_attributes(struct vfio_device *core_vdev,
-					    pgoff_t index, size_t nr_pages,
-					    u64 attributes);
 int vfio_pci_core_gmem_lookup_pfn_range(struct vfio_device *core_vdev,
 					pgoff_t index, unsigned long *pfn,
 					size_t *nr_pages);
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 385b517b49ed5..cd484bdcb3f0c 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -245,16 +245,6 @@ static ssize_t gmem_provider_write(struct gmem_inode *gi,
 	return -EINVAL;
 }
 
-static int gmem_provider_check_set_attributes(struct gmem_inode *gi, pgoff_t index,
-					      size_t nr_pages, u64 attributes)
-{
-	if (gi->provider_ops && gi->provider_ops->check_set_attributes)
-		return gi->provider_ops->check_set_attributes(gi->provider, index,
-							      nr_pages, attributes);
-
-	return 0;
-}
-
 #define kvm_gmem_for_each_file(f, inode) \
 	list_for_each_entry(f, &GMEM_I(inode)->gmem_file_list, entry)
 
@@ -1128,12 +1118,6 @@ static int __kvm_gmem_set_attributes(struct inode *inode, pgoff_t start,
 	if (kvm_gmem_range_has_attributes(inode, start, nr_pages, attrs))
 		goto out;
 
-	r = gmem_provider_check_set_attributes(gi, start, nr_pages, attrs);
-	if (r) {
-		*err_index = start;
-		goto out;
-	}
-
 	mas_init(&mas, mt, start);
 	r = kvm_gmem_mas_preallocate(&mas, attrs, start, nr_pages);
 	if (r) {
@@ -1774,10 +1758,11 @@ int kvm_gmem_get_pfn(struct kvm *kvm, struct kvm_memory_slot *slot,
 
 	/*
 	 * Private memory requires exclusive, writable guest ownership and
-	 * cannot be backed by a read-only frame.
+	 * cannot be backed by a read-only or shared-only frame.
 	 */
 	if (kvm_gmem_is_private_mem(file_inode(file), index) &&
-	    (*pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY)) {
+	    (*pfn_attrs & (GUEST_MEMFD_PFN_ATTRS_READONLY |
+			   GUEST_MEMFD_PFN_ATTRS_NO_PRIVATE))) {
 		r = -EFAULT;
 		goto out_put_folio;
 	}
@@ -1824,9 +1809,10 @@ static long __kvm_gmem_populate(struct kvm *kvm, struct kvm_memory_slot *slot,
 
 	/*
 	 * Populating pages initializes private memory, which cannot be
-	 * read-only or non-cacheable.
+	 * read-only, shared-only, or non-cacheable.
 	 */
-	if ((pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY) ||
+	if ((pfn_attrs & (GUEST_MEMFD_PFN_ATTRS_READONLY |
+			  GUEST_MEMFD_PFN_ATTRS_NO_PRIVATE)) ||
 	    !kvm_gmem_pfn_is_cacheable(pfn_attrs)) {
 		ret = -EPERM;
 		goto out_put_folio;

-- 
2.56.0.455.g6c5a503b38-goog

