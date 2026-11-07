From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:48 -0800
Subject: [PATCH RFC v3 74/88] KVM: selftests: Verify VFIO IRQ info for igb
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-74-8484dde66a7e@google.com>
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
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2686;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=AQWLCgcApEEg/jyplbDhTDq5B3XgkxkLe0iSGXinQCc=;
 b=lzA7mjrnsoNNt6rCSt1o1c7XKjGh/b3RZ9f/ThL79ZgoHIg/TBQHg/cOHoFTJNTQBhv4Maxy/
 eIA9j9nVdKwBg73IhGl+U9b+AJRUyfp6pwsh2i/u1ti2HRsFODVqhyR
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a subtest to verify interrupt capability queries on the bound
Intel 82576 device.

Check that MSI-X reports a positive vector count with eventfd signaling
support, that MSI reports eventfd capability, and that INTx reports
eventfd support along with maskable and auto-masked flags when present.

Testing multiple interrupt types establishes baseline checks on the
underlying device descriptor so that when VFIO resources are later
delegated to or wrapped by guest_memfd, native capability querying on
the device descriptor remains unaffected.
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 48 ++++++++++++++++++++++
 1 file changed, 48 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index c76abe6d45140..6525f392b3930 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -188,4 +188,52 @@ TEST_F(guest_memfd_vfio, get_region_info)
 				    VFIO_REGION_INFO_FLAG_WRITE));
 }
 
+TEST_F(guest_memfd_vfio, get_irq_info)
+{
+	struct vfio_irq_info irq_info = {};
+	int ret;
+
+	/*
+	 * Test MSI-X interrupts (VFIO_PCI_MSIX_IRQ_INDEX):
+	 * Intel 82576 supports up to 10 MSI-X vectors.
+	 */
+	irq_info.argsz = sizeof(irq_info);
+	irq_info.index = VFIO_PCI_MSIX_IRQ_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_IRQ_INFO, &irq_info);
+	ASSERT_EQ(0, ret);
+	ASSERT_GT(irq_info.count, 0);
+	ASSERT_TRUE(irq_info.flags & VFIO_IRQ_INFO_EVENTFD);
+
+	/*
+	 * Test MSI interrupts (VFIO_PCI_MSI_IRQ_INDEX):
+	 * Should report eventfd capability.
+	 */
+	memset(&irq_info, 0, sizeof(irq_info));
+	irq_info.argsz = sizeof(irq_info);
+	irq_info.index = VFIO_PCI_MSI_IRQ_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_IRQ_INFO, &irq_info);
+	ASSERT_EQ(0, ret);
+	ASSERT_GT(irq_info.count, 0);
+	ASSERT_TRUE(irq_info.flags & VFIO_IRQ_INFO_EVENTFD);
+
+	/*
+	 * Test legacy INTx interrupts (VFIO_PCI_INTX_IRQ_INDEX):
+	 * Must support eventfd and masking when present.
+	 */
+	memset(&irq_info, 0, sizeof(irq_info));
+	irq_info.argsz = sizeof(irq_info);
+	irq_info.index = VFIO_PCI_INTX_IRQ_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_IRQ_INFO, &irq_info);
+	ASSERT_EQ(0, ret);
+	ASSERT_LE(irq_info.count, 1);
+	if (irq_info.count == 1) {
+		ASSERT_EQ(VFIO_IRQ_INFO_EVENTFD |
+			  VFIO_IRQ_INFO_MASKABLE |
+			  VFIO_IRQ_INFO_AUTOMASKED,
+			  irq_info.flags & (VFIO_IRQ_INFO_EVENTFD |
+					    VFIO_IRQ_INFO_MASKABLE |
+					    VFIO_IRQ_INFO_AUTOMASKED));
+	}
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

