From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:59 -0800
Subject: [PATCH RFC v3 85/88] KVM: selftests: Verify shared and private
 mmap access for VFIO BARs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-85-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=5917;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=yUySByGqxzqT+Oxfxi3dJk8aiTpxLOKEtbuq/Vzm03I=;
 b=VqBOv4KmhHTpFhYWjDlROlLzM9MRdZp2uwmZyBVP69w5BMEFrucxqf7UGKtcrD4c4NU99K12n
 wWDeO9xZmwvCEAtS9rYITeg/7NOxvTnZdLrUEPPNtklmStGGeLHfVew
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a subtest to verify read and write access to VFIO device BAR memory
mmap-ed via guest_memfd across shared and private states from both host
and guest perspectives.

Map an operational device BAR (BAR0) through guest_memfd and configure
it into a KVM memslot for a software-protected VM.

In shared state, verify that host userspace reads the device status
register and performs read-write verification on the scratch receive
address low register (RAL0). Add and initialize the guest vCPU with
a guest loop synchronized via GUEST_SYNC to perform read and write
operations over the BAR GPA and confirm that changes made by the guest
are visible to the host.

Convert the BAR memory to private. Verify that host userspace reads and
writes to the mmap-ed region are blocked and trigger SIGBUS, as
unmediated host access to private memory is disallowed. Verify that the
guest vCPU continues to have full read and write access to the private
BAR registers without exiting.

Convert the BAR memory back to shared. Verify that host userspace
access is restored, that host reads observe updates made by the guest
while private, and that guest operations continue normally.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 130 +++++++++++++++++++++
 1 file changed, 130 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index 18fab1a39041e..a520cf45fccb8 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -814,4 +814,134 @@ TEST_F(guest_memfd_vfio, conversions)
 	ASSERT_EQ(0, ret);
 }
 
+static uint32_t guest_write_val;
+
+static void guest_rw_test_code(uint64_t bar_gpa)
+{
+	uint32_t *ral0 = (uint32_t *)(bar_gpa + E1000_RAL0);
+	uint32_t *status = (uint32_t *)(bar_gpa + E1000_STATUS);
+	uint32_t val;
+
+	for (;;) {
+		uint32_t write_val = READ_ONCE(guest_write_val);
+
+		/* Read read-only device STATUS register */
+		val = READ_ONCE(*status);
+		GUEST_ASSERT(val != 0xFFFFFFFF);
+
+		/* Write and read-back read-write RAL0 register */
+		WRITE_ONCE(*ral0, write_val);
+		val = READ_ONCE(*ral0);
+		GUEST_ASSERT_EQ(val, write_val);
+
+		GUEST_SYNC(0);
+	}
+}
+
+TEST_F(guest_memfd_vfio, mmap_shared_private_rw)
+{
+	struct vfio_region_info bar0_info = {};
+	uint64_t bar_gpa = 0xc0000000;
+	struct kvm_vcpu *vcpu;
+	void *bar0_mmap;
+	uint32_t *h_ral0;
+	uint32_t *h_status;
+	uint32_t val;
+	int ret;
+
+	if (!variant->use_gmem)
+		SKIP(return, "Shared and private attribute rw test only applies to guest_memfd");
+
+	vfio_pci_enable_memory_and_bus_master(_metadata, self->vfio_fd);
+
+	bar0_info.argsz = sizeof(bar0_info);
+	bar0_info.index = VFIO_PCI_BAR0_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &bar0_info);
+	ASSERT_EQ(0, ret);
+	ASSERT_TRUE(bar0_info.flags & VFIO_REGION_INFO_FLAG_MMAP);
+
+	/* mmap the VFIO BAR through guest_memfd descriptor */
+	bar0_mmap = mmap(NULL, bar0_info.size, PROT_READ | PROT_WRITE,
+			 MAP_SHARED, self->bar_fd, bar0_info.offset);
+	ASSERT_NE(MAP_FAILED, bar0_mmap);
+
+	h_status = (uint32_t *)((uintptr_t)bar0_mmap + E1000_STATUS);
+	h_ral0 = (uint32_t *)((uintptr_t)bar0_mmap + E1000_RAL0);
+
+	/* Configure KVM guest memslot backed by guest_memfd */
+	vcpu = vm_vcpu_add(self->vm, 0, guest_rw_test_code);
+	vm_set_user_memory_region2(self->vm, 1, KVM_MEM_GUEST_MEMFD,
+				   bar_gpa, bar0_info.size, bar0_mmap,
+				   self->gmem_fd, bar0_info.offset);
+	virt_map(self->vm, bar_gpa, bar_gpa, bar0_info.size >> self->vm->page_shift);
+
+	/*
+	 * Phase 1: Shared memory access from Host and Guest.
+	 * Initially, the entire guest_memfd resource is shared.
+	 */
+	/* Host read from STATUS and write/read-back to RAL0 */
+	val = READ_ONCE(*h_status);
+	ASSERT_NE(0xFFFFFFFF, val);
+	WRITE_ONCE(*h_ral0, 0x11223344);
+	val = READ_ONCE(*h_ral0);
+	ASSERT_EQ(0x11223344, val);
+
+	/* Guest read/write to shared BAR memory */
+	vcpu_args_set(vcpu, 1, bar_gpa);
+	guest_write_val = 0xaabbccdd;
+	sync_global_to_guest(self->vm, guest_write_val);
+	vcpu_run(vcpu);
+	ASSERT_EQ(UCALL_SYNC, get_ucall(vcpu, NULL));
+
+	/* Verify host sees the value written by guest in shared mode */
+	val = READ_ONCE(*h_ral0);
+	ASSERT_EQ(0xaabbccdd, val);
+
+	/*
+	 * Phase 2: Convert BAR0 memory to Private.
+	 */
+	gmem_set_private(self->gmem_fd, bar0_info.offset, bar0_info.size);
+
+	/*
+	 * Host accesses to private guest_memfd memory must fail with SIGBUS.
+	 */
+	TEST_EXPECT_SIGBUS((void)READ_ONCE(*h_status));
+	TEST_EXPECT_SIGBUS(WRITE_ONCE(*h_ral0, 0x12345678));
+
+	/*
+	 * Guest read and write access to private BAR memory must succeed.
+	 */
+	guest_write_val = 0x55667788;
+	sync_global_to_guest(self->vm, guest_write_val);
+	vcpu_run(vcpu);
+	ASSERT_EQ(UCALL_SYNC, get_ucall(vcpu, NULL));
+
+	/*
+	 * Phase 3: Convert BAR0 memory back to Shared.
+	 */
+	gmem_set_shared(self->gmem_fd, bar0_info.offset, bar0_info.size);
+
+	/* Host read/write access must now succeed again */
+	val = READ_ONCE(*h_status);
+	ASSERT_NE(0xFFFFFFFF, val);
+	/* Host sees the value written by the guest while private */
+	val = READ_ONCE(*h_ral0);
+	ASSERT_EQ(0x55667788, val);
+
+	WRITE_ONCE(*h_ral0, 0x99aabbcc);
+	val = READ_ONCE(*h_ral0);
+	ASSERT_EQ(0x99aabbcc, val);
+
+	/* Guest read/write access continues to succeed in shared mode */
+	guest_write_val = 0xdeedbeef;
+	sync_global_to_guest(self->vm, guest_write_val);
+	vcpu_run(vcpu);
+	ASSERT_EQ(UCALL_SYNC, get_ucall(vcpu, NULL));
+
+	val = READ_ONCE(*h_ral0);
+	ASSERT_EQ(0xdeedbeef, val);
+
+	ASSERT_EQ(0, munmap(bar0_mmap, bar0_info.size));
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

