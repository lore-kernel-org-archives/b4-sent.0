From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:46 -0800
Subject: [PATCH RFC v3 72/88] KVM: selftests: Add initial VFIO test
 verifying device info
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-72-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=5637;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=qwwY1wogTiFJkGLjVl6X2EfDY2DAV1c/GKKv838ghMk=;
 b=NtT2E6e6NOXKRJJI6K8IGA2kAqoRSKGa8TTX9X40Mk2ZO0d+8X6Uf5VI8mskLD0aG5AXW51ZN
 DL61hLwxxv5D5p+w9bG47JvOxpnd9e/seVW7PI53w29SMhPOwZq8Bfy
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a standalone selftest to verify that an emulated or physical
Intel 82576 network card bound to the vfio cdev interface can be opened,
bound to iommufd, and queried for device information without requiring
an attached IOMMU page table or a running virtual machine.

Structure test setup and teardown into a kselftest harness fixture,
skipping cleanly if the device or /dev/iommu is unavailable, and
verifying that queried device flags reflect PCI and reset capabilities.
---
 tools/testing/selftests/kvm/Makefile.kvm           |   1 +
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 153 +++++++++++++++++++++
 2 files changed, 154 insertions(+)

diff --git a/tools/testing/selftests/kvm/Makefile.kvm b/tools/testing/selftests/kvm/Makefile.kvm
index 5f7118bddfc36..05f87764b71e7 100644
--- a/tools/testing/selftests/kvm/Makefile.kvm
+++ b/tools/testing/selftests/kvm/Makefile.kvm
@@ -162,6 +162,7 @@ TEST_GEN_PROGS_x86 += x86/triple_fault_event_test
 TEST_GEN_PROGS_x86 += x86/recalc_apic_map_test
 TEST_GEN_PROGS_x86 += x86/aperfmperf_test
 TEST_GEN_PROGS_x86 += x86/guest_memfd_conversions_test
+TEST_GEN_PROGS_x86 += x86/guest_memfd_vfio_test
 TEST_GEN_PROGS_x86 += access_tracking_perf_test
 TEST_GEN_PROGS_x86 += coalesced_io_test
 TEST_GEN_PROGS_x86 += dirty_log_perf_test
diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
new file mode 100644
index 0000000000000..669acc6058b5b
--- /dev/null
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -0,0 +1,153 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Minimal standalone test to verify an emulated or physical Intel 82576 (igb)
+ * NIC bound to vfio-pci via IOMMUFD cdev, without creating a KVM guest.
+ */
+#include <dirent.h>
+#include <errno.h>
+#include <fcntl.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <unistd.h>
+#include <sys/ioctl.h>
+#include <sys/mman.h>
+#include <sys/types.h>
+
+#include <linux/iommufd.h>
+#include <linux/pci_regs.h>
+#include <linux/types.h>
+#include <linux/compiler.h>
+#include <linux/vfio.h>
+
+#include "kselftest_harness.h"
+
+#define PCI_VENDOR_ID_INTEL 0x8086
+#define PCI_DEVICE_ID_INTEL_82576 0x10C9
+
+/* Intel 82576 BAR0 register offsets */
+#define E1000_CTRL	0x00000 /* Device Control - RW */
+#define E1000_STATUS	0x00008 /* Device Status - RO */
+#define E1000_RAL0	0x05400 /* Receive Address Low (0) - RW */
+#define E1000_RAH0	0x05404 /* Receive Address High (0) - RW */
+
+static char *find_igb_cdev_path(void)
+{
+	const char *sys_pci = "/sys/bus/pci/devices";
+	struct dirent *dev_entry;
+	DIR *dir = opendir(sys_pci);
+	char cdev_path[PATH_MAX];
+	char path[PATH_MAX];
+
+	if (!dir)
+		return NULL;
+
+	while ((dev_entry = readdir(dir)) != NULL) {
+		FILE *f;
+		uint32_t vendor = 0, device = 0;
+		DIR *vfio_dir;
+		struct dirent *vfio_entry;
+
+		if (dev_entry->d_name[0] == '.')
+			continue;
+
+		snprintf(path, sizeof(path), "%s/%s/vendor", sys_pci, dev_entry->d_name);
+		f = fopen(path, "r");
+		if (!f)
+			continue;
+		if (fscanf(f, "0x%x", &vendor) != 1) {
+			fclose(f);
+			continue;
+		}
+		fclose(f);
+
+		snprintf(path, sizeof(path), "%s/%s/device", sys_pci, dev_entry->d_name);
+		f = fopen(path, "r");
+		if (!f)
+			continue;
+		if (fscanf(f, "0x%x", &device) != 1) {
+			fclose(f);
+			continue;
+		}
+		fclose(f);
+
+		if (vendor != PCI_VENDOR_ID_INTEL || device != PCI_DEVICE_ID_INTEL_82576)
+			continue;
+
+		/* Found an Intel 82576 device. Check if bound to vfio-pci cdev. */
+		snprintf(path, sizeof(path), "%s/%s/vfio-dev", sys_pci, dev_entry->d_name);
+		vfio_dir = opendir(path);
+		if (!vfio_dir)
+			continue;
+
+		while ((vfio_entry = readdir(vfio_dir)) != NULL) {
+			if (strncmp(vfio_entry->d_name, "vfio", 4) == 0) {
+				snprintf(cdev_path, sizeof(cdev_path), "/dev/vfio/devices/%s",
+					 vfio_entry->d_name);
+				closedir(vfio_dir);
+				closedir(dir);
+				return strdup(cdev_path);
+			}
+		}
+		closedir(vfio_dir);
+	}
+
+	closedir(dir);
+	return NULL;
+}
+
+FIXTURE(guest_memfd_vfio) {
+	char *cdev_path;
+	int iommufd;
+	int vfio_fd;
+};
+
+FIXTURE_SETUP(guest_memfd_vfio)
+{
+	struct vfio_device_bind_iommufd bind_args = {};
+	int ret;
+
+	self->cdev_path = find_igb_cdev_path();
+	if (!self->cdev_path)
+		SKIP(return, "Intel 82576 device bound to vfio not found\n");
+
+	self->iommufd = open("/dev/iommu", O_RDWR);
+	if (self->iommufd < 0) {
+		free(self->cdev_path);
+		self->cdev_path = NULL;
+		SKIP(return, "Failed to open /dev/iommu\n");
+	}
+
+	self->vfio_fd = open(self->cdev_path, O_RDWR);
+	ASSERT_GE(self->vfio_fd, 0);
+
+	bind_args.argsz = sizeof(bind_args);
+	bind_args.iommufd = self->iommufd;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_BIND_IOMMUFD, &bind_args);
+	ASSERT_EQ(0, ret);
+}
+
+FIXTURE_TEARDOWN(guest_memfd_vfio)
+{
+	if (self->vfio_fd >= 0)
+		close(self->vfio_fd);
+	if (self->iommufd >= 0)
+		close(self->iommufd);
+	free(self->cdev_path);
+}
+
+TEST_F(guest_memfd_vfio, get_device_info)
+{
+	struct vfio_device_info dev_info = {};
+	int ret;
+
+	dev_info.argsz = sizeof(dev_info);
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_INFO, &dev_info);
+	ASSERT_EQ(0, ret);
+	ASSERT_TRUE(dev_info.flags & VFIO_DEVICE_FLAGS_PCI);
+	ASSERT_TRUE(dev_info.flags & VFIO_DEVICE_FLAGS_RESET);
+	ASSERT_GE(dev_info.num_regions, VFIO_PCI_NUM_REGIONS);
+	ASSERT_GT(dev_info.num_irqs, 0);
+}
+
+TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

