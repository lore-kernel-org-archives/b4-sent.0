From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:55 -0800
Subject: [PATCH RFC v3 81/88] KVM: selftests: Verify guest mapping for VFIO
 BAR
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-81-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=3180;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=m4gF/NigbTTRmt1klBzGGAJYev1gT2d44wz8V7VRpDo=;
 b=zdGRZlDZLizTZQ1sf9kanhtrpiiPGavV3vK3pt5pgWOiRuUUNwCJkOqlBk0Zqm0r0efwGYG8O
 6Zwph+ETe6BAHoQR7qCnY3ys92kB4Rzn66P5rjxM8p+6owCgf2vlFB7
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a test verifying guest execution and stage-2 mapping over a VFIO
device BAR.

Enable PCI memory space decoding on the bound device to allow the fault
handler to insert the PFN into host userspace page tables. Configure the
mapped memory region into a KVM memslot and execute a guest vCPU accessing
the BAR through its page tables.

Verify that the guest executes successfully without memory faults, read
the device status register directly via the guest virtual address, and
verify that the leaf page table entry for the BAR GPA is present.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 57 ++++++++++++++++++++++
 1 file changed, 57 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index 79a0001ca1733..0339794fb6dd3 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -22,6 +22,7 @@
 
 #include "kselftest_harness.h"
 #include "kvm_util.h"
+#include "processor.h"
 
 #define PCI_VENDOR_ID_INTEL 0x8086
 #define PCI_DEVICE_ID_INTEL_82576 0x10C9
@@ -594,4 +595,60 @@ TEST_F(guest_memfd_vfio, host_vma_flags)
 	ASSERT_EQ(0, munmap(bar0_mmap, bar0_info.size));
 }
 
+static void guest_memslot_cacheability_code(uint64_t bar_gpa)
+{
+	uint32_t *reg = (uint32_t *)(bar_gpa + E1000_STATUS);
+	uint32_t val;
+
+	val = READ_ONCE(*reg);
+	GUEST_ASSERT(val != 0xFFFFFFFF);
+
+	GUEST_DONE();
+}
+
+TEST_F(guest_memfd_vfio, guest_mapping)
+{
+	struct vfio_region_info bar0_info = {};
+	uint64_t bar_gpa = 0xc0000000;
+	struct kvm_vcpu *vcpu;
+	void *bar0_mmap;
+	uint64_t *pte;
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
+	/* mmap the VFIO BAR directly into host userspace for memslot config */
+	bar0_mmap = mmap(NULL, bar0_info.size, PROT_READ | PROT_WRITE,
+			 MAP_SHARED, self->bar_fd, bar0_info.offset);
+	ASSERT_NE(MAP_FAILED, bar0_mmap);
+
+	vcpu = vm_vcpu_add(self->vm, 0, guest_memslot_cacheability_code);
+	if (variant->use_gmem)
+		vm_set_user_memory_region2(self->vm, 1, KVM_MEM_GUEST_MEMFD,
+					   bar_gpa, bar0_info.size, bar0_mmap,
+					   self->gmem_fd, bar0_info.offset);
+	else
+		vm_set_user_memory_region(self->vm, 1, 0, bar_gpa,
+					  bar0_info.size, bar0_mmap);
+
+	virt_map(self->vm, bar_gpa, bar_gpa, bar0_info.size >> self->vm->page_shift);
+
+	/* Run guest to fault in the page via stage 2, then verify S2 PTE */
+	vcpu_args_set(vcpu, 1, bar_gpa);
+	vcpu_run(vcpu);
+	ASSERT_EQ(UCALL_DONE, get_ucall(vcpu, NULL));
+
+	pte = vm_get_pte(self->vm, bar_gpa);
+	ASSERT_NE(NULL, pte);
+	ASSERT_TRUE(is_present_pte(&self->vm->mmu, pte));
+
+	ASSERT_EQ(0, munmap(bar0_mmap, bar0_info.size));
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

