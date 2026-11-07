From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:24 -0800
Subject: [PATCH RFC v3 50/88] KVM: selftests: Test guest_memfd conversions
 with sample memory provider backing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-50-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=5146;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=pFmVA22FXGETZKWOVPROthnqtuyrzDD+ZHNTU/H+YNY=;
 b=11BVE+QRpNOg7Hd1AOFKxr49Ovvf9iM3u7cDh54/3reFREN7eARVv8IsPL4S1AeL3D5QnyytI
 dXlUBPCrGnZCsK0Evp6XvNHNHVCdLa2iZrWfJ9bMPZ/08Aj0X4KMUZn
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add fixture variant for the sample memory provider.

If the sample memory provider cannot be opened because the module is not
loaded, the variant is skipped gracefully via TEST_REQUIRE().

Because PFN-backed memory cannot be pinned via GUP, expect pinning to fail
for the variant in the elevated_refcount test.

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
index 023df9cb9d4a6..d0cbb1353d7ee 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
@@ -16,11 +16,13 @@
 #include "kselftest_harness.h"
 #include "test_util.h"
 #include "ucall_common.h"
+#include "../../../../samples/kvm/memory_provider.h"
 
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
+static int create_mp_resource(size_t size)
+{
+	struct mp_new_file nf = {
+		.size = size,
+	};
+	int dev_fd, fd;
+
+	dev_fd = open("/dev/memory_provider", O_RDWR);
+	if (dev_fd < 0) {
+		TEST_REQUIRE(errno != ENOENT && errno != ENODEV);
+		TEST_FAIL("Failed to open /dev/memory_provider: %d (%s)",
+			  errno, strerror(errno));
+	}
+
+	fd = ioctl(dev_fd, MP_NEW_FILE, &nf);
+	TEST_ASSERT(fd >= 0, "MP_NEW_FILE failed: %d (%s)", errno, strerror(errno));
+	close(dev_fd);
+	return fd;
+}
+
+FIXTURE_VARIANT_ADD(gmem_conversions, mp) {
+	.create_resource = create_mp_resource,
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
2.56.0.455.g6c5a503b38-goog

