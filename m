From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:28:02 -0700
Subject: [PATCH RFC v2 30/50] KVM: selftests: Add basic test for sample
 memory provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-30-5dd1dc6c660a@google.com>
References: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
In-Reply-To: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
To: Alex Williamson <alex@shazbot.org>, Alexander Graf <graf@amazon.de>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Alexey Kardashevskiy <aik@amd.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Ashish Kalra <ashish.kalra@amd.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Baolu Lu <baolu.lu@linux.intel.com>, Bill Wendling <morbo@google.com>, 
 Borislav Petkov <bp@alien8.de>, Catalin Marinas <catalin.marinas@arm.com>, 
 Christian Brauner <brauner@kernel.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Connor Williamson <connordw@amazon.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, David Hildenbrand <david@kernel.org>, 
 David Rientjes <rientjes@google.com>, David Woodhouse <dwmw2@infradead.org>, 
 Erdem Aktas <erdemaktas@google.com>, Frank van der Linden <fvdl@google.com>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, Fred Griffoul <griffoul@gmail.com>, 
 Gregory Price <gourry@gourry.net>, "H. Peter Anvin" <hpa@zytor.com>, 
 Hugh Dickins <hughd@google.com>, Ingo Molnar <mingo@redhat.com>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, 
 James Houghton <jthoughton@google.com>, Jan Kara <jack@suse.cz>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Jianxiong Gao <jxgao@google.com>, 
 Joerg Roedel <joro@8bytes.org>, Joey Gouly <joey.gouly@arm.com>, 
 John Starks <John.Starks@microsoft.com>, Jonathan Corbet <corbet@lwn.net>, 
 Justin Stitt <justinstitt@google.com>, Kevin Tian <kevin.tian@intel.com>, 
 Lorenzo Stoakes <ljs@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 Michael Roth <michael.roth@amd.com>, Mike Rapoport <rppt@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Nicolin Chen <nicolinc@nvidia.com>, Oliver Upton <oupton@kernel.org>, 
 Paolo Bonzini <pbonzini@redhat.com>, Pratyush Yadav <pratyush@kernel.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Robin Murphy <robin.murphy@arm.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, Shuah Khan <shuah@kernel.org>, 
 Steffen Eiden <seiden@linux.ibm.com>, Steven Price <steven.price@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Tom Lendacky <thomas.lendacky@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Vishal Annapurve <vannapurve@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Will Deacon <will@kernel.org>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Yan Zhao <yan.y.zhao@intel.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, x86@kernel.org, 
 Shuah Khan <skhan@linuxfoundation.org>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, llvm@lists.linux.dev, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=5553;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=DxHc6o6FnWpOH7kMAejZmhFMGKZWARQeHZ9yAfr2gtM=;
 b=MZWm5OhI65j5qGliKRKMwC78fhjZnRK4OJnvkL5NZPMB3GRVId6GmA9lc7rWY/7Oe6I17BuFk
 /BfBpbRroEDB7//o/KaeRPl5dErRndTcfCEIUCt859LcAinaQKoho5Y
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a selftest for the sample memory provider (/dev/mem_provider_sample).

Test basic lifecycle creation across multiple sizes. Verify file capacity
and absent pages accounting using the MPS_GET_STATS ioctl. Also test
marking pages absent and present with MPS_SET_PRESENT, verifying that
absent pages are reflected in stats accordingly.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/Makefile.kvm           |   1 +
 .../selftests/kvm/mem_provider_sample_test.c       | 147 +++++++++++++++++++++
 2 files changed, 148 insertions(+)

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
index 0000000000000..932ea3f30f494
--- /dev/null
+++ b/tools/testing/selftests/kvm/mem_provider_sample_test.c
@@ -0,0 +1,147 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Tests for the sample memory provider (/dev/mem_provider_sample).
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
+#include "../../../../samples/kvm/mem_provider_sample.h"
+
+#define DEV_PATH "/dev/mem_provider_sample"
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
+	struct mps_new_file nf = {
+		.size = size,
+	};
+	int fd;
+
+	fd = ioctl(dev_fd, MPS_NEW_FILE, &nf);
+	TEST_ASSERT(fd >= 0, "MPS_NEW_FILE failed for size 0x%lx: %d (%s)",
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
+	struct mps_stats st;
+	int i, fd;
+
+	for (i = 0; i < ARRAY_SIZE(sizes); i++) {
+		fd = create_provider_file(dev_fd, sizes[i]);
+
+		memset(&st, 0, sizeof(st));
+		TEST_ASSERT(!ioctl(fd, MPS_GET_STATS, &st),
+			    "MPS_GET_STATS failed: %d (%s)",
+			    errno, strerror(errno));
+		TEST_ASSERT(st.size == sizes[i],
+			    "size mismatch: expected 0x%lx, got 0x%llx",
+			    sizes[i], st.size);
+		TEST_ASSERT(st.absent_pages == 0,
+			    "absent_pages mismatch: expected 0, got %llu",
+			    st.absent_pages);
+
+		close(fd);
+	}
+}
+
+static void test_set_present(int dev_fd)
+{
+	size_t page_size = getpagesize();
+	uint64_t nr_pages = 4;
+	uint64_t file_size = nr_pages * page_size;
+	struct mps_set_present sp;
+	struct mps_stats st;
+	int ret, fd;
+
+	fd = create_provider_file(dev_fd, file_size);
+
+	/* Initially all pages are present */
+	TEST_ASSERT(!ioctl(fd, MPS_GET_STATS, &st),
+		    "MPS_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.absent_pages == 0,
+		    "Initial absent_pages mismatch: expected 0, got %llu",
+		    st.absent_pages);
+
+	/* Mark page 1 absent */
+	memset(&sp, 0, sizeof(sp));
+	sp.value = 0;
+	sp.offset = page_size;
+	sp.len = page_size;
+	ret = ioctl(fd, MPS_SET_PRESENT, &sp);
+	TEST_ASSERT(!ret, "MPS_SET_PRESENT (absent) failed: %d (%s)",
+		    errno, strerror(errno));
+
+	TEST_ASSERT(!ioctl(fd, MPS_GET_STATS, &st),
+		    "MPS_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.size == file_size,
+		    "size changed unexpectedly: 0x%llx", st.size);
+	TEST_ASSERT(st.absent_pages == 1,
+		    "absent_pages mismatch after absent: expected 1, got %llu",
+		    st.absent_pages);
+
+	/* Mark page 1 back to present */
+	sp.value = 1;
+	ret = ioctl(fd, MPS_SET_PRESENT, &sp);
+	TEST_ASSERT(!ret, "MPS_SET_PRESENT (present) failed: %d (%s)",
+		    errno, strerror(errno));
+
+	TEST_ASSERT(!ioctl(fd, MPS_GET_STATS, &st),
+		    "MPS_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.absent_pages == 0,
+		    "absent_pages mismatch after restore: expected 0, got %llu",
+		    st.absent_pages);
+
+	/* Mark all pages absent */
+	sp.value = 0;
+	sp.offset = 0;
+	sp.len = file_size;
+	ret = ioctl(fd, MPS_SET_PRESENT, &sp);
+	TEST_ASSERT(!ret, "MPS_SET_PRESENT (all absent) failed: %d (%s)",
+		    errno, strerror(errno));
+
+	TEST_ASSERT(!ioctl(fd, MPS_GET_STATS, &st),
+		    "MPS_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.absent_pages == nr_pages,
+		    "absent_pages mismatch after all absent: expected %lu, got %llu",
+		    nr_pages, st.absent_pages);
+
+	close(fd);
+}
+
+int main(int argc, char *argv[])
+{
+	int dev_fd;
+
+	dev_fd = open_provider_dev();
+
+	test_lifecycle_and_creation(dev_fd);
+	test_set_present(dev_fd);
+
+	close(dev_fd);
+	return 0;
+}

-- 
2.56.0.257.gf7497c7d27-goog

