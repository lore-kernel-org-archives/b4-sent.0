From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 25 Sep 2026 17:50:54 -0700
Subject: [PATCH RFC 07/17] KVM: selftests: Test rejection of unsupported
 filesystem for resource_fd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-gmem-tmpfs-backend-v1-7-d36159822d18@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790383850; l=1760;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=c84B6n44NVtK2sHukMLB5KU4J3iKw7GkSZw3Puqe1NE=;
 b=mcUInbCP1l8RBE0LpSG40yF7SVS0NuEdAcubDuydYZGl6HTZiLO6aKz+MNMBBt9W88whJp98Y
 rYy1PfGCdV/CUbRH++lB6miMh/H7JzZ5SsHOreuZCnL0q9f+cNQcqzO
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add test coverage verifying that passing a directory file descriptor
from an unsupported filesystem without provider operations as a resource
file fails with EOPNOTSUPP.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/guest_memfd_test.c | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index 84b958b9ef715..31bc74c4c26bd 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -436,6 +436,27 @@ static void test_resource_fd_invalid(struct kvm_vm *vm)
 	TEST_ASSERT_EQ(errno, EBADF);
 }
 
+static void test_resource_fd_unsupported_fs(struct kvm_vm *vm)
+{
+	int fd, file_fd;
+
+	/*
+	 * Passing an FD from an unsupported filesystem without provider ops
+	 * (e.g. the /proc mount root directory) is rejected by KVM with
+	 * EOPNOTSUPP.
+	 */
+	file_fd = open("/proc", O_DIRECTORY | O_RDONLY);
+	TEST_ASSERT(file_fd >= 0, "open /proc failed");
+
+	fd = __vm_create_guest_memfd_resource(vm, page_size,
+					      GUEST_MEMFD_FLAG_USE_RESOURCE,
+					      file_fd);
+	TEST_ASSERT(fd < 0, "guest_memfd with /proc fd should fail");
+	TEST_ASSERT_EQ(errno, EOPNOTSUPP);
+
+	close(file_fd);
+}
+
 #define ____gmem_test(__test, __vm, __flags, __gmem_size, args...)	\
 do {									\
 	int fd = vm_create_guest_memfd(__vm, __gmem_size, __flags);	\
@@ -495,6 +516,7 @@ static void test_guest_memfd(unsigned long vm_type)
 	test_guest_memfd_flags(vm);
 
 	test_resource_fd_invalid(vm);
+	test_resource_fd_unsupported_fs(vm);
 
 	__test_guest_memfd(vm, 0);
 

-- 
2.56.0.rc1.315.gc6ed9934b7-goog

