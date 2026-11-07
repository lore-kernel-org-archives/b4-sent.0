From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:29 -0800
Subject: [PATCH RFC v3 55/88] vfio: Track device file access mode with an
 enum
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-55-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=5176;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=OPzfI8FY9YTnY7U//Qo2HO1R07AW0TxEMrDt75CQipU=;
 b=yxGBfLn330m/QlZKxV56D9+INpmu/vb92BX3fIJN1BHK07X4RoQNHQmNHqFgxcPEyc9f3OrFI
 TITTtiAfEvkBiWVgqH/0/MljlVFSh1dt4fWyaeiRAMfq00Gn4JmxuQ3
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Device file operations currently track whether access has been granted
using a boolean flag, assuming that binding a device always unlocks both
control-plane operations and direct region access simultaneously.

Upcoming support for control-only device bindings requires distinguishing
unbound descriptors from descriptors bound with restricted vs. full
access, without introducing multiple flags that could get out of sync or
represent invalid combinations under lockless release-acquire ordering.

Replace the boolean flag with an enum representing the access mode so
that the entire access state continues to be published and read as a
single release-acquire value.

No functional change intended.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/device_cdev.c | 8 ++++----
 drivers/vfio/group.c       | 2 +-
 drivers/vfio/vfio.h        | 7 ++++++-
 drivers/vfio/vfio_main.c   | 8 ++++----
 4 files changed, 15 insertions(+), 10 deletions(-)

diff --git a/drivers/vfio/device_cdev.c b/drivers/vfio/device_cdev.c
index c1c26d7a9aec9..19be3947fc74a 100644
--- a/drivers/vfio/device_cdev.c
+++ b/drivers/vfio/device_cdev.c
@@ -125,7 +125,7 @@ long vfio_df_ioctl_bind_iommufd(struct vfio_device_file *df,
 
 	mutex_lock(&device->dev_set->lock);
 	/* one device cannot be bound twice */
-	if (df->access_granted) {
+	if (df->access_mode != VFIO_DF_ACCESS_NONE) {
 		ret = -EINVAL;
 		goto out_unlock;
 	}
@@ -163,7 +163,7 @@ long vfio_df_ioctl_bind_iommufd(struct vfio_device_file *df,
 	 * Paired with smp_load_acquire() in vfio_device_fops::ioctl/
 	 * read/write/mmap
 	 */
-	smp_store_release(&df->access_granted, true);
+	smp_store_release(&df->access_mode, VFIO_DF_ACCESS_FULL);
 	mutex_unlock(&device->dev_set->lock);
 	return 0;
 
@@ -185,10 +185,10 @@ void vfio_df_unbind_iommufd(struct vfio_device_file *df)
 
 	/*
 	 * In the time of close, there is no contention with another one
-	 * changing this flag.  So read df->access_granted without lock
+	 * changing this mode.  So read df->access_mode without lock
 	 * and no smp_load_acquire() is ok.
 	 */
-	if (!df->access_granted)
+	if (df->access_mode == VFIO_DF_ACCESS_NONE)
 		return;
 
 	mutex_lock(&device->dev_set->lock);
diff --git a/drivers/vfio/group.c b/drivers/vfio/group.c
index 185f359f75d38..0a33e0e025bd8 100644
--- a/drivers/vfio/group.c
+++ b/drivers/vfio/group.c
@@ -217,7 +217,7 @@ static int vfio_df_group_open(struct vfio_device_file *df)
 	 * Paired with smp_load_acquire() in vfio_device_fops::ioctl/
 	 * read/write/mmap and vfio_file_has_device_access()
 	 */
-	smp_store_release(&df->access_granted, true);
+	smp_store_release(&df->access_mode, VFIO_DF_ACCESS_FULL);
 
 	mutex_unlock(&device->dev_set->lock);
 	mutex_unlock(&device->group->group_lock);
diff --git a/drivers/vfio/vfio.h b/drivers/vfio/vfio.h
index 2eeb526a8da58..af2b8158b40c0 100644
--- a/drivers/vfio/vfio.h
+++ b/drivers/vfio/vfio.h
@@ -16,11 +16,16 @@ struct iommufd_ctx;
 struct iommu_group;
 struct vfio_container;
 
+enum vfio_df_access_mode {
+	VFIO_DF_ACCESS_NONE = 0,
+	VFIO_DF_ACCESS_FULL,
+};
+
 struct vfio_device_file {
 	struct vfio_device *device;
 	struct vfio_group *group;
 
-	u8 access_granted;
+	enum vfio_df_access_mode access_mode;
 	u32 devid; /* only valid when iommufd is valid */
 	spinlock_t kvm_ref_lock; /* protect kvm field */
 	struct file *kvm;
diff --git a/drivers/vfio/vfio_main.c b/drivers/vfio/vfio_main.c
index ea8e6cc13c457..fe126e137d5ca 100644
--- a/drivers/vfio/vfio_main.c
+++ b/drivers/vfio/vfio_main.c
@@ -1349,7 +1349,7 @@ static long vfio_device_fops_unl_ioctl(struct file *filep,
 		return vfio_df_ioctl_bind_iommufd(df, uptr);
 
 	/* Paired with smp_store_release() following vfio_df_open() */
-	if (!smp_load_acquire(&df->access_granted))
+	if (smp_load_acquire(&df->access_mode) == VFIO_DF_ACCESS_NONE)
 		return -EINVAL;
 
 	ret = vfio_device_pm_runtime_get(device);
@@ -1397,7 +1397,7 @@ static ssize_t vfio_device_fops_read(struct file *filep, char __user *buf,
 	struct vfio_device *device = df->device;
 
 	/* Paired with smp_store_release() following vfio_df_open() */
-	if (!smp_load_acquire(&df->access_granted))
+	if (smp_load_acquire(&df->access_mode) == VFIO_DF_ACCESS_NONE)
 		return -EINVAL;
 
 	if (unlikely(!device->ops->read))
@@ -1414,7 +1414,7 @@ static ssize_t vfio_device_fops_write(struct file *filep,
 	struct vfio_device *device = df->device;
 
 	/* Paired with smp_store_release() following vfio_df_open() */
-	if (!smp_load_acquire(&df->access_granted))
+	if (smp_load_acquire(&df->access_mode) == VFIO_DF_ACCESS_NONE)
 		return -EINVAL;
 
 	if (unlikely(!device->ops->write))
@@ -1429,7 +1429,7 @@ static int vfio_device_fops_mmap(struct file *filep, struct vm_area_struct *vma)
 	struct vfio_device *device = df->device;
 
 	/* Paired with smp_store_release() following vfio_df_open() */
-	if (!smp_load_acquire(&df->access_granted))
+	if (smp_load_acquire(&df->access_mode) == VFIO_DF_ACCESS_NONE)
 		return -EINVAL;
 
 	if (unlikely(!device->ops->mmap))

-- 
2.56.0.455.g6c5a503b38-goog

