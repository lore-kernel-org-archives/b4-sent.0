From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:53 -0800
Subject: [PATCH RFC v3 79/88] KVM: selftests: Verify BAR revocation and
 access gating in low power state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-79-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=4274;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=HXOqCEcn1wMNNgFV4ufgWpq3HP3d5KMTONODuY/LkjQ=;
 b=hfJIou2E40cEogfjGxqpPpOHJzj8+eMJz0hE+mUJsmyO3SWxtyR789XZaiT8+HTKnEdUzJ2If
 Q0v4pcLysRCBmrNVjh3IoBZrnVwu9QVRWFtl+wJj7s9Fai6Pwzf069q
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a device transitions to low power state (D3hot), physical BAR
access is invalidated. The kernel revokes existing memory mappings and
marks the BARs unavailable.

Add a subtest to verify BAR revocation upon entering low power state.
Populate BAR0 mappings, write a test pattern, and enter low power mode.
Confirm that host mmap access to the revoked region raises SIGBUS and
that pread and pwrite on the BAR descriptor fail with -EIO while in low
power mode.

Exit low power state back to D0 and confirm that host mmap access and
pread/pwrite operations are restored and succeed again.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 86 ++++++++++++++++++++++
 1 file changed, 86 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index 03c324f7f618d..cf2d46a365504 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -443,4 +443,90 @@ TEST_F(guest_memfd_vfio, device_reset)
 	ASSERT_EQ(0, munmap(bar0, bar0_info.size));
 }
 
+TEST_F(guest_memfd_vfio, low_power_bar_revocation)
+{
+	struct vfio_device_feature feat = {};
+	struct vfio_region_info bar0_info = {};
+	ssize_t ret_bytes;
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
+		    self->bar_fd, bar0_info.offset);
+	ASSERT_NE(MAP_FAILED, bar0);
+
+	/* Probe support for VFIO_DEVICE_FEATURE_LOW_POWER_ENTRY */
+	feat.argsz = sizeof(feat);
+	feat.flags = VFIO_DEVICE_FEATURE_PROBE |
+		     VFIO_DEVICE_FEATURE_SET |
+		     VFIO_DEVICE_FEATURE_LOW_POWER_ENTRY;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_FEATURE, &feat);
+	if (ret != 0) {
+		ASSERT_EQ(0, munmap(bar0, bar0_info.size));
+		SKIP(return, "LOW_POWER_ENTRY feature not supported on device");
+	}
+
+	/* Populate mapping and write test pattern to scratch register */
+	WRITE_ONCE(*(uint32_t *)((char *)bar0 + E1000_RAL0), 0xdeadbeef);
+	val = READ_ONCE(*(uint32_t *)((char *)bar0 + E1000_RAL0));
+	ASSERT_EQ(0xdeadbeef, val);
+
+	/* Enter low-power D3hot state */
+	feat.argsz = sizeof(feat);
+	feat.flags = VFIO_DEVICE_FEATURE_SET |
+		     VFIO_DEVICE_FEATURE_LOW_POWER_ENTRY;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_FEATURE, &feat);
+	ASSERT_EQ(0, ret);
+
+	/*
+	 * In low-power state, BARs are marked unavailable and mappings are
+	 * revoked.
+	 *
+	 * - Host mmap accesses trigger SIGBUS because page tables were zapped
+	 *   and get_pfn fails with -EFAULT while in low power state.
+	 * - Host pread() and pwrite() on the BAR descriptor fail with -EIO.
+	 */
+	TEST_EXPECT_SIGBUS((void)READ_ONCE(*(uint32_t *)((char *)bar0 + E1000_RAL0)));
+	TEST_EXPECT_SIGBUS(WRITE_ONCE(*(uint32_t *)((char *)bar0 + E1000_RAL0), 0x12345678));
+
+	val = 0;
+	ret_bytes = pread(self->bar_fd, &val, sizeof(val), bar0_info.offset + E1000_STATUS);
+	ASSERT_EQ(-1, ret_bytes);
+	ASSERT_EQ(EIO, errno);
+
+	val = 0x12345678;
+	ret_bytes = pwrite(self->bar_fd, &val, sizeof(val), bar0_info.offset + E1000_RAL0);
+	ASSERT_EQ(-1, ret_bytes);
+	ASSERT_EQ(EIO, errno);
+
+	/* Exit low-power state back to D0 */
+	feat.argsz = sizeof(feat);
+	feat.flags = VFIO_DEVICE_FEATURE_SET |
+		     VFIO_DEVICE_FEATURE_LOW_POWER_EXIT;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_FEATURE, &feat);
+	ASSERT_EQ(0, ret);
+
+	/*
+	 * Access must succeed again after returning to active D0.
+	 */
+	val = READ_ONCE(*(uint32_t *)((char *)bar0 + E1000_RAL0));
+	ASSERT_EQ(0xdeadbeef, val);
+
+	val = 0;
+	ret_bytes = pread(self->bar_fd, &val, sizeof(val), bar0_info.offset + E1000_STATUS);
+	ASSERT_EQ(sizeof(val), ret_bytes);
+	ASSERT_NE(0xFFFFFFFF, val);
+
+	ASSERT_EQ(0, munmap(bar0, bar0_info.size));
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

