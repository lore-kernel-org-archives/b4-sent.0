From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:44 -0800
Subject: [PATCH RFC v3 70/88] vfio/pci: Introduce vfio_pci_bar_rw_kbuf for
 kernel buffer MMIO access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-70-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=3928;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=UIlkF+Cr22G3+Xr2iBhEh8LcRpc3sGqQkL185U7r+lA=;
 b=+kFt+aQv22Fzn/rAHsafa1OuVqSafNgWyqhLjRHbRfa9pHHNKcUImie1vu/kp7shzbDEOq5Ui
 o/cvz/JgZIMB7fndBfMPCP9FpzvLu83/5upSc1Qy9/oaTWLV4373+Kc
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor BAR read and write handling to separate the core MMIO logic
from the buffer source.

Extract the core BAR read and write implementation into a static helper
that operates on an iov_iter and accepts a test_mem parameter controlling
whether memory decoding and power state should be validated under
memory_lock. Retain the userspace interface, importing the user buffer
into an iov_iter with test_mem enabled.

Introduce a counterpart helper taking a kernel buffer and setting up
an ITER_KVEC iov_iter, allowing callers with kernel buffers to read
and write to PCI BARs without userspace pointer conversion or copy
overhead, and to specify whether memory testing is required.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/pci/vfio_pci_priv.h |  3 +++
 drivers/vfio/pci/vfio_pci_rdwr.c | 34 ++++++++++++++++++++++++++++++----
 2 files changed, 33 insertions(+), 4 deletions(-)

diff --git a/drivers/vfio/pci/vfio_pci_priv.h b/drivers/vfio/pci/vfio_pci_priv.h
index 607a33270aca1..48a068e68aab8 100644
--- a/drivers/vfio/pci/vfio_pci_priv.h
+++ b/drivers/vfio/pci/vfio_pci_priv.h
@@ -53,6 +53,9 @@ ssize_t vfio_pci_config_rw_single(struct vfio_pci_core_device *vdev,
 
 ssize_t vfio_pci_bar_rw(struct vfio_pci_core_device *vdev, char __user *buf,
 			size_t count, loff_t *ppos, bool iswrite);
+ssize_t vfio_pci_bar_rw_kbuf(struct vfio_pci_core_device *vdev, void *kbuf,
+			     size_t count, loff_t *ppos, bool iswrite,
+			     bool test_mem);
 
 #ifdef CONFIG_VFIO_PCI_VGA
 ssize_t vfio_pci_vga_rw(struct vfio_pci_core_device *vdev, char __user *buf,
diff --git a/drivers/vfio/pci/vfio_pci_rdwr.c b/drivers/vfio/pci/vfio_pci_rdwr.c
index cc64722d1ab9a..c44c78e48e6aa 100644
--- a/drivers/vfio/pci/vfio_pci_rdwr.c
+++ b/drivers/vfio/pci/vfio_pci_rdwr.c
@@ -221,8 +221,9 @@ ssize_t vfio_pci_core_do_io_rw(struct vfio_pci_core_device *vdev, bool test_mem,
 }
 EXPORT_SYMBOL_GPL(vfio_pci_core_do_io_rw);
 
-ssize_t vfio_pci_bar_rw(struct vfio_pci_core_device *vdev, char __user *buf,
-			size_t count, loff_t *ppos, bool iswrite)
+static ssize_t __vfio_pci_bar_rw(struct vfio_pci_core_device *vdev,
+				 struct iov_iter *iter, size_t count,
+				 loff_t *ppos, bool iswrite, bool test_mem)
 {
 	struct pci_dev *pdev = vdev->pdev;
 	loff_t pos = *ppos & VFIO_PCI_OFFSET_MASK;
@@ -284,8 +285,9 @@ ssize_t vfio_pci_bar_rw(struct vfio_pci_core_device *vdev, char __user *buf,
 		x_end = vdev->msix_offset + vdev->msix_size;
 	}
 
-	done = vfio_pci_core_do_io_rw(vdev, res->flags & IORESOURCE_MEM, io, buf, pos,
-				      count, x_start, x_end, iswrite, max_width);
+	done = __vfio_pci_core_do_io_rw(vdev, test_mem && (res->flags & IORESOURCE_MEM),
+					io, iter, pos, count, x_start, x_end,
+					iswrite, max_width);
 
 	if (done >= 0)
 		*ppos += done;
@@ -301,6 +303,30 @@ ssize_t vfio_pci_bar_rw(struct vfio_pci_core_device *vdev, char __user *buf,
 	return done;
 }
 
+ssize_t vfio_pci_bar_rw(struct vfio_pci_core_device *vdev, char __user *buf,
+			size_t count, loff_t *ppos, bool iswrite)
+{
+	struct iov_iter iter;
+	int ret;
+
+	ret = import_ubuf(iswrite ? ITER_SOURCE : ITER_DEST, buf, count, &iter);
+	if (ret)
+		return ret;
+
+	return __vfio_pci_bar_rw(vdev, &iter, count, ppos, iswrite, true);
+}
+
+ssize_t vfio_pci_bar_rw_kbuf(struct vfio_pci_core_device *vdev, void *kbuf,
+			     size_t count, loff_t *ppos, bool iswrite,
+			     bool test_mem)
+{
+	struct kvec kvec = { .iov_base = kbuf, .iov_len = count };
+	struct iov_iter iter;
+
+	iov_iter_kvec(&iter, iswrite ? ITER_SOURCE : ITER_DEST, &kvec, 1, count);
+	return __vfio_pci_bar_rw(vdev, &iter, count, ppos, iswrite, test_mem);
+}
+
 #ifdef CONFIG_VFIO_PCI_VGA
 ssize_t vfio_pci_vga_rw(struct vfio_pci_core_device *vdev, char __user *buf,
 			       size_t count, loff_t *ppos, bool iswrite)

-- 
2.56.0.455.g6c5a503b38-goog

