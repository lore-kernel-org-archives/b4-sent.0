From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:56 -0800
Subject: [PATCH RFC v3 82/88] KVM: selftests: Verify VFIO dmabuf creation
 for igb device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-82-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=3911;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=MbD33+QhDIw1sC8OkTEtVrBZ+IoL3RD4qfhKhPg8oKQ=;
 b=7iVZ9xRpmIAg6xpTbf7wls4Z/04O441wO1Vwt3NgTl0XIJAE2iswEYKcjFie8IMkCRGxXqAKQ
 8/ywYYSClSZASYJSFTxZ80gUqe3p+BNGG16CJqQEWTaXedsT8K4Umdm
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a subtest to verify dmabuf export via VFIO_DEVICE_FEATURE_DMA_BUF.

Probe device feature support using VFIO_DEVICE_FEATURE_PROBE, skipping
the test cleanly when kernel dmabuf support is absent
(CONFIG_VFIO_PCI_DMABUF or CONFIG_PCI_P2PDMA disabled).

Allocate and configure a vfio_device_feature request covering BAR0,
requesting a dma_buf file descriptor export via
VFIO_DEVICE_FEATURE_GET.

Verify that in direct mode a valid file descriptor is returned, confirm
that attempting to mmap the resulting dmabuf fd fails with -EINVAL (as
VFIO PCI dmabufs provide peer-to-peer kernel DMA rather than userspace
CPU mappings), and verify clean closure and resource release.
In guest_memfd mode, verify that dmabuf creation is rejected with
-EOPNOTSUPP.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 74 ++++++++++++++++++++++
 1 file changed, 74 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index 0339794fb6dd3..46d325228bda3 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -651,4 +651,78 @@ TEST_F(guest_memfd_vfio, guest_mapping)
 	ASSERT_EQ(0, munmap(bar0_mmap, bar0_info.size));
 }
 
+TEST_F(guest_memfd_vfio, dmabuf_creation)
+{
+	struct vfio_device_feature_dma_buf *dmabuf_feature;
+	struct vfio_device_feature probe_feat = {};
+	struct vfio_region_info bar0_info = {};
+	struct vfio_device_feature *feat;
+	size_t feat_size;
+	int dmabuf_fd;
+	int ret;
+
+	/*
+	 * Probe support for VFIO_DEVICE_FEATURE_DMA_BUF. This requires kernel
+	 * support for CONFIG_VFIO_PCI_DMABUF (CONFIG_PCI_P2PDMA). In guest_memfd
+	 * mode, VFIO_DEVICE_BIND_FLAG_CTRL_ONLY is active, so the probe itself
+	 * is rejected with -EOPNOTSUPP by the control-only allowlist.
+	 */
+	probe_feat.argsz = sizeof(probe_feat);
+	probe_feat.flags = VFIO_DEVICE_FEATURE_PROBE |
+			   VFIO_DEVICE_FEATURE_GET |
+			   VFIO_DEVICE_FEATURE_DMA_BUF;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_FEATURE, &probe_feat);
+	if (variant->use_gmem) {
+		ASSERT_LT(ret, 0);
+		ASSERT_EQ(EOPNOTSUPP, errno);
+	} else if (ret != 0) {
+		SKIP(return, "Kernel lacks CONFIG_VFIO_PCI_DMABUF support\n");
+	}
+
+	bar0_info.argsz = sizeof(bar0_info);
+	bar0_info.index = VFIO_PCI_BAR0_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &bar0_info);
+	ASSERT_EQ(0, ret);
+
+	/*
+	 * Allocate vfio_device_feature with trailing vfio_device_feature_dma_buf
+	 * containing one dma_range covering BAR0.
+	 */
+	feat_size = sizeof(*feat) + sizeof(*dmabuf_feature) +
+		    sizeof(struct vfio_region_dma_range);
+	feat = calloc(1, feat_size);
+	ASSERT_NE(NULL, feat);
+
+	feat->argsz = feat_size;
+	feat->flags = VFIO_DEVICE_FEATURE_GET | VFIO_DEVICE_FEATURE_DMA_BUF;
+
+	dmabuf_feature = (struct vfio_device_feature_dma_buf *)feat->data;
+	dmabuf_feature->region_index = VFIO_PCI_BAR0_REGION_INDEX;
+	dmabuf_feature->open_flags = O_RDWR | O_CLOEXEC;
+	dmabuf_feature->nr_ranges = 1;
+	dmabuf_feature->dma_ranges[0].offset = 0;
+	dmabuf_feature->dma_ranges[0].length = bar0_info.size;
+
+	dmabuf_fd = ioctl(self->vfio_fd, VFIO_DEVICE_FEATURE, feat);
+	if (variant->use_gmem) {
+		ASSERT_LT(dmabuf_fd, 0);
+		ASSERT_EQ(EOPNOTSUPP, errno);
+	} else {
+		ASSERT_GE(dmabuf_fd, 0);
+
+		/*
+		 * VFIO PCI dmabufs are intended for peer-to-peer kernel DMA and
+		 * do not implement mmap or read operations. Verify mmap returns
+		 * -EINVAL.
+		 */
+		ASSERT_EQ(MAP_FAILED, mmap(NULL, bar0_info.size,
+					   PROT_READ | PROT_WRITE,
+					   MAP_SHARED, dmabuf_fd, 0));
+		ASSERT_EQ(EINVAL, errno);
+		close(dmabuf_fd);
+	}
+
+	free(feat);
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

