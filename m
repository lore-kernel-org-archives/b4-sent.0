From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:46 -0800
Subject: [PATCH RFC v3 12/88] KVM: selftests: Test rejection of regular
 file in tmpfs mount
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-12-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=1842;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=zYxsNZnCD+hu0G5QQ3lbC6j/2PC+WQYN9K55T6nzbPY=;
 b=ySV106WA3UxzgQMwS2cQCoA6sf5fFrB3K9KXQtlXVC9kRWRixPXJMjJH+mrpv7XnI7hdOfeRS
 R33krV9Y6j3DcoWX5+p00ZKWqh8uh8cBdypxdO3uBbxoZ7hkl/lhevi
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add test coverage verifying that creating a regular file inside an
actual tmpfs mount and passing that file descriptor as resource_fd
fails with EOPNOTSUPP, because tmpfs regular files do not have
gmem_provider_ops defined on their file_operations.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/guest_memfd_test.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index 541d8cdd0bbf7..bef1acead4a6d 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -613,6 +613,25 @@ static void __test_guest_memfd(struct kvm_vm *vm, u64 flags)
 	gmem_test_vm(invalid_binding, vm, flags);
 }
 
+static void test_resource_fd_tmpfs_regular_file(struct kvm_vm *vm)
+{
+	int pool_fd, file_fd, fd;
+
+	pool_fd = create_tmpfs_pool_fd("never", true, page_size);
+
+	file_fd = openat(pool_fd, "regular_file", O_CREAT | O_RDWR | O_CLOEXEC, 0644);
+	TEST_ASSERT(file_fd >= 0, "openat regular_file in tmpfs pool failed");
+
+	fd = __vm_create_guest_memfd_resource(vm, page_size,
+					      GUEST_MEMFD_FLAG_USE_RESOURCE,
+					      file_fd);
+	TEST_ASSERT(fd < 0, "guest_memfd with tmpfs regular file should fail");
+	TEST_ASSERT_EQ(errno, EOPNOTSUPP);
+
+	close(file_fd);
+	close(pool_fd);
+}
+
 static void test_guest_memfd(unsigned long vm_type)
 {
 	struct kvm_vm *vm = vm_create_barebones_type(vm_type);
@@ -625,6 +644,7 @@ static void test_guest_memfd(unsigned long vm_type)
 	test_resource_fd_memfd(vm);
 	test_resource_fd_tmpfs_swap(vm);
 	test_resource_fd_tmpfs_huge(vm);
+	test_resource_fd_tmpfs_regular_file(vm);
 
 	__test_guest_memfd(vm, 0);
 

-- 
2.56.0.455.g6c5a503b38-goog

