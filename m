From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:43 -0800
Subject: [PATCH RFC v3 69/88] vfio: Dispatch guest_memfd read and write
 provider ops via vfio_device_ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-69-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=3723;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=jM77+UpFK8UZJ6Z/B9OjQwdxpmk38JIQhpdGHBHGDN0=;
 b=qZQmSdOhDsqL/VO1Qtn/xfjCgHVuDDCpM2sUtQnC+iJGQWbhQHH4tf/D2WJ0crZwfhZ+WoCZ0
 TPw9vQHWPJGBAJdDnviv0dQFie2JIrL5WljLO4Uq+bUnoXiRG/anEkK
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When userspace reads or writes to a guest_memfd descriptor backed by a
VFIO device descriptor, guest_memfd invokes the .read and .write
provider operations under the shared filemap invalidation lock.

Implement .read and .write on vfio_device_gmem_provider_ops to dispatch
to the bus driver's .gmem_read and .gmem_write callbacks on struct
vfio_device_ops. The callbacks operate on kernel buffers (void *buf and
const void *buf), as guest_memfd bounces userspace transfers outside
its filemap invalidation lock. Return -EINVAL if the bus driver does
not define the respective callback.

Enforce the partition between direct VFIO descriptor access and
guest_memfd delegation: query is_ctrl_plane on the target file offset,
rejecting reads and writes to control-plane offsets (such as PCI
configuration space) with -EINVAL so guest_memfd only services
data-plane regions complementary to what direct VFIO descriptor accesses
allow in control-only mode.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/vfio_main.c | 36 ++++++++++++++++++++++++++++++++++++
 include/linux/vfio.h     |  4 ++++
 2 files changed, 40 insertions(+)

diff --git a/drivers/vfio/vfio_main.c b/drivers/vfio/vfio_main.c
index 1c2811848c775..96a768b5ec71b 100644
--- a/drivers/vfio/vfio_main.c
+++ b/drivers/vfio/vfio_main.c
@@ -1650,11 +1650,47 @@ static int vfio_device_gmem_lookup_pfn_range(void *provider, pgoff_t index,
 	return device->ops->gmem_lookup_pfn_range(device, index, pfn, nr_pages);
 }
 
+static ssize_t vfio_device_gmem_read(void *provider, void *buf,
+				     size_t count, loff_t *ppos)
+{
+	struct file *file = provider;
+	struct vfio_device_file *df = file->private_data;
+	struct vfio_device *device = df->device;
+
+	if (!device->ops->gmem_read)
+		return -EINVAL;
+
+	if (device->ops->is_ctrl_plane &&
+	    device->ops->is_ctrl_plane(device, *ppos))
+		return -EINVAL;
+
+	return device->ops->gmem_read(device, buf, count, ppos);
+}
+
+static ssize_t vfio_device_gmem_write(void *provider, const void *buf,
+				      size_t count, loff_t *ppos)
+{
+	struct file *file = provider;
+	struct vfio_device_file *df = file->private_data;
+	struct vfio_device *device = df->device;
+
+	if (!device->ops->gmem_write)
+		return -EINVAL;
+
+	if (device->ops->is_ctrl_plane &&
+	    device->ops->is_ctrl_plane(device, *ppos))
+		return -EINVAL;
+
+	return device->ops->gmem_write(device, buf, count, ppos);
+}
+
 static const struct guest_memfd_provider_operations vfio_device_gmem_provider_ops = {
 	.attach               = vfio_device_gmem_attach,
 	.release              = vfio_device_gmem_release,
 	.get_pfn              = vfio_device_gmem_get_pfn,
 	.lookup_pfn_range     = vfio_device_gmem_lookup_pfn_range,
+	.read                 = vfio_device_gmem_read,
+	.write                = vfio_device_gmem_write,
 	.mmap                 = vfio_device_gmem_mmap,
 	.check_set_attributes = vfio_device_gmem_check_set_attributes,
 };
diff --git a/include/linux/vfio.h b/include/linux/vfio.h
index 8022adedc26a6..012a233a375ab 100644
--- a/include/linux/vfio.h
+++ b/include/linux/vfio.h
@@ -130,6 +130,10 @@ struct vfio_device_ops {
 					 u64 attributes);
 	int (*gmem_lookup_pfn_range)(struct vfio_device *device, pgoff_t index,
 				     unsigned long *pfn, size_t *nr_pages);
+	ssize_t (*gmem_read)(struct vfio_device *device, void *buf,
+			     size_t count, loff_t *ppos);
+	ssize_t (*gmem_write)(struct vfio_device *device, const void *buf,
+			      size_t count, loff_t *ppos);
 	char	*name;
 	int	(*init)(struct vfio_device *vdev);
 	void	(*release)(struct vfio_device *vdev);

-- 
2.56.0.455.g6c5a503b38-goog

