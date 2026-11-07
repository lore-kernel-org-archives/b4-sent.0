From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:45 -0800
Subject: [PATCH RFC v3 71/88] vfio/pci: Implement read and write provider
 ops for guest_memfd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-71-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=4013;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=m9SP1CpmTKvsGoq5eZAgHyb5OpuOEc1QM5jrgJzQxmI=;
 b=IoPXFGcHpHdx3UkOvEWFEMm1Dzaeclszns6ukrwhiM363noCrao70iL5dIJrsqo9NYK4Q0Ok3
 ibey69WXBPFDkrp/2bbZlPPA3FGFWxadq6loOgMcqBRLY3Q25uA+Ycy
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the .gmem_read and .gmem_write provider operations in
vfio-pci to service read and write accesses forwarded by guest_memfd.

When guest_memfd delegates BAR access, it already holds the shared
filemap invalidation lock and serializes against memory attribute
conversions and hardware revocations.

Restrict guest_memfd reads and writes strictly to mappable MMIO BARs
(indices < PCI_STD_NUM_BARS with bar_mmap_supported[index] set),
rejecting all other regions with -EINVAL.

Verify locklessly that BARs are available via bars_available before
accessing MMIO space. Forward to vfio_pci_bar_rw_kbuf with test_mem
set to false to skip acquiring memory_lock and runtime PM, preventing
AB-BA deadlocks against concurrent revocations during resets, power
state transitions, or memory decoding disablement.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/pci/vfio_pci.c      |  2 ++
 drivers/vfio/pci/vfio_pci_core.c | 36 ++++++++++++++++++++++++++++++++++++
 include/linux/vfio_pci_core.h    |  5 +++++
 3 files changed, 43 insertions(+)

diff --git a/drivers/vfio/pci/vfio_pci.c b/drivers/vfio/pci/vfio_pci.c
index 6f28f1ffbad0e..e5e2dbca152ec 100644
--- a/drivers/vfio/pci/vfio_pci.c
+++ b/drivers/vfio/pci/vfio_pci.c
@@ -174,6 +174,8 @@ static const struct vfio_device_ops vfio_pci_ops = {
 	.gmem_get_pfn		= vfio_pci_core_gmem_get_pfn,
 	.gmem_lookup_pfn_range	= vfio_pci_core_gmem_lookup_pfn_range,
 	.gmem_check_set_attributes = vfio_pci_core_gmem_check_set_attributes,
+	.gmem_read		= vfio_pci_core_gmem_read,
+	.gmem_write		= vfio_pci_core_gmem_write,
 #endif
 };
 
diff --git a/drivers/vfio/pci/vfio_pci_core.c b/drivers/vfio/pci/vfio_pci_core.c
index a9274d95e9066..c976574782663 100644
--- a/drivers/vfio/pci/vfio_pci_core.c
+++ b/drivers/vfio/pci/vfio_pci_core.c
@@ -2871,6 +2871,42 @@ int vfio_pci_core_gmem_lookup_pfn_range(struct vfio_device *core_vdev,
 	return -ENOENT;
 }
 EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_lookup_pfn_range);
+
+static ssize_t vfio_pci_core_gmem_rw(struct vfio_device *core_vdev,
+				     void *kbuf, size_t count,
+				     loff_t *ppos, bool iswrite)
+{
+	struct vfio_pci_core_device *vdev =
+		container_of(core_vdev, struct vfio_pci_core_device, vdev);
+	unsigned int index = VFIO_PCI_OFFSET_TO_INDEX(*ppos);
+
+	if (!count)
+		return 0;
+
+	if (index >= PCI_STD_NUM_BARS || !vdev->bar_mmap_supported[index])
+		return -EINVAL;
+
+	/* Lockless check on availability of BARs. */
+	if (!vfio_pci_get_bars_available(vdev))
+		return -EIO;
+
+	return vfio_pci_bar_rw_kbuf(vdev, kbuf, count, ppos, iswrite, false);
+}
+
+ssize_t vfio_pci_core_gmem_read(struct vfio_device *core_vdev, void *buf,
+				size_t count, loff_t *ppos)
+{
+	return vfio_pci_core_gmem_rw(core_vdev, buf, count, ppos, false);
+}
+EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_read);
+
+ssize_t vfio_pci_core_gmem_write(struct vfio_device *core_vdev,
+				 const void *buf, size_t count,
+				 loff_t *ppos)
+{
+	return vfio_pci_core_gmem_rw(core_vdev, (void *)buf, count, ppos, true);
+}
+EXPORT_SYMBOL_GPL(vfio_pci_core_gmem_write);
 #endif
 
 module_init(vfio_pci_core_init);
diff --git a/include/linux/vfio_pci_core.h b/include/linux/vfio_pci_core.h
index b6e2fb93f9500..03cb0b41855dd 100644
--- a/include/linux/vfio_pci_core.h
+++ b/include/linux/vfio_pci_core.h
@@ -181,6 +181,11 @@ int vfio_pci_core_gmem_check_set_attributes(struct vfio_device *core_vdev,
 int vfio_pci_core_gmem_lookup_pfn_range(struct vfio_device *core_vdev,
 					pgoff_t index, unsigned long *pfn,
 					size_t *nr_pages);
+ssize_t vfio_pci_core_gmem_read(struct vfio_device *core_vdev, void *buf,
+				size_t count, loff_t *ppos);
+ssize_t vfio_pci_core_gmem_write(struct vfio_device *core_vdev,
+				 const void *buf, size_t count,
+				 loff_t *ppos);
 static inline void vfio_pci_set_bars_available(struct vfio_pci_core_device *vdev,
 					       bool available)
 {

-- 
2.56.0.455.g6c5a503b38-goog

