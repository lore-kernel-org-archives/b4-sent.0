From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:59 -0800
Subject: [PATCH RFC v3 25/88] KVM: selftests: Add basic test for sample
 memory provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-25-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=3413;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=egSCIn/Z8yZyelQp7cvP3qLOE5NIjYa4+lOtgqtkCcA=;
 b=eS+nI7PxlE1maO7QU8JcyjZXzc2ref6sfu7l8coYHFOVhGHBKNsZtFBYoz3WLd43hTPKAb1qs
 PP5daxaQ65oBQ7t7obsP+mJagOwOWNCEhUA/gMKhIeq0BPfUyn6q5uy
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a selftest for the sample memory provider to verify lifecycle
management and file creation.

Verify creating provider files across multiple sizes and ensure that
initial statistics accurately reflect file capacity, zero absent pages,
and zero read-only pages.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/Makefile.kvm           |  1 +
 .../selftests/kvm/mem_provider_sample_test.c       | 85 ++++++++++++++++++++++
 2 files changed, 86 insertions(+)

diff --git a/tools/testing/selftests/kvm/Makefile.kvm b/tools/testing/selftests/kvm/Makefile.kvm
index 17a4256e90819..5f7118bddfc36 100644
--- a/tools/testing/selftests/kvm/Makefile.kvm
+++ b/tools/testing/selftests/kvm/Makefile.kvm
@@ -72,6 +72,7 @@ TEST_GEN_PROGS_COMMON += set_memory_region_test
 TEST_GEN_PROGS_COMMON += memslot_modification_stress_test
 TEST_GEN_PROGS_COMMON += memslot_perf_test
 TEST_GEN_PROGS_COMMON += vm_types_test
+TEST_GEN_PROGS_COMMON += mem_provider_sample_test
 
 # Compiled test targets
 TEST_GEN_PROGS_x86 = $(TEST_GEN_PROGS_COMMON)
diff --git a/tools/testing/selftests/kvm/mem_provider_sample_test.c b/tools/testing/selftests/kvm/mem_provider_sample_test.c
new file mode 100644
index 0000000000000..b39161f4933d3
--- /dev/null
+++ b/tools/testing/selftests/kvm/mem_provider_sample_test.c
@@ -0,0 +1,85 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Tests for the sample memory provider (/dev/memory_provider).
+ */
+#include <fcntl.h>
+#include <stdint.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <sys/ioctl.h>
+#include <sys/stat.h>
+#include <unistd.h>
+
+#include "test_util.h"
+#include "../../../../samples/kvm/memory_provider.h"
+
+#define DEV_PATH "/dev/memory_provider"
+
+static int open_provider_dev(void)
+{
+	int fd = open(DEV_PATH, O_RDWR);
+
+	if (fd < 0) {
+		TEST_REQUIRE(errno != ENOENT && errno != ENODEV);
+		TEST_FAIL("Failed to open %s: %d (%s)", DEV_PATH, errno,
+			  strerror(errno));
+	}
+	return fd;
+}
+
+static int create_provider_file(int dev_fd, uint64_t size)
+{
+	struct mp_new_file nf = {
+		.size = size,
+	};
+	int fd;
+
+	fd = ioctl(dev_fd, MP_NEW_FILE, &nf);
+	TEST_ASSERT(fd >= 0, "MP_NEW_FILE failed for size 0x%lx: %d (%s)",
+		    size, errno, strerror(errno));
+	return fd;
+}
+
+static void test_lifecycle_and_creation(int dev_fd)
+{
+	size_t page_size = getpagesize();
+	uint64_t sizes[] = {
+		page_size,
+		2 * page_size,
+		2 * 1024 * 1024,
+	};
+	struct mp_stats st;
+	int i, fd;
+
+	for (i = 0; i < ARRAY_SIZE(sizes); i++) {
+		fd = create_provider_file(dev_fd, sizes[i]);
+
+		memset(&st, 0, sizeof(st));
+		TEST_ASSERT(!ioctl(fd, MP_GET_STATS, &st),
+			    "MP_GET_STATS failed: %d (%s)",
+			    errno, strerror(errno));
+		TEST_ASSERT(st.size == sizes[i],
+			    "size mismatch: expected 0x%lx, got 0x%llx",
+			    sizes[i], st.size);
+		TEST_ASSERT(st.absent_pages == 0,
+			    "absent_pages mismatch: expected 0, got %llu",
+			    st.absent_pages);
+		TEST_ASSERT(st.readonly_pages == 0,
+			    "readonly_pages mismatch: expected 0, got %llu",
+			    st.readonly_pages);
+
+		close(fd);
+	}
+}
+
+int main(int argc, char *argv[])
+{
+	int dev_fd;
+
+	dev_fd = open_provider_dev();
+
+	test_lifecycle_and_creation(dev_fd);
+
+	close(dev_fd);
+	return 0;
+}

-- 
2.56.0.455.g6c5a503b38-goog

