From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:51 -0800
Subject: [PATCH RFC v3 77/88] KVM: selftests: Verify VFIO device reset for
 igb device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-77-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2756;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=jIcxaC8x28xPsLi5SMudkDfabTx4GIIOp8BRTMbwoBw=;
 b=22zVgyg/vzsiW0zlhJ3ne60GqMpiyEfDMQk6bsvNnD6uIZt2eSXJ3foj8SNHHIzAaGagwcB/5
 y8itLkPWPqaCVForcElwYW6W+a1qYjsL6jumqYkGxAoeFuJhkUTZucc
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a subtest for VFIO_DEVICE_RESET on the bound Intel 82576 device.

Configure PCI command space to enable memory decode, map BAR0, and write
a distinct test pattern to the scratch receive address low (RAL0) register.

Trigger a device reset via the VFIO device ioctl, handling potential lock
contention with retry logic. Re-enable memory decode post-reset and assert
that the scratch register pattern reverted to its hardware reset value.

This verifies hardware reset lifecycle behavior, establishing a baseline
to later confirm that resetting a device revokes access when BAR0 is
wrapped by guest_memfd.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 45 ++++++++++++++++++++++
 1 file changed, 45 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index 4d5211b6acf79..91cba359e4392 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -331,4 +331,49 @@ TEST_F(guest_memfd_vfio, bar_mmap)
 	ASSERT_EQ(0, munmap(bar0, bar0_info.size));
 }
 
+TEST_F(guest_memfd_vfio, device_reset)
+{
+	struct vfio_region_info bar0_info = {};
+	uint32_t val;
+	void *bar0;
+	int retries = 20;
+	int ret;
+
+	vfio_pci_enable_memory_and_bus_master(_metadata, self->vfio_fd);
+
+	bar0_info.argsz = sizeof(bar0_info);
+	bar0_info.index = VFIO_PCI_BAR0_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &bar0_info);
+	ASSERT_EQ(0, ret);
+
+	bar0 = mmap(NULL, bar0_info.size, PROT_READ | PROT_WRITE, MAP_SHARED,
+		    self->vfio_fd, bar0_info.offset);
+	ASSERT_NE(MAP_FAILED, bar0);
+
+	/* Write scratch test pattern to RAL0 */
+	WRITE_ONCE(*(uint32_t *)((char *)bar0 + E1000_RAL0), 0xdeadbeef);
+	val = READ_ONCE(*(uint32_t *)((char *)bar0 + E1000_RAL0));
+	ASSERT_EQ(0xdeadbeef, val);
+
+	/* Trigger VFIO_DEVICE_RESET, handling possible lock contention (-EAGAIN) */
+	do {
+		ret = ioctl(self->vfio_fd, VFIO_DEVICE_RESET, NULL);
+		if (ret != 0 && errno == EAGAIN)
+			usleep(10000);
+	} while (ret != 0 && errno == EAGAIN && retries-- > 0);
+	ASSERT_EQ(0, ret);
+
+	/*
+	 * After device reset, PCI Command register memory decode is cleared by
+	 * hardware. Re-enable it to access BAR0 registers again.
+	 */
+	vfio_pci_enable_memory_and_bus_master(_metadata, self->vfio_fd);
+
+	/* Verify RAL0 was reset and reverted from scratch pattern */
+	val = READ_ONCE(*(uint32_t *)((char *)bar0 + E1000_RAL0));
+	ASSERT_NE(0xdeadbeef, val);
+
+	ASSERT_EQ(0, munmap(bar0, bar0_info.size));
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

