From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:38 -0800
Subject: [PATCH RFC v3 64/88] vfio: Add vfio_device_gmem_revoke helper for
 guest_memfd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-64-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2301;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=6gfs4j8uCHpXnOLsBDGwfvIT0AGOBGHhi3wjtxG21zs=;
 b=2H/FjEoqaNY0u61FutI/xynBHktbS1ilj9Dq898KbDy8/638MzV06rs1q4/10qrHH8jGsnUXo
 LfFX9u/SduFC73ybrCdDYFQJgPwbpocGEFiTpmQbgpzVeqgnbOtQGrB
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When physical device regions backing guest_memfd memory must be revoked
due to hardware reset, power state transitions, or memory decode state
changes, the bus driver must revoke and reclaim the memory ranges from
guest_memfd before modifying hardware state.

Add a vfio_device_gmem_revoke() helper in VFIO core that queries whether
the device is attached to a guest_memfd instance and invokes
kvm_gmem_revoke() with the specified range and physical frame address.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 drivers/vfio/vfio_main.c | 10 ++++++++++
 include/linux/vfio.h     | 12 ++++++++++++
 2 files changed, 22 insertions(+)

diff --git a/drivers/vfio/vfio_main.c b/drivers/vfio/vfio_main.c
index e4e7bfe77d03b..fd5f71dfc44b7 100644
--- a/drivers/vfio/vfio_main.c
+++ b/drivers/vfio/vfio_main.c
@@ -1643,6 +1643,16 @@ static const struct guest_memfd_provider_operations vfio_device_gmem_provider_op
 	.mmap                 = vfio_device_gmem_mmap,
 	.check_set_attributes = vfio_device_gmem_check_set_attributes,
 };
+
+int vfio_device_gmem_revoke(struct vfio_device *device, pgoff_t start,
+			    size_t nr_pages, const unsigned long *pfn)
+{
+	if (!device->gmem_inode)
+		return 0;
+
+	return kvm_gmem_revoke(device->gmem_inode, start, nr_pages, pfn);
+}
+EXPORT_SYMBOL_GPL(vfio_device_gmem_revoke);
 #endif
 
 const struct file_operations vfio_device_fops = {
diff --git a/include/linux/vfio.h b/include/linux/vfio.h
index ffb01e655735f..aade091a91fe8 100644
--- a/include/linux/vfio.h
+++ b/include/linux/vfio.h
@@ -394,6 +394,18 @@ bool vfio_file_is_valid(struct file *file);
 bool vfio_file_enforced_coherent(struct file *file);
 void vfio_file_set_kvm(struct file *vfio_file, struct file *kvm);
 
+#ifdef CONFIG_KVM_GUEST_MEMFD
+int vfio_device_gmem_revoke(struct vfio_device *device, pgoff_t start,
+			    size_t nr_pages, const unsigned long *pfn);
+#else
+static inline int vfio_device_gmem_revoke(struct vfio_device *device,
+					  pgoff_t start, size_t nr_pages,
+					  const unsigned long *pfn)
+{
+	return -EOPNOTSUPP;
+}
+#endif
+
 #define VFIO_PIN_PAGES_MAX_ENTRIES	(PAGE_SIZE/sizeof(unsigned long))
 
 int vfio_pin_pages(struct vfio_device *device, dma_addr_t iova,

-- 
2.56.0.455.g6c5a503b38-goog

