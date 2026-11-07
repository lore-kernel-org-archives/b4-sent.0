From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:41 -0800
Subject: [PATCH RFC v3 07/88] KVM: selftests: Test negative validation of
 resource_fd argument
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-7-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=2102;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=dKdQoJ+6E8rrtajy5+HMr37wBSZwSe5sC1LJJuGdkHs=;
 b=LxXhMdKPAOtjHYRtDSEnmO6i0SyBR+8ksuLusE+lUgxFRHpPSn5ekpfaFhOJgoQa3Kb6jOzAg
 RiLZHyldizYAfAkkTkilm4Hka1ub4SCVyl4AjywJN2UjejjfdHGfboW
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add negative test coverage verifying that creating a guest_memfd
instance with a non-zero resource_fd when GUEST_MEMFD_FLAG_USE_RESOURCE
is clear fails with -EINVAL, and creating with an invalid resource_fd
fails with -EBADF.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/guest_memfd_test.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index cd5df88bc6427..3313d306c0bdc 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -404,6 +404,8 @@ static void test_guest_memfd_flags(struct kvm_vm *vm)
 	int fd;
 
 	for (flag = BIT(0); flag; flag <<= 1) {
+		if (flag == GUEST_MEMFD_FLAG_USE_RESOURCE)
+			continue;
 		fd = __vm_create_guest_memfd(vm, page_size, flag);
 		if (flag & valid_flags) {
 			TEST_ASSERT(fd >= 0,
@@ -418,6 +420,22 @@ static void test_guest_memfd_flags(struct kvm_vm *vm)
 	}
 }
 
+static void test_resource_fd_invalid(struct kvm_vm *vm)
+{
+	int fd;
+
+	/* Non-zero resource_fd without GUEST_MEMFD_FLAG_USE_RESOURCE fails */
+	fd = __vm_create_guest_memfd_resource(vm, page_size, 0, 1);
+	TEST_ASSERT(fd < 0, "guest_memfd with resource_fd but without flag should fail");
+	TEST_ASSERT_EQ(errno, EINVAL);
+
+	/* Bad file descriptor with GUEST_MEMFD_FLAG_USE_RESOURCE fails */
+	fd = __vm_create_guest_memfd_resource(vm, page_size,
+					      GUEST_MEMFD_FLAG_USE_RESOURCE, -1);
+	TEST_ASSERT(fd < 0, "guest_memfd with -1 resource_fd should fail");
+	TEST_ASSERT_EQ(errno, EBADF);
+}
+
 #define ____gmem_test(__test, __vm, __flags, __gmem_size, args...)	\
 do {									\
 	int fd = vm_create_guest_memfd(__vm, __gmem_size, __flags);	\
@@ -476,6 +494,8 @@ static void test_guest_memfd(unsigned long vm_type)
 
 	test_guest_memfd_flags(vm);
 
+	test_resource_fd_invalid(vm);
+
 	__test_guest_memfd(vm, 0);
 
 	flags = vm_check_cap(vm, KVM_CAP_GUEST_MEMFD_FLAGS);

-- 
2.56.0.455.g6c5a503b38-goog

