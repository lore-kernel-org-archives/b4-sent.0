From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 25 Sep 2026 17:51:00 -0700
Subject: [PATCH RFC 13/17] KVM: selftests: Test guest_memfd resource pool
 sharing across instances
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-gmem-tmpfs-backend-v1-13-d36159822d18@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790383850; l=2284;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=9LO/j7yMhJpTOm28buLLSDSKy7s9Zo30YgKsCsYGTTM=;
 b=mVJcR7vvGiZtoLCGnt/0t4woHxKz3scYXOvAZ0LmNrLTf100ewNFL1vp2GLk6dll/4KmKlQAu
 u/BbjIypF/ODnW1Uifc1XQ2DvUviguno+Rtw2F5Iryj6zwEtjtmcb9u
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test that multiple guest_memfd instances can be created backed by the
same tmpfs resource pool descriptor, that each file descriptor reflects
its requested size, and that they have distinct inodes.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/guest_memfd_test.c | 36 ++++++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index 94ef64474f2a0..81311be059923 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -543,6 +543,41 @@ static void test_resource_fd_tmpfs_huge(struct kvm_vm *vm)
 	close(pool_fd);
 }
 
+static void test_resource_fd_tmpfs_shared_pool(struct kvm_vm *vm)
+{
+	int pool_fd, fd1, fd2;
+	struct stat st1, st2;
+
+	pool_fd = create_tmpfs_pool_fd("never", true, page_size * 2);
+	if (pool_fd < 0)
+		TEST_REQUIRE(false);
+
+	fd1 = vm_create_guest_memfd_resource(vm, page_size,
+					     GUEST_MEMFD_FLAG_USE_RESOURCE,
+					     pool_fd);
+
+	fd2 = vm_create_guest_memfd_resource(vm, page_size * 2,
+					     GUEST_MEMFD_FLAG_USE_RESOURCE,
+					     pool_fd);
+
+	TEST_ASSERT(!fstat(fd1, &st1), "fstat on fd1 should succeed");
+	TEST_ASSERT(st1.st_size == page_size,
+		    "fd1 st_size (%lu) should match requested size (%lu)",
+		    st1.st_size, page_size);
+
+	TEST_ASSERT(!fstat(fd2, &st2), "fstat on fd2 should succeed");
+	TEST_ASSERT(st2.st_size == page_size * 2,
+		    "fd2 st_size (%lu) should match requested size (%lu)",
+		    st2.st_size, page_size * 2);
+
+	TEST_ASSERT(st1.st_ino != st2.st_ino,
+		    "different guest_memfd instances should have distinct inodes");
+
+	close(fd2);
+	close(fd1);
+	close(pool_fd);
+}
+
 enum gmem_pool_type {
 	GMEM_POOL_NONE,
 	GMEM_POOL_FSMOUNT,
@@ -673,6 +708,7 @@ static void test_guest_memfd(unsigned long vm_type)
 	test_resource_fd_tmpfs_file(vm);
 	test_resource_fd_tmpfs_swap(vm);
 	test_resource_fd_tmpfs_huge(vm);
+	test_resource_fd_tmpfs_shared_pool(vm);
 
 	__test_guest_memfd(vm, 0, GMEM_POOL_NONE);
 	__test_guest_memfd(vm, GUEST_MEMFD_FLAG_USE_RESOURCE, GMEM_POOL_FSMOUNT);

-- 
2.56.0.rc1.315.gc6ed9934b7-goog

