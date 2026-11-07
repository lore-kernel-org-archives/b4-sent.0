From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:36 -0800
Subject: [PATCH RFC v3 62/88] vfio: Dispatch guest_memfd
 check_set_attributes via vfio_device_ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-62-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2646;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=/6avTRCqI4M8/ALHbbIFehsJKaQvoBf+svzx5j3iq8o=;
 b=A/0h+r+KSCP4fQo2hcBDtiJJa5JKzY648tnHJ16FNMD3MSKRsvEZ8EZGzK1oxHVIF1ZwPtJO+
 DRSFyeeW6yzBnvH8OVDGq4XMpFSwBUDkTeKVElbM8BqKXtFQu6mFHma
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When userspace requests attribute conversion on a guest_memfd file
backed by a VFIO resource descriptor, guest_memfd invokes the
.check_set_attributes provider operation under the exclusive filemap
invalidation lock before committing attribute changes.

Implement .check_set_attributes on vfio_device_gmem_provider_ops to
dispatch to the bus driver's .gmem_check_set_attributes callback on
struct vfio_device_ops if implemented, allowing the driver to inspect
and validate the requested attributes and offset range.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/vfio_main.c | 24 ++++++++++++++++++++----
 include/linux/vfio.h     |  3 +++
 2 files changed, 23 insertions(+), 4 deletions(-)

diff --git a/drivers/vfio/vfio_main.c b/drivers/vfio/vfio_main.c
index 979ed69c5ebf7..e4e7bfe77d03b 100644
--- a/drivers/vfio/vfio_main.c
+++ b/drivers/vfio/vfio_main.c
@@ -1621,11 +1621,27 @@ static int vfio_device_gmem_mmap(void *provider, struct vm_area_struct *vma)
 	return vfio_device_mmap(df->device, vma);
 }
 
+static int vfio_device_gmem_check_set_attributes(void *provider, pgoff_t index,
+						 size_t nr_pages,
+						 u64 attributes)
+{
+	struct file *file = provider;
+	struct vfio_device_file *df = file->private_data;
+	struct vfio_device *device = df->device;
+
+	if (!device->ops->gmem_check_set_attributes)
+		return 0;
+
+	return device->ops->gmem_check_set_attributes(device, index, nr_pages,
+						      attributes);
+}
+
 static const struct guest_memfd_provider_operations vfio_device_gmem_provider_ops = {
-	.attach  = vfio_device_gmem_attach,
-	.release = vfio_device_gmem_release,
-	.get_pfn = vfio_device_gmem_get_pfn,
-	.mmap    = vfio_device_gmem_mmap,
+	.attach               = vfio_device_gmem_attach,
+	.release              = vfio_device_gmem_release,
+	.get_pfn              = vfio_device_gmem_get_pfn,
+	.mmap                 = vfio_device_gmem_mmap,
+	.check_set_attributes = vfio_device_gmem_check_set_attributes,
 };
 #endif
 
diff --git a/include/linux/vfio.h b/include/linux/vfio.h
index 51e04b980a381..ffb01e655735f 100644
--- a/include/linux/vfio.h
+++ b/include/linux/vfio.h
@@ -125,6 +125,9 @@ struct vfio_device_ops {
 	int (*gmem_get_pfn)(struct vfio_device *device, pgoff_t index,
 			    unsigned long *pfn, int *max_order,
 			    u64 *pfn_attrs);
+	int (*gmem_check_set_attributes)(struct vfio_device *device,
+					 pgoff_t index, size_t nr_pages,
+					 u64 attributes);
 	char	*name;
 	int	(*init)(struct vfio_device *vdev);
 	void	(*release)(struct vfio_device *vdev);

-- 
2.56.0.455.g6c5a503b38-goog

