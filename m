From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:30 -0800
Subject: [PATCH RFC v3 56/88] vfio: Support VFIO_DEVICE_BIND_FLAG_CTRL_ONLY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-56-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=15060;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=nA9E5PspOX358dTaDE5Jo0Ok53XvF21+z9RrLI2Cs9g=;
 b=d1rn3Q0Z089HvpgCmEW5F9Urqt89//NRRDqKud9/JtnihqBE7GnI8YxYIAT9fHZKukfwpcu2O
 J3SyCgk5nK0CRne/vbSjkYx6ezahtmdtCww/JB9IjHSpdbXDS1yV0oi
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In preparation for attaching a VFIO device descriptor to guest_memfd,
mappable device BAR accesses must be mediated exclusively through
guest_memfd so they obey guest_memfd's per-page shared and private
memory attribute tracking and revocation synchronization. In
confidential computing VMs, converting device pages to private assigns
the physical BAR frames to the guest in hardware protection tables
(such as RMP or GPT). If host userspace could bypass guest_memfd via
direct VFIO reads, writes, memory mappings, dma-buf exports, or
ioeventfds, host accesses to private device pages could trigger host
hardware protection faults and crash the host.

An alternative would be to override the file operations table on the
open descriptor to strip non-control handlers, or to block region access
later at guest_memfd attachment time. However, overriding file
operations on an open file is racy because VFS caches capability flags
at open time and dispatches file operations without synchronizing
against pointer updates, and deferring the restriction until attachment
races with concurrent memory mappings, reads, writes, or exports on an
already-enabled descriptor.

Instead, introduce VFIO_DEVICE_BIND_FLAG_CTRL_ONLY for
VFIO_DEVICE_BIND_IOMMUFD to restrict the bound device descriptor as soon
as the device is enabled for use by the bind ioctl, avoiding any race
window:

- Unconditionally disable memory mappings (mmap) on the descriptor with
  -EOPNOTSUPP, as memory mappings of BAR regions belong to guest_memfd.
- Add an is_ctrl_plane callback to struct vfio_device_ops to query
  whether a given file offset belongs to the control plane.
- For descriptors bound with VFIO_DEVICE_BIND_FLAG_CTRL_ONLY, gate
  direct reads and writes using is_ctrl_plane: permit reads and writes
  to control-plane regions (such as PCI configuration space) on the
  VFIO descriptor, while rejecting reads and writes to data-plane
  regions (mappable MMIO BARs) with -EINVAL. This preserves
  control-plane register configuration and virtualization outside
  guest_memfd's filemap invalidation lock while guaranteeing data-plane
  isolation.
- Disable BAR side-channel exports (ioeventfd, dma-buf and graphics plane
  export, live migration, and DMA logging) with -EOPNOTSUPP.

Control-plane ioctls for IOMMU page table management, capability
discovery, interrupt configuration, resets, power management, VF token
configuration, and bus-master control remain permitted via the VFIO
descriptor because none of them expose arbitrary BAR memory to
userspace:

- Capability discovery, IOMMU attachment, VF token setup, and bus-master
  control operate only on host metadata, IOMMU state, or PCI
  configuration space rather than BAR MMIO pages.
- Interrupt configuration is mediated by the host kernel, and any BAR
  pages backing hardware MSI-X tables must remain shared rather than
  private so host-managed interrupt updates never touch private frames.
- Device resets and power-state transitions do not grant userspace BAR
  access and coordinate with guest_memfd revocation before changing
  hardware state once attached.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/device_cdev.c       |   9 +++-
 drivers/vfio/pci/vfio_pci.c      |   1 +
 drivers/vfio/pci/vfio_pci_core.c |  13 +++++
 drivers/vfio/vfio.h              |   1 +
 drivers/vfio/vfio_main.c         | 105 ++++++++++++++++++++++++++++++++++-----
 include/linux/vfio.h             |   2 +
 include/linux/vfio_pci_core.h    |   1 +
 include/uapi/linux/vfio.h        |   7 +++
 8 files changed, 125 insertions(+), 14 deletions(-)

diff --git a/drivers/vfio/device_cdev.c b/drivers/vfio/device_cdev.c
index 19be3947fc74a..e5b04e531ea97 100644
--- a/drivers/vfio/device_cdev.c
+++ b/drivers/vfio/device_cdev.c
@@ -92,7 +92,9 @@ static int vfio_df_check_token(struct vfio_device *device,
 long vfio_df_ioctl_bind_iommufd(struct vfio_device_file *df,
 				struct vfio_device_bind_iommufd __user *arg)
 {
-	const u32 VALID_FLAGS = VFIO_DEVICE_BIND_FLAG_TOKEN;
+	const u32 VALID_FLAGS = VFIO_DEVICE_BIND_FLAG_TOKEN |
+				VFIO_DEVICE_BIND_FLAG_CTRL_ONLY;
+	enum vfio_df_access_mode access_mode;
 	struct vfio_device *device = df->device;
 	struct vfio_device_bind_iommufd bind;
 	unsigned long minsz;
@@ -159,11 +161,14 @@ long vfio_df_ioctl_bind_iommufd(struct vfio_device_file *df,
 		goto out_close_device;
 
 	device->cdev_opened = true;
+	access_mode = (bind.flags & VFIO_DEVICE_BIND_FLAG_CTRL_ONLY) ?
+			      VFIO_DF_ACCESS_CTRL_ONLY :
+			      VFIO_DF_ACCESS_FULL;
 	/*
 	 * Paired with smp_load_acquire() in vfio_device_fops::ioctl/
 	 * read/write/mmap
 	 */
-	smp_store_release(&df->access_mode, VFIO_DF_ACCESS_FULL);
+	smp_store_release(&df->access_mode, access_mode);
 	mutex_unlock(&device->dev_set->lock);
 	return 0;
 
diff --git a/drivers/vfio/pci/vfio_pci.c b/drivers/vfio/pci/vfio_pci.c
index 830369ff878db..3dc232ee65491 100644
--- a/drivers/vfio/pci/vfio_pci.c
+++ b/drivers/vfio/pci/vfio_pci.c
@@ -155,6 +155,7 @@ static const struct vfio_device_ops vfio_pci_ops = {
 	.ioctl		= vfio_pci_core_ioctl,
 	.get_region_info_caps = vfio_pci_ioctl_get_region_info,
 	.device_feature = vfio_pci_core_ioctl_feature,
+	.is_ctrl_plane	= vfio_pci_core_is_ctrl_plane,
 	.read		= vfio_pci_core_read,
 	.write		= vfio_pci_core_write,
 	.mmap		= vfio_pci_core_mmap,
diff --git a/drivers/vfio/pci/vfio_pci_core.c b/drivers/vfio/pci/vfio_pci_core.c
index 6757054e9d875..907e6ab024acd 100644
--- a/drivers/vfio/pci/vfio_pci_core.c
+++ b/drivers/vfio/pci/vfio_pci_core.c
@@ -1680,6 +1680,19 @@ static ssize_t vfio_pci_rw(struct vfio_pci_core_device *vdev, char __user *buf,
 	return ret;
 }
 
+bool vfio_pci_core_is_ctrl_plane(struct vfio_device *core_vdev, loff_t ppos)
+{
+	struct vfio_pci_core_device *vdev =
+		container_of(core_vdev, struct vfio_pci_core_device, vdev);
+	unsigned int index = VFIO_PCI_OFFSET_TO_INDEX(ppos);
+
+	if (index < PCI_STD_NUM_BARS && vdev->bar_mmap_supported[index])
+		return false;
+
+	return true;
+}
+EXPORT_SYMBOL_GPL(vfio_pci_core_is_ctrl_plane);
+
 ssize_t vfio_pci_core_read(struct vfio_device *core_vdev, char __user *buf,
 		size_t count, loff_t *ppos)
 {
diff --git a/drivers/vfio/vfio.h b/drivers/vfio/vfio.h
index af2b8158b40c0..62c5cbb77a899 100644
--- a/drivers/vfio/vfio.h
+++ b/drivers/vfio/vfio.h
@@ -18,6 +18,7 @@ struct vfio_container;
 
 enum vfio_df_access_mode {
 	VFIO_DF_ACCESS_NONE = 0,
+	VFIO_DF_ACCESS_CTRL_ONLY,
 	VFIO_DF_ACCESS_FULL,
 };
 
diff --git a/drivers/vfio/vfio_main.c b/drivers/vfio/vfio_main.c
index fe126e137d5ca..8734ae9d06c2b 100644
--- a/drivers/vfio/vfio_main.c
+++ b/drivers/vfio/vfio_main.c
@@ -1231,8 +1231,23 @@ vfio_ioctl_device_feature_logging_report(struct vfio_device *device,
 	return ret;
 }
 
+static bool vfio_feature_ctrl_only_allowed(u32 flags)
+{
+	switch (flags & VFIO_DEVICE_FEATURE_MASK) {
+	case VFIO_DEVICE_FEATURE_PCI_VF_TOKEN:
+	case VFIO_DEVICE_FEATURE_LOW_POWER_ENTRY:
+	case VFIO_DEVICE_FEATURE_LOW_POWER_ENTRY_WITH_WAKEUP:
+	case VFIO_DEVICE_FEATURE_LOW_POWER_EXIT:
+	case VFIO_DEVICE_FEATURE_BUS_MASTER:
+		return true;
+	default:
+		return false;
+	}
+}
+
 static int vfio_ioctl_device_feature(struct vfio_device *device,
-				     struct vfio_device_feature __user *arg)
+				     struct vfio_device_feature __user *arg,
+				     bool ctrl_only)
 {
 	size_t minsz = offsetofend(struct vfio_device_feature, flags);
 	struct vfio_device_feature feature;
@@ -1255,6 +1270,9 @@ static int vfio_ioctl_device_feature(struct vfio_device *device,
 	    (feature.flags & VFIO_DEVICE_FEATURE_GET))
 		return -EINVAL;
 
+	if (ctrl_only && !vfio_feature_ctrl_only_allowed(feature.flags))
+		return -EOPNOTSUPP;
+
 	switch (feature.flags & VFIO_DEVICE_FEATURE_MASK) {
 	case VFIO_DEVICE_FEATURE_MIGRATION:
 		return vfio_ioctl_device_feature_migration(
@@ -1337,20 +1355,63 @@ static long vfio_get_region_info(struct vfio_device *device,
 	return ret;
 }
 
+static bool vfio_ioctl_ctrl_only_allowed(unsigned int cmd)
+{
+	switch (cmd) {
+	case VFIO_DEVICE_ATTACH_IOMMUFD_PT:
+	case VFIO_DEVICE_DETACH_IOMMUFD_PT:
+	case VFIO_DEVICE_FEATURE:
+	case VFIO_DEVICE_GET_INFO:
+	case VFIO_DEVICE_GET_REGION_INFO:
+	case VFIO_DEVICE_GET_IRQ_INFO:
+	case VFIO_DEVICE_SET_IRQS:
+	case VFIO_DEVICE_RESET:
+	case VFIO_DEVICE_GET_PCI_HOT_RESET_INFO:
+	case VFIO_DEVICE_PCI_HOT_RESET:
+		return true;
+	default:
+		return false;
+	}
+}
+
+static int vfio_df_check_full_access(struct vfio_device_file *df)
+{
+	/* Paired with smp_store_release() following vfio_df_open() */
+	switch (smp_load_acquire(&df->access_mode)) {
+	case VFIO_DF_ACCESS_NONE:
+		return -EINVAL;
+	case VFIO_DF_ACCESS_CTRL_ONLY:
+		return -EOPNOTSUPP;
+	case VFIO_DF_ACCESS_FULL:
+		return 0;
+	}
+	return -EINVAL;
+}
+
 static long vfio_device_fops_unl_ioctl(struct file *filep,
 				       unsigned int cmd, unsigned long arg)
 {
 	struct vfio_device_file *df = filep->private_data;
 	struct vfio_device *device = df->device;
 	void __user *uptr = (void __user *)arg;
+	bool ctrl_only = false;
 	int ret;
 
 	if (cmd == VFIO_DEVICE_BIND_IOMMUFD)
 		return vfio_df_ioctl_bind_iommufd(df, uptr);
 
 	/* Paired with smp_store_release() following vfio_df_open() */
-	if (smp_load_acquire(&df->access_mode) == VFIO_DF_ACCESS_NONE)
+	switch (smp_load_acquire(&df->access_mode)) {
+	case VFIO_DF_ACCESS_NONE:
 		return -EINVAL;
+	case VFIO_DF_ACCESS_CTRL_ONLY:
+		if (!vfio_ioctl_ctrl_only_allowed(cmd))
+			return -EOPNOTSUPP;
+		ctrl_only = true;
+		break;
+	case VFIO_DF_ACCESS_FULL:
+		break;
+	}
 
 	ret = vfio_device_pm_runtime_get(device);
 	if (ret)
@@ -1371,7 +1432,7 @@ static long vfio_device_fops_unl_ioctl(struct file *filep,
 
 	switch (cmd) {
 	case VFIO_DEVICE_FEATURE:
-		ret = vfio_ioctl_device_feature(device, uptr);
+		ret = vfio_ioctl_device_feature(device, uptr, ctrl_only);
 		break;
 
 	case VFIO_DEVICE_GET_REGION_INFO:
@@ -1390,15 +1451,33 @@ static long vfio_device_fops_unl_ioctl(struct file *filep,
 	return ret;
 }
 
+static int vfio_df_check_rw_access(struct vfio_device_file *df, loff_t pos)
+{
+	/* Paired with smp_store_release() following vfio_df_open() */
+	switch (smp_load_acquire(&df->access_mode)) {
+	case VFIO_DF_ACCESS_NONE:
+		return -EINVAL;
+	case VFIO_DF_ACCESS_CTRL_ONLY:
+		if (!df->device->ops->is_ctrl_plane ||
+		    !df->device->ops->is_ctrl_plane(df->device, pos))
+			return -EINVAL;
+		return 0;
+	case VFIO_DF_ACCESS_FULL:
+		return 0;
+	}
+	return -EINVAL;
+}
+
 static ssize_t vfio_device_fops_read(struct file *filep, char __user *buf,
 				     size_t count, loff_t *ppos)
 {
 	struct vfio_device_file *df = filep->private_data;
 	struct vfio_device *device = df->device;
+	int ret;
 
-	/* Paired with smp_store_release() following vfio_df_open() */
-	if (smp_load_acquire(&df->access_mode) == VFIO_DF_ACCESS_NONE)
-		return -EINVAL;
+	ret = vfio_df_check_rw_access(df, *ppos);
+	if (ret)
+		return ret;
 
 	if (unlikely(!device->ops->read))
 		return -EINVAL;
@@ -1412,10 +1491,11 @@ static ssize_t vfio_device_fops_write(struct file *filep,
 {
 	struct vfio_device_file *df = filep->private_data;
 	struct vfio_device *device = df->device;
+	int ret;
 
-	/* Paired with smp_store_release() following vfio_df_open() */
-	if (smp_load_acquire(&df->access_mode) == VFIO_DF_ACCESS_NONE)
-		return -EINVAL;
+	ret = vfio_df_check_rw_access(df, *ppos);
+	if (ret)
+		return ret;
 
 	if (unlikely(!device->ops->write))
 		return -EINVAL;
@@ -1427,10 +1507,11 @@ static int vfio_device_fops_mmap(struct file *filep, struct vm_area_struct *vma)
 {
 	struct vfio_device_file *df = filep->private_data;
 	struct vfio_device *device = df->device;
+	int ret;
 
-	/* Paired with smp_store_release() following vfio_df_open() */
-	if (smp_load_acquire(&df->access_mode) == VFIO_DF_ACCESS_NONE)
-		return -EINVAL;
+	ret = vfio_df_check_full_access(df);
+	if (ret)
+		return ret;
 
 	if (unlikely(!device->ops->mmap))
 		return -EINVAL;
diff --git a/include/linux/vfio.h b/include/linux/vfio.h
index 0cc91c6f96d2b..c81373ddf2a9c 100644
--- a/include/linux/vfio.h
+++ b/include/linux/vfio.h
@@ -97,6 +97,7 @@ struct vfio_device {
  * @pasid_detach_ioas: Opposite of pasid_attach_ioas
  * @open_device: Called when the first file descriptor is opened for this device
  * @close_device: Opposite of open_device
+ * @is_ctrl_plane: Check if a region offset belongs to the control plane
  * @read: Perform read(2) on device file descriptor
  * @write: Perform write(2) on device file descriptor
  * @ioctl: Perform ioctl(2) on device file descriptor, supporting VFIO_DEVICE_*
@@ -127,6 +128,7 @@ struct vfio_device_ops {
 	void	(*pasid_detach_ioas)(struct vfio_device *vdev, u32 pasid);
 	int	(*open_device)(struct vfio_device *vdev);
 	void	(*close_device)(struct vfio_device *vdev);
+	bool	(*is_ctrl_plane)(struct vfio_device *vdev, loff_t ppos);
 	ssize_t	(*read)(struct vfio_device *vdev, char __user *buf,
 			size_t count, loff_t *ppos);
 	ssize_t	(*write)(struct vfio_device *vdev, const char __user *buf,
diff --git a/include/linux/vfio_pci_core.h b/include/linux/vfio_pci_core.h
index 9a1674c152aa2..1053774d2d659 100644
--- a/include/linux/vfio_pci_core.h
+++ b/include/linux/vfio_pci_core.h
@@ -178,6 +178,7 @@ int vfio_pci_core_ioctl_feature(struct vfio_device *device, u32 flags,
 int vfio_pci_ioctl_get_region_info(struct vfio_device *core_vdev,
 				   struct vfio_region_info *info,
 				   struct vfio_info_cap *caps);
+bool vfio_pci_core_is_ctrl_plane(struct vfio_device *core_vdev, loff_t ppos);
 ssize_t vfio_pci_core_read(struct vfio_device *core_vdev, char __user *buf,
 		size_t count, loff_t *ppos);
 ssize_t vfio_pci_core_write(struct vfio_device *core_vdev, const char __user *buf,
diff --git a/include/uapi/linux/vfio.h b/include/uapi/linux/vfio.h
index e41437fa17ad0..ea62d4e72d3bd 100644
--- a/include/uapi/linux/vfio.h
+++ b/include/uapi/linux/vfio.h
@@ -926,12 +926,19 @@ struct vfio_device_feature {
  * be provided the same token as VFIO_DEVICE_FEATURE_PCI_VF_TOKEN provided to
  * the PF.
  *
+ * VFIO_DEVICE_BIND_FLAG_CTRL_ONLY restricts the bound device fd to
+ * control-plane ioctls and non-mappable region read/write access (such as PCI
+ * configuration space), rejecting mmap(), read/write to mmap-supported BARs,
+ * and all other ioctls or device features with -EOPNOTSUPP. This should be used
+ * to prepare the device fd for attachment to guest_memfd.
+ *
  * Return: 0 on success, -errno on failure.
  */
 struct vfio_device_bind_iommufd {
 	__u32		argsz;
 	__u32		flags;
 #define VFIO_DEVICE_BIND_FLAG_TOKEN (1 << 0)
+#define VFIO_DEVICE_BIND_FLAG_CTRL_ONLY (1 << 1)
 	__s32		iommufd;
 	__u32		out_devid;
 	__aligned_u64	token_uuid_ptr;

-- 
2.56.0.455.g6c5a503b38-goog

