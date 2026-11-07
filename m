From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:37 -0800
Subject: [PATCH RFC v3 63/88] vfio/pci: Implement check_set_attributes
 provider op for guest_memfd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-63-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=5833;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=TMwTUp5cqKcj2kTekFr4TruFvpaWuzNv14YEyWz6eMk=;
 b=UbZOzxtTC0NPZ+730r8uhK3++yIyJUWwAWmy+/W4WSFvCFPEUZshY+F2FUPkeQ5iFwFW9Lu4Q
 PXLtOpflYs0DIUR68SWBUFmgEcb08Fk5N8T/UABlrAzf2Oaz48/TkDa
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the .check_set_attributes provider operation in the generic
PCI VFIO bus driver to validate attribute conversion requests on
guest_memfd files backed by a VFIO PCI device.

When converting to private, decode the 40-bit VFIO region offset to
verify that the targeted BAR is a standard memory BAR and that the range
does not exceed the BAR's physical resource size.

Prevent private conversion of pages overlapping the device's MSI-X
vector table. The host kernel accesses MSI-X table entries directly to
configure and mask device interrupts; converting these pages to private
would cause subsequent host kernel interrupt operations to trigger fatal
hardware protection faults (such as RMP or GPT violations) on
confidential computing platforms.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/pci/vfio_pci.c      |  7 ++++---
 drivers/vfio/pci/vfio_pci_core.c | 34 ++++++++++++++++++++++++++++++++++
 drivers/vfio/pci/vfio_pci_priv.h | 10 ++++++++++
 drivers/vfio/pci/vfio_pci_rdwr.c |  4 +---
 include/linux/vfio_pci_core.h    |  3 +++
 5 files changed, 52 insertions(+), 6 deletions(-)

diff --git a/drivers/vfio/pci/vfio_pci.c b/drivers/vfio/pci/vfio_pci.c
index 9bc8009a9e766..f42422c1b7bc5 100644
--- a/drivers/vfio/pci/vfio_pci.c
+++ b/drivers/vfio/pci/vfio_pci.c
@@ -169,9 +169,10 @@ static const struct vfio_device_ops vfio_pci_ops = {
 	.pasid_attach_ioas	= vfio_iommufd_physical_pasid_attach_ioas,
 	.pasid_detach_ioas	= vfio_iommufd_physical_pasid_detach_ioas,
 #ifdef CONFIG_KVM_GUEST_MEMFD
-	.gmem_attach	= vfio_pci_core_gmem_attach,
-	.gmem_release	= vfio_pci_core_gmem_release,
-	.gmem_get_pfn	= vfio_pci_core_gmem_get_pfn,
+	.gmem_attach		= vfio_pci_core_gmem_attach,
+	.gmem_release		= vfio_pci_core_gmem_release,
+	.gmem_get_pfn		= vfio_pci_core_gmem_get_pfn,
+	.gmem_check_set_attributes = vfio_pci_core_gmem_check_set_attributes,
 #endif
 };
 
diff --git a/drivers/vfio/pci/vfio_pci_core.c b/drivers/vfio/pci/vfio_pci_core.c
index 9551a067b5689..894b1332f8a0c 100644
--- a/drivers/vfio/pci/vfio_pci_core.c
+++ b/drivers/vfio/pci/vfio_pci_core.c
@@ -16,6 +16,7 @@
 #include <linux/eventfd.h>
 #include <linux/file.h>
 #include <linux/guest_memfd.h>
+#include <linux/kvm_host.h>
 #include <linux/interrupt.h>
 #include <linux/iommu.h>
 #include <linux/module.h>
@@ -2769,6 +2770,39 @@ int vfio_pci_core_gmem_get_pfn(struct vfio_device *core_vdev, pgoff_t index,
 	return 0;
 }
 EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_get_pfn);
+
+int vfio_pci_core_gmem_check_set_attributes(struct vfio_device *core_vdev,
+					    pgoff_t index, size_t nr_pages,
+					    u64 attributes)
+{
+	struct vfio_pci_core_device *vdev =
+		container_of(core_vdev, struct vfio_pci_core_device, vdev);
+	pgoff_t bar_pgoff;
+	size_t size;
+	loff_t pos;
+	int bar;
+
+	if (!(attributes & KVM_MEMORY_ATTRIBUTE_PRIVATE))
+		return 0;
+
+	/*
+	 * Prevent private conversion of pages containing the MSI-X vector
+	 * table. The host kernel directly programs MSI-X table entries to
+	 * configure and mask interrupts; converting these pages to private
+	 * would cause host kernel writes to trigger fatal hardware protection
+	 * faults (e.g. RMP or GPT violations) on confidential compute platforms.
+	 */
+	bar = index >> (VFIO_PCI_OFFSET_SHIFT - PAGE_SHIFT);
+	bar_pgoff = index & ((1ULL << (VFIO_PCI_OFFSET_SHIFT - PAGE_SHIFT)) - 1);
+	pos = (loff_t)bar_pgoff << PAGE_SHIFT;
+	size = nr_pages << PAGE_SHIFT;
+
+	if (vfio_pci_range_overlaps_msix(vdev, bar, pos, size))
+		return -EINVAL;
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_check_set_attributes);
 #endif
 
 module_init(vfio_pci_core_init);
diff --git a/drivers/vfio/pci/vfio_pci_priv.h b/drivers/vfio/pci/vfio_pci_priv.h
index 4e7162234a2eb..607a33270aca1 100644
--- a/drivers/vfio/pci/vfio_pci_priv.h
+++ b/drivers/vfio/pci/vfio_pci_priv.h
@@ -23,6 +23,16 @@ struct vfio_pci_ioeventfd {
 	bool			test_mem;
 };
 
+static inline bool vfio_pci_range_overlaps_msix(struct vfio_pci_core_device *vdev,
+						int bar, loff_t pos, size_t count)
+{
+	if (vdev->msix_bar == 0xFF || bar != vdev->msix_bar)
+		return false;
+
+	return !(pos + count <= vdev->msix_offset ||
+		 pos >= vdev->msix_offset + vdev->msix_size);
+}
+
 bool vfio_pci_intx_mask(struct vfio_pci_core_device *vdev);
 void vfio_pci_intx_unmask(struct vfio_pci_core_device *vdev);
 
diff --git a/drivers/vfio/pci/vfio_pci_rdwr.c b/drivers/vfio/pci/vfio_pci_rdwr.c
index 7f14dd46de17a..e5f1f60513709 100644
--- a/drivers/vfio/pci/vfio_pci_rdwr.c
+++ b/drivers/vfio/pci/vfio_pci_rdwr.c
@@ -418,9 +418,7 @@ int vfio_pci_ioeventfd(struct vfio_pci_core_device *vdev, loff_t offset,
 		return -EINVAL;
 
 	/* Disallow ioeventfds working around MSI-X table writes */
-	if (bar == vdev->msix_bar &&
-	    !(pos + count <= vdev->msix_offset ||
-	      pos >= vdev->msix_offset + vdev->msix_size))
+	if (vfio_pci_range_overlaps_msix(vdev, bar, pos, count))
 		return -EINVAL;
 
 	if (count == 8)
diff --git a/include/linux/vfio_pci_core.h b/include/linux/vfio_pci_core.h
index 3a6d039454472..6ff67e38eaf84 100644
--- a/include/linux/vfio_pci_core.h
+++ b/include/linux/vfio_pci_core.h
@@ -175,6 +175,9 @@ void vfio_pci_core_gmem_release(struct vfio_device *core_vdev);
 int vfio_pci_core_gmem_get_pfn(struct vfio_device *core_vdev, pgoff_t index,
 			       unsigned long *pfn, int *max_order,
 			       u64 *pfn_attrs);
+int vfio_pci_core_gmem_check_set_attributes(struct vfio_device *core_vdev,
+					    pgoff_t index, size_t nr_pages,
+					    u64 attributes);
 #endif
 extern const struct pci_error_handlers vfio_pci_core_err_handlers;
 int vfio_pci_core_sriov_configure(struct vfio_pci_core_device *vdev,

-- 
2.56.0.455.g6c5a503b38-goog

