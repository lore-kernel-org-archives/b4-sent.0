From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:50 -0800
Subject: [PATCH RFC v3 76/88] KVM: selftests: Verify VFIO MMIO mmap access
 for igb device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-76-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2223;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=jzqW1Jjl/TdHDq92R8GBSwh+0N7VE+Z3IfJio0K3a6M=;
 b=f9okZk6tF+33EEc7SQLegmp34Vb1lvk+kZzlENivyzjPi6JteKmB26YWjXUyVF37IjJG8C0Tk
 2GEFDMEETf7AmUmyoLD2UCbk907cEfoHL0cwp4KYGbpDQEbydtcIKgA
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a subtest verifying memory-mapped I/O (mmap) access to BAR0.

Map BAR0 into userspace address space, read the device status register
using a pointer dereference to confirm device responsiveness, and write
and read back a scratch test pattern on RAL0.

This validates that direct CPU page table mappings to device MMIO via
VFIO function properly, establishing an access baseline before wrapping
the BAR inside guest_memfd.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 37 ++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index fa05b7cfb3185..4d5211b6acf79 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -294,4 +294,41 @@ TEST_F(guest_memfd_vfio, bar_rw)
 	ASSERT_EQ(0xdeadbeef, val);
 }
 
+TEST_F(guest_memfd_vfio, bar_mmap)
+{
+	struct vfio_region_info bar0_info = {};
+	uint32_t val;
+	void *bar0;
+	int ret;
+
+	vfio_pci_enable_memory_and_bus_master(_metadata, self->vfio_fd);
+
+	bar0_info.argsz = sizeof(bar0_info);
+	bar0_info.index = VFIO_PCI_BAR0_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &bar0_info);
+	ASSERT_EQ(0, ret);
+	ASSERT_TRUE(bar0_info.flags & VFIO_REGION_INFO_FLAG_MMAP);
+
+	bar0 = mmap(NULL, bar0_info.size, PROT_READ | PROT_WRITE, MAP_SHARED,
+		    self->vfio_fd, bar0_info.offset);
+	ASSERT_NE(MAP_FAILED, bar0);
+
+	/*
+	 * Read Device Status (E1000_STATUS) via mapped pointer. Confirm device
+	 * is readable and does not return 0xFFFFFFFF.
+	 */
+	val = READ_ONCE(*(uint32_t *)((char *)bar0 + E1000_STATUS));
+	ASSERT_NE(0xFFFFFFFF, val);
+
+	/*
+	 * Write a distinct scratch test pattern to RAL0 via mapped pointer and
+	 * read it back.
+	 */
+	WRITE_ONCE(*(uint32_t *)((char *)bar0 + E1000_RAL0), 0xdeadbeef);
+	val = READ_ONCE(*(uint32_t *)((char *)bar0 + E1000_RAL0));
+	ASSERT_EQ(0xdeadbeef, val);
+
+	ASSERT_EQ(0, munmap(bar0, bar0_info.size));
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

