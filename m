From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:58 -0800
Subject: [PATCH RFC v3 84/88] KVM: selftests: Verify memory conversions for
 VFIO BARs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-84-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=3071;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=mn5g/ezQrSRqlCWnN+nnDw5IsR21Pq9gAvdK+Fhz9Qs=;
 b=i70tv0oqLMTnZRiaorGz0DGcWmezkAmqsVWRLymSSoaq0esH9n1mJOUngKhCcFjJnStDZemCf
 0HxnamsoFriCtQi8zwQet6zCIbYdktgo9xCiTYL76eXOLvQvfBusRFi
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a subtest to verify memory attribute conversions on guest_memfd
files backed by a VFIO PCI device.

Verify that memory attribute conversion to private succeeds on
operational register BAR space that does not host an interrupt table.
Verify that converting back to shared also succeeds cleanly.

Verify that converting a BAR that hosts the MSI-X vector table and PBA
to private is rejected with -EINVAL, and that the returned error offset
identifies the start of the invalid range. Host kernel drivers program
MSI-X table entries directly to mask and unmask interrupts, so
converting these pages to private would trigger fatal hardware
protection faults on confidential computing platforms. Verify that
shared conversions on this BAR remain permitted.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 50 ++++++++++++++++++++++
 1 file changed, 50 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index dde249571ebc4..18fab1a39041e 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -764,4 +764,54 @@ TEST_F(guest_memfd_vfio, ioeventfd_creation)
 	close(efd);
 }
 
+TEST_F(guest_memfd_vfio, conversions)
+{
+	struct vfio_region_info bar0_info = {};
+	struct vfio_region_info bar3_info = {};
+	uint64_t err_offset = 0;
+	int ret;
+
+	if (!variant->use_gmem)
+		SKIP(return, "Attribute conversions only apply to guest_memfd");
+
+	bar0_info.argsz = sizeof(bar0_info);
+	bar0_info.index = VFIO_PCI_BAR0_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &bar0_info);
+	ASSERT_EQ(0, ret);
+
+	bar3_info.argsz = sizeof(bar3_info);
+	bar3_info.index = VFIO_PCI_BAR3_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &bar3_info);
+	ASSERT_EQ(0, ret);
+
+	/*
+	 * BAR0 is an operational MMIO register space with no MSI-X table.
+	 * Converting its pages to private should succeed.
+	 */
+	ret = __gmem_set_private(self->gmem_fd, bar0_info.offset,
+				 bar0_info.size, &err_offset);
+	ASSERT_EQ(0, ret);
+
+	/* Converting back to shared should succeed. */
+	ret = __gmem_set_shared(self->gmem_fd, bar0_info.offset,
+				bar0_info.size, &err_offset);
+	ASSERT_EQ(0, ret);
+
+	/*
+	 * BAR3 contains the MSI-X vector table and PBA. Private conversion
+	 * must be rejected by check_set_attributes to prevent host kernel
+	 * writes to interrupt tables from triggering fatal protection faults.
+	 */
+	ret = __gmem_set_private(self->gmem_fd, bar3_info.offset,
+				 bar3_info.size, &err_offset);
+	ASSERT_LT(ret, 0);
+	ASSERT_EQ(EINVAL, errno);
+	ASSERT_EQ(bar3_info.offset, err_offset);
+
+	/* Shared conversion on BAR3 should be permitted. */
+	ret = __gmem_set_shared(self->gmem_fd, bar3_info.offset,
+				bar3_info.size, &err_offset);
+	ASSERT_EQ(0, ret);
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

