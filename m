From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:47 -0800
Subject: [PATCH RFC v3 13/88] KVM: selftests: Test guest_memfd with tmpfs
 resource pool
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-13-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=2627;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=Qu55YepzOrkvcU6P+bNeN6dK+ZH4EE+CD9gCo1tRMPs=;
 b=1kdK6627i19vf9EPHPpEoGXhZEaTstbkmiKYLeec0b0X0HFFgMZ2ZRNvkGyRYgfjXfR/lS1e9
 BdAqrsrNbD/DUKfc1K2BQZoC/2dn8bnceObkJn7U9z8WcYqSyRW8UTs
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add test coverage verifying that creating a guest_memfd backed by a
tmpfs resource pool directory succeeds across all guest_memfd subtests
and flag combinations, and reports the requested file size.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/guest_memfd_test.c | 35 ++++++++++++++++++++------
 1 file changed, 27 insertions(+), 8 deletions(-)

diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index bef1acead4a6d..2250c3e9a583f 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -562,12 +562,23 @@ static void test_resource_fd_tmpfs_huge(struct kvm_vm *vm)
 	close(pool_fd);
 }
 
-#define ____gmem_test(__test, __vm, __flags, __gmem_size, args...)	\
-do {									\
-	int fd = vm_create_guest_memfd(__vm, __gmem_size, __flags);	\
-									\
-	test_##__test(args);						\
-	close(fd);							\
+#define ____gmem_test(__test, __vm, __flags, __gmem_size, args...)		\
+do {										\
+	int pool_fd = -1;							\
+	int fd;									\
+										\
+	if ((__flags) & GUEST_MEMFD_FLAG_USE_RESOURCE) {			\
+		pool_fd = create_tmpfs_pool_fd("never", true, __gmem_size);	\
+		fd = vm_create_guest_memfd_resource(__vm, __gmem_size,		\
+						    __flags, pool_fd);		\
+	} else {								\
+		fd = vm_create_guest_memfd(__vm, __gmem_size, __flags);	\
+	}									\
+										\
+	test_##__test(args);							\
+	close(fd);								\
+	if (pool_fd >= 0)							\
+		close(pool_fd);							\
 } while (0)
 
 #define __gmem_test(__test, __vm, __flags, __gmem_size)			\
@@ -647,15 +658,23 @@ static void test_guest_memfd(unsigned long vm_type)
 	test_resource_fd_tmpfs_regular_file(vm);
 
 	__test_guest_memfd(vm, 0);
+	__test_guest_memfd(vm, GUEST_MEMFD_FLAG_USE_RESOURCE);
 
 	flags = vm_check_cap(vm, KVM_CAP_GUEST_MEMFD_FLAGS);
-	if (flags & GUEST_MEMFD_FLAG_MMAP)
+	if (flags & GUEST_MEMFD_FLAG_MMAP) {
 		__test_guest_memfd(vm, GUEST_MEMFD_FLAG_MMAP);
+		__test_guest_memfd(vm, GUEST_MEMFD_FLAG_MMAP |
+				       GUEST_MEMFD_FLAG_USE_RESOURCE);
+	}
 
 	/* MMAP should always be supported if INIT_SHARED is supported. */
-	if (flags & GUEST_MEMFD_FLAG_INIT_SHARED)
+	if (flags & GUEST_MEMFD_FLAG_INIT_SHARED) {
 		__test_guest_memfd(vm, GUEST_MEMFD_FLAG_MMAP |
 				       GUEST_MEMFD_FLAG_INIT_SHARED);
+		__test_guest_memfd(vm, GUEST_MEMFD_FLAG_MMAP |
+				       GUEST_MEMFD_FLAG_INIT_SHARED |
+				       GUEST_MEMFD_FLAG_USE_RESOURCE);
+	}
 
 	kvm_vm_free(vm);
 }

-- 
2.56.0.455.g6c5a503b38-goog

