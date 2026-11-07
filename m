From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:42 -0800
Subject: [PATCH RFC v3 68/88] vfio/pci: Use iov_iter for MMIO read and
 write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-68-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=6301;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=c4VDLuT5yqC8DJ1fpMzzzVy4zLcf9cySQYtbQA4hk74=;
 b=L5BjRew5q1svkShxrjXUHUJtKZ/8fmvjKLgv7L6S7iOvEcrS/PClvlilzhXkLk+16KWEMf/Ny
 1dJMQc+3f77BIvFJT8Dpz/JuqAKav6jhjhEryI/df80j9npQPqOyeF+
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor the internal MMIO read and write helpers in vfio_pci_rdwr to
operate on struct iov_iter rather than directly calling copy_to_user
and copy_from_user with user pointers.

Keep the existing vfio_pci_core_do_io_rw interface unchanged by
importing user buffers into an iov_iter via import_ubuf before calling
the internal implementation. The overhead of initializing the iov_iter
on userspace accesses is negligible compared to PCIe bus cycle latency.

This decouples low-level PCI MMIO access from userspace copy semantics,
allowing in-kernel callers to service I/O using kernel buffers (such
as ITER_KVEC) without user copy overhead or page fault recursion.

For delegation of read/write() to guest_memfd, this helps avoid AB-BA
deadlocks between mapping.invalidate_lock and mm->mmap_lock when MMIO read
and write operations are invoked under filemap invalidation locks.

No functional change intended.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/pci/vfio_pci_rdwr.c | 107 ++++++++++++++++++++++++---------------
 1 file changed, 65 insertions(+), 42 deletions(-)

diff --git a/drivers/vfio/pci/vfio_pci_rdwr.c b/drivers/vfio/pci/vfio_pci_rdwr.c
index e5f1f60513709..cc64722d1ab9a 100644
--- a/drivers/vfio/pci/vfio_pci_rdwr.c
+++ b/drivers/vfio/pci/vfio_pci_rdwr.c
@@ -91,34 +91,34 @@ VFIO_IOREAD(32)
 VFIO_IOREAD(64)
 
 #define VFIO_IORDWR(size)						\
-static int vfio_pci_iordwr##size(struct vfio_pci_core_device *vdev,\
-				bool iswrite, bool test_mem,		\
-				void __iomem *io, char __user *buf,	\
-				loff_t off, size_t *filled)		\
-{									\
-	u##size val;							\
-	int ret;							\
-									\
-	if (iswrite) {							\
-		if (copy_from_user(&val, buf, sizeof(val)))		\
-			return -EFAULT;					\
-									\
-		ret = vfio_pci_core_iowrite##size(vdev, test_mem,	\
-						  val, io + off);	\
-		if (ret)						\
-			return ret;					\
-	} else {							\
-		ret = vfio_pci_core_ioread##size(vdev, test_mem,	\
-						 &val, io + off);	\
-		if (ret)						\
-			return ret;					\
-									\
-		if (copy_to_user(buf, &val, sizeof(val)))		\
-			return -EFAULT;					\
-	}								\
-									\
-	*filled = sizeof(val);						\
-	return 0;							\
+static int vfio_pci_iordwr##size(struct vfio_pci_core_device *vdev,		\
+				bool iswrite, bool test_mem,			\
+				void __iomem *io, struct iov_iter *iter,	\
+				loff_t off, size_t *filled)			\
+{										\
+	u##size val;								\
+	int ret;								\
+										\
+	if (iswrite) {								\
+		if (!copy_from_iter_full(&val, sizeof(val), iter))		\
+			return -EFAULT;						\
+										\
+		ret = vfio_pci_core_iowrite##size(vdev, test_mem,		\
+						  val, io + off);		\
+		if (ret)							\
+			return ret;						\
+	} else {								\
+		ret = vfio_pci_core_ioread##size(vdev, test_mem,		\
+						 &val, io + off);		\
+		if (ret)							\
+			return ret;						\
+										\
+		if (!copy_to_iter_full(&val, sizeof(val), iter))		\
+			return -EFAULT;						\
+	}									\
+										\
+	*filled = sizeof(val);							\
+	return 0;								\
 }									\
 
 VFIO_IORDWR(8)
@@ -132,11 +132,12 @@ VFIO_IORDWR(64)
  * reads with -1.  This is intended for handling MSI-X vector tables and
  * leftover space for ROM BARs.
  */
-ssize_t vfio_pci_core_do_io_rw(struct vfio_pci_core_device *vdev, bool test_mem,
-			       void __iomem *io, char __user *buf,
-			       loff_t off, size_t count, size_t x_start,
-			       size_t x_end, bool iswrite,
-			       enum vfio_pci_io_width max_width)
+static ssize_t __vfio_pci_core_do_io_rw(struct vfio_pci_core_device *vdev,
+					bool test_mem, void __iomem *io,
+					struct iov_iter *iter, loff_t off,
+					size_t count, size_t x_start,
+					size_t x_end, bool iswrite,
+					enum vfio_pci_io_width max_width)
 {
 	ssize_t done = 0;
 	int ret;
@@ -153,25 +154,25 @@ ssize_t vfio_pci_core_do_io_rw(struct vfio_pci_core_device *vdev, bool test_mem,
 
 		if (fillable >= 8 && !(off % 8) && max_width >= 8) {
 			ret = vfio_pci_iordwr64(vdev, iswrite, test_mem,
-						io, buf, off, &filled);
+						io, iter, off, &filled);
 			if (ret)
 				return ret;
 
 		} else if (fillable >= 4 && !(off % 4) && max_width >= 4) {
 			ret = vfio_pci_iordwr32(vdev, iswrite, test_mem,
-						io, buf, off, &filled);
+						io, iter, off, &filled);
 			if (ret)
 				return ret;
 
 		} else if (fillable >= 2 && !(off % 2) && max_width >= 2) {
 			ret = vfio_pci_iordwr16(vdev, iswrite, test_mem,
-						io, buf, off, &filled);
+						io, iter, off, &filled);
 			if (ret)
 				return ret;
 
 		} else if (fillable) {
 			ret = vfio_pci_iordwr8(vdev, iswrite, test_mem,
-					       io, buf, off, &filled);
+					       io, iter, off, &filled);
 			if (ret)
 				return ret;
 
@@ -179,23 +180,45 @@ ssize_t vfio_pci_core_do_io_rw(struct vfio_pci_core_device *vdev, bool test_mem,
 			/* Fill reads with -1, drop writes */
 			filled = min(count, (size_t)(x_end - off));
 			if (!iswrite) {
-				u8 val = 0xFF;
-				size_t i;
+				static const u8 ff_buf[64] = { [0 ... 63] = 0xFF };
+				size_t cur = filled;
+
+				while (cur) {
+					size_t step = min(cur, sizeof(ff_buf));
 
-				for (i = 0; i < filled; i++)
-					if (copy_to_user(buf + i, &val, 1))
+					if (!copy_to_iter_full(ff_buf, step, iter))
 						return -EFAULT;
+					cur -= step;
+				}
+			} else {
+				iov_iter_advance(iter, filled);
 			}
 		}
 
 		count -= filled;
 		done += filled;
 		off += filled;
-		buf += filled;
 	}
 
 	return done;
 }
+
+ssize_t vfio_pci_core_do_io_rw(struct vfio_pci_core_device *vdev, bool test_mem,
+			       void __iomem *io, char __user *buf,
+			       loff_t off, size_t count, size_t x_start,
+			       size_t x_end, bool iswrite,
+			       enum vfio_pci_io_width max_width)
+{
+	struct iov_iter iter;
+	int ret;
+
+	ret = import_ubuf(iswrite ? ITER_SOURCE : ITER_DEST, buf, count, &iter);
+	if (ret)
+		return ret;
+
+	return __vfio_pci_core_do_io_rw(vdev, test_mem, io, &iter, off, count,
+					x_start, x_end, iswrite, max_width);
+}
 EXPORT_SYMBOL_GPL(vfio_pci_core_do_io_rw);
 
 ssize_t vfio_pci_bar_rw(struct vfio_pci_core_device *vdev, char __user *buf,

-- 
2.56.0.455.g6c5a503b38-goog

