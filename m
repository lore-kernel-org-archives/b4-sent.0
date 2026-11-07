From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:49 -0800
Subject: [PATCH RFC v3 75/88] KVM: selftests: Verify VFIO MMIO read and
 write for igb device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-75-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=3042;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=3rXXPklnl0jKOPE29y7ipXm7LsNh6MGUlvgjiF//KXQ=;
 b=xloQFGBoKJ2DqV21AvqSu5E1J/CpqtQbloSW0T3GvaqdUgvm8xoOH8M0ztGaadapQ2nhxCakj
 IhodY//gGI6CJqHf9PiPv1GyWySREMT+8pDpBuxA/6S9HQ3zZS/kyLY
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a subtest verifying direct pread() and pwrite() operations on the
device descriptor targeting BAR0 MMIO space.

Enable memory decoding in the PCI Command register, verify that reading
the device status register returns an accessible value, and verify that
writing and reading back a scratch MAC register (RAL0) succeeds with
expected data.

This validates that kernel-mediated MMIO operations over the VFIO device
descriptor function properly, providing a baseline to compare against
when guest_memfd wraps the BAR.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 58 ++++++++++++++++++++++
 1 file changed, 58 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index 6525f392b3930..fa05b7cfb3185 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -236,4 +236,62 @@ TEST_F(guest_memfd_vfio, get_irq_info)
 	}
 }
 
+static void vfio_pci_enable_memory_and_bus_master(struct __test_metadata *_metadata,
+						  int vfio_fd)
+{
+	struct vfio_region_info cfg_info = {};
+	ssize_t ret_bytes;
+	uint16_t cmd;
+	int ret;
+
+	cfg_info.argsz = sizeof(cfg_info);
+	cfg_info.index = VFIO_PCI_CONFIG_REGION_INDEX;
+	ret = ioctl(vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &cfg_info);
+	ASSERT_EQ(0, ret);
+
+	/* Enable Memory Space and Bus Master in PCI Command register */
+	ret_bytes = pread(vfio_fd, &cmd, sizeof(cmd), cfg_info.offset + PCI_COMMAND);
+	ASSERT_EQ(sizeof(cmd), ret_bytes);
+	cmd |= (PCI_COMMAND_MEMORY | PCI_COMMAND_MASTER);
+	ret_bytes = pwrite(vfio_fd, &cmd, sizeof(cmd), cfg_info.offset + PCI_COMMAND);
+	ASSERT_EQ(sizeof(cmd), ret_bytes);
+}
+
+TEST_F(guest_memfd_vfio, bar_rw)
+{
+	struct vfio_region_info bar0_info = {};
+	ssize_t ret_bytes;
+	uint32_t val;
+	int ret;
+
+	vfio_pci_enable_memory_and_bus_master(_metadata, self->vfio_fd);
+
+	bar0_info.argsz = sizeof(bar0_info);
+	bar0_info.index = VFIO_PCI_BAR0_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &bar0_info);
+	ASSERT_EQ(0, ret);
+
+	/*
+	 * Read Device Status (E1000_STATUS) via pread() at BAR0 offset.
+	 * Confirm device is readable and does not return 0xFFFFFFFF.
+	 */
+	val = 0;
+	ret_bytes = pread(self->vfio_fd, &val, sizeof(val), bar0_info.offset + E1000_STATUS);
+	ASSERT_EQ(sizeof(val), ret_bytes);
+	ASSERT_NE(0xFFFFFFFF, val);
+
+	/*
+	 * Write a distinct scratch test pattern to RAL0 via pwrite() and read
+	 * it back via pread().
+	 */
+	val = 0xdeadbeef;
+	ret_bytes = pwrite(self->vfio_fd, &val, sizeof(val), bar0_info.offset + E1000_RAL0);
+	ASSERT_EQ(sizeof(val), ret_bytes);
+
+	val = 0;
+	ret_bytes = pread(self->vfio_fd, &val, sizeof(val), bar0_info.offset + E1000_RAL0);
+	ASSERT_EQ(sizeof(val), ret_bytes);
+	ASSERT_EQ(0xdeadbeef, val);
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

