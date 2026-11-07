From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:53 -0800
Subject: [PATCH RFC v3 19/88] KVM: selftests: Test guest_memfd conversions
 with tmpfs backing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-19-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=9639;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=Ywv4Awh60QVQXfJ42x/j6i2G3l1UGcU6b4v8gcyWpig=;
 b=EDb+BOFfQuAMKC477YknSboSYEtvDUgYLwNAzDBtxOPsFifr+qxx1Kgb2Sjumi6KnTOEoFdoN
 NlP5Q12K2NNCUhaXa9Jue3uo1cBdclLvjJJyIG6fbL7MBuPn4X5T/9n
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move create_tmpfs_pool_fd() into lib/test_util.c and declare it in
include/test_util.h so it can be reused across selftests.

Extend guest_memfd_conversions_test using fixture variants to run all
conversion test cases against both native guest_memfd and tmpfs-backed
guest_memfd instances.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/guest_memfd_test.c     | 52 --------------------
 tools/testing/selftests/kvm/include/test_util.h    |  2 +
 tools/testing/selftests/kvm/lib/test_util.c        | 56 ++++++++++++++++++++++
 .../kvm/x86/guest_memfd_conversions_test.c         | 49 +++++++++++++++++--
 4 files changed, 102 insertions(+), 57 deletions(-)

diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index fd249445ce3cc..cbc2f309664b2 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -481,58 +481,6 @@ static void test_resource_fd_memfd(struct kvm_vm *vm)
 	close(file_fd);
 }
 
-static int create_tmpfs_pool_fd(const char *huge, bool noswap, size_t size)
-{
-	char size_str[32];
-	char template[] = "/tmp/gmem_test_dir_XXXXXX";
-	char *mount_dir;
-	int fs_fd, mnt_fd, dir_fd;
-
-	TEST_ASSERT(size && IS_ALIGNED(size, page_size),
-		    "Pool size '0x%zx' must be positive and page-aligned", size);
-
-	fs_fd = syscall(__NR_fsopen, "tmpfs", FSOPEN_CLOEXEC);
-	TEST_ASSERT(fs_fd >= 0, "fsopen failed");
-
-	if (noswap)
-		TEST_ASSERT(!syscall(__NR_fsconfig, fs_fd, FSCONFIG_SET_FLAG,
-				     "noswap", NULL, 0), "fsconfig noswap failed");
-
-	if (huge)
-		TEST_ASSERT(!syscall(__NR_fsconfig, fs_fd, FSCONFIG_SET_STRING,
-				     "huge", huge, 0), "fsconfig huge failed");
-
-	snprintf(size_str, sizeof(size_str), "%zu", size);
-	TEST_ASSERT(!syscall(__NR_fsconfig, fs_fd, FSCONFIG_SET_STRING,
-			     "size", size_str, 0), "fsconfig size failed");
-
-	TEST_ASSERT(!syscall(__NR_fsconfig, fs_fd, FSCONFIG_CMD_CREATE,
-			     NULL, NULL, 0), "fsconfig create failed");
-
-	mnt_fd = syscall(__NR_fsmount, fs_fd, FSMOUNT_CLOEXEC, 0);
-	TEST_ASSERT(mnt_fd > 0, "fsmount failed");
-	close(fs_fd);
-
-	mount_dir = mkdtemp(template);
-	TEST_ASSERT(mount_dir, "mkdtemp failed");
-
-	TEST_ASSERT(!syscall(__NR_move_mount, mnt_fd, "", AT_FDCWD, mount_dir,
-			     MOVE_MOUNT_F_EMPTY_PATH), "move_mount failed");
-	close(mnt_fd);
-
-	dir_fd = open(mount_dir, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
-	TEST_ASSERT(dir_fd >= 0, "open tmpfs mount directory failed");
-
-	/*
-	 * Detach mount from namespace so removing mount_dir upon exit or
-	 * unmount doesn't conflict, while dir_fd retains the active mount.
-	 */
-	TEST_ASSERT(!umount2(mount_dir, MNT_DETACH), "umount2 failed");
-	TEST_ASSERT(!rmdir(mount_dir), "rmdir failed");
-
-	return dir_fd;
-}
-
 static void test_resource_fd_tmpfs_swap(struct kvm_vm *vm)
 {
 	int pool_fd, fd;
diff --git a/tools/testing/selftests/kvm/include/test_util.h b/tools/testing/selftests/kvm/include/test_util.h
index c80019e24b2d0..e6707534f1951 100644
--- a/tools/testing/selftests/kvm/include/test_util.h
+++ b/tools/testing/selftests/kvm/include/test_util.h
@@ -244,4 +244,6 @@ char *strdup_printf(const char *fmt, ...) __attribute__((format(printf, 1, 2), n
 
 char *sys_get_cur_clocksource(void);
 
+int create_tmpfs_pool_fd(const char *huge, bool noswap, size_t size);
+
 #endif /* SELFTEST_KVM_TEST_UTIL_H */
diff --git a/tools/testing/selftests/kvm/lib/test_util.c b/tools/testing/selftests/kvm/lib/test_util.c
index f5f7189f96a84..c5b264f533ad0 100644
--- a/tools/testing/selftests/kvm/lib/test_util.c
+++ b/tools/testing/selftests/kvm/lib/test_util.c
@@ -10,10 +10,14 @@
 #include <ctype.h>
 #include <limits.h>
 #include <stdlib.h>
+#include <fcntl.h>
 #include <time.h>
+#include <sys/mount.h>
 #include <sys/stat.h>
 #include <sys/syscall.h>
+#include <linux/align.h>
 #include <linux/mman.h>
+#include <linux/mount.h>
 #include "linux/kernel.h"
 
 #include "test_util.h"
@@ -483,3 +487,55 @@ char *sys_get_cur_clocksource(void)
 
 	return clk_name;
 }
+
+int create_tmpfs_pool_fd(const char *huge, bool noswap, size_t size)
+{
+	char size_str[32];
+	char template[] = "/tmp/gmem_test_dir_XXXXXX";
+	char *mount_dir;
+	int fs_fd, mnt_fd, dir_fd;
+
+	TEST_ASSERT(size && IS_ALIGNED(size, getpagesize()),
+		    "Pool size '0x%zx' must be positive and page-aligned", size);
+
+	fs_fd = syscall(__NR_fsopen, "tmpfs", FSOPEN_CLOEXEC);
+	TEST_ASSERT(fs_fd >= 0, "fsopen failed");
+
+	if (noswap)
+		TEST_ASSERT(!syscall(__NR_fsconfig, fs_fd, FSCONFIG_SET_FLAG,
+				     "noswap", NULL, 0), "fsconfig noswap failed");
+
+	if (huge)
+		TEST_ASSERT(!syscall(__NR_fsconfig, fs_fd, FSCONFIG_SET_STRING,
+				     "huge", huge, 0), "fsconfig huge failed");
+
+	snprintf(size_str, sizeof(size_str), "%zu", size);
+	TEST_ASSERT(!syscall(__NR_fsconfig, fs_fd, FSCONFIG_SET_STRING,
+			     "size", size_str, 0), "fsconfig size failed");
+
+	TEST_ASSERT(!syscall(__NR_fsconfig, fs_fd, FSCONFIG_CMD_CREATE,
+			     NULL, NULL, 0), "fsconfig create failed");
+
+	mnt_fd = syscall(__NR_fsmount, fs_fd, FSMOUNT_CLOEXEC, 0);
+	TEST_ASSERT(mnt_fd > 0, "fsmount failed");
+	close(fs_fd);
+
+	mount_dir = mkdtemp(template);
+	TEST_ASSERT(mount_dir, "mkdtemp failed");
+
+	TEST_ASSERT(!syscall(__NR_move_mount, mnt_fd, "", AT_FDCWD, mount_dir,
+			     MOVE_MOUNT_F_EMPTY_PATH), "move_mount failed");
+	close(mnt_fd);
+
+	dir_fd = open(mount_dir, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
+	TEST_ASSERT(dir_fd >= 0, "open tmpfs mount directory failed");
+
+	/*
+	 * Detach mount from namespace so removing mount_dir upon exit or
+	 * unmount doesn't conflict, while dir_fd retains the active mount.
+	 */
+	TEST_ASSERT(!umount2(mount_dir, MNT_DETACH), "umount2 failed");
+	TEST_ASSERT(!rmdir(mount_dir), "rmdir failed");
+
+	return dir_fd;
+}
diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
index e1c84df0f0596..023df9cb9d4a6 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
@@ -20,12 +20,30 @@
 FIXTURE(gmem_conversions) {
 	struct kvm_vcpu *vcpu;
 	int gmem_fd;
+	int resource_fd;
 	/* HVA of the first byte of the memory mmap()-ed from gmem_fd. */
 	char *mem;
 };
 
 typedef FIXTURE_DATA(gmem_conversions) test_data_t;
 
+FIXTURE_VARIANT(gmem_conversions) {
+	int (*create_resource)(size_t size);
+};
+
+FIXTURE_VARIANT_ADD(gmem_conversions, native) {
+	.create_resource = NULL,
+};
+
+static int create_tmpfs_resource(size_t size)
+{
+	return create_tmpfs_pool_fd("never", true, size);
+}
+
+FIXTURE_VARIANT_ADD(gmem_conversions, tmpfs) {
+	.create_resource = create_tmpfs_resource,
+};
+
 FIXTURE_SETUP(gmem_conversions) { }
 
 static size_t page_size;
@@ -37,8 +55,9 @@ static void guest_do_rmw(void);
  * Defer setup until the individual test is invoked so that tests can specify
  * the number of pages and flags for the guest_memfd instance.
  */
-static void gmem_conversions_do_setup(test_data_t *t, int nr_pages,
-				      int gmem_flags)
+static void gmem_conversions_do_setup(test_data_t *t,
+				      const FIXTURE_VARIANT(gmem_conversions) * variant,
+				      int nr_pages, int gmem_flags)
 {
 	const struct vm_shape shape = {
 		.mode = VM_MODE_DEFAULT,
@@ -50,12 +69,27 @@ static void gmem_conversions_do_setup(test_data_t *t, int nr_pages,
 	 */
 	const gpa_t gpa = SZ_4G;
 	const u32 slot = 1;
+	size_t size = nr_pages * page_size;
 	struct kvm_vm *vm;
+	int gmem_fd = -1;
 
 	vm = __vm_create_shape_with_one_vcpu(shape, &t->vcpu, nr_pages, guest_do_rmw);
 
+	t->resource_fd = -1;
+
+	if (variant->create_resource) {
+		uint64_t flags = gmem_flags | GUEST_MEMFD_FLAG_USE_RESOURCE;
+
+		t->resource_fd = variant->create_resource(size);
+		TEST_ASSERT(t->resource_fd >= 0, "Failed to create backing resource");
+
+		gmem_fd = __vm_create_guest_memfd_resource(vm, size, flags,
+							   t->resource_fd);
+		TEST_ASSERT(gmem_fd >= 0, "Failed to create guest_memfd with resource");
+	}
+
 	vm_mem_add(vm, VM_MEM_SRC_SHMEM, gpa, slot, nr_pages,
-		   KVM_MEM_GUEST_MEMFD, -1, 0, gmem_flags);
+		   KVM_MEM_GUEST_MEMFD, gmem_fd, 0, gmem_flags);
 
 	t->gmem_fd = kvm_slot_to_fd(vm, slot);
 	t->mem = addr_gpa2hva(vm, gpa);
@@ -68,6 +102,11 @@ static void gmem_conversions_do_teardown(test_data_t *t)
 	if (!t->vcpu)
 		return;
 
+	if (t->resource_fd >= 0) {
+		close(t->resource_fd);
+		t->resource_fd = -1;
+	}
+
 	/* No need to close gmem_fd, it's owned by the VM structure. */
 	kvm_vm_free(t->vcpu->vm);
 	t->vcpu = NULL;
@@ -91,7 +130,7 @@ TEST_F(gmem_conversions, test)							\
 {										\
 	const int nr = (__nr_pages);						\
 										\
-	gmem_conversions_do_setup(self, nr, flags);				\
+	gmem_conversions_do_setup(self, variant, nr, flags);			\
 	__gmem_conversions_##test(self, nr);					\
 }										\
 static void __gmem_conversions_##test(test_data_t *t, int nr_pages)		\
@@ -127,7 +166,7 @@ TEST_F(gmem_conversions, test)							\
 	int i;									\
 										\
 	for (i = 0; i < nr; ++i) {						\
-		gmem_conversions_do_setup(self, nr, flags);			\
+		gmem_conversions_do_setup(self, variant, nr, flags);		\
 		__gmem_conversions_multipage_##test(self, nr, i);		\
 		gmem_conversions_do_teardown(self);				\
 	}									\

-- 
2.56.0.455.g6c5a503b38-goog

