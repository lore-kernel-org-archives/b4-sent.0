From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:52 -0800
Subject: [PATCH RFC v3 78/88] KVM: selftests: Verify VFIO access directly
 and via guest_memfd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-78-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=6129;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=wMpfVe5pW5612uAirzjznbXSxcHXbU2mXBke4sAga64=;
 b=tdBMo5bwX2Uer41RpQmN0GH50JgBfYlCVTon4eNRJWYkAyazzOurorg07KXh3Jb95H9HI98uP
 YptA2UUYyosDFhRRnsmzi7EgQN+1UkGEJfe/r5Sb3/gVzYbH6wjyWS0
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the VFIO igb device selftest suite to run across fixture variants
testing both direct VFIO access and mediated access via guest_memfd.

Define two fixture variants:
- direct: binds the device normally, exercising direct descriptor read,
  write, mmap, and reset.
- guest_memfd: binds with the control-only flag and attaches the device
  as a backing resource for a guest_memfd instance, validating that BAR
  read, write, mmap, and reset succeed through the guest_memfd
  descriptor.

Because guest_memfd delegation of VFIO regions relies on in-place
conversion (per-gmem memory attributes) so the entire sparse region
namespace can be initialized as shared via INIT_SHARED, require
kvm_has_gmem_attributes when setting up the guest_memfd variant.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 77 ++++++++++++++++++++--
 1 file changed, 72 insertions(+), 5 deletions(-)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index 91cba359e4392..03c324f7f618d 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -21,6 +21,7 @@
 #include <linux/vfio.h>
 
 #include "kselftest_harness.h"
+#include "kvm_util.h"
 
 #define PCI_VENDOR_ID_INTEL 0x8086
 #define PCI_DEVICE_ID_INTEL_82576 0x10C9
@@ -96,10 +97,27 @@ static char *find_igb_cdev_path(void)
 	return NULL;
 }
 
+#define VFIO_PCI_OFFSET_SHIFT 40
+
 FIXTURE(guest_memfd_vfio) {
 	char *cdev_path;
+	struct kvm_vm *vm;
+	int gmem_fd;
 	int iommufd;
 	int vfio_fd;
+	int bar_fd;
+};
+
+FIXTURE_VARIANT(guest_memfd_vfio) {
+	bool use_gmem;
+};
+
+FIXTURE_VARIANT_ADD(guest_memfd_vfio, direct) {
+	.use_gmem = false,
+};
+
+FIXTURE_VARIANT_ADD(guest_memfd_vfio, guest_memfd) {
+	.use_gmem = true,
 };
 
 FIXTURE_SETUP(guest_memfd_vfio)
@@ -107,6 +125,10 @@ FIXTURE_SETUP(guest_memfd_vfio)
 	struct vfio_device_bind_iommufd bind_args = {};
 	int ret;
 
+	self->vm = NULL;
+	self->gmem_fd = -1;
+	self->bar_fd = -1;
+
 	self->cdev_path = find_igb_cdev_path();
 	if (!self->cdev_path)
 		SKIP(return, "Intel 82576 device bound to vfio not found\n");
@@ -123,12 +145,50 @@ FIXTURE_SETUP(guest_memfd_vfio)
 
 	bind_args.argsz = sizeof(bind_args);
 	bind_args.iommufd = self->iommufd;
+	if (variant->use_gmem)
+		bind_args.flags = VFIO_DEVICE_BIND_FLAG_CTRL_ONLY;
+
 	ret = ioctl(self->vfio_fd, VFIO_DEVICE_BIND_IOMMUFD, &bind_args);
 	ASSERT_EQ(0, ret);
+
+	/*
+	 * Create a SW_PROTECTED_VM with 1 runnable vCPU allocated for memslot0
+	 * and stack/page table allocation, so guest_mapping can execute vCPUs
+	 * and FIXTURE_TEARDOWN uniformly cleans up self->vm across both variants.
+	 */
+	self->vm = __vm_create((struct vm_shape){ .mode = VM_MODE_DEFAULT,
+						  .type = KVM_X86_SW_PROTECTED_VM },
+			       1, 0);
+
+	if (variant->use_gmem) {
+		uint64_t gmem_flags = GUEST_MEMFD_FLAG_USE_RESOURCE |
+				      GUEST_MEMFD_FLAG_PFN_MODE |
+				      GUEST_MEMFD_FLAG_MMAP |
+				      GUEST_MEMFD_FLAG_INIT_SHARED;
+		uint64_t gmem_size = (uint64_t)VFIO_PCI_NUM_REGIONS << VFIO_PCI_OFFSET_SHIFT;
+
+		/*
+		 * guest_memfd providers (including VFIO) is only intended to be
+		 * used with gmem_in_place_conversion.
+		 */
+		TEST_REQUIRE(kvm_has_gmem_attributes);
+
+		self->gmem_fd = vm_create_guest_memfd_resource(self->vm, gmem_size,
+							       gmem_flags,
+							       self->vfio_fd);
+		ASSERT_GE(self->gmem_fd, 0);
+		self->bar_fd = self->gmem_fd;
+	} else {
+		self->bar_fd = self->vfio_fd;
+	}
 }
 
 FIXTURE_TEARDOWN(guest_memfd_vfio)
 {
+	if (self->gmem_fd >= 0)
+		close(self->gmem_fd);
+	if (self->vm)
+		kvm_vm_free(self->vm);
 	if (self->vfio_fd >= 0)
 		close(self->vfio_fd);
 	if (self->iommufd >= 0)
@@ -236,6 +296,13 @@ TEST_F(guest_memfd_vfio, get_irq_info)
 	}
 }
 
+/*
+ * PCI Command register configuration belongs to the PCI configuration space
+ * region (VFIO_PCI_CONFIG_REGION_INDEX), which is accessed via the underlying
+ * VFIO device descriptor (vfio_fd). In guest_memfd mode, bar_fd refers to the
+ * guest_memfd descriptor representing memory BARs and cannot be used to read or
+ * write PCI configuration space.
+ */
 static void vfio_pci_enable_memory_and_bus_master(struct __test_metadata *_metadata,
 						  int vfio_fd)
 {
@@ -276,7 +343,7 @@ TEST_F(guest_memfd_vfio, bar_rw)
 	 * Confirm device is readable and does not return 0xFFFFFFFF.
 	 */
 	val = 0;
-	ret_bytes = pread(self->vfio_fd, &val, sizeof(val), bar0_info.offset + E1000_STATUS);
+	ret_bytes = pread(self->bar_fd, &val, sizeof(val), bar0_info.offset + E1000_STATUS);
 	ASSERT_EQ(sizeof(val), ret_bytes);
 	ASSERT_NE(0xFFFFFFFF, val);
 
@@ -285,11 +352,11 @@ TEST_F(guest_memfd_vfio, bar_rw)
 	 * it back via pread().
 	 */
 	val = 0xdeadbeef;
-	ret_bytes = pwrite(self->vfio_fd, &val, sizeof(val), bar0_info.offset + E1000_RAL0);
+	ret_bytes = pwrite(self->bar_fd, &val, sizeof(val), bar0_info.offset + E1000_RAL0);
 	ASSERT_EQ(sizeof(val), ret_bytes);
 
 	val = 0;
-	ret_bytes = pread(self->vfio_fd, &val, sizeof(val), bar0_info.offset + E1000_RAL0);
+	ret_bytes = pread(self->bar_fd, &val, sizeof(val), bar0_info.offset + E1000_RAL0);
 	ASSERT_EQ(sizeof(val), ret_bytes);
 	ASSERT_EQ(0xdeadbeef, val);
 }
@@ -310,7 +377,7 @@ TEST_F(guest_memfd_vfio, bar_mmap)
 	ASSERT_TRUE(bar0_info.flags & VFIO_REGION_INFO_FLAG_MMAP);
 
 	bar0 = mmap(NULL, bar0_info.size, PROT_READ | PROT_WRITE, MAP_SHARED,
-		    self->vfio_fd, bar0_info.offset);
+		    self->bar_fd, bar0_info.offset);
 	ASSERT_NE(MAP_FAILED, bar0);
 
 	/*
@@ -347,7 +414,7 @@ TEST_F(guest_memfd_vfio, device_reset)
 	ASSERT_EQ(0, ret);
 
 	bar0 = mmap(NULL, bar0_info.size, PROT_READ | PROT_WRITE, MAP_SHARED,
-		    self->vfio_fd, bar0_info.offset);
+		    self->bar_fd, bar0_info.offset);
 	ASSERT_NE(MAP_FAILED, bar0);
 
 	/* Write scratch test pattern to RAL0 */

-- 
2.56.0.455.g6c5a503b38-goog

