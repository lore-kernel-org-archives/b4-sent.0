From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:43 -0800
Subject: [PATCH RFC v3 09/88] KVM: selftests: Test rejection of memfd for
 resource_fd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-9-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=1909;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=jiwqzVYGQdXa1AlyMlZiDSlQ5Amwfala9fk+uK/j2tc=;
 b=PszqvFys8SqnJc1HxGZEKNlvVEFwz7sIeHsPskHnWi4bT6RpLtog7UsESKEfmxvHt5TZCim82
 VpkdFcaoV62BbYTF3YA+BLAEU556e8Oz+fbgR9PXpvhp9j2rNyMPT9f
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add test coverage verifying that passing an fd created via memfd_create
as a resource file fails with EOPNOTSUPP, because regular files do not
implement gmem_provider_ops. Only directory file descriptors representing
the mount root are supported as resource pools.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/guest_memfd_test.c | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index 445396860d819..d62ae23256083 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -457,6 +457,27 @@ static void test_resource_fd_unsupported_fs(struct kvm_vm *vm)
 	close(file_fd);
 }
 
+static void test_resource_fd_memfd(struct kvm_vm *vm)
+{
+	int fd, file_fd;
+
+	/*
+	 * Passing an fd returned by memfd_create is rejected with EOPNOTSUPP
+	 * because regular files do not have gmem_provider_ops defined on their
+	 * f_op. Only directory FDs representing the mount root are supported
+	 * resource pools.
+	 */
+	file_fd = memfd_create("test_memfd", 0);
+	TEST_ASSERT(file_fd >= 0, "memfd_create failed");
+
+	fd = __vm_create_guest_memfd_resource(vm, page_size,
+					      GUEST_MEMFD_FLAG_USE_RESOURCE,
+					      file_fd);
+	TEST_ASSERT(fd < 0, "guest_memfd with memfd should fail");
+	TEST_ASSERT_EQ(errno, EOPNOTSUPP);
+	close(file_fd);
+}
+
 #define ____gmem_test(__test, __vm, __flags, __gmem_size, args...)	\
 do {									\
 	int fd = vm_create_guest_memfd(__vm, __gmem_size, __flags);	\
@@ -517,6 +538,7 @@ static void test_guest_memfd(unsigned long vm_type)
 
 	test_resource_fd_invalid(vm);
 	test_resource_fd_unsupported_fs(vm);
+	test_resource_fd_memfd(vm);
 
 	__test_guest_memfd(vm, 0);
 

-- 
2.56.0.455.g6c5a503b38-goog

