From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:34 -0800
Subject: [PATCH RFC v3 60/88] vfio/pci: Implement get_pfn provider op for
 guest_memfd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-60-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=3886;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=csbHfwVQmJAIvOL3JkXMdnFfqy9AUj2CCzhFEzRs5Ek=;
 b=WOkAJg7cFMQRQZBPquFwhsiqfmQ+MJXo+8XyVeu5y9SUxzhSHcejH5/SogBd1YAcut6NsIkjq
 Wb9r8OuGmI2CKiK9HL0TQjRmrP6IA+Y54RW+x0R/lWeRZxEsEgvr07e
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the .get_pfn provider operation in the generic PCI VFIO bus
driver to translate guest_memfd page offsets to physical BAR frames.

Check the BAR availability flag locklessly via smp_load_acquire() to
avoid acquiring the device memory lock on the fault path, returning
-EFAULT if memory decoding is disabled or the device is in low-power D3.

Decode the 40-bit VFIO region offset to identify the targeted BAR and
offset within the BAR, validating that the BAR is a standard memory BAR,
supports memory mapping, and the offset falls within the resource size.

Compute the physical frame number from the PCI resource start address
and report GUEST_MEMFD_PFN_ATTRS_CACHE_UC_ALLOW_WC as the frame's
caching attribute so stage-2 mappings permit guest write-combining while
host userspace mappings remain uncached.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/pci/vfio_pci.c      |  1 +
 drivers/vfio/pci/vfio_pci_core.c | 38 ++++++++++++++++++++++++++++++++++++++
 include/linux/vfio_pci_core.h    |  3 +++
 3 files changed, 42 insertions(+)

diff --git a/drivers/vfio/pci/vfio_pci.c b/drivers/vfio/pci/vfio_pci.c
index 96f438671db29..9bc8009a9e766 100644
--- a/drivers/vfio/pci/vfio_pci.c
+++ b/drivers/vfio/pci/vfio_pci.c
@@ -171,6 +171,7 @@ static const struct vfio_device_ops vfio_pci_ops = {
 #ifdef CONFIG_KVM_GUEST_MEMFD
 	.gmem_attach	= vfio_pci_core_gmem_attach,
 	.gmem_release	= vfio_pci_core_gmem_release,
+	.gmem_get_pfn	= vfio_pci_core_gmem_get_pfn,
 #endif
 };
 
diff --git a/drivers/vfio/pci/vfio_pci_core.c b/drivers/vfio/pci/vfio_pci_core.c
index c7b67fbce4cae..9551a067b5689 100644
--- a/drivers/vfio/pci/vfio_pci_core.c
+++ b/drivers/vfio/pci/vfio_pci_core.c
@@ -2731,6 +2731,44 @@ void vfio_pci_core_gmem_release(struct vfio_device *core_vdev)
 	up_write(&vdev->memory_lock);
 }
 EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_release);
+
+int vfio_pci_core_gmem_get_pfn(struct vfio_device *core_vdev, pgoff_t index,
+			       unsigned long *pfn, int *max_order,
+			       u64 *pfn_attrs)
+{
+	struct vfio_pci_core_device *vdev =
+		container_of(core_vdev, struct vfio_pci_core_device, vdev);
+	struct pci_dev *pdev = vdev->pdev;
+	unsigned int bar;
+	u64 pgoff;
+
+	/*
+	 * Lockless check: if memory decoding is disabled or the device is in
+	 * low-power D3, fail immediately without blocking on memory_lock.
+	 */
+	if (!smp_load_acquire(&vdev->bars_available))
+		return -EFAULT;
+
+	bar = index >> (VFIO_PCI_OFFSET_SHIFT - PAGE_SHIFT);
+	pgoff = index & ((1ULL << (VFIO_PCI_OFFSET_SHIFT - PAGE_SHIFT)) - 1);
+
+	if (bar >= PCI_STD_NUM_BARS || !vdev->bar_mmap_supported[bar])
+		return -EINVAL;
+
+	if (pgoff >= (pci_resource_len(pdev, bar) >> PAGE_SHIFT))
+		return -EINVAL;
+
+	*pfn = (pci_resource_start(pdev, bar) >> PAGE_SHIFT) + pgoff;
+
+	if (max_order)
+		*max_order = 0;
+
+	if (pfn_attrs)
+		*pfn_attrs = GUEST_MEMFD_PFN_ATTRS_CACHE_UC_ALLOW_WC;
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_get_pfn);
 #endif
 
 module_init(vfio_pci_core_init);
diff --git a/include/linux/vfio_pci_core.h b/include/linux/vfio_pci_core.h
index c3c16459e14f4..3a6d039454472 100644
--- a/include/linux/vfio_pci_core.h
+++ b/include/linux/vfio_pci_core.h
@@ -172,6 +172,9 @@ void vfio_pci_core_unregister_device(struct vfio_pci_core_device *vdev);
 #ifdef CONFIG_KVM_GUEST_MEMFD
 int vfio_pci_core_gmem_attach(struct vfio_device *core_vdev);
 void vfio_pci_core_gmem_release(struct vfio_device *core_vdev);
+int vfio_pci_core_gmem_get_pfn(struct vfio_device *core_vdev, pgoff_t index,
+			       unsigned long *pfn, int *max_order,
+			       u64 *pfn_attrs);
 #endif
 extern const struct pci_error_handlers vfio_pci_core_err_handlers;
 int vfio_pci_core_sriov_configure(struct vfio_pci_core_device *vdev,

-- 
2.56.0.455.g6c5a503b38-goog

