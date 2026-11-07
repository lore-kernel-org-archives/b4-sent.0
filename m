From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:54 -0800
Subject: [PATCH RFC v3 80/88] KVM: selftests: Verify host VMA flags for
 VFIO BAR
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-80-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2687;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=UlabEjEO5/7bc1Xc7qMAcF1rv+8kEYtRG7NVYEhErUE=;
 b=AYnUVtyYbnET239Be/q7ZKR7z0MuG0D/wBLiSNROBy6M+iTcydm/LLxQnKZUtCpZwDkUgkWWx
 NLfenWKq+rzDHvtjBPQsocyULycu+dcV6xLglIVZfDmfMBDwHdFzAaM
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a test verifying host userspace memory mapping characteristics
over a VFIO device BAR.

Map BAR0 of the bound VFIO device into host userspace and parse
/proc/self/smaps to verify that the kernel configured the expected
hardware MMIO VMA flags (io, pf, de).

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 65 ++++++++++++++++++++++
 1 file changed, 65 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index cf2d46a365504..79a0001ca1733 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -529,4 +529,69 @@ TEST_F(guest_memfd_vfio, low_power_bar_revocation)
 	ASSERT_EQ(0, munmap(bar0, bar0_info.size));
 }
 
+
+static void verify_smaps_vm_flags(struct __test_metadata *_metadata,
+				  void *addr, const char *flag_substr)
+{
+	unsigned long vma_start, vma_end;
+	bool found_flag = false;
+	bool in_vma = false;
+	char *line = NULL;
+	size_t size = 0;
+	FILE *file;
+
+	file = fopen("/proc/self/smaps", "r");
+	ASSERT_NE(NULL, file);
+
+	while (getline(&line, &size, file) > 0) {
+		if (sscanf(line, "%lx-%lx", &vma_start, &vma_end) == 2) {
+			if ((unsigned long)addr >= vma_start &&
+			    (unsigned long)addr < vma_end)
+				in_vma = true;
+			else
+				in_vma = false;
+			continue;
+		}
+
+		if (in_vma && !strncmp(line, "VmFlags:", 8)) {
+			if (strstr(line, flag_substr))
+				found_flag = true;
+			break;
+		}
+	}
+
+	free(line);
+	fclose(file);
+
+	ASSERT_TRUE(found_flag);
+}
+
+TEST_F(guest_memfd_vfio, host_vma_flags)
+{
+	struct vfio_region_info bar0_info = {};
+	void *bar0_mmap;
+	int ret;
+
+	bar0_info.argsz = sizeof(bar0_info);
+	bar0_info.index = VFIO_PCI_BAR0_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &bar0_info);
+	ASSERT_EQ(0, ret);
+	ASSERT_TRUE(bar0_info.flags & VFIO_REGION_INFO_FLAG_MMAP);
+
+	/* mmap the VFIO BAR directly into host userspace */
+	bar0_mmap = mmap(NULL, bar0_info.size, PROT_READ | PROT_WRITE,
+			 MAP_SHARED, self->bar_fd, bar0_info.offset);
+	ASSERT_NE(MAP_FAILED, bar0_mmap);
+
+	/*
+	 * Verify host VMA configuration in /proc/self/smaps:
+	 * VFIO MMIO mappings must have io, pf, and de flags set.
+	 */
+	verify_smaps_vm_flags(_metadata, bar0_mmap, "io");
+	verify_smaps_vm_flags(_metadata, bar0_mmap, "pf");
+	verify_smaps_vm_flags(_metadata, bar0_mmap, "de");
+
+	ASSERT_EQ(0, munmap(bar0_mmap, bar0_info.size));
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

