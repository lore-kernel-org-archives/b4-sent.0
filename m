From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:47 -0800
Subject: [PATCH RFC v3 73/88] KVM: selftests: Verify VFIO region info for
 igb device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-73-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2549;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=mrWvs6FF7l4LpcTEng8nbYIsnoTAo2jJxDhGuJ9QU+g=;
 b=wY395FIuwjLW/oJNaiS8f/FOkSCxKWTmBujK/E4H3vKhDyLPEibe2RUJEOyL3f7zZZ6SQEXMe
 pVDqo0rakbqDQ8XO4K1/+VBsAUIcnImILMrQ/YDvpu/qskpIqC2kMNB
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a subtest for VFIO region info queries on the bound device.

Verify that the operational register MMIO space (128 KiB), MSI-X table
and PBA space (16 KiB), and extended PCIe configuration space (4096 bytes)
report their exact sizes and expected access capability flags.

Testing multiple regions establishes baseline checks on the underlying
device descriptor so that when VFIO BARs are later delegated to or wrapped
by guest_memfd, native region querying on the device descriptor is
confirmed to remain unaffected.
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 38 ++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index 669acc6058b5b..c76abe6d45140 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -150,4 +150,42 @@ TEST_F(guest_memfd_vfio, get_device_info)
 	ASSERT_GT(dev_info.num_irqs, 0);
 }
 
+TEST_F(guest_memfd_vfio, get_region_info)
+{
+	struct vfio_region_info reg_info = {};
+	int ret;
+
+	/* Test BAR0: 128 KiB MMIO register space */
+	reg_info.argsz = sizeof(reg_info);
+	reg_info.index = VFIO_PCI_BAR0_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &reg_info);
+	ASSERT_EQ(0, ret);
+	ASSERT_EQ(0x20000, reg_info.size);
+	ASSERT_EQ(VFIO_REGION_INFO_FLAG_READ |
+		  VFIO_REGION_INFO_FLAG_WRITE |
+		  VFIO_REGION_INFO_FLAG_MMAP,
+		  reg_info.flags & (VFIO_REGION_INFO_FLAG_READ |
+				    VFIO_REGION_INFO_FLAG_WRITE |
+				    VFIO_REGION_INFO_FLAG_MMAP));
+
+	/* Test BAR3: 16 KiB MSI-X table and PBA */
+	memset(&reg_info, 0, sizeof(reg_info));
+	reg_info.argsz = sizeof(reg_info);
+	reg_info.index = VFIO_PCI_BAR3_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &reg_info);
+	ASSERT_EQ(0, ret);
+	ASSERT_EQ(0x4000, reg_info.size);
+
+	/* Test PCIe Config Space: 4096 bytes extended config */
+	memset(&reg_info, 0, sizeof(reg_info));
+	reg_info.argsz = sizeof(reg_info);
+	reg_info.index = VFIO_PCI_CONFIG_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &reg_info);
+	ASSERT_EQ(0, ret);
+	ASSERT_EQ(PCI_CFG_SPACE_EXP_SIZE, reg_info.size);
+	ASSERT_EQ(VFIO_REGION_INFO_FLAG_READ | VFIO_REGION_INFO_FLAG_WRITE,
+		  reg_info.flags & (VFIO_REGION_INFO_FLAG_READ |
+				    VFIO_REGION_INFO_FLAG_WRITE));
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

