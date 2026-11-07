From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:35 -0800
Subject: [PATCH RFC v3 61/88] vfio: Implement mmap provider op for
 guest_memfd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-61-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2752;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=NmjUQDJ7kwJoSKxjmguxqr+e/jaq/RcX/cxOk+5qSGo=;
 b=ba5b8oVSqCJBgb8rRqu7kCB3RfRR+uk2t9fQ3KTkROGoJJH8hNBnYw4EeYlCKLYDIRbTG+TqQ
 U//vSQOeCyaAEsC3YXGI+uXDVq6nwov9AsvUY9W6m47Yc0A6asX98wj
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When userspace creates a shared mapping on a guest_memfd file backed by
a VFIO device descriptor, guest_memfd invokes the .mmap provider
operation to allow the provider to configure the VMA.

Implement .mmap on vfio_device_gmem_provider_ops by forwarding directly
to the bus driver's existing .mmap callback on struct vfio_device_ops.
This reuses existing driver mapping setup and region boundary
validation, such as PCI BAR checking and VMA flag configuration in
vfio-pci, without requiring bus drivers to duplicate mapping logic for
guest_memfd.

While the bus driver's mapping handler sets its own virtual memory
operations on the VMA, guest_memfd overrides them with its own PFN
virtual memory operations upon return, ensuring fault handling remains
mediated by guest_memfd attribute checks.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/vfio_main.c | 28 +++++++++++++++++++++++-----
 1 file changed, 23 insertions(+), 5 deletions(-)

diff --git a/drivers/vfio/vfio_main.c b/drivers/vfio/vfio_main.c
index 93bd0a200ad22..979ed69c5ebf7 100644
--- a/drivers/vfio/vfio_main.c
+++ b/drivers/vfio/vfio_main.c
@@ -1503,20 +1503,25 @@ static ssize_t vfio_device_fops_write(struct file *filep,
 	return device->ops->write(device, buf, count, ppos);
 }
 
+static int vfio_device_mmap(struct vfio_device *device,
+			    struct vm_area_struct *vma)
+{
+	if (unlikely(!device->ops->mmap))
+		return -EOPNOTSUPP;
+
+	return device->ops->mmap(device, vma);
+}
+
 static int vfio_device_fops_mmap(struct file *filep, struct vm_area_struct *vma)
 {
 	struct vfio_device_file *df = filep->private_data;
-	struct vfio_device *device = df->device;
 	int ret;
 
 	ret = vfio_df_check_full_access(df);
 	if (ret)
 		return ret;
 
-	if (unlikely(!device->ops->mmap))
-		return -EINVAL;
-
-	return device->ops->mmap(device, vma);
+	return vfio_device_mmap(df->device, vma);
 }
 
 #ifdef CONFIG_PROC_FS
@@ -1604,10 +1609,23 @@ static int vfio_device_gmem_get_pfn(void *provider, pgoff_t index,
 					 pfn_attrs);
 }
 
+static int vfio_device_gmem_mmap(void *provider, struct vm_area_struct *vma)
+{
+	struct file *file = provider;
+	struct vfio_device_file *df = file->private_data;
+
+	/*
+	 * No control- vs. data-plane filtering is required because
+	 * vfio_device_mmap() already only allows mmap-ing the data plane.
+	 */
+	return vfio_device_mmap(df->device, vma);
+}
+
 static const struct guest_memfd_provider_operations vfio_device_gmem_provider_ops = {
 	.attach  = vfio_device_gmem_attach,
 	.release = vfio_device_gmem_release,
 	.get_pfn = vfio_device_gmem_get_pfn,
+	.mmap    = vfio_device_gmem_mmap,
 };
 #endif
 

-- 
2.56.0.455.g6c5a503b38-goog

