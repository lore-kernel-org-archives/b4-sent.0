From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:33 -0800
Subject: [PATCH RFC v3 59/88] vfio: Dispatch guest_memfd get_pfn provider
 op via vfio_device_ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-59-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2331;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=xvhk/B5cJ5UV/xewATDcSIWa/TiLlY+J1HVubbWHrTs=;
 b=o7/Mg1zgNXsxxe9h93PAmVT9+adieaG+XGvsvYOAGMQVbFhjEeQODEIVNBVomRcjlxVrpS+fC
 vD5PwxCvv4YA1qhXrdJYU5KtKYsUBP51tja93wBeyuXND0y2TJGrwT/
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When servicing guest stage-2 page faults or host userspace page faults
on guest_memfd memory backed by a VFIO resource descriptor, guest_memfd
invokes the .get_pfn provider operation under the shared filemap
invalidation lock.

Implement .get_pfn on vfio_device_gmem_provider_ops to dispatch to the
bus driver's .gmem_get_pfn callback on struct vfio_device_ops. Return
-EOPNOTSUPP if the bus driver does not implement the callback. The core
dispatch path avoids acquiring dev_set->lock to satisfy the requirement
that provider callbacks do not acquire locks held during revocation.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/vfio_main.c | 16 ++++++++++++++++
 include/linux/vfio.h     |  3 +++
 2 files changed, 19 insertions(+)

diff --git a/drivers/vfio/vfio_main.c b/drivers/vfio/vfio_main.c
index 618daf8bdaf80..93bd0a200ad22 100644
--- a/drivers/vfio/vfio_main.c
+++ b/drivers/vfio/vfio_main.c
@@ -1589,9 +1589,25 @@ static void vfio_device_gmem_release(void *provider)
 	fput(file);
 }
 
+static int vfio_device_gmem_get_pfn(void *provider, pgoff_t index,
+				    unsigned long *pfn, int *max_order,
+				    u64 *pfn_attrs)
+{
+	struct file *file = provider;
+	struct vfio_device_file *df = file->private_data;
+	struct vfio_device *device = df->device;
+
+	if (!device->ops->gmem_get_pfn)
+		return -EOPNOTSUPP;
+
+	return device->ops->gmem_get_pfn(device, index, pfn, max_order,
+					 pfn_attrs);
+}
+
 static const struct guest_memfd_provider_operations vfio_device_gmem_provider_ops = {
 	.attach  = vfio_device_gmem_attach,
 	.release = vfio_device_gmem_release,
+	.get_pfn = vfio_device_gmem_get_pfn,
 };
 #endif
 
diff --git a/include/linux/vfio.h b/include/linux/vfio.h
index 65dc2cb523351..51e04b980a381 100644
--- a/include/linux/vfio.h
+++ b/include/linux/vfio.h
@@ -122,6 +122,9 @@ struct guest_memfd_provider_operations;
 struct vfio_device_ops {
 	int (*gmem_attach)(struct vfio_device *device);
 	void (*gmem_release)(struct vfio_device *device);
+	int (*gmem_get_pfn)(struct vfio_device *device, pgoff_t index,
+			    unsigned long *pfn, int *max_order,
+			    u64 *pfn_attrs);
 	char	*name;
 	int	(*init)(struct vfio_device *vdev);
 	void	(*release)(struct vfio_device *vdev);

-- 
2.56.0.455.g6c5a503b38-goog

