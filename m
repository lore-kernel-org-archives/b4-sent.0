From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:40 -0800
Subject: [PATCH RFC v3 66/88] vfio: Dispatch guest_memfd lookup_pfn_range
 via vfio_device_ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-66-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2394;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=BBsLRY5/zduXiatMpUbbSqrLV52w59feoL+MHLEuZoM=;
 b=7xcifykO14nQsxFEs8sdU2o2UQh7kl92DT/YVnK7Uryfd0l2oNHeq3Pu9Lenfx7JmCK9mvetu
 SSaH9jUPfbAAsKMHNUCvsSRzAHQMcprqLifHfZLn5oE3OIxXZ9WRwNH
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When scanning guest_memfd memory ranges for confidential architecture
reclaim or conversion, guest_memfd invokes the .lookup_pfn_range
provider operation to locate backed PFN extents or skip unbacked holes
in bulk.

Implement .lookup_pfn_range on vfio_device_gmem_provider_ops to
dispatch to the bus driver's .gmem_lookup_pfn_range callback on struct
vfio_device_ops. Return -EOPNOTSUPP if the bus driver does not define
the callback.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/vfio_main.c | 15 +++++++++++++++
 include/linux/vfio.h     |  2 ++
 2 files changed, 17 insertions(+)

diff --git a/drivers/vfio/vfio_main.c b/drivers/vfio/vfio_main.c
index fd5f71dfc44b7..1c2811848c775 100644
--- a/drivers/vfio/vfio_main.c
+++ b/drivers/vfio/vfio_main.c
@@ -1636,10 +1636,25 @@ static int vfio_device_gmem_check_set_attributes(void *provider, pgoff_t index,
 						      attributes);
 }
 
+static int vfio_device_gmem_lookup_pfn_range(void *provider, pgoff_t index,
+					     unsigned long *pfn,
+					     size_t *nr_pages)
+{
+	struct file *file = provider;
+	struct vfio_device_file *df = file->private_data;
+	struct vfio_device *device = df->device;
+
+	if (!device->ops->gmem_lookup_pfn_range)
+		return -EOPNOTSUPP;
+
+	return device->ops->gmem_lookup_pfn_range(device, index, pfn, nr_pages);
+}
+
 static const struct guest_memfd_provider_operations vfio_device_gmem_provider_ops = {
 	.attach               = vfio_device_gmem_attach,
 	.release              = vfio_device_gmem_release,
 	.get_pfn              = vfio_device_gmem_get_pfn,
+	.lookup_pfn_range     = vfio_device_gmem_lookup_pfn_range,
 	.mmap                 = vfio_device_gmem_mmap,
 	.check_set_attributes = vfio_device_gmem_check_set_attributes,
 };
diff --git a/include/linux/vfio.h b/include/linux/vfio.h
index aade091a91fe8..8022adedc26a6 100644
--- a/include/linux/vfio.h
+++ b/include/linux/vfio.h
@@ -128,6 +128,8 @@ struct vfio_device_ops {
 	int (*gmem_check_set_attributes)(struct vfio_device *device,
 					 pgoff_t index, size_t nr_pages,
 					 u64 attributes);
+	int (*gmem_lookup_pfn_range)(struct vfio_device *device, pgoff_t index,
+				     unsigned long *pfn, size_t *nr_pages);
 	char	*name;
 	int	(*init)(struct vfio_device *vdev);
 	void	(*release)(struct vfio_device *vdev);

-- 
2.56.0.455.g6c5a503b38-goog

