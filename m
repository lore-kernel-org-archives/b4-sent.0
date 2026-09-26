From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 25 Sep 2026 17:50:59 -0700
Subject: [PATCH RFC 12/17] KVM: selftests: Test guest_memfd with mounted
 tmpfs root directory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-gmem-tmpfs-backend-v1-12-d36159822d18@google.com>
References: <20260925-gmem-tmpfs-backend-v1-0-d36159822d18@google.com>
In-Reply-To: <20260925-gmem-tmpfs-backend-v1-0-d36159822d18@google.com>
To: Hugh Dickins <hughd@google.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, David Hildenbrand <david@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Shuah Khan <shuah@kernel.org>, 
 vannapurve@google.com, erdemaktas@google.com, jxgao@google.com, 
 rientjes@google.com, fvdl@google.com, jthoughton@google.com, 
 tarunsahu@google.com, pratyush@kernel.org, fuad.tabba@linux.dev, 
 Gregory Price <gourry@gourry.net>, David Woodhouse <dwmw2@infradead.org>, 
 yan.y.zhao@intel.com, michael.roth@amd.com, suzuki.poulose@arm.com, 
 Christian Brauner <brauner@kernel.org>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Nicolin Chen <nicolinc@nvidia.com>, Xu Yilun <yilun.xu@linux.intel.com>, 
 aik@amd.com, aneesh.kumar@kernel.org, Vlastimil Babka <vbabka@kernel.org>
Cc: kernel-team@android.com, kernel-team@meta.com, 
 linux-kernel@vger.kernel.org, linux-mm@kvack.org, kvm@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790383850; l=7758;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=I2qZYT+hdR9asssZySkypzr+BY173budj+AtlVNc+WY=;
 b=4/VFnb+9s+yMlUcYP3RlcOKI9CoI44IGLvMZ9TOrzcZL5l3AvKLpTfTxSoQJqrZvDZH53/7xc
 1NdnFokQecUCT4JzQmqjmtlO9cMXSiBhIGbWZLyXfeo1J5GdVqZAuGI
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add test coverage verifying that opening the root directory of an
existing mounted tmpfs filesystem and passing that file descriptor as
the resource pool succeeds across all guest_memfd subtests and flag
combinations.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/guest_memfd_test.c | 137 +++++++++++++++++++------
 1 file changed, 103 insertions(+), 34 deletions(-)

diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index 73212d5307049..94ef64474f2a0 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -10,11 +10,13 @@
 #include <errno.h>
 #include <stdio.h>
 #include <fcntl.h>
+#include <limits.h>
 
 #include <linux/bitmap.h>
 #include <linux/falloc.h>
 #include <linux/mount.h>
 #include <linux/sizes.h>
+#include <sys/mount.h>
 #include <sys/types.h>
 #include <sys/stat.h>
 
@@ -541,66 +543,122 @@ static void test_resource_fd_tmpfs_huge(struct kvm_vm *vm)
 	close(pool_fd);
 }
 
-#define ____gmem_test(__test, __vm, __flags, __gmem_size, args...)		\
+enum gmem_pool_type {
+	GMEM_POOL_NONE,
+	GMEM_POOL_FSMOUNT,
+	GMEM_POOL_MOUNTED_DIR,
+};
+
+struct gmem_pool {
+	int fd;
+	char path[PATH_MAX];
+	bool is_mounted;
+};
+
+static struct gmem_pool create_gmem_pool(size_t size, enum gmem_pool_type type)
+{
+	struct gmem_pool pool = { .fd = -1, .is_mounted = false };
+	int mnt_fd;
+
+	if (type == GMEM_POOL_NONE)
+		return pool;
+
+	mnt_fd = create_tmpfs_pool_fd("never", true, size);
+	TEST_REQUIRE(mnt_fd >= 0);
+
+	if (type == GMEM_POOL_FSMOUNT) {
+		pool.fd = mnt_fd;
+		return pool;
+	}
+
+	strcpy(pool.path, "/tmp/gmem_test_dir_XXXXXX");
+	TEST_ASSERT(mkdtemp(pool.path), "mkdtemp failed");
+
+	if (syscall(__NR_move_mount, mnt_fd, "", AT_FDCWD, pool.path,
+		    MOVE_MOUNT_F_EMPTY_PATH)) {
+		close(mnt_fd);
+		rmdir(pool.path);
+		TEST_REQUIRE(false);
+	}
+	close(mnt_fd);
+
+	pool.fd = open(pool.path, O_RDONLY | O_DIRECTORY);
+	TEST_ASSERT(pool.fd >= 0, "open mounted tmpfs root failed");
+	pool.is_mounted = true;
+
+	return pool;
+}
+
+static void destroy_gmem_pool(struct gmem_pool *pool)
+{
+	if (pool->fd >= 0)
+		close(pool->fd);
+	if (pool->is_mounted) {
+		TEST_ASSERT(!umount(pool->path), "umount failed");
+		TEST_ASSERT(!rmdir(pool->path), "rmdir failed");
+	}
+}
+
+#define ____gmem_test(__test, __vm, __flags, __pool_type, __gmem_size, args...)	\
 do {										\
-	int pool_fd = -1;							\
+	struct gmem_pool pool = { .fd = -1 };					\
 	int fd;									\
 										\
 	if ((__flags) & GUEST_MEMFD_FLAG_USE_RESOURCE) {			\
-		pool_fd = create_tmpfs_pool_fd("never", true, __gmem_size);	\
+		pool = create_gmem_pool(__gmem_size, __pool_type);		\
 		fd = vm_create_guest_memfd_resource(__vm, __gmem_size,		\
-						    __flags, pool_fd);		\
+						    __flags, pool.fd);		\
 	} else {								\
 		fd = vm_create_guest_memfd(__vm, __gmem_size, __flags);	\
 	}									\
 										\
 	test_##__test(args);							\
 	close(fd);								\
-	if (pool_fd >= 0)							\
-		close(pool_fd);							\
+	destroy_gmem_pool(&pool);						\
 } while (0)
 
-#define __gmem_test(__test, __vm, __flags, __gmem_size)			\
-	____gmem_test(__test, __vm, __flags, __gmem_size, fd, __gmem_size)
+#define __gmem_test(__test, __vm, __flags, __pool_type, __gmem_size)		\
+	____gmem_test(__test, __vm, __flags, __pool_type, __gmem_size, fd, __gmem_size)
 
-#define gmem_test(__test, __vm, __flags)				\
-	__gmem_test(__test, __vm, __flags, page_size * 4)
+#define gmem_test(__test, __vm, __flags, __pool_type)				\
+	__gmem_test(__test, __vm, __flags, __pool_type, page_size * 4)
 
-#define __gmem_test_vm(__test, __vm, __flags, __gmem_size)		\
-	____gmem_test(__test, __vm, __flags, __gmem_size, __vm, fd, __gmem_size)
+#define __gmem_test_vm(__test, __vm, __flags, __pool_type, __gmem_size)	\
+	____gmem_test(__test, __vm, __flags, __pool_type, __gmem_size, __vm, fd, __gmem_size)
 
-#define gmem_test_vm(__test, __vm, __flags)				\
-	__gmem_test_vm(__test, __vm, __flags, page_size * 4)
+#define gmem_test_vm(__test, __vm, __flags, __pool_type)			\
+	__gmem_test_vm(__test, __vm, __flags, __pool_type, page_size * 4)
 
-static void __test_guest_memfd(struct kvm_vm *vm, u64 flags)
+static void __test_guest_memfd(struct kvm_vm *vm, u64 flags,
+			       enum gmem_pool_type pool_type)
 {
 	test_create_guest_memfd_multiple(vm);
 	test_create_guest_memfd_invalid_sizes(vm, flags);
 
-	gmem_test(file_read_write, vm, flags);
+	gmem_test(file_read_write, vm, flags, pool_type);
 
 	if (flags & GUEST_MEMFD_FLAG_MMAP) {
 		if (flags & GUEST_MEMFD_FLAG_INIT_SHARED) {
 			size_t pmd_size = get_trans_hugepagesz();
 
-			gmem_test(mmap_supported, vm, flags);
-			gmem_test(fault_overflow, vm, flags);
-			gmem_test(numa_allocation, vm, flags);
-			__gmem_test(collapse, vm, flags, pmd_size);
+			gmem_test(mmap_supported, vm, flags, pool_type);
+			gmem_test(fault_overflow, vm, flags, pool_type);
+			gmem_test(numa_allocation, vm, flags, pool_type);
+			__gmem_test(collapse, vm, flags, pool_type, pmd_size);
 		} else {
-			gmem_test(fault_private, vm, flags);
+			gmem_test(fault_private, vm, flags, pool_type);
 		}
 
-		gmem_test(mmap_cow, vm, flags);
-		gmem_test(mbind, vm, flags);
+		gmem_test(mmap_cow, vm, flags, pool_type);
+		gmem_test(mbind, vm, flags, pool_type);
 	} else {
-		gmem_test(mmap_not_supported, vm, flags);
+		gmem_test(mmap_not_supported, vm, flags, pool_type);
 	}
 
-	gmem_test(file_size, vm, flags);
-	gmem_test(fallocate, vm, flags);
-	gmem_test(invalid_punch_hole, vm, flags);
-	gmem_test_vm(invalid_binding, vm, flags);
+	gmem_test(file_size, vm, flags, pool_type);
+	gmem_test(fallocate, vm, flags, pool_type);
+	gmem_test(invalid_punch_hole, vm, flags, pool_type);
+	gmem_test_vm(invalid_binding, vm, flags, pool_type);
 }
 
 static void test_guest_memfd(unsigned long vm_type)
@@ -616,23 +674,34 @@ static void test_guest_memfd(unsigned long vm_type)
 	test_resource_fd_tmpfs_swap(vm);
 	test_resource_fd_tmpfs_huge(vm);
 
-	__test_guest_memfd(vm, 0);
-	__test_guest_memfd(vm, GUEST_MEMFD_FLAG_USE_RESOURCE);
+	__test_guest_memfd(vm, 0, GMEM_POOL_NONE);
+	__test_guest_memfd(vm, GUEST_MEMFD_FLAG_USE_RESOURCE, GMEM_POOL_FSMOUNT);
+	__test_guest_memfd(vm, GUEST_MEMFD_FLAG_USE_RESOURCE, GMEM_POOL_MOUNTED_DIR);
 
 	flags = vm_check_cap(vm, KVM_CAP_GUEST_MEMFD_FLAGS);
 	if (flags & GUEST_MEMFD_FLAG_MMAP) {
-		__test_guest_memfd(vm, GUEST_MEMFD_FLAG_MMAP);
+		__test_guest_memfd(vm, GUEST_MEMFD_FLAG_MMAP, GMEM_POOL_NONE);
+		__test_guest_memfd(vm, GUEST_MEMFD_FLAG_MMAP |
+				       GUEST_MEMFD_FLAG_USE_RESOURCE,
+				   GMEM_POOL_FSMOUNT);
 		__test_guest_memfd(vm, GUEST_MEMFD_FLAG_MMAP |
-				       GUEST_MEMFD_FLAG_USE_RESOURCE);
+				       GUEST_MEMFD_FLAG_USE_RESOURCE,
+				   GMEM_POOL_MOUNTED_DIR);
 	}
 
 	/* MMAP should always be supported if INIT_SHARED is supported. */
 	if (flags & GUEST_MEMFD_FLAG_INIT_SHARED) {
 		__test_guest_memfd(vm, GUEST_MEMFD_FLAG_MMAP |
-				       GUEST_MEMFD_FLAG_INIT_SHARED);
+				       GUEST_MEMFD_FLAG_INIT_SHARED,
+				   GMEM_POOL_NONE);
+		__test_guest_memfd(vm, GUEST_MEMFD_FLAG_MMAP |
+				       GUEST_MEMFD_FLAG_INIT_SHARED |
+				       GUEST_MEMFD_FLAG_USE_RESOURCE,
+				   GMEM_POOL_FSMOUNT);
 		__test_guest_memfd(vm, GUEST_MEMFD_FLAG_MMAP |
 				       GUEST_MEMFD_FLAG_INIT_SHARED |
-				       GUEST_MEMFD_FLAG_USE_RESOURCE);
+				       GUEST_MEMFD_FLAG_USE_RESOURCE,
+				   GMEM_POOL_MOUNTED_DIR);
 	}
 
 	kvm_vm_free(vm);

-- 
2.56.0.rc1.315.gc6ed9934b7-goog

