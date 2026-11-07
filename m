From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:32 -0800
Subject: [PATCH RFC v3 58/88] vfio/pci: Implement attach and release
 provider ops for guest_memfd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-58-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=4120;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=BlUGE6K++nDiJr8qPUVvPATO+O8fe24pYgQMxNdL00c=;
 b=NgSlL+6BQDukoZMQwJMCQVxrx2tW2tfdtYAwt2Mqe6zuF4vrIrK51yN6n7vJ+9KVephyFm5Wd
 nI/Gwn7eHXYBu4/2kJhD2xUzUg8WGqxthiF+W0hHlwEEnmJsIIb2avw
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement guest_memfd provider operations in the generic PCI VFIO bus
driver to support attaching VFIO PCI devices to guest_memfd.

In the attachment path, acquire the device memory lock for write to
initialize the BAR availability flag according to whether PCI memory
decoding is active and runtime power management is not engaged. BAR
resources are already mapped and reserved during device open at bind
time.

In the release path, acquire the device memory lock for write and mark
BARs unavailable.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/pci/vfio_pci.c      |  4 ++++
 drivers/vfio/pci/vfio_pci_core.c | 37 +++++++++++++++++++++++++++++++++++++
 include/linux/vfio_pci_core.h    |  5 +++++
 3 files changed, 46 insertions(+)

diff --git a/drivers/vfio/pci/vfio_pci.c b/drivers/vfio/pci/vfio_pci.c
index 3dc232ee65491..96f438671db29 100644
--- a/drivers/vfio/pci/vfio_pci.c
+++ b/drivers/vfio/pci/vfio_pci.c
@@ -168,6 +168,10 @@ static const struct vfio_device_ops vfio_pci_ops = {
 	.detach_ioas	= vfio_iommufd_physical_detach_ioas,
 	.pasid_attach_ioas	= vfio_iommufd_physical_pasid_attach_ioas,
 	.pasid_detach_ioas	= vfio_iommufd_physical_pasid_detach_ioas,
+#ifdef CONFIG_KVM_GUEST_MEMFD
+	.gmem_attach	= vfio_pci_core_gmem_attach,
+	.gmem_release	= vfio_pci_core_gmem_release,
+#endif
 };
 
 static const struct vfio_pci_device_ops vfio_pci_dev_ops = {
diff --git a/drivers/vfio/pci/vfio_pci_core.c b/drivers/vfio/pci/vfio_pci_core.c
index 907e6ab024acd..c7b67fbce4cae 100644
--- a/drivers/vfio/pci/vfio_pci_core.c
+++ b/drivers/vfio/pci/vfio_pci_core.c
@@ -15,6 +15,7 @@
 #include <linux/device.h>
 #include <linux/eventfd.h>
 #include <linux/file.h>
+#include <linux/guest_memfd.h>
 #include <linux/interrupt.h>
 #include <linux/iommu.h>
 #include <linux/module.h>
@@ -2696,6 +2697,42 @@ static int __init vfio_pci_core_init(void)
 	return vfio_pci_init_perm_bits();
 }
 
+#ifdef CONFIG_KVM_GUEST_MEMFD
+int vfio_pci_core_gmem_attach(struct vfio_device *core_vdev)
+{
+	struct vfio_pci_core_device *vdev =
+		container_of(core_vdev, struct vfio_pci_core_device, vdev);
+	bool bars_available;
+
+	down_write(&vdev->memory_lock);
+
+	bars_available = __vfio_pci_memory_enabled(vdev) &&
+			 !vdev->pm_runtime_engaged;
+
+	/* Pairs with smp_load_acquire() in provider operations */
+	smp_store_release(&vdev->bars_available, bars_available);
+
+	up_write(&vdev->memory_lock);
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_attach);
+
+void vfio_pci_core_gmem_release(struct vfio_device *core_vdev)
+{
+	struct vfio_pci_core_device *vdev =
+		container_of(core_vdev, struct vfio_pci_core_device, vdev);
+
+	down_write(&vdev->memory_lock);
+
+	/* Pairs with smp_load_acquire() in provider operations */
+	smp_store_release(&vdev->bars_available, false);
+
+	up_write(&vdev->memory_lock);
+}
+EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_release);
+#endif
+
 module_init(vfio_pci_core_init);
 module_exit(vfio_pci_core_cleanup);
 
diff --git a/include/linux/vfio_pci_core.h b/include/linux/vfio_pci_core.h
index 1053774d2d659..c3c16459e14f4 100644
--- a/include/linux/vfio_pci_core.h
+++ b/include/linux/vfio_pci_core.h
@@ -149,6 +149,7 @@ struct vfio_pci_core_device {
 	struct notifier_block	nb;
 	struct rw_semaphore	memory_lock;
 	struct list_head	dmabufs;
+	bool			bars_available;
 };
 
 enum vfio_pci_io_width {
@@ -168,6 +169,10 @@ int vfio_pci_core_init_dev(struct vfio_device *core_vdev);
 void vfio_pci_core_release_dev(struct vfio_device *core_vdev);
 int vfio_pci_core_register_device(struct vfio_pci_core_device *vdev);
 void vfio_pci_core_unregister_device(struct vfio_pci_core_device *vdev);
+#ifdef CONFIG_KVM_GUEST_MEMFD
+int vfio_pci_core_gmem_attach(struct vfio_device *core_vdev);
+void vfio_pci_core_gmem_release(struct vfio_device *core_vdev);
+#endif
 extern const struct pci_error_handlers vfio_pci_core_err_handlers;
 int vfio_pci_core_sriov_configure(struct vfio_pci_core_device *vdev,
 				  int nr_virtfn);

-- 
2.56.0.455.g6c5a503b38-goog

