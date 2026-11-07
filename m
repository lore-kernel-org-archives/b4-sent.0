From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:31 -0800
Subject: [PATCH RFC v3 57/88] vfio: Dispatch guest_memfd provider
 operations via vfio_device_ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-57-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=4501;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=q2ITMkbAof/3UP+0FfKPWcVVHgQv4Rq4rRtRz04IELc=;
 b=dY2yZNw6w5h8twDc2KQFqIDSj+kEflkJIL6zIJOdYeI4Zfv9+RVf/WpjLyZjT9gdkhmx7PeRk
 h9/vQsv1G13CPj8w6oaoyFHRUaGfzC1xYGZ/akAfFW69XvPPrdEysLF
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a guest_memfd instance is created using a VFIO device descriptor as
its resource_fd, guest_memfd queries file_operations::gmem_provider_ops
on the resource file to attach the external memory provider.

Implement guest_memfd provider operations on vfio_device_fops to
dispatch .attach and .release to the bus driver via vfio_device_ops.

In .attach:
- Verify that the device descriptor was bound with
  VFIO_DEVICE_BIND_FLAG_CTRL_ONLY by checking that access_mode is
  VFIO_DF_ACCESS_CTRL_ONLY, returning -EINVAL if the descriptor was
  bound in full-access mode or has not been bound yet.
- Check and record attachment state centrally in struct vfio_device
  under dev_set->lock, rejecting attachment with -EBUSY if the device
  is already attached to a guest_memfd instance.
- Dispatch to the bus driver's .gmem_attach callback to let the driver
  perform bus-specific validation and resource reservation.
- Pin the device file across attachment via get_file(), dropping it on
  .release via fput().

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/vfio_main.c | 63 ++++++++++++++++++++++++++++++++++++++++++++++++
 include/linux/vfio.h     |  7 ++++++
 2 files changed, 70 insertions(+)

diff --git a/drivers/vfio/vfio_main.c b/drivers/vfio/vfio_main.c
index 8734ae9d06c2b..618daf8bdaf80 100644
--- a/drivers/vfio/vfio_main.c
+++ b/drivers/vfio/vfio_main.c
@@ -1535,6 +1535,66 @@ static void vfio_device_show_fdinfo(struct seq_file *m, struct file *filep)
 }
 #endif
 
+#ifdef CONFIG_KVM_GUEST_MEMFD
+static void *vfio_device_gmem_attach(struct inode *inode, struct file *file)
+{
+	struct vfio_device_file *df = file->private_data;
+	struct vfio_device *device = df->device;
+	int ret;
+
+	/*
+	 * Attachment is only permitted if the device descriptor was bound
+	 * with VFIO_DEVICE_BIND_FLAG_CTRL_ONLY, ensuring direct region
+	 * accesses (read, write, mmap) and side-channel exports (such as
+	 * dma-buf or ioeventfd) were disabled from the outset.
+	 */
+	if (smp_load_acquire(&df->access_mode) != VFIO_DF_ACCESS_CTRL_ONLY)
+		return ERR_PTR(-EINVAL);
+
+	if (!device->ops->gmem_attach)
+		return ERR_PTR(-EOPNOTSUPP);
+
+	mutex_lock(&device->dev_set->lock);
+	if (device->gmem_inode) {
+		ret = -EBUSY;
+		goto out_unlock;
+	}
+
+	ret = device->ops->gmem_attach(device);
+	if (ret)
+		goto out_unlock;
+
+	device->gmem_inode = inode;
+out_unlock:
+	mutex_unlock(&device->dev_set->lock);
+
+	return ret ? ERR_PTR(ret) : get_file(file);
+}
+
+static void vfio_device_gmem_release(void *provider)
+{
+	struct file *file = provider;
+	struct vfio_device_file *df = file->private_data;
+	struct vfio_device *device = df->device;
+
+	mutex_lock(&device->dev_set->lock);
+
+	if (device->ops->gmem_release)
+		device->ops->gmem_release(device);
+
+	device->gmem_inode = NULL;
+
+	mutex_unlock(&device->dev_set->lock);
+
+	fput(file);
+}
+
+static const struct guest_memfd_provider_operations vfio_device_gmem_provider_ops = {
+	.attach  = vfio_device_gmem_attach,
+	.release = vfio_device_gmem_release,
+};
+#endif
+
 const struct file_operations vfio_device_fops = {
 	.owner		= THIS_MODULE,
 	.open		= vfio_device_fops_cdev_open,
@@ -1547,6 +1607,9 @@ const struct file_operations vfio_device_fops = {
 #ifdef CONFIG_PROC_FS
 	.show_fdinfo	= vfio_device_show_fdinfo,
 #endif
+#ifdef CONFIG_KVM_GUEST_MEMFD
+	.gmem_provider_ops = &vfio_device_gmem_provider_ops,
+#endif
 };
 
 static struct vfio_device *vfio_device_from_file(struct file *file)
diff --git a/include/linux/vfio.h b/include/linux/vfio.h
index c81373ddf2a9c..65dc2cb523351 100644
--- a/include/linux/vfio.h
+++ b/include/linux/vfio.h
@@ -74,6 +74,9 @@ struct vfio_device {
 #endif
 	u8 cdev_opened:1;
 	u8 noiommu:1;
+#ifdef CONFIG_KVM_GUEST_MEMFD
+	struct inode *gmem_inode;
+#endif
 	/*
 	 * debug_root is a static property of the vfio_device
 	 * which must be set prior to registering the vfio_device.
@@ -114,7 +117,11 @@ struct vfio_device {
  *             this device is attached to.
  * @device_feature: Optional, fill in the VFIO_DEVICE_FEATURE ioctl
  */
+struct guest_memfd_provider_operations;
+
 struct vfio_device_ops {
+	int (*gmem_attach)(struct vfio_device *device);
+	void (*gmem_release)(struct vfio_device *device);
 	char	*name;
 	int	(*init)(struct vfio_device *vdev);
 	void	(*release)(struct vfio_device *vdev);

-- 
2.56.0.455.g6c5a503b38-goog

