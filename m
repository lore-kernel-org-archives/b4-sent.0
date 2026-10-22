From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:28:22 -0700
Subject: [PATCH RFC v2 50/50] KVM: selftests: Test guest_memfd conversions
 with sample memory provider backing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-50-5dd1dc6c660a@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=5170;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=rlB85PYh1jaJvMrL1kLAqla/p5s2l4avZfOOeeGlWDM=;
 b=VSMpakwCoRWmpL30l5zo+rYlaAKf2cnLwpQ7a87uoka6eTdULgcyR5+xHnOSv19D2vO2aAMw7
 uw5/EyEtXt5Amy29y7apd5iX/XRwsIqytyCd7Kch17Xizk0nX9V2GLL
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add fixture variant for the sample memory provider.

If /dev/mem_provider_sample cannot be opened because the module is not
loaded, the mps variant is skipped gracefully via TEST_REQUIRE().

Because PFN-backed memory cannot be pinned via GUP, expect pinning to fail
for the mps variant in the elevated_refcount test.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/include/kvm_util.h     |  1 +
 tools/testing/selftests/kvm/lib/kvm_util.c         |  9 ++++-
 .../kvm/x86/guest_memfd_conversions_test.c         | 44 +++++++++++++++++++++-
 3 files changed, 51 insertions(+), 3 deletions(-)

diff --git a/tools/testing/selftests/kvm/include/kvm_util.h b/tools/testing/selftests/kvm/include/kvm_util.h
index eca296539db79..1a1387f36a52c 100644
--- a/tools/testing/selftests/kvm/include/kvm_util.h
+++ b/tools/testing/selftests/kvm/include/kvm_util.h
@@ -1350,6 +1350,7 @@ static inline int pin_self_to_any_cpu(void)
 	return pin_task_to_any_cpu(pthread_self());
 }
 
+int __pin_pages(void *vaddr, uint64_t size);
 void pin_pages(void *vaddr, uint64_t size);
 void unpin_pages(void);
 
diff --git a/tools/testing/selftests/kvm/lib/kvm_util.c b/tools/testing/selftests/kvm/lib/kvm_util.c
index d42e201eba763..9793818f54d23 100644
--- a/tools/testing/selftests/kvm/lib/kvm_util.c
+++ b/tools/testing/selftests/kvm/lib/kvm_util.c
@@ -674,7 +674,7 @@ int __pin_task_to_cpu(pthread_t task, int cpu)
 
 static int gup_test_fd = -1;
 
-void pin_pages(void *vaddr, uint64_t size)
+int __pin_pages(void *vaddr, uint64_t size)
 {
 	const struct pin_longterm_test args = {
 		.addr = (uint64_t)vaddr,
@@ -685,7 +685,12 @@ void pin_pages(void *vaddr, uint64_t size)
 	gup_test_fd = __open_path_or_exit("/sys/kernel/debug/gup_test", O_RDWR,
 					  "Is CONFIG_GUP_TEST enabled?");
 
-	TEST_ASSERT_EQ(ioctl(gup_test_fd, PIN_LONGTERM_TEST_START, &args), 0);
+	return ioctl(gup_test_fd, PIN_LONGTERM_TEST_START, &args);
+}
+
+void pin_pages(void *vaddr, uint64_t size)
+{
+	TEST_ASSERT_EQ(__pin_pages(vaddr, size), 0);
 }
 
 void unpin_pages(void)
diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
index 023df9cb9d4a6..b99e4cdbab8e6 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
@@ -16,11 +16,13 @@
 #include "kselftest_harness.h"
 #include "test_util.h"
 #include "ucall_common.h"
+#include "../../../../samples/kvm/mem_provider_sample.h"
 
 FIXTURE(gmem_conversions) {
 	struct kvm_vcpu *vcpu;
 	int gmem_fd;
 	int resource_fd;
+	bool expect_pin_failure;
 	/* HVA of the first byte of the memory mmap()-ed from gmem_fd. */
 	char *mem;
 };
@@ -29,10 +31,14 @@ typedef FIXTURE_DATA(gmem_conversions) test_data_t;
 
 FIXTURE_VARIANT(gmem_conversions) {
 	int (*create_resource)(size_t size);
+	uint64_t extra_flags;
+	bool expect_pin_failure;
 };
 
 FIXTURE_VARIANT_ADD(gmem_conversions, native) {
 	.create_resource = NULL,
+	.extra_flags = 0,
+	.expect_pin_failure = false,
 };
 
 static int create_tmpfs_resource(size_t size)
@@ -42,6 +48,34 @@ static int create_tmpfs_resource(size_t size)
 
 FIXTURE_VARIANT_ADD(gmem_conversions, tmpfs) {
 	.create_resource = create_tmpfs_resource,
+	.extra_flags = 0,
+	.expect_pin_failure = false,
+};
+
+static int create_mps_resource(size_t size)
+{
+	struct mps_new_file nf = {
+		.size = size,
+	};
+	int dev_fd, fd;
+
+	dev_fd = open("/dev/mem_provider_sample", O_RDWR);
+	if (dev_fd < 0) {
+		TEST_REQUIRE(errno != ENOENT && errno != ENODEV);
+		TEST_FAIL("Failed to open /dev/mem_provider_sample: %d (%s)",
+			  errno, strerror(errno));
+	}
+
+	fd = ioctl(dev_fd, MPS_NEW_FILE, &nf);
+	TEST_ASSERT(fd >= 0, "MPS_NEW_FILE failed: %d (%s)", errno, strerror(errno));
+	close(dev_fd);
+	return fd;
+}
+
+FIXTURE_VARIANT_ADD(gmem_conversions, mps) {
+	.create_resource = create_mps_resource,
+	.extra_flags = GUEST_MEMFD_FLAG_PFN_MODE,
+	.expect_pin_failure = true,
 };
 
 FIXTURE_SETUP(gmem_conversions) { }
@@ -75,10 +109,12 @@ static void gmem_conversions_do_setup(test_data_t *t,
 
 	vm = __vm_create_shape_with_one_vcpu(shape, &t->vcpu, nr_pages, guest_do_rmw);
 
+	t->expect_pin_failure = variant->expect_pin_failure;
 	t->resource_fd = -1;
 
 	if (variant->create_resource) {
-		uint64_t flags = gmem_flags | GUEST_MEMFD_FLAG_USE_RESOURCE;
+		uint64_t flags = gmem_flags | GUEST_MEMFD_FLAG_USE_RESOURCE |
+				 variant->extra_flags;
 
 		t->resource_fd = variant->create_resource(size);
 		TEST_ASSERT(t->resource_fd >= 0, "Failed to create backing resource");
@@ -506,6 +542,12 @@ GMEM_CONVERSION_MULTIPAGE_TEST_INIT_SHARED(elevated_refcount, 4)
 {
 	int i;
 
+	if (t->expect_pin_failure) {
+		TEST_ASSERT(__pin_pages(t->mem + test_page * page_size, page_size) < 0,
+			    "Pinning PFN-backed memory should fail");
+		return;
+	}
+
 	pin_pages(t->mem + test_page * page_size, page_size);
 
 	for (i = 0; i < nr_pages; i++)

-- 
2.56.0.257.gf7497c7d27-goog

